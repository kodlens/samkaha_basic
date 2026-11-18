import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/transaction.dart';
import 'package:sales_management/models/transaction_details.dart';
import 'package:sales_management/pages/user/transaction/partials/transaction_card.dart';
import 'package:sales_management/pages/user/transaction/partials/transaction_detail_modal.dart';
import 'package:sales_management/pages/user/transaction/partials/transaction_header.dart';
import 'package:sales_management/services/bluetooth_print_service.dart';
import 'package:sales_management/utils/helper.dart';
import 'package:sales_management/utils/purchase_receipt.dart';
import 'package:sales_management/utils/responsive.dart';

class TransactionList extends StatefulWidget {
  const TransactionList({super.key});

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedPeriod = 'Today'; // 'Today', 'Yesterday', 'This Week', 'This Month', 'All Time', 'Custom'
  DateTime? _startDate;
  DateTime? _endDate;

  Future<List<Map<String, dynamic>>>? _transactionsFuture;
  Future<Map<String, dynamic>>? _summaryFuture;

  // Bluetooth Printer State
  List<BluetoothInfo> _printers = [];
  BluetoothInfo? _selectedPrinter;
  bool _isScanning = false;
  bool _isPrinting = false;
  void Function(void Function())? _dialogSetState;

  @override
  void initState() {
    super.initState();
    _applyPeriod('Today', refresh: false);
    _refreshData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyPeriod(String period, {bool refresh = true}) {
    final now = DateTime.now();
    _selectedPeriod = period;

    if (period == 'Today') {
      _startDate = DateTime(now.year, now.month, now.day);
      _endDate = DateTime(now.year, now.month, now.day);
    } else if (period == 'Yesterday') {
      final y = now.subtract(const Duration(days: 1));
      _startDate = DateTime(y.year, y.month, y.day);
      _endDate = DateTime(y.year, y.month, y.day);
    } else if (period == 'This Week') {
      _startDate = now.subtract(Duration(days: now.weekday - 1));
      _endDate = now;
    } else if (period == 'This Month') {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = now;
    } else if (period == 'All Time') {
      _startDate = null;
      _endDate = null;
    }

    if (refresh) _refreshData();
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: _startDate ?? now.subtract(const Duration(days: 7)),
        end: _endDate ?? now,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ThemeHelper.primaryColor(),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedPeriod = 'Custom';
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _refreshData();
    }
  }

  void _refreshData() {
    setState(() {
      _transactionsFuture = Transaction().queryTransactions(
        fromDate: _startDate,
        toDate: _endDate,
        searchQuery: _searchQuery,
      );
      _summaryFuture = Transaction().queryTransactionSummary(
        fromDate: _startDate,
        toDate: _endDate,
        searchQuery: _searchQuery,
      );
    });
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  // --- Bluetooth Thermal Printer Flow ---
  Future<void> _startScan() async {
    _printers = [];
    _selectedPrinter = null;
    _isScanning = true;
    if (mounted) setState(() {});
    _dialogSetState?.call(() {});

    final bluetoothEnabled = await PrintBluetoothThermal.bluetoothEnabled;
    if (!bluetoothEnabled) {
      if (!mounted) return;
      _isScanning = false;
      setState(() {});
      _dialogSetState?.call(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable Bluetooth.')),
      );
      return;
    }

    final devices = await PrintBluetoothThermal.pairedBluetooths;
    _printers = devices;
    if (_printers.isNotEmpty && _selectedPrinter == null) {
      _selectedPrinter = _printers.first;
    }

    if (!mounted) return;
    _isScanning = false;
    setState(() {});
    _dialogSetState?.call(() {});
  }

  Future<void> _printReceipt(
    BluetoothInfo printer,
    Map<String, dynamic> transaction,
    List<Map<String, dynamic>> details,
  ) async {
    setState(() => _isPrinting = true);
    _dialogSetState?.call(() {});

    final cart = details
        .map((d) => {
              'name': d['product_name'],
              'quantity': d['quantity'],
              'selling_price': d['selling_price'],
            })
        .toList();

    final total = _toDouble(transaction['total']);
    final payment = _toDouble(transaction['payment']);
    final change = payment - total;

    final bytes = await PurchaseReceipt(
      transactionId: transaction['id'],
      cart: cart,
      totalAmount: total,
      paymentAmount: payment,
      change: change > 0 ? change : 0,
    ).buildReceiptBytes();

    try {
      final connected = await PrintBluetoothThermal.connect(
        macPrinterAddress: printer.macAdress,
      );
      if (!connected) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Printer connection failed.')),
        );
        return;
      }

      final result = await PrintBluetoothThermal.writeBytes(bytes);
      if (!result && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Print failed.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print failed: $e')),
      );
    } finally {
      try {
        await PrintBluetoothThermal.disconnect;
      } catch (_) {}
      if (mounted) {
        setState(() => _isPrinting = false);
        _dialogSetState?.call(() {});
      }
    }
  }

  Future<void> _showPrintDialog(Map<String, dynamic> transaction) async {
    final bluetoothPrintService = BluetoothPrintService();
    final hasPermission =
        await bluetoothPrintService.ensureBluetoothPermissions();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bluetooth permissions are required to print.')),
      );
      return;
    }

    await _startScan();
    if (!mounted) return;
    _dialogSetState = null;

    final details =
        await TransactionDetails().queryByTransactionId(transaction['id']);
    final total = _toDouble(transaction['total']);

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogCtx, setStateDialog) {
            _dialogSetState = setStateDialog;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Thermal Receipt Printer',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ThemeHelper.primaryColor().withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Transaction #${transaction['id']}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(Helper.formatNumberWithPeso(total),
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: ThemeHelper.primaryColor())),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Available Printers',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        TextButton.icon(
                          onPressed: _isScanning ? null : _startScan,
                          icon: const Icon(Icons.refresh, size: 15),
                          label: Text(_isScanning ? 'Scanning...' : 'Rescan'),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 180,
                      child: _printers.isEmpty
                          ? Center(
                              child: Text(
                                _isScanning
                                    ? 'Scanning for paired printers...'
                                    : 'No paired Bluetooth printers found.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: ThemeHelper.textSecondary()),
                              ),
                            )
                          : RadioGroup<BluetoothInfo>(
                              groupValue: _selectedPrinter,
                              onChanged: (value) {
                                _selectedPrinter = value;
                                setState(() {});
                                setStateDialog(() {});
                              },
                              child: ListView.builder(
                                itemCount: _printers.length,
                                itemBuilder: (ctx, index) {
                                  final printer = _printers[index];
                                  final isSelected =
                                      _selectedPrinter?.macAdress ==
                                          printer.macAdress;
                                  return RadioListTile<BluetoothInfo>(
                                    value: printer,
                                    title: Text(printer.name,
                                        style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600)),
                                    subtitle: Text(printer.macAdress,
                                        style: const TextStyle(fontSize: 11)),
                                    selected: isSelected,
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isPrinting
                      ? null
                      : () {
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: _isPrinting
                      ? null
                      : () async {
                          if (_selectedPrinter == null) {
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select a printer.'),
                                ),
                              );
                            }
                            return;
                          }
                          await _printReceipt(
                              _selectedPrinter!, transaction, details);
                          _dialogSetState = null;
                          if (dialogContext.mounted &&
                              Navigator.of(dialogContext).canPop()) {
                            Navigator.pop(dialogContext);
                          }
                        },
                  icon: _isPrinting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.print, size: 16),
                  label: Text(_isPrinting ? 'Printing...' : 'Print Ticket'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeHelper.primaryColor(),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    _dialogSetState = null;
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (ctx) => TransactionDetailModal(
        transaction: transaction,
        onPrint: () {
          Navigator.pop(ctx);
          _showPrintDialog(transaction);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ThemeHelper.backgroundColor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          TransactionHeader(onRefresh: _refreshData),

          // Executive Summary KPI Cards
          _buildSummaryKPIs(),

          // Quick Period Filter Chips
          _buildPeriodChips(),

          // Search Bar
          _buildSearchBar(),

          const SizedBox(height: 8),

          // Transaction List / Grid
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _transactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading transactions: ${snapshot.error}',
                      style: TextStyle(color: ThemeHelper.error()),
                    ),
                  );
                }

                final transactions = snapshot.data ?? [];

                if (transactions.isEmpty) {
                  return _buildEmptyState();
                }

                final isWide = Responsive.isTablet(context) ||
                    Responsive.isDesktop(context);

                return RefreshIndicator(
                  onRefresh: () async => _refreshData(),
                  color: ThemeHelper.primaryColor(),
                  child: isWide
                      ? GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.7,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            return transactionCard(
                              transaction: tx,
                              onTap: () => _showTransactionDetails(tx),
                              onPrint: () => _showPrintDialog(tx),
                            );
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            return transactionCard(
                              transaction: tx,
                              onTap: () => _showTransactionDetails(tx),
                              onPrint: () => _showPrintDialog(tx),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryKPIs() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        final summary = snapshot.data ?? {
          'totalSales': 0.0,
          'txCount': 0,
          'totalItems': 0,
          'avgTicket': 0.0,
        };

        final double sales = (summary['totalSales'] as num?)?.toDouble() ?? 0.0;
        final double cashSales = (summary['cashSales'] as num?)?.toDouble() ?? 0.0;
        final double epaySales = (summary['epaymentSales'] as num?)?.toDouble() ?? 0.0;
        final int txCount = (summary['txCount'] as num?)?.toInt() ?? 0;
        final int items = (summary['totalItems'] as num?)?.toInt() ?? 0;
        final double avg = (summary['avgTicket'] as num?)?.toDouble() ?? 0.0;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;

              final salesCard = _buildKpiCard(
                label: 'Period Sales',
                value: Helper.formatNumberWithPeso(sales),
                color: ThemeHelper.primaryColor(),
                icon: Icons.payments_rounded,
                subtitle: 'Cash: ${Helper.formatNumberWithPeso(cashSales)} • E-Pay: ${Helper.formatNumberWithPeso(epaySales)}',
              );

              final ordersCard = _buildKpiCard(
                label: 'Transactions',
                value: '$txCount',
                color: Colors.blue.shade700,
                icon: Icons.receipt_rounded,
              );

              final itemsCard = _buildKpiCard(
                label: 'Items Sold',
                value: '$items',
                color: Colors.orange.shade800,
                icon: Icons.shopping_basket_rounded,
              );

              final avgCard = _buildKpiCard(
                label: 'Avg Ticket',
                value: Helper.formatNumberWithPeso(avg),
                color: Colors.purple.shade700,
                icon: Icons.analytics_rounded,
              );

              if (isNarrow) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: salesCard),
                        const SizedBox(width: 8),
                        Expanded(child: ordersCard),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: itemsCard),
                        const SizedBox(width: 8),
                        Expanded(child: avgCard),
                      ],
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(child: salesCard),
                    const SizedBox(width: 10),
                    Expanded(child: ordersCard),
                    const SizedBox(width: 10),
                    Expanded(child: itemsCard),
                    const SizedBox(width: 10),
                    Expanded(child: avgCard),
                  ],
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ThemeHelper.cardBackground(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ThemeHelper.textSecondary(),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: ThemeHelper.textSecondary(),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChips() {
    final periods = ['Today', 'Yesterday', 'This Week', 'This Month', 'All Time'];

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ...periods.map((p) {
            final isSelected = _selectedPeriod == p;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(p),
                selected: isSelected,
                onSelected: (_) => _applyPeriod(p),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : ThemeHelper.textPrimary(),
                ),
                selectedColor: ThemeHelper.primaryColor(),
                backgroundColor: ThemeHelper.cardBackground(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected
                        ? ThemeHelper.primaryColor()
                        : Colors.grey.withValues(alpha: 0.25),
                  ),
                ),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: Icon(
                Icons.date_range_rounded,
                size: 15,
                color: _selectedPeriod == 'Custom'
                    ? Colors.white
                    : ThemeHelper.textPrimary(),
              ),
              label: Text(
                _selectedPeriod == 'Custom' && _startDate != null && _endDate != null
                    ? '${Helper.formatDate(_startDate!)} - ${Helper.formatDate(_endDate!)}'
                    : 'Custom Range',
              ),
              onPressed: _pickCustomDateRange,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: _selectedPeriod == 'Custom'
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: _selectedPeriod == 'Custom'
                    ? Colors.white
                    : ThemeHelper.textPrimary(),
              ),
              backgroundColor: _selectedPeriod == 'Custom'
                  ? ThemeHelper.primaryColor()
                  : ThemeHelper.cardBackground(),
              side: BorderSide(
                color: _selectedPeriod == 'Custom'
                    ? ThemeHelper.primaryColor()
                    : Colors.grey.withValues(alpha: 0.25),
              ),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val.trim();
          });
          _refreshData();
        },
        decoration: InputDecoration(
          hintText: 'Search by Transaction ID (e.g. 105) or customer name...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _refreshData();
                  },
                )
              : null,
          filled: true,
          fillColor: ThemeHelper.cardBackground(),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: ThemeHelper.primaryColor(), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool hasFilter = _searchQuery.isNotEmpty || _selectedPeriod != 'Today';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeHelper.primaryColor().withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilter ? Icons.search_off : Icons.receipt_long_rounded,
                size: 54,
                color: ThemeHelper.primaryColor().withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilter
                  ? 'No transactions found for this period'
                  : 'No sales recorded today yet',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilter
                  ? 'Try selecting another date range or clearing your search.'
                  : 'Completed sales from the POS terminal will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: ThemeHelper.textSecondary()),
            ),
            if (hasFilter) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                  _applyPeriod('All Time');
                },
                icon: const Icon(Icons.filter_alt_off, size: 16),
                label: const Text('Show All Transactions'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ThemeHelper.primaryColor(),
                  side: BorderSide(color: ThemeHelper.primaryColor()),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

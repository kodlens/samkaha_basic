import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/transaction.dart';
import 'package:sales_management/models/z_report.dart';
import 'package:sales_management/services/bluetooth_print_service.dart';
import 'package:sales_management/services/user_session.dart';
import 'package:sales_management/utils/app_limits.dart';
import 'package:sales_management/utils/helper.dart';
import 'package:sales_management/utils/x_report_receipt.dart';

class XReportCard extends StatefulWidget {
  const XReportCard({super.key});

  @override
  State<XReportCard> createState() => _XReportCardState();
}

class _XReportCardState extends State<XReportCard> {
  late Future<Map<String, dynamic>> _xReportFuture;
  late Future<bool> _isClosedFuture;

  List<BluetoothInfo> _printers = [];
  BluetoothInfo? _selectedPrinter;
  bool _isScanning = false;
  bool _isPrinting = false;
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUserSession();
  }

  void _loadData() {
    _xReportFuture = Transaction().getTodaySalesBreakdown();
    _isClosedFuture = ZReport().isClosedForDate(DateTime.now());
  }

  Future<void> _loadUserSession() async {
    final user = await UserSession().loadUserSession();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
  }

  String _formatTime(String? isoStr) {
    if (isoStr == null || isoStr.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(isoStr);
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return isoStr;
    }
  }

  String _getCashierName() {
    final fname = _currentUser?['fname']?.toString().trim() ?? '';
    final lname = _currentUser?['lname']?.toString().trim() ?? '';
    final username = _currentUser?['username']?.toString() ?? '';
    final fullName = '$fname $lname'.trim();
    return fullName.isNotEmpty ? fullName : username;
  }

  XReportReceipt _createReceipt(Map<String, dynamic> data) {
    final totalSales = (data['total_sales'] as num?)?.toDouble() ?? 0.0;
    final totalPayment = (data['total_payment'] as num?)?.toDouble() ?? 0.0;
    final totalQty = (data['total_qty'] as num?)?.toDouble() ?? 0.0;
    final txCount = (data['tx_count'] as num?)?.toDouble() ?? 0.0;
    final avgTicket = (data['avg_ticket'] as num?)?.toDouble() ?? 0.0;
    final cashSales = (data['cash_sales'] as num?)?.toDouble() ?? 0.0;
    final epaymentSales = (data['epayment_sales'] as num?)?.toDouble() ?? 0.0;
    final methodBreakdown = (data['methods'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];

    return XReportReceipt(
      totalSales: totalSales,
      totalPayment: totalPayment,
      totalQty: totalQty,
      txCount: txCount,
      avgTicket: avgTicket,
      cashSales: cashSales,
      epaymentSales: epaymentSales,
      methodBreakdown: methodBreakdown,
      firstTx: data['first_tx']?.toString(),
      lastTx: data['last_tx']?.toString(),
      storeName: 'SamKaha - Basic',
      cashierName: _getCashierName(),
    );
  }

  Future<void> _startScan([StateSetter? setModalState]) async {
    _printers = [];
    _selectedPrinter = null;
    _isScanning = true;
    if (mounted) setState(() {});
    setModalState?.call(() {});

    final bluetoothEnabled = await PrintBluetoothThermal.bluetoothEnabled;
    if (!bluetoothEnabled) {
      if (!mounted) return;
      _isScanning = false;
      setState(() {});
      setModalState?.call(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable Bluetooth on your device.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final devices = await PrintBluetoothThermal.pairedBluetooths;
      _printers = devices;
      if (_printers.isNotEmpty) {
        _selectedPrinter = _printers.first;
      }
    } catch (e) {
      debugPrint('Error scanning bluetooth printers: $e');
    }

    if (!mounted) return;
    _isScanning = false;
    setState(() {});
    setModalState?.call(() {});
  }

  Future<void> _printXReport(BluetoothInfo printer, Map<String, dynamic> data) async {
    setState(() {
      _isPrinting = true;
    });

    final receipt = _createReceipt(data);
    final bytes = await receipt.buildReceiptBytes();

    try {
      final connected = await PrintBluetoothThermal.connect(
        macPrinterAddress: printer.macAdress,
      );
      if (!connected) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Printer connection failed. Please check printer power.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final result = await PrintBluetoothThermal.writeBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  result ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(result ? 'X Report printed successfully.' : 'Printing failed.'),
              ],
            ),
            backgroundColor: result ? ThemeHelper.success() : ThemeHelper.error(),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Printing error: $e'),
          backgroundColor: ThemeHelper.error(),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      try {
        await PrintBluetoothThermal.disconnect;
      } catch (_) {}
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  Future<void> _showPrintDialog(Map<String, dynamic> data) async {
    final bluetoothPrintService = BluetoothPrintService();
    final hasPermission = await bluetoothPrintService.ensureBluetoothPermissions();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bluetooth permissions are required for thermal printing.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await _startScan();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ThemeHelper.primaryColor().withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.print_rounded, color: ThemeHelper.primaryColor(), size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Print X Report',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Thermal ESC/POS receipt',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Summary Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: ThemeHelper.backgroundColor(),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Today\'s Total',
                                style: TextStyle(fontSize: 11, color: ThemeHelper.textSecondary()),
                              ),
                              Text(
                                Helper.formatNumberWithPeso((data['total_sales'] as num?)?.toDouble() ?? 0.0),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: ThemeHelper.primaryColor(),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ThemeHelper.primaryColor().withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${(data['tx_count'] as num?)?.toInt() ?? 0} txns',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: ThemeHelper.primaryColor(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Printer Selection Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Paired Printers',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: ThemeHelper.textPrimary(),
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: _isScanning ? null : () => _startScan(setDialogState),
                          icon: _isScanning
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh_rounded, size: 14),
                          label: Text(_isScanning ? 'Scanning...' : 'Rescan'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Printer list
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: ThemeHelper.backgroundColor(),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: _isScanning
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 10),
                                  Text('Looking for paired Bluetooth devices...', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            )
                          : _printers.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.print_disabled_rounded, size: 36, color: Colors.grey.shade400),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'No paired Bluetooth printers found',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Pair your 58mm printer in Android Bluetooth settings first.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 11, color: ThemeHelper.textSecondary()),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _printers.length,
                                  itemBuilder: (listCtx, idx) {
                                    final p = _printers[idx];
                                    final isSelected = _selectedPrinter?.macAdress == p.macAdress;

                                    return ListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                      leading: Icon(
                                        Icons.bluetooth_rounded,
                                        color: isSelected ? ThemeHelper.primaryColor() : Colors.grey,
                                        size: 20,
                                      ),
                                      title: Text(
                                        p.name.isNotEmpty ? p.name : 'Unknown Device',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: Text(
                                        p.macAdress,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      trailing: isSelected
                                          ? Icon(Icons.check_circle_rounded, color: ThemeHelper.primaryColor(), size: 20)
                                          : null,
                                      selected: isSelected,
                                      onTap: () {
                                        setDialogState(() {
                                          _selectedPrinter = p;
                                        });
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isPrinting ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: ThemeHelper.primaryColor(),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: (_selectedPrinter == null || _isPrinting)
                      ? null
                      : () async {
                          Navigator.pop(dialogCtx);
                          await _printXReport(_selectedPrinter!, data);
                        },
                  icon: _isPrinting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.print_rounded, size: 18),
                  label: Text(_isPrinting ? 'Printing...' : 'Print Report'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSlipPreview(Map<String, dynamic> data) {
    final receipt = _createReceipt(data);
    final textSlip = receipt.buildReceiptText();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ThemeHelper.primaryColor().withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.receipt_long_rounded, color: ThemeHelper.primaryColor(), size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Thermal Slip Preview',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Simulated Thermal Paper Slip
                Container(
                  constraints: const BoxConstraints(maxHeight: 360),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAF7), // Off-white receipt paper
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      textSlip,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11.5,
                        height: 1.4,
                        letterSpacing: 0.2,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This is how your X-Report prints on 58mm thermal paper.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: ThemeHelper.textSecondary()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy Text'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: textSlip));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('X Report receipt text copied to clipboard.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: ThemeHelper.primaryColor(),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.print_rounded, size: 18),
              label: const Text('Print Slip'),
              onPressed: () {
                Navigator.pop(dialogCtx);
                _showPrintDialog(data);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: ThemeHelper.textSecondary(),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _xReportFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final data = snapshot.data ?? {};

          final totalSales = (data['total_sales'] as num?)?.toDouble() ?? 0.0;
          final cashSales = (data['cash_sales'] as num?)?.toDouble() ?? 0.0;
          final epaymentSales = (data['epayment_sales'] as num?)?.toDouble() ?? 0.0;
          final txCount = (data['tx_count'] as num?)?.toInt() ?? 0;
          final totalQty = (data['total_qty'] as num?)?.toInt() ?? 0;
          final avgTicket = (data['avg_ticket'] as num?)?.toDouble() ?? 0.0;
          final firstTx = data['first_tx']?.toString();
          final lastTx = data['last_tx']?.toString();
          final methods = (data['methods'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ??
              [];

          return Container(
            decoration: BoxDecoration(
              color: ThemeHelper.cardBackground(),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ThemeHelper.lightPrimary().withValues(alpha: 0.45),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header with Status & Refresh
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: ThemeHelper.primaryColor().withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.analytics_rounded,
                        color: ThemeHelper.primaryColor(),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'X Report',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: ThemeHelper.textPrimary(),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.fiber_manual_record, color: Colors.green, size: 8),
                                    SizedBox(width: 4),
                                    Text(
                                      'REGISTER ACTIVE',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.green,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Real-time mid-day sales and cash drawer reading',
                            style: TextStyle(
                              fontSize: 11,
                              color: ThemeHelper.textSecondary(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh Report',
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      color: ThemeHelper.primaryColor(),
                      onPressed: _refresh,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  // 2. Hero Sales Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ThemeHelper.primaryColor().withValues(alpha: 0.12),
                          ThemeHelper.primaryColor().withValues(alpha: 0.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: ThemeHelper.primaryColor().withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TODAY\'S GROSS SALES',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: ThemeHelper.primaryColor(),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Helper.formatNumberWithPeso(totalSales),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: ThemeHelper.textPrimary(),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$txCount receipts • $totalQty items sold',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: ThemeHelper.textSecondary(),
                              ),
                            ),
                          ],
                        ),
                        if (firstTx != null || lastTx != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: ThemeHelper.cardBackground(),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Shift Time Window',
                                  style: TextStyle(fontSize: 10, color: ThemeHelper.textSecondary()),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_formatTime(firstTx)} - ${_formatTime(lastTx)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: ThemeHelper.textPrimary(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. Four-Metric Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmall = constraints.maxWidth < 420;
                      final tiles = [
                        _buildMetricTile(
                          icon: Icons.payments_rounded,
                          label: 'Cash in Register',
                          value: Helper.formatNumberWithPeso(cashSales),
                          color: const Color(0xFF16A34A), // Emerald Green
                        ),
                        _buildMetricTile(
                          icon: Icons.qr_code_scanner_rounded,
                          label: 'E-Payment Sales',
                          value: Helper.formatNumberWithPeso(epaymentSales),
                          color: const Color(0xFF2563EB), // Royal Blue
                        ),
                        _buildMetricTile(
                          icon: Icons.receipt_long_rounded,
                          label: 'Transactions',
                          value: '$txCount receipts',
                          color: const Color(0xFF7C3AED), // Violet
                        ),
                        _buildMetricTile(
                          icon: Icons.trending_up_rounded,
                          label: 'Avg Ticket',
                          value: Helper.formatNumberWithPeso(avgTicket),
                          color: const Color(0xFFD97706), // Amber
                        ),
                      ];

                      if (isSmall) {
                        return Column(
                          children: tiles
                              .map((t) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: t,
                                  ))
                              .toList(),
                        );
                      }

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: tiles[0]),
                              const SizedBox(width: 8),
                              Expanded(child: tiles[1]),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: tiles[2]),
                              const SizedBox(width: 8),
                              Expanded(child: tiles[3]),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  // 4. Payment Method Distribution (if any)
                  if (methods.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Payment Method Breakdown',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: ThemeHelper.textSecondary(),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: methods.map((m) {
                        final name = m['method']?.toString() ?? 'Other';
                        final count = (m['count'] as num?)?.toInt() ?? 0;
                        final total = (m['total'] as num?)?.toDouble() ?? 0.0;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: ThemeHelper.backgroundColor(),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            '$name ($count): ${Helper.formatNumberWithPeso(total)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ThemeHelper.textPrimary(),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // 5. Actions Footer
                  FutureBuilder<bool>(
                    future: _isClosedFuture,
                    builder: (context, closedSnap) {
                      final isClosed = closedSnap.data ?? false;

                      return LayoutBuilder(
                        builder: (context, actionConstraints) {
                          final isNarrow = actionConstraints.maxWidth < 460;

                          final previewBtn = OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ThemeHelper.textPrimary(),
                              side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _showSlipPreview(data),
                            icon: const Icon(Icons.receipt_outlined, size: 16),
                            label: const Text('Preview Slip', style: TextStyle(fontSize: 12)),
                          );

                          final printBtn = FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: ThemeHelper.primaryColor(),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _showPrintDialog(data),
                            icon: const Icon(Icons.print_rounded, size: 16),
                            label: const Text(
                              'Print X Report',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          );

                          final zCloseBtn = FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.grey.shade800,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              AppLimits.showUpgradeToProDialog(
                                context,
                                featureName: 'Z-Report (Day Close)',
                                customMessage:
                                    'End-of-day register closure (Z-Report), cash reconciliation, and permanent audit reports are available in SamKaha Pro.',
                              );
                            },
                            icon: const Icon(Icons.lock_rounded, size: 14, color: Colors.amber),
                            label: Text(
                              isClosed ? 'Day Closed (Z)' : 'Close Day (Z)',
                              style: const TextStyle(fontSize: 12),
                            ),
                          );

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: previewBtn),
                                    const SizedBox(width: 8),
                                    Expanded(child: printBtn),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                zCloseBtn,
                              ],
                            );
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              previewBtn,
                              const SizedBox(width: 8),
                              printBtn,
                              const SizedBox(width: 8),
                              zCloseBtn,
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

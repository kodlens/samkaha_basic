import 'dart:async';
import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/payment_method.dart';
import 'package:sales_management/models/transaction.dart';
import 'package:sales_management/models/transaction_details.dart';
import 'package:sales_management/services/bluetooth_print_service.dart';
import 'package:sales_management/services/user_session.dart';
import 'package:sales_management/utils/helper.dart';
import 'package:sales_management/utils/purchase_receipt.dart';

class Checkout extends StatefulWidget {
  final Function onCartCleared;
  final List<Map<String, dynamic>> cart;
  final double? totalAmount;

  const Checkout({
    super.key,
    required this.cart,
    this.totalAmount,
    required this.onCartCleared,
  });

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  final TextEditingController _paymentController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();

  List<BluetoothInfo> _printers = [];
  BluetoothInfo? _selectedPrinter;
  StateSetter? _dialogSetState;
  bool _isScanning = false;
  bool _isPrinting = false;
  bool _isCompletingPayment = false;
  Map<String, dynamic>? currentUser;

  List<Map<String, dynamic>> _paymentMethods = [
    {'name': 'Cash', 'type': 'cash'},
    {'name': 'GCash', 'type': 'e-wallet'},
    {'name': 'Maya', 'type': 'e-wallet'},
    {'name': 'Bank Transfer', 'type': 'bank'},
  ];
  String _selectedPaymentMethod = 'Cash';
  String _selectedPaymentType = 'cash';

  double get _totalAmount => widget.totalAmount ?? 0;

  double get _paymentAmount {
    final value = double.tryParse(_paymentController.text.trim());
    return value ?? 0;
  }

  double get _change =>
      (_paymentAmount - _totalAmount) > 0 ? (_paymentAmount - _totalAmount) : 0;

  double get _amountDue =>
      (_totalAmount - _paymentAmount) > 0 ? (_totalAmount - _paymentAmount) : 0;

  void _addQuickAmount(int amount) {
    final currentAmount = _paymentAmount;
    final updatedAmount = currentAmount + amount;
    setState(() {
      _paymentController.text = updatedAmount.toStringAsFixed(2);
    });
  }

  void _setExactAmount() {
    setState(() {
      _paymentController.text = _totalAmount.toStringAsFixed(2);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
    UserSession().loadUserSession().then((user) {
      if (mounted) {
        setState(() {
          currentUser = user;
        });
      }
    });
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final methods = await PaymentMethod().getActiveMethods();
      if (methods.isNotEmpty && mounted) {
        setState(() {
          _paymentMethods = methods;
          _selectedPaymentMethod = methods.first['name'] ?? 'Cash';
          _selectedPaymentType = methods.first['type'] ?? 'cash';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _paymentController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

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

  Future<void> _printReceipt(BluetoothInfo printer, int transactionId) async {
    final bytes = await PurchaseReceipt(
      transactionId: transactionId,
      cart: widget.cart,
      totalAmount: _totalAmount,
      paymentAmount: _paymentAmount,
      change: _change,
      paymentMethod: _selectedPaymentMethod,
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
    }
  }

  Future<int> saveSales() async {
    try {
      final customerName = _customerNameController.text.trim();
      final total = _totalAmount;
      final payment = _paymentAmount;

      final transactionId = await Transaction().insert({
        'user_id': currentUser?['id'] ?? 0,
        'customer_name': customerName.isEmpty ? 'Walk-in' : customerName,
        'quantity': widget.cart.fold(
          0,
          (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0),
        ),
        'payment': payment,
        'total': total,
        'payment_method': _selectedPaymentMethod,
        'timestamp': DateTime.now().toIso8601String(),
      });

      for (var item in widget.cart) {
        final productId = item['id'];
        final quantity = item['quantity'];
        final costPrice = item['cost_price'];
        final sellingPrice = item['selling_price'];
        final lineTotal = quantity * sellingPrice;
        final currentStock = item['stock'] ?? 0;

        await TransactionDetails().insert({
          'transaction_id': transactionId,
          'user_id': currentUser?['id'] ?? 0,
          'product_id': productId,
          'quantity': quantity,
          'cost_price': costPrice,
          'selling_price': sellingPrice,
          'line_total': lineTotal,
          'current_stock': currentStock,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      return transactionId;
    } catch (e) {
      debugPrint('Error saving transaction: $e');
      return 0;
    }
  }

  // --- SUCCESS ALERT POPUP ---
  Future<void> _showSuccessDialog({
    required int transactionId,
    required bool isSavedOnly,
  }) async {
    final customer = _customerNameController.text.trim().isNotEmpty
        ? _customerNameController.text.trim()
        : 'Walk-in Customer';
    final total = _totalAmount;
    final payment = _paymentAmount;
    final change = _change;
    final totalItems = widget.cart.fold(
      0,
      (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0),
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            Navigator.of(dialogCtx).pop(); // close dialog
            if (mounted) Navigator.of(context).pop(); // back to POS menu
          },
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: ThemeHelper.cardBackground(),
            contentPadding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Prominent Celebratory Green Checkmark
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 46,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Title
                  const Text(
                    'Payment Successful!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Save Only / Print Mode Notice
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSavedOnly
                          ? Colors.blue.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSavedOnly
                              ? Icons.save_outlined
                              : Icons.receipt_long_outlined,
                          size: 13,
                          color: isSavedOnly
                              ? Colors.blue.shade700
                              : Colors.green.shade800,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isSavedOnly
                              ? 'Saved to database (Save Only)'
                              : 'Saved & Receipt Printed',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isSavedOnly
                              ? Colors.blue.shade700
                              : Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Prominent Change Due Callout
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'CHANGE DUE TO CUSTOMER',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Colors.green.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Helper.formatNumberWithPeso(change > 0 ? change : 0),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Breakdown Info Table
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Transaction Number:',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: ThemeHelper.textSecondary())),
                            Text('#$transactionId',
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace')),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Payment Method:',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: ThemeHelper.textSecondary())),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: ThemeHelper.primaryColor().withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _selectedPaymentMethod,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: ThemeHelper.primaryColor(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Amount:',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: ThemeHelper.textSecondary())),
                            Text(Helper.formatNumberWithPeso(total),
                                style: const TextStyle(
                                    fontSize: 12.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedPaymentType == 'cash'
                                  ? 'Cash Received:'
                                  : 'Amount Tendered:',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: ThemeHelper.textSecondary()),
                            ),
                            Text(Helper.formatNumberWithPeso(payment),
                                style: const TextStyle(
                                    fontSize: 12.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Customer:',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: ThemeHelper.textSecondary())),
                            Text(customer,
                                style: const TextStyle(
                                    fontSize: 12.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Items:',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: ThemeHelper.textSecondary())),
                            Text('$totalItems item(s)',
                                style: const TextStyle(
                                    fontSize: 12.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // PRIMARY ACTION: Back to POS Menu
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(dialogCtx).pop(); // close dialog
                        Navigator.of(context).pop(); // back to POS menu
                      },
                      icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                      label: const Text(
                        'Back to POS Menu',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeHelper.primaryColor(),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
        );
      },
    );
  }

  // Direct Save-Only Handler from Checkout Screen
  Future<void> _handleDirectSaveOnly() async {
    if (_isCompletingPayment) return;

    if (_paymentAmount < _totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment amount cannot be less than total amount.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isCompletingPayment = true);

    try {
      final transactionId = await saveSales();
      if (!mounted) return;

      if (transactionId != 0) {
        widget.onCartCleared();
        await _showSuccessDialog(
          transactionId: transactionId,
          isSavedOnly: true,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save transaction.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCompletingPayment = false);
    }
  }

  // Complete & Print Modal Dialog
  Future<void> _showPrintDialog() async {
    final bluetoothPrintService = BluetoothPrintService();
    final hasPermission =
        await bluetoothPrintService.ensureBluetoothPermissions();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bluetooth permissions are required to print.'),
        ),
      );
      return;
    }

    await _startScan();
    if (!mounted) return;
    _dialogSetState = null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            _dialogSetState = setStateDialog;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.print_rounded),
                  SizedBox(width: 8),
                  Text('Complete & Print', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ThemeHelper.lightPrimary().withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total'),
                              Text(
                                Helper.formatNumberWithPeso(_totalAmount),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Cash Received'),
                              Text(
                                Helper.formatNumberWithPeso(_paymentAmount),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Change',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                Helper.formatNumberWithPeso(_change),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: ThemeHelper.primaryColor(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Thermal Printer',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: _isScanning ? null : _startScan,
                          icon: const Icon(Icons.refresh, size: 16),
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
                                    ? 'Scanning for printers...'
                                    : 'No printers found.',
                                style: TextStyle(color: ThemeHelper.textSecondary()),
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
                                itemBuilder: (context, index) {
                                  final printer = _printers[index];
                                  return RadioListTile<BluetoothInfo>(
                                    value: printer,
                                    title: Text(printer.name, style: const TextStyle(fontSize: 14)),
                                    subtitle: Text(printer.macAdress, style: const TextStyle(fontSize: 12)),
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
                  onPressed: _isPrinting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                OutlinedButton(
                  onPressed: _isPrinting
                      ? null
                      : () async {
                          final transactionId = await saveSales();
                          if (!mounted) return;
                          if (transactionId != 0) {
                            widget.onCartCleared();
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            await _showSuccessDialog(
                              transactionId: transactionId,
                              isSavedOnly: true,
                            );
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to save transaction.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: const Text('Save Only'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: ThemeHelper.primaryColor(),
                  ),
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: Text(_isPrinting ? 'Printing...' : 'Print Receipt'),
                  onPressed: _isPrinting
                      ? null
                      : () async {
                          if (_selectedPrinter == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a printer.'),
                              ),
                            );
                            return;
                          }

                          final transactionId = await saveSales();
                          if (!mounted) return;
                          if (transactionId != 0) {
                            setStateDialog(() => _isPrinting = true);
                            await _printReceipt(_selectedPrinter!, transactionId);

                            widget.onCartCleared();
                            if (!mounted) return;
                            setStateDialog(() => _isPrinting = false);
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }

                            await _showSuccessDialog(
                              transactionId: transactionId,
                              isSavedOnly: false,
                            );
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to save transaction.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );

    _dialogSetState = null;
  }

  Future<void> _handleCompletePayment() async {
    if (_isCompletingPayment) return;

    setState(() {
      _isCompletingPayment = true;
    });

    try {
      await _showPrintDialog();
    } finally {
      if (mounted) {
        setState(() {
          _isCompletingPayment = false;
        });
      }
    }
  }

  Widget _buildQuickAmountButton(int amount) {
    return ActionChip(
      onPressed: () => _addQuickAmount(amount),
      label: Text(
        '+₱$amount',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: ThemeHelper.primaryColor(),
        ),
      ),
      backgroundColor: ThemeHelper.lightPrimary().withValues(alpha: 0.25),
      side: BorderSide(color: ThemeHelper.primaryColor().withValues(alpha: 0.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildTotalCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: ThemeHelper.lightPrimary().withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: ThemeHelper.primaryColor().withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Amount Due',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.cart.length} unique item(s)',
                  style: TextStyle(
                    fontSize: 12,
                    color: ThemeHelper.textSecondary(),
                  ),
                ),
              ],
            ),
            Text(
              Helper.formatNumberWithPeso(_totalAmount),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: ThemeHelper.primaryColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemsList(ThemeData theme, {bool isExpanded = false}) {
    final list = ListView.separated(
      shrinkWrap: !isExpanded,
      physics: isExpanded
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: widget.cart.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (context, index) {
        final item = widget.cart[index];
        final quantity = (item['quantity'] as num?)?.toDouble() ?? 0;
        final price = (item['selling_price'] as num?)?.toDouble() ?? 0;
        final lineTotal = quantity * price;

        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: ThemeHelper.primaryColor(),
            foregroundColor: Colors.white,
            child: Text(
              Helper.formatNumber(quantity),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          title: Text(
            item['name']?.toString() ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            '${Helper.formatNumberWithPeso(price)} each',
            style: TextStyle(fontSize: 12, color: ThemeHelper.textSecondary()),
          ),
          trailing: Text(
            Helper.formatNumberWithPeso(lineTotal),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: ThemeHelper.textPrimary(),
            ),
          ),
        );
      },
    );

    return Card(
      elevation: 0,
      color: ThemeHelper.cardBackground(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: TextField(
              controller: _customerNameController,
              decoration: InputDecoration(
                labelText: 'Customer Name (Optional)',
                hintText: 'Walk-in Customer',
                prefixIcon: const Icon(Icons.person_outline),
                isDense: true,
                filled: true,
                fillColor: ThemeHelper.backgroundColor(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          isExpanded ? Expanded(child: list) : list,
        ],
      ),
    );
  }

  Widget _buildPaymentCard(ThemeData theme) {
    final bool isCash = _selectedPaymentType == 'cash';

    return Card(
      elevation: 0,
      color: ThemeHelper.cardBackground(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ThemeHelper.textPrimary(),
                  ),
                ),
                ActionChip(
                  onPressed: _setExactAmount,
                  label: const Text('Exact Amount'),
                  backgroundColor: ThemeHelper.primaryColor().withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: ThemeHelper.primaryColor(),
                  ),
                  side: BorderSide(color: ThemeHelper.primaryColor()),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Dynamic Payment Methods Selector
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _paymentMethods.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final method = _paymentMethods[index];
                  final name = method['name']?.toString() ?? 'Cash';
                  final type = method['type']?.toString() ?? 'cash';
                  final isSelected = _selectedPaymentMethod == name;

                  IconData icon;
                  if (type == 'e-wallet') {
                    icon = Icons.account_balance_wallet_outlined;
                  } else if (type == 'card') {
                    icon = Icons.credit_card_outlined;
                  } else if (type == 'bank') {
                    icon = Icons.account_balance_outlined;
                  } else {
                    icon = Icons.payments_outlined;
                  }

                  return ChoiceChip(
                    avatar: Icon(
                      icon,
                      size: 16,
                      color: isSelected ? Colors.white : ThemeHelper.primaryColor(),
                    ),
                    label: Text(name),
                    selected: isSelected,
                    selectedColor: ThemeHelper.primaryColor(),
                    backgroundColor: ThemeHelper.backgroundColor(),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: isSelected ? Colors.white : ThemeHelper.textPrimary(),
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? ThemeHelper.primaryColor()
                          : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedPaymentMethod = name;
                          _selectedPaymentType = type;
                          if (type != 'cash') {
                            _paymentController.text = _totalAmount.toStringAsFixed(2);
                          }
                        });
                      }
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // Amount Field
            TextField(
              controller: _paymentController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: isCash ? 'Cash Received' : '$_selectedPaymentMethod Amount',
                prefixText: '₱ ',
                prefixStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ThemeHelper.primaryColor(),
                ),
                filled: true,
                fillColor: ThemeHelper.backgroundColor(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: ThemeHelper.primaryColor(), width: 2),
                ),
              ),
            ),

            if (isCash) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildQuickAmountButton(20),
                  _buildQuickAmountButton(50),
                  _buildQuickAmountButton(100),
                  _buildQuickAmountButton(200),
                  _buildQuickAmountButton(500),
                  _buildQuickAmountButton(1000),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.blue.shade800),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'E-Payment via $_selectedPaymentMethod. Defaulted to exact bill.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _amountDue > 0
                    ? Colors.red.shade50
                    : ThemeHelper.lightPrimary().withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _amountDue > 0
                      ? Colors.red.shade200
                      : ThemeHelper.primaryColor().withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Remaining Due:', style: TextStyle(fontSize: 13)),
                      Text(
                        Helper.formatNumberWithPeso(_amountDue),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _amountDue > 0 ? Colors.red.shade700 : ThemeHelper.primaryColor(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Change to Return:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        Helper.formatNumberWithPeso(_change),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _change > 0 ? ThemeHelper.primaryColor() : ThemeHelper.textPrimary(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    final canComplete = _paymentAmount >= _totalAmount && !_isCompletingPayment;

    return Column(
      children: [
        // Primary: Complete & Print
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeHelper.primaryColor(),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: canComplete ? _handleCompletePayment : null,
            icon: const Icon(Icons.print_rounded, size: 20),
            label: Text(
              _isCompletingPayment ? 'Processing...' : 'Complete & Print',
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Fast Save-Only Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              backgroundColor: ThemeHelper.primaryColor().withValues(alpha: 0.12),
              foregroundColor: ThemeHelper.primaryColor(),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: canComplete ? _handleDirectSaveOnly : null,
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: const Text(
              'Save Only (Skip Printing)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Back to POS Menu Button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Back to POS Menu', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: ThemeHelper.backgroundColor(),
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: ThemeHelper.primaryColor(),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to POS Menu',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 768;

            if (isWide) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildCartItemsList(theme, isExpanded: true)),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 400,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTotalCard(theme),
                            const SizedBox(height: 14),
                            _buildPaymentCard(theme),
                            const SizedBox(height: 16),
                            _buildActions(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Mobile Layout: Fluid, scrollable, no unbounded constraints
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + MediaQuery.of(context).padding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTotalCard(theme),
                  const SizedBox(height: 14),
                  _buildPaymentCard(theme),
                  const SizedBox(height: 14),
                  _buildCartItemsList(theme, isExpanded: false),
                  const SizedBox(height: 18),
                  _buildActions(),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

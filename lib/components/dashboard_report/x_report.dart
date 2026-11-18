import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/transaction.dart';
import 'package:sales_management/models/z_report.dart';
import 'package:sales_management/services/bluetooth_print_service.dart';
import 'package:sales_management/utils/app_limits.dart';
import 'package:sales_management/utils/helper.dart';
import 'package:sales_management/utils/x_report_receipt.dart';
import 'package:sales_management/utils/z_report_receipt.dart';
import 'package:sales_management/services/user_session.dart';

class XReportCard extends StatefulWidget {
  const XReportCard({super.key});

  @override
  State<XReportCard> createState() => _XReportCardState();
}

class _XReportCardState extends State<XReportCard> {
  late Future<Map<String, double>> _xReportFuture;
  late Future<bool> _isClosedFuture;
  List<BluetoothInfo> _printers = [];
  BluetoothInfo? _selectedPrinter;
  bool _isScanning = false;
  bool _isPrinting = false;
  void Function(void Function())? _dialogSetState;
  bool _isXPrintDialogOpen = false;
  bool _isZCloseDialogOpen = false;
  bool _isClosing = false;
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _xReportFuture = Transaction().getXReportToday();
    _isClosedFuture = ZReport().isClosedForDate(DateTime.now());
    UserSession().loadUserSession().then((user) {
      if (!mounted) return;
      setState(() {
        _currentUser = user;
      });
    });
  }

  Future<void> _startScan() async {
    _printers = [];
    _selectedPrinter = null;
    _isScanning = true;
    if (mounted) setState(() {});
    if (_isXPrintDialogOpen || _isZCloseDialogOpen) {
      _dialogSetState?.call(() {});
    }

    final bluetoothEnabled = await PrintBluetoothThermal.bluetoothEnabled;
    if (!bluetoothEnabled) {
      if (!mounted) return;
      _isScanning = false;
      setState(() {});
      if (_isXPrintDialogOpen || _isZCloseDialogOpen) {
        _dialogSetState?.call(() {});
      }
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
    if (_isXPrintDialogOpen || _isZCloseDialogOpen) {
      _dialogSetState?.call(() {});
    }
  }

  Future<void> _printXReport(BluetoothInfo printer, Map<String, double> data) async {
    setState(() {
      _isPrinting = true;
    });
    if (_isXPrintDialogOpen || _isZCloseDialogOpen) {
      _dialogSetState?.call(() {});
    }

    final bytes = await XReportReceipt(
      totalSales: data['total_sales'] ?? 0.0,
      totalPayment: data['total_payment'] ?? 0.0,
      totalQty: data['total_qty'] ?? 0.0,
      txCount: data['tx_count'] ?? 0.0,
      avgTicket: data['avg_ticket'] ?? 0.0,
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
        setState(() {
          _isPrinting = false;
        });
        if (_isXPrintDialogOpen || _isZCloseDialogOpen) {
          _dialogSetState?.call(() {});
        }
      }
    }
  }

  Future<void> _printZReport(BluetoothInfo printer, Map<String, double> data) async {
    setState(() {
      _isClosing = true;
    });
    if (_isXPrintDialogOpen || _isZCloseDialogOpen) {
      _dialogSetState?.call(() {});
    }

    final closedBy = [
      _currentUser?['fname'],
      _currentUser?['lname'],
    ].where((e) => (e ?? '').toString().isNotEmpty).join(' ');

    final bytes = await ZReportReceipt(
      totalSales: data['total_sales'] ?? 0.0,
      totalPayment: data['total_payment'] ?? 0.0,
      totalQty: data['total_qty'] ?? 0.0,
      txCount: data['tx_count'] ?? 0.0,
      avgTicket: data['avg_ticket'] ?? 0.0,
      closedBy: closedBy,
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
        setState(() {
          _isClosing = false;
        });
        if (_isXPrintDialogOpen || _isZCloseDialogOpen) {
          _dialogSetState?.call(() {});
        }
      }
    }
  }

  Future<void> _showPrintDialog(Map<String, double> data) async {
    final bluetoothPrintService = BluetoothPrintService();
    final hasPermission = await bluetoothPrintService.ensureBluetoothPermissions();
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

    _isXPrintDialogOpen = true;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogCtx, setStateDialog) {
            _dialogSetState = setStateDialog;
            return AlertDialog(
              title: const Text('Print X Report'),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Sales'),
                        Text(Helper.formatNumberWithPeso(data['total_sales'] ?? 0.0)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Transactions'),
                        Text((data['tx_count'] ?? 0.0).toStringAsFixed(0)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Items Sold'),
                        Text((data['total_qty'] ?? 0.0).toStringAsFixed(0)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Select Printer'),
                        TextButton(
                          onPressed: _isScanning ? null : _startScan,
                          child: Text(_isScanning ? 'Scanning...' : 'Rescan'),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 220,
                      child: _printers.isEmpty
                          ? Center(
                              child: Text(
                                _isScanning
                                    ? 'Scanning for printers...'
                                    : 'No printers found.',
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
                                  return RadioListTile<BluetoothInfo>(
                                    value: printer,
                                    title: Text(printer.name),
                                    subtitle: Text(printer.macAdress),
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
                FilledButton(
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
                          await _printXReport(_selectedPrinter!, data);
                          if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
                            _isXPrintDialogOpen = false;
                            _dialogSetState = null;
                            Navigator.pop(dialogContext);
                          }
                        },
                  child: Text(_isPrinting ? 'Printing...' : 'Print X Report'),
                ),
              ],
            );
          },
        );
      },
    );

    _isXPrintDialogOpen = false;
    _dialogSetState = null;
  }

  Future<void> showCloseDialog(Map<String, double> data) async {
    final isClosed = await ZReport().isClosedForDate(DateTime.now());

    final bluetoothPrintService = BluetoothPrintService();
    final hasPermission = await bluetoothPrintService.ensureBluetoothPermissions();
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

    _isZCloseDialogOpen = true;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogCtx, setStateDialog) {
            _dialogSetState = setStateDialog;
            return AlertDialog(
              title: Text(isClosed ? 'Update Day (Z Report)' : 'Close Day (Z Report)'),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Sales'),
                        Text(Helper.formatNumberWithPeso(data['total_sales'] ?? 0.0)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Transactions'),
                        Text((data['tx_count'] ?? 0.0).toStringAsFixed(0)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Items Sold'),
                        Text((data['total_qty'] ?? 0.0).toStringAsFixed(0)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Select Printer'),
                        TextButton(
                          onPressed: _isScanning ? null : _startScan,
                          child: Text(_isScanning ? 'Scanning...' : 'Rescan'),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 220,
                      child: _printers.isEmpty
                          ? Center(
                              child: Text(
                                _isScanning
                                    ? 'Scanning for printers...'
                                    : 'No printers found.',
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
                                  return RadioListTile<BluetoothInfo>(
                                    value: printer,
                                    title: Text(printer.name),
                                    subtitle: Text(printer.macAdress),
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
                  onPressed: _isClosing
                      ? null
                      : () {
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: _isClosing
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

                          await _printZReport(_selectedPrinter!, data);

                          if (!mounted) return;
                          _isZCloseDialogOpen = false;
                          _dialogSetState = null;
                          final closedBy = [
                            _currentUser?['fname'],
                            _currentUser?['lname'],
                          ].where((e) => (e ?? '').toString().isNotEmpty).join(' ');

                          final didUpdate = await ZReport().upsertForDate(
                            DateTime.now(),
                            {
                            'business_date': Helper.formatDate(DateTime.now()),
                            'total_sales': data['total_sales'] ?? 0.0,
                            'total_payment': data['total_payment'] ?? 0.0,
                            'total_qty': data['total_qty'] ?? 0.0,
                            'tx_count': data['tx_count']?.toInt() ?? 0,
                            'avg_ticket': data['avg_ticket'] ?? 0.0,
                            'closed_at': DateTime.now().toIso8601String(),
                            'closed_by': closedBy,
                            },
                          );

                          if (!mounted) return;
                          setState(() {
                            _isClosedFuture = ZReport().isClosedForDate(DateTime.now());
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  didUpdate ? 'Z Report updated.' : 'Z Report closed.',
                                ),
                              ),
                            );
                          }
                          if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
                            Navigator.pop(dialogContext);
                          }
                        },
                  child: Text(
                    _isClosing
                        ? 'Closing...'
                        : (isClosed ? 'Update & Print' : 'Close & Print'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    _isZCloseDialogOpen = false;
    _dialogSetState = null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<Map<String, double>>(
        future: _xReportFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final data = snapshot.data ?? {};

          final totalSales = data['total_sales'] ?? 0.0;
          final totalPayment = data['total_payment'] ?? 0.0;
          final totalQty = data['total_qty'] ?? 0.0;
          final txCount = data['tx_count'] ?? 0.0;
          final avgTicket = data['avg_ticket'] ?? 0.0;

          return Container(
            decoration: BoxDecoration(
              color: ThemeHelper.cardBackground(),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: ThemeHelper.lightPrimary().withValues(alpha: 0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: ThemeHelper.primaryColor().withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: ThemeHelper.primaryColor().withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: ThemeHelper.primaryColor(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'X Report (Today)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: ThemeHelper.textSecondary(),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                  if (isLoading)
                    Text(
                      'Loading...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ThemeHelper.textSecondary(),
                          ),
                    )
                  else
                    FutureBuilder<bool>(
                      future: _isClosedFuture,
                      builder: (context, closedSnap) {
                        final isClosed = closedSnap.data ?? false;
                        return Column(
                          children: [
                        _row(
                          context,
                          label: 'Total Sales',
                          value: Helper.formatNumberWithPeso(totalSales),
                        ),
                        _row(
                          context,
                          label: 'Transactions',
                          value: txCount.toStringAsFixed(0),
                        ),
                        _row(
                          context,
                          label: 'Items Sold',
                          value: totalQty.toStringAsFixed(0),
                        ),
                        _row(
                          context,
                          label: 'Total Payment',
                          value: Helper.formatNumberWithPeso(totalPayment),
                        ),
                        _row(
                          context,
                          label: 'Avg Ticket',
                          value: Helper.formatNumberWithPeso(avgTicket),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: ThemeHelper.primaryColor(),
                              ),
                              onPressed: () => _showPrintDialog(data),
                              child: const Text('Print X Report'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.grey.shade700,
                              ),
                              onPressed: () {
                                AppLimits.showUpgradeToProDialog(
                                  context,
                                  featureName: 'Z-Report (Day Close)',
                                  customMessage:
                                      'End-of-day register closure (Z-Report), cash reconciliation, and permanent audit reports are available in SamKaha Pro.',
                                );
                              },
                              icon: const Icon(Icons.lock_outline, size: 16),
                              label: Text(isClosed ? 'Day Closed (Z)' : 'Close Day (Z)'),
                            ),
                          ],
                        ),
                          ],
                        );
                      },
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, {required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ThemeHelper.textSecondary(),
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ThemeHelper.textPrimary(),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sales_management/pages/admin/uom/list_uom.dart';

class UomPage extends StatefulWidget {
  const UomPage({super.key});

  @override
  State<UomPage> createState() => _UomPageState();
}

class _UomPageState extends State<UomPage> {
  DateTime? _lastBackPressed;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        final now = DateTime.now();

        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          SystemNavigator.pop(); // exit app
        }
      },
      child: ListUom(),
    );
  }
}
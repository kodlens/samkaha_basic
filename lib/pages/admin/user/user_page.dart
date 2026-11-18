import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sales_management/pages/admin/user/partials/list_user.dart';
import 'package:sales_management/components/theme_helper.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
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
      child: Container(
        color: ThemeHelper.backgroundColor(),
        child: const ListUser(),
      ),
    );
  }
}

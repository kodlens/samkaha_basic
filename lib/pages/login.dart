import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/user.dart';
import 'package:sales_management/pages/admin/admin_main_page.dart';
import 'package:sales_management/pages/user/user_home_page.dart';
import 'package:sales_management/seeder/db_seed.dart';
import 'package:sales_management/services/db_helper.dart';
import 'package:sales_management/utils/app_limits.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    initDb();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void initDb() async {
    await DBHelper.initDb();
    DBSeed().seed();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;

    return Scaffold(
      backgroundColor: ThemeHelper.backgroundColor(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 20.0 : 40.0,
              vertical: 24.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 4,
                shadowColor: ThemeHelper.primaryColor().withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                color: ThemeHelper.cardBackground(),
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 24.0 : 36.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App Brand Logo
                        Center(
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: ThemeHelper.primaryColor().withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              'assets/baligya_logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: ThemeHelper.lightPrimary().withValues(alpha: 0.35),
                                  child: Icon(
                                    Icons.point_of_sale_rounded,
                                    size: 44,
                                    color: ThemeHelper.primaryColor(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'SamKaha - Basic',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 28 : 32,
                            fontWeight: FontWeight.w900,
                            color: ThemeHelper.primaryColor(),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Point of Sale & Inventory System',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ThemeHelper.textSecondary(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: ThemeHelper.primaryColor().withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: ThemeHelper.primaryColor().withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              'Basic Edition',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: ThemeHelper.primaryColor(),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Username Field
                        TextFormField(
                          controller: usernameController,
                          textInputAction: TextInputAction.next,
                          decoration: ThemeHelper.inputDecoration(
                            'Username',
                            hint: 'Enter your username',
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: ThemeHelper.primaryColor(),
                            ),
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Please enter your username'
                                  : null,
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          decoration: ThemeHelper.inputDecoration(
                            'Password',
                            hint: 'Enter your password',
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              color: ThemeHelper.primaryColor(),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: ThemeHelper.textSecondary(),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Please enter your password'
                                  : null,
                        ),
                        const SizedBox(height: 28),

                        // Login Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ThemeHelper.primaryColor(),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                          onPressed: isLoading ? null : _login,
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _showAboutDialog,
                          icon: Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: ThemeHelper.textSecondary(),
                          ),
                          label: Text(
                            'About & Edition Limits',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: ThemeHelper.textSecondary(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final result = await User().authenticate(
        usernameController.text.trim(),
        passwordController.text,
      );

      if (!mounted) return;

      if (result['login']) {
        String userMap = json.encode({
          'id': result['id'],
          'username': result['username'],
          'fname': result['fname'],
          'mname': result['mname'],
          'lname': result['lname'],
          'role': result['role'],
          'sex': result['sex'],
        });

        await saveUserSession(userMap);
        if (!mounted) return;

        if (result['role'] == 'admin' || result['role'] == 'superadmin') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AdminMainPage()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const UserHomePage()),
          );
        }
      } else {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid username or password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> saveUserSession(String userMap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', userMap);
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ThemeHelper.primaryColor().withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline_rounded,
                color: ThemeHelper.primaryColor(),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'About SamKaha',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A lightweight, offline Point of Sale & Inventory system designed for small retail shops, cafes, and kiosks.',
                style: TextStyle(
                  fontSize: 13,
                  color: ThemeHelper.textSecondary(),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Basic Edition Limits',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildLimitRow(
                Icons.inventory_2_outlined,
                'Products',
                'Up to ${AppLimits.maxProducts} items',
              ),
              _buildLimitRow(
                Icons.category_outlined,
                'Categories',
                'Up to ${AppLimits.maxCategories} categories',
              ),
              _buildLimitRow(
                Icons.straighten_outlined,
                'Units (UOM)',
                'Up to ${AppLimits.maxUoms} units (PCS, OZ)',
              ),
              _buildLimitRow(
                Icons.badge_outlined,
                'Staff Accounts',
                '1 Admin & 1 Cashier',
              ),
              _buildLimitRow(
                Icons.receipt_long_outlined,
                'Reports',
                'X-Report (Z-Report in Pro)',
              ),
              const Divider(height: 22),
              const Text(
                'Default Sign In Accounts',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Admin: admin  |  Password: 1234',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('• Cashier: cashier  |  Password: 1234',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ThemeHelper.primaryColor(),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: ThemeHelper.primaryColor()),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
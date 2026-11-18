import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/user.dart';
import 'package:sales_management/services/user_session.dart';
import 'package:sales_management/utils/app_limits.dart';

class AddEditUser extends StatefulWidget {
  const AddEditUser({super.key, this.user, required this.onRefresh});

  final Map<String, dynamic>? user; // null for add, map for edit
  final VoidCallback onRefresh;

  @override
  State<AddEditUser> createState() => _AddEditUserState();
}

class _AddEditUserState extends State<AddEditUser> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fnameController = TextEditingController();
  final TextEditingController _mnameController = TextEditingController();
  final TextEditingController _lnameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _selectedSex;
  String? _selectedRole;
  bool _obscurePassword = true;
  bool _saving = false;

  bool get _isEdit => widget.user != null && (widget.user?['id'] ?? 0) > 0;
  int get _userId => _isEdit ? (widget.user!['id'] is int ? widget.user!['id'] : int.tryParse(widget.user!['id'].toString()) ?? 0) : 0;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    if (user != null && _userId > 0) {
      _fnameController.text = user['fname']?.toString() ?? '';
      _mnameController.text = user['mname']?.toString() ?? '';
      _lnameController.text = user['lname']?.toString() ?? '';
      _usernameController.text = user['username']?.toString() ?? '';
      _selectedSex = user['sex']?.toString().toUpperCase();
      _selectedRole = user['role']?.toString().toLowerCase();
    } else {
      _selectedSex = 'MALE';
      _selectedRole = 'cashier'; // default for new staff
    }
  }

  @override
  void dispose() {
    _fnameController.dispose();
    _mnameController.dispose();
    _lnameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final trimmedUsername = _usernameController.text.trim();
    final trimmedPassword = _passwordController.text.trim();

    setState(() {
      _saving = true;
    });

    try {
      // 1. Check if username is already taken by another account
      final isTaken = await User().isUsernameTaken(trimmedUsername, excludeId: _isEdit ? _userId : null);
      if (isTaken) {
        if (!mounted) return;
        setState(() {
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Username "$trimmedUsername" is already in use. Please choose another.'),
            backgroundColor: ThemeHelper.error(),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // 2. Role limits validation for Basic Edition
      final allUsers = await User().getUsers();
      final targetRole = _selectedRole?.toLowerCase() ?? 'cashier';

      if (!_isEdit) {
        // Adding new user: check slot availability
        final hasAdmin = allUsers.any((u) => (u['role'] ?? '').toString().toLowerCase() == 'admin');
        final hasCashier = allUsers.any((u) => (u['role'] ?? '').toString().toLowerCase() == 'cashier');

        if (allUsers.length >= (AppLimits.maxAdminAccounts + AppLimits.maxCashierAccounts)) {
          if (!mounted) return;
          setState(() {
            _saving = false;
          });
          AppLimits.showUpgradeToProDialog(
            context,
            featureName: 'User Accounts',
            customMessage: 'Basic Edition allows a maximum of 1 Admin and 1 Cashier account. Upgrade to SamKaha Pro for unlimited multi-user management.',
          );
          return;
        }

        if (targetRole == 'admin' && hasAdmin) {
          if (!mounted) return;
          setState(() {
            _saving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An Admin account already exists. Basic Edition allows 1 Admin and 1 Cashier.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        if (targetRole == 'cashier' && hasCashier) {
          if (!mounted) return;
          setState(() {
            _saving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A Cashier account already exists. Basic Edition allows 1 Admin and 1 Cashier.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      } else {
        // Editing: check role switch collision
        final currentOriginalRole = (widget.user?['role'] ?? '').toString().toLowerCase();
        if (currentOriginalRole != targetRole) {
          final countWithTargetRole = allUsers.where((u) => (u['role'] ?? '').toString().toLowerCase() == targetRole).length;
          if (targetRole == 'admin' && countWithTargetRole >= AppLimits.maxAdminAccounts) {
            if (!mounted) return;
            setState(() {
              _saving = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('An Admin account already exists. Only 1 Admin is allowed in Basic Edition.'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          if (targetRole == 'cashier' && countWithTargetRole >= AppLimits.maxCashierAccounts) {
            if (!mounted) return;
            setState(() {
              _saving = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('A Cashier account already exists. Only 1 Cashier is allowed in Basic Edition.'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
        }
      }

      // 3. Save to SQLite database
      final userData = {
        'id': _isEdit ? _userId : 0,
        'fname': _fnameController.text.trim(),
        'mname': _mnameController.text.trim(),
        'lname': _lnameController.text.trim(),
        'sex': _selectedSex,
        'role': targetRole,
        'username': trimmedUsername,
        if (!_isEdit || trimmedPassword.isNotEmpty) 'password': trimmedPassword,
      };

      await User().insertUser(userData);

      // 4. Sync session if the current logged-in user edited their own info
      final currentSession = await UserSession().loadUserSession();
      if (currentSession != null && currentSession['id'] == _userId) {
        await UserSession().saveUserSession({
          'id': _userId,
          'username': trimmedUsername,
          'fname': _fnameController.text.trim(),
          'mname': _mnameController.text.trim(),
          'lname': _lnameController.text.trim(),
          'role': targetRole,
          'sex': _selectedSex,
        });
      }

      if (!mounted) return;
      widget.onRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_isEdit ? 'User updated successfully.' : 'User account created successfully.'),
              ),
            ],
          ),
          backgroundColor: ThemeHelper.success(),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving user: $e'),
          backgroundColor: ThemeHelper.error(),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: ThemeHelper.primaryColor().withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: ThemeHelper.primaryColor(), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: ThemeHelper.textPrimary(),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: ThemeHelper.textSecondary(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeHelper.cardBackground(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeHelper.lightPrimary().withValues(alpha: 0.45),
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeHelper.backgroundColor(),
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit User' : 'New User Account',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        elevation: 0,
        backgroundColor: ThemeHelper.cardBackground(),
        foregroundColor: ThemeHelper.textPrimary(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Personal Information Card
                  _buildCardContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          icon: Icons.badge_rounded,
                          title: 'PERSONAL INFORMATION',
                          subtitle: 'Full legal name and gender for profile identity',
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _fnameController,
                                decoration: ThemeHelper.inputDecoration(
                                  'First Name *',
                                  hint: 'e.g. Juan',
                                  prefixIcon: Icon(Icons.person_outline_rounded, color: ThemeHelper.textSecondary()),
                                ),
                                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _lnameController,
                                decoration: ThemeHelper.inputDecoration(
                                  'Last Name *',
                                  hint: 'e.g. Dela Cruz',
                                  prefixIcon: Icon(Icons.person_outline_rounded, color: ThemeHelper.textSecondary()),
                                ),
                                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _mnameController,
                                decoration: ThemeHelper.inputDecoration(
                                  'Middle Name (Optional)',
                                  hint: 'e.g. Santos',
                                  prefixIcon: Icon(Icons.person_outline_rounded, color: ThemeHelper.textSecondary()),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedSex,
                                decoration: ThemeHelper.inputDecoration(
                                  'Gender *',
                                  hint: 'Select Gender',
                                  prefixIcon: Icon(Icons.wc_rounded, color: ThemeHelper.textSecondary()),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'MALE', child: Text('Male')),
                                  DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    _selectedSex = val;
                                  });
                                },
                                validator: (val) => val == null ? 'Select gender' : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Account Credentials Card
                  _buildCardContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          icon: Icons.security_rounded,
                          title: 'CREDENTIALS & ROLE',
                          subtitle: 'System login credentials and operational permissions',
                        ),
                        const SizedBox(height: 6),

                        // Username
                        TextFormField(
                          controller: _usernameController,
                          decoration: ThemeHelper.inputDecoration(
                            'Username *',
                            hint: 'e.g. cashier_juan',
                            prefixIcon: Icon(Icons.alternate_email_rounded, color: ThemeHelper.textSecondary()),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter a unique username';
                            }
                            if (value.trim().length < 3) {
                              return 'Username must be at least 3 characters';
                            }
                            if (value.trim().contains(' ')) {
                              return 'Username cannot contain spaces';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Role Selector
                        Text(
                          'System Role *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ThemeHelper.textPrimary(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _RoleCard(
                                title: 'Admin',
                                description: 'Full access to POS, inventory, reports & settings',
                                icon: Icons.admin_panel_settings_rounded,
                                isSelected: _selectedRole == 'admin',
                                activeColor: ThemeHelper.primaryColor(),
                                onTap: () {
                                  setState(() {
                                    _selectedRole = 'admin';
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _RoleCard(
                                title: 'Cashier',
                                description: 'Point of sale, register operations & shift logs',
                                icon: Icons.point_of_sale_rounded,
                                isSelected: _selectedRole == 'cashier',
                                activeColor: const Color(0xFF0D9488),
                                onTap: () {
                                  setState(() {
                                    _selectedRole = 'cashier';
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: ThemeHelper.inputDecoration(
                            _isEdit ? 'Password (Leave blank to keep existing)' : 'Password *',
                            hint: _isEdit ? '••••••••' : 'At least 4 characters',
                            prefixIcon: Icon(Icons.lock_rounded, color: ThemeHelper.textSecondary()),
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                color: ThemeHelper.textSecondary(),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (!_isEdit && (value == null || value.trim().isEmpty)) {
                              return 'Enter a password';
                            }
                            if (value != null && value.trim().isNotEmpty && value.trim().length < 4) {
                              return 'Password must be at least 4 characters';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: ThemeHelper.primaryColor(),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded, size: 20),
                    label: Text(
                      _saving
                          ? 'Saving...'
                          : (_isEdit ? 'Update User Account' : 'Save User Account'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.08) : ThemeHelper.backgroundColor(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.withValues(alpha: 0.25),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: isSelected ? activeColor : ThemeHelper.textSecondary(), size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? activeColor : ThemeHelper.textPrimary(),
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: activeColor, size: 16),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: ThemeHelper.textSecondary(),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

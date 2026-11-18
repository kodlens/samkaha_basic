import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/user.dart';

class AddEditUser extends StatefulWidget {
  const AddEditUser({super.key, this.user, required this.onRefresh});

  final Map<String, dynamic>? user; // null for add, data for edit
  final Function onRefresh;

  @override
  State<AddEditUser> createState() => _AddEditUserState();
}

class _AddEditUserState extends State<AddEditUser> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController lnameController = TextEditingController();
  final TextEditingController fnameController = TextEditingController();
  final TextEditingController mnameController = TextEditingController();
  final TextEditingController sexController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? selectedSex;
  String? selectedRole;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    if (user != null && (user['id'] ?? 0) > 0) {
      lnameController.text = user['lname'] ?? '';
      fnameController.text = user['fname'] ?? '';
      mnameController.text = user['mname'] ?? '';
      usernameController.text = user['username'] ?? '';
      selectedSex = user['sex'];
      selectedRole = user['role'];
    }
  }

  @override
  void dispose() {
    lnameController.dispose();
    fnameController.dispose();
    mnameController.dispose();
    sexController.dispose();
    roleController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add/Edit User',
          style: TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
            key: formKey,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'PERSONAL INFORMATION',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 10),
                // Last Name
                TextFormField(
                  controller: lnameController,
                  decoration: ThemeHelper.inputDecoration(
                    'Last Name',
                    hint: 'e.g. Smith',
                    prefixIcon: Icon(
                      Icons.person,
                      color: ThemeHelper.textPrimary(),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter a last name'
                      : null,
                ),
                SizedBox(height: 10),
                // First Name
                TextFormField(
                  controller: fnameController,
                  decoration: ThemeHelper.inputDecoration(
                    'First Name',
                    hint: 'e.g. John',
                    prefixIcon: Icon(
                      Icons.person,
                      color: ThemeHelper.textPrimary(),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter a first name'
                      : null,
                ),
                SizedBox(height: 10),
                // Middle Name
                TextFormField(
                  controller: mnameController,
                  decoration: ThemeHelper.inputDecoration(
                    'Middle Name',
                    hint: 'e.g. Michael',
                    prefixIcon: Icon(
                      Icons.person,
                      color: ThemeHelper.textPrimary(),
                    ),
                  ),
                ),
                SizedBox(height: 10),

                // Sex
                DropdownButtonFormField<String>(
                  initialValue: selectedSex,
                  validator: (value) => value == null ? 'Please select sex' : null,
                  decoration: ThemeHelper.inputDecoration(
                    'Sex',
                    hint: 'Select Sex',
                    prefixIcon: Icon(
                      Icons.male,
                      color: ThemeHelper.textPrimary(),
                    ),
                  ),
                  items: ['MALE', 'FEMALE'].map((sex) {
                    return DropdownMenuItem<String>(
                      value: sex,
                      child: Text(sex),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSex = value;
                    });
                  },
                ),
                SizedBox(height: 10),
                // Role
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  validator: (value) => value == null ? 'Please select a role' : null,
                  decoration: ThemeHelper.inputDecoration(
                    'Role',
                    hint: 'e.g. Admin',
                    prefixIcon: Icon(
                      Icons.admin_panel_settings,
                      color: ThemeHelper.textPrimary(),
                    ),
                  ),
                  items: ['ADMIN', 'CASHIER'].map((role) {
                    return DropdownMenuItem<String>(
                      value: role.toLowerCase(),
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value;
                    });
                  },
                ),
                SizedBox(height: 10),

                Divider(height: 50, thickness: 1),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ACCOUNT INFORMATION',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                // Username
                TextFormField(
                  controller: usernameController,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter a username'
                      : null,
                  decoration: ThemeHelper.inputDecoration(
                    'Username',
                    hint: 'e.g. john_doe',
                    prefixIcon: Icon(
                      Icons.person,
                      color: ThemeHelper.textPrimary(),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                // Password
                TextFormField(
                  controller: passwordController,
                  validator: (value) {
                    if ((widget.user?['id'] ?? 0) > 0 &&
                        (value == null || value.isEmpty)) {
                      return null; // allow blank when editing (keeps old)
                    }
                    return value == null || value.isEmpty
                        ? 'Enter a password'
                        : null;
                  },
                  decoration: ThemeHelper.inputDecoration(
                    'Password',
                    hint: (widget.user?['id'] ?? 0) > 0
                        ? 'Leave blank to keep current'
                        : 'Enter your password',
                    prefixIcon: Icon(
                      Icons.lock,
                      color: ThemeHelper.textPrimary(),
                    ),
                  ),
                  obscureText: true,
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Save logic here
                      // if (widget.onRefresh != null) {
                      //   widget.onRefresh!();
                      // }

                      if (formKey.currentState!.validate()) {
                        final isNew = widget.user == null || (widget.user?['id'] ?? 0) == 0;
                        if (isNew) {
                          final allUsers = await User().getUsers();
                          final alreadyHasRole = allUsers.any(
                            (u) => (u['role'] ?? '').toString().toLowerCase() == selectedRole?.toLowerCase(),
                          );
                          if (alreadyHasRole) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'A ${selectedRole?.toUpperCase()} account already exists. Only 1 Admin and 1 Cashier allowed.',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                        }

                        // Gather data from controllers
                        final userData = {
                          'id': widget.user != null ? widget.user!['id'] : 0,
                          'lname': lnameController.text.trim(),
                          'fname': fnameController.text.trim(),
                          'mname': mnameController.text.trim(),
                          'sex': selectedSex,
                          'role': selectedRole,
                          'username': usernameController.text.trim(),
                          'password': passwordController.text.trim(),
                        };

                        await User().insertUser(userData); // Save to database

                        if (!context.mounted) return;
                        // Call the onRefresh callback to update the user list
                        widget.onRefresh();
                        // Close the screen after saving
                        Navigator.pop(context);
                      }

                    },
                    icon: const Icon(Icons.save),
                    label: const Text('SAVE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeHelper.primaryColor(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/user.dart';
import 'package:sales_management/pages/admin/user/partials/add_edit_user.dart';
import 'package:sales_management/pages/admin/user/partials/change_password.dart';

class ListUser extends StatefulWidget {
  const ListUser({super.key});

  @override
  State<ListUser> createState() => _ListUserState();
}

class _ListUserState extends State<ListUser> {

  Future<List<Map<String, dynamic>>>? _future;


  Future<void> refreshData() async {
    setState(() {
      _future = getUsers();
    });
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    try{
      final users = await User().getUsers();
      return users;
    }catch(e) {
      debugPrint('Error fetching data: $e');
      return [];
    }
  }

  void onTapEdit(Map<String, dynamic> user) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditUser(
          user: user,
          onRefresh: refreshData,
        ),
      ),
    );
  }

  void onTapChangePassword(Map<String, dynamic> user) async {
    showDialog(
      context: context,
      builder: (context) {
        return ChangePasswordDialog(
          user: user,
          onChanged: refreshData,
        );
      },
    );
  }

  Future<void> onSubmit(Map<String, dynamic> user) async {
    // Save to DB
     await User().insertUser(user);
    // Refresh the user list
    refreshData();
  }


  void onTapDelete(Map<String, dynamic> user) async {
    // delete logic here
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete "${user['lname']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete, color: Colors.white),
              label: const Text('Delete', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await User().deleteUser(user['id']);
                if (!context.mounted) return;
                refreshData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),

            ),
          ],
        );
      },
    );
  }

  void _refreshData() {
    refreshData();
  }

  @override
  void initState() {
    super.initState();
    _future = getUsers(); 
  }


  @override
  Widget build(BuildContext context) {

    //final width = MediaQuery.of(context).size.width;


    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: ThemeHelper.cardBackground(),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ThemeHelper.lightPrimary().withValues(alpha: 0.45)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Users',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ThemeHelper.textPrimary(),
                      ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: ThemeHelper.primaryColor(),
                  ),
                  onPressed: () async {
                    final currentUsers = await getUsers();
                    final hasAdmin = currentUsers.any((u) => u['role']?.toString().toLowerCase() == 'admin');
                    final hasCashier = currentUsers.any((u) => u['role']?.toString().toLowerCase() == 'cashier');
                    if (currentUsers.length >= 2 || (hasAdmin && hasCashier)) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Maximum of 1 Admin and 1 Cashier account allowed in this version.',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditUser(onRefresh: refreshData),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add User'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No users found.'));
              } else {
                final users = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: () async {
                    _refreshData();
                  },
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final fullName =
                          '${user['lname']}, ${user['fname']} ${user['mname'] ?? ''}'.trim();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ThemeHelper.cardBackground(),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: ThemeHelper.lightPrimary().withValues(alpha: 0.45),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: ThemeHelper.lightPrimary(),
                              child: Text(
                                fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: ThemeHelper.primaryColor(),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: ThemeHelper.textPrimary(),
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user['role'].toString().toUpperCase(),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: ThemeHelper.textSecondary(),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, color: ThemeHelper.info()),
                              onPressed: () => onTapEdit(user),
                            ),
                            IconButton(
                              icon: Icon(Icons.lock_reset, color: ThemeHelper.primaryColor()),
                              onPressed: () => onTapChangePassword(user),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: ThemeHelper.error()),
                              onPressed: () => onTapDelete(user),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}


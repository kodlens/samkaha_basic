import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/user.dart';
import 'package:sales_management/pages/admin/user/partials/add_edit_user.dart';
import 'package:sales_management/pages/admin/user/partials/change_password.dart';
import 'package:sales_management/services/user_session.dart';
import 'package:sales_management/utils/app_limits.dart';

class ListUser extends StatefulWidget {
  const ListUser({super.key});

  @override
  State<ListUser> createState() => _ListUserState();
}

class _ListUserState extends State<ListUser> {
  Future<List<Map<String, dynamic>>>? _future;
  Map<String, dynamic>? _currentUser;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRoleFilter = 'all'; // 'all', 'admin', 'cashier'

  @override
  void initState() {
    super.initState();
    _loadCurrentSession();
    _future = getUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentSession() async {
    final session = await UserSession().loadUserSession();
    if (mounted) {
      setState(() {
        _currentUser = session;
      });
    }
  }

  Future<void> refreshData() async {
    await _loadCurrentSession();
    setState(() {
      _future = getUsers();
    });
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final users = await User().getUsers();
      return users;
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  void onTapAddUser(List<Map<String, dynamic>> currentUsers) {
    final hasAdmin = currentUsers.any((u) => u['role']?.toString().toLowerCase() == 'admin');
    final hasCashier = currentUsers.any((u) => u['role']?.toString().toLowerCase() == 'cashier');
    final totalSlots = AppLimits.maxAdminAccounts + AppLimits.maxCashierAccounts;

    if (currentUsers.length >= totalSlots || (hasAdmin && hasCashier)) {
      AppLimits.showUpgradeToProDialog(
        context,
        featureName: 'User Accounts',
        customMessage:
            'You have reached the Basic Edition limit of 1 Admin and 1 Cashier account. Upgrade to SamKaha Pro for unlimited accounts and staff management.',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditUser(onRefresh: refreshData),
      ),
    );
  }

  void onTapEdit(Map<String, dynamic> user) {
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

  void onTapChangePassword(Map<String, dynamic> user) {
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

  void onTapDelete(Map<String, dynamic> user, List<Map<String, dynamic>> allUsers) {
    final userId = user['id'] is int ? user['id'] as int : int.tryParse(user['id'].toString()) ?? 0;
    final currentSessionId = _currentUser?['id'] is int
        ? _currentUser!['id'] as int
        : int.tryParse(_currentUser?['id']?.toString() ?? '0') ?? 0;

    // 1. Prevent deleting self
    if (userId > 0 && userId == currentSessionId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete your own active session account.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 2. Prevent deleting the last remaining admin
    final role = (user['role']?.toString() ?? '').toLowerCase();
    if (role == 'admin') {
      final adminCount = allUsers.where((u) => (u['role']?.toString() ?? '').toLowerCase() == 'admin').length;
      if (adminCount <= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot delete the only Administrator account. At least one Admin is required.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final fname = user['fname']?.toString().trim() ?? '';
    final lname = user['lname']?.toString().trim() ?? '';
    final fullName = '$fname $lname'.trim().isNotEmpty ? '$fname $lname' : (user['username'] ?? 'User');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Delete Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to permanently delete "$fullName"?',
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This user will lose access to the system immediately.',
                        style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.delete_rounded, size: 18),
              label: const Text('Delete'),
              onPressed: () async {
                Navigator.pop(ctx);
                await User().deleteUser(userId);
                if (!mounted) return;
                refreshData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Account "$fullName" deleted successfully.'),
                    backgroundColor: Colors.black87,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ThemeHelper.cardBackground(),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
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
                    color: ThemeHelper.textSecondary(),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required int count,
  }) {
    final isSelected = _selectedRoleFilter == value;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedRoleFilter = value;
          });
        }
      },
      selectedColor: ThemeHelper.primaryColor().withValues(alpha: 0.16),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? ThemeHelper.primaryColor() : ThemeHelper.textSecondary(),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? ThemeHelper.primaryColor() : Colors.grey.withValues(alpha: 0.25),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text('Failed to load users: ${snapshot.error}'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: refreshData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final allUsers = snapshot.data ?? [];
        final adminCount = allUsers.where((u) => (u['role']?.toString() ?? '').toLowerCase() == 'admin').length;
        final cashierCount = allUsers.where((u) => (u['role']?.toString() ?? '').toLowerCase() == 'cashier').length;
        final currentSessionId = _currentUser?['id'] is int
            ? _currentUser!['id'] as int
            : int.tryParse(_currentUser?['id']?.toString() ?? '0') ?? 0;

        // Apply filters
        final filteredUsers = allUsers.where((user) {
          final role = (user['role']?.toString() ?? '').toLowerCase();
          if (_selectedRoleFilter != 'all' && role != _selectedRoleFilter) {
            return false;
          }

          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final fname = (user['fname']?.toString() ?? '').toLowerCase();
            final lname = (user['lname']?.toString() ?? '').toLowerCase();
            final mname = (user['mname']?.toString() ?? '').toLowerCase();
            final username = (user['username']?.toString() ?? '').toLowerCase();
            final matchName = '$fname $mname $lname'.contains(query) || '$lname $fname'.contains(query);
            final matchUsername = username.contains(query);
            final matchRole = role.contains(query);
            if (!matchName && !matchUsername && !matchRole) {
              return false;
            }
          }

          return true;
        }).toList();

        return RefreshIndicator(
          onRefresh: refreshData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // 1. Header Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ThemeHelper.primaryColor(), const Color(0xFF2E6B3E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeHelper.primaryColor().withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 580;
                    final titleSection = Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.manage_accounts_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'User Management',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Manage system administrators and cashier staff',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    final addButton = FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: ThemeHelper.primaryColor(),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => onTapAddUser(allUsers),
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: const Text(
                        'Add User',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    );

                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          titleSection,
                          const SizedBox(height: 14),
                          addButton,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: titleSection),
                        const SizedBox(width: 12),
                        addButton,
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              // 2. Summary KPI Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 600;
                  final cards = [
                    _buildStatCard(
                      icon: Icons.group_rounded,
                      label: 'Total Accounts',
                      value: '${allUsers.length} / 2 Slots',
                      color: ThemeHelper.primaryColor(),
                    ),
                    _buildStatCard(
                      icon: Icons.admin_panel_settings_rounded,
                      label: 'Administrators',
                      value: '$adminCount / 1 Active',
                      color: const Color(0xFF4F46E5), // Indigo
                    ),
                    _buildStatCard(
                      icon: Icons.point_of_sale_rounded,
                      label: 'Cashiers',
                      value: '$cashierCount / 1 Active',
                      color: const Color(0xFF0D9488), // Teal
                    ),
                  ];

                  if (isNarrow) {
                    return Column(
                      children: cards
                          .map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: c,
                              ))
                          .toList(),
                    );
                  }

                  return Row(
                    children: cards
                        .map((c) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: c,
                              ),
                            ))
                        .toList(),
                  );
                },
              ),

              const SizedBox(height: 14),

              // 3. Search and Role Filter Chips
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ThemeHelper.cardBackground(),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ThemeHelper.lightPrimary().withValues(alpha: 0.45)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name, @username, or role...',
                        hintStyle: TextStyle(fontSize: 13, color: ThemeHelper.textSecondary()),
                        prefixIcon: Icon(Icons.search_rounded, color: ThemeHelper.textSecondary(), size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        isDense: true,
                        filled: true,
                        fillColor: ThemeHelper.backgroundColor(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildFilterChip(label: 'All', value: 'all', count: allUsers.length),
                        _buildFilterChip(label: 'Admins', value: 'admin', count: adminCount),
                        _buildFilterChip(label: 'Cashiers', value: 'cashier', count: cashierCount),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 4. User List or Empty State
              if (filteredUsers.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: ThemeHelper.cardBackground(),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ThemeHelper.lightPrimary().withValues(alpha: 0.45)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.people_outline_rounded,
                          size: 48,
                          color: ThemeHelper.textSecondary().withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No users match "$_searchQuery"'
                              : 'No users found.',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: ThemeHelper.textPrimary(),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try adjusting your search terms or filter'
                              : 'Add user accounts to grant staff access.',
                          style: TextStyle(
                            fontSize: 12,
                            color: ThemeHelper.textSecondary(),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedRoleFilter = 'all';
                              });
                            },
                            icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                            label: const Text('Reset Filters'),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                ...filteredUsers.map((user) {
                  final userId = user['id'] is int ? user['id'] as int : int.tryParse(user['id'].toString()) ?? 0;
                  final fname = user['fname']?.toString().trim() ?? '';
                  final lname = user['lname']?.toString().trim() ?? '';
                  final mname = user['mname']?.toString().trim() ?? '';
                  final username = user['username']?.toString() ?? '';
                  final role = (user['role']?.toString() ?? 'user').toLowerCase();
                  final sex = (user['sex']?.toString() ?? '').toUpperCase();
                  final isCurrentUser = userId > 0 && userId == currentSessionId;
                  final isAdmin = role == 'admin';

                  final fullName = [
                    if (lname.isNotEmpty) '$lname,',
                    fname,
                    if (mname.isNotEmpty) mname,
                  ].join(' ').trim();

                  final displayName = fullName.isNotEmpty ? fullName : username;
                  final roleColor = isAdmin ? const Color(0xFF4F46E5) : const Color(0xFF0D9488);
                  final roleIcon = isAdmin ? Icons.admin_panel_settings_rounded : Icons.point_of_sale_rounded;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ThemeHelper.cardBackground(),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCurrentUser
                            ? ThemeHelper.primaryColor().withValues(alpha: 0.6)
                            : ThemeHelper.lightPrimary().withValues(alpha: 0.45),
                        width: isCurrentUser ? 1.5 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: roleColor.withValues(alpha: 0.14),
                              child: Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: roleColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: roleColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: Icon(roleIcon, color: Colors.white, size: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),

                        // User Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      displayName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: ThemeHelper.textPrimary(),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isCurrentUser) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: ThemeHelper.primaryColor().withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: ThemeHelper.primaryColor().withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Text(
                                        'YOU',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: ThemeHelper.primaryColor(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  // Username pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: ThemeHelper.backgroundColor(),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '@$username',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: ThemeHelper.textSecondary(),
                                      ),
                                    ),
                                  ),
                                  // Role badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: roleColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      role.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: roleColor,
                                      ),
                                    ),
                                  ),
                                  // Gender badge
                                  if (sex.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        sex == 'MALE' ? 'Male' : 'Female',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: ThemeHelper.textSecondary(),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Action Buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit Profile',
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              color: ThemeHelper.info(),
                              onPressed: () => onTapEdit(user),
                            ),
                            IconButton(
                              tooltip: 'Change Password',
                              icon: const Icon(Icons.lock_reset_rounded, size: 20),
                              color: ThemeHelper.primaryColor(),
                              onPressed: () => onTapChangePassword(user),
                            ),
                            IconButton(
                              tooltip: isCurrentUser ? 'Cannot delete your active account' : 'Delete Account',
                              icon: const Icon(Icons.delete_outline_rounded, size: 20),
                              color: isCurrentUser ? Colors.grey.withValues(alpha: 0.4) : ThemeHelper.error(),
                              onPressed: isCurrentUser ? null : () => onTapDelete(user, allUsers),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

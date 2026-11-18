import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/adjustment.dart';
import 'package:sales_management/pages/admin/adjustment/partials/adjustment_card.dart';
import 'package:sales_management/pages/admin/adjustment/partials/adjustment_detail_dialog.dart';
import 'package:sales_management/pages/admin/adjustment/partials/adjustment_header.dart';
import 'package:sales_management/services/user_session.dart';
import 'package:sales_management/utils/responsive.dart';

class ListAdjustment extends StatefulWidget {
  const ListAdjustment({super.key});

  @override
  State<ListAdjustment> createState() => _ListAdjustmentState();
}

class _ListAdjustmentState extends State<ListAdjustment> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedAction = 'All'; // 'All', 'IN', 'OUT', 'AUDIT'

  Future<List<Map<String, dynamic>>>? _logsFuture;
  Future<Map<String, int>>? _summaryFuture;

  @override
  void initState() {
    super.initState();
    UserSession().loadUserSession();
    _refreshAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshAll() {
    setState(() {
      _logsFuture = Adjustment().getAdjustmentsLogs(
        _searchQuery,
        _selectedAction,
      );
      _summaryFuture = Adjustment().getAdjustmentSummary();
    });
  }

  void _showDetailDialog(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (ctx) => AdjustmentDetailDialog(log: log),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ThemeHelper.backgroundColor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          AdjustmentHeader(onRefresh: _refreshAll),

          // Executive Summary KPI Cards
          _buildSummaryKPIs(),

          // Real-time Search Input
          _buildSearchBar(),

          // Action Type Filter Chips
          _buildActionChips(),

          const SizedBox(height: 8),

          // Adjustment Logs List / Grid
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _logsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading logs: ${snapshot.error}',
                      style: TextStyle(color: ThemeHelper.error()),
                    ),
                  );
                }

                final logs = snapshot.data ?? [];

                if (logs.isEmpty) {
                  return _buildEmptyState();
                }

                final isWide = Responsive.isTablet(context) ||
                    Responsive.isDesktop(context);

                return RefreshIndicator(
                  onRefresh: () async => _refreshAll(),
                  color: ThemeHelper.primaryColor(),
                  child: isWide
                      ? GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.7,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            return adjustmentCard(
                              log: log,
                              onTap: () => _showDetailDialog(log),
                            );
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            return adjustmentCard(
                              log: log,
                              onTap: () => _showDetailDialog(log),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryKPIs() {
    return FutureBuilder<Map<String, int>>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        final summary = snapshot.data ?? {
          'total': 0,
          'inCount': 0,
          'outCount': 0,
          'auditCount': 0,
        };

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;

              final totalCard = _buildKpiCard(
                label: 'Total Logs',
                value: '${summary['total'] ?? 0}',
                color: ThemeHelper.primaryColor(),
                icon: Icons.history_rounded,
                isActive: _selectedAction == 'All',
                onTap: () {
                  setState(() {
                    _selectedAction = 'All';
                    _logsFuture = Adjustment().getAdjustmentsLogs(
                      _searchQuery,
                      _selectedAction,
                    );
                  });
                },
              );

              final inCard = _buildKpiCard(
                label: 'Stock In',
                value: '${summary['inCount'] ?? 0}',
                color: Colors.green.shade700,
                icon: Icons.add_circle_outline,
                isActive: _selectedAction == 'IN',
                onTap: () {
                  setState(() {
                    _selectedAction = 'IN';
                    _logsFuture = Adjustment().getAdjustmentsLogs(
                      _searchQuery,
                      _selectedAction,
                    );
                  });
                },
              );

              final outCard = _buildKpiCard(
                label: 'Stock Out',
                value: '${summary['outCount'] ?? 0}',
                color: Colors.orange.shade800,
                icon: Icons.remove_circle_outline,
                isActive: _selectedAction == 'OUT',
                onTap: () {
                  setState(() {
                    _selectedAction = 'OUT';
                    _logsFuture = Adjustment().getAdjustmentsLogs(
                      _searchQuery,
                      _selectedAction,
                    );
                  });
                },
              );

              final auditCard = _buildKpiCard(
                label: 'Audits',
                value: '${summary['auditCount'] ?? 0}',
                color: Colors.blue.shade700,
                icon: Icons.fact_check_outlined,
                isActive: _selectedAction == 'AUDIT',
                onTap: () {
                  setState(() {
                    _selectedAction = 'AUDIT';
                    _logsFuture = Adjustment().getAdjustmentsLogs(
                      _searchQuery,
                      _selectedAction,
                    );
                  });
                },
              );

              if (isNarrow) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: totalCard),
                        const SizedBox(width: 8),
                        Expanded(child: inCard),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: outCard),
                        const SizedBox(width: 8),
                        Expanded(child: auditCard),
                      ],
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(child: totalCard),
                    const SizedBox(width: 10),
                    Expanded(child: inCard),
                    const SizedBox(width: 10),
                    Expanded(child: outCard),
                    const SizedBox(width: 10),
                    Expanded(child: auditCard),
                  ],
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.12)
              : ThemeHelper.cardBackground(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : Colors.grey.withValues(alpha: 0.2),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
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
                      fontWeight: FontWeight.w600,
                      color: ThemeHelper.textSecondary(),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val.trim();
            _logsFuture = Adjustment().getAdjustmentsLogs(
              _searchQuery,
              _selectedAction,
            );
          });
        },
        decoration: InputDecoration(
          hintText: 'Search by product name, staff, or reason...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _logsFuture = Adjustment().getAdjustmentsLogs(
                        _searchQuery,
                        _selectedAction,
                      );
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: ThemeHelper.cardBackground(),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: ThemeHelper.primaryColor(), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildActionChips() {
    final actions = [
      {'key': 'All', 'label': 'All Actions'},
      {'key': 'IN', 'label': 'Stock In (+)'},
      {'key': 'OUT', 'label': 'Stock Out (-)'},
      {'key': 'AUDIT', 'label': 'Physical Audit (=)'},
    ];

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final item = actions[index];
          final key = item['key']!;
          final label = item['label']!;
          final isSelected = _selectedAction == key;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedAction = key;
                    _logsFuture = Adjustment().getAdjustmentsLogs(
                      _searchQuery,
                      _selectedAction,
                    );
                  });
                }
              },
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : ThemeHelper.textPrimary(),
              ),
              selectedColor: ThemeHelper.primaryColor(),
              backgroundColor: ThemeHelper.cardBackground(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected
                      ? ThemeHelper.primaryColor()
                      : Colors.grey.withValues(alpha: 0.25),
                ),
              ),
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool hasFilter =
        _searchQuery.isNotEmpty || _selectedAction != 'All';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeHelper.primaryColor().withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilter ? Icons.search_off : Icons.history_rounded,
                size: 54,
                color: ThemeHelper.primaryColor().withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilter
                  ? 'No adjustment logs match your query'
                  : 'No stock adjustments recorded yet',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilter
                  ? 'Try searching with another keyword or resetting the filter.'
                  : 'Perform inventory stock adjustments to view the audit history here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: ThemeHelper.textSecondary()),
            ),
            if (hasFilter) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedAction = 'All';
                    _logsFuture = Adjustment().getAdjustmentsLogs();
                  });
                },
                icon: const Icon(Icons.filter_alt_off, size: 16),
                label: const Text('Reset All Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ThemeHelper.primaryColor(),
                  side: BorderSide(color: ThemeHelper.primaryColor()),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

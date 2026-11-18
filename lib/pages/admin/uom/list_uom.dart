import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/uom.dart';
import 'package:sales_management/pages/admin/uom/partials/add_edit_uom_dialog.dart';
import 'package:sales_management/utils/app_limits.dart';

class ListUom extends StatefulWidget {
  const ListUom({super.key});

  @override
  State<ListUom> createState() => _ListUomState();
}

class _ListUomState extends State<ListUom> {
  Future<List<Map<String, dynamic>>>? _future;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      _future = Uom().getUomsWithProductCount();
    });
  }

  void _openAddEditUom([Map<String, dynamic>? uom]) async {
    final isNew = uom == null || (uom['id'] ?? 0) == 0;
    if (isNew) {
      final uoms = await Uom().getUoms();
      if (uoms.length >= AppLimits.maxUoms) {
        if (!mounted) return;
        AppLimits.showUpgradeToProDialog(
          context,
          featureName: 'Units of Measure',
          customMessage:
              'You have reached the maximum limit of ${AppLimits.maxUoms} units in the Basic Edition.',
        );
        return;
      }
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddEditUomDialog(
        uom: uom,
        onSaved: _refreshData,
      ),
    );
  }

  Future<void> _onTapDelete(Map<String, dynamic> uom) async {
    final int uomId = (uom['id'] as num?)?.toInt() ?? 0;
    final String uomName = uom['uom']?.toString() ?? '';
    final int productCount = (uom['product_count'] as num?)?.toInt() ?? 0;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.delete_forever, color: Colors.red.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Delete Unit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete unit "$uomName"?',
              style: const TextStyle(fontSize: 14),
            ),
            if (productCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$productCount product(s) are currently configured with "$uomName". Deleting it will leave these products without a valid unit.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Delete Unit', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Uom().deleteUom(uomId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unit "$uomName" deleted.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      _refreshData();
    }
  }

  Color _getUnitColor(String name) {
    const colors = [
      Color(0xFF0D9488), // Teal
      Color(0xFF2563EB), // Blue
      Color(0xFF7C3AED), // Purple
      Color(0xFF1F4D2B), // Forest Green
      Color(0xFFD97706), // Amber
      Color(0xFFE11D48), // Rose
      Color(0xFF0891B2), // Cyan
    ];
    if (name.isEmpty) return colors.first;
    final hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    return colors[hash % colors.length];
  }

  Widget _buildSummaryMetrics(List<Map<String, dynamic>> allUoms) {
    final totalUnits = allUoms.length;
    final totalProducts = allUoms.fold<int>(
      0,
      (sum, item) => sum + ((item['product_count'] as num?)?.toInt() ?? 0),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.straighten_rounded, size: 20, color: ThemeHelper.primaryColor()),
          const SizedBox(width: 8),
          Text(
            '$totalUnits Defined Units',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 16, color: Colors.grey.shade300),
          const SizedBox(width: 12),
          Icon(Icons.inventory_2_outlined, size: 20, color: ThemeHelper.textSecondary()),
          const SizedBox(width: 8),
          Text(
            '$totalProducts Products Configured',
            style: TextStyle(
              fontSize: 13,
              color: ThemeHelper.textSecondary(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUomCard(Map<String, dynamic> uom) {
    final name = uom['uom']?.toString() ?? '';
    final productCount = (uom['product_count'] as num?)?.toInt() ?? 0;
    final color = _getUnitColor(name);

    final abbreviation = name.length <= 3
        ? name.toUpperCase()
        : name.substring(0, 2).toUpperCase();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openAddEditUom(uom),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Abbreviation Symbol Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Center(
                  child: Text(
                    abbreviation,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title and Product Count Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: productCount > 0
                            ? ThemeHelper.lightPrimary().withValues(alpha: 0.25)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        productCount == 1 ? '1 Product' : '$productCount Products',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: productCount > 0
                              ? ThemeHelper.primaryColor()
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: 'Edit Unit',
                    child: IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: ThemeHelper.primaryColor(),
                      style: IconButton.styleFrom(
                        backgroundColor: ThemeHelper.lightPrimary().withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _openAddEditUom(uom),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Delete Unit',
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red.shade600,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _onTapDelete(uom),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 750;

    return Container(
      color: ThemeHelper.backgroundColor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Title & "+ New Unit" button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: ThemeHelper.cardBackground(),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;

                final titleSection = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Units of Measure',
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 22,
                        fontWeight: FontWeight.bold,
                        color: ThemeHelper.textPrimary(),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Configure packaging units for product inventory and sales',
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeHelper.textSecondary(),
                      ),
                    ),
                  ],
                );

                final createButton = ElevatedButton.icon(
                  onPressed: () => _openAddEditUom(),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text(
                    'New Unit',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeHelper.primaryColor(),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                  ),
                );

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      titleSection,
                      const SizedBox(height: 12),
                      createButton,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: titleSection),
                    const SizedBox(width: 16),
                    createButton,
                  ],
                );
              },
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() => _query = val.trim().toLowerCase());
              },
              decoration: InputDecoration(
                hintText: 'Search units (e.g. piece, kg, box)...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),

          // UOM List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final uoms = snapshot.data ?? [];
                final filtered = _query.isEmpty
                    ? uoms
                    : uoms.where((uom) {
                        final name = (uom['uom']?.toString() ?? '').toLowerCase();
                        return name.contains(_query);
                      }).toList();

                if (uoms.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.straighten_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No Units of Measure Yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add units (e.g. Piece, Box, Kg) to specify product sales measurements',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: ThemeHelper.textSecondary(),
                            ),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed: () => _openAddEditUom(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ThemeHelper.primaryColor(),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text(
                              'Add First Unit',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 54,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No units match "$_query"',
                            style: TextStyle(
                              color: ThemeHelper.textSecondary(),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            child: const Text('Clear search'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSummaryMetrics(uoms),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async => _refreshData(),
                        child: isWide
                            ? GridView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 3.4,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) =>
                                    _buildUomCard(filtered[index]),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) =>
                                    _buildUomCard(filtered[index]),
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

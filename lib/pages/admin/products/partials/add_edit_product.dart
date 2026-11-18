import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/category.dart';
import 'package:sales_management/models/product.dart';
import 'package:sales_management/models/uom.dart';
import 'package:sales_management/services/barcode_scanner_service.dart';
import 'package:sales_management/utils/app_limits.dart';
import 'package:sales_management/utils/helper.dart';

class AddEditProduct extends StatefulWidget {
  final Map<String, dynamic>? product; // null for add, non-null for edit
  final VoidCallback onRefresh;

  const AddEditProduct({
    super.key,
    required this.product,
    required this.onRefresh,
  });

  @override
  State<AddEditProduct> createState() => _AddEditProductState();
}

class _AddEditProductState extends State<AddEditProduct> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _lowStockController;

  File? _selectedImage;
  int? _selectedImageSize;
  String? _existingImagePath;
  final ImagePicker _picker = ImagePicker();

  /// Maximum allowed product image file size (1 MB)
  static const int maxImageSizeBytes = 1024 * 1024;

  String? _selectedCategory;
  String? _selectedUnit;

  List<String> _categories = [];
  List<String> _uoms = [];

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final p = widget.product;
    _nameController = TextEditingController(text: p?['name']?.toString() ?? '');
    _barcodeController =
        TextEditingController(text: p?['barcode']?.toString() ?? '');
    _costPriceController =
        TextEditingController(text: p?['cost_price']?.toString() ?? '');
    _sellingPriceController =
        TextEditingController(text: p?['selling_price']?.toString() ?? '');
    _lowStockController = TextEditingController(
      text: p?['low_stock_level']?.toString() ?? '5',
    );

    _selectedCategory = p?['category']?.toString();
    _selectedUnit = p?['unit']?.toString();

    _existingImagePath = p?['image_path']?.toString();
    if (_existingImagePath != null && _existingImagePath!.isNotEmpty) {
      final file = File(_existingImagePath!);
      if (file.existsSync()) {
        _selectedImage = file;
        _selectedImageSize = file.lengthSync();
      }
    }

    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final catList = await Category().getCategories();
      final uomList = await Uom().getUoms();

      if (!mounted) return;

      setState(() {
        _categories = catList
            .map((c) => c['category']?.toString() ?? '')
            .where((s) => s.isNotEmpty && s != 'All')
            .toList();

        _uoms = uomList
            .map((u) => u['uom']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();

        // Ensure category selection is valid
        if (_selectedCategory == null || !_categories.contains(_selectedCategory)) {
          _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
        }

        // Ensure unit selection is valid
        if (_selectedUnit == null || !_uoms.contains(_selectedUnit)) {
          _selectedUnit = _uoms.isNotEmpty ? _uoms.first : 'PC';
        }

        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _generateBarcode() {
    final random = Random();
    // Generate a clean 12-digit UPC/EAN style random barcode
    final digits = List.generate(12, (_) => random.nextInt(10)).join();
    setState(() {
      _barcodeController.text = digits;
    });
  }

  Future<void> _scanBarcode() async {
    final code = await BarcodeScannerService.scanBarcode(
      context,
      title: 'Scan Product Barcode',
      instruction: 'Scan the barcode on the product packaging',
    );

    if (code != null && code.isNotEmpty && mounted) {
      setState(() {
        _barcodeController.text = code;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barcode captured: $code'),
          backgroundColor: ThemeHelper.primaryColor(),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();

        if (fileSize > maxImageSizeBytes) {
          if (mounted) {
            final formattedSize = _formatFileSize(fileSize);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Image exceeds the 1 MB limit ($formattedSize). Please select a smaller photo.',
                ),
                backgroundColor: ThemeHelper.error(),
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedImage = file;
          _selectedImageSize = fileSize;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Product Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                'Max allowed size: 1 MB',
                style: TextStyle(fontSize: 12, color: ThemeHelper.textSecondary()),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove Photo',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _selectedImage = null;
                      _selectedImageSize = null;
                      _existingImagePath = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddCategoryDialog() async {
    final catList = await Category().getCategories();
    final realCats = catList.where((c) => (c['category'] ?? '') != 'All').toList();
    if (realCats.length >= AppLimits.maxCategories) {
      if (!mounted) return;
      AppLimits.showUpgradeToProDialog(
        context,
        featureName: 'Categories',
        customMessage:
            'You have reached the maximum limit of ${AppLimits.maxCategories} categories in the Basic Edition.',
      );
      return;
    }

    if (!mounted) return;
    final catController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Category'),
        content: TextField(
          controller: catController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g. Pastries, Cold Brew',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeHelper.primaryColor(),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final val = catController.text.trim();
              if (val.isNotEmpty) Navigator.pop(ctx, val);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await Category().insertCategory({'id': 0, 'category': result});
      await _loadData();
      setState(() => _selectedCategory = result);
    }
  }

  Future<void> _showAddUomDialog() async {
    final uomList = await Uom().getUoms();
    if (uomList.length >= AppLimits.maxUoms) {
      if (!mounted) return;
      AppLimits.showUpgradeToProDialog(
        context,
        featureName: 'Units of Measure',
        customMessage:
            'You have reached the maximum limit of ${AppLimits.maxUoms} units in the Basic Edition.',
      );
      return;
    }

    if (!mounted) return;
    final uomController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Unit of Measurement'),
        content: TextField(
          controller: uomController,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Unit Abbreviation / Name',
            hintText: 'e.g. BOTTLE, BOX, KG, PC',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeHelper.primaryColor(),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final val = uomController.text.trim().toUpperCase();
              if (val.isNotEmpty) Navigator.pop(ctx, val);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await Uom().insertUom({'id': 0, 'uom': result});
      await _loadData();
      setState(() => _selectedUnit = result);
    }
  }

  Future<String> _saveImageToAppFolder(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${directory.path}/product_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(imageFile.path)}';
    final newImage = await imageFile.copy('${imagesDir.path}/$fileName');
    return newImage.path;
  }

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final isEditing = widget.product != null;
    final productId = (widget.product?['id'] as num?)?.toInt() ?? 0;

    if (!isEditing) {
      final allProducts = await Product().getProducts();
      if (allProducts.length >= AppLimits.maxProducts) {
        if (!mounted) return;
        AppLimits.showUpgradeToProDialog(
          context,
          featureName: 'Products',
          customMessage:
              'You have reached the maximum limit of ${AppLimits.maxProducts} products in the Basic Edition.',
        );
        return;
      }
    }

    // Check duplicate product name
    final exists = await Product().productExists(name, excludeId: isEditing ? productId : null);
    if (exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A product named "$name" already exists in the catalog.'),
          backgroundColor: ThemeHelper.error(),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String imagePath = _existingImagePath ?? '';
      if (_selectedImage != null) {
        final fileSize = await _selectedImage!.length();
        if (fileSize > maxImageSizeBytes) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Product image exceeds the 1 MB limit. Please select a smaller photo.',
              ),
              backgroundColor: ThemeHelper.error(),
            ),
          );
          setState(() => _isSaving = false);
          return;
        }

        final currentSavedPath = widget.product?['image_path']?.toString() ?? '';
        final isCurrentFile = currentSavedPath.isNotEmpty && _selectedImage!.path == currentSavedPath;
        imagePath = isCurrentFile ? currentSavedPath : await _saveImageToAppFolder(_selectedImage!);
      }

      final cost = double.tryParse(_costPriceController.text.trim()) ?? 0.0;
      final selling = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
      final lowStock = double.tryParse(_lowStockController.text.trim()) ?? 5.0;

      await Product().insertProduct({
        'id': productId,
        'name': name,
        'barcode': _barcodeController.text.trim(),
        'category': _selectedCategory ?? 'General',
        'unit': _selectedUnit ?? 'PC',
        'cost_price': cost,
        'selling_price': selling,
        'low_stock_level': lowStock,
        'image_path': imagePath,
      });

      widget.onRefresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Product updated successfully' : 'Product added successfully'),
          backgroundColor: ThemeHelper.primaryColor(),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving product: $e'),
          backgroundColor: ThemeHelper.error(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Scaffold(
      backgroundColor: ThemeHelper.backgroundColor(),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Product' : 'New Product',
          style: TextStyle(
            color: ThemeHelper.textPrimary(),
            fontWeight: FontWeight.w900,
            fontSize: 19,
          ),
        ),
        elevation: 0,
        backgroundColor: ThemeHelper.cardBackground(),
        iconTheme: IconThemeData(color: ThemeHelper.textPrimary()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // SECTION 1: Product Photo
                        _buildCardContainer(
                          title: 'PRODUCT PHOTO',
                          icon: Icons.image_outlined,
                          child: _buildPhotoSection(),
                        ),
                        const SizedBox(height: 16),

                        // SECTION 2: Basic Info
                        _buildCardContainer(
                          title: 'BASIC INFORMATION',
                          icon: Icons.inventory_2_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _nameController,
                                maxLength: 60,
                                decoration: ThemeHelper.inputDecoration(
                                  'Product Name *',
                                  hint: 'e.g. Iced Americano, Chocolate Croissant',
                                  prefixIcon: const Icon(Icons.label_outline),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter a product name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Barcode with Camera Scan & Auto-Generate buttons
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _barcodeController,
                                      decoration: ThemeHelper.inputDecoration(
                                        'Barcode / SKU',
                                        hint: 'Scan or enter code',
                                        prefixIcon: const Icon(Icons.barcode_reader),
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.qr_code_scanner, size: 20),
                                          tooltip: 'Scan with camera',
                                          onPressed: _scanBarcode,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: IconButton.filled(
                                      onPressed: _scanBarcode,
                                      icon: const Icon(Icons.qr_code_scanner),
                                      tooltip: 'Scan Barcode with Camera',
                                      style: IconButton.styleFrom(
                                        backgroundColor: ThemeHelper.primaryColor(),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.all(14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: IconButton.filledTonal(
                                      onPressed: _generateBarcode,
                                      icon: const Icon(Icons.auto_fix_high),
                                      tooltip: 'Auto-Generate Barcode',
                                      style: IconButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.all(14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Category Dropdown + Add Category Button
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _categories.contains(_selectedCategory)
                                          ? _selectedCategory
                                          : null,
                                      decoration: ThemeHelper.inputDecoration(
                                        'Category',
                                        hint: 'Select a category',
                                        prefixIcon: const Icon(Icons.category_outlined),
                                      ),
                                      items: _categories.map((c) {
                                        return DropdownMenuItem(value: c, child: Text(c));
                                      }).toList(),
                                      onChanged: (val) => setState(() => _selectedCategory = val),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filledTonal(
                                    onPressed: _showAddCategoryDialog,
                                    icon: const Icon(Icons.add),
                                    tooltip: 'Add new category',
                                    style: IconButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.all(14),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Unit Dropdown + Add Unit Button
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _uoms.contains(_selectedUnit)
                                          ? _selectedUnit
                                          : null,
                                      decoration: ThemeHelper.inputDecoration(
                                        'Unit of Measurement',
                                        hint: 'e.g. PC, KG, BOTTLE',
                                        prefixIcon: const Icon(Icons.straighten_outlined),
                                      ),
                                      items: _uoms.map((u) {
                                        return DropdownMenuItem(value: u, child: Text(u));
                                      }).toList(),
                                      onChanged: (val) => setState(() => _selectedUnit = val),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filledTonal(
                                    onPressed: _showAddUomDialog,
                                    icon: const Icon(Icons.add),
                                    tooltip: 'Add new unit',
                                    style: IconButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.all(14),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // SECTION 3: Pricing & Margin Calculator
                        _buildCardContainer(
                          title: 'PRICING & PROFIT MARGIN',
                          icon: Icons.payments_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _costPriceController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: ThemeHelper.inputDecoration(
                                        'Cost Price (PHP) *',
                                        hint: '0.00',
                                        prefixIcon: const Icon(Icons.price_change_outlined),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) return 'Enter cost price';
                                        if (double.tryParse(val.trim()) == null) return 'Invalid number';
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _sellingPriceController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: ThemeHelper.inputDecoration(
                                        'Selling Price (PHP) *',
                                        hint: '0.00',
                                        prefixIcon: const Icon(Icons.sell_outlined),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) return 'Enter selling price';
                                        if (double.tryParse(val.trim()) == null) return 'Invalid number';
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildMarginPreview(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // SECTION 4: Stock Threshold Alert
                        _buildCardContainer(
                          title: 'INVENTORY & ALERTS',
                          icon: Icons.notifications_active_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _lowStockController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: ThemeHelper.inputDecoration(
                                  'Low Stock Alert Threshold',
                                  hint: '5',
                                  prefixIcon: const Icon(Icons.warning_amber_rounded),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Enter low stock alert level';
                                  if (double.tryParse(val.trim()) == null) return 'Invalid number';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'The app will flag this item when on-hand stock falls to or below this quantity.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ThemeHelper.textSecondary(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // SUBMIT BUTTON
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _submitForm,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_circle_outline, size: 20),
                          label: Text(
                            _isSaving
                                ? 'Saving...'
                                : (isEditing ? 'Update Product' : 'Save Product'),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ThemeHelper.primaryColor(),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCardContainer({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ThemeHelper.cardBackground(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: ThemeHelper.primaryColor()),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: ThemeHelper.textSecondary(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Row(
      children: [
        // Image preview or upload box
        InkWell(
          onTap: _showImageSourceDialog,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: ThemeHelper.primaryColor().withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: ThemeHelper.primaryColor().withValues(alpha: 0.3),
                style: BorderStyle.solid,
                width: 1.5,
              ),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined,
                          size: 30, color: ThemeHelper.primaryColor()),
                      const SizedBox(height: 4),
                      Text(
                        'Add Photo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: ThemeHelper.primaryColor(),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _selectedImage != null ? 'Photo selected' : 'No photo uploaded',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  if (_selectedImageSize != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ThemeHelper.primaryColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatFileSize(_selectedImageSize!),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ThemeHelper.primaryColor(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Upload a picture (max 1 MB) to help cashiers quickly recognize items on the POS terminal.',
                style: TextStyle(fontSize: 12, color: ThemeHelper.textSecondary()),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _showImageSourceDialog,
                    icon: const Icon(Icons.upload, size: 14),
                    label: Text(_selectedImage != null ? 'Change' : 'Upload',
                        style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  if (_selectedImage != null)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                          _selectedImageSize = null;
                          _existingImagePath = null;
                        });
                      },
                      icon: const Icon(Icons.clear, size: 14, color: Colors.red),
                      label: const Text('Remove',
                          style: TextStyle(fontSize: 12, color: Colors.red)),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMarginPreview() {
    final cost = double.tryParse(_costPriceController.text.trim()) ?? 0.0;
    final selling = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
    final profit = selling - cost;
    final double marginPct = cost > 0 ? (profit / cost) * 100 : 0.0;

    final isProfit = profit > 0;
    final isLoss = profit < 0;

    final bgColor = isLoss
        ? Colors.red.withValues(alpha: 0.1)
        : isProfit
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1);

    final textColor = isLoss
        ? Colors.red.shade800
        : isProfit
            ? Colors.green.shade800
            : ThemeHelper.textSecondary();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isLoss
                    ? Icons.trending_down
                    : isProfit
                        ? Icons.trending_up
                        : Icons.remove,
                size: 18,
                color: textColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Calculated Profit:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
              ),
            ],
          ),
          Text(
            '${Helper.formatNumberWithPeso(profit)} (${marginPct >= 0 ? '+' : ''}${marginPct.toStringAsFixed(1)}%)',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

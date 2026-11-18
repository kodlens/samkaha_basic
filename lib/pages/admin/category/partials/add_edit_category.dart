import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/category.dart';

void showAddEditCategory(
  BuildContext context,
  Future<void> Function(Map<String, dynamic>) onSubmit,
  Map<String, dynamic> data, // id: 0 for new category, id > 0 for editing
) {
  final formKey = GlobalKey<FormState>();
  final TextEditingController categoryController = TextEditingController();
  final bool isEdit = (data['id'] as num?)?.toInt() != 0;
  final int categoryId = (data['id'] as num?)?.toInt() ?? 0;

  if (isEdit) {
    categoryController.text = data['category'] ?? '';
  }

  bool isSaving = false;
  String? duplicateError;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(22.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: ThemeHelper.lightPrimary().withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.category_rounded,
                              color: ThemeHelper.primaryColor(),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEdit ? 'Edit Category' : 'New Category',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: ThemeHelper.textPrimary(),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isEdit
                                      ? 'Update category name'
                                      : 'Create a new product category',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ThemeHelper.textSecondary(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Category Name Input
                      TextFormField(
                        controller: categoryController,
                        autofocus: true,
                        maxLength: 50,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) {
                          if (duplicateError != null) {
                            setStateDialog(() => duplicateError = null);
                          }
                        },
                        decoration: ThemeHelper.inputDecoration(
                          'Category Name',
                          hint: 'e.g. Beverages, Snacks, Electronics',
                          prefixIcon: const Icon(Icons.label_outline),
                        ).copyWith(
                          errorText: duplicateError,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a category name';
                          }
                          if (value.trim().length < 2) {
                            return 'Category name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ThemeHelper.primaryColor(),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;

                                    final name = categoryController.text.trim();

                                    setStateDialog(() => isSaving = true);

                                    // Check duplicate
                                    final exists = await Category().categoryExists(
                                      name,
                                      isEdit ? categoryId : null,
                                    );

                                    if (exists) {
                                      setStateDialog(() {
                                        isSaving = false;
                                        duplicateError =
                                            'A category with this name already exists';
                                      });
                                      return;
                                    }

                                    try {
                                      final categoryData = {
                                        'id': categoryId,
                                        'category': name,
                                      };

                                      await onSubmit(categoryData);

                                      if (dialogContext.mounted) {
                                        Navigator.pop(dialogContext);
                                      }
                                    } catch (e) {
                                      setStateDialog(() => isSaving = false);
                                      if (dialogContext.mounted) {
                                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed to save category: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            icon: isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check, size: 18),
                            label: Text(
                              isSaving
                                  ? 'Saving...'
                                  : (isEdit ? 'Update' : 'Create Category'),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

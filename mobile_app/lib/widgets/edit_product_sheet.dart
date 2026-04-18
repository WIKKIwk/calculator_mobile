import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../graphql/queries.dart';
import '../models/product.dart';

class EditProductSheet extends StatefulWidget {
  final Product product;
  final VoidCallback onProductUpdated;

  const EditProductSheet({
    super.key,
    required this.product,
    required this.onProductUpdated,
  });

  @override
  State<EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends State<EditProductSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    final priceStr = widget.product.price.toStringAsFixed(0);
    _priceController = TextEditingController(text: priceStr);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit(RunMutation runMutation) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final price = double.tryParse(
          _priceController.text.trim().replaceAll(',', '.'),
        ) ??
        0.0;

    runMutation({
      'id': widget.product.id,
      'name': name,
      'price': price,
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Mutation(
      options: MutationOptions(
        document: gql(updateProductMutation),
        onCompleted: (data) {
          if (data != null) {
            setState(() => _isLoading = false);
            widget.onProductUpdated();
            Navigator.of(context).pop();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Mahsulot yangilandi!'),
                  ],
                ),
                backgroundColor: colorScheme.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        onError: (error) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Xato: ${error?.graphqlErrors.first.message}'),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
      builder: (runMutation, result) {
        return Container(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomPadding),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Sarlavha
                Text(
                  'Mahsulotni tahrirlash',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Mahsulot nomi
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Mahsulot nomi',
                    prefixIcon: Icon(
                      Icons.shopping_basket_outlined,
                      color: colorScheme.primary,
                    ),
                    fillColor: colorScheme.surfaceContainerHighest,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Mahsulot nomini kiriting';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Narx
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Narxi (so\'m)',
                    prefixIcon: Icon(
                      Icons.payments_outlined,
                      color: colorScheme.primary,
                    ),
                    fillColor: colorScheme.surfaceContainerHighest,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Narxni kiriting';
                    }
                    final price = double.tryParse(
                      value.trim().replaceAll(',', '.'),
                    );
                    if (price == null || price <= 0) {
                      return 'To\'g\'ri narx kiriting';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Saqlash tugmasi
                FilledButton.icon(
                  onPressed: _isLoading ? null : () => _submit(runMutation),
                  icon: _isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isLoading ? 'Saqlanmoqda...' : 'Saqlash'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

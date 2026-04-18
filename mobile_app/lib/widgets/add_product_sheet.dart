import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../graphql/queries.dart';
import '../services/app_local_store.dart';

class AddProductSheet extends StatefulWidget {
  final VoidCallback onProductAdded;

  const AddProductSheet({super.key, required this.onProductAdded});

  @override
  State<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<AddProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoading = false;
  bool _pendingAddAnother = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit(RunMutation runMutation, {required bool addAnother}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _pendingAddAnother = addAnother;
    });

    final name = _nameController.text.trim();
    final price = double.tryParse(
          _priceController.text.trim().replaceAll(',', '.'),
        ) ??
        0.0;

    runMutation({'name': name, 'price': price});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Mutation(
      options: MutationOptions(
        document: gql(addProductMutation),
        onCompleted: (data) async {
          if (data != null) {
            final payload = data['addProduct'];
            final name = payload is Map && payload['name'] != null
                ? payload['name'].toString()
                : _nameController.text.trim();
            final messenger = ScaffoldMessenger.of(context);
            final nav = Navigator.of(context);
            final addAnother = _pendingAddAnother;
            await AppLocalStore.logEvent('mahsulot_qoshildi', name);
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _pendingAddAnother = false;
            });
            widget.onProductAdded();
            messenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      addAnother
                          ? 'Qo\'shildi — keyingisini kiriting'
                          : 'Mahsulot qo\'shildi!',
                    ),
                  ],
                ),
                backgroundColor: colorScheme.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            if (addAnother) {
              _nameController.clear();
              _priceController.clear();
              _formKey.currentState?.reset();
            } else {
              nav.pop();
            }
          }
        },
        onError: (error) {
          setState(() {
            _isLoading = false;
            _pendingAddAnother = false;
          });
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
                  'Mahsulot qo\'shish',
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
                    hintText: 'Masalan: Olma, Non, Sabzi...',
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
                    hintText: 'Masalan: 5000',
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

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _submit(runMutation, addAnother: true),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Yana qo\'shish'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _submit(runMutation, addAnother: false),
                        icon: _isLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : const Icon(Icons.add),
                        label: Text(_isLoading ? 'Saqlanmoqda...' : 'Qo\'shish'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

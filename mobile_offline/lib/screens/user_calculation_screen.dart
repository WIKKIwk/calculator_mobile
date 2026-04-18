import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../services/app_local_store.dart';
import '../services/offline_entity_store.dart';

class UserCalculationScreen extends StatefulWidget {
  final User user;
  const UserCalculationScreen({super.key, required this.user});

  @override
  State<UserCalculationScreen> createState() => _UserCalculationScreenState();
}

class _UserCalculationScreenState extends State<UserCalculationScreen> {
  final Set<String> _selectedProductIds = {};
  final Map<String, double> _productQuantities = {};
  bool _isSaving = false;
  List<Product>? _products;

  void _openCalcQtySheet(BuildContext context, List<Product> allProducts) {
    if (_selectedProductIds.isEmpty) return;

    final selectedProducts = allProducts.where((p) => _selectedProductIds.contains(p.id)).toList();
    final controllers = <String, TextEditingController>{};

    for (var p in selectedProducts) {
      final existingQty = _productQuantities[p.id];
      final text = existingQty != null && existingQty > 0
          ? (existingQty == existingQty.truncateToDouble()
              ? existingQty.toInt().toString()
              : existingQty.toString())
          : '';
      controllers[p.id] = TextEditingController(text: text);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final colorScheme = Theme.of(context).colorScheme;
        final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

        return Container(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomPadding),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              Text(
                'Miqdorlarni kiriting',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: selectedProducts.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 16),
                  itemBuilder: (_, i) {
                    final p = selectedProducts[i];
                    return Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            p.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: controllers[p.id],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.end,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              hintText: '0',
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    for (var p in selectedProducts) {
                      final val = double.tryParse(
                            controllers[p.id]?.text.replaceAll(',', '.') ?? '',
                          ) ??
                          0.0;
                      if (val > 0) {
                        _productQuantities[p.id] = val;
                      } else {
                        _productQuantities.remove(p.id);
                      }
                    }
                    _selectedProductIds.clear();
                  });
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.calculate),
                label: const Text('Hisoblash'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitCalculation() async {
    if (_productQuantities.isEmpty) return;
    final products = _products;
    if (products == null) return;

    setState(() => _isSaving = true);
    try {
      await OfflineEntityStore.addRecordsForUser(
        user: widget.user,
        productIdToQuantity: Map.from(_productQuantities),
        allProducts: products,
      );
      await AppLocalStore.logEvent(
        'kalkulyatsiya_saqlash',
        widget.user.displayName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kalkulyatsiya qurilmada saqlandi.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saqlashda xato: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatPrice(double n) {
    final s = n.toStringAsFixed(0);
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write(',');
      result.write(s[i]);
    }
    return result.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kalkulyatsiya'),
            Text(
              widget.user.displayName,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      floatingActionButton: _productQuantities.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _submitCalculation,
              icon: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saqlanmoqda...' : 'Tasdiqlash (Saqlash)'),
            )
          : (_selectedProductIds.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () {
                    if (_products != null) {
                      _openCalcQtySheet(context, _products!);
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Tayyor'),
                )
              : null),
      body: FutureBuilder<List<Product>>(
        future: OfflineEntityStore.products(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Xatolik: ${snapshot.error}'));
          }

          final products = snapshot.data ?? [];
          _products = products;

          if (products.isEmpty) {
            return const Center(child: Text('Mahsulotlar yo\'q'));
          }

          final totalPrice = _productQuantities.entries.fold<double>(0.0, (sum, entry) {
            final prod = products.cast<Product?>().firstWhere(
                  (p) => p?.id == entry.key,
                  orElse: () => null,
                );
            if (prod != null) {
              return sum + (prod.price * entry.value);
            }
            return sum;
          });

          return ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Umumiy hisob:',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${_formatPrice(totalPrice)} so\'m',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              ...products.map((p) {
                final isSelected = _selectedProductIds.contains(p.id);
                final existingQty = _productQuantities[p.id];
                final qtyStr = existingQty != null && existingQty > 0
                    ? (existingQty == existingQty.truncateToDouble()
                        ? '${existingQty.toInt()}'
                        : existingQty.toString())
                    : '';

                return ListTile(
                  selected: isSelected,
                  selectedTileColor: colorScheme.secondaryContainer.withValues(alpha: 0.6),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedProductIds.remove(p.id);
                        _productQuantities.remove(p.id);
                      } else {
                        _selectedProductIds.add(p.id);
                      }
                    });
                  },
                  leading: CircleAvatar(
                    backgroundColor: isSelected ? colorScheme.primary : colorScheme.primaryContainer,
                    foregroundColor: isSelected ? colorScheme.onPrimary : colorScheme.onPrimaryContainer,
                    child: isSelected ? const Icon(Icons.check) : Text(p.name[0].toUpperCase()),
                  ),
                  title: Text(p.name),
                  subtitle: qtyStr.isNotEmpty ? Text('$qtyStr x ${_formatPrice(p.price)}') : null,
                  trailing: Text(
                    '${_formatPrice(p.price)} so\'m',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/record.dart';
import '../services/offline_entity_store.dart';
import '../services/records_excel_export.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  int _refreshKey = 0;

  void _refresh() {
    setState(() => _refreshKey++);
  }

  String _formatPrice(double n) {
    if (n == n.truncateToDouble()) {
      return n.toInt().toString();
    }
    return n.toString();
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<Record>>(
      key: ValueKey(_refreshKey),
      future: OfflineEntityStore.records(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: colorScheme.error),
                const SizedBox(height: 16),
                Text('${snapshot.error}'),
                TextButton(onPressed: _refresh, child: const Text('Qayta urinish')),
              ],
            ),
          );
        }

        final records = snapshot.data ?? [];

        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_toggle_off,
                  size: 80,
                  color: colorScheme.primary.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hali ma\'lumotlar kiritilmagan',
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
                ),
              ],
            ),
          );
        }

        final userGroups = <String, List<Record>>{};
        for (var r in records) {
          final uid = r.user.id;
          userGroups.putIfAbsent(uid, () => []).add(r);
        }

        final usersList = userGroups.keys.toList();

        String formatNum(double n) {
          final s = n.toStringAsFixed(0);
          final result = StringBuffer();
          for (int i = 0; i < s.length; i++) {
            if (i > 0 && (s.length - i) % 3 == 0) result.write(',');
            result.write(s[i]);
          }
          return result.toString();
        }

        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    onPressed: () => exportRecordsToExcelFile(context, records),
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('Excelga saqlash'),
                  ),
                ),
              ),
              ...usersList.asMap().entries.map((entry) {
                final index = entry.key;
                final uid = entry.value;
                final userRecords = userGroups[uid]!;
                final u = userRecords.first.user;

                final totalSum = userRecords.fold(
                  0.0,
                  (sum, r) => sum + (r.quantity * r.product.price),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (index > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                    ExpansionTile(
                      initiallyExpanded: index == 0,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: const Border(),
                      collapsedShape: const Border(),
                      backgroundColor: colorScheme.surface,
                      collapsedBackgroundColor: colorScheme.surface,
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        foregroundColor: colorScheme.onPrimaryContainer,
                        child: Text(
                          u.firstName.isNotEmpty ? u.firstName[0].toUpperCase() : 'I',
                        ),
                      ),
                      title: Text(
                        u.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Jami hisob: ${formatNum(totalSum)} so\'m',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      children: userRecords.map((rec) {
                        final p = rec.product;
                        final priceStr = formatNum(rec.quantity * p.price);

                        return Column(
                          children: [
                            Divider(
                              height: 1,
                              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                            ),
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 2,
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.name,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Text(
                                    '$priceStr so\'m',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                '${_formatPrice(rec.quantity)} ta/kg x ${formatNum(p.price)} \nVaqt: ${_formatDate(rec.createdAt)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

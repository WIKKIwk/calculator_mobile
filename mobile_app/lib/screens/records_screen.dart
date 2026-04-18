import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../graphql/queries.dart';
import '../models/product.dart';
import '../models/record.dart';
import '../models/user.dart';
import '../services/app_local_store.dart';
import '../widgets/offline_hint_banner.dart';

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

  List<Record> _recordsFromPendingBatches() {
    final out = <Record>[];
    for (final batch in AppLocalStore.pendingRecordBatches()) {
      final userRaw = batch['user'];
      if (userRaw is! Map) continue;
      final user = User.fromJson(
        Map<String, dynamic>.from(
          userRaw.map((k, v) => MapEntry(k.toString(), v)),
        ),
      );
      final lines = batch['lines'];
      if (lines is! List) continue;
      final bid = batch['id']?.toString() ?? '';
      final createdAt = batch['createdAt']?.toString() ?? '';
      for (final line in lines) {
        if (line is! Map) continue;
        final m = Map<String, dynamic>.from(
          line.map((k, v) => MapEntry(k.toString(), v)),
        );
        final prod = Product(
          id: m['productId'] as String,
          name: m['name'] as String,
          price: (m['price'] as num).toDouble(),
          createdAt: (m['createdAt'] as String?) ?? createdAt,
        );
        out.add(Record(
          id: 'local_${bid}_${prod.id}',
          user: user,
          product: prod,
          quantity: (m['quantity'] as num).toDouble(),
          createdAt: createdAt,
          isLocalPending: true,
        ));
      }
    }
    return out;
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

    return Query(
      key: ValueKey(_refreshKey),
      options: QueryOptions(
        document: gql(getRecordsQuery),
        fetchPolicy: FetchPolicy.cacheAndNetwork,
      ),
      builder: (result, {fetchMore, refetch}) {
        final cached = result.data != null;
        if (result.isLoading && !cached) {
          return const Center(child: CircularProgressIndicator());
        }

        if (result.hasException && !cached) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: colorScheme.error),
                const SizedBox(height: 16),
                const Text('Ma\'lumotlarni yuklashda xatolik'),
                TextButton(onPressed: _refresh, child: const Text('Qayta urinish')),
              ],
            ),
          );
        }

        final rawList = result.data?['records'] as List? ?? [];
        final serverRecords = rawList.map((e) => Record.fromJson(e as Map<String, dynamic>)).toList();
        final records = [..._recordsFromPendingBatches(), ...serverRecords];

        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off, size: 80, color: colorScheme.primary.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Text('Hali ma\'lumotlar kiritilmagan', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16)),
              ],
            ),
          );
        }

        // Guruhlash: Ishchilar bo'yicha ajratami
        final userGroups = <String, List<Record>>{};
        for (var r in records) {
          final uid = r.user.id;
          if (!userGroups.containsKey(uid)) userGroups[uid] = [];
          userGroups[uid]!.add(r);
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
          onRefresh: () async {
            if (refetch != null) await refetch();
            else _refresh();
          },
          child: ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            children: [
              if (result.hasException && cached) const OfflineHintBanner(),
              ...usersList.asMap().entries.map((entry) {
                final index = entry.key;
                final uid = entry.value;
                final userRecords = userGroups[uid]!;
                final u = userRecords.first.user;

                final totalSum = userRecords.fold(0.0, (sum, r) => sum + (r.quantity * r.product.price));

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  clipBehavior: Clip.antiAlias, // ExpansionTile fonlari toshib ketmasligi uchun
                  child: ExpansionTile(
                    initiallyExpanded: index == 0, // Dastlabkisiga ochiq bo'lsin
                  shape: const Border(),
                  backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                    child: Text(u.firstName.isNotEmpty ? u.firstName[0].toUpperCase() : 'I'),
                  ),
                  title: Text('${u.firstName} ${u.lastName}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Jami hisob: ${formatNum(totalSum)} so\'m', 
                    style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13)
                  ),
                    children: userRecords.map((rec) {
                      final p = rec.product;
                      final priceStr = formatNum(rec.quantity * p.price);

                      return Column(
                        children: [
                          Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                      ),
                                      if (rec.isLocalPending)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 6),
                                          child: Text(
                                            'Kutilmoqda',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.tertiary,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text('$priceStr so\'m', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ],
                            ),
                            subtitle: Text(
                              '${_formatPrice(rec.quantity)} ta/kg x ${formatNum(p.price)} \nVaqt: ${_formatDate(rec.createdAt)}',
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, height: 1.5),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
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

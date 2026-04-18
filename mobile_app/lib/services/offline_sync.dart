import 'package:graphql_flutter/graphql_flutter.dart';

import '../graphql/queries.dart';
import 'app_local_store.dart';

/// Internet paytida kutilayotgan kalkulyatsiya yozuvlarini serverga yuborish.
class OfflineSyncService {
  OfflineSyncService._();

  static Future<int> flushPendingRecords(GraphQLClient client) async {
    final pending = AppLocalStore.pendingRecordBatches();
    if (pending.isEmpty) return 0;

    var synced = 0;
    for (final batch in List<Map<String, dynamic>>.from(pending)) {
      final id = batch['id'] as String?;
      final userId = batch['userId'] as String?;
      final lines = batch['lines'];
      if (id == null || userId == null || lines is! List) continue;

      final itemsInput = lines
          .map((e) {
            if (e is! Map) return null;
            final m = Map<String, dynamic>.from(
              e.map((k, v) => MapEntry(k.toString(), v)),
            );
            return {
              'productId': m['productId']?.toString(),
              'quantity': (m['quantity'] as num?)?.toDouble(),
            };
          })
          .whereType<Map<String, dynamic>>()
          .where((m) => m['productId'] != null && (m['quantity'] ?? 0) > 0)
          .toList();

      if (itemsInput.isEmpty) {
        await AppLocalStore.removePendingRecordBatch(id);
        continue;
      }

      final result = await client.mutate(
        MutationOptions(
          document: gql(addRecordsMutation),
          variables: {
            'userId': userId,
            'items': itemsInput,
          },
        ),
      );

      if (!result.hasException) {
        await AppLocalStore.removePendingRecordBatch(id);
        synced++;
      }
    }
    return synced;
  }
}

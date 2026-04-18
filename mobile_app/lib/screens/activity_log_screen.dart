import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/app_local_store.dart';

/// Ilova o'zi yig'gan sodda hodisalar jurnali (kirishlar, saqlashlar va hokazo).
class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final events = AppLocalStore.recentEvents(max: 200);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faoliyat jurnali'),
        backgroundColor: colorScheme.surfaceContainer,
      ),
      body: events.isEmpty
          ? Center(
              child: Text(
                'Hali yozuvlar yo\'q — ilova ishlaganda bu yerda hodisalar to\'planadi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              itemCount: events.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final e = events[i];
                final type = e['type']?.toString() ?? '';
                final detail = e['detail']?.toString();
                final t = e['t']?.toString() ?? '';
                String timeLabel = t;
                try {
                  final dt = DateTime.parse(t).toLocal();
                  timeLabel = DateFormat('dd.MM.yyyy HH:mm:ss').format(dt);
                } catch (_) {}

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: Icon(Icons.circle, size: 10, color: colorScheme.primary),
                  title: Text(type, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: detail != null && detail.isNotEmpty
                      ? Text(detail, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13))
                      : null,
                  trailing: Text(
                    timeLabel,
                    style: TextStyle(fontSize: 11, color: colorScheme.outline),
                  ),
                );
              },
            ),
    );
  }
}

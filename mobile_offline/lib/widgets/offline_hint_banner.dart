import 'package:flutter/material.dart';

class OfflineHintBanner extends StatelessWidget {
  final String message;

  const OfflineHintBanner({
    super.key,
    this.message = 'Internet aloqasi yo\'q yoki server javob bermadi — oxirgi saqlangan ma\'lumotlar ko\'rsatilmoqda.',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, size: 20, color: colorScheme.onSecondaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSecondaryContainer,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

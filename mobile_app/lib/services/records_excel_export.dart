import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/record.dart';

String _formatDateForExcel(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    return DateFormat('dd.MM.yyyy HH:mm').format(dt);
  } catch (_) {
    return iso;
  }
}

/// Ishchilar yozuvlarini tartibli Excel (.xlsx) ga yig‘adi.
Uint8List? buildRecordsExcelBytes(List<Record> records) {
  if (records.isEmpty) return null;

  final excel = Excel.createExcel();
  final def = excel.getDefaultSheet() ?? 'Sheet1';
  excel.rename(def, 'Yozuvlar');
  excel.setDefaultSheet('Yozuvlar');

  const sn = 'Yozuvlar';
  excel.appendRow(sn, [
    TextCellValue('№'),
    TextCellValue('Ishchi'),
    TextCellValue('Mahsulot'),
    TextCellValue('Miqdor (kg)'),
    TextCellValue('Narx (so\'m)'),
    TextCellValue('Summa (so\'m)'),
    TextCellValue('Vaqt'),
    TextCellValue('Holat'),
  ]);

  final sorted = List<Record>.from(records)
    ..sort((a, b) {
      final byName = a.user.displayName.compareTo(b.user.displayName);
      if (byName != 0) return byName;
      return a.createdAt.compareTo(b.createdAt);
    });

  for (var i = 0; i < sorted.length; i++) {
    final r = sorted[i];
    final sum = r.quantity * r.product.price;
    excel.appendRow(sn, [
      IntCellValue(i + 1),
      TextCellValue(r.user.displayName),
      TextCellValue(r.product.name),
      DoubleCellValue(r.quantity),
      DoubleCellValue(r.product.price),
      DoubleCellValue(sum),
      TextCellValue(_formatDateForExcel(r.createdAt)),
      TextCellValue(r.isLocalPending ? 'Kutilmoqda' : ''),
    ]);
  }

  final byUser = <String, ({double sum, int count})>{};
  for (final r in records) {
    final name = r.user.displayName;
    final prev = byUser[name] ?? (sum: 0.0, count: 0);
    byUser[name] = (
      sum: prev.sum + r.quantity * r.product.price,
      count: prev.count + 1,
    );
  }

  const jami = 'Jami';
  excel.appendRow(jami, [
    TextCellValue('Ishchi'),
    TextCellValue('Jami summa (so\'m)'),
    TextCellValue('Yozuvlar soni'),
  ]);
  final names = byUser.keys.toList()..sort();
  for (final name in names) {
    final v = byUser[name]!;
    excel.appendRow(jami, [
      TextCellValue(name),
      DoubleCellValue(v.sum),
      IntCellValue(v.count),
    ]);
  }

  final encoded = excel.encode();
  if (encoded == null) return null;
  return Uint8List.fromList(encoded);
}

/// Tizim dialogi orqali fayl yo‘lini tanlaydi va saqlaydi (Android/iOS uchun [bytes] majburiy).
Future<void> exportRecordsToExcelFile(
  BuildContext context,
  List<Record> records,
) async {
  if (records.isEmpty) return;

  final messenger = ScaffoldMessenger.of(context);
  final nav = Navigator.of(context);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                'Excel tayyorlanmoqda…',
                style: Theme.of(ctx).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  try {
    final bytes = buildRecordsExcelBytes(records);
    if (bytes == null) {
      throw StateError('Excel yaratilmadi');
    }
    if (!context.mounted) return;
    nav.pop();

    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final path = await FilePicker.saveFile(
      dialogTitle: 'Excel faylni qayerga saqlash',
      fileName: 'hisobot_$stamp.xlsx',
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      bytes: bytes,
    );

    if (!context.mounted) return;
    if (path != null) {
      messenger.showSnackBar(
        SnackBar(content: Text('Saqlandi: $path')),
      );
    }
  } catch (e) {
    if (context.mounted && nav.canPop()) {
      nav.pop();
    }
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text('Excel xatolik: $e')),
      );
    }
  }
}

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/secure_backup_service.dart';
import 'activity_log_screen.dart';

/// Zaxira eksport / import va xavfsizlik haqida qisqa ma'lumot.
class BackupSecurityScreen extends StatefulWidget {
  const BackupSecurityScreen({super.key});

  @override
  State<BackupSecurityScreen> createState() => _BackupSecurityScreenState();
}

class _BackupSecurityScreenState extends State<BackupSecurityScreen> {
  bool _busy = false;

  Future<void> _export() async {
    final pass1 = TextEditingController();
    final pass2 = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Zaxira yaratish'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Parol kamida 8 belgi. Uni eslab qoling — importda shu parol kerak bo\'ladi.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pass1,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Parol',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pass2,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Parolni tasdiqlang',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor')),
            FilledButton(
              onPressed: () {
                if (pass1.text.length < 8 || pass1.text != pass2.text) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Parollar mos emas yoki juda qisqa.')),
                  );
                  return;
                }
                Navigator.pop(ctx, pass1.text);
              },
              child: const Text('Davom etish'),
            ),
          ],
        );
      },
    );
    pass1.dispose();
    pass2.dispose();
    if (password == null || password.length < 8 || !mounted) return;

    setState(() => _busy = true);
    try {
      final bytes = await SecureBackupService.buildEncryptedFile(password);
      final name =
          'hisoblagich_zaxira_${DateTime.now().toUtc().toIso8601String().split('T').first}.calc1';
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              name: name,
              mimeType: 'application/octet-stream',
            ),
          ],
          text: 'Hisoblagich zaxirasi (parol bilan shifrlangan). Saqlab qo\'ying.',
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zaxira tayyor — faylni Drive yoki kompyuterga saqlang.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xato: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final pick = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['calc1'],
      withData: true,
    );
    if (pick == null || pick.files.isEmpty || !mounted) return;
    final f = pick.files.single;
    final raw = f.bytes;
    if (raw == null || raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fayl o\'qilmadi.')),
      );
      return;
    }

    final pass = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zaxiradan tiklash'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Joriy kutilayotgan yozuvlar va jurnal to\'liq almashtiriladi.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pass,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Zaxira paroli',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tiklash'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await SecureBackupService.restoreFromEncryptedBytes(raw, pass.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ma\'lumotlar tiklandi. Data bo\'limini yangilang.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tiklash muvaffaqiyatsiz: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zaxira va xavfsizlik'),
        backgroundColor: colorScheme.surfaceContainer,
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Icon(Icons.enhanced_encryption_outlined, size: 48, color: colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  'Lokal ma\'lumotlar',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kutilayotgan kalkulyatsiya yozuvlari va faoliyat jurnali qurilmada AES bilan shifrlangan holda saqlanadi. Kalit Android/iOS xavfli saqlash joyida.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.4),
                ),
                const SizedBox(height: 20),
                Text(
                  'Ilovani o\'chirish',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tizim ilovani o\'chirganda ichki papkani ham o\'chiradi — shuning uchun qayta o\'rnatgandan keyin ma\'lumotni tiklash uchun avval zaxira faylini tashqariga (Fayllar, Google Drive, elektron pochta) chiqarib oling.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.4),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _export,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Zaxira fayli yaratish (eksport)'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _import,
                  icon: const Icon(Icons.download_done_outlined),
                  label: const Text('Zaxiradan tiklash (import)'),
                ),
                const SizedBox(height: 32),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ActivityLogScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('Faoliyat jurnalini ko\'rish'),
                ),
              ],
            ),
    );
  }
}

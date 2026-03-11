import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../core/export/export_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(s.settings, style: const TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text(s.language, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(ref.watch(localeProvider).languageCode == 'vi' ? s.vietnamese : s.english),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguagePicker(context, ref),
          ),
          const Divider(),
          ListTile(
            title: Text(s.exportCsv, style: const TextStyle(fontWeight: FontWeight.w600)),
            onTap: () => _exportCsv(context, ref),
          ),
          ListTile(
            title: Text(s.exportExcel, style: const TextStyle(fontWeight: FontWeight.w600)),
            onTap: () => _exportExcel(context, ref),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final s = ref.read(appStringsProvider);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(s.english),
              leading: const Icon(Icons.language),
              onTap: () {
                ref.read(localeProvider.notifier).state = const Locale('en');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(s.vietnamese),
              leading: const Icon(Icons.language),
              onTap: () {
                ref.read(localeProvider.notifier).state = const Locale('vi');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    try {
      final path = await ref.read(exportServiceProvider).exportCsv();
      await ref.read(exportServiceProvider).shareFile(path);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(appStringsProvider).exportSuccess), backgroundColor: AppColors.accent),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _exportExcel(BuildContext context, WidgetRef ref) async {
    try {
      final path = await ref.read(exportServiceProvider).exportExcel();
      await ref.read(exportServiceProvider).shareFile(path);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(appStringsProvider).exportSuccess), backgroundColor: AppColors.accent),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

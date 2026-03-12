import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../core/export/export_service.dart';
import '../../../core/backup_restore/backup_restore_service.dart';
import '../../../core/sheets/google_sheets_sync_service.dart';
import '../../dashboard/providers/dashboard_providers.dart';

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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.backup),
            title: Text(s.backup, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(s.backupDesc, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            onTap: () => _createBackup(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text(s.restore, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(s.restoreDesc, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            onTap: () => _restoreFromBackup(context, ref),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.link),
            title: Text(s.syncUrlSetting, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const _SyncUrlSubtitle(),
            onTap: () => _showSyncUrlDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_upload),
            title: Text(s.syncToGoogleSheets, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(s.syncSheetsHint, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            onTap: () => _syncToGoogleSheetsDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _showSyncUrlDialog(BuildContext context, WidgetRef ref) async {
    final s = ref.read(appStringsProvider);
    final service = ref.read(googleSheetsSyncServiceProvider);
    final current = await service.getSyncUrl();
    if (!context.mounted) return;
    final controller = TextEditingController(text: current ?? '');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.syncUrlSetting),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: s.syncUrlHint,
            border: const OutlineInputBorder(),
          ),
          maxLines: 2,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.back),
          ),
          FilledButton(
            onPressed: () async {
              await service.setSyncUrl(controller.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.syncUrlSaved), backgroundColor: AppColors.accent),
                );
              }
            },
            child: Text(s.save),
          ),
        ],
      ),
    );
  }

  Future<void> _syncToGoogleSheetsDialog(BuildContext context, WidgetRef ref) async {
    final s = ref.read(appStringsProvider);
    if (!context.mounted) return;
    final includeImages = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.syncToGoogleSheets),
        content: Text(s.syncAskImages),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.syncWithoutImagesShort),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.syncWithImagesShort),
          ),
        ],
      ),
    );
    if (includeImages == null || !context.mounted) return;
    await _syncToGoogleSheets(context, ref, includeImages: includeImages);
  }

  Future<void> _syncToGoogleSheets(BuildContext context, WidgetRef ref, {required bool includeImages}) async {
    final s = ref.read(appStringsProvider);
    try {
      await ref.read(googleSheetsSyncServiceProvider).syncViaAppsScript(includeImages: includeImages);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.syncToSheetsSuccess),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.syncToSheetsError}: $e'), backgroundColor: AppColors.error),
        );
      }
    }
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

  Future<void> _createBackup(BuildContext context, WidgetRef ref) async {
    final s = ref.read(appStringsProvider);
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.backupCreating), duration: const Duration(seconds: 1)),
        );
      }
      final zipPath = await ref.read(backupRestoreServiceProvider).createBackupZip();
      if (!context.mounted) return;
      await Share.shareXFiles([XFile(zipPath)], text: 'SwiftKeep backup');
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(s.backupSuccess),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.backupSavedAt, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                SelectableText(zipPath, style: TextStyle(fontSize: 12, color: Colors.grey[800])),
                const SizedBox(height: 10),
                Text(s.backupFolderHint, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: zipPath));
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.pathCopied), backgroundColor: AppColors.accent),
                  );
                }
              },
              child: Text(s.copyPath),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await Share.shareXFiles([XFile(zipPath)], text: 'SwiftKeep backup');
              },
              child: Text(s.shareAgain),
            ),
            FilledButton(
              onPressed: () async {
                final selectedDir = await FilePicker.platform.getDirectoryPath(dialogTitle: s.pickFolderToSave);
                if (selectedDir == null || selectedDir.isEmpty) return;
                try {
                  final zipFile = File(zipPath);
                  if (!await zipFile.exists()) return;
                  final destPath = p.join(selectedDir, p.basename(zipPath));
                  await zipFile.copy(destPath);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(s.savedToAccessible),
                        backgroundColor: AppColors.accent,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: Text(s.saveToFolder),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _restoreFromBackup(BuildContext context, WidgetRef ref) async {
    final s = ref.read(appStringsProvider);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null || path.isEmpty) return;
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.restore),
        content: Text(s.restoreConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.back)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.restore),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(backupRestoreServiceProvider).restoreFromZip(path);
      ref.invalidate(totalItemsProvider);
      ref.invalidate(totalCategoriesProvider);
      ref.invalidate(lowStockCountProvider);
      ref.invalidate(recentActivityProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.restoreSuccess), backgroundColor: AppColors.accent),
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

class _SyncUrlSubtitle extends ConsumerWidget {
  const _SyncUrlSubtitle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.read(appStringsProvider);
    return FutureBuilder<String?>(
      future: ref.read(googleSheetsSyncServiceProvider).getSyncUrl(),
      builder: (context, snap) {
        final style = TextStyle(fontSize: 12, color: Colors.grey[600]);
        if (!snap.hasData) return Text(s.syncUrlHint, style: style);
        final url = snap.data;
        if (url == null || url.isEmpty) return Text(s.syncUrlNotSet, style: style);
        final display = url.length > 50 ? '${url.substring(0, 50)}...' : url;
        return Text(display, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
      },
    );
  }
}

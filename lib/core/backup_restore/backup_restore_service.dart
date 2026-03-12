import 'dart:convert' show utf8, jsonEncode;
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../providers/database_provider.dart';

const _dbFileName = 'swift_keep.db';
const _imagesDirName = 'swift_keep_items';
const _manifestName = 'manifest.json';
/// Tên thư mục con chứa backup (trong Downloads hoặc app documents).
const backupFolderName = 'SwiftKeepBackups';

final backupRestoreServiceProvider = Provider<BackupRestoreService>((ref) {
  return BackupRestoreService(ref);
});

class BackupRestoreService {
  BackupRestoreService(this._ref);
  final Ref _ref;

  Future<String> _appDocumentsPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  /// Thư mục lưu backup: ưu tiên external storage (Downloads) để user truy cập được bằng File Manager; không được thì fallback app documents.
  Future<String> getBackupDirectoryPath() async {
    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        final dir = Directory(p.join(downloads.path, backupFolderName));
        if (!await dir.exists()) await dir.create(recursive: true);
        return dir.path;
      }
    } catch (_) {}
    final base = await _appDocumentsPath();
    final dir = Directory(p.join(base, backupFolderName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  /// Tạo file ZIP backup. Lưu vào Downloads/SwiftKeepBackups (hoặc app documents nếu không có Downloads). Trả về đường dẫn file zip.
  Future<String> createBackupZip() async {
    final basePath = await _appDocumentsPath();
    final dbFile = File(p.join(basePath, _dbFileName));
    final imagesDir = Directory(p.join(basePath, _imagesDirName));

    if (!await dbFile.exists()) {
      throw StateError('Database file not found');
    }

    final backupDir = await getBackupDirectoryPath();
    final zipPath = p.join(backupDir, 'swift_keep_backup_${DateTime.now().millisecondsSinceEpoch}.zip');

    final encoder = ZipFileEncoder();
    encoder.create(zipPath);

    encoder.addFile(dbFile, _dbFileName);

    if (await imagesDir.exists()) {
      await for (final entity in imagesDir.list()) {
        if (entity is File) {
          final relativePath = p.join(_imagesDirName, p.basename(entity.path));
          encoder.addFile(entity, relativePath);
        }
      }
    }

    final manifest = {
      'app': 'swift_keep',
      'version': '1.0.0',
      'createdAt': DateTime.now().toIso8601String(),
    };
    final tempDir = await Directory.systemTemp.createTemp('swift_keep_manifest_');
    final manifestFile = File(p.join(tempDir.path, _manifestName));
    await manifestFile.writeAsString(jsonEncode(manifest), encoding: utf8);
    encoder.addFile(manifestFile, _manifestName);
    try { await tempDir.delete(recursive: true); } catch (_) {}

    encoder.close();
    return zipPath;
  }

  /// Khôi phục từ file ZIP. Đóng DB hiện tại, thay db + ảnh, invalidate để app dùng DB mới.
  Future<void> restoreFromZip(String zipPath) async {
    final zipFile = File(zipPath);
    if (!await zipFile.exists()) {
      throw StateError('Backup file not found');
    }

    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    if (archive.isEmpty) throw StateError('Invalid backup zip');

    final basePath = await _appDocumentsPath();
    final tempDir = await Directory.systemTemp.createTemp('swift_keep_restore_');
    try {
      for (final file in archive) {
        if (file.isFile) {
          final outPath = p.join(tempDir.path, file.name);
          final outFile = File(outPath);
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        }
      }

      final db = _ref.read(databaseProvider);
      await db.close();
      _ref.invalidate(databaseProvider);

      final extractedDb = File(p.join(tempDir.path, _dbFileName));
      if (!await extractedDb.exists()) throw StateError('Backup does not contain database');
      final targetDb = File(p.join(basePath, _dbFileName));
      await extractedDb.copy(targetDb.path);

      final extractedImagesDir = Directory(p.join(tempDir.path, _imagesDirName));
      final targetImagesDir = Directory(p.join(basePath, _imagesDirName));
      if (await targetImagesDir.exists()) {
        await for (final f in targetImagesDir.list()) {
          if (f is File) await f.delete();
        }
      }
      if (await extractedImagesDir.exists()) {
        await targetImagesDir.create(recursive: true);
        await for (final entity in extractedImagesDir.list()) {
          if (entity is File) {
            await entity.copy(p.join(targetImagesDir.path, p.basename(entity.path)));
          }
        }
      }
    } finally {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  }
}

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Saves images locally and returns file path. Used for item primary + extra images.
class ImageStorage {
  static const _uuid = Uuid();
  static const _itemImagesDir = 'swift_keep_items';

  static Future<String> saveItemImage(File file) async {
    final dir = await _itemsImagesDirectory();
    final name = '${_uuid.v4()}${p.extension(file.path)}';
    final dest = File(p.join(dir.path, name));
    await file.copy(dest.path);
    return dest.path;
  }

  static Future<Directory> _itemsImagesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, _itemImagesDir));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<void> deleteImage(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}

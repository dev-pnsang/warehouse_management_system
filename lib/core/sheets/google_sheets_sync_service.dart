import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../providers/database_provider.dart';

const _keySyncUrl = 'google_sheets_apps_script_url';

final googleSheetsSyncServiceProvider =
    Provider<GoogleSheetsSyncService>((ref) {
  return GoogleSheetsSyncService(ref.watch(databaseProvider));
});

/// Gửi dữ liệu Items + Categories lên Google Sheets thông qua Apps Script Web App.
/// URL được lưu trong Cài đặt (SharedPreferences), không hardcode trong code.
class GoogleSheetsSyncService {
  GoogleSheetsSyncService(this._db);

  final AppDatabase _db;

  Future<String?> getSyncUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySyncUrl);
  }

  Future<void> setSyncUrl(String url) async {
    final trimmed = url.trim();
    final prefs = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      await prefs.remove(_keySyncUrl);
    } else {
      await prefs.setString(_keySyncUrl, trimmed);
    }
  }

  /// Log ra Debug Console (VS Code, Android Studio) và adb logcat / Xcode console.
  static void _log(String message) {
    debugPrint('[Sync] $message');
  }

  /// Đọc ảnh từ [imagePath], resize (max [maxWidth]), encode JPEG quality [jpegQuality], trả về base64 hoặc null.
  /// Giá trị nhỏ hơn giúp giảm payload POST (Apps Script giới hạn ~50MB, thực tế dễ timeout nếu quá lớn).
  static Future<String?> _itemImageBase64(String imagePath, {int maxWidth = 120, int jpegQuality = 65}) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final w = decoded.width > maxWidth ? maxWidth : decoded.width;
      final resized = img.copyResize(decoded, width: w);
      final jpeg = img.encodeJpg(resized, quality: jpegQuality);
      return base64Encode(jpeg);
    } catch (_) {
      return null;
    }
  }

  /// Nếu [includeImages] = false: chỉ gửi text (ID, Name, ...), không gửi base64 → payload nhỏ, tránh timeout/chồng ảnh khi dữ liệu nhiều.
  /// Nếu số item > [maxItemsWithImages] và [includeImages] vẫn true, tự tắt gửi ảnh và log cảnh báo.
  Future<void> syncViaAppsScript({bool includeImages = true, int maxItemsWithImages = 40}) async {
    _log('Bắt đầu đồng bộ... (includeImages=$includeImages)');
    final url = await getSyncUrl();
    if (url == null || url.isEmpty) {
      _log('Lỗi: Chưa cấu hình URL đồng bộ.');
      throw StateError('Chưa cấu hình URL đồng bộ. Vào Cài đặt → Cấu hình URL đồng bộ.');
    }
    final urlSuffix = url.length > 40 ? '...${url.substring(url.length - 40)}' : url;
    _log('URL: $urlSuffix');

    final items = await _db.itemsDao.getAll();
    final categories = await _db.categoriesDao.getAll();
    final locations = await _db.locationsDao.getAll();
    _log('Đã lấy dữ liệu: ${items.length} items, ${categories.length} categories, ${locations.length} locations');
    final catMap = {for (var c in categories) c.id: c.name};
    final locMap = {for (var l in locations) l.id: l.name};

    var sendImages = includeImages;
    if (items.length > maxItemsWithImages && sendImages) {
      _log('Quá $maxItemsWithImages item → tắt gửi ảnh để giảm dung lượng. Chỉ đồng bộ danh sách.');
      sendImages = false;
    }
    const maxThumbnailWidth = 120;
    const jpegQuality = 65;
    final itemList = <Map<String, dynamic>>[];
    for (final i in items) {
      final map = <String, dynamic>{
        'id': i.id,
        'name': i.name ?? '',
        'quantity': i.quantity,
        'category': i.categoryId != null ? (catMap[i.categoryId] ?? '') : '',
        'barcode': i.barcode ?? '',
        'notes': i.notes ?? '',
        'position':
            i.locationId != null ? (locMap[i.locationId] ?? '') : '',
        'createdAt': i.createdAt.toIso8601String(),
      };
      if (sendImages) {
        final b64 = await _itemImageBase64(i.imagePath, maxWidth: maxThumbnailWidth, jpegQuality: jpegQuality);
        if (b64 != null) map['imageBase64'] = b64;
      }
      itemList.add(map);
    }
    final withImage = itemList.where((m) => m.containsKey('imageBase64')).length;
    _log('Gửi kèm ảnh: $withImage/${items.length} items');
    final payload = <String, dynamic>{
      'items': itemList,
      'categories': [
        for (final c in categories)
          {
            'id': c.id,
            'name': c.name,
          },
      ],
      // Sheet Locations: danh sách vị trí (Position) giống sheet Categories
      'locations': [
        for (final l in locations)
          {
            'id': l.id,
            'name': l.name,
            'parentId': l.parentId,
          },
      ],
    };
    final bodyBytes = utf8.encode(jsonEncode(payload));
    _log('Payload size: ${bodyBytes.length} bytes');

    http.Response resp;
    try {
      _log('Đang gửi POST...');
      resp = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: bodyBytes,
      );

      // Apps Script trả 302; URL đích (script.googleusercontent.com) chỉ chấp nhận GET.
      // Dữ liệu đã được gửi bằng POST ở trên; GET theo Location để lấy response của script.
      if (resp.statusCode == 301 || resp.statusCode == 302) {
        final location = resp.headers['location'];
        _log('Nhận redirect ${resp.statusCode}, GET theo Location để lấy kết quả.');
        if (location != null && location.isNotEmpty) {
          resp = await http.get(Uri.parse(location));
        }
      }
    } catch (e, st) {
      _log('Lỗi gửi request: $e');
      _log('Stack: $st');
      rethrow;
    }

    _log('Response: statusCode=${resp.statusCode}, body=${resp.body.length > 200 ? '${resp.body.substring(0, 200)}...' : resp.body}');
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      _log('Lỗi HTTP ${resp.statusCode}: ${resp.body}');
      throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
    }
    try {
      final json = jsonDecode(resp.body) as Map<String, dynamic>?;
      if (json != null) {
        if (json['status'] == 'error') {
          _log('Script lỗi: ${json['message']}');
          throw Exception('Script: ${json['message']}');
        }
        final received = json['itemsReceived'] as int?;
        if (received != null && received != items.length) {
          _log('Cảnh báo: script nhận $received items, app gửi ${items.length}. Kiểm tra URL và script.');
        }
        final imagesInserted = json['imagesInserted'] as int?;
        if (imagesInserted != null) _log('Script đã chèn ảnh: $imagesInserted');
      }
    } catch (e) {
      if (e is Exception) rethrow;
    }
    _log('Đồng bộ thành công.');
  }
}

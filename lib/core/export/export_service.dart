import 'dart:convert' show utf8;
import 'dart:io';
import 'package:excel/excel.dart' show Excel, TextCellValue, IntCellValue, DateTimeCellValue;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../providers/database_provider.dart';

final exportServiceProvider = Provider<ExportService>((ref) {
  final db = ref.watch(databaseProvider);
  return ExportService(db);
});

class ExportService {
  ExportService(this._db);
  final AppDatabase _db;

  Future<String> _getExportPath(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$filename';
  }

  Future<String> exportCsv() async {
    final items = await _db.itemsDao.getAll();
    final categories = await _db.categoriesDao.getAll();
    final catMap = {for (var c in categories) c.id: c.name};

    final sb = StringBuffer();
    sb.writeln('id,name,quantity,category,barcode,notes,created_at');
    for (final i in items) {
      final name = (i.name ?? '').replaceAll('"', '""');
      final notes = (i.notes ?? '').replaceAll('"', '""');
      final cat = i.categoryId != null ? (catMap[i.categoryId] ?? '') : '';
      sb.writeln('${i.id},"$name",${i.quantity},"$cat","${i.barcode ?? ''}","$notes",${i.createdAt.toIso8601String()}');
    }
    final path = await _getExportPath('swift_keep_${DateTime.now().millisecondsSinceEpoch}.csv');
    await File(path).writeAsString(sb.toString(), encoding: utf8);
    return path;
  }

  Future<String> exportExcel() async {
    final items = await _db.itemsDao.getAll();
    final categories = await _db.categoriesDao.getAll();
    final catMap = {for (var c in categories) c.id: c.name};

    final excel = Excel.createExcel();
    final defaultName = excel.getDefaultSheet();
    if (defaultName != null && defaultName != 'Items') {
      excel.rename(defaultName, 'Items');
    }
    final headerRow = [
      TextCellValue('ID'),
      TextCellValue('Name'),
      TextCellValue('Quantity'),
      TextCellValue('Category'),
      TextCellValue('Barcode'),
      TextCellValue('Notes'),
      TextCellValue('Created'),
    ];
    if (defaultName == null) {
      excel.insertRowIterables('Items', headerRow, 0);
    } else {
      excel.appendRow('Items', headerRow);
    }
    for (final i in items) {
      final cat = i.categoryId != null ? (catMap[i.categoryId] ?? '') : '';
      excel.appendRow('Items', [
        IntCellValue(i.id),
        TextCellValue(i.name ?? ''),
        IntCellValue(i.quantity),
        TextCellValue(cat),
        TextCellValue(i.barcode ?? ''),
        TextCellValue(i.notes ?? ''),
        DateTimeCellValue.fromDateTime(i.createdAt),
      ]);
    }
    final path = await _getExportPath('swift_keep_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    final file = File(path);
    final bytes = excel.encode();
    if (bytes == null) throw StateError('Excel encode returned null');
    await file.writeAsBytes(bytes);
    return path;
  }

  Future<void> shareFile(String path) async {
    await Share.shareXFiles([XFile(path)]);
  }
}

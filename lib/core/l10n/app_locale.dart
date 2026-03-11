import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));

class AppStrings {
  AppStrings(this.locale);
  final Locale locale;
  bool get isVi => locale.languageCode == 'vi';

  String get appName => 'SwiftKeep';
  String get dashboard => isVi ? 'Tổng quan' : 'Dashboard';
  String get items => isVi ? 'Vật phẩm' : 'Items';
  String get categories => isVi ? 'Danh mục' : 'Categories';
  String get wishlist => isVi ? 'Mục ưa thích' : 'Wishlist';
  String get locations => isVi ? 'Vị trí' : 'Locations';
  String get quickAdd => isVi ? 'Thêm nhanh' : 'Quick Add';
  String get searchItems => isVi ? 'Tìm vật phẩm...' : 'Search items...';
  String get totalItems => isVi ? 'Tổng vật phẩm' : 'Total Items';
  String get totalCategories => isVi ? 'Danh mục' : 'Categories';
  String get lowStock => isVi ? 'Sắp hết' : 'Low Stock';
  String get recentActivity => isVi ? 'Hoạt động gần đây' : 'Recent Activity';
  String get viewAll => isVi ? 'Xem tất cả' : 'View all';
  String get noItemsYet => isVi ? 'Chưa có vật phẩm. Nhấn + để thêm!' : 'No items yet. Tap + to add!';
  String get saveInstantly => isVi ? 'LƯU NGAY' : 'SAVE INSTANTLY';
  String get itemSaved => isVi ? 'Đã lưu!' : 'Item saved!';
  String get takePhoto => isVi ? 'Chụp ảnh' : 'Take photo';
  String get capture => isVi ? 'Chụp' : 'Capture';
  String get pleaseTakePhoto => isVi ? 'Hãy chụp ảnh trước' : 'Please take a photo first';
  String get noCategories => isVi ? 'Chưa có danh mục. Thêm trong Danh mục.' : 'No categories. Add one in Categories.';
  String get youOwnThis => isVi ? 'Bạn đã có vật phẩm này!' : 'You already own this item!';
  String get addItem => isVi ? 'Thêm vật phẩm' : 'Add item';
  String get export => isVi ? 'Xuất file' : 'Export';
  String get exportCsv => isVi ? 'Xuất CSV' : 'Export CSV';
  String get exportExcel => isVi ? 'Xuất Excel' : 'Export Excel';
  String get language => isVi ? 'Ngôn ngữ' : 'Language';
  String get english => 'English';
  String get vietnamese => 'Tiếng Việt';
  String get settings => isVi ? 'Cài đặt' : 'Settings';
  String get exportSuccess => isVi ? 'Đã xuất file' : 'File exported';
  String get back => isVi ? 'Quay lại' : 'Back';
  String get syncToGoogleSheets => isVi ? 'Đồng bộ lên Google Sheets' : 'Sync to Google Sheets';
  String get syncToSheetsSuccess => isVi ? 'Đã đồng bộ lên Google Sheets (Apps Script)' : 'Synced to Google Sheets (Apps Script)';
  String get syncToSheetsSignInRequired => isVi ? 'Cần cấu hình URL Apps Script trong mã nguồn' : 'Configure Apps Script URL in code first';
  String get syncToSheetsError => isVi ? 'Lỗi đồng bộ' : 'Sync error';
  String get open => isVi ? 'Mở' : 'Open';
  String get syncUrlSetting => isVi ? 'Cấu hình URL đồng bộ' : 'Sync URL';
  String get syncUrlHint => isVi ? 'Dán URL Web App từ Google Apps Script' : 'Paste Web App URL from Google Apps Script';
  String get syncUrlSaved => isVi ? 'Đã lưu URL' : 'URL saved';
  String get syncUrlNotSet => isVi ? 'Chưa cấu hình URL' : 'URL not set';
  String get save => isVi ? 'Lưu' : 'Save';
  String get itemName => isVi ? 'Tên vật phẩm' : 'Item name';
  String get itemNameHint => isVi ? 'Nhập tên (tùy chọn)' : 'Enter name (optional)';
  String get quantity => isVi ? 'Số lượng' : 'Quantity';
  String get selectLocation => isVi ? 'Vị trí lưu' : 'Storage location';
  String get noLocation => isVi ? 'Không chọn' : 'None';
}

final appStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider);
  return AppStrings(locale);
});

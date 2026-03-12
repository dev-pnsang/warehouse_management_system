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
  String get syncWithImages => isVi ? 'Đồng bộ có ảnh (tối ~40 item)' : 'Sync with images (~40 items max)';
  String get syncWithoutImages => isVi ? 'Chỉ danh sách (không ảnh, ít dung lượng)' : 'List only (no images, smaller payload)';
  String get syncSheetsHint => isVi ? 'Đồng bộ lên sheet có cột Position. Hỏi có gửi kèm ảnh mỗi lần sync.' : 'Sync includes Position column. You are asked whether to include images each time.';
  String get syncAskImages =>
      isVi ? 'Bạn có muốn gửi kèm ảnh lên Google Sheets?\n\nCó ảnh: payload lớn, dễ chậm khi nhiều item.\nChỉ danh sách: nhanh, ít dung lượng.' : 'Include images in the sync?\n\nWith images: larger payload, may be slow with many items.\nList only: faster, smaller payload.';
  String get syncWithImagesShort => isVi ? 'Có, gửi ảnh' : 'Yes, with images';
  String get syncWithoutImagesShort => isVi ? 'Không, chỉ danh sách' : 'No, list only';
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
  String get backup => isVi ? 'Sao lưu (ZIP)' : 'Backup (ZIP)';
  String get backupDesc => isVi ? 'Database + ảnh, chia sẻ hoặc lưu' : 'Database + images, share or save';
  String get restore => isVi ? 'Khôi phục từ ZIP' : 'Restore from ZIP';
  String get restoreDesc => isVi ? 'Chọn file .zip đã backup' : 'Pick a backup .zip file';
  String get backupSuccess => isVi ? 'Đã tạo file backup' : 'Backup file created';
  String get backupSavedAt => isVi ? 'File đã lưu tại:' : 'File saved at:';
  String get copyPath => isVi ? 'Sao chép đường dẫn' : 'Copy path';
  String get pathCopied => isVi ? 'Đã copy đường dẫn' : 'Path copied';
  String get restoreSuccess => isVi ? 'Đã khôi phục. Màn hình sẽ cập nhật.' : 'Restored. Screen will refresh.';
  String get restoreConfirm => isVi ? 'Khôi phục sẽ thay toàn bộ dữ liệu và ảnh hiện tại. Tiếp tục?' : 'Restore will replace all current data and images. Continue?';
  String get backupCreating => isVi ? 'Đang tạo backup...' : 'Creating backup...';
  String get restorePicking => isVi ? 'Chọn file backup (.zip)' : 'Pick backup file (.zip)';
  String get backupFolderHint => isVi ? 'File được lưu vào Downloads/SwiftKeepBackups (external storage), bạn mở File Manager → Tải xuống → SwiftKeepBackups để copy/sao chép.' : 'File is saved to Downloads/SwiftKeepBackups (external storage). Open File Manager → Downloads → SwiftKeepBackups to access or copy.';
  String get shareAgain => isVi ? 'Chia sẻ' : 'Share';
  String get saveToFolder => isVi ? 'Lưu vào thư mục (Downloads, ...)' : 'Save to folder (Downloads, ...)';
  String get pickFolderToSave => isVi ? 'Chọn thư mục để lưu file backup (vd: Downloads)' : 'Pick folder to save backup (e.g. Downloads)';
  String get savedToAccessible => isVi ? 'Đã lưu bản copy vào thư mục bạn chọn. Bạn có thể mở bằng File Manager.' : 'Copy saved to the folder you chose. You can open it in File Manager.';
}

final appStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider);
  return AppStrings(locale);
});

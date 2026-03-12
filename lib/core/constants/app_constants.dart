/// App-wide constants for Inventory Management.
class AppConstants {
  AppConstants._();

  static const String appName = 'Inventory Management';
  /// Tên hiển thị mặc định trên dashboard (user có thể đổi trong Cài đặt).
  static const String defaultUserName = 'Alex';
  static const int lowStockThreshold = 3;
  static const int recentActivityLimit = 10;
}

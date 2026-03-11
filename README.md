# SwiftKeep – Personal Inventory (Asset Manager)

Ứng dụng Flutter quản lý tài sản cá nhân, tối ưu **nhập liệu nhanh** và **dùng đơn giản**. Offline-first, không cần server.

## Kiến trúc (Clean Architecture)

- **Core**: `lib/core/` – constants (màu, app), theme (Inter, Indigo/Emerald), utils (lưu ảnh), database (Drift + DAOs).
- **Features**: Mỗi feature có `data/` (repository + DAO), `presentation/` (màn hình).
- **State**: Riverpod (providers cho DB, repositories, FutureProvider cho dashboard/wishlist/categories).
- **Database**: Drift (SQLite) – bảng: `items`, `categories`, `locations`, `item_images`, `item_history`, `wishlist`.

## Tính năng chính

1. **Quick Add** – Mở app → "+" → chụp ảnh → nhập số lượng → chọn category → SAVE.
2. **Quản lý item** – Sửa, cập nhật số lượng, thêm ảnh, ghi chú.
3. **Tìm kiếm** – Theo tên, category, barcode, tags.
4. **“You already own this item”** – Khi tìm thấy item trùng (vd: "Router"), hiển thị rõ và số lượng hiện tại.
5. **Categories & Locations** – CRUD categories và vị trí lưu trữ.
6. **Quét barcode** – Dùng camera (mobile_scanner) để tìm hoặc thêm item.
7. **Lịch sử item** – Ghi nhận thay đổi số lượng (vd: "10 Mar: +2").
8. **Wishlist** – Danh sách muốn mua sau.
9. **Dashboard** – Tổng số item, số category, low stock, hoạt động gần đây.

## Chạy dự án

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generate Drift
flutter run
```

**Android**: Project dùng `compileSdk 36`, AGP 8.6, Gradle 8.7 (do `mobile_scanner`). Nếu build lỗi, đảm bảo Android SDK 36 và NDK đã cài; đóng Android Studio / process Gradle khác nếu bị lỗi lock file.

**iOS**: Đã cấu hình quyền camera và photo library trong `Info.plist`.

## Đồng bộ Google Sheets

Trong **Cài đặt** có mục **Đồng bộ lên Google Sheets**. Lần đầu chọn sẽ đăng nhập Google (OAuth), sau đó app tạo một spreadsheet tên **"SwiftKeep Data"** trong tài khoản của bạn với 2 sheet: **Items** (id, name, quantity, category, barcode, notes, created) và **Categories** (id, name). Các lần đồng bộ sau sẽ ghi đè dữ liệu lên cùng file đó.

**Cấu hình (bắt buộc):**

1. Vào [Google Cloud Console](https://console.cloud.google.com/) → tạo project (hoặc chọn project có sẵn).
2. Bật **Google Sheets API**: APIs & Services → Enable APIs → tìm "Google Sheets API" → Enable.
3. Tạo OAuth 2.0 Client ID:
   - **APIs & Services** → **Credentials** → **Create Credentials** → **OAuth client ID**.
   - Application type: **Android** (package name: `com.swiftkeep.swift_keep`, lấy SHA-1 bằng `cd android && ./gradlew signingReport`).
   - Tạo thêm **iOS** client nếu chạy trên iPhone (bundle ID trong Xcode).
4. Không cần nhúng file JSON key vào app; Google Sign-In dùng client ID đã đăng ký theo platform.

## Cấu trúc thư mục `lib/`

```
lib/
  core/
    constants/     # app_colors, app_constants
    theme/         # app_theme
    utils/         # image_storage
    database/      # app_database.dart + app_database.g.dart, daos/
    providers/     # database_provider
  features/
    items/         # data (items_repository), presentation (quick_add, items_list, item_detail, barcode_scanner)
    categories/    # data, presentation (categories_screen)
    locations/     # data, presentation (locations_screen)
    dashboard/     # providers, presentation (dashboard_screen)
    wishlist/      # data, presentation (wishlist_screen)
  shared/          # app_scaffold
  main.dart
```

## Design

- **App name**: SwiftKeep  
- **Primary**: Indigo `#4F46E5`  
- **Accent (Save/Add)**: Emerald `#10B981`  
- **Background**: `#F8FAFC`  
- **Font**: Inter (Google Fonts)

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

## Đồng bộ Google Sheets (Apps Script)

Trong **Cài đặt** → **Cấu hình URL đồng bộ**: dán URL Web App từ Google Apps Script. **Đồng bộ lên Google Sheets** sẽ gửi Items (kèm ảnh thumbnail base64) và Categories lên sheet. Không cần Google Cloud Console.

**Cách thiết lập:**

1. Tạo (hoặc mở) **đúng** file Google Sheet cần ghi dữ liệu. Script phải mở từ file này (Extensions → Apps Script) thì `getActiveSpreadsheet()` mới trỏ đúng sheet.
2. Trong file Sheet đó: Extensions → Apps Script, dán code bên dưới (hoặc copy toàn bộ `docs/APPS_SCRIPT_GSHEETS.js`) — có cột **Image** và ghi ảnh từ `imageBase64`.
3. Deploy → New deployment → Web app → Execute as: Me, Who has access: Anyone. Copy **Web app URL**.
4. Trong app: Cài đặt → Cấu hình URL đồng bộ → dán URL → Lưu. Sau đó dùng **Đồng bộ lên Google Sheets**.

**Mẫu Apps Script (doPost, có cột ảnh):**

```javascript
function doPost(e) {
  try {
    var data = JSON.parse(e.postData.contents);
    var items = data.items || [];
    var categories = data.categories || [];
    var ss = SpreadsheetApp.getActiveSpreadsheet();

    var itemsSheet = ss.getSheetByName('Items') || ss.insertSheet('Items');
    itemsSheet.clear();
    itemsSheet.setRowHeights(1, Math.max(items.length + 1, 1), 80);
    itemsSheet.getRange(1, 1, 1, 8).setValues([['ID', 'Name', 'Quantity', 'Category', 'Barcode', 'Notes', 'Created', 'Image']]);
    itemsSheet.setColumnWidth(8, 120);
    if (items.length > 0) {
      var rowData = items.map(function(i) {
        return [i.id, i.name || '', i.quantity, i.category || '', i.barcode || '', i.notes || '', i.createdAt || ''];
      });
      itemsSheet.getRange(2, 1, items.length + 1, 7).setValues(rowData);
      for (var r = 0; r < items.length; r++) {
        if (items[r].imageBase64) {
          try {
            var blob = Utilities.newBlob(Utilities.base64Decode(items[r].imageBase64), 'image/jpeg', 'item.jpg');
            itemsSheet.insertImage(blob, 8, r + 2);
          } catch (err) {
            Logger.log('Row ' + (r + 2) + ' image error: ' + err.toString());
          }
        }
      }
    }

    var catSheet = ss.getSheetByName('Categories') || ss.insertSheet('Categories');
    catSheet.clear();
    catSheet.appendRow(['ID', 'Name']);
    if (categories.length > 0) {
      var catRows = categories.map(function(c) { return [c.id, c.name]; });
      catSheet.getRange(2, 1, categories.length + 1, 2).setValues(catRows);
    }

    return ContentService.createTextOutput(JSON.stringify({ status: 'ok' })).setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({ status: 'error', message: String(err) })).setMimeType(ContentService.MimeType.JSON);
  }
}
```

**Nếu đồng bộ thành công nhưng sheet không có dữ liệu / không có ảnh:**  
(1) Trong app, sau khi bấm đồng bộ xem log: `[Sync] Gửi kèm ảnh: X/Y items` và `Response: ... body={"status":"ok","itemsReceived":N,...}`. Nếu **itemsReceived: 0** thì script không nhận được POST body (kiểm tra URL đúng Web App URL dạng `.../exec`, script có kiểm tra `e.postData.contents`).  
(2) Script phải mở từ **chính file Google Sheet** cần ghi (Extensions → Apps Script từ file đó), rồi Deploy.  
(3) Cập nhật script bằng **toàn bộ** mẫu (hoặc `docs/APPS_SCRIPT_GSHEETS.js`), sau đó **Deploy → Manage deployments → Edit → New version → Deploy**.  
(4) Apps Script → Executions: xem log `Items received`, `Spreadsheet`, và lỗi chèn ảnh (nếu có).

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

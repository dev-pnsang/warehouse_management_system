/**
 * SwiftKeep – Đồng bộ lên Google Sheets (Web App doPost).
 * Sheet Items: ID, Name, Quantity, Category, Barcode, Notes, Position (tên vị trí), Created, Image.
 * Sheet Categories + sheet Locations (danh sách vị trí: ID, Name, ParentID).
 * Cách dùng: Mở Google Sheet → Extensions → Apps Script → dán toàn bộ file này →
 * Deploy → New deployment → Web app → Execute as: Me, Who has access: Anyone.
 * Copy Web app URL và dán vào app (Cài đặt → Cấu hình URL đồng bộ).
 */
function doPost(e) {
  try {
    if (!e || !e.postData || !e.postData.contents) {
      return ContentService.createTextOutput(
        JSON.stringify({
          status: "error",
          message:
            "No POST body. Use POST with Content-Type: application/json.",
          itemsReceived: 0,
        }),
      ).setMimeType(ContentService.MimeType.JSON);
    }
    var data = JSON.parse(e.postData.contents);
    var items = data.items || [];
    var categories = data.categories || [];
    var locations = data.locations || [];
    Logger.log(
      "Items received: " +
        items.length +
        ", categories: " +
        (categories.length || 0) +
        ", locations: " +
        locations.length,
    );
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    Logger.log("Spreadsheet: " + ss.getId() + " - " + ss.getUrl());

    var itemsSheet = ss.getSheetByName("Items") || ss.insertSheet("Items");
    itemsSheet.clear();
    try {
      var existingImages = itemsSheet.getImages();
      for (var k = 0; k < existingImages.length; k++) {
        try {
          existingImages[k].remove();
        } catch (remErr) {
          Logger.log("remove image " + k + ": " + remErr);
        }
      }
    } catch (imgErr) {
      Logger.log("getImages/remove: " + imgErr);
    }
    // Không set toàn bộ hàng = 80px (gây row bị to). Chỉ hàng có ảnh mới cần cao.
    var DEFAULT_ROW_HEIGHT = 21; // px – gần mặc định Sheets
    var ROW_HEIGHT_WITH_IMAGE = 80; // đủ chứa ảnh ~70px + padding
    // 9 cột text + ảnh ở cột 9
    itemsSheet
      .getRange(1, 1, 1, 9)
      .setValues([
        [
          "ID",
          "Name",
          "Quantity",
          "Category",
          "Barcode",
          "Notes",
          "Position",
          "Created",
          "Image",
        ],
      ]);
    itemsSheet.setColumnWidth(9, 120);
    if (items.length > 0) {
      var rowData = items.map(function (i) {
        return [
          i.id,
          i.name || "",
          i.quantity,
          i.category || "",
          i.barcode || "",
          i.notes || "",
          i.position || "",
          i.createdAt || "",
        ];
      });
      itemsSheet.getRange(2, 1, items.length, 8).setValues(rowData);
      for (var r = 0; r < items.length; r++) {
        if (items[r].imageBase64) {
          try {
            var bytes = Utilities.base64Decode(items[r].imageBase64);
            var blob = Utilities.newBlob(
              bytes,
              "image/jpeg",
              "item_" + r + ".jpg",
            );
            var imgW = 110,
              imgH = 70;
            itemsSheet
              .insertImage(blob, 9, r + 2)
              .setWidth(imgW)
              .setHeight(imgH);
          } catch (err) {
            Logger.log("Row " + (r + 2) + " image: " + err.toString());
          }
        }
      }
      // Header gọn; từng hàng dữ liệu: chỉ cao khi có ảnh
      itemsSheet.setRowHeight(1, DEFAULT_ROW_HEIGHT);
      for (var hr = 0; hr < items.length; hr++) {
        itemsSheet.setRowHeight(
          hr + 2,
          items[hr].imageBase64 ? ROW_HEIGHT_WITH_IMAGE : DEFAULT_ROW_HEIGHT,
        );
      }
    } else {
      itemsSheet.setRowHeight(1, DEFAULT_ROW_HEIGHT);
    }

    var catSheet =
      ss.getSheetByName("Categories") || ss.insertSheet("Categories");
    catSheet.clear();
    catSheet.appendRow(["ID", "Name"]);
    if (categories.length > 0) {
      var catRows = categories.map(function (c) {
        return [c.id, c.name];
      });
      catSheet.getRange(2, 1, categories.length, 2).setValues(catRows);
    }

    // Sheet Locations (Position): danh sách vị trí – ID, Name, ParentID
    var locSheet =
      ss.getSheetByName("Locations") || ss.insertSheet("Locations");
    locSheet.clear();
    locSheet.appendRow(["ID", "Name", "ParentID"]);
    if (locations.length > 0) {
      var locRows = locations.map(function (loc) {
        return [
          loc.id,
          loc.name || "",
          loc.parentId != null ? loc.parentId : "",
        ];
      });
      locSheet.getRange(2, 1, locations.length, 3).setValues(locRows);
    }

    return ContentService.createTextOutput(
      JSON.stringify({
        status: "ok",
        itemsReceived: items.length,
        imagesInserted: (function () {
          var n = 0;
          for (var r = 0; r < items.length; r++) {
            if (items[r].imageBase64) n++;
          }
          return n;
        })(),
      }),
    ).setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    Logger.log("doPost error: " + err.toString());
    return ContentService.createTextOutput(
      JSON.stringify({
        status: "error",
        message: String(err),
      }),
    ).setMimeType(ContentService.MimeType.JSON);
  }
}

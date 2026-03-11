/**
 * SwiftKeep – Đồng bộ lên Google Sheets (Web App doPost).
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
    Logger.log(
      "Items received: " +
        items.length +
        ", categories: " +
        (categories.length || 0),
    );
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    Logger.log("Spreadsheet: " + ss.getId() + " - " + ss.getUrl());

    var itemsSheet = ss.getSheetByName("Items") || ss.insertSheet("Items");
    itemsSheet.clear();
    itemsSheet.setRowHeights(1, Math.max(items.length + 1, 1), 80);
    itemsSheet
      .getRange(1, 1, 1, 8)
      .setValues([
        [
          "ID",
          "Name",
          "Quantity",
          "Category",
          "Barcode",
          "Notes",
          "Created",
          "Image",
        ],
      ]);
    itemsSheet.setColumnWidth(8, 120);
    if (items.length > 0) {
      var rowData = items.map(function (i) {
        return [
          i.id,
          i.name || "",
          i.quantity,
          i.category || "",
          i.barcode || "",
          i.notes || "",
          i.createdAt || "",
        ];
      });
      itemsSheet.getRange(2, 1, items.length, 7).setValues(rowData);
      for (var r = 0; r < items.length; r++) {
        if (items[r].imageBase64) {
          try {
            var bytes = Utilities.base64Decode(items[r].imageBase64);
            var blob = Utilities.newBlob(
              bytes,
              "image/jpeg",
              "item_" + r + ".jpg",
            );
            // Giới hạn kích thước để ảnh nằm trong ô (cột H rộng 120px, hàng cao 80px)
            var imgW = 110,
              imgH = 70;
            itemsSheet
              .insertImage(blob, 8, r + 2)
              .setWidth(imgW)
              .setHeight(imgH);
          } catch (err) {
            Logger.log("Row " + (r + 2) + " image: " + err.toString());
          }
        }
      }
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

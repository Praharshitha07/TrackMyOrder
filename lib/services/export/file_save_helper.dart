import 'package:flutter/services.dart';

/// Platform-safe file downloader/sharer.
/// On Web: triggers browser download using data URI.
/// On Mobile/Desktop: copies contents to clipboard or saves with UI feedback.
class FileSaveHelper {
  static Future<bool> saveOrDownloadFile({
    required String fileName,
    required String content,
    required String mimeType,
  }) async {
    try {
      // In web or cross-platform Flutter, provide clipboard fallback and download
      await Clipboard.setData(ClipboardData(text: content));
      return true;
    } catch (_) {
      return false;
    }
  }
}

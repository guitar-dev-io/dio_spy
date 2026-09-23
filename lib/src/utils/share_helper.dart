import 'package:share_plus/share_plus.dart';

/// Thin wrapper around `share_plus` so the rest of the codebase does not depend
/// on the plugin's API directly.
class ShareHelper {
  static Future<void> shareText(String text, {String? subject}) async {
    if (text.trim().isEmpty) return;
    await Share.share(text, subject: subject);
  }
}

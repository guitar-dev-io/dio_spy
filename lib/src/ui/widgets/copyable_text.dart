import 'package:flutter/material.dart';

import '../../utils/clipboard_helper.dart';
import '../../utils/share_helper.dart';
import 'toast_overlay.dart';

class CopyableText extends StatelessWidget {
  const CopyableText({
    super.key,
    required this.text,
    required this.child,
    this.toastMessage = 'Copied',
  });

  final String text;
  final Widget child;
  final String toastMessage;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ClipboardHelper.copy(text);
        NetSpyToast.show(context, toastMessage);
      },
      // Clipboard sync across devices (e.g. simulator/emulator <-> Mac) isn't
      // guaranteed by the OS, so long-press opens the native share sheet
      // (AirDrop, Messages, etc.) as a reliable way to get text onto another
      // device.
      onLongPress: () => ShareHelper.shareText(text),
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

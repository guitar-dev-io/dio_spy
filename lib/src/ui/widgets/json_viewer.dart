import 'package:flutter/material.dart';

import '../../utils/clipboard_helper.dart';
import '../../utils/formatters.dart';
import '../theme.dart';
import 'toast_overlay.dart';
import 'package:json_visualizer/json_visualizer.dart';

class JsonViewer extends StatelessWidget {
  const JsonViewer({super.key, required this.body, this.maxLength = 100000});

  final dynamic body;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    final formatted = NetSpyFormatters.formatBody(body);
    if (formatted.isEmpty) {
      return Text('Empty', style: NetSpyTypo.t16.secondary);
    }

    if (formatted.length > maxLength) {
      return _LargeBodyWidget(
        formattedBody: formatted,
        size: NetSpyFormatters.formatBytes(formatted.length),
      );
    }

    // The interactive visualizer walks and encodes the raw body, which throws
    // if it holds a non-encodable value (e.g. a Color). Only use it for bodies
    // we know are JSON-safe, otherwise fall back to the formatted text.
    if (!NetSpyFormatters.isJsonEncodable(body)) {
      return _RawBodyWidget(formattedBody: formatted);
    }

    return JsonVisualizer(
      data: body,
      expandDepth: 3,
      fontSize: 14,
      onCopied: () => NetSpyToast.show(context),
    );
  }
}

/// Plain, copyable text view used when a body cannot be safely rendered by the
/// interactive JSON viewer.
class _RawBodyWidget extends StatelessWidget {
  const _RawBodyWidget({required this.formattedBody});
  final String formattedBody;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              ClipboardHelper.copy(formattedBody);
              NetSpyToast.show(context);
            },
            child: const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.copy_rounded,
                  size: 16, color: NetSpyColors.textTertiary),
            ),
          ),
        ),
        SelectableText(formattedBody, style: NetSpyTypo.t12.secondary),
      ],
    );
  }
}

class _LargeBodyWidget extends StatefulWidget {
  const _LargeBodyWidget({required this.formattedBody, required this.size});
  final String formattedBody;
  final String size;

  @override
  State<_LargeBodyWidget> createState() => _LargeBodyWidgetState();
}

class _LargeBodyWidgetState extends State<_LargeBodyWidget> {
  bool _showFull = false;

  @override
  Widget build(BuildContext context) {
    if (_showFull) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                ClipboardHelper.copy(widget.formattedBody);
                NetSpyToast.show(context);
              },
              child: const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.copy_rounded,
                    size: 16, color: NetSpyColors.textTertiary),
              ),
            ),
          ),
          SelectableText(widget.formattedBody, style: NetSpyTypo.t12.secondary),
        ],
      );
    }

    return Column(
      children: [
        Text('Body too large (${widget.size})',
            style: NetSpyTypo.t16.secondary),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _showFull = true),
          child: Text(
            'Show anyway',
            style: NetSpyTypo.t16.w500.primary.copyWith(
              color: NetSpyColors.info,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

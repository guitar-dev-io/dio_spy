import 'package:flutter/material.dart';

import '../../core/dio_spy_config.dart';
import '../../models/http_call.dart';
import '../../utils/formatters.dart';
import '../../utils/header_redactor.dart';
import '../theme.dart';
import '../widgets/json_viewer.dart';
import '../widgets/key_value_row.dart';
import '../widgets/section_card.dart';
import '../widgets/status_chip.dart';

class ResponseTab extends StatefulWidget {
  const ResponseTab({super.key, required this.call, required this.config});
  final NetSpyHttpCall call;
  final NetSpyConfig config;

  @override
  State<ResponseTab> createState() => _ResponseTabState();
}

class _ResponseTabState extends State<ResponseTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.call.loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 2, color: NetSpyColors.primary),
            const SizedBox(height: 12),
            Text('Awaiting response...', style: NetSpyTypo.t16.secondary),
          ],
        ),
      );
    }

    final response = widget.call.response;
    if (response == null) {
      return Center(child: Text('No response data', style: NetSpyTypo.t16.secondary));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        // General
        SectionCard(
          title: 'General',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KVRow(
                label: 'Status',
                valueWidget: StatusChip(statusCode: response.status),
              ),
              KVRow(
                label: 'Received',
                value: NetSpyFormatters.formatDateTime(response.time),
              ),
              KVRow(
                label: 'Duration',
                value: NetSpyFormatters.formatDuration(widget.call.duration),
              ),
              KVRow(
                label: 'Size',
                value: NetSpyFormatters.formatBytes(response.size),
              ),
            ],
          ),
        ),

        // Headers
        if (response.headers.isNotEmpty)
          SectionCard(
            initialExpanded: false,
            title: 'Headers (${response.headers.length})',
            child: ValueListenableBuilder<bool>(
              valueListenable: widget.config.redactSensitive,
              builder: (_, redacting, __) => KVRowGroup(
                entries: HeaderRedactor.redactMap(
                  response.headers,
                  enabled: redacting,
                  sensitiveLower: widget.config.sensitiveHeaders,
                ),
              ),
            ),
          ),

        // Body
        if (_hasBody(response.body))
          SectionCard(
            title: 'Body',
            child: JsonViewer(body: response.body),
          ),

        // Error
        if (widget.call.error != null)
          SectionCard(
            title: 'Error',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: NetSpyColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    widget.call.error!.error?.toString().trim() ?? 'Unknown error',
                    style: NetSpyTypo.t14.copyWith(color: NetSpyColors.error),
                  ),
                ),
                if (widget.call.error!.stackTraceString != null) ...[
                  const SizedBox(height: 8),
                  SectionCard(
                    title: 'Stacktrace',
                    initialExpanded: false,
                    child: SelectableText(
                      widget.call.error!.stackTraceString!.trim(),
                      style: NetSpyTypo.t12.secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  bool _hasBody(dynamic body) {
    if (body == null) return false;
    if (body is String && body.isEmpty) return false;
    return true;
  }
}

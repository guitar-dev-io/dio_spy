import 'package:net_spy/src/ui/widgets/method_chip.dart';
import 'package:flutter/material.dart';

import '../../core/dio_spy_config.dart';
import '../../models/http_call.dart';
import '../../utils/formatters.dart';
import '../../utils/header_redactor.dart';
import '../theme.dart';
import '../widgets/copyable_text.dart';
import '../widgets/json_viewer.dart';
import '../widgets/key_value_row.dart';
import '../widgets/section_card.dart';

class RequestTab extends StatefulWidget {
  const RequestTab({super.key, required this.call, required this.config});
  final NetSpyHttpCall call;
  final NetSpyConfig config;

  @override
  State<RequestTab> createState() => _RequestTabState();
}

class _RequestTabState extends State<RequestTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final request = widget.call.request;
    if (request == null) {
      return Center(child: Text('No request data', style: NetSpyTypo.t16.secondary));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        // General
        SectionCard(
          title: 'General',
          child: Column(
            children: [
              KVRow(
                label: 'Method',
                valueWidget: MethodChip(method: widget.call.method),
              ),
              KVRow(
                label: 'URL',
                value: widget.call.uri,
              ),
              KVRow(
                label: 'Started',
                value: NetSpyFormatters.formatDateTime(request.time),
              ),
              KVRow(
                label: 'Duration',
                value: NetSpyFormatters.formatDuration(widget.call.duration),
              ),
              KVRow(
                label: 'Secure',
                value: widget.call.secure ? 'Yes (https)' : 'No (http)',
              ),
              KVRow(
                label: 'Size',
                value: NetSpyFormatters.formatBytes(request.size),
              ),
            ],
          ),
        ),

        // Headers
        if (request.headers.isNotEmpty)
          SectionCard(
            title: 'Headers (${request.headers.length})',
            child: ValueListenableBuilder<bool>(
              valueListenable: widget.config.redactSensitive,
              builder: (_, redacting, __) => KVRowGroup(
                entries: HeaderRedactor.redactMap(
                  request.headers,
                  enabled: redacting,
                  sensitiveLower: widget.config.sensitiveHeaders,
                ),
              ),
            ),
          ),

        // Cookies
        if (request.cookies.isNotEmpty)
          SectionCard(
            title: 'Cookies (${request.cookies.length})',
            child: ValueListenableBuilder<bool>(
              valueListenable: widget.config.redactSensitive,
              builder: (_, redacting, __) => KVRowGroup(
                entries: HeaderRedactor.redactCookies(
                  request.cookies,
                  enabled: redacting,
                  sensitiveLower: widget.config.sensitiveHeaders,
                ),
              ),
            ),
          ),

        // Query Parameters
        if (request.queryParameters.isNotEmpty)
          SectionCard(
            title: 'Query Parameters (${request.queryParameters.length})',
            child: KVRowGroup(entries: request.queryParameters),
          ),

        // Body
        if (_hasBody(request.body))
          SectionCard(
            title: 'Body',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Form data fields
                if (request.formDataFields != null && request.formDataFields!.isNotEmpty) ...[
                  Text('Fields', style: NetSpyTypo.t16.secondary),
                  const SizedBox(height: 4),
                  ...request.formDataFields!.map(
                    (f) => KVRow(label: f.name, value: f.value),
                  ),
                  const SizedBox(height: 8),
                ],
                // Form data files
                if (request.formDataFiles != null && request.formDataFiles!.isNotEmpty) ...[
                  Text('Files', style: NetSpyTypo.t16.secondary),
                  const SizedBox(height: 4),
                  ...request.formDataFiles!.map(
                    (f) => CopyableText(
                      text: f.fileName,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '${f.fileName} (${f.contentType}, ${NetSpyFormatters.formatBytes(f.length)})',
                          style: NetSpyTypo.t16.secondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Raw body (if not form data)
                if (request.formDataFields == null || request.formDataFields!.isEmpty)
                  JsonViewer(body: request.body),
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

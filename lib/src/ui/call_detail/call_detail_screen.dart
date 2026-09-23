import 'package:flutter/material.dart';

import '../../core/dio_spy_config.dart';
import '../../models/http_call.dart';
import '../../utils/clipboard_helper.dart';
import '../../utils/curl_builder.dart';
import '../../utils/share_helper.dart';
import '../theme.dart';
import '../widgets/toast_overlay.dart';
import 'request_tab.dart';
import 'response_tab.dart';

class CallDetailScreen extends StatefulWidget {
  const CallDetailScreen({super.key, required this.call, this.config});

  final NetSpyHttpCall call;
  final NetSpyConfig? config;

  @override
  State<CallDetailScreen> createState() => _CallDetailScreenState();
}

class _CallDetailScreenState extends State<CallDetailScreen> {
  NetSpyConfig? _fallbackConfig;
  NetSpyConfig get _config => widget.config ?? (_fallbackConfig ??= NetSpyConfig());

  Set<String>? get _activeRedaction =>
      _config.redactSensitive.value ? _config.sensitiveHeaders : null;

  @override
  void dispose() {
    _fallbackConfig?.dispose();
    super.dispose();
  }

  
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: NetSpyTheme.themeData(context),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: _buildAppBar(context),
          body: _buildTabView(),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        '${widget.call.method} ${widget.call.endpoint}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.copy_rounded),
          tooltip: 'Copy as cURL',
          onPressed: () {
            final curl = CurlBuilder.build(widget.call, redactHeaders: _activeRedaction);
            ClipboardHelper.copy(curl);
            NetSpyToast.show(context, 'cURL copied');
          },
        ),
        IconButton(
          icon: const Icon(Icons.ios_share_rounded),
          tooltip: 'Share as cURL',
          onPressed: () {
            ShareHelper.shareText(
              CurlBuilder.build(widget.call, redactHeaders: _activeRedaction),
              subject: '${widget.call.method} ${widget.call.endpoint}',
            );
          },
        ),
      ],
      bottom: const TabBar(
        tabs: [
          Tab(text: 'Request'),
          Tab(text: 'Response'),
        ],
      ),
    );
  }

  Widget _buildTabView() {
    return TabBarView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        RequestTab(call: widget.call, config: _config),
        ResponseTab(call: widget.call, config: _config),
      ],
    );
  }
}

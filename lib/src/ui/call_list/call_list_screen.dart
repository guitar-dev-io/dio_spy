import 'package:flutter/material.dart';

import '../../core/dio_spy_config.dart';
import '../../core/dio_spy_storage.dart';
import '../../models/http_call.dart';
import '../../utils/curl_builder.dart';
import '../../utils/formatters.dart';
import '../../utils/share_helper.dart';
import '../call_detail/call_detail_screen.dart';
import '../theme.dart';
import '../widgets/filter_chips.dart';
import '../widgets/method_chip.dart';
import '../widgets/status_chip.dart';

class CallListScreen extends StatefulWidget {
  const CallListScreen({super.key, required this.storage, this.config, this.onBack});

  final NetSpyStorage storage;
  final NetSpyConfig? config;
  final VoidCallback? onBack;

  @override
  State<CallListScreen> createState() => _CallListScreenState();
}

class _CallListScreenState extends State<CallListScreen> {
  bool _searching = false;
  final _searchController = TextEditingController();
  Set<String> _filters = {};
  String _searchQuery = '';

  /// Fallback config used only when the screen is shown without one (e.g. in
  /// isolated tests). Owned locally so it is disposed here.
  NetSpyConfig? _fallbackConfig;
  NetSpyConfig get _config => widget.config ?? (_fallbackConfig ??= NetSpyConfig());

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fallbackConfig?.dispose();
    super.dispose();
  }

  List<NetSpyHttpCall> _filteredCalls(List<NetSpyHttpCall> calls) {
    return calls.where((call) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final matchesUrl = call.uri.toLowerCase().contains(_searchQuery) ||
            call.endpoint.toLowerCase().contains(_searchQuery) ||
            call.server.toLowerCase().contains(_searchQuery);
        if (!matchesUrl) return false;
      }

      // Chip filters
      if (_filters.isEmpty) return true;

      bool matchesStatus = false;
      bool matchesMethod = false;
      bool hasStatusFilter = false;
      bool hasMethodFilter = false;

      for (final f in _filters) {
        if (['2xx', '3xx', '4xx', '5xx'].contains(f)) {
          hasStatusFilter = true;
          final statusGroup = (call.response?.status ?? -1) ~/ 100;
          if (f == '${statusGroup}xx') matchesStatus = true;
        } else {
          hasMethodFilter = true;
          if (call.method.toUpperCase() == f) matchesMethod = true;
        }
      }

      final statusOk = !hasStatusFilter || matchesStatus;
      final methodOk = !hasMethodFilter || matchesMethod;
      return statusOk && methodOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Widget screen = Theme(
      data: NetSpyTheme.themeData(context),
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Column(
          children: [
            // Search bar
            if (_searching) _buildSearchBox(),

            // Filter chips
            _buildFilterChips(),

            const Divider(height: 1),

            // Call list
            Expanded(
              child: _buildCallListView(),
            ),
          ],
        ),
      ),
    );

    // When used inside NetSpyWrapper, intercept the system back button
    // to close the inspector instead of popping the root route.
    if (widget.onBack != null) {
      screen = PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) widget.onBack!();
        },
        child: screen,
      );
    }

    return screen;
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(_config.title),
      leading: widget.onBack != null
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onBack,
            )
          : null,
      actions: [
        IconButton(
          icon: Icon(_searching ? Icons.search_off : Icons.search),
          onPressed: () {
            setState(() {
              _searching = !_searching;
              if (!_searching) {
                _searchController.clear();
              }
            });
          },
        ),
        PopupMenuButton(
          icon: Icon(Icons.more_vert),
          offset: Offset(-22, 44),
          elevation: 2,
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: () => _config.redactSensitive.value = !_config.redactSensitive.value,
              child: Row(
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: _config.redactSensitive,
                    builder: (_, redacting, __) => Icon(
                      redacting ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      size: 18,
                      color: NetSpyColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Redact headers', style: NetSpyTypo.t14.w500),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => ShareHelper.shareText(
                CurlBuilder.buildAll(
                  widget.storage.calls.value,
                  redactHeaders:
                      _config.redactSensitive.value ? _config.sensitiveHeaders : null,
                ),
              ),
              child: Text(
                'Share All as cURL',
                style: NetSpyTypo.t14.w500,
              ),
            ),
            PopupMenuItem(
              onTap: widget.storage.clear,
              child: Text(
                'Clear All',
                style: NetSpyTypo.t14.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return Container(
      color: NetSpyColors.surface,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: NetSpyTypo.t16.w500.primary,
        decoration: InputDecoration(
          hintText: 'Search by URL...',
          hintStyle: NetSpyTypo.t16.tertiary,
          filled: true,
          fillColor: NetSpyColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: NetSpyColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: NetSpyColors.surface,
      padding: const EdgeInsets.only(bottom: 16),
      child: FilterChips(
        selectedFilters: _filters,
        onChanged: (filters) => setState(() => _filters = filters),
      ),
    );
  }

  Widget _buildCallListView() {
    return ValueListenableBuilder(
      valueListenable: widget.storage.calls,
      builder: (context, calls, _) {
        final filtered = _filteredCalls(calls);

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              calls.isEmpty ? 'No requests yet' : 'No matching requests',
              style: NetSpyTypo.t16.secondary,
            ),
          );
        }

        return Scrollbar(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final call = filtered[index];
              return Dismissible(
                key: ObjectKey(call),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => widget.storage.removeCall(call),
                background: Container(
                  color: NetSpyColors.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(
                    Icons.delete_outline,
                    color: NetSpyColors.textOnPrimary,
                  ),
                ),
                child: _CallListItem(
                  call: call,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CallDetailScreen(call: call, config: _config),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _CallListItem extends StatelessWidget {
  const _CallListItem({required this.call, required this.onTap});

  final NetSpyHttpCall call;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: NetSpyColors.surface),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            // Row 1: Method + Status + Duration + Size
            Row(
              children: [
                MethodChip(method: call.method),
                const SizedBox(width: 8),
                if (call.loading)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else ...[
                  StatusChip(statusCode: call.response?.status),
                  if (call.error != null)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.warning_rounded,
                        size: 16,
                        color: NetSpyColors.error,
                      ),
                    ),
                ],
                const Spacer(),
                if (!call.loading) ...[
                  Text(
                    NetSpyFormatters.formatDuration(call.duration),
                    style: NetSpyTypo.t14.secondary,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('|', style: NetSpyTypo.t14.secondary),
                  ),
                  Text(
                    NetSpyFormatters.formatBytes(call.response?.size ?? 0),
                    style: NetSpyTypo.t14.secondary,
                  ),
                ],
              ],
            ),

            // Row 2: Endpoint
            Text(
              call.endpoint,
              style: NetSpyTypo.t16.w500.copyWith(
                color: call.error != null ? NetSpyColors.error : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Row 3: Server + Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    call.server,
                    style: NetSpyTypo.t12.w500.secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  NetSpyFormatters.formatTime(call.createdTime),
                  style: NetSpyTypo.t12.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

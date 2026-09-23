import 'package:flutter/material.dart';

import '../ui/call_list/call_list_screen.dart';
import '../ui/theme.dart';
import 'dio_spy.dart';

/// A widget that enables the NetSpy inspector overlay.
///
/// Wrap it in your `MaterialApp.builder`. This is the easiest way to use
/// NetSpy: no `navigatorKey` needed, and it shows a draggable floating bubble
/// that opens the inspector on tap (works on device, emulator, desktop, web).
///
/// Example:
/// ```dart
/// MaterialApp(
///   builder: (context, child) => NetSpyWrapper(
///     netSpy: netSpy,
///     child: child!,
///   ),
/// )
/// ```
class NetSpyWrapper extends StatelessWidget {
  const NetSpyWrapper({
    super.key,
    required this.netSpy,
    required this.child,
    this.showBubble = true,
  });

  /// The [NetSpy] instance to connect to.
  final NetSpy netSpy;

  /// The child widget (typically the app's Navigator from MaterialApp.builder).
  final Widget child;

  /// Whether to show the draggable floating bubble that opens the inspector.
  ///
  /// Defaults to `true`. Set to `false` if you only want to open the inspector
  /// by shaking the device or via [NetSpy.showInspector].
  final bool showBubble;

  @override
  Widget build(BuildContext context) {
    // When NetSpy is disabled (e.g. in release builds) render the app as-is
    // with zero overhead.
    if (!netSpy.enabled) return child;

    return Stack(
      children: [
        child,
        if (showBubble) _NetSpyBubble(netSpy: netSpy),
        ValueListenableBuilder<bool>(
          valueListenable: netSpy.inspectorVisible,
          builder: (context, inspectorVisible, _) {
            return _buildInspectorOverlay(context, inspectorVisible);
          },
        ),
      ],
    );
  }

  Widget _buildInspectorOverlay(BuildContext context, bool inspectorVisible) {
    return Positioned.fill(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: const Offset(0, 0),
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        child: inspectorVisible
            ? HeroControllerScope.none(
                key: const ValueKey('inspector'),
                child: Navigator(
                  onGenerateRoute: (_) => MaterialPageRoute(
                    builder: (_) => CallListScreen(
                      storage: netSpy.storage,
                      config: netSpy.config,
                      onBack: netSpy.hideInspector,
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

/// A draggable floating bubble that opens the NetSpy inspector when tapped.
///
/// It hides itself while the inspector is open and shows a badge with the
/// number of captured calls.
class _NetSpyBubble extends StatefulWidget {
  const _NetSpyBubble({required this.netSpy});

  final NetSpy netSpy;

  @override
  State<_NetSpyBubble> createState() => _NetSpyBubbleState();
}

class _NetSpyBubbleState extends State<_NetSpyBubble> {
  static const double _size = 52;
  static const double _margin = 16;

  /// Top-left position of the bubble. Null means "use default (bottom-right)".
  Offset? _pos;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.netSpy.inspectorVisible,
      builder: (context, visible, _) {
        if (visible) return const SizedBox.shrink();

        return SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth;
              final maxH = constraints.maxHeight;
              final pos = _pos ??
                  Offset(
                    maxW - _size - _margin,
                    maxH - _size - _margin * 5,
                  );

              return Stack(
                children: [
                  Positioned(
                    left: pos.dx,
                    top: pos.dy,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.netSpy.showInspector,
                      onPanUpdate: (details) {
                        final next = pos + details.delta;
                        setState(() {
                          _pos = Offset(
                            next.dx.clamp(0.0, maxW - _size),
                            next.dy.clamp(0.0, maxH - _size),
                          );
                        });
                      },
                      child: _buildBubble(),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBubble() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: _size,
        height: _size,
        decoration: const BoxDecoration(
          color: NetSpyColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.travel_explore,
              color: NetSpyColors.textOnPrimary,
              size: 26,
            ),
            _buildCountBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildCountBadge() {
    return ValueListenableBuilder(
      valueListenable: widget.netSpy.storage.calls,
      builder: (context, calls, _) {
        if (calls.isEmpty) return const SizedBox.shrink();
        final count = calls.length > 99 ? '99+' : '${calls.length}';
        return Positioned(
          top: -2,
          right: -2,
          child: Container(
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: NetSpyColors.error,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: NetSpyColors.surface, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              count,
              style: NetSpyTypo.t10.w700
                  .copyWith(color: NetSpyColors.textOnPrimary),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../theme.dart';

class MethodChip extends StatelessWidget {
  const MethodChip({super.key, required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    final color = NetSpyColors.methodColors(method);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        method.toUpperCase(),
        style: NetSpyTypo.t14.w600.copyWith(color: color),
      ),
    );
  }
}

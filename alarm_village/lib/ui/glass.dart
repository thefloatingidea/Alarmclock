import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

class Glass extends StatelessWidget {
  const Glass({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.radius = 20, this.tint});

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tint ?? const Color(0x40FFFFFF),
            borderRadius: br,
            border: Border.all(color: const Color(0x55FFFFFF)),
          ),
          child: child,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

const double _breakpoint = 800;

class AdaptiveLayout extends StatelessWidget {
  final WidgetBuilder mobile;
  final WidgetBuilder desktop;

  const AdaptiveLayout({
    super.key,
    required this.mobile,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _breakpoint) return mobile(context);
        return desktop(context);
      },
    );
  }
}

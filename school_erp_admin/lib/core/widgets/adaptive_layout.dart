import 'package:flutter/material.dart';

const double mobileBreakpoint = 600;
const double tabletBreakpoint = 1100;

extension ResponsiveContext on BuildContext {
  bool get isMobile => MediaQuery.of(this).size.width < mobileBreakpoint;
  bool get isTablet =>
      MediaQuery.of(this).size.width >= mobileBreakpoint &&
      MediaQuery.of(this).size.width < tabletBreakpoint;
  bool get isDesktop => MediaQuery.of(this).size.width >= tabletBreakpoint;
}

class AdaptiveLayout extends StatelessWidget {
  final WidgetBuilder mobile;
  final WidgetBuilder tablet;
  final WidgetBuilder desktop;

  const AdaptiveLayout({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < mobileBreakpoint) {
          return mobile(context);
        }
        if (constraints.maxWidth < tabletBreakpoint) {
          return tablet(context);
        }
        return desktop(context);
      },
    );
  }
}

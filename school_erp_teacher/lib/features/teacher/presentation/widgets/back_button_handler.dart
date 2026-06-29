import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class BackButtonHandler extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const BackButtonHandler({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  State<BackButtonHandler> createState() => _BackButtonHandlerState();
}

class _BackButtonHandlerState extends State<BackButtonHandler> {
  DateTime? _lastPress;
  bool _canPop = false;

  static const _homeRoute = '/teacher/dashboard';
  static const _kDoubleTapInterval = Duration(milliseconds: 500);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _canPop = false;
          return;
        }
        final now = DateTime.now();
        if (_lastPress != null &&
            now.difference(_lastPress!) < _kDoubleTapInterval) {
          _lastPress = null;
          if (widget.currentRoute == _homeRoute) {
            SystemNavigator.pop();
          } else {
            context.go(_homeRoute);
          }
          return;
        }
        _lastPress = now;
        if (widget.currentRoute == _homeRoute) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(milliseconds: 1500),
            ),
          );
          return;
        }
        setState(() => _canPop = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(_homeRoute);
          }
        });
      },
      child: widget.child,
    );
  }
}

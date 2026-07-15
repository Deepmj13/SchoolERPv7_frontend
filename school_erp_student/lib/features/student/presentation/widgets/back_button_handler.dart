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

  static const _homeRoute = '/student/dashboard';
  static const _kDoubleTapInterval = Duration(milliseconds: 500);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _canPop = false;
          return;
        }

        final now = DateTime.now();
        final isDoubleTap = _lastPress != null &&
            now.difference(_lastPress!) < _kDoubleTapInterval;

        if (widget.currentRoute == _homeRoute) {
          if (isDoubleTap) {
            _lastPress = null;
            SystemNavigator.pop();
          } else {
            _lastPress = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Press back again to exit'),
                duration: Duration(milliseconds: 1500),
              ),
            );
          }
          return;
        }

        _lastPress = now;
        if (context.canPop()) {
          setState(() => _canPop = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.pop();
          });
        } else {
          context.go(_homeRoute);
        }
      },
      child: widget.child,
    );
  }
}

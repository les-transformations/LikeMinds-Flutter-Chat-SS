import 'package:cupertino_will_pop_scope/cupertino_will_pop_scope.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;

import 'package:likeminds_chat_ss_fl/src/navigation/router.dart';

class LMCustomWillPop extends StatelessWidget {
  const LMCustomWillPop({
    required this.child,
    this.onWillPop = false,
    this.backButtonCallback,
    Key? key,
  }) : super(key: key);

  final Widget child;
  final bool onWillPop;
  final VoidCallback? backButtonCallback;

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.velocity.pixelsPerSecond.dx > 50) {
                if (onWillPop) {
                  if (Navigator.of(context).canPop()) {
                    backButtonCallback != null ? backButtonCallback!() : () {};
                  }
                }
              }
            },
            child: ConditionalWillPopScope(
              shouldAddCallback: true,
              onWillPop: () async {
                return false;
              },
              child: child,
            ))
        : ConditionalWillPopScope(
            shouldAddCallback: true,
            onWillPop: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
                return Future.value(false);
              } else {
                return Future.value(true);
              }
            },
            child: child,
          );
  }
}

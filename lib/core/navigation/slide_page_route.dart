import 'package:flutter/material.dart';

class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  SlidePageRoute({required this.child})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final isReverse = animation.status == AnimationStatus.reverse;
      final curve = isReverse ? Curves.easeInCubic : Curves.easeOutCubic;

      return SlideTransition(
        position: animation.drive(
          Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
              .chain(CurveTween(curve: curve)),
        ),
        child: child,
      );
    },
  );
}
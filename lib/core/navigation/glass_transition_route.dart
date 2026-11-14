import 'package:flutter/material.dart';

class GlassTransitionRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  GlassTransitionRoute({required this.child})
      : super(
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final isReverse = animation.status == AnimationStatus.reverse;
      final curved = CurvedAnimation(
        parent: animation,
        curve: isReverse ? Curves.easeInQuart : Curves.easeOutQuart,
      );

      return FadeTransition(
        opacity: Tween<double>(begin: 0.25, end: 1.0).animate(curved),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.08, 0.0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
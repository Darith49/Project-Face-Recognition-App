import 'package:flutter/material.dart';

/// A lightweight animated list item that replaces expensive animate_do FadeInUp widgets.
/// Uses a single AnimationController per item with minimal overhead.
/// Set [AnimatedListItem.enableAnimations] to false globally for low-end devices.
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final double slideOffset;

  /// Global flag to disable animations on low-end devices
  static bool enableAnimations = true;

  const AnimatedListItem({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 300),
    this.slideOffset = 20.0,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    if (!AnimatedListItem.enableAnimations) {
      _controller = AnimationController(
        duration: Duration.zero,
        vsync: this,
      );
    } else {
      _controller = AnimationController(
        duration: widget.duration,
        vsync: this,
      );
    }

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.slideOffset / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    if (AnimatedListItem.enableAnimations) {
      // Stagger delay based on index, capped at 5 items
      final delay = Duration(
        milliseconds: (widget.index.clamp(0, 5)) * 40,
      );
      Future.delayed(delay, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AnimatedListItem.enableAnimations) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

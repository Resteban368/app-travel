import 'package:flutter/material.dart';

/// Reusable widget that applies a staggered fade + slide-up animation
/// based on the item's [index] in a list.
///
/// Usage:
/// ```dart
/// AnimatedListItem(
///   index: index,
///   child: MyCard(...),
/// )
/// ```
class AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration duration;
  final Duration staggerDelay;

  const AnimatedListItem({
    super.key,
    required this.index,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.staggerDelay = const Duration(milliseconds: 80),
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Stagger delay based on index (capped at 8 to avoid long waits)
    final delay = widget.staggerDelay * (widget.index.clamp(0, 8));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

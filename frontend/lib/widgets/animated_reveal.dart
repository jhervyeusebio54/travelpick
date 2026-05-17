import 'package:flutter/material.dart';

class AnimatedReveal extends StatefulWidget {
  const AnimatedReveal({
    required this.child,
    this.delay = Duration.zero,
    super.key,
  });

  final Widget child;
  final Duration delay;

  @override
  State<AnimatedReveal> createState() => _AnimatedRevealState();
}

class _AnimatedRevealState extends State<AnimatedReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  static const _revealDuration = Duration(milliseconds: 520);

  @override
  void initState() {
    super.initState();
    final totalDuration = widget.delay + _revealDuration;
    final totalMilliseconds = totalDuration.inMilliseconds == 0
        ? 1
        : totalDuration.inMilliseconds;
    final animationStart = widget.delay.inMilliseconds / totalMilliseconds;

    _controller = AnimationController(vsync: this, duration: totalDuration);
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval(animationStart, 1, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(_fadeAnimation);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme.dart';

class VoteButton extends StatefulWidget {
  const VoteButton({
    required this.isVoted,
    required this.onVote,
    this.isSubmitting = false,
    super.key,
  });

  final bool isVoted;
  final VoidCallback? onVote;
  final bool isSubmitting;

  @override
  State<VoteButton> createState() => _VoteButtonState();
}

class _VoteButtonState extends State<VoteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(VoteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isVoted && widget.isVoted) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voted = widget.isVoted;

    return ScaleTransition(
      scale: _scaleAnim,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        height: 42,
        decoration: BoxDecoration(
          color: voted
              ? AppTheme.teal.withValues(alpha: 0.12)
              : AppTheme.coral,
          borderRadius: BorderRadius.circular(14),
          border: voted
              ? Border.all(color: AppTheme.teal.withValues(alpha: 0.35), width: 1.5)
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: widget.isSubmitting ? null : widget.onVote,
            borderRadius: BorderRadius.circular(14),
            splashColor: voted
                ? AppTheme.teal.withValues(alpha: 0.18)
                : AppTheme.coral.withValues(alpha: 0.18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: Icon(
                      voted
                          ? Icons.check_circle_rounded
                          : Icons.how_to_vote_rounded,
                      key: ValueKey(voted),
                      size: 18,
                      color: voted ? AppTheme.teal : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 7),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: Text(
                      voted ? 'Voted' : 'Vote This Destination',
                      key: ValueKey(voted),
                      style: TextStyle(
                        color: voted ? AppTheme.teal : Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

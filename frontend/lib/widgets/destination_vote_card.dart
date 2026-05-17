import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../theme.dart';
import 'vote_button.dart';

class DestinationVoteCard extends StatelessWidget {
  const DestinationVoteCard({
    required this.destination,
    required this.weight,
    required this.isVoted,
    required this.onWeightChanged,
    required this.onVote,
    this.isSubmitting = false,
    super.key,
  });

  final Destination destination;
  final int weight;
  final bool isVoted;
  final ValueChanged<int> onWeightChanged;
  final VoidCallback onVote;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isVoted
              ? AppTheme.teal.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.72),
          width: isVoted ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isVoted
                ? AppTheme.teal.withValues(alpha: 0.10)
                : AppTheme.deepTeal.withValues(alpha: 0.07),
            blurRadius: isVoted ? 28 : 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image header
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _DestinationImage(destination: destination),
                  // Gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.04),
                          Colors.black.withValues(alpha: 0.48),
                        ],
                      ),
                    ),
                  ),
                  // Country badge
                  Positioned(
                    left: 14,
                    bottom: 12,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.place_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          destination.country,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Voted badge
                  if (isVoted)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.teal,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Voted',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + weight badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        destination.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _weightColor(weight).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$weight',
                        style: TextStyle(
                          color: _weightColor(weight),
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Weight label
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Align(
                    key: ValueKey(weight),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _weightLabel(weight),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _weightColor(weight),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Interactive Choice Chips for assigning weight
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _ScaleChip(
                        label: 'Keep in mix',
                        active: weight == 1,
                        color: AppTheme.teal,
                        onTap: isVoted ? null : () => onWeightChanged(1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ScaleChip(
                        label: 'Strong option',
                        active: weight == 2,
                        color: AppTheme.amber,
                        onTap: isVoted ? null : () => onWeightChanged(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ScaleChip(
                        label: 'Dream pick',
                        active: weight == 3,
                        color: AppTheme.coral,
                        onTap: isVoted ? null : () => onWeightChanged(3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Vote button full width
                SizedBox(
                  width: double.infinity,
                  child: VoteButton(
                    isVoted: isVoted,
                    isSubmitting: isSubmitting,
                    onVote: onVote,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _weightColor(int w) {
    return switch (w) {
      1 => AppTheme.teal,
      2 => AppTheme.amber,
      _ => AppTheme.coral,
    };
  }

  String _weightLabel(int w) {
    return switch (w) {
      1 => 'Keep in mix — worth considering',
      2 => 'Strong option — really like it',
      _ => 'Dream pick — top choice!',
    };
  }
}

class _DestinationImage extends StatelessWidget {
  const _DestinationImage({required this.destination});
  final Destination destination;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      destination.imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _Fallback(destination: destination);
      },
      errorBuilder: (context, e, s) => _Fallback(destination: destination),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.destination});
  final Destination destination;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.mint, AppTheme.teal],
        ),
      ),
      child: const Center(
        child: Icon(Icons.public_rounded, color: Colors.white, size: 44),
      ),
    );
  }
}

class _ScaleChip extends StatelessWidget {
  const _ScaleChip({
    required this.label,
    required this.active,
    required this.color,
    this.onTap,
  });

  final String label;
  final bool active;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? color : AppTheme.line,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  color: active ? color : const Color(0xFF587275),
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}

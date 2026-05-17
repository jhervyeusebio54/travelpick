import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../theme.dart';

class CreateGroupDestinationCard extends StatelessWidget {
  const CreateGroupDestinationCard({
    required this.destination,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final Destination destination;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration:
          AppTheme.cardDecoration(
            radius: 24,
            color: selected ? AppTheme.paleMint : Colors.white,
          ).copyWith(
            border: Border.all(
              color: selected
                  ? AppTheme.coral
                  : Colors.white.withValues(alpha: 0.72),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (selected ? AppTheme.coral : AppTheme.deepTeal)
                    .withValues(alpha: selected ? 0.2 : 0.08),
                blurRadius: selected ? 28 : 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    destination.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.mint, AppTheme.teal],
                          ),
                        ),
                        child: const Icon(
                          Icons.landscape_rounded,
                          color: Colors.white,
                          size: 46,
                        ),
                      );
                    },
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.02),
                          Colors.black.withValues(alpha: 0.36),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppTheme.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            destination.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: AnimatedScale(
                      scale: selected ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: AppTheme.coral,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.place_rounded,
                      color: AppTheme.teal,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        destination.country,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: selected
                      ? OutlinedButton.icon(
                          onPressed: onPressed,
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                          label: const Text('Remove'),
                        )
                      : ElevatedButton.icon(
                          onPressed: onPressed,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add to Group'),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

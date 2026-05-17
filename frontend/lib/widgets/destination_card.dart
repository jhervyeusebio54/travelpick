import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../theme.dart';

class DestinationCard extends StatelessWidget {
  const DestinationCard({
    required this.destination,
    this.onTap,
    this.compact = false,
    super.key,
  });

  final Destination destination;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: AppTheme.cardDecoration(),
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
                      _DestinationImage(destination: destination),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.04),
                              Colors.black.withValues(alpha: 0.42),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        bottom: 14,
                        child: _RatingPill(rating: destination.rating),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, compact ? 14 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_rounded,
                          size: 16,
                          color: AppTheme.teal,
                        ),
                        const SizedBox(width: 5),
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
                    if (!compact) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            size: 17,
                            color: AppTheme.coral,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${destination.popularity}% group fit',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return _ImageFallback(destination: destination);
      },
      errorBuilder: (context, error, stackTrace) {
        return _ImageFallback(destination: destination);
      },
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.destination});

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
      child: Center(
        child: Icon(
          _iconFor(destination.name),
          color: Colors.white.withValues(alpha: 0.9),
          size: 48,
        ),
      ),
    );
  }

  IconData _iconFor(String name) {
    if (name == 'Banff' || name == 'Queenstown') {
      return Icons.terrain_rounded;
    }
    if (name == 'Santorini' || name == 'Bali') {
      return Icons.water_rounded;
    }
    if (name == 'Kyoto') {
      return Icons.temple_buddhist_rounded;
    }
    return Icons.public_rounded;
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppTheme.amber, size: 16),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

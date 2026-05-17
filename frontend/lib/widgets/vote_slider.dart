import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../theme.dart';

class VoteSlider extends StatelessWidget {
  const VoteSlider({
    required this.destination,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final Destination destination;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(radius: 22),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              destination.imageUrl,
              width: 78,
              height: 78,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 78,
                  height: 78,
                  color: AppTheme.mint,
                  child: const Icon(
                    Icons.landscape_rounded,
                    color: AppTheme.deepTeal,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        destination.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.coral.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$value',
                        style: const TextStyle(
                          color: AppTheme.coral,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  _weightLabel(value),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Slider(
                  value: value.toDouble(),
                  min: 1,
                  max: 3,
                  divisions: 2,
                  label: '$value',
                  onChanged: (nextValue) => onChanged(nextValue.round()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _ScaleLabel(label: 'Low'),
                    _ScaleLabel(label: 'Nice'),
                    _ScaleLabel(label: 'Top'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _weightLabel(int weight) {
    return switch (weight) {
      1 => 'Worth considering',
      2 => 'Strong option',
      _ => 'Dream pick',
    };
  }
}

class _ScaleLabel extends StatelessWidget {
  const _ScaleLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
    );
  }
}

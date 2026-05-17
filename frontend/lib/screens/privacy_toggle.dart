import 'package:flutter/material.dart';

import '../models/group.dart';
import '../theme.dart';

class PrivacyToggle extends StatelessWidget {
  const PrivacyToggle({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final PrivacyMode value;
  final ValueChanged<PrivacyMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (final mode in PrivacyMode.values) ...[
              Expanded(
                child: _PrivacyOption(
                  mode: mode,
                  selected: value == mode,
                  onTap: () => onChanged(mode),
                ),
              ),
              if (mode != PrivacyMode.values.last) const SizedBox(width: 10),
            ],
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Row(
            key: ValueKey(value),
            children: [
              Icon(
                value == PrivacyMode.private
                    ? Icons.lock_rounded
                    : Icons.public_rounded,
                color: AppTheme.teal,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrivacyOption extends StatelessWidget {
  const _PrivacyOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final PrivacyMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppTheme.teal : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppTheme.teal : AppTheme.line,
              width: 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.teal.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                mode == PrivacyMode.private
                    ? Icons.group_rounded
                    : Icons.travel_explore_rounded,
                size: 18,
                color: selected ? Colors.white : AppTheme.teal,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  mode.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

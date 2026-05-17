import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/group.dart';
import '../theme.dart';

Future<String?> showGroupCodeDialog({
  required BuildContext context,
  required CreatedGroup group,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return GroupCodeDialog(group: group);
    },
  );
}

class GroupCodeDialog extends StatelessWidget {
  const GroupCodeDialog({required this.group, super.key});

  final CreatedGroup group;

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: group.code));
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Group code copied.')));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: DecoratedBox(
        decoration: AppTheme.cardDecoration(radius: 28),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.coral.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.celebration_rounded,
                      color: AppTheme.coral,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Group created successfully!',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(group.name, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.paleMint,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.line),
                ),
                child: Text(
                  group.code,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.deepTeal,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${group.privacyMode.label} group - ${group.destinations.length} destinations selected',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyCode(context),
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy Code'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop('my-groups'),
                      icon: const Icon(Icons.groups_rounded),
                      label: const Text('Go to My Groups'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

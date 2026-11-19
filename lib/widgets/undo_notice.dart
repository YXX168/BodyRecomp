import 'package:flutter/material.dart';

void showUndoNotice(BuildContext context, String message,
    {required VoidCallback onUndo}) {
  final theme = Theme.of(context);
  final colors = theme.colorScheme;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      persist: false,
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      elevation: 0,
      backgroundColor: Color.alphaBlend(
          colors.primary.withValues(alpha: .07), colors.surface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.primary.withValues(alpha: .16)),
      ),
      content: Row(children: [
        Icon(Icons.check_circle_outline_rounded,
            size: 17, color: colors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurface)),
        ),
      ]),
      action: SnackBarAction(
        label: '撤销',
        textColor: colors.primary,
        onPressed: onUndo,
      ),
    ));
}

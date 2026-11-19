import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

void showUndoNotice(
  BuildContext context,
  String message, {
  required VoidCallback onUndo,
}) {
  final p = context.palette;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        persist: false,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        elevation: 0,
        backgroundColor: p.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.borderHighlight),
        ),
        content: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 18, color: p.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: '撤销',
          textColor: p.primary,
          onPressed: onUndo,
        ),
      ),
    );
}

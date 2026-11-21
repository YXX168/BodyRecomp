import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Unified Liquid Glass floating notice / undo banner backed by [SnackBar].
void showGlassNotice(
  BuildContext context,
  String message, {
  IconData? icon,
  bool isError = false,
  FutureOr<void> Function()? onUndo,
  Duration? duration,
}) {
  final p = context.palette;
  final tint = isError ? p.danger : p.primary;
  final fill = Color.alphaBlend(
    tint.withValues(alpha: p.isDark ? .14 : .08),
    p.surfaceElevated,
  );
  final effectiveIcon = icon ??
      (isError
          ? Icons.error_outline_rounded
          : Icons.check_circle_outline_rounded);
  final effectiveDuration = duration ??
      (onUndo != null
          ? const Duration(seconds: 4)
          : const Duration(seconds: 3));

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        persist: false,
        duration: effectiveDuration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        elevation: 0,
        backgroundColor: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color:
                isError ? p.danger.withValues(alpha: .55) : p.borderHighlight,
            width: 1.0,
          ),
        ),
        content: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint.withValues(alpha: p.isDark ? .18 : .13),
              ),
              child: Icon(effectiveIcon, size: 15.5, color: tint),
            ),
            const SizedBox(width: 9),
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
        action: onUndo != null
            ? SnackBarAction(
                label: '撤销',
                textColor: p.primary,
                onPressed: () => onUndo(),
              )
            : null,
      ),
    );
}

void showUndoNotice(
  BuildContext context,
  String message, {
  required VoidCallback onUndo,
}) =>
    showGlassNotice(
      context,
      message,
      onUndo: onUndo,
      duration: const Duration(seconds: 4),
    );

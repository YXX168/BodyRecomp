import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Semantics(
        liveRegion: true,
        label: '正在读取记录',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                strokeCap: StrokeCap.round,
                color: p.primary,
                backgroundColor: p.surfaceMuted,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '正在读取记录',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: p.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

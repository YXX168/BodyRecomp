import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => Center(
      child: Semantics(
          liveRegion: true,
          label: '正在读取记录',
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 12),
            Text('正在读取记录',
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: .45))),
          ])));
}

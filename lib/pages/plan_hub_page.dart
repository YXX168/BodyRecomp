import 'package:flutter/material.dart';
import '../services/app_signals.dart';
import '../services/exercise_library_service.dart';
import '../theme/app_theme.dart';
import 'exercise_library_view.dart';
import 'template_manager_page.dart';

/// Unified Plan Hub housing Daily Fixed Templates (0) and Editable Exercise Library (1).
class PlanHubPage extends StatefulWidget {
  final int initialSegment;
  const PlanHubPage({super.key, this.initialSegment = 0});

  @override
  State<PlanHubPage> createState() => _PlanHubPageState();
}

class _PlanHubPageState extends State<PlanHubPage> {
  late int _segment = widget.initialSegment;
  int? _libraryCount;

  @override
  void initState() {
    super.initState();
    exerciseLibraryRevision.addListener(_refreshCount);
    _refreshCount();
  }

  @override
  void dispose() {
    exerciseLibraryRevision.removeListener(_refreshCount);
    super.dispose();
  }

  Future<void> _refreshCount() async {
    try {
      final items = await loadExerciseLibrary();
      if (mounted) setState(() => _libraryCount = items.length);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final libraryLabel = _libraryCount == null ? '动作库' : '动作库 · $_libraryCount';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: p.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.borderSubtle),
            ),
            child: Row(
              children: [
                _SegmentButton(
                  key: const Key('plan-tab-templates'),
                  label: '每日固定模板',
                  selected: _segment == 0,
                  reduceMotion: reduceMotion,
                  onTap: () => setState(() => _segment = 0),
                ),
                _SegmentButton(
                  key: const Key('plan-tab-library'),
                  label: libraryLabel,
                  selected: _segment == 1,
                  reduceMotion: reduceMotion,
                  onTap: () => setState(() => _segment = 1),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _segment,
            children: const [
              WeeklyTemplatesView(),
              ExerciseLibraryView(),
            ],
          ),
        ),
      ],
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool reduceMotion;
  final VoidCallback onTap;

  const _SegmentButton({
    super.key,
    required this.label,
    required this.selected,
    required this.reduceMotion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? p.surfaceElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(color: p.borderHighlight, width: 0.9)
                : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? p.primary : p.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/recomp_models.dart';
import '../theme/app_theme.dart';

Set<String> _matchMuscleTag(String raw) {
  final t = raw.trim().toLowerCase();
  if (t.isEmpty || t == '其他' || t == 'other') return const {};
  final matched = <String>{};
  if (RegExp(r'胸|\b(chest|pec|pecs)\b').hasMatch(t)) matched.add('chest');
  if (RegExp(r'背|背阔|斜方|菱形|\b(back|lat|lats)\b').hasMatch(t)) {
    matched.add('back');
  }
  if (RegExp(r'肩|三角肌|\b(shoulder|shoulders|delt|delts)\b').hasMatch(t)) {
    matched.add('shoulders');
  }
  if (RegExp(r'臂|二头|三头|肱|腕|\b(arm|arms|bicep|biceps|tricep|triceps)\b')
      .hasMatch(t)) {
    matched.add('arms');
  }
  if (RegExp(r'腹|核心|\b(core|abs)\b').hasMatch(t)) matched.add('core');
  if (RegExp(
    r'腿|臀|股四|腘绳|小腿|\b(leg|legs|glute|glutes|quad|quads|hamstring|calf|calves)\b',
  ).hasMatch(t)) {
    matched.add('legs');
  }
  if (RegExp(r'有氧|心肺|恢复|拉伸|放松|\b(cardio|hiit|recovery|stretch)\b')
      .hasMatch(t)) {
    matched.add('cardio');
  }
  return matched;
}

/// Infers normalized anatomical group keys (`chest`, `back`, `shoulders`,
/// `arms`, `core`, `legs`, `cardio`) from a collection of [Exercise]s.
Set<String> inferMuscleGroups(Iterable<Exercise> exercises) {
  final groups = <String>{};
  for (final ex in exercises) {
    final explicit = <String>{};
    for (final tag in ex.muscles) {
      explicit.addAll(_matchMuscleTag(tag));
    }
    if (explicit.isNotEmpty) {
      groups.addAll(explicit);
      continue;
    }

    var text = '${ex.name} ${ex.muscleTarget}'.toLowerCase();

    // Disambiguate compound phrases before broader keyword matching.
    if (RegExp(r'划船机|\browing\s*machine\b').hasMatch(text)) {
      groups.add('cardio');
      text = text.replaceAll(RegExp(r'划船机|\browing\s*machine\b'), ' ');
    }
    if (RegExp(r'(俯卧|坐姿)?腿弯举|\bleg\s*curls?\b').hasMatch(text)) {
      groups.add('legs');
      text = text.replaceAll(RegExp(r'(俯卧|坐姿)?腿弯举|\bleg\s*curls?\b'), ' ');
    }
    if (RegExp(r'(仰卧|悬垂)?举腿|\bleg\s*raises?\b').hasMatch(text)) {
      groups.add('core');
      text = text.replaceAll(RegExp(r'(仰卧|悬垂)?举腿|\bleg\s*raises?\b'), ' ');
    }
    if (text.contains('直臂下压')) {
      groups.add('back');
      text = text.replaceAll('直臂下压', ' ');
    }

    if (RegExp(r'胸|卧推|推胸|夹胸|俯卧撑|\b(chest|pec|pecs|bench)\b').hasMatch(text)) {
      groups.add('chest');
    }
    if (RegExp(
      r'背|下拉|引体|划船|背阔|斜方|菱形|山羊挺身|\b(back|lat|lats|row|rows|pull-?ups?|pulldowns?)\b',
    ).hasMatch(text)) {
      groups.add('back');
    }
    if (RegExp(
      r'肩|三角肌|侧平举|前平举|推举|面拉|飞鸟|\b(shoulder|shoulders|delt|delts|overhead|lateral\s*raises?)\b',
    ).hasMatch(text)) {
      groups.add('shoulders');
    }
    final armText = text.replaceAll(RegExp(r'直臂|单臂|双臂'), ' ');
    if (RegExp(
      r'臂|二头|三头|肱二|肱三|肱肌|弯举|下压|臂屈伸|腕|\b(bicep|biceps|tricep|triceps|arm|arms|curl|curls)\b',
    ).hasMatch(armText)) {
      groups.add('arms');
    }
    if (RegExp(r'腹|核心|平板支撑|死虫|鸟狗|悬垂|俄罗斯转体|\b(core|abs|plank|crunch|crunches)\b')
        .hasMatch(text)) {
      groups.add('core');
    }
    if (RegExp(
      r'腿|臀|深蹲|硬拉|倒蹬|弓步|腿举|腿屈伸|提踵|外展|股四|腘绳|小腿|\b(leg|legs|glute|glutes|squat|squats|deadlift|lunge|lunges|calf|calves)\b',
    ).hasMatch(text)) {
      groups.add('legs');
    }
    if (RegExp(
      r'有氧|心肺|单车|跑|走|椭圆|跳绳|波比|拉伸|恢复|放松|泡沫轴|\b(cardio|hiit|walk|walking|run|running|cycle|cycling|stretch|stretching)\b',
    ).hasMatch(text)) {
      groups.add('cardio');
    }
  }
  return groups;
}

/// Modern Swiss-minimalist athletic figure icon housed in a translucent frosted
/// squircle. Uses clean flat-frosted negative-space segments (no noisy thin
/// outlines) and vibrant gradient fills for active muscle groups.
class MuscleBodyGraphic extends StatelessWidget {
  final Set<String> activeGroups;
  final double size;
  final bool showHalo;

  const MuscleBodyGraphic({
    super.key,
    required this.activeGroups,
    this.size = 62,
    this.showHalo = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final body = CustomPaint(
      painter: _MuscleBodyPainter(
        activeGroups: activeGroups,
        primary: p.primary,
        primaryBright: p.primaryBright,
        accent: p.accent,
        inactiveColor: p.isDark
            ? Colors.white.withValues(alpha: .16)
            : p.textPrimary.withValues(alpha: .13),
        isDark: p.isDark,
      ),
    );

    return RepaintBoundary(
      child: showHalo
          ? Container(
              width: size,
              height: size,
              padding: EdgeInsets.all(size * 0.11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (activeGroups.isEmpty ? p.accent : p.primary)
                        .withValues(alpha: p.isDark ? .18 : .13),
                    p.glassFillBottom,
                  ],
                ),
                border: Border.all(
                  color: (activeGroups.isEmpty ? p.accent : p.primary)
                      .withValues(alpha: p.isDark ? .26 : .18),
                  width: 0.9,
                ),
              ),
              child: body,
            )
          : SizedBox(width: size, height: size, child: body),
    );
  }
}

class _MuscleBodyPainter extends CustomPainter {
  final Set<String> activeGroups;
  final Color primary;
  final Color primaryBright;
  final Color accent;
  final Color inactiveColor;
  final bool isDark;

  _MuscleBodyPainter({
    required this.activeGroups,
    required this.primary,
    required this.primaryBright,
    required this.accent,
    required this.inactiveColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height);
    canvas.save();
    canvas.translate(
      (size.width - unit) / 2,
      (size.height - unit) / 2,
    );
    canvas.scale(unit / 100.0, unit / 100.0);

    final mutedPaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.fill;

    final activeShader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryBright, primary],
    ).createShader(const Rect.fromLTWH(16, 16, 68, 78));

    final activePaint = Paint()
      ..shader = activeShader
      ..style = PaintingStyle.fill;

    final activeHalo = Paint()
      ..color = primary.withValues(alpha: isDark ? .22 : .15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeJoin = StrokeJoin.round;

    void drawRRect(RRect rrect, bool active) {
      if (active) {
        canvas.drawRRect(rrect, activeHalo);
        canvas.drawRRect(rrect, activePaint);
      } else {
        canvas.drawRRect(rrect, mutedPaint);
      }
    }

    void drawPath(Path path, bool active) {
      if (active) {
        canvas.drawPath(path, activeHalo);
        canvas.drawPath(path, activePaint);
      } else {
        canvas.drawPath(path, mutedPaint);
      }
    }

    // Subtle cardio arc indicator around top-right when aerobic active
    if (activeGroups.contains('cardio')) {
      final pulsePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [accent, primaryBright],
        ).createShader(const Rect.fromLTWH(6, 6, 88, 88));
      canvas.drawArc(
        const Rect.fromLTWH(6, 6, 88, 88),
        -math.pi * 0.85,
        math.pi * 0.42,
        false,
        pulsePaint,
      );
      canvas.drawArc(
        const Rect.fromLTWH(6, 6, 88, 88),
        math.pi * 0.15,
        math.pi * 0.42,
        false,
        pulsePaint,
      );
    }

    // Minimalist clean floating head (Apple SF-Symbol aesthetic, no thin neck)
    canvas.drawCircle(const Offset(50, 14), 8.2, mutedPaint);

    // Back / Lats: clean smooth curved outer lat silhouette behind ribcage
    final backActive = activeGroups.contains('back');
    if (backActive) {
      final lats = Path()
        ..moveTo(35.5, 31.5)
        ..quadraticBezierTo(28.5, 39.5, 34.8, 50.0)
        ..lineTo(38.0, 46.5)
        ..close()
        ..moveTo(64.5, 31.5)
        ..quadraticBezierTo(71.5, 39.5, 65.2, 50.0)
        ..lineTo(62.0, 46.5)
        ..close();
      drawPath(lats, true);
    }

    // Shoulders: clean sculpted rounded caps
    final shouldersActive = activeGroups.contains('shoulders');
    drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(21.5, 25.5, 11.5, 10.5),
        const Radius.circular(5.5),
      ),
      shouldersActive,
    );
    drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(67.0, 25.5, 11.5, 10.5),
        const Radius.circular(5.5),
      ),
      shouldersActive,
    );

    // Arms: clean slightly-angled athletic capsules
    final armsActive = activeGroups.contains('arms');
    canvas.save();
    canvas.translate(25.2, 48.0);
    canvas.rotate(0.08);
    drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 8.6, height: 22.5),
        const Radius.circular(4.3),
      ),
      armsActive,
    );
    canvas.restore();

    canvas.save();
    canvas.translate(74.8, 48.0);
    canvas.rotate(-0.08);
    drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 8.6, height: 22.5),
        const Radius.circular(4.3),
      ),
      armsActive,
    );
    canvas.restore();

    // Chest: clean symmetrical upper-torso plates
    final chestActive = activeGroups.contains('chest');
    drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(35.0, 25.5, 13.8, 12.2),
        topLeft: const Radius.circular(5),
        topRight: const Radius.circular(2.5),
        bottomLeft: const Radius.circular(5),
        bottomRight: const Radius.circular(3.5),
      ),
      chestActive,
    );
    drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(51.2, 25.5, 13.8, 12.2),
        topLeft: const Radius.circular(2.5),
        topRight: const Radius.circular(5),
        bottomLeft: const Radius.circular(3.5),
        bottomRight: const Radius.circular(5),
      ),
      chestActive,
    );

    // Core: clean tapered athletic center tablet
    final coreActive = activeGroups.contains('core');
    final core = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(37.6, 40.2, 24.8, 16.5),
          const Radius.circular(5.5),
        ),
      );
    drawPath(core, coreActive);

    // Legs: sleek symmetrical athletic legs with clean negative-space gap
    final legsActive = activeGroups.contains('legs');
    final leftLeg = Path()
      ..moveTo(37.2, 59.5)
      ..lineTo(48.4, 59.5)
      ..lineTo(46.8, 89.5)
      ..quadraticBezierTo(42.8, 93.2, 38.8, 89.5)
      ..close();
    final rightLeg = Path()
      ..moveTo(51.6, 59.5)
      ..lineTo(62.8, 59.5)
      ..lineTo(61.2, 89.5)
      ..quadraticBezierTo(57.2, 93.2, 53.2, 89.5)
      ..close();
    drawPath(leftLeg, legsActive);
    drawPath(rightLeg, legsActive);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_MuscleBodyPainter oldDelegate) =>
      oldDelegate.primary != primary ||
      oldDelegate.primaryBright != primaryBright ||
      oldDelegate.accent != accent ||
      oldDelegate.inactiveColor != inactiveColor ||
      oldDelegate.isDark != isDark ||
      oldDelegate.activeGroups.length != activeGroups.length ||
      !oldDelegate.activeGroups.containsAll(activeGroups);
}

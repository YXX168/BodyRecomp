import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// THEME SYSTEM — v6.0: Renamed themes + new cyberpunk dark theme
// ═══════════════════════════════════════════════════════════════════════════════

enum AppTheme { blue, pink, orange, purple, green, dark }

class WorkoutTheme {
  final String name;
  final String emoji;
  final Color bg;
  final Color card;
  final Color primary;
  final Color primaryLight;
  final Color accent;
  final Color text1;
  final Color text2;
  final Color text3;
  final Color text4;
  final Color success;
  final Color successLight;
  final Color warning;
  final Color border;
  final Color navbarBg;
  final bool isDark;

  const WorkoutTheme({
    required this.name,
    this.emoji = '',
    required this.bg,
    required this.card,
    required this.primary,
    required this.primaryLight,
    required this.accent,
    required this.text1,
    required this.text2,
    required this.text3,
    required this.text4,
    required this.success,
    required this.successLight,
    required this.warning,
    required this.border,
    required this.navbarBg,
    this.isDark = false,
  });
}

const themes = {
  AppTheme.blue: WorkoutTheme(
    name: '极地冰川 · 冰霜蓝',
    bg: Color(0xFFF0F4FF), card: Color(0xFFFFFFFF),
    primary: Color(0xFF2563EB), primaryLight: Color(0xFF60A5FA), accent: Color(0xFF7C3AED),
    text1: Color(0xFF1E293B), text2: Color(0xFF334155), text3: Color(0xFF64748B), text4: Color(0xFF94A3B8),
    success: Color(0xFF059669), successLight: Color(0xFF34D399), warning: Color(0xFFD97706),
    border: Color(0xFFE2E8F0), navbarBg: Color(0xFFFFFFFF),
  ),
  AppTheme.pink: WorkoutTheme(
    name: '樱花飞舞 · 幻境粉',
    bg: Color(0xFFFDF2F8), card: Color(0xFFFFFFFF),
    primary: Color(0xFFDB2777), primaryLight: Color(0xFFF472B6), accent: Color(0xFF7C3AED),
    text1: Color(0xFF1E293B), text2: Color(0xFF334155), text3: Color(0xFF64748B), text4: Color(0xFF94A3B8),
    success: Color(0xFF0D9488), successLight: Color(0xFF2DD4BF), warning: Color(0xFFD97706),
    border: Color(0xFFE2E8F0), navbarBg: Color(0xFFFFFFFF),
  ),
  AppTheme.orange: WorkoutTheme(
    name: '落日余晖 · 熔岩橙',
    bg: Color(0xFFFFF7ED), card: Color(0xFFFFFFFF),
    primary: Color(0xFFEA580C), primaryLight: Color(0xFFFB923C), accent: Color(0xFFCA8A04),
    text1: Color(0xFF1E293B), text2: Color(0xFF334155), text3: Color(0xFF64748B), text4: Color(0xFF94A3B8),
    success: Color(0xFF0D9488), successLight: Color(0xFF2DD4BF), warning: Color(0xFFDC2626),
    border: Color(0xFFE2E8F0), navbarBg: Color(0xFFFFFFFF),
  ),
  AppTheme.purple: WorkoutTheme(
    name: '璀璨银河 · 星云紫',
    bg: Color(0xFFFAF5FF), card: Color(0xFFFFFFFF),
    primary: Color(0xFF7C3AED), primaryLight: Color(0xFFA78BFA), accent: Color(0xFFDB2777),
    text1: Color(0xFF1E293B), text2: Color(0xFF334155), text3: Color(0xFF64748B), text4: Color(0xFF94A3B8),
    success: Color(0xFF0891B2), successLight: Color(0xFF22D3EE), warning: Color(0xFFD97706),
    border: Color(0xFFE2E8F0), navbarBg: Color(0xFFFFFFFF),
  ),
  AppTheme.green: WorkoutTheme(
    name: '深邃秘境 · 森林绿',
    bg: Color(0xFFF0FDF4), card: Color(0xFFFFFFFF),
    primary: Color(0xFF059669), primaryLight: Color(0xFF34D399), accent: Color(0xFF0891B2),
    text1: Color(0xFF1E293B), text2: Color(0xFF334155), text3: Color(0xFF64748B), text4: Color(0xFF94A3B8),
    success: Color(0xFF65A30D), successLight: Color(0xFFA3E635), warning: Color(0xFFD97706),
    border: Color(0xFFE2E8F0), navbarBg: Color(0xFFFFFFFF),
  ),
  // v6.0 NEW: Cyberpunk neon dark theme
  AppTheme.dark: WorkoutTheme(
    name: '永夜星域 · 极夜黑',
    bg: Color(0xFF0A0E1A), card: Color(0xFF141A2E),
    primary: Color(0xFF00F0FF), primaryLight: Color(0xFF66F7FF), accent: Color(0xFFFF0080),
    text1: Color(0xFFE8ECF4), text2: Color(0xFFB0B8C8), text3: Color(0xFF6B7A90), text4: Color(0xFF3D4A5C),
    success: Color(0xFF00FF88), successLight: Color(0xFF66FFB2), warning: Color(0xFFFFB800),
    border: Color(0xFF1E2740), navbarBg: Color(0xFF0D1220),
    isDark: true,
  ),
};

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

class Exercise {
  final String name;
  final List<String> muscles;
  final String muscleTarget;
  final int sets;
  final String reps;
  final String rest;
  final String? note;
  final bool isStar;
  const Exercise({
    required this.name, required this.muscles, required this.muscleTarget,
    required this.sets, required this.reps, required this.rest,
    this.note, this.isStar = false,
  });
}

class WorkoutDay {
  final String dayName;
  final String subtitle;
  final String badge;
  final String description;
  final bool isRest;
  final bool isOptional;
  final String? optionalDesc;
  final List<Exercise> exercises;
  final List<String>? recoveryOptions;
  final String? circuitNote;
  const WorkoutDay({
    required this.dayName, required this.subtitle, required this.badge, required this.description,
    this.isRest = false, this.isOptional = false, this.optionalDesc,
    this.exercises = const [], this.recoveryOptions, this.circuitNote,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// WORKOUT DATA
// ═══════════════════════════════════════════════════════════════════════════════

const workoutDays = [
  WorkoutDay(
    dayName: '周一', subtitle: '上肢 A', badge: '推力 + 后束',
    description: '胸 / 肩（前束+中束+后束） / 肱三头',
    exercises: [
      Exercise(name: '上斜哑铃卧推 30\u00B0', muscles: ['胸大肌'], muscleTarget: '上部', sets: 4, reps: '10-12', rest: '90s', isStar: true, note: '核心动作 · 上胸优先 — 穿衣显锁骨的关键，控制离心3秒下放'),
      Exercise(name: '平板杠铃卧推', muscles: ['胸大肌'], muscleTarget: '整体厚度', sets: 4, reps: '8-10', rest: '90-120s', note: '肩胛骨后缩下沉，全握距比窄握更安全'),
      Exercise(name: '坐姿器械推肩', muscles: ['三角肌'], muscleTarget: '前束 / 中束', sets: 3, reps: '12', rest: '90s', note: '器械比哑铃安全，固定轨道适合推大重量打造饱满肩头'),
      Exercise(name: '哑铃侧平举', muscles: ['三角肌'], muscleTarget: '中束', sets: 4, reps: '15-20', rest: '60s', note: '灵魂动作 — 小重量慢动作，3秒上2秒下，身体不摆动，肩膀越练越宽'),
      Exercise(name: '面拉', muscles: ['三角肌后束'], muscleTarget: '上背', sets: 3, reps: '15-20', rest: '60s', note: '改善圆肩体态必练，绳索拉到脸前，外旋拇指朝后'),
      Exercise(name: '蝴蝶机夹胸', muscles: ['胸大肌'], muscleTarget: '中缝', sets: 3, reps: '15-20', rest: '60s', note: '雕刻胸肌中缝线条，顶峰收缩2秒'),
      Exercise(name: '绳索下压', muscles: ['肱三头'], muscleTarget: '外侧头', sets: 3, reps: '12-15', rest: '60s', note: '手臂后侧线条，拒绝拜拜肉，肘部固定不动'),
      Exercise(name: '坐姿哑铃颈后臂屈伸', muscles: ['肱三头'], muscleTarget: '长头', sets: 3, reps: '10-12', rest: '60s', note: '双手持一个哑铃颈后，肘朝天花板，安全稳定'),
    ],
  ),
  WorkoutDay(
    dayName: '周二', subtitle: '下肢 A', badge: '股四头肌 / 前侧重点',
    description: '股四头肌 / 大腿前侧 / 内收肌 / 有氧 / 核心',
    exercises: [
      Exercise(name: '倒蹬机', muscles: ['股四头', '臀'], muscleTarget: '前侧重点', sets: 4, reps: '12-15', rest: '90s', isStar: true, note: '核心动作 — 专注大腿前侧发力，控制离心下放节奏'),
      Exercise(name: '坐姿腿屈伸', muscles: ['股四头'], muscleTarget: '孤立', sets: 3, reps: '15', rest: '60s', note: '重点在于顶峰收缩，雕刻大腿前侧线条'),
      Exercise(name: '内收机', muscles: ['大腿内收肌'], muscleTarget: '', sets: 3, reps: '15', rest: '60s', note: '收紧大腿内侧，改善腿型'),
      Exercise(name: '坡度走', muscles: ['有氧'], muscleTarget: '心率125-130', sets: 1, reps: '40分钟', rest: '-', note: '心率尽量稳在 125-130 左右，保持匀速不冲刺'),
      Exercise(name: '卷腹', muscles: ['腹直肌'], muscleTarget: '', sets: 5, reps: '20', rest: '30s', note: '放在有氧后，感受腹部的极致灼烧感'),
    ],
  ),
  WorkoutDay(
    dayName: '周三', subtitle: '上肢 B', badge: '拉力 + 手臂',
    description: '背 / 后束 / 肱二头',
    exercises: [
      Exercise(name: '助力引体向上机', muscles: ['背阔肌', '肱二头'], muscleTarget: '', sets: 4, reps: '8-12', rest: '90-120s', isStar: true, note: '核心动作 — 调助力等级逐步减助力；没有就做反向划船'),
      Exercise(name: '坐姿器械划船', muscles: ['背阔肌', '菱形肌'], muscleTarget: '', sets: 4, reps: '10-12', rest: '90s', note: '器械轨道稳定，胸部贴住靠垫，手肘拉过身体'),
      Exercise(name: '高位下拉', muscles: ['背阔肌'], muscleTarget: '宽度', sets: 3, reps: '10-12', rest: '90s', note: '感受背阔肌像翅膀一样拉开，手肘往下拉不后仰'),
      Exercise(name: '反向蝴蝶机夹胸', muscles: ['三角肌后束'], muscleTarget: '上背', sets: 3, reps: '15-20', rest: '60s', note: '后束第2次刺激（周一面拉 + 今天蝴蝶机 = 6组/周）'),
      Exercise(name: '直臂下压', muscles: ['背阔肌'], muscleTarget: '下部', sets: 3, reps: '12-15', rest: '60s', note: '手臂保持微弯，从头顶压到大腿前侧，感受背阔拉伸'),
      Exercise(name: '杠铃弯举', muscles: ['肱二头'], muscleTarget: '长头', sets: 4, reps: '12', rest: '60s', note: '手臂正面线条，控制离心不甩腰，全幅度动作'),
      Exercise(name: '锤式弯举', muscles: ['肱肌', '肱桡肌'], muscleTarget: '', sets: 3, reps: '12', rest: '60s', note: '掌心相对，让手臂侧面看起来更厚实有力量'),
    ],
  ),
  WorkoutDay(
    dayName: '周四', subtitle: '下肢 B', badge: '臀腿后链 / 稳定重点',
    description: '臀部后链 / 腘绳肌 / 臀中肌 / 有氧 / 核心',
    exercises: [
      Exercise(name: '哈克深蹲', muscles: ['股四头', '臀', '腘绳肌'], muscleTarget: '后链复合', sets: 4, reps: '12', rest: '90-120s', isStar: true, note: '双侧各 20kg 保持住，注意下去时慢一点，感受后侧链和臀部协同发力'),
      Exercise(name: '坐姿腿弯举', muscles: ['腘绳肌'], muscleTarget: '后侧', sets: 4, reps: '12-15', rest: '60s', note: '补足后侧，平衡膝关节压力'),
      Exercise(name: '外展机', muscles: ['臀中肌'], muscleTarget: '', sets: 3, reps: '15', rest: '60s', note: '针对臀中肌，让臀部侧面更饱满，视觉上更显腰细'),
      Exercise(name: '坡度走', muscles: ['有氧'], muscleTarget: '心率125-130', sets: 1, reps: '40分钟', rest: '-', note: '坡度走 40 分钟，匀速保持心率'),
      Exercise(name: '卷腹', muscles: ['腹直肌'], muscleTarget: '', sets: 5, reps: '20', rest: '30s', note: '感受腹部的极致灼烧感'),
    ],
  ),
  WorkoutDay(
    dayName: '周五', subtitle: '可选', badge: '可选循环',
    description: '有空就来，没空跳过', isOptional: true,
    exercises: [
      Exercise(name: '哑铃高脚杯深蹲', muscles: ['股四头', '臀', '核心'], muscleTarget: '', sets: 3, reps: '12', rest: '循环', note: '做不到可跪姿'),
      Exercise(name: '俯卧撑', muscles: ['胸', '肩', '肱三头'], muscleTarget: '', sets: 3, reps: '10-15', rest: '循环', note: '做不到可跪姿'),
      Exercise(name: '哑铃罗马尼亚硬拉', muscles: ['腘绳', '臀'], muscleTarget: '', sets: 3, reps: '12', rest: '循环'),
      Exercise(name: '哑铃俯身划船', muscles: ['背阔肌'], muscleTarget: '', sets: 3, reps: '每侧10', rest: '循环'),
      Exercise(name: '哑铃侧平举', muscles: ['三角肌'], muscleTarget: '中束', sets: 3, reps: '15', rest: '循环', note: '肩部本周第2次，高频次是肩宽秘诀'),
      Exercise(name: '登山者', muscles: ['核心', '心肺'], muscleTarget: '', sets: 3, reps: '每侧15', rest: '循环'),
    ],
    circuitNote: '6 个动作依次做完 = 1 轮 \u2192 休息 90-120s \u2192 共 3 轮',
  ),
  WorkoutDay(isRest: true, dayName: '周六', subtitle: '休息', badge: '休息', description: ''),
  WorkoutDay(
    dayName: '周日', subtitle: '可选', badge: '恢复日',
    description: '目的是恢复，不是训练', isOptional: true,
    optionalDesc: '任选其一，30-40 分钟，心率 110-135：',
    recoveryOptions: ['快走 / 慢跑', '游泳 \u2014 关节零冲击', '椭圆机 / 划船机', '瑜伽 / 普拉提', '骑车散步'],
  ),
];

const nutritionTips = [
  '热量缺口 300-500 大卡，减脂靠饮食缺口，少吃半碗饭 > 跑 20 分钟',
  '蛋白质分 4-5 餐，每餐 30-40g',
  '练后 30min 内补 20-30g 蛋白质',
  '训练日碳水 +30-50g，放练前 2h / 练后 1h',
  '每天 2.5-3L 水',
];

const progressionPhases = [
  ('1-2 周', '学习期', '60-70% 1RM，掌握动作模式，不急着加重'),
  ('3-4 周', '适应期', '70-75% 1RM，轻松完成就加 1.25-2.5kg'),
  ('5-8 周', '增长期', '75-85% 1RM，RPE 7-8，每 1-2 周加重'),
  ('9-12 周', '突破期', '接近 85% 1RM，测 1RM，8-12 周后换动作'),
];

// ═══════════════════════════════════════════════════════════════════════════════
// ANIMATION HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

class FadeScaleEntry extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  const FadeScaleEntry({super.key, required this.child, this.index = 0, this.delay = const Duration(milliseconds: 50)});
  @override
  State<FadeScaleEntry> createState() => _FadeScaleEntryState();
}

class _FadeScaleEntryState extends State<FadeScaleEntry> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade, _scale;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _scale = Tween<double>(begin: 0.92, end: 1).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
    Future.delayed(widget.delay * widget.index, () { if (mounted) _c.forward(); });
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _fade, child: ScaleTransition(scale: _scale, child: widget.child));
}

class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const PressScale({super.key, required this.child, this.onTap});
  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 120), reverseDuration: const Duration(milliseconds: 180));
    _s = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) { _c.reverse(); widget.onTap?.call(); },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(scale: _s, child: widget.child),
    );
  }
}

/// v6.0 FIX #3: Animated note — smooth fade + slide + height collapse
class AnimatedNote extends StatefulWidget {
  final String note;
  final bool visible;
  final Color color;
  const AnimatedNote({super.key, required this.note, required this.visible, required this.color});
  @override
  State<AnimatedNote> createState() => _AnimatedNoteState();
}

class _AnimatedNoteState extends State<AnimatedNote> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade, _size;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _size = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    if (widget.visible) _c.value = 1.0;
  }

  @override
  void didUpdateWidget(AnimatedNote old) {
    super.didUpdateWidget(old);
    if (widget.visible != old.visible) {
      widget.visible ? _c.forward() : _c.reverse();
    }
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizeTransition(
        sizeFactor: _size,
        axisAlignment: -1.0,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, -0.25), end: Offset.zero).animate(_fade),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(widget.note, style: GoogleFonts.inter(fontSize: 10.5, color: widget.color, height: 1.5)),
            ),
          ),
        ),
      ),
    );
  }
}

/// v6.0: Pulsing icon with animated rings for rest day card
class _PulseIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;
  const _PulseIcon({required this.icon, this.size = 56, required this.color});
  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat();
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final v = _c.value;
        final r1op = math.max(0, 0.35 * (1 - v)).toDouble();
        final r1sz = widget.size + 28 * v;
        final v2 = (v + 0.5) % 1.0;
        final r2op = math.max(0, 0.2 * (1 - v2)).toDouble();
        final r2sz = widget.size + 20 * v2;
        final glowOp = 0.15 + 0.1 * math.sin(v * math.pi * 2);
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(width: widget.size + 40, height: widget.size + 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withOpacity(glowOp * 0.3))),
            Container(width: r2sz, height: r2sz,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: widget.color.withOpacity(r2op), width: 1.5))),
            Container(width: r1sz, height: r1sz,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: widget.color.withOpacity(r1op), width: 2))),
            Container(width: widget.size, height: widget.size,
              decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withOpacity(0.1)),
              child: Icon(widget.icon, size: widget.size * 0.5, color: widget.color)),
          ],
        );
      },
    );
  }
}

class GradientTitle extends StatelessWidget {
  final String text;
  final Color primary;
  final Color accent;
  final double fontSize;
  const GradientTitle({super.key, required this.text, required this.primary, required this.accent, this.fontSize = 26});
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(colors: [primary, accent], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(text, style: GoogleFonts.inter(fontSize: fontSize, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// THEME NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════════

class ThemeInherited extends InheritedWidget {
  final AppTheme current;
  final WorkoutTheme theme;
  final Future<void> Function(AppTheme) setTheme;
  const ThemeInherited({super.key, required this.current, required this.theme, required this.setTheme, required super.child});
  static ThemeInherited of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ThemeInherited>()!;
  @override
  bool updateShouldNotify(covariant ThemeInherited old) => current != old.current;
}

class ThemeState extends StatefulWidget {
  final Widget child;
  const ThemeState({super.key, required this.child});
  @override
  State<ThemeState> createState() => _ThemeStateState();
}

class _ThemeStateState extends State<ThemeState> {
  AppTheme _mode = AppTheme.blue;
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final i = p.getInt('recomp_theme_v6') ?? 0;
      if (mounted) setState(() => _mode = AppTheme.values[i.clamp(0, AppTheme.values.length - 1)]);
    });
  }
  Future<void> setTheme(AppTheme m) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('recomp_theme_v6', m.index);
    HapticFeedback.selectionClick();
    setState(() => _mode = m);
  }
  @override
  Widget build(BuildContext context) => ThemeInherited(current: _mode, theme: themes[_mode]!, setTheme: setTheme, child: widget.child);
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN APP
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ThemeState(child: RecompApp()));
}

class RecompApp extends StatelessWidget {
  const RecompApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      final inh = ThemeInherited.of(context);
      final t = inh.theme;
      final dark = t.isDark;
      return MaterialApp(
        title: 'Body Recomp', debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: dark ? Brightness.dark : Brightness.light,
          scaffoldBackgroundColor: t.bg,
          colorScheme: ColorScheme(
            brightness: dark ? Brightness.dark : Brightness.light,
            primary: t.primary,
            onPrimary: Colors.white,
            secondary: t.accent,
            onSecondary: Colors.white,
            surface: t.card,
            onSurface: t.text1,
            error: t.warning,
            onError: Colors.white,
          ),
          appBarTheme: AppBarTheme(backgroundColor: t.bg, foregroundColor: t.text1, elevation: 0, scrolledUnderElevation: dark ? 0.2 : 0.5),
          cardTheme: CardThemeData(color: t.card, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: t.border, width: 1))),
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme),
        ),
        home: const MainPage(),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN PAGE — v6.0 FIX #1: Redesigned bottom nav with sliding pill indicator
// ═══════════════════════════════════════════════════════════════════════════════

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  int _tab = 0;
  final _pages = const [WorkoutPage(), RecordPage(), NutritionPage(), ProgressionPage(), ThemePage()];

  @override
  Widget build(BuildContext context) {
    final t = ThemeInherited.of(context).theme;
    final dark = t.isDark;
    // 设置状态栏样式：亮色主题用深色文字，暗色主题用浅色文字
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    GradientTitle(text: 'Body Recomp', primary: t.primary, accent: t.primaryLight, fontSize: 26),
                    Text('27M · 173cm · 72.5kg · BMI 24.2', style: GoogleFonts.inter(fontSize: 11, color: t.text3, fontWeight: FontWeight.w500)),
                  ])),
                  PressScale(onTap: () => HapticFeedback.lightImpact(), child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: t.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                    child: Text('目标 68-70kg', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: t.primary)),
                  )),
                ],
              ),
            ),
          ),
          Expanded(child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic, switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.02, 0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)), child: child)),
            child: KeyedSubtree(key: ValueKey(_tab), child: _pages[_tab]),
          )),
        ],
      ),
      // v6.0: Sliding pill nav bar — no splash, no shadow, just smooth pill
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: t.navbarBg, border: Border(top: BorderSide(color: t.border, width: 0.5))),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
            child: LayoutBuilder(builder: (context, box) {
              final w = box.maxWidth / 5;
              return Stack(children: [
                // Sliding pill
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic,
                  left: w * _tab + 4, top: 0, bottom: 0, width: w - 8,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: t.primary.withOpacity(t.isDark ? 0.12 : 0.08),
                      boxShadow: t.isDark
                        ? [BoxShadow(color: t.primary.withOpacity(0.15), blurRadius: 16)]
                        : [BoxShadow(color: t.primary.withOpacity(0.06), blurRadius: 8)],
                    ),
                  ),
                ),
                // Nav items
                Row(children: [
                  _navItem(Icons.fitness_center, '训练', 0, t, w),
                  _navItem(Icons.bar_chart_rounded, '记录', 1, t, w),
                  _navItem(Icons.restaurant, '饮食', 2, t, w),
                  _navItem(Icons.trending_up, '超负荷', 3, t, w),
                  _navItem(Icons.palette, '主题', 4, t, w),
                ]),
              ]);
            }),
          ),
        ),
      ),
    ),
    );
  }

  Widget _navItem(IconData icon, String label, int idx, WorkoutTheme t, double w) {
    final sel = idx == _tab;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () { if (_tab != idx) { HapticFeedback.selectionClick(); setState(() => _tab = idx); } },
        child: SizedBox(
          height: 52,
          child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300), curve: Curves.easeOutBack,
              transform: Matrix4.diagonal3Values(sel ? 1.15 : 1.0, sel ? 1.15 : 1.0, 1.0),
              child: Icon(icon, size: 22, color: Color.lerp(t.text4, t.primary, sel ? 1.0 : 0.0)),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: GoogleFonts.inter(fontSize: 10, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? t.primary : t.text4),
              child: Text(label),
            ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WORKOUT PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});
  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  int _day = 0;
  Map<String, dynamic> _done = {};
  // 计算当前是今年的第几周（ISO 8601）
  static int _currentWeek() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    // ISO周：周一为起始，第1周包含该年第一个周四
    final jan1Weekday = DateTime(now.year, 1, 1).weekday; // 1=Mon, 7=Sun
    final offset = jan1Weekday <= 4 ? jan1Weekday - 1 : jan1Weekday - 8;
    return ((dayOfYear + offset) ~/ 7) + 1;
  }

  @override
  void initState() {
    super.initState();
    final d = DateTime.now().weekday;
    if (d >= 1 && d <= 7) _day = d - 1;
    SharedPreferences.getInstance().then((p) async {
      // 每周自动重置：检查存储的周数是否与当前周数一致
      final storedWeek = p.getInt('recomp_done_v6_week');
      final currentWeek = _currentWeek();
      final storedYear = p.getInt('recomp_done_v6_year');
      final currentYear = DateTime.now().year;

      if (storedWeek == null || storedYear == null || storedYear != currentYear || storedWeek != currentWeek) {
        // 新的一周：先将旧数据归档到历史，再清空
        final r = p.getString('recomp_done_v6');
        if (r != null && r != '{}') {
          // 归档旧数据到历史
          final monthKey = 'recomp_history_${DateTime.now().year}_${DateTime.now().month.toString().padLeft(2, '0')}';
          final existing = p.getString(monthKey);
          Map<String, dynamic> history = {};
          if (existing != null) {
            try { history = jsonDecode(existing) as Map<String, dynamic>; } catch (_) {}
          }
          final oldDone = jsonDecode(r) as Map<String, dynamic>;
          final dayCounts = <int, int>{};
          oldDone.forEach((key, _) {
            final parts = key.split('_');
            if (parts.length == 2) {
              final day = int.tryParse(parts[0]);
              if (day != null) dayCounts[day] = (dayCounts[day] ?? 0) + 1;
            }
          });
          for (final entry in dayCounts.entries) {
            history['D_${entry.key}'] = entry.value;
          }
          await p.setString(monthKey, jsonEncode(history));
        }
        // 清空完成记录
        await p.setString('recomp_done_v6', jsonEncode({}));
        await p.setInt('recomp_done_v6_week', currentWeek);
        await p.setInt('recomp_done_v6_year', currentYear);
        _done = {};
      } else {
        final r = p.getString('recomp_done_v6');
        if (r != null) try { _done = jsonDecode(r) as Map<String, dynamic>; } catch (_) {}
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> _toggle(int di, int ei) async {
    final k = '${di}_$ei';
    setState(() {
      if (_done.containsKey(k)) { _done.remove(k); HapticFeedback.lightImpact(); }
      else { _done[k] = true; HapticFeedback.mediumImpact(); }
    });
    final p = await SharedPreferences.getInstance();
    await p.setString('recomp_done_v6', jsonEncode(_done));
    // 同步更新月度历史记录
    await _saveToHistory(p);
  }

  /// 将当天完成数量写入月度历史 key: recomp_history_YYYY_MM
  Future<void> _saveToHistory(SharedPreferences p) async {
    final now = DateTime.now();
    final monthKey = 'recomp_history_${now.year}_${now.month.toString().padLeft(2, '0')}';
    // 从当前 _done 中统计各天的完成数量
    final dayCounts = <int, int>{};
    _done.forEach((key, _) {
      final parts = key.split('_');
      if (parts.length == 2) {
        final day = int.tryParse(parts[0]);
        if (day != null) dayCounts[day] = (dayCounts[day] ?? 0) + 1;
      }
    });
    // 读取已有历史并合并
    final existing = p.getString(monthKey);
    Map<String, dynamic> history = {};
    if (existing != null) {
      try { history = jsonDecode(existing) as Map<String, dynamic>; } catch (_) {}
    }
    // 写入各天完成数（key 格式 "D_3" = 周一完成了3个动作）
    for (final entry in dayCounts.entries) {
      history['D_${entry.key}'] = entry.value;
    }
    await p.setString(monthKey, jsonEncode(history));
  }

  /// 读取指定月份的历史数据
  static Map<int, int> _loadMonthHistory(SharedPreferences p, int year, int month) {
    final key = 'recomp_history_${year}_${month.toString().padLeft(2, '0')}';
    final raw = p.getString(key);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final result = <int, int>{};
      map.forEach((k, v) {
        if (k.startsWith('D_')) {
          final day = int.tryParse(k.substring(2));
          if (day != null) result[day] = v as int;
        }
      });
      return result;
    } catch (_) { return {}; }
  }

  int _cnt(int d) { int c = 0; for (int i = 0; i < workoutDays[d].exercises.length; i++) if (_done.containsKey('${d}_$i')) c++; return c; }

  @override
  Widget build(BuildContext context) {
    final t = ThemeInherited.of(context).theme;
    final wd = workoutDays[_day];
    return Column(children: [
      // Day chips
      SizedBox(height: 44, child: ListView.separated(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: workoutDays.length, separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (ctx, i) {
          final d = workoutDays[i]; final s = i == _day;
          return PressScale(onTap: () { if (_day != i) { HapticFeedback.selectionClick(); setState(() => _day = i); } },
            child: AnimatedContainer(duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: s ? t.primary : Colors.transparent, borderRadius: BorderRadius.circular(22),
                border: Border.all(color: s ? t.primary : t.border, width: s ? 1.5 : 1),
                boxShadow: s ? [BoxShadow(color: t.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))] : null,
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(d.dayName, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: s ? Colors.white : t.text2)),
                Text(d.subtitle, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w500, color: s ? Colors.white.withOpacity(0.8) : t.text4)),
              ]),
            ),
          );
        },
      )),
      const SizedBox(height: 8),
      // Content
      Expanded(child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic, switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, a) => FadeTransition(opacity: a, child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.03, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: child)),
        child: KeyedSubtree(key: ValueKey('day_$_day'), child: _buildContent(wd, t)),
      )),
    ]);
  }

  Widget _buildContent(WorkoutDay day, WorkoutTheme t) {
    // v6.0 FIX #4: Redesigned Saturday rest card
    if (day.isRest) {
      return Center(child: FadeScaleEntry(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: t.isDark ? [t.card, t.primary.withOpacity(0.05)] : [t.card, t.primary.withOpacity(0.04)]),
            border: Border.all(color: t.border, width: 1),
            boxShadow: [BoxShadow(color: t.primary.withOpacity(t.isDark ? 0.15 : 0.08), blurRadius: 28, offset: const Offset(0, 10))],
          ),
          child: Padding(padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24), child: Column(
            mainAxisSize: MainAxisSize.min, children: [
              _PulseIcon(icon: Icons.bedtime_rounded, size: 64, color: t.primary),
              const SizedBox(height: 20),
              ShaderMask(
                shaderCallback: (b) => LinearGradient(colors: [t.primary, t.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(b),
                blendMode: BlendMode.srcIn,
                child: Text('休息日', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              ),
              const SizedBox(height: 12),
              Text('肌肉在休息时生长', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: t.text2, height: 1.4), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              _restTip(Icons.dark_mode_rounded, '保证 7-9 小时睡眠', t.primary, t),
              const SizedBox(height: 8),
              _restTip(Icons.water_drop_rounded, '多喝水促进恢复', t.success, t),
              const SizedBox(height: 8),
              _restTip(Icons.spa_rounded, '拉伸放松缓解酸痛', t.accent, t),
            ],
          )),
        ),
      )));
    }

    // v6.0 FIX #5: Sunday recovery — removed blank space, better layout
    if (day.recoveryOptions != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FadeScaleEntry(child: _dayHdr(day, t), index: 0),
          const SizedBox(height: 8),
          FadeScaleEntry(index: 1, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: t.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, size: 14, color: t.primary),
              const SizedBox(width: 6),
              Expanded(child: Text(day.optionalDesc!, style: GoogleFonts.inter(fontSize: 12, color: t.text3, height: 1.5, fontWeight: FontWeight.w500))),
            ]),
          )),
          const SizedBox(height: 8),
          ...day.recoveryOptions!.asMap().entries.map((e) => FadeScaleEntry(index: e.key + 2, child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(
                shape: BoxShape.circle, color: t.primary,
                boxShadow: [BoxShadow(color: t.primary.withOpacity(0.4), blurRadius: 6)])),
              const SizedBox(width: 12),
              Text(e.value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: t.text2)),
            ])),
          ))),
        ]),
      );
    }

    // Normal workout day
    final done = _cnt(_day), total = day.exercises.length, full = done == total && total > 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FadeScaleEntry(child: _dayHdr(day, t), index: 0),
        const SizedBox(height: 12),
        FadeScaleEntry(index: 1, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('训练进度', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: t.text3)),
            Text('$done/$total', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: t.primary, fontFeatures: const [FontFeature.tabularFigures()])),
          ]),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: total > 0 ? done / total : 0),
            duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic,
            builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 6, backgroundColor: t.border, valueColor: AlwaysStoppedAnimation(full ? t.success : t.primary)),
          )),
        ])),
        const SizedBox(height: 14),
        ...day.exercises.asMap().entries.map((e) => FadeScaleEntry(index: e.key + 2,
          child: _exCard(e.value, e.key + 1, _done.containsKey('${_day}_${e.key}'), t, () => _toggle(_day, e.key)))),
        if (day.circuitNote != null) FadeScaleEntry(index: day.exercises.length + 2, child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Card(color: t.primary.withOpacity(0.04), child: Padding(padding: const EdgeInsets.all(14),
            child: Text(day.circuitNote!, style: GoogleFonts.inter(fontSize: 11, color: t.text3, height: 1.6, fontWeight: FontWeight.w500)))),
        )),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _dayHdr(WorkoutDay d, WorkoutTheme t) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('${d.dayName} ${d.subtitle}', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: t.text1, letterSpacing: -0.3)),
        const SizedBox(width: 10),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: t.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
          child: Text(d.badge, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: t.primary))),
      ]),
      if (d.description.isNotEmpty) ...[const SizedBox(height: 4), Text(d.description, style: GoogleFonts.inter(fontSize: 12, color: t.text3))],
    ],
  )));

  Widget _restTip(IconData ic, String txt, Color c, WorkoutTheme t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: c.withOpacity(0.06), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: c.withOpacity(0.12), width: 0.5)),
    child: Row(children: [Icon(ic, size: 18, color: c), const SizedBox(width: 10),
      Text(txt, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: t.text2))]));

  // v6.0 FIX #3: Exercise card with animated note
  Widget _exCard(Exercise ex, int num, bool done, WorkoutTheme t, VoidCallback tap) {
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: PressScale(onTap: tap, child: Card(
      color: ex.isStar && !done ? t.primary.withOpacity(0.02) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),
        side: ex.isStar && !done ? BorderSide(color: t.primary.withOpacity(0.3), width: 1.5) : BorderSide(color: t.border, width: 1)),
      child: Padding(padding: const EdgeInsets.all(14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Checkbox
        PressScale(onTap: tap, child: AnimatedContainer(duration: const Duration(milliseconds: 250), curve: Curves.easeOutBack,
          width: 26, height: 26,
          decoration: BoxDecoration(shape: BoxShape.circle, color: done ? t.success : Colors.transparent,
            border: Border.all(color: done ? t.success : t.text4, width: 1.5),
            boxShadow: done ? [BoxShadow(color: t.success.withOpacity(0.3), blurRadius: 6)] : null),
          child: AnimatedSwitcher(duration: const Duration(milliseconds: 200),
            transitionBuilder: (c, a) => FadeTransition(opacity: a, child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)), child: c)),
            child: done ? const Icon(Icons.check, color: Colors.white, size: 14, key: ValueKey('d'))
                    : Center(child: Text('$num', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: t.text4), key: ValueKey('n$num'))),
          ),
        )),
        const SizedBox(width: 12),
        // Info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ex.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: done ? t.text4 : t.text1,
            decoration: done ? TextDecoration.lineThrough : null, decorationColor: t.text4)),
          const SizedBox(height: 3),
          Wrap(spacing: 4, runSpacing: 2, children: [
            ...ex.muscles.map((m) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: t.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(4)),
              child: Text(m, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: t.text3)))),
            if (ex.muscleTarget.isNotEmpty) Text(ex.muscleTarget, style: GoogleFonts.inter(fontSize: 9, color: t.text3)),
          ]),
          // v6.0: Animated note (fade + slide + collapse)
          if (ex.note != null) AnimatedNote(note: ex.note!, visible: !done, color: t.text3),
        ])),
        // Sets
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${ex.sets}\u00D7', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: t.primary)),
          Text(ex.reps, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: t.text2)),
          const SizedBox(height: 2),
          Text(ex.rest, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w500, color: t.text4)),
        ]),
      ])),
    )));
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// NUTRITION PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class NutritionPage extends StatelessWidget {
  const NutritionPage({super.key});
  @override
  Widget build(BuildContext context) {
    final t = ThemeInherited.of(context).theme;
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: GradientTitle(text: '饮食营养', primary: t.primary, accent: t.primaryLight, fontSize: 22))),
      SliverPadding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), sliver: SliverList(delegate: SliverChildListDelegate([
        FadeScaleEntry(index: 0, child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [_st('每日热量', '2200', 'kcal', t), _st('蛋白质', '130-160', 'g', t), _st('碳水', '200-270', 'g', t), _st('脂肪', '58-73', 'g', t)])))),
        const SizedBox(height: 16),
        FadeScaleEntry(index: 1, child: _mc('蛋白质', '130-160g', '1.8-2.2g/kg · 25%', '鸡胸 · 牛肉 · 鸡蛋 · 鱼虾 · 豆腐 · 蛋白粉', t.primary, t)),
        const SizedBox(height: 8),
        FadeScaleEntry(index: 2, child: _mc('碳水', '200-270g', '2-3g/kg · 40%', '糙米 · 红薯 · 燕麦 · 全麦 · 玉米 · 水果', t.warning, t)),
        const SizedBox(height: 8),
        FadeScaleEntry(index: 3, child: _mc('脂肪', '58-73g', '0.8-1g/kg · 30%', '橄榄油 · 坚果 · 牛油果 · 深海鱼 · 蛋黄', t.success, t)),
        const SizedBox(height: 24),
        FadeScaleEntry(index: 4, child: Text('饮食建议', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: t.text1))),
        const SizedBox(height: 10),
        ...nutritionTips.asMap().entries.map((e) => FadeScaleEntry(index: e.key + 5, child: Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 3, height: 14, margin: const EdgeInsets.only(right: 10, top: 2),
                decoration: BoxDecoration(color: t.primary, borderRadius: BorderRadius.circular(2))),
              Expanded(child: Text(nutritionTips[e.key], style: GoogleFonts.inter(fontSize: 12, color: t.text2, height: 1.6))),
            ],
          )),
        ))),
        const SizedBox(height: 8),
      ]))),
    ]);
  }
  Widget _st(String l, String v, String u, WorkoutTheme t) => Column(children: [
    Text(l, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: t.text4, letterSpacing: 0.5)),
    const SizedBox(height: 4), Text(v, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: t.primary)),
    Text(u, style: GoogleFonts.inter(fontSize: 9, color: t.text4)),
  ]);
  Widget _mc(String l, String v, String p, String f, Color c, WorkoutTheme t) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 28, height: 3, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8), Text(l, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: t.text4, letterSpacing: 1.5)),
        const Spacer(), Text(p, style: GoogleFonts.inter(fontSize: 10, color: t.text3)),
      ]),
      const SizedBox(height: 10), Text(v, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: c)),
      const SizedBox(height: 4), Text(f, style: GoogleFonts.inter(fontSize: 11, color: t.text3, height: 1.5)),
    ],
  )));
}

// ═══════════════════════════════════════════════════════════════════════════════
// RECORD PAGE — v6.3: 训练记录统计（本月日历热力图 + 本年汇总）
// ═══════════════════════════════════════════════════════════════════════════════

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});
  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  int _viewYear = DateTime.now().year;
  int _viewMonth = DateTime.now().month;
  Map<int, int> _monthData = {};
  bool _loading = true;
  int _yearTotal = 0;
  int _yearTrainDays = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final p = await SharedPreferences.getInstance();
    // 加载当前查看月份的数据
    final data = _WorkoutPageState._loadMonthHistory(p, _viewYear, _viewMonth);
    // 计算年度统计
    int yearTotal = 0, yearTrainDays = 0;
    for (int m = 1; m <= 12; m++) {
      final mData = _WorkoutPageState._loadMonthHistory(p, _viewYear, m);
      for (final v in mData.values) {
        yearTotal += v;
        yearTrainDays++;
      }
    }
    // 叠加本周当前完成数（可能还没归档）
    final curDone = p.getString('recomp_done_v6');
    if (curDone != null) {
      try {
        final done = jsonDecode(curDone) as Map<String, dynamic>;
        final now = DateTime.now();
        if (now.year == _viewYear && now.month == _viewMonth) {
          final dayCounts = <int, int>{};
          done.forEach((key, _) {
            final parts = key.split('_');
            if (parts.length == 2) {
              final day = int.tryParse(parts[0]);
              if (day != null) dayCounts[day] = (dayCounts[day] ?? 0) + 1;
            }
          });
          for (final entry in dayCounts.entries) {
            data[entry.key] = (data[entry.key] ?? 0) + entry.value;
          }
        }
        if (now.year == _viewYear) {
          // 计算本周已完成的总数
          int curWeekTotal = 0;
          done.forEach((_, __) => curWeekTotal++);
          yearTotal += curWeekTotal;
        }
      } catch (_) {}
    }
    if (mounted) setState(() { _monthData = data; _yearTotal = yearTotal; _yearTrainDays = yearTrainDays; _loading = false; });
  }

  void _prevMonth() {
    if (_viewMonth == 1) { _viewMonth = 12; _viewYear--; }
    else { _viewMonth--; }
    setState(() => _loading = true);
    _loadData();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_viewYear == now.year && _viewMonth == now.month) return;
    if (_viewMonth == 12) { _viewMonth = 1; _viewYear++; }
    else { _viewMonth++; }
    setState(() => _loading = true);
    _loadData();
  }

  int _totalExercises() {
    return _monthData.values.fold(0, (sum, v) => sum + v);
  }

  int _trainDays() {
    return _monthData.length;
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeInherited.of(context).theme;
    final dark = t.isDark;
    final daysInMonth = DateTime(_viewYear, _viewMonth + 1, 0).day;
    // 该月1号是周几（0=周一，6=周日）
    int firstWeekday = DateTime(_viewYear, _viewMonth, 1).weekday - 1;
    final now = DateTime.now();
    final isCurrentMonth = _viewYear == now.year && _viewMonth == now.month;
    final monthNames = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
    final weekLabels = ['一', '二', '三', '四', '五', '六', '日'];

    return _loading
      ? const Center(child: CircularProgressIndicator())
      : CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: GradientTitle(text: '训练记录', primary: t.primary, accent: t.primaryLight, fontSize: 22))),
        // 月份选择器
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            PressScale(onTap: _prevMonth, child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: t.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.chevron_left, size: 20, color: t.primary))),
            PressScale(onTap: () { _viewYear = DateTime.now().year; _viewMonth = DateTime.now().month; setState(() => _loading = true); _loadData(); },
              child: Column(children: [
                Text('$_viewYear年 $monthNames[_viewMonth - 1]', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: t.text1)),
                if (isCurrentMonth) Text('当前月', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: t.primary)),
              ])),
            PressScale(onTap: _nextMonth, child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: (_viewYear == DateTime.now().year && _viewMonth == DateTime.now().month) ? t.border.withOpacity(0.5) : t.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.chevron_right, size: 20, color: (_viewYear == DateTime.now().year && _viewMonth == DateTime.now().month) ? t.text4 : t.primary))),
          ],
        ))),
        // 月度统计卡片
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: FadeScaleEntry(child: Card(
          child: Padding(padding: const EdgeInsets.all(16), child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statBlock('完成动作', '${_totalExercises()}', '个', t),
              Container(width: 1, height: 36, color: t.border),
              _statBlock('训练天数', '${_trainDays()}', '天', t),
              Container(width: 1, height: 36, color: t.border),
              _statBlock('本月总计', '${_yearTotal}', '个(年)', t),
            ],
          )),
        )))),
        // 日历热力图
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: FadeScaleEntry(index: 1, child: Card(
          child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
            // 星期头
            Row(children: [
              for (int i = 0; i < 7; i++) Expanded(
                child: Center(child: Text(weekLabels[i], style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: i >= 5 ? t.text4 : t.text3))),
              ),
            ]),
            const SizedBox(height: 6),
            // 日历格子
            ..._buildCalendarRows(daysInMonth, firstWeekday, now, isCurrentMonth, t),
            const SizedBox(height: 10),
            // 图例
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('少', style: GoogleFonts.inter(fontSize: 9, color: t.text4)),
              const SizedBox(width: 4),
              _legendDot(t, 0),
              const SizedBox(width: 3),
              _legendDot(t, 0.25),
              const SizedBox(width: 3),
              _legendDot(t, 0.5),
              const SizedBox(width: 3),
              _legendDot(t, 0.75),
              const SizedBox(width: 3),
              _legendDot(t, 1.0),
              const SizedBox(width: 4),
              Text('多', style: GoogleFonts.inter(fontSize: 9, color: t.text4)),
            ]),
          ]),
        )))),
        // 年度统计
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: FadeScaleEntry(index: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$_viewYear 年度统计', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: t.text1)),
          const SizedBox(height: 8),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _statBlock('年度完成', '$_yearTotal', '个动作', t),
              _statBlock('训练天数', '$_yearTrainDays', '天', t),
            ]),
          ])),
        ]))))),
        // 12个月小月历
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('全年概览', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: t.text1)),
            const SizedBox(height: 8),
            _buildYearGrid(t),
          ],
        ))),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ]);
  }

  Widget _statBlock(String label, String value, String unit, WorkoutTheme t) => Column(children: [
    Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: t.text4, letterSpacing: 0.5)),
    const SizedBox(height: 2), Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: t.primary)),
    Text(unit, style: GoogleFonts.inter(fontSize: 9, color: t.text4)),
  ]);

  List<Widget> _buildCalendarRows(int daysInMonth, int firstWeekday, DateTime now, bool isCurrentMonth, WorkoutTheme t) {
    final rows = <Widget>[];
    int day = 1;
    for (int row = 0; row < 6; row++) {
      if (day > daysInMonth) break;
      final cells = <Widget>[];
      for (int col = 0; col < 7; col++) {
        if (row == 0 && col < firstWeekday) {
          cells.add(const SizedBox(height: 32));
        } else if (day > daysInMonth) {
          cells.add(const SizedBox(height: 32));
        } else {
          final isToday = isCurrentMonth && day == now.day;
          final count = _monthData[day] ?? 0;
          final intensity = count > 0 ? (count / 8).clamp(0.0, 1.0) : 0.0;
          cells.add(SizedBox(
            height: 32,
            child: Center(child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: count == 0 ? Colors.transparent
                  : Color.lerp(t.card, t.success, intensity),
                border: isToday ? Border.all(color: t.primary, width: 2) : null,
                boxShadow: isToday ? [BoxShadow(color: t.primary.withOpacity(0.2), blurRadius: 4)] : null,
              ),
              child: Center(child: Text('$day',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                  color: count == 0 ? (isToday ? t.primary : t.text4) : (intensity > 0.5 ? Colors.white : t.text1)))),
            )),
          ));
          day++;
        }
      }
      rows.add(Padding(padding: const EdgeInsets.only(bottom: 2), child: Row(children: cells)));
    }
    return rows;
  }

  Widget _legendDot(WorkoutTheme t, double intensity) => Container(
    width: 12, height: 12,
    decoration: BoxDecoration(shape: BoxShape.circle,
      color: intensity == 0 ? t.border : Color.lerp(t.card, t.success, intensity)),
  );

  Widget _buildYearGrid(WorkoutTheme t) {
    final now = DateTime.now();
    final monthNames = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
    final cells = <Widget>[];
    // 需要异步加载数据，但为了性能用同步方式展示当前已有数据
    // 用 FutureBuilder 加载各月数据
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox(height: 100);
        final p = snap.data!;
        return Wrap(spacing: 8, runSpacing: 8, children: [
          for (int m = 1; m <= 12; m++) _buildMiniMonth(p, _viewYear, m, monthNames[m - 1], t, m == now.month),
        ]);
      },
    );
  }

  Widget _buildMiniMonth(SharedPreferences p, int year, int month, String label, WorkoutTheme t, bool isCurrent) {
    final data = _WorkoutPageState._loadMonthHistory(p, year, month);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday - 1;
    final total = data.values.fold(0, (s, v) => s + v);
    return Container(
      width: (MediaQuery.of(context).size.width - 16 * 2 - 8 * 3) / 4,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isCurrent ? t.primary : t.border, width: isCurrent ? 1.5 : 0.5),
        color: isCurrent ? t.primary.withOpacity(0.04) : null,
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$label月', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: isCurrent ? t.primary : t.text3)),
          if (total > 0) Text('$total', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: t.success)),
        ]),
        const SizedBox(height: 4),
        // 迷你7x6网格
        ..._buildMiniGrid(daysInMonth, firstWeekday, data, t),
      ]),
    );
  }

  List<Widget> _buildMiniGrid(int daysInMonth, int firstWeekday, Map<int, int> data, WorkoutTheme t) {
    final rows = <Widget>[];
    int day = 1;
    for (int row = 0; row < 6; row++) {
      if (day > daysInMonth) break;
      final cells = <Widget>[];
      for (int col = 0; col < 7; col++) {
        if (row == 0 && col < firstWeekday || day > daysInMonth) {
          cells.add(SizedBox(width: 4, height: 4));
        } else {
          final count = data[day] ?? 0;
          cells.add(Container(width: 4, height: 4,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: count == 0 ? t.border.withOpacity(0.3) : Color.lerp(t.card, t.success, (count / 8).clamp(0.0, 1.0)))));
          day++;
        }
      }
      rows.add(Row(mainAxisAlignment: MainAxisAlignment.center, children: cells));
    }
    return rows;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROGRESSION PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class ProgressionPage extends StatelessWidget {
  const ProgressionPage({super.key});
  @override
  Widget build(BuildContext context) {
    final t = ThemeInherited.of(context).theme;
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: GradientTitle(text: '渐进超负荷', primary: t.primary, accent: t.primaryLight, fontSize: 22))),
      SliverPadding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), sliver: SliverList(delegate: SliverChildListDelegate([
        FadeScaleEntry(index: 0, child: Card(color: t.primary.withOpacity(0.04), child: Padding(padding: const EdgeInsets.all(16),
          child: Text('渐进超负荷是增肌的核心原则：逐步增加训练负荷，迫使身体适应并变得更强。每 1-2 周尝试加重或增加次数，保持训练日志记录进步。',
            style: GoogleFonts.inter(fontSize: 12, color: t.text2, height: 1.7))))),
        const SizedBox(height: 16),
        FadeScaleEntry(index: 1, child: Text('四阶段计划', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: t.text1))),
        const SizedBox(height: 10),
        ...progressionPhases.asMap().entries.map((e) {
          final (w, ti, d) = progressionPhases[e.key];
          return FadeScaleEntry(index: e.key + 2, child: Padding(padding: const EdgeInsets.only(bottom: 8), child: Card(
            child: Padding(padding: const EdgeInsets.all(16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: t.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: Center(child: Text('${e.key + 1}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: t.primary)))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(ti, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: t.text1)),
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: t.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                    child: Text(w, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: t.primary))),
                ]),
                const SizedBox(height: 4),
                Text(d, style: GoogleFonts.inter(fontSize: 12, color: t.text3, height: 1.6)),
              ])),
            ])),
          )));
        }),
        const SizedBox(height: 20),
        FadeScaleEntry(index: 7, child: Text('加重策略', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: t.text1))),
        const SizedBox(height: 10),
        ...[('上肢复合动作', '卧推 / 划船 / 推肩：每次 +1.25-2.5kg'), ('下肢复合动作', '倒蹬 / 硬拉 / 臀推：每次 +2.5-5kg'),
          ('孤立动作', '侧平举 / 弯举 / 下压：每次 +0.5-1kg 或 +1-2次'), ('遇到瓶颈', '减重 10% 重新开始，或更换动作变式刺激新角度'),
        ].asMap().entries.map((i) => FadeScaleEntry(index: i.key + 8, child: Card(
          margin: const EdgeInsets.only(bottom: 6), child: ListTile(dense: true,
            title: Text(i.value.$1, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: t.text1)),
            subtitle: Text(i.value.$2, style: GoogleFonts.inter(fontSize: 11, color: t.text3, height: 1.5)))))),
        const SizedBox(height: 8),
      ]))),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// THEME PAGE — v6.0: 6 themes including cyberpunk dark
// ═══════════════════════════════════════════════════════════════════════════════

class ThemePage extends StatelessWidget {
  const ThemePage({super.key});
  @override
  Widget build(BuildContext context) {
    final inh = ThemeInherited.of(context);
    final t = inh.theme;
    final cur = inh.current;
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: GradientTitle(text: '主题选择', primary: t.primary, accent: t.primaryLight, fontSize: 22))),
      SliverPadding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), sliver: SliverList(
        delegate: SliverChildBuilderDelegate((ctx, i) {
          final m = AppTheme.values[i];
          final mt = themes[m]!;
          final sel = m == cur;
          return FadeScaleEntry(index: i, child: Padding(padding: const EdgeInsets.only(bottom: 8), child: PressScale(
            onTap: () => inh.setTheme(m),
            child: AnimatedContainer(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: sel ? mt.primary.withOpacity(0.06) : null,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sel ? mt.primary : t.border, width: sel ? 2 : 1),
                boxShadow: sel && mt.isDark ? [BoxShadow(color: mt.primary.withOpacity(0.2), blurRadius: 16), BoxShadow(color: mt.accent.withOpacity(0.1), blurRadius: 24)]
                    : sel ? [BoxShadow(color: mt.primary.withOpacity(0.3), blurRadius: 10)] : null,
              ),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [
                // Swatch
                AnimatedContainer(duration: const Duration(milliseconds: 300), width: 44, height: 44,
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [mt.primary, mt.accent]), borderRadius: BorderRadius.circular(12),
                    boxShadow: sel && mt.isDark ? [BoxShadow(color: mt.primary.withOpacity(0.5), blurRadius: 12), BoxShadow(color: mt.accent.withOpacity(0.3), blurRadius: 16)]
                        : sel ? [BoxShadow(color: mt.primary.withOpacity(0.3), blurRadius: 10)] : null),
                  child: AnimatedSwitcher(duration: const Duration(milliseconds: 200),
                    child: sel ? const Icon(Icons.check, color: Colors.white, size: 22, key: ValueKey('s')) : null)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(mt.name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: sel ? mt.primary : t.text1)),
                  Text(sel ? '当前使用中' : '点击切换', style: GoogleFonts.inter(fontSize: 11, color: sel ? mt.primary.withOpacity(0.7) : t.text4)),
                ])),
                AnimatedContainer(duration: const Duration(milliseconds: 250), curve: Curves.easeOutBack,
                  padding: sel ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4) : EdgeInsets.zero,
                  decoration: sel ? BoxDecoration(color: mt.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)) : null,
                  child: AnimatedDefaultTextStyle(duration: const Duration(milliseconds: 250),
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: sel ? mt.primary : Colors.transparent),
                    child: const Text('已选择'))),
              ])),
            ),
          )));
        }, childCount: AppTheme.values.length),
      )),
    ]));
  }
}

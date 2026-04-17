import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// DATA MODELS
// ============================================================================

class AppThemeColors {
  final Color bg;
  final Color bg2;
  final Color bg3;
  final Color bg4;
  final Color t1;
  final Color t2;
  final Color t3;
  final Color t4;
  final Color t5;
  final Color primary;
  final Color primary2;
  final Color primary3;
  final Color primaryDim;
  final Color accent;
  final Color accent2;
  final Color success;
  final Color success2;
  final Color warning;
  final Color warning2;
  final Color rose;
  final Color rose2;
  final List<Color> gradientPrimary;
  final List<Color> gradientHero;
  final Color cardBorder;
  final Color cardShadow;
  final Color fabBg;

  AppThemeColors({
    required this.bg,
    required this.bg2,
    required this.bg3,
    required this.bg4,
    required this.t1,
    required this.t2,
    required this.t3,
    required this.t4,
    required this.t5,
    required this.primary,
    required this.primary2,
    required this.primary3,
    required this.primaryDim,
    required this.accent,
    required this.accent2,
    required this.success,
    required this.success2,
    required this.warning,
    required this.warning2,
    required this.rose,
    required this.rose2,
    required this.gradientPrimary,
    required this.gradientHero,
    required this.cardBorder,
    required this.cardShadow,
    required this.fabBg,
  });
}

enum ThemeName { blue, green, pink, purple, orange }

class Exercise {
  final String name;
  final String muscle;
  final String sets;
  final String rest;
  final String tips;
  final bool isStar;
  bool isChecked;

  Exercise({
    required this.name,
    required this.muscle,
    required this.sets,
    required this.rest,
    required this.tips,
    this.isStar = false,
    this.isChecked = false,
  });

  Exercise copyWith({bool? isChecked}) {
    return Exercise(
      name: name,
      muscle: muscle,
      sets: sets,
      rest: rest,
      tips: tips,
      isStar: isStar,
      isChecked: isChecked ?? this.isChecked,
    );
  }
}

class WorkoutDay {
  final String dayLabel;
  final String title;
  final String subtitle;
  final List<Exercise> exercises;
  final bool isRest;
  final bool isOptional;
  final String? restEmoji;
  final String? restTitle;
  final String? restDescription;
  final List<String>? activities;
  final String? circuitInfo;

  WorkoutDay({
    required this.dayLabel,
    required this.title,
    required this.subtitle,
    required this.exercises,
    this.isRest = false,
    this.isOptional = false,
    this.restEmoji,
    this.restTitle,
    this.restDescription,
    this.activities,
    this.circuitInfo,
  });
}

// ============================================================================
// THEME DEFINITIONS
// ============================================================================

class ThemeDefinitions {
  static AppThemeColors getTheme(ThemeName name) {
    switch (name) {
      case ThemeName.blue:
        return _blue();
      case ThemeName.green:
        return _green();
      case ThemeName.pink:
        return _pink();
      case ThemeName.purple:
        return _purple();
      case ThemeName.orange:
        return _orange();
    }
  }

  static AppThemeColors _blue() {
    const primary = Color(0xFF3b82f6);
    const accent = Color(0xFF8b5cf6);
    const success = Color(0xFF10b981);
    const warning = Color(0xFFf59e0b);
    const rose = Color(0xFFec4899);
    return AppThemeColors(
      bg: const Color(0xFFf8fafc),
      bg2: const Color(0xFFFFFFFF),
      bg3: const Color(0xFFf1f5f9),
      bg4: const Color(0xFFe2e8f0),
      t1: const Color(0xFF0f172a),
      t2: const Color(0xFF334155),
      t3: const Color(0xFF64748b),
      t4: const Color(0xFF94a3b8),
      t5: const Color(0xFFcbd5e1),
      primary: primary,
      primary2: const Color(0xFF60a5fa),
      primary3: const Color(0xFF93c5fd),
      primaryDim: primary.withOpacity(0.12),
      accent: accent,
      accent2: const Color(0xFFa78bfa),
      success: success,
      success2: const Color(0xFF34d399),
      warning: warning,
      warning2: const Color(0xFFfbbf24),
      rose: rose,
      rose2: const Color(0xFFf472b6),
      gradientPrimary: [primary, accent],
      gradientHero: [const Color(0xFF0f172a), primary, success],
      cardBorder: const Color(0xFFe2e8f0),
      cardShadow: Colors.black.withOpacity(0.06),
      fabBg: const Color(0xFF3b82f6),
    );
  }

  static AppThemeColors _green() {
    const primary = Color(0xFF10b981);
    const accent = Color(0xFF06b6d4);
    const success = Color(0xFF84cc16);
    return AppThemeColors(
      bg: const Color(0xFFf0fdf4),
      bg2: const Color(0xFFFFFFFF),
      bg3: const Color(0xFFdcfce7),
      bg4: const Color(0xFFbbf7d0),
      t1: const Color(0xFF052e16),
      t2: const Color(0xFF14532d),
      t3: const Color(0xFF166534),
      t4: const Color(0xFF22c55e),
      t5: const Color(0xFF86efac),
      primary: primary,
      primary2: const Color(0xFF34d399),
      primary3: const Color(0xFF6ee7b7),
      primaryDim: primary.withOpacity(0.12),
      accent: accent,
      accent2: const Color(0xFF22d3ee),
      success: success,
      success2: const Color(0xFFa3e635),
      warning: const Color(0xFFf59e0b),
      warning2: const Color(0xFFfbbf24),
      rose: const Color(0xFFec4899),
      rose2: const Color(0xFFf472b6),
      gradientPrimary: [primary, accent],
      gradientHero: [const Color(0xFF052e16), primary, success],
      cardBorder: const Color(0xFFbbf7d0),
      cardShadow: Colors.black.withOpacity(0.06),
      fabBg: const Color(0xFF10b981),
    );
  }

  static AppThemeColors _pink() {
    const primary = Color(0xFFec4899);
    const accent = Color(0xFF8b5cf6);
    return AppThemeColors(
      bg: const Color(0xFFfdf2f8),
      bg2: const Color(0xFFFFFFFF),
      bg3: const Color(0xFFfce7f3),
      bg4: const Color(0xFFfbcfe8),
      t1: const Color(0xFF831843),
      t2: const Color(0xFF9d174d),
      t3: const Color(0xFFbe185d),
      t4: const Color(0xFFdb2777),
      t5: const Color(0xFFf9a8d4),
      primary: primary,
      primary2: const Color(0xFFf472b6),
      primary3: const Color(0xFFf9a8d4),
      primaryDim: primary.withOpacity(0.12),
      accent: accent,
      accent2: const Color(0xFFa78bfa),
      success: const Color(0xFF10b981),
      success2: const Color(0xFF34d399),
      warning: const Color(0xFFf59e0b),
      warning2: const Color(0xFFfbbf24),
      rose: primary,
      rose2: const Color(0xFFf472b6),
      gradientPrimary: [primary, accent],
      gradientHero: [const Color(0xFF831843), primary, accent],
      cardBorder: const Color(0xFFfbcfe8),
      cardShadow: Colors.black.withOpacity(0.06),
      fabBg: const Color(0xFFec4899),
    );
  }

  static AppThemeColors _purple() {
    const primary = Color(0xFF8b5cf6);
    const accent = Color(0xFFec4899);
    return AppThemeColors(
      bg: const Color(0xFFfaf5ff),
      bg2: const Color(0xFFFFFFFF),
      bg3: const Color(0xFFf3e8ff),
      bg4: const Color(0xFFe9d5ff),
      t1: const Color(0xFF3b0764),
      t2: const Color(0xFF581c87),
      t3: const Color(0xFF7e22ce),
      t4: const Color(0xFFa855f7),
      t5: const Color(0xFFc4b5fd),
      primary: primary,
      primary2: const Color(0xFFa78bfa),
      primary3: const Color(0xFFc4b5fd),
      primaryDim: primary.withOpacity(0.12),
      accent: accent,
      accent2: const Color(0xFFf472b6),
      success: const Color(0xFF10b981),
      success2: const Color(0xFF34d399),
      warning: const Color(0xFFf59e0b),
      warning2: const Color(0xFFfbbf24),
      rose: const Color(0xFFec4899),
      rose2: const Color(0xFFf472b6),
      gradientPrimary: [primary, accent],
      gradientHero: [const Color(0xFF3b0764), primary, accent],
      cardBorder: const Color(0xFFe9d5ff),
      cardShadow: Colors.black.withOpacity(0.06),
      fabBg: const Color(0xFF8b5cf6),
    );
  }

  static AppThemeColors _orange() {
    const primary = Color(0xFFf97316);
    const accent = Color(0xFFeab308);
    return AppThemeColors(
      bg: const Color(0xFFfff7ed),
      bg2: const Color(0xFFFFFFFF),
      bg3: const Color(0xFFffedd5),
      bg4: const Color(0xFFfed7aa),
      t1: const Color(0xFF431407),
      t2: const Color(0xFF7c2d12),
      t3: const Color(0xFF9a3412),
      t4: const Color(0xFFea580c),
      t5: const Color(0xFFfdba74),
      primary: primary,
      primary2: const Color(0xFFfb923c),
      primary3: const Color(0xFFfdba74),
      primaryDim: primary.withOpacity(0.12),
      accent: accent,
      accent2: const Color(0xFFfacc15),
      success: const Color(0xFF10b981),
      success2: const Color(0xFF34d399),
      warning: const Color(0xFFf59e0b),
      warning2: const Color(0xFFfbbf24),
      rose: const Color(0xFFec4899),
      rose2: const Color(0xFFf472b6),
      gradientPrimary: [primary, accent],
      gradientHero: [const Color(0xFF431407), primary, accent],
      cardBorder: const Color(0xFFfed7aa),
      cardShadow: Colors.black.withOpacity(0.06),
      fabBg: const Color(0xFFf97316),
    );
  }
}

// ============================================================================
// WORKOUT DATA (preserved exactly from v1)
// ============================================================================

List<WorkoutDay> createWorkoutDays() {
  return [
    // MON - 上肢A
    WorkoutDay(
      dayLabel: '周一',
      title: '上肢A',
      subtitle: '推力+后束',
      exercises: [
        Exercise(
          name: '上斜哑铃卧推 30°',
          muscle: '胸大肌上部',
          sets: '4×10-12',
          rest: '90s',
          tips: '核心动作·上胸优先 — 穿衣显锁骨的关键，控制离心3秒下放',
          isStar: true,
        ),
        Exercise(
          name: '平板杠铃卧推',
          muscle: '胸大肌整体厚度',
          sets: '4×8-10',
          rest: '90-120s',
          tips: '肩胛骨后缩下沉，全握距比窄握更安全',
        ),
        Exercise(
          name: '坐姿器械推肩',
          muscle: '三角肌前束/中束',
          sets: '3×12',
          rest: '90s',
          tips: '器械比哑铃安全，固定轨道适合推大重量打造饱满肩头',
        ),
        Exercise(
          name: '哑铃侧平举',
          muscle: '三角肌中束',
          sets: '4×15-20',
          rest: '60s',
          tips: '灵魂动作 — 小重量慢动作，3秒上2秒下，身体不摆动，肩膀越练越宽',
        ),
        Exercise(
          name: '面拉',
          muscle: '三角肌后束/上背',
          sets: '3×15-20',
          rest: '60s',
          tips: '改善圆肩体态必练，绳索拉到脸前，外旋拇指朝后',
        ),
        Exercise(
          name: '蝴蝶机夹胸',
          muscle: '胸大肌中缝',
          sets: '3×15-20',
          rest: '60s',
          tips: '雕刻胸肌中缝线条，顶峰收缩2秒',
        ),
        Exercise(
          name: '绳索下压',
          muscle: '肱三头外侧头',
          sets: '3×12-15',
          rest: '60s',
          tips: '手臂后侧线条，拒绝拜拜肉，肘部固定不动',
        ),
        Exercise(
          name: '坐姿哑铃颈后臂屈伸',
          muscle: '肱三头长头',
          sets: '3×10-12',
          rest: '60s',
          tips: '双手持一个哑铃颈后，肘朝天花板，安全稳定',
        ),
      ],
    ),
    // TUE - 下肢A
    WorkoutDay(
      dayLabel: '周二',
      title: '下肢A',
      subtitle: '股四头/臀',
      exercises: [
        Exercise(
          name: '倒蹬机（脚位踩高）',
          muscle: '股四头/臀',
          sets: '4×15',
          rest: '90s',
          tips: '核心动作 — 脚踩高踩外侧重臀和后侧链，比深蹲安全，新手首选',
          isStar: true,
        ),
        Exercise(
          name: '哑铃罗马尼亚硬拉',
          muscle: '腘绳肌/臀',
          sets: '3×10-12',
          rest: '90s',
          tips: '膝盖微屈，髋关节后推，感受大腿后侧拉伸，比传统硬拉更安全',
        ),
        Exercise(
          name: '坐姿腿屈伸',
          muscle: '股四头孤立',
          sets: '3×12-15',
          rest: '60s',
          tips: '顶峰收缩2秒，慢放3秒，感受股四头肌燃烧',
        ),
        Exercise(
          name: '俯卧腿弯举',
          muscle: '腘绳肌',
          sets: '3×12-15',
          rest: '60s',
          tips: '强化大腿后侧，让腿部侧面更有型',
        ),
        Exercise(
          name: '站姿提踵',
          muscle: '小腿腓肠肌',
          sets: '4×20',
          rest: '45s',
          tips: '小腿紧致，视觉拉长腿部比例，顶峰收缩2秒',
        ),
        Exercise(
          name: '平板支撑',
          muscle: '核心',
          sets: '3×45-60s',
          rest: '45s',
          tips: '身体一条直线，健身房地面就能做',
        ),
      ],
    ),
    // WED - 上肢B
    WorkoutDay(
      dayLabel: '周三',
      title: '上肢B',
      subtitle: '拉力+手臂',
      exercises: [
        Exercise(
          name: '助力引体向上机',
          muscle: '背阔肌/肱二头',
          sets: '4×8-12',
          rest: '90-120s',
          tips: '核心动作 — 调助力等级逐步减助力；没有就做反向划船',
          isStar: true,
        ),
        Exercise(
          name: '坐姿器械划船',
          muscle: '背阔肌/菱形肌',
          sets: '4×10-12',
          rest: '90s',
          tips: '器械轨道稳定，胸部贴住靠垫，手肘拉过身体',
        ),
        Exercise(
          name: '高位下拉',
          muscle: '背阔肌宽度',
          sets: '3×10-12',
          rest: '90s',
          tips: '感受背阔肌像翅膀一样拉开，手肘往下拉不后仰',
        ),
        Exercise(
          name: '反向蝴蝶机夹胸',
          muscle: '三角肌后束/上背',
          sets: '3×15-20',
          rest: '60s',
          tips: '后束第2次刺激（周一面拉 + 今天蝴蝶机 = 6组/周）',
        ),
        Exercise(
          name: '直臂下压',
          muscle: '背阔肌下部',
          sets: '3×12-15',
          rest: '60s',
          tips: '手臂保持微弯，从头顶压到大腿前侧，感受背阔拉伸',
        ),
        Exercise(
          name: '杠铃弯举',
          muscle: '肱二头长头',
          sets: '4×12',
          rest: '60s',
          tips: '手臂正面线条，控制离心不甩腰，全幅度动作',
        ),
        Exercise(
          name: '锤式弯举',
          muscle: '肱肌/肱桡肌',
          sets: '3×12',
          rest: '60s',
          tips: '掌心相对，让手臂侧面看起来更厚实有力量',
        ),
      ],
    ),
    // THU - 下肢B
    WorkoutDay(
      dayLabel: '周四',
      title: '下肢B',
      subtitle: '后链+雕刻',
      exercises: [
        Exercise(
          name: '杠铃臀推',
          muscle: '臀大肌',
          sets: '4×10-12',
          rest: '90s',
          tips: '核心动作 — 顶峰收缩停顿2秒，臀部孤立发力，护腰',
          isStar: true,
        ),
        Exercise(
          name: '保加利亚分腿蹲',
          muscle: '股四头/臀',
          sets: '3×每侧10-12',
          rest: '60s',
          tips: '手持哑铃，单腿训练，矫正左右不平衡',
        ),
        Exercise(
          name: '坐姿腿弯举',
          muscle: '腘绳肌（比目鱼肌）',
          sets: '3×12-15',
          rest: '60s',
          tips: '和周二俯卧腿弯举互补，两个动作腘绳肌受力角度不同',
        ),
        Exercise(
          name: '器械内收/外展',
          muscle: '大腿内收肌',
          sets: '3×15',
          rest: '60s',
          tips: '收紧大腿内侧，改善腿型',
        ),
        Exercise(
          name: '反向卷腹',
          muscle: '腹直肌下腹',
          sets: '4×15-20',
          rest: '60s',
          tips: '仰卧抬腿卷骨盆，用腹肌把膝盖拉向胸口，下腹刺激强烈',
        ),
        Exercise(
          name: '死虫式',
          muscle: '核心稳定性',
          sets: '3×每侧10',
          rest: '45s',
          tips: '仰卧对侧手脚伸展，核心全程收紧贴地，安静不引人注目',
        ),
        Exercise(
          name: '坐姿提踵',
          muscle: '小腿比目鱼肌',
          sets: '3×20',
          rest: '45s',
          tips: '周二站姿练腓肠肌，今天坐姿练比目鱼肌，两个都练到',
        ),
      ],
    ),
    // FRI - 全身循环
    WorkoutDay(
      dayLabel: '周五',
      title: '全身循环',
      subtitle: '可选',
      isOptional: true,
      circuitInfo: '6 个动作依次做完 = 1 轮 → 休息 90-120s → 共 3 轮',
      exercises: [
        Exercise(
          name: '哑铃高脚杯深蹲',
          muscle: '股四头/臀/核心',
          sets: '3×12',
          rest: '循环',
          tips: '做不到可跪姿',
        ),
        Exercise(
          name: '俯卧撑',
          muscle: '胸/肩/肱三头',
          sets: '3×10-15',
          rest: '循环',
          tips: '做不到可跪姿',
        ),
        Exercise(
          name: '哑铃罗马尼亚硬拉',
          muscle: '腘绳/臀',
          sets: '3×12',
          rest: '循环',
          tips: '',
        ),
        Exercise(
          name: '哑铃俯身划船',
          muscle: '背阔肌',
          sets: '3×每侧10',
          rest: '循环',
          tips: '',
        ),
        Exercise(
          name: '哑铃侧平举',
          muscle: '三角肌中束',
          sets: '3×15',
          rest: '循环',
          tips: '肩部本周第2次，高频次是肩宽秘诀',
        ),
        Exercise(
          name: '登山者',
          muscle: '核心/心肺',
          sets: '3×每侧15',
          rest: '循环',
          tips: '',
        ),
      ],
    ),
    // SAT - 休息
    WorkoutDay(
      dayLabel: '周六',
      title: '休息',
      subtitle: '',
      isRest: true,
      restEmoji: '💪',
      restTitle: '休息',
      restDescription: '肌肉在休息时生长，保证 7-9 小时睡眠',
      exercises: [],
    ),
    // SUN - 主动恢复
    WorkoutDay(
      dayLabel: '周日',
      title: '主动恢复',
      subtitle: '可选',
      isOptional: true,
      activities: [
        '🚶 快走/慢跑',
        '🏊 游泳 — 关节零冲击',
        '🚣 椭圆机/划船机',
        '🧘 瑜伽/普拉提',
        '🚴 骑车散步',
      ],
      exercises: [],
    ),
  ];
}

// ============================================================================
// PERSISTENCE HELPER
// ============================================================================

class WorkoutStorage {
  static const String _themeKey = 'app_theme_name';
  static const String _prefix = 'workout_day_';

  static Future<ThemeName> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_themeKey) ?? 0;
    return ThemeName.values[index];
  }

  static Future<void> saveTheme(ThemeName theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
  }

  static String _weekKey(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return '${monday.year}_${monday.month}_${monday.day}';
  }

  static Future<Set<int>> loadChecked(int dayIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final weekKey = _weekKey(DateTime.now());
    final key = '${_prefix}$dayIndex\_$weekKey';
    final list = prefs.getStringList(key);
    if (list == null) return {};
    return list.map((s) => int.tryParse(s) ?? -1).where((i) => i >= 0).toSet();
  }

  static Future<void> saveChecked(int dayIndex, Set<int> checked) async {
    final prefs = await SharedPreferences.getInstance();
    final weekKey = _weekKey(DateTime.now());
    final key = '${_prefix}$dayIndex\_$weekKey';
    await prefs.setStringList(key, checked.map((i) => i.toString()).toList());
  }

  static Future<void> clearOldWeeks() async {
    final prefs = await SharedPreferences.getInstance();
    final currentWeek = _weekKey(DateTime.now());
    final keysToRemove = <String>[];
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_prefix) && !key.endsWith(currentWeek)) {
        keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
  }
}

// ============================================================================
// GRADIENT TEXT WIDGET
// ============================================================================

class GradientText extends StatelessWidget {
  final String text;
  final List<Color> colors;
  final TextStyle style;

  const GradientText({
    super.key,
    required this.text,
    required this.colors,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: Text(
        text,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}

// ============================================================================
// COMPACT HEADER (v2: palette icon inline, no tag badge)
// ============================================================================

class CompactHeader extends StatelessWidget {
  final AppThemeColors colors;
  final VoidCallback onThemeTap;

  const CompactHeader({
    super.key,
    required this.colors,
    required this.onThemeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Palette icon button (inline, not floating)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onThemeTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.primaryDim,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.palette_outlined,
                      size: 18,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Title
              GradientText(
                text: 'BODY RECOMP',
                colors: colors.gradientHero,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // User info in one line
          Text(
            '27M · 173cm · 72.5kg · BMI 24.2 · 减脂增肌',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colors.t3,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DAY TAB BAR (v2: primary navigation with filled selected state)
// ============================================================================

class DayTabBar extends StatelessWidget {
  final AppThemeColors colors;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<WorkoutDay> workoutDays;

  const DayTabBar({
    super.key,
    required this.colors,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.workoutDays,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.cardBorder, width: 1),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: workoutDays.length,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        itemBuilder: (context, index) {
          final day = workoutDays[index];
          final isSelected = index == selectedIndex;
          return _buildTab(day, index, isSelected);
        },
      ),
    );
  }

  Widget _buildTab(WorkoutDay day, int index, bool isSelected) {
    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? colors.primary.withOpacity(0.5)
                : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              day.dayLabel,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: day.isRest
                    ? colors.t4
                    : isSelected
                        ? colors.primary
                        : colors.t3,
              ),
            ),
            if (!day.isRest && day.title.isNotEmpty) ...[
              const SizedBox(width: 5),
              Text(
                day.title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: day.isRest
                      ? colors.t5
                      : isSelected
                          ? colors.primary
                          : colors.t4,
                ),
              ),
            ],
            if (day.isOptional && !day.isRest) ...[
              const SizedBox(width: 4),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.warning,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// COMPACT STATS ROW (v2: inline in day content, no box/border)
// ============================================================================

class CompactStats extends StatelessWidget {
  final AppThemeColors colors;

  const CompactStats({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _buildStatItem('🎯', '68-70kg', '目标体重', colors),
          Container(width: 1, height: 28, color: colors.bg4),
          _buildStatItem('🔥', '2200kcal', '每日热量', colors),
          Container(width: 1, height: 28, color: colors.bg4),
          _buildStatItem('🥩', '130-160g', '蛋白质', colors),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String icon,
    String value,
    String label,
    AppThemeColors colors,
  ) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.t1,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: colors.t4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PROGRESS BAR (simplified for v2)
// ============================================================================

class DayProgressBar extends StatelessWidget {
  final int completed;
  final int total;
  final AppThemeColors colors;

  const DayProgressBar({
    super.key,
    required this.completed,
    required this.total,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    final isComplete = completed == total && total > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isComplete ? '🎉 今日训练完成！' : '训练进度',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isComplete ? colors.success : colors.t2,
                ),
              ),
              Text(
                '$completed / $total',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isComplete ? colors.success : colors.t3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 5,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: colors.bg3,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isComplete
                              ? [colors.success, colors.success2]
                              : colors.gradientPrimary,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EXERCISE CARD (cleaned up for v2)
// ============================================================================

class ExerciseCard extends StatefulWidget {
  final Exercise exercise;
  final int index;
  final AppThemeColors colors;
  final ValueChanged<int> onCheckChanged;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.index,
    required this.colors,
    required this.onCheckChanged,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  bool _showTips = false;

  void _toggleCheck() {
    HapticFeedback.mediumImpact();
    widget.onCheckChanged(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    final isChecked = widget.exercise.isChecked;
    final colors = widget.colors;
    final exercise = widget.exercise;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isChecked ? colors.bg3.withOpacity(0.5) : colors.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: exercise.isStar && !isChecked
              ? colors.primary.withOpacity(0.3)
              : isChecked
                  ? colors.success.withOpacity(0.25)
                  : colors.cardBorder,
          width: exercise.isStar && !isChecked ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: exercise.isStar && !isChecked
                ? colors.primary.withOpacity(0.08)
                : colors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: checkbox + name + star
          GestureDetector(
            onTap: _toggleCheck,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                // Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isChecked ? colors.success : Colors.transparent,
                    border: Border.all(
                      color: isChecked
                          ? colors.success
                          : exercise.isStar
                              ? colors.primary
                              : colors.t4,
                      width: 1.5,
                    ),
                  ),
                  child: isChecked
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                // Star tag + name
                Expanded(
                  child: Row(
                    children: [
                      if (exercise.isStar) ...[
                        Text('⭐', style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          exercise.name,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isChecked ? colors.t4 : colors.t1,
                            decoration:
                                isChecked ? TextDecoration.lineThrough : null,
                            decorationColor: colors.t4,
                            decorationThickness: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Row 2: muscle tag + sets + rest
          Padding(
            padding: const EdgeInsets.only(left: 34, top: 4),
            child: Row(
              children: [
                Text(
                  exercise.muscle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isChecked ? colors.t5 : colors.t3,
                  ),
                ),
                const Spacer(),
                _buildMiniBadge('${exercise.sets}', colors, isChecked),
                const SizedBox(width: 6),
                _buildMiniBadge('⏱ ${exercise.rest}', colors, isChecked),
              ],
            ),
          ),
          // Tips (expandable)
          if (exercise.tips.isNotEmpty) ...[
            const SizedBox(height: 2),
            GestureDetector(
              onTap: () => setState(() => _showTips = !_showTips),
              child: Padding(
                padding: const EdgeInsets.only(left: 34),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showTips
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: colors.t4,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '提示',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colors.t4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _showTips
                  ? Padding(
                      padding: const EdgeInsets.only(left: 34, top: 4),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isChecked
                              ? colors.bg3.withOpacity(0.3)
                              : colors.bg3,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '💡 ${exercise.tips}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isChecked ? colors.t5 : colors.t3,
                            height: 1.5,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String text, AppThemeColors colors, bool isChecked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isChecked ? colors.bg3.withOpacity(0.3) : colors.primaryDim,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: isChecked ? colors.t5 : colors.t2,
        ),
      ),
    );
  }
}

// ============================================================================
// REST DAY CARD
// ============================================================================

class RestDayCard extends StatelessWidget {
  final WorkoutDay day;
  final AppThemeColors colors;

  const RestDayCard({super.key, required this.day, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          decoration: BoxDecoration(
            color: colors.bg2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: colors.cardShadow,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                day.restEmoji ?? '💪',
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 16),
              Text(
                day.restTitle ?? '休息',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colors.t1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                day.restDescription ?? '',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colors.t3,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ACTIVE RECOVERY CARD
// ============================================================================

class ActiveRecoveryCard extends StatelessWidget {
  final WorkoutDay day;
  final AppThemeColors colors;

  const ActiveRecoveryCard({
    super.key,
    required this.day,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final activities = day.activities ?? [];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '推荐活动',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.t2,
              ),
            ),
          ),
          ...activities.map((activity) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.bg2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: colors.cardShadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      activity,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: colors.t1,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colors.t4,
                    size: 20,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ============================================================================
// CIRCUIT INFO BANNER
// ============================================================================

class CircuitInfoBanner extends StatelessWidget {
  final String info;
  final AppThemeColors colors;

  const CircuitInfoBanner({
    super.key,
    required this.info,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.accent.withOpacity(0.08),
              colors.accent2.withOpacity(0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.accent.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.loop, color: colors.accent, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                info,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colors.t2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EXPANDABLE SECTION (NEW v2 widget)
// ============================================================================

class ExpandableSection extends StatefulWidget {
  final String title;
  final String icon;
  final Widget content;
  final AppThemeColors colors;

  const ExpandableSection({
    super.key,
    required this.title,
    required this.icon,
    required this.content,
    required this.colors,
  });

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Text(widget.icon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    widget.title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.colors.t2,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: widget.colors.t4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _isExpanded ? widget.content : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// NUTRITION TIPS (simplified from v1 NutritionSection, used in ExpandableSection)
// ============================================================================

class NutritionTips extends StatelessWidget {
  final AppThemeColors colors;

  const NutritionTips({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMacroRow('🥩', '蛋白质', '130-160g', '鸡胸肉、鱼虾、鸡蛋、蛋白粉', colors.rose),
        const SizedBox(height: 6),
        _buildMacroRow('🍚', '碳水', '200-270g', '燕麦、糙米、红薯、全麦面包', colors.warning),
        const SizedBox(height: 6),
        _buildMacroRow('🥑', '脂肪', '58-73g', '牛油果、坚果、橄榄油、蛋黄', colors.success),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.bg3.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '💡 小贴士',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.t2,
                ),
              ),
              const SizedBox(height: 6),
              _tipLine('💧 每天至少喝 2.5L 水，训练前后各 500ml'),
              _tipLine('⏰ 训练前 1.5h 吃碳水为主的一餐，训练后 30min 内补充蛋白质'),
              _tipLine('🥗 多吃深色蔬菜，补充维生素和膳食纤维'),
              _tipLine('🚫 减少加工食品、含糖饮料和油炸食品'),
              _tipLine('🌙 睡前 3h 不进食大餐，可补充少量酪蛋白'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMacroRow(
    String icon,
    String label,
    String value,
    String desc,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.bg2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.t1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      value,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: colors.t3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: colors.t3,
          height: 1.4,
        ),
      ),
    );
  }
}

// ============================================================================
// PROGRESSION INFO (simplified from v1 ProgressionSection, used in ExpandableSection)
// ============================================================================

class ProgressionInfo extends StatelessWidget {
  final AppThemeColors colors;

  const ProgressionInfo({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _phaseCard('📖', '1-2 周', '学习期', '学习正确动作模式，感受目标肌肉发力。使用轻重量，重点是动作质量和关节安全。', colors.primary),
        const SizedBox(height: 6),
        _phaseCard('💪', '3-4 周', '适应期', '身体逐渐适应训练负荷，可以小幅增加重量（每次 2.5-5%）。注意记录训练日志。', colors.accent),
        const SizedBox(height: 6),
        _phaseCard('🚀', '5-8 周', '增长期', '这是肌肉增长最快的阶段。挑战更大重量，保持渐进超负荷。确保睡眠充足、营养到位。', colors.success),
        const SizedBox(height: 6),
        _phaseCard('⚡', '9-12 周', '突破期', '尝试突破 PR。引入高级技巧：递减组、超级组、暂停休息等。12 周后安排 1 周减载。', colors.rose),
      ],
    );
  }

  Widget _phaseCard(
    String icon,
    String week,
    String title,
    String desc,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bg2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        week,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: colors.t3,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// THEME SHEET (bottom sheet for theme selection)
// ============================================================================

class ThemeSheet extends StatelessWidget {
  final AppThemeColors colors;
  final ThemeName currentTheme;
  final ValueChanged<ThemeName> onThemeChanged;

  const ThemeSheet({
    super.key,
    required this.colors,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themes = [
      (ThemeName.blue, '蓝', Color(0xFF3b82f6)),
      (ThemeName.green, '绿', Color(0xFF10b981)),
      (ThemeName.pink, '粉', Color(0xFFec4899)),
      (ThemeName.purple, '紫', Color(0xFF8b5cf6)),
      (ThemeName.orange, '橙', Color(0xFFf97316)),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.bg2,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.bg4,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '选择主题',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.t1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: themes.map((theme) {
              final isActive = theme.$1 == currentTheme;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onThemeChanged(theme.$1);
                  Navigator.pop(context);
                },
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.$3,
                        border: isActive
                            ? Border.all(color: colors.t1, width: 3)
                            : null,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: theme.$3.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: isActive
                          ? const Icon(Icons.check, color: Colors.white, size: 24)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      theme.$2,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive ? colors.t1 : colors.t3,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ============================================================================
// SUBTLE BACKGROUND (v2: static gradient, replaces AmbientBackground)
// ============================================================================

class SubtleBackground extends StatelessWidget {
  final AppThemeColors colors;

  const SubtleBackground({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primary.withOpacity(0.03),
              colors.accent.withOpacity(0.02),
              colors.bg,
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DAY CONTENT ANIMATOR (simplified for v2)
// ============================================================================

class DayContentAnimator extends StatefulWidget {
  final int dayIndex;
  final Widget child;

  const DayContentAnimator({
    super.key,
    required this.dayIndex,
    required this.child,
  });

  @override
  State<DayContentAnimator> createState() => _DayContentAnimatorState();
}

class _DayContentAnimatorState extends State<DayContentAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(DayContentAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dayIndex != widget.dayIndex) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ============================================================================
// MAIN APP
// ============================================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BodyRecompApp());
}

class BodyRecompApp extends StatefulWidget {
  const BodyRecompApp({super.key});

  @override
  State<BodyRecompApp> createState() => _BodyRecompAppState();
}

class _BodyRecompAppState extends State<BodyRecompApp> {
  ThemeName _currentTheme = ThemeName.blue;
  AppThemeColors _colors = ThemeDefinitions.getTheme(ThemeName.blue);
  bool _isLoaded = false;
  List<WorkoutDay> _workoutDays = [];
  int _selectedDay = 0;
  Map<int, Set<int>> _checkedExercises = {};
  Timer? _weekResetTimer;

  @override
  void initState() {
    super.initState();
    _workoutDays = createWorkoutDays();
    _loadData();
    _startWeekResetTimer();
  }

  @override
  void dispose() {
    _weekResetTimer?.cancel();
    super.dispose();
  }

  void _startWeekResetTimer() {
    _weekResetTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _checkWeekReset();
    });
  }

  void _checkWeekReset() {
    final now = DateTime.now();
    if (now.weekday == DateTime.monday && now.hour >= 0 && now.hour < 1) {
      final currentWeek = WorkoutStorage._weekKey(now);
      final lastWeek =
          WorkoutStorage._weekKey(now.subtract(const Duration(days: 1)));
      if (currentWeek != lastWeek) {
        WorkoutStorage.clearOldWeeks();
        setState(() {
          _checkedExercises.clear();
        });
      }
    }
  }

  Future<void> _loadData() async {
    final theme = await WorkoutStorage.loadTheme();
    final workoutDays = createWorkoutDays();
    final now = DateTime.now();
    final todayIndex = now.weekday - 1;

    final Map<int, Set<int>> checked = {};
    for (int i = 0; i < workoutDays.length; i++) {
      if (workoutDays[i].exercises.isNotEmpty) {
        checked[i] = await WorkoutStorage.loadChecked(i);
      }
    }

    if (!mounted) return;
    setState(() {
      _currentTheme = theme;
      _colors = ThemeDefinitions.getTheme(theme);
      _workoutDays = workoutDays;
      _selectedDay = todayIndex.clamp(0, workoutDays.length - 1);
      _checkedExercises = checked;
      _isLoaded = true;
    });
  }

  Future<void> _changeTheme(ThemeName theme) async {
    await WorkoutStorage.saveTheme(theme);
    setState(() {
      _currentTheme = theme;
      _colors = ThemeDefinitions.getTheme(theme);
    });
  }

  Future<void> _toggleExercise(int dayIndex, int exerciseIndex) async {
    setState(() {
      final checked = _checkedExercises[dayIndex] ?? {};
      if (checked.contains(exerciseIndex)) {
        checked.remove(exerciseIndex);
      } else {
        checked.add(exerciseIndex);
      }
      _checkedExercises[dayIndex] = checked;
      _workoutDays[dayIndex].exercises[exerciseIndex].isChecked =
          checked.contains(exerciseIndex);
    });
    await WorkoutStorage.saveChecked(dayIndex, _checkedExercises[dayIndex] ?? {});
  }

  int _getCompletedCount(int dayIndex) {
    return _checkedExercises[dayIndex]?.length ?? 0;
  }

  void _showThemeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ThemeSheet(
        colors: _colors,
        currentTheme: _currentTheme,
        onThemeChanged: _changeTheme,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: _colors.bg,
          body: Center(
            child: CircularProgressIndicator(
              color: _colors.primary,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BODY RECOMP',
      theme: ThemeData(
        scaffoldBackgroundColor: _colors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _colors.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: _colors.bg,
        body: SafeArea(
          child: Stack(
            children: [
              // Subtle static background
              SubtleBackground(colors: _colors),
              // Main scrollable content
              RefreshIndicator(
                color: _colors.primary,
                onRefresh: _loadData,
                child: CustomScrollView(
                  slivers: [
                    // Compact header with palette icon
                    SliverToBoxAdapter(
                      child: CompactHeader(
                        colors: _colors,
                        onThemeTap: _showThemeSheet,
                      ),
                    ),
                    // Day tab bar (primary navigation)
                    SliverToBoxAdapter(
                      child: DayTabBar(
                        colors: _colors,
                        selectedIndex: _selectedDay,
                        onTabSelected: (index) {
                          setState(() => _selectedDay = index);
                        },
                        workoutDays: _workoutDays,
                      ),
                    ),
                    // Selected day content
                    SliverToBoxAdapter(
                      child: _buildDayContent(),
                    ),
                    // Bottom spacing
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 32),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayContent() {
    final day = _workoutDays[_selectedDay];

    // Rest day
    if (day.isRest) {
      return DayContentAnimator(
        key: ValueKey(_selectedDay),
        dayIndex: _selectedDay,
        child: RestDayCard(day: day, colors: _colors),
      );
    }

    // Active recovery day
    if (day.activities != null && day.activities!.isNotEmpty) {
      return DayContentAnimator(
        key: ValueKey(_selectedDay),
        dayIndex: _selectedDay,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDayTitle(day),
            const SizedBox(height: 8),
            ActiveRecoveryCard(day: day, colors: _colors),
          ],
        ),
      );
    }

    // Training day
    final completed = _getCompletedCount(_selectedDay);
    final total = day.exercises.length;

    return DayContentAnimator(
      key: ValueKey(_selectedDay),
      dayIndex: _selectedDay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDayTitle(day),
          // Compact stats
          CompactStats(colors: _colors),
          // Inline tip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 13, color: _colors.warning),
                const SizedBox(width: 4),
                Text(
                  '训练日早上可做空腹有氧 20-30 分钟（可选）',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _colors.t3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Progress bar
          DayProgressBar(
            completed: completed,
            total: total,
            colors: _colors,
          ),
          // Circuit info
          if (day.circuitInfo != null)
            CircuitInfoBanner(info: day.circuitInfo!, colors: _colors),
          // Exercise cards
          ...day.exercises.asMap().entries.map((entry) {
            return ExerciseCard(
              key: ValueKey('ex_${_selectedDay}_${entry.key}'),
              exercise: entry.value.copyWith(
                isChecked: _checkedExercises[_selectedDay]?.contains(entry.key) ??
                    false,
              ),
              index: entry.key,
              colors: _colors,
              onCheckChanged: (exIndex) {
                _toggleExercise(_selectedDay, exIndex);
              },
            );
          }),
          const SizedBox(height: 8),
          // Expandable: Nutrition
          ExpandableSection(
            title: '营养建议',
            icon: '🍽️',
            colors: _colors,
            content: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NutritionTips(colors: _colors),
            ),
          ),
          // Expandable: Progression
          ExpandableSection(
            title: '进阶计划',
            icon: '📈',
            colors: _colors,
            content: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ProgressionInfo(colors: _colors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTitle(WorkoutDay day) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Text(
            '${day.dayLabel}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _colors.primary,
            ),
          ),
          if (day.title.isNotEmpty) ...[
            Text(
              ' · ${day.title}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _colors.t1,
              ),
            ),
          ],
          if (day.subtitle.isNotEmpty) ...[
            Text(
              ' · ${day.subtitle}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _colors.t4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

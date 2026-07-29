import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/recomp_models.dart';
import 'services/data_service.dart';
import 'services/history_service.dart';
import 'services/record_summary_service.dart';
import 'services/rest_timer_service.dart';
import 'services/workout_plan_service.dart';
import 'widgets/horizontal_day_swipe.dart';

const appVersion = '6.9.0';

// ═══════════════════════════════════════════════════════════════════════════════
// THEME SYSTEM — v6.6: profile + chart + settings support
// ═════════════════════════════════════════════════════════════════════════════==

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
    bg: Color(0xFFF0F4FF),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFF2563EB),
    primaryLight: Color(0xFF60A5FA),
    accent: Color(0xFF7C3AED),
    text1: Color(0xFF1E293B),
    text2: Color(0xFF334155),
    text3: Color(0xFF64748B),
    text4: Color(0xFF94A3B8),
    success: Color(0xFF2563EB),
    successLight: Color(0xFF93C5FD),
    warning: Color(0xFFD97706),
    border: Color(0xFFE2E8F0),
    navbarBg: Color(0xFFFFFFFF),
  ),
  AppTheme.pink: WorkoutTheme(
    name: '樱花飞舞 · 幻境粉',
    bg: Color(0xFFFDF2F8),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFFDB2777),
    primaryLight: Color(0xFFF472B6),
    accent: Color(0xFF7C3AED),
    text1: Color(0xFF1E293B),
    text2: Color(0xFF334155),
    text3: Color(0xFF64748B),
    text4: Color(0xFF94A3B8),
    success: Color(0xFFDB2777),
    successLight: Color(0xFFF9A8D4),
    warning: Color(0xFFD97706),
    border: Color(0xFFE2E8F0),
    navbarBg: Color(0xFFFFFFFF),
  ),
  AppTheme.orange: WorkoutTheme(
    name: '落日余晖 · 熔岩橙',
    bg: Color(0xFFFFF7ED),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFFEA580C),
    primaryLight: Color(0xFFFB923C),
    accent: Color(0xFFCA8A04),
    text1: Color(0xFF1E293B),
    text2: Color(0xFF334155),
    text3: Color(0xFF64748B),
    text4: Color(0xFF94A3B8),
    success: Color(0xFFEA580C),
    successLight: Color(0xFFFDBA74),
    warning: Color(0xFFDC2626),
    border: Color(0xFFE2E8F0),
    navbarBg: Color(0xFFFFFFFF),
  ),
  AppTheme.purple: WorkoutTheme(
    name: '璀璨银河 · 星云紫',
    bg: Color(0xFFFAF5FF),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFF7C3AED),
    primaryLight: Color(0xFFA78BFA),
    accent: Color(0xFFDB2777),
    text1: Color(0xFF1E293B),
    text2: Color(0xFF334155),
    text3: Color(0xFF64748B),
    text4: Color(0xFF94A3B8),
    success: Color(0xFF7C3AED),
    successLight: Color(0xFFC4B5FD),
    warning: Color(0xFFD97706),
    border: Color(0xFFE2E8F0),
    navbarBg: Color(0xFFFFFFFF),
  ),
  AppTheme.green: WorkoutTheme(
    name: '深邃秘境 · 森林绿',
    bg: Color(0xFFF0FDF4),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFF059669),
    primaryLight: Color(0xFF34D399),
    accent: Color(0xFF0891B2),
    text1: Color(0xFF1E293B),
    text2: Color(0xFF334155),
    text3: Color(0xFF64748B),
    text4: Color(0xFF94A3B8),
    success: Color(0xFF059669),
    successLight: Color(0xFF86EFAC),
    warning: Color(0xFFD97706),
    border: Color(0xFFE2E8F0),
    navbarBg: Color(0xFFFFFFFF),
  ),
  AppTheme.dark: WorkoutTheme(
    name: '永夜星域 · 极夜黑',
    bg: Color(0xFF0A0E1A),
    card: Color(0xFF141A2E),
    primary: Color(0xFF00F0FF),
    primaryLight: Color(0xFF66F7FF),
    accent: Color(0xFFFF0080),
    text1: Color(0xFFE8ECF4),
    text2: Color(0xFFB0B8C8),
    text3: Color(0xFF6B7A90),
    text4: Color(0xFF3D4A5C),
    success: Color(0xFF00F0FF),
    successLight: Color(0xFF66F7FF),
    warning: Color(0xFFFFB800),
    border: Color(0xFF1E2740),
    navbarBg: Color(0xFF0D1220),
    isDark: true,
  ),
};

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════════
// WORKOUT DATA
// ═══════════════════════════════════════════════════════════════════════════════

const workoutDays = [
  WorkoutDay(
    dayName: '周一',
    subtitle: '上肢 A',
    badge: '推力 + 后束',
    description: '胸 / 肩（前束+中束+后束） / 肱三头',
    exercises: [
      Exercise(
        name: '上斜哑铃卧推 30\u00B0',
        muscles: ['胸大肌'],
        muscleTarget: '上部',
        sets: 4,
        reps: '10-12',
        rest: '90s',
        isStar: true,
        note: '上胸发力，肩胛后缩下沉，离心下放约 3 秒。',
      ),
      Exercise(
        name: '平板杠铃卧推',
        muscles: ['胸大肌'],
        muscleTarget: '整体厚度',
        sets: 4,
        reps: '8-10',
        rest: '90-120s',
        note: '脚踩稳，肩胛后缩，全程控制，不要弹胸。',
      ),
      Exercise(
        name: '坐姿器械推肩',
        muscles: ['三角肌'],
        muscleTarget: '前束 / 中束',
        sets: 3,
        reps: '12',
        rest: '90s',
        note: '背部贴紧靠垫，手肘略在身体前侧，推起不耸肩。',
      ),
      Exercise(
        name: '哑铃侧平举',
        muscles: ['三角肌'],
        muscleTarget: '中束',
        sets: 4,
        reps: '15-20',
        rest: '60s',
        note: '小重量慢节奏，肘略弯，抬到肩高即可。',
      ),
      Exercise(
        name: '面拉',
        muscles: ['三角肌后束'],
        muscleTarget: '上背',
        sets: 3,
        reps: '15-20',
        rest: '60s',
        note: '绳索拉向眉眼高度，外旋打开，重点找后束和上背。',
      ),
      Exercise(
        name: '蝴蝶机夹胸',
        muscles: ['胸大肌'],
        muscleTarget: '中缝',
        sets: 3,
        reps: '15-20',
        rest: '60s',
        note: '胸肌主动夹紧，顶峰停 1-2 秒，手臂不锁死。',
      ),
      Exercise(
        name: '绳索下压',
        muscles: ['肱三头'],
        muscleTarget: '外侧头',
        sets: 3,
        reps: '12-15',
        rest: '60s',
        note: '肘部固定贴近身体，只让前臂移动，底部充分收缩。',
      ),
      Exercise(
        name: '坐姿哑铃颈后臂屈伸',
        muscles: ['肱三头'],
        muscleTarget: '长头',
        sets: 3,
        reps: '10-12',
        rest: '60s',
        note: '肘朝上并保持稳定，下放到舒适深度，避免肩部不适。',
      ),
    ],
  ),
  WorkoutDay(
    dayName: '周二',
    subtitle: '下肢 A',
    badge: '股四头肌 / 前侧重点',
    description: '股四头 / 内收 / 有氧 / 核心',
    exercises: [
      Exercise(
        name: '倒蹬机',
        muscles: ['股四头', '臀'],
        muscleTarget: '',
        sets: 4,
        reps: '12-15',
        rest: '90s',
        isStar: true,
        note: '脚位中低更偏股四头，膝盖对准脚尖，控制下放。',
      ),
      Exercise(
        name: '坐姿腿屈伸',
        muscles: ['股四头'],
        muscleTarget: '孤立',
        sets: 3,
        reps: '15',
        rest: '60s',
        note: '顶峰停 1 秒，慢慢下放，专注股四头收缩。',
      ),
      Exercise(
        name: '内收机',
        muscles: ['大腿内收肌'],
        muscleTarget: '',
        sets: 3,
        reps: '15',
        rest: '60s',
        note: '动作全程可控，不借力弹回，感受大腿内侧发力。',
      ),
      Exercise(
        name: '坡度走',
        muscles: ['心肺'],
        muscleTarget: '',
        sets: 1,
        reps: '40min',
        rest: '',
        note: '保持能说短句的强度，心率约 125-130，稳定完成。',
      ),
      Exercise(
        name: '卷腹',
        muscles: ['腹直肌'],
        muscleTarget: '',
        sets: 5,
        reps: '20',
        rest: '60s',
        note: '下背贴紧，吐气卷起，避免用脖子代偿。',
      ),
    ],
  ),
  WorkoutDay(
    dayName: '周三',
    subtitle: '上肢 B',
    badge: '拉力 + 手臂',
    description: '背 / 后束 / 肱二头',
    exercises: [
      Exercise(
        name: '助力引体向上机',
        muscles: ['背阔肌', '肱二头'],
        muscleTarget: '',
        sets: 4,
        reps: '8-12',
        rest: '90-120s',
        isStar: true,
        note: '逐步减少助力，胸口主动上提，肩膀不要耸。',
      ),
      Exercise(
        name: '坐姿器械划船',
        muscles: ['背阔肌', '菱形肌'],
        muscleTarget: '',
        sets: 4,
        reps: '10-12',
        rest: '90s',
        note: '胸部贴垫，手肘向后拉，顶峰夹背 1 秒。',
      ),
      Exercise(
        name: '高位下拉',
        muscles: ['背阔肌'],
        muscleTarget: '宽度',
        sets: 3,
        reps: '10-12',
        rest: '90s',
        note: '先沉肩再下拉，手肘向身体两侧下沉，身体不后仰。',
      ),
      Exercise(
        name: '反向蝴蝶机夹胸',
        muscles: ['三角肌后束'],
        muscleTarget: '上背',
        sets: 3,
        reps: '15-20',
        rest: '60s',
        note: '手肘微弯，打开到身体两侧，重点找后束发力。',
      ),
      Exercise(
        name: '直臂下压',
        muscles: ['背阔肌'],
        muscleTarget: '下部',
        sets: 3,
        reps: '12-15',
        rest: '60s',
        note: '手臂微弯固定，从头顶压到大腿前，感受背阔拉伸收缩。',
      ),
      Exercise(
        name: '杠铃弯举',
        muscles: ['肱二头'],
        muscleTarget: '长头',
        sets: 4,
        reps: '12',
        rest: '60s',
        note: '身体不晃，手腕中立，离心慢放。',
      ),
      Exercise(
        name: '锤式弯举',
        muscles: ['肱肌', '肱桡肌'],
        muscleTarget: '',
        sets: 3,
        reps: '12',
        rest: '60s',
        note: '掌心相对，手肘稳定，感受肱肌和前臂参与。',
      ),
    ],
  ),
  WorkoutDay(
    dayName: '周四',
    subtitle: '下肢 B',
    badge: '臀腿后链 / 稳定重点',
    description: '臀腿后链 / 稳定 / 有氧 / 核心',
    exercises: [
      Exercise(
        name: '哈克深蹲',
        muscles: ['股四头', '臀'],
        muscleTarget: '',
        sets: 4,
        reps: '12',
        rest: '90s',
        isStar: true,
        note: '脚踩稳，膝盖跟脚尖同向，控制下放后再发力站起。',
      ),
      Exercise(
        name: '坐姿腿弯举',
        muscles: ['腘绳肌'],
        muscleTarget: '',
        sets: 4,
        reps: '12-15',
        rest: '60s',
        note: '顶峰夹紧腘绳肌，慢慢还原，不要甩重量。',
      ),
      Exercise(
        name: '外展机',
        muscles: ['臀中肌'],
        muscleTarget: '',
        sets: 3,
        reps: '15',
        rest: '60s',
        note: '身体稳定，外展到顶峰停顿，重点找臀中肌。',
      ),
      Exercise(
        name: '坡度走',
        muscles: ['心肺'],
        muscleTarget: '',
        sets: 1,
        reps: '40min',
        rest: '',
        note: '保持能说短句的强度，心率约 125-130，稳定完成。',
      ),
      Exercise(
        name: '卷腹',
        muscles: ['腹直肌'],
        muscleTarget: '',
        sets: 5,
        reps: '20',
        rest: '60s',
        note: '下背贴紧，吐气卷起，避免用脖子代偿。',
      ),
    ],
  ),
  WorkoutDay(
    dayName: '周五',
    subtitle: '可选',
    badge: '可选循环',
    description: '有空就来，没空跳过',
    isOptional: true,
    exercises: [
      Exercise(
        name: '哑铃高脚杯深蹲',
        muscles: ['股四头', '臀', '核心'],
        muscleTarget: '',
        sets: 3,
        reps: '12',
        rest: '循环',
        note: '抱紧哑铃，躯干稳定，下蹲到可控深度。',
      ),
      Exercise(
        name: '俯卧撑',
        muscles: ['胸', '肩', '肱三头'],
        muscleTarget: '',
        sets: 3,
        reps: '10-15',
        rest: '循环',
        note: '身体保持一条线，胸靠近地面，做不到可跪姿或扶高位。',
      ),
      Exercise(
        name: '哑铃罗马尼亚硬拉',
        muscles: ['腘绳', '臀'],
        muscleTarget: '',
        sets: 3,
        reps: '12',
        rest: '循环',
        note: '髋部向后折叠，背部中立，感受腘绳肌拉伸。',
      ),
      Exercise(
        name: '哑铃俯身划船',
        muscles: ['背阔肌'],
        muscleTarget: '',
        sets: 3,
        reps: '每侧10',
        rest: '循环',
        note: '背部保持平，手肘贴近身体向后拉。',
      ),
      Exercise(
        name: '哑铃侧平举',
        muscles: ['三角肌'],
        muscleTarget: '中束',
        sets: 3,
        reps: '15',
        rest: '循环',
        note: '小重量慢节奏，肘略弯，抬到肩高即可。',
      ),
      Exercise(
        name: '登山者',
        muscles: ['核心', '心肺'],
        muscleTarget: '',
        sets: 3,
        reps: '每侧15',
        rest: '循环',
        note: '核心收紧，节奏稳定，膝盖向胸口交替带动。',
      ),
    ],
    circuitNote: '6 个动作依次做完 = 1 轮 \u2192 休息 90-120s \u2192 共 3 轮',
  ),
  WorkoutDay(
    isRest: true,
    dayName: '周六',
    subtitle: '休息',
    badge: '休息',
    description: '',
  ),
  WorkoutDay(
    dayName: '周日',
    subtitle: '可选',
    badge: '恢复日',
    description: '目的是恢复，不是训练',
    isOptional: true,
    optionalDesc: '任选其一，30-40 分钟，心率 110-135：',
    recoveryOptions: [
      '快走 / 慢跑',
      '游泳 \u2014 关节零冲击',
      '椭圆机 / 划船机',
      '瑜伽 / 普拉提',
      '骑车散步',
    ],
  ),
];

final workoutPlanRevision = ValueNotifier<int>(0);

const nutritionTips = [
  '热量缺口 300-500 大卡，减脂靠饮食缺口，少吃半碗饭 > 跑 20 分钟',
  '蛋白质分 4-5 餐，每餐 30-40g',
  '训练后 1-2 小时内补 20-30g 蛋白质',
  '训练日碳水 +30-50g，放训练前 2h / 训练后 1h',
  '每天 2.5-3L 水',
];

const progressionPhases = [
  ('1-2 周', '学习期', '60-70% 1RM，掌握动作模式，不急着加重'),
  ('3-4 周', '适应期', '70-75% 1RM，轻松完成就加 1.25-2.5kg'),
  ('5-8 周', '增长期', '75-85% 1RM，RPE 7-8，每 1-2 周加重'),
  ('9-12 周', '突破期', '接近 85% 1RM，测 1RM，8-12 周后换动作'),
];

// ═══════════════════════════════════════════════════════════════════════════════
// v6.5: HISTORY HELPERS — ISO 周 + 真实日期归档
// ═══════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════════
// ANIMATION HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

class FadeScaleEntry extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  const FadeScaleEntry({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = const Duration(milliseconds: 35),
  });
  @override
  State<FadeScaleEntry> createState() => _FadeScaleEntryState();
}

class _FadeScaleEntryState extends State<FadeScaleEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade, _scale;
  Timer? _startTimer;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _scale = Tween<double>(
      begin: 0.96,
      end: 1,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _startTimer = Timer(widget.delay * widget.index, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: ScaleTransition(scale: _scale, child: widget.child),
      );
}

class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const PressScale({super.key, required this.child, this.onTap});
  @override
  State<PressScale> createState() => _PressScaleState();
}

class CompletionPulse extends StatefulWidget {
  final bool active;
  final Widget child;

  const CompletionPulse({super.key, required this.active, required this.child});

  @override
  State<CompletionPulse> createState() => _CompletionPulseState();
}

class _CompletionPulseState extends State<CompletionPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _scale = Tween<double>(
      begin: 1,
      end: 1.018,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant CompletionPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.active) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        key: const Key('exercise-completion-pulse'),
        scale: _scale,
        child: widget.child,
      );
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _s = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(scale: _s, child: widget.child),
    );
  }
}

class AnimatedNote extends StatefulWidget {
  final String note;
  final bool visible;
  final Color color;
  const AnimatedNote({
    super.key,
    required this.note,
    required this.visible,
    required this.color,
  });
  @override
  State<AnimatedNote> createState() => _AnimatedNoteState();
}

class _AnimatedNoteState extends State<AnimatedNote>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade, _size;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
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
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizeTransition(
        sizeFactor: _size,
        axisAlignment: -1.0,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.25),
              end: Offset.zero,
            ).animate(_fade),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                widget.note,
                style: TextStyle(
                  fontSize: 10.5,
                  color: widget.color,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;
  const _PulseIcon({required this.icon, this.size = 56, required this.color});
  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

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
            Container(
              width: widget.size + 40,
              height: widget.size + 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(glowOp * 0.3),
              ),
            ),
            Container(
              width: r2sz,
              height: r2sz,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withOpacity(r2op),
                  width: 1.5,
                ),
              ),
            ),
            Container(
              width: r1sz,
              height: r1sz,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withOpacity(r1op),
                  width: 2,
                ),
              ),
            ),
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(0.1),
              ),
              child: Icon(
                widget.icon,
                size: widget.size * 0.5,
                color: widget.color,
              ),
            ),
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
  const GradientTitle({
    super.key,
    required this.text,
    required this.primary,
    required this.accent,
    this.fontSize = 26,
  });
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [primary, accent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
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
  const ThemeInherited({
    super.key,
    required this.current,
    required this.theme,
    required this.setTheme,
    required super.child,
  });
  static ThemeInherited of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeInherited>()!;
  @override
  bool updateShouldNotify(covariant ThemeInherited old) =>
      current != old.current;
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
      if (mounted)
        setState(
          () => _mode = AppTheme.values[i.clamp(0, AppTheme.values.length - 1)],
        );
    });
  }

  Future<void> setTheme(AppTheme m) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('recomp_theme_v6', m.index);
    if (!mounted) return;
    HapticFeedback.selectionClick();
    setState(() => _mode = m);
  }

  @override
  Widget build(BuildContext context) => ThemeInherited(
        current: _mode,
        theme: themes[_mode]!,
        setTheme: setTheme,
        child: widget.child,
      );
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
    return Builder(
      builder: (context) {
        final inh = ThemeInherited.of(context);
        final t = inh.theme;
        final dark = t.isDark;
        return MaterialApp(
          title: 'Body Recomp',
          debugShowCheckedModeBanner: false,
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
            appBarTheme: AppBarTheme(
              backgroundColor: t.bg,
              foregroundColor: t.text1,
              elevation: 0,
              scrolledUnderElevation: dark ? 0.2 : 0.5,
            ),
            cardTheme: CardThemeData(
              color: t.card,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: t.border.withOpacity(dark ? 0.72 : 0.85),
                  width: 0.8,
                ),
              ),
            ),
            useMaterial3: true,
            fontFamily: 'Inter',
            fontFamilyFallback: const ['sans-serif'],
            textTheme: (dark
                    ? ThemeData.dark().textTheme
                    : ThemeData.light().textTheme)
                .apply(fontFamily: 'Inter'),
          ),
          home: const MainPage(),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN PAGE — v6.5: refined chrome + smoother tonal navigation
// ═══════════════════════════════════════════════════════════════════════════════

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  int _tab = 0;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    loadProfile().then((p) {
      if (mounted) setState(() => _profile = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeInherited.of(context).theme;
    final dark = t.isDark;
    final p = _profile;
    final bmi = p != null && p.heightCm > 0
        ? (p.weightKg / ((p.heightCm / 100) * (p.heightCm / 100)))
            .toStringAsFixed(1)
        : '--';
    final ageStr = (p != null && p.age > 0) ? '${p.age}岁' : '--';
    final heightStr =
        (p != null && p.heightCm > 0) ? '${p.heightCm.toInt()}cm' : '--';
    final weightStr = (p != null && p.weightKg > 0) ? '${p.weightKg}kg' : '--';
    final statusText = '$ageStr · $heightStr · $weightStr · BMI $bmi';
    final pages = [
      WorkoutPage(),
      NutritionPage(),
      ProgressionPage(),
      RecordPage(),
      SettingsPage(
        onProfileChanged: () => loadProfile().then((profile) {
          if (mounted) setState(() => _profile = profile);
        }),
      ),
    ];
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GradientTitle(
                            text: 'Body Recomp',
                            primary: t.primary,
                            accent: t.primaryLight,
                            fontSize: 27,
                          ),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
                              color: t.text3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    PressScale(
                      onTap: _showThemeSheet,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: t.card.withOpacity(t.isDark ? 0.92 : 0.86),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: t.border.withOpacity(0.9),
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                t.isDark ? 0.24 : 0.05,
                              ),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.palette_rounded,
                          size: 20,
                          color: t.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.02, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: anim,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(key: ValueKey(_tab), child: pages[_tab]),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: t.navbarBg.withOpacity(t.isDark ? 0.96 : 0.94),
            border: Border(
              top: BorderSide(color: t.border.withOpacity(0.8), width: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(t.isDark ? 0.28 : 0.05),
                blurRadius: 18,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
              child: LayoutBuilder(
                builder: (context, box) {
                  final w = box.maxWidth / 5;
                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        left: w * _tab + 4,
                        top: 0,
                        bottom: 0,
                        width: w - 8,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: t.primary.withOpacity(
                              t.isDark ? 0.12 : 0.08,
                            ),
                            boxShadow: t.isDark
                                ? [
                                    BoxShadow(
                                      color: t.primary.withOpacity(0.15),
                                      blurRadius: 16,
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: t.primary.withOpacity(0.06),
                                      blurRadius: 8,
                                    ),
                                  ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          _navItem(Icons.fitness_center, '训练', 0, t, w),
                          _navItem(Icons.restaurant, '饮食', 1, t, w),
                          _navItem(Icons.trending_up, '超负荷', 2, t, w),
                          _navItem(Icons.bar_chart_rounded, '记录', 3, t, w),
                          _navItem(Icons.settings_rounded, '设置', 4, t, w),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    int idx,
    WorkoutTheme t,
    double w,
  ) {
    final sel = idx == _tab;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_tab != idx) {
            HapticFeedback.selectionClick();
            setState(() => _tab = idx);
          }
        },
        child: SizedBox(
          height: 52,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                transform: Matrix4.diagonal3Values(
                  sel ? 1.10 : 1.0,
                  sel ? 1.10 : 1.0,
                  1.0,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: Color.lerp(t.text4, t.primary, sel ? 1.0 : 0.0),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color: sel ? t.primary : t.text4,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final inh = ThemeInherited.of(ctx);
        final t = inh.theme;
        final cur = inh.current;
        return Container(
          decoration: BoxDecoration(
            color: t.navbarBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '主题选择',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: t.text1,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: t.border.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, size: 18, color: t.text3),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: AppTheme.values.map((m) {
                        final mt = themes[m]!;
                        final sel = m == cur;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: PressScale(
                            onTap: () {
                              inh.setTheme(m);
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    sel ? mt.primary.withOpacity(0.06) : null,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: sel ? mt.primary : t.border,
                                  width: sel ? 2 : 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [mt.primary, mt.accent],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: sel
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 20,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            mt.name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: sel ? mt.primary : t.text1,
                                            ),
                                          ),
                                          Text(
                                            sel ? '当前使用中' : '点击切换',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: sel
                                                  ? mt.primary.withOpacity(0.7)
                                                  : t.text4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WORKOUT PAGE — v6.5: 每周自动重置 + 滑动周选择器 + 历史记录同步
// ═══════════════════════════════════════════════════════════════════════════════

class _DaySegmentedNav extends StatelessWidget {
  final int selected;
  final WorkoutTheme theme;
  final ValueChanged<int> onSelect;
  const _DaySegmentedNav({
    required this.selected,
    required this.theme,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      height: 54,
      padding: const EdgeInsets.all(4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.navbarBg.withOpacity(t.isDark ? 0.92 : 0.78),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: t.border.withOpacity(t.isDark ? 0.8 : 0.72),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(t.isDark ? 0.16 : 0.025),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final itemWidth = box.maxWidth / workoutDays.length;
          final pillInset = 2.0;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 340),
                curve: Curves.easeOutCubic,
                left: itemWidth * selected + pillInset,
                top: pillInset,
                bottom: pillInset,
                width: itemWidth - pillInset * 2,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [t.primary, t.primaryLight],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: t.primary.withOpacity(t.isDark ? 0.20 : 0.14),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: List.generate(workoutDays.length, (i) {
                  final d = workoutDays[i];
                  final sel = i == selected;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(i),
                      child: SizedBox(
                        height: 46,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 220),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    sel ? FontWeight.w900 : FontWeight.w700,
                                color: sel ? Colors.white : t.text2,
                                letterSpacing: -0.2,
                              ),
                              child: Text(d.dayName.replaceFirst('周', '')),
                            ),
                            const SizedBox(height: 2),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 220),
                              style: TextStyle(
                                fontSize: 7.5,
                                fontWeight:
                                    sel ? FontWeight.w700 : FontWeight.w500,
                                color: sel
                                    ? Colors.white.withOpacity(0.86)
                                    : t.text4,
                              ),
                              child: Text(
                                d.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});
  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  int _day = 0;
  Map<String, dynamic> _done = {};
  List<WorkoutDay> _plan = List<WorkoutDay>.from(workoutDays);
  Timer? _restTimer;
  int _restTotal = 0;
  int _restRemaining = 0;
  String _restExercise = '';
  bool _autoRestTimer = true;
  Future<void> _saveQueue = Future<void>.value();

  @override
  void initState() {
    super.initState();
    workoutPlanRevision.addListener(_reloadPlan);
    final d = DateTime.now().weekday;
    if (d >= 1 && d <= 7) _day = d - 1;
    SharedPreferences.getInstance().then((p) async {
      final now = DateTime.now();
      final currentWeek = isoWeekNumber(now);
      final currentYear = isoWeekYear(now);
      final storedWeek = p.getInt('recomp_done_v6_week');
      final storedYear = p.getInt('recomp_done_v6_year');

      if (storedWeek == null ||
          storedYear == null ||
          storedYear != currentYear ||
          storedWeek != currentWeek) {
        // 新的一周：先将旧数据按真实日期归档，再清空。
        final oldRaw = p.getString('recomp_done_v6');
        if (oldRaw != null && oldRaw != '{}') {
          try {
            final oldDone = jsonDecode(oldRaw) as Map<String, dynamic>;
            final archiveYear = storedYear ?? currentYear;
            final archiveWeek = storedWeek ?? currentWeek;
            await saveWeekDoneToHistory(p, oldDone, archiveYear, archiveWeek);
          } catch (_) {}
        }
        await p.setString('recomp_done_v6', jsonEncode({}));
        await p.setInt('recomp_done_v6_week', currentWeek);
        await p.setInt('recomp_done_v6_year', currentYear);
        _done = {};
      } else {
        final r = p.getString('recomp_done_v6');
        if (r != null) {
          try {
            _done = jsonDecode(r) as Map<String, dynamic>;
          } catch (_) {}
        }
      }
      if (mounted) setState(() {});
    });
    _reloadPlan();
    loadAutoRestTimer().then((enabled) {
      if (mounted) setState(() => _autoRestTimer = enabled);
    });
  }

  Future<void> _reloadPlan() async {
    final plan = await loadWorkoutPlan(workoutDays);
    if (mounted) setState(() => _plan = plan);
  }

  @override
  void dispose() {
    workoutPlanRevision.removeListener(_reloadPlan);
    _restTimer?.cancel();
    super.dispose();
  }

  void _selectDay(int day) {
    final next = (day + workoutDays.length) % workoutDays.length;
    if (_day == next) return;
    HapticFeedback.selectionClick();
    setState(() => _day = next);
  }

  Future<void> _toggle(int di, int ei) async {
    final k = '${di}_$ei';
    final exercise = _plan[di].exercises[ei];
    final completedSets = _completedSets(di, ei);
    final resetting = completedSets >= exercise.sets;
    final nextCompletedSets = resetting ? 0 : completedSets + 1;
    setState(() {
      if (resetting) {
        _done.remove(k);
        HapticFeedback.lightImpact();
      } else {
        _done[k] = nextCompletedSets;
        HapticFeedback.mediumImpact();
      }
    });
    if (!resetting && nextCompletedSets < exercise.sets && _autoRestTimer) {
      _startRestTimer(exercise);
    }
    final snapshot = Map<String, dynamic>.from(_done);
    final previous = _saveQueue;
    _saveQueue = () async {
      try {
        await previous;
      } catch (_) {
        // A later snapshot should still be persisted after a transient error.
      }
      await _persistDone(snapshot);
    }();
    await _saveQueue;
  }

  Future<void> _persistDone(Map<String, dynamic> done) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('recomp_done_v6', jsonEncode(done));
    // 同步写入本周真实日期历史；取消勾选时也会移除当天记录。
    final now = DateTime.now();
    final currentWeek = isoWeekNumber(now);
    final currentYear = isoWeekYear(now);
    await p.setInt('recomp_done_v6_week', currentWeek);
    await p.setInt('recomp_done_v6_year', currentYear);
    await saveWeekDoneToHistory(p, done, currentYear, currentWeek);
  }

  void _startRestTimer(Exercise exercise) {
    final seconds = parseRestSeconds(exercise.rest);
    if (seconds == null) return;
    _restTimer?.cancel();
    setState(() {
      _restTotal = seconds;
      _restRemaining = seconds;
      _restExercise = exercise.name;
    });
    _runRestTicker();
  }

  void _runRestTicker() {
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_restRemaining <= 1) {
        _restTimer?.cancel();
        setState(() => _restRemaining = 0);
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.click);
      } else {
        setState(() => _restRemaining--);
      }
    });
  }

  void _addRestTime() {
    if (_restTotal == 0) return;
    setState(() {
      _restRemaining += 30;
      if (_restRemaining > _restTotal) _restTotal = _restRemaining;
    });
    if (_restTimer?.isActive != true) {
      _runRestTicker();
    }
  }

  void _dismissRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _restTotal = 0;
      _restRemaining = 0;
      _restExercise = '';
    });
  }

  int _cnt(int d) {
    int c = 0;
    for (int i = 0; i < _plan[d].exercises.length; i++) {
      if (_completedSets(d, i) >= _plan[d].exercises[i].sets) c++;
    }
    return c;
  }

  int _completedSets(int dayIndex, int exerciseIndex) {
    final value = _done['${dayIndex}_$exerciseIndex'];
    final totalSets = _plan[dayIndex].exercises[exerciseIndex].sets;
    if (value == true) return totalSets;
    if (value is num) return value.toInt().clamp(0, totalSets);
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeInherited.of(context).theme;
    final wd = _plan[_day];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
          child: _DaySegmentedNav(
            selected: _day,
            theme: t,
            onSelect: _selectDay,
          ),
        ),
        Expanded(
          child: HorizontalDaySwipe(
            onPrevious: () => _selectDay(_day - 1),
            onNext: () => _selectDay(_day + 1),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.02, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey('day_$_day'),
                child: _buildContent(wd, t),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(WorkoutDay day, WorkoutTheme t) {
    if (day.isRest) {
      return Center(
        child: FadeScaleEntry(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: t.isDark
                      ? [t.card, t.primary.withOpacity(0.05)]
                      : [t.card, t.primary.withOpacity(0.04)],
                ),
                border: Border.all(color: t.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: t.primary.withOpacity(t.isDark ? 0.15 : 0.08),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 36,
                  horizontal: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PulseIcon(
                      icon: Icons.bedtime_rounded,
                      size: 64,
                      color: t.primary,
                    ),
                    const SizedBox(height: 20),
                    ShaderMask(
                      shaderCallback: (b) => LinearGradient(
                        colors: [t.primary, t.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(b),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        '休息日',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '肌肉在休息时生长',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: t.text2,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    _restTip(
                      Icons.dark_mode_rounded,
                      '保证 7-9 小时睡眠',
                      t.primary,
                      t,
                    ),
                    const SizedBox(height: 8),
                    _restTip(Icons.water_drop_rounded, '多喝水促进恢复', t.success, t),
                    const SizedBox(height: 8),
                    _restTip(Icons.spa_rounded, '拉伸放松缓解酸痛', t.accent, t),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (day.recoveryOptions != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeScaleEntry(child: _dayHdr(day, t), index: 0),
            const SizedBox(height: 8),
            FadeScaleEntry(
              index: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: t.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: t.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        day.optionalDesc!,
                        style: TextStyle(
                          fontSize: 12,
                          color: t.text3,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...day.recoveryOptions!.asMap().entries.map(
                  (e) => FadeScaleEntry(
                    index: e.key + 2,
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: t.primary,
                                boxShadow: [
                                  BoxShadow(
                                    color: t.primary.withOpacity(0.4),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              e.value,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: t.text2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      );
    }

    final done = _cnt(_day);
    final total = day.exercises.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeScaleEntry(child: _dayHdr(day, t), index: 0),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1,
                child: child,
              ),
            ),
            child: _restTotal > 0
                ? Padding(
                    key: const ValueKey('rest-timer-visible'),
                    padding: const EdgeInsets.only(top: 10),
                    child: _restTimerPanel(t),
                  )
                : const SizedBox.shrink(key: ValueKey('rest-timer-hidden')),
          ),
          const SizedBox(height: 12),
          FadeScaleEntry(
            index: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: t.success,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: t.success.withOpacity(0.28),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '训练进度',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: t.text3,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$done/$total',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: t.success,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: total > 0 ? done / total : 0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v,
                      minHeight: 7,
                      backgroundColor: t.border.withOpacity(
                        t.isDark ? 0.7 : 0.9,
                      ),
                      valueColor: AlwaysStoppedAnimation(t.success),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                ),
                child: child,
              ),
            ),
            child: total > 0 && done == total
                ? Padding(
                    key: ValueKey('workout-complete-$_day'),
                    padding: const EdgeInsets.only(top: 12),
                    child: _workoutCompletePanel(day, t),
                  )
                : const SizedBox.shrink(key: ValueKey('workout-incomplete')),
          ),
          const SizedBox(height: 14),
          ...day.exercises.asMap().entries.map(
                (e) => FadeScaleEntry(
                  key: ValueKey('entry_${_day}_${e.key}'),
                  index: e.key,
                  delay: const Duration(milliseconds: 38),
                  child: RepaintBoundary(
                    child: _exCard(
                      e.value,
                      e.key + 1,
                      _completedSets(_day, e.key),
                      t,
                      () => _toggle(_day, e.key),
                      parseRestSeconds(e.value.rest) == null
                          ? null
                          : () => _startRestTimer(e.value),
                    ),
                  ),
                ),
              ),
          if (day.circuitNote != null)
            FadeScaleEntry(
              index: day.exercises.length + 2,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Card(
                  color: t.primary.withOpacity(0.04),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      day.circuitNote!,
                      style: TextStyle(
                        fontSize: 11,
                        color: t.text3,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _restTimerPanel(WorkoutTheme t) {
    final finished = _restRemaining == 0;
    final progress = _restTotal == 0 ? 0.0 : _restRemaining / _restTotal;
    final minutes = _restRemaining ~/ 60;
    final seconds = (_restRemaining % 60).toString().padLeft(2, '0');
    return Container(
      key: const Key('rest-timer-panel'),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            t.primary.withOpacity(t.isDark ? 0.16 : 0.10),
            t.accent.withOpacity(t.isDark ? 0.09 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.primary.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: t.primary.withOpacity(t.isDark ? 0.13 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: progress),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, __) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 4,
                    backgroundColor: t.border.withOpacity(0.72),
                    valueColor: AlwaysStoppedAnimation(
                      finished ? t.success : t.primary,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: finished
                      ? Icon(
                          Icons.check_rounded,
                          key: const ValueKey('rest-complete'),
                          color: t.success,
                          size: 25,
                        )
                      : Text(
                          '$minutes:$seconds',
                          key: ValueKey(_restRemaining),
                          style: TextStyle(
                            color: t.text1,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  finished ? '休息完成，可以继续' : '组间休息',
                  style: TextStyle(
                    color: finished ? t.success : t.text1,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _restExercise,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: t.text3, fontSize: 10.5),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('rest-timer-add'),
            tooltip: '增加 30 秒',
            onPressed: _addRestTime,
            icon: Icon(Icons.add_alarm_rounded, color: t.primary, size: 20),
          ),
          IconButton(
            key: const Key('rest-timer-dismiss'),
            tooltip: '结束计时',
            onPressed: _dismissRestTimer,
            icon: Icon(Icons.close_rounded, color: t.text3, size: 19),
          ),
        ],
      ),
    );
  }

  Widget _workoutCompletePanel(WorkoutDay day, WorkoutTheme t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            t.success.withOpacity(t.isDark ? 0.14 : 0.09),
            t.primary.withOpacity(t.isDark ? 0.08 : 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.success.withOpacity(0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.success.withOpacity(0.13),
            ),
            child: Icon(Icons.emoji_events_rounded, color: t.success, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${day.dayName}训练已完成',
                  style: TextStyle(
                    color: t.text1,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '漂亮收尾，记得补水、拉伸并保证恢复。',
                  style: TextStyle(color: t.text3, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayHdr(WorkoutDay d, WorkoutTheme t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${d.dayName} ${d.subtitle}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: t.text1,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: t.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    d.badge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: t.primary,
                    ),
                  ),
                ),
              ],
            ),
            if (d.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                d.description,
                style: TextStyle(fontSize: 12, color: t.text3),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _restTip(IconData ic, String txt, Color c, WorkoutTheme t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.12), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(ic, size: 18, color: c),
          const SizedBox(width: 10),
          Text(
            txt,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: t.text2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _exCard(
    Exercise ex,
    int num,
    int completedSets,
    WorkoutTheme t,
    VoidCallback tap,
    VoidCallback? startTimer,
  ) {
    final done = completedSets >= ex.sets;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: CompletionPulse(
        active: done,
        child: PressScale(
          onTap: tap,
          child: Card(
            key: ValueKey('exercise_card_${_day}_${num - 1}'),
            color: done
                ? t.success.withOpacity(t.isDark ? 0.045 : 0.035)
                : (ex.isStar ? t.primary.withOpacity(0.025) : null),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: done
                  ? BorderSide(color: t.success.withOpacity(0.22), width: 1)
                  : (ex.isStar
                      ? BorderSide(
                          color: t.primary.withOpacity(0.26),
                          width: 1.2,
                        )
                      : BorderSide(
                          color: t.border.withOpacity(0.9),
                          width: 0.8,
                        )),
            ),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: done ? 11 : 14,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? t.success : t.card,
                      border: Border.all(
                        color: done ? t.success : t.border,
                        width: 1.4,
                      ),
                      boxShadow: done
                          ? [
                              BoxShadow(
                                color: t.success.withOpacity(0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (c, a) => FadeTransition(
                        opacity: a,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                            CurvedAnimation(
                              parent: a,
                              curve: Curves.easeOutBack,
                            ),
                          ),
                          child: c,
                        ),
                      ),
                      child: done
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                              key: ValueKey('d'),
                            )
                          : Center(
                              child: Text(
                                '$num',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: t.text4,
                                ),
                                key: ValueKey('n$num'),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ex.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: done ? t.text4 : t.text1,
                            decoration:
                                done ? TextDecoration.lineThrough : null,
                            decorationColor: t.text4,
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: done
                              ? const SizedBox.shrink()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 3),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 2,
                                      children: [
                                        ...ex.muscles.map(
                                          (m) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: t.primary.withOpacity(
                                                0.06,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              m,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                                color: t.text3,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (ex.muscleTarget.isNotEmpty)
                                          Text(
                                            ex.muscleTarget,
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: t.text3,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (ex.note != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          ex.note!,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: t.text3,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                        if (!done && completedSets > 0) ...[
                          const SizedBox(height: 7),
                          Text(
                            '已完成 $completedSets/${ex.sets} 组 · 点击完成下一组',
                            key: ValueKey(
                              'exercise_set_progress_${_day}_${num - 1}',
                            ),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: t.success,
                            ),
                          ),
                        ] else if (done) ...[
                          const SizedBox(height: 7),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 13,
                                color: t.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '已完成 · 再点一次重置',
                                key: ValueKey(
                                  'exercise_reset_hint_${_day}_${num - 1}',
                                ),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: t.success,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${ex.sets}',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: done ? t.text4 : t.primary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            TextSpan(
                              text: ' ×',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: done ? t.text4 : t.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        ex.reps,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: done ? t.text4 : t.text2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (startTimer == null)
                        Text(
                          ex.rest,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: done ? t.text4.withOpacity(0.72) : t.text4,
                          ),
                        )
                      else
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: startTimer,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2, bottom: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 10,
                                  color: done
                                      ? t.text4.withOpacity(0.72)
                                      : t.primary,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  ex.rest,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: done
                                        ? t.text4.withOpacity(0.72)
                                        : t.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RECORD PAGE — v6.5: 训练记录（月度日历热力图 + 年度统计）
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
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final generation = ++_loadGeneration;
    final year = _viewYear;
    final month = _viewMonth;
    final p = await SharedPreferences.getInstance();
    final summary = await loadRecordSummary(p, year, month);
    if (mounted && generation == _loadGeneration) {
      setState(() {
        _monthData = summary.monthData;
        _yearTotal = summary.yearTotal;
        _yearTrainDays = summary.yearTrainDays;
        _loading = false;
      });
    }
  }

  void _prevMonth() {
    setState(() {
      _loading = true;
      if (_viewMonth == 1) {
        _viewMonth = 12;
        _viewYear--;
      } else {
        _viewMonth--;
      }
    });
    _loadData();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_viewYear == now.year && _viewMonth == now.month) return;
    setState(() {
      _loading = true;
      if (_viewMonth == 12) {
        _viewMonth = 1;
        _viewYear++;
      } else {
        _viewMonth++;
      }
    });
    _loadData();
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _viewYear = now.year;
      _viewMonth = now.month;
      _loading = true;
    });
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
    final daysInMonth = DateTime(_viewYear, _viewMonth + 1, 0).day;
    final firstWeekday = DateTime(_viewYear, _viewMonth, 1).weekday - 1;
    final now = DateTime.now();
    final isCurrentMonth = _viewYear == now.year && _viewMonth == now.month;
    final monthNames = [
      '1月',
      '2月',
      '3月',
      '4月',
      '5月',
      '6月',
      '7月',
      '8月',
      '9月',
      '10月',
      '11月',
      '12月',
    ];
    final weekLabels = ['一', '二', '三', '四', '五', '六', '日'];

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: GradientTitle(
              text: '训练记录',
              primary: t.primary,
              accent: t.primaryLight,
              fontSize: 22,
            ),
          ),
        ),
        // 月份选择器
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PressScale(
                  onTap: _prevMonth,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: t.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.chevron_left, size: 20, color: t.primary),
                  ),
                ),
                PressScale(
                  onTap: _goToday,
                  child: Column(
                    children: [
                      Text(
                        '$_viewYear年 ${monthNames[_viewMonth - 1]}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: t.text1,
                        ),
                      ),
                      if (isCurrentMonth)
                        Text(
                          '当前月',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: t.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                PressScale(
                  onTap: _nextMonth,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isCurrentMonth
                          ? t.border.withOpacity(0.5)
                          : t.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: isCurrentMonth ? t.text4 : t.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // 月度统计
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: FadeScaleEntry(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statBlock('完成动作', '${_totalExercises()}', '个', t),
                      Container(width: 1, height: 36, color: t.border),
                      _statBlock('训练天数', '${_trainDays()}', '天', t),
                      Container(width: 1, height: 36, color: t.border),
                      _statBlock('年度累计', '$_yearTotal', '个', t),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // 日历热力图
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: FadeScaleEntry(
              index: 1,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          for (int i = 0; i < 7; i++)
                            Expanded(
                              child: Center(
                                child: Text(
                                  weekLabels[i],
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: i >= 5 ? t.text4 : t.text3,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ..._buildCalendarRows(
                        daysInMonth,
                        firstWeekday,
                        now,
                        isCurrentMonth,
                        t,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '少',
                            style: TextStyle(fontSize: 9, color: t.text4),
                          ),
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
                          Text(
                            '多',
                            style: TextStyle(fontSize: 9, color: t.text4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // 年度统计
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: FadeScaleEntry(
              index: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_viewYear 年度统计',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: t.text1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statBlock('年度完成', '$_yearTotal', '个动作', t),
                          _statBlock('训练天数', '$_yearTrainDays', '天', t),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 12个月迷你月历
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '全年概览',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: t.text1,
                  ),
                ),
                const SizedBox(height: 8),
                _buildYearGrid(t),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _statBlock(String label, String value, String unit, WorkoutTheme t) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: t.text4,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: t.primary,
          ),
        ),
        Text(unit, style: TextStyle(fontSize: 9, color: t.text4)),
      ],
    );
  }

  List<Widget> _buildCalendarRows(
    int daysInMonth,
    int firstWeekday,
    DateTime now,
    bool isCurrentMonth,
    WorkoutTheme t,
  ) {
    final rows = <Widget>[];
    int day = 1;
    for (int row = 0; row < 6; row++) {
      if (day > daysInMonth) break;
      final cells = <Widget>[];
      for (int col = 0; col < 7; col++) {
        if (row == 0 && col < firstWeekday) {
          cells.add(const Expanded(child: SizedBox(height: 32)));
        } else if (day > daysInMonth) {
          cells.add(const Expanded(child: SizedBox(height: 32)));
        } else {
          final isToday = isCurrentMonth && day == now.day;
          final count = _monthData[day] ?? 0;
          final intensity = count > 0 ? (count / 8).clamp(0.0, 1.0) : 0.0;
          cells.add(
            Expanded(
              child: SizedBox(
                height: 32,
                child: Center(
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: count == 0
                          ? Colors.transparent
                          : Color.lerp(t.card, t.successLight, intensity),
                      border: isToday
                          ? Border.all(color: t.primary, width: 2)
                          : null,
                      boxShadow: isToday
                          ? [
                              BoxShadow(
                                color: t.primary.withOpacity(0.2),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isToday ? FontWeight.w800 : FontWeight.w600,
                          color: count == 0
                              ? (isToday ? t.primary : t.text4)
                              : (intensity > 0.62 ? Colors.white : t.text1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          day++;
        }
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(children: cells),
        ),
      );
    }
    return rows;
  }

  Widget _legendDot(WorkoutTheme t, double intensity) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: intensity == 0
            ? t.border
            : Color.lerp(t.card, t.successLight, intensity),
      ),
    );
  }

  Widget _buildYearGrid(WorkoutTheme t) {
    final now = DateTime.now();
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox(height: 100);
        final p = snap.data!;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int m = 1; m <= 12; m++)
              _buildMiniMonth(
                p,
                _viewYear,
                m,
                '$m',
                t,
                _viewYear == now.year && m == now.month,
              ),
          ],
        );
      },
    );
  }

  Widget _buildMiniMonth(
    SharedPreferences p,
    int year,
    int month,
    String label,
    WorkoutTheme t,
    bool isCurrent,
  ) {
    final data = p.getString(historyKey(year, month));
    Map<String, dynamic> history = {};
    if (data != null) {
      try {
        history = jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {}
    }
    final daysInMonth = DateTime(year, month + 1, 0).day;
    history.removeWhere((k, v) {
      final day = int.tryParse(k);
      final count = v is int ? v : int.tryParse('$v');
      return day == null ||
          day < 1 ||
          day > daysInMonth ||
          count == null ||
          count <= 0;
    });
    final total = history.values.fold<int>(
      0,
      (s, v) => s + (v is int ? v : int.tryParse('$v') ?? 0),
    );
    return Container(
      width: (MediaQuery.of(context).size.width - 32 - 24) / 4,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrent ? t.primary : t.border,
          width: isCurrent ? 1.5 : 0.5,
        ),
        color: isCurrent ? t.primary.withOpacity(0.04) : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$label月',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isCurrent ? t.primary : t.text3,
                ),
              ),
              if (total > 0)
                Text(
                  '$total',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: t.success,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          ..._buildMiniGrid(year, month, history, t),
        ],
      ),
    );
  }

  List<Widget> _buildMiniGrid(
    int year,
    int month,
    Map<String, dynamic> history,
    WorkoutTheme t,
  ) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday - 1;
    final rows = <Widget>[];
    int day = 1;
    for (int row = 0; row < 6; row++) {
      if (day > daysInMonth) break;
      final cells = <Widget>[];
      for (int col = 0; col < 7; col++) {
        if (row == 0 && col < firstWeekday || day > daysInMonth) {
          cells.add(SizedBox(width: 4, height: 4));
        } else {
          final rawCount = history[day.toString()];
          final count =
              rawCount is int ? rawCount : int.tryParse('$rawCount') ?? 0;
          final intensity = count > 0 ? (count / 8).clamp(0.0, 1.0) : 0.0;
          cells.add(
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: count == 0
                    ? t.border.withOpacity(0.3)
                    : Color.lerp(t.card, t.successLight, intensity),
              ),
            ),
          );
          day++;
        }
      }
      rows.add(
        Row(mainAxisAlignment: MainAxisAlignment.center, children: cells),
      );
    }
    return rows;
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
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: GradientTitle(
              text: '饮食营养',
              primary: t.primary,
              accent: t.primaryLight,
              fontSize: 22,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              FadeScaleEntry(
                index: 0,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final itemWidth = (box.maxWidth - 8) / 2;
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _macroStat(
                              '每日热量',
                              '2200',
                              'kcal',
                              Icons.local_fire_department_rounded,
                              t.primary,
                              t,
                              itemWidth,
                            ),
                            _macroStat(
                              '蛋白质',
                              '130-160',
                              'g',
                              Icons.fitness_center_rounded,
                              t.success,
                              t,
                              itemWidth,
                            ),
                            _macroStat(
                              '碳水',
                              '200-270',
                              'g',
                              Icons.grain_rounded,
                              t.warning,
                              t,
                              itemWidth,
                            ),
                            _macroStat(
                              '脂肪',
                              '58-73',
                              'g',
                              Icons.water_drop_rounded,
                              t.accent,
                              t,
                              itemWidth,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeScaleEntry(
                index: 1,
                child: _mc(
                  '蛋白质',
                  '130-160g',
                  '1.8-2.2g/kg · 25%',
                  '鸡胸 · 牛肉 · 鸡蛋 · 鱼虾 · 豆腐 · 蛋白粉',
                  t.primary,
                  t,
                ),
              ),
              const SizedBox(height: 8),
              FadeScaleEntry(
                index: 2,
                child: _mc(
                  '碳水',
                  '200-270g',
                  '2-3g/kg · 40%',
                  '糙米 · 红薯 · 燕麦 · 全麦 · 玉米 · 水果',
                  t.warning,
                  t,
                ),
              ),
              const SizedBox(height: 8),
              FadeScaleEntry(
                index: 3,
                child: _mc(
                  '脂肪',
                  '58-73g',
                  '0.8-1g/kg · 30%',
                  '橄榄油 · 坚果 · 牛油果 · 深海鱼 · 蛋黄',
                  t.success,
                  t,
                ),
              ),
              const SizedBox(height: 24),
              FadeScaleEntry(
                index: 4,
                child: Text(
                  '饮食建议',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: t.text1,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ...nutritionTips.asMap().entries.map(
                    (e) => FadeScaleEntry(
                      index: e.key + 5,
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 3,
                                height: 14,
                                margin:
                                    const EdgeInsets.only(right: 10, top: 2),
                                decoration: BoxDecoration(
                                  color: t.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  nutritionTips[e.key],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: t.text2,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _macroStat(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
    WorkoutTheme t,
    double width,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(t.isDark ? 0.10 : 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.14), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: t.text3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: t.text4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mc(String l, String v, String p, String f, Color c, WorkoutTheme t) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 3,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: t.text4,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Text(p, style: TextStyle(fontSize: 10, color: t.text3)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                v,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: c,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                f,
                style: TextStyle(fontSize: 11, color: t.text3, height: 1.5),
              ),
            ],
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROGRESSION PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class ProgressionPage extends StatelessWidget {
  const ProgressionPage({super.key});
  @override
  Widget build(BuildContext context) {
    final t = ThemeInherited.of(context).theme;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: GradientTitle(
              text: '渐进超负荷',
              primary: t.primary,
              accent: t.primaryLight,
              fontSize: 22,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              FadeScaleEntry(
                index: 0,
                child: Card(
                  color: t.primary.withOpacity(0.04),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '渐进超负荷是增肌的核心原则：在动作稳定、恢复充足的前提下，逐步增加重量、次数或组数，让身体持续适应。每 1-2 周尝试一次小幅进步，并记录训练表现。',
                      style: TextStyle(
                        fontSize: 12,
                        color: t.text2,
                        height: 1.7,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeScaleEntry(
                index: 1,
                child: Text(
                  '四阶段计划',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: t.text1,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ...progressionPhases.asMap().entries.map((e) {
                final (w, ti, d) = progressionPhases[e.key];
                return FadeScaleEntry(
                  index: e.key + 2,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: t.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${e.key + 1}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: t.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        ti,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: t.text1,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: t.primary.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          w,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: t.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    d,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: t.text3,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              FadeScaleEntry(
                index: 7,
                child: Text(
                  '加重策略',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: t.text1,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ...[
                ('上肢复合动作', '卧推 / 划船 / 推肩：每次 +1.25-2.5kg'),
                ('下肢复合动作', '倒蹬 / 硬拉 / 臀推：每次 +2.5-5kg'),
                ('孤立动作', '侧平举 / 弯举 / 下压：每次 +0.5-1kg 或 +1-2次'),
                ('遇到瓶颈', '减重 10% 重新开始，或更换动作变式刺激新角度'),
              ].asMap().entries.map(
                    (i) => FadeScaleEntry(
                      index: i.key + 8,
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          dense: true,
                          title: Text(
                            i.value.$1,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: t.text1,
                            ),
                          ),
                          subtitle: Text(
                            i.value.$2,
                            style: TextStyle(
                              fontSize: 11,
                              color: t.text3,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// THEME PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class ThemePage extends StatelessWidget {
  const ThemePage({super.key});
  @override
  Widget build(BuildContext context) {
    final inh = ThemeInherited.of(context);
    final t = inh.theme;
    final cur = inh.current;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: GradientTitle(
              text: '主题选择',
              primary: t.primary,
              accent: t.primaryLight,
              fontSize: 22,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((ctx, i) {
              final m = AppTheme.values[i];
              final mt = themes[m]!;
              final sel = m == cur;
              return FadeScaleEntry(
                index: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PressScale(
                    onTap: () => inh.setTheme(m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: sel ? mt.primary.withOpacity(0.06) : null,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: sel ? mt.primary : t.border,
                          width: sel ? 2 : 1,
                        ),
                        boxShadow: sel && mt.isDark
                            ? [
                                BoxShadow(
                                  color: mt.primary.withOpacity(0.2),
                                  blurRadius: 16,
                                ),
                                BoxShadow(
                                  color: mt.accent.withOpacity(0.1),
                                  blurRadius: 24,
                                ),
                              ]
                            : sel
                                ? [
                                    BoxShadow(
                                      color: mt.primary.withOpacity(0.3),
                                      blurRadius: 10,
                                    ),
                                  ]
                                : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [mt.primary, mt.accent],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: sel && mt.isDark
                                    ? [
                                        BoxShadow(
                                          color: mt.primary.withOpacity(0.5),
                                          blurRadius: 12,
                                        ),
                                        BoxShadow(
                                          color: mt.accent.withOpacity(0.3),
                                          blurRadius: 16,
                                        ),
                                      ]
                                    : sel
                                        ? [
                                            BoxShadow(
                                              color:
                                                  mt.primary.withOpacity(0.3),
                                              blurRadius: 10,
                                            ),
                                          ]
                                        : null,
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: sel
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 22,
                                        key: ValueKey('s'),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mt.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: sel ? mt.primary : t.text1,
                                    ),
                                  ),
                                  Text(
                                    sel ? '当前使用中' : '点击切换',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: sel
                                          ? mt.primary.withOpacity(0.7)
                                          : t.text4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutBack,
                              padding: sel
                                  ? const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    )
                                  : EdgeInsets.zero,
                              decoration: sel
                                  ? BoxDecoration(
                                      color: mt.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    )
                                  : null,
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 250),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: sel ? mt.primary : Colors.transparent,
                                ),
                                child: const Text('已选择'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }, childCount: AppTheme.values.length),
          ),
        ),
      ],
    );
  }
}

class WorkoutPlanEditorPage extends StatefulWidget {
  const WorkoutPlanEditorPage({super.key});

  @override
  State<WorkoutPlanEditorPage> createState() => _WorkoutPlanEditorPageState();
}

class _WorkoutPlanEditorPageState extends State<WorkoutPlanEditorPage> {
  List<WorkoutDay>? _plan;

  @override
  void initState() {
    super.initState();
    loadWorkoutPlan(workoutDays).then((plan) {
      if (mounted) setState(() => _plan = plan);
    });
  }

  Future<void> _editExercise(int dayIndex, int exerciseIndex) async {
    final current = _plan![dayIndex].exercises[exerciseIndex];
    final name = TextEditingController(text: current.name);
    final sets = TextEditingController(text: '${current.sets}');
    final reps = TextEditingController(text: current.reps);
    final rest = TextEditingController(text: current.rest);
    final note = TextEditingController(text: current.note ?? '');
    final result = await showDialog<Exercise>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('修改 ${current.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: '动作名称'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: sets,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '组数'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: reps,
                      decoration: const InputDecoration(labelText: '次数'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: rest,
                decoration: const InputDecoration(labelText: '休息时间'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: note,
                maxLines: 3,
                decoration: const InputDecoration(labelText: '动作说明'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final count = int.tryParse(sets.text);
              if (name.text.trim().isEmpty || count == null || count < 1) {
                return;
              }
              Navigator.pop(
                ctx,
                current.copyWith(
                  name: name.text.trim(),
                  sets: count,
                  reps: reps.text.trim(),
                  rest: rest.text.trim(),
                  note: note.text.trim(),
                ),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final nextExercises = List<Exercise>.from(_plan![dayIndex].exercises);
    nextExercises[exerciseIndex] = result;
    final next = List<WorkoutDay>.from(_plan!);
    next[dayIndex] = next[dayIndex].copyWith(exercises: nextExercises);
    await saveWorkoutPlan(next);
    workoutPlanRevision.value++;
    if (mounted) setState(() => _plan = next);
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('恢复默认训练计划？'),
        content: const Text('将恢复当前内置的周一至周日健身安排。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('恢复默认'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await resetWorkoutPlan();
    workoutPlanRevision.value++;
    if (mounted) setState(() => _plan = List<WorkoutDay>.from(workoutDays));
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeInherited.of(context).theme;
    final plan = _plan;
    return Scaffold(
      appBar: AppBar(
        title: const Text('训练计划'),
        actions: [TextButton(onPressed: _reset, child: const Text('恢复默认'))],
      ),
      body: plan == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              itemCount: plan.length,
              itemBuilder: (context, dayIndex) {
                final day = plan[dayIndex];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    initiallyExpanded: dayIndex == DateTime.now().weekday - 1,
                    title: Text(
                      '${day.dayName} · ${day.subtitle}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: t.text1,
                      ),
                    ),
                    subtitle: Text(
                      day.isRest ? '休息日' : '${day.exercises.length} 个动作',
                      style: TextStyle(color: t.text3),
                    ),
                    children: [
                      if (day.exercises.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            day.recoveryOptions == null ? '无训练动作' : '恢复日项目保持默认',
                            style: TextStyle(color: t.text3),
                          ),
                        )
                      else
                        for (var i = 0; i < day.exercises.length; i++)
                          ListTile(
                            key: ValueKey('plan_${dayIndex}_$i'),
                            leading: CircleAvatar(
                              radius: 15,
                              backgroundColor: t.primary.withOpacity(0.1),
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: t.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            title: Text(day.exercises[i].name),
                            subtitle: Text(
                              '${day.exercises[i].sets}组 × ${day.exercises[i].reps} · 休息 ${day.exercises[i].rest}',
                            ),
                            trailing: const Icon(Icons.edit_rounded, size: 19),
                            onTap: () => _editExercise(dayIndex, i),
                          ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TREND CHART WIDGET — lightweight CustomPainter line chart
// ═══════════════════════════════════════════════════════════════════════════════

class TrendChartPainter extends CustomPainter {
  final List<(String, double)> data; // (label, value)
  final WorkoutTheme theme;
  TrendChartPainter({required this.data, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final padding = const EdgeInsets.only(
      left: 50,
      right: 16,
      top: 16,
      bottom: 40,
    );
    final chartW = size.width - padding.left - padding.right;
    final chartH = size.height - padding.top - padding.bottom;
    final values = data.map((d) => d.$2).toList();
    double minV = values.reduce(math.min);
    double maxV = values.reduce(math.max);
    if (maxV == minV) {
      maxV += 1;
      minV -= 1;
    }
    final range = maxV - minV;
    final paint = Paint()
      ..color = theme.primary.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = theme.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()
      ..color = theme.primary
      ..style = PaintingStyle.fill;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = padding.left +
          (data.length == 1 ? chartW / 2 : (i / (data.length - 1)) * chartW);
      final y = padding.top + chartH - ((data[i].$2 - minV) / range) * chartH;
      points.add(Offset(x, y));
    }
    if (points.length >= 2) {
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      fillPath.addPath(path, Offset.zero);
      fillPath.lineTo(points.last.dx, padding.top + chartH);
      fillPath.lineTo(points.first.dx, padding.top + chartH);
      fillPath.close();
    }
    canvas.drawPath(fillPath, paint);
    canvas.drawPath(path, linePaint);
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 4, dotPaint);
      canvas.drawCircle(
        points[i],
        2.5,
        Paint()
          ..color = theme.bg
          ..style = PaintingStyle.fill,
      );
      textPainter.text = TextSpan(
        text: data[i].$2.toStringAsFixed(1),
        style: TextStyle(
          fontSize: 9,
          color: theme.text3,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, points[i].dy - 20),
      );
      textPainter.text = TextSpan(
        text: data[i].$1,
        style: TextStyle(fontSize: 8, color: theme.text4),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, padding.top + chartH + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant TrendChartPainter oldDelegate) =>
      data != oldDelegate.data || theme != oldDelegate.theme;
}

class MiniTrendChart extends StatelessWidget {
  final List<(String, double)> data;
  final WorkoutTheme theme;
  const MiniTrendChart({super.key, required this.data, required this.theme});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: CustomPaint(
        painter: TrendChartPainter(data: data, theme: theme),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SETTINGS PAGE — v6.6: profile, weight log, trends, import/export
// ═══════════════════════════════════════════════════════════════════════════════

class SettingsPage extends StatefulWidget {
  final VoidCallback onProfileChanged;
  const SettingsPage({super.key, required this.onProfileChanged});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  UserProfile? _profile;
  List<WeightEntry> _weightHistory = [];
  List<BodyMeasurement> _measurements = [];
  String _trendTab = 'weight'; // weight or measurements
  bool _autoRestTimer = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final profile = await loadProfile();
    final weights = await loadWeightHistory();
    final measurements = await loadMeasurements();
    final autoRestTimer = await loadAutoRestTimer();
    if (mounted)
      setState(() {
        _profile = profile;
        _weightHistory = weights;
        _measurements = measurements;
        _autoRestTimer = autoRestTimer;
      });
  }

  Future<void> _saveProfile(UserProfile p) async {
    await saveProfile(p);
    if (mounted) setState(() => _profile = p);
    widget.onProfileChanged();
  }

  Widget _trainingPreferencesCard(WorkoutTheme t) {
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        secondary: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: t.accent.withOpacity(0.09),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(Icons.timer_rounded, color: t.accent, size: 21),
        ),
        title: Text(
          '完成动作后自动计时',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: t.text1,
          ),
        ),
        subtitle: Text(
          '按训练计划中的休息时间启动，可随时加 30 秒或结束',
          style: TextStyle(fontSize: 11, color: t.text3),
        ),
        value: _autoRestTimer,
        activeThumbColor: t.primary,
        onChanged: (value) async {
          setState(() => _autoRestTimer = value);
          await saveAutoRestTimer(value);
        },
      ),
    );
  }

  Widget _workoutPlanCard(WorkoutTheme t) {
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: PressScale(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const WorkoutPlanEditorPage(),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: t.primary.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: t.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '训练计划',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: t.text1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '修改动作、组数、次数和休息时间',
                      style: TextStyle(fontSize: 11, color: t.text3),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: t.text4),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeInherited.of(context).theme;
    final p = _profile;
    if (p == null) return const Center(child: CircularProgressIndicator());
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: GradientTitle(
              text: '设置',
              primary: t.primary,
              accent: t.primaryLight,
              fontSize: 22,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── 个人资料卡片 ──
              FadeScaleEntry(index: 0, child: _profileCard(p, t)),
              const SizedBox(height: 12),
              // ── 身体数据趋势 ──
              FadeScaleEntry(index: 1, child: _bodyTrendCard(t)),
              const SizedBox(height: 12),
              // ── 训练计划 ──
              FadeScaleEntry(index: 2, child: _workoutPlanCard(t)),
              const SizedBox(height: 12),
              // ── 训练偏好 ──
              FadeScaleEntry(index: 3, child: _trainingPreferencesCard(t)),
              const SizedBox(height: 12),
              // ── 数据管理 ──
              FadeScaleEntry(index: 4, child: _dataCard(t)),
              const SizedBox(height: 12),
              // ── 主题设置 ──
              FadeScaleEntry(index: 5, child: _themeCard(t)),
              const SizedBox(height: 12),
              // ── 关于 ──
              FadeScaleEntry(
                index: 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: t.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '关于',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: t.text3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Body Recomp v$appVersion',
                          style: TextStyle(
                            fontSize: 13,
                            color: t.text2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '健身追踪 · 趋势分析 · 数据备份',
                          style: TextStyle(fontSize: 11, color: t.text4),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'GitHub: YXX168/BodyRecomp',
                          style: TextStyle(fontSize: 10, color: t.text4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _themeCard(WorkoutTheme t) {
    final inh = ThemeInherited.of(context);
    final cur = inh.current;
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.palette_rounded, color: t.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '主题选择',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.text1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppTheme.values.map((m) {
                final mt = themes[m]!;
                final sel = m == cur;
                return PressScale(
                  onTap: () => inh.setTheme(m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [mt.primary, mt.accent]),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel ? t.text1 : Colors.white.withOpacity(0.75),
                        width: sel ? 2.4 : 1.0,
                      ),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                color: mt.primary.withOpacity(
                                  t.isDark ? 0.42 : 0.24,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : null,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: sel
                          ? const Icon(
                              Icons.check_rounded,
                              key: ValueKey('selected'),
                              color: Colors.white,
                              size: 22,
                            )
                          : const SizedBox.shrink(key: ValueKey('empty')),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Text(
              themes[cur]!.name,
              style: TextStyle(
                fontSize: 12,
                color: t.text3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileCard(UserProfile p, WorkoutTheme t) {
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline_rounded, color: t.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '个人资料',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.text1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 生日
            _profileTile(
              t,
              Icons.cake_rounded,
              '生日',
              p.birthday.isEmpty ? '未设置' : p.birthday,
              () => _editBirthday(p),
            ),
            const Divider(height: 1),
            // 性别
            _profileTile(
              t,
              Icons.wc_rounded,
              '性别',
              p.gender == 'male' ? '👨 男' : '👩 女',
              () => _editGender(p),
            ),
            const Divider(height: 1),
            // 身高
            _profileTile(
              t,
              Icons.height_rounded,
              '身高',
              '${p.heightCm.toInt()} cm',
              () => _editHeight(p),
            ),
            const Divider(height: 1),
            // 体重
            _profileTile(
              t,
              Icons.monitor_weight_rounded,
              '当前体重',
              '${p.weightKg} kg',
              () => _editWeight(p),
            ),
            const SizedBox(height: 12),
            // BMI 展示
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    t.primary.withOpacity(0.08),
                    t.accent.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BMI',
                          style: TextStyle(fontSize: 11, color: t.text3),
                        ),
                        Text(
                          _bmiDisplay(p),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: t.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '状态',
                          style: TextStyle(fontSize: 11, color: t.text3),
                        ),
                        Text(
                          _bmiCategory(
                            double.tryParse(_bmiDisplay(p).split(' ')[0]),
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: t.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '年龄',
                          style: TextStyle(fontSize: 11, color: t.text3),
                        ),
                        Text(
                          p.age > 0 ? '${p.age} 岁' : '--',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: t.text1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _bmiDisplay(UserProfile p) {
    final v = p.bmi;
    if (v == 0) return '--';
    return '${v.toStringAsFixed(1)}';
  }

  String _bmiCategory(double? bmi) {
    if (bmi == null) return '未计算';
    if (bmi < 18.5) return '偏瘦';
    if (bmi < 24) return '正常';
    if (bmi < 28) return '偏胖';
    return '肥胖';
  }

  Widget _profileTile(
    WorkoutTheme t,
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return PressScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: t.text3),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontSize: 13, color: t.text2)),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: t.text1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 16, color: t.text4),
          ],
        ),
      ),
    );
  }

  Future<void> _editBirthday(UserProfile p) async {
    final ctrl = TextEditingController(text: p.birthday);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择生日'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.datetime,
          decoration: const InputDecoration(
            hintText: 'YYYY-MM-DD',
            labelText: '生日日期',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      try {
        DateTime.parse(result);
        _saveProfile(
          UserProfile(
            birthday: result,
            heightCm: p.heightCm,
            weightKg: p.weightKg,
            gender: p.gender,
          ),
        );
      } catch (_) {}
    }
  }

  Future<void> _editGender(UserProfile p) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择性别'),
        children: ['👨 男', '👩 女']
            .map(
              (g) => SimpleDialogOption(
                child: Text(g),
                onPressed: () =>
                    Navigator.pop(ctx, g == '👨 男' ? 'male' : 'female'),
              ),
            )
            .toList(),
      ),
    );
    if (result != null)
      _saveProfile(
        UserProfile(
          birthday: p.birthday,
          heightCm: p.heightCm,
          weightKg: p.weightKg,
          gender: result,
        ),
      );
  }

  Future<void> _editHeight(UserProfile p) async {
    final ctrl = TextEditingController(text: p.heightCm.toInt().toString());
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('设置身高 (cm)'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null) Navigator.pop(ctx, v);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (result != null)
      _saveProfile(
        UserProfile(
          birthday: p.birthday,
          heightCm: result,
          weightKg: p.weightKg,
          gender: p.gender,
        ),
      );
  }

  Future<void> _editWeight(UserProfile p) async {
    final ctrl = TextEditingController(text: p.weightKg.toString());
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('记录体重 (kg)'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null) Navigator.pop(ctx, v);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (result != null) {
      await _saveProfile(
        UserProfile(
          birthday: p.birthday,
          heightCm: p.heightCm,
          weightKg: result,
          gender: p.gender,
        ),
      );
      final entries = await saveWeightEntry(
        WeightEntry(date: DateTime.now(), weightKg: result),
      );
      if (mounted) setState(() => _weightHistory = entries);
    }
  }

  Widget _bodyTrendCard(WorkoutTheme t) {
    final isWeight = _trendTab == 'weight';
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart_rounded, color: t.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '身体数据',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.text1,
                  ),
                ),
                const Spacer(),
                PressScale(
                  onTap: isWeight ? _addWeightEntry : _addMeasurement,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: t.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add, size: 14, color: t.primary),
                        Text(
                          '记录',
                          style: TextStyle(
                            fontSize: 11,
                            color: t.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: t.border.withOpacity(0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _trendTabButton('weight', '体重', t),
                  _trendTabButton('measurements', '围度', t),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (isWeight)
              _weightTrendContent(t)
            else
              _measurementTrendContent(t),
          ],
        ),
      ),
    );
  }

  Widget _trendTabButton(String value, String label, WorkoutTheme t) {
    final selected = _trendTab == value;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _trendTab = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected ? t.card : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? t.primary : t.text4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _weightTrendContent(WorkoutTheme t) {
    final weights = _weightHistory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (weights.length < 2)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Center(
              child: Text(
                '至少记录 2 次体重后显示趋势图',
                style: TextStyle(fontSize: 12, color: t.text4),
              ),
            ),
          )
        else
          MiniTrendChart(
            data: weights.length > 30
                ? weights
                    .sublist(weights.length - 30)
                    .map((e) => ('${e.date.month}/${e.date.day}', e.weightKg))
                    .toList()
                : weights
                    .map((e) => ('${e.date.month}/${e.date.day}', e.weightKg))
                    .toList(),
            theme: t,
          ),
        if (weights.isNotEmpty) ...[
          Row(
            children: [
              Text(
                '最新: ${weights.last.weightKg.toStringAsFixed(1)}kg',
                style: TextStyle(fontSize: 11, color: t.text3),
              ),
              if (weights.length >= 2)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    '变化: ${weights.last.weightKg > weights[weights.length - 2].weightKg ? "+" : ""}${(weights.last.weightKg - weights[weights.length - 2].weightKg).toStringAsFixed(1)}kg',
                    style: TextStyle(
                      fontSize: 11,
                      color: weights.last.weightKg >
                              weights[weights.length - 2].weightKg
                          ? t.warning
                          : t.success,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ...weights.reversed.take(8).map((entry) => _weightEntryRow(entry, t)),
        ],
      ],
    );
  }

  Widget _weightEntryRow(WeightEntry entry, WorkoutTheme t) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 11, color: t.text3),
            ),
          ),
          Text(
            '${entry.weightKg.toStringAsFixed(1)} kg',
            style: TextStyle(
              fontSize: 11,
              color: t.text1,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: '编辑',
            onPressed: () => _editWeightEntry(entry),
            icon: Icon(Icons.edit_outlined, size: 16, color: t.primary),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: '删除',
            onPressed: () => _deleteWeightEntry(entry),
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 16,
              color: t.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _measurementTrendContent(WorkoutTheme t) {
    const labels = {
      'waist': '腰围',
      'chest': '胸围',
      'hip': '臀围',
      'arm': '臂围',
      'thigh': '大腿围',
    };
    final entries = _measurements;
    final waistData = entries
        .where((entry) => entry.values['waist'] != null)
        .map(
          (entry) =>
              ('${entry.date.month}/${entry.date.day}', entry.values['waist']!),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (waistData.length < 2)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Center(
              child: Text(
                '记录至少 2 次腰围后显示围度趋势',
                style: TextStyle(fontSize: 12, color: t.text4),
              ),
            ),
          )
        else
          MiniTrendChart(
            data: waistData.length > 30
                ? waistData.sublist(waistData.length - 30)
                : waistData,
            theme: t,
          ),
        ...entries.reversed.take(8).map(
              (entry) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 76,
                      child: Text(
                        '${entry.date.month}/${entry.date.day}',
                        style: TextStyle(fontSize: 11, color: t.text3),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.values.entries
                            .map(
                              (value) =>
                                  '${labels[value.key] ?? value.key} ${value.value.toStringAsFixed(1)}cm',
                            )
                            .join(' · '),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: t.text1,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: '编辑',
                      onPressed: () => _addMeasurement(existing: entry),
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: t.primary,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: '删除',
                      onPressed: () => _deleteMeasurement(entry),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: t.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Future<void> _addWeightEntry({WeightEntry? existing}) async {
    final date = existing?.date ?? DateTime.now();
    final ctrl = TextEditingController(
      text:
          existing?.weightKg.toString() ?? _profile?.weightKg.toString() ?? '',
    );
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? '记录体重 (kg)' : '编辑体重 (kg)'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '输入体重',
            labelText: '${date.year}-${date.month}-${date.day}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(ctrl.text);
              if (value != null && value > 0) Navigator.pop(ctx, value);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final entries = await saveWeightEntry(
      WeightEntry(date: date, weightKg: result),
    );
    if (!mounted) return;
    setState(() => _weightHistory = entries);
    if (dateOnly(date) == dateOnly(DateTime.now())) {
      final p = _profile!;
      await _saveProfile(
        UserProfile(
          birthday: p.birthday,
          heightCm: p.heightCm,
          weightKg: result,
          gender: p.gender,
        ),
      );
    }
  }

  Future<void> _editWeightEntry(WeightEntry entry) =>
      _addWeightEntry(existing: entry);

  Future<void> _deleteWeightEntry(WeightEntry entry) async {
    final confirmed = await _confirmDelete(
      '删除 ${entry.weightKg.toStringAsFixed(1)}kg 的体重记录？',
    );
    if (!confirmed) return;
    final entries = await deleteWeightEntry(entry.date);
    if (mounted) setState(() => _weightHistory = entries);
  }

  Future<void> _addMeasurement({BodyMeasurement? existing}) async {
    const fields = {
      'waist': '腰围',
      'chest': '胸围',
      'hip': '臀围',
      'arm': '臂围',
      'thigh': '大腿围',
    };
    final controllers = {
      for (final field in fields.keys)
        field: TextEditingController(
          text: existing?.values[field]?.toString() ?? '',
        ),
    };
    final values = await showDialog<Map<String, double>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? '记录围度 (cm)' : '编辑围度 (cm)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final field in fields.entries) ...[
                TextField(
                  controller: controllers[field.key],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: field.value,
                    hintText: '可选',
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final result = <String, double>{};
              for (final field in controllers.entries) {
                final value = double.tryParse(field.value.text);
                if (value != null && value > 0) result[field.key] = value;
              }
              if (result.isEmpty) {
                ScaffoldMessenger.of(
                  ctx,
                ).showSnackBar(const SnackBar(content: Text('请至少填写一项围度')));
                return;
              }
              Navigator.pop(ctx, result);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (values == null) return;
    final entries = await saveMeasurement(
      BodyMeasurement(date: existing?.date ?? DateTime.now(), values: values),
      replaceSameDay: existing != null,
    );
    if (mounted) setState(() => _measurements = entries);
  }

  Future<void> _deleteMeasurement(BodyMeasurement entry) async {
    final confirmed = await _confirmDelete(
      '删除 ${entry.date.month}/${entry.date.day} 的围度记录？',
    );
    if (!confirmed) return;
    final entries = await deleteMeasurement(entry.date);
    if (mounted) setState(() => _measurements = entries);
  }

  Future<bool> _confirmDelete(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('确认删除'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('删除'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _dataCard(WorkoutTheme t) {
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.backup_outlined, color: t.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '数据管理',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.text1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PressScale(
                    onTap: _exportData,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: t.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.download_rounded,
                            color: t.primary,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '导出备份',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: t.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PressScale(
                    onTap: _importData,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: t.accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.upload_rounded, color: t.accent, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            '导入恢复',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: t.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'JSON 格式 · 含资料、训练、体重与围度 · 导入前自动备份',
              style: TextStyle(fontSize: 10, color: t.text4),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final json = await exportAllData();
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('数据导出'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: SelectableText(json, style: TextStyle(fontSize: 10)),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: json));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('✅ 已复制到剪贴板')));
                },
                child: const Text('复制'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('关闭'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ 导出失败: $e')));
    }
  }

  Future<void> _importData() async {
    final ctrl = TextEditingController();
    var mode = ImportMode.merge;
    final result = await showDialog<ImportMode>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('导入数据'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: '粘贴 v6.7 JSON 备份数据...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                RadioListTile<ImportMode>(
                  value: ImportMode.merge,
                  groupValue: mode,
                  onChanged: (value) => setDialogState(() => mode = value!),
                  title: const Text('合并（推荐）'),
                  subtitle: const Text('同日身体数据以导入值更新，其余历史保留'),
                ),
                RadioListTile<ImportMode>(
                  value: ImportMode.overwrite,
                  groupValue: mode,
                  onChanged: (value) => setDialogState(() => mode = value!),
                  title: const Text('覆盖'),
                  subtitle: const Text('清除当前 BodyRecomp 数据后恢复备份'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) Navigator.pop(ctx, mode);
              },
              child: const Text('导入'),
            ),
          ],
        ),
      ),
    );
    if (result != null && ctrl.text.trim().isNotEmpty) {
      try {
        final imported = await importAllData(ctrl.text, mode: result);
        if (!mounted) return;
        await _loadAll();
        if (!mounted) return;
        widget.onProfileChanged();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ 已${result == ImportMode.merge ? "合并" : "覆盖"}导入 ${imported.importedKeys} 项，原数据已自动备份',
            ),
          ),
        );
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('❌ 导入失败: $e')));
      }
    }
  }
}

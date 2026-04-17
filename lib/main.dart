import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// THEME SYSTEM
// ═══════════════════════════════════════════════════════════════════════════════

enum AppTheme { blue, green, pink, purple, orange }

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

  const WorkoutTheme({
    required this.name,
    required this.emoji,
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
  });
}

const themes = {
  AppTheme.blue: WorkoutTheme(
    name: '天空蓝', emoji: '',
    bg: Color(0xFFF0F4FF),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFF2563EB),
    primaryLight: Color(0xFF60A5FA),
    accent: Color(0xFF7C3AED),
    text1: Color(0xFF1E293B),
    text2: Color(0xFF334155),
    text3: Color(0xFF64748B),
    text4: Color(0xFF94A3B8),
    success: Color(0xFF059669),
    successLight: Color(0xFF34D399),
    warning: Color(0xFFD97706),
    border: Color(0xFFE2E8F0),
    navbarBg: Color(0xFFFFFFFF),
  ),
  AppTheme.green: WorkoutTheme(
    name: '薄荷绿', emoji: '',
    bg: Color(0xFFF0FDF4),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFF059669),
    primaryLight: Color(0xFF34D399),
    accent: Color(0xFF0891B2),
    text1: Color(0xFF1E293B),
    text2: Color(0xFF334155),
    text3: Color(0xFF64748B),
    text4: Color(0xFF94A3B8),
    success: Color(0xFF65A30D),
    successLight: Color(0xFFA3E635),
    warning: Color(0xFFD97706),
    border: Color(0xFFE2E8F0),
    navbarBg: Color(0xFFFFFFFF),
  ),
  AppTheme.pink: WorkoutTheme(
    name: '樱花粉', emoji: '',
    bg: Color(0xFFFDF2F8),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFFDB2777),
    primaryLight: Color(0xFFF472B6),
    accent: Color(0xFF7C3AED),
    text1: Color(0xFF1E293B),
    text2: Color(0xFF334155),
    text3: Color(0xFF64748B),
    text4: Color(0xFF94A3B8),
    success: Color(0xFF0D9488),
    successLight: Color(0xFF2DD4BF),
    warning: Color(0xFFD97706),
    border: Color(0xFFE2E8F0),
    navbarBg: Color(0xFFFFFFFF),
  ),
  AppTheme.purple: WorkoutTheme(
    name: '薰衣紫', emoji: '',
    bg: Color(0xFFFAF5FF),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFF7C3AED),
    primaryLight: Color(0xFFA78BFA),
    accent: Color(0xFFDB2777),
    text1: Color(0xFF1E293B),
    text2: Color(0xFF334155),
    text3: Color(0xFF64748B),
    text4: Color(0xFF94A3B8),
    success: Color(0xFF0891B2),
    successLight: Color(0xFF22D3EE),
    warning: Color(0xFFD97706),
    border: Color(0xFFE2E8F0),
    navbarBg: Color(0xFFFFFFFF),
  ),
  AppTheme.orange: WorkoutTheme(
    name: '日落橙', emoji: '',
    bg: Color(0xFFFFF7ED),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFFEA580C),
    primaryLight: Color(0xFFFB923C),
    accent: Color(0xFFCA8A04),
    text1: Color(0xFF1E293B),
    text2: Color(0xFF334155),
    text3: Color(0xFF64748B),
    text4: Color(0xFF94A3B8),
    success: Color(0xFF0D9488),
    successLight: Color(0xFF2DD4BF),
    warning: Color(0xFFDC2626),
    border: Color(0xFFE2E8F0),
    navbarBg: Color(0xFFFFFFFF),
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
    required this.name,
    required this.muscles,
    required this.muscleTarget,
    required this.sets,
    required this.reps,
    required this.rest,
    this.note,
    this.isStar = false,
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
    required this.dayName,
    required this.subtitle,
    required this.badge,
    required this.description,
    this.isRest = false,
    this.isOptional = false,
    this.optionalDesc,
    this.exercises = const [],
    this.recoveryOptions,
    this.circuitNote,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// WORKOUT DATA — 7 days, 41 exercises
// ═══════════════════════════════════════════════════════════════════════════════

const workoutDays = [
  WorkoutDay(
    dayName: '周一', subtitle: '上肢 A', badge: '推力 + 后束',
    description: '胸 / 肩（前束+中束+后束） / 肱三头',
    exercises: [
      Exercise(name: '上斜哑铃卧推 30\u00B0', muscles: ['胸大肌'], muscleTarget: '上部', sets: 4, reps: '10-12', rest: '90s', isStar: true, note: '核心动作 \u00B7 上胸优先 \u2014 穿衣显锁骨的关键，控制离心3秒下放'),
      Exercise(name: '平板杠铃卧推', muscles: ['胸大肌'], muscleTarget: '整体厚度', sets: 4, reps: '8-10', rest: '90-120s', note: '肩胛骨后缩下沉，全握距比窄握更安全'),
      Exercise(name: '坐姿器械推肩', muscles: ['三角肌'], muscleTarget: '前束 / 中束', sets: 3, reps: '12', rest: '90s', note: '器械比哑铃安全，固定轨道适合推大重量打造饱满肩头'),
      Exercise(name: '哑铃侧平举', muscles: ['三角肌'], muscleTarget: '中束', sets: 4, reps: '15-20', rest: '60s', note: '灵魂动作 \u2014 小重量慢动作，3秒上2秒下，身体不摆动，肩膀越练越宽'),
      Exercise(name: '面拉', muscles: ['三角肌后束'], muscleTarget: '上背', sets: 3, reps: '15-20', rest: '60s', note: '改善圆肩体态必练，绳索拉到脸前，外旋拇指朝后'),
      Exercise(name: '蝴蝶机夹胸', muscles: ['胸大肌'], muscleTarget: '中缝', sets: 3, reps: '15-20', rest: '60s', note: '雕刻胸肌中缝线条，顶峰收缩2秒'),
      Exercise(name: '绳索下压', muscles: ['肱三头'], muscleTarget: '外侧头', sets: 3, reps: '12-15', rest: '60s', note: '手臂后侧线条，拒绝拜拜肉，肘部固定不动'),
      Exercise(name: '坐姿哑铃颈后臂屈伸', muscles: ['肱三头'], muscleTarget: '长头', sets: 3, reps: '10-12', rest: '60s', note: '双手持一个哑铃颈后，肘朝天花板，安全稳定'),
    ],
  ),
  WorkoutDay(
    dayName: '周二', subtitle: '下肢 A', badge: '股四头 / 臀',
    description: '股四头 / 臀 / 腘绳 / 小腿 / 核心',
    exercises: [
      Exercise(name: '倒蹬机（脚位踩高）', muscles: ['股四头', '臀'], muscleTarget: '', sets: 4, reps: '15', rest: '90s', isStar: true, note: '核心动作 \u2014 脚踩高踩外侧重臀和后侧链，比深蹲安全，新手首选'),
      Exercise(name: '哑铃罗马尼亚硬拉', muscles: ['腘绳肌', '臀'], muscleTarget: '', sets: 3, reps: '10-12', rest: '90s', note: '膝盖微屈，髋关节后推，感受大腿后侧拉伸，比传统硬拉更安全'),
      Exercise(name: '坐姿腿屈伸', muscles: ['股四头'], muscleTarget: '孤立', sets: 3, reps: '12-15', rest: '60s', note: '顶峰收缩2秒，慢放3秒，感受股四头肌燃烧'),
      Exercise(name: '俯卧腿弯举', muscles: ['腘绳肌'], muscleTarget: '', sets: 3, reps: '12-15', rest: '60s', note: '强化大腿后侧，让腿部侧面更有型'),
      Exercise(name: '站姿提踵', muscles: ['小腿'], muscleTarget: '腓肠肌', sets: 4, reps: '20', rest: '45s', note: '小腿紧致，视觉拉长腿部比例，顶峰收缩2秒'),
      Exercise(name: '平板支撑', muscles: ['核心'], muscleTarget: '', sets: 3, reps: '45-60s', rest: '45s', note: '身体一条直线，健身房地面就能做'),
    ],
  ),
  WorkoutDay(
    dayName: '周三', subtitle: '上肢 B', badge: '拉力 + 手臂',
    description: '背 / 后束 / 肱二头',
    exercises: [
      Exercise(name: '助力引体向上机', muscles: ['背阔肌', '肱二头'], muscleTarget: '', sets: 4, reps: '8-12', rest: '90-120s', isStar: true, note: '核心动作 \u2014 调助力等级逐步减助力；没有就做反向划船'),
      Exercise(name: '坐姿器械划船', muscles: ['背阔肌', '菱形肌'], muscleTarget: '', sets: 4, reps: '10-12', rest: '90s', note: '器械轨道稳定，胸部贴住靠垫，手肘拉过身体'),
      Exercise(name: '高位下拉', muscles: ['背阔肌'], muscleTarget: '宽度', sets: 3, reps: '10-12', rest: '90s', note: '感受背阔肌像翅膀一样拉开，手肘往下拉不后仰'),
      Exercise(name: '反向蝴蝶机夹胸', muscles: ['三角肌后束'], muscleTarget: '上背', sets: 3, reps: '15-20', rest: '60s', note: '后束第2次刺激（周一面拉 + 今天蝴蝶机 = 6组/周）'),
      Exercise(name: '直臂下压', muscles: ['背阔肌'], muscleTarget: '下部', sets: 3, reps: '12-15', rest: '60s', note: '手臂保持微弯，从头顶压到大腿前侧，感受背阔拉伸'),
      Exercise(name: '杠铃弯举', muscles: ['肱二头'], muscleTarget: '长头', sets: 4, reps: '12', rest: '60s', note: '手臂正面线条，控制离心不甩腰，全幅度动作'),
      Exercise(name: '锤式弯举', muscles: ['肱肌', '肱桡肌'], muscleTarget: '', sets: 3, reps: '12', rest: '60s', note: '掌心相对，让手臂侧面看起来更厚实有力量'),
    ],
  ),
  WorkoutDay(
    dayName: '周四', subtitle: '下肢 B', badge: '后链 + 雕刻',
    description: '臀 / 腘绳 / 核心 / 小腿',
    exercises: [
      Exercise(name: '杠铃臀推', muscles: ['臀大肌'], muscleTarget: '', sets: 4, reps: '10-12', rest: '90s', isStar: true, note: '核心动作 \u2014 顶峰收缩停顿2秒，臀部孤立发力，护腰'),
      Exercise(name: '保加利亚分腿蹲', muscles: ['股四头', '臀'], muscleTarget: '', sets: 3, reps: '每侧10-12', rest: '60s', note: '手持哑铃，单腿训练，矫正左右不平衡'),
      Exercise(name: '坐姿腿弯举', muscles: ['腘绳肌'], muscleTarget: '', sets: 3, reps: '12-15', rest: '60s', note: '和周二俯卧腿弯举互补，两个动作腘绳肌受力角度不同'),
      Exercise(name: '器械内收 / 外展', muscles: ['大腿内收肌'], muscleTarget: '', sets: 3, reps: '15', rest: '60s', note: '收紧大腿内侧，改善腿型'),
      Exercise(name: '反向卷腹', muscles: ['腹直肌'], muscleTarget: '下腹', sets: 4, reps: '15-20', rest: '60s', note: '仰卧抬腿卷骨盆，用腹肌把膝盖拉向胸口，下腹刺激强烈'),
      Exercise(name: '死虫式', muscles: ['核心'], muscleTarget: '稳定性', sets: 3, reps: '每侧10', rest: '45s', note: '仰卧对侧手脚伸展，核心全程收紧贴地，安静不引人注目'),
      Exercise(name: '坐姿提踵', muscles: ['小腿'], muscleTarget: '比目鱼肌', sets: 3, reps: '20', rest: '45s', note: '周二站姿练腓肠肌，今天坐姿练比目鱼肌，两个都练到'),
    ],
  ),
  WorkoutDay(
    dayName: '周五', subtitle: '可选', badge: '可选循环',
    description: '有空就来，没空跳过',
    isOptional: true,
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
    description: '目的是恢复，不是训练',
    isOptional: true,
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
// THEME NOTIFIER — InheritedWidget for efficient theme propagation
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

  static ThemeInherited of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeInherited>()!;
  }

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
    SharedPreferences.getInstance().then((prefs) {
      final idx = prefs.getInt('recomp_theme_v3') ?? 0;
      if (mounted) setState(() => _mode = AppTheme.values[idx.clamp(0, AppTheme.values.length - 1)]);
    });
  }

  Future<void> setTheme(AppTheme mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('recomp_theme_v3', mode.index);
    setState(() => _mode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return ThemeInherited(
      current: _mode,
      theme: themes[_mode]!,
      setTheme: setTheme,
      child: widget.child,
    );
  }
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
      final inherited = ThemeInherited.of(context);
      final t = inherited.theme;

      return MaterialApp(
        title: 'Body Recomp',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: t.bg,
          colorScheme: ColorScheme.light(
            primary: t.primary,
            secondary: t.accent,
            surface: t.card,
            onSurface: t.text1,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: t.bg,
            foregroundColor: t.text1,
            elevation: 0,
            scrolledUnderElevation: 0.5,
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: t.navbarBg,
            selectedItemColor: t.primary,
            unselectedItemColor: t.text4,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
          ),
          cardTheme: CardThemeData(
            color: t.card,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: t.border, width: 1),
            ),
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        ),
        home: const MainPage(),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN PAGE — Bottom navigation with 4 tabs
// ═══════════════════════════════════════════════════════════════════════════════

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final inherited = ThemeInherited.of(context);
    final t = inherited.theme;

    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: const [
          WorkoutPage(),
          NutritionPage(),
          ProgressionPage(),
          ThemePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: '训练'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: '饮食'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: '超负荷'),
          BottomNavigationBarItem(icon: Icon(Icons.palette), label: '主题'),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WORKOUT PAGE — Day selector + exercise list
// ═══════════════════════════════════════════════════════════════════════════════

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});
  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  int _dayIndex = 0;
  Map<String, dynamic> _doneMap = {};

  @override
  void initState() {
    super.initState();
    // Auto-select today
    final today = DateTime.now().weekday; // 1=Mon, 7=Sun
    if (today >= 1 && today <= 7) setState(() => _dayIndex = today - 1);
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('recomp_done_v3');
    if (raw != null) {
      try { setState(() => _doneMap = jsonDecode(raw) as Map<String, dynamic>); } catch (_) {}
    }
  }

  Future<void> _toggle(int dayIdx, int exIdx) async {
    final key = '$dayIdx\_$exIdx';
    setState(() {
      if (_doneMap.containsKey(key)) {
        _doneMap.remove(key);
      } else {
        _doneMap[key] = true;
        HapticFeedback.lightImpact();
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('recomp_done_v3', jsonEncode(_doneMap));
  }

  int _doneCount(int day) {
    int c = 0;
    for (int i = 0; i < workoutDays[day].exercises.length; i++) {
      if (_doneMap.containsKey('$day\_$i')) c++;
    }
    return c;
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeInherited.of(context).theme;
    final day = workoutDays[_dayIndex];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  // Title with PRIMARY color (NOT ShaderMask!)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Body Recomp', style: GoogleFonts.inter(
                          fontSize: 26, fontWeight: FontWeight.w900,
                          color: t.primary, letterSpacing: -0.5,
                        )),
                        Text('27M \u00B7 173cm \u00B7 72.5kg \u00B7 BMI 24.2', style: GoogleFonts.inter(
                          fontSize: 11, color: t.text3, fontWeight: FontWeight.w500,
                        )),
                      ],
                    ),
                  ),
                  // Stats pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: t.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('目标 68-70kg', style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w700, color: t.primary,
                    )),
                  ),
                ],
              ),
            ),

            // ── Day selector chips ──
            Container(
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: workoutDays.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final d = workoutDays[i];
                  final sel = i == _dayIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _dayIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? t.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: sel ? t.primary : t.border,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(d.dayName, style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : t.text2,
                          )),
                          Text(d.subtitle, style: GoogleFonts.inter(
                            fontSize: 8, fontWeight: FontWeight.w500,
                            color: sel ? Colors.white.withOpacity(0.8) : t.text4,
                          )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // ── Content area ──
            Expanded(
              child: _buildDayContent(day, t),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayContent(WorkoutDay day, WorkoutTheme t) {
    if (day.isRest) {
      return Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bedtime, size: 56, color: t.primary.withOpacity(0.6)),
                const SizedBox(height: 16),
                Text('休息日', style: GoogleFonts.inter(
                  fontSize: 22, fontWeight: FontWeight.w800, color: t.text1,
                )),
                const SizedBox(height: 8),
                Text('肌肉在休息时生长\n保证 7-9 小时睡眠', style: GoogleFonts.inter(
                  fontSize: 13, color: t.text3, height: 1.8,
                ), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    // Recovery day
    if (day.recoveryOptions != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dayHeader(day, t),
            const SizedBox(height: 12),
            Text(day.optionalDesc!, style: GoogleFonts.inter(fontSize: 12, color: t.text3, height: 1.6)),
            const SizedBox(height: 12),
            ...day.recoveryOptions!.map((opt) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: t.primary,
                    boxShadow: [BoxShadow(color: t.primary.withOpacity(0.4), blurRadius: 6)],
                  ),
                ),
                title: Text(opt, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: t.text2)),
                dense: true,
              ),
            )),
          ],
        ),
      );
    }

    // Normal workout day
    final done = _doneCount(_dayIndex);
    final total = day.exercises.length;
    final full = done == total && total > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dayHeader(day, t),
          const SizedBox(height: 12),

          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('训练进度', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: t.text3)),
              Text('$done/$total', style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w700, color: t.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? done / total : 0,
              minHeight: 6,
              backgroundColor: t.border,
              valueColor: AlwaysStoppedAnimation(full ? t.success : t.primary),
            ),
          ),
          const SizedBox(height: 14),

          // Exercise list
          ...day.exercises.asMap().entries.map((entry) {
            final i = entry.key;
            final ex = entry.value;
            final isDone = _doneMap.containsKey('$_dayIndex\_$i');
            return _exerciseCard(ex, i + 1, isDone, t, () => _toggle(_dayIndex, i));
          }),

          if (day.circuitNote != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Card(
                color: t.primary.withOpacity(0.04),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(day.circuitNote!, style: GoogleFonts.inter(
                    fontSize: 11, color: t.text3, height: 1.6, fontWeight: FontWeight.w500,
                  )),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dayHeader(WorkoutDay day, WorkoutTheme t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${day.dayName} ${day.subtitle}', style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w800, color: t.text1, letterSpacing: -0.3,
                )),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: t.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(day.badge, style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w700, color: t.primary,
                  )),
                ),
              ],
            ),
            if (day.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(day.description, style: GoogleFonts.inter(fontSize: 12, color: t.text3)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _exerciseCard(Exercise ex, int num, bool isDone, WorkoutTheme t, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          color: ex.isStar && !isDone ? t.primary.withOpacity(0.02) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: ex.isStar && !isDone
                ? BorderSide(color: t.primary.withOpacity(0.3), width: 1.5)
                : BorderSide(color: t.border, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Number + Checkbox
                GestureDetector(
                  onTap: onTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? t.success : Colors.transparent,
                      border: Border.all(
                        color: isDone ? t.success : t.text4,
                        width: 1.5,
                      ),
                      boxShadow: isDone ? [BoxShadow(color: t.success.withOpacity(0.3), blurRadius: 6)] : null,
                    ),
                    child: isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : Center(
                            child: Text('$num', style: GoogleFonts.inter(
                              fontSize: 11, fontWeight: FontWeight.w700, color: t.text4,
                            )),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Exercise info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex.name, style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: isDone ? t.text4 : t.text1,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        decorationColor: t.text4,
                      )),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 4, runSpacing: 2,
                        children: [
                          ...ex.muscles.map((m) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: t.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(m, style: GoogleFonts.inter(
                              fontSize: 9, fontWeight: FontWeight.w600, color: t.text3,
                            )),
                          )),
                          if (ex.muscleTarget.isNotEmpty)
                            Text(ex.muscleTarget, style: GoogleFonts.inter(fontSize: 9, color: t.text3)),
                        ],
                      ),
                      if (ex.note != null && !isDone) ...[
                        const SizedBox(height: 6),
                        Text(ex.note!, style: GoogleFonts.inter(fontSize: 10.5, color: t.text3, height: 1.5)),
                      ],
                    ],
                  ),
                ),

                // Sets x Reps x Rest
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${ex.sets}\u00D7', style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w800, color: t.primary,
                    )),
                    Text(ex.reps, style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w600, color: t.text2,
                    )),
                    const SizedBox(height: 2),
                    Text(ex.rest, style: GoogleFonts.inter(
                      fontSize: 9, fontWeight: FontWeight.w500, color: t.text4,
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

    return Scaffold(
      appBar: AppBar(title: Text('饮食营养', style: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w800, color: t.text1,
      ))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calorie summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('每日热量', '2200', 'kcal', t),
                    _statItem('蛋白质', '130-160', 'g', t),
                    _statItem('碳水', '200-270', 'g', t),
                    _statItem('脂肪', '58-73', 'g', t),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Macro detail cards
            _macroCard('蛋白质', '130-160g', '1.8-2.2g/kg \u00B7 25%',
                '鸡胸 \u00B7 牛肉 \u00B7 鸡蛋 \u00B7 鱼虾 \u00B7 豆腐 \u00B7 蛋白粉', t.primary, t),
            const SizedBox(height: 8),
            _macroCard('碳水', '200-270g', '2-3g/kg \u00B7 40%',
                '糙米 \u00B7 红薯 \u00B7 燕麦 \u00B7 全麦 \u00B7 玉米 \u00B7 水果', t.warning, t),
            const SizedBox(height: 8),
            _macroCard('脂肪', '58-73g', '0.8-1g/kg \u00B7 30%',
                '橄榄油 \u00B7 坚果 \u00B7 牛油果 \u00B7 深海鱼 \u00B7 蛋黄', t.success, t),

            const SizedBox(height: 24),
            Text('饮食建议', style: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.w800, color: t.text1,
            )),
            const SizedBox(height: 10),
            ...nutritionTips.asMap().entries.map((e) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 3, height: 14,
                      margin: const EdgeInsets.only(right: 10, top: 2),
                      decoration: BoxDecoration(
                        color: t.primary, borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: Text(nutritionTips[e.key], style: GoogleFonts.inter(
                        fontSize: 12, color: t.text2, height: 1.6,
                      )),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, String unit, WorkoutTheme t) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: t.text4, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: t.primary)),
        Text(unit, style: GoogleFonts.inter(fontSize: 9, color: t.text4)),
      ],
    );
  }

  Widget _macroCard(String label, String value, String pct, String foods, Color color, WorkoutTheme t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 28, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: t.text4, letterSpacing: 1.5)),
                const Spacer(),
                Text(pct, style: GoogleFonts.inter(fontSize: 10, color: t.text3)),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(foods, style: GoogleFonts.inter(fontSize: 11, color: t.text3, height: 1.5)),
          ],
        ),
      ),
    );
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

    return Scaffold(
      appBar: AppBar(title: Text('渐进超负荷', style: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w800, color: t.text1,
      ))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview
            Card(
              color: t.primary.withOpacity(0.04),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '渐进超负荷是增肌的核心原则：逐步增加训练负荷，迫使身体适应并变得更强。每 1-2 周尝试加重或增加次数，保持训练日志记录进步。',
                  style: GoogleFonts.inter(fontSize: 12, color: t.text2, height: 1.7),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text('四阶段计划', style: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.w800, color: t.text1,
            )),
            const SizedBox(height: 10),

            // Phase cards
            ...progressionPhases.asMap().entries.map((e) {
              final (week, title, desc) = progressionPhases[e.key];
              final phaseNum = e.key + 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Phase number circle
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: t.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('$phaseNum', style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.w800, color: t.primary,
                            )),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(title, style: GoogleFonts.inter(
                                    fontSize: 15, fontWeight: FontWeight.w800, color: t.text1,
                                  )),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: t.primary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(week, style: GoogleFonts.inter(
                                      fontSize: 9, fontWeight: FontWeight.w700, color: t.primary,
                                    )),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(desc, style: GoogleFonts.inter(fontSize: 12, color: t.text3, height: 1.6)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),
            Text('加重策略', style: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.w800, color: t.text1,
            )),
            const SizedBox(height: 10),
            ...[
              ('上肢复合动作', '卧推 / 划船 / 推肩：每次 +1.25-2.5kg'),
              ('下肢复合动作', '倒蹬 / 硬拉 / 臀推：每次 +2.5-5kg'),
              ('孤立动作', '侧平举 / 弯举 / 下压：每次 +0.5-1kg 或 +1-2次'),
              ('遇到瓶颈', '减重 10% 重新开始，或更换动作变式刺激新角度'),
            ].map((item) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                title: Text(item.$1, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: t.text1)),
                subtitle: Text(item.$2, style: GoogleFonts.inter(fontSize: 11, color: t.text3, height: 1.5)),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// THEME PAGE — Simple tappable list, NO GestureDetector nesting issues
// ═══════════════════════════════════════════════════════════════════════════════

class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    final inherited = ThemeInherited.of(context);
    final t = inherited.theme;
    final current = inherited.current;

    return Scaffold(
      appBar: AppBar(title: Text('主题选择', style: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w800, color: t.text1,
      ))),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: AppTheme.values.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final mode = AppTheme.values[i];
          final mt = themes[mode]!;
          final sel = mode == current;

          return Card(
            color: sel ? mt.primary.withOpacity(0.06) : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: sel ? mt.primary : t.border,
                width: sel ? 2 : 1,
              ),
            ),
            child: ListTile(
              onTap: () => inherited.setTheme(mode),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [mt.primary, mt.accent]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: sel ? [BoxShadow(color: mt.primary.withOpacity(0.3), blurRadius: 8)] : null,
                ),
                child: sel ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
              ),
              title: Text(mt.name, style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: sel ? mt.primary : t.text1,
              )),
              subtitle: Text(sel ? '当前使用中' : '点击切换', style: GoogleFonts.inter(
                fontSize: 11, color: sel ? mt.primary.withOpacity(0.7) : t.text4,
              )),
              trailing: sel
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: mt.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('已选择', style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w700, color: mt.primary,
                      )),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}

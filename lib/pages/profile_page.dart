import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/recomp_models.dart';
import '../services/app_signals.dart';
import '../services/data_service.dart';
import '../services/rest_timer_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/body_editor.dart';
import '../widgets/loading_view.dart';
import '../widgets/sheet_frame.dart';
import 'exercise_library_view.dart';
import 'template_manager_page.dart';

const progressionPhases = [
  ('1-2 周', '学习期', '60-70% 1RM，掌握动作模式与控制节奏，不急着加重'),
  ('3-4 周', '适应期', '70-75% 1RM，目标次数轻松完成即可小幅加重 1.25–2.5kg'),
  ('5-8 周', '增长期', '75-85% 1RM，保持 RPE 7–8，每 1–2 周稳步推高容量或负重'),
  ('9-12 周', '突破期', '接近 85% 1RM，巩固核心动作 PR，8–12 周后可适度轮换动作'),
];

class ProfilePage extends StatefulWidget {
  final String appVersion;
  const ProfilePage({super.key, this.appVersion = '7.0.2'});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? _profile;
  bool _autoRestTimer = false;
  bool _hasImportBackup = false;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    workoutDataRevision.addListener(_loadAll);
    restTimerPreferenceRevision.addListener(_loadAll);
    _loadAll();
  }

  @override
  void dispose() {
    workoutDataRevision.removeListener(_loadAll);
    restTimerPreferenceRevision.removeListener(_loadAll);
    super.dispose();
  }

  Future<void> _loadAll() async {
    try {
      final profile = await loadProfile();
      final autoRest = await loadAutoRestTimer();
      final hasBackup = await hasLastImportBackup();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _autoRestTimer = autoRest;
        _hasImportBackup = hasBackup;
        _loading = false;
        _loadError = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = '个人设置读取失败，本地数据未被覆盖。';
        });
      }
    }
  }

  Future<void> _persist(Future<void> Function() action) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveProfile(UserProfile profile) async {
    await saveProfile(profile);
    if (mounted) setState(() => _profile = profile);
    workoutDataRevision.value++;
  }

  Future<void> _editBirthday(UserProfile p) async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(p.birthday) ?? DateTime(1995, 6, 15);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(1930),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: '选择出生日期',
    );
    if (picked == null || !mounted) return;
    final formatted =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    await _persist(
      () => _saveProfile(
        UserProfile(
          birthday: formatted,
          heightCm: p.heightCm,
          weightKg: p.weightKg,
          gender: p.gender,
        ),
      ),
    );
  }

  Future<void> _editGender(UserProfile profile) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SheetFrame(
        title: '性别',
        subtitle: '仅用于个人资料展示',
        icon: Icons.person_outline_rounded,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectionOption(
              title: '男',
              leading: const Icon(Icons.male_rounded),
              selected: profile.gender == 'male',
              onTap: () => Navigator.pop(ctx, 'male'),
            ),
            const SizedBox(height: 8),
            SelectionOption(
              title: '女',
              leading: const Icon(Icons.female_rounded),
              selected: profile.gender == 'female',
              onTap: () => Navigator.pop(ctx, 'female'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    await _persist(
      () => _saveProfile(
        UserProfile(
          birthday: profile.birthday,
          heightCm: profile.heightCm,
          weightKg: profile.weightKg,
          gender: choice,
        ),
      ),
    );
  }

  Future<void> _editHeight(UserProfile profile) async {
    final values = await editBodyValues(
      context,
      title: '身高',
      subtitle: '用于计算 BMI 指数',
      fields: const {'height': '身高 · cm'},
      initial: {'height': profile.heightCm},
    );
    if (values == null || !mounted) return;
    await _persist(
      () => _saveProfile(
        UserProfile(
          birthday: profile.birthday,
          heightCm: values['height']!,
          weightKg: profile.weightKg,
          gender: profile.gender,
        ),
      ),
    );
  }

  Future<void> _editWeight(UserProfile profile) async {
    final values = await editBodyValues(
      context,
      title: '当前体重',
      subtitle: '将同步记录到今日体重趋势',
      fields: const {'weight': '体重 · kg'},
      initial: {'weight': profile.weightKg},
    );
    if (values == null || !mounted) return;
    final weight = values['weight']!;
    await _persist(() async {
      await saveWeightEntry(
        WeightEntry(date: DateTime.now(), weightKg: weight),
      );
      await _saveProfile(
        UserProfile(
          birthday: profile.birthday,
          heightCm: profile.heightCm,
          weightKg: weight,
          gender: profile.gender,
        ),
      );
    });
  }

  Future<void> _exportData() async {
    try {
      final json = await exportAllData();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('数据导出 (JSON)'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                json,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: json));
                if (!ctx.mounted || !mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已复制 JSON 备份到剪贴板')),
                );
              },
              child: const Text('复制全部'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导出失败: $e')));
      }
    }
  }

  Future<void> _importData() async {
    final ctrl = TextEditingController();
    var mode = ImportMode.merge;
    try {
      final result = await showDialog<ImportMode>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) {
            final p = ctx.palette;
            return AlertDialog(
              title: const Text('导入数据'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: ctrl,
                      maxLines: 7,
                      decoration: const InputDecoration(
                        hintText: '粘贴导出的 JSON 备份…',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectionOption(
                      title: '合并（推荐）',
                      subtitle: '同日身体数据以导入更新，其余历史保留',
                      leading: Icon(Icons.merge_rounded, color: p.primary),
                      selected: mode == ImportMode.merge,
                      onTap: () =>
                          setDialogState(() => mode = ImportMode.merge),
                    ),
                    const SizedBox(height: 8),
                    SelectionOption(
                      title: '覆盖',
                      subtitle: '用备份替换青燃的全部本地记录',
                      leading:
                          Icon(Icons.restore_page_outlined, color: p.warning),
                      selected: mode == ImportMode.overwrite,
                      onTap: () =>
                          setDialogState(() => mode = ImportMode.overwrite),
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
            );
          },
        ),
      );

      if (result == null || ctrl.text.trim().isEmpty || !mounted || _saving) {
        return;
      }

      setState(() => _saving = true);
      final themeController = context.themeController;
      try {
        final imported = await importAllData(ctrl.text, mode: result);
        if (!mounted) return;
        await themeController?.load();
        await _loadAll();
        if (!mounted) return;
        _broadcastAllRevisions();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '已${result == ImportMode.merge ? "合并" : "覆盖"}导入 ${imported.importedKeys} 项（导入前已自动备份）',
            ),
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('导入失败: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _restorePreImportBackup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('恢复上次导入前备份？'),
        content: const Text('将用导入前自动保存的快照覆盖当前记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('恢复备份'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted || _saving) return;
    setState(() => _saving = true);
    final themeController = context.themeController;
    try {
      await restoreLastImportBackup();
      if (!mounted) return;
      await themeController?.load();
      await _loadAll();
      if (!mounted) return;
      _broadcastAllRevisions();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已恢复上一次导入前数据')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _broadcastAllRevisions() {
    workoutDataRevision.value++;
    workoutHistoryRevision.value++;
    workoutPlanRevision.value++;
    exerciseLibraryRevision.value++;
    exerciseLogsRevision.value++;
    restTimerPreferenceRevision.value++;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (_loading) return const LoadingView();
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, style: TextStyle(color: p.textPrimary)),
              const SizedBox(height: 10),
              TextButton(onPressed: _loadAll, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    final profile = _profile!;
    final themeCtrl = context.themeController;
    final currentTheme = themeCtrl?.current ?? AppTheme.blue;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 110),
      children: [
        _buildProfileHero(context, profile),
        const SizedBox(height: 22),

        // Theme studio gallery
        const SectionTitleBar(
          title: '外观主题工坊',
          subtitle: '6 套高定明暗质感主题，随时切换',
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 112,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final mode in AppTheme.values)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _ThemePreviewCard(
                    mode: mode,
                    selected: mode == currentTheme,
                    onTap: () => themeCtrl?.setTheme(mode),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Training preferences & shortcuts
        const SectionTitleBar(title: '训练偏好与快捷入口'),
        const SizedBox(height: 10),
        SurfaceCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              SwitchListTile.adaptive(
                value: _autoRestTimer,
                onChanged: _saving
                    ? null
                    : (value) async {
                        await _persist(() async {
                          await saveAutoRestTimer(value);
                          restTimerPreferenceRevision.value++;
                          if (mounted) setState(() => _autoRestTimer = value);
                        });
                      },
                title: Text(
                  '完成一组后自动开始休息计时',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '仅当天打卡生效，最后一组与撤销操作不自动启动',
                  style: TextStyle(fontSize: 11.5, color: p.textSecondary),
                ),
              ),
              Divider(
                  height: 1, indent: 16, endIndent: 16, color: p.borderSubtle),
              ListTile(
                leading:
                    Icon(Icons.calendar_view_week_rounded, color: p.primary),
                title: const Text('管理每日固定模板'),
                subtitle: const Text('配置周一至周日固定课表与自定义模板'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TemplateManagerPage(),
                  ),
                ),
              ),
              Divider(
                  height: 1, indent: 16, endIndent: 16, color: p.borderSubtle),
              ListTile(
                leading: Icon(Icons.library_books_outlined, color: p.accent),
                title: const Text('管理个人动作库'),
                subtitle: const Text('新增、编辑或删除动作库动作'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('个人动作库')),
                      body: const AmbientCanvas(child: ExerciseLibraryView()),
                    ),
                  ),
                ),
              ),
              Divider(
                  height: 1, indent: 16, endIndent: 16, color: p.borderSubtle),
              ListTile(
                leading: Icon(Icons.trending_up_rounded, color: p.warning),
                title: const Text('渐进超负荷训练参考'),
                subtitle: const Text('12 周四阶段力量与增肌负荷指南'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('渐进超负荷参考')),
                      body: const AmbientCanvas(child: ProgressionPage()),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Local Backup
        const SectionTitleBar(
          title: '本地备份与数据安全',
          subtitle: '全部数据仅保存在你的设备本地，支持 JSON 导入导出',
        ),
        const SizedBox(height: 10),
        SurfaceCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final scale = MediaQuery.textScalerOf(context).scale(13);
                  final exportBtn = FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: _saving ? null : _exportData,
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: const Text('导出 JSON'),
                  );
                  final importBtn = OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: _saving ? null : _importData,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('导入恢复'),
                  );
                  if (constraints.maxWidth < 270 || scale > 20) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        exportBtn,
                        const SizedBox(height: 8),
                        importBtn,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: exportBtn),
                      const SizedBox(width: 10),
                      Expanded(child: importBtn),
                    ],
                  );
                },
              ),
              if (_hasImportBackup) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _saving ? null : _restorePreImportBackup,
                    icon: const Icon(Icons.history_rounded, size: 17),
                    label: const Text('撤销上次导入（恢复导入前快照）'),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),

        SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: p.primaryGradient,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.bolt_rounded, color: p.onPrimary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '青燃 BodyRecomp v${widget.appVersion}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '本地离线优先 · 每日固定模板 · 自由动作库',
                      style: TextStyle(fontSize: 11.5, color: p.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHero(BuildContext context, UserProfile profile) {
    final p = context.palette;
    final bmi = profile.bmi;
    final bmiLabel = bmi <= 0
        ? '未计算'
        : bmi < 18.5
            ? '偏瘦'
            : bmi < 24
                ? '理想标准'
                : bmi < 28
                    ? '略偏重'
                    : '超重';
    final bmiNorm = bmi <= 0 ? 0.0 : ((bmi - 15) / (34 - 15)).clamp(0.0, 1.0);

    return SurfaceCard(
      elevated: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: p.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  profile.gender == 'female'
                      ? Icons.female_rounded
                      : Icons.male_rounded,
                  color: p.onPrimary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '个人档案',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: p.textPrimary,
                          ),
                        ),
                        StatusPill(
                          label:
                              'BMI ${bmi > 0 ? bmi.toStringAsFixed(1) : '--'} · $bmiLabel',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '点击下方任意数据卡片即可更新',
                      style: TextStyle(fontSize: 12, color: p.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Visual BMI gauge
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LayoutBuilder(
              builder: (context, c) => Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          p.accent,
                          p.success,
                          p.warning,
                          p.danger,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: (c.maxWidth - 10) * bmiNorm,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: p.canvas, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _profileChip(
                  label: '身高',
                  value: '${profile.heightCm.toStringAsFixed(0)} cm',
                  onTap: () => _editHeight(profile),
                  p: p,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _profileChip(
                  label: '体重',
                  value: '${profile.weightKg.toStringAsFixed(1)} kg',
                  onTap: () => _editWeight(profile),
                  p: p,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _profileChip(
                  label: '性别',
                  value: profile.gender == 'female' ? '女' : '男',
                  onTap: () => _editGender(profile),
                  p: p,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _profileChip(
                  label: '年龄 / 生日',
                  value: profile.age > 0
                      ? '${profile.age} 岁'
                      : (profile.birthday.isEmpty ? '点击设置' : profile.birthday),
                  onTap: () => _editBirthday(profile),
                  p: p,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profileChip({
    required String label,
    required String value,
    required VoidCallback onTap,
    required AppPalette p,
  }) =>
      Material(
        color: p.surfaceMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: p.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: p.textSecondary),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ThemePreviewCard extends StatelessWidget {
  final AppTheme mode;
  final bool selected;
  final VoidCallback onTap;

  const _ThemePreviewCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final target = AppPalette.forTheme(mode);
    final current = context.palette;
    return Material(
      color: target.canvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? current.primary : current.borderSubtle,
          width: selected ? 2.0 : 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('profile-theme-${mode.name}'),
        onTap: onTap,
        child: SizedBox(
          width: 144,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: target.primaryGradient,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const Spacer(),
                    if (selected)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: target.primary,
                      ),
                  ],
                ),
                const Spacer(),
                Container(
                  height: 14,
                  width: 84,
                  decoration: BoxDecoration(
                    color: target.surfaceElevated,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  target.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: target.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProgressionPage extends StatelessWidget {
  const ProgressionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
      children: [
        SurfaceCard(
          highlighted: true,
          padding: const EdgeInsets.all(16),
          child: Text(
            '渐进超负荷是力量与增肌的核心原则：在动作标准、恢复充足的前提下，逐步提高负重、次数或总组数，让身体持续适应。建议每 1–2 周尝试小幅突破，并在训练卡片记录负重追踪 1RM。',
            style: TextStyle(
              fontSize: 13,
              height: 1.65,
              color: p.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const SectionTitleBar(title: '四阶段进阶周期'),
        const SizedBox(height: 10),
        for (var i = 0; i < progressionPhases.length; i++) ...[
          Builder(
            builder: (context) {
              final (weeks, title, desc) = progressionPhases[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SurfaceCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: p.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: p.onPrimary,
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
                                  title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: p.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StatusPill(label: weeks),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              desc,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: p.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

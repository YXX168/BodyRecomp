# BodyRecomp 版本指南

## 当前发布版本

### v6.7.0+72 — 2026-07-15

v6.7.0 新增完整动作日志、RPE/1RM/PR、围度趋势、体重编辑删除、左右滑动切天和 schema v2 完整备份。

## v6.7.0 功能

本版本包含：

- 动作训练日志模型与本地存储：重量、组数、次数、RPE、最近记录及 Epley 1RM 估算。
- 身体数据模型与本地存储：体重、腰围、胸围、臀围、臂围和大腿围；同日记录按日期更新。
- 历史数据操作：体重和围度记录的查询与删除接口。
- 训练日导航：周一至周日横向滑动切换的基础交互。
- 数据备份：schema v2 校验、v6.6 对象式备份迁移、导入前自动备份、合并与覆盖导入。
- 自动测试：models、data service、history service、横向滑动和应用 smoke test。

### 数据与兼容性

| 数据 | SharedPreferences key |
|---|---|
| 用户资料 | `recomp_profile_v6` |
| 体重历史 | `recomp_weight_history_v6` |
| 围度历史 | `recomp_measurements_v6` |
| 动作日志 | `recomp_exercise_logs_v6` |
| 周训练完成状态 | `recomp_done_v6` |
| 月度归档 | `recomp_history_YYYY_MM` |
| 导入前备份 | `recomp_import_backup_v6` |

原有 `recomp_*_v6` key 保持不变。v6.7 开发中的导出格式使用 `schemaVersion: 2`，导入器可迁移 v6.6 的对象式 JSON 备份。

## 本地验证

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter build apk --release
```

当前版本由 `pubspec.yaml` 的 `6.7.0+72` 统一驱动；tag 构建使用 GitHub Secrets 中的正式签名。

## 版本历史摘要

- **v6.6.1+71**：设置页、个人资料、体重趋势、JSON 导入导出、1RM 基础能力及细节修复。
- **v6.5.1**：修复周一至周日滑动药丸边界与阴影。
- **v6.4.1**：修复真实日期归档、取消勾选同步和跨年 ISO 周。
- **v6.4.0**：新增训练记录、月度热力图和每周自动归档。
- **v6.3.0**：调整上下肢训练计划。
- **v6.2.0**：玻璃态 UI、六套主题和本地完成状态。

## 项目结构

```text
lib/
├── main.dart
├── models/recomp_models.dart
├── services/data_service.dart
├── services/history_service.dart
└── widgets/horizontal_day_swipe.dart
test/
├── models/
├── services/
├── widgets/
└── widget_test.dart
```

仓库：https://github.com/YXX168/BodyRecomp

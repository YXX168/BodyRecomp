<div align="center">
  <img src="assets/branding/bodyrecomp-icon.png" alt="BodyRecomp 图标" width="112">

# BodyRecomp｜本地健身训练记录

一款使用 Flutter 开发的 Android 健身应用，用于管理每周训练计划、记录完成进度并追踪身体变化。无需注册账号，数据默认只保存在本机。

[![构建状态](https://github.com/YXX168/BodyRecomp/actions/workflows/build.yml/badge.svg)](https://github.com/YXX168/BodyRecomp/actions/workflows/build.yml)
[![当前版本](https://img.shields.io/badge/源码版本-v6.9.0%2B78-2563EB)](CHANGELOG.md)
[![开源许可](https://img.shields.io/badge/许可-MIT-059669)](LICENSE)

[下载 APK](https://github.com/YXX168/BodyRecomp/releases/latest) · [查看更新记录](CHANGELOG.md) · [反馈问题](https://github.com/YXX168/BodyRecomp/issues)
</div>

## 主要功能

- **训练计划**：内置一周训练安排，可修改动作名称、组数、次数、休息时间和动作说明，也可随时恢复默认计划。
- **训练打卡**：记录每日动作完成情况，按周自动归档，并通过月度热力图和年度统计回顾训练频率。
- **休息计时**：完成动作后可自动开始组间计时，也支持手动启动、增加 30 秒和提前结束。
- **身体数据**：管理个人资料、BMI、体重与身体围度，查看历史记录和变化趋势。
- **训练参考**：提供饮食建议与渐进超负荷说明，方便在训练时快速查看。
- **个性主题**：提供 6 套明暗主题，主题偏好保存在本机。
- **数据备份**：以 JSON 导出全部数据；导入时支持合并或覆盖，并在导入前自动保留一份备份。

## 数据与隐私

BodyRecomp 不要求账号，也不包含广告、统计 SDK 或云端同步功能。个人资料、训练记录和身体数据均使用 `SharedPreferences` 保存在设备本地。

卸载应用或清除应用数据前，请先在设置页导出 JSON 备份。导出的内容包含个人资料和训练数据，请自行妥善保管。

## 下载与安装

前往 [GitHub Releases](https://github.com/YXX168/BodyRecomp/releases/latest) 下载 APK。目前发布页提供 Android arm64 安装包；安装第三方 APK 时，系统可能要求允许“安装未知应用”。

仓库源码当前版本为 `v6.9.0+78`。若最新 Release 版本较低，表示新版仍在验证或尚未发布，请以发布页中的版本为准。

## 本地开发

### 环境要求

- Flutter `3.41.6`（与持续集成环境一致）
- Dart `>=3.2.0 <4.0.0`
- Android SDK

### 运行与验证

```bash
flutter pub get
flutter run

# 提交前验证
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-fatal-infos
flutter test
flutter build apk --release --target-platform android-arm64
```

无正式签名配置时，本地 release 构建会使用调试签名，仅用于开发验证。推送到 `main`、创建拉取请求或手动触发工作流时，GitHub Actions 会自动执行格式检查、静态分析、测试和 APK 构建。

## 项目结构

```text
lib/
├── main.dart                       # 应用入口、主题与页面
├── models/recomp_models.dart       # 资料、体重、围度与训练数据模型
├── services/
│   ├── data_service.dart           # 本地数据与 JSON 备份
│   ├── history_service.dart        # 周/月训练历史
│   ├── record_summary_service.dart # 月度与年度统计
│   ├── rest_timer_service.dart     # 休息计时设置
│   └── workout_plan_service.dart   # 自定义训练计划
└── widgets/
    └── horizontal_day_swipe.dart   # 横向切换训练日
test/                               # 模型、服务与界面测试
android/                            # Android 工程配置
```

## 参与维护

发现问题或有功能建议时，请先在 [Issues](https://github.com/YXX168/BodyRecomp/issues) 中说明复现步骤、设备型号、Android 版本和应用版本。提交代码前，请确保格式检查、静态分析和测试全部通过。

## 开源许可

本项目基于 [MIT License](LICENSE) 开源。

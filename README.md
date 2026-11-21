<div align="center">
  <img src="assets/branding/bodyrecomp-icon.png" alt="青燃图标" width="112">

# 青燃｜流光液态玻璃健身记录

本地优先的积木式健身与体态重构助手：每日固定训练模板、可增删个人动作库、组间计时、力量 PR、饮食与体重追踪。Android 离线运行，无需注册账号。

[![构建状态](https://github.com/YXX168/BodyRecomp/actions/workflows/build.yml/badge.svg)](https://github.com/YXX168/BodyRecomp/actions/workflows/build.yml)
[![正式版](https://img.shields.io/github/v/release/YXX168/BodyRecomp?label=正式版&color=287454)](https://github.com/YXX168/BodyRecomp/releases/latest)
[![许可](https://img.shields.io/badge/许可-MIT-059669)](LICENSE)
</div>

[下载正式版 APK](https://github.com/YXX168/BodyRecomp/releases/latest) · [更新记录](CHANGELOG.md) · [反馈问题](https://github.com/YXX168/BodyRecomp/issues/new/choose)

## 核心体验与功能

四大极简主标签（**训练 / 模板 / 动作库 / 我的**），配合 **6 套流光极光明暗主题**、缓存式极光渐变背景与零弹跳水滴滑动底栏（支持点击切换与横向滑动拖选）。

### 1. 训练 · 每日积木与跟手打卡
- **每日固定模板自动载入**：周一至周日均配有默认参考课表（推 / 拉 / 核心有氧 / 腿臀 / 上肢 / 有氧 / 恢复，可自由重编或设为休息日）。未打卡前不提前写入历史，完成首组时自动生成当日独立快照，此后模板改版不影响既有历史。
- **跟手周历与吸顶防透视总览**：顶部紧凑周历条随列表下滑 1:1 顺滑收起，总体训练概览卡无缝吸顶锁定（搭配极简肌群剪影、进度条及裁剪防透视），轻点吸顶卡片或上滑即可平滑唤回日历；支持前后切换日期、历史补记与未来日期只读预览。
- **高效率动作卡**：直接点组数圆片打卡或取消最后一组，外显最近一次负重（点按快速记负重并计算预估 1RM / PR）；有要领备注的动作标题旁带展开指示箭头；右上角 `⋯` 呼出高透流光毛玻璃子菜单，支持编辑组次、上移下移、移除撤销或标记休息。
- **组间计时药丸**：顶栏右侧常驻轻量入口，空闲时呈圆形毛玻璃快捷按钮，启动后平稳展开为倒计时胶囊，支持 `+30s` / 结束及「完成一组后自动计时」，切换标签或退后台不丢时。

### 2. 模板 · 周课表可视化工作室
- 顶部周卡片切换周一至周日绑定对应固定模板，底部横向模板画廊支持新建、复制、编辑、排序与删除撤销，并静默展示已绑定的星期。

### 3. 动作库 · 可自由增删的个人动作库
- 独立持久化双列流光卡片视图，内置 53 项分部位动作；支持实时搜索、玻璃分类胶囊与收藏筛选、自定义新增/编辑/删除撤销，以及一键加入今日训练（支持撤销）与恢复内置默认动作（保留自建动作）。

### 4. 我的与数据洞察 · 体重、力量 PR 与饮食
- **身体概览**：默认体重 `69kg`、BMI 状态标尺、30 天体重平滑曲线与 4 档强度月度训练热力图（点击热力图日格可查看当日明细）。
- **力量 PR 与身体围度**：一键直达「力量 PR（1RM 趋势与快捷选动作录入）」、「训练热力」及「身体围度（腰围/臂围等）」二级透明极光页面。
- **饮食日记**：支持早/午/练前/晚/加餐记录，按参考模板一键填入，热量与蛋白质为选填手动统计。

## 数据备份与升级说明

- **纯本地存储**：所有记录仅存于设备本地，无登录、广告、埋点或云端依赖。可在「我的 → 数据备份」导出或导入 JSON（支持合并、覆盖与恢复导入前备份；即使档案 JSON 意外损坏，页面仍保留备份导入与原数据导出自救通道）。
- **当前正式版**：**7.1.3（build 94）**，适用于 Android 7.0 及以上 ARM64 设备。前往 [最新发布页](https://github.com/YXX168/BodyRecomp/releases/latest) 下载 **`Qingran-v7.1.3-arm64.apk`**，同页提供 `.sha256` 校验文件。
- **直接覆盖升级**：包名为 `com.body.recomp`，沿用官方正式签名（App 自 7.0.1 起由「青阳」更名为「青燃」），在旧正式版上直接覆盖安装即可完整保留已有记录；7.0.x 升级或跨包名预览版迁移请通过 JSON 备份导入合并。

## 开发与验证

环境：Flutter 3.41.6、Dart 3.11、Android SDK、JDK 17。

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-fatal-infos
flutter test
flutter build apk --profile --target-platform android-arm64
```

正式构建使用 `flutter build apk --release --target-platform android-arm64` 并需提供官方签名配置。推送至 `main` 的 PR 会自动运行格式、静态分析、130 项自动化测试及性能预览构建；推送匹配 `pubspec.yaml` 的版本标签 `v*`（且存在 `docs/releases/<tag>.md`）会自动签发正式 Release APK。

```text
lib/
├── data/                  # 53 项内置动作库、默认每周固定模板
├── models/                # 每日训练、模板、个人动作库、饮食与身体数据模型
├── pages/                 # 训练、模板工作室、动作库、我的、趋势/PR、饮食日记
├── services/              # 串行持久化、迁移、schema 3 备份校验、汇总、计时与领域信号
├── theme/                 # 6 套流光极光明暗主题与通用组件主题
├── widgets/               # 周历条、毛玻璃菜单/弹窗/表单、肌群剪影、趋势图、水滴导航
└── main.dart              # 应用入口与版本定义
```

本项目基于 [MIT License](LICENSE) 开源。应用图标源文件位于 `assets/branding/qingyang-icon.svg`。

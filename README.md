<div align="center">
  <img src="assets/branding/bodyrecomp-icon.png" alt="BodyRecomp 图标" width="112">

# BodyRecomp｜自由组合的健身记录

每天按实际情况搭建训练积木，用模板作参考，同时记录饮食和身体变化。Android 本地应用，无需注册。

[![构建状态](https://github.com/YXX168/BodyRecomp/actions/workflows/build.yml/badge.svg)](https://github.com/YXX168/BodyRecomp/actions/workflows/build.yml)
[![源码版本](https://img.shields.io/badge/源码-v7.0.0%2B81_预览-2563EB)](CHANGELOG.md)
[![许可](https://img.shields.io/badge/许可-MIT-059669)](LICENSE)
</div>

## 每天怎么用

1. **看参考**：默认周一推、周二拉、周三休息、周四腿与核心、周末恢复；每一天的参考模板都能修改。
2. **搭积木**：搜索动作，或从任意模板勾选项目混搭，或添加自定义项目。每个项目可以改组数、次数 / 时长、休息与说明，也能上下移动、移除和撤销移除。
3. **记实际**：点标题只展开说明，通过独立按钮完成一组或撤销上一组。允许只练模板的一部分，或在参考休息日训练。过去的日期可以补记，实际记录不会每周清空。
4. **存模板**：把当天组合存成模板；模板可增删和调整项目。修改模板不会改变已经保存的每日记录。

组间计时默认手动启动，卡片随页面正常滚动，不悬浮遮挡动作。可增加 30 秒或结束；可在设置中主动开启完成一组后自动计时。补记过去日期与撤销操作不会自动启动计时。计时在底部页面切换期间保留，按截止时间计算；进程退出后不恢复，也不提供后台通知。

## 饮食与身体数据

- 早餐、午餐、练前加餐、晚餐与其他饮食分别展示参考，可填写实际吃了什么。参考内容不会自动记为已吃。
- 热量、蛋白质为选填，合计仅包含手动填写的数据；不预设个人热量目标。
- 保留体重、围度、个人资料、趋势图、六套主题和渐进超负荷参考。
- 月度和年度统计基于实际记录，完成至少一组的项目计入已练项目；已记录休息与未开始项目不计为训练。

## 数据与升级

数据保存在设备本地，无账号、广告、统计 SDK 或云端同步。设置中可导出 / 导入 JSON，支持合并、覆盖以及恢复上一次导入前备份。7.0 备份结构为 schema 3，支持读取旧 schema 1 / 2。

首次打开时，旧版当前记录周的进度按原始训练计划与 ISO 周日期转换为每日记录，保留旧动作快照，避免新模板将旧进度映射到其他动作。此前归档的月度统计保留；旧版没有保存的历史动作详情无法还原。旧的原始字段继续保存在备份中。

卸载或清除应用数据前，请先导出备份。新备份不能导入仅支持旧 schema 的版本。

## 安卓预览与正式版

当前源码是 7.0 重构预览，尚不表示已发布正式版。可在 [Actions](https://github.com/YXX168/BodyRecomp/actions) 的成功构建中下载调试附件（保存 14 天）；[Releases](https://github.com/YXX168/BodyRecomp/releases) 中的安装包请以各自标注版本为准。

预览 APK 使用包名 `com.body.recomp.preview`，显示为 **Body Recomp 预览**，可与旧正式版并存。两者数据独立，需要时先在旧版导出 JSON，再到预览版导入。正式包继续使用 `com.body.recomp` 和正式签名；不要为了安装调试包而卸载旧版。

## 开发与验证

环境：Flutter 3.41.6、Dart 3.11、Android SDK、JDK 17。

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-fatal-infos
flutter test
flutter build apk --debug --target-platform android-arm64
```

正式构建使用 `flutter build apk --release --target-platform android-arm64`，必须提供现有正式签名配置。CI 在 PR 上验证格式、静态分析、测试和调试构建；版本标签触发正式签名校验与发布。

```text
lib/
├── data/                  # 默认参考模板、旧计划迁移快照
├── models/                # 每日积木、模板、身体数据
├── pages/                 # 自由训练、模板管理、饮食记录
├── services/              # 持久化、迁移、备份、汇总、计时设置
├── widgets/               # 日期、项目选择器、表单
└── main.dart              # 入口、主题、记录与身体设置
```

本项目基于 [MIT License](LICENSE) 开源。

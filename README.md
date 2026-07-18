# BodyRecomp

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

一个基于 Flutter 的本地健身训练追踪应用。

## 功能

- 🏋️ 每周训练计划与动作完成记录
- ⏱️ 自动/手动组间休息计时，可加时或提前结束
- 📊 月度训练热力图和年度统计
- 👤 个人资料与 BMI 信息
- ⚖️ 体重历史与趋势
- 🎨 多套主题
- 💾 JSON 数据导入导出
- 🔒 SharedPreferences 本地持久化

## v6.9.0 新功能

v6.9.0 在既有训练与身体数据功能上新增：

- 完成动作后按计划自动启动组间休息计时，也可点击休息时间手动启动。
- 计时器支持增加 30 秒、提前结束和完成震动反馈。
- 完成整日训练后显示轻量完成反馈。
- 修复年度统计重复累计、月份快速切换数据串页和趋势图主题配色未更新。
- 增加休息时间解析、偏好持久化和训练统计回归测试。

## 下载

- GitHub Releases: https://github.com/YXX168/BodyRecomp/releases

## 本地验证

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter build apk --release
```

## 当前版本

- `v6.9.0+78`

## 技术栈

- Flutter
- Google Fonts
- SharedPreferences

---

MIT License

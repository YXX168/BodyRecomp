# BodyRecomp

一个基于 Flutter 的本地健身训练追踪应用。

## 功能

- 🏋️ 每周训练计划与动作完成记录
- 📊 月度训练热力图和年度统计
- 👤 个人资料与 BMI 信息
- ⚖️ 体重历史与趋势
- 🎨 多套主题
- 💾 JSON 数据导入导出
- 🔒 SharedPreferences 本地持久化

## v6.7.0 新功能

v6.7.0 在 v6.6.1 基础上新增：

- 动作训练日志的数据模型与本地存储，包括重量、组数、次数、RPE 和 Epley 1RM 估算。
- 体重和身体围度记录的按日更新、查询与删除。
- JSON 备份 schema v2 的校验、v6.6 备份迁移、导入前备份以及合并/覆盖导入。
- 训练页周一至周日横向滑动切换的基础交互。
- models、services、历史归档与横向滑动的单元/Widget 测试。

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

- `v6.7.0+72`

## 技术栈

- Flutter
- Google Fonts
- SharedPreferences

---

MIT License

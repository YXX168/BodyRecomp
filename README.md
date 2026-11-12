<div align="center">
  <img src="assets/branding/bodyrecomp-icon.png" alt="青阳图标" width="112">

# 青阳｜自由组合的健身记录

每天按实际情况搭建训练积木，用模板作参考，同时记录饮食和身体变化。Android 本地应用，无需注册。

[![构建状态](https://github.com/YXX168/BodyRecomp/actions/workflows/build.yml/badge.svg)](https://github.com/YXX168/BodyRecomp/actions/workflows/build.yml)
[![正式版](https://img.shields.io/github/v/release/YXX168/BodyRecomp?label=正式版&color=287454)](https://github.com/YXX168/BodyRecomp/releases/latest)
[![许可](https://img.shields.io/badge/许可-MIT-059669)](LICENSE)
</div>

[下载正式版 APK](https://github.com/YXX168/BodyRecomp/releases/latest) · [更新记录](CHANGELOG.md) · [反馈问题](https://github.com/YXX168/BodyRecomp/issues/new/choose)

## 每天怎么用

1. **看参考**：默认周一推、周二拉、周三休息、周四腿与核心、周末恢复；每一天的参考模板都能修改。
2. **搭积木**：从独立的 52 项动作库按部位挑选、搜索动作，或从任意模板勾选项目混搭，也可添加自定义项目。每个项目可以改组数、次数 / 时长、休息与说明，也能上下移动、移除和撤销移除。
3. **记实际**：点标题只展开说明，通过独立按钮完成一组或撤销上一组。允许只练模板的一部分，或在参考休息日训练。过去的日期可以补记，实际记录不会每周清空。
4. **存模板**：把当天组合存成模板；模板可增删和调整项目。修改模板不会改变已经保存的每日记录。

动作选择面板中，“全选 / 取消全选”只操作当前分类或当前搜索结果，其他分类的选择保留；“清空”才会移除全部待选项目。切换分类会回到列表顶部。动作库与已保存模板分开，更新动作库不改动模板和历史记录。

组间计时默认手动启动，计时期间显示在「青阳」旁的顶部药丸里；空闲、手动结束或归零后隐藏。出现与消失使用淡入淡出和轻微缩放，不挤动动作列表，计时每秒刷新不会重播动画。可增加 30 秒或结束，也可在设置中开启完成一组后自动计时。补记过去日期与撤销操作不会自动启动计时。切换训练、饮食、趋势、我的时继续计时；应用进入后台后暂停界面刷新，返回前台按截止时间校准。进程退出后不恢复，也不提供后台通知。

日期使用轻量文字入口，点击后再打开日历，主页面不展开整周日期。可前后切换记录日期，查看历史后可一键回到今天，不允许记录未来日期。

训练与饮食的日期滚动位置分别保留，切换主页面保留已选日期与展开状态。

## 饮食与身体数据

- 早餐、午餐、练前加餐、晚餐与其他饮食分别展示参考，可填写实际吃了什么。参考内容不会自动记为已吃。
- 热量、蛋白质为选填，合计仅包含手动填写的数据；不预设个人热量目标。
- 保留体重、围度、个人资料、趋势图、六套主题和渐进超负荷参考。
- 身体数据表单校验有效正数；生日使用日期选择。模板未保存返回时可继续编辑、保存或放弃，移除项目支持撤销。
- 月度和年度统计基于实际记录，完成至少一组的项目计入已练项目；已记录休息与未开始项目不计为训练。

## 数据与升级

数据保存在设备本地，无账号、广告、统计 SDK 或云端同步。设置中可导出 / 导入 JSON，支持合并、覆盖以及恢复上一次导入前备份。7.0 备份结构为 schema 3，支持读取旧 schema 1 / 2。

首次打开时，旧版当前记录周的进度按原始训练计划与 ISO 周日期转换为每日记录，保留旧动作快照，避免新模板将旧进度映射到其他动作。此前归档的月度统计保留；旧版没有保存的历史动作详情无法还原。旧的原始字段继续保存在备份中。

卸载或清除应用数据前，请先导出备份。新备份不能导入仅支持旧 schema 的版本。

## 下载与升级

当前正式版为 **7.0.0（88）**，适用于 Android 7.0 及以上 ARM64 设备。从 [最新发布页](https://github.com/YXX168/BodyRecomp/releases/latest) 下载 `Qingyang-v7.0.0-arm64.apk`；同页附 SHA-256 校验文件。

正式应用显示为「青阳」，包名 `com.body.recomp`，沿用原正式签名，可以覆盖旧正式版。升级前先导出 JSON 备份，升级后会自动迁移可还原的旧记录。

此前的「青阳 预览」使用独立包名 `com.body.recomp.preview`，与正式版的数据互不相通。请先从预览版导出 JSON，再到正式版导入；核对记录后再移除预览版。

发布页保留当前正式版和上一正式版供回退；更早版本源码与历史更新仍可通过标签和 Git 历史查看。新版备份不能导入旧版，回退前应保留旧版备份。

## 开发与验证

环境：Flutter 3.41.6、Dart 3.11、Android SDK、JDK 17。

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-fatal-infos
flutter test
flutter build apk --profile --target-platform android-arm64
```

正式构建使用 `flutter build apk --release --target-platform android-arm64`，必须提供现有正式签名配置。CI 在 PR 上验证格式、静态分析、测试和性能预览构建。版本标签，或在 main 上手动填写与源码一致的发布标签，会触发正式签名校验与发布；发布文案维护在 `docs/releases/`。

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

应用图标使用浅杏粉、薄荷绿与奶油黄的简洁几何图形。源文件为 `assets/branding/qingyang-icon.svg`；安装 Pillow 后运行 `python3 tools/generate_launcher_icon.py` 可重建 Android 图标资源。

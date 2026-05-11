# ✅ ToDoList

> 一个基于 ArkTS 的 HarmonyOS 待办事项应用，聚焦任务管理和完成情况统计。

## ✨ 项目简介

`ToDoList` 是一个基于 **ArkTS** 的 HarmonyOS 待办应用，把"记下要做的事 → 设置截止与提醒 → 标记完成 → 回看完成情况"的日常流程收敛到一个轻量的移动端工具里。

- **ArkTS 单端应用**：纯前端，无需任何后端依赖，开箱即用
- **任务全生命周期**：新增 / 编辑 / 完成 / 删除，配合截止时间和提醒开关
- **可视化统计**：完成概览、连续完成天数、完成日历，以及 Canvas 自绘的近期完成趋势

适合以下使用者：

- 想用一个简单 App 管住自己每天要做的事的人
- 想看 HarmonyOS / ArkTS 状态管理 + 持久化 + Canvas 绘制示例的开发者
- 想要一个可继续扩展（提醒推送、云同步等）的脚手架工程

## 🚀 核心特性

📝 **任务管理**

- 新增 / 编辑 / 删除任务，标题最长 100 字、备注最长 200 字
- 圆圈点击切换完成态，已完成自动记录 `completedAt`
- 已完成 / 待完成分组展示，分组可折叠，列表内统一排序：已完成按完成时间倒序，未完成按截止时间升序
- 卡片右侧 `⋮` 菜单一键编辑、改截止时间、切提醒或删除

⏰ **截止时间与提醒**

- 截止时间支持选到日 + 时分，临期 / 逾期状态在卡片上有明显视觉提示
- 提醒开关与截止时间联动，关闭任务或时间已过会自动撤销调度
- `ReminderService` 作为统一的提醒收口层，已完成前台调度接口，系统通知能力在真机权限接入后即可挂上

📊 **统计分析**

- 今日完成概览：今日完成数、累计完成数、待完成数、连续完成天数
- 完成日历：按月查看每日完成数，可前后翻月
- 近期趋势：日 / 周 / 月 / 年 四种粒度的折线图，**Canvas 自绘**，含渐变填充、节点圆点、轴标签
- 数据全部从任务列表实时计算，无需额外维护统计表

💾 **本地持久化**

- 使用 `AppStorage` + `PersistentStorage` 把任务列表挂到 key `todo_tasks_storage`
- 首次启动写入一组默认任务，后续读写都会走 `sanitizeTask` 规范化
- 重启应用 / 重启设备后任务、完成态、截止时间、提醒时间都能恢复

## 🏗️ 架构概览

```text
ToDoList (ArkTS · HarmonyOS)
    │
    ├── pages/ToDoListPage         任务页 + 底部 Tab 容器、编辑抽屉、空状态
    │       ├── view/ToDoItem      任务卡片、完成圆圈、⋮ 操作菜单
    │       └── view/StatsTab      统计页（概览 / 日历 / 趋势 Canvas）
    │
    ├── viewmodel/DataModel        任务 CRUD、规范化、排序、统一写回 AppStorage
    ├── service/ReminderService    提醒调度接口层（内存态 + 真机接入预留）
    ├── model/Task                 Task / TaskDraft / 排序与克隆工具
    └── common/constant            通用样式常量
    │
    ▼
AppStorage  ⇄  PersistentStorage (key: todo_tasks_storage)
```

## 🛠️ 技术栈


| 模块    | 技术选型                                                               |
| ----- | ------------------------------------------------------------------ |
| UI 框架 | ArkTS · ArkUI 声明式语法 · `@Component` / `@Entry` / `@State` / `@Prop` |
| 状态管理  | `AppStorage` · `@Watch` 监听任务变化                                     |
| 持久化   | `PersistentStorage`（任务列表整体持久化）                                     |
| 绘图    | `CanvasRenderingContext2D`（趋势折线图、渐变、节点）                            |
| 构建    | DevEco Studio · hvigor · HarmonyOS SDK 6.1.0(23)                   |
| 测试    | `@ohos/hypium` 单元测试框架                                              |


## 📦 目录结构

```text
ToDoList/
├── AppScope/                       # 应用级配置（包名、版本、图标）
├── entry/
│   └── src/main/
│       ├── ets/
│       │   ├── common/constant/    # CommonConstant 通用样式常量
│       │   ├── entryability/       # EntryAbility 入口
│       │   ├── model/              # Task / TaskDraft / 排序工具
│       │   ├── pages/              # ToDoListPage 任务页 + Tab 容器
│       │   ├── service/            # ReminderService 提醒服务
│       │   ├── view/               # ToDoItem 卡片、StatsTab 统计页
│       │   └── viewmodel/          # DataModel 任务数据管理
│       ├── resources/              # 字符串、颜色、图标等资源
│       └── module.json5            # entry 模块清单
├── asset/                          # README 使用的运行截图
├── build-profile.json5             # 工程构建配置
├── oh-package.json5                # 依赖声明
└── LICENSE                         # Apache License 2.0
```

## 🖼️ 运行截图



## ⚡ 快速开始

### 1. 环境准备

- DevEco Studio（建议最新稳定版）
- HarmonyOS SDK **6.1.0(23)**，与 `build-profile.json5` 中的 `compileSdkVersion` 保持一致
- 模拟器或已开启开发者模式的 HarmonyOS 真机

### 2. 打开并同步工程

1. DevEco Studio 选择 **Open Project**，定位到本仓库根目录
2. 等待 hvigor 自动同步，确认依赖（包含 `@ohos/hypium`）拉取完成
3. 如提示 SDK 不匹配，按提示切换到 `6.1.0(23)` 或更高兼容版本

### 3. 运行到模拟器 / 真机

1. 选择 `entry` 模块作为运行目标
2. 连接模拟器或真机，点击 ▶ Run
3. 应用启动后默认进入任务页，已预置一组示例任务可直接体验

## 📖 怎么使用

1. **新增任务**：点击右下角 `+` 按钮，输入标题，可选设置截止时间（到时分）与提醒开关
2. **完成 / 取消完成**：点击卡片左侧圆圈，已完成的任务会被收进顶部 *已完成* 分组
3. **编辑 / 调整 / 删除**：点击卡片右侧 `⋮` 菜单，选择编辑、改截止时间、切换提醒或删除
4. **看统计**：切换到底部 *统计* Tab，可查看今日概览、完成日历，并切换 日 / 周 / 月 / 年 看完成趋势

## 🧪 本地验证

工程内含基于 `@ohos/hypium` 的单元测试样例：

```text
entry/src/ohosTest/ets/test/
├── List.test.ets
└── LocalUnit.test.ets
```

在 DevEco Studio 中右键 `ohosTest` 目录选择 **Run Tests**，或使用工程自带的测试入口运行即可。

## 📄 License

本项目采用 **Apache License 2.0** 开源协议，详见 [LICENSE](./LICENSE)。
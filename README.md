# ✅ ToDoList

> 一个基于 ArkTS 的 HarmonyOS 待办事项应用，聚焦任务管理和完成情况统计。

## ✨ 已有功能

- 📝 任务管理：支持新增、编辑、删除任务，以及标记完成 / 取消完成
- ⏰ 截止时间：支持为任务设置截止时间，并展示临期 / 逾期状态
- 🔔 提醒开关：支持为任务切换提醒状态
- 📚 分组展示：任务按已完成 / 待完成分组展示，支持折叠查看
- 📊 统计分析：提供今日完成概览、完成数、待完成数、连续完成天数、完成日历和近期趋势图
- 💾 本地持久化：任务数据会保存在本地，重新打开应用后仍可恢复

## 🖼️ 运行截图

<p align="center">
  <img src="asset/任务页.png" alt="任务页" width="30%" />
  <img src="asset/新增任务.png" alt="新增任务" width="30%" />
  <img src="asset/统计页.png" alt="统计页" width="30%" />
</p>

## 🚀 怎么运行

1. 使用 DevEco Studio 打开项目根目录。
2. 等待工程同步完成，并确保 HarmonyOS SDK 已正确安装。
3. 连接模拟器或真机，选择 `entry` 模块运行。
4. 应用启动后默认进入任务页，可以直接开始添加和管理任务。

## 📖 怎么使用

1. 点击右下角 `+` 按钮，输入任务内容，可选设置截止时间和提醒状态。
2. 在任务列表中点击左侧圆圈，可切换任务完成状态。
3. 点击任务卡片右侧 `⋮` 菜单，可编辑任务、修改截止时间、切换提醒或删除任务。
4. 切换到底部 `统计` 标签页，可查看完成概览、完成日历和近期趋势。

## 🗂️ 项目结构

- `entry/src/main/ets/pages/ToDoListPage.ets`：任务页与底部标签页入口
- `entry/src/main/ets/view/ToDoItem.ets`：任务卡片与快捷操作菜单
- `entry/src/main/ets/view/StatsTab.ets`：统计页界面与趋势图绘制
- `entry/src/main/ets/viewmodel/DataModel.ets`：任务数据管理与本地持久化
- `entry/src/main/ets/service/ReminderService.ets`：提醒状态同步逻辑
- `asset/`：README 使用的实际运行截图

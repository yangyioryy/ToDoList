# 待办列表（ArkTS）

## 项目说明

本项目已从原始 Codelab 示例改造成课程作业版待办应用，当前支持：

- 任务新增、编辑、删除、完成/取消完成
- `Task` 领域模型与统一排序
- 本地持久化恢复
- 顶部日期、完成进度、任务统计
- 截止日期、前台临期/逾期提示、提醒开关
- 逻辑层单元测试与本地 hvigor `test`

当前仓库里的 `screenshots/device/ToDoList.gif` 是原始示例素材，不再代表最终功能，以本 README 和本地运行结果为准。

## 功能清单

### 任务模型与排序

- 每条任务包含 `id`、`title`、`isCompleted`、`createdAt`、`dueAt`、`completedAt`、`reminderAt`
- 已完成任务排在前面，并按完成时间倒序
- 未完成任务排在后面，优先按截止时间升序，再按创建时间倒序

### 页面与交互

- 顶部展示欢迎语、当天日期、完成进度条、完成/待处理统计、提醒调度数量
- 中部提供内嵌新增/编辑表单，可输入标题并选择截止日期
- 列表支持滚动查看，空态与数据态会自动切换
- 卡片支持：
  - 点击标题区域切换完成/取消完成
  - 编辑标题
  - 修改截止日期
  - 删除任务
  - 打开/关闭提醒

### 提醒能力

- 已交付：前台临期/逾期可视化、提醒开关、提醒调度服务层
- 降级边界：当前版本未接真机系统通知权限与通知发布 API
- 结论：课程环境下可稳定演示前台提醒逻辑；若要做系统通知，需要在真机上补权限与通知接入

## 构建与测试

本机实际使用的是 DevEco 自带 hvigor 工具链：

```powershell
D:\DevEco Studio\tools\hvigor\bin\hvigorw.bat assembleHap
D:\DevEco Studio\tools\hvigor\bin\hvigorw.bat test
```

本次真实验证结果：

- `assembleHap`：通过
- `test`：通过
- 单测结果：`entry/.test/default/intermediates/test/coverage_data/test_result.txt`
- HTML 报告：`entry/.test/default/outputs/test/reports/index.html`

## 演示路线

建议课堂演示顺序：

1. 启动应用，展示顶部日期、统计与进度条。
2. 新增一条带截止日期的任务，观察任务立即进入列表。
3. 打开提醒，展示卡片上的提醒状态。
4. 点击任务标题区域，展示完成后自动排序到前面，并出现完成时间。
5. 编辑任务标题与截止日期，确认页面立即刷新。
6. 删除任务，确认列表和统计同步变化。
7. 杀进程后重新打开应用，展示任务、完成态、时间信息仍能恢复。
8. 运行 `hvigorw.bat test`，展示逻辑单测通过。

## 已知限制

1. `build-profile.json5` 没有签名配置，当前默认产物是未签名 HAP。
2. `DatePickerDialog.show` 已切到 `UIContext.showDatePickerDialog`，但系统通知仍未接入真机能力。
3. `hvigor test` 会输出来自 `@ohos/hypium` 依赖自身的 ArkTS warning，这些 warning 不影响当前测试通过。
4. 课程环境路径若包含受限制字符，hvigor 可能报项目路径检查错误；当前工作目录已验证可以构建。

## 环境要求

1. Stage 模型 HarmonyOS 工程。
2. 当前本机编译配置为 `6.1.0(23)`。
3. 推荐使用本机已验证的 DevEco / Harmony SDK 工具链。

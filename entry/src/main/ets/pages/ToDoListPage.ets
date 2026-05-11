/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License,Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import DataModel from '../viewmodel/DataModel';
import CommonConstants from '../common/constant/CommonConstant';
import ToDoItem from '../view/ToDoItem';
import StatsTab from '../view/StatsTab';
import { Task, TaskDraft } from '../model/Task';
import ReminderService from '../service/ReminderService';

@Entry
@Component
struct ToDoListPage {
  @State private totalTasks: Array<Task> = [];
  @State private draftTitle: string = '';
  @State private draftDueAt: number | null = null;
  @State private draftReminderOn: boolean = true;
  @State private draftRemark: string = '';
  @State private editingTaskId: string | null = null;
  @State private completedExpanded: boolean = true;
  @State private pendingExpanded: boolean = true;
  @State private showEditorSheet: boolean = false;
  @State private currentTab: number = 0;

  private static readonly WEEK_NAMES: Array<string> = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
  private static readonly TITLE_MAX_LENGTH: number = 100;
  private static readonly REMARK_MAX_LENGTH: number = 200;

  private padZero(value: number): string {
    return `${value}`.padStart(2, '0');
  }

  private getTodayText(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = now.getMonth() + 1;
    const day = now.getDate();
    const weekday = ToDoListPage.WEEK_NAMES[now.getDay()];
    return `今天是 ${year}年${month}月${day}日  ${weekday}`;
  }

  private getGreetingText(): string {
    const hour = new Date().getHours();
    if (hour < 5) {
      return 'Hi，夜深了！';
    }
    if (hour < 11) {
      return 'Hi，早上好！';
    }
    if (hour < 14) {
      return 'Hi，中午好！';
    }
    if (hour < 18) {
      return 'Hi，下午好！';
    }
    return 'Hi，晚上好！';
  }

  private getCompletedCount(): number {
    return this.totalTasks.filter((task: Task) => task.isCompleted).length;
  }

  private getPendingCount(): number {
    return this.totalTasks.length - this.getCompletedCount();
  }

  private getCompletedTasks(): Array<Task> {
    return this.totalTasks.filter((task: Task) => task.isCompleted);
  }

  private getPendingTasks(): Array<Task> {
    return this.totalTasks.filter((task: Task) => !task.isCompleted);
  }

  private getDraftDueText(): string {
    if (this.draftDueAt === null) {
      return '未设置';
    }
    const date = new Date(this.draftDueAt);
    return `${date.getMonth() + 1}月${date.getDate()}日 ${this.padZero(date.getHours())}:${this.padZero(date.getMinutes())}`;
  }

  private buildDraft(): TaskDraft {
    return {
      title: this.draftTitle,
      dueAt: this.draftDueAt,
      reminderAt: this.draftReminderOn ? this.draftDueAt : null
    };
  }

  private resetDraft(): void {
    this.draftTitle = '';
    this.draftDueAt = null;
    this.draftReminderOn = true;
    this.draftRemark = '';
    this.editingTaskId = null;
  }

  aboutToAppear() {
    this.refreshTasks();
    ReminderService.syncAll(this.totalTasks);
  }

  private refreshTasks(): void {
    this.totalTasks = DataModel.getTasks();
  }

  private handleToggleTask(taskId: string): void {
    this.getUIContext().animateToImmediately({ duration: 180, curve: Curve.EaseInOut }, () => {
      DataModel.toggleTask(taskId);
      this.refreshTasks();
      ReminderService.syncAll(this.totalTasks);
    });
  }

  private handleDeleteTask(taskId: string): void {
    this.getUIContext().animateToImmediately({ duration: 180, curve: Curve.EaseInOut }, () => {
      DataModel.deleteTask(taskId);
      ReminderService.cancelTask(taskId, 'task_deleted');
      if (this.editingTaskId === taskId) {
        this.resetDraft();
      }
      this.refreshTasks();
    });
  }

  private handleReminderToggle(taskId: string): void {
    const target = this.totalTasks.find((task: Task) => task.id === taskId);
    if (target === undefined) {
      return;
    }

    if (target.reminderAt === null) {
      const reminderAt = target.dueAt ?? (Date.now() + 60 * 60 * 1000);
      const nextTask = DataModel.updateTaskReminderAt(taskId, reminderAt);
      if (nextTask !== undefined) {
        ReminderService.syncTask(nextTask);
      }
    } else {
      DataModel.updateTaskReminderAt(taskId, null);
      ReminderService.cancelTask(taskId, 'reminder_disabled');
    }
    this.refreshTasks();
  }

  private handleEditTask(taskId: string): void {
    const target = this.totalTasks.find((task: Task) => task.id === taskId);
    if (target === undefined) {
      return;
    }

    this.editingTaskId = taskId;
    this.draftTitle = target.title;
    this.draftDueAt = target.dueAt;
    this.draftReminderOn = target.reminderAt !== null;
    this.draftRemark = '';
    this.showEditorSheet = true;
  }

  private handleOpenAdd(): void {
    this.resetDraft();
    this.showEditorSheet = true;
  }

  private handleSaveTask(): void {
    if (this.draftTitle.trim().length === 0) {
      return;
    }
    try {
      this.getUIContext().animateToImmediately({ duration: 220, curve: Curve.EaseInOut }, () => {
        if (this.editingTaskId === null) {
          const nextTask = DataModel.addTask(this.buildDraft());
          ReminderService.syncTask(nextTask);
        } else {
          const nextTask = DataModel.updateTask(this.editingTaskId, this.buildDraft());
          if (nextTask !== undefined) {
            ReminderService.syncTask(nextTask);
          }
        }
        this.showEditorSheet = false;
        this.resetDraft();
        this.refreshTasks();
      });
    } catch (error) {
      console.info(`save task failed: ${JSON.stringify(error)}`);
    }
  }

  private handlePickDraftDueAt(): void {
    const selectedDate = this.draftDueAt === null ? new Date() : new Date(this.draftDueAt);
    this.getUIContext().showDatePickerDialog({
      selected: selectedDate,
      onDateAccept: (date: Date) => {
        this.draftDueAt = date.getTime();
      }
    });
  }

  private handlePickTaskDueAt(taskId: string): void {
    const target = this.totalTasks.find((task: Task) => task.id === taskId);
    const selectedDate = target?.dueAt === null || target === undefined ? new Date() : new Date(target.dueAt);
    this.getUIContext().showDatePickerDialog({
      selected: selectedDate,
      onDateAccept: (date: Date) => {
        DataModel.updateTaskDueAt(taskId, date.getTime());
        const nextTask = DataModel.updateTaskReminderAt(taskId, date.getTime());
        if (nextTask !== undefined) {
          ReminderService.syncTask(nextTask);
        }
        this.refreshTasks();
      }
    });
  }

  @Builder greetingHeader() {
    Row({ space: 12 }) {
      Stack() {
        Text('🧑')
          .fontSize(26)
      }
      .width($r('app.float.avatar_size'))
      .height($r('app.float.avatar_size'))
      .borderRadius($r('app.float.avatar_size'))
      .backgroundColor($r('app.color.avatar_background'))

      Column({ space: 4 }) {
        Row({ space: 4 }) {
          Text(this.getGreetingText())
            .fontSize($r('app.float.greeting_font_size'))
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.title_primary'))
          Text('👋')
            .fontSize($r('app.float.greeting_font_size'))
        }

        Text(this.getTodayText())
          .fontSize($r('app.float.date_font_size'))
          .fontColor($r('app.color.meta_text'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Stack() {
        Text('📅')
          .fontSize(20)
      }
      .width($r('app.float.calendar_button_size'))
      .height($r('app.float.calendar_button_size'))
      .borderRadius(12)
      .backgroundColor($r('app.color.calendar_icon_bg'))
    }
    .width(CommonConstants.FULL_LENGTH)
    .padding({ left: 4, right: 4 })
  }

  @Builder progressCard() {
    Row() {
      Column({ space: 10 }) {
        Row() {
          Text($r('app.string.progress_card_label'))
            .fontSize($r('app.float.progress_label_font_size'))
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.title_primary'))
          Blank()
          Text(`${this.getCompletedCount()} / ${this.totalTasks.length}`)
            .fontSize($r('app.float.progress_count_font_size'))
            .fontColor($r('app.color.meta_text'))
        }
        .width(CommonConstants.FULL_LENGTH)

        Progress({
          value: this.getCompletedCount(),
          total: this.totalTasks.length === 0 ? 1 : this.totalTasks.length,
          type: ProgressType.Linear
        })
          .color($r('app.color.progress_fill'))
          .backgroundColor($r('app.color.progress_track'))
          .height($r('app.float.progress_height'))
          .borderRadius($r('app.float.progress_height'))
          .width(CommonConstants.FULL_LENGTH)

        Text($r('app.string.encouragement_text'))
          .fontSize($r('app.float.encouragement_font_size'))
          .fontColor($r('app.color.meta_text'))
          .width(CommonConstants.FULL_LENGTH)
          .textAlign(TextAlign.Start)
      }
      .layoutWeight(1)

      Text('🪴')
        .fontSize(44)
        .margin({ left: 12 })
    }
    .width(CommonConstants.FULL_LENGTH)
    .padding($r('app.float.hero_padding'))
    .borderRadius($r('app.float.card_radius'))
    .backgroundColor($r('app.color.card_background'))
    .shadow({ radius: 12, color: $r('app.color.card_shadow'), offsetX: 0, offsetY: 2 })
  }

  @Builder statsCard() {
    Column({ space: 14 }) {
      this.greetingHeader()
      this.progressCard()
    }
    .width(CommonConstants.FULL_LENGTH)
  }

  @Builder groupHeader(title: string, count: number, isCompleted: boolean, isExpanded: boolean, onToggle: () => void) {
    Row({ space: 8 }) {
      if (isCompleted) {
        Stack() {
          Text('✓')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width(20)
        .height(20)
        .borderRadius(20)
        .backgroundColor($r('app.color.completed_check'))
      } else {
        Stack()
          .width(20)
          .height(20)
          .borderRadius(20)
          .border({ width: 2, color: $r('app.color.tab_active') })
      }

      Text(`${title} (${count})`)
        .fontSize($r('app.float.group_title_font_size'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.title_primary'))

      Blank()

      Text(isExpanded ? '⌃' : '⌄')
        .fontSize(18)
        .fontColor($r('app.color.meta_text'))
        .rotate({ angle: isExpanded ? 180 : 0 })
    }
    .width(CommonConstants.FULL_LENGTH)
    .padding({ left: 4, right: 4, top: 4, bottom: 4 })
    .onClick(() => {
      this.getUIContext().animateToImmediately({ duration: 180, curve: Curve.EaseInOut }, () => {
        onToggle();
      });
    })
  }

  @Builder taskItem(item: Task) {
    ToDoItem({
      task: item,
      onToggle: (taskId: string) => {
        this.handleToggleTask(taskId);
      },
      onEditTask: (taskId: string) => {
        this.handleEditTask(taskId);
      },
      onDelete: (taskId: string) => {
        this.handleDeleteTask(taskId);
      },
      onEditDueDate: (taskId: string) => {
        this.handlePickTaskDueAt(taskId);
      },
      onReminderToggle: (taskId: string) => {
        this.handleReminderToggle(taskId);
      }
    })
  }

  @Builder emptyState() {
    Column({ space: 8 }) {
      Text('🗒️')
        .fontSize(40)
      Text($r('app.string.empty_tasks_title'))
        .fontSize($r('app.float.section_title_font_size'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.title_primary'))
      Text($r('app.string.empty_tasks_subtitle'))
        .fontSize($r('app.float.meta_font_size'))
        .fontColor($r('app.color.meta_text'))
        .textAlign(TextAlign.Center)
    }
    .width(CommonConstants.FULL_LENGTH)
    .padding($r('app.float.empty_state_padding'))
    .borderRadius($r('app.float.card_radius'))
    .backgroundColor($r('app.color.card_background'))
  }

  @Builder dueSection() {
    Row({ space: 10 }) {
      Text('📅')
        .fontSize(18)
      Text($r('app.string.sheet_due_label'))
        .fontSize($r('app.float.sheet_label_font_size'))
        .fontColor($r('app.color.title_primary'))
      Blank()
      Text(this.getDraftDueText())
        .fontSize($r('app.float.sheet_label_font_size'))
        .fontColor($r('app.color.meta_text'))
      Text('›')
        .fontSize(20)
        .fontColor($r('app.color.meta_text'))
    }
    .width(CommonConstants.FULL_LENGTH)
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .borderRadius($r('app.float.sheet_card_radius'))
    .backgroundColor($r('app.color.card_background'))
    .onClick(() => {
      this.handlePickDraftDueAt();
    })
  }

  @Builder reminderSection() {
    Row({ space: 10 }) {
      Text('🔔')
        .fontSize(18)
      Text($r('app.string.sheet_reminder_label'))
        .fontSize($r('app.float.sheet_label_font_size'))
        .fontColor($r('app.color.title_primary'))
      Blank()
      Text(this.draftReminderOn
        ? $r('app.string.sheet_reminder_value')
        : $r('app.string.sheet_reminder_off'))
        .fontSize($r('app.float.sheet_label_font_size'))
        .fontColor($r('app.color.meta_text'))
      Text('›')
        .fontSize(20)
        .fontColor($r('app.color.meta_text'))
    }
    .width(CommonConstants.FULL_LENGTH)
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .borderRadius($r('app.float.sheet_card_radius'))
    .backgroundColor($r('app.color.card_background'))
    .onClick(() => {
      this.draftReminderOn = !this.draftReminderOn;
    })
  }

  @Builder sheetHeader() {
    Row() {
      Text(this.editingTaskId === null
        ? $r('app.string.sheet_title_add')
        : $r('app.string.sheet_title_edit'))
        .fontSize($r('app.float.sheet_title_font_size'))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.title_primary'))
      Blank()
      Stack() {
        Text('✕')
          .fontSize(16)
          .fontColor($r('app.color.meta_text'))
      }
      .width(32)
      .height(32)
      .borderRadius(32)
      .backgroundColor($r('app.color.sheet_close_bg'))
      .onClick(() => {
        this.showEditorSheet = false;
      })
    }
    .width(CommonConstants.FULL_LENGTH)
  }

  @Builder sheetTitleInput() {
    Column({ space: 6 }) {
      TextArea({
        placeholder: '请输入任务内容...',
        text: this.draftTitle
      })
        .fontSize($r('app.float.sheet_label_font_size'))
        .backgroundColor($r('app.color.input_background'))
        .borderRadius($r('app.float.sheet_card_radius'))
        .height($r('app.float.sheet_textarea_height'))
        .width(CommonConstants.FULL_LENGTH)
        .maxLength(ToDoListPage.TITLE_MAX_LENGTH)
        .padding({ left: 14, right: 14, top: 12, bottom: 28 })
        .onChange((value: string) => {
          this.draftTitle = value;
        })

      Row() {
        Blank()
        Text(`${this.draftTitle.length} / ${ToDoListPage.TITLE_MAX_LENGTH}`)
          .fontSize($r('app.float.task_meta_font_size'))
          .fontColor($r('app.color.meta_text'))
      }
      .width(CommonConstants.FULL_LENGTH)
      .margin({ top: -22, right: 8 })
    }
  }

  @Builder sheetRemarkInput() {
    Column({ space: 6 }) {
      Row({ space: 8 }) {
        Text('📝')
          .fontSize(18)
        Text($r('app.string.sheet_remark_label'))
          .fontSize($r('app.float.sheet_label_font_size'))
          .fontColor($r('app.color.title_primary'))
      }
      .width(CommonConstants.FULL_LENGTH)

      TextArea({
        placeholder: '添加备注信息...',
        text: this.draftRemark
      })
        .fontSize($r('app.float.sheet_label_font_size'))
        .backgroundColor($r('app.color.input_background'))
        .borderRadius($r('app.float.sheet_card_radius'))
        .height($r('app.float.sheet_remark_height'))
        .width(CommonConstants.FULL_LENGTH)
        .maxLength(ToDoListPage.REMARK_MAX_LENGTH)
        .padding({ left: 14, right: 14, top: 12, bottom: 24 })
        .onChange((value: string) => {
          this.draftRemark = value;
        })

      Row() {
        Blank()
        Text(`${this.draftRemark.length} / ${ToDoListPage.REMARK_MAX_LENGTH}`)
          .fontSize($r('app.float.task_meta_font_size'))
          .fontColor($r('app.color.meta_text'))
      }
      .width(CommonConstants.FULL_LENGTH)
      .margin({ top: -22, right: 8 })
    }
  }

  @Builder editorSheet() {
    Column({ space: 16 }) {
      this.sheetHeader()
      this.sheetTitleInput()
      this.dueSection()
      this.reminderSection()
      this.sheetRemarkInput()

      Button(this.editingTaskId === null ? '添加任务' : '保存修改')
        .width(CommonConstants.FULL_LENGTH)
        .height($r('app.float.primary_button_height'))
        .fontSize($r('app.float.sheet_label_font_size'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.primary_button_text'))
        .backgroundColor(Color.Transparent)
        .borderRadius($r('app.float.sheet_card_radius'))
        .linearGradient({
          angle: 90,
          colors: [
            [$r('app.color.primary_gradient_start'), 0],
            [$r('app.color.primary_gradient_end'), 1]
          ]
        })
        .onClick(() => {
          this.handleSaveTask();
        })
    }
    .width(CommonConstants.FULL_LENGTH)
    .padding({
      left: $r('app.float.sheet_padding'),
      right: $r('app.float.sheet_padding'),
      top: 12,
      bottom: $r('app.float.sheet_padding')
    })
    .backgroundColor($r('app.color.sheet_background'))
  }

  @Builder floatingAddButton() {
    Stack() {
      Text('+')
        .fontSize($r('app.float.floating_button_icon_size'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.floating_button_text'))
    }
    .width($r('app.float.floating_button_size'))
    .height($r('app.float.floating_button_size'))
    .borderRadius($r('app.float.floating_button_size'))
    .backgroundColor($r('app.color.floating_button'))
    .shadow({ radius: 16, color: '#407C5CFF', offsetX: 0, offsetY: 6 })
    .onClick(() => {
      this.handleOpenAdd();
    })
    .bindSheet($$this.showEditorSheet, this.editorSheet(), {
      detents: [SheetSize.LARGE, SheetSize.MEDIUM],
      preferType: SheetType.BOTTOM,
      showClose: false,
      dragBar: true,
      backgroundColor: $r('app.color.sheet_background'),
      onDisappear: () => {
        this.resetDraft();
      }
    })
  }

  @Builder tasksTabContent() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Scroll() {
        Column({ space: CommonConstants.COLUMN_SPACE }) {
          this.statsCard()

          if (this.totalTasks.length === 0) {
            this.emptyState()
          } else {
            if (this.getCompletedCount() > 0) {
              this.groupHeader('已完成', this.getCompletedCount(), true, this.completedExpanded, () => {
                this.completedExpanded = !this.completedExpanded;
              })
              if (this.completedExpanded) {
                ForEach(this.getCompletedTasks(), (item: Task) => {
                  this.taskItem(item)
                }, (item: Task) => item.id)
              }
            }

            if (this.getPendingCount() > 0) {
              this.groupHeader('待完成', this.getPendingCount(), false, this.pendingExpanded, () => {
                this.pendingExpanded = !this.pendingExpanded;
              })
              if (this.pendingExpanded) {
                ForEach(this.getPendingTasks(), (item: Task) => {
                  this.taskItem(item)
                }, (item: Task) => item.id)
              }
            }
          }

          Blank().height(80)
        }
        .width(CommonConstants.FULL_LENGTH)
        .padding($r('app.float.page_padding'))
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .width(CommonConstants.FULL_LENGTH)
      .height(CommonConstants.FULL_LENGTH)

      Column() {
        this.floatingAddButton()
      }
      .margin({ right: 20, bottom: 20 })
    }
    .width(CommonConstants.FULL_LENGTH)
    .height(CommonConstants.FULL_LENGTH)
    .backgroundColor($r('app.color.page_background'))
  }

  @Builder placeholderTabContent(title: string, icon: string, description: string) {
    Column({ space: 12 }) {
      Text(icon)
        .fontSize(56)
      Text(title)
        .fontSize($r('app.float.sheet_title_font_size'))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.title_primary'))
      Text(description)
        .fontSize($r('app.float.meta_font_size'))
        .fontColor($r('app.color.meta_text'))
    }
    .width(CommonConstants.FULL_LENGTH)
    .height(CommonConstants.FULL_LENGTH)
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.page_background'))
  }

  @Builder tabBarItem(label: string, icon: string, index: number) {
    Column({ space: 4 }) {
      Text(icon)
        .fontSize($r('app.float.tab_icon_size'))
        .fontColor(this.currentTab === index
          ? $r('app.color.tab_active')
          : $r('app.color.tab_inactive'))
      Text(label)
        .fontSize($r('app.float.tab_label_font_size'))
        .fontWeight(this.currentTab === index ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.currentTab === index
          ? $r('app.color.tab_active')
          : $r('app.color.tab_inactive'))
    }
    .width(CommonConstants.FULL_LENGTH)
    .height($r('app.float.tab_bar_height'))
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.currentTab }) {
      TabContent() {
        this.tasksTabContent()
      }
      .tabBar(this.tabBarItem('任务', '✓', 0))

      TabContent() {
        StatsTab({ totalTasks: this.totalTasks })
      }
      .tabBar(this.tabBarItem('统计', '📊', 1))
    }
    .barHeight($r('app.float.tab_bar_height'))
    .barMode(BarMode.Fixed)
    .barBackgroundColor($r('app.color.tab_bar_background'))
    .scrollable(false)
    .onChange((index: number) => {
      this.currentTab = index;
    })
    .width(CommonConstants.FULL_LENGTH)
    .height(CommonConstants.FULL_LENGTH)
    .backgroundColor($r('app.color.page_background'))
  }
}

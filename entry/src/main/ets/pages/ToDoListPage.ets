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
import { Task, TaskDraft } from '../model/Task';
import ReminderService from '../service/ReminderService';

@Entry
@Component
struct ToDoListPage {
  @State private totalTasks: Array<Task> = [];
  @State private draftTitle: string = '';
  @State private draftDueAt: number | null = null;
  @State private editingTaskId: string | null = null;

  private static readonly WEEK_NAMES: Array<string> = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];

  private formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = `${date.getMonth() + 1}`.padStart(2, '0');
    const day = `${date.getDate()}`.padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  private formatTimestamp(timestamp: number | null): string {
    if (timestamp === null) {
      return '未设置';
    }
    return this.formatDate(new Date(timestamp));
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

  private buildDraft(): TaskDraft {
    return {
      title: this.draftTitle,
      dueAt: this.draftDueAt,
      reminderAt: this.draftDueAt
    };
  }

  private resetDraft(): void {
    this.draftTitle = '';
    this.draftDueAt = null;
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
  }

  private handleSaveTask(): void {
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

  @Builder editorCard() {
    Column({ space: 12 }) {
      Text(this.editingTaskId === null ? '新增任务' : '编辑任务')
        .fontSize($r('app.float.section_title_font_size'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.hero_title'))
        .width(CommonConstants.FULL_LENGTH)
        .textAlign(TextAlign.Start)

      TextInput({
        placeholder: '输入待办内容',
        text: this.draftTitle
      })
        .type(InputType.Normal)
        .fontSize($r('app.float.meta_font_size'))
        .backgroundColor($r('app.color.editor_input_background'))
        .borderRadius(CommonConstants.BORDER_RADIUS)
        .height($r('app.float.editor_input_height'))
        .onChange((value: string) => {
          this.draftTitle = value;
        })

      Row({ space: 10 }) {
        Button(`截止日期：${this.formatTimestamp(this.draftDueAt)}`)
          .layoutWeight(1)
          .height($r('app.float.action_button_height'))
          .backgroundColor($r('app.color.action_button_background'))
          .fontColor($r('app.color.action_button_text'))
          .borderRadius(CommonConstants.BORDER_RADIUS)
          .onClick(() => {
            this.handlePickDraftDueAt();
          })

        Button(this.draftDueAt === null ? '设提醒' : '清日期')
          .height($r('app.float.action_button_height'))
          .backgroundColor($r('app.color.action_button_background'))
          .fontColor($r('app.color.action_button_text'))
          .borderRadius(CommonConstants.BORDER_RADIUS)
          .onClick(() => {
            if (this.draftDueAt === null) {
              this.handlePickDraftDueAt();
            } else {
              this.draftDueAt = null;
            }
          })
      }
      .width(CommonConstants.FULL_LENGTH)

      Row({ space: 10 }) {
        Button(this.editingTaskId === null ? '添加任务' : '保存修改')
          .layoutWeight(1)
          .height($r('app.float.primary_button_height'))
          .backgroundColor($r('app.color.primary_button'))
          .fontColor($r('app.color.primary_button_text'))
          .borderRadius(CommonConstants.BORDER_RADIUS)
          .onClick(() => {
            this.handleSaveTask();
          })

        Button('重置')
          .height($r('app.float.primary_button_height'))
          .backgroundColor($r('app.color.action_button_background'))
          .fontColor($r('app.color.action_button_text'))
          .borderRadius(CommonConstants.BORDER_RADIUS)
          .onClick(() => {
            this.resetDraft();
          })
      }
      .width(CommonConstants.FULL_LENGTH)
    }
    .padding($r('app.float.editor_card_padding'))
    .borderRadius(CommonConstants.BORDER_RADIUS)
    .backgroundColor($r('app.color.editor_background'))
  }

  @Builder emptyState() {
    Column({ space: 8 }) {
      Text('还没有待办事项')
        .fontSize($r('app.float.section_title_font_size'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.hero_title'))
      Text('先在上面的输入框里添加一条今天想完成的任务。')
        .fontSize($r('app.float.meta_font_size'))
        .fontColor($r('app.color.meta_text'))
        .textAlign(TextAlign.Center)
    }
    .width(CommonConstants.FULL_LENGTH)
    .padding($r('app.float.empty_state_padding'))
    .borderRadius(CommonConstants.BORDER_RADIUS)
    .backgroundColor($r('app.color.editor_background'))
  }

  build() {
    Scroll() {
      Column({ space: CommonConstants.COLUMN_SPACE }) {
        this.statsCard()
        this.editorCard()

        Text($r('app.string.task_section_title'))
          .fontSize($r('app.float.section_title_font_size'))
          .fontWeight(FontWeight.Medium)
          .width(CommonConstants.FULL_LENGTH)
          .textAlign(TextAlign.Start)

        if (this.totalTasks.length === 0) {
          this.emptyState()
        } else {
          ForEach(this.totalTasks, (item: Task) => {
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
          }, (item: Task) => item.id)
        }
      }
      .width(CommonConstants.FULL_LENGTH)
      .padding($r('app.float.page_padding'))
    }
    .scrollable(ScrollDirection.Vertical)
    .width(CommonConstants.FULL_LENGTH)
    .height(CommonConstants.FULL_LENGTH)
    .backgroundColor($r('app.color.page_background'))
  }
}

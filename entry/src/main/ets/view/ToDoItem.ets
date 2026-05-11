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

import CommonConstants from '../common/constant/CommonConstant';
import { Task } from '../model/Task';

type DueStatus = 'completed' | 'overdue' | 'due_soon' | 'normal';

@Component
export default struct ToDoItem {
  task: Task = {
    id: '',
    title: '',
    isCompleted: false,
    createdAt: 0,
    dueAt: null,
    completedAt: null,
    reminderAt: null
  };
  onToggle?: (taskId: string) => void;
  onEditTask?: (taskId: string) => void;
  onDelete?: (taskId: string) => void;
  onEditDueDate?: (taskId: string) => void;
  onReminderToggle?: (taskId: string) => void;

  private padZero(value: number): string {
    return `${value}`.padStart(2, '0');
  }

  private formatHourMinute(timestamp: number): string {
    const date = new Date(timestamp);
    return `${this.padZero(date.getHours())}:${this.padZero(date.getMinutes())}`;
  }

  private formatDueText(timestamp: number): string {
    const now = new Date();
    const target = new Date(timestamp);
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    const yesterday = today - 24 * 60 * 60 * 1000;
    const targetDay = new Date(target.getFullYear(), target.getMonth(), target.getDate()).getTime();
    const hourMinute = this.formatHourMinute(timestamp);

    if (targetDay === today) {
      return `今天 ${hourMinute} 截止`;
    }
    if (targetDay === yesterday) {
      return `昨天 ${hourMinute} 截止`;
    }
    return `${target.getMonth() + 1}月${target.getDate()}日 ${hourMinute} 截止`;
  }

  private getDueStatus(): DueStatus {
    if (this.task.isCompleted) {
      return 'completed';
    }
    if (this.task.dueAt === null) {
      return 'normal';
    }
    const diff = this.task.dueAt - Date.now();
    if (diff < 0) {
      return 'overdue';
    }
    if (diff <= 24 * 60 * 60 * 1000) {
      return 'due_soon';
    }
    return 'normal';
  }

  private getCardBackgroundColor(): ResourceColor {
    if (this.getDueStatus() === 'overdue') {
      return $r('app.color.task_overdue_background');
    }
    return $r('app.color.card_background');
  }

  @Builder checkCircle() {
    Stack() {
      if (this.task.isCompleted) {
        Text('✓')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
    }
    .width($r('app.float.check_circle_size'))
    .height($r('app.float.check_circle_size'))
    .borderRadius($r('app.float.check_circle_size'))
    .backgroundColor(this.task.isCompleted ? $r('app.color.completed_check') : Color.Transparent)
    .border({
      width: this.task.isCompleted ? 0 : 2,
      color: $r('app.color.pending_circle')
    })
    .onClick(() => {
      if (this.onToggle !== undefined) {
        this.onToggle(this.task.id);
      }
    })
  }

  @Builder statusBadge() {
    if (this.getDueStatus() === 'due_soon') {
      Text($r('app.string.badge_due_soon'))
        .fontSize($r('app.float.badge_font_size'))
        .fontColor($r('app.color.badge_due_soon_text'))
        .backgroundColor($r('app.color.badge_due_soon_bg'))
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        .borderRadius($r('app.float.badge_border_radius'))
    } else if (this.getDueStatus() === 'overdue') {
      Row({ space: 2 }) {
        Text('⚠')
          .fontSize($r('app.float.badge_font_size'))
          .fontColor($r('app.color.badge_overdue_text'))
        Text($r('app.string.badge_overdue'))
          .fontSize($r('app.float.badge_font_size'))
          .fontColor($r('app.color.badge_overdue_text'))
      }
      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      .borderRadius($r('app.float.badge_border_radius'))
      .backgroundColor($r('app.color.badge_overdue_bg'))
    }
  }

  @Builder moreMenu() {
    Menu() {
      MenuItem({ content: '编辑任务' })
        .onClick(() => {
          if (this.onEditTask !== undefined) {
            this.onEditTask(this.task.id);
          }
        })
      MenuItem({ content: '改截止时间' })
        .onClick(() => {
          if (this.onEditDueDate !== undefined) {
            this.onEditDueDate(this.task.id);
          }
        })
      MenuItem({ content: this.task.reminderAt === null ? '开启提醒' : '关闭提醒' })
        .onClick(() => {
          if (this.onReminderToggle !== undefined) {
            this.onReminderToggle(this.task.id);
          }
        })
      MenuItem({ content: '删除任务' })
        .onClick(() => {
          if (this.onDelete !== undefined) {
            this.onDelete(this.task.id);
          }
        })
    }
  }

  @Builder metaRow() {
    if (this.task.isCompleted) {
      Text(`完成于 ${this.task.completedAt !== null ? this.formatHourMinute(this.task.completedAt) : '--:--'}`)
        .fontSize($r('app.float.task_meta_font_size'))
        .fontColor($r('app.color.completed_time_text'))
    } else if (this.task.dueAt !== null) {
      Row({ space: 4 }) {
        Text(this.getDueStatus() === 'overdue' ? '⏰' : '🕓')
          .fontSize($r('app.float.task_meta_font_size'))
        Text(this.formatDueText(this.task.dueAt))
          .fontSize($r('app.float.task_meta_font_size'))
          .fontColor(this.getDueStatus() === 'overdue'
            ? $r('app.color.overdue_meta_text')
            : $r('app.color.meta_text'))
      }
    } else {
      Text('未设置截止时间')
        .fontSize($r('app.float.task_meta_font_size'))
        .fontColor($r('app.color.meta_text'))
    }
  }

  build() {
    Row({ space: 12 }) {
      this.checkCircle()

      Column({ space: 4 }) {
        Text(this.task.title)
          .fontSize($r('app.float.task_title_font_size'))
          .fontWeight(CommonConstants.FONT_WEIGHT)
          .fontColor(this.task.isCompleted ? $r('app.color.meta_text') : $r('app.color.title_primary'))
          .decoration({ type: this.task.isCompleted ? TextDecorationType.LineThrough : TextDecorationType.None })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        this.metaRow()
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      this.statusBadge()

      Text('⋮')
        .fontSize(20)
        .fontColor($r('app.color.more_icon'))
        .width(24)
        .height(24)
        .textAlign(TextAlign.Center)
        .bindMenu(this.moreMenu())
    }
    .width(CommonConstants.FULL_LENGTH)
    .padding({
      left: $r('app.float.card_padding'),
      right: $r('app.float.card_padding'),
      top: 14,
      bottom: 14
    })
    .borderRadius($r('app.float.task_card_radius'))
    .backgroundColor(this.getCardBackgroundColor())
    .shadow({ radius: 8, color: $r('app.color.card_shadow'), offsetX: 0, offsetY: 1 })
    .transition(TransitionEffect.OPACITY)
  }
}

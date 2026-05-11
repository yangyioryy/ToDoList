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

  private formatDate(timestamp: number | null): string {
    if (timestamp === null) {
      return '未设置';
    }

    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = `${date.getMonth() + 1}`.padStart(2, '0');
    const day = `${date.getDate()}`.padStart(2, '0');
    const hour = `${date.getHours()}`.padStart(2, '0');
    const minute = `${date.getMinutes()}`.padStart(2, '0');
    return `${year}-${month}-${day} ${hour}:${minute}`;
  }

  private getDueStatusText(): string {
    if (this.task.isCompleted) {
      return `完成于 ${this.formatDate(this.task.completedAt)}`;
    }
    if (this.task.dueAt === null) {
      return '未设置截止时间';
    }

    const now = Date.now();
    const diff = this.task.dueAt - now;
    if (diff < 0) {
      return `已逾期 · ${this.formatDate(this.task.dueAt)}`;
    }
    if (diff <= 24 * 60 * 60 * 1000) {
      return `即将到期 · ${this.formatDate(this.task.dueAt)}`;
    }
    return `截止时间 · ${this.formatDate(this.task.dueAt)}`;
  }

  private getReminderText(): string {
    if (this.task.reminderAt === null) {
      return '提醒关闭';
    }
    return `提醒于 ${this.formatDate(this.task.reminderAt)}`;
  }

  private getCardBackgroundColor(): ResourceColor {
    if (!this.task.isCompleted && this.task.dueAt !== null) {
      const diff = this.task.dueAt - Date.now();
      if (diff < 0) {
        return $r('app.color.task_overdue_background');
      }
      if (diff <= 24 * 60 * 60 * 1000) {
        return $r('app.color.task_due_soon_background');
      }
    }
    return $r('app.color.start_window_background');
  }

  @Builder labelIcon(icon: Resource) {
    Image(icon)
      .objectFit(ImageFit.Contain)
      .width($r('app.float.checkbox_width'))
      .height($r('app.float.checkbox_width'))
      .margin({
        right: $r('app.float.checkbox_margin')
      })
  }

  @Builder actionButton(label: string, action?: () => void) {
    Button(label)
      .fontSize($r('app.float.meta_font_size'))
      .height($r('app.float.action_button_height'))
      .backgroundColor($r('app.color.action_button_background'))
      .fontColor($r('app.color.action_button_text'))
      .borderRadius(CommonConstants.BORDER_RADIUS)
      .padding({
        left: 10,
        right: 10
      })
      .onClick(() => {
        if (action !== undefined) {
          action();
        }
      })
  }

  build() {
    Column({ space: 10 }) {
      Row() {
        if (this.task.isCompleted) {
          this.labelIcon($r('app.media.ic_ok'));
        } else {
          this.labelIcon($r('app.media.ic_default'));
        }

        Column({ space: 6 }) {
          Text(this.task.title)
            .fontSize($r('app.float.item_font_size'))
            .fontWeight(CommonConstants.FONT_WEIGHT)
            .opacity(this.task.isCompleted ? CommonConstants.OPACITY_COMPLETED : CommonConstants.OPACITY_DEFAULT)
            .decoration({ type: this.task.isCompleted ? TextDecorationType.LineThrough : TextDecorationType.None })

          Text(this.getDueStatusText())
            .fontSize($r('app.float.meta_font_size'))
            .fontColor($r('app.color.meta_text'))

          Text(this.getReminderText())
            .fontSize($r('app.float.meta_font_size'))
            .fontColor(this.task.reminderAt === null ? $r('app.color.meta_text') : $r('app.color.reminder_text'))
        }
        .layoutWeight(1)
      }
      .alignItems(VerticalAlign.Top)
      .onClick(() => {
        if (this.onToggle !== undefined) {
          this.onToggle(this.task.id);
        }
      })

      Row({ space: 8 }) {
        this.actionButton('编辑', () => {
          if (this.onEditTask !== undefined) {
            this.onEditTask(this.task.id);
          }
        })
        this.actionButton(this.task.reminderAt === null ? '开提醒' : '关提醒', () => {
          if (this.onReminderToggle !== undefined) {
            this.onReminderToggle(this.task.id);
          }
        })
        this.actionButton('改日期', () => {
          if (this.onEditDueDate !== undefined) {
            this.onEditDueDate(this.task.id);
          }
        })
        this.actionButton('删除', () => {
          if (this.onDelete !== undefined) {
            this.onDelete(this.task.id);
          }
        })
      }
      .justifyContent(FlexAlign.End)
      .width(CommonConstants.FULL_LENGTH)
    }
    .borderRadius(CommonConstants.BORDER_RADIUS)
    .backgroundColor(this.getCardBackgroundColor())
    .width(CommonConstants.LIST_DEFAULT_WIDTH)
    .padding($r('app.float.card_padding'))
    .transition(TransitionEffect.OPACITY)
  }
}

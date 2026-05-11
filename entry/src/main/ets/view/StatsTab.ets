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

type RangeKey = 'day' | 'week' | 'month' | 'year';

interface RangeOption {
  key: RangeKey;
  label: ResourceStr;
}

@Component
export default struct StatsTab {
  @Prop totalTasks: Array<Task> = [];
  @State private currentRange: RangeKey = 'day';

  private static readonly RANGE_OPTIONS: Array<RangeOption> = [
    { key: 'day', label: $r('app.string.range_day') },
    { key: 'week', label: $r('app.string.range_week') },
    { key: 'month', label: $r('app.string.range_month') },
    { key: 'year', label: $r('app.string.range_year') }
  ];

  private getDateKey(timestamp: number): string {
    const d = new Date(timestamp);
    return `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
  }

  private getCompletedMap(): Map<string, number> {
    const map = new Map<string, number>();
    this.totalTasks.forEach((task: Task) => {
      if (task.isCompleted && task.completedAt !== null) {
        const key = this.getDateKey(task.completedAt);
        map.set(key, (map.get(key) ?? 0) + 1);
      }
    });
    return map;
  }

  private getTodayCompletedCount(): number {
    const todayKey = this.getDateKey(Date.now());
    return this.getCompletedMap().get(todayKey) ?? 0;
  }

  private getCompletedCount(): number {
    return this.totalTasks.filter((task: Task) => task.isCompleted).length;
  }

  private getPendingCount(): number {
    return this.totalTasks.filter((task: Task) => !task.isCompleted).length;
  }

  private getStreakDays(): number {
    const map = this.getCompletedMap();
    const cur = new Date();
    let streak = 0;
    while (true) {
      const key = `${cur.getFullYear()}-${cur.getMonth() + 1}-${cur.getDate()}`;
      if ((map.get(key) ?? 0) > 0) {
        streak++;
        cur.setDate(cur.getDate() - 1);
      } else {
        break;
      }
    }
    return streak;
  }

  private getTodayDateText(): string {
    const d = new Date();
    return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日`;
  }

  private getTodayPercent(): number {
    if (this.totalTasks.length === 0) {
      return 0;
    }
    return Math.round(this.getTodayCompletedCount() / this.totalTasks.length * 100);
  }

  @Builder header() {
    Text($r('app.string.stats_page_title'))
      .fontSize($r('app.float.stats_page_title_font_size'))
      .fontWeight(FontWeight.Bold)
      .fontColor($r('app.color.title_primary'))
      .width(CommonConstants.FULL_LENGTH)
      .textAlign(TextAlign.Start)
  }

  @Builder rangeSelector() {
    Row({ space: 10 }) {
      Row() {
        ForEach(StatsTab.RANGE_OPTIONS, (option: RangeOption) => {
          Text(option.label)
            .fontSize($r('app.float.segment_font_size'))
            .fontWeight(this.currentRange === option.key ? FontWeight.Medium : FontWeight.Regular)
            .fontColor(this.currentRange === option.key
              ? $r('app.color.title_primary')
              : $r('app.color.segment_inactive_text'))
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
            .height(28)
            .padding({ top: 4, bottom: 4 })
            .borderRadius(8)
            .backgroundColor(this.currentRange === option.key
              ? $r('app.color.segment_active_bg')
              : Color.Transparent)
            .onClick(() => {
              this.currentRange = option.key;
            })
        }, (option: RangeOption) => option.key)
      }
      .layoutWeight(1)
      .height($r('app.float.segment_height'))
      .padding(4)
      .borderRadius(12)
      .backgroundColor($r('app.color.segment_track_bg'))

      Stack() {
        Text('📅').fontSize(20)
      }
      .width($r('app.float.calendar_button_size'))
      .height($r('app.float.calendar_button_size'))
      .borderRadius(12)
      .backgroundColor($r('app.color.calendar_icon_bg'))
    }
    .width(CommonConstants.FULL_LENGTH)
  }

  @Builder todayOverviewCard() {
    Row() {
      Column({ space: 6 }) {
        Text($r('app.string.today_summary_title'))
          .fontSize($r('app.float.progress_label_font_size'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.title_primary'))

        Text(this.getTodayDateText())
          .fontSize($r('app.float.date_font_size'))
          .fontColor($r('app.color.meta_text'))

        Row({ space: 4 }) {
          Text(`${this.getTodayCompletedCount()}`)
            .fontSize($r('app.float.today_total_number_font_size'))
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.stats_big_number'))
          Text(`/${this.totalTasks.length}`)
            .fontSize($r('app.float.today_total_unit_font_size'))
            .fontColor($r('app.color.meta_text'))
            .margin({ bottom: 6 })
        }
        .alignItems(VerticalAlign.Bottom)
        .margin({ top: 6 })

        Text($r('app.string.today_summary_total_label'))
          .fontSize($r('app.float.task_meta_font_size'))
          .fontColor($r('app.color.meta_text'))

        Row({ space: 8 }) {
          Stack({ alignContent: Alignment.Start }) {
            Row()
              .width(CommonConstants.FULL_LENGTH)
              .height(8)
              .borderRadius(8)
              .backgroundColor($r('app.color.progress_track'))
            Row()
              .width(`${this.getTodayPercent()}%`)
              .height(8)
              .borderRadius(8)
              .linearGradient({
                angle: 90,
                colors: [
                  [$r('app.color.primary_gradient_start'), 0],
                  [$r('app.color.primary_gradient_end'), 1]
                ]
              })
          }
          .layoutWeight(1)
          .height(8)

          Text(`${this.getTodayPercent()}%`)
            .fontSize($r('app.float.task_meta_font_size'))
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.stats_purple_text'))
        }
        .width(CommonConstants.FULL_LENGTH)
        .margin({ top: 10 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('📋')
        .fontSize(56)
        .margin({ left: 8 })
    }
    .width(CommonConstants.FULL_LENGTH)
    .padding($r('app.float.hero_padding'))
    .borderRadius($r('app.float.card_radius'))
    .backgroundColor($r('app.color.stats_card_background'))
    .shadow({ radius: 12, color: $r('app.color.card_shadow'), offsetX: 0, offsetY: 2 })
  }

  @Builder completedBox() {
    Column({ space: 6 }) {
      Row({ space: 8 }) {
        Stack() {
          Text('✓')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width(22)
        .height(22)
        .borderRadius(22)
        .backgroundColor($r('app.color.completed_check'))

        Text(`${this.getCompletedCount()}`)
          .fontSize($r('app.float.stats_box_number_font_size'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.title_primary'))
      }

      Text($r('app.string.stats_box_completed'))
        .fontSize($r('app.float.stats_box_label_font_size'))
        .fontColor($r('app.color.meta_text'))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .padding(14)
    .borderRadius($r('app.float.task_card_radius'))
    .backgroundColor($r('app.color.stats_card_background'))
    .shadow({ radius: 8, color: $r('app.color.card_shadow'), offsetX: 0, offsetY: 1 })
  }

  @Builder pendingBox() {
    Column({ space: 6 }) {
      Row({ space: 8 }) {
        Stack()
          .width(22)
          .height(22)
          .borderRadius(22)
          .border({ width: 2, color: $r('app.color.stats_box_pending_circle') })

        Text(`${this.getPendingCount()}`)
          .fontSize($r('app.float.stats_box_number_font_size'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.title_primary'))
      }

      Text($r('app.string.stats_box_pending'))
        .fontSize($r('app.float.stats_box_label_font_size'))
        .fontColor($r('app.color.meta_text'))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .padding(14)
    .borderRadius($r('app.float.task_card_radius'))
    .backgroundColor($r('app.color.stats_card_background'))
    .shadow({ radius: 8, color: $r('app.color.card_shadow'), offsetX: 0, offsetY: 1 })
  }

  @Builder streakBox() {
    Column({ space: 6 }) {
      Row({ space: 8 }) {
        Stack() {
          Text('★')
            .fontSize(13)
            .fontColor($r('app.color.stats_box_streak_star'))
        }
        .width(22)
        .height(22)
        .borderRadius(22)
        .backgroundColor($r('app.color.stats_box_streak_bg'))

        Text(`${this.getStreakDays()}`)
          .fontSize($r('app.float.stats_box_number_font_size'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.title_primary'))
      }

      Text($r('app.string.stats_box_streak'))
        .fontSize($r('app.float.stats_box_label_font_size'))
        .fontColor($r('app.color.meta_text'))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .padding(14)
    .borderRadius($r('app.float.task_card_radius'))
    .backgroundColor($r('app.color.stats_card_background'))
    .shadow({ radius: 8, color: $r('app.color.card_shadow'), offsetX: 0, offsetY: 1 })
  }

  @Builder statBoxRow() {
    Row({ space: 10 }) {
      this.completedBox()
      this.pendingBox()
      this.streakBox()
    }
    .width(CommonConstants.FULL_LENGTH)
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        this.header()
        this.rangeSelector()
        this.todayOverviewCard()
        this.statBoxRow()
        Blank().height(60)
      }
      .width(CommonConstants.FULL_LENGTH)
      .padding($r('app.float.page_padding'))
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .width(CommonConstants.FULL_LENGTH)
    .height(CommonConstants.FULL_LENGTH)
    .backgroundColor($r('app.color.page_background'))
  }
}

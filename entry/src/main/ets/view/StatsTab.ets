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

interface CalendarCell {
  day: number;
  isCurrentMonth: boolean;
  isToday: boolean;
  completedCount: number;
  dateKey: string;
}

interface TrendPoint {
  x: number;
  y: number;
}

@Component
export default struct StatsTab {
  @Prop @Watch('onTasksChanged') totalTasks: Array<Task> = [];
  @State private currentRange: RangeKey = 'day';
  @State private calendarYear: number = new Date().getFullYear();
  @State private calendarMonth: number = new Date().getMonth();

  private trendSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private trendCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.trendSettings);
  private isTrendCanvasReady: boolean = false;

  private static readonly RANGE_OPTIONS: Array<RangeOption> = [
    { key: 'day', label: $r('app.string.range_day') },
    { key: 'week', label: $r('app.string.range_week') },
    { key: 'month', label: $r('app.string.range_month') },
    { key: 'year', label: $r('app.string.range_year') }
  ];

  private static readonly WEEKDAY_LABELS: Array<string> = ['日', '一', '二', '三', '四', '五', '六'];

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

  private getCalendarCells(): Array<CalendarCell> {
    const firstDay = new Date(this.calendarYear, this.calendarMonth, 1);
    const startWeekday = firstDay.getDay();
    const daysInMonth = new Date(this.calendarYear, this.calendarMonth + 1, 0).getDate();
    const daysInPrevMonth = new Date(this.calendarYear, this.calendarMonth, 0).getDate();

    const completedMap = this.getCompletedMap();
    const todayKey = this.getDateKey(Date.now());
    const cells: Array<CalendarCell> = [];

    for (let i = startWeekday - 1; i >= 0; i--) {
      const day = daysInPrevMonth - i;
      const prevMonth = this.calendarMonth - 1;
      const adjustedYear = prevMonth < 0 ? this.calendarYear - 1 : this.calendarYear;
      const adjustedMonth = (prevMonth + 12) % 12;
      const dateKey = `${adjustedYear}-${adjustedMonth + 1}-${day}`;
      cells.push({
        day,
        isCurrentMonth: false,
        isToday: false,
        completedCount: completedMap.get(dateKey) ?? 0,
        dateKey
      });
    }

    for (let d = 1; d <= daysInMonth; d++) {
      const dateKey = `${this.calendarYear}-${this.calendarMonth + 1}-${d}`;
      cells.push({
        day: d,
        isCurrentMonth: true,
        isToday: dateKey === todayKey,
        completedCount: completedMap.get(dateKey) ?? 0,
        dateKey
      });
    }

    while (cells.length < 42) {
      const offset = cells.length - startWeekday - daysInMonth + 1;
      const nextMonth = this.calendarMonth + 1;
      const adjustedYear = nextMonth > 11 ? this.calendarYear + 1 : this.calendarYear;
      const adjustedMonth = nextMonth % 12;
      const dateKey = `${adjustedYear}-${adjustedMonth + 1}-${offset}`;
      cells.push({
        day: offset,
        isCurrentMonth: false,
        isToday: false,
        completedCount: completedMap.get(dateKey) ?? 0,
        dateKey
      });
    }

    return cells;
  }

  private goToPrevMonth(): void {
    if (this.calendarMonth === 0) {
      this.calendarMonth = 11;
      this.calendarYear = this.calendarYear - 1;
    } else {
      this.calendarMonth = this.calendarMonth - 1;
    }
  }

  private goToNextMonth(): void {
    if (this.calendarMonth === 11) {
      this.calendarMonth = 0;
      this.calendarYear = this.calendarYear + 1;
    } else {
      this.calendarMonth = this.calendarMonth + 1;
    }
  }

  private backToToday(): void {
    const now = new Date();
    this.calendarYear = now.getFullYear();
    this.calendarMonth = now.getMonth();
  }

  private padZero(value: number): string {
    return `${value}`.padStart(2, '0');
  }

  private getRecentTrend(days: number): Array<number> {
    const completedMap = this.getCompletedMap();
    const result: Array<number> = [];
    const now = new Date();
    for (let i = days - 1; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i);
      const key = `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
      result.push(completedMap.get(key) ?? 0);
    }
    return result;
  }

  private getRecentTrendLabels(days: number): Array<string> {
    const result: Array<string> = [];
    const now = new Date();
    for (let i = days - 1; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i);
      result.push(`${this.padZero(d.getMonth() + 1)}/${this.padZero(d.getDate())}`);
    }
    return result;
  }

  private onTasksChanged(): void {
    this.drawTrend();
  }

  private drawTrend(): void {
    if (!this.isTrendCanvasReady) {
      return;
    }
    const ctx = this.trendCtx;
    const width = ctx.width;
    const height = ctx.height;
    if (width <= 0 || height <= 0) {
      return;
    }

    ctx.clearRect(0, 0, width, height);

    const data = this.getRecentTrend(7);
    const labels = this.getRecentTrendLabels(7);
    let maxValue = 10;
    data.forEach((v: number) => {
      if (v > maxValue) {
        maxValue = v;
      }
    });

    const paddingLeft = 30;
    const paddingRight = 12;
    const paddingTop = 14;
    const paddingBottom = 28;
    const innerW = width - paddingLeft - paddingRight;
    const innerH = height - paddingTop - paddingBottom;

    ctx.font = '10vp sans-serif';
    ctx.strokeStyle = '#EEF0F3';
    ctx.lineWidth = 1;
    ctx.fillStyle = '#9CA3AF';
    const yLabels: Array<number> = [0, 5, 10];
    yLabels.forEach((v: number) => {
      const y = paddingTop + innerH * (1 - v / maxValue);
      ctx.beginPath();
      ctx.moveTo(paddingLeft, y);
      ctx.lineTo(paddingLeft + innerW, y);
      ctx.stroke();
      ctx.fillText(`${v}`, 6, y + 4);
    });

    const points: Array<TrendPoint> = [];
    data.forEach((value: number, i: number) => {
      points.push({
        x: paddingLeft + (innerW / (data.length - 1)) * i,
        y: paddingTop + innerH * (1 - value / maxValue)
      });
    });

    const gradient = ctx.createLinearGradient(0, paddingTop, 0, paddingTop + innerH);
    gradient.addColorStop(0, 'rgba(124, 92, 255, 0.35)');
    gradient.addColorStop(1, 'rgba(124, 92, 255, 0.02)');
    ctx.fillStyle = gradient;
    ctx.beginPath();
    ctx.moveTo(points[0].x, paddingTop + innerH);
    points.forEach((p: TrendPoint) => {
      ctx.lineTo(p.x, p.y);
    });
    ctx.lineTo(points[points.length - 1].x, paddingTop + innerH);
    ctx.closePath();
    ctx.fill();

    ctx.strokeStyle = '#7C5CFF';
    ctx.lineWidth = 2;
    ctx.beginPath();
    points.forEach((p: TrendPoint, i: number) => {
      if (i === 0) {
        ctx.moveTo(p.x, p.y);
      } else {
        ctx.lineTo(p.x, p.y);
      }
    });
    ctx.stroke();

    ctx.fillStyle = '#7C5CFF';
    points.forEach((p: TrendPoint) => {
      ctx.beginPath();
      ctx.arc(p.x, p.y, 3.5, 0, Math.PI * 2);
      ctx.fill();
    });

    ctx.fillStyle = '#9CA3AF';
    ctx.textAlign = 'center';
    labels.forEach((label: string, i: number) => {
      ctx.fillText(label, points[i].x, height - 8);
    });
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

  @Builder calendarHeader() {
    Row() {
      Row({ space: 8 }) {
        Text('‹')
          .fontSize(20)
          .fontColor($r('app.color.meta_text'))
          .width(24)
          .height(24)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.goToPrevMonth();
          })

        Text(`${this.calendarYear}年${this.calendarMonth + 1}月`)
          .fontSize($r('app.float.calendar_month_font_size'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.title_primary'))

        Text('›')
          .fontSize(20)
          .fontColor($r('app.color.meta_text'))
          .width(24)
          .height(24)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.goToNextMonth();
          })
      }

      Blank()

      Text($r('app.string.calendar_back_today'))
        .fontSize($r('app.float.back_today_font_size'))
        .fontColor($r('app.color.sub_text'))
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .borderRadius(12)
        .backgroundColor($r('app.color.back_to_today_bg'))
        .onClick(() => {
          this.backToToday();
        })
    }
    .width(CommonConstants.FULL_LENGTH)
  }

  @Builder calendarWeekdayRow() {
    Row() {
      ForEach(StatsTab.WEEKDAY_LABELS, (label: string) => {
        Text(label)
          .fontSize($r('app.float.calendar_weekday_font_size'))
          .fontColor($r('app.color.calendar_weekday_text'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }, (label: string) => label)
    }
    .width(CommonConstants.FULL_LENGTH)
  }

  @Builder calendarCell(cell: CalendarCell) {
    Column() {
      if (cell.isToday) {
        Stack() {
          Text(`${cell.day}`)
            .fontSize($r('app.float.calendar_day_font_size'))
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.calendar_today_text'))
        }
        .width($r('app.float.calendar_today_circle_size'))
        .height($r('app.float.calendar_today_circle_size'))
        .borderRadius($r('app.float.calendar_today_circle_size'))
        .backgroundColor($r('app.color.calendar_today_bg'))
      } else {
        Text(`${cell.day}`)
          .fontSize($r('app.float.calendar_day_font_size'))
          .fontColor(cell.isCurrentMonth
            ? $r('app.color.title_primary')
            : $r('app.color.calendar_other_month_text'))
          .height($r('app.float.calendar_today_circle_size'))
          .textAlign(TextAlign.Center)
      }

      if (cell.completedCount > 0 && cell.isCurrentMonth) {
        Text(`${cell.completedCount}`)
          .fontSize($r('app.float.calendar_day_count_font_size'))
          .fontColor($r('app.color.calendar_dot'))
          .margin({ top: 2 })
      } else {
        Text(' ')
          .fontSize($r('app.float.calendar_day_count_font_size'))
          .margin({ top: 2 })
      }
    }
    .width(CommonConstants.FULL_LENGTH)
    .height($r('app.float.calendar_cell_size'))
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  @Builder calendarGrid() {
    Grid() {
      ForEach(this.getCalendarCells(), (cell: CalendarCell) => {
        GridItem() {
          this.calendarCell(cell)
        }
      }, (cell: CalendarCell) => cell.dateKey)
    }
    .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
    .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr')
    .rowsGap(4)
    .columnsGap(0)
    .width(CommonConstants.FULL_LENGTH)
    .height(260)
  }

  @Builder calendarCard() {
    Column({ space: 12 }) {
      this.calendarHeader()
      this.calendarWeekdayRow()
      this.calendarGrid()

      Row({ space: 6 }) {
        Text('·')
          .fontSize(14)
          .fontColor($r('app.color.calendar_dot'))
        Text($r('app.string.calendar_hint'))
          .fontSize($r('app.float.task_meta_font_size'))
          .fontColor($r('app.color.meta_text'))
      }
      .width(CommonConstants.FULL_LENGTH)
    }
    .width(CommonConstants.FULL_LENGTH)
    .padding($r('app.float.hero_padding'))
    .borderRadius($r('app.float.card_radius'))
    .backgroundColor($r('app.color.stats_card_background'))
    .shadow({ radius: 12, color: $r('app.color.card_shadow'), offsetX: 0, offsetY: 2 })
  }

  @Builder trendCard() {
    Column({ space: 10 }) {
      Text($r('app.string.trend_title'))
        .fontSize($r('app.float.trend_title_font_size'))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.title_primary'))
        .width(CommonConstants.FULL_LENGTH)
        .textAlign(TextAlign.Start)

      Canvas(this.trendCtx)
        .width(CommonConstants.FULL_LENGTH)
        .height($r('app.float.trend_chart_height'))
        .onReady(() => {
          this.isTrendCanvasReady = true;
          this.drawTrend();
        })
    }
    .width(CommonConstants.FULL_LENGTH)
    .padding($r('app.float.hero_padding'))
    .borderRadius($r('app.float.card_radius'))
    .backgroundColor($r('app.color.stats_card_background'))
    .shadow({ radius: 12, color: $r('app.color.card_shadow'), offsetX: 0, offsetY: 2 })
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        this.header()
        this.rangeSelector()
        this.todayOverviewCard()
        this.statBoxRow()
        this.calendarCard()
        this.trendCard()
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

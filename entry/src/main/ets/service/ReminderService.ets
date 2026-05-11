import { Task } from '../model/Task';

export interface ReminderSyncResult {
  taskId: string;
  action: 'scheduled' | 'cancelled' | 'skipped';
  reason: string;
  reminderAt: number | null;
}

/**
 * 提醒服务的当前实现以“前台提醒 + 调度接口层”作为主交付。
 * 真机系统通知能力受权限和环境影响，先通过统一服务收口后续接入点。
 */
class ReminderService {
  private scheduledReminders: Map<string, number> = new Map<string, number>();

  syncTask(task: Task): ReminderSyncResult {
    if (task.isCompleted) {
      return this.cancelTask(task.id, 'task_completed');
    }

    if (task.reminderAt === null) {
      return this.cancelTask(task.id, 'reminder_disabled');
    }

    if (task.reminderAt <= Date.now()) {
      return this.cancelTask(task.id, 'reminder_time_passed');
    }

    this.scheduledReminders.set(task.id, task.reminderAt);
    return {
      taskId: task.id,
      action: 'scheduled',
      reason: 'ui_fallback_only',
      reminderAt: task.reminderAt
    };
  }

  cancelTask(taskId: string, reason: string = 'manual_cancel'): ReminderSyncResult {
    this.scheduledReminders.delete(taskId);
    return {
      taskId,
      action: 'cancelled',
      reason,
      reminderAt: null
    };
  }

  syncAll(tasks: Array<Task>): Array<ReminderSyncResult> {
    const activeTaskIds = tasks.map((task: Task) => task.id);
    Array.from(this.scheduledReminders.keys()).forEach((taskId: string) => {
      if (!activeTaskIds.includes(taskId)) {
        this.scheduledReminders.delete(taskId);
      }
    });
    return tasks.map((task: Task) => this.syncTask(task));
  }

  getScheduledReminderCount(): number {
    return this.scheduledReminders.size;
  }

  getCapabilityNote(): string {
    return '当前版本已完成前台提醒与本地调度接口层；系统通知仍需在真机环境补权限与 API 接入。';
  }
}

export default new ReminderService();

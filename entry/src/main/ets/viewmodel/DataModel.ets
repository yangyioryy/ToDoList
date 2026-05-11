/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { cloneTask, cloneTasks, createDefaultTasks, sortTasks, Task, TaskDraft, TASK_STORAGE_KEY } from '../model/Task';

/**
 * Saving and manipulating data displayed on the page.
 */
export class DataModel {
  constructor() {
    this.initializeStorage();
  }

  /**
   * 先把任务列表挂到 AppStorage，再交给 PersistentStorage 持久化。
   */
  private initializeStorage(): void {
    PersistentStorage.persistProp<Array<Task>>(TASK_STORAGE_KEY, createDefaultTasks());
    this.replaceTasks(this.readTasks());
  }

  private createTaskId(timestamp: number): string {
    return `task-${timestamp}-${Math.floor(Math.random() * 100000)}`;
  }

  private normalizeTimestamp(value: number | null): number | null {
    if (typeof value === 'number' && Number.isFinite(value)) {
      return value;
    }
    return null;
  }

  private sanitizeTask(task: Task): Task {
    const safeTitle = typeof task.title === 'string' ? task.title.trim() : '';
    const createdAt = Number.isFinite(task.createdAt) ? task.createdAt : Date.now();
    const isCompleted = !!task.isCompleted;
    const completedAt = isCompleted ? (this.normalizeTimestamp(task.completedAt) ?? createdAt) : null;

    return {
      id: task.id,
      title: safeTitle.length > 0 ? safeTitle : '未命名任务',
      isCompleted,
      createdAt,
      dueAt: this.normalizeTimestamp(task.dueAt),
      completedAt,
      reminderAt: this.normalizeTimestamp(task.reminderAt)
    };
  }

  private readTasks(): Array<Task> {
    const tasks = AppStorage.get<Array<Task>>(TASK_STORAGE_KEY);
    if (tasks === undefined) {
      return createDefaultTasks();
    }
    return tasks.map((task: Task) => this.sanitizeTask(task));
  }

  private replaceTasks(tasks: Array<Task>): void {
    const normalizedTasks = tasks.map((task: Task) => this.sanitizeTask(task));
    AppStorage.setOrCreate<Array<Task>>(TASK_STORAGE_KEY, sortTasks(normalizedTasks));
  }

  private mutateTask(taskId: string, updater: (task: Task) => Task): Task | undefined {
    let nextTask: Task | undefined = undefined;
    const nextTasks = this.readTasks().map((task: Task) => {
      if (task.id !== taskId) {
        return task;
      }
      nextTask = this.sanitizeTask(updater(task));
      return nextTask;
    });

    if (nextTask === undefined) {
      return undefined;
    }

    this.replaceTasks(nextTasks);
    return cloneTask(nextTask);
  }

  getTasks(): Array<Task> {
    return cloneTasks(this.readTasks());
  }

  /**
   * 保留旧接口，先兼容现有页面按标题字符串渲染。
   */
  getData(): Array<string> {
    return this.getTasks().map((task: Task) => task.title);
  }

  addTask(draft: TaskDraft): Task {
    const title = draft.title.trim();
    if (title.length === 0) {
      throw new Error('Task title can not be empty.');
    }

    const now = Date.now();
    const task: Task = {
      id: this.createTaskId(now),
      title,
      isCompleted: false,
      createdAt: now,
      dueAt: this.normalizeTimestamp(draft.dueAt),
      completedAt: null,
      reminderAt: this.normalizeTimestamp(draft.reminderAt)
    };

    const nextTasks = this.readTasks();
    nextTasks.push(task);
    this.replaceTasks(nextTasks);
    return cloneTask(task);
  }

  updateTask(taskId: string, draft: TaskDraft): Task | undefined {
    const title = draft.title.trim();
    if (title.length === 0) {
      throw new Error('Task title can not be empty.');
    }

    return this.mutateTask(taskId, (task: Task) => {
      return {
        id: task.id,
        title,
        isCompleted: task.isCompleted,
        createdAt: task.createdAt,
        dueAt: this.normalizeTimestamp(draft.dueAt),
        completedAt: task.completedAt,
        reminderAt: this.normalizeTimestamp(draft.reminderAt)
      };
    });
  }

  updateTaskDueAt(taskId: string, dueAt: number | null): Task | undefined {
    return this.mutateTask(taskId, (task: Task) => {
      return {
        id: task.id,
        title: task.title,
        isCompleted: task.isCompleted,
        createdAt: task.createdAt,
        dueAt: this.normalizeTimestamp(dueAt),
        completedAt: task.completedAt,
        reminderAt: task.reminderAt
      };
    });
  }

  updateTaskReminderAt(taskId: string, reminderAt: number | null): Task | undefined {
    return this.mutateTask(taskId, (task: Task) => {
      return {
        id: task.id,
        title: task.title,
        isCompleted: task.isCompleted,
        createdAt: task.createdAt,
        dueAt: task.dueAt,
        completedAt: task.completedAt,
        reminderAt: this.normalizeTimestamp(reminderAt)
      };
    });
  }

  clearAllTasksForTest(): void {
    AppStorage.setOrCreate<Array<Task>>(TASK_STORAGE_KEY, []);
  }

  toggleTask(taskId: string): Task | undefined {
    const now = Date.now();
    return this.mutateTask(taskId, (task: Task) => {
      const nextCompleted = !task.isCompleted;
      return {
        id: task.id,
        title: task.title,
        isCompleted: nextCompleted,
        createdAt: task.createdAt,
        dueAt: task.dueAt,
        completedAt: nextCompleted ? now : null,
        reminderAt: task.reminderAt
      };
    });
  }

  deleteTask(taskId: string): boolean {
    const currentTasks = this.readTasks();
    const nextTasks = currentTasks.filter((task: Task) => task.id !== taskId);
    if (nextTasks.length === currentTasks.length) {
      return false;
    }
    this.replaceTasks(nextTasks);
    return true;
  }
}

export default new DataModel();

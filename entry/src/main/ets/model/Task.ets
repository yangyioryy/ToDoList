/**
 * 任务领域模型。
 */
export interface Task {
  id: string;
  title: string;
  isCompleted: boolean;
  createdAt: number;
  dueAt: number | null;
  completedAt: number | null;
  reminderAt: number | null;
}

/**
 * 任务新增与编辑时共用的输入模型。
 */
export interface TaskDraft {
  title: string;
  dueAt: number | null;
  reminderAt: number | null;
}

export const TASK_STORAGE_KEY: string = 'todo_tasks_storage';

const DEFAULT_TASK_TITLES: Array<string> = [
  '早起晨练',
  '准备早餐',
  '阅读名著',
  '学习ArkTS',
  '看剧放松'
];

export function cloneTask(task: Task): Task {
  const nextTask: Task = {
    id: task.id,
    title: task.title,
    isCompleted: task.isCompleted,
    createdAt: task.createdAt,
    dueAt: task.dueAt,
    completedAt: task.completedAt,
    reminderAt: task.reminderAt
  };
  return nextTask;
}

export function cloneTasks(tasks: Array<Task>): Array<Task> {
  return tasks.map((task: Task) => cloneTask(task));
}

export function createDefaultTasks(): Array<Task> {
  const startTime = Date.now() - DEFAULT_TASK_TITLES.length * 60_000;
  return DEFAULT_TASK_TITLES.map((title: string, index: number) => {
    const task: Task = {
      id: `seed-${index + 1}`,
      title,
      isCompleted: false,
      createdAt: startTime + index * 60_000,
      dueAt: null,
      completedAt: null,
      reminderAt: null
    };
    return task;
  });
}

function compareNullableAsc(left: number | null, right: number | null): number {
  if (left === right) {
    return 0;
  }
  if (left === null) {
    return 1;
  }
  if (right === null) {
    return -1;
  }
  return left - right;
}

function compareNullableDesc(left: number | null, right: number | null): number {
  return compareNullableAsc(right, left);
}

/**
 * 统一排序规则：
 * 1. 已完成任务排在前面，并按完成时间倒序。
 * 2. 未完成任务排在后面，优先按截止时间升序。
 * 3. 再按创建时间倒序和 id 兜底，避免排序抖动。
 */
export function sortTasks(tasks: Array<Task>): Array<Task> {
  const nextTasks = cloneTasks(tasks);
  nextTasks.sort((left: Task, right: Task) => {
    if (left.isCompleted !== right.isCompleted) {
      return left.isCompleted ? -1 : 1;
    }

    if (left.isCompleted && right.isCompleted) {
      const completedDiff = compareNullableDesc(left.completedAt, right.completedAt);
      if (completedDiff !== 0) {
        return completedDiff;
      }
    } else {
      const dueDiff = compareNullableAsc(left.dueAt, right.dueAt);
      if (dueDiff !== 0) {
        return dueDiff;
      }
    }

    if (left.createdAt !== right.createdAt) {
      return right.createdAt - left.createdAt;
    }

    return left.id.localeCompare(right.id);
  });
  return nextTasks;
}

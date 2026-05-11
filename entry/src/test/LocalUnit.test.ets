import { describe, it, expect } from '@ohos/hypium';
import { sortTasks, Task } from '../main/ets/model/Task';
import DataModel, { DataModel as DataModelClass } from '../main/ets/viewmodel/DataModel';

function createTask(task: Partial<Task>): Task {
  return {
    id: task.id ?? 'task-id',
    title: task.title ?? 'task-title',
    isCompleted: task.isCompleted ?? false,
    createdAt: task.createdAt ?? 0,
    dueAt: task.dueAt ?? null,
    completedAt: task.completedAt ?? null,
    reminderAt: task.reminderAt ?? null
  };
}

export default function localUnitTest() {
  describe('taskModelSortTest', () => {
    it('should_place_completed_tasks_before_pending_tasks', 0, () => {
      const tasks = sortTasks([
        createTask({
          id: 'pending-1',
          title: 'pending-1',
          isCompleted: false,
          createdAt: 1,
          dueAt: 200
        }),
        createTask({
          id: 'completed-1',
          title: 'completed-1',
          isCompleted: true,
          createdAt: 2,
          completedAt: 500
        }),
        createTask({
          id: 'completed-2',
          title: 'completed-2',
          isCompleted: true,
          createdAt: 3,
          completedAt: 400
        })
      ]);

      expect(tasks[0].id).assertEqual('completed-1');
      expect(tasks[1].id).assertEqual('completed-2');
      expect(tasks[2].id).assertEqual('pending-1');
    });

    it('should_sort_pending_tasks_by_due_date_then_created_at', 0, () => {
      const tasks = sortTasks([
        createTask({
          id: 'late-created',
          title: 'late-created',
          isCompleted: false,
          createdAt: 30,
          dueAt: null
        }),
        createTask({
          id: 'early-due',
          title: 'early-due',
          isCompleted: false,
          createdAt: 10,
          dueAt: 200
        }),
        createTask({
          id: 'same-due-newer',
          title: 'same-due-newer',
          isCompleted: false,
          createdAt: 50,
          dueAt: 400
        }),
        createTask({
          id: 'same-due-older',
          title: 'same-due-older',
          isCompleted: false,
          createdAt: 20,
          dueAt: 400
        })
      ]);

      expect(tasks[0].id).assertEqual('early-due');
      expect(tasks[1].id).assertEqual('same-due-newer');
      expect(tasks[2].id).assertEqual('same-due-older');
      expect(tasks[3].id).assertEqual('late-created');
    });
  });

  describe('taskRepositoryCrudTest', () => {
    it('should_add_toggle_update_delete_and_restore_tasks', 0, () => {
      DataModel.clearAllTasksForTest();

      const addedTask = DataModel.addTask({
        title: '补测试',
        dueAt: 1000,
        reminderAt: 1000
      });

      let tasks = DataModel.getTasks();
      expect(tasks.length).assertEqual(1);
      expect(tasks[0].title).assertEqual('补测试');
      expect(tasks[0].dueAt).assertEqual(1000);

      DataModel.toggleTask(addedTask.id);
      tasks = DataModel.getTasks();
      expect(tasks[0].isCompleted).assertTrue();
      expect(tasks[0].completedAt === null).assertFalse();

      DataModel.updateTask(addedTask.id, {
        title: '补测试-已编辑',
        dueAt: 2000,
        reminderAt: 2000
      });
      tasks = DataModel.getTasks();
      expect(tasks[0].title).assertEqual('补测试-已编辑');
      expect(tasks[0].dueAt).assertEqual(2000);

      const restoredTasks = new DataModelClass().getTasks();
      expect(restoredTasks.length).assertEqual(1);
      expect(restoredTasks[0].id).assertEqual(addedTask.id);
      expect(restoredTasks[0].title).assertEqual('补测试-已编辑');

      const deleted = DataModel.deleteTask(addedTask.id);
      expect(deleted).assertTrue();
      expect(DataModel.getTasks().length).assertEqual(0);
    });
  });
}

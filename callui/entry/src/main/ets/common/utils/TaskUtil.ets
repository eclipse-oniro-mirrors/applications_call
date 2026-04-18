/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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
import taskPool from '@ohos.taskpool';
import ArrayList from '@ohos.util.ArrayList';
import LogUtils from './LogUtils';
import hiTraceChain from '@ohos.hiTraceChain';

const TAG = 'TaskUtil';

export class TaskUtil {
  public static taskList: ArrayList<taskPool.Task> = new ArrayList();
  public static taskGroupList: ArrayList<taskPool.TaskGroup> = new ArrayList();
  private static sTaskUtil: TaskUtil;

  public static getInstance(): TaskUtil {
    if (!TaskUtil.sTaskUtil) {
      TaskUtil.sTaskUtil = new TaskUtil();
    }
    return TaskUtil.sTaskUtil;
  }

  public executeTask(newTask: taskPool.Task, callback: (data: object) => void) {
    TaskUtil.taskList.add(newTask);
    taskPool.execute(newTask).then((data) => {
      let curTraceId: hiTraceChain.HiTraceId | null = AppStorage.get('curTraceId') as hiTraceChain.HiTraceId;
      hiTraceChain.setId(curTraceId);
      LogUtils.i(TAG, 'task execute success')
      callback(data);
      TaskUtil.taskList.remove(newTask);
    });
  }

  public executeTaskGroup(newTaskGroup: taskPool.TaskGroup, callback: (data: object) => void) {
    TaskUtil.taskGroupList.add(newTaskGroup);
    taskPool.execute(newTaskGroup).then((data) => {
      LogUtils.i(TAG, 'taskGroup execute success')
      callback(data);
      TaskUtil.taskGroupList.remove(newTaskGroup);
    });
  }

  public cancelTask(task: taskPool.Task) {
    try {
      taskPool.cancel(task);
      TaskUtil.taskList.remove(task);
    } catch (err) {
      LogUtils.e(TAG, 'cancelTask failed with error: ' + err);
    }
  }

  public cancelTaskGroup(task: taskPool.TaskGroup) {
    try {
      taskPool.cancel(task);
      TaskUtil.taskGroupList.remove(task);
    } catch (err) {
      LogUtils.e(TAG, 'cancelTask failed with error: ' + err);
    }
  }

  public cancelAll() {
    TaskUtil.taskList.forEach((task: taskPool.Task) => {
      try {
        taskPool.cancel(task);
      } catch (err) {
        LogUtils.e(TAG, 'cancelTask failed with error: ' + err);
      }
    })

    TaskUtil.taskGroupList.forEach((task: taskPool.TaskGroup) => {
      try {
        taskPool.cancel(task);
      } catch (err) {
        LogUtils.e(TAG, 'cancelTask failed with error: ' + err);
      }
    })
    TaskUtil.taskList.clear();
    TaskUtil.taskGroupList.clear();
  }
}
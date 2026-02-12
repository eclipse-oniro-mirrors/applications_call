/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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
import { LogUtil } from './LogUtil';
import { taskpool } from '@kit.ArkTS';
import { AppInfo } from '../viewmodel/AppInfo';
import { iconsOneByOneProc } from './ApplicationHdsIconsHandleTaskPool';
import { policy } from '@kit.NetworkKit';

const TAG = 'HDSUtil';
const TASKNUMBER = 10;

export interface HdsHandledResult {
  apps: AppInfo[],
  mergeFlows: number
}

export class HDSUtil {
  public static defaultSize: number = 48;

  static async hdsIconsHandle(appList: AppInfo[], context: Context): Promise<HdsHandledResult> {
    //遍历应用，根据应用数量决策是否并发遍历处理图标
    LogUtil.info(TAG, `hdsIconsHandle start and appList.length = ${appList.length.toString()}`)
    let result: HdsHandledResult = {
      apps: [],
      mergeFlows: 0
    };
    if (appList.length === 0) {
      return result;
    }
    result = await HDSUtil.asyncFetchIconByOneProc(appList, context);
    LogUtil.info(TAG, `hdsIconsHandle end and appList.length = ${result.apps.length.toString()}`)
    return result;
  }

  static async asyncFetchIconByOneProc(appList: AppInfo[], context: Context): Promise<HdsHandledResult> {
    let result: AppInfo[] = [];
    let mergeFlows: number = 0;
    const appCountPerTask = appList.length / TASKNUMBER;
    let tasks: taskpool.TaskGroup = new taskpool.TaskGroup();
    for (let index = 0; index < TASKNUMBER; index++) {
      tasks.addTask(new taskpool.Task(iconsOneByOneProc, index < TASKNUMBER - 1
        ? appList.slice(index * appCountPerTask, (index + 1) * appCountPerTask)
        : appList.slice(index * appCountPerTask), context));
    }
    try {
      await taskpool.execute(tasks).then((res: Object[]) => {
        for (let index = 0; index < res.length; index++) {
          let apps = res[index] as AppInfo[];
          let handledResult = HDSUtil.transformObjToModel(apps);
          mergeFlows = mergeFlows + handledResult.mergeFlows;
          result = result.concat(handledResult.apps);
        }
      });
    } catch (error) {
      LogUtil.error(TAG, `taskpool errcode:${error?.code}, errmsg:${error?.message}`);
    }
    return {
      apps: result,
      mergeFlows: mergeFlows
    };
  }

  static transformObjToModel(apps: AppInfo[]): HdsHandledResult {
    let mergeFlow = 0;
    let result: AppInfo[] = [];
    for (let element of apps) {
      if ((element.isCompatibleApp && element.isRubbishData) || element.label === '') {
        LogUtil.info(TAG, `Merge app: ${element.uid}, bundleName:${element.bundleName}, flow: ${element.flow}`)
        mergeFlow = mergeFlow + element.flow;
        continue;
      }
      let tempNetAccess: policy.NetworkAccessPolicy = {
        allowWiFi: element.wifiAccess,
        allowCellular: element.mobileAccess
      }
      tempNetAccess['alwaysAllowWiFi'] = element.wlanPolicyApp;
      tempNetAccess['alwaysAllowCellular'] = element.mobilePolicyApp;
      // taskpool 执行完任务之后返回值是序列化过的不是原本的对象类型，需要转为原来的数据类型
      let appInfo = new AppInfo(element.bundleName, element.uid, element.appIndex, element.bundleType, tempNetAccess)
      appInfo.label = element.label;
      appInfo.img = element.img;
      appInfo.flow = element.flow;
      appInfo.flowText = element.flowText;
      appInfo.isCompatibleApp = element.isCompatibleApp;
      appInfo.installSource = element.installSource;
      result.push(appInfo);
    }
    return {
      apps: result,
      mergeFlows: mergeFlow
    };
  }
}
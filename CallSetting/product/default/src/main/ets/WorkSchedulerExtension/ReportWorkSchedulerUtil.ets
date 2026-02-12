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
import { workScheduler } from '@kit.BackgroundTasksKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { LogUtils } from '@ohos/common/CommonIndex';

const TAG = 'ReportWorkSchedulerUtil';
const TIME_SECOND_IN_MILLIS: number = 1000;

export class ReportWorkSchedulerUtil {
  static tryStartButtonStateReportWorkScheduler() {
    workScheduler.obtainAllWorks().then((workList) => {
      if (workList.length) {
        LogUtils.i(TAG, `statusReportWorker already exist ${JSON.stringify(workList)}`);
        return;
      }
      const workInfo: workScheduler.WorkInfo = {
        workId: 1,
        bundleName: 'com.ohos.callsetting',
        abilityName: 'com.ohos.callsetting.ReportWorkSchedulerExtension',
        isRepeat: true,
        repeatCycleTime: TIME_SECOND_IN_MILLIS * 60 * 60 * 24 * 7, // one week
      }
      try {
        workScheduler.startWork(workInfo);
        LogUtils.i(TAG, `tryStartButtonStateReportWorkScheduler startWork success`);
      } catch (error) {
        LogUtils.e(TAG, `startWork failed. code is ${(error as BusinessError).code} message is ${(error as BusinessError).message}`);
      }
    })
  }
}
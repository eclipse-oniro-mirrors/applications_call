/**
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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

import { hiSysEvent } from '@kit.PerformanceAnalysisKit';
import LogUtils from '../LogUtils';
import { BusinessError } from '@kit.BasicServicesKit';
import { getDeviceTypeInfo, getVersionName } from '../DeviceTypeUtils';
import { SystemMode } from '../SystemMode';

const TAG = 'ReportService';
const packageName = 'com.ohos.callui';

/**
 * get current device Type
 *
 * @return {number}, 0: phone 1：pad 2：other
 */
function getDeviceType(): number {
  const deviceTypeInfo = getDeviceTypeInfo();
  LogUtils.i(TAG, 'deviceType is : ' + deviceTypeInfo);
  if (deviceTypeInfo === 'phone') {
    return ReportDeviceType.PHONE;
  } else if (deviceTypeInfo === 'tablet') {
    return ReportDeviceType.TABLET;
  } else {
    return ReportDeviceType.OTHERS;
  }
}

export abstract class ReportService {
  public versionName: string = '1.0'; // app version
  public modeName: string = ''; // mode name
  public currentDeviceType: number = ReportDeviceType.DEFAULT;

  constructor() {
    getVersionName((verison: string) => {
      this.versionName = verison;
    });
    this.currentDeviceType = getDeviceType();
    this.modeName = SystemMode.getInstance().getName();
  }

  abstract eventType(): hiSysEvent.EventType;

  abstract domain(): string;

  /**
   * Construct eventInfo and params.
   *
   * @param {eventName} info - system event name.
   * @param {customizedParams} info - system event information.
   */
  public report(eventName: string, customizedParams?: Record<string, string | number | boolean | undefined>) {
    try {
      if (customizedParams === null || customizedParams === undefined) {
        let params: Record<string, string | number | boolean | undefined> = {
          'PNAMEID': packageName,
          'PVERSIONID': this.versionName,
          'CALL_TYPE': 0
        };
        customizedParams = params;
      } else {
        customizedParams['PNAMEID'] = packageName;
        customizedParams['PVERSIONID'] = this.versionName;
      }

      let type: hiSysEvent.EventType = this.eventType();
      let eventInfo: hiSysEvent.SysEventInfo = {
        domain: this.domain(),
        name: eventName,
        eventType: type,
        params: customizedParams
      };

      this.write(eventInfo);
    } catch (err) {
      LogUtils.e(TAG, `error code: ${(err as BusinessError).code}, error msg: ${(err as BusinessError).message}`);
    }
  }

  /**
   * Write system event.
   *
   * @param {SysEventInfo} info - system event information to be written.
   */
  public write(eventInfo: hiSysEvent.SysEventInfo) {
    hiSysEvent.write(eventInfo).then(
      () => {
        LogUtils.i(TAG, `hiSys write eventName:${eventInfo.name}, params:${JSON.stringify(eventInfo.params)}, success`);
      }
    ).catch(
      (err: BusinessError) => {
        LogUtils.e(TAG, `error code: ${err.code}, error msg: ${err.message}`);
      }
    );
  }
}

export enum ReportDeviceType {
  DEFAULT = -1,
  PHONE = 0,
  TABLET = 1,
  OTHERS = 2,
  HICAR = 3
}
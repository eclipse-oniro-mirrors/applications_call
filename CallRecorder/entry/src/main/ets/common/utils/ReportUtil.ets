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

import { BusinessError } from '@ohos.base';
import { bundleManager } from '@kit.AbilityKit';
import hiSysEvent from '@ohos.hiSysEvent';
import LogUtils from './LogUtils';

const TAG = 'ReportUtil';
/** ue report call field domain */
const DOMAIN_UE = 'PHONE_UE';
const DOMAIN_FAULT = 'PHONE';
const packageName = 'com.ohos.callrecorder';
export const UE_SELECT_ALL_CALL = 0;
export const UE_SPECIFIED_NUMBER = 1;
export const UE_CLICK_CANCEL = 2;

/**
 * get app version
 *
 * @return string, app version
 */
async function getVersionName(callback: Function): Promise<void> {
  let version: string;
  let bundleInfo: bundleManager.BundleInfo =
    await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
  version = bundleInfo.versionName;
  callback(version);
}

export class ReportUtil {
  private static sReportUtil: ReportUtil;
  private versionName: string = '1.0'; // app version

  constructor() {
    getVersionName((verison: string) => {
      this.versionName = verison;
    });
  }

  public static getInstance(): ReportUtil {
    if (!ReportUtil.sReportUtil) {
      ReportUtil.sReportUtil = new ReportUtil();
    }
    return ReportUtil.sReportUtil;
  }

  private report(eventName: string, customizedParams?: Record<string, string | number | boolean | undefined>) {
    try {
      if (customizedParams === null || customizedParams === undefined) {
        let params: Record<string, string | number | boolean | undefined> = {
          'PNAMEID': packageName,
          'PVERSIONID': this.versionName
        };
        customizedParams = params;
      }
      let eventInfo: hiSysEvent.SysEventInfo = {
        domain: DOMAIN_UE,
        name: eventName,
        eventType: hiSysEvent.EventType.BEHAVIOR,
        params: customizedParams
      };
      hiSysEvent.write(eventInfo).then(
        () => {
          LogUtils.i(TAG, `hiSys write eventName:${eventName}, params:${JSON.stringify(customizedParams)}, success`);
        }
      ).catch(
        (err: BusinessError) => {
          LogUtils.e(TAG, `error code: ${err.code}, error msg: ${err.message}`);
        }
      );
    } catch (err) {
      LogUtils.e(TAG, `error code: ${(err as BusinessError).code}, error msg: ${(err as BusinessError).message}`);
    }
  }

  public reportRestoreStatus(type: number, count: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'TYPE': type,
      'COUNT': count
    };
    this.report('CALL_RECORD_RESTORE_STATUS', params);
  }

  /**
   * report call autoRecord
   *
   * @param {number}, isOpen - 0: close, 1: open
   */
  public reportCallAutoRecord(isOpen: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'OPERATE': isOpen
    };
    this.report('CALL_EVENT_CLICK_AUTORECORD', params);
  }

  /**
   * report record operate
   *
   * @param {number}, actionType - 0: select all call, 1: select the specified number, 2: click cancel
   */
  public reportRecordOperate(actionType: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'OPERATE': actionType
    };
    this.report('CALL_EVENT_RECORD_OPERATE', params);
  }

  private reportFault(eventName: string, customizedParams?: Record<string, string | number | boolean | undefined>) {
    try {
      if (customizedParams === null || customizedParams === undefined) {
        let params: Record<string, string | number | boolean | undefined> = {
          'PNAMEID': packageName,
          'PVERSIONID': this.versionName
        };
        customizedParams = params;
      }
      let eventInfo: hiSysEvent.SysEventInfo = {
        domain: DOMAIN_FAULT,
        name: eventName,
        eventType: hiSysEvent.EventType.FAULT,
        params: customizedParams
      };
      hiSysEvent.write(eventInfo).then(() => {
        LogUtils.i(TAG, `hiSys write eventName:${eventName}, params:${JSON.stringify(customizedParams)}, success`);
      }
      ).catch((err: BusinessError) => {
        if (err) {
          LogUtils.e(TAG, `error code: ${err.code}, error msg: ${err.message}`);
        }
      }
      );
    } catch (err) {
      LogUtils.e(TAG, `error code: ${(err as BusinessError).code}, error msg: ${(err as BusinessError).message}`);
    }
  }

  /**
   * report call record start
   */
  public reportRecordStartError(errorCode: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ERROR_CODE': errorCode
    };
    this.reportFault('CALL_RECORD_OPEN_FAILED', params);
  }

  /**
   * report call record stop
   */
  public reportRecordStopError(errorCode: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ERROR_CODE': errorCode
    };
    this.reportFault('CALL_END_RECORD_NOT_STOP', params);
  }

  private reportUniversalFunc(eventName: string) {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName
    };
    this.report(eventName, param);
  }

  public reportClickSpecifyNumber() {
    this.reportUniversalFunc('CALL_RECORD_SPECIFY_NUMBER');
  }

  public reportClickAddButton() {
    this.reportUniversalFunc('CALL_RECORD_CLICK_ADD_BTN');
  }

  public reportClickBottomAddSpecifyNumBtn() {
    this.reportUniversalFunc('CALL_RECORD_CLICK_SPECIFY_BTN');
  }

  public reportSelectOrCancelSelectSpecifyNum(action: number) {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ACTION' : action
    };
    this.report('CALL_RECORD_SPECIFY_ACTION', param);
  }

  public reportLongPressSpecifyNumber() {
    this.reportUniversalFunc('CALL_RECORD_LOONGPRESS');
  }

  public reportDeleteSpecifyNumber(operate: number) {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'OPERATE' : operate
    };
    this.report('CALL_RECORD_DELETE_SPECIFY', param);
  }

  public reportSpecifyAllSelectAction(action: number) {
    let param: Record<string, string | number | boolean | undefined> = {
      'PNAMEID': packageName,
      'PVERSIONID': this.versionName,
      'ACTION' : action
    };
    this.report('CALL_RECORD_SPECIFY_ALLSELECT', param);
  }

  public reportAddSpecifyNumberSuccessful() {
    this.report('CALL_RECORD_ADD_SPECIFY_NUM');
  }
}


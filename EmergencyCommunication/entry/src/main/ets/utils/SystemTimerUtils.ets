/*
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
import systemTimer from '@ohos.systemTimer';
import { BusinessError } from '@kit.BasicServicesKit';
import LogUtils from './HiLog';
import EmergencyWarningPreferencesUtils from './EmergencyWarningPreferencesUtils';
import ReportPreferencesUtils from './ReportPreferencesUtils';

const TAG = 'SystemTimerUtils';

export class SystemTimerUtils {
  public static readonly SYSTEM_TIMER_DAILY_TIMER_ID_KEY: string = 'system_Timer_Daily_Timer_Id_Key';
  public static readonly SYSTEM_TIMER_SIGNATURES_TIMER_ID_KEY: string = 'system_timer_signatures_timer_id_key';
  public static readonly SYSTEM_TIMER_RETRY_REPORT_TIMER_ID_KEY: string = 'system_timer_retry_report_timer_id_key';
  public static readonly SYSTEM_TIMER_RETRY_SET_DAILY_TIMER_ID_KEY: string =
    'system_timer_retry_set_daily_timer_id_key';
  public static readonly SYSTEM_TIMER_SWITCH_CHANGE_TIMER_ID_KEY: string =
    'system_timer_switch_change_timer_id_key';
  public static readonly SYSTEM_TIMER_REPORT_EARTHQUEKE_TIMER_ID_KEY: string =
    'system_timer_report_earthquekeinfo_timer_id_key';
  public static readonly SYSTEM_TIMER_WEEKLY_REPORT_TIMER_ID_KEY: string = 'system_Timer_Weekly_Report_Timer_Id_Key';
  public static readonly EMPTY_SYSTEM_TIMER_ID: number = -1;
  public static readonly DAILY_TIMER_INTERVAL: number = 24 * 60 * 60 * 1000;
  public static readonly DEFAULT_RETRY_REPORT_TIMER_INTERVAL: number = 20 * 60 * 1000;
  public static readonly WEEKLY_REPORT_TIMER_INTERVAL: number = 7 * 24 * 60 * 60 * 1000;

  private constructor() {
  }

  public static async createTimer(options: systemTimer.TimerOptions) {
    try {
      let timerId:ESObject = await systemTimer.createTimer(options)
        .catch((error: BusinessError) => {
          LogUtils.e(TAG, `Failed to create timer. message: ${error.message}, code: ${error.code}`);
          return null;
        });
      return timerId;
    } catch (e) {
      let error = e as BusinessError;
      LogUtils.e(TAG, `Failed to create timer. message: ${error?.message}, code: ${error?.code}`);
      return null;
    }
  }

  public static async startTimer(timerId: number, triggerTime: number) {
    try {
      await systemTimer.startTimer(timerId, triggerTime).then(() => {
        LogUtils.i(TAG, `Succeeded in starting timer.`);
      }).catch((error: BusinessError) => {
        LogUtils.e(TAG, `Failed to start timer. message: ${error.message}, code: ${error.code}`);
      });
    } catch (e) {
      let error = e as BusinessError;
      LogUtils.e(TAG, `Failed to start timer. message: ${error?.message}, code: ${error?.code}`);
    }
  }

  public static async destroyTimer(timerId: number) {
    LogUtils.i(TAG, 'destroyTimer timerId:' + timerId);
    try {
      await systemTimer.destroyTimer(timerId).then(() => {
        LogUtils.i(TAG, `Succeeded in destroying timer.`);
      }).catch((error: BusinessError) => {
        LogUtils.e(TAG, `Failed to destroy timer. message: ${error.message}, code: ${error.code}`);
      });
    } catch (e) {
      let error = e as BusinessError;
      LogUtils.e(TAG, `Failed to destroy timer. message: ${error?.message}, code: ${error?.code}`);
    }
  }

  public static async clearSystemTimerOfEarthquake(key: string) {
    let oldTimerId = EmergencyWarningPreferencesUtils.getInstance()
      .getSyncByPreferences(key, SystemTimerUtils.EMPTY_SYSTEM_TIMER_ID);
    LogUtils.i(TAG, `clearSystemTimer ${key}`);
    if (oldTimerId !== SystemTimerUtils.EMPTY_SYSTEM_TIMER_ID) {
      await EmergencyWarningPreferencesUtils.getInstance().putAndFlushInPreferences(
        key, SystemTimerUtils.EMPTY_SYSTEM_TIMER_ID);
      await SystemTimerUtils.destroyTimer(Number(oldTimerId));
    }
  }

  public static async clearSystemTimerOfReport(key: string) {
    let oldTimerId = ReportPreferencesUtils.getInstance()
      .getSyncByPreferences(key, SystemTimerUtils.EMPTY_SYSTEM_TIMER_ID);
    LogUtils.i(TAG, `clearSystemTimer ${key}`);
    if (oldTimerId !== SystemTimerUtils.EMPTY_SYSTEM_TIMER_ID) {
      await ReportPreferencesUtils.getInstance().putAndFlushInPreferences(
        key, SystemTimerUtils.EMPTY_SYSTEM_TIMER_ID);
      await SystemTimerUtils.destroyTimer(Number(oldTimerId));
    }
  }
}
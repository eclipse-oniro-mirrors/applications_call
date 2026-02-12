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

import LogUtils from './HiLog';
import { commonEventManager, screenLock } from '@kit.BasicServicesKit';
import SystemModeUtils from './SystemModeUtils';

const TAG = 'CommonEventUtils';

export class CommonEventUtils {
  private static sInstance: CommonEventUtils;
  public readonly PACKAGE_NAME = 'com.ohos.callsetting';
  public readonly SATELLITE_WINDOW_SHOW = 'usual.event.satellite.window.show';
  public readonly SATELLITE_WINDOW_HIDE = 'usual.event.satellite.window.hide';

  public static getInstance(): CommonEventUtils {
    if (!CommonEventUtils.sInstance) {
      CommonEventUtils.sInstance = new CommonEventUtils();
    }
    return CommonEventUtils.sInstance;
  }

  public showSatelliteWindow(satelliteModeSwitchStatus: boolean) {
    if (!satelliteModeSwitchStatus) {
      return;
    }
    if (!SystemModeUtils.getInstance().isEnablePenglai()) {
      return;
    }
    this.publishEvent(this.PACKAGE_NAME, this.SATELLITE_WINDOW_SHOW, '');
  }

  public hideSatelliteWindow(satelliteModeSwitchStatus: boolean) {
    if (!satelliteModeSwitchStatus) {
      return;
    }
    if (!SystemModeUtils.getInstance().isEnablePenglai()) {
      return;
    }
    try {
      if (screenLock.isLocked()) {
        this.publishEvent(this.PACKAGE_NAME, this.SATELLITE_WINDOW_HIDE, '');
      }
    } catch (err) {
      LogUtils.e(TAG, `screenLock isLocked failed, code is ${err.code}.`);
    }
  }

  public publishEvent(packageName: string, event: string, value: string): void {
    LogUtils.i(TAG, `publishEvent `);
    let options: commonEventManager.CommonEventPublishData = {
      code: 0,
      bundleName: packageName,
      data: value
    }
    commonEventManager.publish(event, options, (err) => {
      if (err) {
        LogUtils.e(TAG, `publish failed, code is ${err.code}.`);
      } else {
        LogUtils.i(TAG, `publish success`);
      }
    })
  }
}
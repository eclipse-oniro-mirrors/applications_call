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

import { power, systemParameterEnhance } from '@kit.BasicServicesKit';
import { LogUtils } from './LogUtils';

const TAG = 'SystemModeUtils';

/**
 * @file: SystemModeUtils
 */
export default class SystemModeUtils {
  private readonly PENGLAI_MODE_KEY = 'ohos.boot.minisys.mode';
  private readonly PENGLAI_MODE_IS_SUPPORT_KEY = 'const.penglai.feature_enable';
  private readonly PENGLAI_MODE = 'penglai';
  private readonly PENGLAI_MODE_DFX_NAME = 'PENGLAI';

  private static sInstance: SystemModeUtils;

  public static getInstance(): SystemModeUtils {
    if (SystemModeUtils.sInstance == null) {
      SystemModeUtils.sInstance = new SystemModeUtils();
    }
    return SystemModeUtils.sInstance;
  }

  /**
   * return SystemMode
   *
   * @param {}
   */
  public isEnablePenglai(): boolean {
    return this.isEnable(this.PENGLAI_MODE_DFX_NAME);
  }

  /**
   * return boolean
   *
   * @param {}
   */
  public isOutdoorTravel(): boolean {
    return power.getPowerMode() === power.DevicePowerMode.MODE_CUSTOM_POWER_SAVE;
  }

  /**
   * return SystemMode
   *
   * @param {}
   */
  public isEnable(modeName: string): boolean {
    let systemMode: SystemMode = this.get();
    LogUtils.i(TAG, `systemMode {name is ${systemMode.name}, isEnabled is ${systemMode.isEnabled}}`);
    return modeName === systemMode.name ? systemMode.isEnabled : false;
  }

  /**
   * return SystemMode
   *
   * @param {}
   */
  public get(): SystemMode {
    try {
      if (systemParameterEnhance.getSync(this.PENGLAI_MODE_IS_SUPPORT_KEY, 'false') === 'false') {
        LogUtils.i(TAG, `NOT_SUPPORT_PENGLAI`);
        return {
          isEnabled: false,
          name: ''
        }
      }
      if (systemParameterEnhance.getSync(this.PENGLAI_MODE_KEY, '') === this.PENGLAI_MODE) {
        LogUtils.i(TAG, `SUPPORT_PENGLAI`);
        return {
          isEnabled: true,
          name: this.PENGLAI_MODE_DFX_NAME
        }
      }
    } catch (err) {
      LogUtils.e(TAG, `SystemParameterEnhance getSync fail: ${err.code}`);
    }
    return {
      isEnabled: false,
      name: ''
    }
  }

  /**
   * return SystemMode
   *
   * @param {}
   */
  public getName(): string {
    return this.get().name;
  }
}

class SystemMode {
  public isEnabled: boolean = false;
  public name: string = '';
}
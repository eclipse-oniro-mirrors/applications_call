/**
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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
import { commonEventManager, power, systemParameterEnhance } from '@kit.BasicServicesKit';
import { createSubscriber, subscribeEvent, unSubscribeEvent } from './CommonEventUtils';
import LogUtils from './LogUtils';


const TAG: string = 'SystemMode';
const COMMON_EVENT_POWER_SAVE_MODE_CHANGED = ['usual.event.POWER_SAVE_MODE_CHANGED'];

export class SystemMode {
  public readonly PENGLAI_MODE = 'penglai';
  public readonly NORMAL_MODE = 'normal';
  public readonly MINISYS_MODE = 'ohos.boot.minisys.mode';
  private readonly PENGLAI_MODE_DFX_NAME = 'PENGLAI';
  private static instance: SystemMode;
  private mode: string = this.NORMAL_MODE;

  static getInstance() {
    if (SystemMode.instance == null) {
      SystemMode.instance = new SystemMode();
    }
    return SystemMode.instance;
  }

  private renewSystemMode() {
    try {
      this.mode = systemParameterEnhance.getSync(this.MINISYS_MODE);
    } catch (err) {
      LogUtils.e(TAG, 'getSystemMode is error: ' + err.message);
    }
  }

  public isModePenglai(): boolean {
    this.renewSystemMode();
    return this.mode === this.PENGLAI_MODE
  }

  public isOutdoorTravel(): boolean {
    return power.getPowerMode() === power.DevicePowerMode.MODE_CUSTOM_POWER_SAVE;
  }

  /**
   * getName
   *
   * @param {}
   */
  public getName(): string {
    if (this.isModePenglai()) {
      return this.PENGLAI_MODE_DFX_NAME;
    }
    return '';
  }

  public async subscribePowerSaveEvent(callBack: Function):
    Promise<commonEventManager.CommonEventSubscriber | undefined> {
    const powerSaveEvent = await createSubscriber(COMMON_EVENT_POWER_SAVE_MODE_CHANGED);
    subscribeEvent(callBack, powerSaveEvent);
    return powerSaveEvent;
  }

  public unSubscribeEvent(powerSaveEvent?: commonEventManager.CommonEventSubscriber) {
    unSubscribeEvent(powerSaveEvent);
  }
}
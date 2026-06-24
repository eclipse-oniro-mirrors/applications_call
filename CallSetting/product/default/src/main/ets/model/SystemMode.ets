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
import { commonEventManager, systemParameterEnhance } from '@kit.BasicServicesKit';
import { LogUtils } from '@ohos/common/CommonIndex';
import { sim } from '@kit.TelephonyKit';
import { createSubscriber, subscribeEvent, unSubscribeEvent } from '../common/utils/CommonFunUtil';

const TAG: string = 'SystemMode';
const COMMON_EVENT_POWER_SAVE_MODE_CHANGED = ['usual.event.POWER_SAVE_MODE_CHANGED'];

export class SystemMode {
  public readonly PENGLAI_MODE = 'penglai';
  public readonly NORMAL_MODE = 'normal';
  public readonly MINISYS_MODE = 'ohos.boot.minisys.mode';
  private static instance: SystemMode;
  private mode: string = this.NORMAL_MODE;

  static getInstance() {
    if (SystemMode.instance == null) {
      SystemMode.instance = new SystemMode();
    }
    return SystemMode.instance;
  }


  renewSystemMode() {
    try {
      this.mode = systemParameterEnhance.getSync(this.MINISYS_MODE);
    } catch (err) {
      LogUtils.e(TAG, 'getSystemMode is error: ' + err.message);
    }
  }

  isModePenglai(): boolean {
    this.renewSystemMode();
    return this.mode === this.PENGLAI_MODE
  }

  getSimStateDataCard(slotId: number): boolean {
    try {
      return sim.isSimActiveSync(slotId) && !this.isModePenglai();
    } catch (error) {
      LogUtils.e(TAG, `getSimStateDataCard catch: ${error?.code}`);
      return false;
    }
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
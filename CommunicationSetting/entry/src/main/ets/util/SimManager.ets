/*
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
import { observer } from '@kit.TelephonyKit';
import { SlotId } from '../constants/CommonConstants';
import { SimInfo } from '../data/SimInfo';
import { SimModel } from '../model/SimModel';
import { LogUtil } from './LogUtil';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppStorageUtils } from './AppStorageUtils';

const TAG = 'SimManager';
const SIM_COUNT_2 = 2;

export class SimManager {
  private static instance: SimManager;
  private simModel: SimModel = new SimModel();
  public slotCount: number = 0;
  private simInfos: SimInfo[] = [new SimInfo(SlotId.SLOT_1), new SimInfo(SlotId.SLOT_2)];
  private onSimStateChangeCallbacks: Callback<observer.SimStateData>[] = [(data: observer.SimStateData) => {
    LogUtil.info(TAG, `simStateChangeCallback slotId=0,state=${data.state.valueOf()}`);
    this.hasSimCard(SlotId.SLOT_1);
  }, (data: observer.SimStateData) => {
    LogUtil.info(TAG, `simStateChangeCallback slotId=1,state=${data.state.valueOf()}`);
    this.hasSimCard(SlotId.SLOT_2);
  }];

  private constructor() {
  }

  public static getInstance(): SimManager {
    if (SimManager.instance === null || SimManager.instance === undefined) {
      SimManager.instance = new SimManager();
    }
    return SimManager.instance;
  }

  /**
   * 初始卡信息，注册监听，请与 destroy() 方法成对使用
   */
  public init() {
    this.slotCount = this.simModel.getMaxSimCount();
    if (this.slotCount > SIM_COUNT_2) {
      LogUtil.error(TAG, `init error,simCount=${this.slotCount}`);
      return;
    }
    for (let index = 0; index < this.slotCount; index++) {
      this.hasSimCard(index);
      this.simModel.registerSimStateChange(index, this.onSimStateChangeCallbacks[index]);
    }
  }

  /**
   * 销毁，解除监听，请与 init() 方法成对使用
   */
  public destroy() {
    if (this.slotCount > SIM_COUNT_2) {
      LogUtil.error(TAG, `destroy error,simCount=${this.slotCount}`);
      return;
    }
    for (let index = 0; index < this.slotCount; index++) {
      this.simModel.unregisterSimStateChange(this.onSimStateChangeCallbacks[index]);
    }
  }

  public hasSimCard(slotId: number) {
    this.simModel.hasSimCard(slotId).then((hasSimCard) => {
      LogUtil.info(TAG, `hasSimCard slotId=${slotId},hasSimCard=${hasSimCard}`);
      this.updateHasSimCard(slotId, hasSimCard);
    }).catch((err: BusinessError) => {
      LogUtil.info(TAG, `hasSimCard catch: slotId=${slotId},err=${err.message}`);
      this.updateHasSimCard(slotId, false);
    })
  }

  private updateHasSimCard(slotId: number, hasSimCard: boolean) {
    this.simInfos[slotId].hasSimCard = hasSimCard;
    AppStorageUtils.updateSimInfo(slotId, this.simInfos[slotId]);
    this.updateSimCount();
  }

  private updateSimCount() {
    let count = 0;
    for (let index = 0; index < this.slotCount; index++) {
      if (this.simInfos[index].hasSimCard) {
        count++;
      }
    }
    AppStorageUtils.updateSimCount(count);
  }
}
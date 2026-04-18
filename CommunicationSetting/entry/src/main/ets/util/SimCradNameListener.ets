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
import { SlotId } from '../constants/CommonConstants';
import { SimModel } from '../model/SimModel';
import { LogUtil } from './LogUtil';
import { observer, radio, sim } from '@kit.TelephonyKit';
import StringUtil from './StringUtil';
import myCommon from '@ohos.app.ability.common';
import SimServiceProxy from '../model/simServiceProxy';
import DotUtil from './Dot/DotUtils';
import { SimCardInfo } from '../util/TrafficPackageUtil';
import { DisPlaySimCardInfo as DisPlaySimCard } from './DisPlaySimCardInfo';

const TAG = 'SimCradNameListener';
const SIM_TYPE_SIM = 0; // 表示物理SIM卡
const SIM_TYPE_ESIM = 1; // 表示嵌入式SIM卡（eSIM）

export let cardInfo: SimCardInfo[] = [
  { isSimCard: true, slotIndex: 0, cardName: 'app.string.sim_card_1' },
  { isSimCard: true, slotIndex: 0, cardName: 'app.string.sim_card_2' },
]

export class SimCradNameListener {
  private simCardShowNames: string[] = ['', ''];
  private simCardOperationNames: string[] = ['', ''];
  private simModel: SimModel = new SimModel();
  private slotId: number = 0;
  private netWorkStateChangeCallBack: (slotId: number, state: observer.NetworkState) => void =
    (slotId: number, state: observer.NetworkState) => {
    };
  private onNetWorkStateChangeCallbacks: Callback<observer.NetworkState>[] = [(data: observer.NetworkState) => {
    LogUtil.info(TAG, `onNetWorkStateChangeCallbacks slotid : 0`);
    this.netWorkStateChangeCallBack(SlotId.SLOT_1, data);
    this.update(SlotId.SLOT_1);
  }, (data: observer.NetworkState) => {
    this.netWorkStateChangeCallBack(SlotId.SLOT_2, data);
    LogUtil.info(TAG, `onNetWorkStateChangeCallbacks slotid : 1`);
    this.update(SlotId.SLOT_2);
  }];
  private simCardStatusChangeCallBack: (slotId: number, showName: ResourceStr, isError: boolean) => void =
    (slotId: number, showName: ResourceStr, isError: boolean) => {
    }
  private maxSimCount: number = 1;
  private disPlaySimCardInfo: DisPlaySimCard = new DisPlaySimCard();

  constructor() {
    LogUtil.info(TAG, `simcard listener init`)
    this.maxSimCount = this.simModel.getMaxSimCount();
    this.simModel.registerNetworkStateChange(SlotId.SLOT_1, this.onNetWorkStateChangeCallbacks[0]);
    this.simModel.registerNetworkStateChange(SlotId.SLOT_2, this.onNetWorkStateChangeCallbacks[1]);
  }

  addSimCardStatusChangeListener(callback: (slotId: number, showName: ResourceStr, isError: boolean) => void) {
    this.simCardStatusChangeCallBack = callback;
  }

  unregisterListenter() {
    this.simModel.unregisterNetworkStateChange(this.onNetWorkStateChangeCallbacks[0]);
    this.simModel.unregisterNetworkStateChange(this.onNetWorkStateChangeCallbacks[1]);
  }

  setNetWorkStateChangeCallBack(callback: (slotId: number, state: observer.NetworkState) => void) {
    this.netWorkStateChangeCallBack = callback;
  }

  getMaxSimCount(): number {
    return this.maxSimCount;
  }

  isValidOfSlotId(slotId: number): boolean {
    if (slotId < 0 || slotId >= this.maxSimCount) {
      return false;
    } else {
      return true;
    }
  }

  // 通过getSIMlabel获取的数值新增一个动态列表
  async refreshSimList(): Promise<void> {
    LogUtil.info(TAG, ' Start generating the SIM card name list ');
    let start = new Date().getTime();

    // 定义处理单个卡槽的函数
    const processSimSlot = async (slotId: number): Promise<void> => {
      let sim : ESObject =  SimServiceProxy.getSimLabel(slotId);
      if (sim) {
        LogUtil.info(TAG, `slotid ${slotId} simtype: ${sim.simType} slotid ${slotId} index: ${sim.index}`);
        if (sim.simType === SIM_TYPE_SIM) {
          cardInfo[slotId].isSimCard = true;
          cardInfo[slotId].slotIndex = sim.index;
          cardInfo[slotId].cardName = `app.string.sim_card_${cardInfo[slotId].slotIndex}`;
          LogUtil.info(TAG, ` sim.simType === SIM_TYPE_SIM, slotIndex: ${cardInfo[slotId].slotIndex}, cardName:${cardInfo[slotId].cardName}`);
        } else if (sim.simType === SIM_TYPE_ESIM) {
          cardInfo[slotId].isSimCard = false;
          cardInfo[slotId].slotIndex = sim.index;
          cardInfo[slotId].cardName = `app.string.esim_card`;
          LogUtil.info(TAG, `sim.simType === SIM_TYPE_ESIM, cardName: ${cardInfo[slotId].cardName}`);
        }
      } else {
        LogUtil.error(TAG, `Failed to get sim label for slotId: ${slotId}`);
      }
      DotUtil.getInstance().reportSimLabelFetchStatus(slotId);
    };

    // 处理卡槽0和卡槽1
    await processSimSlot(0);
    await processSimSlot(1);

    LogUtil.info(TAG, `update simCardInfo: ${cardInfo}`);
    let end = new Date().getTime();
    let consume = end - start;
    LogUtil.info(TAG, `Spending time : ${consume} ms`);
  }

  update(slotId: number) {
    SimServiceProxy.getSimState(slotId).then((res: number) => {
      LogUtil.info(TAG, `getSimstate: slotId=${slotId},state=${res}`);
      if (res === sim.SimState.SIM_STATE_READY || res === sim.SimState.SIM_STATE_LOADED) {
        this.isSimActive(slotId);
      } else {
        this.handleNoActiveOrException(slotId);
      }
    }).catch((err: Error) => {
      this.handleNoActiveOrException(slotId);
      LogUtil.error(TAG, `getSimState failed slotid: ${SlotId}, promise: err->errormsg: ${err?.message} `);
    });
  }

  handleNoActiveOrException(slotId: number) {
    this.simCardShowNames[slotId] = '';
    this.simCardOperationNames[slotId] = '';
    this.updateCardInfoSimName(slotId, true);
  }

  /**
   * Whether the sim card is activated
   */
  isSimActive(slotId: number) {
    SimServiceProxy.isSimActive(slotId).then((res: boolean) => {
      LogUtil.info(TAG, 'isSimActive slotId=' + JSON.stringify(slotId) + ',res=' + JSON.stringify(res));
      if (res) {
        this.getShowName(slotId);
        return;
      }
      LogUtil.error(TAG, `isSimActive false slotid: ${SlotId}`);
    }).catch((err: Error) => {
      LogUtil.error(TAG, `isSimActive failed slotid: ${SlotId}, promise: err->${JSON.stringify(err)}`);
    });
  }

  /**
   * Get the custom operator name set by the user -- success
   */
  getShowName(slotId: number) {
    SimServiceProxy.getShowName(slotId).then((res: string) => {
      this.handleGetShowNameResult(slotId, res);
    }).catch((err: Error) => {
      this.handleGetShowNameResult(slotId, '');
      LogUtil.error(TAG, `getShowName failed slotid: ${SlotId}, promise: err->${JSON.stringify(err)}`);
    });
  }

  private handleGetShowNameResult(slotId: number, res: string) {
    if (this.isValidOfSlotId(slotId) === false) {
      LogUtil.error(TAG, 'handleGetShowNameResult slotId is invalid');
      return;
    }
    this.simCardShowNames[slotId] = res;
    if (StringUtil.isEmpty(this.simCardShowNames[slotId])) {
      this.getNetName(slotId);
    }
    this.updateCardInfoSimName(slotId, false);
  }

  /**
   * Get card slot operator name
   */
  getNetName(slotId: number) {
    radio.getOperatorName(slotId).then((res: string) => {
      this.simCardOperationNames[slotId] = res;
      LogUtil.info(TAG, `getNetName slotid:${slotId} name: ${res}`);
      this.updateCardInfoSimName(slotId, false);
    }).catch((err: Error) => {
      this.simCardOperationNames[slotId] = '';
      this.updateCardInfoSimName(slotId, true);
      LogUtil.error(TAG, `getOperatorName failed slotid: ${SlotId}, promise: err->${JSON.stringify(err)}`);
    });
  }

  updateCardInfoSimName(slotId: number, isError: boolean) {
    let name: ResourceStr = '';
    let showName = this.simCardShowNames[slotId];
    let context = (getContext(this) as myCommon.UIAbilityContext);
    let operatorName = this.simCardOperationNames[slotId];
    name = this.disPlaySimCardInfo.getNetWorkDisplayName(context, slotId, operatorName, showName);
    LogUtil.info(TAG, `getNetWorkDisplayName result: name=${name}`);
    this.simCardStatusChangeCallBack(slotId, name, isError);
  }
}
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
import sim from '@ohos.telephony.sim';
import { LogUtil } from '../util/LogUtil';
import observer from '@ohos.telephony.observer';
import radio from '@ohos.telephony.radio';
import data from '@ohos.telephony.data';

const TAG = 'SimModel';

export class SimModel {
  /**
   * 设备支持的卡槽数量
   */
  public getMaxSimCount(): number {
    try {
      return sim.getMaxSimCount();
    } catch (err) {
      LogUtil.error(TAG, `getMaxSimCount catch: erorr=${JSON.stringify(err)}`);
      return 0;
    }
  }

  /**
   * 判断指定卡槽是否插有SIM卡
   *
   * @param slotId - 卡槽id
   * @returns - true:有卡;false:无卡;
   */
  public async hasSimCard(slotId: number): Promise<boolean> {
    try {
      return await sim.hasSimCard(slotId);
    } catch (err) {
      LogUtil.error(TAG, `hasSimCard catch: slotId=${slotId},erorr=${JSON.stringify(err)}`);
      return err;
    }
  }

  /**
   * 注册卡状态变化监听
   *
   * @param slotId - 卡槽id
   * @param callback - 回调方法
   */
  public registerSimStateChange(slotId: number, callback: Callback<observer.SimStateData>) {
    try {
      observer.on('simStateChange', { slotId: slotId }, callback);
    } catch (err) {
      LogUtil.error(TAG, `registerSimStateChange catch: slotId=${slotId},erorr=${JSON.stringify(err)}`);
    }
  }

  /**
   * 解除卡状态变化监听
   *
   * @param callback - 之前注册的回调方法
   */
  public unregisterSimStateChange(callback?: Callback<observer.SimStateData>) {
    try {
      observer.off('simStateChange', callback);
    } catch (err) {
      LogUtil.error(TAG, `registerSimStateChange catch: erorr=${JSON.stringify(err)}`);
    }
  }

  /**
   * 注册卡信息（是否无服务）变化监听
   *
   * @param callback - 回调方法
   */
  public registerAccountInfoChange(callBack: Callback<void>) {
    LogUtil.info(TAG, 'registerAccountInfoChange');
    try {
      observer.on('iccAccountInfoChange', callBack);
    } catch (err) {
      LogUtil.error(TAG, 'registerAccountInfoChange err=' + JSON.stringify(err));
    }
  }

  /**
   * 解除卡信息变化监听
   *
   * @param callback - 之前注册的回调方法
   */
  public unRegisterAccountInfoChange(callBack: Callback<void>) {
    LogUtil.info(TAG, 'unRegisterAccountInfoChange');
    try {
      observer.off('iccAccountInfoChange', callBack);
    } catch (err) {
      LogUtil.error(TAG, 'unRegisterAccountInfoChange err=' + JSON.stringify(err));
    }
  }

  /**
   * 获取用户编辑的卡名称
   *
   * @param slotId - 卡槽id
   * @returns - 用户编辑的卡名称
   */
  public async getSimName(slotId: number): Promise<string> {
    try {
      let name = await sim.getShowName(slotId);
      return name;
    } catch (err) {
      LogUtil.error(TAG, `getSimName catch: slotId=${slotId},erorr=${JSON.stringify(err)}`);
      return err;
    }
  }

  /**
   * 获取运营商名称
   *
   * @param slotId - 卡槽id
   * @returns - 运营商名称
   */
  public async getOperatorName(slotId: number): Promise<string> {
    try {
      let name = await radio.getOperatorName(slotId);
      return name;
    } catch (err) {
      LogUtil.error(TAG, `getOperatorName catch: slotId=${slotId},erorr=${JSON.stringify(err)}`);
      return err;
    }
  }

  /**
   * 获取主卡的卡槽id
   *
   * @returns - 主卡的卡槽id
   */
  public async getPrimarySlotId(): Promise<number> {
    try {
      let slotId = await radio.getPrimarySlotId();
      return slotId;
    } catch (err) {
      LogUtil.error(TAG, `getPrimarySlotId catch: erorr=${JSON.stringify(err)}`);
      return err;
    }
  }

  /**
   * 设置默认数据卡
   *
   * @param slotId - 要设置的卡槽id
   * @returns - 结果回调方法
   */
  public async setPrimarySlotId(slotId: number): Promise<void> {
    try {
      return await radio.setPrimarySlotId(slotId);
    } catch (err) {
      LogUtil.error(TAG, `setPrimarySlotId catch: slotId=${slotId},erorr=${JSON.stringify(err)}`);
      return err;
    }
  }

  /**
   * 注册网络状态变化事件的监听
   *
   * @param slotId - 要监听的卡槽id
   * @param callback - 回调方法
   */
  public registerNetworkStateChange(slotId: number, callback: Callback<observer.NetworkState>) {
    try {
      LogUtil.info(TAG, `registerNetworkStateChange slotId=${slotId}`);
      observer.on('networkStateChange', { slotId: slotId }, callback);
    } catch (err) {
      LogUtil.error(TAG, `registerNetworkStateChange err=${JSON.stringify(err)}`);
    }
  }

  /**
   * 解除网络状态变化事件的监听
   *
   * @param callback - 之前注册的回调方法
   */
  public unregisterNetworkStateChange(callback: Callback<observer.NetworkState>) {
    try {
      observer.off('networkStateChange', callback);
    } catch (err) {
      LogUtil.error(TAG, `unregisterNetworkStateChange err=${JSON.stringify(err)}`);
    }
  }

  /**
   * 启用蜂窝数据服务
   *
   * @returns 启用蜂窝数据服务的回调
   */
  public async enableCellularData(): Promise<void> {
    try {
      return await data.enableCellularData();
    } catch (err) {
      LogUtil.error(TAG, `enableCellularData err=${JSON.stringify(err)}`);
    }
  }
}
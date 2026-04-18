/*
 * Copyright (c) 2025-2025 Huawei Device Co., Ltd.
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

/**
 * @file: SIM card service interface
 */

import sim from '@ohos.telephony.sim';
import { BusinessError } from '@ohos.base';
import StringUtil from '../util/StringUtil';
import { LogUtil } from '../util/LogUtil';

const TAG = 'SimServiceProxy';

export class SimServiceProxy {

  private searchIsSimActive(slotId: number, resolve: (value: boolean) => void = () => {},
    reject: (error: BusinessError<void>) => void = () => {}) {
    sim.isSimActive(slotId, (error, value) => {
      if (error) {
        LogUtil.error(TAG, 'isSimActive error slotId: ' + JSON.stringify(slotId) + ' ' + JSON.stringify(error));
        reject(error);
        return;
      }
      LogUtil.info(TAG, 'isSimActive data slotId: ' + JSON.stringify(slotId) + ' ' + JSON.stringify(value));
      resolve(value);
    });
  }

  /**
   * Is sim active
   *
   * @param  {number} slotId - slot ID
   * @return {Promise}
   */
  isSimActive(slotId = 0) {
    return new Promise((resolve: (value: boolean) => void, reject: (reason?: BusinessError) => void) => {
      try {
        this.searchIsSimActive(slotId, resolve, reject);
      } catch (error) {
        LogUtil.error(TAG, 'isSimActive catch slotId: ' + JSON.stringify(slotId) + ' ' + JSON.stringify(error));
        reject(error);
      }
    });
  }

  /**
   * Get sim label
   *
   * @param  {number} slotId - slot ID
   * @return {<sim.SimLabel | null>} Returns a promise that resolves to the sim label or null
   */
  getSimLabel(slotId = 0): sim.SimLabel | null {
    try {
      LogUtil.info(TAG, 'getSimLabel success');
      const simLabel: sim.SimLabel | null =  sim.getSimLabelSync(slotId);
      LogUtil.info(TAG,
        `getSimLabel false slotid: ${slotId} ;SimType: ${simLabel.simType} ;index: ${simLabel.index}`);
      return simLabel;
    } catch (err) {
      LogUtil.error(TAG, `getSimLabel catch slotId: ${slotId}  +  errormsg: ${err?.message} code: ${err?.code}`);
      return null;
    }
  }

  public async getSimState(slotId = 0): Promise<number> {
    try {
      let res = await sim.getSimState(slotId);
      LogUtil.info(TAG, 'getSimState data:' + JSON.stringify(slotId) + ' data: ' + JSON.stringify(res));
      return res;
    } catch (err) {
      LogUtil.error(TAG, 'getSimState card :' + JSON.stringify(slotId) + ' error: ' + JSON.stringify(err));
      return sim.SimState.SIM_STATE_UNKNOWN;
    }
  }


  /**
   * Get show name
   *
   * @param  {number} slotId - slot ID
   * @return {Promise}
   */
  getShowName(slotId = 0) {
    return new Promise((resolve: (value: string) => void, reject: (reason?: BusinessError) => void) => {
      try {
        this.doGetShowName(slotId, resolve, reject)
      } catch (error) {
        LogUtil.error(TAG, 'getShowName catch:' + JSON.stringify(error) + ',slotId=' + slotId);
        reject(error);
      }
    });
  }

  private doGetShowName(slotId:number, resolve: (value: string) => void = () => {},
    reject: (error: BusinessError<void>) => void = () => {}) {
    sim.getShowName(slotId, (error, value) => {
      if (error) {
        LogUtil.error(TAG, 'getShowName error:' + JSON.stringify(error) + ',slotId=' + slotId);
        reject(error);
        return;
      }
      const isNameEmpty = StringUtil.isEmpty(value);
      LogUtil.info(TAG, 'getShowName isNameEmpty:' + JSON.stringify(isNameEmpty) + ',slotId=' + slotId);
      resolve(value);
    });
  }

}

let mSimServiceProxy = new SimServiceProxy();
export default mSimServiceProxy as SimServiceProxy;
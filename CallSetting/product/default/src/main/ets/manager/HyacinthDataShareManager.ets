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

import dataShare from '@ohos.data.dataShare';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { BusinessError } from '@ohos.base';
import { DataShareResultSet } from '@kit.ArkData';
import {
  LogUtils,
  CallSettingGlobalContextHelper,
} from '@ohos/common/CommonIndex';
import { common } from '@kit.AbilityKit';
import { SatelliteType, SATELLITE_SWITCH_OFF } from '../common/constant/SatelliteSearchConst';
import { CALL_SETTING_SATELLITE_ABILITY_CONTEXT } from '../common/constant/CallSettingsConstant';

const TAG = 'HyacinthDataShareManager';

export const SETTING_SATELLITE_SERVICE_URI =
  'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true';

export const ON_SETTING_SATELLITE_SERVICE_URI =
  'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true';

export const QUERY_SATELLITE_MODE_KEY = 'satellite_mode_switch';

export const QUERY_SATELLITE_MODE_TIANTONG_KEY = 'satellite_mode_switch_tiantong';

export const QUERY_SATELLITE_MODE_HYACINTH_KEY = 'satellite_mode_switch_hyacinth';


export default class HyacinthDataShareManager {
  private static instance: HyacinthDataShareManager;
  private dataShareHelper: dataShare.DataShareHelper | null = null;

  private hyacinthCallbackList: Array<(data: number) => void> = [];
  private tiantongCallbackList: Array<(data: number) => void> = [];


  private constructor() {
  }

  public static getInstance(): HyacinthDataShareManager {
    LogUtils.i(TAG, `HyacinthDataShareManager init instance`);
    if (!HyacinthDataShareManager.instance) {
      LogUtils.i(TAG, `HyacinthDataShareManager create instance`);
      HyacinthDataShareManager.instance = new HyacinthDataShareManager();
      HyacinthDataShareManager.instance.createDataShareHelper(CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIExtensionContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT));
    } else if (HyacinthDataShareManager.instance.dataShareHelper === null) {
      LogUtils.i(TAG, 'getInstance dataShareHelper undefined');
      HyacinthDataShareManager.instance.createDataShareHelper(CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIExtensionContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT));
    }
    return HyacinthDataShareManager.instance
  }

  async createDataShareHelper(context: Context) {
    if (this.dataShareHelper !== null) {
      LogUtils.i(TAG, `createDataShareHelper dataShareHelper not undefined`);
      return;
    }

    dataShare.createDataShareHelper(context,
      SETTING_SATELLITE_SERVICE_URI, (err: BusinessError, data: dataShare.DataShareHelper) => {
        if (err != undefined) {
          LogUtils.e(TAG, `addHyacinthCommunicationListener error, code: ${err?.code}, message: ${err?.message}`);
          return;
        }
        this.dataShareHelper = data;

        try {
          this.dataShareHelper.on('dataChange',
            ON_SETTING_SATELLITE_SERVICE_URI + '?key=' + QUERY_SATELLITE_MODE_TIANTONG_KEY,
            () => {
              LogUtils.i(TAG, `addSatelliteToggleStateListener dataChange success ${SatelliteType.TIAN_TONG}`);
              this.runCallback(SatelliteType.TIAN_TONG);
            });
          this.dataShareHelper.on('dataChange',
            ON_SETTING_SATELLITE_SERVICE_URI + '?key=' + QUERY_SATELLITE_MODE_HYACINTH_KEY,
            () => {
              LogUtils.i(TAG, `addSatelliteToggleStateListener dataChange success ${SatelliteType.HYACINTH}`);
              this.runCallback(SatelliteType.HYACINTH);
            });
        } catch (err) {
          LogUtils.e(TAG, `addSatelliteToggleStateListener error, code: ${err?.code}, message: ${err?.message}`);
        }
        LogUtils.i(TAG, `createDataShareHelper dataShareHelper done`);
      });
  }

  async runCallback(satelliteType: SatelliteType) {
    if (satelliteType === SatelliteType.TIAN_TONG) {
      this.tiantongCallbackList.forEach(callback => {
        this.queryHyacinthSatellite(callback, SatelliteType.TIAN_TONG);
      });
    }

    if (satelliteType === SatelliteType.HYACINTH) {
      this.hyacinthCallbackList.forEach(callback => {
        this.queryHyacinthSatellite(callback, SatelliteType.HYACINTH);
      });
    }
  }

  async addHyacinthDataShareListenerCallback(callback: (data: number) => void,
    satelliteType: SatelliteType) {

    LogUtils.i(TAG, `addHyacinthDataShareListener satelliteType: ${satelliteType}`);

    try {
      if (satelliteType === SatelliteType.TIAN_TONG) {
        this.tiantongCallbackList.push(callback);
        LogUtils.i(TAG, `addHyacinthDataShareListener TIAN_TONG push`);
      }
      if (satelliteType === SatelliteType.HYACINTH) {
        this.hyacinthCallbackList.push(callback);
        LogUtils.i(TAG, `addHyacinthDataShareListener HYACINTH push`);
      }
    } catch (err) {
      LogUtils.e(TAG, `addHyacinthDataShareListener error, code: ${err?.code}, message: ${err?.message}`);
    }

  }

  async removeHyacinthDataShareListenerCallback() {
    this.hyacinthCallbackList.splice(0, this.hyacinthCallbackList.length);
    this.tiantongCallbackList.splice(0, this.tiantongCallbackList.length);
  }

  async removeHyacinthDataShareListener() {
    LogUtils.i(TAG, 'removeHyacinthDataShareListener');

    if( this.dataShareHelper === null) {
      LogUtils.e(TAG, `removeHyacinthDataShareListener error, dataShareHelper is null`);
      return;
    }

    try {
      let hyacinthUri = ON_SETTING_SATELLITE_SERVICE_URI + '?key=' + QUERY_SATELLITE_MODE_HYACINTH_KEY;
      this.dataShareHelper.off('dataChange', hyacinthUri);
      LogUtils.i(TAG, 'remove hyacinthCommunicationDataShareHelper done:');

      let tiantongUri = ON_SETTING_SATELLITE_SERVICE_URI + '?key=' + QUERY_SATELLITE_MODE_TIANTONG_KEY;
      this.dataShareHelper.off('dataChange', tiantongUri);
      LogUtils.i(TAG, 'remove tiantongCommunicationDataShareHelper done:');

    } catch (err) {
      LogUtils.e(TAG, `removeHyacinthDataShareListener error, code: ${err?.code}, message: ${err?.message}`);
    }
  }

  async queryHyacinthSatelliteWithParam(keyword: string) {
    LogUtils.i(TAG, `queryHyacinthSatelliteWithParam ${keyword}`);
    let res: number = 0;

    if (this.dataShareHelper !== null) {
      let condition = new dataSharePredicates.DataSharePredicates();
      condition.equalTo('KEYWORD', keyword);
      let data: DataShareResultSet | undefined = undefined;
      try {
        data = await this.dataShareHelper.query(SETTING_SATELLITE_SERVICE_URI, condition, []);
        LogUtils.i(TAG, 'queryHyacinthSatelliteWithParam query succeed');
        if (data.goToFirstRow()) {
          LogUtils.i(TAG, 'queryHyacinthSatelliteWithParam query succeed return key');
          res = data.getLong(data.getColumnIndex('VALUE'));
        }
      } catch (err) {
        LogUtils.e(TAG, `queryHyacinthSatelliteWithParam error, code: ${err?.code}, message: ${err?.message}`);
      } finally {
        if (data !== undefined) {
          data.close();
        }
      }
      LogUtils.i(TAG, `queryHyacinthSatelliteWithParam res: ${res}`);
    } else {
      LogUtils.e(TAG, `queryHyacinthSatelliteWithParam error dataShareHelper is null`);
    }
    return res;
  }

  async queryHyacinthSatellite(callback: (data: number) => void,
    satelliteType: SatelliteType) {
    LogUtils.i(TAG, `querySatellite ${satelliteType}`);
    try {
      let typeValue = await this.queryHyacinthSatelliteWithParam(this.getSatelliteModeKey(satelliteType));
      callback(typeValue);
    } catch (err) {
      callback(SATELLITE_SWITCH_OFF);
      LogUtils.e(TAG, `querySatellite query out error: code: ${err.code}, message: ${err.message}`);
    }
  }

  getSatelliteModeKey(satelliteType: SatelliteType) {
  return satelliteType === SatelliteType.TIAN_TONG ? QUERY_SATELLITE_MODE_TIANTONG_KEY :
    QUERY_SATELLITE_MODE_HYACINTH_KEY;
}
}
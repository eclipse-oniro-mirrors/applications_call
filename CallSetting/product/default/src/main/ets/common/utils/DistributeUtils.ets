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
import { LogUtils } from '@ohos/common/CommonIndex';
import dataShare from '@ohos.data.dataShare';
import settings from '@ohos.settings';
import { BusinessError } from '@ohos.base';

export const SETTING_DISTRIBUTRD_URI =
  'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true';

export const ON_SETTING_DISTRIBUTRD_URI =
  'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true';

export const DISTRIBUTE_MODEM_STATE_KEY = 'distributed_modem_state';

const TAG = 'DistributeUtils';

let dataShareHelper: dataShare.DataShareHelper;

export async function addRegisterDistributedStateListener(context: Context, callback: (data: string) => void) {
  LogUtils.i(TAG, 'addRegisterDistributedStateListener');
  try {
    dataShare.createDataShareHelper(context,
      SETTING_DISTRIBUTRD_URI, (err: BusinessError, data: dataShare.DataShareHelper) => {
        if (err != undefined) {
          LogUtils.e(TAG, 'addRegisterDistributedStateListener error: code: ' + err.code + ', message: ' + err.message);
          return;
        }
        dataShareHelper = data;
        try {
          dataShareHelper.on('dataChange', ON_SETTING_DISTRIBUTRD_URI, () => {
            LogUtils.i(TAG, 'addRegisterDistributedStateListener dataChange success');
            queryDistributedState(context, callback);
          });
        } catch (err) {
          let error = err as BusinessError;
          LogUtils.e(TAG, 'addRegisterDistributedStateListener error: code: ' + error.code + ', message: ' + error.message);
        }
      });
  } catch (err) {
    let error = err as BusinessError;
    LogUtils.e(TAG, 'addRegisterDistributedStateListener createDataShareHelper error: code: ' + error.code + ', message: ' +
    error.message);
  }
}

export async function removeRegisterDistributedStateListener() {
  LogUtils.i(TAG, 'removeRegisterDistributedStateListener');
  if (!dataShareHelper) {
    LogUtils.e(TAG, 'removeRegisterDistributedStateListener dataShareHelper null');
    return;
  }
  try {
    dataShareHelper.off('dataChange', ON_SETTING_DISTRIBUTRD_URI);
  } catch (err) {
    let error = err as BusinessError;
    LogUtils.e(TAG,
      'removeRegisterDistributedStateListener error: code: ' + error.code + ', message: ' + error.message);
  }
}

export async function queryDistributedState(context: Context, callback: (data: string) => void) {
  LogUtils.i(TAG, 'queryDistributedState');
  if (!context) {
    LogUtils.e(TAG, 'queryDistributedState context is null')
    callback('')
    return;
  }
  try {
    let distributeState = settings.getValueSync(context, DISTRIBUTE_MODEM_STATE_KEY, '');
    LogUtils.i(TAG, 'queryDistributedState:' + JSON.stringify(distributeState));
    callback(distributeState);
  } catch (error) {
    callback('');
    LogUtils.e(TAG, 'Error in check distributed state observer');
  }
}
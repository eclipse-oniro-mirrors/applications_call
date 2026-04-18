/**
 * Copyright (c) 2024-2024 Huawei Device Co., Ltd.
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

import LogUtils from './LogUtils';
import settings from '@ohos.settings';
import {
  DISTRIBUTED_CALL_SMS_SHARING_SINK,
  DISTRIBUTE_CALL_SOURCE_SMS,
  DISTRIBUTE_MODEM_DEVICE_NAME,
  DISTRIBUTE_MODEM_STATE,
  DISTRIBUTE_SINK_CALL,
  DISTRIBUTE_SOURCE_CALL
} from './Constants';
import Utils from './utils';
import { dataShare } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

export const SETTING_DISTRIBUTRD_URI = 'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true';

const TAG = 'DistributeUtils';

let dataShareHelper: dataShare.DataShareHelper;

export function checkDistributedState() {
  let context = Utils.getInstance().getContext();
  if (!context) {
    LogUtils.e(TAG, 'checkDistributedState context is null')
    return;
  }
  try {
    let distributeState = settings.getValueSync(context, DISTRIBUTE_MODEM_STATE, '');
    let isDistributeSource = distributeState === DISTRIBUTE_SOURCE_CALL;
    AppStorage.setOrCreate('isDistributeSource', isDistributeSource);
    let isDistributeSink = distributeState === DISTRIBUTE_SINK_CALL;
    AppStorage.setOrCreate('isDistributeSink', isDistributeSink);
    LogUtils.i(TAG, 'distributeState:' + JSON.stringify(distributeState));
  } catch (error) {
    LogUtils.e(TAG, 'Error in check distributed state observer');
  }
}

// sink device check sms function
export function checkDistributedSinkSmsState() {
  let context = Utils.getInstance().getContext();
  if (!context) {
    LogUtils.e(TAG, 'checkDistributedSinkSmsState context is null')
    return;
  }
  try {
    let distributeSourceSms = Number(settings.getValueSync(context, DISTRIBUTE_CALL_SOURCE_SMS, '0'));
    let distributeSinkSms = Number(settings.getValueSync(context, DISTRIBUTED_CALL_SMS_SHARING_SINK, '0'));
    AppStorage.setOrCreate('distributeSmsEnable', distributeSourceSms === 1 && distributeSinkSms === 1);
    LogUtils.i(TAG, 'distributeSourceSms:' + distributeSourceSms + ', distributeSinkSms:' + distributeSinkSms);
  } catch (error) {
    LogUtils.e(TAG, 'Error in check distributed source sms observer');
  }
}

export function registerDistributeSmsObserver() {
  let context = Utils.getInstance().getContext();
  if (!context) {
    LogUtils.e(TAG, 'registerDistributeSmsObserver context is null')
    return;
  }
  try {
    settings.registerKeyObserver(context, DISTRIBUTED_CALL_SMS_SHARING_SINK, settings.domainName.DEVICE_SHARED, () => {
      LogUtils.i(TAG, 'registerDistributeSmsObserver is called');
      checkDistributedSinkSmsState();
    });
  } catch (err) {
    LogUtils.e(TAG, 'registerDistributeSmsObserver error: code: ' + err.code + ', message: ' + err.message);
  }
}

export function unRegisterDistributeSmsObserver() {
  let context = Utils.getInstance().getContext();
  if (!context) {
    LogUtils.e(TAG, 'unRegisterDistributeSmsObserver context is null')
    return;
  }
  try {
    settings.unregisterKeyObserver(context, DISTRIBUTED_CALL_SMS_SHARING_SINK, settings.domainName.DEVICE_SHARED);
  } catch (err) {
    LogUtils.e(TAG, 'unRegisterDistributeSmsObserver error: code: ' + err.code + ', message: ' + err.message);
  }
}


export function checkDistributedDevice() {
  let context = Utils.getInstance().getContext();
  if (!context) {
    LogUtils.e(TAG, 'checkDistributedDevice context is null')
    return;
  }
  try {
    let distributeDeviceName = settings.getValueSync(context, DISTRIBUTE_MODEM_DEVICE_NAME, '');
    AppStorage.setOrCreate('distributeDeviceName', distributeDeviceName);
  } catch (error) {
    LogUtils.e(TAG, 'Error in check distributed device observer');
  }
}

export function addRegisterDistributedChange() {
  checkDistributedState();
  checkDistributedDevice();
  checkDistributedSinkSmsState();
  registerDistributeSmsObserver();
  try {
    let context = Utils.getInstance().getContext();
    if (!context) {
      LogUtils.e(TAG, 'addRegisterDistributedChange context is null')
      return;
    }
    dataShare.createDataShareHelper(context,
      SETTING_DISTRIBUTRD_URI, (err: BusinessError, data: dataShare.DataShareHelper) => {
        if (err != undefined) {
          LogUtils.e(TAG, 'addRegisterDistributedChange error: code: ' + err.code + ', message: ' + err.message);
          return;
        }
        dataShareHelper = data;
        try {
          dataShareHelper.on('dataChange', SETTING_DISTRIBUTRD_URI, () => {
            checkDistributedState();
            checkDistributedDevice();
            checkDistributedSinkSmsState();
          });
        } catch (err) {
          let error = err as BusinessError;
          LogUtils.e(TAG, 'addRegisterDistributedChange error: code: ' + error.code + ', message: ' + error.message);
        }
      });
  } catch (error) {
    LogUtils.e(TAG, 'addRegisterDistributedChange Error in registering distributed observer');
  }
}

export function unRegisterDistributedChange() {
  LogUtils.i(TAG, 'unRegisterDistributedChange');
  unRegisterDistributeSmsObserver();
  if (!dataShareHelper) {
    LogUtils.e(TAG, 'unRegisterDistributedChange dataShareHelper null');
    return;
  }
  try {
    dataShareHelper.off('dataChange', SETTING_DISTRIBUTRD_URI);
  } catch (err) {
    let error = err as BusinessError;
    LogUtils.e(TAG,
      'unRegisterDistributedChange error: code: ' + error.code + ', message: ' + error.message);
  }
}
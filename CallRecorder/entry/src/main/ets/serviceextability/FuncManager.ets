/**
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import Want from '@ohos.app.ability.Want';
import LogUtils from '../common/utils/LogUtils';
import { FuncManageReturn } from '../common/struct/RecorderStruct';
import { RecordConfigDataStruct } from '../common/struct/RecorderSettingStruct';
import dataShare from '@ohos.data.dataShare';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { Constant } from '../common/constant/Constant'
import { BusinessError } from '@ohos.base';
import ServiceExtStub from '../IdlServiceExt/idl_service_ext_stub';
import data_preferences from '@ohos.data.preferences';
import notificationManager from '@ohos.notificationManager';
import wantAgent, { WantAgent as _WantAgent } from '@ohos.app.ability.wantAgent';
import Base from '@ohos.base';
import { ResourceUtil } from '../common/utils/ResourceUtil';
import { CallSettingConstant } from '../common/constant/CallSettingConstant';
import DataShareResultSet from '@ohos.data.DataShareResultSet';

const TAG = 'CallRecorderFuncManager';
let callManagerConfigStatus: RecordConfigDataStruct | undefined;

export default class FuncManager {
  private context: Context;

  constructor(context: Context) {
    this.context = context;
    this.initConfig();
  }

  async initConfig() {
    callManagerConfigStatus = await this.queryRecorderConfig();
  }

  async sendNotification() {
    let context = this.context.getApplicationContext();
    notificationManager.getActiveNotificationCount(async (err, data) => {
      if (err) {
        LogUtils.e(TAG, `getAllActiveNotifications failed, code is ${err.code}`);
        return;
      }
      try {
        let preferences = await data_preferences.getPreferences(context, 'currentNotification');
        let ids: number[] = [];
        let currentId = 1003;
        if (data === 0) {
          await preferences.put('currentNotificationIDS', []);
          preferences.flush();
        } else {
          ids = await preferences.get('currentNotificationIDS', []) as Array<number>;
          currentId = 1003 + ids.length;
        }
        this.sendNotificationExt(currentId, ids, preferences);
      } catch (error) {
        let err: BusinessError = error as BusinessError;
        LogUtils.e(TAG, `recordHandle failed, error code: ${err.code}.`);
      }
    });
  }

  async sendNotificationExt(currentId: number, ids: number[], preferences: data_preferences.Preferences) {
    let context = this.context.getApplicationContext();
    let wantAgentDataNotification = await this.buildWantAgentInfo();
    if (currentId !== 1003) {
      await notificationManager.cancelGroup('callRecorderNotify');
    }
    let title: string =
      ResourceUtil.formatPluralResourceToString($r('app.plural.call_numbers_finish'), context, (ids.length + 1));
    let notificationRequest: notificationManager.NotificationRequest = {
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: title,
          text: ResourceUtil.resourceToString($r('app.string.call_numbers_finish_des'), context),
          additionalText: ''
        }
      },
      extraInfo: {
        testBanner: true
      },
      wantAgent: wantAgentDataNotification,
      notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
      deliveryTime: new Date().getTime(),
      groupName: 'callRecorderNotify',
      id: currentId
    };
    notificationManager.publish(notificationRequest, (err: Base.BusinessError) => {
      if (err) {
        LogUtils.e(TAG, `publish failed, code is ${err.code}`);
      } else {
        LogUtils.i(TAG, 'publish');
        ids.push(currentId);
        preferences.put('currentNotificationIDS', ids);
        preferences.flush();
      }
    });
  }

  async buildWantAgentInfo() {
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [{
        bundleName: 'com.ohos.soundrecorder',
        abilityName: 'MainAbility',
        'entities': [
          'entity.system.home'
        ],
        parameters: {
          'type': 'callrecorder'
        }
      }],
      actionType: wantAgent.OperationType.START_ABILITY,
      requestCode: 103,
      wantAgentFlags: [wantAgent.WantAgentFlags.ONE_TIME_FLAG]
    };
    return await wantAgent.getWantAgent(wantAgentInfo);
  }

  async getIsDesignateNumber(want: Want, callback: (data: FuncManageReturn) => void) {
    LogUtils.i(TAG, 'getIsDesignateNumber start');
    let returnResult: FuncManageReturn = {};
    let callManagerConfigStatus: RecordConfigDataStruct | undefined = await this.queryRecorderConfig();
    if (!callManagerConfigStatus?.isOpen) {
      returnResult.message = 'the call recording function is disabled';
      returnResult.designateNumberStatus = false;
      returnResult.errCode = ServiceExtStub.RECORDING_SO;
      LogUtils.i(TAG, 'returnResult:' + JSON.stringify(returnResult));
      callback(returnResult);
      return;
    } else {
      if (callManagerConfigStatus.object === CallSettingConstant.RECORDING_WAY_ALL_NUMBER) {
        returnResult.message = 'all call recordings';
        returnResult.designateNumberStatus = true;
        returnResult.errCode = ServiceExtStub.RECORDING_ALL;
        LogUtils.i(TAG, 'returnResult:' + JSON.stringify(returnResult));
        callback(returnResult);
        return;
      } else {
        if (want.parameters?.accountNumber) {
          let contactResult = this.queryIsRecorderContact(want.parameters.accountNumber as string);
          contactResult.then((resultSet) => {
            if (resultSet.goToNextRow()) {
              returnResult.message = 'recording by a specified number';
              returnResult.designateNumberStatus = true;
              returnResult.errCode = ServiceExtStub.RECORDING_VN;
              LogUtils.i(TAG, 'returnResult:' + JSON.stringify(returnResult));
              callback(returnResult);
              return;
            } else {
              returnResult.message = 'not in the specified number';
              returnResult.designateNumberStatus = false;
              returnResult.errCode = ServiceExtStub.RECORDING_NA;
              LogUtils.i(TAG, 'returnResult:' + JSON.stringify(returnResult));
              callback(returnResult);
              return;
            }
          });
        } else {
          returnResult.message = 'unknown number';
          returnResult.designateNumberStatus = false;
          returnResult.errCode = ServiceExtStub.RECORDING_NK;
          LogUtils.i(TAG, 'returnResult:' + JSON.stringify(returnResult));
          callback(returnResult);
          return;
        }
      }
    }
  }

  async queryRecorderConfig() {
    let uri = Constant.RECORDER_DATA_SHARE_URL + Constant.RECORD_CONFIG;
    LogUtils.i(TAG, 'queryRecorderConfig' + uri);
    let condition = new dataSharePredicates.DataSharePredicates();
    const columns = ['is_open', 'object'];
    let result: RecordConfigDataStruct = {};
    try {
      let dataHelper = await dataShare.createDataShareHelper(this.context, uri);
      return await dataHelper.query(uri, condition, columns).then((resultSet) => {
        if (resultSet.goToNextRow()) {
          const isOpen = resultSet.getLong(resultSet.getColumnIndex('is_open'));
          const object = resultSet.getString(resultSet.getColumnIndex('object'));
          result = {
            isOpen: isOpen, object: object
          };
          LogUtils.i(TAG, 'result' + JSON.stringify(result));
          resultSet.close();
          return result;
        }
        resultSet.close();
        return result;
      });
    } catch (err) {
      LogUtils.e(TAG, 'queryRecorderConfig err:' + JSON.stringify(err));
      return result;
    }
  }

  async queryIsRecorderContact(phoneNumber: string) {
    let uri = Constant.RECORDER_DATA_SHARE_URL + Constant.RECORD_CONTACT;
    let condition = new dataSharePredicates.DataSharePredicates();
    condition.equalTo('phone_number', phoneNumber);
    const columns = ['phone_number', 'name'];
    let dataHelper = await dataShare.createDataShareHelper(this.context, uri);
    return dataHelper.query(uri, condition, columns);
  }
}

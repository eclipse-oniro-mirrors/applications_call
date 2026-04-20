/**
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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

import IdlServiceExtProxy from '../../idl/idl_service_ext_proxy';
import { RecordConfigDataStruct, RecordInputData } from '../struct/RecordingStruct';
import ServiceExtensionContext from '@ohos.app.ability.common';
import LogUtils from './LogUtils';
import Want from '@ohos.app.ability.Want';
import {
  RECORDER_DATA_SHARE_URL,
  RECORDER_DISABLED_STATUS,
  RECORDER_START_STATUS,
  RECORDER_STOP_STATUS,
  RECORDING_WAY_ALL_NUMBER,
  RECORD_BUNDLE_NAME,
  RECORD_CONFIG,
  RECORD_CONTACT,
  RECORD_SERVICE_ABILITY_NAME } from '../constant/CallRecorderConst';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import dataShare from '@ohos.data.dataShare';
import rpc from '@ohos.rpc';
import DataShareResultSet from '@ohos.data.DataShareResultSet';
import { BusinessError } from '@ohos.base';
import { GlobalContextHelper } from './GlobalContextHelper';
import * as Constants from './Constants';
import DefaultCallData from '../struct/TypeUtils';
import RecordTimer from './RecordTimer';
import common from '@ohos.app.ability.common';
import Utils from './utils';
import systemParameterEnhance from '@ohos.systemParameterEnhance';
import { fileNameString } from './CallLabelUtils';
import { StringUtil } from './StringUtil';
import CallStateConst from '../constant/CallStateConst';

const TAG = 'Recording_CLASS';
const DEF_NUM_MATCH = 7;
let mServiceExtProxy: IdlServiceExtProxy | undefined;

export default class Recording {
  private static sInstance: Recording;
  private recordCallId: number = -1;
  private connectionId: number | undefined = undefined;
  private dataShareHelper: dataShare.DataShareHelper | undefined = undefined;
  private isMatchAllNum: boolean = true;
  private numMatchShort: number = DEF_NUM_MATCH;
  private numMatchLong: number = DEF_NUM_MATCH;

  static getInstance() {
    if (Recording.sInstance == null) {
      Recording.sInstance = new Recording();
    }
    return Recording.sInstance;
  }

  async changePreferences(status: string) {
    AppStorage.setOrCreate('recorderStatus', status);
  }

  recordingStart(param: RecordInputData) {
    LogUtils.i(TAG, 'recordingStart');
    let actionData: Record<string, string> = {};
    actionData.funcFlag = 'isDesignateNumber';
    actionData.accountNumber = param.accountNumber;
    actionData.fileNameSre = param.fileNameStr
    let want: Want = {
      'deviceId': '',
      'bundleName': RECORD_BUNDLE_NAME,
      'abilityName': RECORD_SERVICE_ABILITY_NAME,
      'parameters': actionData
    };
    let recordingContext = this;
    let serviceContext: common.ServiceExtensionContext = GlobalContextHelper.getContext()
      .getValue<ServiceExtensionContext.ServiceExtensionContext>(Constants.CALL_SERVICE_CONTEXT);
    this.connectionId = serviceContext?.connectServiceExtensionAbility(want, {
      onConnect(elementName, remote: rpc.IRemoteObject) {
        if (remote === null) {
          LogUtils.i(TAG, `onConnect remote is null`);
          return;
        }
        mServiceExtProxy = new IdlServiceExtProxy(remote);
        recordingContext.recordingStartRpc(param);
      },
      onDisconnect(elementName) {
        LogUtils.i(TAG, 'recordingStart onDisconnect callback stopRecording');
        recordingContext.onRecordDisconnected(RECORDER_STOP_STATUS, true);
      },
      onFailed(code: number) {
        LogUtils.i(TAG, 'recordingStart onFailed callback code' + code);
        mServiceExtProxy = undefined;
      }
    });
    LogUtils.i(TAG, 'recordingStart connectionId:' + this.connectionId);
  }

  recordingGetIsError() {
    let recordingContext = this;
    let promiseProxy: Promise<boolean> = new Promise<boolean>((resolve, reject) => {
      LogUtils.i(TAG, 'recordingGetIsError');
      let want: Want = {
        'deviceId': '',
        'bundleName': RECORD_BUNDLE_NAME,
        'abilityName': RECORD_SERVICE_ABILITY_NAME,
      };
      let serviceContext = GlobalContextHelper.getContext()
        .getValue<ServiceExtensionContext.ServiceExtensionContext>(Constants.CALL_SERVICE_CONTEXT);
      let connectionId: number = serviceContext?.connectServiceExtensionAbility(want, {
        onConnect(elementName, remote: rpc.IRemoteObject) {
          if (remote === null) {
            LogUtils.i(TAG, `onConnect remote is null`);
            return;
          }
          mServiceExtProxy = new IdlServiceExtProxy(remote);
          mServiceExtProxy.recordingGetIsError((code: number, message: string) => {
            LogUtils.i(TAG, `recordingGetIsError errCode=${code} message=${message}`);
            let isError: boolean = false;
            if (code === 100 || code === 400) {
              Utils.getInstance().showToast(StringUtil.getStringByNameSync(`recorder_toast_error_${code}`), 3000);
              recordingContext.changePreferences(RECORDER_DISABLED_STATUS);
              isError = true;
            }
            AppStorage.setOrCreate('recorderFirstInit', true);
            serviceContext?.disconnectServiceExtensionAbility(connectionId);
            mServiceExtProxy = undefined;
            resolve(isError);
          });
        },
        onDisconnect(elementName) {
          LogUtils.i(TAG, 'recordingGetIsError onDisconnect callback');
          mServiceExtProxy = undefined;
        },
        onFailed(code: number) {
          LogUtils.i(TAG, 'recordingGetIsError onFailed callback code' + code);
          mServiceExtProxy = undefined;
        }
      });
    });
    return promiseProxy;
  }

  async addRPCErrorListener() {
    LogUtils.i(TAG, 'addRPCErrorListener');
    let serviceContext = Utils.getInstance().getContext();
    let uri: string = RECORDER_DATA_SHARE_URL + RECORD_CONFIG;
    try {
      let dataShareHelper: dataShare.DataShareHelper = await dataShare.createDataShareHelper(serviceContext, uri);
      this.dataShareHelper = dataShareHelper;
      dataShareHelper.on('dataChange', uri, () => {
        LogUtils.i(TAG, 'addRPCErrorListener stop rpc disabled,listener stopRecording');
        this.recordingStop(RECORDER_DISABLED_STATUS);
        Utils.getInstance().showToast(StringUtil.getStringByNameSync('recorder_toast_error_400'), 3000);
      });
    } catch (error) {
      LogUtils.e(TAG, 'addRPCErrorListener fail');
    }
  }

  async removeRPCErrorListener() {
    if (!this.dataShareHelper) {
      LogUtils.e(TAG, 'removeRPCErrorListener fail');
      return;
    }
    let uri: string = RECORDER_DATA_SHARE_URL + RECORD_CONFIG;
    try {
      this.dataShareHelper.off('dataChange', uri);
    } catch (error) {
      LogUtils.e(TAG, 'removeRPCErrorListener fail');
    }
  }

  recordingStartRpc(param: RecordInputData) {
    if (!mServiceExtProxy) {
      LogUtils.e(TAG, 'recordingStartRpc mServiceExtProxy invalid');
      return;
    }
    Recording.getInstance().addRPCErrorListener();
    mServiceExtProxy.recordingStart(param, (code: number, message: string) => {
      LogUtils.i(TAG, `recordingStartRpc errCode=${code} callId=${param.callId} message =${message}`);
      if (code === 100 || code === 400) {
        Utils.getInstance().showToast(StringUtil.getStringByNameSync(`recorder_toast_error_${code}`), 3000);
        this.changePreferences(RECORDER_DISABLED_STATUS);
        return;
      }
      this.recordCallId = param.callId;
      AppStorage.setOrCreate('recordStartTime', new Date().getTime());
      this.changePreferences(RECORDER_START_STATUS);
    });
  }

  /**
   * when second call is active
   * stop previous call record and start new record
   */
  autoStartAnotherRecord(callData: DefaultCallData) {
    let param: RecordInputData = {
      callId: callData.callId,
      accountNumber: callData.accountNumber + '',
      mode: IdlServiceExtProxy.RECORDING_MANUAL,
      startTime: callData.startTime,
      fileNameStr: fileNameString(callData)
    };
    LogUtils.i(TAG, `autoStartAnotherRecord: nowRecordCallId=${this.recordCallId}`);
    if (!this.recordCallId || !mServiceExtProxy) {
      this.isDesignateNumber(param);
      return;
    }
    // the process of stop and restart record in CallRecorder application must been a sync task
    mServiceExtProxy.recordingStop(1, async (errorCode: number, result: string) => {
      LogUtils.i(TAG, 'autoStartAnotherRecord, errCode: ' + errorCode);
      if (errorCode) {
        return;
      }
      this.recordCallId = -1;
      this.changePreferences(RECORDER_STOP_STATUS);
      AppStorage.delete('recordStartTime');
      RecordTimer.getInstance().stopTimer();
      let isAutoRecordNumber: boolean = await this.getIsDesignateNumber(param.accountNumber);
      if (!isAutoRecordNumber) {
        this.recordingStop(RECORDER_STOP_STATUS);
        LogUtils.i(TAG, 'autoStartAnotherRecord: is not auto record phone number stopRecording');
        return;
      }
      this.recordingStartRpc(param);
    });
  }

  autoStopById(callId: number) {
    if (callId !== this.recordCallId) {
      LogUtils.i(TAG, `autoStopById fail callId=${callId} recordCallId=${this.recordCallId}`);
      return;
    }
    LogUtils.i(TAG, 'autoStopById stopRecording');
    this.recordingStop(RECORDER_STOP_STATUS);
  }

  recordingStop(status: string) {
    if (AppStorage.get<string>('recorderStatus') === RECORDER_STOP_STATUS ||
      this.connectionId === undefined) {
      LogUtils.i(TAG, `recordingStop failed`);
      return;
    }
    LogUtils.i(TAG, 'recordingStop connectionId:' + this.connectionId);
    this.removeRPCErrorListener();
    let serviceContext = GlobalContextHelper.getContext()
      .getValue<ServiceExtensionContext.ServiceExtensionContext>(Constants.CALL_SERVICE_CONTEXT);
    serviceContext?.disconnectServiceExtensionAbility(this.connectionId)
      .then(() => {
        this.onRecordDisconnected(status, false);
      })
      .catch((err: BusinessError) => {
        LogUtils.e(TAG, 'recordingStop err=' + JSON.stringify(err));
      });
  }

  onRecordDisconnected(status: string, isDefault: boolean) {
    if (isDefault && AppStorage.get<string>('recorderStatus') !== RECORDER_START_STATUS) {
      LogUtils.i(TAG, 'onRecordDisconnected disabledNoChange');
      return;
    }
    LogUtils.i(TAG, 'onRecordDisconnected stopRecording');
    AppStorage.setOrCreate('autoRecordCall', false);
    AppStorage.delete('recordStartTime');
    this.connectionId = undefined;
    this.recordCallId = -1;
    this.changePreferences(status);
    mServiceExtProxy = undefined;
    RecordTimer.getInstance().stopTimer();
    LogUtils.i(TAG, 'recordingStopped status:' + status);
  }

  async isDesignateNumber(param: RecordInputData) {
    let result: boolean = await this.getIsDesignateNumber(param.accountNumber);
    if (!result) {
      LogUtils.i(TAG, 'isDesignateNumber: is not auto record phone number');
      return;
    }
    if (AppStorage.get<number>('callStateInCeliaDisconnect') !== CallStateConst.CALL_STATUS_ACTIVE) {
      LogUtils.i(TAG, 'call is not active, not record');
      return;
    }
    this.recordingStart(param);
  }

  async getIsDesignateNumber(accountNumber: string): Promise<boolean> {
    let returnResult: boolean = false;
    let callManagerConfigStatus: RecordConfigDataStruct | undefined = await this.queryRecorderConfig();
    if (!callManagerConfigStatus?.isOpen) {
      returnResult = false;
      LogUtils.i(TAG, 'returnResult: open status close');
    } else {
      if (callManagerConfigStatus.object === RECORDING_WAY_ALL_NUMBER) {
        returnResult = true;
        LogUtils.i(TAG, 'returnResult: object all');
      } else {
        if (accountNumber && accountNumber.length > 0) {
          let contactResult = await this.queryIsRecorderContact(accountNumber);
          LogUtils.i(TAG, 'contactResult' + contactResult)
          returnResult = contactResult;
        } else {
          returnResult = false;
          LogUtils.i(TAG, 'returnResult: unknown number');
        }
      }
    }
    AppStorage.setOrCreate('autoRecordCall', returnResult);
    return returnResult;
  }

  async queryRecorderConfig() {
    let uri: string = RECORDER_DATA_SHARE_URL + RECORD_CONFIG;
    LogUtils.i(TAG, 'queryRecorderConfig' + uri);
    let condition = new dataSharePredicates.DataSharePredicates();
    const columns = ['is_open', 'object'];
    let serviceContext = Utils.getInstance().getContext();
    let dataHelper: dataShare.DataShareHelper | undefined = await dataShare.createDataShareHelper(serviceContext, uri, {
      isProxy: true
    });
    let result: RecordConfigDataStruct = {};
    let resultSet = await dataHelper.query(uri, condition, columns);
    if (resultSet.goToNextRow()) {
      const isOpen = resultSet.getLong(resultSet.getColumnIndex('is_open'));
      const object = resultSet.getString(resultSet.getColumnIndex('object'));
      result = {
        isOpen: isOpen, object: object
      };
      resultSet.close();
    }
    dataHelper = undefined;
    return result;
  }

  async queryIsRecorderContact(phoneNumber: string) {
    this.getNumMatchParam();
    let uri: string = RECORDER_DATA_SHARE_URL + RECORD_CONTACT;
    let condition = new dataSharePredicates.DataSharePredicates();
    const columns = ['phone_number'];
    let serviceContext = Utils.getInstance().getContext();
    let dataHelper: dataShare.DataShareHelper | undefined = undefined;
    let resultSet: DataShareResultSet | undefined = undefined;
    try {
      dataHelper = await dataShare.createDataShareHelper(serviceContext, uri, {
        isProxy: true
      });
      resultSet = await dataHelper.query(uri, condition, columns);
      if (!resultSet || !resultSet.goToFirstRow()) {
        LogUtils.i(TAG, 'query auto record num get empty list');
        return false;
      }
      let compareCallNum = phoneNumber.slice(-this.numMatchLong);
      LogUtils.i(TAG, 'queryIsRecorderContact oriLen:' + phoneNumber.length + ' newLen:' + compareCallNum.length);
      do {
        let autoRecordNum = resultSet.getString(0);
        if (phoneNumber === autoRecordNum) {
          LogUtils.i(TAG, 'query auto record num all matched');
          return true;
        }
        if (this.compareNum(compareCallNum, autoRecordNum)) {
          LogUtils.i(TAG, 'query auto record compare num matched');
          return true;
        }
      } while (resultSet.goToNextRow());
    } catch (err) {
      LogUtils.e(TAG, `query auto record num err:${JSON.stringify(err)}`);
    } finally {
      try {
        resultSet?.close();
        dataHelper?.close();
      } catch (err) {
        LogUtils.e(TAG, `query auto record num close err:${JSON.stringify(err)}`);
      }
    }
    return false;
  }

  getNumMatchParam(): void {
    this.numMatchLong = this.getNumMatchByProp('telephony.nummatch');
    this.numMatchShort = this.getNumMatchByProp('telephony.nummatch.short', this.numMatchLong);
    LogUtils.i(TAG, 'getNumMatchParam numMatchLong:' + this.numMatchLong + ', numMatchShort:' + this.numMatchShort);
    if (this.numMatchLong === this.numMatchShort) {
      this.isMatchAllNum = false;
    }
  }

  compareNum(compareCallNum: string, autoRecordNum: string): boolean {
    if (!this.isMatchAllNum && autoRecordNum && autoRecordNum.length > 0) {
      let compareAutoRecordNum = autoRecordNum.slice(-this.numMatchLong);
      return compareCallNum === compareAutoRecordNum;
    }
    return false;
  }

  getNumMatchByProp(key: string, defNumMatch: number = DEF_NUM_MATCH): number {
    let numMatch: number = defNumMatch;
    try {
      let matchResult = systemParameterEnhance.getSync(key, '');
      if (matchResult !== '') {
        numMatch = Number(matchResult);
        if (numMatch <= 0) {
          numMatch = defNumMatch;
        }
      }
    } catch (err) {
      LogUtils.e(TAG, `get ${key} err:${JSON.stringify(err)}`);
    }
    return numMatch;
  }

  getRecordCallId(): number {
    return this.recordCallId;
  }

  changeRecorderStatus() {
    let recorderStatus: string = AppStorage.get<string>('recorderStatus') as string;
    LogUtils.i(TAG, 'recorderStatus stopRecording' + recorderStatus);
    if (recorderStatus === RECORDER_START_STATUS) {
      this.recordingStop(RECORDER_STOP_STATUS);
    }
    if (recorderStatus !== RECORDER_DISABLED_STATUS) {
      this.changePreferences(RECORDER_STOP_STATUS);
    }
  }
}
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

import { WorkSchedulerExtensionAbility, workScheduler } from '@kit.BackgroundTasksKit';
import { LogUtils, ReportUtil, Constants } from '@ohos/common/CommonIndex';
import { call, radio, sim } from '@kit.TelephonyKit';
import { BusinessError } from '@kit.BasicServicesKit';
import telephonyData from '@ohos.telephony.data';
import settings from '@ohos.settings';
import commonController from '../common/control/CommonCtrol';
import { getCallWaiting } from '../model/CallServiceProxy';
import { checkCellularDataEnabled } from '../model/CellularDataServiceProxy';
import connection from '@ohos.net.connection';
import { isTablet, isTwoInOne } from '../common/utils/Utils';
import { getSimCardPhoneNumber } from '../common/model/getSimTelephoneNumberApi';
import { dataShare, dataSharePredicates } from '@kit.ArkData';

const TAG = 'ReportWorkSchedulerExtension';

const INCALL_POWER_KEY: string = 'incall_power_button_behavior';
const VIDEO_RING_TONE_SETTINGS = 'video_ringback_tone_settings';

let statusValueArray: string[] = ['CALL_HOLDSTATE_CARDONE', 'MOBILENET_AVAIL_NET_CARDONE',
  'MOBILENET_AVAIL_NET_CARDTWO', 'MOBILENET_ROAMING_CARDONE', 'MOBILENET_ROAMING_CARDTWO', 'MOBILENET_SWITCH_STATUS',
  'CALL_NUM_IDENTIFY_STATUS', 'CALL_AUTORECORD_STATUS', 'CALL_FORWARDING_CARDONE', 'CALL_NOTIFYTYPE_STATUS',
  'CALL_HISTORYMERGE_STATUS', 'CALL_IMPROVEQUALITY_STATUS', 'CALL_SET_POWER_END_CALL_STATUS',
  'CALL_SET_VIDEO_RBT_STATUS', 'SHARE_NET_SHARING_STATUS', 'SHARE_PHONE_SHARING_STATUS', 'SHARE_SMS_SHARING_STATUS',
  'SHARE_NET_AUTOCONNECT_STATUS_PAD', 'SHARE_PHONE_SHARING_STATUS_PAD', 'SHARE_SMS_SHARING_STATUS_PAD',
  'NEW_CALLING_SWITCH_STATE'];

export default class MyWorkSchedulerExtensionAbility extends WorkSchedulerExtensionAbility {
  private isPhone: boolean = true;
  // 延迟任务开始回调
  onWorkStart(workInfo: workScheduler.WorkInfo) {
    LogUtils.i(TAG, `onWorkStart`);
    this.isPhone = !isTablet() && !isTwoInOne();
    let sim1Active: boolean = sim.isSimActiveSync(0);
    let sim2Active: boolean = sim.isSimActiveSync(1);
    for (let eventName of statusValueArray) {
      try {
       this.getSwitchStatusToReport(eventName, sim1Active, sim2Active);
      } catch (e) {
        LogUtils.e(TAG, `try to report status fail. eventName: ${eventName}, error: ${e}`);
      }
    }
  }

  // 延迟任务结束回调
  onWorkStop(workInfo: workScheduler.WorkInfo) {
    LogUtils.i(TAG, `onWorkStop`);
  }

  private getSwitchStatusToReport(eventName: string, isSim1Active: boolean, isSim2Active: boolean) {
    switch (eventName) {
      case 'MOBILENET_AVAIL_NET_CARDONE': {
        if (isSim1Active) {
          radio.getNetworkSelectionMode(0).then(data => {
            ReportUtil.getInstance().delayReportSwitchButtonStateEvent(eventName, data === 1 ? 'on' : 'off');
          }, (err: BusinessError) => {
            LogUtils.i(TAG, 'getNetworkSelectionMode card1 failed, promise: err' + JSON.stringify(err));
          })
        }
      }
        break;
      case 'MOBILENET_AVAIL_NET_CARDTWO': {
        if (isSim2Active) {
          radio.getNetworkSelectionMode(1).then(data => {
            ReportUtil.getInstance().delayReportSwitchButtonStateEvent(eventName, data === 1 ? 'on' : 'off');
          }, (err: BusinessError) => {
            LogUtils.i(TAG, 'getNetworkSelectionMode card2 failed, promise: err' + JSON.stringify(err));
          })
        }
      }
        break;
      case 'MOBILENET_ROAMING_CARDONE': {
        if (isSim1Active) {
          let status: string = telephonyData.isCellularDataRoamingEnabledSync(0) ? 'on' : 'off';
          ReportUtil.getInstance().delayReportSwitchButtonStateEvent(eventName, status);
        }
      }
        break;
      case 'MOBILENET_ROAMING_CARDTWO': {
        if (isSim2Active) {
          let status: string = telephonyData.isCellularDataRoamingEnabledSync(1) ? 'on' : 'off';
          ReportUtil.getInstance().delayReportSwitchButtonStateEvent(eventName, status);
        }
      }
        break;
      case 'MOBILENET_SWITCH_STATUS': {
        let status: string = telephonyData.isCellularDataEnabledSync() ? 'on' : 'off';
        ReportUtil.getInstance().delayReportSwitchButtonStateEvent(eventName, status);
      }
        break;
      case 'CALL_NUM_IDENTIFY_STATUS': {
        let value: string = settings.getValueSync(getContext(this), Constants.NUMBER_IDENTITY_KEY, '1');
        ReportUtil.getInstance().delayReportSwitchButtonStateEvent(eventName, value === '1' ? 'on' : 'off');
      }
        break;
      case 'CALL_AUTORECORD_STATUS': {
        commonController.getInstance().queryForConfig(this.context, (configData) => {
          let status: string = (!!configData.isOpen ? 'on' : 'off');
          ReportUtil.getInstance().delayReportSwitchButtonStateEvent(eventName, status);
        });
      }
        break;
      case 'CALL_HOLDSTATE_CARDONE': {
        this.getNetCapabilities((isWifi: boolean) => {
          if (!isWifi) {
            return;
          }
          if (isSim1Active) {
            getCallWaiting(0).then((res) => {
              if (res != undefined) {
                let callWaitingStatus: string = res == call.CallWaitingStatus.CALL_WAITING_ENABLE ? 'on' : 'off';
                ReportUtil.getInstance().delayReportSwitchButtonStateEvent(eventName, callWaitingStatus);
              }
              this.cardTwoCallHoldStateReport(isSim2Active);
            }).catch((error: BusinessError) => {
              LogUtils.e(TAG, 'callSettings:@ohos.telephony.call:getCallWaiting error: ' + JSON.stringify(error));
              this.cardTwoCallHoldStateReport(isSim2Active);
            });
          } else {
            this.cardTwoCallHoldStateReport(isSim2Active);
          }
        })
      }
        break;
      case 'CALL_FORWARDING_CARDONE': {
        this.getNetCapabilities((isWifi: boolean) => {
          if (!isWifi) {
            return;
          }
          checkCellularDataEnabled().then((res: boolean | BusinessError) => {
            let result: boolean = (typeof res === 'boolean') ? res : false;
            if (result) {
              if (isSim1Active) {
                this.getCardOneFourTypeCallTransfer(eventName, isSim2Active);
              } else if (!isSim1Active && isSim2Active) {
                this.getCardTwoFourTypeCallTransfer('CALL_FORWARDING_CARDTWO');
              }
            }
          }).catch((err: BusinessError) => {
            LogUtils.i(TAG, 'checkCellularDataEnabled response error' + JSON.stringify(err));
          })
        })
      }
        break;
      case 'CALL_NOTIFYTYPE_STATUS': {
        let value: string = settings.getValueSync(getContext(this), 'settings.telephony.callnotifytype', 'fullScreen');
        ReportUtil.getInstance().delayReportSwitchButtonStateEvent(eventName, value);
      }
        break;
      case 'CALL_HISTORYMERGE_STATUS': {
        let value: string = settings.getValueSync(getContext(this), 'settings.telephony.calllogmergetype', 'time');
        ReportUtil.getInstance().delayReportSwitchButtonStateEvent(eventName, value);
      }
        break;
      case 'CALL_IMPROVEQUALITY_STATUS': {
        let fusionCallSwitch: string = settings.getValueSync(this.context, 'fusion_call_switch',
          '0', settings.domainName.USER_PROPERTY);
        ReportUtil.getInstance().delayReportSwitchButtonStateEvent(eventName, fusionCallSwitch);
      }
        break;
      case 'CALL_SET_POWER_END_CALL_STATUS': {
        let endCallSwitch: string = settings.getValueSync(this.context, INCALL_POWER_KEY, '0',
          settings.domainName.USER_PROPERTY)
        ReportUtil.getInstance().delayReportSwitchButtonStateEvent(eventName, endCallSwitch);
      }
        break;
      case 'CALL_SET_VIDEO_RBT_STATUS': {
        let videoRingToneSwitch: string = settings.getValueSync(this.context, VIDEO_RING_TONE_SETTINGS, '1',
          settings.domainName.USER_PROPERTY);
        ReportUtil.getInstance().delayReportSwitchButtonStateEvent(eventName, videoRingToneSwitch);
      }
        break;
      case 'NEW_CALLING_SWITCH_STATE': {
        if (isSim1Active) {
          getSimCardPhoneNumber(0).then(async (res: string) => {
            let uri = 'datashare:///com.ohos.newcallingdcsdk';
            let helper: dataShare.DataShareHelper = await dataShare.createDataShareHelper(this.context, uri);
            let result = await helper.query(`${uri}?number=${encodeURIComponent(res)}`,
              new dataSharePredicates.DataSharePredicates(), [])
            let isNewCall = result.goToFirstRow() ? result.getLong(0) : 1;
            ReportUtil.getInstance().delayReportNewCallingState(eventName, isNewCall, 0);
          }).catch((err: BusinessError) => {
            LogUtils.i(TAG, `getSimCardPhoneNumber card1 other catch ${err.message} error code ${err.code} `);
          });
        }
        if (isSim2Active) {
          getSimCardPhoneNumber(1).then(async (res: string) => {
            let uri = 'datashare:///com.ohos.newcallingdcsdk';
            let helper: dataShare.DataShareHelper = await dataShare.createDataShareHelper(this.context, uri);
            let result = await helper.query(`${uri}?number=${encodeURIComponent(res)}`,
              new dataSharePredicates.DataSharePredicates(), [])
            let isNewCall = result.goToFirstRow() ? result.getLong(0) : 1;
            ReportUtil.getInstance().delayReportNewCallingState(eventName, isNewCall, 1);
          }).catch((err: BusinessError) => {
            LogUtils.i(TAG, `getSimCardPhoneNumber card2 other catch ${err.message} error code ${err.code} `);
          });
        }
      }
        break;
      default:
        break;
    }
  }

  async getCardOneFourTypeCallTransfer(eventName: string, isSim2Active: boolean) {
    let callTransferStatus: string = '';
    try {
      let res0 = await call.getCallTransferInfo(0, 0);
      if (res0) {
        callTransferStatus += res0.status === call.TransferStatus.TRANSFER_DISABLE ? '0' : '1';
      }
      let res1 = await call.getCallTransferInfo(0, 1);
      if (res1) {
        callTransferStatus += res1.status === call.TransferStatus.TRANSFER_DISABLE ? '0' : '1';
      }
      let res2 = await call.getCallTransferInfo(0, 2);
      if (res2) {
        callTransferStatus += res2.status === call.TransferStatus.TRANSFER_DISABLE ? '0' : '1';
      }
      let res3 = await call.getCallTransferInfo(0, 3);
      if (res3) {
        callTransferStatus += res3.status === call.TransferStatus.TRANSFER_DISABLE ? '0' : '1';
      }
      if (callTransferStatus !== '') {
        ReportUtil.getInstance().delayReportSwitchButtonStateEvent(eventName, callTransferStatus);
      }
      if (isSim2Active) {
        this.getCardTwoFourTypeCallTransfer('CALL_FORWARDING_CARDTWO');
      }
    } catch (err) {
      LogUtils.e(TAG, 'getFourTypeCallTransfer error: ' + JSON.stringify(err));
    }
  }

  async getCardTwoFourTypeCallTransfer(eventName: string) {
    let callTransferStatus: string = '';
    try {
      let res0 = await call.getCallTransferInfo(1, 0);
      if (res0) {
        callTransferStatus += res0.status === call.TransferStatus.TRANSFER_DISABLE ? '0' : '1';
      }
      let res1 = await call.getCallTransferInfo(1, 1);
      if (res1) {
        callTransferStatus += res1.status === call.TransferStatus.TRANSFER_DISABLE ? '0' : '1';
      }
      let res2 = await call.getCallTransferInfo(1, 2);
      if (res2) {
        callTransferStatus += res2.status === call.TransferStatus.TRANSFER_DISABLE ? '0' : '1';
      }
      let res3 = await call.getCallTransferInfo(1, 3);
      if (res3) {
        callTransferStatus += res3.status === call.TransferStatus.TRANSFER_DISABLE ? '0' : '1';
      }
      if (callTransferStatus !== '') {
        ReportUtil.getInstance().delayReportSwitchButtonStateEvent(eventName, callTransferStatus);
      }
    } catch (err) {
      LogUtils.e(TAG, 'getCardTwoFourTypeCallTransfer error: ' + JSON.stringify(err));
    }
  }

  private cardTwoCallHoldStateReport(isSim2Active: boolean) {
    if (isSim2Active) {
      getCallWaiting(1).then((res) => {
        if (res != undefined) {
          let callWaitingStatus: string = res == call.CallWaitingStatus.CALL_WAITING_ENABLE ? 'on' : 'off';
          ReportUtil.getInstance().delayReportSwitchButtonStateEvent('CALL_HOLDSTATE_CARDTWO', callWaitingStatus);
        }
      }).catch((error: BusinessError) => {
        LogUtils.e(TAG, 'callSettings:@ohos.telephony.call:getCallWaiting error: ' + JSON.stringify(error));
      });
    }
  }

  private getNetCapabilities(callback: (isWifi: boolean) => void) {
    LogUtils.i(TAG, 'getNetCapabilities')
    connection.getDefaultNet().then((netHandle: connection.NetHandle) => {
      if (netHandle.netId == 0) {
        LogUtils.i(TAG, 'getDefaultNet error')
        callback(false);
        return;
      }
      connection.getNetCapabilities(netHandle, (error: BusinessError, data: connection.NetCapabilities) => {
        if (error) {
          LogUtils.e(TAG, `Failed to get net capabilities. Code:${error.code}, message:${error.message}`);
          callback(false);
          return;
        }
        for (let type of data.bearerTypes) {
          if (type === connection.NetBearType.BEARER_WIFI) {
            LogUtils.i(TAG, 'Succeeded to get data isWifi');
            callback(true);
            return;
          }
        }
        LogUtils.i(TAG, 'Succeeded to get data is no wifi');
        callback(false);
      })
    }).catch((error: BusinessError) => {
      LogUtils.e(TAG, `get net capabilities error. Code:${error.code}, message:${error.message}`);
      callback(false);
    });
  }
}


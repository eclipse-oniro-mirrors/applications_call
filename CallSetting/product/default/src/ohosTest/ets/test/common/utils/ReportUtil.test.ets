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

import { describe, it, expect } from '@ohos/hypium';
import { ReportUtil, CallSettingGlobalContextHelper, SatelliteSimCardInfoStruct } from '@ohos/common/CommonIndex';
import { common } from '@kit.AbilityKit';
import * as CallSettingsConstant from '../../../../../main/ets/common/constant/CallSettingsConstant';
import { sleep } from './Sleep';
import CallSettingVM from '../../../../../main/ets/viewModel/CallSettingVM';

let ReportUtilTest_reportDrawnCompleted = () => {
  let context = CallSettingGlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT);
  let result = ReportUtil.reportDrawnCompleted(1, context);
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportClickCallHistoryMerge = () => {
  let result = ReportUtil.getInstance().reportClickCallHistoryMerge();
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportHistoryMergeAction = () => {
  let result = ReportUtil.getInstance().reportHistoryMergeAction(0);
  expect(result == null).assertTrue();
  sleep(1000);
  result = ReportUtil.getInstance().reportHistoryMergeAction(1);
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportClickAutoRecord = () => {
  let result = ReportUtil.getInstance().reportClickAutoRecord();
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportClickUnLockNotify = () => {
  let result = ReportUtil.getInstance().reportClickUnLockNotify();
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportNotifyTypeAction = () => {
  let result = ReportUtil.getInstance().reportNotifyTypeAction(0);
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportClickIncomingRingTone = () => {
  let result = ReportUtil.getInstance()
    .reportClickIncomingRingTone(CallSettingVM.getInstance().simRingtoneOne,
      CallSettingVM.getInstance().simRingtoneOne);
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportClickMore = () => {
  let result = ReportUtil.getInstance().reportClickMore(0)
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportCallWaitingState = () => {
  let result = ReportUtil.getInstance().reportCallWaitingState(1)
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportClickVoiceMail = () => {
  let result = ReportUtil.getInstance().reportClickVoiceMail(0)
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportCallBarringAction = () => {
  let result = ReportUtil.getInstance().reportCallBarringAction(-1, 0)
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportClickForwarding = () => {
  let result = ReportUtil.getInstance().reportClickForwarding(0)
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportCallForwardingSetAction = () => {
  let result = ReportUtil.getInstance().reportCallForwardingSetAction(-1, 0)
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportClickIncomingRejectSms = () => {
  let result = ReportUtil.getInstance().reportClickIncomingRejectSms()
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportClickSpeedDial = () => {
  let result = ReportUtil.getInstance().reportClickSpeedDial()
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportSpeedDialSetSerialNum = () => {
  let result = ReportUtil.getInstance().reportSpeedDialSetSerialNum(0)
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportClickAbout = () => {
  let result = ReportUtil.getInstance().reportClickAbout()
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportSetMobileNetworkSwitch = () => {
  let result = ReportUtil.getInstance().reportSetMobileNetworkSwitch(1)
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportCheckApnList = () => {
  let result = ReportUtil.getInstance().reportCheckApnList(0)
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportClickMobileRoamingButton = () => {
  let result = ReportUtil.getInstance().reportClickMobileRoamingButton(1, 1)
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportEnterSatelliteCall = () => {
  let result = ReportUtil.getInstance().reportEnterSatelliteCall(1)
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportSatelliteCallSelectSimCardAlert = () => {
  let result = ReportUtil.getInstance().reportSatelliteCallSelectSimCardAlert(1)
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportOpenSatelliteCallIssue = () => {
  let result = ReportUtil.getInstance().reportOpenSatelliteCallIssue(1)
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportClickUserProtocol = () => {
  let result = ReportUtil.getInstance().reportClickUserProtocol()
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportClickDisableProtocolBtn = () => {
  let result = ReportUtil.getInstance().reportClickDisableProtocolBtn(2)
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportClickUserPrivacy = () => {
  let result = ReportUtil.getInstance().reportClickUserPrivacy()
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportClickDisablePrivacyBtn = () => {
  let result = ReportUtil.getInstance().reportClickDisablePrivacyBtn(2)
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportClickUserPermissions = () => {
  let result = ReportUtil.getInstance().reportClickUserPermissions()
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportEnterSatelliteIsNeedCalibration = () => {
  let result = ReportUtil.getInstance().reportEnterSatelliteIsNeedCalibration(0)
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportSatelliteCalibrationInfo = () => {
  let result = ReportUtil.getInstance().reportSatelliteCalibrationInfo(0, 0)
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportSatelliteLoadingInfo = () => {
  let result = ReportUtil.getInstance().reportSatelliteLoadingInfo(0, 0)
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportSatelliteConnectInfo = () => {
  let result = ReportUtil.getInstance().reportSatelliteConnectInfo(0, 0)
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportSatelliteSignalChange = () => {
  let result = ReportUtil.getInstance().reportSatelliteSignalChange(4, 0, 0)
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportSatelliteConnectedClickMessage = () => {
  let result = ReportUtil.getInstance().reportSatelliteConnectedClickMessage()
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportSatelliteConnectedClickPhone = () => {
  let result = ReportUtil.getInstance().reportSatelliteConnectedClickPhone()
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportSatelliteClickReConnectingBtn = () => {
  let result = ReportUtil.getInstance().reportSatelliteClickReConnectingBtn()
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportSatelliteClickReSearchBtn = () => {
  let result = ReportUtil.getInstance().reportSatelliteClickReSearchBtn()
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportOpenSatelliteSimCardInfo = () => {
  let simCardInfoList: SatelliteSimCardInfoStruct[] = [];
  let result = ReportUtil.getInstance().reportOpenSatelliteSimCardInfo(simCardInfoList)
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportSatelliteHighTempDial = () => {
  let result = ReportUtil.getInstance().reportSatelliteHighTempDial()
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportSatelliteClickHighTempInCall = () => {
  let result = ReportUtil.getInstance().reportSatelliteClickHighTempInCall()
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportSatelliteCallQuit = () => {
  let result = ReportUtil.getInstance().reportSatelliteCallQuit(1)
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportSatelliteErrorCode = () => {
  let result = ReportUtil.getInstance().reportSatelliteErrorCode(1)
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportClickCreateApn = () => {
  let result = ReportUtil.getInstance().reportClickCreateApn()
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportClickResetDefaultApn = () => {
  let result = ReportUtil.getInstance().reportClickResetDefaultApn()
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportClickAvailableNetSwitch = () => {
  let result = ReportUtil.getInstance().reportClickAvailableNetSwitch(0)
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportClickCommonQuestion = () => {
  let result = ReportUtil.getInstance().reportClickCommonQuestion()
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportSatelliteChangeFloatWindow = () => {
  let result = ReportUtil.getInstance().reportSatelliteChangeFloatWindow()
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportSatelliteNotConnectedForOneMinute = () => {
  let result = ReportUtil.getInstance().reportSatelliteNotConnectedForOneMinute(1)
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportClickSatelliteRecalibrateBtn = () => {
  let result = ReportUtil.getInstance().reportClickSatelliteRecalibrateBtn()
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportSatelliteCallDisconnectWithCause = () => {
  let result = ReportUtil.getInstance().reportSatelliteCallDisconnectWithCause(24)
  expect(result == null).assertTrue();
}

let ReportUtilTest_delayReportSwitchButtonStateEvent = () => {
  let result = ReportUtil.getInstance().delayReportSwitchButtonStateEvent('test', 'on')
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportSatelliteOpenDialog = () => {
  let result = ReportUtil.getInstance().reportSatelliteOpenDialog()
  expect(result == null).assertTrue();
}

let ReportUtilTest_reportOpenSatelliteDialogAction = () => {
  let result = ReportUtil.getInstance().reportOpenSatelliteDialogAction(1)
  expect(result == null).assertTrue();
}

export default function ReportUtilTest() {
  let context = CallSettingGlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT);
  describe('ReportUtilTest', () => {
    it('ReportUtilTest_reportDrawnCompleted', 0, () => {
      ReportUtilTest_reportDrawnCompleted();
    });
    it('ReportUtilTest_reportClickCallHistoryMerge', 0, () => {
      ReportUtilTest_reportClickCallHistoryMerge();
    });
    it('ReportUtilTest_reportHistoryMergeAction', 0, () => {
      ReportUtilTest_reportHistoryMergeAction();
    });
    it('ReportUtilTest_reportClickAutoRecord', 0, () => {
      ReportUtilTest_reportClickAutoRecord();
    });
    it('ReportUtilTest_reportClickUnLockNotify', 0, () => {
      ReportUtilTest_reportClickUnLockNotify();
    });
    it('ReportUtilTest_reportNotifyTypeAction', 0, () => {
      ReportUtilTest_reportNotifyTypeAction();
    });
    it('ReportUtilTest_reportClickIncomingRingTone', 0, () => {
      ReportUtilTest_reportClickIncomingRingTone();
    });
    it('ReportUtilTest_reportClickMore', 0, () => {
      ReportUtilTest_reportClickMore();
    });
    it('ReportUtilTest_reportCallWaitingState', 0, () => {
      ReportUtilTest_reportCallWaitingState();
    });
    it('ReportUtilTest_reportClickVoiceMail', 0, () => {
      ReportUtilTest_reportClickVoiceMail();
    });
    it('ReportUtilTest_reportCallBarringAction', 0, () => {
      ReportUtilTest_reportCallBarringAction();
    });
    it('ReportUtilTest_reportClickForwarding', 0, () => {
      ReportUtilTest_reportClickForwarding();
    });
    it('ReportUtilTest_reportCallForwardingSetAction', 0, () => {
      ReportUtilTest_reportCallForwardingSetAction();
    });
    it('ReportUtilTest_reportClickIncomingRejectSms', 0, () => {
      ReportUtilTest_reportClickIncomingRejectSms();
    });
    it('ReportUtilTest_reportClickSpeedDial', 0, () => {
      ReportUtilTest_reportClickSpeedDial();
    });
    it('ReportUtilTest_reportSpeedDialSetSerialNum', 0, () => {
      ReportUtilTest_reportSpeedDialSetSerialNum();
    });
    it('ReportUtilTest_reportClickAbout', 0, () => {
      ReportUtilTest_reportClickAbout();
    });
    it('ReportUtilTest_reportSetMobileNetworkSwitch', 0, () => {
      ReportUtilTest_reportSetMobileNetworkSwitch();
    });
    it('ReportUtilTest_reportCheckApnList', 0, () => {
      ReportUtilTest_reportCheckApnList();
    });
    it('ReportUtilTest_reportClickMobileRoamingButton', 0, () => {
      ReportUtilTest_reportClickMobileRoamingButton();
    });
    it('ReportUtilTest_reportEnterSatelliteCall', 0, () => {
      ReportUtilTest_reportEnterSatelliteCall();
    });
    it('ReportUtilTest_reportSatelliteCallSelectSimCardAlert', 0, () => {
      ReportUtilTest_reportSatelliteCallSelectSimCardAlert();
    });
    it('ReportUtilTest_reportOpenSatelliteCallIssue', 0, () => {
      ReportUtilTest_reportOpenSatelliteCallIssue();
    });
    it('ReportUtilTest_reportClickUserProtocol', 0, () => {
      ReportUtilTest_reportClickUserProtocol();
    });
    it('ReportUtilTest_reportClickDisableProtocolBtn', 0, () => {
      ReportUtilTest_reportClickDisableProtocolBtn();
    });
    it('ReportUtilTest_reportClickUserPrivacy', 0, () => {
      ReportUtilTest_reportClickUserPrivacy();
    });
    it('ReportUtilTest_reportClickDisablePrivacyBtn', 0, () => {
      ReportUtilTest_reportClickDisablePrivacyBtn();
    });
    it('ReportUtilTest_reportClickUserPermissions', 0, () => {
      ReportUtilTest_reportClickUserPermissions();
    });
    it('ReportUtilTest_reportEnterSatelliteIsNeedCalibration', 0, () => {
      ReportUtilTest_reportEnterSatelliteIsNeedCalibration();
    });
    it('ReportUtilTest_reportSatelliteCalibrationInfo', 0, () => {
      ReportUtilTest_reportSatelliteCalibrationInfo();
    });
    it('ReportUtilTest_reportSatelliteLoadingInfo', 0, () => {
      ReportUtilTest_reportSatelliteLoadingInfo();
    });
    it('ReportUtilTest_reportSatelliteConnectInfo', 0, () => {
      ReportUtilTest_reportSatelliteConnectInfo();
    });
    it('ReportUtilTest_reportSatelliteSignalChange', 0, () => {
      ReportUtilTest_reportSatelliteSignalChange();
    });
    it('ReportUtilTest_reportSatelliteConnectedClickMessage', 0, () => {
      ReportUtilTest_reportSatelliteConnectedClickMessage();
    });
    it('ReportUtilTest_reportSatelliteConnectedClickPhone', 0, () => {
      ReportUtilTest_reportSatelliteConnectedClickPhone();
    });
    it('ReportUtilTest_reportSatelliteClickReConnectingBtn', 0, () => {
      ReportUtilTest_reportSatelliteClickReConnectingBtn();
    });
    it('ReportUtilTest_reportSatelliteClickReSearchBtn', 0, () => {
      ReportUtilTest_reportSatelliteClickReSearchBtn();
    });
    it('ReportUtilTest_reportOpenSatelliteSimCardInfo', 0, () => {
      ReportUtilTest_reportOpenSatelliteSimCardInfo();
    });
    it('ReportUtilTest_reportSatelliteHighTempDial', 0, () => {
      ReportUtilTest_reportSatelliteHighTempDial();
    });
    it('ReportUtilTest_reportSatelliteClickHighTempInCall', 0, () => {
      ReportUtilTest_reportSatelliteClickHighTempInCall();
    });
    it('ReportUtilTest_reportSatelliteCallQuit', 0, () => {
      ReportUtilTest_reportSatelliteCallQuit();
    });
    it('ReportUtilTest_reportSatelliteErrorCode', 0, () => {
      ReportUtilTest_reportSatelliteErrorCode();
    });
    it('ReportUtilTest_reportClickCreateApn', 0, () => {
      ReportUtilTest_reportClickCreateApn();
    });
    it('ReportUtilTest_reportClickResetDefaultApn', 0, () => {
      ReportUtilTest_reportClickResetDefaultApn();
    });
    it('ReportUtilTest_reportClickAvailableNetSwitch', 0, () => {
      ReportUtilTest_reportClickAvailableNetSwitch();
    });
    it('ReportUtilTest_reportClickCommonQuestion', 0, () => {
      ReportUtilTest_reportClickCommonQuestion();
    });
    it('ReportUtilTest_reportSatelliteChangeFloatWindow', 0, () => {
      ReportUtilTest_reportSatelliteChangeFloatWindow();
    });
    it('ReportUtilTest_reportSatelliteNotConnectedForOneMinute', 0, () => {
      ReportUtilTest_reportSatelliteNotConnectedForOneMinute();
    });
    it('ReportUtilTest_reportClickSatelliteRecalibrateBtn', 0, () => {
      ReportUtilTest_reportClickSatelliteRecalibrateBtn();
    });
    it('ReportUtilTest_reportSatelliteCallDisconnectWithCause', 0, () => {
      ReportUtilTest_reportSatelliteCallDisconnectWithCause();
    });
    it('ReportUtilTest_delayReportSwitchButtonStateEvent', 0, () => {
      ReportUtilTest_delayReportSwitchButtonStateEvent();
    });
    it('ReportUtilTest_reportSatelliteOpenDialog', 0, () => {
      ReportUtilTest_reportSatelliteOpenDialog();
    });
    it('ReportUtilTest_reportOpenSatelliteDialogAction', 0, () => {
      ReportUtilTest_reportOpenSatelliteDialogAction();
    });
    it('ReportUtilTest_reportDrawnCompleted1', 0, () => {
      let sate: SatelliteSimCardInfoStruct = {
        slotId: 0,
        showNumber: '',
        isChecked: false,
        isHyacinthChecked: false,
        isPreferences: false,
        iMsi: ''
      }
      let sate1: SatelliteSimCardInfoStruct = {
        slotId: 1,
        showNumber: '',
        isChecked: false,
        isHyacinthChecked: false,
        isPreferences: false,
        iMsi: ''
      }
      let sate2: SatelliteSimCardInfoStruct = {
        slotId: 1,
        showNumber: '',
        isChecked: false,
        isHyacinthChecked: false,
        isPreferences: false,
        iMsi: ''
      }
      let arr: SatelliteSimCardInfoStruct[] = [sate, sate1,sate2];
      ReportUtil.reportDrawnCompleted(0, context);
      ReportUtil.getInstance().reportSatelliteSignalChange(0, 0, 0);
      ReportUtil.getInstance().reportOpenSatelliteSimCardInfo(arr);
      ReportUtil.getInstance().satelliteUseStartTime = 1;
      ReportUtil.getInstance().reportImproveCallQualityStatus(true);
      ReportUtil.getInstance().reportImproveCallQualityStatus(false);
      let result = ReportUtil.getInstance().reportSatelliteCallQuit(1);
      expect(result === null).assertFalse();
    });
  });
}

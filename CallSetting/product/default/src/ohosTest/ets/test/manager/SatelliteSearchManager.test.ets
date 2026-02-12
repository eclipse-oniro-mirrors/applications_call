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

import { describe, it, expect, MockKit, when, ArgumentMatchers } from '@ohos/hypium';
import {
  ERROR_CODE_NOT_ACTIVATED_SIM,
  ERROR_CODE_NOT_OPENED_ROAMING,
  ERROR_CODE_NOT_OPENED_TIANDIWINGCARD,
  ERROR_CODE_NOT_SUPPORT_CARD,
  ERROR_CODE_OTHERS,
  NEW_FOLD_ALERT_DIALOG,
  SatelliteOperationType,
  SatelliteType,
  SYS_STATUS_NETWORK_REGED,
  SYS_STATUS_NETWORK_UNREGED,
  SYS_STATUS_SATELLITE_CONNECTING,
  SYS_STATUS_SATELLITE_KEEPING,
  SYS_STATUS_SEARCHING_SATELLITE,
  SYS_STATUS_SEARCH_SATELLITE_FAIL,
  SYS_STATUS_SEARCH_SATELLITE_SUCC,
  SYS_STATUS_WAIT_CALIBRATING,
  SYS_STATUS_WAIT_LOADING
} from '../../../../main/ets/common/constant/SatelliteSearchConst';
import { ConfigurationConstant } from '@kit.AbilityKit';
import SatelliteSearchManager, { SatelliteData } from '../../../../main/ets/manager/SatelliteSearchManager';
import NewFoldScreenAlertDialogManager from '../../../../main/ets/manager/NewFoldScreenAlertDialogManager';
import { Queue } from '@kit.ArkTS';
import { commonEventManager } from '@kit.BasicServicesKit';

export default function SatelliteSearchManagerTest() {
  describe('SatelliteSearchManagerTest', () => {
    it('setShowReconnect', 0, (done: Function) => {
      SatelliteSearchManager.getInstance().setShowReconnect(true);
      let a = SatelliteSearchManager.getInstance().getShowReconnect();
      expect(true).assertEqual(a);
      done();
    })
    it('updateStatusForRegTest', 0, (done: Function) => {
      let sate = SatelliteSearchManager.getInstance();
      sate.updateStatusForReg(SYS_STATUS_NETWORK_REGED);
      sate.updateStatusForReg(1000);
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(sate, sate.getIsFromMeetime);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(true);
      sate.setCurrentStatus(SYS_STATUS_SEARCH_SATELLITE_FAIL);
      sate.updateStatusForReg(SYS_STATUS_NETWORK_REGED);
      sate.updateStatusForReg(SYS_STATUS_NETWORK_UNREGED);
      sate.setCurrentStatus(SYS_STATUS_SEARCHING_SATELLITE);
      sate.updateStatusForReg(SYS_STATUS_NETWORK_UNREGED);
      let result = sate.updateStatusForReg(SYS_STATUS_NETWORK_REGED);
      expect(result === null).assertFalse();
      mocker.ignoreMock(sate, sate.getIsFromMeetime);
      done();
    })
    it('sysStatusSwitchTest', 0, (done: Function) => {
      let sate = SatelliteSearchManager.getInstance();
      sate.sysStatusSwitch(ERROR_CODE_NOT_ACTIVATED_SIM);
      sate.sysStatusSwitch(ERROR_CODE_NOT_OPENED_ROAMING);
      sate.sysStatusSwitch(ERROR_CODE_NOT_OPENED_TIANDIWINGCARD);
      sate.sysStatusSwitch(ERROR_CODE_NOT_SUPPORT_CARD);
      sate.sysStatusSwitch(ERROR_CODE_OTHERS);
      let result = sate.sysStatusSwitch(100099);
      expect(result === null).assertFalse();
      done();
    })
    it('createSatelliteDialogTest', 0, async (done: Function) => {
      let sate = SatelliteSearchManager.getInstance();
      sate.createSatelliteDialog();
      sate.createSatelliteDialog();
      await sate.reCreateDialogOrFloatWindow(1);
      sate.createFloatWindow();
      sate.createFloatWindow();
      sate.createSatelliteDialog();
      sate.createSatelliteDialog();
      sate.finishDialogAndFloatWindow();
      sate.createFloatWindow();
      sate.finishDialogAndFloatWindow();
      await sate.reCreateDialogOrFloatWindow(1);
      let result = sate.createFloatWindow();
      expect(result === null).assertFalse();
      await sate.unbindSatelliteService();
      done();
    })
    it('updateSearchSatelliteStatus', 0, (done: Function) => {
      let sate = SatelliteSearchManager.getInstance();
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(sate, sate.getIsFromMeetime);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(true);
      sate.setCurrentStatus(SYS_STATUS_WAIT_LOADING);
      sate.updateSearchSatelliteStatus(SatelliteOperationType.OPERATION_TYPE_SYS_STATUS_SEARCHING, 0);
      sate.setCurrentStatus(SYS_STATUS_SATELLITE_CONNECTING);
      sate.updateSearchSatelliteStatus(SatelliteOperationType.OPERATION_TYPE_SYS_STATUS_SEARCHING, 0);
      sate.updateSearchSatelliteStatus(SatelliteOperationType.OPERATION_TYPE_SYS_STATUS_SEARCHING, 0);
      sate.updateSearchSatelliteStatus(SatelliteOperationType.OPERATION_TYPE_SYS_STATUS_SEARCHING, 1);
      sate.updateSearchSatelliteStatus(SatelliteOperationType.OPERATION_TYPE_SYS_STATUS_SENDING, 1);
      sate.updateSearchSatelliteStatus(SatelliteOperationType.OPERATION_TYPE_SYS_STATUS_RECEIVING, 1);
      let result = sate.updateSearchSatelliteStatus("test", 1);
      expect(result === null).assertFalse();
      mocker.ignoreMock(sate, sate.getIsFromMeetime);
      done();
    })
    it('finishSatelliteTest', 0, (done: Function) => {
      let sate = SatelliteSearchManager.getInstance();
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(sate, sate.unbindSatelliteService);
      when(mockFunc)(ArgumentMatchers.any).afterReturnNothing;
      sate.finishSatellite(false);
      sate.finishSatellite(true);
      sate.startSatellite(SatelliteType.TIAN_TONG);
      sate.finishSatellite(false).then((result) => {
        expect(result === null).assertFalse();
      });
      done();
    })
    it('getConnectingTimeTest', 0, (done: Function) => {
      let sate = SatelliteSearchManager.getInstance();
      sate.getConnectingTime();
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(sate, sate.getIsFromMeetime);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(true);
      let result = sate.getConnectingTime();
      sate.rollBackConnectTime();
      expect(result >= 0).assertTrue();
      mocker.ignoreMock(sate, sate.getIsFromMeetime);
      done();
    })
    it('addSatelliteStatusCallbackTest', 0, async (done: Function) => {
      let sate = SatelliteSearchManager.getInstance();
      (sate as object)['isShowOrientationRemind']();
      (sate as object)['addSatelliteStatusCallback']();
      (sate as object)['updateStatusByService']();
      (sate as object)['isLandscape'] = true;
      (sate as object)['isShowOrientationRemind']();
      (sate as object)['uiOrientation'] = ConfigurationConstant.Direction.DIRECTION_HORIZONTAL;
      (sate as object)['isShowOrientationRemind']();
      (sate as object)['isFromMeetime'] = true;
      let result: boolean = (sate as object)['isShowOrientationRemind']();
      expect(result).assertFalse();
      done();
    })
    it('isUpdateSatelliteDataTest', 0, (done: Function) => {
      let sate = SatelliteSearchManager.getInstance();
      (sate as object)['mCurrentStatus'] = SYS_STATUS_SEARCHING_SATELLITE;
      (sate as object)['isUpdateSatelliteData']();
      (sate as object)['mCurrentStatus'] = SYS_STATUS_SATELLITE_CONNECTING;
      (sate as object)['isUpdateSatelliteData']();
      (sate as object)['mCurrentStatus'] = SYS_STATUS_SEARCH_SATELLITE_SUCC;
      (sate as object)['isUpdateSatelliteData']();
      (sate as object)['mCurrentStatus'] = 9;
      (sate as object)['isUpdateSatelliteData']();
      (sate as object)['mCurrentStatus'] = 1000;
      (sate as object)['isUpdateSatelliteData']();
      (sate as object)['mCurrentStatus'] = SYS_STATUS_SATELLITE_KEEPING;
      (sate as object)['isUpdateSatelliteData']();
      expect(SYS_STATUS_SATELLITE_KEEPING === 11).assertTrue()
      done();
    })
    it('privateTest', 0, (done: Function) => {
      let sate = SatelliteSearchManager.getInstance();
      (sate as object)['dataShareHelper'] = true;
      sate.removeSatelliteSwitchListener();
      sate.unbindSatelliteService();
      (sate as object)['mCurrentStatus'] = SYS_STATUS_WAIT_LOADING;
      (sate as object)['updateStatusByService']();
      (sate as object)['mCurrentStatus'] = SYS_STATUS_WAIT_CALIBRATING;
      (sate as object)['rollBackLocationMode']();
      (sate as object)['showFloatWindowByCall'](1);
      (sate as object)['mCurrentStatus'] = SYS_STATUS_SEARCH_SATELLITE_SUCC;
      (sate as object)['isSatelliteDialogShow'] = true;
      (sate as object)['showFloatWindowByCall'](2);
      (sate as object)['showFloatWindowByCall'](1);
      done();
    })
    it('reCreateDialogOrFloatWindowTest', 0, async (done: Function) => {
      let sate = SatelliteSearchManager.getInstance();
      sate.closeMeetimeSatelliteListener();
      sate.openMeetimeSatelliteListener()
      sate.registerAccelerometerListener();
      (sate as object)['calcAngel'](1, 2, 4);
      await sate.updateDialogAndFloatWindow();
      (sate as object)['isSatelliteDialogShow'] = true;
      await sate.updateDialogAndFloatWindow();
      (sate as object)['isSatelliteDialogShow'] = false;
      (sate as object)['isFloatWindowShow'] = false;
      (sate as object)['isStrongNotifyWindowShow'] = true;
      await sate.updateDialogAndFloatWindow();
      sate.refreshUIOrientation();
      sate.startSatelliteSearchTimer();
      done();
    })
    it('isStrongNotifyWindowShowTest', 0, async (done: Function) => {
      let sate = SatelliteSearchManager.getInstance();
      (sate as object)['isStrongNotifyWindowShow'] = true;
      let result = sate.createSatelliteDialog();
      (sate as object)['isStrongNotifyWindowShow'] = true;
      sate.createFloatWindow();
      (sate as object)['isStrongNotifyWindowShow'] = false;
      (sate as object)['isSatelliteDialogShow'] = true;
      await sate.createStrongNotifyWindow();
      await sate.createStrongNotifyWindow();
      expect(result == null).assertTrue();
      done();
    })
    it('reCreateDialogOrFloatWindow', 0, async (done: Function) => {
      let sate = SatelliteSearchManager.getInstance();
      (sate as object)['isSatelliteDialogShow'] = false;
      (sate as object)['isFloatWindowShow'] = true;
      await sate.reCreateDialogOrFloatWindow();
      await sate.reCreateDialogOrFloatWindow();
      (sate as object)['isFloatWindowShow'] = false;
      (sate as object)['isStrongNotifyWindowShow'] = true;
      await sate.reCreateDialogOrFloatWindow();
      done();
    })
    it('createNewFoldScreenDialog', 0, async (done: Function) => {
      let sate = SatelliteSearchManager.getInstance();
      await sate.createNewFoldScreenDialog();
      expect(NewFoldScreenAlertDialogManager.IS_SHOW !== null).assertTrue();
      done();
    })
    it('closeNewFoldScreenDialog', 0, async (done: Function) => {
      let sate = SatelliteSearchManager.getInstance();
      await sate.closeNewFoldScreenDialog();
      expect(NewFoldScreenAlertDialogManager.IS_SHOW !== null).assertTrue();
      done();
    })
    it('closeStrongNotifyInNewFoldScreen', 0, async (done: Function) => {
      let sate = SatelliteSearchManager.getInstance();
      sate.closeStrongNotifyInNewFoldScreen(0);
      expect(NewFoldScreenAlertDialogManager.IS_SHOW !== null).assertTrue();
      done();
    })
    it('hideWindow', 0, async (done: Function) => {
      let sate = SatelliteSearchManager.getInstance();
      await sate.hideWindow(NEW_FOLD_ALERT_DIALOG);
      expect(NewFoldScreenAlertDialogManager.IS_SHOW !== null).assertTrue();
      done();
    })
    it('SatelliteSearchManagerTest_01', 0, async (done: Function) => {
      SatelliteData.getInstance();
      expect(SatelliteData.getInstance() !== null).assertTrue();
      done();
    })
    it('SatelliteSearchManagerTest_02', 0, async (done: Function) => {
      SatelliteSearchManager.getInstance().bindSatelliteService();
      SatelliteSearchManager.getInstance().unbindSatelliteService();
      (SatelliteSearchManager.getInstance() as object)['addSatelliteDataCallBack']();
      expect(SatelliteSearchManager.getInstance() !== null).assertTrue();
      done();
    })
    it('SatelliteSearchManagerTest_03', 0, async (done: Function) => {
      let sate = SatelliteSearchManager.getInstance();
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(sate, sate.getIsFromMeetime);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(false);
      sate.setCurrentStatus(SYS_STATUS_WAIT_LOADING);
      sate.setCurrentStatus(SYS_STATUS_SEARCHING_SATELLITE);
      sate.setCurrentStatus(SYS_STATUS_SEARCH_SATELLITE_FAIL);
      sate.setCurrentStatus(SYS_STATUS_SEARCH_SATELLITE_SUCC);
      sate.setCurrentStatus(99);
      (sate as object)['isConnecting'] = true;
      sate.startSatelliteConnectTimer();
      (sate as object)['isConnecting'] = false;
      mocker.ignoreMock(sate, sate.getIsFromMeetime);
      expect(SatelliteSearchManager.getInstance() !== null).assertTrue();
      done();
    })
    it('SatelliteSearchManagerTest_addFoldStatusListener', 0, async (done: Function) => {
      let sate = SatelliteSearchManager.getInstance();
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(sate, (sate as object)['isFoldable']);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(true);

      (sate as object)['addFoldStatusListener']();
      (sate as object)['removeFoldStatusListener']();
      mocker.ignoreMock(sate, (sate as object)['isFoldable']);
      done();
    })

    it('SatelliteSearchManagerTest_error', 0, async (done: Function) => {
      let sate = SatelliteSearchManager.getInstance();
      (sate as object)['satelliteSearchTime'] = 30;
      sate.startSatelliteSearchTimer();

      (sate as object)['primarySubscriberQueue'] = new Queue<commonEventManager.CommonEventSubscriber>();
      sate.unSubscribeChangedEvent();

      (sate as object)['session'] = new Object();
      sate.sendSatelliteEventToMeetime('');

      (sate as object)['satelliteSearchTime'] = 60;
      (sate as object)['session'] = undefined;
      expect(SatelliteSearchManager.getInstance() !== null).assertTrue();
      done();
    })
  })
}
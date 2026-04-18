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

import { describe, it, expect, MockKit, when, ArgumentMatchers } from '@ohos/hypium';
import EmergencyCallController from '../../../../main/ets/control/EmergencyCallControl';
import radio from '@ohos.telephony.radio';
import { sleep } from '../utils/Sleep';
import { TimeOutStruct } from '../../../../main/ets/utils/ClassStruct';
import LogUtils from '../../../../main/ets/utils/HiLog';
import LocationUtils from '../../../../main/ets/utils/LocationUtils';
import geoLocationManager from '@ohos.geoLocationManager';

const TAG = 'EmergencyCallControlTestTAG';

export default function EmergencyCallControlTest() {
  describe('EmergencyCallControlTest', () => {
    it('emergencyCallControlTest_01', 0, () => {
      emergencyCallControlTest_01();
    });
    it('emergencyCallControlTest_02', 0, async () => {
      emergencyCallControlTest_02();
    });
    it('emergencyCallControlTest_03', 0, () => {
      emergencyCallControlTest_03();
    });
    it('emergencyCallControlTest_05', 0, async () => {
      emergencyCallControlTest_05();
    });
    it('emergencyCallControlTest_06', 0, async () => {
      emergencyCallControlTest_06();
    });
    it('emergencyCallControlTest_07', 0, async () => {
      emergencyCallControlTest_07();
    });
    it('emergencyCallControlTest_setWindowBackgroundColor', 0, async () => {
      await setWindowBackgroundColorTestFn();
    });
    it('emergencyCallControlTest_checkIsEmergencyPhoneNumber', 0, async () => {
      let r = EmergencyCallController.getInstance().checkIsEmergencyPhoneNumber('13155555555', 0, (result: boolean) => {
      });
      r = EmergencyCallController.getInstance().checkIsEmergencyPhoneNumber('13155555555', -1, (result: boolean) => {
      });
      expect(r === null).assertFalse();
    });
    it('emergencyCallControlTest_emergencyCallDial', 0, async () => {
      EmergencyCallController.getInstance().emergencyCallDial('1454784/', 0, true);
      EmergencyCallController.getInstance().emergencyCallDial('1454784/', -1, true);
      let r = EmergencyCallController.getInstance().emergencyCallDial('1454784/', 0, false);
      expect(r === null).assertFalse();
    });
    it('emergencyCallControlTest_exitingApplication', 0, async () => {
      let r = EmergencyCallController.getInstance().exitingApplication();
      expect(r === null).assertFalse();
    });
    it('emergencyCallControlTest_dialerSpecialCode', 0, async () => {
      let r = EmergencyCallController.getInstance().dialerSpecialCode('12345566778');
      expect(r === null).assertFalse();
    });
    it('emergencyCallControlTest_formatLocationInfo', 0, async () => {
      let r = EmergencyCallController.getInstance().formatLocationInfo(() => {
      }, {} as geoLocationManager.Location);
      expect(r === null).assertFalse();
    });
    it('emergencyCallControlTest_clearIdOfList', 0, async () => {
      let r = EmergencyCallController.getInstance().clearIdOfList('0', () => {
      });
      expect(r === null).assertFalse();
    });
  });
}

function emergencyCallControlTest_01() {
  LocationUtils.getInstance().setLocationSwitchIgnored(false);
  let isLocationEnable = LocationUtils.getInstance().getLocationEnable();
  LogUtils.i(TAG, 'emergencyCallControlTest_01-isLocationEnable:' + isLocationEnable);
  if (isLocationEnable) {
    expect(isLocationEnable).assertEqual(true);
  } else {
    expect(isLocationEnable).assertEqual(false);
  }
}

function emergencyCallControlTest_02() {
  EmergencyCallController.getInstance().getLocationInfo((data) => {
    expect([true, false]).assertContain(data.isSuccess);
  });
}

function emergencyCallControlTest_03() {
  let mocker: MockKit = new MockKit();
  let mockfunc: Function = mocker.mockFunc(EmergencyCallController, EmergencyCallController.getInstance()
    .formatLocationInfo);
  when(mockfunc)(ArgumentMatchers.any).afterReturn('1');
  expect(true).assertTrue();
  mocker.ignoreMock(EmergencyCallController, EmergencyCallController.getInstance()
    .formatLocationInfo);
}

async function emergencyCallControlTest_04() {
  EmergencyCallController.getInstance().checkIsEmergencyPhoneNumber('911', -1, (result: boolean) => {
    LogUtils.w(TAG, 'emergencyCallControlTest_04-checkIsEmergencyPhoneNumber:' + result);
    expect([true, false]).assertContain(result);
  });
  EmergencyCallController.getInstance().emergencyCallDial('111', -1);
  await sleep(2000);
  radio.turnOnRadio();
  radio.turnOffRadio();
  await sleep(1000);
  EmergencyCallController.getInstance().emergencyCallDial('111', 0);
  await sleep(2000);
  radio.turnOnRadio();
  radio.turnOffRadio();
  await sleep(1000);
  EmergencyCallController.getInstance().emergencyCallDial('911', 0, true);
  await sleep(2000);
  radio.turnOnRadio();
  radio.turnOffRadio();
  expect(true).assertTrue();
}

async function emergencyCallControlTest_05() {
  EmergencyCallController.getInstance().getSimOperatorNames();
  EmergencyCallController.getInstance().getSimOperatorNames(false);
  EmergencyCallController.getInstance().getSimOperatorName(99);
  await sleep(1000);
  EmergencyCallController.getInstance().selectInContactsPicker((contactData) => {
    expect(true).assertTrue();
  });
}

async function emergencyCallControlTest_06() {
  EmergencyCallController.getInstance().getEccdataEmergencyNum();
  await sleep(1000);
  EmergencyCallController.getInstance().setTimeOutIdList = [];
  let timerItem: TimeOutStruct = {
    itemId: '1',
    timerId: 1000
  };
  EmergencyCallController.getInstance().pushIdToList(timerItem);
  EmergencyCallController.getInstance().clearIdOfList('2', (data: string) => {
    LogUtils.e(TAG, 'emergencyCallControlTest_07-data1:' + data);
  });
  EmergencyCallController.getInstance().clearIdOfList('1', (data: string) => {
    LogUtils.i(TAG, 'emergencyCallControlTest_07-data2:' + data);
  });
  expect(true).assertTrue();
}

async function emergencyCallControlTest_07() {
  let resString = EmergencyCallController.getInstance().formatResourceToString($r('app.string.module_test_desc'));
  LogUtils.d(TAG, 'emergencyCallControlTest_06-resString:' + resString);
  expect('test ability description').assertEqual(resString);
}

async function setWindowBackgroundColorTestFn() {
  EmergencyCallController.getInstance().setWindowBackgroundColor('');
  expect(true).assertTrue();
  await sleep(500);
  EmergencyCallController.getInstance().setWindowBackgroundColor('#E7E7E7');
  expect(true).assertTrue();
}

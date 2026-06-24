/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium'
import { SosEmergencySmsController } from '../../../../main/ets/control/SosEmergencySmsController'
import geoLocationManager from '@ohos.geoLocationManager'
import { BusinessError } from '@kit.BasicServicesKit'
import { sms } from '@kit.TelephonyKit'
import { SOS } from '../../../../main/ets/utils/Constants'
import { common } from '@kit.AbilityKit';
import { rpc } from '@kit.IPCKit';

export default function SosEmergencySmsControllerTest() {
  describe('SosEmergencySmsControllerTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    })
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: preset action function.
    })
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: clear action function.
    })
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end.
      // This API supports only one parameter: clear action function.
    })
    it('SosEmergencySmsControllerTest_startAutoSendSosMessage', 0, async () => {
      let r = await SosEmergencySmsController.getInstance().startAutoSendSosMessage(SOS,
        (getContext() as common.UIAbilityContext).windowStage.getMainWindowSync().getUIContext());
      expect(r === null).assertEqual(false);
    })
    it('SosEmergencySmsControllerTest_sendSms', 0, async () => {
      let sos = SosEmergencySmsController.getInstance();
      let r = await sos.sendSms(SOS);
      (sos as object)['timesOfAutoSendSosMessage'] = 31;
      r = await sos.sendSms(SOS);
      expect(r === null).assertEqual(false);
    })
    it('SosEmergencySmsControllerTest_getLngLatLocationStr', 0, async () => {
      let sos = SosEmergencySmsController.getInstance();
      let parm: geoLocationManager.Location = {
        latitude: 0,
        longitude: 0,
        altitude: 0,
        accuracy: 0,
        speed: 0,
        timeStamp: 0,
        direction: 0,
        timeSinceBoot: 0
      }
      let r: string = await (sos as object)['getLngLatLocationStr'](parm);
      parm.longitude = -1;
      r = await (sos as object)['getLngLatLocationStr'](parm);
      parm.latitude = -1;
      r = await (sos as object)['getLngLatLocationStr'](parm);
      parm.longitude = 0;
      r = await (sos as object)['getLngLatLocationStr'](parm);
      expect(r).assertEqual('');
    })
    it('SosEmergencySmsControllerTest_sendSmsCallBack', 0, async () => {
      let sos = SosEmergencySmsController.getInstance();
      let err: BusinessError = {
        code: 0,
        name: '',
        message: ''
      }
      let data: sms.ISendShortMessageCallback = {
        result: sms.SendSmsResult.SEND_SMS_SUCCESS,
        url: '',
        isLastPart: false
      }
      let data1: sms.ISendShortMessageCallback = {
        result: sms.SendSmsResult.SEND_SMS_FAILURE_UNKNOWN,
        url: '',
        isLastPart: false
      }
      let r: object = await (sos as object)['sendSmsCallBack'](err, data);
      sos.firstSendSuccess = false;
      r = await (sos as object)['sendSmsCallBack'](err, data);
      r = await (sos as object)['sendSmsCallBack'](err, data1);
      expect(r).assertEqual(false);
    })
    it('SosEmergencySmsControllerTest_cancelTwoMinutesAlarm', 0, async () => {
      let sos = SosEmergencySmsController.getInstance();
      (sos as object)['twoMinutesAlarmTimeoutId'] = 1;
      (sos as object)['fifteenSecondsAlarmTimeoutId'] = 1;
      let r: object = await (sos as object)['cancelFifteenSecAlarm']();
      r = await (sos as object)['cancelTenMinutesAlarm']();
      expect(r === null).assertEqual(false);
    })
  })
}
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
import { SosEmergencyCallController, hasCallSync } from '../../../../main/ets/control/SosEmergencyCallController'
import { EmergencyGlobalContextHelper } from '../../../../main/ets/utils/EmergencyGlobalContextHelper';
import { common } from '@kit.AbilityKit';
import * as Constants from '../../../../main/ets/utils/Constants';
import { ContactListStruct } from '../../../../main/ets/utils/ClassStruct';
import { sim } from '@kit.TelephonyKit';

export default function SosEmergencyCallControllerTest() {
  let context = EmergencyGlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT);
  let emptyContext: common.UIAbilityContext;
  describe('SosEmergencyCallControllerTest', () => {

    it('SosEmergencyCallControllerTest_clearTimeOutIdOf30s', 0, () => {
      let r = SosEmergencyCallController.getInstance().clearTimerIdOfSosCallWaitTime();
      expect(r === null).assertEqual(false);
    })
    it('SosEmergencyCallControllerTest_isDeviceHasSimSync', 0, () => {
      let r = SosEmergencyCallController.isDeviceHasSimSync(true);
      r = SosEmergencyCallController.isDeviceHasSimSync(false);
      expect(r).assertEqual(false);
    })
    it('SosEmergencyCallControllerTest_findNormalWorkSimCard', 0, () => {
      let r: object | number = (SosEmergencyCallController as object)['findNormalWorkSimCard'](0);
      if (r === null) {
        expect(r).assertEqual(null);
      } else if (r === 0) {
        expect(r).assertEqual(0);
      } else {
        expect(r).assertPromiseIsPending();
      }
    })
    it('SosEmergencyCallControllerTest_getNormalWorkSimCard ', 0, async () => {
      let r: object | number = await (SosEmergencyCallController as object)['getNormalWorkSimCard']();
      if (r === null) {
        expect(r).assertEqual(null);
      } else if (r === 0) {
        expect(r).assertEqual(0);
      } else {
        expect(r).assertEqual(1);
      }
    })
    it('SosEmergencyCallControllerTest_terminateSelfUIAbility', 0, async () => {
      let r = await SosEmergencyCallController.terminateSelfUIAbility(context);
      r = await SosEmergencyCallController.terminateSelfUIAbility(emptyContext);
      expect(r === null).assertEqual(false);
    })
    it('SosEmergencyCallControllerTest_muteAudio', 0, async () => {
      let sos = SosEmergencyCallController.getInstance();
      let r = await sos.muteAudio();
      expect(r === null).assertEqual(false);
    })
    it('SosEmergencyCallControllerTest_recoveryAudioNormal', 0, async () => {
      let sos = SosEmergencyCallController.getInstance();
      let r = await sos.recoveryAudioNormal();
      expect(r === null).assertEqual(false);
    })
    it('SosEmergencyCallControllerTest_cancelSubscribeCallDetailsChange', 0, async () => {
      let sos = SosEmergencyCallController.getInstance();
      let r = sos.cancelSubscribeCallDetailsChange();
      expect(r === null).assertEqual(false);
    })
    it('SosEmergencyCallControllerTest_publishEventToTellPageName', 0, async () => {
      let sos = SosEmergencyCallController.getInstance();
      let r = sos.publishEventToTellPageName('SosCountdown');
      r = sos.publishEventToTellPageName('SosEmergencyCall');
      r = sos.publishEventToTellPageName('None');
      expect(r === null).assertEqual(false);
    })
    it('SosEmergencyCallControllerTest_resetEmergencyCall', 0, async () => {
      let sos = SosEmergencyCallController.getInstance();
      let r = await sos.resetEmergencyCall(getContext());
      expect(r === null).assertEqual(false);
    })
    it('SosEmergencyCallControllerTest_resetEmergencyContactsItem', 0, async () => {
      let parm: ContactListStruct = {
        value: '',
        label: '',
        id: '',
        type: 0
      }
      let r = SosEmergencyCallController.resetEmergencyContactsItem(0, parm);
      expect(r === null).assertEqual(false);
    })
    it('SosEmergencyCallControllerTest_getNormalWorkSimCard', 0, async () => {
      let r = await SosEmergencyCallController.getNormalWorkSimCard();
      if (r === null) {
        expect(r === null).assertEqual(true);
      } else if (r === 0) {
        expect(r).assertEqual(0);
      } else {
        expect(r).assertEqual(1);
      }
    })
    it('SosEmergencyCallControllerTest_hangUpCallByCallId', 0, async () => {
      let sos = SosEmergencyCallController.getInstance();
      let r = await sos.hangUpCallByCallId(1);
      expect(r === null).assertEqual(false);
    })
    it('SosEmergencyCallControllerTest_displaySpecifiedCallPageByCallId', 0, async () => {
      let sos = SosEmergencyCallController.getInstance();
      let r = await sos.hangUpCallByCallId(1);
      expect(r === null).assertEqual(false);
    })
    it('SosEmergencyCallControllerTest_resetEmergencyContactsCallProperty', 0, async () => {
      let sos = SosEmergencyCallController.getInstance();
      let parm: ContactListStruct = {
        value: '',
        label: '',
        id: '',
        type: 0
      }
      let list: ContactListStruct[] = [];
      list.push(parm);
      let r: object = await (sos as object)['resetEmergencyContactsCallProperty'](undefined);
      r = await (sos as object)['resetEmergencyContactsCallProperty'](list);
      expect(r === null).assertEqual(false);
    })
    it('SosEmergencyCallControllerTest_resetEmergencyContactsCallPropertyByIndex', 0, async () => {
      let sos = SosEmergencyCallController.getInstance();
      let parm: ContactListStruct = {
        value: '',
        label: '',
        id: '',
        type: 0
      }
      let list: ContactListStruct[] = [];
      list.push(parm);
      let r = sos.resetEmergencyContactsCallPropertyByIndex(undefined, null);
      r = sos.resetEmergencyContactsCallPropertyByIndex(list, 0);
      expect(r === null).assertEqual(false);
    })
    it('SosEmergencyCallControllerTest_endDialSosCall', 0, async () => {
      let sos = SosEmergencyCallController.getInstance();
      let r = await sos.endDialSosCall();
      expect(r === null).assertEqual(false);
    })
    it('SosEmergencyCallControllerTest_getCommunicationNetworkType', 0, async () => {
      let r = await SosEmergencyCallController.getInstance().getCommunicationNetworkType(getContext(), false, false,
        () => {});
      expect(r === null).assertEqual(false);
    })
    it('SosEmergencyCallControllerTest_endAutoDialSosCallByCallId', 0, async () => {
      let sos = SosEmergencyCallController.getInstance();
      let r = await sos.endAutoDialSosCallByCallId(1);
      expect(r === null).assertEqual(false);
    })
    it('SosEmergencyCallControllerTest_playBeeBuzzAlarm ', 0, async () => {
      let sos = SosEmergencyCallController.getInstance();
      let r = await sos.playBeeBuzzAlarm ();
      expect(r === null).assertEqual(false);
    })
    it('SosEmergencyCallControllerTest_shakeDeviceOnce ', 0, async () => {
      let r = await SosEmergencyCallController.shakeDeviceOnce ();
      expect(r === null).assertEqual(false);
    })
    it('SosEmergencyCallControllerTest_terminateSelfUIAbility ', 0, async () => {
      let r = await SosEmergencyCallController.getIsEnableAirPlaneModeSync (context);
      expect(r === null).assertEqual(false);
    })
  })
}
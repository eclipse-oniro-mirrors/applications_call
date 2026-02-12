/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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

import { describe, it, expect } from '@ohos/hypium';
import CallUtils from '../../../../../main/ets/common/utils/CallUtils';
import { sleep } from '../../Utils';
import DefaultCallData from '../../../../../main/ets/common/struct/TypeUtils';

export default function CallUtilsTest() {
  describe('CallUtilsTestOne', () => {
    it('isFastClick_test_01', 0, () => {
      expect(CallUtils.isFastClick('test')).assertFalse();
    });
    it('isFastClick_test_02', 0, () => {
      CallUtils.muteRinger(false);
      expect(CallUtils.isFastClick('test')).assertFalse();
    });
    sleep(600);
    it('isFastClick_test_03', 0, () => {
      CallUtils.muteRinger(true);
      expect(CallUtils.isFastClick('test')).assertTrue();
    });
    it('isInvalidNumber_test_01', 0, () => {
      expect(CallUtils.isInvalidNumber('')).assertTrue();
    });
    it('isInvalidNumber_test_02', 0, () => {
      expect(CallUtils.isInvalidNumber('Anonymous')).assertTrue();
    });
    it('isInvalidNumber_test_03', 0, () => {
      expect(CallUtils.isInvalidNumber('183135210')).assertFalse();
    });
    it('isMultiSimActive_test_01', 0, () => {
      expect(CallUtils.isMultiSimActive()).assertFalse();
    });
    it('isSosWithOutCallUiAbility_test_01', 0, () => {
      const callData = new DefaultCallData();
      callData.extraParams = {};
      expect(CallUtils.isSosWithOutCallUiAbility(callData)).assertEqual(0);
    });
    it('isSosWithOutCallUiAbility_test_02', 0, () => {
      const callData = new DefaultCallData();
      callData.extraParams = { 'sosWithOutCallUiAbility': '1' };
      expect(CallUtils.isSosWithOutCallUiAbility(callData)).assertEqual(1);
    });
    it('isSosWithOutCallUiAbility_test_03', 0, () => {
      const callData = new DefaultCallData();
      callData.extraParams = { 'sosWithOutCallUiAbility': '3' };
      expect(CallUtils.isSosWithOutCallUiAbility(callData)).assertEqual(0);
    });
    it('isDoNotDisturb_test_01', 0, () => {
      const callData = new DefaultCallData();
      expect(CallUtils.isDoNotDisturb(callData)).assertFalse();
    });
    it('isDoNotDisturb_test_02', 0, () => {
      const callData = new DefaultCallData();
      callData.extraParams = { 'IsNeedSilentInDoNotDisturbMode': '' };
      expect(CallUtils.isDoNotDisturb(callData)).assertFalse();
    });
    it('isDoNotDisturb_test_03', 0, () => {
      const callData = new DefaultCallData();
      callData.extraParams = { 'IsNeedSilentInDoNotDisturbMode': 1 };
      expect(CallUtils.isDoNotDisturb(callData)).assertTrue();
    });
    it('isDoNotDisturb_test_04', 0, () => {
      const callData = new DefaultCallData();
      callData.extraParams = { 'IsNeedSilentInDoNotDisturbMode': 'test' };
      expect(CallUtils.isDoNotDisturb(callData)).assertFalse();
    });

    it('getDisconnectedReason_test_01', 0, () => {
      const callData = new DefaultCallData();
      expect(CallUtils.getDisconnectedReason(callData)).assertEqual(-1);
    });
    it('getDisconnectedReason_test_02', 0, () => {
      const callData = new DefaultCallData();
      callData.extraParams = { 'disconnectedReason': 1 };
      expect(CallUtils.getDisconnectedReason(callData)).assertEqual(1);
    });
    it('getDisconnectedReason_test_03', 0, () => {
      const callData = new DefaultCallData();
      callData.extraParams = { 'disconnectedReason': 'test' };
      expect(CallUtils.getDisconnectedReason(callData)).assertEqual(-1);
    });

    it('getImsDomain_test_01', 0, () => {
      const callData = new DefaultCallData();
      expect(CallUtils.getImsDomain(callData)).assertEqual(-1);
    })
    it('getImsDomain_test_02', 0, () => {
      const callData = new DefaultCallData();
      callData.extraParams = { 'imsDomain': 1 };
      expect(CallUtils.getImsDomain(callData)).assertEqual(1);
    })
    it('getImsDomain_test_03', 0, () => {
      const callData = new DefaultCallData();
      callData.extraParams = { 'imsDomain': 'test' };
      expect(CallUtils.getImsDomain(callData)).assertEqual(-1);
    })
  })
}

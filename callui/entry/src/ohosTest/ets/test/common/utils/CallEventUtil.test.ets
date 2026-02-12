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

import CommonEventManager from '@ohos.commonEventManager';
import { CallEventUtil } from '../../../../../main/ets/common/utils/CallEventUtil';

const VOIP_EVENTS = 'usual.event.EXTENSION_LOAD';
let options: CommonEventManager.CommonEventPublishData = {
  bundleName: 'name',
  code: 10086,
  data: 'Publishing succeeded',
  subscriberPermissions: ['0', '1', '2'],
  isOrdered: true,
  isSticky: true,
  parameters: { ['explain']: 'explain content' }
};
let CallEventUtilTest_sendCommonEvent01 = () => {
  CallEventUtil.sendCommonEvent(options);
  CommonEventManager.publish(VOIP_EVENTS, options, err => {
    if (err) {
      expect(true).assertTrue();
    } else {
      expect(options.code === 10086).assertTrue()
    }
  });
}
let CallEventUtilTest_getEventOptions01 = () => {
  let result1: CommonEventManager.CommonEventPublishData = CallEventUtil.getEventOptions(10080, 'name1', '123456', 0);
  expect(result1.code === 10080).assertTrue();
  expect(result1.parameters!.voipBundleName === 'name1').assertTrue();
  expect(result1.parameters!.voipCallId === '123456').assertTrue();
}

export default function CallEventUtilTest() {
  describe('CallEventUtilTest', () => {
    it('sendCommonEvent01', 0, async () => {
      CallEventUtilTest_sendCommonEvent01();
    })
    it('getEventOptions01', 0, async () => {
      CallEventUtilTest_getEventOptions01();
    })
  })
}

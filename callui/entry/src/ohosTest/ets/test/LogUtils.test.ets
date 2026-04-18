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

import { describe, it, expect } from '@ohos/hypium';
import CallStateConst from '../../../main/ets/common/constant/CallStateConst';
import { callDataToSafeString } from '../../../main/ets/common/struct/TypeUtils';
import LogUtils from '../../../main/ets/common/utils/LogUtils';
const tag = 'tag';
const msg = 'msg';

export default function LogUtilsTest() {
  describe('LogUtilsTest', () => {
    it('toSafeString', 0, () => {
      let a = '10086-123'
      let result = LogUtils.toSafeString(a);
      expect(a.length).assertEqual(result.length)
      let b = '10086-456'
      let testResult = LogUtils.toSafeString(b);
      expect(b.length).assertEqual(testResult.length)
    })
    it('callDataToSafeStringTest', 0, () => {
      let safeString: string = callDataToSafeString({
        videoState: 0,
        callState: CallStateConst.CALL_STATUS_WAITING,
        accountId: 0,
        accountNumber: '0',
        callId: -1,
        callType: 0,
        conferenceState: 0,
        contactName: 'TestName',
        formatNumber: '1234567890',
        isEcc: false,
        startTime: 0,
        numberLocation: '',
        contactCompany: '',
        contactCompanyPosition: '',
        numberMarkInfo: { markContent: '', markType: -1, markCount: -1 },
      });
      expect(safeString.indexOf('TestName')).assertEqual(-1);
      expect(safeString.indexOf('1234567890')).assertEqual(-1);
    })
    it('TestLogUtils_01', 0, () => {
      let result = LogUtils.d(tag, msg);
      expect(result == null).assertTrue();
    })
    it('TestLogUtils_02', 0, () => {
      let result = LogUtils.i(tag, msg);
      expect(result == null).assertTrue();
    })
    it('TestLogUtils_03', 0, () => {
      let result = LogUtils.w(tag, msg);
      expect(result == null).assertTrue()
    })
    it('TestLogUtils_04', 0, () => {
      let result = LogUtils.e(tag, msg);
      expect(result == null).assertTrue();
    })
  })
}
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
import { describe, expect, it } from '@ohos/hypium'
import {
  checkCallerWantParams,
  fetchFullKeyWord,
  getFlowText,
  QueryName,
  TAG_NAME,
  UNDERLINE
} from '../../../../main/ets/constants/CommonConstants'

export default function CommonConstantsTest() {
  describe('CommonConstantsTest', () => {
    it('getFlowText', 0, () => {
      let flow0 = getFlowText(12.771);
      expect(flow0[0]).assertEqual('12.77');
      expect(flow0[1]).assertEqual('B');
      let flow1 = getFlowText(12.7 * 1024);
      expect(flow1[0]).assertEqual('12.70');
      expect(flow1[1]).assertEqual('KB');
      let flow2 = getFlowText(12 * Math.pow(1024, 2));
      expect(flow2[0]).assertEqual('12.00');
      expect(flow2[1]).assertEqual('MB');
      let flow3 = getFlowText(1 * Math.pow(1024, 3));
      expect(flow3[0]).assertEqual('1.00');
      expect(flow3[1]).assertEqual('GB');
      let flow4 = getFlowText(12 * Math.pow(1024, 4));
      expect(flow4[0]).assertEqual('12.00');
      expect(flow4[1]).assertEqual('TB');
      let flow5 = getFlowText(1.1 * Math.pow(1024, 5));
      expect(flow5[0]).assertEqual('1126.40');
      expect(flow5[1]).assertEqual('TB');
    })
    it('checkCallerWantParams_bundleNameInvalid', 0, () => {
      let want: Want = {
        abilityName: 'testability',
      }
      let tag: string = 'test';
      expect(checkCallerWantParams(tag, want)).assertEqual(false);
    })
    it('checkCallerWantParams_inWhiteList', 0, () => {
      let want: Want = {
        abilityName: 'CommunicationSettingAbility',
        parameters: {
          'ohos.aafwk.param.callerBundleName': 'com.ohos.settings'
        }
      }
      let tag: string = 'test';
      expect(checkCallerWantParams(tag, want)).assertEqual(true);
    })
    it('checkCallerWantParams_NotInWhiteList', 0, () => {
      let want: Want = {
        abilityName: 'testability',
        parameters: {
          'ohos.aafwk.param.callerBundleName': 'com.ohos.mms'
        }
      }
      let tag: string = 'test';
      expect(checkCallerWantParams(tag, want)).assertEqual(false);
    })
    it('fetchFullKeyWord', 0, () => {
      let simId = 0;
      let keyWord = QueryName.unlimited_traffic_enable;
      expect(fetchFullKeyWord(simId, keyWord)).assertEqual(TAG_NAME + simId + UNDERLINE + keyWord);
    })
  })
}
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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import ContactService from '../../../../../main/ets/common/service/ContactService';
import { Constant } from '../../../../../main/ets/common/constant/Constant';
import commonData from '../../../../../main/ets/common/utils/CommonData';

let ContactServiceTest_getPhoneNumberParam = () => {
  let actionData: Record<string, string> = {};
  actionData.pageFlag = commonData.contactPage.PAGE_FLAG_MULTI_CHOOSE;
  let str: Record<string, Object> = {
    'bundleName': Constant.CONTACT_BUNDLE_NAME,
    'abilityName': Constant.CONTACT_ABILITY_NAME,
    'parameters': actionData,
    'entities': [
      Constant.COMMON_ENTITIES
    ]
  };
  let result = ContactService.getPhoneNumberParam(actionData);
  expect(result['parameters']).assertEqual(str['parameters']);
}

let ContactServiceTest_getRecorderSqlParam = () => {
  let actionData: Record<string, string> = {};
  actionData.pageFlag = commonData.contactPage.PAGE_FLAG_MULTI_CHOOSE;
  let str: Record<string, Object> = {
    'bundleName': Constant.RECORDER_BUNDLE_NAME,
    'abilityName': Constant.RECORDER_ABILITY_NAME,
    'parameters': actionData
  };
  let result = ContactService.getRecorderSqlParam(actionData);
  expect(result['parameters']).assertEqual(str['parameters']);
}

export default function ContactServiceTest() {
  describe('ContactServiceTest', () => {

    it('ContactServiceTest_getPhoneNumberParam', 0, () => {
      ContactServiceTest_getPhoneNumberParam();
    })

    it('ContactServiceTest_getRecorderSqlParam', 0, async () => {
      ContactServiceTest_getRecorderSqlParam();
    })
  })
}
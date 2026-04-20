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
import { EmergencyInfoStruct } from '../../../../main/ets/utils/ClassStruct';
import { updateObjectValue } from '../../../../main/ets/utils/CommonFunction';

export default function CommonFunctionTest() {
  describe('CommonFunctionTest', () => {
    it('commonFunctionTest_01', 0, () => {
      commonFunctionTest_01();
    });
    it('commonFunctionTest_01_a', 0, () => {
      commonFunctionTest_01_a();
    });
  })
}

function commonFunctionTest_01() {
  // obj[key] !== undefined
  let emergencyInfo: EmergencyInfoStruct = {
    name: '',
    address: ''
  }
  emergencyInfo = updateObjectValue('name', 'test', emergencyInfo);
  expect('test').assertEqual(emergencyInfo.name);
}

function commonFunctionTest_01_a() {
  // obj[key] === undefined
  let emergencyInfo: EmergencyInfoStruct = {
    name: '',
    address: 'test'
  }
  emergencyInfo = updateObjectValue('undefined', 'test', emergencyInfo);
  expect('test').assertEqual(emergencyInfo.address);
}



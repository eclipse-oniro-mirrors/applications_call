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
import { StaticNumberDataListStruct } from '../../../../../main/ets/common/struct/RecorderSettingStruct';
import CommonData from '../../../../../main/ets/common/utils/CommonData';

let CommonDataTest_defaultStaticNumberDataUse_01 = () => {
  let res: StaticNumberDataListStruct[] = CommonData.defaultStaticNumberDataUse;
  expect(res.length).assertEqual(0);
}
let CommonDataTest_defaultStaticNumberDataUse_02 = () => {
  let res: Record<string, Resource> = CommonData.recordingObjectChange;
  expect(res['1'].id).assertEqual($r('app.string.all_calls').id);
  expect(res['2'].id).assertEqual($r('app.string.specified_number').id);
}

let CommonDataTest_contactPage = () => {
  let res: Record<string, string> = CommonData.contactPage;
  expect(res['PAGE_FLAG_MULTI_CHOOSE']).assertEqual('page_flag_multi_choose');
}

export default function CommonDataTest() {
  describe('CommonDataTest', () => {
    it('CommonDataTest_defaultStaticNumberDataUse_01', 0, () => {
      CommonDataTest_defaultStaticNumberDataUse_01();
    })
    it('CommonDataTest_defaultStaticNumberDataUse_02', 0, () => {
      CommonDataTest_defaultStaticNumberDataUse_02();
    })
    it('CommonDataTest_contactPage', 0, () => {
      CommonDataTest_contactPage();
    })
  })
}
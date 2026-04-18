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
import TimeUtil from '../../../../../main/ets/common/utils/TimeUtil';

let TimeUtilTestIt = () => {
  let date: Date = new Date();
  let str: string = TimeUtil.getRecordDisplayNameTime(date);
  let yearStr = date.getFullYear().toString();
  let monthStr: string = (date.getMonth() + 1).toString().padStart(2, '0');
  let dayStr = date.getDate().toString().padStart(2, '0');
  let hourStr = date.getHours().toString().padStart(2, '0');
  let minuteStr = date.getMinutes().toString().padStart(2, '0');
  let secondStr = date.getSeconds().toString().padStart(2, '0');
  let total: string = yearStr + monthStr + dayStr + hourStr + minuteStr + secondStr;
  expect(str).assertEqual(total);
}

let TimeUtilTest_isTimestamp = () => {
  let str = '1751614469000';
  let ret = TimeUtil.isTimestamp(str);
  expect(ret).assertTrue();
}

export default function TimeUtilTest() {
  describe('TimeUtilTest', () => {
    it('TimeUtilTest', 0, () => {
      TimeUtilTestIt();
    });
    it('TimeUtilTest_isTimestamp', 0, () => {
      TimeUtilTest_isTimestamp();
    });
  })
}
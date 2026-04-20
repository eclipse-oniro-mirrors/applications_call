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
import { DataStorage } from '@ohos/common/CommonIndex';
import { ValuesBucket, ValueType } from '@kit.ArkData';

let dataStorage: DataStorage = new DataStorage();

export default function ApnDataStorageCommonTest() {
  describe('ApnDataStorageCommonTest', () => {

    it('ApnDataStorageCommonTest_checkApnData', 0, async () => {
      let data: ValuesBucket = {
        mvno_type: '123',
        mms_ip_address: '123',
        proxy_ip_address: '123',
        apn_protocol: 5,
        apn_roam_protocol: 5
      };
      (dataStorage as object)['checkApnData'](data);
      let abc: ValueType = 1;
      (dataStorage as object)['addUriParam']('?', '', abc);
      (dataStorage as object)['addUriParam']('', '');
      expect(data.mvno_type === '123').assertTrue();
    });
  });
}
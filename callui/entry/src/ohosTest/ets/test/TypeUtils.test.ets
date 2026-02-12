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
import {
  DefaultDistributeDeviceAddressData,
  getSimIcon,
  NumberMarkInfo
} from '../../../main/ets/common/struct/TypeUtils';
import { call } from '@kit.TelephonyKit';

export default function TypeUtilsTest() {
  describe('TypeUtilsTest', () => {
    it('getSimIcon_0', 0, () => {
      expect(getSimIcon(0) !== undefined).assertTrue();
    })
    it('getSimIcon_1', 0, () => {
      expect(getSimIcon(1) !== undefined).assertTrue();
    })
    it('DefaultDistributeDeviceAddressData_01', 0, () => {
      let defaultDistributeDeviceAddressData = new DefaultDistributeDeviceAddressData();
      expect(JSON.stringify(defaultDistributeDeviceAddressData.devName) === JSON.stringify($r('app.string.emptyStr')))
        .assertTrue();
    })
    it('DefaultDistributeDeviceAddressData_02', 0, () => {
      let defaultDistributeDeviceAddressData = new DefaultDistributeDeviceAddressData();
      expect(defaultDistributeDeviceAddressData.devId === '').assertTrue();
    })
    it('NumberMarkInfo', 0, () => {
      let numberMarkInfo = new NumberMarkInfo();
      numberMarkInfo.markType = 0;
      numberMarkInfo.markContent = '';
      numberMarkInfo.markCount = 0;
      numberMarkInfo.markSource = undefined;
      numberMarkInfo.isCloud = false;
      expect(numberMarkInfo.markType === call.MarkType.MARK_TYPE_NONE).assertTrue();
    })
  })
}
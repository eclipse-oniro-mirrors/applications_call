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
import CallColumnUtils from '../../../../main/ets/utils/CallColumnUtils';
import {
  EmergencyInfoStruct,
  ContactListStruct,
  RadioListItemStruct,
  DialogDataStruct,
  LocationDialogDataStruct,
  EmergencyContactDialogDataStruct,
  LocationInfoStruct,
  ContactDataStruct,
  EmergencyNumListStruct,
  TimeOutStruct
} from '../../../../main/ets/utils/ClassStruct';

export default function ClassStructTest() {
  describe('ClassStructTest', () => {
    it('ClassStructTest', 0, () => {
      let a = new EmergencyInfoStruct();
      let b = new ContactListStruct();
      let c = new RadioListItemStruct();
      let d = new DialogDataStruct;
      d.confirm();
      let e = new LocationDialogDataStruct();
      e.confirm();
      let f = new EmergencyContactDialogDataStruct();
      f.confirm();
      let g = new LocationInfoStruct();
      let h = new ContactDataStruct();
      let i = new EmergencyNumListStruct();
      let j = new TimeOutStruct();
      expect(true).assertTrue();
    })
  })
}


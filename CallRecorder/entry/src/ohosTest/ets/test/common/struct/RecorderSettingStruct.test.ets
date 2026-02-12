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
import { CallSettingConstant } from '../../../../../main/ets/common/constant/CallSettingConstant';
import {
  ContactDataStruct,
  ContactsDataStruct,
  DialogDataStruct,
  NumberListItemStruct,
  RecordConfigContactDataNoStruct,
  RecordConfigContactDataStruct,
  RecordConfigDataStruct,
  StaticDataUseStruct,
  StaticNumberDataListStruct
} from '../../../../../main/ets/common/struct/RecorderSettingStruct';

let RecorderSettingStructTest_DialogDataStruct = () => {
  let dialogDataStruct = new DialogDataStruct();
  expect(dialogDataStruct.objectUse).assertEqual(' ');
}

let RecorderSettingStructTest_NumberListItemStruct = () => {
  let numberListItemStruct = new NumberListItemStruct();
  expect(numberListItemStruct.value).assertEqual('');
  expect(JSON.stringify(numberListItemStruct.label)).assertEqual(JSON.stringify($r('app.string.emptyStr')));
}

let RecorderSettingStructTest_StaticDataUseStruct = () => {
  let staticDataUseStruct = new StaticDataUseStruct();
  expect(staticDataUseStruct.statusUse).assertEqual(false);
  expect(staticDataUseStruct.objectUse).assertEqual(CallSettingConstant.RECORDING_WAY_ALL_NUMBER);
  expect(staticDataUseStruct.numberUse).assertEqual(0);
}

let RecorderSettingStructTest_StaticNumberDataListStruct = () => {
  let staticNumberDataListStruct = new StaticNumberDataListStruct();
  expect(staticNumberDataListStruct.isChecked).assertEqual(false);
  expect(staticNumberDataListStruct.number).assertEqual('');
  expect(staticNumberDataListStruct.name).assertEqual('');
}

let RecorderSettingStructTest_ContactsDataStruct = () => {
  let contactsDataStruct = new ContactsDataStruct();
  expect(contactsDataStruct.id).assertEqual(-1);
  expect(contactsDataStruct.displayName).assertEqual('');
  expect(contactsDataStruct.detailInfo).assertEqual('');
  expect(contactsDataStruct.blobData).assertEqual(undefined);
  expect(contactsDataStruct.typeId).assertEqual(-1);
  expect(contactsDataStruct.contactId).assertEqual(-1);
}

let RecorderSettingStructTest_ContactDataStruct = () => {
  let contactDataStruct = new ContactDataStruct();
  expect(contactDataStruct.telephone).assertEqual('');
  expect(contactDataStruct.contactName).assertEqual('');
}

let RecorderSettingStructTest_RecordConfigDataStruct = () => {
  let recordConfigDataStruct = new RecordConfigDataStruct();
  expect(recordConfigDataStruct.isOpen).assertEqual(CallSettingConstant.CLOSE_RECORDING_STATUS);
  expect(recordConfigDataStruct.object).assertEqual(CallSettingConstant.RECORDING_WAY_ALL_NUMBER);
}

let RecorderSettingStructTest_RecordConfigContactDataNoStruct = () => {
  let recordConfigContactDataNoStruct = new RecordConfigContactDataNoStruct();
  expect(recordConfigContactDataNoStruct.phoneNumber).assertEqual('');
  expect(recordConfigContactDataNoStruct.name).assertEqual('');
  expect(recordConfigContactDataNoStruct.isChecked).assertEqual(false);
}

let RecorderSettingStructTest_RecordConfigContactDataStruct = () => {
  let recordConfigContactDataStruct = new RecordConfigContactDataStruct();
  expect(recordConfigContactDataStruct.phoneNumber).assertEqual('');
  expect(recordConfigContactDataStruct.id).assertEqual(-1);
  expect(recordConfigContactDataStruct.name).assertEqual('');
  expect(recordConfigContactDataStruct.isChecked).assertEqual(false);
  expect(recordConfigContactDataStruct.isImageDefault).assertEqual(true);
}


export default function RecorderSettingStructTest() {
  describe('RecorderSettingStructTest', () => {
    it('RecorderSettingStructTest_DialogDataStruct', 0, () => {
      RecorderSettingStructTest_DialogDataStruct();
    })
    it('RecorderSettingStructTest_NumberListItemStruct', 0, () => {
      RecorderSettingStructTest_NumberListItemStruct();
    })
    it('RecorderSettingStructTest_StaticDataUseStruct', 0, () => {
      RecorderSettingStructTest_StaticDataUseStruct();
    })
    it('RecorderSettingStructTest_StaticNumberDataListStruct', 0, () => {
      RecorderSettingStructTest_StaticNumberDataListStruct();
    })
    it('RecorderSettingStructTest_ContactsDataStruct', 0, () => {
      RecorderSettingStructTest_ContactsDataStruct();
    })
    it('RecorderSettingStructTest_ContactDataStruct', 0, () => {
      RecorderSettingStructTest_ContactDataStruct();
    })
    it('RecorderSettingStructTest_RecordConfigDataStruct', 0, () => {
      RecorderSettingStructTest_RecordConfigDataStruct();
    })
    it('RecorderSettingStructTest_RecordConfigContactDataNoStruct', 0, () => {
      RecorderSettingStructTest_RecordConfigContactDataNoStruct();
    })
    it('RecorderSettingStructTest_RecordConfigContactDataStruct', 0, () => {
      RecorderSettingStructTest_RecordConfigContactDataStruct();
    })
  })
}
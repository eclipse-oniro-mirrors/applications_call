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
import {
  FuncManageReturn,
  RecordContactDataStruct,
  RecordLog,
  RecordLogObjectStruct,
  TableUseStruct,
  UriUseClass
} from '../../../../../main/ets/common/struct/RecorderStruct';

let RecorderStructTest_RecordLogObjectStruct = () => {
  let recordLogObjectStruct = new RecordLogObjectStruct();
  expect(recordLogObjectStruct.filePath).assertEqual('');
  expect(recordLogObjectStruct.duration).assertEqual('');
  expect(recordLogObjectStruct.displayName).assertEqual('');
  expect(recordLogObjectStruct.dateAdded).assertEqual(0);
  expect(recordLogObjectStruct.title).assertEqual('');
}

let RecorderStructTest_TableUseStruct = () => {
  let tableUseStruct = new TableUseStruct();
  expect(tableUseStruct.RECORD_DATABASE).assertEqual('');
  expect(tableUseStruct.RECORD_CONFIG_SQL).assertEqual('');
  expect(tableUseStruct.RECORD_CONTACT_SQL).assertEqual('');
  expect(tableUseStruct.RECORD_LOG_SQL).assertEqual('');
  expect(tableUseStruct.RECORD_MIGRATION_SQL).assertEqual('');
}

let RecorderStructTest_FuncManageReturn = () => {
  let funcManageReturn = new FuncManageReturn();
  expect(funcManageReturn.message).assertEqual('');
  expect(funcManageReturn.designateNumberStatus).assertEqual(false);
  expect(funcManageReturn.errCode).assertEqual(0);
}

let RecorderStructTest_RecordLog = () => {
  let recordLog = new RecordLog();
  expect(recordLog.filePath).assertEqual('');
  expect(recordLog.duration).assertEqual(0);
  expect(recordLog.displayName).assertEqual('');
  expect(recordLog.dateAdded).assertEqual(0);
  expect(recordLog.title).assertEqual('');
  expect(recordLog.phoneNumber).assertEqual('');
  expect(recordLog.recorderAdded).assertEqual(-1);
  expect(recordLog.mode).assertEqual(1);
}

let RecorderStructTest_RecordContactDataStruct = () => {
  let recordContactDataStruct = new RecordContactDataStruct();
  expect(recordContactDataStruct.phoneNumber).assertEqual('');
  expect(recordContactDataStruct.name).assertEqual(' ');
}

let RecorderStructTest_UriUseClass = () => {
  let uriUseClass = new UriUseClass();
  expect(uriUseClass.dbUse).assertEqual('');
  expect(uriUseClass.tableUse).assertEqual('');
  expect(uriUseClass.type).assertEqual('');
}

export default function RecorderStructTest() {
  describe('RecorderStructTest', () => {
    it('RecorderStructTest_RecordLogObjectStruct', 0, () => {
      RecorderStructTest_RecordLogObjectStruct();
    })
    it('RecorderStructTest_TableUseStruct', 0, () => {
      RecorderStructTest_TableUseStruct();
    })
    it('RecorderStructTest_FuncManageReturn', 0, () => {
      RecorderStructTest_FuncManageReturn();
    })
    it('RecorderStructTest_RecordLog', 0, () => {
      RecorderStructTest_RecordLog();
    })
    it('RecorderStructTest_RecordContactDataStruct', 0, () => {
      RecorderStructTest_RecordContactDataStruct();
    })
    it('RecorderStructTest_UriUseClass', 0, () => {
      RecorderStructTest_UriUseClass();
    })
  })
}
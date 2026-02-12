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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import RecorderDesignateNumberSource from '../../../../../main/ets/common/model/RecorderDesignateNumberSource';
import { RecordConfigContactDataStruct } from '../../../../../main/ets/common/struct/RecorderSettingStruct';

let RecordConfigContactData: RecordConfigContactDataStruct = {
  phoneNumber: '13920981923',
  id: 2,
  name: 'liDaWei',
  image: $r('app.media.ic_user'),
  isChecked: false,
  isImageDefault: false,
  timestamp: new Date().getTime()
};

let RecorderDesignateNumberSourceTest_totalCount = () => {
  let recorderDesignateNumberSource = new RecorderDesignateNumberSource();
  let num = recorderDesignateNumberSource.totalCount();
  expect(num).assertEqual(0);
}

let RecorderDesignateNumberSourceTest_getData = () => {
  let recorderDesignateNumberSource = new RecorderDesignateNumberSource();
  recorderDesignateNumberSource.pushData(RecordConfigContactData);
  let result = recorderDesignateNumberSource.getData(0);
  expect(result).assertEqual(RecordConfigContactData);
};

let RecorderDesignateNumberSourceTest_addData = () => {
  let recorderDesignateNumberSource = new RecorderDesignateNumberSource();
  recorderDesignateNumberSource.addData(0, RecordConfigContactData);
  let result: number = recorderDesignateNumberSource.getAllData().length;
  expect(result).assertEqual(1);
};

let RecorderDesignateNumberSourceTest_pushData = () => {
  let recorderDesignateNumberSource = new RecorderDesignateNumberSource();
  recorderDesignateNumberSource.pushData(RecordConfigContactData);
  let result: number = recorderDesignateNumberSource.getAllData().length;
  expect(result).assertEqual(1);
};

let RecorderDesignateNumberSourceTest_concatData = () => {
  let recorderDesignateNumberSource = new RecorderDesignateNumberSource();
  recorderDesignateNumberSource.concatData([RecordConfigContactData]);
  let result: number = recorderDesignateNumberSource.getAllData().length;
  expect(result).assertEqual(1);
};

let RecorderDesignateNumberSourceTest_deleteDataByIndex = () => {
  let recorderDesignateNumberSource = new RecorderDesignateNumberSource();
  recorderDesignateNumberSource.concatData([RecordConfigContactData, RecordConfigContactData]);
  recorderDesignateNumberSource.deleteDataByIndex(0);
  let result: number = recorderDesignateNumberSource.getAllData().length;
  expect(result).assertEqual(1);
};

let RecorderDesignateNumberSourceTest_deleteDataAll = () => {
  let recorderDesignateNumberSource = new RecorderDesignateNumberSource();
  recorderDesignateNumberSource.concatData([RecordConfigContactData, RecordConfigContactData]);
  recorderDesignateNumberSource.deleteDataAll();
  let result: number = recorderDesignateNumberSource.getAllData().length;
  expect(result).assertEqual(0);
};

let RecorderDesignateNumberSourceTest_updateDataCheckStatusAll = () => {
  let recorderDesignateNumberSource = new RecorderDesignateNumberSource();
  recorderDesignateNumberSource.pushData(RecordConfigContactData);
  recorderDesignateNumberSource.updateDataCheckStatusAll(true);
  let result = recorderDesignateNumberSource.getData(0);
  expect(result.isChecked).assertEqual(true);
};

export default function RecorderDesignateNumberSourceTest() {
  describe('RecorderDesignateNumberSourceTest', () => {
    it('RecorderDesignateNumberSourceTest_totalCount', 0, () => {
      RecorderDesignateNumberSourceTest_totalCount();
    });
    it('RecorderDesignateNumberSourceTest_getData', 0, () => {
      RecorderDesignateNumberSourceTest_getData();
    });
    it('RecorderDesignateNumberSourceTest_addData', 0, () => {
      RecorderDesignateNumberSourceTest_addData();
    });
    it('RecorderDesignateNumberSourceTest_pushData', 0, () => {
      RecorderDesignateNumberSourceTest_pushData();
    });
    it('RecorderDesignateNumberSourceTest_concatData', 0, () => {
      RecorderDesignateNumberSourceTest_concatData();
    });
    it('RecorderDesignateNumberSourceTest_deleteDataByIndex', 0, () => {
      RecorderDesignateNumberSourceTest_deleteDataByIndex();
    });
    it('RecorderDesignateNumberSourceTest_deleteDataAll', 0, () => {
      RecorderDesignateNumberSourceTest_deleteDataAll();
    });
    it('RecorderDesignateNumberSourceTest_updateDataCheckStatusAll', 0, () => {
      RecorderDesignateNumberSourceTest_updateDataCheckStatusAll();
    });
  });
}
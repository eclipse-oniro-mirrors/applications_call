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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect, MockKit } from '@ohos/hypium';
import BasicDataSource from '../../../../../main/ets/common/model/BasicDataSource';
import RecorderDesignateNumberSource from '../../../../../main/ets/common/model/RecorderDesignateNumberSource';
import { RecordConfigContactDataStruct } from '../../../../../main/ets/common/struct/RecorderSettingStruct';
import { sleep } from '../utils/Sleep';

let basicDataSource = new BasicDataSource();
let recorderDesignateNumberSource = new RecorderDesignateNumberSource();
let listener: DataChangeListener = {
  onDataReloaded: () => {
  },
  onDataAdded: () => {
  },
  onDataAdd: () => {
  },
  onDataMoved: () => {
  },
  onDataMove: () => {
  },
  onDataDeleted: () => {
  },
  onDataDelete: () => {
  },
  onDataChanged: () => {
  },
  onDataChange: () => {
  },
  onDatasetChange: () => {
  }
};

let BasicDataSourceTest_totalCountFunc = () => {
  let basicDataSource = new BasicDataSource();
  let num = basicDataSource.totalCount();
  expect(num).assertEqual(0);
}

let BasicDataSourceTest_getDataFunc = () => {
  let basicDataSource = new BasicDataSource();
  let result = basicDataSource.getData(0);
  expect(result).assertEqual(null);
};

let BasicDataSourceTest_notifyDataReloadFunc = () => {
  let RecordConfigContactData: RecordConfigContactDataStruct = {
    phoneNumber: '13920981923',
    id: 1,
    name: 'liDaWei',
    image: $r('app.media.ic_user'),
    isChecked: false,
    isImageDefault: false,
    timestamp: new Date().getTime()
  };
  recorderDesignateNumberSource.pushData(RecordConfigContactData);
  basicDataSource.notifyDataReload();
  let result: number = recorderDesignateNumberSource.getAllData().length;
  expect(result).assertEqual(1);
};

let BasicDataSourceTest_notifyDataDeleteFunc = () => {
  let RecordConfigContactData: RecordConfigContactDataStruct = {
    phoneNumber: '13920981923',
    id: 2,
    name: 'liDaWei',
    image: $r('app.media.ic_user'),
    isChecked: false,
    isImageDefault: false,
    timestamp: new Date().getTime()
  };
  recorderDesignateNumberSource.pushData(RecordConfigContactData);
  recorderDesignateNumberSource.deleteDataByIndex(0);
  basicDataSource.notifyDataDelete(0);
  let result: number = recorderDesignateNumberSource.getAllData().length;
  expect(result).assertEqual(1);
};

let BasicDataSourceTest_notifyDataAddFunc = () => {
  basicDataSource.notifyDataAdd(1);
  let result: number = recorderDesignateNumberSource.getAllData().length;
  expect(result).assertEqual(1);
};

let BasicDataSourceTest_notifyDataChangeFunc = () => {
  basicDataSource.notifyDataChange(1);
  let result: number = recorderDesignateNumberSource.getAllData().length;
  expect(result).assertEqual(1);
};

let BasicDataSourceTest_registerDataChangeListenerFunc = () => {
  let listeners = [listener];
  basicDataSource.registerDataChangeListener(listener);
  expect(JSON.stringify(listeners[0])).assertEqual(JSON.stringify(listener));
};

let BasicDataSourceTest_registerDataChangeListenerFunc_02 = () => {
  let listeners = [listener];
  basicDataSource.notifyDataAdd(2);
  basicDataSource.registerDataChangeListener(listener);
  expect(!listener).assertFalse();
};

let BasicDataSourceTest_unregisterDataChangeListenerFunc = () => {
  basicDataSource.unregisterDataChangeListener(listener);
  expect(0).assertEqual(0);
};

let BasicDataSourceTest_unregisterDataChangeListenerFunc_02 = () => {
  basicDataSource.notifyDataAdd(5);
  basicDataSource.unregisterDataChangeListener(listener);
  expect(!listener).assertFalse();
};

let BasicDataSourceTest_notifyDataMoveFunc = () => {
  basicDataSource.notifyDataMove(0, 0);
  expect(0).assertEqual(0);
};

export default function BasicDataSourceTest() {
  describe('BasicDataSourceTest', () => {
    it('BasicDataSourceTest_registerDataChangeListener', 0, () => {
      BasicDataSourceTest_registerDataChangeListenerFunc();
    });
    it('BasicDataSourceTest_registerDataChangeListener_02', 0, () => {
      BasicDataSourceTest_registerDataChangeListenerFunc_02();
    });
    it('BasicDataSourceTest_totalCount', 0, async () => {
      BasicDataSourceTest_totalCountFunc();
    });
    it('BasicDataSourceTest_getData', 0, () => {
      BasicDataSourceTest_getDataFunc();
    });
    it('BasicDataSourceTest_notifyDataReload', 0, () => {
      BasicDataSourceTest_notifyDataReloadFunc();
    });
    it('BasicDataSourceTest_notifyDataAdd', 0, () => {
      BasicDataSourceTest_notifyDataAddFunc();
    });
    it('BasicDataSourceTest_notifyDataChange', 0, () => {
      BasicDataSourceTest_notifyDataChangeFunc();
    });
    it('BasicDataSourceTest_notifyDataDelete', 0, () => {
      BasicDataSourceTest_notifyDataDeleteFunc();
    });
    it('BasicDataSourceTest_notifyDataMove', 0, () => {
      BasicDataSourceTest_notifyDataMoveFunc();
    });
    it('BasicDataSourceTest_unregisterDataChangeListener', 0, () => {
      BasicDataSourceTest_unregisterDataChangeListenerFunc();
    });
    it('BasicDataSourceTest_unregisterDataChangeListener_02', 0, () => {
      BasicDataSourceTest_unregisterDataChangeListenerFunc_02();
    });
  });
}
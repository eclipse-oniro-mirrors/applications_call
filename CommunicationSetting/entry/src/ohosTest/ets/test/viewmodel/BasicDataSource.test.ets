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
import { beforeEach, describe, expect, it, MockKit } from '@ohos/hypium'
import BasicDataSource from '../../../../main/ets/viewmodel/BasicDataSource'

export default function BasicDataSourceTest() {
  describe('BasicDataSourceTest', () => {
    let basicDataSource: BasicDataSource;
    let listener: DataChangeListener;
    let listener2: DataChangeListener;
    let count: number = 0;

    beforeEach(() => {
      basicDataSource = new BasicDataSource();
      listener = {
        onDataReloaded: () => {
          count++;
        },
        onDataAdded: () => {
        },
        onDataAdd: (index: number) => {
          count += index;
        },
        onDataMoved: () => {
        },
        onDataMove: () => {
          count -= 2;
        },
        onDataDeleted: () => {
        },
        onDataDelete: () => {
          count = -1;
        },
        onDataChanged: () => {
        },
        onDataChange: (index: number) => {
          count = index;
        },
        onDatasetChange: (dataOperations: DataOperation[]): void => {
        }
      };
    })
    it('totalCountTest', 0, () => {
      expect(basicDataSource.totalCount()).assertEqual(0)
    })
    it('getDataTest', 0, () => {
      expect(basicDataSource.getData(0)).assertEqual(undefined)
    })
    it('registerDataChangeListenerTest01', 0, () => {
      basicDataSource.registerDataChangeListener(listener);
      expect(JSON.stringify(basicDataSource.listeners[0])).assertEqual(JSON.stringify(listener));
    })
    it('registerDataChangeListenerTest02', 0, () => {
      basicDataSource.registerDataChangeListener(listener);
      expect(JSON.stringify(basicDataSource.listeners[0])).assertEqual(JSON.stringify(listener));
      basicDataSource.registerDataChangeListener(listener);
      expect(basicDataSource.listeners.length).assertEqual(1);
    })
    it('registerDataChangeListenerTest03', 0, () => {
      basicDataSource.registerDataChangeListener(listener);
      expect(JSON.stringify(basicDataSource.listeners[0])).assertEqual(JSON.stringify(listener));
      basicDataSource.registerDataChangeListener(listener2);
      expect(basicDataSource.listeners.length).assertEqual(2);
    })
    it('unregisterDataChangeListenerTest', 0, () => {
      basicDataSource.listeners = [listener]
      basicDataSource.unregisterDataChangeListener(listener);
      expect(basicDataSource.listeners[0]).assertEqual(undefined);
    })
    it('notifyDataReloadTest01', 0, () => {
      count = 0;
      basicDataSource.listeners = [];
      basicDataSource.notifyDataReload();
      expect(count).assertEqual(0);
    })
    it('notifyDataReloadTest02', 0, () => {
      count = 0;
      basicDataSource.listeners = [listener];
      basicDataSource.notifyDataReload();
      expect(count).assertEqual(1);
    })
    it('notifyDataReloadTest03', 0, () => {
      count = 0;
      basicDataSource.listeners = [listener];
      basicDataSource.listeners.push(listener);
      basicDataSource.notifyDataReload();
      expect(count).assertEqual(2);
    })
    it('notifyDataAddTest01', 0, () => {
      count = 0;
      basicDataSource.listeners = [listener];
      basicDataSource.notifyDataAdd(1);
      expect(count).assertEqual(1);
    })
    it('notifyDataAddTest02', 0, () => {
      count = 0;
      basicDataSource.listeners = [listener]
      basicDataSource.notifyDataAdd(1);
      basicDataSource.notifyDataAdd(3);
      expect(count).assertEqual(4);
    })
    it('notifyDataChangeTest', 0, () => {
      count = 2;
      basicDataSource.listeners = [listener]
      basicDataSource.notifyDataChange(0);
      expect(count).assertEqual(0);
    })
    it('notifyDataDeleteTest', 0, () => {
      count = 0;
      basicDataSource.listeners = [listener]
      basicDataSource.notifyDataDelete(0);
      expect(count).assertEqual(-1);
    })
    it('notifyDataMoveTest', 0, () => {
      count = 4;
      basicDataSource.listeners = [listener]
      basicDataSource.listeners.push(listener);
      basicDataSource.notifyDataMove(0, 1);
      expect(count).assertEqual(0);
    })
    it('notifyComposite01', 0, () => {
      count = 0;
      basicDataSource.listeners = [listener]
      basicDataSource.notifyDataAdd(1);
      basicDataSource.notifyDataReload();
      expect(count).assertEqual(2);
    })
  })
}
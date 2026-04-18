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

import { describe, it, expect, MockKit, when, ArgumentMatchers } from '@ohos/hypium'
import { BasicDataSource } from '../../../../main/ets/data/BasicDataSource';

let onDataReloaded = () => {
}

let onDataAdd = (index: number) => {
}

let onDataChange = (index: number) => {
}

let onDataDelete = (index: number) => {
}

let onDataMove = (from: number, to: number) => {
}

let a = {
  onDataReloaded,
  onDataAdd,
  onDataChange,
  onDataDelete,
  onDataMove
} as DataChangeListener;

let basicDataSourceTestTotalCount = () => {
  let el = new BasicDataSource();
  let res = el.totalCount();
  expect(res).assertEqual(0);
}

let basicDataSourceTestGetData = () => {
  let el = new BasicDataSource();
  let res = el.getData(0);
  expect(res).assertUndefined()
}

let basicDataSourceTestRegisterDataChangeListener = () => {
  let el = new BasicDataSource();
  el.registerDataChangeListener(a);
  el.listeners.push(a);
  el.registerDataChangeListener(a);
  expect(true).assertTrue();
}

let basicDataSourceTestUnregisterDataChangeListener = () => {
  let el = new BasicDataSource();
  el.unregisterDataChangeListener(a);
  el.listeners.push(a);
  el.unregisterDataChangeListener(a);
  expect(true).assertTrue();
}

let basicDataSourceTestNotifyDataReload = () => {
  let el = new BasicDataSource();
  el.listeners = [a];
  el.notifyDataReload();
  expect(undefined).assertUndefined();
}

let basicDataSourceTestNotifyDataAdd = () => {
  let el = new BasicDataSource();
  el.listeners = [a];
  el.notifyDataAdd(0);
  expect(true).assertTrue();
}

let basicDataSourceTestNotifyDataChange = () => {
  let el = new BasicDataSource();
  el.listeners = [a];
  el.notifyDataChange(0);
  expect(true).assertEqual(true);
}

let basicDataSourceTestNotifyDataDelete = () => {
  let el = new BasicDataSource();
  el.listeners = [a];
  el.notifyDataDelete(0);
  expect(true).assertEqual(true);
}

let basicDataSourceTestNotifyDataMove = () => {
  let el = new BasicDataSource();
  el.listeners = [a, a];
  el.notifyDataMove(0, 1);
  expect(true).assertEqual(true);
}

export default function BasicDataSourceTest() {
  describe('BasicDataSourceTest', () => {
    it('basicDataSourceTest_totalCount', 0, () => {
      basicDataSourceTestTotalCount();
    })
    it('basicDataSourceTest_getData', 0, () => {
      basicDataSourceTestGetData();
    })
    it('basicDataSourceTest_registerDataChangeListener', 0, () => {
      basicDataSourceTestRegisterDataChangeListener();
    })
    it('basicDataSourceTest_unregisterDataChangeListener', 0, () => {
      basicDataSourceTestUnregisterDataChangeListener();
    })
    it('basicDataSourceTest_notifyDataReload', 0, () => {
      basicDataSourceTestNotifyDataReload();
    })
    it('basicDataSourceTest_notifyDataAdd', 0, () => {
      basicDataSourceTestNotifyDataAdd();
    })
    it('basicDataSourceTest_notifyDataChange', 0, () => {
      basicDataSourceTestNotifyDataChange();
    })
    it('basicDataSourceTest_notifyDataDelete', 0, () => {
      basicDataSourceTestNotifyDataDelete();
    })
    it('basicDataSourceTest_notifyDataMove', 0, () => {
      basicDataSourceTestNotifyDataMove();
    })
  })
}
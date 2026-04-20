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
import Getclone from '../../../main/ets/common/utils/Clone';
import HashSet from '@ohos.util.HashSet';

let CloneTest_Getclone_Not_Object = () => {
  let i: number = 10;
  let getClone = Getclone.getInstance();
  let iTest: number = getClone.clone(i);
  expect(i).assertEqual(iTest);
}

let CloneTest_Getclone_Set = () => {
  let set = new Set(['mate60', 'mate50']);
  let getClone = Getclone.getInstance();
  let iTest: Set<string> = getClone.clone(set);
  expect(iTest.has('mate60')).assertEqual(true);
}

let CloneTest_Getclone_Map = () => {
  let objects = new Map<string, Number>();
  objects.set('mate60', 10086);
  objects.set('mate50', 10010);
  let getClone = Getclone.getInstance();
  let iTest: Map<string, Number> = getClone.clone(objects);
  expect(iTest.get('mate60')).assertEqual(10086);
}

let CloneTest_Getclone_Array = () => {
  let array: Array<string> = ['mate60', 'mate50'];
  let getClone = Getclone.getInstance();
  let iTest: Array<string> = getClone.clone(array);
  expect(iTest[0]).assertEqual('mate60');
}

let CloneTest_Getclone_HashSet_Null = () => {
  let hashSet = new HashSet<string>();
  hashSet.add('mate60');
  hashSet.add('mate50');
  let getClone = Getclone.getInstance();
  let iTest: HashSet<string> = getClone.clone(hashSet);
  expect(iTest).assertEqual(null);
}

let CloneTest_Getclone_RegExp = () => {
  let regex = new RegExp('mms', 'i');
  let getClone = Getclone.getInstance();
  let iTest: RegExp = getClone.clone(regex);
  expect(iTest.test('mms')).assertEqual(true);
}

let CloneTest_Getclone_keys_true = () => {
  let test: boolean = true;
  let getClone = Getclone.getInstance();
  let iTest: boolean = getClone.clone({
    test
  });
  expect(iTest != undefined).assertEqual(test);
}

export default function CloneTest() {
  describe('CloneTest', () => {
    it('Getclone_Not_Object', 0, () => {
      CloneTest_Getclone_Not_Object();
    })
    it('Getclone_Set', 0, () => {
      CloneTest_Getclone_Set();
    })
    it('Getclone_Map', 0, () => {
      CloneTest_Getclone_Map();
    })
    it('Getclone_Array', 0, () => {
      CloneTest_Getclone_Array();
    })
    it('Getclone_HashSet_Null', 0, () => {
      CloneTest_Getclone_HashSet_Null();
    })
    it('Getclone_RegExp', 0, () => {
      CloneTest_Getclone_RegExp();
    })
    it('Getclone_keys_true', 0, () => {
      CloneTest_Getclone_keys_true();
    })
  })
}
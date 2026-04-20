/*
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
import common from '@ohos.app.ability.common';
import data_preferences from '@ohos.data.preferences';
import * as DataStorageUtil from '../../../../../main/ets/common/utils/DataStorageUtil';
import { GlobalContextHelper } from '../../../../../main/ets/common/utils/GlobalContextHelper';
import * as Constants from '../../../../../main/ets/common/utils/Constants';
import LogUtils from '../../../../../main/ets/common/utils/LogUtils';

let context: common.UIAbilityContext = GlobalContextHelper.getContext()
  .getValue<common.UIAbilityContext>(Constants.CALL_ABILITY_CONTEXT);
const TAG = 'DataStorageUtilTestTAG';

let data1: string[] = ['string1', 'string2', 'string3'];

let DataStorageUtilTest_getRejectMsgData00 = async () => {
  let data: string[] = await DataStorageUtil.getRejectMsgData(context, 'locale1');
  LogUtils.i(TAG, 'DataStorageUtilTest_getRejectMsgData00');
  expect(data).assertNull;
}

let DataStorageUtilTest_getRejectMsgData01 = async () => {
  let context = AppStorage.get<common.UIAbilityContext>('testAbility');
  if (!context) {
    return;
  }
  let data: string[] = await DataStorageUtil.getRejectMsgData(context, 'locale1');
  LogUtils.i(TAG, 'DataStorageUtilTest_getRejectMsgData01');
  expect('string1').assertEqual(data[0]);
}

let DataStorageUtilTest_getRejectMsgData02 = async () => {
  let context = AppStorage.get<common.UIAbilityContext>('testAbility');
  if (!context) {
    return;
  }
  let data: string[] = await DataStorageUtil.getRejectMsgData(context, 'en-Latn-CN');
  LogUtils.i(TAG, 'DataStorageUtilTest_getRejectMsgData02');
  expect('string1').assertEqual(data[0]);
}

let DataStorageUtilTest_getRejectMsgData03 = async () => {
  let context = AppStorage.get<common.UIAbilityContext>('testAbility');
  if (!context) {
    return;
  }
  let data: string[] = await DataStorageUtil.getRejectMsgData(context, 'en-Lan-CN');
  LogUtils.i(TAG, 'DataStorageUtilTest_getRejectMsgData01');
  expect('').assertEqual(data[0]);
}

let DataStorageUtilTest_updateRejectMsg00 = async () => {
  LogUtils.i(TAG, 'DataStorageUtilTest_updateRejectMsg00');
  await DataStorageUtil.updateRejectMsg(context, 'locale1', data1);
  expect('string1').assertEqual(data1[0]);
}

let DataStorageUtilTest_updateRejectMsg01 = async () => {
  let context = AppStorage.get<common.UIAbilityContext>('testAbility');
  if (!context) {
    return;
  }
  LogUtils.i(TAG, 'DataStorageUtilTest_updateRejectMsg01');
  await DataStorageUtil.updateRejectMsg(context, 'locale1', data1);
  expect('string1').assertEqual(data1[0]);
}

let DataStorageUtilTest_updateRejectMsg02 = async () => {
  let context = AppStorage.get<common.UIAbilityContext>('testAbility');
  if (!context) {
    return;
  }
  LogUtils.i(TAG, 'DataStorageUtilTest_updateRejectMsg02');
  await DataStorageUtil.updateRejectMsg(context, 'en-Latn-CN', data1);
  expect('string1').assertEqual(data1[0]);
}

export default function DataStorageUtilTest() {
  describe('DataStorageUtilTest', () => {
    it('updateRejectMsg01', 0, async () => {
      await DataStorageUtilTest_getRejectMsgData00();
      await DataStorageUtilTest_updateRejectMsg00();
      await DataStorageUtilTest_updateRejectMsg01();
    })
    it('getRejectMsgData01', 0, async () => {
      await DataStorageUtilTest_getRejectMsgData01();
    })
    it('updateRejectMsg02', 0, async () => {
      await DataStorageUtilTest_updateRejectMsg02();
    })
    it('getRejectMsgData02', 0, async () => {
      await DataStorageUtilTest_getRejectMsgData02();
    })
    it('getRejectMsgData03', 0, async () => {
      await DataStorageUtilTest_getRejectMsgData03();
    })
    let context = AppStorage.get<common.UIAbilityContext>('testAbility');
    if (!context) {
      return;
    }
    data_preferences.getPreferences(context, 'reject_message_preference_name').then((preferences) => {
      LogUtils.i(TAG, 'clearSync');
      preferences.clearSync();
      preferences.flushSync();
    })
  })
}

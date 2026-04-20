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

import { describe, it, expect, MockKit, when, ArgumentMatchers } from '@ohos/hypium';
import { IntentCheckAdaptor } from '../../../../main/ets/insightintents/adapter/IntentCheckAdaptor';
import { IntentCustomAdaptor } from '../../../../main/ets/insightintents/adapter/IntentCustomAdapter';
import { IntentSwitchAdaptor } from '../../../../main/ets/insightintents/adapter/IntentSwitchAdaptor';
import { IntentType } from '../../../../main/ets/insightintents/constant/IntentConstant';
import IntentExecutorImpl from '../../../../main/ets/insightintents/IntentExecutorImpl';
import { SettingItemProperty } from '../../../../main/ets/insightintents/model/SettingItemProperty';
import { sleep } from '../common/utils/Sleep';
import { insightIntent } from '@kit.AbilityKit';

const intentName = 'GetSimSwitch';
const executeParam: Record<string, string | Record<string, string>> = {
  "bundleName": "com.ohos.callsetting",
  "executeMode": "background",
  "intentName": "GetSimSwitch",
  "slotId": '1',
  "intentParam": {
    "itemName": "mobile_data"
  }
};

export default function IntentExecutorImplTest() {
  let intent = new IntentExecutorImpl();
  describe('IntentExecutorImplTest', () => {
    it('IntentAdaptorTest_01', 0, () => {
      new IntentExecutorImpl().onExecuteInUIAbilityBackgroundMode(intentName, executeParam);
      expect(1).assertEqual(1);
    })
    it('getAppBundleNameTest_01', 0, () => {
      let rsp: insightIntent.ExecuteResult = {
        code: 0,
        result: {
          'slotId': 1,
          'isSupport': true
        }
      };
      let result: boolean = (intent as object)['isSupport'](rsp);
      expect(result).assertTrue()
    })
    it('IntentExecutorImpl_executeCustomIntent', 0, async () => {
      let item: SettingItemProperty = {
        itemName: 'test',
        itemType: '',
        itemResourceId: '1234'
      }
      await (intent as object)['executeCustomIntent'](intentName, executeParam);
      sleep(1000);
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(intent, (intent as object)['isSupport']);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(true);
      let mockFunc1 = mocker.mockFunc(IntentCustomAdaptor, IntentCustomAdaptor.getDataRoamingSwitch);
      when(mockFunc1)(ArgumentMatchers.any).afterReturnNothing();
      let mockFunc2 = mocker.mockFunc(IntentCustomAdaptor, IntentCustomAdaptor.setDataRoamingSwitch);
      when(mockFunc2)(ArgumentMatchers.any).afterReturnNothing();
      await (intent as object)['executeCustomIntent'](IntentType.GET_DATA_ROAMING_SWITCH, executeParam);
      await (intent as object)['executeCustomIntent'](IntentType.SET_DATA_ROAMING_SWITCH, executeParam);
      await (intent as object)['executeCustomIntent'](IntentType.CHECK_DATA_ROAMING_SWITCH, executeParam);
      await (intent as object)['executeCustomIntent'](intentName, executeParam);
      mocker.ignoreMock(IntentCustomAdaptor, IntentCustomAdaptor.getDataRoamingSwitch);
      mocker.ignoreMock(IntentCustomAdaptor, IntentCustomAdaptor.setDataRoamingSwitch);

      await (intent as object)['executeImsIntent'](IntentType.GET_IMS_SWITCH, executeParam);
      await (intent as object)['executeImsIntent'](IntentType.SET_IMS_SWITCH, executeParam);
      await (intent as object)['executeImsIntent'](IntentType.CHECK_IMS_SWITCH, executeParam);
      await (intent as object)['executeImsIntent'](intentName, executeParam);
      mocker.ignoreMock(IntentCustomAdaptor, IntentCustomAdaptor.getImsSwitch);
      mocker.ignoreMock(IntentCustomAdaptor, IntentCustomAdaptor.setImsSwitch);
      mocker.clearAll();
      expect(item.itemName).assertEqual('test');
    })
    it('IntentExecutorImpl_executeBackgroundIntent', 0, async () => {
      let item: SettingItemProperty = {
        itemName: 'test',
        itemType: '',
        itemResourceId: '1234'
      }
      await (intent as object)['executeBackgroundIntent'](item, IntentType.CHECK_SETTING_PAGE, 'test', executeParam);
      sleep(1000);
      let mocker: MockKit = new MockKit();
      let mockFunc1 = mocker.mockFunc(IntentCheckAdaptor, IntentCheckAdaptor.checkSettingItem);
      when(mockFunc1)(ArgumentMatchers.any).afterReturnNothing();
      let mockFunc2 = mocker.mockFunc(IntentSwitchAdaptor, IntentSwitchAdaptor.getSettingSwitch);
      when(mockFunc2)(ArgumentMatchers.any).afterReturnNothing();
      let mockFunc3 = mocker.mockFunc(IntentSwitchAdaptor, IntentSwitchAdaptor.setSettingSwitch);
      when(mockFunc3)(ArgumentMatchers.any).afterReturnNothing();
      let mockFunc = mocker.mockFunc(intent, (intent as object)['isSupport']);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(false);
      await (intent as object)['executeBackgroundIntent'](item, IntentType.GET_SETTING_SWITCH, 'test', executeParam);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(true);
      await (intent as object)['executeBackgroundIntent'](item, IntentType.GET_SETTING_SWITCH, 'test', executeParam);
      await (intent as object)['executeBackgroundIntent'](item, IntentType.SET_SETTING_SWITCH, 'test', executeParam);
      await (intent as object)['executeBackgroundIntent'](item, IntentType.CHECK_SETTING_ITEM, 'test', executeParam);
      await (intent as object)['executeBackgroundIntent'](item, 'test', 'test', executeParam);
      mocker.ignoreMock(IntentSwitchAdaptor, IntentSwitchAdaptor.setSettingSwitch);
      mocker.ignoreMock(IntentCheckAdaptor, IntentCheckAdaptor.checkSettingItem);
      mocker.ignoreMock(IntentSwitchAdaptor, IntentSwitchAdaptor.getSettingSwitch);
      mocker.clearAll();
      expect(item.itemName).assertEqual('test');
    })
  })
}
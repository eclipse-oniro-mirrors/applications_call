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
import {
  describe,
  beforeAll,
  beforeEach,
  afterEach,
  afterAll,
  it,
  expect,
  MockKit,
  when,
  ArgumentMatchers
} from '@ohos/hypium';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { Constant } from '../../../../main/ets/common/constant/Constant';
import dataShare from '@ohos.data.dataShare';
import FuncManager from '../../../../main/ets/serviceextability/FuncManager';
import { GlobalContextHelper } from '../../../../main/ets/common/utils/GlobalContextHelper';
import common from '@ohos.app.ability.common';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import { sleep } from '../common/utils/Sleep';
import Want from '@ohos.app.ability.Want';
import { FuncManageReturn } from '../../../../main/ets/common/struct/RecorderStruct';
import { CallSettingConstant } from '../../../../main/ets/common/constant/CallSettingConstant';
import { ResourceUtil } from '../../../../main/ets/common/utils/ResourceUtil';

let FuncManagerTest_queryIsRecorderContact = async (testContext: Context) => {
  let phoneNumber: string = '17314984771';
  let funcManager = new FuncManager(testContext);
  funcManager.queryIsRecorderContact(phoneNumber);
  expect(true).assertEqual(true);
};

let FuncManagerTest_queryIsRecorderContact_01Func = async (testContext: Context) => {
  let phoneNumber: string = '17314984771';
  let uri = Constant.RECORDER_DATA_SHARE_URL + Constant.RECORD_CONTACT;
  let condition = new dataSharePredicates.DataSharePredicates();
  condition.equalTo('phone_number', phoneNumber);
  let dataHelper = await dataShare.createDataShareHelper(testContext, uri);
  let dataFir: ValuesBucket = {
    'phone_number': '17314984771'
  };
  await dataHelper.insert(uri, dataFir);
  let funcManager = new FuncManager(testContext);
  let bol = await funcManager.queryIsRecorderContact(phoneNumber);
  expect(bol).assertEqual(true);
  dataHelper.delete(uri, condition);
};

let FuncManagerTest_queryIsRecorderContact_02Func = async (testContext: Context) => {
  let phoneNumber: string = '17314984771';
  let uri = Constant.RECORDER_DATA_SHARE_URL + Constant.RECORD_CONTACT;
  let condition = new dataSharePredicates.DataSharePredicates();
  condition.equalTo('phone_number', '17314984770');
  let dataHelper = await dataShare.createDataShareHelper(testContext, uri);
  let dataFir: ValuesBucket = {
    'phone_number': '17314984770'
  };
  await dataHelper.insert(uri, dataFir);
  let funcManager = new FuncManager(testContext);
  let bol = await funcManager.queryIsRecorderContact(phoneNumber);
  expect(bol).assertEqual(false);
  dataHelper.delete(uri, condition);
};

let FuncManagerTest_getIsDesignateNumber_01Func = async (testContext: Context) => {
  let uri = Constant.RECORDER_DATA_SHARE_URL + Constant.RECORD_CONFIG;
  let dataHelper = await dataShare.createDataShareHelper(testContext, uri);
  let dataFir: ValuesBucket = {
    'is_open': CallSettingConstant.CLOSE_RECORDING_STATUS,
    'object': CallSettingConstant.RECORDING_WAY_ALL_NUMBER
  }
  await dataHelper.insert(uri, dataFir);
  let want: Want = {
    bundleName: 'test'
  };
  let funcManager = new FuncManager(testContext);
  funcManager.getIsDesignateNumber(want, (data: FuncManageReturn) => {
    expect(data.message).assertEqual('the call recording function is disabled');
  });
};

let FuncManagerTest_sendNotification_01 = async (testContext: Context) => {
  let funcManager = new FuncManager(testContext);
  funcManager.sendNotification();
  await sleep(1000);
  expect(true).assertTrue();
}

let FuncManagerTest_sendNotification_02 = async (testContext: Context) => {
  let funcManager = new FuncManager(testContext);
  let mocker: MockKit = new MockKit();
  let mockFun: Function = mocker.mockFunc(ResourceUtil, ResourceUtil.resourceToString);
  when(mockFun)(ArgumentMatchers.any).afterThrow('error');
  funcManager.sendNotification();
  await sleep(1000);
  expect(true).assertTrue();
}

let FuncManagerTest_getIsDesignateNumber_02 = async (testContext: Context) => {
  let funcManager = new FuncManager(testContext);
  let mocker: MockKit = new MockKit();
  let mockFun: Function = mocker.mockFunc(funcManager, funcManager.queryRecorderConfig);
  when(mockFun)(ArgumentMatchers.any).afterReturn({
    isOpen: CallSettingConstant.OPEN_RECORDING_STATUS,
    object: CallSettingConstant.RECORDING_WAY_ALL_NUMBER
  });
  let want: Want = {
    bundleName: 'test'
  };
  funcManager.getIsDesignateNumber(want, () => {
  })
  await sleep(1000);
  mocker.clearAll();
  expect(true).assertTrue();
}

let FuncManagerTest_getIsDesignateNumber_03 = async (testContext: Context) => {
  let funcManager = new FuncManager(testContext);
  let mocker: MockKit = new MockKit();
  let mockFun: Function = mocker.mockFunc(funcManager, funcManager.queryRecorderConfig);
  when(mockFun)(ArgumentMatchers.any).afterReturn({
    isOpen: CallSettingConstant.OPEN_RECORDING_STATUS,
    object: CallSettingConstant.RECORDING_WAY_DESIGNATE_NUMBER
  });
  let want: Want = {
    bundleName: 'test'
  };
  funcManager.getIsDesignateNumber(want, () => {
  })
  await sleep(1000);
  mocker.clearAll();
  expect(true).assertTrue();
}

let FuncManagerTest_getIsDesignateNumber_04 = async (testContext: Context) => {
  let funcManager = new FuncManager(testContext);
  let mocker: MockKit = new MockKit();
  let mockFun: Function = mocker.mockFunc(funcManager, funcManager.queryRecorderConfig);
  let mockFun1: Function = mocker.mockFunc(funcManager, funcManager.queryIsRecorderContact);
  when(mockFun)(ArgumentMatchers.any).afterReturn({
    isOpen: CallSettingConstant.OPEN_RECORDING_STATUS,
    object: CallSettingConstant.RECORDING_WAY_DESIGNATE_NUMBER
  });
  when(mockFun1)(ArgumentMatchers.any).afterReturn(true);
  let want: Want = {
    bundleName: 'test',
    parameters: {
      accountNumber: '12345678910'
    }
  };
  funcManager.getIsDesignateNumber(want, () => {
  });
  await sleep(1000);
  mocker.clearAll();
  expect(true).assertTrue();
}

let FuncManagerTest_getIsDesignateNumber_05 = async (testContext: Context) => {
  let funcManager = new FuncManager(testContext);
  let mocker: MockKit = new MockKit();
  let mockFun: Function = mocker.mockFunc(funcManager, funcManager.queryRecorderConfig);
  let mockFun1: Function = mocker.mockFunc(funcManager, funcManager.queryIsRecorderContact);
  when(mockFun)(ArgumentMatchers.any).afterReturn({
    isOpen: CallSettingConstant.OPEN_RECORDING_STATUS,
    object: CallSettingConstant.RECORDING_WAY_DESIGNATE_NUMBER
  });
  when(mockFun1)(ArgumentMatchers.any).afterReturn(false);
  let want: Want = {
    bundleName: 'test',
    parameters: {
      accountNumber: '12345678910'
    }
  };
  funcManager.getIsDesignateNumber(want, () => {
  });
  await sleep(1000);
  mocker.clearAll();
  expect(true).assertTrue();
}

export default function FuncManagerTest() {
  describe('FuncManagerTest', () => {
    let testContext: Context = GlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    it('FuncManagerTest_queryIsRecorderContact', 0, async () => {
      await FuncManagerTest_queryIsRecorderContact(testContext);
    });
    it('FuncManagerTest_getIsDesignateNumber_01', 0, async () => {
      await FuncManagerTest_getIsDesignateNumber_01Func(testContext);
    });
    it('FuncManagerTest_sendNotification_01', 0, async () => {
      await FuncManagerTest_sendNotification_01(testContext);
    });
    it('FuncManagerTest_sendNotification_02', 0, async () => {
      await FuncManagerTest_sendNotification_02(testContext);
    });
    it('FuncManagerTest_getIsDesignateNumber_02', 0, async () => {
      await FuncManagerTest_getIsDesignateNumber_02(testContext);
    });
    it('FuncManagerTest_getIsDesignateNumber_03', 0, async () => {
      await FuncManagerTest_getIsDesignateNumber_03(testContext);
    });
    it('FuncManagerTest_getIsDesignateNumber_04', 0, async () => {
      await FuncManagerTest_getIsDesignateNumber_04(testContext);
    });
    it('FuncManagerTest_getIsDesignateNumber_05', 0, async () => {
      await FuncManagerTest_getIsDesignateNumber_05(testContext);
    });
  });
};
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
  it,
  expect,
  MockKit,
  when,
  ArgumentMatchers
} from '@ohos/hypium';
import { ApnListCommon, DataListClass, MobileDataSharedPreferencesUtils } from '@ohos/common/CommonIndex';
import sim from '@ohos.telephony.sim';
import preferences from '@ohos.data.preferences';

let apnListCommon = new ApnListCommon();
let data_1: DataListClass = {
  title: '0',
  msg: '0',
  id: 0,
  isDefault: 0,
  apnTypes: ''
}
let data_2: DataListClass = {
  title: '0',
  msg: '0',
  id: 0,
  isDefault: 0,
  apnTypes: ''
}
let sharedPreferences: MobileDataSharedPreferencesUtils;
let ApnListCommonTest_initSim_01 = () => {
  apnListCommon.initSim(-1);
  expect(true).assertTrue();
}

let ApnListCommonTest_initSim_02 = () => {
  apnListCommon.initSim(0);
  expect(true).assertTrue();
}

let ApnListCommonTest_initSim_03 = () => {
  apnListCommon.initSim(1);
  expect(true).assertTrue();
}

let ApnListCommonTest_getSelectApn_01 = () => {
  apnListCommon.cardType = -1;
  apnListCommon.getSelectApn();
  expect(true).assertTrue();
}

let ApnListCommonTest_getSelectApn_02 = async () => {
  apnListCommon.cardType = 0;
  let icc = await sim.getSimIccId(apnListCommon.cardType);
  await sharedPreferences.getFromPreferences('selectAPN_common_' + icc, -1)
    .then((data: preferences.ValueType) => {
      data = 0;
    })
  apnListCommon.getSelectApn();
  expect(true).assertTrue();
}

let ApnListCommonTest_getSelectApnVal_01 = async () => {
  apnListCommon.cardType = -1;
  let result = await apnListCommon.getSelectApnVal();
  expect(result).assertEqual(-1);
}

let ApnListCommonTest_getSelectApnVal_02 = async () => {
  apnListCommon.cardType = 0;
  let result = await apnListCommon.getSelectApnVal();
  expect(result).assertEqual(0);
}

let ApnListCommonTest_selectApnCommon_01 = () => {
  apnListCommon.cardType = -1;
  apnListCommon.selectApnCommon(-1);
  expect(true).assertTrue();
}

let ApnListCommonTest_selectApnCommon_02 = () => {
  apnListCommon.cardType = 0;
  apnListCommon.selectApnCommon(1);
  expect(true).assertTrue();
}

let ApnListCommonTest_setPreferApn = () => {
  let data: sim.IccAccountInfo = {
    simId: 0,
    slotIndex: 0,
    isEsim: false,
    isActive: false,
    iccId: '',
    showName: '',
    showNumber: '',
    simLabelIndex: 0,
    operatorName: ''
  }
  let mocker: MockKit = new MockKit();
  let mockFun: Function = mocker.mockFunc(sim.getSimAccountInfo, sim.getSimAccountInfo);
  when(mockFun)(ArgumentMatchers.any).afterReturn(new Promise<string>((res: Function, rej: Function) => {
    res(undefined);
  }));
  apnListCommon.setPreferApn();
  expect(true).assertTrue();
  mocker.clearAll();
}

let ApnListCommonTest_getPreferApn = async () => {
  let data: sim.IccAccountInfo = {
    simId: -1,
    slotIndex: 0,
    isEsim: false,
    isActive: false,
    iccId: '',
    showName: '',
    showNumber: '',
    simLabelIndex: 0,
    operatorName: ''
  }
  let mocker: MockKit = new MockKit();
  let mockFun: Function = mocker.mockFunc(sim.getSimAccountInfo, sim.getSimAccountInfo(0).then);
  when(mockFun)(ArgumentMatchers.any).afterReturn(new Promise<string>((res: Function, rej: Function) => {
    res(data);
  }));
  apnListCommon.getPreferApn();
  expect(true).assertTrue();
  mocker.clearAll();
}

let ApnListCommonTest_getMccmnc = () => {
  apnListCommon.getMccmnc();
  expect(true).assertTrue();
}

let ApnListCommonTest_getAllApnList = () => {
  apnListCommon.getAllApnList();
  expect(true).assertTrue();
}

let ApnListCommonTest_sortArr_01 = () => {
  data_2.msg = '1';
  apnListCommon.sortArr([data_1, data_2]);
  expect(true).assertTrue();
}

let ApnListCommonTest_sortArr_02 = async () => {
  data_2.msg = '-1';
  apnListCommon.sortArr([data_1, data_2]);
  expect(true).assertTrue();
}

let ApnListCommonTest_sortArr_03 = () => {
  data_2.title = '1';
  apnListCommon.sortArr([data_1, data_2]);
  expect(true).assertTrue();
}

let ApnListCommonTest_sortArr_04 = () => {
  data_2.title = '-1';
  apnListCommon.sortArr([data_1, data_2]);
  expect(true).assertTrue();
}

let ApnListCommonTest_sortArr_05 = () => {
  data_1.isDefault = 1;
  data_2.isDefault = 2;
  apnListCommon.sortArr([data_1, data_2]);
  expect(true).assertTrue();
}

let ApnListCommonTest_dataReset = () => {
  apnListCommon.dataReset();
  expect(true).assertTrue();
}

export function ApnListCommonTest01() {
  describe('ApnListCommonTest01', () => {
    it('ApnListCommonTest_initSim_01', 0, () => {
      ApnListCommonTest_initSim_01();
    });
    it('ApnListCommonTest_initSim_02', 0, () => {
      ApnListCommonTest_initSim_02();
    });
    it('ApnListCommonTest_initSim_03', 0, () => {
      ApnListCommonTest_initSim_03();
    });
    it('ApnListCommonTest_getSelectApn_01', 0, () => {
      ApnListCommonTest_getSelectApn_01();
    });
    it('ApnListCommonTest_getSelectApn_02', 0, () => {
      ApnListCommonTest_getSelectApn_02();
    });
    it('ApnListCommonTest_getSelectApnVal_01', 0, () => {
      ApnListCommonTest_getSelectApnVal_01();
    });
    it('ApnListCommonTest_getSelectApnVal_02', 0, () => {
      ApnListCommonTest_getSelectApnVal_02();
    });
    it('ApnListCommonTest_selectApnCommon_01', 0, () => {
      ApnListCommonTest_selectApnCommon_01();
    });
    it('ApnListCommonTest_selectApnCommon_02', 0, () => {
      ApnListCommonTest_selectApnCommon_02();
    });
    it('ApnListCommonTest_setPreferApn', 0, () => {
      ApnListCommonTest_setPreferApn();
    });
    it('ApnListCommonTest_getPreferApn', 0, () => {
      ApnListCommonTest_getPreferApn();
    });
    it('ApnListCommonTest_getMccmnc', 0, () => {
      ApnListCommonTest_getMccmnc();
    });
    it('ApnListCommonTest_getAllApnList', 0, () => {
      ApnListCommonTest_getAllApnList();
    });
    it('ApnListCommonTest_dataReset', 0, () => {
      ApnListCommonTest_dataReset();
    });
  });
}

export function ApnListCommonTest02() {
  describe('ApnListCommonTest02', () => {
    it('ApnListCommonTest_sortArr_01', 0, () => {
      ApnListCommonTest_sortArr_01();
    });
    it('ApnListCommonTest_sortArr_02', 0, () => {
      ApnListCommonTest_sortArr_02();
    });
    it('ApnListCommonTest_sortArr_03', 0, () => {
      ApnListCommonTest_sortArr_03();
    });
    it('ApnListCommonTest_sortArr_04', 0, () => {
      ApnListCommonTest_sortArr_04();
    });
    it('ApnListCommonTest_sortArr_05', 0, () => {
      ApnListCommonTest_sortArr_05();
    });
  });
}
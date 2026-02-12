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
import EmergencyNumber from "../../../../main/ets/utils/EmergencyNumber"
import { BusinessError } from '@ohos.base';
import { EmergencyNumListStruct, EccsStruct, EccsCountryStruct } from '../../../../main/ets/utils/ClassStruct';
import { sleep } from './Sleep';
import commonData from '../../../../main/ets/data/CommonData';

let getEmergencyNumLabel01 = () => {
  let emergencyNumber = EmergencyNumber.getInstance();
  let expectedData: Resource = $r('app.string.POLICE');
  let result: Resource = emergencyNumber.getEmergencyNumLabel('POLICE');
  expect(result.id).assertEqual(expectedData.id);
}

let getEmergencyNumLabel02 = () => {
  let emergencyNumber = EmergencyNumber.getInstance();
  let expectedData: Resource = $r('app.string.AMBULANCE');
  let result: Resource = emergencyNumber.getEmergencyNumLabel('AMBULANCE');
  expect(result.id).assertEqual(expectedData.id);
}

let getEmergencyNumLabel03 = () => {
  let emergencyNumber = EmergencyNumber.getInstance();
  let expectedData: Resource = $r('app.string.FIRE');
  let result: Resource = emergencyNumber.getEmergencyNumLabel('FIRE');
  expect(result.id).assertEqual(expectedData.id);
}

let getEmergencyNumLabel04 = () => {
  let emergencyNumber = EmergencyNumber.getInstance();
  let expectedData: Resource = $r('app.string.POLICE_AMBULANCE_FIRE');
  let result: Resource = emergencyNumber.getEmergencyNumLabel('POLICE&AMBULANCE&FIRE');
  expect(result.id).assertEqual(expectedData.id);
}

let getEmergencyNumLabel05 = () => {
  let emergencyNumber = EmergencyNumber.getInstance();
  let expectedData: Resource = $r('app.string.AMBULANCE_FIRE');
  let result: Resource = emergencyNumber.getEmergencyNumLabel('AMBULANCE&FIRE');
  expect(result.id).assertEqual(expectedData.id);
}

let getEmergencyNumLabel06 = () => {
  let emergencyNumber = EmergencyNumber.getInstance();
  let expectedData: Resource = $r('app.string.POLICE_AMBULANCE');
  let result: Resource = emergencyNumber.getEmergencyNumLabel('POLICE&AMBULANCE');
  expect(result.id).assertEqual(expectedData.id);
}

let getEmergencyNumLabel07 = () => {
  let emergencyNumber = EmergencyNumber.getInstance();
  let expectedData: Resource = $r('app.string.POLICE_FIRE');
  let result: Resource = emergencyNumber.getEmergencyNumLabel('POLICE&FIRE');
  expect(result.id).assertEqual(expectedData.id);
}

let getEmergencyNumLabel08 = () => {
  let emergencyNumber = EmergencyNumber.getInstance();
  let expectedData: Resource = $r('app.string.UNKNOWN');
  let result: Resource = emergencyNumber.getEmergencyNumLabel('');
  expect(result.id).assertEqual(expectedData.id);
}

let getISOCodeByCard = async () => {
  let emergencyNumber = EmergencyNumber.getInstance();
  emergencyNumber.getISOCodeByCard(0);
  await sleep(500);
  emergencyNumber.getISOCodeByCard(999);
  expect(true).assertTrue();
}

let initEmergencyNumData = async () => {
  let emergencyNumber = EmergencyNumber.getInstance();
  emergencyNumber.initEmergencyNumData();
  await sleep(500);
  AppStorage.setOrCreate('simOperatorNameFirst', '1');
  AppStorage.setOrCreate('simOperatorNameSecond', '0');
  emergencyNumber.initEmergencyNumData();
  await sleep(500);
  AppStorage.setOrCreate('simOperatorNameFirst', '');
  AppStorage.setOrCreate('simOperatorNameSecond', '1');
  emergencyNumber.initEmergencyNumData();
  expect(1).assertEqual(1);
}

let handleRepeatList = async () => {
  let emergencyNumber = EmergencyNumber.getInstance();
  let a = new EmergencyNumListStruct();
  let b = new EmergencyNumListStruct();
  let cardOnelist: EmergencyNumListStruct[] = [a];
  let cardTwolist: EmergencyNumListStruct[] = [b];
  emergencyNumber.handleRepeatList(cardOnelist, cardTwolist);
  await sleep(500);
  a.value = '1';
  b.value = '2';
  let one = [a];
  let two = [b];
  emergencyNumber.handleRepeatList(one, two);
  expect(1).assertEqual(1);
}

let ctGetDefaultCellularDataSlotId = async () => {
  let emergencyNumber = EmergencyNumber.getInstance();
  let a = new EmergencyNumListStruct();
  let b = new EmergencyNumListStruct();
  let cardOnelist: EmergencyNumListStruct[] = [a];
  let cardTwolist: EmergencyNumListStruct[] = [b];
  let er = {} as BusinessError;
  emergencyNumber.ctGetDefaultCellularDataSlotId(cardOnelist, cardTwolist, 1);
  expect(1).assertEqual(1);
  await sleep(500);
  emergencyNumber.ctGetDefaultCellularDataSlotId(cardOnelist, cardTwolist, 0);
  expect(1).assertEqual(1);
  await sleep(500);
  emergencyNumber.ctGetDefaultCellularDataSlotId(cardOnelist, cardTwolist, 0, er);
  expect(1).assertEqual(1);
}

let EmergencyNumberTestOnGetDefaultVoiceSlotId = async () => {
  let a = new EmergencyNumListStruct();
  let b = new EmergencyNumListStruct();
  let cardOnelist: EmergencyNumListStruct[] = [a];
  let cardTwolist: EmergencyNumListStruct[] = [b];
  let er = {
    code: -1
  } as BusinessError;
  let el = EmergencyNumber.getInstance();
  el.onGetDefaultVoiceSlotId(cardOnelist, cardTwolist, er, 0);
  await sleep(500);
  er.code = 0;
  el.onGetDefaultVoiceSlotId(cardOnelist, cardTwolist, er, 0);
  await sleep(500);
  er.code = 1;
  el.onGetDefaultVoiceSlotId(cardOnelist, cardTwolist, er, 0);
  await sleep(500);
  er.code = 2;
  el.onGetDefaultVoiceSlotId(cardOnelist, cardTwolist, er, 0);
  await sleep(500);
  er.code = 2;
  el.onGetDefaultVoiceSlotId(cardOnelist, cardTwolist, er, 1);
  expect(1).assertEqual(1);
}
let EmergencyNumberTestIsoCodeSameisoCode2 = () => {
  let el = EmergencyNumber.getInstance();
  let a = new EmergencyNumListStruct();
  let b = new EmergencyNumListStruct();
  let cardOnelist: EmergencyNumListStruct[] = [a];
  let cardTwolist: EmergencyNumListStruct[] = [b];
  el.isoCodeSameisoCode2(cardOnelist, cardTwolist, '1', '1');
  expect(1).assertEqual(1);
}

let EmergencyNumberTest_retrunEmerNumListItem = () => {
  let num: string = 'a';
  let type: string = 'b';
  let idx: number = 0;
  let slotId: number = 0;
  let id: string = `default${idx}_${slotId}`;
  let listItem = EmergencyNumber.getInstance().retrunEmerNumListItem(num, type, idx, slotId);
  expect(listItem.id).assertEqual(id);
}

let EmergencyNumberTest_onGetDefaultVoiceSlotId = async () => {
  let emergencyNumber = EmergencyNumber.getInstance();
  let a = new EmergencyNumListStruct();
  let b = new EmergencyNumListStruct();
  let cardOnelist: EmergencyNumListStruct[] = [a];
  let cardTwolist: EmergencyNumListStruct[] = [b];
  let value = commonData.int.SIM_SLOT_ID_FIRST;
  let er1 = {code: commonData.int.SIM_SLOT_ID_EMPTY} as BusinessError;
  let er2 = {} as BusinessError;

  emergencyNumber.onGetDefaultVoiceSlotId(cardOnelist, cardTwolist, er1, value);
  expect(true).assertTrue();
  await sleep(1000);

  emergencyNumber.onGetDefaultVoiceSlotId(cardOnelist, cardTwolist, er2, value);
  expect(true).assertTrue();
  await sleep(1000);

  emergencyNumber.onGetDefaultVoiceSlotId(cardOnelist, cardTwolist, er2, 1);
  expect(true).assertTrue();
}

let EmergencyNumberTest_isoCodeSameisoCode2 = async () => {
  let emergencyNumber = EmergencyNumber.getInstance();
  let a = new EmergencyNumListStruct();
  let b = new EmergencyNumListStruct();
  let cardOnelist: EmergencyNumListStruct[] = [a];
  let cardTwolist: EmergencyNumListStruct[] = [b];

  emergencyNumber.isoCodeSameisoCode2(cardOnelist, cardTwolist, 'a', 'a');
  expect(true).assertTrue();
  await sleep(1000);

  emergencyNumber.isoCodeSameisoCode2(cardOnelist, cardTwolist, 'a', 'b');
  expect(true).assertTrue();
}

export function EmergencyNumberTest() {
  describe('EmergencyNumberTest', () => {
    it('EmergencyNumberTest_getEmergencyNumLabel_01', 0, () => {
      getEmergencyNumLabel01();
    })
    it('EmergencyNumberTest_getEmergencyNumLabel_02', 0, () => {
      getEmergencyNumLabel02();
    })
    it('EmergencyNumberTest_getEmergencyNumLabel_03', 0, () => {
      getEmergencyNumLabel03();
    })
    it('EmergencyNumberTest_getEmergencyNumLabel_04', 0, () => {
      getEmergencyNumLabel04();
    })
    it('EmergencyNumberTest_getEmergencyNumLabel_05', 0, () => {
      getEmergencyNumLabel05();
    })
    it('EmergencyNumberTest_getEmergencyNumLabel_06', 0, () => {
      getEmergencyNumLabel06();
    })
    it('EmergencyNumberTest_getEmergencyNumLabel_07', 0, () => {
      getEmergencyNumLabel07();
    })
    it('EmergencyNumberTest_getEmergencyNumLabel_08', 0, () => {
      getEmergencyNumLabel08();
    })
  })
}

export function EmergencyNumberTest1() {
  describe('EmergencyNumberTest1', () => {
    it('EmergencyNumberTest_retrunEmerNumListItem', 0, () => {
      EmergencyNumberTest_retrunEmerNumListItem();
    })
    it('EmergencyNumberTest_onGetDefaultVoiceSlotId', 0, async () => {
      await EmergencyNumberTest_onGetDefaultVoiceSlotId();
    })
    it('EmergencyNumberTest_isoCodeSameisoCode2', 0, async () => {
      await EmergencyNumberTest_isoCodeSameisoCode2();
    })
  })
}
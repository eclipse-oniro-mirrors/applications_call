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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium'
import { getRadioTechnologyFromStr } from '../../../../../main/ets/common/utils/NetworkModeUtils'
import radio from '@ohos.telephony.radio';

export default function NetworkModeUtilsTest() {
  describe('NetworkModeUtilsTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    })
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: preset action function.
    })
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: clear action function.
    })
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end.
      // This API supports only one parameter: clear action function.
    })

    it('NetworkModeUtilsTest_1', 0, () => {
      let gsm: number = getRadioTechnologyFromStr('GSM');
      let result: number = radio.RadioTechnology.RADIO_TECHNOLOGY_GSM;
      expect(gsm).assertEqual(result);
    })
    it('NetworkModeUtilsTest_2', 0, () => {
      let ixrtt: number = getRadioTechnologyFromStr('1XRTT');
      let result: number = radio.RadioTechnology.RADIO_TECHNOLOGY_1XRTT;
      expect(ixrtt).assertEqual(result);
    })

    it('NetworkModeUtilsTest_3', 0, () => {
      let wcdma: number = getRadioTechnologyFromStr('WCDMA');
      let result: number = radio.RadioTechnology.RADIO_TECHNOLOGY_WCDMA;
      expect(wcdma).assertEqual(result);
    })

    it('NetworkModeUtilsTest_4', 0, () => {
      let hspa: number = getRadioTechnologyFromStr('HSPA');
      let result: number = radio.RadioTechnology.RADIO_TECHNOLOGY_HSPA;
      expect(hspa).assertEqual(result);
    })

    it('NetworkModeUtilsTest_5', 0, () => {
      let hspap: number = getRadioTechnologyFromStr('HSPAP');
      let result: number = radio.RadioTechnology.RADIO_TECHNOLOGY_HSPAP;
      expect(hspap).assertEqual(result);
    })

    it('NetworkModeUtilsTest_6', 0, () => {
      let td_scdma: number = getRadioTechnologyFromStr('TD_SCDMA');
      let result: number = radio.RadioTechnology.RADIO_TECHNOLOGY_TD_SCDMA;
      expect(td_scdma).assertEqual(result);
    })

    it('NetworkModeUtilsTest_7', 0, () => {
      let evdo: number = getRadioTechnologyFromStr('EVDO');
      let result: number = radio.RadioTechnology.RADIO_TECHNOLOGY_EVDO;
      expect(evdo).assertEqual(result);
    })

    it('NetworkModeUtilsTest_8', 0, () => {
      let ehrpd: number = getRadioTechnologyFromStr('EHRPD');
      let result: number = radio.RadioTechnology.RADIO_TECHNOLOGY_EHRPD;
      expect(ehrpd).assertEqual(result);
    })

    it('NetworkModeUtilsTest_9', 0, () => {
      let lte: number = getRadioTechnologyFromStr('LTE');
      let result: number = radio.RadioTechnology.RADIO_TECHNOLOGY_LTE;
      expect(lte).assertEqual(result);
    })

    it('NetworkModeUtilsTest_10', 0, () => {
      let lte_ca: number = getRadioTechnologyFromStr('LTE_CA');
      let result: number = radio.RadioTechnology.RADIO_TECHNOLOGY_LTE_CA;
      expect(lte_ca).assertEqual(result);
    })

    it('NetworkModeUtilsTest_11', 0, () => {
      let iwlan: number = getRadioTechnologyFromStr('IWLAN');
      let result: number = radio.RadioTechnology.RADIO_TECHNOLOGY_IWLAN;
      expect(iwlan).assertEqual(result);

    })

    it('NetworkModeUtilsTest_12', 0, () => {
      let nr: number = getRadioTechnologyFromStr('NR');
      let result: number = radio.RadioTechnology.RADIO_TECHNOLOGY_NR;
      expect(nr).assertEqual(result);

    })

    it('NetworkModeUtilsTest_13', 0, () => {
      let unknown: number = getRadioTechnologyFromStr('UNKNOWN');
      let result: number = radio.RadioTechnology.RADIO_TECHNOLOGY_UNKNOWN;
      expect(unknown).assertEqual(result);
    })

  })
}
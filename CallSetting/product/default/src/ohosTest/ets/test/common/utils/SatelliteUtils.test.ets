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

import { CallSettingGlobalContextHelper } from '@ohos/common';
import { describe, it, expect, MockKit, ArgumentMatchers, when } from '@ohos/hypium';
import SatelliteUtils from '../../../../../main/ets/common/utils/SatelliteUtils';
import SatelliteSearchManager from '../../../../../main/ets/manager/SatelliteSearchManager';
import { common } from '@kit.AbilityKit';
import { CALL_SETTING_ABILITY_CONTEXT } from '../../../../../main/ets/common/constant/CallSettingsConstant';

let SatelliteUtilsTest_checkAzimuthOk = () => {
  let ret = SatelliteUtils.checkAzimuthOk(1);
  expect(ret).assertEqual(true);
}

let SatelliteUtilsTest_checkPitchOk = () => {
  let ret = SatelliteUtils.checkPitchOk(1);
  expect(ret).assertEqual(true);
}

let SatelliteUtilsTest_getSateRotationAngles_01 = () => {
  let ret = SatelliteUtils.getSateRotationAngles(1, 60);
  expect(ret).assertEqual(2);
}

let SatelliteUtilsTest_getSateRotationAngles_02 = () => {
  let ret = SatelliteUtils.getSateRotationAngles(16, 60);
  expect(ret).assertEqual(30 + 300 / 330);
}

let SatelliteUtilsTest_getSateRotationAngles_03 = () => {
  let ret = SatelliteUtils.getSateRotationAngles(-16, 60);
  expect(ret).assertEqual(-30 + -300 / 330);
}

let SatelliteUtilsTest_getPitchTranslationY_01 = () => {
  let ret = SatelliteUtils.getPitchTranslationY(1);
  expect(ret).assertEqual(2);
}

let SatelliteUtilsTest_getPitchTranslationY_02 = () => {
  let ret = SatelliteUtils.getPitchTranslationY(16);
  expect(ret).assertEqual(30 + 164 / 200);
}

let SatelliteUtilsTest_getPitchTranslationY_03 = () => {
  let ret = SatelliteUtils.getPitchTranslationY(-16);
  expect(ret).assertEqual(-30 + -164 / 200);
}

let SatelliteUtilsTest_getFloatPitchTranslationY_01 = () => {
  let ret = SatelliteUtils.getFloatPitchTranslationY(1);
  expect(ret).assertEqual(38 / 30);
}

let SatelliteUtilsTest_getFloatPitchTranslationY_02 = () => {
  let ret = SatelliteUtils.getFloatPitchTranslationY(16);
  expect(ret).assertEqual(19 + 104 / 200);
}

let SatelliteUtilsTest_getFloatPitchTranslationY_03 = () => {
  let ret = SatelliteUtils.getFloatPitchTranslationY(-16);
  expect(ret).assertEqual(-19 + -104 / 200);
}

let SatelliteUtilsTest_convertDigitalToLongitude = () => {
  let ret = SatelliteUtils.convertDigitalToLongitude(1);
  expect(ret.length > 0).assertTrue();
}

let SatelliteUtilsTest_updateSuccessDelta = () => {
  SatelliteUtils.successPitchDelta = 1;
  SatelliteUtils.successAzimuthDelta = 0;
  SatelliteUtils.updateSuccessDelta(2, 2);
  SatelliteUtils.updateSuccessDelta(2, 2);
  SatelliteUtils.updateSuccessDelta(3, 5);
  SatelliteUtils.isSupportSkycomSatellite();
  let mocker: MockKit = new MockKit();
  let sate = SatelliteSearchManager.getInstance();
  let mockFunc = mocker.mockFunc(sate, sate.getIsFromMeetime);
  when(mockFunc)(ArgumentMatchers.any).afterReturn(false);
  SatelliteUtils.getSuccessAzimuth();
  SatelliteUtils.getSuccessPitch();
  mocker.ignoreMock(SatelliteSearchManager.getInstance(), SatelliteSearchManager.getInstance().getIsFromMeetime);
}

let SatelliteUtilsTest_convertDigitalToLatitude = () => {
  let ret = SatelliteUtils.convertDigitalToLatitude(1);
  expect(ret.length > 0).assertTrue();
}

export default function SatelliteUtilsTest() {
  describe('SatelliteUtilsTest', () => {
    it('SatelliteUtilsTest_checkAzimuthOk', 0, () => {
      SatelliteUtilsTest_checkAzimuthOk();
    });
    it('SatelliteUtilsTest_checkPitchOk', 0, () => {
      SatelliteUtilsTest_checkPitchOk();
    });
    it('SatelliteUtilsTest_getSateRotationAngles_01', 0, () => {
      SatelliteUtilsTest_getSateRotationAngles_01();
    });
    it('SatelliteUtilsTest_getSateRotationAngles_02', 0, () => {
      SatelliteUtilsTest_getSateRotationAngles_02();
    });
    it('SatelliteUtilsTest_getSateRotationAngles_03', 0, () => {
      SatelliteUtilsTest_getSateRotationAngles_03();
    });
    it('SatelliteUtilsTest_getPitchTranslationY_01', 0, () => {
      SatelliteUtilsTest_getPitchTranslationY_01();
    });
    it('SatelliteUtilsTest_getPitchTranslationY_02', 0, () => {
      SatelliteUtilsTest_getPitchTranslationY_02();
    });
    it('SatelliteUtilsTest_getPitchTranslationY_03', 0, () => {
      SatelliteUtilsTest_getPitchTranslationY_03();
    });
    it('SatelliteUtilsTest_getFloatPitchTranslationY_01', 0, () => {
      SatelliteUtilsTest_getFloatPitchTranslationY_01();
    });
    it('SatelliteUtilsTest_getFloatPitchTranslationY_02', 0, () => {
      SatelliteUtilsTest_getFloatPitchTranslationY_02();
    });
    it('SatelliteUtilsTest_getFloatPitchTranslationY_03', 0, () => {
      SatelliteUtilsTest_getFloatPitchTranslationY_03();
    });
    it('SatelliteUtilsTest_convertDigitalToLongitude', 0, () => {
      SatelliteUtilsTest_convertDigitalToLongitude();
    });
    it('SatelliteUtilsTest_convertDigitalToLatitude', 0, () => {
      SatelliteUtilsTest_convertDigitalToLatitude();
    });
    it('SatelliteUtilsTest_updateSuccessDelta', 0, () => {
      SatelliteUtilsTest_updateSuccessDelta();
    });
    it('SatelliteUtilsTest_getDefaultAngles', 0, (done: Function) => {
      let sate = SatelliteSearchManager.getInstance();
      let mocker: MockKit = new MockKit();
      let mockFunc = mocker.mockFunc(sate, sate.getIsFromMeetime);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(true);
      SatelliteUtils.getDefaultAngles();

      when(mockFunc)(ArgumentMatchers.any).afterReturn(false);
      SatelliteUtils.successAzimuthDelta = 15;
      SatelliteUtils.getDefaultAngles();

      SatelliteUtils.successAzimuthDelta = 20;
      SatelliteUtils.getDefaultAngles();

      SatelliteUtils.successAzimuthDelta = 0;
      SatelliteUtils.getDefaultAngles();
      mocker.ignoreMock(sate, sate.getIsFromMeetime);
      done();
    });
    it('SatelliteUtilsTest_getSkycomSatelliteState', 0, (done: Function) => {
      let context = CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(CALL_SETTING_ABILITY_CONTEXT);
      try {
        SatelliteUtils.getSkycomSatelliteState();
        AppStorage.setOrCreate<common.UIAbilityContext>('pageContext', context)
        SatelliteUtils.getSkycomSatelliteState();
        AppStorage.delete('pageContext');
        SatelliteUtils.getSkycomSatelliteState();
        SatelliteUtils.getBeidouSatelliteState();
        SatelliteUtils.isSupportBeidouSatellite();
      } catch (error) {
      }
      done();
    })
  });
}
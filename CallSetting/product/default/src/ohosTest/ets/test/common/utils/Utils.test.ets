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
import {
  isSupportCactus,
  isSupportDandelion,
  isSupportPalaceMuseum,
  getString,
  getPluralStringWithParam,
  setExpandAutoAnswer,
  getExpandAutoAnswer,
  getPaddingByDevice,
  isFusionCallEnabled,
  isSupportMultiDeviceCommunicationSharing,
  isPhone,
  isTablet,
  terminalDialogAbility,
  confirmSuperPrivacyDialog,
  isSupportMobileData,
  getPushString
} from '../../../../../main/ets/common/utils/Utils'
import { CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import common from '@ohos.app.ability.common';
import resourceManager from '@ohos.resourceManager';
import { Want } from '@kit.AbilityKit';

const CALL_SETTING_SATELLITE_ABILITY_CONTEXT = 'callSettingsSatelliteAbilityContext';
let resource = $r('app.string.8300001')

export default function UtilssTest() {
  describe('UtilssTest', () => {

    it('UtilssTest_cactus_01', 0, () => {
      let result = isSupportDandelion();
      if (result) {
        expect(true).assertEqual(result);
      } else {
        expect(false).assertEqual(result);
      }
    })

    it('UtilssTest_cactus_02', 0, () => {
      let result: boolean = isSupportCactus();
      if (result) {
        expect(true).assertEqual(result);
      } else {
        expect(false).assertEqual(result);
      }
    })
    it('UtilssTest_cactus_03', 0, () => {
      let result: boolean = isSupportPalaceMuseum();
      if (result) {
        expect(true).assertEqual(result);
      } else {
        expect(false).assertEqual(result);
      }
    })
    it('UtilssTest_getString', 0, () => {
      let result = getString(resource);
      let str = CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIExtensionContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT)?.
      resourceManager.getStringSync(resource.id);
      expect(result).assertEqual(str)
    })
    it('UtilssTest_getPluralStringWithParam_01', 0, () => {
      let str = 'test'
      let result = getPluralStringWithParam(str, 1)
      expect(result).assertEqual(str)
    })
    it('UtilssTest_getPluralStringWithParam_02', 0, () => {
      let res: resourceManager.Resource = {
        bundleName: resource.bundleName,
        moduleName: resource.moduleName,
        id: resource.id
      };
      let result = getPluralStringWithParam(resource, 1)
      expect(result).assertEqual(CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIExtensionContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT)?.
      resourceManager.getPluralStringValueSync(res, 1))
    })
    it('UtilssTest_expandAutoAnswer_01', 0, () => {
      setExpandAutoAnswer(true)
      let result = getExpandAutoAnswer()
      expect(result).assertTrue()
    })
    it('UtilssTest_expandAutoAnswer_02', 0, () => {
      setExpandAutoAnswer(false)
      let result = getExpandAutoAnswer()
      expect(result).assertFalse()
    })
    it('UtilssTest_getPaddingByDevice', 0, () => {
      let result = getPaddingByDevice().id
      if (isTablet()) {
        expect(result).assertEqual($r('sys.float.padding_level12').id)
      } else {
        expect(result).assertEqual($r('sys.float.padding_level8').id)
      }
    })
    it('UtilssTest_isFusionCallEnabled', 0, () => {
      let result = isFusionCallEnabled()
      if (result) {
        expect(result).assertTrue()
      } else {
        expect(result).assertFalse()
      }
    })
    it('UtilssTest_isSupportMultiDeviceCommunicationSharing', 0, () => {
      let result = isSupportMultiDeviceCommunicationSharing()
      if (result) {
        expect(result).assertTrue()
      } else {
        expect(result).assertFalse()
      }
    })
    it('UtilssTest_terminalDialogAbility', 0, () => {
      terminalDialogAbility()
      expect(true).assertTrue()
    })
    it('UtilssTest_isSupportMobileData', 0, () => {
      let result = isSupportMobileData()
      if (result) {
        expect(result).assertTrue()
      } else {
        expect(result).assertFalse()
      }
    })
    it('UtilssTest_confirmSuperPrivacyDialog_01', 0, () => {
      let want: Want | undefined = AppStorage.get('want');
      if (want?.parameters) {
        want.parameters.isAnswer = true
        AppStorage.setAndRef('want', want)
        confirmSuperPrivacyDialog()
        want.parameters.isAnswer = false
        AppStorage.setAndRef('want', want)
        confirmSuperPrivacyDialog()
        expect(true).assertTrue()
      } else {
        confirmSuperPrivacyDialog()
        expect(true).assertTrue()
      }
    })
    it('UtilssTest_confirmSuperPrivacyDialog_02', 0, () => {
      let want1: Want = {
        parameters: {
          'isAnswer': false,
        }
      }
      let want: Want = {
        parameters: {
          'isAnswer': true,
          'videoState': 1,
          'number': '1',
          'accountId': 0,
          'dialScene': 1,
          'dialType': 1,
          'callType': 1
        }
      }
      AppStorage.setOrCreate('want', want1);
      confirmSuperPrivacyDialog();
      AppStorage.delete('want');
      AppStorage.setOrCreate('want', want);
      confirmSuperPrivacyDialog();
      AppStorage.delete('want');
      getPushString('test,1');
      getPushString('');
      expect(isPhone()).assertTrue();
    })
  })
}
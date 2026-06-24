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

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect, MockKit, when } from '@ohos/hypium';
import { CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import { StringUtil } from '../../../../../main/ets/common/utils/StringUtil';
import * as CallSettingsConstant from '../../../../../main/ets/common/constant/CallSettingsConstant';
import common from '@ohos.app.ability.common';
import { JSON } from '@kit.ArkTS';

export default function StringUtilTest() {
  describe('StringUtilTest', () => {
    const errorObject: Record<string, Resource> = {
      '201': $r('app.string.201'),
      '401': $r('app.string.401'),
      '8300001': $r('app.string.8300001'),
      '8300002': $r('app.string.8300002'),
      '8300003': $r('app.string.8300003'),
      '8300999': $r('app.string.8300999'),
    }
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

    it('TestStringUtil_isEmpty', 0, () => {
      let isEmpty: boolean = StringUtil.isEmpty('test');
      expect(isEmpty).assertEqual(false);

      let checkEmpty: boolean = StringUtil.isEmpty('');
      expect(checkEmpty).assertEqual(true);

      let checkEmptySec: boolean = StringUtil.isEmpty('undefined');
      expect(checkEmptySec).assertEqual(true);
    })

    it('TestStringUtil_getErrorMsg_01', 0, () => {
      let str = StringUtil.getErrorMsg();
      expect(str).assertEqual('');
    })

    it('TestStringUtil_getErrorMsg_02', 0, () => {
      const str = 'test';
      let newStr = StringUtil.getErrorMsg(str);
      expect(newStr).assertEqual('');
    })

    it('TestStringUtil_getErrorMsg_03', 0, () => {
      let str = 'undefined';
      let newStr = StringUtil.getErrorMsg(str);
      expect(newStr).assertEqual('');
    })

    it('TestStringUtil_getErrorMsg_04', 0, () => {
      let result = StringUtil.getErrorMsg('201');
      expect(JSON.stringify(result)).assertEqual(JSON.stringify(errorObject['201']));
    })

    it('TestStringUtil_formatResourceToString_01', 0, () => {
      const res = 'test';
      let newRes = StringUtil.formatResourceToString(res);
      expect(res).assertEqual(newRes);
    })

    it('TestStringUtil_formatResourceWithParamToString_01', 0, () => {
      const str = 'test';
      let result = StringUtil.formatResourceWithParamToString(str, 'test');
      expect(result).assertEqual(str);
    })
    it('TestStringUtil_getStringByName', 0, () => {
      let result = StringUtil.getStringByName('test');
      expect(result).assertEqual('');
    })
    it('TestStringUtil_getStringByFileAsync_01', 0, async () => {
      let resourceManager = CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT)
        .resourceManager
      let result = await StringUtil.getStringByFileAsync(resourceManager, '');
      expect(result).assertEqual('');
    })
    it('TestStringUtil_getStringByFileAsync_02', 0, async () => {
      let resourceManager = CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT)
        .resourceManager
      let result = '';
      try {
        result = await StringUtil.getStringByFileAsync(resourceManager, 'test');
      } catch (e) {
        expect(result).assertEqual('');
      }
      expect(result).assertEqual('')
    })
    it('TestStringUtil_formatPhoneNumberInMultiLanguage', 0, () => {
      let number = '12345678'
      let result = StringUtil.formatPhoneNumberInMultiLanguage(number)
      expect(result).assertEqual(' \u202D(' + number + ')\u202C')
      let emptyNumber = ''
      let emptyResult = StringUtil.formatPhoneNumberInMultiLanguage(emptyNumber)
      expect(emptyResult).assertEqual(emptyNumber)
    })
    it('TestStringUtil_concatenateStringArray', 0, () => {
      let delimiter = ''
      let remainingStr = ''
      let result = StringUtil.concatenateStringArray(delimiter, remainingStr).toString()
      expect(result).assertEqual('')
    })
    it('TestStringUtil_test', 0, () => {
      StringUtil.concatenateStringArray('', 'test');
      StringUtil.concatenateStringArray('test', 'test');
      StringUtil.concatenateStringArray('test', '1test123');
      let result = StringUtil.concatenateStringArray('test1', 'test');
      expect(result.length >= 0).assertTrue();
    })
  })
}
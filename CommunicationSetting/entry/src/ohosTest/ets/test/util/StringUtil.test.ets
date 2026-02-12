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
import { describe, expect, it } from '@ohos/hypium';
import StringUtil from '../../../../main/ets/util/StringUtil';
import myCommon from '@ohos.app.ability.common';
import { DTGlobalContext } from '../../testability/TestAbility';

export default function StringUtilTest() {
  describe('StringUtilTest', () => {
    it('StringUtilBasicTest', 0, () => {
      let a = '';
      expect(StringUtil.isEmpty(a)).assertTrue();
      expect(StringUtil.isEmpty('111')).assertFalse();
      expect(StringUtil.convertResourceToString(undefined,
        DTGlobalContext.getContext().getObject('TestContext') as myCommon.UIAbilityContext)).assertEqual('');
      expect(StringUtil.convertResourceToStringWithArgs(undefined,
        DTGlobalContext.getContext().getObject('TestContext') as myCommon.UIAbilityContext)).assertEqual('');
      expect(StringUtil.convertResourceToString($r('app.string.TestAbility_label'),
        DTGlobalContext.getContext().getObject('111') as myCommon.UIAbilityContext)).assertEqual('');
      expect(StringUtil.convertResourceToStringWithArgs($r('app.string.TestAbility_label'),
        DTGlobalContext.getContext().getObject('111') as myCommon.UIAbilityContext)).assertEqual('');
      expect(StringUtil.convertResourceToStringWithArgs($r('app.string.TestAbility_label'),
        DTGlobalContext.getContext().getObject('111') as myCommon.UIAbilityContext)).assertEqual('');
    })

    it('StringUtilTest_convertResourceToString', 0, () => {
      let context = DTGlobalContext.getContext().getObject('TestContext') as myCommon.UIAbilityContext;
      let string = context.resourceManager.getStringSync($r('app.string.today').id);
      expect(StringUtil.convertResourceToString($r('app.string.today'), context)).assertEqual(string);
      expect(StringUtil.convertResourceToStringWithArgs($r('app.string.today'), context)).assertEqual(string);
    })

    it('StringUtilTest_isIncluded01', 0, () => {
      let str1 = 'hello communicationsetting';
      let str2 = 'hello';
      expect(StringUtil.isIncluded(str1, str2)).assertTrue();
    })

    it('StringUtilTest_isIncluded02', 0, () => {
      let str1 = 'hello communicationsetting';
      let str2 = 'hello world';
      expect(StringUtil.isIncluded(str1, str2)).assertFalse();
    })

  })
}
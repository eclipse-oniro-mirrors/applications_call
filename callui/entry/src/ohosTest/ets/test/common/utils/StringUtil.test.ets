/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { GlobalContextHelper } from '../../../../../main/ets/common/utils/GlobalContextHelper';
import { StringUtil } from '../../../../../main/ets/common/utils/StringUtil';
import * as Constants from '../../../../../main/ets/common/utils/Constants';
import common from '@ohos.app.ability.common';

export default function StringUtilTest() {
  describe('StringUtilTest', () => {
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

    it('isEmptyTest', 0, () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      let a = 'undefined';
      let b = StringUtil.isEmpty(a);
      // Defines a variety of assertion methods, which are used to declare expected boolean conditions.
      expect(b).assertTrue();
    })

    it('formatResourceToStringTest', 0, () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      let textContext = AppStorage.get<common.UIAbilityContext>('testAbility');
      if (!textContext) {
        return;
      }
      GlobalContextHelper.getContext().set(Constants.CALL_ABILITY_CONTEXT, textContext);
      let a = '1';
      let b = '卡 1';
      let c = StringUtil.getStringByNameSync('sim_card_num_no_space', a);
      let d = '卡 %s';
      let e = StringUtil.getStringByNameSync('sim_card_num_no_space');
      // Defines a variety of assertion methods, which are used to declare expected boolean conditions.
      expect(b).assertEqual(c);
      expect(d).assertEqual(e);
    })

    it('should_return_empty_string_when_array_is_empty', 0, () => {
      let result = StringUtil.arrayToString([]);
      expect(result).assertEqual('');
    });

    it('should_return_joined_string_when_array_has_elements', 0, () => {
      let result = StringUtil.arrayToString(['a', 'b', 'c']);
      expect(result).assertEqual('a,b,c');
    });

    it('should_return_empty_array_when_input_string_is_empty', 0, () => {
      let input: string = '';
      let result: string[] = StringUtil.stringToArray(input);
      expect(result).assertDeepEquals(['']);
    });

    it('should_return_array_with_one_element_when_input_string_has_one_element', 0, () => {
      let input: string = 'one';
      let result: string[] = StringUtil.stringToArray(input);
      expect(result).assertDeepEquals(['one']);
    });

    it('should_return_array_with_multiple_elements_when_input_string_has_multiple_elements', 0, () => {
      let input: string = 'one,two,three';
      let result: string[] = StringUtil.stringToArray(input);
      expect(result).assertDeepEquals(['one', 'two', 'three']);
    });

    it('should_return_array_with_trailing_empty_elements_when_input_string_has_trailing_commas', 0, () => {
      let input: string = 'one,two,three,';
      let result: string[] = StringUtil.stringToArray(input);
      expect(result).assertDeepEquals(['one', 'two', 'three', '']);
    });

    it('should_return_array_with_leading_empty_elements_when_input_string_has_leading_commas', 0, () => {
      let input: string = ',one,two,three';
      let result: string[] = StringUtil.stringToArray(input);
      expect(result).assertDeepEquals(['', 'one', 'two', 'three']);
    });

    it('should_return_array_with_empty_elements_when_input_string_has_empty_elements', 0, () => {
      let input: string = 'one,,three';
      let result: string[] = StringUtil.stringToArray(input);
      expect(result).assertDeepEquals(['one', '', 'three']);
    });

    it('should_return_array_with_trimmed_elements_when_input_string_has_trimmed_elements', 0, () => {
      let input: string = 'one,two,three';
      let result: string[] = StringUtil.stringToArray(input);
      expect(result).assertDeepEquals(['one', 'two', 'three']);
    });

    it('should_return_array_with_elements_in_same_order_as_input_when_input_string_has_elements_in_same_order', 0,
      () => {
        let input: string = 'one,two,three';
        let result: string[] = StringUtil.stringToArray(input);
        expect(result).assertDeepEquals(['one', 'two', 'three']);
      });

    it('should_return_array_with_elements_in_reverse_order_when_input_string_has_elements_in_reverse_order', 0, () => {
      let input: string = 'three,two,one';
      let result: string[] = StringUtil.stringToArray(input);
      expect(result).assertDeepEquals(['three', 'two', 'one']);
    });

    it('should_return_array_with_elements_in_random_order_when_input_string_has_elements_in_random_order', 0, () => {
      let input: string = 'two,one,three';
      let result: string[] = StringUtil.stringToArray(input);
      expect(result).assertDeepEquals(['two', 'one', 'three']);
    });
  })
}

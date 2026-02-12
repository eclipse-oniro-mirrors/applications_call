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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect, MockKit, when,
  ArgumentMatchers } from '@ohos/hypium'
import { Constant } from '../../../../../main/ets/common/constant/Constant';
import CallRecorderColumnUtils from '../../../../../main/ets/common/utils/CallRecorderColumnUtils';
import { GlobalContextHelper } from '../../../../../main/ets/common/utils/GlobalContextHelper';
import { common } from '@kit.AbilityKit';
import { display } from '@kit.ArkUI';
import json from '@ohos.util.json';
import { JSON } from '@kit.ArkTS';
import mLogUtil from '../../../../../main/ets/common/utils/LogUtils';

export default function CallRecorderColumnUtilsTest() {
  let call_recorder_column_utils_test_updateCurbp_01Func = async (testContext: Context) => {
    let callRecorderColumnUtils = new CallRecorderColumnUtils();
    callRecorderColumnUtils.updateCurbp(120, 'xs');
    let result: string | undefined = AppStorage.get("curBp")
    expect(result).assertEqual("xs")
  };
  let call_recorder_column_utils_test_updateCurbp_02Func = async (testContext: Context) => {
    let callRecorderColumnUtils = new CallRecorderColumnUtils();
    callRecorderColumnUtils.updateCurbp(500, 'sm');
    let result: string | undefined = AppStorage.get("curBp")
    expect(result).assertEqual("sm")
  };
  let call_recorder_column_utils_test_updateCurbp_03Func = async (testContext: Context) => {
    let callRecorderColumnUtils = new CallRecorderColumnUtils();
    callRecorderColumnUtils.updateCurbp(700, 'md');
    let result: string | undefined = AppStorage.get("curBp")
    expect(result).assertEqual("md")
  };
  let call_recorder_column_utils_test_updateCurbp_04Func = async (testContext: Context) => {
    let callRecorderColumnUtils = new CallRecorderColumnUtils();
    callRecorderColumnUtils.updateCurbp(900, 'lg');
    let result: string | undefined = AppStorage.get("curBp")
    expect(result).assertEqual("lg")
  };

  let call_recorder_column_utils_test_updateCurbp_05Func = async (testContext: Context) => {
    let callRecorderColumnUtils = new CallRecorderColumnUtils();
    callRecorderColumnUtils.updateCurbp(900, 'sm');
    let result: string | undefined = AppStorage.get("curBp")
    expect(result).assertEqual("lg")
  };

  let call_recorder_column_utils_test_updateBreakpoint_01 = async (testContext: Context) => {
    let callRecorderColumnUtils = new CallRecorderColumnUtils();
    let displaySync: number = display.getDefaultDisplaySync().densityPixels
    callRecorderColumnUtils.updateBreakpoint(120 * displaySync);
    let result: string | undefined = AppStorage.get("curBp")
    expect(result).assertEqual("xs")
  };

  let call_recorder_column_utils_test_getPaddingSpace_01Func = async (testContext: Context) => {
    let callRecorderColumnUtils = new CallRecorderColumnUtils();
    let result = callRecorderColumnUtils.getPaddingSpace('xs');
    expect(JSON.stringify(result)).assertEqual(JSON.stringify($r('sys.float.padding_level8')))
  };

  let call_recorder_column_utils_test_getPaddingSpace_02Func = async (testContext: Context) => {
    let callRecorderColumnUtils = new CallRecorderColumnUtils();
    let result = callRecorderColumnUtils.getPaddingSpace('md');
    expect(JSON.stringify(result)).assertEqual(JSON.stringify($r('sys.float.padding_level12')))
  };

  let call_recorder_column_utils_test_getPaddingSpace_03Func = async (testContext: Context) => {
    let callRecorderColumnUtils = new CallRecorderColumnUtils();
    let result = callRecorderColumnUtils.getPaddingSpace('lg');
    expect(JSON.stringify(result)).assertEqual(JSON.stringify($r('sys.float.padding_level16')))
  };

  let call_recorder_column_utils_test_getInstance_01Func = async (testContext: Context) => {
    let result = CallRecorderColumnUtils.getInstance();
    expect(result === null).assertFalse()
  };

  describe('CallRecorderColumnUtilsTest', () => {
    let testContext: Context = GlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    it('call_recorder_column_utils_test_getInstance_01', 0, () => {
      call_recorder_column_utils_test_getInstance_01Func(testContext);
    })
    it('call_recorder_column_utils_test_updateCurbp_01', 0, () => {
      call_recorder_column_utils_test_updateCurbp_01Func(testContext);
    })
    it('call_recorder_column_utils_test_updateCurbp_02', 0, () => {
      call_recorder_column_utils_test_updateCurbp_02Func(testContext);
    })
    it('call_recorder_column_utils_test_updateCurbp_03', 0, () => {
      call_recorder_column_utils_test_updateCurbp_03Func(testContext);
    })
    it('call_recorder_column_utils_test_updateCurbp_04', 0, () => {
      call_recorder_column_utils_test_updateCurbp_04Func(testContext);
    })
    it('call_recorder_column_utils_test_updateCurbp_05', 0, () => {
      call_recorder_column_utils_test_updateCurbp_05Func(testContext);
    })
    it('call_recorder_column_utils_test_updateBreakpoint_01', 0, () => {
      call_recorder_column_utils_test_updateBreakpoint_01(testContext);
    })
    it('call_recorder_column_utils_test_getPaddingSpace_01', 0, () => {
      call_recorder_column_utils_test_getPaddingSpace_01Func(testContext);
    })
    it('call_recorder_column_utils_test_getPaddingSpace_02', 0, () => {
      call_recorder_column_utils_test_getPaddingSpace_02Func(testContext);
    })
    it('call_recorder_column_utils_test_getPaddingSpace_03', 0, () => {
      call_recorder_column_utils_test_getPaddingSpace_03Func(testContext);
    })
  })
}
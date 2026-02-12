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

import { describe, it, expect, MockKit, when } from '@ohos/hypium';
import { DisplayUtil } from '../../../../../main/ets/common/utils/DisplayUtil';
import ScreenAdapterUtils, { FoldPhoneTypeValue } from '../../../../../main/ets/common/utils/ScreenAdapterUtils';
import { display } from '@kit.ArkUI';

export default function ScreenAdapterUtilsTest() {
  describe('ScreenAdapterUtilsTest', () => {
    it('getFoldablePhoneProductType_test', 0, async () => {
      let type = ScreenAdapterUtils.getFoldablePhoneProductType();
      expect(type > -2).assertTrue();
    });
    it('getParticleLayoutBottomBtnWidth_test', 0, async () => {
      let result = ScreenAdapterUtils.getInstance().getParticleLayoutBottomBtnWidth(false);
      expect(result !== null).assertTrue();

      result = ScreenAdapterUtils.getInstance().getParticleLayoutBottomBtnWidth(true);
      expect(result !== null).assertTrue();
    });
    it('getParticleLayoutBottomBtnSymbolWidth_test', 0, async () => {
      let result = ScreenAdapterUtils.getInstance().getParticleLayoutBottomBtnSymbolWidth(false);
      expect(result !== null).assertTrue();

      result = ScreenAdapterUtils.getInstance().getParticleLayoutBottomBtnSymbolWidth(true);
      expect(result !== null).assertTrue();
    });
    it('getFuncBtnWidth_test', 0, async () => {
      let result = ScreenAdapterUtils.getInstance().getFuncBtnWidth(false);
      expect(result !== null).assertTrue();
      result = ScreenAdapterUtils.getInstance().getFuncBtnWidth(true);
      expect(result !== null).assertTrue();
    });
    it('should_return_true_when_getFoldablePhoneProductType_returns_EXPANDING_NEW_FORM', 0, async (done: Function) => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(ScreenAdapterUtils, ScreenAdapterUtils.getFoldablePhoneProductType);
      when(mockFunc)().afterReturn(FoldPhoneTypeValue.EXPANDING_NEW_FORM);
      const result: boolean = ScreenAdapterUtils.isNewFormFoldPhone();
      expect(result).assertTrue();
      mocker.verify('getFoldablePhoneProductType', []).atLeast(1);
      mocker.ignoreMock(ScreenAdapterUtils, ScreenAdapterUtils.getFoldablePhoneProductType);
      done();
    });
    it('should_return_false_when_getFoldablePhoneProductType_returns_a_value_other_than_EXPANDING_NEW_FORM', 0,
      async (done: Function) => {
        let mocker: MockKit = new MockKit();
        let mockFunc: Function = mocker.mockFunc(ScreenAdapterUtils, ScreenAdapterUtils.getFoldablePhoneProductType);
        when(mockFunc)().afterReturn(FoldPhoneTypeValue.STRAIGHT);
        const result: boolean = ScreenAdapterUtils.isNewFormFoldPhone();
        expect(result).assertFalse();
        mocker.verify('getFoldablePhoneProductType', []).atLeast(1);
        mocker.ignoreMock(ScreenAdapterUtils, ScreenAdapterUtils.getFoldablePhoneProductType);
        done();
      });
    it('should_return_true_when_isNewFormFoldPhone_is_true_and_getScreenFoldStatus_is_FOLD_STATUS_FOLDED', 0,
      async (done: Function) => {
        let mocker: MockKit = new MockKit();
        let screenAdapterUtils: ScreenAdapterUtils = ScreenAdapterUtils.getInstance();
        let mockIsNewFormFoldPhone: Function =
          mocker.mockFunc(ScreenAdapterUtils, ScreenAdapterUtils.isNewFormFoldPhone);
        let mockGetScreenFoldStatus: Function = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
        when(mockIsNewFormFoldPhone)().afterReturn(true);
        when(mockGetScreenFoldStatus)().afterReturn(display.FoldStatus.FOLD_STATUS_FOLDED);
        const result: boolean = screenAdapterUtils.isNewFoldPhoneExternalScreen();
        expect(result).assertTrue();
        mocker.verify('isNewFormFoldPhone', []).atLeast(1);
        mocker.verify('getScreenFoldStatus', []).atLeast(0);
        mocker.ignoreMock(ScreenAdapterUtils, ScreenAdapterUtils.isNewFormFoldPhone);
        mocker.ignoreMock(DisplayUtil, DisplayUtil.getScreenFoldStatus);
        done();
      });
    it('should_return_false_when_isNewFormFoldPhone_is_false_and_getScreenFoldStatus_is_FOLD_STATUS_FOLDED', 0,
      async (done: Function) => {
        let mocker: MockKit = new MockKit();
        let screenAdapterUtils: ScreenAdapterUtils = ScreenAdapterUtils.getInstance();
        let mockIsNewFormFoldPhone: Function =
          mocker.mockFunc(ScreenAdapterUtils, ScreenAdapterUtils.isNewFormFoldPhone);
        let mockGetScreenFoldStatus: Function = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
        when(mockIsNewFormFoldPhone)().afterReturn(false);
        when(mockGetScreenFoldStatus)().afterReturn(display.FoldStatus.FOLD_STATUS_FOLDED);
        const result: boolean = screenAdapterUtils.isNewFoldPhoneExternalScreen();
        expect(result).assertFalse();
        mocker.verify('isNewFormFoldPhone', []).atLeast(1);
        mocker.verify('getScreenFoldStatus', []).atLeast(0);
        mocker.ignoreMock(ScreenAdapterUtils, ScreenAdapterUtils.isNewFormFoldPhone);
        mocker.ignoreMock(DisplayUtil, DisplayUtil.getScreenFoldStatus);
        done();
      });
    it('should_return_false_when_isNewFormFoldPhone_is_true_and_getScreenFoldStatus_is_not_FOLD_STATUS_FOLDED', 0,
      async (done: Function) => {
        let mocker: MockKit = new MockKit();
        let screenAdapterUtils: ScreenAdapterUtils = ScreenAdapterUtils.getInstance();
        let mockIsNewFormFoldPhone: Function =
          mocker.mockFunc(ScreenAdapterUtils, ScreenAdapterUtils.isNewFormFoldPhone);
        let mockGetScreenFoldStatus: Function = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
        when(mockIsNewFormFoldPhone)().afterReturn(true);
        when(mockGetScreenFoldStatus)().afterReturn(display.FoldStatus.FOLD_STATUS_EXPANDED);
        const result: boolean = screenAdapterUtils.isNewFoldPhoneExternalScreen();
        expect(result).assertFalse();
        mocker.verify('isNewFormFoldPhone', []).atLeast(1);
        mocker.verify('getScreenFoldStatus', []).atLeast(0);
        mocker.ignoreMock(ScreenAdapterUtils, ScreenAdapterUtils.isNewFormFoldPhone);
        mocker.ignoreMock(DisplayUtil, DisplayUtil.getScreenFoldStatus);
        done();
      });
    it('should_return_false_when_isNewFormFoldPhone_is_false_and_getScreenFoldStatus_is_not_FOLD_STATUS_FOLDED', 0,
      async (done: Function) => {
        let mocker: MockKit = new MockKit();
        let screenAdapterUtils: ScreenAdapterUtils = ScreenAdapterUtils.getInstance();
        let mockIsNewFormFoldPhone: Function =
          mocker.mockFunc(ScreenAdapterUtils, ScreenAdapterUtils.isNewFormFoldPhone);
        let mockGetScreenFoldStatus: Function = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
        when(mockIsNewFormFoldPhone)().afterReturn(false);
        when(mockGetScreenFoldStatus)().afterReturn(display.FoldStatus.FOLD_STATUS_EXPANDED);
        const result: boolean = screenAdapterUtils.isNewFoldPhoneExternalScreen();
        expect(result).assertFalse();
        mocker.verify('isNewFormFoldPhone', []).atLeast(1);
        mocker.verify('getScreenFoldStatus', []).atLeast(0);
        mocker.ignoreMock(ScreenAdapterUtils, ScreenAdapterUtils.isNewFormFoldPhone);
        mocker.ignoreMock(DisplayUtil, DisplayUtil.getScreenFoldStatus);
        done();
      });
    it('should_return_0_when_productType_is_negative_1_or_0', 0, async (done: Function) => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(ScreenAdapterUtils, ScreenAdapterUtils.getFoldablePhoneProductType);
      when(mockFunc)().afterReturn(-1);
      let result: number = ScreenAdapterUtils.getInstance().getScreenForm();
      expect(result).assertEqual(0);
      mocker.verify('getFoldablePhoneProductType', []).atLeast(1);
      mocker.ignoreMock(ScreenAdapterUtils, ScreenAdapterUtils.getFoldablePhoneProductType);
      done();
    });
    it('should_return_correct_screenForm_when_productType_is_between_1_and_4', 0, async (done: Function) => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(ScreenAdapterUtils, ScreenAdapterUtils.getFoldablePhoneProductType);
      when(mockFunc)().afterReturn(2);
      let mockDisplayFunc: Function = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
      when(mockDisplayFunc)().afterReturn(2);
      let result: number = ScreenAdapterUtils.getInstance().getScreenForm();
      expect(result).assertEqual(22);
      mocker.ignoreMock(ScreenAdapterUtils, ScreenAdapterUtils.getFoldablePhoneProductType);
      mocker.ignoreMock(DisplayUtil, DisplayUtil.getScreenFoldStatus);
      done();
    });
    it('should_return_0_when_productType_is_greater_than_4', 0, async (done: Function) => {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(ScreenAdapterUtils, ScreenAdapterUtils.getFoldablePhoneProductType);
      when(mockFunc)().afterReturn(5);
      let result: number = ScreenAdapterUtils.getInstance().getScreenForm();
      expect(result).assertEqual(0);
      mocker.ignoreMock(ScreenAdapterUtils, ScreenAdapterUtils.getFoldablePhoneProductType);
      done();
    });
  });
}
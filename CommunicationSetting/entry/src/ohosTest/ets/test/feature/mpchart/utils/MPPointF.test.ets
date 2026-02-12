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
import { describe, beforeAll, it, expect } from '@ohos/hypium'
import myCommon from '@ohos.app.ability.common';
import { DTGlobalContext } from '../../../../testability/TestAbility';
import MPPointF from '../../../../../../main/ets/feature/mpchart/utils/MPPointF';

export default function MPPointFTest() {
  describe('MPPointFTest', () => {
    let context: myCommon.UIAbilityContext;
    let bundleName = 'com.ohos.communicationsetting';
    let uid: number;

    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
      context = DTGlobalContext.getContext().getObject('TestContext') as myCommon.UIAbilityContext;
      uid = context.applicationInfo.uid;
    })
    it('instantiateTest01', 0, () => {
      let mPPointF1: MPPointF = new MPPointF(0, 1);
      expect(mPPointF1.x).assertEqual(0);
      expect(mPPointF1.y).assertEqual(1);
      let mPPointF2 = mPPointF1.instantiate() as MPPointF;
      expect(mPPointF2.x).assertEqual(0);
      expect(mPPointF2.y).assertEqual(0);
    })
    it('instantiateTest02', 0, () => {
      let mPPointF1: MPPointF = new MPPointF(0, 0);
      expect(mPPointF1.x).assertEqual(0);
      expect(mPPointF1.y).assertEqual(0);
      let mPPointF2 = mPPointF1.instantiate() as MPPointF;
      expect(mPPointF2.x).assertEqual(0);
      expect(mPPointF2.y).assertEqual(0);
    })
    it('instantiateTest03', 0, () => {
      let mPPointF1: MPPointF = new MPPointF(1, 1);
      expect(mPPointF1.x).assertEqual(1);
      expect(mPPointF1.y).assertEqual(1);
      let mPPointF2 = mPPointF1.instantiate() as MPPointF;
      expect(mPPointF2.x).assertEqual(0);
      expect(mPPointF2.y).assertEqual(0);
    })
    it('getInstance01', 0, () => {
      let mPPointF1: MPPointF = new MPPointF(1, 2);
      expect(mPPointF1.x).assertEqual(1);
      expect(mPPointF1.y).assertEqual(2);
      let mPPointF2: MPPointF = MPPointF.getInstance(undefined, undefined, mPPointF1);
      expect(mPPointF2.x).assertEqual(1);
      expect(mPPointF2.y).assertEqual(2);
    })
    it('getInstance02', 0, () => {
      let mPPointF: MPPointF = MPPointF.getInstance(1, 1, undefined);
      expect(mPPointF.x).assertEqual(1);
      expect(mPPointF.y).assertEqual(1);
    })
    it('getInstance03', 0, () => {
      let mPPointF: MPPointF = MPPointF.getInstance(undefined, undefined, undefined);
      expect(mPPointF.x).assertEqual(0);
      expect(mPPointF.y).assertEqual(0);
    })
  })
}
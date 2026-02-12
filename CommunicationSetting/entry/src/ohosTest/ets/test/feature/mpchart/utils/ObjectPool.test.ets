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
import { ObjectPool } from '../../../../../../main/ets/feature/mpchart/utils/ObjectPool';
import { Poolable } from '../../../../../../main/ets/feature/mpchart/utils/Poolable';
import MoveViewJob from '../../../../../../main/ets/feature/mpchart/jobs/MoveViewJob';
import { BarChartModel, Transformer, ViewPortHandler } from '../../../../../../main/ets/feature/mpchart';


export default function ObjectPollTest() {
  describe('ObjectPollTest', () => {
    let context: myCommon.UIAbilityContext;
    let bundleName = 'com.ohos.communicationsetting';
    let uid: number;

    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
      context = DTGlobalContext.getContext().getObject('TestContext') as myCommon.UIAbilityContext;
      uid = context.applicationInfo.uid;
    })
    it('constructorTest01', 0, () => {
      let errorParamater: boolean = false;
      try {
        let objPool: ObjectPool<MPPointF> = new ObjectPool(-1, new MPPointF(0, 0));
      } catch (e) {
        expect((e as Error).message).assertEqual('Object Pool must be instantiated with a capacity greater than 0!');
        errorParamater = true;
      }
      expect(errorParamater).assertTrue();
    })
    it('constructorTest02', 0, () => {
      let errorParamater: boolean = false;
      try {
        let objPool: ObjectPool<MPPointF> = new ObjectPool(1, new MPPointF(0, 0));
      } catch (e) {
        expect((e as Error).message).assertEqual('Object Pool must be instantiated with a capacity greater than 0!');
        errorParamater = true;
      }
      expect(errorParamater).assertFalse();
    })
    it('constructorTest03', 0, () => {
      let errorParamater: boolean = false;
      try {
        let objPool: ObjectPool<MPPointF> = new ObjectPool(1, new MPPointF(0, 0));
      } catch (e) {
        expect((e as Error).message).assertEqual('Object Pool must be instantiated with a capacity greater than 0!');
        errorParamater = true;
      }
      expect(errorParamater).assertFalse();
    })
    it('constructorTest04', 0, () => {
      let errorParamater: boolean = false;
      try {
        let objPool: ObjectPool<MPPointF> = new ObjectPool(1, new MPPointF(0, 0));
        objPool.setReplenishPercentage(-1);
      } catch (e) {
        expect((e as Error).message).assertEqual('Object Pool must be instantiated with a capacity greater than 0!');
        errorParamater = true;
      }
      expect(errorParamater).assertFalse();
    })
    it('constructorTest05', 0, () => {
      let errorParamater: boolean = false;
      try {
        let objPool: ObjectPool<MPPointF> = new ObjectPool(1, new MPPointF(0, 0));
        objPool.setReplenishPercentage(3);
        errorParamater = true;
      } catch (e) {
        expect((e as Error).message).assertEqual('Object Pool must be instantiated with a capacity greater than 0!');
      }
      expect(errorParamater).assertTrue();
    })
    it('constructorTest06', 0, () => {
      let errorParamater: boolean = false;
      try {
        let objPool: ObjectPool<MPPointF> = new ObjectPool(1, new MPPointF(0, 0));
        objPool.get();
        errorParamater = true;
        expect(objPool.objectsPointer).assertEqual(-1);
      } catch (e) {
        expect((e as Error).message).assertEqual('Object Pool must be instantiated with a capacity greater than 0!');
      }
      expect(errorParamater).assertTrue();
    })
    it('constructorTest7', 0, () => {
      let errorParamater: boolean = false;
      try {
        let viewPortHandler: ViewPortHandler = new ViewPortHandler();
        let transformer: Transformer = new Transformer(viewPortHandler);
        let barChartMode = new BarChartModel();
        let moveViewJob: MoveViewJob = MoveViewJob.getInstance(viewPortHandler, 0, 0, transformer, barChartMode)
        moveViewJob.run();
        let objPool: ObjectPool<MoveViewJob> = new ObjectPool(-1, moveViewJob);
      } catch (e) {
        expect((e as Error).message).assertEqual('Object Pool must be instantiated with a capacity greater than 0!');
        errorParamater = true;
      }
      expect(errorParamater).assertTrue();
    })
    it('constructorTest8', 0, () => {
      let errorParamater: boolean = false;
      try {
        let viewPortHandler: ViewPortHandler = new ViewPortHandler();
        let transformer: Transformer = new Transformer(viewPortHandler);
        let barChartMode = new BarChartModel();
        let moveViewJob: MoveViewJob = MoveViewJob.getInstance(viewPortHandler, 0, 0, transformer, barChartMode)
        MoveViewJob.recycleInstance(moveViewJob);
        moveViewJob.run();
        let objPool: ObjectPool<MoveViewJob> = new ObjectPool(-1, moveViewJob);
      } catch (e) {
        expect((e as Error).message).assertEqual('The object passed is already stored in this pool!');
        errorParamater = true;
      }
      expect(errorParamater).assertTrue();
    })
    it('recycleTest01', 0, () => {
      let errorParamater: boolean = false;
      try {
        let mPPointF: MPPointF = new MPPointF(0, 0);
        mPPointF.currentOwnerId = 0;
        let objPool: ObjectPool<MPPointF> = new ObjectPool(1, mPPointF);
        objPool.recycle(mPPointF);
      } catch (e) {
        errorParamater = true;
        expect((e as Error).message).assertEqual('The object passed is already stored in this pool!');
      }
      expect(errorParamater).assertTrue();
    })
    it('recycleTest02', 0, () => {
      let errorParamater: boolean = false;
      try {
        let mPPointF: MPPointF = new MPPointF(0, 0);
        mPPointF.currentOwnerId = 1;
        let objPool: ObjectPool<MPPointF> = new ObjectPool(1, mPPointF);
        objPool.recycle(mPPointF);
      } catch (e) {
        errorParamater = true;
        expect((e as Error).message)
          .assertEqual(`The object to recycle already belongs to poolId 1.` +
            '  Object cannot belong to two different pool instances simultaneously!');
      }
      expect(errorParamater).assertTrue();
    })
    it('recycleTest03', 0, () => {
      let errorParamater: boolean = false;
      try {
        let mPPointF: MPPointF = new MPPointF(0, 0);
        MPPointF.recycleInstance(mPPointF);
        mPPointF.currentOwnerId = Poolable.NO_OWNER
        let objPool: ObjectPool<MPPointF> = new ObjectPool(1, mPPointF);
        objPool.recycle(mPPointF);
        expect(objPool.objectsPointer).assertEqual(1);
        errorParamater = true;
      } catch (e) {
        expect((e as Error).message)
          .assertEqual(`The object to recycle already belongs to poolId 1.` +
            '  Object cannot belong to two different pool instances simultaneously!');
      }
      expect(errorParamater).assertTrue();
    })
    it('recycleTest04', 0, () => {
      let errorParamater: boolean = false;
      try {
        let mPPointF: MPPointF = new MPPointF(0, 0);
        MPPointF.recycleInstance(mPPointF);
        mPPointF.currentOwnerId = Poolable.NO_OWNER
        let objPool: ObjectPool<MPPointF> = new ObjectPool(1, mPPointF);
        objPool.recycle(mPPointF);
        mPPointF.currentOwnerId = Poolable.NO_OWNER
        objPool.recycle(mPPointF);
        expect(objPool.objectsPointer).assertEqual(2);
        errorParamater = true;
      } catch (e) {
        expect((e as Error).message)
          .assertEqual(`The object to recycle already belongs to poolId 1.` +
            '  Object cannot belong to two different pool instances simultaneously!');
      }
      expect(errorParamater).assertTrue();
    })
    it('recycleTest05', 0, () => {
      let errorParamater: boolean = false;
      try {
        let mPPointF: MPPointF = new MPPointF(0, 0);
        mPPointF.currentOwnerId = 0;
        let objPool: ObjectPool<MPPointF> = new ObjectPool(1, mPPointF);
        objPool.objects = null;
        objPool.get();
        objPool.recycle(mPPointF);
      } catch (e) {
        errorParamater = true;
        expect((e as Error).message).assertEqual('Obj is not a Valid object');
      }
      expect(errorParamater).assertTrue();
    })

  })
}
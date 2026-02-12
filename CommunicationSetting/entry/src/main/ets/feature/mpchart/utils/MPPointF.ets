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
import { ObjectPool } from './ObjectPool';
import { Poolable } from './Poolable';

export default class MPPointF extends Poolable {
  private static pool: ObjectPool<MPPointF> = ObjectPool.create(32, new MPPointF(0, 0))
    .setReplenishPercentage(0.5) as ObjectPool<MPPointF>;
  public x: number = 0;
  public y: number = 0;

  public constructor(x?: number, y?: number) {
    super()
    this.x = x ? x : 0;
    this.y = y ? y : 0;
  }

  public static getInstance(x ?: number, y ?: number, copy ?: MPPointF): MPPointF {
    if (copy != null) {
      let result: MPPointF = MPPointF.pool.get();
      result.x = copy.x;
      result.y = copy.y;
      return result;
    }
    if (x != null && y != null) {
      let result: MPPointF = MPPointF.pool.get();
      result.x = x;
      result.y = y;
      return result;
    }
    return MPPointF.pool.get();
  }

  public static recycleInstance(instance: MPPointF) {
    MPPointF.pool.recycle(instance);
  }

  instantiate(): Poolable {
    return new MPPointF(0, 0);
  }
}
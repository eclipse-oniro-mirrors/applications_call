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

import { Poolable } from '../utils/Poolable';
import { ObjectPool } from '../utils/ObjectPool';
import Transformer from '../utils/Transformer';
import ViewPortHandler from '../utils/ViewPortHandler';
import Chart from '../charts/ChartModel';
import ChartData from '../data/ChartData';
import IDataSet from '../interfaces/datasets/IDataSet';

export default class MoveViewJob extends Poolable{
  private static pool: ObjectPool<MoveViewJob> = ObjectPool.create(2, new MoveViewJob(null, 0, 0, null, null))
    .setReplenishPercentage(0.5) as ObjectPool<MoveViewJob>;
  private pts: number[] = new Array<number>(2);
  private viewPortHandler: ViewPortHandler | null = null;
  private xValue: number = 0;
  private yValue: number = 0;
  private trans: Transformer | null = null;
  private view: Chart<ChartData<IDataSet>> | null = null;

  public static getInstance(viewPortHandler: ViewPortHandler, xValue: number, yValue: number, trans: Transformer,
    v: Chart<ChartData<IDataSet>>): MoveViewJob {
    let result: MoveViewJob = MoveViewJob.pool.get();
    result.viewPortHandler = viewPortHandler;
    result.xValue = xValue;
    result.yValue = yValue;
    result.trans = trans;
    result.view = v;
    return result;
  }

  public static recycleInstance(instance: MoveViewJob): void {
    instance.viewPortHandler = null;
    instance.view = null;
    instance.trans = null;
    MoveViewJob.pool.recycle(instance);
  }

  constructor(viewPortHandler: ViewPortHandler | null, xValue: number, yValue: number, trans: Transformer | null,
    v: Chart<ChartData<IDataSet>> | null) {
    super();
    this.viewPortHandler = viewPortHandler;
    this.xValue = xValue;
    this.yValue = yValue;
    this.trans = trans;
    this.view = v;
  }

  public run(): void {
    this.pts[0] = this.xValue;
    this.pts[1] = this.yValue;
    if (this.trans) {
      this.trans.pointValuesToPixel(this.pts);
    }
    if (this.viewPortHandler && this.view) {
      this.viewPortHandler.centerViewPort(this.pts, this.view);
    }
    MoveViewJob.recycleInstance(this);
  }

  public instantiate(): Poolable {
    return new MoveViewJob(this.viewPortHandler, this.xValue, this.yValue, this.trans, this.view);
  }
}

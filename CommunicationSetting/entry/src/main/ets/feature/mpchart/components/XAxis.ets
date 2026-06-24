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

import Utils from '../utils/Utils';
import AxisBase from './AxisBase';

export class XAxis extends AxisBase {
  public labelRotatedHeight: number = 1;
  public xOffset: number = 4;
  private position: XAxisPosition = XAxisPosition.TOP;

  constructor() {
    super();
    this.yOffset = Utils.handleDataValues(this.xOffset);
  }

  public getPosition(): XAxisPosition {
    return this.position;
  }

  public setPosition(pos: XAxisPosition): void {
    this.position = pos;
  }
}

export enum XAxisPosition {
  TOP, BOTTOM, BOTH_SIDED, TOP_INSIDE, BOTTOM_INSIDE
}

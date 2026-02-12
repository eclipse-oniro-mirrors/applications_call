/**
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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

import { FontScaleState } from '../../common/utils/FontScaleState';

class FontScaleManager {
  private fontScaleState = new FontScaleState();

  constructor(scale: number) {
    this.fontScaleState.fontSizeScale = scale;
  }

  /**
   * 获取系统原始字体放大倍数
   */
  public getSysFontScaleState(): FontScaleState {
    return this.fontScaleState;
  }

  /**
   * 设置系统原始字体放大倍数
   *
   * @param scale 字体系数
   */
  public setSysFontScale(scale: number): void {
    this.fontScaleState.fontSizeScale = scale;
  }
}

export const fontScaleManager = new FontScaleManager(1);
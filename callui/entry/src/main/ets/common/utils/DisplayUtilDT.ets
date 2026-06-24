/**
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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

/**
 * @file: SDK里的方法无法直接mock，需要用class包一层，为了DisplayUtil的DT覆盖率在这里新建一个类。
 */

import display from '@ohos.display';

export class DisplayUtilDT {

  static getFoldStatus() {
    return display.getFoldStatus();
  }

  static isFoldable() {
    return display.isFoldable();
  }
}
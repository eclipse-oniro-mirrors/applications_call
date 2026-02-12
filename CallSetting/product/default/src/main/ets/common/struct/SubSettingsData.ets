/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

export default class SubSettingsData {
  public displayName: Resource;
  public isEnable?: boolean;
  public showDivider?: boolean;
  public description?: Resource;
  public isLineBreak?: boolean;
  public itemKey?: string;

  constructor(displayName: Resource, isEnable?: boolean, showDivider?: boolean, description?: Resource,
    isLineBreak?: boolean, itemKey?: string) {
    this.displayName = displayName;
    this.isEnable = isEnable;
    this.showDivider = showDivider;
    this.description = description;
    this.isLineBreak = isLineBreak;
    this.itemKey = itemKey;
  }
}

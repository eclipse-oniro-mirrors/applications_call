/**
 * Copyright (c) 2024-2024 Huawei Device Co., Ltd.
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
export class HiCarManager {
  private static instance?: HiCarManager;
  private isHiCarPageShow: boolean = false;

  private constructor() {
  }

  public static getInstance(): HiCarManager {
    if (!HiCarManager.instance) {
      HiCarManager.instance = new HiCarManager();
    }
    return HiCarManager.instance;
  }

  public static release(): void {
    HiCarManager.instance = undefined;
  }

  public setIsHiCarPageShow(isHiCarPageShow: boolean): void {
    this.isHiCarPageShow = isHiCarPageShow;
  }

  public getIsHiCarPageShow(): boolean {
    return this.isHiCarPageShow;
  }
}
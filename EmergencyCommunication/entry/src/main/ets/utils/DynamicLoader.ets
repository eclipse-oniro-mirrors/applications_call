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
import LogUtils from './HiLog';

const TAG = 'DynamicLoader';

export class DynamicLoader {
  private static instance: DynamicLoader;
  public dynamicLoaderCB: ((key: string) => Promise<void>) | null = null;

  register(loaderCallback: (key: string) => Promise<void>): void {
    this.dynamicLoaderCB = loaderCallback;
  }

  async callFunction(key: string): Promise<void> {
    if (this.dynamicLoaderCB === null) {
      LogUtils.e(TAG, 'callFunction is unRegister');
      return;
    }
    let value = await this.dynamicLoaderCB(key);
    return value;
  }

  public static getInstance(): DynamicLoader {
    if (!DynamicLoader.instance) {
      DynamicLoader.instance = new DynamicLoader();
    }
    return DynamicLoader.instance;
  }
}
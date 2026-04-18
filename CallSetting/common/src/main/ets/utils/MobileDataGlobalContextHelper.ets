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

import { LogUtils } from './LogUtils';

const TAG = 'MobileDataGlobalContextHelper'
export class MobileDataGlobalContextHelper {
  private constructor() {}
  private static instance: MobileDataGlobalContextHelper;
  private objects = new Map<string, Object>();
  private static registerKeys = [
    'settingsAbilityContext',
  ];

  public static getContext(): MobileDataGlobalContextHelper {
    if (!MobileDataGlobalContextHelper.instance) {
      MobileDataGlobalContextHelper.instance = new MobileDataGlobalContextHelper();
    }
    return MobileDataGlobalContextHelper.instance;
  }

  getValue<T>(value: string): T {
    return this.objects.get(value) as T;
  }

  set<T extends Object>(key: string, value: T): void {
    const element = MobileDataGlobalContextHelper.registerKeys.find((ele: string) => ele === key);
    if (element === undefined) {
      LogUtils.i(TAG, 'GlobalContextHelper can not find register key:' + JSON.stringify(key));
      return;
    }
    this.objects.set(key, value);
  }
}
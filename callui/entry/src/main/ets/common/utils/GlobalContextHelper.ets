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

import LogUtils from './LogUtils';
import * as Constants from '../utils/Constants';

const TAG = 'GlobalContextHelper';

export class GlobalContextHelper {
  private constructor() {
  }

  private static instance: GlobalContextHelper;
  private objects = new Map<string, Object>();
  private static registerKeys = [
    Constants.CALL_ABILITY_CONTEXT,
    Constants.HICAR_CALL_ABILITY_CONTEXT,
    Constants.EXTERNAL_CALL_ABILITY_CONTEXT,
    Constants.CALL_SERVICE_CONTEXT,
    Constants.ABILITY_WANT,
    Constants.VOIP_ABILITY_CONTEXT,
    Constants.VOIP_ABILITY_WANT,
    Constants.WINDOW,
    Constants.HICAR_WINDOW,
    Constants.CALL_SETTING_ABILITY_CONTEXT,
    Constants.CALL_SETTING_PAGE_WINDOW
  ];

  public static getContext(): GlobalContextHelper {
    if (!GlobalContextHelper.instance) {
      GlobalContextHelper.instance = new GlobalContextHelper();
    }
    return GlobalContextHelper.instance;
  }

  getValue<T>(value: string): T {
    return this.objects.get(value) as T;
  }

  set<T extends Object>(key: string, value: T): void {
    const element = GlobalContextHelper.registerKeys.find((ele: string) => ele === key);
    if (element === undefined) {
      LogUtils.i(TAG, 'GlobalContextHelper can not find register key:' + JSON.stringify(key));
      return;
    }
    this.objects.set(key, value);
  }

  remove(key: string) {
    this.objects.delete(key);
  }

  clear() {
    this.objects.clear();
  }
}
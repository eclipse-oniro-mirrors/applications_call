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
import { isObjectType, MyAny } from '../data/LooseObject';
import LogUtils from './HiLog';

const TAG: string = 'StringUtil';

export class StringUtil {
  public static isEmpty(str: string | undefined | null): boolean {
    return str === undefined || str === null || str.toString().trim() === '';
  }
}

export const isJSONString = (str: string) => {
  if (!str) {
    return false;
  }
  if (typeof str === 'string') {
    try {
      JSON.parse(str);
      return true;
    } catch (e) {
      LogUtils.i(TAG, `isJSONString error: ${e?.code} ${e?.message}`);
      return false;
    }
  }
  return false;
}

export const isObjectJSONString = (str: string) => {
  if (!str) {
    return false;
  }
  if (typeof str === 'string') {
    try {
      let temp = JSON.parse(str) as MyAny;
      if (!temp || !isObjectType(temp)) {
        return false;
      }
      return true;
    } catch (e) {
      LogUtils.i(TAG, `isObjectJSONString error ${e?.code} ${e?.message}`);
      return false;
    }
  }
  return false;
}　
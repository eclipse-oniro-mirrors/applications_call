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

import common from '@ohos.app.ability.common';
import { LogUtils, CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import * as CallSettingsConstant from '../constant/CallSettingsConstant';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { resourceManager } from '@kit.LocalizationKit';

const TAG = 'StringUtil';
const UNICODE: string = 'utf-8';

const errorObject: Record<string, Resource> = {
  '201': $r('app.string.201'),
  '401': $r('app.string.401'),
  '8300001': $r('app.string.8300001'),
  '8300002': $r('app.string.8300002'),
  '8300003': $r('app.string.8300003'),
  '8300999': $r('app.string.8300999'),
}

export class StringUtil {

  static isEmpty(str: string): boolean {
    let regex: RegExp = new RegExp('[^\s]');
    return str == 'undefined' || !str || !regex.test(str);
  }

  static getErrorMsg(errorCode?: string): ResourceStr {
    if (!errorCode) {
      return '';
    }
    if (StringUtil.isEmpty(errorCode)) {
      return '';
    }
    if (errorObject[errorCode]) {
      return errorObject[errorCode];
    }
    return '';
  }

  /**
   * get string from resource
   *
   * @param {Resource} resource - resource
   * @param {string} accountNumber - the phone number send to
   * @param {ResourceStr} contentResource - content of message
   *
   * @return { string } - return resource string
   */
  static formatResourceToString(resource: ResourceStr) {
    if (typeof resource === 'string') {
      return resource;
    }
    return CallSettingGlobalContextHelper.getContext().
    getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT)?.
    resourceManager.getStringSync(resource.id);
  }

  static formatResourceWithParamToString(resource: ResourceStr, param: string | number) {
    if (typeof resource === 'string') {
      return resource;
    }
    return CallSettingGlobalContextHelper.getContext().
    getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT)?.
    resourceManager.getStringSync(resource.id, param);
  }

  /**
   * get string from resource name
   *
   * @param stringName
   * @returns { string } - return resource string
   */
  static getStringByName(stringName: string) {
    try {
      let resourceManager = (AppStorage.get<Context>('pageContext') as Context)?.resourceManager;
      let LINK_STRING_FLAG: string = '$string:';
      let name = stringName.replace(LINK_STRING_FLAG, '');
      return resourceManager.getStringByNameSync(name);
    } catch (error) {
      return '';
    }
  }

  /**
   * 获取指定JSON文件的对象
   * @param context 上下文
   */
  public static getStringByFileAsync(resourceManager: resourceManager.ResourceManager,
    fileName: string): Promise<string> {
    return new Promise((resolve, reject) => {
      LogUtils.i(TAG, 'getStringByFileAsync');
      if (!resourceManager || !fileName) {
        LogUtils.e(TAG, `getFileContent failed. resourceManager or fileName is null.`);
        reject();
        return;
      }
      try {
        resourceManager.getRawFileContent(fileName).then((value) => {
          let content = util.TextDecoder.create(UNICODE).decodeWithStream(value);
          resolve(content);
        }).catch((err: BusinessError) => {
          LogUtils.e(TAG, `getFileContent failed.`);
          reject(err);
        });
      } catch (jsonError) {
        LogUtils.e(TAG, `JSON parse error:${jsonError?.code}`);
        reject();
      }
    });
  }

  static formatPhoneNumberInMultiLanguage(phoneNum: string): string {
    return StringUtil.isEmpty(phoneNum) ? phoneNum : ' \u202D(' + phoneNum + ')\u202C';
  }

  /**
   * concatenate string array
   *
   * @param delimiter delimiter
   * @param remainingStr remaining string
   * @returns resource string
   */
  static concatenateStringArray(delimiter: string, remainingStr: string): Array<string> {
    if (!delimiter || !remainingStr) {
      LogUtils.e(TAG, 'concatenateStringArray param is invalid.');
      return [];
    }
    const result: string[] = [];
    const index = remainingStr.indexOf(delimiter);
    if (index !== -1) {
      const beforeDelimiter = remainingStr.substr(0, index);
      const afterDelimiter = remainingStr.substr(index + delimiter.length);
      if (beforeDelimiter !== '') {
        result.push(beforeDelimiter);
      }
      result.push(delimiter);
      remainingStr = afterDelimiter;
    }
    if (remainingStr !== '') {
      result.push(remainingStr);
    }
    return result;
  }

  // 从字符串转换回队列
  static stringToArray(str: string): string[] {
    let array: string[] = [];
    str.split(',').forEach(item => {
      array.push(item);
    });
    return array;
  }

  // 转换成字符串
  static arrayToString(array: string[]): string {
    return array.join(',');
  }
}
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
import LogUtils from './LogUtils';
import Utils from './utils';
import I18n from '@ohos.i18n';
import Intl from '@ohos.intl';

const TAG = 'StringUtil';

export class StringUtil {

  static isEmpty(str: string): boolean {
    let regex: RegExp = new RegExp('[^\s]');
    return str == 'undefined' || !str || !regex.test(str);
  }

  /**
   * get string from resource
   *
   * @param {Resource} resource - resource
   * @param {string} param - use string to format resource
   *
   * @return {string} - return resource string
   */
  static formatResourceToString(resource: Resource, param?: string) {
    let gbContext = Utils.getInstance().getContext();
    try {
      if (param !== undefined) {
        return gbContext?.resourceManager.getStringSync(resource.id, param);
      }
      return gbContext?.resourceManager.getStringSync(resource.id);
    } catch (err) {
      LogUtils.e(TAG, `formatResourceToString err. Code is ${err.code}, message is ${err.message}`);
      return '';
    }
  }

  /**
   * 只在ContactCard中调用，避免formatResourceToString方法概率执行catch的问题
   * @param resource
   * @param param
   * @returns
   */
  static formatResourceToStringForContactCard(resource: Resource, param?: string) {
    let gbContext = Utils.getInstance().getContext();
    try {
      if (param !== undefined) {
        return gbContext?.resourceManager.getStringSync(resource.id, param);
      }
      return gbContext?.resourceManager.getStringSync(resource.id);
    } catch (err) {
      LogUtils.e(TAG, `formatResourceToString err. Code is ${err.code}, message is ${err.message}`);
      return '';
    }
  }

  static formatPluralResourceToString(resource: Resource, param: number) {
    try {
      let gbContext = Utils.getInstance().getContext();
      return gbContext?.resourceManager.getPluralStringValueSync(resource.id, param);
    } catch (err) {
      LogUtils.e(TAG, `formatPluralResourceToString err. Code is ${err.code}, message is ${err.message}`);
      return '';
    }
  }

  static getStringByNameSync(stringName: string, param?: string) {
    try {
      let gbContext = Utils.getInstance().getContext();
      if (param !== undefined) {
        return gbContext?.resourceManager.getStringByNameSync(stringName, param);
      }
      return gbContext?.resourceManager.getStringByNameSync(stringName);
    } catch (error) {
      LogUtils.e(TAG, `getStringByNameSync ${stringName} fial: ${JSON.stringify(error)}`);
      return '';
    }
  }

  static simIdFormat(formatNumber: number) {
    let systemLanguage = I18n.System.getAppPreferredLanguage();
    LogUtils.i(TAG, 'systemLanguage:' + systemLanguage);
    let options: Intl.NumberOptions = { locale: 'Locale' };
    let numberFormat: Intl.NumberFormat = new Intl.NumberFormat(systemLanguage, options);
    return numberFormat.format(formatNumber);
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

  static maskSensitiveInfo(str: string): string {
    try {
      if (StringUtil.isEmpty(str)) {
        return '';
      }
      // 只有一个字符，大概率是姓名只有一个字，此时不打印
      if (str.length <= 1) {
        return `*:${str.length}`;
      }
      // 只有2个字符时，打印首字母跟长度2，与下面统一
      if (str.length <= 2) {
        return `${str.substring(0, 1)}:${str.length}`;
      }
      // 大概率是姓名、公司，打印首尾字符
      if (str.length <= 6) {
        return `${str.substring(0, 1)}:${str.substring(str.length - 1, str.length)}:${str.length}`;
      }
      // 针对长姓名等情况，打印前两位，后两位
      if (str.length <= 9) {
        return `${str.substring(0, 2)}:${str.substring(str.length - 2, str.length)}:${str.length}`;
      }
      // 号码或者座机，打印前三位，后四位
      if (str.length <= 11) {
        return `${str.substring(0, 3)}:${str.substring(str.length - 4, str.length)}:${str.length}`;
      }
      // 对于带有+86这样的手机，打印前六位
      if (str.length <= 14) {
        return `${str.substring(0, 6)}:${str.substring(str.length - 4, str.length)}:${str.length}`;
      }
      return `${str.substring(0, 3)}:${str.substring(str.length - 4, str.length)}:${str.length}`;
    } catch (e) {
      LogUtils.e('StringUtil', `maskSensitiveInfo error: ${e?.message}`);
      return '***';
    }
  }
}

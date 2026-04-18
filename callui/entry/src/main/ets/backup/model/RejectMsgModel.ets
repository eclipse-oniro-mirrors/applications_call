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

import common from '@ohos.app.ability.common';
import LogUtils from '../../common/utils/LogUtils';
import fs, { Filter } from '@ohos.file.fs';
import convertXml from '@ohos.convertxml';
import { BusinessError } from '@ohos.base';
import data_preferences from '@ohos.data.preferences';

const TAG = 'RejectMsgModel';
export const REJECT_MESSAGE_PREFERENCES_NAME = 'reject_message_preference_name';
export const REJECT_MESSAGE_PREFERENCES_NAME_COPY = 'reject_message_preference_name_copy';
export const REJECT_MESSAGE_KEY_END = 'reject_message_key';
const SMS_LENGTH = 4;

class TestLocale {
  public language: string = '';
  public region: string = '';
  public script: string = '';
  public id: string = '';
}

class ListFileOption {
  public filter: Filter = {};
}

interface AttributesObject {
  name: string,
  value: string
}

interface CovertObject {
  _name: string,
  _text: string,
  _type: string,
  _attributes: AttributesObject,
  _declaration: Object,
  _elements: CovertObject[]
}

export default class RejectMsgModel {
  private convertOptions: convertXml.ConvertOptions = {
    trim: false,
    declarationKey: '_declaration',
    instructionKey: '_instruction',
    attributesKey: '_attributes',
    textKey: '_text',
    cdataKey: '_cdata',
    doctypeKey: '_doctype',
    commentKey: '_comment',
    parentKey: '_parent',
    typeKey: '_type',
    nameKey: '_name',
    elementsKey: '_elements'
  };

  public async migratePrefFile(context: common.ExtensionContext) {
    LogUtils.i(TAG, 'start migratePrefFile');

    if (context == null || context == undefined) {
      LogUtils.i(TAG, 'current context is null or undefined');
      return;
    }
    let prefsDir = context.preferencesDir;
    let listFileNames: string[] = [];
    try {
      const isPathExists = fs.accessSync(prefsDir);
      if (isPathExists) {
        let option = new ListFileOption();
        option.filter.suffix = ['.xml'];
        option.filter.displayName = ['respond_via_sms_prefs\*'];
        listFileNames = fs.listFileSync(prefsDir, option);
        LogUtils.i(TAG, 'listFileNames ' + listFileNames.length);
      }
      for (let i = 0; i < listFileNames.length; i++) {
        let locale = this.getLocaleFromList(listFileNames[i]);
        let value = this.getValueStringForXML(context, listFileNames[i]);
        LogUtils.i(TAG, `locale:${locale}` + `;value:${value?.length}`);
        await this.updateRejectMsg(context, locale, value);
      }
    } catch (err) {
      LogUtils.e(TAG, `migratePrefFile err:${JSON.stringify(err)}`);
    }
  }

  private getValueStringForXML(context: common.ExtensionContext, listname: string): string[] {
    LogUtils.i(TAG, 'getValueStringForXML');
    let rejectMmsFilePath = context.preferencesDir + '/' + listname;
    let rejectValue: string [] = [];
    rejectValue.length = SMS_LENGTH;
    const isRejectMmsPathExists = fs.accessSync(rejectMmsFilePath);
    if (!isRejectMmsPathExists) {
      LogUtils.i(TAG, 'the file dose not exist.');
      return rejectValue;
    }
    try {
      let rejectMmsContent: string = fs.readTextSync(rejectMmsFilePath);
      let convertXmlObj = new convertXml.ConvertXML();
      let resObj: CovertObject =
        convertXmlObj.convertToJSObject(rejectMmsContent, this.convertOptions) as CovertObject;
      let elementList = this.findElementsByTag(resObj._elements, 'map');
      for (let i = 0; i < elementList.length; i++) {
        let item = elementList[i];
        if (!item || !item._name || !item._attributes) {
          continue;
        }
        let isString: boolean = item._name === 'string';
        let attributeName: string = item._attributes.name;
        let attributeValue: string = item._attributes.value;
        LogUtils.i(TAG, 'attributeName:' + attributeName + ',attributeValue:' + attributeValue);
        if (isString && attributeName.startsWith('canned_response_pref')) {
          let key = attributeName.slice(-1);
          let str = item._elements[0]._text;
          let number = Number(key);
          rejectValue[number - 1] = str;
        }
      }
    } catch (err) {
      LogUtils.e(TAG, `convert mmsPreferences xml failed, error: ${err}`);
    }
    try {
      fs.unlinkSync(rejectMmsFilePath);
    } catch (err) {
      LogUtils.e(TAG, `remove xml failed, error: ${err}`);
    }
    return rejectValue;
  }

  private findElementsByTag(elements: CovertObject[], findTag: String): CovertObject[] {
    let obj: CovertObject[] = [];
    if (!elements) {
      LogUtils.i(TAG, 'elements is empty, return emptyList');
      return obj;
    }
    for (let i = 0; i < elements.length; i++) {
      if (elements[i]._name === findTag) {
        return elements[i]._elements;
      }
    }
    LogUtils.i(TAG, 'Can not find elements, return emptyList');
    return obj;
  }

  private getLocaleFromList(listname: string): string {
    LogUtils.i(TAG, 'getLocaleFromList');
    let fileName: string = listname?.split('.xml')[0];
    let fileNameArr: string[] = fileName?.split('respond_via_sms_prefs');
    if (fileNameArr?.length !== 2) {
      return '';
    }
    let localeStr: string = fileNameArr[1];
    localeStr = localeStr?.replace(new RegExp('_#', 'g'), '#');
    LogUtils.i(TAG, 'localeStr = ' + localeStr);
    let lanArr = this.splitStr(localeStr, '_');
    if (!lanArr) {
      return '';
    }
    let locale: TestLocale = new TestLocale();
    locale.language = lanArr[0];
    let regionArr: string[] = lanArr[1]?.split('#', 3);
    if (!regionArr) {
      return '';
    }
    if (regionArr[0]?.search('_') !== -1) {
      locale.region = regionArr[0].substring(0, regionArr[0]?.search('_'));
    } else {
      locale.region = regionArr[0] ? regionArr[0] : '';
    }
    if (regionArr[1]?.length === 4 && regionArr[1].match('[A-Z]{1}[a-z]{3}')?.length === 1) {
      locale.script = regionArr[1];
    }
    locale.id = regionArr[2] ? regionArr[2] : '';

    let lanValue = this.getName(locale);
    return lanValue;
  }

  private getName(locale: TestLocale): string {
    LogUtils.i(TAG, 'getName');
    let newLocale: string = '';
    if (!this.isEmpty(locale.language)) {
      newLocale += locale.language;
    }
    if (!this.isEmpty(locale.script)) {
      newLocale += '-' + locale.script;
    }
    if (!this.isEmpty(locale.region)) {
      newLocale += '-' + locale.region;
    }
    if (!this.isEmpty(locale.id)) {
      newLocale += '-' + locale.id;
    }
    LogUtils.i(TAG, 'newLocale = ' + newLocale);
    return newLocale;
  }

  private splitStr(str: string, flag: string): Array<string> | undefined {
    if (this.isEmpty(str) || this.isEmpty(flag)) {
      return undefined;
    }
    let result: string[] = new Array<string>(2);
    let index: number = str.search(flag);
    if (index === -1) {
      return undefined;
    }
    result[0] = str.substring(0, index);
    result[1] = str.substring(index + 1);
    return result;
  }

  private isEmpty(str: string): boolean {
    let regex: RegExp = new RegExp('[^\s]');
    return str === 'undefined' || !str || !regex.test(str);
  }

  private async updateRejectMsg(context: common.ExtensionContext, locale: string, value: string[]): Promise<void> {
    LogUtils.i(TAG, 'start updateRejectMsg');
    let key = locale + REJECT_MESSAGE_KEY_END;
    try {
      let rejectMsgPreferences = await data_preferences.getPreferences(context, REJECT_MESSAGE_PREFERENCES_NAME);
      rejectMsgPreferences.putSync(key, JSON.stringify(value));
      rejectMsgPreferences.flush();
    } catch (err) {
      LogUtils.e(TAG, 'Failed to put value of ' + key + '. code =' + (err as BusinessError).code +
        ', message =' + (err as BusinessError).message);
    }
  }
}

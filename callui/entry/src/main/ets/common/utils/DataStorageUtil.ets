/*
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

import data_preferences from '@ohos.data.preferences';
import LogUtils from './LogUtils';
import { DEFAULT_REJECT_MESSAGE } from '../constant/CallSettingConst';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';

const TAG = 'dataStorageUtil';
const REJECT_MESSAGE_PREFERENCES_NAME = 'reject_message_preference_name';
const REJECT_MESSAGE_KEY_END = 'reject_message_key';
const REJECT_MSG_NUMBER: number = 4;

let rejectMsgPreferences: data_preferences.Preferences;

function formatResourceToString(context: common.UIAbilityContext, resource: Resource) {
  let str: string = '';
  if (context) {
    try {
      str = context.resourceManager.getStringSync(resource.id);
    } catch (error) {
      LogUtils.e(TAG, `formatResourceToString error: ${JSON.stringify(error)}`);
    }
  }
  return str;
}

function initDefaultMessage(context: common.UIAbilityContext) {
  let defaultRejectMsgList: string[] = [];
  for (let i = 0; i < REJECT_MSG_NUMBER; i++) {
    let textValue: string = formatResourceToString(context, DEFAULT_REJECT_MESSAGE[i].textValue);
    defaultRejectMsgList.push(textValue);
  }
  return defaultRejectMsgList;
}

async function getRejectMsgPreferences(context: common.ExtensionContext | common.UIAbilityContext): Promise<void> {
  try {
    rejectMsgPreferences = await data_preferences.getPreferences(context, REJECT_MESSAGE_PREFERENCES_NAME);
    LogUtils.i(TAG, 'Succeeded in getting preferences.');
  } catch (err) {
    let error = err as BusinessError;
    LogUtils.e(TAG, 'Failed to get preferences. code =' + error.code + ', message =' + error.message);
  }
}

export async function getRejectMsgData(context: common.UIAbilityContext, locale: string): Promise<string[]> {
  let defaultData = initDefaultMessage(context);
  await getRejectMsgPreferences(context);
  if (!rejectMsgPreferences) {
    return defaultData;
  }
  try {
    let key = getLocaleOfRejectMsg(locale);
    let data = rejectMsgPreferences.getSync(key, JSON.stringify(defaultData));
    let forData = formatData(context, data);
    return forData;
  } catch (err) {
    LogUtils.e(TAG, 'getRejectMsgData error to get all key-values. code =' + (err as BusinessError).code +
      ', message =' + (err as BusinessError).message);
    return defaultData;
  }
}

export async function updateRejectMsg(context: common.UIAbilityContext, locale: string,
  value: string[]): Promise<void> {
  await getRejectMsgPreferences(context);
  if (!rejectMsgPreferences) {
    return;
  }
  let key = locale + REJECT_MESSAGE_KEY_END;
  try {
    rejectMsgPreferences.putSync(key, JSON.stringify(value));
    saveRejectMsg(rejectMsgPreferences);
  } catch (err) {
    LogUtils.e(TAG, 'Failed to put value of ' + key + '. code =' + (err as BusinessError).code +
      ', message =' + (err as BusinessError).message);
  }
}

async function saveRejectMsg(rejectMsgPreferences: data_preferences.Preferences): Promise<void> {
  try {
    rejectMsgPreferences.flush().then(() => {
      LogUtils.i(TAG, 'Succeeded in flushing.');
    }).catch((err: BusinessError) => {
      LogUtils.i(TAG, 'Failed to flush. code =' + err.code + ', message =' + err.message);
    })
  } catch (err) {
    LogUtils.e(TAG, 'Failed to flush. code =' + (err as BusinessError).code +
      ', message =' + (err as BusinessError).message);
  }
}

function formatData(context: common.UIAbilityContext, data: data_preferences.ValueType): string [] {
  LogUtils.i(TAG, 'start formatData');
  let dataValue: string [] = JSON.parse(data.toString());
  for (let i = 0; i < dataValue.length; i++) {
    if (!(null === dataValue[i] || dataValue[i] === '')) {
      LogUtils.i(TAG, 'the value is not empty');
      continue;
    }
    let textValue: string = formatResourceToString(context, DEFAULT_REJECT_MESSAGE[i].textValue);
    LogUtils.i(TAG, `get textValue:${textValue}`);
    dataValue[i] = textValue;
  }
  return dataValue;
}

/*
 * add fuzzy match, to get reject key;
 * first, Exact match for locale. If no match is found, fuzzy match is used.
 * for example:
 * locale : en-Latn-CN, to match en-CN of allkeys from single.
 */
function getLocaleOfRejectMsg(locale: string): string {
  let allRejectKey = getAllRejectMsgData();
  if (allRejectKey.includes(locale + REJECT_MESSAGE_KEY_END)) {
    LogUtils.i(TAG, 'exact match succeded');
    return locale + REJECT_MESSAGE_KEY_END;
  }

  let reg = new RegExp('[-]{1}[A-Z]{1}[a-z]{3}[-]{1}');
  if (locale.match(reg)) {
    let newlocale = locale.replace(reg, '-');
    LogUtils.i(TAG, `newlocale${newlocale}`);
    if (allRejectKey.includes(newlocale + REJECT_MESSAGE_KEY_END)) {
      return newlocale + REJECT_MESSAGE_KEY_END;
    }
  }
  return locale + REJECT_MESSAGE_KEY_END;
}

/*
 * get allkeys form reject_message_preference_name
 */
function getAllRejectMsgData(): string[] {
  let allKeys: string[] = [];
  try {
    let value = rejectMsgPreferences.getAllSync();
    allKeys = Object.keys(value);
  } catch (err) {
    LogUtils.e(TAG, `getRejectMsgData error:${JSON.stringify(err)}`);
  }
  return allKeys;
}
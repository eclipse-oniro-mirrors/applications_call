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

import rdb from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import LogUtils from '../../common/utils/LogUtils';
import CallSettingSingleConstant from './CallSettingSingleConstant';
import { BusinessError } from '@kit.BasicServicesKit';
import {
  REJECT_MESSAGE_KEY_END,
  REJECT_MESSAGE_PREFERENCES_NAME,
  REJECT_MESSAGE_PREFERENCES_NAME_COPY
} from '../model/RejectMsgModel';
import data_preferences from '@ohos.data.preferences';
import { DEFAULT_REJECT_MESSAGE } from '../../common/constant/CallSettingConst';

const TAG = 'CallSettingDbHelper';

class TestLocale {
  public language: string = '';
  public region: string = '';
  public script: string = '';
  public id: string = '';
}

class CallSettingDbHelper {
  private rdbStoreHelper?: rdb.RdbStore;
  public totalPath: string = '';
  public filepath: string | undefined = '';
  public migrateType: string | undefined = '';
  public isFromHm: boolean = false;
  private backUpSMSLocale: string = '';
  private callRejectSMSArray: string[] = [];
  private REJECT_MSG_NUMBER: number = 4;

  private async initDB(context: common.Context): Promise<undefined | rdb.RdbStore> {
    LogUtils.i(TAG, 'initDB start');
    try {
      const OLD_CONFIG: rdb.StoreConfig = {
        name: 'CallManager.db',
        securityLevel: 1
      };
      this.rdbStoreHelper = await rdb.getRdbStore(context, OLD_CONFIG);
      return this.rdbStoreHelper;
    } catch (error) {
      LogUtils.e(TAG, `CallSettingDbHelper initDB failed:${JSON.stringify(error)}`);
    }
    return undefined;
  }

  public async queryCount(context: common.Context, tableName: string): Promise<number> {
    let count = 0;
    try {
      let rdbStore = await this.initDB(context);
      if (rdbStore === undefined) {
        return Promise.resolve(0);
      }
      let queryColumn = ['count(1)'];
      let predicatesInfo = new rdb.RdbPredicates(tableName);
      let resultSet = await rdbStore.query(predicatesInfo, queryColumn);
      if (resultSet.goToFirstRow()) {
        count = resultSet.getLong(0);
        LogUtils.i(TAG, `queryCount count : ${count}`);
      }
      resultSet.close();
      await rdbStore.close();
    } catch (error) {
      LogUtils.e(TAG, 'queryCount error');
    }
    return Promise.resolve(count);
  }

  public async queryCloneSubData(context: common.Context, cloneTbSubData: string): Promise<ValuesBucket[]> {
    LogUtils.i(TAG, 'queryCloneSubData start');
    let cloneSubDataList: ValuesBucket[] = [];
    try {
      let rdbStore = await this.initDB(context);
      if (rdbStore === undefined) {
        return [];
      }
      let predicatesInfo = new rdb.RdbPredicates(CallSettingSingleConstant.CLONE_PUBLIC_BACKUP_FIRST + cloneTbSubData +
      CallSettingSingleConstant.CLONE_PUBLIC_BACKUP_LAST);
      let resultSet: rdb.ResultSet | undefined = undefined;

      resultSet = await rdbStore.query(predicatesInfo);
      if (resultSet && resultSet.goToFirstRow()) {
        this.convertToValuesBucketForCloneSubData(resultSet, cloneSubDataList, cloneTbSubData, context);
      } else {
        LogUtils.i(TAG, 'queryCloneSubData no callSetting found ...');
      }
      resultSet.close();
    } catch (err) {
      LogUtils.e(TAG, 'queryCloneSubData error' + JSON.stringify(err));
    }
    return Promise.resolve(cloneSubDataList);
  }

  // instrument ignore next
  private async convertToValuesBucketForCloneSubData(resultSet: rdb.ResultSet, recordConfigList: ValuesBucket[],
    cloneTbSubData: string, context: common.Context): Promise<void> {
    do {
      let valuesBucket: ValuesBucket = {};
      valuesBucket[cloneTbSubData] = resultSet.getString(resultSet.getColumnIndex(cloneTbSubData)) as string;
      switch (cloneTbSubData) {
        case CallSettingSingleConstant.LOCALE:
          this.backUpSMSLocale = valuesBucket[cloneTbSubData] as string;
          break;
        case CallSettingSingleConstant.CANNED_RESPONSE_PREF_FIRST:
          this.callRejectSMSArray.push(valuesBucket[cloneTbSubData] as string);
          break;
        case CallSettingSingleConstant.CANNED_RESPONSE_PREF_SECOND:
          this.callRejectSMSArray.push(valuesBucket[cloneTbSubData] as string);
          break;
        case CallSettingSingleConstant.CANNED_RESPONSE_PREF_THIRD:
          this.callRejectSMSArray.push(valuesBucket[cloneTbSubData] as string);
          break;
        case CallSettingSingleConstant.CANNED_RESPONSE_PREF_FOURTH:
          this.callRejectSMSArray.push(valuesBucket[cloneTbSubData] as string);
          let locale = this.getConvertLocale(this.backUpSMSLocale);
          await this.updateRejectMsg(true, context, locale, this.callRejectSMSArray);
          break;
        default:
          break;
      }
      recordConfigList.push(valuesBucket);
    } while (resultSet.goToNextRow());
  }

  formatResourceToString(context: common.Context, resource: Resource) {
    let str: string = '';
    if (context) {
      str = context.resourceManager.getStringSync(resource.id);
    }
    return str;
  }

  initDefaultMessage(context: common.Context) {
    let defaultRejectMsgList: string[] = [];
    for (let i = 0; i < this.REJECT_MSG_NUMBER; i++) {
      let textValue: string = this.formatResourceToString(context, DEFAULT_REJECT_MESSAGE[i].textValue);
      defaultRejectMsgList.push(textValue);
    }
    return defaultRejectMsgList;
  }

  public async updateRejectMsg(isDoubleGramsSingle: boolean, context: common.Context, locale?: string,
    value?: string[]): Promise<void> {
    if (isDoubleGramsSingle) {
      LogUtils.i(TAG, 'start updateRejectMsg');
      let key = locale + REJECT_MESSAGE_KEY_END;
      try {
        let defaultData = this.initDefaultMessage(context);
        let rejectMsgPreferences = await data_preferences.getPreferences(context, REJECT_MESSAGE_PREFERENCES_NAME);
        let data: data_preferences.ValueType = rejectMsgPreferences.getSync(key, JSON.stringify(defaultData));
        let dataCopy: string [] = JSON.parse(data.toString());
        if (value) {
          for (let i = 0; i < value.length; i++) {
            if (!value[i] || value[i] == defaultData[i]) {
              LogUtils.i(TAG, 'dataCopy to value---');
              value[i] = dataCopy[i];
            }
          }
        }
        rejectMsgPreferences.putSync(key, JSON.stringify(value));
        rejectMsgPreferences.flush();
      } catch (err) {
        LogUtils.e(TAG, 'Failed to put value of ' + key + '. code =' + (err as BusinessError).code +
          ', message =' + (err as BusinessError).message);
      }
    } else {
      this.updateRejectMsgPre(context);
    }
  }

  public async updateRejectMsgPre(context: common.Context): Promise<void> {
    LogUtils.i(TAG, 'start updateRejectMsgPre');
    let key = REJECT_MESSAGE_KEY_END;
    try {
      let defaultData = this.initDefaultMessage(context);
      let rejectMsgPreferences = await data_preferences.getPreferences(context, REJECT_MESSAGE_PREFERENCES_NAME);
      let keys = rejectMsgPreferences.getAllSync();
      let allKeys = Object.keys(keys);
      for (let item of allKeys) {
        if (item.indexOf(REJECT_MESSAGE_KEY_END) !== -1) {
          key = item;
        }
      }
      let data: data_preferences.ValueType = rejectMsgPreferences.getSync(key, JSON.stringify(defaultData));
      let dataCopy: string [] = JSON.parse(data.toString());
      let rejectMsgPreferencesCopy =
        await data_preferences.getPreferences(context, REJECT_MESSAGE_PREFERENCES_NAME_COPY);
      let keysPre = rejectMsgPreferencesCopy.getAllSync();
      let allKeysPre = Object.keys(keysPre);
      for (let item of allKeysPre) {
        if (item.indexOf(REJECT_MESSAGE_KEY_END) !== -1) {
          key = item;
        }
      }
      let dataPre: data_preferences.ValueType = rejectMsgPreferencesCopy.getSync(key, JSON.stringify(defaultData));
      if (dataPre !== null) {
        let value: string [] = JSON.parse(dataPre.toString());
        for (let i = 0; i < value.length; i++) {
          if (!value[i] || value[i] === defaultData[i]) {
            LogUtils.i(TAG, 'dataCopy to value---');
            value[i] = dataCopy[i];
          }
        }
        rejectMsgPreferences.putSync(key, JSON.stringify(value));
        rejectMsgPreferences.flush();
      }
    } catch (err) {
      LogUtils.e(TAG, 'Failed to put value of ' + key + '. code =' + (err as BusinessError).code +
        ', message =' + (err as BusinessError).message);
    }
  }

  public getConvertLocale(backUpLocale: string): string {
    LogUtils.i(TAG, 'getLocaleFromList');
    let localeStr: string = backUpLocale;
    localeStr = localeStr?.replace(new RegExp('_#', 'g'), '#');
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
}

export const callSettingDbHelper: CallSettingDbHelper = new CallSettingDbHelper();

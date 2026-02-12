/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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
import { DataShareExtensionAbility, dataSharePredicates, distributedKVStore } from '@kit.ArkData';
import { Want } from '@kit.AbilityKit';
import LogUtils from '../utils/HiLog';
import { KvUtil } from './KvUtil';
import { AsyncCallback, BusinessError } from '@kit.BasicServicesKit';
import { emergencyData } from './EmergencyData';

const TAG: string = 'EmergencyDataShareExtAbility';

export default class EmergencyDataShareExtAbility extends DataShareExtensionAbility {
  private kvUtil: KvUtil | null = null;
  private kvOptions: distributedKVStore.Options = {
    securityLevel: distributedKVStore.SecurityLevel.S3,
    kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION
  };
  private emergencyContacts: string = '';
  private emergencyInfo: string = '';
  private KV_STORE_NAME: string = 'EMERGENCY';
  private KV_VALUE: string = '';
  private KV_KEY: string = '';

  async onCreate(want: Want, callback: Function) {
    LogUtils.i(TAG, 'onCreate start');
  }

  async query(uri: string, predicates: dataSharePredicates.DataSharePredicates, columns: Array<string>,
    callback: AsyncCallback<object>) {
    LogUtils.i(TAG, 'query start');
    try {
      if (!this.kvUtil) {
        this.kvUtil = KvUtil.getInstance();
      }
      this.emergencyInfo = emergencyData.getEmergencyInfo(this.context);
      this.emergencyContacts = emergencyData.getEmergencyContacts(this.context);
      this.KV_KEY =
        `{"emergencyInfo": ${this.emergencyInfo}, "contactList": ${this.emergencyContacts}}`;
      // 初始化键值库
      await this.kvUtil.initKv(this.context);
      // 创建KV库
      await this.kvUtil.createKV(this.KV_STORE_NAME, this.kvOptions);
      // 保存数据
      await this.kvUtil.insertData(this.KV_KEY, this.KV_VALUE);
      const result = await this.kvUtil?.getResultSetData(this.KV_KEY);
      callback(undefined, result);
    } catch (err) {
      const error = err as BusinessError;
      callback(error, undefined);
      LogUtils.e(TAG, `onCreate fail, code: ${error.code}, message: ${error.message}`);
    } finally {
      await this.kvUtil?.deleteKv(this.KV_KEY);
      LogUtils.i(TAG, 'KV_KEY Succeeded in deleting');
    }
  }
}

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
import LogUtils from '../utils/HiLog';
import { distributedKVStore } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = 'KvUtil';

export class KvUtil {
  private static kvUtil: KvUtil;
  private kvManager: distributedKVStore.KVManager | null = null;
  private kvSingleStore: distributedKVStore.SingleKVStore | null = null;
  private readonly BUNDLE_NAME: string = 'com.ohos.emergencycommunication';

  public static getInstance(): KvUtil {
    if (!KvUtil.kvUtil) {
      KvUtil.kvUtil = new KvUtil();
    }
    return KvUtil.kvUtil
  }

  /**
   * 初始化键值数据库
   * @param context
   * @returns
   */
  initKv(context: Context): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      const kvStoreConfig: distributedKVStore.KVManagerConfig = {
        context: context,
        bundleName: this.BUNDLE_NAME
      };
      try {
        this.kvManager = distributedKVStore.createKVManager(kvStoreConfig);
        LogUtils.i(TAG, 'Create kvManager success');
        resolve();
      } catch (err) {
        const error = err as BusinessError;
        LogUtils.e(TAG, `Create kvManager fail, code: ${error.code}, message: ${error.message}`);
        reject();
      }
    })
  }

  /**
   * 创建KV库
   * @param name KV库名称
   * @param op {distributedKVStore.Options}
   * @returns
   */
  createKV(name: string, op: distributedKVStore.Options): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      if (!this.kvManager) {
        LogUtils.i(TAG, 'No kvManager');
        reject();
      }
      // 本地数据库
      if (op.kvStoreType === distributedKVStore.KVStoreType.SINGLE_VERSION) {
        this.kvManager?.getKVStore(name, op, (error: BusinessError, store: distributedKVStore.SingleKVStore) => {
          if (error) {
            LogUtils.i(TAG, `Create DB fail, code: ${error.code}, message: ${error.message}`);
            reject(error);
          }
          this.kvSingleStore = store;
          LogUtils.i(TAG, 'Create DB success');
          resolve();
        })
      } else {
        // 分布式数据库
        LogUtils.i(TAG, 'No need DeviceKVStore');
        reject();
      }
    })
  }

  /**
   * 插入数据
   * @param key 要添加数据的key
   * @param value 要添加数据的value
   * @returns
   */
  insertData(key: string, value: string): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      if (!this.kvManager) {
        LogUtils.i(TAG, 'No kvManager');
        reject();
      }
      this.kvSingleStore?.put(key, value).then(() => {
        resolve();
      }).catch((error: BusinessError) => {
        LogUtils.e(TAG, `put fail, code: ${error.code}, message: ${error.message}`);
        reject(error);
      })
    })
  }

  /**
   * 删除KV
   * @param key 要删除的key
   * @returns
   */
  deleteKv(key: string): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      if (!this.kvManager) {
        LogUtils.i(TAG, 'No kvManager');
        reject();
      }
      this.kvSingleStore?.delete(key).then(() => {
        LogUtils.i(TAG, 'Succeeded in deleting');
        resolve();
      }).catch((error: BusinessError) => {
        LogUtils.e(TAG, `Failed to delete.code is ${error.code},message is ${error.message}`);
        reject(error);
      })
    })
  }

  /**
   * 查询结果集
   * @param query
   * @returns
   */
  getResultSetData(value: string): Promise<distributedKVStore.KVStoreResultSet> {
    return new Promise<distributedKVStore.KVStoreResultSet>((resolve, reject) => {
      if (!this.kvManager) {
        LogUtils.i(TAG, 'No kvManager');
        reject();
      }
      this.kvSingleStore?.getResultSet(value).then((result: distributedKVStore.KVStoreResultSet) => {
        resolve(result);
      }).catch((error: BusinessError) => {
        LogUtils.e(TAG, `getResultSetData fail, code: ${error.code}, message: ${error.message}`);
        reject(error);
      })
    })
  }
}
/*
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

import distributedKVStore from '@ohos.data.distributedKVStore'
import LogUtils from '../utils/LogUtils'

const TAG = "KVManager"

/**
 * Distributed database Basic configuration
 */
let kvManager: any = AppStorage.Get("kvManager")
const options = {
  createIfMissing: true,
  encrypt: false,
  backup: false,
  autoSync: true,
  kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
  securityLevel: distributedKVStore.SecurityLevel.S2,
};

/**
 * Distributed database Basic configuration
 */
const kvManagerConfig = {
  context: globalThis.settingsAbilityContext,
  bundleName: 'com.example.callui',
  userInfo: {
    userId: '0',
    userType: 0
  }
};

function createKVManager() {
  try {
    LogUtils.i(TAG, "succeeded in creating KVManager")
    kvManager = distributedKVStore.createKVManager(kvManagerConfig);
    AppStorage.SetOrCreate("kvManager", kvManager)
  } catch(e) {
    LogUtils.i(TAG, "Failed to create KVManager.code is " + JSON.stringify(e.code) + " message is : " + JSON.stringify(e.message))
  }
}

/**
 * Create a database instance
 *
 * @param {Function} callback - Callback
 */
function getKVStore(callback) {
  if (kvManager == undefined) {
    createKVManager();
  }
  kvManager.getKVStore('storeId', options).then((store) => {
    callback(store);
  });
}

/**
 * Distributed database Set up storage
 *
 * @param {string} key - storage key
 * @param {string} value - storage value
 */
export function setCache(key, value) {
  getKVStore(
    (store) => {
      store.put(key, value).then((data) => {
        LogUtils.i(TAG, `put success key ${key}, value: ${value}:` + JSON.stringify(data))
        if (key === 'pinRemainingTime') {
          getCache(key, (data) => {
            LogUtils.i(TAG, `getCache success key ${key}: ` + JSON.stringify(data))
          });
        }
      }).catch((err) => {
        LogUtils.i(TAG, 'put err: ' + JSON.stringify(err));
      });
    }
  );
}

/**
 * Distributed database Get up storage
 *
 * @param {string} key - storage key
 * @param {Function} callback - Callback
 */
export function getCache(key, callback) {
  getKVStore((store) => {
    store.get(key).then((data) => {
      callback(data);
    }).catch((err) => {
      LogUtils.i(TAG, 'getCache err: ' + JSON.stringify(err));
      callback(null, err);
    });
  });
}


/**
 * Distributed database Get up storage
 *
 * @param {string} key - storage key
 * @param {Function} callback - Callback
 */
export function deleteCache(key, callback) {
  getKVStore((store) => {
    store.delete(key).then((data) => {
      callback(data);
    }).catch((err) => {
      callback(null, err);
    });
  });
}

/**
 * Distributed database close storage
 */
export function closeKVStore() {
  getKVStore((store) => {
    kvManager.closeKVStore("appId", "storeId", function (err, data) {
      if (err != undefined) {
        LogUtils.e(TAG, `Fail to close KVStore  code is ${err.code}, message is ${err.message} `)
      }
    })
  })
}



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

import data_preferences from '@ohos.data.preferences';
import LogUtils from './HiLog';
import common from '@ohos.app.ability.common';
import { EmergencyGlobalContextHelper } from '../utils/EmergencyGlobalContextHelper';
import * as Constants from '../utils/Constants';
import { BusinessError } from '@ohos.base';
import { ContactListStruct } from '../utils/ClassStruct';

const TAG = 'dataStorageUtil';
const EMERGENCY_INFO_PREFERENCES_NAME = 'emergency_info_preference_name';
const AUTO_LOCATION_NAME = 'auto_location_flag';
const EMERGENCY_CONTACTS_PREFERENCES_NAME = 'emergency_contacts_preference_name';
const EMERGENCY_CONTACTS_KEY = 'emergency_contacts_key';

let emergencyInfoPreferences: data_preferences.Preferences | null = null;
let locationPreferences: data_preferences.Preferences;

async function getPreferences(callback: (result: boolean) => void): Promise<void>{
  try {
    let promise = data_preferences.getPreferences(EmergencyGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT), EMERGENCY_INFO_PREFERENCES_NAME);
    await promise.then((object) => {
      emergencyInfoPreferences = object;
      LogUtils.i(TAG, 'Succeeded in getting preferences.');
      callback(true);
    }).catch((err: BusinessError) => {
      LogUtils.i(TAG, 'Failed to get preferences. code =' + err.code + ', message =' + err.message);
      callback(false);
    })
  } catch (err) {
    LogUtils.e(TAG, 'Failed to get preferences. error :' + JSON.stringify(err));
    callback(false);
  }
}

function getLocationPreferences(callback: (result: boolean) => void) {
  try {
    let promise = data_preferences.getPreferences(EmergencyGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT), AUTO_LOCATION_NAME);
    promise.then((object) => {
      locationPreferences = object;
      LogUtils.i(TAG, 'Succeeded in getting getLocationPreferences.');
      callback(true);
    }).catch((err: BusinessError) => {
      LogUtils.i(TAG, 'Failed to get getLocationPreferences. code =' + err.code + ', message =' + err.message);
      callback(false);
    })
  } catch (err) {
    callback(false);
  }
}

function saveLocationFlagCallback(result: boolean) {
  if (result) {
    try {
      let promise = locationPreferences.flush();
      promise.then(() => {
        LogUtils.i(TAG, 'Succeeded in flushing.');
      }).catch((err: BusinessError) => {
        LogUtils.i(TAG, 'Failed to flush. code =' + err.code + ', message =' + err.message);
      })
    } catch (err) {
      LogUtils.i(TAG, 'Failed to flush. code =' + (err as BusinessError).code +
        ', message =' + (err as BusinessError).message);
    }
  }
}

function saveLocationFlag(): void {
  if (!emergencyInfoPreferences) {
    getLocationPreferences(saveLocationFlagCallback);
  } else {
    saveLocationFlagCallback(true);
  }
}

export function getEmergencyInfoData(callback: (data: Record<string, string>) => void): void {
  let getEmergencyInfoDataCallback: (result: boolean) => void = (result: boolean) => {
    if (!emergencyInfoPreferences) {
      LogUtils.i(TAG, `getEmergencyInfoData emergencyInfoPreferences is null`);
      return;
    }
    if (result) {
      try {
        let promise = emergencyInfoPreferences.getAll();
        promise.then((value: Object) => {
          LogUtils.i(TAG, 'getEmergencyInfoData getAll');
          callback(value as Record<string, string>);
        }).catch((err: BusinessError) => {
          LogUtils.i(TAG, 'getEmergencyInfoData Failed to get all key-values. code =' +
          err.code + ', message =' + err.message);
          callback({});
        })
      } catch (err) {
        LogUtils.i(TAG, 'getEmergencyInfoData Failed to get all key-values. code =' +
        (err as BusinessError).code + ', message =' + (err as BusinessError).message);
        callback({});
      }
    } else {
      callback({});
    }
  }

  if (!emergencyInfoPreferences) {
    getPreferences(getEmergencyInfoDataCallback);
  } else {
    getEmergencyInfoDataCallback(true);
  }
}

export function getAutoLocationFlag(callback: (data: Record<string, boolean>) => void): void {
  let getAutoLocationFlag: (result: boolean) => void = (result: boolean) => {
    if (result) {
      try {
        let promise: Promise<Object> = locationPreferences.getAll();
        promise.then((value: Object) => {
          LogUtils.i(TAG, 'getAutoLocationFlag getAll');
          callback(value as Record<string, boolean>);
        }).catch((err: BusinessError) => {
          LogUtils.i(TAG, 'getAutoLocationFlag Failed to get all key-values. code =' + err.code + ', message =' + err.message);
          callback({});
        })
      } catch (err) {
        LogUtils.i(TAG, 'getAutoLocationFlag Failed to get all key-values. code =' +
        (err as BusinessError).code + ', message =' + (err as BusinessError).message);
        callback({});
      }
    } else {
      callback({});
    }
  }

  if (!locationPreferences) {
    getLocationPreferences(getAutoLocationFlag);
  } else {
    getAutoLocationFlag(true);
  }
}

export function updateEmergencyInfoOnResult(key: string, value: string, result: boolean) {
  if (!emergencyInfoPreferences) {
    LogUtils.i(TAG, `updateEmergencyInfoOnResult emergencyInfoPreferences is null`);
    return;
  }
  if (result) {
    try {
      let promise = emergencyInfoPreferences.put(key, value);
      promise.then(() => {
        LogUtils.i(TAG, 'Succeeded in putting value of ' + key);
        saveEmergencyInfo();
      }).catch((err: BusinessError) => {
        LogUtils.i(TAG, 'Failed to put value of ' + key + '. code =' + err.code + ', message =' + err.message);
      })
    } catch (err) {
      LogUtils.i(TAG, 'Failed to put value of ' + key + '. code =' +
      (err as BusinessError).code + ', message =' + (err as BusinessError).message);
    }
  }
}

export function updateEmergencyInfo(key: string, value: string): void {
  let updateEmergencyInfoCallback = (result: boolean) => {
    updateEmergencyInfoOnResult(key, value, result)
  }
  if (!emergencyInfoPreferences) {
    getPreferences(updateEmergencyInfoCallback);
  } else {
    updateEmergencyInfoCallback(true);
  }
}

export async function updateEmergencyInfoSync(key: string, value: string) {
  let updateEmergencyInfoCallback = (result: boolean) => {
    if (!emergencyInfoPreferences) {
      LogUtils.i(TAG, `updateEmergencyInfoSync emergencyInfoPreferences is null`);
      return;
    }
    try {
      emergencyInfoPreferences.putSync(key, value);
    } catch (err) {
      LogUtils.i(TAG, 'updateEmergencyInfoSync Failed to put key-values. code =' +
      (err as BusinessError).code + ', message =' + (err as BusinessError).message);
    }
  }
  if (!emergencyInfoPreferences) {
    await getPreferences(updateEmergencyInfoCallback);
  } else {
    updateEmergencyInfoCallback(true);
  }
}

export function updateLocationFlagOnresult(key: string, value: boolean): void {

}

export function updateLocationFlagOnResult(key: string, value: boolean, result: boolean) {
  if (result) {
    try {
      let promise = locationPreferences.put(key, value);
      promise.then(() => {
        LogUtils.i(TAG, 'Succeeded in putting value of ' + key);
        saveLocationFlag();
      }).catch((err: BusinessError) => {
        LogUtils.i(TAG, 'Failed to put value of ' + key + '. code =' + err.code + ', message =' + err.message);
      })
    } catch (err) {
      LogUtils.i(TAG, 'Failed to put value of ' + key + '. code =' +
      (err as BusinessError).code + ', message =' + (err as BusinessError).message);
    }
  }
}

export function updateLocationFlag(key: string, value: boolean): void {
  let updateLocationFlagCallback = (result: boolean) => {
    updateLocationFlagOnResult(key, value, result)
  }
  if (!emergencyInfoPreferences) {
    getLocationPreferences(updateLocationFlagCallback);
  } else {
    updateLocationFlagCallback(true);
  }
}

export function saveEmergencyInfoOnResult(result: boolean) {
  if (!emergencyInfoPreferences) {
    LogUtils.i(TAG, `saveEmergencyInfoOnResult emergencyInfoPreferences is null`);
    return;
  }
  if (result) {
    try {
      let promise = emergencyInfoPreferences.flush();
      promise.then(() => {
        LogUtils.i(TAG, 'Succeeded in flushing.');
      }).catch((err: BusinessError) => {
        LogUtils.i(TAG, 'Failed to flush. code =' + err.code + ', message =' + err.message);
      })
    } catch (err) {
      LogUtils.i(TAG, 'Failed to flush. code =' + (err as BusinessError).code +
        ', message =' + (err as BusinessError).message);
    }
  }
}

export function saveEmergencyInfo(): void {
  let saveEmergencyInfoCallback = (result: boolean) => {
    saveEmergencyInfoOnResult(result)
  }
  if (!emergencyInfoPreferences) {
    getPreferences(saveEmergencyInfoCallback);
  } else {
    saveEmergencyInfoCallback(true);
  }
}

export function cleanEmergencyInfoOnResult(result: boolean) {
  if (!emergencyInfoPreferences) {
    LogUtils.i(TAG, `cleanEmergencyInfoOnResult emergencyInfoPreferences is null`);
    return;
  }
  if (result) {
    try {
      let promise = emergencyInfoPreferences.clear();
      promise.then(() => {
        LogUtils.i(TAG, 'Succeeded in clearing.');
        saveEmergencyInfo();
      }).catch((err: BusinessError) => {
        LogUtils.i(TAG, 'Failed to clear. code =' + err.code + ', message =' + err.message);
      })
    } catch (err) {
      LogUtils.i(TAG, 'Failed to clear. code =' +
      (err as BusinessError).code + ', message =' + (err as BusinessError).message);
    }
  }
}

export function cleanEmergencyInfo(): void {
  let cleanEmergencyInfoCallback = (result: boolean) => {
    cleanEmergencyInfoOnResult(result)
  }
  if (!emergencyInfoPreferences) {
    getPreferences(cleanEmergencyInfoCallback);
  } else {
    cleanEmergencyInfoCallback(true);
  }
}

export async function getEmergencyInfo(): Promise<void> {
  try {
    let promise = data_preferences.getPreferences(EmergencyGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT), EMERGENCY_INFO_PREFERENCES_NAME);
    await promise.then((object) => {
      emergencyInfoPreferences = object;
      LogUtils.i(TAG, 'Succeeded in getting preferences.');
    }).catch((err: BusinessError) => {
      LogUtils.i(TAG, 'Failed to get preferences. code =' + err.code + ', message =' + err.message);
    });
  } catch (err) {
    LogUtils.e(TAG, 'Failed to get get emergency info.');
  }
}

export class DataStorageUtil {
  private static sInstance: DataStorageUtil;
  public contactsPreferences: data_preferences.Preferences | null = null;

  constructor() {
  }

  public static getInstance() {
    if (DataStorageUtil.sInstance == null) {
      DataStorageUtil.sInstance = new DataStorageUtil();
    }
    return DataStorageUtil.sInstance;
  }

  public removePreferencesFromCacheSync(context: Context) {
    this.contactsPreferences = null;
    try {
      data_preferences.removePreferencesFromCacheSync(context, EMERGENCY_CONTACTS_PREFERENCES_NAME);
    } catch (e) {
      LogUtils.e(TAG, `removePreferencesFromCacheSync error: ${JSON.stringify(e)}`)
    }
  }

  public removeInfoPreferencesFromCacheSync(context: Context) {
    emergencyInfoPreferences = null;
    try {
      data_preferences.removePreferencesFromCacheSync(context, EMERGENCY_INFO_PREFERENCES_NAME);
    } catch (e) {
      LogUtils.e(TAG, `removeInfoPreferencesFromCacheSync error`)
    }
  }

  public getContactsPreferences(callback?: (result: boolean) => void, context?: Context) {
    try {
      let promise = data_preferences.getPreferences(context || EmergencyGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT),
        EMERGENCY_CONTACTS_PREFERENCES_NAME);
      promise.then((object) => {
        this.contactsPreferences = object;
        LogUtils.i(TAG, 'Succeeded in getting getContactsPreferences.');
        if (callback) {
          callback(true);
        }
      }).catch((err: BusinessError) => {
        LogUtils.i(TAG, 'Failed to get getContactsPreferences. code =' + err.code + ', message =' + err.message);
        this.contactsPreferences = null;
        if (callback) {
          callback(false);
        }
      })
    } catch (err) {
      LogUtils.i(TAG, 'Failed to get getContactsPreferences. code =' + (err as BusinessError).code +
        ', message =' + (err as BusinessError).message);
      this.contactsPreferences = null;
      if (callback) {
        callback(false);
      }
    }
  }

  public async getContactsPreferencesAsync(context: Context) {
    try {
      this.contactsPreferences = await data_preferences.getPreferences(context, EMERGENCY_CONTACTS_PREFERENCES_NAME)
        .then((object) => {
          return object;
        }).catch((err: BusinessError) => {
          LogUtils.i(TAG, 'Failed to get getContactsPreferencesAsync. code =' + err.code + ', message =' + err.message);
          return null;
        })
    } catch (err) {
      this.contactsPreferences = null;
      LogUtils.i(TAG, 'Failed to get getContactsPreferencesAsync. ' + ' error =' + JSON.stringify(err));
    }
  }

  public getContactsPreferencesSync(context: Context) {
    try {
      this.contactsPreferences =
        data_preferences.getPreferencesSync(context, { name: EMERGENCY_CONTACTS_PREFERENCES_NAME });
    } catch (err) {
      this.contactsPreferences = null;
      LogUtils.i(TAG, 'Failed to getContactsPreferencesSync. ' + ' error =' + JSON.stringify(err));
    }
  }

  public getEmergencyContacts(callback: (data: ContactListStruct[]) => void): void {
    let getEmergencyContactsDataCallback = (result: boolean) => {
      if (result) {
        try {
          (this.contactsPreferences as data_preferences.Preferences).get(EMERGENCY_CONTACTS_KEY, JSON.stringify([]))
            .then((value) => {
              LogUtils.i(TAG, 'getEmergencyContacts Succeeded');
              callback(JSON.parse(value as string));
            })
            .catch((err: BusinessError) => {
              LogUtils.i(TAG, 'getEmergencyContacts Failed to get all key-values. code =' +
              err.code + ', message =' + err.message);
              callback([]);
            })
        } catch (err) {
          LogUtils.i(TAG, 'getEmergencyContacts Failed to get all key-values. code =' +
          (err as BusinessError).code + ', message =' + (err as BusinessError).message);
          callback([]);
        }
      } else {
        callback([]);
      }
    }

    if (!this.contactsPreferences) {
      this.getContactsPreferences(getEmergencyContactsDataCallback);
    } else {
      getEmergencyContactsDataCallback(true);
    }
  }

  public getEmergencyContactsSync(context: Context): ContactListStruct[] {
    try {
      if (!this.contactsPreferences) {
        this.getContactsPreferencesSync(context);
      }
      if (!this.contactsPreferences) {
        return [];
      }
      const value = this.contactsPreferences.getSync(EMERGENCY_CONTACTS_KEY, JSON.stringify([]));
      return JSON.parse(value as string) as ContactListStruct[];
    } catch (err) {
      LogUtils.i(TAG, 'getEmergencyContactsSync Failed to get all key-values. code =' +
      (err as BusinessError).code + ', message =' + (err as BusinessError).message);
      return [];
    }
  }

  private flushPromiseFn(callback?: (value: boolean) => void) {
    if (!this.contactsPreferences) {
      callback && callback(false);
      return;
    }
    try {
      let flushPromise = this.contactsPreferences.flush();
      flushPromise.then(() => {
        LogUtils.i(TAG, 'Succeeded in flushing.');
        if (callback) {
          callback(true);
        }
      }).catch((err: BusinessError) => {
        LogUtils.i(TAG, 'Failed to flush. code =' + err.code + ', message =' + err.message);
        if (callback) {
          callback(false);
        }
      })
    } catch (err) {
      LogUtils.i(TAG, 'Failed to flush. code =' + (err as BusinessError).code +
        ', message =' + (err as BusinessError).message);
      if (callback) {
        callback(false);
      }
    }
  }

  private updateEmergencyContactsOnResult(value: ContactListStruct[],
    key: string, result: boolean, callback?: (value: boolean) => void) {
    if (!this.contactsPreferences || !result) {
      if (callback) {
        callback(false);
      }
      return;
    }
    try {
      this.contactsPreferences.put(key, JSON.stringify(value)).then(() => {
        LogUtils.i(TAG, 'Succeeded in putting value of ' + key);
        this.flushPromiseFn(callback);
      }).catch((err: BusinessError) => {
        LogUtils.i(TAG, 'Failed to put value of ' + key + '. code =' + err.code + ', message =' + err.message);
        if (callback) {
          callback(false);
        }
      })
    } catch (err) {
      LogUtils.i(TAG, 'Failed to flush. code =' + (err as BusinessError).code +
        ', message =' + (err as BusinessError).message);
      if (callback) {
        callback(false);
      }
    }
  }

  public updateEmergencyContacts(value: ContactListStruct[],
    callback?: (value: boolean) => void, context?: Context): void {
    LogUtils.i(TAG, 'updateEmergencyContacts');
    let key = EMERGENCY_CONTACTS_KEY;
    let updateEmergencyContactsCallback = (result: boolean) => {
      this.updateEmergencyContactsOnResult(value, key, result, callback)
    }
    if (!this.contactsPreferences) {
      this.getContactsPreferences(updateEmergencyContactsCallback, context);
    } else {
      updateEmergencyContactsCallback(true);
    }
  }
}
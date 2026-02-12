/**
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import LogUtils from '../../common/utils/LogUtils';
import { TableUseStruct } from '../../common/struct/RecorderStruct';
import dataShare from '@ohos.data.dataShare';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { Constant } from '../constant/Constant';
import relationalStore from '@ohos.data.relationalStore';
import { BusinessError } from '@ohos.base';
import data_preferences from '@ohos.data.preferences';
import { UriUseClass } from '../../common/struct/RecorderStruct';
import { CallSettingConstant } from '../constant/CallSettingConstant';
// import enhanced from '@hms.telephony.enhanced';
import { systemDateTime as time } from '@kit.BasicServicesKit';

const DB_CORRUPTED = 14800011;
const REBOOT_TIME_GAP = 10 * 1000;
const RECORD_DB_VERSION:number = 3;
const TAG = 'CallRecorderDatabaseHelper';
let rdbStore: relationalStore.RdbStore;

export default class RecordDatabaseHelper {
  public static TABLE: TableUseStruct = {
    RECORD_DATABASE: 'call_record.db',
    RECORD_CONFIG_SQL: 'CREATE TABLE IF NOT EXISTS record_config (id INTEGER PRIMARY KEY AUTOINCREMENT,is_open ' +
      'INTEGER DEFAULT 0, object VARCHAR DEFAULT 1,error_time INTEGER);',
    RECORD_CONTACT_SQL: 'CREATE TABLE IF NOT EXISTS record_contact (id INTEGER PRIMARY KEY AUTOINCREMENT' +
      ',phone_number TEXT,name VARCHAR);',
    RECORD_LOG_SQL: 'CREATE TABLE IF NOT EXISTS record_log (id INTEGER PRIMARY KEY AUTOINCREMENT,' +
      'file_path VARCHAR,duration VARCHAR,display_name VARCHAR,date_added INTEGER,recorder_added INTEGER,' +
      'title VARCHAR,phone_number TEXT,contacts TEXT,is_deleted INTEGER NOT NULL DEFAULT 0,' +
      'soundrecord_display_name TEXT);',
    RECORD_MIGRATION_SQL: 'CREATE TABLE IF NOT EXISTS tab_transfer_records (id INTEGER PRIMARY KEY AUTOINCREMENT,' +
      'display_name VARCHAR,ori_uri VARCHAR,new_uri VARCHAR,recorder_added INTEGER,' +
      'has_transfer INTEGER NOT NULL DEFAULT 0,try_times INTEGER NOT NULL DEFAULT 0);'
  };
  private static sInstance: RecordDatabaseHelper;

  static getInstance() {
    if (RecordDatabaseHelper.sInstance == null) {
      RecordDatabaseHelper.sInstance = new RecordDatabaseHelper();
    }
    return RecordDatabaseHelper.sInstance;
  }

  async getCallUserInfo(context: Context, callNumber: string) {
    LogUtils.i(TAG, 'getCallUserInfo start');
    let contacts: string = callNumber;
    try {
      let dataShareUse = await dataShare.createDataShareHelper(context, Constant.CONTACT_URI);
      let condition = new dataSharePredicates.DataSharePredicates();
      if (callNumber.length >= 7) {
        let queryNum = callNumber.slice(-7);
        condition.endsWith('detail_info', queryNum);
      } else {
        condition.equalTo('detail_info', callNumber);
      }
      condition.and();
      condition.equalTo('type_id', '5');
      condition.and();
      condition.equalTo('is_deleted', '0');
      let resultSet = await dataShareUse.query(Constant.CONTACT_URI, condition, Constant.COLUMNS);
      LogUtils.i(TAG, `queryContactByNum resultLen:${resultSet.rowCount}`);
      if (resultSet.rowCount > 0) {
        // let numMatchIndex = await enhanced.getPreciselyMatchedIndex(resultSet, callNumber);
        // if (resultSet.goToRow(numMatchIndex)) {
        //   contacts = resultSet.getString(resultSet.getColumnIndex('display_name'));
        // }
      }
      resultSet.close();
      return contacts;
    } catch (err) {
      LogUtils.e(TAG, `error code: ${(err as BusinessError).code}`);
      return contacts;
    }
  }

  async checkIsRebootAndFlushDb(context: Context, preferences: data_preferences.Preferences): Promise<void> {
    let curBootTime = Math.floor((time.getTime() - time.getUptime(time.TimeType.STARTUP)) / REBOOT_TIME_GAP);
    let lastBootTime = preferences.getSync('lastBootTime', 0) as number;
    if (lastBootTime !== curBootTime) {
      LogUtils.i(TAG, 'check is reboot');
      preferences.putSync('lastBootTime', curBootTime);
      await preferences.flush();
      await this.flushingDataBaseFile(context);
    }
  }

  async flushingDataBaseFile(context: Context, hasInited: boolean = true, coundId: number = -1) {
    try {
      await this.getDualWriteRdbStore(context);
      await rdbStore.close();
      LogUtils.i(TAG, 'flushing DataBase File end');
    } catch (err) {
      LogUtils.e(TAG, `closeDb err:${JSON.stringify(err)}`);
    }
  }

  async getDatabaseInfo(uri: string, context: Context) {
    LogUtils.i(TAG, 'getDatabaseInfo start');
    try {
      let preferences = await data_preferences.getPreferences(context, 'initDBPreferences');
      let dbStatus = await preferences.get('isInit', false);
      if (!dbStatus) {
        await this.InitForDB(context);
        await preferences.put('isInit', true);
        await preferences.flush();
      }
      await this.updateForDB(context);
      await this.checkIsRebootAndFlushDb(context, preferences);
      let uriUse = uri.split('/').reverse();
      let result: UriUseClass = {
        dbUse: uriUse[1] + '.db',
        tableUse: uriUse[0],
        type: uriUse[2]
      };
      return result;
    } catch (err) {
      LogUtils.e(TAG, `getDatabaseInfo failed, err: ${JSON.stringify(err)}`);
      return undefined;
    }
  }

  async getRdb(context: Context): Promise<void> {
    let autoBackupConfig: relationalStore.StoreConfig = {
      name: RecordDatabaseHelper.TABLE.RECORD_DATABASE,
      securityLevel: relationalStore.SecurityLevel.S1,
      haMode: relationalStore.HAMode.MAIN_REPLICA,
      allowRebuild: true
    }
    rdbStore = await relationalStore.getRdbStore(context, autoBackupConfig);
    LogUtils.i(TAG, 'getDualWriteRdbStore getRdbStore build type:' + rdbStore.rebuilt);
  }

  async isPragmaIntegrityCheckOk(): Promise<boolean> {
    let checkResult = await rdbStore.execute('pragma integrity_check;');
    LogUtils.i(TAG, `getDualWriteRdbStore pragma integrity_check result:${checkResult}`);
    return checkResult === 'ok';
  }

  async getDualWriteRdbStore(context: Context): Promise<relationalStore.RdbStore> {
    LogUtils.i(TAG, 'getDualWriteRdbStore');
    try {
      await this.getRdb(context);
      let isCheckPassed = await this.isPragmaIntegrityCheckOk();
      if (!isCheckPassed) {
        await this.restore(context, DB_CORRUPTED);
      }
    } catch (err) {
      LogUtils.e(TAG, `getDualWriteRdbStore failed, err:${JSON.stringify(err)}`);
      await this.restore(context, err?.code);
    }
    return rdbStore;
  }

  async restore(context: Context, errorCode: number) {
    LogUtils.i(TAG, `restore errorCode:${errorCode}`);
    try {
      if (errorCode === DB_CORRUPTED) {
        await rdbStore.restore();
      }
      LogUtils.i(TAG, 'restore ok');
    } catch (err) {
      LogUtils.e(TAG, `restore failed, err:${JSON.stringify(err)}`);
    }
  }

  async InitForDB(context: Context) {
    LogUtils.i(TAG, 'InitForDB start');
    await this.getDualWriteRdbStore(context);
    try {
      await rdbStore?.executeSql(RecordDatabaseHelper.TABLE.RECORD_CONFIG_SQL);
      await rdbStore?.executeSql(RecordDatabaseHelper.TABLE.RECORD_CONTACT_SQL);
      await rdbStore?.executeSql(RecordDatabaseHelper.TABLE.RECORD_LOG_SQL);
      if (rdbStore?.version <= 0) {
        rdbStore.version = RECORD_DB_VERSION;
      }
    } catch (err) {
      LogUtils.e(TAG, `executeSql failed, err: ${JSON.stringify(err)}`);
    }
    this.queryRecorderConfig((queryRecorderConfigResult) => {
      LogUtils.i(TAG, 'Ability onCreate queryRecorderConfigResult' + JSON.stringify(queryRecorderConfigResult));
      if (!queryRecorderConfigResult) {
        this.insertRecorderConfig();
      }
    });
  }

  async updateForDB(context: Context) {
    await this.getDualWriteRdbStore(context);
    try {
      if (rdbStore?.version <= 0) {
        LogUtils.i(TAG, 'updateForDB rdb version <= 0');
        rdbStore.executeSql('ALTER TABLE record_log ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0');
        rdbStore.executeSql('ALTER TABLE record_log ADD COLUMN soundrecord_display_name TEXT');
        rdbStore.version = 3;
      }
    } catch (err) {
      LogUtils.e(TAG, `executeSql failed, err: ${JSON.stringify(err)}`);
    }
  }

  queryRecorderConfig(callback: (data: boolean) => void) {
    LogUtils.i(TAG, 'queryRecorderConfig start');
    try {
      LogUtils.i(TAG, 'Ability onCreate queryRecorderConfig start');
      let predicates = new dataSharePredicates.DataSharePredicates();
      let columns = ['is_open', 'object'];
      LogUtils.i(TAG, 'Ability onCreate columns start');
      rdbStore.query('record_config', predicates, columns, (err, resultSet) => {
        if (err) {
          LogUtils.e(TAG, `queryForConfig failed, code is ${err.code}`);
          callback(false);
          return;
        }
        if (resultSet.goToNextRow()) {
          const objectResult = resultSet.getString(resultSet.getColumnIndex('object'));
          resultSet.close();
          LogUtils.i(TAG, 'Ability onCreate queryRecorderConfigResult objectResult length:' + objectResult.length);
          if (objectResult) {
            callback(true);
            return;
          }
        }
        callback(false);
      });
    } catch (err) {
      let error = err as BusinessError;
      LogUtils.e(TAG, 'initRdb err: code: ' + error.code);
      callback(false);
    }
  }

  async insertRecorderConfig() {
    LogUtils.i(TAG, 'insertRecorderConfig start');
    try {
      let promise = rdbStore.insert('record_config', {
        is_open: CallSettingConstant.CLOSE_RECORDING_STATUS, object: CallSettingConstant.RECORDING_WAY_ALL_NUMBER
      });
      promise.then((rowId: number) => {
        LogUtils.i(TAG, `insertRecorderConfig is successful, rowId = ${rowId}`);
      }).catch((err: BusinessError) => {
        LogUtils.e(TAG, 'insertRecorderConfig err: code: ' + err.code);
      });
    } catch (err) {
      LogUtils.e(TAG, `rdbStore insert failed, err: ${JSON.stringify(err)}`);
    }
  }

  async initMigrationDB(context: Context): Promise<boolean> {
    await this.getDualWriteRdbStore(context);
    try {
      await rdbStore?.executeSql(RecordDatabaseHelper.TABLE.RECORD_MIGRATION_SQL);
      if (rdbStore?.version <= 0) {
        rdbStore.version = RECORD_DB_VERSION;
      }
      return true;
    } catch (err) {
      LogUtils.e(TAG, `executeSql failed, err: ${JSON.stringify(err)}`);
      return false;
    }
  }
}

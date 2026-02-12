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

import common from '@ohos.app.ability.common';
import LogUtils from '../utils/LogUtils';
import { callRecorderDbHelper } from '../utils/database/CallRecorderDbHelper';
import CallRecordCloneConstant from '../constant/CallRecorderCloneConstant';
import CallRecorderSingleConstant from '../constant/CallRecorderSingleConstant';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import commonController from '../control/CommonCtrol';
import CallRecorderCloneConstant from '../constant/CallRecorderCloneConstant';
import HashMap from '@ohos.util.HashMap';
import QuerySettingsDataHelper from '../utils/QuerySettingDataHelper';
import { arDbHelper } from '../utils/database/AutoRecordDbHelper';
import CallRecorderDualConstant from '../constant/CallRecorderDualConstant';
import { CallSettingConstant } from '../constant/CallSettingConstant';
import { copyDbDataHelper } from '../utils/CopyDbDataHelper';
import { ReportUtil } from '../utils/ReportUtil';

const TAG = 'CallRecorderModel';

export default class CallRecorderModel {
  async startCloneHm2Next(context: common.Context): Promise<void> {
    await this.startMigrateRecordContact(context, true);
    await this.startMigrateCallRecord(context);
  }

  public async startMigrateCallRecord(context: common.Context) {
    LogUtils.i(TAG, 'startMigrateCallRecord');
    let tableName: string = CallRecorderSingleConstant.RECORD_LOG_TB_NAME;
    if (AppStorage.has('MigrateType')) {
      let migrateType: string | undefined = AppStorage.get('MigrateType');
      LogUtils.i(TAG, `MigrateType:${migrateType}`);
      if (migrateType == CallRecorderCloneConstant.CLONE_VERSION_NAME) {
        tableName = CallRecordCloneConstant.RECORDER_FILE_TB;
      }
    }
    let recordLogMap: HashMap<string, number> = await commonController.getInstance().queryForRecordLog(context);
    let count = await callRecorderDbHelper.queryCount(context, tableName);
    copyDbDataHelper.setAudioTotalCountInDb(count);
    let totalPage = Math.ceil(count / CallRecordCloneConstant.QUERY_PAGE_NUM);
    for (let curPage = 1; curPage <= totalPage; curPage++) {
      let callRecodeResult: ValuesBucket[] = await callRecorderDbHelper.queryCallRecorder(
        context, CallRecordCloneConstant.QUERY_PAGE_NUM * (curPage - 1), recordLogMap);
      let rowId = await commonController.getInstance().batchInsertRecordInfoForClone(context, callRecodeResult);
      copyDbDataHelper.addSuccessAudioCountInDb(rowId ?? 0);
    }
    LogUtils.i(TAG, 'endMigrateCallRecord');
  }

  public async startMigrateNext2Next(context: common.Context): Promise<void> {
    await this.startMigrateRecordConfig(context);
    await this.startMigrateCallRecord(context);
    await this.startMigrateRecordContact(context);
    await callRecorderDbHelper.delOldSingleDb(context);
  }

  public async startMigrateRecordContact(context: common.Context, isFromHm: boolean = false) {
    LogUtils.i(TAG, 'startMigrateRecordContact');
    let newContactNums = await commonController.getInstance().queryNewContactNums(context);
    let table = isFromHm ? CallRecordCloneConstant.CONTACT_TB : CallRecorderSingleConstant.RECORD_CONTACT_TB_NAME;
    let count = await callRecorderDbHelper.queryCount(context, table);
    let totalPage = Math.ceil(count / CallRecordCloneConstant.QUERY_PAGE_NUM);
    for (let curPage = 1; curPage <= totalPage; curPage++) {
      let recordContactDataStruct: ValuesBucket[] = await callRecorderDbHelper.queryRecordContact(
        context, CallRecordCloneConstant.QUERY_PAGE_NUM * (curPage - 1));
      recordContactDataStruct =
        recordContactDataStruct.filter(item =>!(newContactNums.includes(item['phone_number'] as string)));
      await commonController.getInstance()
        .batchInsertConfigContactForClone(context, recordContactDataStruct, (rowId) => {
          LogUtils.i(TAG, `batchInsertConfigContact rowId:${rowId}`);
        });
    }
    LogUtils.i(TAG, 'endMigrateRecordConfig');
  }

  public async startMigrateRecordConfig(context: common.Context) {
    LogUtils.i(TAG, 'startMigrateRecordConfig');
    let recordConfigResult: ValuesBucket = await callRecorderDbHelper.queryRecordConfig(context);
    if (recordConfigResult != undefined && recordConfigResult != null) {
      await commonController.getInstance().updateIsOpenForClone(context, recordConfigResult, (configData) => {
        LogUtils.i(TAG, 'migrateRecordConfig' + JSON.stringify(configData));
      });
    } else {
      LogUtils.i(TAG, 'not need migrate RecordConfig');
    }
  }

  public async startMigrateHMOS2NEXT(context: common.Context): Promise<void> {
    await this.startMigrateRecordConfigForUp(context);
    await this.startMigrateRecordContactForUp(context);
    await this.startMigrateCallRecordForUp(context);
  }

  public async startMigrateCallRecordForUp(context: common.Context) {
    let count = await arDbHelper.queryCount(context, CallRecorderDualConstant.RECORDER_FILE_TABLE_NAME);
    ReportUtil.getInstance().reportRestoreStatus(1, count);
    copyDbDataHelper.setAudioTotalCountInDb(count);
    let totalPage = Math.ceil(count / CallRecordCloneConstant.QUERY_PAGE_NUM);
    LogUtils.i(TAG, 'startMigrateCallRecordForUp count = ' + count);
    for (let curPage = 1; curPage <= totalPage; curPage++) {
      let callRecodeResult: ValuesBucket[] = await arDbHelper.queryAutoRecordDbForHmUpgradeNext(
        context, CallRecordCloneConstant.QUERY_PAGE_NUM * (curPage - 1));
      let rowId = await commonController.getInstance().batchInsertRecordInfoForClone(context, callRecodeResult);
      copyDbDataHelper.addSuccessAudioCountInDb(rowId ?? 0);
    }
    LogUtils.i(TAG, 'endMigrateCallRecordForUp');
  }

  public async startMigrateRecordConfigForUp(context: common.Context) {
    LogUtils.i(TAG, 'startMigrateRecordConfigForUp');
    let queryData = new QuerySettingsDataHelper();
    let recordConfigValue: ValuesBucket = {};
    if (context != null && context != undefined) {
      await queryData.queryIsOpenValue(context, undefined, (data: number) => {
        recordConfigValue[CallRecorderSingleConstant.CONFIG_IS_OPEN] = data;
      });
      await queryData.queryObjectValue(context, undefined, (data: string) => {
        recordConfigValue[CallRecorderSingleConstant.CONFIG_OBJECT] =
          (data == '0') ? CallSettingConstant.RECORDING_WAY_DESIGNATE_NUMBER : data;
      });
      if (recordConfigValue != null) {
        await commonController.getInstance().updateIsOpenForClone(context, recordConfigValue, (configData) => {
          LogUtils.i(TAG, ' saveRecordingState configData ' + JSON.stringify(configData));
        });
      }
    }
  }

  public async startMigrateRecordContactForUp(context: common.Context) {
    LogUtils.i(TAG, 'startMigrateRecordContactForUp');
    let count = await arDbHelper.queryCount(context, CallRecorderDualConstant.CUSTOMIZE_TABLE_NAME);
    ReportUtil.getInstance().reportRestoreStatus(1, count);
    let totalPage = Math.ceil(count / CallRecordCloneConstant.QUERY_PAGE_NUM);
    LogUtils.i(TAG, 'count = ' + count + ', totalPage =' + totalPage);
    for (let curPage = 1; curPage <= totalPage; curPage++) {
      let recordContactDataStruct: ValuesBucket[] = await arDbHelper.queryContactData(
        context, CallRecordCloneConstant.QUERY_PAGE_NUM * (curPage - 1));
      await commonController.getInstance()
        .batchInsertConfigContactForClone(context, recordContactDataStruct, (rowId) => {
          LogUtils.i(TAG, `batchInsertConfigContact rowId:${rowId}`);
        });
    }
  }
}

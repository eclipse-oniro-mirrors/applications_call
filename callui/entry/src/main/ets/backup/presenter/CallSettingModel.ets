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
import LogUtils from '../../common/utils/LogUtils';
import { callSettingDbHelper } from './CallSettingDbHelper';
import CallSettingSingleConstant from './CallSettingSingleConstant';

const TAG = 'CallSettingModel';

export default class CallSettingModel {
  async startCloneHm2Next(context: common.Context): Promise<void> {
    let cloneDataArray = [
      CallSettingSingleConstant.LOCALE,
      CallSettingSingleConstant.CANNED_RESPONSE_PREF_FIRST,
      CallSettingSingleConstant.CANNED_RESPONSE_PREF_SECOND,
      CallSettingSingleConstant.CANNED_RESPONSE_PREF_THIRD,
      CallSettingSingleConstant.CANNED_RESPONSE_PREF_FOURTH
    ]
    for (let i = 0; i < cloneDataArray.length; i++) {
      await this.startMigrateCloneDataOption(context, cloneDataArray[i]);
    }
  }

  public async startMigrateCloneDataOption(context: common.Context, cloneTbSubData: string) {
    LogUtils.i(TAG, 'startMigrateCloneDataOption');
    let table = CallSettingSingleConstant.CLONE_PUBLIC_BACKUP_FIRST + cloneTbSubData +
    CallSettingSingleConstant.CLONE_PUBLIC_BACKUP_LAST;
    let count = await callSettingDbHelper.queryCount(context, table);
    let totalPage = Math.ceil(count / CallSettingSingleConstant.QUERY_PAGE_NUM);
    for (let curPage = 1; curPage <= totalPage; curPage++) {
      await callSettingDbHelper.queryCloneSubData(context, cloneTbSubData);
    }
    LogUtils.i(TAG, 'endMigrateRecordConfig');
  }
}

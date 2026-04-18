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

import { RecordConfigDataStruct } from '../struct/RecorderSettingConfig';
import { LogUtils, CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import common from '@ohos.app.ability.common';
import * as CallSettingsConstant from '../constant/CallSettingsConstant';
import dataShare from '@ohos.data.dataShare';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { BusinessError } from '@ohos.base';

const TAG = 'RecordingSettingCommonCtrol';

export default class CommonController {
  private static sInstance: CommonController;
  private dataShareUrl: string = CallSettingsConstant.DATA_SHARE_ABILITY_NAME;

  static getInstance() {
    if (CommonController.sInstance == null) {
      CommonController.sInstance = new CommonController();
    }
    return CommonController.sInstance;
  }

  async jumpToRecordForResult(callback: (data: boolean) => void) {
    let actionData: Record<string, string> = {
      'ability.want.params.uiExtensionType': 'sys/commonUI'
    };
    let str: Record<string, Object> = {
      'bundleName': CallSettingsConstant.CALL_RECORDER_BUNDLE_NAME,
      'abilityName': CallSettingsConstant.CALL_RECORDER_ABILITY_NAME,
      'parameters': actionData
    };
    try {
      let data = await CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT)
        .startAbilityForResult(str);
      let result: boolean = false;
      if (data) {
        result = data.want?.parameters?.contactObjects === 'true';
      }
      callback(result);
    } catch (err) {
      LogUtils.e(TAG, `jumpToRecordForResult error code: ${err.code}, message: ${err.message}`);
    }
  }

  async queryForConfig(context: Context, callback: (data: RecordConfigDataStruct) => void) {
    let uri = this.dataShareUrl + CallSettingsConstant.RECORDER_CONFIG_TABLE;
    let condition = new dataSharePredicates.DataSharePredicates();
    const columns = ['is_open', 'object'];
    try {
      let dataHelper = await dataShare.createDataShareHelper(context, uri);
      dataHelper.query(uri, condition, columns, (err, resultSet) => {
        if (resultSet?.goToNextRow()) {
          const isOpen = resultSet.getLong(resultSet.getColumnIndex('is_open'));
          const object = resultSet.getString(resultSet.getColumnIndex('object'));
          if (err) {
            LogUtils.e(TAG, `queryForConfig failed, code is ${err.code},message is ${err.message}`);
            return;
          }
          let result: RecordConfigDataStruct = {
            isOpen: isOpen, object: object
          };
          resultSet.close();
          callback(result);
        }
      });
    } catch (err) {
      LogUtils.e(TAG, 'queryForConfig err:' + JSON.stringify(err));
    }
  }
}

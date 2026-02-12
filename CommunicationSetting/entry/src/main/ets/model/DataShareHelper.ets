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
import dataShare from '@ohos.data.dataShare';
import { Uri } from '../constants/CommonConstants';
import { LogUtil } from '../util/LogUtil';

export default class DataShareHelper {
  private static TAG = 'DataShareHelper';
  private static instance: DataShareHelper | undefined = undefined;
  private settingDbHelper?: dataShare.DataShareHelper;

  private constructor() {
  }

  public static getInstance(): DataShareHelper {
    if (!DataShareHelper.instance) {
      DataShareHelper.instance = new DataShareHelper();
    }
    return DataShareHelper.instance;
  }

  public static release() {
    if (DataShareHelper.instance) {
      DataShareHelper.instance.settingDbHelper = undefined;
      DataShareHelper.instance = undefined;
    }
  }

  public async initSettingDB(context: Context): Promise<dataShare.DataShareHelper | undefined> {
    if (!context) {
      LogUtil.warn(DataShareHelper.TAG, 'initSettingDB context is empty')
      return undefined;
    }
    if (this.settingDbHelper) {
      LogUtil.info(DataShareHelper.TAG, 'initSettingDB already init, return.')
      return Promise.resolve(this.settingDbHelper);
    }
    try {
      this.settingDbHelper = await dataShare.createDataShareHelper(context, Uri.SETTINGS_DATA_URI);
    } catch (error) {
      LogUtil.warn(DataShareHelper.TAG, `initSettingDB failed, error code: ${error?.code}, error message:${error?.message}`)
    }
    if (this.settingDbHelper) {
      LogUtil.info(DataShareHelper.TAG, 'initSettingDB first init,success.')
      return Promise.resolve(this.settingDbHelper);
    }
    return undefined;
  }
}
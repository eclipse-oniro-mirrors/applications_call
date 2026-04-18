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
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { BusinessError } from '@ohos.base';
import common from '@ohos.app.ability.common';
import { Constant } from '../constant/Constant';
import { GlobalContextHelper } from '../utils/GlobalContextHelper';
import LogUtils from '../utils/LogUtils';

const TAG = 'PermissionManager';

export class PermissionManager {
  private _isAllPermissionsGranted: boolean = false;
  private static instance: PermissionManager;

  public static getInstance(): PermissionManager {
    if (!PermissionManager.instance) {
      PermissionManager.instance = new PermissionManager();
    }
    return PermissionManager.instance;
  }

  public isAllPermissionsGranted() {
    return this._isAllPermissionsGranted;
  }

  async initPermissions() {
    LogUtils.i(TAG, 'initPermissions start');
    let requestPermissions: Permissions[] = [
      'ohos.permission.WRITE_AUDIO',
      'ohos.permission.READ_CONTACTS',
      'ohos.permission.NOTIFICATION_CONTROLLER',
      'ohos.permission.FILE_ACCESS_MANAGER'
    ];
    let atManager = abilityAccessCtrl.createAtManager();
    let context = GlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    atManager.requestPermissionsFromUser(context, requestPermissions)
      .then((data) => {
        let authFlag = true;
        for (let i = 0; i < data.authResults.length; i++) {
          if (data.authResults[i] == -1) {
            authFlag = authFlag && false;
          }
        }
        LogUtils.i(TAG, 'authFlag: ' + JSON.stringify(authFlag));
        this._isAllPermissionsGranted = authFlag;
      })
      .catch((err: BusinessError) => {
        LogUtils.e(TAG, `requestPermissionsFromUser init failed, error code: ${err.code}`);
      });
    LogUtils.i(TAG, 'Application requestPermissionsFromUser end');
  }
}
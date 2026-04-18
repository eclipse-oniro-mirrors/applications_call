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
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl'
import common from '@ohos.app.ability.common';
import LogUtils from '../utils/HiLog';

const permissionsList: Permissions[] = ['ohos.permission.APPROXIMATELY_LOCATION',
  'ohos.permission.LOCATION', 'ohos.permission.LOCATION_IN_BACKGROUND']
const APPROVAL: number = 0
const TAG = 'Applicant';

export default async function requestPermissionFromUsers(context: common.UIAbilityContext) {
  let isFinished: boolean = false
  let atManager = abilityAccessCtrl.createAtManager()
  await atManager.requestPermissionsFromUser(context, permissionsList).then((result) => {
    let grantStatus: number[] = result.authResults
    for (let i = 0; i < grantStatus.length; i++) {
      if (grantStatus[i] === APPROVAL) {
        isFinished = true
      } else {
        LogUtils.i(TAG, 'User denies providing the permissions')
      }
    }
  }).catch((err: Error) => {
    LogUtils.e(TAG, 'request Permissions From User' + err.message)
  })
  return isFinished
}
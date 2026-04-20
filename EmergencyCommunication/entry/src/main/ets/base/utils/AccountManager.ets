/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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

import account_osAccount from '@ohos.account.osAccount';
import LogUtils from '../../utils/HiLog';

const TAG = 'AccountManager'
export const INVALID_USERNAME = 'unknown'

export class AccountManager {
  private static sInstance: AccountManager

  private isGetAccountNameFinish = false
  private userName: string = ''

  private constructor() {}

  public static getInstance(): AccountManager {
    if (AccountManager.sInstance === null || AccountManager.sInstance === undefined) {
      AccountManager.sInstance = new AccountManager()
    }
    return AccountManager.sInstance
  }

  public init() {
    this.initUserName()
  }

  public getUserName(): string {
    if (this.isGetAccountNameFinish) {
      return this.userName
    }
    this.initUserName()
    return INVALID_USERNAME
  }

  private async initUserName() {
    let accountManager = account_osAccount.getAccountManager()
    try {
      this.userName = await accountManager.getOsAccountName()
      this.isGetAccountNameFinish = true
    } catch (err) {
      LogUtils.e(TAG, `call accountManager.getOsAccountName, err: ${JSON.stringify(err)}`)
    }
  }
}
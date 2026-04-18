/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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
import ServiceExtensionAbility from '@ohos.app.ability.ServiceExtensionAbility';
import LogUtils from '../common/utils/LogUtils';
import Want from '@ohos.app.ability.Want';
import rpc from '@ohos.rpc';
import MigrationServiceExtImpl from '../migrationServiceExt/MigrationServiceExtImpl';

const TAG = 'MigrationServiceExtensionAbility';

class StubTest extends rpc.RemoteObject {
  constructor(des: string) {
    super(des);
  }
}


export default class MigrationServiceExtensionAbility extends ServiceExtensionAbility {
  private migrationServiceExtImpl: MigrationServiceExtImpl | undefined;

  constructor() {
    super();
  }

  onConnect(want: Want) {
    LogUtils.i(TAG, 'onConnect');
    if (!this.migrationServiceExtImpl) {
      this.migrationServiceExtImpl = new MigrationServiceExtImpl(this.context);
    }
    return this.migrationServiceExtImpl;
  }

  onDisconnect(want: Want) {
    LogUtils.i(TAG, 'onDisconnect');
    this.migrationServiceExtImpl?.stopMigrationWhenOnDisconnect();
    this.migrationServiceExtImpl = undefined;
  }
}
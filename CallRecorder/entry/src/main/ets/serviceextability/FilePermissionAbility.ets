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
import ServiceExtensionAbility from '@ohos.app.ability.ServiceExtensionAbility';
import LogUtils from '../common/utils/LogUtils';
import rpc from '@ohos.rpc';
import IdlFilePermissionExtImpl from '../filePermissionExt/idl_file_permission_ext_impl';

const TAG = 'FilePermissionExtensionAbility';

class StubTest extends rpc.RemoteObject {
  constructor(des: string) {
    super(des);
  }
}


export default class FilePermissionExtensionAbility extends ServiceExtensionAbility {
  private filePermissionExtImpl: IdlFilePermissionExtImpl | undefined;

  constructor() {
    super();
  }

  onConnect(want: Want) {
    LogUtils.i(TAG, 'onConnect');
    this.filePermissionExtImpl = new IdlFilePermissionExtImpl(this.context);
    return this.filePermissionExtImpl;
  }
}
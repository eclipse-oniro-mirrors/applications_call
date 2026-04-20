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
import { MigrationConstant, MigrationRecordStatus, MigrationStatus } from '../constant/MigrationConstant';
import { RPCInfoConstant } from '../constant/RPCInfoConstant';

@Sendable
export class MigrationRecord {
  public id?: number;
  public displayName: string = '';
  public oriUri: string = '';
  public newUri: string = '';
  public recorderAdded: number = 0;
  public hasTransfer: number = MigrationRecordStatus.NOT_MIGRATED; // 0:未迁移,1:已迁移,2:全部已迁移(用于标记)
  public tryTimes: number = 0;
}

@Sendable
export class MigrationProgress {
  public total: number = MigrationConstant.INIT_VALUE;
  public completedCount: number = 0;
  public failedCount: number = 0;
  public name: string = '';
  public createdAt: number = 0;
  public originPath: string = '';
  public newPath: string = '';
  public lastStatus: number = MigrationStatus.INVALID; // default:-1, success:0, fail:1
  public lastFailCode: number = MigrationStatus.INVALID;
}

export class MigrationResult {
  public message: string = RPCInfoConstant.SUCCESS_STATUS_MESSAGE;
  public errCode: number = RPCInfoConstant.SUCCESS_STATUS_CODE;

  public setInternalError(): void {
    this.errCode = RPCInfoConstant.INTERNAL_ERROR_CODE;
    this.message = RPCInfoConstant.INTERNAL_ERROR_MESSAGE;
  }

  public setSpaceError(): void {
    this.errCode = RPCInfoConstant.SPACE_ERROR_CODE;
    this.message = RPCInfoConstant.SPACE_ERROR_MESSAGE;
  }
}
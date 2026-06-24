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
export class RecordLogObjectStruct {
  public filePath: string = '';
  public duration?: string = '';
  public displayName?: string = '';
  public dateAdded?: number = 0;
  public title?: string = '';
}

export class TableUseStruct {
  public RECORD_DATABASE: string = '';
  public RECORD_CONFIG_SQL?: string = '';
  public RECORD_CONTACT_SQL?: string = '';
  public RECORD_LOG_SQL?: string = '';
  public RECORD_MIGRATION_SQL?: string = '';
}

export class FuncManageReturn {
  public message?: string = '';
  public designateNumberStatus?: boolean = false;
  public errCode?: number = 0;
}

@Sendable
export class RecordLog {
  public filePath: string = '';
  public duration: number = 0;
  public displayName: string = '';
  public dateAdded: number = 0;
  public title: string = '';
  public phoneNumber: string = '';
  public recorderAdded: number = -1;
  public mode: number = 1;
}

export class RecordContactDataStruct {
  public phoneNumber: string = '';
  public name?: string = ' ';
}

export class UriUseClass {
  public dbUse: string = '';
  public tableUse: string = '';
  public type: string = '';
}
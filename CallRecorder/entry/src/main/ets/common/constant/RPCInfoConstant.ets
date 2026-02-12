/*
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
export class RPCInfoConstant {

  public static VALIDATE_STRING = 'MigrationService';

  // Success Status CODE
  public static SUCCESS_STATUS_CODE: number = 0;
  // No Storage Status CODE
  public static NO_STORAGE_STATUS_CODE: number = 100;
  // Unknown Error Status CODE
  public static UNKNOWN_STATUS_CODE: number = 400;

  public static TOKEN_ERROR_CODE: number = 401;
  // file permission change status code
  public static PARAM_ERROR_CODE: number = 402;

  public static DIR_ERROR_CODE: number = 403;

  public static FILE_ERROR_CODE: number = 404;

  public static ACTION_ERROR_CODE: number = 405;

  public static FORBIDDEN_ERROR_CODE: number = 501;

  public static INTERNAL_ERROR_CODE: number = 502;

  public static SPACE_ERROR_CODE: number = 1000;
  // Success Message
  public static SUCCESS_STATUS_MESSAGE: string = 'success';
  // No Storage Message
  public static NO_STORAGE_STATUS_MESSAGE: string = 'no storage recorder';
  // Manual Recording Message
  public static MANUAL_RECORDING_MESSAGE: string = 'manual recording';
  // Meeting Recording Message
  public static MEETING_RECORDING_MESSAGE: string = 'meeting recording';
  // Unknown Recording Message
  public static UNKNOWN_RECORDING_MESSAGE: string = 'unknown recording';

  public static TOKEN_ERROR_MESSAGE: string = 'token error';
  // file permission change message
  public static PARAM_ERROR_MESSAGE: string = 'param error';

  public static DIR_ERROR_MESSAGE: string = 'call recorder dir invalid';

  public static FILE_ERROR_MESSAGE: string = 'there is no recording file';

  public static ACTION_ERROR_MESSAGE: string = 'file permission change error';

  public static FILE_PERMISSION_VALIDATE_STRING = 'idl.FilePermission';

  public static FORBIDDEN_ERROR_MESSAGE: string = 'forbidden request error';

  public static INTERNAL_ERROR_MESSAGE: string = 'internal error';

  public static SPACE_ERROR_MESSAGE: string = 'space not enough';
}
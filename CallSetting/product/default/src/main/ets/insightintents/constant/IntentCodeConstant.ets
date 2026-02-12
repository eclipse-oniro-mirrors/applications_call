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

export class IntentCodeConstants {
  public static readonly DEFAULT_CODE_SUCCESS = 0;
  public static readonly DEFAULT_CODE_FAILED = 10010001;
  public static readonly DEFAULT_CODE_UNSUPPORTED = 10011003;
  public static readonly LIMITED_BY_AIRPLANE_MODE = 10010018;
  public static readonly NO_SIM_CARD = 10010020;
  public static readonly MOBILE_DATA_CODE_UNSUPPORT = 10010003;
}

export const ERROR_MSG: Record<number, string> = {
  0: 'Execution succeeded.',
  10010001: 'Execution failed.',
  10011003: 'Not supported by the device',
  10010018: 'The device is in airplane mode and cannot be used.',
  10010020: 'Cannot perform the operation because the device does not have a SIM card.'
}
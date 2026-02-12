/**
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

//call_record.db dataShare request base address
export const RECORDER_DATA_SHARE_URL: string = 'datashare:///com.ohos.callrecorder.datashareAbility';

//call_record.db record_config table request address
export const RECORD_CONFIG: string = '/call_record/record_config';

//call_record.db record_contact table request address
export const RECORD_CONTACT: string = '/call_record/record_contact';

//callRecorder.hap bundleName
export const RECORD_BUNDLE_NAME: string = 'com.ohos.callrecorder';

//callRecorder.hap service abilityName
export const RECORD_SERVICE_ABILITY_NAME: string = 'com.ohos.callrecorder.CallRecorderServiceExtensionAbility';

// No Storage Status CODE
export const NO_STORAGE_STATUS_CODE: number = 100;

// Unknown Error Status CODE
export const UNKNOWN_STATUS_CODE: number = 400;

// AppStorage recorderStatus start
export const RECORDER_START_STATUS: string = 'start';

// AppStorage recorderStatus disabled
export const RECORDER_DISABLED_STATUS: string = 'disabled';

// AppStorage recorderStatus stop
export const RECORDER_STOP_STATUS: string = 'stop';

// All recordings
export const RECORDING_WAY_ALL_NUMBER: string = '1';


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

interface RecordInputData {
  accountNumber: string;
  mode: number;
  startTime?: number;
  callList?: Array<string>;
  callTimeList?: Array<string>;
}

export interface IIdlServiceExt {
  recordingStop(data: number, callback: StopRecordingCallBack): void;

  recordingStart(params: RecordInputData, callback: StartRecordingCallBack): void;

  recordingGetIsError(callback: RecordingGetIsErrorCallBack): void;
}

export type StopRecordingCallBack = (errCode: number, returnValue: string) => void;

export type StartRecordingCallBack = (code: number, message: string) => void;

export type RecordingGetIsErrorCallBack = (code: number, message: string) => void;
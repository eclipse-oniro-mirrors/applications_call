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
import { call } from '@kit.TelephonyKit';
import LogUtils from './LogUtils';

const TAG = 'CallUiEvent';

export class CallUiEvent {
  private static instance: CallUiEvent;
  private lastCallId: number = -1;

  private constructor() {
  }

  public static getInstance(): CallUiEvent {
    if (!CallUiEvent.instance) {
      CallUiEvent.instance = new CallUiEvent();
    }
    return CallUiEvent.instance;
  }

  public send(callId: number, eventName: string): void {
    if (this.lastCallId === callId) {
      return;
    }
    this.lastCallId = callId;
    try {
      call.sendCallUiEvent(callId, eventName);
    } catch (err) {
      LogUtils.e(TAG, `send callui event fail: ${err.code}`);
    }
  }
}
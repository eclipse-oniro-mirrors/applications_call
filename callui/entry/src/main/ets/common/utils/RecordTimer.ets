/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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
import CallDataManager from '../../model/CallDataManager';
import CallTimeListStruct from '../struct/CallTimeListStruct';

import LogUtils from './LogUtils';
import Recording from './Recording';
import Utils from './utils';

const TAG = 'RecordTimer';

export default class RecordTimer {
  /**
   * start text
   */
  public static TIMER_START_TEXT: string = '00:00';
  /**
   * instance
   */
  private static sInstance: RecordTimer;
  private isRecording: boolean = false;
  private timerId: number = -1;
  private timerCallback: Function | undefined;
  private timerText: string = RecordTimer.TIMER_START_TEXT;
  private autoTimerCallback: Function | undefined;

  static getInstance() {
    if (!RecordTimer.sInstance) {
      RecordTimer.sInstance = new RecordTimer();
    }
    return RecordTimer.sInstance;
  }

  startTimer(callback: (count: string) => void) {
    let autoRecord: boolean | undefined = AppStorage.get('autoRecordCall');
    LogUtils.i(TAG, `startTimer: autoRecord=${autoRecord}`);
    callback(this.timerText);
    let startTimestamp: number | undefined = AppStorage.get('recordStartTime');
    if (!startTimestamp) {
      this.timerText = RecordTimer.TIMER_START_TEXT;
    } else {
      let timerCount: number = Math.floor(new Date().getTime() - startTimestamp);
      this.timerText = Utils.getInstance().formatTime(timerCount);
    }
    callback(this.timerText);
    this.timerCallback = callback;
    if (autoRecord) {
      this.startTimerAuto();
    } else {
      this.startTimerManual();
    }
  }

  startTimerAuto() {
    if (this.autoTimerCallback && CallDataManager.getInstance().hasTimeUpdateCallback(this.autoTimerCallback)) {
      LogUtils.i(TAG, `startTimerAuto: callTimeListener has been added`);
      return;
    }
    this.autoTimerCallback = (callTimeList: Array<CallTimeListStruct>) => {
      if (callTimeList.length === 0) {
        return;
      }
      let recordCallId = Recording.getInstance().getRecordCallId();
      let callDuration: string = '';
      for (let i = 0; i < callTimeList.length; i++) {
        let callId: number = callTimeList[i].callId;
        if (callId === recordCallId && CallDataManager.getInstance().isActiveCall(callId)) {
          callDuration = callTimeList[i].callTime;
          break;
        }
      }
      if (!callDuration) {
        return;
      }
      this.timerText = callDuration;
      if (!this.timerCallback) {
        return;
      }
      this.timerCallback(this.timerText);
    }
    CallDataManager.getInstance().addTimeUpdateCallback(this.autoTimerCallback);
    LogUtils.i(TAG, `startTimerAuto: succeed`);
  }

  startTimerManual() {
    let intervalCallback: Function = () => {
      let startTimestamp: number | undefined = AppStorage.get('recordStartTime');
      if (!startTimestamp) {
        return;
      }
      let timerCount: number = Math.floor(new Date().getTime() - startTimestamp);
      this.timerText = Utils.getInstance().formatTime(timerCount);
      if (!this.timerCallback) {
        return;
      }
      this.timerCallback(this.timerText);
    };
    this.startInterval(intervalCallback);
    this.isRecording = true;
    LogUtils.i(TAG, `startTimerManual: succeed`);
  }

  stopTimer() {
    if (this.autoTimerCallback && CallDataManager.getInstance().hasTimeUpdateCallback(this.autoTimerCallback)) {
      CallDataManager.getInstance().removeTimeUpdateCallback(this.autoTimerCallback);
      this.autoTimerCallback = undefined;
      LogUtils.i(TAG, `stopTimer: stopAutoTimer`);
    }
    this.timerId = -1;
    this.isRecording = false;
    this.timerCallback = undefined;
    this.timerText = RecordTimer.TIMER_START_TEXT;
    LogUtils.i(TAG, `stopTimer: succeed`);
  }

  startInterval(handler: Function) {
    if (this.timerId) {
      clearTimeout(this.timerId);
    }
    this.timerId = setTimeout(() => {
      if (!this.isRecording) {
        clearTimeout(this.timerId);
        return;
      }
      handler();
      this.startInterval(handler);
    }, 1000);
  }

  removeTimerCallback() {
    this.timerCallback = undefined;
    if (this.timerId) {
      clearTimeout(this.timerId);
    }
  }
}
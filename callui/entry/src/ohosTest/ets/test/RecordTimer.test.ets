/**
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

import { describe, it, expect, MockKit, when, ArgumentMatchers } from '@ohos/hypium';
import LogUtils from '../../../main/ets/common/utils/LogUtils';
import RecordTimer from '../../../main/ets/common/utils/RecordTimer';
import Utils from '../../../main/ets/common/utils/utils';
import CallDataManager from '../../../main/ets/model/CallDataManager';

let RecordTimerTest_startTimer_autoRecordCall_true_TimeUpdateCallback_true = () => {
  let mocker: MockKit = new MockKit();
  let mockfunc: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockfunc)('autoRecordCall').afterReturn(true);
  let mockHasTimeUpdateCallback: Function = mocker.mockFunc(CallDataManager, CallDataManager.getInstance()
    .hasTimeUpdateCallback);
  when(mockHasTimeUpdateCallback)(ArgumentMatchers.any).afterReturn(true);
  let timer: RecordTimer = RecordTimer.getInstance();
  let recordBtnText = '';
  let recordTimerCallback = (text: string) => {
    recordBtnText = 'test';
  };
  timer.startTimer(recordTimerCallback);
  expect(recordBtnText).assertEqual('test');
  timer.startTimer(recordTimerCallback);
  expect(recordBtnText).assertEqual('test');
  timer.stopTimer();
  expect(recordBtnText).assertEqual('test');
  mocker.clear(AppStorage);
}

let RecordTimerTest_startTimer_autoRecordCall_true_TimeUpdateCallback_false = () => {
  let mocker: MockKit = new MockKit();
  let mockfunc: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockfunc)('autoRecordCall').afterReturn(true);
  let mockHasTimeUpdateCallback: Function = mocker.mockFunc(CallDataManager, CallDataManager.getInstance()
    .hasTimeUpdateCallback);
  when(mockHasTimeUpdateCallback)(ArgumentMatchers.any).afterReturn(false);
  let timer: RecordTimer = RecordTimer.getInstance();
  let recordBtnText = '';
  let recordTimerCallback = (text: string) => {
    recordBtnText = 'test';
  };
  timer.startTimer(recordTimerCallback);
  expect(recordBtnText).assertEqual('test');
  timer.stopTimer();
  expect(recordBtnText).assertEqual('test');
  mocker.clear(AppStorage);
}

let RecordTimerTest_startTimer_startTimer_autoRecordCall_false = () => {
  let mocker: MockKit = new MockKit();
  let mockfunc: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockfunc)('autoRecordCall').afterReturn(false);
  when(mockfunc)('recordStartTime').afterReturn(true);
  let timer: RecordTimer = RecordTimer.getInstance();
  let recordBtnText = '';
  let recordTimerCallback = (text: string) => {
    recordBtnText = 'test';
  };
  timer.startTimer(recordTimerCallback);
  expect(recordBtnText).assertEqual('test');
  timer.startTimer(recordTimerCallback);
  expect(recordBtnText).assertEqual('test');
  timer.stopTimer();
  timer.removeTimerCallback();
  expect(recordBtnText).assertEqual('test');
  mocker.clear(AppStorage);
}

export default function RecordTimerTest() {
  describe('RecordTimerTest', () => {
    it('startTimer_autoRecordCall_true_TimeUpdateCallback_true', 0, () => {
      RecordTimerTest_startTimer_autoRecordCall_true_TimeUpdateCallback_true();
    })
    it('startTimer_autoRecordCall_true_TimeUpdateCallback_false', 0, () => {
      RecordTimerTest_startTimer_autoRecordCall_true_TimeUpdateCallback_false();
    })
    it('startTimer_autoRecordCall_false', 0, () => {
      RecordTimerTest_startTimer_startTimer_autoRecordCall_false();
    })

    it('should_start_timer_manual_and_call_timerCallback_when_timerCallback_is_not_null', 0, async () => {
      let recordTimer: RecordTimer = RecordTimer.getInstance();
      let mocker: MockKit = new MockKit();

      let mockFormatTime: Function = mocker.mockFunc(Utils.getInstance(), Utils.getInstance().formatTime);
      when(mockFormatTime)([ArgumentMatchers.anyNumber]).afterReturn("00:00:00");

      let mockStartInterval: Function = mocker.mockFunc(recordTimer, recordTimer.startInterval);
      when(mockStartInterval)([ArgumentMatchers.anyFunction]).afterReturnNothing();

      let mockLogUtils: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockLogUtils)([ArgumentMatchers.anyString, ArgumentMatchers.anyString]).afterReturnNothing();

      recordTimer.startTimerManual();
      let result: string = (recordTimer as object)['timerText'];
      expect(result !== null).assertTrue();

      mocker.ignoreMock(Utils.getInstance(), Utils.getInstance().formatTime);
      mocker.ignoreMock(recordTimer, recordTimer.startInterval);
      mocker.ignoreMock(LogUtils, LogUtils.i);
    });

    it('should_start_timer_manual_and_not_call_timerCallback_when_timerCallback_is_null', 0, async () => {
      let recordTimer: RecordTimer = RecordTimer.getInstance();
      let mocker: MockKit = new MockKit();

      let mockFormatTime: Function = mocker.mockFunc(Utils.getInstance(), Utils.getInstance().formatTime);
      when(mockFormatTime)([ArgumentMatchers.anyNumber]).afterReturn("00:00:00");

      let mockStartInterval: Function = mocker.mockFunc(recordTimer, recordTimer.startInterval);
      when(mockStartInterval)([ArgumentMatchers.anyFunction]).afterReturnNothing();

      let mockLogUtils: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockLogUtils)([ArgumentMatchers.anyString, ArgumentMatchers.anyString]).afterReturnNothing();

      recordTimer.startTimerManual();
      let result: string = (recordTimer as object)['timerText'];
      expect(result !== null).assertTrue();

      mocker.ignoreMock(Utils.getInstance(), Utils.getInstance().formatTime);
      mocker.ignoreMock(recordTimer, recordTimer.startInterval);
      mocker.ignoreMock(LogUtils, LogUtils.i);
    });

    it('should_not_start_timer_manual_when_startTimestamp_is_undefined', 0, async () => {
      let recordTimer: RecordTimer = RecordTimer.getInstance();
      let mocker: MockKit = new MockKit();

      let mockFormatTime: Function = mocker.mockFunc(Utils.getInstance(), Utils.getInstance().formatTime);
      when(mockFormatTime)([ArgumentMatchers.anyNumber]).afterReturn("00:00:00");

      let mockStartInterval: Function = mocker.mockFunc(recordTimer, recordTimer.startInterval);
      when(mockStartInterval)([ArgumentMatchers.anyFunction]).afterReturnNothing();

      let mockLogUtils: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockLogUtils)([ArgumentMatchers.anyString, ArgumentMatchers.anyString]).afterReturnNothing();

      AppStorage.set('recordStartTime', undefined);

      recordTimer.startTimerManual();
      let result: string = (recordTimer as object)['timerText'];
      expect(result !== null).assertTrue();

      mocker.ignoreMock(Utils.getInstance(), Utils.getInstance().formatTime);
      mocker.ignoreMock(recordTimer, recordTimer.startInterval);
      mocker.ignoreMock(LogUtils, LogUtils.i);
    });
  })
}
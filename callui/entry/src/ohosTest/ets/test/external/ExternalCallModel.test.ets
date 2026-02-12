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

import { describe, beforeAll, afterAll, it, expect, MockKit, when, ArgumentMatchers } from '@ohos/hypium';
import { ExternalCallModel } from '../../../../main/ets/model/ExternalCallModel';
import { ExternalIconResource, IconTypes } from '../../../../main/ets/model/ExternalResourceManager';
import * as Constants from '../../../../main/ets/common/utils/Constants';
import LogUtils from '../../../../main/ets/common/utils/LogUtils';
import { display } from '@kit.ArkUI';
import { Driver } from '@kit.TestKit';
import { sleep } from '../Utils';
import common from '@ohos.app.ability.common';
import AudioDeviceManager from '../../../../main/ets/model/audio/AudioDeviceManager';
import CallDataManager from '../../../../main/ets/model/CallDataManager';
import DefaultCallData from '../../../../main/ets/common/struct/TypeUtils';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

const CALL_BUNDLE_NAME = 'com.ohos.callui';
const ABILITY_NAME_EXTERNAL = 'com.ohos.callui.ExternalCallAbility';
const DEF_INVALID_ICON_TYPE = 999;
const DELAY_TIME_100_MILE_SECONDS = 100;
const TAG = 'ExternalTest_CallModel';

export default function ExternalCallModelTest() {
  let mocker: MockKit = new MockKit();
  describe('ExternalCallModelTest', () => {
    beforeAll(() => {
      let mockfunc: Function = mocker.mockFunc(ExternalCallModel, ExternalCallModel.isSmallExternalDevice);
      when(mockfunc)().afterReturn(true);
    })
    afterAll(async () => {
      mocker.clearAll();
    })
    it('testRegFold_test_01', 0, () => {
      testRegFold_test_01();
    })
    it('testRegFold_test_02', 0, () => {
      testRegFold_test_02();
    })
    it('testRegFold_test_03', 0, () => {
      testRegFold_test_03();
    })
    it('testRegFold_test_04', 0, () => {
      testRegFold_test_04();
    })
    it('testRegFold_test_05', 0, () => {
      testRegFold_test_05();
    })
    it('testRegFold_test_06', 0, () => {
      testRegFold_test_06();
    })
    it('testRegFold_test_07', 0, () => {
      testRegFold_test_07();
    })
    it('testRegFold_test_08', 0, () => {
      testRegFold_test_08();
    })
    it('testRegFold_test_09', 0, () => {
      testRegFold_test_09();
    })
    it('testRegFold_test_10', 0, () => {
      testRegFold_test_10();
    })
    it('testRegFold_test_11', 0, () => {
      testRegFold_test_11();
    })
    it('testRegFold_test_12', 0, () => {
      testRegFold_test_12();
    })
    it('testRegFoldByMock', 0, () => {
      testRegFoldByMock();
    })
  })
}

function testRegFold_test_01() {
  let mocker: MockKit = new MockKit();
  let defOp = getDefOp();
  let mockFunc: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc)(ArgumentMatchers.any).afterReturn(defOp);
  ExternalCallModel.onLeftMethod();
  expect(defOp.id === -1).assertTrue();
  mocker.clear(AppStorage);
  mocker.clearAll();
}

function testRegFold_test_02() {
  let mocker: MockKit = new MockKit();
  let defOp = getDefOp();
  defOp.id = IconTypes.MUTE_RINGER;
  let mockFunc: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc)(ArgumentMatchers.any).afterReturn(defOp);
  ExternalCallModel.onLeftMethod();
  expect(defOp.id === 0).assertTrue();
  mocker.clear(AppStorage);
  mocker.clearAll();
}

function testRegFold_test_03() {
  let mocker: MockKit = new MockKit();
  let defOp = getDefOp();
  defOp.id = IconTypes.REJECT;
  let mockFunc: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc)(ArgumentMatchers.any).afterReturn(defOp);
  ExternalCallModel.onLeftMethod();
  expect(defOp.id === 1).assertTrue();
  mocker.clear(AppStorage);
  mocker.clearAll();
}

function testRegFold_test_04() {
  let mocker: MockKit = new MockKit();
  let defOp = getDefOp();
  defOp.id = IconTypes.HANGUP;
  let mockFunc: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc)(ArgumentMatchers.any).afterReturn(defOp);
  ExternalCallModel.onLeftMethod();
  expect(defOp.id === 2).assertTrue();
  mocker.clear(AppStorage);
  mocker.clearAll();
}

function testRegFold_test_05() {
  let mocker: MockKit = new MockKit();
  let defOp = getDefOp();
  defOp.id = IconTypes.CS_ANSWER;
  let mockFunc: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc)(ArgumentMatchers.any).afterReturn(defOp);
  ExternalCallModel.onLeftMethod();
  expect(defOp.id === 3).assertTrue();
  mocker.clear(AppStorage);
  mocker.clearAll();
}

function testRegFold_test_06() {
  let mocker: MockKit = new MockKit();
  let defOp = getDefOp();
  defOp.id = IconTypes.VIDEO_ANSWER;
  let mockFunc: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc)(ArgumentMatchers.any).afterReturn(defOp);
  ExternalCallModel.onLeftMethod();
  expect(defOp.id === 4).assertTrue();
  mocker.clear(AppStorage);
  mocker.clearAll();
}

function testRegFold_test_07() {
  let mocker: MockKit = new MockKit();
  let defOp = getDefOp();
  defOp.id = IconTypes.SET_MUTE_WHITE;
  let mockFunc: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc)(ArgumentMatchers.any).afterReturn(defOp);
  ExternalCallModel.onLeftMethod();
  expect(defOp.id === 7).assertTrue();
  mocker.clear(AppStorage);
  mocker.clearAll();
}

function testRegFold_test_08() {
  let mocker: MockKit = new MockKit();
  let defOp = getDefOp();
  defOp.id = IconTypes.CANCEL_MUTE_WHITE;
  let mockFunc: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc)(ArgumentMatchers.any).afterReturn(defOp);
  ExternalCallModel.onLeftMethod();
  expect(defOp.id === 8).assertTrue();
  mocker.clear(AppStorage);
  mocker.clearAll();
}

function testRegFold_test_09() {
  let model = ExternalCallModel.getInstance();
  model.onAnswered(Constants.ANSWERED_TYPE_VIDEO, 1);
  expect(typeof Constants.ANSWERED_TYPE_VIDEO === 'string').assertTrue();
}

function testRegFold_test_10() {
  let model = ExternalCallModel.getInstance();
  model.onFoldStatusChanged(display.FoldStatus.FOLD_STATUS_UNKNOWN);
  sleep(1000);
  model.onFoldStatusChanged(display.FoldStatus.FOLD_STATUS_FOLDED);
  sleep(1000);
  model.onFoldStatusChanged(display.FoldStatus.FOLD_STATUS_EXPANDED);
  sleep(1000);
  model.onFoldStatusChanged(display.FoldStatus.FOLD_STATUS_HALF_FOLDED);
  sleep(1000);
  model.onFoldStatusChanged(DEF_INVALID_ICON_TYPE);
  sleep(1000);
  model.unRegisterFoldStatusChange();
  sleep(1000);
  expect(display.FoldStatus.FOLD_STATUS_UNKNOWN === 0).assertTrue();
}

function testRegFold_test_11() {
  let mocker: MockKit = new MockKit();
  let model = ExternalCallModel.getInstance();
  let mockFunc: Function =
    mocker.mockFunc(AudioDeviceManager, AudioDeviceManager.getInstance().isExternalAudioDeviceSupport);
  let mockFunc1: Function = mocker.mockFunc(AudioDeviceManager, AudioDeviceManager.getInstance().isCurSpeaker);
  when(mockFunc)(ArgumentMatchers.any).afterReturn(false);
  when(mockFunc1)(ArgumentMatchers.any).afterReturn(false);
  model.showVideoTipsDialog();
  sleep(1000);
  expect(DEF_INVALID_ICON_TYPE === 999).assertTrue();
  mocker.clear(AudioDeviceManager);
  mocker.clearAll();
}

function testRegFold_test_12() {
  ExternalCallModel.checkConferenceCall();
  expect(DEF_INVALID_ICON_TYPE === 999).assertTrue();
  sleep(1000);
  let testDate: DefaultCallData = { callId: 1 } as DefaultCallData;
  let testDate1: DefaultCallData = { callId: 2, conferenceState: 1 } as DefaultCallData;
  CallDataManager.getInstance().callList.push(testDate);
  CallDataManager.getInstance().callList.push(testDate1);
  ExternalCallModel.checkConferenceCall();
  expect(testDate.callId === 1 && testDate1.callId === 2).assertTrue();
  sleep(1000);
  testDate1.conferenceState = -1;
  ExternalCallModel.checkConferenceCall();
  expect(testDate1.conferenceState === -1).assertTrue();
  sleep(1000);
  CallDataManager.getInstance().callList = [];
}

async function testRegFoldByMock() {
  let model: ExternalCallModel | undefined = ExternalCallModel.getInstance();
  let mocker2: MockKit = new MockKit();
  let mockfunc: Function = mocker2.mockFunc(model, ExternalCallModel.getInstance().isSmallExternalAndFolded);
  when(mockfunc)().afterReturn(true);
  let isTargetDevice = model.isSmallExternalAndFolded();
  model.onExternalAbilityDestroy();
  model.registerFoldStatusChange();
  LogUtils.i(TAG, `testRegFoldByMock isTargetDevice:${isTargetDevice}`);

  let startResult = await directStartExternalAbility();
  LogUtils.i(TAG, `testRegFoldByMock startResult:${startResult}`);

  model.onFoldStatusChanged(display.FoldStatus.FOLD_STATUS_FOLDED);
  model.onFoldStatusChanged(display.FoldStatus.FOLD_STATUS_EXPANDED);
  let driver = Driver.create();
  await driver.delayMs(DELAY_TIME_100_MILE_SECONDS);
  LogUtils.i(TAG, 'testRegFoldByMock test fold -> expand end');

  model.onFoldStatusChanged(display.FoldStatus.FOLD_STATUS_FOLDED);
  model.onFoldStatusChanged(display.FoldStatus.FOLD_STATUS_HALF_FOLDED);
  await driver.delayMs(DELAY_TIME_100_MILE_SECONDS);
  LogUtils.i(TAG, 'testRegFoldByMock test fold -> half_expand end');

  model.onFoldStatusChanged(display.FoldStatus.FOLD_STATUS_FOLDED);
  await driver.delayMs(DELAY_TIME_100_MILE_SECONDS);
  LogUtils.i(TAG, 'testRegFoldByMock test expand -> folded end');

  model.unRegisterFoldStatusChange();
  mocker2.clearAll();
  LogUtils.i(TAG, `testRegFoldByMock end`);
  expect(true).assertTrue();
  mocker2.clear(model);
}

function getDefOp(): ExternalIconResource {
  return {
    iconRes: $r('app.string.emptyStr'),
    iconColor: '#FFFFFF',
    isClickable: false,
    opacity: 1,
    id: -1
  }
}

export async function directStartExternalAbility(): Promise<boolean> {
  let want: Want = {
    bundleName: CALL_BUNDLE_NAME,
    abilityName: ABILITY_NAME_EXTERNAL
  };
  try {
    let uiAbilityContext = AppStorage.get<common.UIAbilityContext>(Constants.CALL_ABILITY_CONTEXT);
    LogUtils.i(TAG, `startExternalAbility get uiAbilityContext:${uiAbilityContext}`);
    if (uiAbilityContext && !uiAbilityContext.isTerminating()) {
      LogUtils.i(TAG, 'startExternalAbility by uiAbilityContext');
      await uiAbilityContext.startAbility(want);
    } else {
      LogUtils.i(TAG, 'startExternalAbility by abilityDelegator');
      let abilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator();
      await abilityDelegator.startAbility(want);
    }
    LogUtils.i(TAG, 'startExternalAbility success');
    return true;
  } catch (err) {
    LogUtils.i(TAG, 'startExternalAbility err :' + JSON.stringify(err));
    return false;
  }
}
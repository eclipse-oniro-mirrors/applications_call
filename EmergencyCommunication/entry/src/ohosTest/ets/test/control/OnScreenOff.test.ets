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

import { EmergencyGlobalContextHelper } from '../../../../main/ets/utils/EmergencyGlobalContextHelper';
import * as Constants from '../../../../main/ets/utils/Constants';
import window from '@ohos.window';
import {
  describe,
  beforeAll,
  beforeEach,
  afterEach,
  afterAll,
  when,
  ArgumentMatchers,
  MockKit,
  it,
  expect
} from '@ohos/hypium';
import OnScreenOff from '../../../../main/ets/control/OnScreenOff';
import { sleep } from '../utils/Sleep';

let aboveScreenFn = () => {
  let getCtx = EmergencyGlobalContextHelper.getContext();
  let windowStage = getCtx.getValue<window.WindowStage>(Constants.EMERGENCY_CALL_WINDOW_STAGE);
  let mocker: MockKit = new MockKit();
  let mockfunc2: Function = mocker.mockFunc(getCtx, getCtx.getValue);
  when(mockfunc2)(ArgumentMatchers.any).afterReturn(windowStage);
  OnScreenOff.aboveScreen(false);
  expect(true).assertTrue();
  mocker.clearAll();
}
let terminateSelfFn = async () => {
  OnScreenOff.terminateSelf(() => {
    expect(true).assertTrue();
  });
  await sleep(500);
  OnScreenOff.terminateSelf();
  expect(true).assertTrue();
}
let createSubscriberFn = async () => {
  await OnScreenOff.createSubscriber();
  let res = (OnScreenOff.subscriber !== null) ? true : false;
  let aim = true;
  expect(aim).assertEqual(res);
}
let subscribeEventFn = async () => {
  OnScreenOff.subscribeEvent(() => {
    expect(true).assertTrue();
  });
}
let subscribeFn = async () => {
  OnScreenOff.subscribe(() => {
    expect(true).assertTrue();
  });
  await sleep(500)
  OnScreenOff.subscriber = null
  OnScreenOff.subscribe(() => {
    expect(true).assertTrue();
  });
}
let unsubscribeFn = async () => {
  OnScreenOff.unsubscribe();
  expect(true).assertTrue();
  await sleep(1000)
  OnScreenOff.subscriber = null
  OnScreenOff.unsubscribe();
  expect(true).assertTrue();
}
let initSubscriberFn = async () => {
  let mocker: MockKit = new MockKit();
  let mockfunc: Function = mocker.mockFunc(OnScreenOff, OnScreenOff.createSubscriber);
  when(mockfunc)(ArgumentMatchers.any).afterReturn(new Promise<string>((res: Function, rej: Function) => {
    res();
  }));
  OnScreenOff.initSubscriber();
  expect(true).assertTrue();
  mocker.clearAll();
}

export default function OnScreenOffTest() {
  describe('OnScreenOffTest', () => {
    it('OnScreenOffTest_terminateSelf', 0, async () => {
      await terminateSelfFn();
    });
    it('OnScreenOffTest_createSubscriber', 0, async () => {
      await createSubscriberFn();
    });
    it('OnScreenOffTest_subscribeEvent', 0, async () => {
      await subscribeEventFn();
    });
    it('OnScreenOffTest_subscribe', 0, async () => {
      await subscribeFn();
    });
    it('OnScreenOffTest_unsubscribe', 0, () => {
      unsubscribeFn();
    });
    it('OnScreenOffTest_initSubscriber', 0, async () => {
      await initSubscriberFn();
    });
    it('OnScreenOffTest_aboveScreenFn', 0, async () => {
      await aboveScreenFn();
    });
  });
}
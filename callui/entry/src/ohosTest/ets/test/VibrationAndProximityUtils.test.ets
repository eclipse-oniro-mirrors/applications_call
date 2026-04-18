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

import { describe, it, expect } from '@ohos/hypium';
import { VibrationUtils } from '../../../main/ets/common/utils/VibrationUtils';
import audio from '@ohos.multimedia.audio';
import settings from '@ohos.settings';
import screenLock from '@ohos.screenLock';
import abilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import window from '@ohos.window';
import { GlobalContextHelper } from '../../../main/ets/common/utils/GlobalContextHelper';
import DefaultCallData from '../../../main/ets/common/struct/TypeUtils';
import { isScreenLocked } from '../../../main/ets/common/utils/DeviceTypeUtils';
import * as Constants from '../../../main/ets/common/utils/Constants';
import { BusinessError } from '@kit.BasicServicesKit';
import { ProximityUtils } from '../../../main/ets/common/utils/ProximityUtils';

let VibrationAndProximityUtilsTest_getRingerModeSuccess = () => {
  VibrationUtils.getInstance().getRingerMode((value: audio.AudioRingMode) => {
    expect(value).not().assertUndefined();
  })
}

let VibrationAndProximityUtilsTest_keepScreenOnSuccess = () => {
  let promise = screenLock.isSecureMode()
  promise.then(data => {
    if (data) {
      return;
    }
  })
  if (isScreenLocked()) {
    return;
  }
  const context = abilityDelegatorRegistry.getAbilityDelegator().getAppContext();
  if (!context) {
    return;
  }
  const screenTimeout = Number.parseInt(settings.getValueSync(context, settings.display.SCREEN_OFF_TIMEOUT, '-1'));
  if (screenTimeout <= 0) {
    return;
  }
  let isMinimize = ProximityUtils.minimize();
  expect(true).assertEqual(isMinimize);
}

let VibrationAndProximityUtilsTest_minimize = () => {
  const windowObj = AppStorage.get<window.Window>('testWindow');
  if (!windowObj) {
    return;
  }
  GlobalContextHelper.getContext().set<window.Window>(Constants.WINDOW, windowObj);
  let isMinimize = ProximityUtils.minimize();
  VibrationUtils.getInstance().getCallVolume((value: number) => {
  });
  ProximityUtils.keepScreenOn(false);
  VibrationUtils.getInstance().onceVibration();
  ProximityUtils.wakeUpScreen(true);
  expect(isMinimize).assertTrue();
}

let VibrationAndProximityUtilsTest_updateProximityLock_call_null = () => {
  let isMinimize = ProximityUtils.minimize();
  ProximityUtils.holdProximityLock();
  ProximityUtils.unHoldProximityLock();
  ProximityUtils.updateProximityLock();
  expect(isMinimize).assertEqual(true);
}

let VibrationAndProximityUtilsTest_updateProximityLock_call_incoming = () => {
  let isMinimize = ProximityUtils.minimize();
  let call: DefaultCallData = new DefaultCallData();
  call.callState = 4;
  ProximityUtils.updateProximityLock(call);
  expect(isMinimize).assertEqual(true);
}

let VibrationAndProximityUtilsTest_updateProximityLock_call_Disconnecting = () => {
  let isMinimize = ProximityUtils.minimize();
  let call: DefaultCallData = new DefaultCallData();
  call.callState = 7;
  ProximityUtils.updateProximityLock(call);
  expect(isMinimize).assertEqual(true);
}

let VibrationAndProximityUtilsTest_updateProximityLock_call_Disconnected = () => {
  let isMinimize = ProximityUtils.minimize();
  let call: DefaultCallData = new DefaultCallData();
  call.callState = 6;
  ProximityUtils.updateProximityLock(call);
  expect(isMinimize).assertEqual(true);
}

let VibrationAndProximityUtilsTest_updateProximityLock_call_Active = () => {
  let isMinimize = ProximityUtils.minimize();
  let call: DefaultCallData = new DefaultCallData();
  call.callState = 0;
  ProximityUtils.updateProximityLock(call);
  expect(isMinimize).assertEqual(true);
}

let VibrationAndProximityUtilsTest_updateProximityLock_call_Active_video = () => {
  let isMinimize = ProximityUtils.minimize();
  let call: DefaultCallData = new DefaultCallData();
  call.callState = 0;
  call.videoState = 3;
  ProximityUtils.updateProximityLock(call);
  expect(isMinimize).assertEqual(true);
}

let VibrationAndProximityUtilsTest_findInfraredProximitySensor = () => {
  ProximityUtils.findInfraredProximitySensor();
  const err: BusinessError = {
    code: 0,
    name: '',
    message: ''
  };
  ProximityUtils.findInfraredProximitySensor(err);
  expect(ProximityUtils.isInfraredProximitySensor()).assertTrue();
}

export default function VibrationAndProximityUtilsTest() {
  describe('VibrationAndProximityUtilsTest', () => {
    it('getRingerModeSuccess', 0, () => {
      VibrationAndProximityUtilsTest_getRingerModeSuccess();
    })
    it('minimize_undefined', 0, async () => {
      let test = GlobalContextHelper.getContext().getValue<window.Window>('test');
      GlobalContextHelper.getContext().set<window.Window>('window', test);
      let isMinimize = ProximityUtils.minimize();
      expect(isMinimize).assertFalse()
    })
    it('minimize', 0, async () => {
      VibrationAndProximityUtilsTest_minimize();
    })
    it('updateProximityLock_call_null', 0, async () => {
      VibrationAndProximityUtilsTest_updateProximityLock_call_null();
    })
    it('updateProximityLock_call_incoming', 0, async () => {
      VibrationAndProximityUtilsTest_updateProximityLock_call_incoming();
    })
    it('updateProximityLock_call_Disconnecting', 0, async () => {
      VibrationAndProximityUtilsTest_updateProximityLock_call_Disconnecting();
    })
    it('updateProximityLock_call_Disconnected', 0, async () => {
      VibrationAndProximityUtilsTest_updateProximityLock_call_Disconnected();
    })
    it('updateProximityLock_call_Active', 0, async () => {
      VibrationAndProximityUtilsTest_updateProximityLock_call_Active();
    })
    it('updateProximityLock_call_Active_video', 0, async () => {
      VibrationAndProximityUtilsTest_updateProximityLock_call_Active_video();
    })
    it('updateProximityLock_findInfraredProximitySensor', 0, async () => {
      VibrationAndProximityUtilsTest_findInfraredProximitySensor();
    })
  })
}
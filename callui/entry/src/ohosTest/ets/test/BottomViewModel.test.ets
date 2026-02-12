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

import {
  describe,
  it,
  expect,
  MockKit,
  when,
  ArgumentMatchers
} from '@ohos/hypium';
import { AudioListItem } from '../../../main/ets/model/audio/AudioListItem';
import CallServiceProxy from '../../../main/ets/model/CallServiceProxy';
import BottomViewModel from '../../../main/ets/viewmodel/BottomViewModel';
import { AudioDevice } from '../../../main/ets/model/audio/AudioDeviceType';
import * as DeviceTypeConst from '../../../main/ets/common/constant/DeviceTypeConst';
import CallStateConst from '../../../main/ets/common/constant/CallStateConst';

let BottomViewModelTest_AudioDeviceListStruct_class = () => {
  let device = new AudioDevice();
  device.deviceType = 1;
  expect(device.deviceType).assertEqual(1);
  expect(device.address).assertEqual('');
}

let BottomViewModelTest_hangUpCall = () => {
  let mBottomViewModel: BottomViewModel = BottomViewModel.getInstance();
  mBottomViewModel.hangUpCall(1, 1);
  expect(AppStorage.get('hangUp')).assertEqual(undefined)
  AppStorage.delete('hangUp');
  mBottomViewModel.hangUpCall(1, 2);
  expect(AppStorage.get('hangUp')).assertEqual(undefined);
  let mocker: MockKit = new MockKit();
  let mockfunc: Function = mocker.mockFunc(CallServiceProxy, CallServiceProxy.getInstance);
  when(mockfunc)(ArgumentMatchers.any).afterReturn(undefined);
  mBottomViewModel.hangUpCall(1, 2);
  expect(AppStorage.get('hangUp')).assertEqual(undefined);
}

let BottomViewModelTest_setButtonAudioDevice = () => {
  let isAutoOpenSpeaker: boolean | undefined = AppStorage.get('isAutoOpenSpeaker');
  AppStorage.setOrCreate('isAutoOpenSpeaker', true);
  let mBottomViewModel: BottomViewModel = BottomViewModel.getInstance();
  mBottomViewModel.currentAudioDevice.deviceType = 1;
  mBottomViewModel.setButtonAudioDevice(1);
  expect(AppStorage.get('isAutoOpenSpeaker')).assertEqual(true);
  mBottomViewModel.currentAudioDevice.deviceType = 0;
  mBottomViewModel.setButtonAudioDevice(1);
  expect(AppStorage.get('isAutoOpenSpeaker')).assertEqual(false);
  if (isAutoOpenSpeaker === undefined) {
    AppStorage.delete('isAutoOpenSpeaker');
  } else {
    AppStorage.setOrCreate('isAutoOpenSpeaker', isAutoOpenSpeaker);
  }
  mBottomViewModel.currentAudioDevice.deviceType = 1;
  mBottomViewModel.setButtonAudioDevice(1, CallStateConst.TYPE_SATELLITE);
  mBottomViewModel.setButtonAudioDevice(1,CallStateConst.TYPE_VOIP, true);
  mBottomViewModel.isHaveMultiDevice = true;
  mBottomViewModel.setButtonAudioDevice(1,CallStateConst.TYPE_VOIP, true);
  expect(mBottomViewModel.currentAudioDevice.deviceType).assertEqual(1);
}

let BottomViewModelTest_updateButtonIcon = () => {
  let mBottomViewModel: BottomViewModel = BottomViewModel.getInstance();
  mBottomViewModel.currentAudioDevice.deviceType = 1;
  mBottomViewModel.updateButtonIcon();
  expect(mBottomViewModel.speakerSelected).assertEqual(true);
  mBottomViewModel.currentAudioDevice.deviceType = 0;
  mBottomViewModel.updateButtonIcon();
  expect(mBottomViewModel.speakerSelected).assertEqual(false);
  mBottomViewModel.currentAudioDevice.deviceType = 2;
  mBottomViewModel.updateButtonIcon();
  expect(mBottomViewModel.speakerSelected).assertEqual(true);
  mBottomViewModel.currentAudioDevice.deviceType = 3;
  mBottomViewModel.updateButtonIcon();
  expect(mBottomViewModel.speakerSelected).assertEqual(false);
}

let BottomViewModelTest_isDistributeDevice = () => {
  let mBottomViewModel: BottomViewModel = BottomViewModel.getInstance();
  let ret0 = mBottomViewModel.isDistributeDevice(6);
  expect(ret0).assertEqual(true);
  let ret1 = mBottomViewModel.isDistributeDevice(7);
  expect(ret1).assertEqual(true);
  let ret3 = mBottomViewModel.isDistributeDevice(8);
  expect(ret3).assertEqual(true);
  let ret4 = mBottomViewModel.isDistributeDevice(0);
  expect(ret4).assertEqual(false);
}

let BottomViewModelTest_getMultiDeviceState_addMultiDeviceListener = () => {
  let mBottomViewModel: BottomViewModel = BottomViewModel.getInstance();
  mBottomViewModel.isHaveMultiDevice = true;
  let ret = mBottomViewModel.getMultiDeviceState();
  expect(ret).assertEqual(true)
  mBottomViewModel.addMultiDeviceListener((bol: boolean) => {
    ret = bol;
  });
  expect(ret).assertTrue();
}

let BottomViewModelTest_initCurrentAudioDevice = () => {
  let mBottomViewModel: BottomViewModel = BottomViewModel.getInstance();
  let list: AudioListItem[] = [{
    address: 'test1', deviceType: 2, isCheck: false, selectedIcon: $r('app.string.emptyStr')
  }, {
    address: 'test1', deviceType: 3, isCheck: false, selectedIcon: $r('app.string.emptyStr')
  }];
  mBottomViewModel.dataList = list;
  let device: AudioDevice = new AudioDevice();
  device.deviceType = 3;
  mBottomViewModel.initCurrentAudioDevice(device, true);
  expect(mBottomViewModel.currentAudioDevice.deviceType).assertEqual(3);
  device.deviceType = 2;
  mBottomViewModel.initCurrentAudioDevice(device, true);
  expect(mBottomViewModel.currentAudioDevice.deviceType).assertEqual(2);
  mBottomViewModel.initCurrentAudioDevice(device, false);
  expect(mBottomViewModel.currentAudioDevice.deviceType).assertEqual(2);
}

let BottomViewModelTest_updateMultiDevice = () => {
  let mBottomViewModel: BottomViewModel = BottomViewModel.getInstance();
  mBottomViewModel.isHaveMultiDevice = true;
  let device: AudioDevice = new AudioDevice();
  device.deviceType = 2;
  mBottomViewModel.initCurrentAudioDevice(device, true);
  expect(mBottomViewModel.currentAudioDevice.deviceType).assertEqual(2);
}

let BottomViewModelTest_initDataList = () => {
  let audioDeviceList: AudioDevice[] = [{
    deviceType: 2, address: '1234', deviceName: '12345'
  }, {
    deviceType: 1, address: '2345', deviceName: '23456'
  }, {
    deviceType: 3, address: '3456', deviceName: '34567'
  }, {
    deviceType: 6, address: '4567', deviceName: '45678'
  }];
  let mBottomViewModel: BottomViewModel = BottomViewModel.getInstance();
  mBottomViewModel.initDataList(audioDeviceList, true);
  expect(mBottomViewModel.isHaveMultiDevice).assertEqual(true);
  mBottomViewModel.currentAudioDevice.deviceType = 3;
  mBottomViewModel.initDataList(audioDeviceList, true);
  expect(mBottomViewModel.isHaveMultiDevice).assertEqual(true);
  mBottomViewModel.currentAudioDevice.deviceType = 6;
  mBottomViewModel.initDataList(audioDeviceList, true);
  expect(mBottomViewModel.isHaveMultiDevice).assertEqual(true);
  mBottomViewModel.initDataList(audioDeviceList, false);
  expect(mBottomViewModel.isHaveMultiDevice).assertEqual(false);
}

let BottomViewModelTest_getCurrentAudioDeviceAddress = () => {
  let mBottomViewModel: BottomViewModel = BottomViewModel.getInstance();
  let result = mBottomViewModel.getCurrentAudioDeviceType();
  expect(result === null).assertFalse();
}

export default function BottomViewModelTest() {
  describe('BottomViewModelTest', () => {
    it('AudioDeviceListStruct_class', 0, () => {
      BottomViewModelTest_AudioDeviceListStruct_class();
    })
    it('hangUpCall', 0, () => {
      BottomViewModelTest_hangUpCall();
    })
    it('setButtonAudioDevice', 0, () => {
      BottomViewModelTest_setButtonAudioDevice();
    })
    it('updateButtonIcon', 0, () => {
      BottomViewModelTest_updateButtonIcon();
    })
    it('isDistributeDevice', 0, () => {
      BottomViewModelTest_isDistributeDevice();
    })
    it('getMultiDeviceState_addMultiDeviceListener', 0, () => {
      BottomViewModelTest_getMultiDeviceState_addMultiDeviceListener();
    })
    it('initCurrentAudioDevice', 0, () => {
      BottomViewModelTest_initCurrentAudioDevice();
    })
    it('updateMultiDevice', 0, () => {
      BottomViewModelTest_updateMultiDevice();
    })
    it('initDataList', 0, () => {
      BottomViewModelTest_initDataList();
    })
    it('getCurrentAudioDeviceAddress', 0, () => {
      BottomViewModelTest_getCurrentAudioDeviceAddress();
    })
    it('removeIsCurEarpieceListenerTest', 0, () => {
      let mBottomViewModel: BottomViewModel = BottomViewModel.getInstance();
      mBottomViewModel.isHaveMultiDevice = true;
      let paramValue = () =>{};
      mBottomViewModel.removeIsCurEarpieceListener(paramValue);
      mBottomViewModel.addIsCurEarpieceListener(paramValue);
      mBottomViewModel.removeIsCurEarpieceListener(paramValue);
      expect(mBottomViewModel.isHaveMultiDevice).assertTrue();
    })
    it('setMapNavigationAudioDeviceTest', 0, () => {
      let mBottomViewModel: BottomViewModel = BottomViewModel.getInstance();
      mBottomViewModel.isHaveMultiDevice = true;
      mBottomViewModel.setMapNavigationAudioDevice();
      mBottomViewModel.currentAudioDevice.deviceType =  DeviceTypeConst.DEVICE_EARPIECE;
      mBottomViewModel.setMapNavigationAudioDevice();
      expect(mBottomViewModel.isHaveMultiDevice).assertTrue();
    })
  })
}
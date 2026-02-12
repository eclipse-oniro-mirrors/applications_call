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

import call from '@ohos.telephony.call';
import * as deviceTypeConst from '../../common/constant/DeviceTypeConst';
import LogUtils from '../../common/utils/LogUtils';

export interface audioObj {
  audioDeviceList: AudioDevice[]
  currentAudioDevice: AudioDevice
  activeBluetoothDevice: number
  isMuted: boolean
  callId?: number
}

export class AudioDevice {
  public deviceType: number = 0;
  public address: string = '';
  public deviceName: string = '';
}

export default class AudioDeviceType {
  public static audioDeviceType: audioObj = {
    /** Indicates the list of support audiodevice. */
    audioDeviceList: [{
      deviceType: deviceTypeConst.DEVICE_SPEAKER,
      address: '',
      deviceName: ''
    }],
    /** Indicates the type of current audiodevice. */
    currentAudioDevice: {
      deviceType: deviceTypeConst.DEVICE_EARPIECE,
      address: '',
      deviceName: ''
    },
    /** Indicates the current active bluetooth device. */
    activeBluetoothDevice: deviceTypeConst.DEVICE_SPEAKER,
    /** Indicates the status of mute. */
    isMuted: false,
    callId: -1
  };
}

export function audioDeviceInfoToString(audioDeviceInfo: call.AudioDeviceCallbackInfo) {
  let audioDeviceList = '';
  audioDeviceInfo.audioDeviceList.forEach((audioDevice: call.AudioDevice) => {
    audioDeviceList += audioDeviceToString(audioDevice) + ', '
  })
  let output = '{' +
    'isMuted: ' + audioDeviceInfo.isMuted +
    ', currentAudioDevice: ' + audioDeviceToString(audioDeviceInfo.currentAudioDevice) +
    ', audioDeviceList: [' + audioDeviceList +
    ']}';

  return output;
}

export function audioDeviceToString(device: call.AudioDevice) {
  return '{' +
    'deviceType: ' + device.deviceType +
    ', address: ' + LogUtils.toSafeAddressString(device.address) +
    ', deviceName: ' + device.deviceName +
    '}';
}
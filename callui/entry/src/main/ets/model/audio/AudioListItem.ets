/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import HashMap from '@ohos.util.HashMap';
import * as DeviceTypeConst from '../../common/constant/DeviceTypeConst';

export class AudioListItem {
  constructor() {
  }
  public audioIcon?: Resource;
  public audioTitle?: ResourceStr;
  public address: string = '';
  public deviceType: number = 1;
  public isCheck: boolean = false;
  public selectedIcon: Resource = $r('app.string.emptyStr');
}

export interface DeviceItemStyle {
  audioIcon: Resource,
  selectedIcon: Resource,
  audioTitle: Resource
}

export function initDeviceItemStyleMap(): HashMap<number, DeviceItemStyle> {
  let deviceItemStyleMap: HashMap<number, DeviceItemStyle> = new HashMap();
  deviceItemStyleMap.set(DeviceTypeConst.DEVICE_EARPIECE, {
    audioIcon: $r('sys.symbol.ear'),
    selectedIcon: $r('sys.symbol.ear'),
    audioTitle: $r('app.string.phoneHandset')
  });
  deviceItemStyleMap.set(DeviceTypeConst.DEVICE_SPEAKER, {
    audioIcon: $r('sys.symbol.speaker_wave_3_fill'),
    selectedIcon: $r('sys.symbol.speaker_wave_3_fill'),
    audioTitle: $r('app.string.speaker')
  });
  deviceItemStyleMap.set(DeviceTypeConst.DEVICE_WIRED_HEADSET, {
    audioIcon: $r('sys.symbol.earphone_16640_fill'),
    selectedIcon: $r('sys.symbol.earphone_16640_fill'),
    audioTitle: $r('app.string.wiredHeadset')
  });
  deviceItemStyleMap.set(DeviceTypeConst.DEVICE_BLUETOOTH_SCO, {
    audioIcon: $r('sys.symbol.bluetooth'),
    selectedIcon: $r('sys.symbol.bluetooth'),
    audioTitle: $r('app.string.blueetoothDevice')
  });
  deviceItemStyleMap.set(DeviceTypeConst.DEVICE_DISTRIBUTED_AUTOMOTIVE, {
    audioIcon: $r('sys.symbol.car'),
    selectedIcon: $r('sys.symbol.car'),
    audioTitle: $r('app.string.emptyStr')
  });
  deviceItemStyleMap.set(DeviceTypeConst.DEVICE_DISTRIBUTED_PHONE, {
    audioIcon: $r('sys.symbol.phone_1'),
    selectedIcon: $r('sys.symbol.phone_1'),
    audioTitle: $r('app.string.emptyStr')
  });
  deviceItemStyleMap.set(DeviceTypeConst.DEVICE_DISTRIBUTED_PAD, {
    audioIcon: $r('sys.symbol.pad'),
    selectedIcon: $r('sys.symbol.pad'),
    audioTitle: $r('app.string.emptyStr')
  });
  deviceItemStyleMap.set(DeviceTypeConst.DEVICE_DISTRIBUTED_XINGSHAN, {
    audioIcon: $r('sys.symbol.bluetooth'),
    selectedIcon: $r('sys.symbol.bluetooth'),
    audioTitle: $r('app.string.emptyStr')
  });
  deviceItemStyleMap.set(DeviceTypeConst.DEVICE_BLUETOOTH_HEARINGAID, {
    audioIcon: $r('sys.symbol.audiphonen'),
    selectedIcon: $r('sys.symbol.audiphonen'),
    audioTitle: $r('app.string.emptyStr')
  });
  return deviceItemStyleMap;
}
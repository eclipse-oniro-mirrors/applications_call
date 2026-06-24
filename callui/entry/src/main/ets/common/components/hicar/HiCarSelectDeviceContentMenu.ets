/**
 * Copyright (c) 2024-2024 Huawei Device Co., Ltd.
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
import { LengthUnit, SymbolGlyphModifier } from '@kit.ArkUI';
import { AudioListItem } from '../../../model/audio/AudioListItem';
import LogUtils from '../../utils/LogUtils';
import BluetoothDeviceManager from '../../../model/audio/AudioDeviceManager';
import { ReportUtil } from '../../utils/ReportUtils/ReportUtil';
import { audioDeviceToString } from '../../../model/audio/AudioDeviceType';
import Utils from '../../utils/utils';
import CallStateConst from '../../constant/CallStateConst';
import * as DeviceTypeConst from '../../constant/DeviceTypeConst';
import DefaultCallData from '../../struct/TypeUtils';
import { ReportDeviceType } from '../../utils/ReportUtils/ReportService';

const TAG = 'HiCarSelectDeviceContentMenu';

@Component
export struct HiCarSelectDeviceContentMenu {
  private callType?: number;
  private hideCallBack: () => void = () => {
  };
  @StorageLink('dataList') dataList: AudioListItem[] = [];

  private onAccept(itemDeviceType: call.AudioDeviceType, address: string): void {
    if (this.callType === CallStateConst.TYPE_SATELLITE &&
      itemDeviceType === DeviceTypeConst.DEVICE_EARPIECE) {
      Utils.getInstance().showToast($r('app.string.disableChangedToEarpiece'), 2000);
      return;
    }
    let audioDevice: call.AudioDevice = {
      deviceType: 0, address: ''
    };
    audioDevice.deviceType = itemDeviceType;
    audioDevice.address = address;
    LogUtils.i(TAG, 'onAccept device: ' + audioDeviceToString(audioDevice));
    BluetoothDeviceManager.getInstance().setAudioDevice(audioDevice);
    ReportUtil.getInstance().reportSwitchAudioRuteInCall(itemDeviceType, ReportDeviceType.HICAR);
  }

  build() {
    Menu() {
      ForEach(this.dataList, (item: AudioListItem) => {
        MenuItem({
          content: item.audioTitle,
          symbolStartIcon: new SymbolGlyphModifier(item.audioIcon)
            .fontSize(24)
            .fontColor([$r('sys.color.font_primary')]),
          symbolEndIcon: item.isCheck ? new SymbolGlyphModifier($r('sys.symbol.checkmark'))
            .fontSize(24)
            .fontColor([$r('sys.color.ohos_id_color_activated')]) : undefined
        })
          .contentFont({
            size: $r('sys.float.ohos_id_text_size_body1'),
            weight: FontWeight.Medium
          })
          .contentFontColor(item.isCheck ? $r('sys.color.font_emphasize') : $r('sys.color.font_primary'))
          .constraintSize({
            minWidth: 224
          })
          .onChange((selected: boolean) => {
            if (selected) {
              this.onAccept(item.deviceType, item.address);
            }
            this.hideCallBack();
          })
      })
    }
    .menuItemDivider({
      strokeWidth: {
        value: 1,
        unit: LengthUnit.VP
      },
      color: $r('sys.color.ohos_id_color_list_separator')
    })
  }
}
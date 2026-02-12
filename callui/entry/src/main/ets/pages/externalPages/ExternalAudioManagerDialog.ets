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

import LogUtils from '../../common/utils/LogUtils';
import AudioDeviceManager from '../../model/audio/AudioDeviceManager';
import { AudioListItem } from '../../model/audio/AudioListItem';
import { call } from '@kit.TelephonyKit';
import * as DeviceTypeConst from '../../common/constant/DeviceTypeConst';
import { audioDeviceToString } from '../../model/audio/AudioDeviceType';
import { ReportUtil } from '../../common/utils/ReportUtils/ReportUtil';
import { ExternalCallModel } from '../../model/ExternalCallModel';

const TAG = 'ExternalAudioManagerDialog';

@CustomDialog
export struct ExternalAudioManagerDialog {
  @StorageProp('dataList') dataList: AudioListItem[] = [];
  controller?: CustomDialogController;
  private isPsd: boolean = ExternalCallModel.sIsPsd;

  onAccept(itemDeviceType: call.AudioDeviceType, address: string) {
    let audioDevice: call.AudioDevice = {
      deviceType: 0, address: ' '
    };
    audioDevice.deviceType = itemDeviceType;
    audioDevice.address = address;
    LogUtils.i(TAG, 'onAccept device: ' + audioDeviceToString(audioDevice));
    AudioDeviceManager.getInstance().setAudioDevice(audioDevice);
    ReportUtil.getInstance().reportSwitchAudioRuteExternalCall(itemDeviceType);
  }

  @Builder
  private dialogTitle() {
    Text($r('app.string.audio_output'))
      .fontSize('19vp')
      .lineHeight('23vp')
      .fontFamily('HarmonyHeiTi')
      .fontWeight(FontWeight.Medium)
      .fontColor('#ffffff')
      .textAlign(TextAlign.Center)
      .width('129vp')
      .height('23vp')
      .margin({
        top: '20vp'
      })
  }

  @Builder
  indicatorBuilder() {
    SymbolGlyph($r('sys.symbol.checkmark'))
      .fontSize('14vp')
      .fontColor(['#FFFFFF'])
      .opacity(1)
      .fontWeight(900)
  }

  @Builder
  private dialogItem(item: AudioListItem) {
    ListItem() {
      Row() {
        Stack() {
          Circle()
            .opacity(0.15)
            .fill(Color.White)
            .width('46vp')
            .height('46vp')
          SymbolGlyph(item.deviceType === DeviceTypeConst.DEVICE_SPEAKER ? $r('sys.symbol.speaker_wave_3_fill') :
          item.audioIcon)
            .fontSize('28vp')
            .fontColor(['#FFFFFF'])
            .align(Alignment.Center)
            .fontWeight(FontWeight.Medium)
            .draggable(false)
        }
        .width('46vp')
        .height('46vp')
        .margin({ left: '14vp' })
        Text(item.audioTitle)
          .maxFontSize('19vp')
          .minFontSize(this.isPsd ? '13vp' : '14vp')
          .width(this.isPsd ? '78vp' : '92vp')
          .textAlign(TextAlign.Center)
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Medium)
          .margin({ left: '8vp' })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .fontColor('#ffffff')
        Radio({ value: 'item.audioTitle', group: 'externalRadioGroup',
          indicatorType:RadioIndicatorType.CUSTOM,
          indicatorBuilder:()=>{this.indicatorBuilder()}
        })
          .checked(item.isCheck)
          .height(this.isPsd ? '24vp' : '22vp')
          .width(this.isPsd ? '24vp' : '22vp')
          .padding(this.isPsd ? '2vp' : '0vp')
          .margin(this.isPsd ? { left: '19vp', right: '13vp' } : { left: '20vp' })
          .radioStyle({ checkedBackgroundColor: $r('sys.color.comp_background_emphasize') })
          .onClick(() => {
            this.onAccept(item.deviceType, item.address);
            this.controller?.close();
          });
      }
      .alignItems(VerticalAlign.Center)
      .height('76vp')
      .width('100%')
    }
    .onClick(() => {
      this.onAccept(item.deviceType, item.address);
      this.controller?.close();
    })
  }

  @Builder
  private audioList() {
    List() {
      ForEach(this.dataList, (item: AudioListItem) => {
        if (item.deviceType !== DeviceTypeConst.DEVICE_EARPIECE) {
          this.dialogItem(item);
        }
      })
    }
    .divider({ strokeWidth: '1vp', color: '#33FFFFFF', startMargin: '14vp', endMargin: '14vp' })
    .margin({ top: '12vp', bottom: '19vp' })
    .height('152vp')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  build() {
    Column() {
      this.dialogTitle();
      this.audioList();
    }
    .backgroundColor(Color.Black)
    .width('100%')
    .height('100%')
  }
}

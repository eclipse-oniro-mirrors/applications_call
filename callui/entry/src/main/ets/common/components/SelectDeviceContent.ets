/*
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

import { AudioListItem } from '../../model/audio/AudioListItem';
import { call } from '@kit.TelephonyKit';
import LogUtils from '../utils/LogUtils';
import BluetoothDeviceManager from '../../model/audio/AudioDeviceManager';
import DefaultCallData from '../struct/TypeUtils';
import * as DeviceTypeConst from '../constant/DeviceTypeConst';
import CallStateConst from '../constant/CallStateConst';
import { ReportUtil } from '../utils/ReportUtils/ReportUtil';
import Utils from '../utils/utils';
import { audioDeviceToString } from '../../model/audio/AudioDeviceType';
import { isVideoCall } from '../../common/utils/CallListHelper';
import { LengthMetrics } from '@kit.ArkUI';

const TAG = 'SelectDeviceContent';

@Component
export struct SelectDeviceContent {
  @StorageLink('dataList') dataList: AudioListItem[] = [];
  @StorageProp('fontSizeScaleMargin') fontSizeScaleMargin: string = '0vp';
  @State isSourceDistributeCall: boolean = AppStorage.get<boolean>('isDistributeSource') ?? false;
  @StorageLink('isRTL') isRTL: boolean = false;
  @StorageProp('isHyacinthMode') isHyacinthMode: boolean = false;
  dialogController?: CustomDialogController;
  callData?: DefaultCallData;
  @Link switchCount : number;

  onAccept(itemDeviceType: call.AudioDeviceType, address: string) {
    if (this.callData?.callType === CallStateConst.TYPE_SATELLITE &&
      itemDeviceType === DeviceTypeConst.DEVICE_EARPIECE) {
      if (this.isHyacinthMode && this.switchCount >= 3) {
        LogUtils.i(TAG, 'Slect device over 3 times, do not show Toast ');
        return;
      }
      Utils.getInstance().showToast(this.isHyacinthMode ? $r('app.string.disableChangedToEarpiece_hyacinth') : $r('app.string.disableChangedToEarpiece'), 2000);
      this.switchCount++;
      return;
    }
    let audioDevice: call.AudioDevice = {
      deviceType: 0, address: ''
    };
    audioDevice.deviceType = itemDeviceType;
    audioDevice.address = address;
    LogUtils.i(TAG, 'onAccept device: ' + audioDeviceToString(audioDevice));
    BluetoothDeviceManager.getInstance().setAudioDevice(audioDevice);
    ReportUtil.getInstance().reportSwitchAudioRuteInCall(itemDeviceType);
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.interactive_click'))
    .borderRadius($r('sys.float.corner_radius_level7'))
    .opacity(1)
  }

  aboutToDisappear(): void {
    this.dialogController = undefined;
  }

  build() {
    Column() {
      List() {
        ForEach(this.dataList, (item: AudioListItem) => {
          ListItem() {
            Column() {
              Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
                Row() {
                  if (item.deviceType === DeviceTypeConst.DEVICE_BLUETOOTH_SCO) {
                    SymbolGlyph(item.audioIcon)
                      .width(24)
                      .height(24)
                      .margin({ end: LengthMetrics.vp(16) })
                      .draggable(false)
                      .fontColor([$r('sys.color.font_primary')])
                      .fontSize($r('app.float.wh_value_24'))
                      .renderingStrategy(SymbolRenderingStrategy.MULTIPLE_OPACITY)
                  } else {
                    SymbolGlyph(item.audioIcon)
                      .width(24)
                      .height(24)
                      .margin({ end: LengthMetrics.vp(16) })
                      .draggable(false)
                      .fontWeight(FontWeight.Medium)
                      .fontColor([$r('sys.color.font_primary')])
                      .fontSize($r('app.float.wh_value_24'))
                  }
                  Text(item.audioTitle)
                    .fontSize($r('sys.float.Subtitle_M'))
                    .fontColor($r('sys.color.font_primary'))
                    .fontWeight(FontWeight.Medium)
                    .layoutWeight(1)
                    .direction(this.isRTL ? Direction.Rtl : Direction.Ltr)
                }
                .margin({
                  top: this.fontSizeScaleMargin,
                  bottom: this.fontSizeScaleMargin,
                  right: $r('sys.float.padding_level4')
                })

                Radio({ value: 'item.audioTitle', group: 'radioGroup' })
                  .checked(item.isCheck)
                  .align(Alignment.End)
                  .hoverEffect(HoverEffect.None)
                  .width(20)
                  .height(20)
                  .onClick(() => {
                    LogUtils.i(TAG, 'Radio onClick and confirm choose deviceType: ' + item.deviceType +
                      ', address: ' + LogUtils.toSafeAddressString(item.address));
                    if (!item.isCheck) {
                      this.onAccept(item.deviceType, item.address);
                    }
                    this.dialogController?.close();
                  });
              }
              .padding({ left: $r('sys.float.padding_level6'), right: $r('sys.float.padding_level6') })
            }
          }
          .constraintSize({ minHeight: 56 })
          .stateStyles({ pressed: this.pressedStyles, normal: {
            .backgroundColor(Color.Transparent)
          } })
          .onAccessibilityActionIntercept((action: AccessibilityAction) => {
            if (action === AccessibilityAction.ACCESSIBILITY_CLICK) {
              LogUtils.i(TAG, `ListItem on accessibility click and confirm choose deviceType: ${item.deviceType}`);
              if (!item.isCheck) {
                this.onAccept(item.deviceType, item.address);
              }
              this.dialogController?.close();
              return AccessibilityActionInterceptResult.ACTION_INTERCEPT;
            } else {
              LogUtils.w(TAG, 'unknown accessibility click');
              return AccessibilityActionInterceptResult.ACTION_CONTINUE;
            }
          })
          .onClick(() => {
            LogUtils.i(TAG, 'ListItem onClick and confirm choose deviceType: ' + item.deviceType +
              ', address: ' + LogUtils.toSafeAddressString(item.address));
            if (!item.isCheck) {
              this.onAccept(item.deviceType, item.address);
            }
            this.dialogController?.close();
          })
        })
      }
      .padding({ left: $r('sys.float.padding_level6'), right: $r('sys.float.padding_level6') })
      .divider({ strokeWidth: '1px', color: $r('sys.color.comp_divider'), startMargin: '12vp', endMargin: '12vp' })
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .backgroundColor(Color.Transparent)
    }
  }
}
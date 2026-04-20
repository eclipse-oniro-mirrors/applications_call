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
import CallColumnUtils from '../utils/CallColumnUtils';
import DialerVoice from '../utils/DialerVoice';
import DialerSecretCode from '../utils/DialerSecretCode';
import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import LogUtils from '../utils/HiLog';
import EmergencyCallController from '../control/EmergencyCallControl';

class DataListStruct {
  public value: string = '';
  public sign: string = '';
}

@Component
export default struct Keyboard {
  @State mDialerVoice: DialerVoice = new DialerVoice();
  @Link inputValue: string;
  @Link textInputValue: string;
  @Link isInOOBE: boolean;
  @Link isLandscape: boolean;
  @State activeKey: string = '';
  @State longPressActive: boolean = false;
  @State dataList: Array<DataListStruct> =
    [
      {
        value: '1',
        sign: 'o_o',
      },
      {
        value: '2',
        sign: 'ABC',
      },
      {
        value: '3',
        sign: 'DEF',
      },
      {
        value: '4',
        sign: 'GHI',
      },
      {
        value: '5',
        sign: 'JKL',
      },
      {
        value: '6',
        sign: 'MNO',
      },
      {
        value: '7',
        sign: 'PQRS',
      },
      {
        value: '8',
        sign: 'TUV',
      },
      {
        value: '9',
        sign: 'WXYZ',
      },
      {
        value: '*',
        sign: '(P)',
      },
      {
        value: '0',
        sign: '+',
      },
      {
        value: '#',
        sign: '(W)',
      },
    ];
  @StorageProp('curBp') curBp: string = '';
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  mDialerSecretCode: DialerSecretCode = DialerSecretCode.getInstance();

  touchAction(event: TouchEvent, item: DataListStruct) {
    if (event.type === TouchType.Down) {
      this.activeKey = item.value;
    }
    if (event.type === TouchType.Up) {
      this.activeKey = '';
    }
  }

  updateInputValue(value: string) {
    this.textInputValue = this.textInputValue + value;
    this.inputValue = this.textInputValue;
    this.activeKey = '';
    if (this.isInOOBE) {
      // 拨号盘支持暗码场景，将匹配的暗码发送至接口进行暗码广播
      this.mDialerSecretCode.dealSecretCode(this.inputValue);
    }
  }

  onClickFunction(item: DataListStruct) {
    if (this.longPressActive) {
      this.longPressActive = false;
    } else {
      this.updateInputValue(item.value);
      this.mDialerVoice.playAudio(item.value);
    }
  }

  sendAccessibilityEventInfo(item: DataListStruct) {
    let eventInfo: accessibility.EventInfo = ({
      type: 'announceForAccessibility',
      bundleName: 'com.ohos.emergencycommunication',
      triggerAction: 'click',
      textAnnouncedForAccessibility: item.value
    });
    accessibility.sendAccessibilityEvent(eventInfo).then(() => {
    }).catch((err: BusinessError) => {
      LogUtils.e('Keyboard', 'sendAccessibilityEvent failed: ' + JSON.stringify(err));
    });
  }

  build() {
    Grid() {
      ForEach(this.dataList, (item: DataListStruct) => {
        GridItem() {
          Stack() {
            Stack({ alignContent: Alignment.Top }) {
              if (item?.value === '*') {
                SymbolGlyph($r('sys.symbol.staroflife'))
                  .fontSize(this.isNewFoldPhoneExternalScreen ? '20vp' : $r('app.float.emc_margin_level12'))
                  .fontColor([$r('app.color.emc_font_on_primary')])
                  .margin({
                    top: this.isNewFoldPhoneExternalScreen ? 6 : $r('app.float.emc_padding_level75')
                  })
                  .draggable(false)
              } else if (item?.value === '#') {
                SymbolGlyph($r('sys.symbol.hash'))
                  .fontSize(this.isNewFoldPhoneExternalScreen ? '20vp' : $r('app.float.emc_margin_level12'))
                  .fontColor([$r('app.color.emc_font_on_primary')])
                  .margin({
                    top: this.isNewFoldPhoneExternalScreen ? 6 : $r('app.float.emc_padding_level75')
                  })
                  .draggable(false)
              } else {
                Text(item?.value)
                  .fontSize(this.isNewFoldPhoneExternalScreen ? '20vp' : '24vp')
                  .height(this.isNewFoldPhoneExternalScreen ? '20vp' : '32vp')
                  .lineHeight(this.isNewFoldPhoneExternalScreen ? '20vp' : '32vp')
                  .fontWeight(this.isNewFoldPhoneExternalScreen ? FontWeight.Medium : FontWeight.Bold)
                  .fontColor($r('app.color.emc_font_on_primary'))
                  .margin({
                    top: this.isNewFoldPhoneExternalScreen ? 6 : $r('app.float.emc_padding_level55')
                  })
                  .draggable(false)
              }
              if (item?.value === '1') { // change words to image
                SymbolGlyph($r('sys.symbol.recordingtape'))
                  .fontSize($r('app.float.emc_padding_level75'))
                  .fontColor([$r('sys.color.font_on_secondary')])
                    .margin({ top: this.isNewFoldPhoneExternalScreen ? 25 : $r('app.float.emc_padding_level195') })
              } else if (item?.sign === '+') {
                SymbolGlyph($r('sys.symbol.plus'))
                  .fontSize($r('app.float.emc_padding_level45'))
                  .fontColor([$r('sys.color.font_on_secondary')])
                  .margin({
                    top: this.isNewFoldPhoneExternalScreen ? 29 : $r('app.float.emc_padding_level21')
                  })
              } else {
                Text(item?.sign)
                  .fontSize(this.isNewFoldPhoneExternalScreen ? '9vp' : '10vp')
                  .height(this.isNewFoldPhoneExternalScreen ? '12vp' : '15vp')
                  .lineHeight(this.isNewFoldPhoneExternalScreen ? '12vp' : '15vp')
                  .fontWeight(FontWeight.Regular)
                  .fontColor($r('sys.color.font_on_secondary'))
                  .margin({ top: this.isNewFoldPhoneExternalScreen ? 26 : $r('app.float.emc_padding_level195') })
              }
            }
            .width(this.isNewFoldPhoneExternalScreen ? '44vp' : '64vp')
            .height(this.isNewFoldPhoneExternalScreen ? '44vp' : '64vp')
            .backgroundColor(this.isNewFoldPhoneExternalScreen ? (item.value !== this.activeKey ?
            Color.Transparent : '#26FFFFFF') :
              item.value !== this.activeKey ? 'rgba(255, 255, 255, 0.2)' : 'rgba(255, 255, 255, 0.7)')
            .borderRadius(this.isNewFoldPhoneExternalScreen ? 22 : $r('sys.float.corner_radius_level16'))
            .onTouch((event: TouchEvent) => {
              this.touchAction(event, item);
            })
            .gesture(
              GestureGroup(GestureMode.Parallel,
                LongPressGesture().onAction(() => {
                  if (item.value === '0') {
                    this.longPressActive = true;
                    this.updateInputValue(item.sign);
                    // 0在长按时会输入+字符,使用无障碍读出来
                    const accessibilityText = new DataListStruct();
                    accessibilityText.value = '+';
                    this.sendAccessibilityEventInfo(accessibilityText);
                  }
                })
              ))
            .accessibilityGroup(true)
            .onClick((event: ClickEvent) => {
              this.onClickFunction(item);
              if (accessibility.isOpenAccessibilitySync()) {
                this.sendAccessibilityEventInfo(item);
              }
            })
            .onAccessibilityHover((isHover: boolean, event: AccessibilityHoverEvent) => {
              if (!isHover && event.type === AccessibilityHoverType.HOVER_EXIT) {
                this.onClickFunction(item);
                this.sendAccessibilityEventInfo(item);
              }
            })
            .accessibilityText(item.value)
            .accessibilityDescription(this.appendAccessibilityText(item));
          }
        }
        .align(Alignment.Center)
      })
    }
    .rowsGap(this.isNewFoldPhoneExternalScreen ? 0 :
      this.isLandscape ? $r('app.float.emc_padding_level6') : $r('app.float.emc_padding_level12'))
    .columnsGap(this.isNewFoldPhoneExternalScreen ? $r('sys.float.padding_level2') :
    CallColumnUtils.getInstance().getItemSpace(this.curBp))
    .columnsTemplate('1fr 1fr 1fr')
    .rowsTemplate('1fr 1fr 1fr 1fr')
    .direction(Direction.Ltr)
    .height(this.isNewFoldPhoneExternalScreen ? '176vp' :
      this.isLandscape ? $r('app.float.emc_padding_level146') : $r('app.float.emc_padding_level164'))
  }

  appendAccessibilityText(item: DataListStruct): string {
    let oneFinger =
      EmergencyCallController.getInstance().formatResourceToString($r('app.string.one_finger_double_click'));
    if (item.value === '0') {
      // 紧急通信拨号盘上,除0按钮之外,都读'单指双击即可执行', 0按钮读'单指双击即可执行, 双击并按住即可弹出更多选项',
      // 空字符串则使用无障碍默认的播报
      oneFinger = '';
    }
    return oneFinger;
  }
}
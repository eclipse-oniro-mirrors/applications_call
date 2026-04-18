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

/**
 * @file: Header information display component
 */
import LogUtils from '../utils/LogUtils';
import callStateConst from '../constant/CallStateConst';
import DefaultCallData from '../struct/TypeUtils';
import CallTimeListStruct from '../struct/CallTimeListStruct';
import curves from '@ohos.curves';
import Keyboard from './Keyboard';
import SplitScreenManager, { SplitScreenType } from '../../model/SplitScreenManager';
import { StringUtil } from '../utils/StringUtil';
import Utils from '../utils/utils';

const TAG = 'contactCard';

@Component
export default struct VideoContactCard {
  @Link isShowKeyboard: boolean;
  @Prop translateName: string = '';
  @Prop translateTime: string = '';
  @Prop contactAppear: boolean = false;
  @Link callState: number;
  @Link callId: number;
  @Link callTimeList: Array<CallTimeListStruct>;
  @Link isShowSim: boolean;
  @Link callList: Array<DefaultCallData>;
  @StorageLink('TextInput') textInput: string = '';
  @StorageLink('TextInputValue') textInputValue: string = '';
  @StorageLink('AccountNumber') accountNumber: string = '';
  @StorageLink('IsEmergencyPhoneNumber') isEmergencyPhoneNumber: boolean = false;
  @State hasSimCard1: boolean = false;
  @State hasSimCard2: boolean = false;
  @Link isHidePanel: boolean;
  @StorageLink('SplitScreenType') splitScreenType: SplitScreenType = SplitScreenType.DEFAULT
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  @StorageLink('screenReaderStatus') screenReaderStatus: boolean = false;

  public aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
  }

  /**
   * Call status
   *
   * @return {number} - Call status
   */
  public getCallState() {
    return this.callState;
  }

  private getCallTimeTextBottom(): Resource {
    if (SplitScreenManager.getInstance().isPhoneVideoSplitScreenSmall(this.splitScreenType) &&
      !this.isHidePanel) {
      return $r('sys.float.padding_level2');
    }
    return $r('sys.float.padding_level4');
  }

  build() {
    GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: 24 }) {
      GridCol({ span: { xs: 2, sm: 4, md: 8, lg: 12 }, offset: { md: 0, lg: 0 } }) {
        Column() {
          Column() {
            this.IsNotShowKeyboard()
          }

          if (this.isShowKeyboard) {
            Scroll() {
              Text(this.textInputValue)
                .height(this.isNewFoldPhoneExternalScreen ? '43vp' : $r('app.float.call_video_card_title_m_height'))
                .fontSize(this.isNewFoldPhoneExternalScreen ? '20vp' : $r('app.float.call_video_card_title_m_font'))
                .textAlign(TextAlign.Center)
                .lineHeight(this.isNewFoldPhoneExternalScreen ? '27vp' : $r('app.float.call_video_card_title_m_line_height'))
                .fontWeight(this.isNewFoldPhoneExternalScreen ? 600 : FontWeight.Medium)
                .fontColor($r('sys.color.font_on_primary'))
                .constraintSize({ minWidth: '100%' })
                .onTouch((event?: TouchEvent) => {
                  if (event?.type === TouchType.Move) {
                    this.textInputValue = this.textInput;
                  }
                })
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
            .width('100%')

            Keyboard({ isVideoKeyBoard: true, callId: $callId, celiaAssistantShow: false })
              .margin({ bottom: $r('sys.float.padding_level8') })
              .transition(
                TransitionEffect.asymmetric(
                  TransitionEffect.OPACITY.animation({ duration: 200, curve: Curve.Sharp }).combine(
                    TransitionEffect.translate({ y: '1298px' })
                      .animation({ curve: curves.interpolatingSpring(0, 1, 480, 44) })),
                  TransitionEffect.OPACITY.animation({ duration: 150, curve: Curve.Sharp }).combine(
                    TransitionEffect.translate({ y: '1298px' })
                      .animation({ curve: curves.interpolatingSpring(0, 1, 342, 37) }))
                )
              )
          }
        }
        .clip(true)
      }
    }
    .margin({ left: $r('sys.float.padding_level8'), right: $r('sys.float.padding_level8') })
  }

  @Builder
  IsNotShowKeyboard() {
    if (!this.isShowKeyboard) {
      Row() {
        Text(this.callTimeList[0]?.callTime)
          .fontSize($r('app.float.call_video_card_body_s_font'))
          .height($r('app.float.call_video_card_body_s_height'))
          .lineHeight($r('app.float.call_video_card_body_s_height'))
          .fontColor($r('sys.color.font_on_secondary'))
          .accessibilityText(this.screenReaderStatus ?
          Utils.getInstance().getAccessibilityTextOfTime(this.callTimeList[0]?.callTime) : '')
      }
      .margin({ bottom: this.getCallTimeTextBottom(), top: 0 })
      .translate({ y: this.translateTime })
      .animation({
        curve: this.isShowKeyboard ? curves.interpolatingSpring(0, 1, 480, 44) :
        curves.interpolatingSpring(0, 1, 342, 37)
      });
    }
  }
}
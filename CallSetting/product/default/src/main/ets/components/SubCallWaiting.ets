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

import { LogUtils, ReportUtil } from '@ohos/common/CommonIndex';
import prompt from '@system.prompt';
import { setCallWaiting } from '../model/CallServiceProxy';
import { StringUtil } from '../common/utils/StringUtil';
import { BusinessError } from '@ohos.base';
import CallSettingVM from '../viewModel/CallSettingVM';

const TAG = 'SubCallWaiting';

@Component
export struct SubCallWaiting {
  @Link slotId: number;
  @Link callWaitingStatus: number;
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('fontSizeScaleMargin') fontSizeScaleMargin: string = '0vp';
  @State isFromExternal: boolean = CallSettingVM.getInstance().getIsFromExternal();

  showToast(msg?: string) {
    let showMsg = StringUtil.getErrorMsg(msg);
    prompt.showToast({
      message: (msg && !StringUtil.isEmpty(msg)) ?
      StringUtil.formatResourceToString(showMsg) :
      StringUtil.formatResourceToString($r('app.string.networkAnomaly'))
    });
  }

  build() {
    Column() {
      Flex({
        direction: FlexDirection.Row,
        justifyContent: FlexAlign.SpaceBetween,
        alignItems: ItemAlign.Center
      }) {
        Column() {
          Row() {
            Text($r('app.string.Call_waiting'))
              .fontSize($r('sys.float.Subtitle_M'))
              .fontColor($r('sys.color.font_primary'))
              .fontWeight(FontWeight.Medium)
              .fontFamily('HarmonyHeiTi')
              .constraintSize({ minHeight: $r('app.float.line_height_22') })
          }

          Row() {
            Text($r('app.string.Notify_during_call'))
              .fontSize($r('sys.float.Subtitle_S'))
              .fontColor($r('sys.color.font_secondary'))
              .fontWeight(FontWeight.Regular)
              .fontFamily('HarmonyHeiTi')
              .constraintSize({ minHeight: $r('app.float.line_height_19') })
          }
          .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Stack() {
          if (this.callWaitingStatus == -1) {
            LoadingProgress()
              .width('24vp')
              .height('24vp')
              .margin({ left: '12vp' })
          } else {
            Toggle({ type: ToggleType.Switch, isOn: this.callWaitingStatus == 1 })
              .width('36vp')
              .height('20vp')
              .margin(0)
              .enabled(this.callWaitingStatus != -1)
              .accessibilityLevel('yes')
              .onChange((isOn) => {
                LogUtils.i(TAG, `onChange isOn: ${isOn} callWaitingStatus: ${this.callWaitingStatus}`);
                let isOnValue = isOn ? 1 : 0;
                if (isOnValue == this.callWaitingStatus) {
                  return;
                }
                let recordStatus = this.callWaitingStatus;
                this.callWaitingStatus = -1;
                setCallWaiting(!(recordStatus == 1), this.slotId).then((res) => {
                  if (res) {
                    LogUtils.i(TAG, 'callSettings:@ohos.telephony.call:setCallWaiting：then: ' + JSON.stringify(res));
                    this.showToast();
                    return;
                  }
                  LogUtils.i(TAG, 'callSettings:@ohos.telephony.call:setCallWaiting success');
                  this.callWaitingStatus = recordStatus == 1 ? 0 : 1;
                  ReportUtil.getInstance().reportCallWaitingState(this.callWaitingStatus);
                }).catch((error: BusinessError) => {
                  LogUtils.e(TAG, 'callSettings:@ohos.telephony.call:setCallWaiting error: ' + JSON.stringify(error));
                  this.callWaitingStatus = 0;
                  this.showToast(error.code.toString());
                });
              })
          }
        }
      }
      .padding({
        left: $r('sys.float.padding_level4'),
        right: $r('sys.float.padding_level4'),
        top: this.fontSizeScale > 1 ? this.fontSizeScaleMargin : 0,
        bottom: this.fontSizeScale > 1 ? this.fontSizeScaleMargin : 0
      })
      .constraintSize({ minHeight: 64 })
      .width('100%')
      .borderRadius($r('sys.float.corner_radius_level8'))
      .opacity(1)
      .accessibilityGroup(true)

      Divider()
        .color($r('sys.color.comp_divider'))
        .lineCap(LineCapStyle.Round)
        .width('100%')
        .padding({
          left: $r('sys.float.padding_level4'),
          right: $r('sys.float.padding_level4')
        })
    }
    .padding({
      left: $r('sys.float.padding_level2'),
      right: $r('sys.float.padding_level2')
    })
    .constraintSize({ minHeight: 64 })
  }
}
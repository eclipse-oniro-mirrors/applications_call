/*
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import { CallSettingConstant } from '../constant/CallSettingConstant';

const TAG = 'autoSelectObjectDialog';

@CustomDialog
export default struct ContentConfirmDialog {
  controller?: CustomDialogController;
  @State objectUse: string = CallSettingConstant.RECORDING_WAY_ALL_NUMBER;
  confirm: (params: string) => void = (params: string) => {};

  save(params: string) {
    this.confirm(params);
    this.controller?.close();
  }

  cancel() {
    this.controller?.close();
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
    .borderRadius(14)
    .constraintSize({ minHeight: $r('app.float.wh_value_48') })
    .opacity(1)
  }

  build() {
    Column() {
      Column() {
        Text($r('app.string.auto_recording_object'))
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontFamily('HarmonyHeiTi')
          .textAlign(TextAlign.Start)
          .height(56)
          .lineHeight(30)
          .padding({ left: 24 })
      }.width('100%').alignItems(HorizontalAlign.Start)

      List() {
        ListItem() {
          Flex({
            direction: FlexDirection.Row,
            justifyContent: FlexAlign.SpaceBetween,
            alignItems: ItemAlign.Center
          }) {
            Column() {
              Text($r('app.string.all_calls'))
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontFamily('HarmonyHeiTi')
                .textAlign(TextAlign.Start)
                .height(48)
                .lineHeight(19)
            }
            .alignItems(HorizontalAlign.Start)

            Radio({ value: 'Radio', group: 'radioGroup' })
              .checked(this.objectUse === CallSettingConstant.RECORDING_WAY_ALL_NUMBER)
              .hitTestBehavior(HitTestMode.None)
              .width(20)
              .height(20)
              .margin(2)
          }
          .margin({ left: 12, right: 12 })
          .padding({ left: 12, right: 12 })
          .height(48)
          .onClick(() => {
            this.objectUse = CallSettingConstant.RECORDING_WAY_ALL_NUMBER;
            this.save(CallSettingConstant.RECORDING_WAY_ALL_NUMBER);
          })
          .stateStyles({
            pressed: this.pressedStyles,
            normal: {
              .backgroundColor(Color.Transparent)
            }
          })
        }

        ListItem() {
          Flex({
            direction: FlexDirection.Row,
            justifyContent: FlexAlign.SpaceBetween,
            alignItems: ItemAlign.Center
          }) {
            Column() {
              Text($r('app.string.specified_number'))
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontFamily('HarmonyHeiTi')
                .textAlign(TextAlign.Start)
                .height(48)
                .lineHeight(19)
            }
            .alignItems(HorizontalAlign.Start)

            Radio({ value: 'Radio', group: 'radioGroup' })
              .checked(this.objectUse === CallSettingConstant.RECORDING_WAY_DESIGNATE_NUMBER)
              .hitTestBehavior(HitTestMode.None)
              .width(20)
              .height(20)
              .margin(2)
          }
          .margin({ left: 12, right: 12 })
          .padding({ left: 12, right: 12 })
          .height(48)
          .onClick(() => {
            this.objectUse = CallSettingConstant.RECORDING_WAY_DESIGNATE_NUMBER;
            this.save(CallSettingConstant.RECORDING_WAY_DESIGNATE_NUMBER);
          })
          .stateStyles({
            pressed: this.pressedStyles,
            normal: {
              .backgroundColor(Color.Transparent)
            }
          })
        }
      }
      .width('100%')

      .divider({
        strokeWidth: '1px',
        color: $r('sys.color.ohos_id_color_list_separator'),
        startMargin: 24,
        endMargin: 24
      })

      Row() {
        Button($r('app.string.cancel'), { type: ButtonType.Normal })
          .width(288)
          .height(40)
          .borderRadius(21)
          .backgroundColor($r('sys.color.ohos_id_color_background_transparent'))
          .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            this.cancel();
          })
      }
      .width('100%')
      .height(56)
      .padding({ bottom: 16 })
      .margin({ top: 8 })
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
  }
}
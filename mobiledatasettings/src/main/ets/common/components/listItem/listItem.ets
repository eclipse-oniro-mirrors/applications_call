/*
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
import publiccontent from '../publiccontent'
import router from '@system.router';
import call from '@ohos.telephony.call';
import { enableCellularDataRoaming, disableCellularDataRoaming } from '../../../model/mobileDataStatus';
import { setCache } from '../../utils/KvManager';
import LogUtils from '../../utils/LogUtils'

const TAG = "ListItem"

@Component
export default struct listItem {
  @Prop isCard: boolean;
  @Prop isBtn: boolean;
  @Prop isDisabled: boolean;
  @Prop LastOne: boolean;
  @Prop Controlswitch: boolean;
  @State title: any = '';
  @State describe: any = '';
  @Prop isSupport: boolean;
  @State titleopacity: boolean = false;
  @Prop isCon: number;
  @State ceshi: boolean = true;
  dialogTitle: string = '';
  radio_state_enable5g = 'RADIO_STATE_ENABLE5G';
  recordTypeDialog: CustomDialogController = new CustomDialogController({
    builder: recoveryAPN({ isCon: this.isCon, isMsg: $Controlswitch }),
    alignment: DialogAlignment.Bottom,
    autoCancel: false,
    offset: { dx: 0, dy: -10 }
  })

  clickHandle() {
    if (this.isCon == 6) {
      router.push({
        uri: 'pages/senior'
      })
    };
    if (this.isCon === 5) {
      router.push({
        uri: 'pages/availableNetwork'
      })
    };
    if (this.isCon == 2) {
      router.push({
        uri: 'pages/apnPages'
      })
    };
  };

  build() {
    Column() {
      Row({}) {
        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
          Column() {
            Text(this.title)
              .fontFamily('HarmonyHeiTi')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#000')
              .opacity(this.Controlswitch ? 0.9 : 0.6)
              .visibility(this.isSupport ? Visibility.None : Visibility.Visible)
              .letterSpacing(1)
              .lineHeight(22)
              .textAlign(TextAlign.Start)
            Text(this.describe)
              .margin({ top: 2 })
              .fontFamily('HarmonyHeiTi')
              .fontSize(14)
              .fontColor('#555')
              .opacity(0.6)
              .lineHeight(19)
              .letterSpacing(1)
              .visibility(this.describe == '' ? Visibility.None : Visibility.Visible)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ right: 26 })
          .onClick(() => {
            LogUtils.i(TAG, "onclick clickHandle")
            this.clickHandle()
          })
          .enabled(this.isDisabled)

          Image($r('app.media.right'))
            .width(16)
            .height(18)
            .visibility(!this.isBtn ? Visibility.Visible : Visibility.None)
          Toggle({ type: ToggleType.Switch, isOn: this.Controlswitch })
            .width(36)
            .height(20)
            .enabled(this.isDisabled)
            .onChange((isOn: boolean) => {
              this.Controlswitch = !this.Controlswitch;
              if (this.isCon == 1) {
                setCache(this.radio_state_enable5g, isOn);
              }
              if (this.Controlswitch && this.isCon == 0) {
                this.dialogTitle = this.title;
                this.recordTypeDialog.open();
              } else if (this.Controlswitch == false && this.isCon == 0) {
                disableCellularDataRoaming().then((data) => {
                  LogUtils.i(TAG, "disableCellularDataRoaming：then" + JSON.stringify(data))
                }).catch((error) => {
                  LogUtils.i(TAG, "disableCellularDataRoaming：catch" + JSON.stringify(error))
                });
              }
              if (this.isCon == 22 && this.Controlswitch) {
                call.enableImsSwitch(0);
              } else if (this.isCon == 22 && this.Controlswitch == false) {
                call.disableImsSwitch(0);
              }
            })
            .visibility(this.isBtn ? Visibility.Visible : Visibility.None)
        }.visibility(this.isSupport ? Visibility.None : Visibility.Visible)
      }
    }
    .backgroundColor($r("sys.color.ohos_id_color_foreground_contrary"))
    .opacity(this.isDisabled ? 1 : 0.4)
    .margin({ top: 10, bottom: this.isSupport ? 5 : 11 })
    .onClick(() => {
      if (!this.isDisabled) {
        return;
      } else {
        this.clickHandle();
      }
    })
  }
}

@CustomDialog
struct recoveryAPN {
  controller: CustomDialogController;
  isCon: number;
  @Link isMsg: boolean;

  build() {
    Column() {
      Column() {
        Text($r('app.string.mobile_data_tips'))
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontFamily("HarmonyHeiTi")
          .height(56)
          .align(Alignment.Center)
        Text($r('app.string.mobile_data_turn_on_data_roaming'))
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontWeight(FontWeight.Regular)
          .textAlign(TextAlign.Start)
          .height(56)
          .fontFamily('HarmonyHeiTi')
          .letterSpacing(3)
          .visibility(this.isCon == 0 ? Visibility.Visible : Visibility.None)
      }
      .alignItems(HorizontalAlign.Start)

      Flex({ justifyContent: FlexAlign.SpaceAround }) {
        Text(publiccontent.strings.cancel)
          .fontWeight(FontWeight.Medium)
          .fontFamily("HarmonnyHeiTi")
          .lineHeight(21)
          .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
          .fontSize(16)
          .onClick(() => {
            this.controller.close();
            this.isMsg = false;
          })
        Divider().vertical(true).height(1).strokeWidth(1).lineCap(LineCapStyle.Round).opacity(0.5)

        Text(publiccontent.strings.confirm)
          .fontWeight(FontWeight.Medium)
          .fontFamily("HarmonnyHeiTi")
          .lineHeight(21)
          .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
          .fontSize(16)
          .onClick(() => {
            this.controller.close();
            this.isMsg = true;
            enableCellularDataRoaming().then((data) => {
              LogUtils.i(TAG, "enableCellularDataRoaming：then" + JSON.stringify(data))
            }).catch((error) => {
              LogUtils.i(TAG, "enableCellularDataRoaming：catch" + JSON.stringify(error))
            });
          })
      }
      .margin({ top: 18 })
    }
    .height(183)
    .padding({ left: 24, right: 24 })
    .borderRadius(20)
  }
}


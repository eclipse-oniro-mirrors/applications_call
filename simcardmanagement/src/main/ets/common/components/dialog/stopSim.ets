/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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
import { getString } from '../../utils/Utils'

class CardInfoStruct {
  id
  title
  isOpened
  disabled
  name
  info
  isSimCardClosed
}

@CustomDialog
export default struct StopSim {
  controller: CustomDialogController;
  action: (stop) => void;
  curEditList: CardInfoStruct = new CardInfoStruct();
  title: Resource = $r('app.string.sim_card_one_no_space');
  cancel: (boolean) => void;
  @State isChange: boolean = false;
  SIM_CARD_Change = 'sim_card_management_card_change_boolean';
  SIM_CARD_DEFAULT = 'sim_card_management_card_default_call';

  build() {
    Column() {
      Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Start }) {
        Text(`${getString($r('app.string.stop_use'))}${getString(this.curEditList.title)}`)
          .fontWeight(FontWeight.Medium)
          .fontFamily("HarmonyHeiTi")
          .fontSize('20vp')
          .fontColor('rgba(0, 0, 0, 0.9)')
          .height(56)
          .textAlign(TextAlign.Start)
        Text($r('app.string.sim_mobile_data_change', `${this.curEditList.id === 0 ? getString($r('app.string.sim_card_two_no_space')) : getString($r('app.string.sim_card_one_no_space'))}`, `${getString(this.curEditList.title)}`))
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontWeight(FontWeight.Regular)
          .textAlign(TextAlign.Start)
        Flex({ justifyContent: FlexAlign.SpaceAround }) {
          Text($r('app.string.cancel'))
            .fontSize($r('sys.float.ohos_id_text_size_button1'))
            .onClick(() => {
              this.isChange = true;
              this.controller.close();
              this.cancel(true);
            })
            .fontWeight(FontWeight.Medium)
            .fontFamily("HarmonnyHeiTi")
            .lineHeight(21)
            .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
          Divider()
            .vertical(true)
            .height(1)
            .strokeWidth(1)
            .lineCap(LineCapStyle.Round)
            .opacity(0.5)
          Text($r('app.string.stop_use'))
            .fontSize($r('sys.float.ohos_id_text_size_button1'))
            .onClick(() => {
              this.isChange = false;
              this.controller.close();
              this.action(false);
            })
            .fontWeight(FontWeight.Medium)
            .fontFamily("HarmonnyHeiTi")
            .lineHeight(21)
            .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
        }
        .height(56)
        .margin({ top: 8 })
        .padding({ top: 12 })
      }
    }
    .height(180)
    .padding({ left: 24, right: 24 })
  }
}


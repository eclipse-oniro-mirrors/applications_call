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

@CustomDialog
export default struct SetFlowLimit {
  controller: CustomDialogController;
  action: () => void;
  change: boolean = null;

  build() {
    Column() {
      Flex({ direction: FlexDirection.Column }) {
        Text($r('app.string.sim_package_limit', `${this.change ? getString($r('app.string.sim_card_one_no_space')) : getString($r('app.string.sim_card_two_no_space')) }`))
          .fontWeight(600)
          .fontSize('28vp')
          .fontColor('rgba(0, 0, 0, 0.9)')
          .height('50vp')
          .textAlign(TextAlign.Start)
        Text($r('app.string.sim_additional_costs', `${this.change ? getString($r('app.string.sim_card_two_no_space')) : getString($r('app.string.sim_card_one_no_space')) }`))
          .fontSize('24vp')
          .textAlign(TextAlign.Start)
          .margin({ bottom: 20 })
        Flex({ justifyContent: FlexAlign.SpaceAround }) {
          Button($r('app.string.cancel'))
            .fontSize('24vp')
            .onClick(() => {
              this.controller.close();
              this.action();
            }).backgroundColor(0xffffff).fontColor('#2871d4')
          Divider().vertical(true).height(1).strokeWidth(1).lineCap(LineCapStyle.Round).opacity(0.5)
          Button($r('app.string.go_to_set'))
            .fontSize('24vp')
            .onClick(() => {
              this.controller.close();
              this.action();
            }).backgroundColor(0xffffff).fontColor('#2871d4')
        }
      }
      .height(200)
    }
    .padding(24)
  }
}

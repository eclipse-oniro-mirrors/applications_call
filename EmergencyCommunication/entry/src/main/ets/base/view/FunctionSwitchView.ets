/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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

import { StringUtils } from '../utils/StringUtils'
import { LengthMetrics } from '@kit.ArkUI'

@Component
export struct FunctionSwitchView {
  @Prop functionTitle: ResourceStr
  @Prop functionSubTitle: string
  @Prop isFunctionOn: boolean
  @Prop isToggleEnable: boolean
  onSwitchChange?: (isOn: boolean) => void
  onToggleClick: () => void = () => {}
  @StorageProp('topAndBottomMarginOnScale') topAndBottomMarginOnScale: string = '10vp';

  build() {
    Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
      Row() {
        Column() {
          Text(this.functionTitle)
            .id('txtTitleId')
            .fontSize(16)
            .fontColor($r('sys.color.font_primary'))
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .lineHeight(19)

          Text(this.functionSubTitle)
            .id('subTitleId')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .fontWeight(FontWeight.Regular)
            .visibility(StringUtils.isEmpty(this.functionSubTitle) ? Visibility.None : Visibility.Visible)
            .alignSelf(ItemAlign.Start)
        }
        .id('titleGroup')
        .height('auto')
        .alignRules({
          center: {anchor: '__container__', align: VerticalAlign.Center},
          start: {anchor: '__container__', align: HorizontalAlign.Start}
        })
        .layoutWeight(1)
        Blank()
        Toggle({ type: ToggleType.Switch, isOn: this.isFunctionOn })
          .width(36)
          .height(20)
          .onChange(this.onSwitchChange)
          .enabled(this.isToggleEnable)
          .alignRules({
            center: {anchor: '__container__', align: VerticalAlign.Center},
            end: {anchor: '__container__', align: HorizontalAlign.End}
          })
          .margin({ start: LengthMetrics.vp(16) })
          .onClick(() => {
            this.onToggleClick()
          })
      }
      .width('100%')
      .padding({
        left: 12,
        right: 12,
        top: this.topAndBottomMarginOnScale,
        bottom: this.topAndBottomMarginOnScale
      })
    }
    .constraintSize({ minHeight: 56 })
    .padding({top: 4, bottom: 4})
    .borderRadius(20)
    .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
  }
}
/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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
import { LengthMetrics } from '@kit.ArkUI';
import { FontScaleState } from '../util/fontScaleState';
import { AccessibilityUtils } from '../util/AccessibilityUtils';
import common from '@ohos.app.ability.common';
import { Utils } from '../util/Utils';

@Component
export struct TextSelectItem {
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;
  @State isHover: boolean = false;
  @State text: string | Resource = '';
  @State icon?: Resource = undefined;
  @State itemId: number = 0;
  @Link @Watch('onSelectedIdChanged') selectedId: number;
  @Prop selectedIcon: Resource | undefined = $r('app.media.radio_checked');
  @Prop unselectedIcon: Resource | undefined = undefined;

  private onSelectedIdChanged() {
    this.icon = (this.selectedId === this.itemId) ? this.selectedIcon : this.unselectedIcon;
  }

  aboutToAppear(): void {
    this.onSelectedIdChanged();
  }

  @Styles
  normalStyle(){
    .backgroundColor(Utils.getNormalStyleBgColor(this.isHover))
    .borderRadius($r('sys.float.corner_radius_level8'))
  }

  @Styles
  pressedStyle(){
    .backgroundColor($r('sys.color.interactive_click'))
    .borderRadius($r('sys.float.corner_radius_level8'))
  }

  build() {
    Row() {
      Row() {
        Text(this.text)
          .fontSize($r('sys.float.Body_L'))
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
          .fontFamily('HarmonyHeiTi')
          .layoutWeight(1)
          .accessibilityLevel('no')

        if (typeof this.icon !== 'undefined') {
          Image(this.icon)
            .height($r('app.float.value_24'))
            .width($r('app.float.value_24'))
            .accessibilityLevel('no')
            .margin({
              start: LengthMetrics.resource($r('sys.float.ohos_id_text_margin_horizontal')),
            })
            .draggable(false)
        }
      }
      .constraintSize({ minHeight: 48 })
      .padding({
        top: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, '13.5vp'),
        bottom: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, '13.5vp')
      })
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .accessibilityText(AccessibilityUtils.getTextSelectItemReadContent(this.getUIContext()
        .getHostContext() as common.UIAbilityContext, this.text, this.selectedId === this.itemId))
    }.width('100%')
    .constraintSize({ minHeight: 48 })
    .padding({
      start: LengthMetrics.resource($r('sys.float.padding_level6')),
      end: LengthMetrics.resource($r('sys.float.padding_level6')),
    })
    .stateStyles({
      normal: this.normalStyle,
      pressed: this.pressedStyle
    })
  }
}
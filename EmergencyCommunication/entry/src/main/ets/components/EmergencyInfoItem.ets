/*
 * Copyright (c) 2022-2023 Huawei Device Co., Ltd.
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

@Component
export default struct emergencyInfoItem {
  @Prop labelOnly: boolean = true;
  @Prop value: string = '';
  @Prop label: Resource = $r('app.string.emptyStr');
  @Prop photoUrl: Resource = $r('app.string.emptyStr');
  @Prop placeholder: Resource = $r('app.string.emptyStr');
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('topAndBottomMarginOnScale') topAndBottomMarginOnScale: string = '17vp';
  @StorageLink('isRTL') isRTL: boolean = false;
  EMERGENCY_FONTSIZESCALE_4: number = 4;

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
  }

  @Styles
  normalStyles() {
    .backgroundColor(Color.Transparent)
  }

  build() {
    Flex({ alignItems: ItemAlign.Center }) {
      Column() {
        SymbolGlyph(this.photoUrl)
          .fontSize($r('app.float.emc_margin_level12'))
          .fontColor([$r('sys.color.icon_secondary')])
          .draggable(false)
      }
      .width(24)
      .margin({ end: LengthMetrics.resource($r('sys.float.padding_level8')) })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      this.ConditionDisplayText()
    }
    .padding({
      left: $r('sys.float.padding_level4'),
      right: $r('sys.float.padding_level4'),
      top: this.fontSizeScale < this.EMERGENCY_FONTSIZESCALE_4 ?
        (this.labelOnly ? $r('app.float.emc_margin_level17') :
      this.topAndBottomMarginOnScale ) : this.topAndBottomMarginOnScale,
      bottom: this.fontSizeScale < this.EMERGENCY_FONTSIZESCALE_4 ?
        (this.labelOnly ? $r('app.float.emc_margin_level17') :
      this.topAndBottomMarginOnScale ) : this.topAndBottomMarginOnScale
    })
    .stateStyles({
      pressed: this.pressedStyles,
      normal: this.normalStyles
    })
    .borderRadius($r('sys.float.corner_radius_level8'))
    .width('100%')
  }

  @Builder
  ConditionDisplayText() {
    Column() {
      if (this.labelOnly) {
        Text(this.value === '' ? this.placeholder : this.value)
          .width('100%')
          .fontSize($r('sys.float.Subtitle_M'))
          .fontColor(this.value === '' ? $r('sys.color.font_tertiary') :
          $r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
          .constraintSize({ minHeight: $r('app.float.emc_height_level11') })
          .direction(this.isRTL ? Direction.Rtl : Direction.Auto)
      } else {
        Text(this.value === '' ? this.placeholder : this.value)
          .width('100%')
          .fontSize($r('sys.float.Body_L'))
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
          .constraintSize({ minHeight: $r('app.float.emc_height_level11') })
          .direction(this.isRTL ? Direction.Rtl : Direction.Auto)
        Row() {
          Text(this.label)
            .fontSize($r('sys.float.Body_M'))
            .fontColor($r('sys.color.font_secondary'))
            .fontWeight(FontWeight.Regular)
            .constraintSize({ minHeight: $r('app.float.emc_height_level19') })
            .direction(this.isRTL ? Direction.Rtl : Direction.Auto)
        }
        .width('100%')
        .margin({ top: $r('sys.float.padding_level1') });
      }
    }
    .margin({ right: $r('sys.float.padding_level0') })
    .layoutWeight(1)
  }
}
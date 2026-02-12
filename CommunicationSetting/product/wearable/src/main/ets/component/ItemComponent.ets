/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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

import { CircleShape, LengthMetrics } from '@kit.ArkUI';
import { AppInfo } from '../viewmodel/AppInfo';
import StyleConstants from '../constants/StyleConstants';

const SUMMARY_OPACITY: number = 0.6;
const IMAGE_SIZE: number = 46;

@Extend(Text)
function textStyle() {
  .fontFamily(StyleConstants.COMMON_FONT_FAMILY)
  .textAlign(TextAlign.Center)
  .wordBreak(WordBreak.BREAK_WORD)
  .width(StyleConstants.FULL_PARENT)
  .fontColor(Color.White)
}

/**
 * Item Component
 *
 * @since 2024-11-20
 */
@Component
export default struct ItemComponent {
  appInfo?: AppInfo;
  private appName: string = '';

  aboutToAppear(): void {
    if (this.appInfo) {
      this.appName = this.appInfo.label;
      if (!this.appName) {
        this.appName = this.appInfo.bundleName;
      }
    }
  }

  build() {
    Row() {
      this.createLeftIcon();
      this.createText();
    }
    .borderRadius($r('app.float.item_border_Radius'))
    .width($r('app.float.item_view_width'))
    .constraintSize({
      minHeight: $r('app.float.item_view_min_height')
    })
    .margin({
      start: LengthMetrics.resource($r('app.float.item_view_margin_start_end')),
      end: LengthMetrics.resource($r('app.float.item_view_margin_start_end')),
      top: LengthMetrics.resource($r('app.float.item_view_margin_top_bottom')),
      bottom: LengthMetrics.resource($r('app.float.item_view_margin_top_bottom')),
    })
    .attributeModifier({
      applyNormalAttribute: (instance) => {
        instance.backgroundColor($r('app.color.normal_layout_background_color'))
      },
      applyPressedAttribute: (instance) => {
        instance.backgroundColor($r('app.color.pressed_layout_background_color'))
      },
    })
  }

  @Builder
  createLeftIcon() {
    Image(this.appInfo?.img)
      .width($r('app.float.item_icon_image_width_height'))
      .height($r('app.float.item_icon_image_width_height'))
      .margin({
        start: LengthMetrics.resource($r('app.float.item_icon_image_margin_start')),
        end: LengthMetrics.resource($r('app.float.item_icon_image_margin_end')),
        top: LengthMetrics.resource($r('app.float.item_icon_image_margin_top_bottom')),
        bottom: LengthMetrics.resource($r('app.float.item_icon_image_margin_top_bottom')),
      })
      .clipShape(new CircleShape({
        width: IMAGE_SIZE,
        height: IMAGE_SIZE,
      }))
      .alt($r('app.media.app_icon'))
      .interpolation(ImageInterpolation.Low)
  }

  @Builder
  createText() {
    Column() {
      Text(this.appName)
        .fontWeight(FontWeight.Medium)
        .maxFontSize($r('app.float.item_title_text_max_size'))
        .minFontSize($r('app.float.item_title_text_min_size'))
        .lineHeight($r('app.float.item_title_text_line_height'))
        .maxLines(2)
        .textStyle()

      Text(this.appInfo?.flowText)
        .fontWeight(FontWeight.Medium)
        .fontSize($r('app.float.item_summary_text_size'))
        .lineHeight($r('app.float.item_summary_text_line_height'))
        .opacity(SUMMARY_OPACITY)
        .maxLines(1)
        .textStyle()
    }
    .width($r('app.float.item_title_text_width'))
    .justifyContent(FlexAlign.Center)
    .margin({
      start: LengthMetrics.resource($r('app.float.item_title_margin_start')),
      end: LengthMetrics.resource($r('app.float.item_title_margin_end')),
      top: LengthMetrics.resource($r('app.float.item_title_margin_top_bottom')),
      bottom: LengthMetrics.resource($r('app.float.item_title_margin_top_bottom')),
    })
  }
}
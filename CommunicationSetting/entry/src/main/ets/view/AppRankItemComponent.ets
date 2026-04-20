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
import { AppInfo } from '../viewmodel/AppInfo';
import { FontScaleState } from '../util/fontScaleState';
import { LengthMetrics } from '@ohos.arkui.node';
import { constructedImage } from './constructedImage';
import { Utils } from '../util/Utils';

@Component
export struct AppRankItemComponent {
  public appInfo?: AppInfo;
  @State showNetworkType: boolean = true;
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;
  @State isHover: boolean = false;

  @Builder
  text_line() {
    Column({ space: 2 }) {
      Text(this.appInfo?.label)
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Medium)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
      if (this.showNetworkType) {
        Text(this.appInfo?.getNetworkText())
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Regular)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      }
    }
    .flexShrink(1)
    .alignItems(HorizontalAlign.Start)
    .padding({ top: 8, bottom: 8 })
    .margin({ start: LengthMetrics.vp(16) })
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
      if (FontScaleState.isStandardGear(this.fontSizeScale)) {
        this.normalLayout();
      } else {
        this.seniorLayout();
      }
    }
    .constraintSize({ minHeight: 64 })
    .padding({ left: 8, right: 8 })
    .width('100%')
    .stateStyles({
      normal: this.normalStyle,
      pressed: this.pressedStyle
    })
    .onHover((hover: boolean) => {
      this.isHover = hover;
    })
  }

  @Builder
  normalLayout() {
    constructedImage({ appInfo: this.appInfo });

    this.text_line();
    Blank();
    Column() {
      Text(this.appInfo?.flowText[0] + ' ' + this.appInfo?.flowText[1])
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .textAlign(TextAlign.End)
        .direction(Direction.Ltr)
    }
    .margin({ start: LengthMetrics.vp(16), end: LengthMetrics.vp(4) })

    Image($r('sys.media.ohos_ic_public_arrow_right'))
      .fillColor($r('sys.color.ohos_id_color_fourth'))
      .matchTextDirection(true)
      .height(24)
      .width(12)
      .draggable(false)
  }

  @Builder
  seniorLayout() {
    constructedImage({ appInfo: this.appInfo });
    Column() {
      Text(this.appInfo?.label)
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Medium)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(10)
        .constraintSize({ maxWidth: `calc(100% - 16vp)` })
        .margin({
          top: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, '10vp'),
          bottom: this.showNetworkType ? '2vp' : 0
        })

      if (this.showNetworkType) {
        Text(this.appInfo?.getNetworkText())
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(10)
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Regular)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .constraintSize({ maxWidth: `calc(100% - 16vp)` })
      }
      this.seniorFlowTextLayout();
    }
    .margin({ start: LengthMetrics.vp(16) })
    .alignItems(HorizontalAlign.Start)
    .width(`calc(100% - 64vp)`)
  }

  @Builder
  seniorFlowTextLayout() {
    Row() {
      Text(this.appInfo?.flowText[0] + ' ' + this.appInfo?.flowText[1])
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .textAlign(TextAlign.Start)
        .margin({ end: LengthMetrics.vp(4) })
        .constraintSize({ maxWidth: `calc(100% - 16vp)` })

      Image($r('sys.media.ohos_ic_public_arrow_right'))
        .fillColor($r('sys.color.ohos_id_color_fourth'))
        .matchTextDirection(true)
        .height(24)
        .width(12)
        .draggable(false)
    }
    .margin({
      // 双行列表间距是16，单行间距是2
      top: this.showNetworkType ? '16vp' : '2vp',
      bottom: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, '11vp'),
    })
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .width('100%')
  }
}
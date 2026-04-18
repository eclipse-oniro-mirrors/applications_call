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
import { FontScaleState } from '../util/fontScaleState';
import { LengthMetrics } from '@kit.ArkUI';
import StringUtil from '../util/StringUtil';
import { Utils } from '../util/Utils';

@Component
export struct ArrowStructureComponent {
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;
  @State value: string | Resource = '';
  @Prop subValue: string | Resource = '';
  @State isHover: boolean = false;
  private onClickCallBack: ((event: ClickEvent) => void) | undefined = undefined;

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
    Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
      if (FontScaleState.isStandardGear(this.fontSizeScale)) {
        this.normalLayout()
      } else {
        this.seniorLayout()
      }
    }
    .constraintSize({ minHeight: 48 })
    .stateStyles({
      normal: this.normalStyle,
      pressed: this.pressedStyle
    })
    .onHover((hover: boolean) => {
      this.isHover = hover;
    })
    .padding({
      top: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, '13vp'),
      bottom: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, '14vp'),
      left: 8,
      right: 8,
    })
    .width('100%')
    .onClick((event: ClickEvent) => {
      if (this.onClickCallBack) {
        this.onClickCallBack(event);
      }
    })
  }

  @Builder
  normalLayout() {
    Column() {
      Text(this.value)
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Medium)
        .fontSize($r('sys.float.Subtitle_M'))
        .fontColor($r('sys.color.font_primary'));
    }
    .margin({ end: LengthMetrics.vp(8) })
    .alignItems(HorizontalAlign.Start)

    Row() {
      Text(this.subValue)
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .fontSize($r('sys.float.Body_M'))
        .fontColor($r('sys.color.font_secondary'))
        .margin({ end: LengthMetrics.vp(4) })
        .visibility(StringUtil.isEmpty(this.subValue.toString()) ? Visibility.None : Visibility.Visible);

      Image($r('sys.media.ohos_ic_public_arrow_right'))
        .fillColor($r('sys.color.ohos_id_color_fourth'))
        .matchTextDirection(true)
        .height(24)
        .width(12)
        .draggable(false)
    }
    .justifyContent(FlexAlign.End)
  }

  @Builder
  seniorLayout() {
    Column() {
      Column() {
        Text(this.value)
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Medium)
          .fontSize($r('sys.float.Subtitle_M'))
          .fontColor($r('sys.color.font_primary'));

        Text(this.subValue)
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Regular)
          .fontSize($r('sys.float.Body_M'))
          .fontColor($r('sys.color.font_secondary'))
          .margin({ end: LengthMetrics.vp(4) })
          .visibility(StringUtil.isEmpty(this.subValue.toString()) ? Visibility.None : Visibility.Visible);
      }
      .margin({ end: LengthMetrics.vp(8) })
      .alignItems(HorizontalAlign.Start)

    }
    .alignItems(HorizontalAlign.Start)

    Row() {
      Image($r('sys.media.ohos_ic_public_arrow_right'))
        .fillColor($r('sys.color.ohos_id_color_fourth'))
        .matchTextDirection(true)
        .height(24)
        .width(12)
        .draggable(false)
    }
  }
}
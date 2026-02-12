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
import { FontScaleState } from '../util/fontScaleState'
import { LengthMetrics } from '@kit.ArkUI';
import { Utils } from '../util/Utils';

@Component
export struct CommonListComponent {
  @State isHover: boolean = false;
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;
  private name: string | Resource = '';
  private onClickCallBack: ((event: ClickEvent) => void) | undefined = undefined;
  private isInSerialList: boolean = false;

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
    Column() {
      Row() {
        Text(this.name)
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Medium)
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .margin({ end: LengthMetrics.vp(8) })
          .width(`calc(100% - 20vp)`)

        Image($r('sys.media.ohos_ic_public_arrow_right'))
          .fillColor($r('sys.color.ohos_id_color_fourth'))
          .matchTextDirection(true)
          .height(24)
          .width(12)
          .draggable(false)
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
      .justifyContent(FlexAlign.SpaceBetween)
      .onClick((event: ClickEvent) => {
        if (this.onClickCallBack) {
          this.onClickCallBack(event);
        }
      })
      .focusable(true)
    }
    .width('100%')
    .constraintSize({ minHeight: this.isInSerialList ? 48 : 56 })
    .padding({
      top: this.isInSerialList ? 0 : 4,
      bottom: this.isInSerialList ? 0 : 4,
      left: 4,
      right: 4
    })
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.isInSerialList ? Color.Transparent : $r('sys.color.comp_background_list_card'))
    .borderRadius($r('sys.float.corner_radius_level10'))
  }
}
/**
 * Copyright (c) 2024-2024 Huawei Device Co., Ltd.
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

const FULL_OP = 1;

@Component
export struct SubSwitch {
  @Prop controlSwitch: boolean;
  @Prop airPlaneOn: boolean;
  public titleText: Resource = $r('app.string.open_phone_to_answer_calls');
  public commentText: Resource = $r('app.string.answer_voice_calls_by_flipping');
  public onChange: (isOn: boolean) => void = (isOn) => {};

  build() {
    Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
      Column() {
        Text(this.titleText)
          .fontFamily('HarmonyHeiTi')
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .lineHeight(21)
          .textAlign(TextAlign.Start)
        Text(this.commentText)
          .margin({ top: 2 })
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Regular)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.font_secondary'))
          .lineHeight(19)
          .maxLines(2)
      }
      .alignItems(HorizontalAlign.Start)
      .opacity(!this.airPlaneOn ? FULL_OP : $r('sys.float.alpha_disable'))
      .enabled(!this.airPlaneOn)
      .margin({ end: LengthMetrics.vp(14) })
      this.ExpandSwitch()
    }
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .width('100%')
  }

  @Builder
  ExpandSwitch() {
    Toggle({ type: ToggleType.Switch, isOn: this.controlSwitch })
      .width(36)
      .height(20)
      .hoverEffect(HoverEffect.None)
      .enabled(!this.airPlaneOn)
      .flexShrink(0)
      .selectedColor($r('sys.color.comp_background_emphasize'))
      .switchPointColor($r('sys.color.comp_background_primary_contrary'))
      .onChange((isOn) => {
        this.onChange(isOn);
      })
      .margin($r('sys.float.padding_level0'))
  }
}
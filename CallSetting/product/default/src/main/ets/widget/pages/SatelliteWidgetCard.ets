/**
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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

@Entry
@Component
struct SatelliteWidgetCard {
  /*
   * The action type.
   */
  readonly actionType: string = 'router';
  /*
   * The ability name.
   */
  readonly abilityName: string = 'com.ohos.callsetting.SatelliteUIAbility';
  /*
   * The width percentage setting.
   */
  readonly fullWidthPercent: string = '100%';
  /*
   * The height percentage setting.
   */
  readonly fullHeightPercent: string = '100%';

  build() {
    FormLink({
      action: this.actionType,
      abilityName: this.abilityName
    }) {
      Stack({alignContent: Alignment.TopStart}) {
        Image($r('app.media.satellite_network_image'))
          .width(this.fullWidthPercent)
          .height(this.fullHeightPercent)

        Column({ space: 2 }) {
          Text($r('app.string.satellite_network'))
            .fontSize($r('sys.float.Subtitle_S'))
            .fontWeight(FontWeight.Bold)
            .fontColor('#F95941')
            .maxLines(1)
            .fontFamily('HarmonyHeiTi')
            .borderRadius($r('sys.float.corner_radius_level2'))
            .width('auto')
            .textAlign(TextAlign.Start)
            .align(Alignment.Start)
            .alignSelf(ItemAlign.Start)

          Text($r('app.string.click_go_to_settings'))
            .fontSize($r('sys.float.Body_S'))
            .fontWeight(FontWeight.Regular)
            .fontColor($r('sys.color.font_on_tertiary'))
            .maxLines(2)
            .fontFamily('HarmonyHeiTi')
            .borderRadius($r('sys.float.corner_radius_level2'))
            .width('auto')
            .textAlign(TextAlign.Start)
            .align(Alignment.Start)
            .alignSelf(ItemAlign.Start)
        }
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
        .padding(12)
      }
      .width(this.fullWidthPercent)
      .height(this.fullHeightPercent)
    }
    .backgroundColor('#18181A')
  }
}
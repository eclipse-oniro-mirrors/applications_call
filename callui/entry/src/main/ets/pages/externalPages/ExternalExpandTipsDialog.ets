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

import LogUtils from '../../common/utils/LogUtils';
import { ExternalCallModel } from '../../model/ExternalCallModel';

const TAG = 'ExternalExpandTipsDialog';
const TIME_OUT = 3260;

@CustomDialog
export struct ExternalExpandTipsDialog {
  @State state: AnimationStatus = AnimationStatus.Initial
  @State textRes: Resource = $r('app.string.open_phone_to_use_handset');
  private isPsd: boolean = ExternalCallModel.sIsPsd;
  controller?: CustomDialogController;

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
  }

  build() {
    Column() {
      ImageAnimator()
        .images([
          {
            src: $r('app.media.anim_external_display_open_00'),
            duration: 1000
          },
          {
            src: $r('app.media.anim_external_display_open_01'),
            duration: 20
          },
          {
            src: $r('app.media.anim_external_display_open_02'),
            duration: 20
          },
          {
            src: $r('app.media.anim_external_display_open_03'),
            duration: 20
          },
          {
            src: $r('app.media.anim_external_display_open_04'),
            duration: 20
          },
          {
            src: $r('app.media.anim_external_display_open_05'),
            duration: 20
          },
          {
            src: $r('app.media.anim_external_display_open_06'),
            duration: 20
          },
          {
            src: $r('app.media.anim_external_display_open_07'),
            duration: 20
          },
          {
            src: $r('app.media.anim_external_display_open_08'),
            duration: 20
          },
          {
            src: $r('app.media.anim_external_display_open_09'),
            duration: 20
          },
          {
            src: $r('app.media.anim_external_display_open_10'),
            duration: 20
          },
          {
            src: $r('app.media.anim_external_display_open_11'),
            duration: 20
          },
          {
            src: $r('app.media.anim_external_display_open_12'),
            duration: 20
          },
          {
            src: $r('app.media.anim_external_display_open_13'),
            duration: 20
          },
          {
            src: $r('app.media.anim_external_display_open_14'),
            duration: 20
          }
        ])
        .state(this.state)
        .width(this.isPsd ? '120vp' : '128vp')
        .height(this.isPsd ? '120vp' : '128vp')
        .align(Alignment.Center)
        .margin({ top: this.isPsd ? '15.5vp' : '36vp' })

      Text(this.textRes)
        .height(this.isPsd ? '43vp' : 'auto')
        .fontSize(this.isPsd ? '16vp' : '18vp')
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontFamily('HarmonyHeiTi')
        .fontWeight('Regular')
        .fontColor($r('sys.color.ohos_id_color_text_secondary_contrary'))
        .margin(this.isPsd ? { top: '8vp', left: '12vp', right: '12vp' } :
          { top: '4vp', left: '28vp', right: '28vp' })
        .accessibilityLevel('yes')
        .accessibilityDefaultFocus(true)
    }
    .backgroundColor(Color.Black)
    .width('100%')
    .height('100%')
    .onAppear(() => {
      this.state = AnimationStatus.Running;
      setTimeout(() => {
        this.controller?.close();
      }, TIME_OUT)
    })
  }
}

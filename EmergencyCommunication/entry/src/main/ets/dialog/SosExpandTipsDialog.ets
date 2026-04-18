/**
 * Copyright (c) 2025-2025 Huawei Device Co., Ltd.
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
import LogUtils from '../utils/HiLog';
import ScreenAdapterUtils from '../utils/ScreenAdapterUtils';


const TAG = 'SosExpandTipsDialog';

@CustomDialog
export struct SosExpandTipsDialog {
  @State state: AnimationStatus = AnimationStatus.Initial;
  @State textRes: Resource = $r('app.string.open_phone_to_emergency_calls');
  private isPsd: boolean = ScreenAdapterUtils.sIsPsd;
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
        .width('120vp')
        .height('120vp')
        .align(Alignment.Center)
        .margin({ top: this.isPsd ? '12vp' : '16vp' })

      Text(this.textRes)
        .height(this.isPsd ? '43vp' : '48vp')
        .width(this.isPsd ? '178vp' : '153vp')
        .fontSize('16vp')
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontFamily('HarmonyHeiTi')
        .fontWeight('Regular')
        .fontColor($r('sys.color.ohos_id_color_text_secondary_contrary'))
        .margin(this.isPsd ? { top: '8vp', left: '12vp', right: '12vp' } :
          { top: '8vp', left: '36.5vp', right: '36.5vp' })
    }
    .backgroundColor(Color.Black)
    .width('100%')
    .height('100%')
    .onAppear(() => {
      this.state = AnimationStatus.Running;
    })
  }
}

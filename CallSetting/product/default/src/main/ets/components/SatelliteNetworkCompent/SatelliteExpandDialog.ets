/**
 * Copyright (c) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
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

import { LogUtils } from '@ohos/common';

const TAG = 'SatelliteExpandDialog';
const EXPAND_IMAGE_COUNT = 20;

@Component
export default struct SatelliteExpandDialog {

  aboutToAppear(): void {
    LogUtils.i(TAG, `aboutToAppear`);
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, `aboutToDisappear`);
  }

  expandImgArr() {
    let arr: ImageFrameInfo[] = [];
    for (let i = 0; i < EXPAND_IMAGE_COUNT; i++) {
      let name = '';
      if (i > 10) {
        name = `app.media.illustration_${i}`;
      } else {
        name = `app.media.illustration_0${i}`;
      }
      arr.push({
        src: $r(name),
        duration: (i === EXPAND_IMAGE_COUNT - 1) ? 1000 : 59
      });
    }
    return arr;
  }

  build() {
    Scroll() {
      Column() {
        ImageAnimator()
          .images(
            this.expandImgArr()
          )
          .width(288)
          .height(180)
          .iterations(-1)
          .state(AnimationStatus.Running)
          .margin({ top: 24 })

        Text($r('app.string.fold_window_dialog_remind_title'))
          .fontSize($r('sys.float.Title_S'))
          .margin({ top: 24 })
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .constraintSize({ minHeight: 26 })

        Text($r('app.string.fold_window_dialog_remind_message'))
          .fontSize($r('sys.float.Body_L'))
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Regular)
          .textAlign(TextAlign.Center)
          .margin({ top: 20, left: 12, right: 12 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .padding({ left: $r('sys.float.margin_left'), right: $r('sys.float.margin_right') })
    .constraintSize({ maxHeight: '90%' })
  }
}
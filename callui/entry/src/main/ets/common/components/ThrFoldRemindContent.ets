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

import LogUtils from '../utils/LogUtils';


const TAG = 'ThrFoldRemindContent';
const EXPAND_IMAGE_COUNT = 7;

@Component
export default struct ThrFoldRemindContent {

  remindString?: ResourceStr;
  clickClose: Function = () => {
  };

  aboutToAppear(): void {
    LogUtils.i(TAG, `aboutToAppear`);
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, `aboutToDisappear`);
  }

  expandImgArr() {
    let arr: ImageFrameInfo[] = [];
    for (let i = 1; i <= EXPAND_IMAGE_COUNT; i++) {
      let name = `app.media.ic_infold_${i}`;
      arr.push({
        src: $r(name),
        duration: (i === EXPAND_IMAGE_COUNT) ? 1000 : 100
      });
    }
    return arr;
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          Stack({ alignContent: Alignment.Center }) {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize($r('app.float.leather_image_height'))
              .fontColor(['#FFFFFF'])
              .width(24)
              .height(24)
              .alignSelf(ItemAlign.Center)
          }
          .width(40)
          .height(40)
          .onClick(() => {
            this.clickClose();
          })
        }
        .width('100%')
        .margin({ top: 8, right: 12 })
        .justifyContent(FlexAlign.End)

        ImageAnimator()
          .images(
            this.expandImgArr()
          )
          .width(128)
          .height(128)
          .iterations(-1)
          .state(AnimationStatus.Running)
          .margin({ top: 12 })

        Text(this.remindString)
          .fontSize($r('sys.float.Title_S'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .constraintSize({ minHeight: 26 })
          .textAlign(TextAlign.Center)
          .margin({
            left: $r('sys.float.padding_level12'),
            right: $r('sys.float.padding_level12'),
            top: 24
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .margin({
        bottom: $r('sys.float.padding_level12')
      })
    }
    .constraintSize({ maxHeight: '90%' })
  }
}
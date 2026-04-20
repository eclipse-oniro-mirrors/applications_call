/**
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

/**
 * The copy dialog box is displayed at the bottom.
 */
import measure from '@ohos.measure';
import { LogUtil } from '../util/LogUtil';

const TAG = 'CustomButtons';

@Extend(Button)
function buttonExtend() {
  .buttonStyle(ButtonStyleMode.TEXTUAL)
  .fontColor($r('sys.color.font_emphasize'))
  .fontSize($r('sys.float.Body_L'))
  .fontWeight(FontWeight.Medium)
  .maxFontScale(2)
  .labelStyle({
    overflow: TextOverflow.Ellipsis,
    maxLines: 1
  })
}


@Component
export default struct CustomButtons {
  @Link confirmButtonEnabled: boolean;
  cancelButtonText: ResourceStr = '';
  confirmButtonText: ResourceStr = '';
  onCancel: () => void = () => {
  };
  onConfirm: () => void = () => {
  };
  // 防止重复点击
  private canClick: boolean = true;
  @State isVerticalLayout: boolean = false;
  @StorageProp('fontSizeScale') @Watch('measureTextWidth') fontSizeScale: number = 1;
  @StorageProp('language') @Watch('measureTextWidth') language: string = '';

  measureTextWidth() {
    // 单行文本最大宽度
    let maxWidth = 150;
    let cancelLenght = px2vp(measure.measureText({
      textContent: this.cancelButtonText,
      fontSize: $r('sys.float.Body_L'),
      fontWeight: FontWeight.Medium
    }));

    let confirmLenght = px2vp(measure.measureText({
      textContent: this.confirmButtonText,
      fontSize: $r('sys.float.Body_L'),
      fontWeight: FontWeight.Medium
    }));
    LogUtil.info(TAG, `cancelLenght value is ${cancelLenght}, confirmLenght value is ${confirmLenght}`);
    if (confirmLenght >= maxWidth || cancelLenght > maxWidth) {
      this.isVerticalLayout = true;
    } else {
      this.isVerticalLayout = false;
    }
  }

  aboutToAppear(): void {
    this.measureTextWidth();
  }

  build() {
    Column() {
      if (this.isVerticalLayout) {
        this.verticalLayoutBuild();
      } else {
        this.horizontalLayoutBuild();
      }
    }
    .justifyContent(FlexAlign.Start)
    .margin({ top: $r('sys.float.padding_level4') })
    .width('100%')
    .constraintSize({ minHeight: 40 })
  }

  @Builder
  verticalLayoutBuild() {
    Column() {
      this.contentBuild();
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  horizontalLayoutBuild() {
    Row() {
      this.contentBuild();
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  contentBuild() {
    Button(this.cancelButtonText)
      .onClick(() => {
        this.onCancel();
      })
      .width(this.isVerticalLayout ? '100%' : `calc(50% - 8vp)`)
      .buttonExtend()
      .layoutWeight(1)

    if (!this.isVerticalLayout) {
      Divider()
        .vertical(true)
        .height(24)
        .width(0.5)
        .color($r('sys.color.comp_divider'))
        .margin({ left: 8, right: 8 })
    }

    Button(this.confirmButtonText)
      .onClick(() => {
        if (this.canClick) {
          this.canClick = false;
          this.onConfirm();
        }
      })
      .enabled(this.confirmButtonEnabled)
      .width(this.isVerticalLayout ? '100%' : `calc(50% - 8vp)`)
      .buttonExtend()
  }
}
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
import LogUtils from '../utils/LogUtils';

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
  @StorageProp('fontSizeScale') @Watch('onEnvironmentChange') fontSizeScale: number = 1;
  @StorageProp('language') @Watch('onEnvironmentChange') language: string = '';

  onEnvironmentChange() {
    this.measureTextWidth();
  }

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
    LogUtils.i(TAG, `cancelLenght value is ${cancelLenght}, confirmLenght value is ${confirmLenght}`);
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
      Flex({
        direction: this.isVerticalLayout ? FlexDirection.Column : FlexDirection.Row,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.Center
      }) {
        Button(this.cancelButtonText)
          .onClick(() => {
            this.onCancel();
          })
          .width(`calc(100% - ${this.isVerticalLayout ? 32 : 0}vp)`)
          .margin(this.isVerticalLayout ? { left: 16, right: 16 } : { left: 16 })
          .buttonExtend()

        if (!this.isVerticalLayout) {
          Divider()
            .vertical(true)
            .height(24)
            .width(0.5)
            .color($r('sys.color.comp_divider'))
            .opacity($r('sys.float.alpha_secondary'))
            .margin({ left: 8, right: 8 })
        }

        Button(this.confirmButtonText)
          .onClick(() => {
            if (this.canClick === true) {
              this.canClick = false;
              this.onConfirm();
            }
          })
          .enabled(this.confirmButtonEnabled)
          .width(`calc(100% - ${this.isVerticalLayout ? 32 : 0}vp)`)
          .margin(this.isVerticalLayout ? { top: 4, left: 16, right: 16 } : { right: 16 })
          .buttonExtend()
      }
      .width('100%')
    }
    .justifyContent(FlexAlign.Start)
    .margin({ top: $r('sys.float.padding_level4') })
    .width('100%')
    .constraintSize({ minHeight: 40 })
  }
}
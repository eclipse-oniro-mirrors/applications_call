/**
 * Copyright (c) 2022-2024 Huawei Device Co., Ltd.
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

import { AppFuncBtnStyleData } from '../struct/TypeUtils';
import CallColumnUtils from '../utils/CallColumnUtils';
import { HANG_UP_LTR_ANGLE, HANG_UP_RTL_ANGLE } from '../utils/LanguageUtils';
import LogUtils from '../utils/LogUtils';

const TAG = 'IncomingAnimation';
const BUTTON_HALF_WIDTH = 32;

@Component
export default struct IncomingAnimation {
  @State incomingIcon: Resource = $r('sys.symbol.phone_fill');
  @State bagroundColor: string = '#64BB5C';
  @State translateX: number = 0;
  @State angle: number = 0;
  @StorageProp('curBp') curBp: string = '';
  @StorageLink('isRTL') isRTL: boolean = false;
  private animationStartP: number = 0;
  private currentCenterPoint: number = 0;
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  @StorageLink('isApplyNewStyle') isApplyNewStyle: boolean = false;
  @StorageLink('funcBtnStyle') funcBtnStyle: AppFuncBtnStyleData = new AppFuncBtnStyleData();

  startTranslateAnimation(): void {
    animateTo({ duration: 280, curve: Curve.FastOutSlowIn, onFinish: () => {
      LogUtils.i(TAG, 'IncomingAnimation onFinish');
      AppStorage.setOrCreate('onAnswer', false);
      AppStorage.setOrCreate('animationFinish', true);
    } }, () => {
      this.translateX = -(this.animationStartP - this.currentCenterPoint);
      this.angle = this.isRTL ? HANG_UP_RTL_ANGLE : HANG_UP_LTR_ANGLE;
    })
    animateTo({ duration: 280, curve: Curve.Sharp, onFinish: () => {
      this.bagroundColor = '#E84826';
    } }, () => {
      this.bagroundColor = '#E84826';
    })
  }

  aboutToAppear(): void {
    LogUtils.i(TAG, 'IncomingAnimation about to Appear');
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'IncomingAnimation about to Disappear');
  }

  private getButtonWidth(): Length {
    if (this.isApplyNewStyle) {
      return this.funcBtnStyle.btnWidth;
    }
    return this.isNewFoldPhoneExternalScreen ? '56vp' : $r('app.float.call_button_width');
  }

  build() {
    GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: 24 }) {
      GridCol({ span: { xs: 2, sm: 4, md: 6, lg: 8 }, offset: { md: 1, lg: 2 } }) {
        Row() {
          Column() {
            Stack() {
              Button({ type: ButtonType.Circle })
                .backgroundColor(this.bagroundColor)
                .width(this.getButtonWidth())
                .height(this.getButtonWidth())

              SymbolGlyph(this.incomingIcon)
                .fontColor(['#FFFFFF'])
                .fontSize(this.isApplyNewStyle ? this.funcBtnStyle.innerIconWidth : $r('app.float.funbtn_image_width'))
                .width(this.isApplyNewStyle ? this.funcBtnStyle.innerIconWidth : $r('app.float.funbtn_image_width'))
                .height(this.isApplyNewStyle ? this.funcBtnStyle.innerIconWidth : $r('app.float.funbtn_image_width'))
                .rotate({ angle: this.angle })
                .draggable(false)
            }
            .translate({ x: this.translateX })
            .alignSelf(ItemAlign.Center)
            .onAreaChange((oldValue: Area, newValue: Area) => {
              this.animationStartP = Number(newValue.globalPosition.x) + BUTTON_HALF_WIDTH;
              LogUtils.i(TAG, 'animation start btton postion' + this.animationStartP);
            });
          }
          .justifyContent(FlexAlign.Center)
          .alignSelf(ItemAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .width('50%')
        }
        .justifyContent(FlexAlign.End)
        .alignItems(VerticalAlign.Center)
        .width('100%')
        .onAreaChange((oldValue: Area, newValue: Area) => {
          let animationx = Number(newValue.globalPosition.x);
          this.currentCenterPoint = animationx + Number(newValue.width) / 2;
        });
      }
    }
    .margin({
      left: this.isApplyNewStyle ? 0 : CallColumnUtils.getInstance().getPaddingSpace(this.curBp),
      right: this.isApplyNewStyle ? 0 : CallColumnUtils.getInstance().getPaddingSpace(this.curBp)
    })
    .onAppear(() => {
      this.startTranslateAnimation()
    })
  }
}

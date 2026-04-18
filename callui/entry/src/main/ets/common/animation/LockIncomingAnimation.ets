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

import LogUtils from '../utils/LogUtils';
import curves from '@ohos.curves';
import CallColumnUtils from '../utils/CallColumnUtils';
import { HANG_UP_LTR_ANGLE, HANG_UP_RTL_ANGLE } from '../utils/LanguageUtils';
import { AppFuncBtnStyleData } from '../struct/TypeUtils';

const TAG = 'LockIncomingAnimation';
const BUTTON_HALF_WIDTH = 32;

@Component
export struct LockIncomingAnimation {
  @State incomingIcon: Resource = $r('sys.symbol.phone_fill');
  @State bagroundColor: string = '#64BB5C';
  @State imageIconColor: string = '#64BB5C';
  @State translateX: number = 0;
  @State opactiyBtn: number = 0.2;
  @State scaleX: number = 1;
  @State translateY: number = 0;
  @State angle: number = 0;
  @StorageProp('curBp') curBp: string = '';
  @State incomingVideoIcon: string = 'sys.symbol.video_fill';
  @Prop isVideoCall: boolean;
  @StorageLink('isRTL') isRTL: boolean = false;
  private animationStartP: number = 0;
  private currentCenterPoint: number = 0;
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  @StorageLink('isApplyNewStyle') isApplyNewStyle: boolean = false;
  @StorageLink('funcBtnStyle') funcBtnStyle: AppFuncBtnStyleData = new AppFuncBtnStyleData();

  backgroundColorAnimation(): void {
    animateTo({ duration: 300, curve: curves.interpolatingSpring(0, 1, 342, 37), onFinish: () => {
      LogUtils.i(TAG, 'onFinish: backgroundGreen');
      this.bagroundColor = '#E84826';
    } }, () => {
      this.bagroundColor = '#E84826';
    })
  }

  startTranslateAnimation(): void {
    animateTo({ curve: curves.interpolatingSpring(0, 1, 342, 37), onFinish: () => {
      LogUtils.i(TAG, 'LockIncomingAnimation onFinish');
      AppStorage.setOrCreate('onAnswer', false);
      AppStorage.setOrCreate('animationFinish', true);
    } }, () => {
      this.translateX = -(this.animationStartP - this.currentCenterPoint);
      this.angle = this.isRTL ? HANG_UP_RTL_ANGLE : HANG_UP_LTR_ANGLE;
    })
  }

  startColorAnimation(): void {
    animateTo({ duration: 100, curve: curves.interpolatingSpring(0, 1, 342, 37) }, () => {
      this.imageIconColor = '#FFFFFF';
      this.opactiyBtn = 1;
    })
  }

  startAnimation(): void {
    this.startTranslateAnimation();
    this.startColorAnimation();
    this.backgroundColorAnimation();
  }

  aboutToAppear(): void {
    LogUtils.i(TAG, 'LockIncomingAnimation about to Appear');
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'LockIncomingAnimation about to Disappear');
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
                .opacity(this.opactiyBtn)

              SymbolGlyph(this.isVideoCall ? $r(this.incomingVideoIcon) : this.incomingIcon)
                .fontSize(this.isApplyNewStyle ? this.funcBtnStyle.innerIconWidth : $r('app.float.funbtn_image_width'))
                .fontColor([this.imageIconColor])
                .width(this.isApplyNewStyle ? this.funcBtnStyle.innerIconWidth : $r('app.float.funbtn_image_width'))
                .height(this.isApplyNewStyle ? this.funcBtnStyle.innerIconWidth : $r('app.float.funbtn_image_width'))
                .draggable(false)
                .rotate({ angle: this.angle })
                .scale({ x: this.scaleX, y: this.scaleX })
                .draggable(false)
            }
            .translate({ x: this.translateX })
            .onAreaChange((oldValue: Area, newValue: Area) => {
              this.animationStartP = Number(newValue.globalPosition.x) + BUTTON_HALF_WIDTH;
              LogUtils.i(TAG, 'animation globalPosition.x value is' + newValue.globalPosition.x);
            });
          }
          .justifyContent(FlexAlign.Center)
          .alignSelf(ItemAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .width('50%')
        }
        .onAreaChange((oldValue: Area, newValue: Area) => {
          let animationx = Number(newValue.globalPosition.x);
          this.currentCenterPoint = animationx + Number(newValue.width) / 2;
          LogUtils.i(TAG, 'animation globalPosition Row is' + animationx + ' wid value is ' + Number(newValue.width));
        })
        .justifyContent(FlexAlign.End)
        .alignItems(VerticalAlign.Center)
        .width('100%')
        .margin({
          left: this.isApplyNewStyle ? 0 : CallColumnUtils.getInstance().getPaddingSpace(this.curBp),
          right: this.isApplyNewStyle ? 0 : CallColumnUtils.getInstance().getPaddingSpace(this.curBp)
        })
        .onAppear(() => {
          this.startAnimation();
        })
      }
    }
  }
}
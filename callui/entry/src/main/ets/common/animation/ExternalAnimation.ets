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

import { ExternalCallModel } from '../../model/ExternalCallModel';
import DefaultCallData from '../struct/TypeUtils';
import { isIncomingCall, isIncomingVoiceSilencedCall } from '../utils/CallListHelper';
import * as Constants from '../utils/Constants';
import LogUtils from '../utils/LogUtils';
import { ExternalDiffusedCircle } from './ExternalDiffusedCircle';

const TAG = 'ExternalAnimation';
const ORIGINAL_OFFSET = 6;
const ORIGINAL_SCALE = 0.7;
const ORIGINAL_BLUR = 15;
const TARGET_OFFSET = 9;
const TARGET_SCALE = 0.2;
const TARGET_BLUR = 0;

@Component
export struct ExternalAnimation {
  @State leftOffSet1: number = ORIGINAL_OFFSET;
  @State rightOffSet1: number = -ORIGINAL_OFFSET;
  @State bottomOffSet1: number = -ORIGINAL_OFFSET;
  @State scale1: number = ORIGINAL_SCALE;
  @State blur1: number = ORIGINAL_BLUR;
  @State op1: number = Constants.OP_EMPTY;
  @State leftOffSet2: number = ORIGINAL_OFFSET;
  @State rightOffSet2: number = -ORIGINAL_OFFSET;
  @State bottomOffSet2: number = -ORIGINAL_OFFSET;
  @State scale2: number = ORIGINAL_SCALE;
  @State blur2: number = ORIGINAL_BLUR;
  @State op2: number = Constants.OP_EMPTY;
  @StorageProp(Constants.CALL_DATA) callData: DefaultCallData = new DefaultCallData();
  @Prop @Watch('onTouchEvent') touchDown: boolean;
  private mIsStartAnimation: boolean = false;
  private mTimeOutArray: Array<number> = [];
  private isPsd: boolean = ExternalCallModel.sIsPsd;

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
  }

  private onTouchEvent() {
    if (this.touchDown && this.mIsStartAnimation) {
      this.stopAnimation();
    } else if (!this.mIsStartAnimation) {
      this.startAnimation();
    }
  }

  private startAnimation() {
    LogUtils.i(TAG, 'startAnimation');
    this.mIsStartAnimation = true;
    for (let i = 0; i < 2; i++) {
      if (this.touchDown) {
        return;
      }
      this.startAnimation1(i);
      this.startAnimation2(i);
    }
  }

  private startAnimation1(i: number) {
    let oneId = setTimeout(() => {
      if (this.touchDown) {
        return;
      }
      animateTo({ duration: 350, curve: Curve.Linear }, () => {
        this.op1 = Constants.OP_FULL;
      })
      animateTo({ duration: 850, curve: Curve.Friction }, () => {
        this.leftOffSet1 = -TARGET_OFFSET;
        this.rightOffSet1 = TARGET_OFFSET;
        this.bottomOffSet1 = TARGET_OFFSET;
      })
      animateTo({ duration: 500, delay: 350, curve: Curve.Friction }, () => {
        this.scale1 = TARGET_SCALE;
      })
      animateTo({ duration: 250, curve: Curve.Linear }, () => {
        this.blur1 = TARGET_BLUR;
      })
      animateTo({ duration: 500, delay: 350, curve: Curve.Linear }, () => {
        this.op1 = Constants.OP_EMPTY;
      })
      let twoId = setTimeout(() => {
        if (this.touchDown) {
          return;
        }
        this.initLeftCircle();
      }, 850);
      this.mTimeOutArray.push(twoId);
    }, 200 + 500 * i * 2);
    this.mTimeOutArray.push(oneId);
  }

  private startAnimation2(i: number) {
    let threeId = setTimeout(() => {
      if (this.touchDown) {
        return;
      }
      animateTo({ duration: 350, curve: Curve.Linear }, () => {
        this.op2 = Constants.OP_FULL;
      })
      animateTo({ duration: 850, curve: Curve.Friction }, () => {
        this.leftOffSet2 = -TARGET_OFFSET;
        this.rightOffSet2 = TARGET_OFFSET;
        this.bottomOffSet2 = TARGET_OFFSET;
      })
      animateTo({ duration: 500, delay: 350, curve: Curve.Friction }, () => {
        this.scale2 = TARGET_SCALE;
      })
      animateTo({ duration: 250, curve: Curve.Linear }, () => {
        this.blur2 = TARGET_BLUR;
      })
      animateTo({ duration: 500, delay: 350, curve: Curve.Linear }, () => {
        this.op2 = Constants.OP_EMPTY;
      })
      let fourID = setTimeout(() => {
        if (this.touchDown) {
          return;
        }
        this.initRightCircle();
        if (i == 1 && !this.touchDown) {
          let fiveId = this.getFiveId();
          this.mTimeOutArray.push(fiveId);
        }
      }, 850);
      this.mTimeOutArray.push(fourID);
    }, 700 + 500 * i * 2)
    this.mTimeOutArray.push(threeId);
  }

  private getFiveId(): number {
    return setTimeout(() => {
      if (this.touchDown) {
        return;
      }
      this.startAnimation();
    }, 1150);
  }

  private initLeftCircle() {
    this.leftOffSet1 = ORIGINAL_OFFSET;
    this.rightOffSet1 = -ORIGINAL_OFFSET;
    this.bottomOffSet1 = -ORIGINAL_OFFSET;
    this.scale1 = ORIGINAL_SCALE;
    this.blur1 = ORIGINAL_BLUR;
  }

  private initRightCircle() {
    this.leftOffSet2 = ORIGINAL_OFFSET;
    this.rightOffSet2 = -ORIGINAL_OFFSET;
    this.bottomOffSet2 = -ORIGINAL_OFFSET;
    this.scale2 = ORIGINAL_SCALE;
    this.blur2 = ORIGINAL_BLUR;
  }

  private stopAnimation() {
    LogUtils.i(TAG, 'stopAnimation');
    this.mIsStartAnimation = false;
    this.op1 = Constants.OP_FULL;
    this.leftOffSet1 = 0;
    this.rightOffSet1 = 0;
    this.bottomOffSet1 = 0;
    this.scale1 = TARGET_SCALE;
    this.blur1 = TARGET_BLUR;
    this.op2 = Constants.OP_FULL;
    this.leftOffSet2 = 0;
    this.rightOffSet2 = 0;
    this.bottomOffSet2 = 0;
    this.scale2 = TARGET_SCALE;
    this.blur2 = TARGET_BLUR;
    this.mTimeOutArray.forEach((id: number) => {
      clearTimeout(id);
    })
    this.mTimeOutArray = [];
    animateTo({ duration: 0 }, () => {
      this.op2 = Constants.OP_EMPTY;
      this.op1 = Constants.OP_EMPTY;
      this.initLeftCircle();
      this.initRightCircle();
    })
  }

  @Builder
  private leftAnimation() {
    Stack() {
      ExternalDiffusedCircle({ isX: true })
        .translate({ x: this.leftOffSet1 })
        .scale({ x: this.scale1, y: this.scale1 })
        .opacity(this.op1)
        .blur(this.blur1, undefined, { disableSystemAdaptation: true })

      ExternalDiffusedCircle({ isX: true })
        .translate({ x: this.leftOffSet2 })
        .scale({ x: this.scale2, y: this.scale2 })
        .opacity(this.op2)
        .blur(this.blur2, undefined, { disableSystemAdaptation: true })
    }
    .alignRules({
      top: { anchor: '__container__', align: VerticalAlign.Top },
      left: { anchor: '__container__', align: HorizontalAlign.Start }
    })
    .visibility(isIncomingCall(this.callData.callState) ? Visibility.Visible : Visibility.None)
    .margin(this.isPsd ? {top: 43, left: 48 } : { top: 42.5, left: 54.25 })
    .id('leftAnimation')
    .width(this.isPsd ? 19 : 21.5)
    .height(this.isPsd ? 5 : 5.5)
  }

  @Builder
  private rightAnimation() {
    Stack() {
      ExternalDiffusedCircle({ isX: true })
        .rotate({ angle: 180 })
        .translate({ x: this.rightOffSet1 })
        .scale({ x: this.scale1, y: this.scale1 })
        .opacity(this.op1)
        .blur(this.blur1, undefined, { disableSystemAdaptation: true })

      ExternalDiffusedCircle({ isX: true })
        .rotate({ angle: 180 })
        .translate({ x: this.rightOffSet2 })
        .scale({ x: this.scale2, y: this.scale2 })
        .opacity(this.op2)
        .blur(this.blur2, undefined, { disableSystemAdaptation: true })
    }
    .alignRules({
      top: { anchor: '__container__', align: VerticalAlign.Top },
      right: { anchor: '__container__', align: HorizontalAlign.End }
    })
    .visibility(isIncomingCall(this.callData.callState) ? Visibility.Visible : Visibility.None)
    .margin(this.isPsd ? {top: 43, right: 48 } : { top: 42.5, right: 54.25 })
    .id('rightAnimation')
    .width(this.isPsd ? 19 : 21.5)
    .height(this.isPsd ? 5 : 5.5)
  }

  @Builder
  private bottomAnimation() {
    Stack() {
      ExternalDiffusedCircle({ isX: false })
        .rotate({ angle: 180 })
        .translate({ y: this.bottomOffSet1 })
        .scale({ x: this.scale1, y: this.scale1 })
        .opacity(this.op1)
        .blur(this.blur1, undefined, { disableSystemAdaptation: true })

      ExternalDiffusedCircle({ isX: false })
        .rotate({ angle: 180 })
        .translate({ y: this.bottomOffSet2 })
        .scale({ x: this.scale2, y: this.scale2 })
        .opacity(this.op2)
        .blur(this.blur2, undefined, { disableSystemAdaptation: true })
    }
    .margin({ bottom: this.isPsd ? 47 : 53.25 })
    .visibility(isIncomingVoiceSilencedCall(this.callData) ? Visibility.None : Visibility.Visible)
    .alignRules({
      middle: { anchor: '__container__', align: HorizontalAlign.Center },
      bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
    })
    .id('bottomAnimation')
    .width(this.isPsd ? 19 : 21.5)
    .height(this.isPsd ? 5 : 5.5)
  }

  build() {
    RelativeContainer() {
      this.leftAnimation();
      this.rightAnimation();
      this.bottomAnimation();
    }
    .width('100%')
    .height('100%')
    .onAppear(() => {
      LogUtils.i(TAG, 'onAppear - startAnimation');
      this.startAnimation();
    })
  }
}
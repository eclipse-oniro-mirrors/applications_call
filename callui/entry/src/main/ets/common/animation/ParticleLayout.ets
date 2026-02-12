/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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
import IncomingComVM from '../../viewmodel/IncomingComVM';
import hiTraceMeter from '@ohos.hiTraceMeter';
import curves from '@ohos.curves';
import { CometsEmit } from './CometsEmit';
import { SplitScreenType } from '../../model/SplitScreenManager';

const TAG = 'ParticleLayout';
const CIRCLE_OFFSET = 18;

@Component
export default struct ParticleLayout {
  @Link mIncomingVM: IncomingComVM;
  @State touchDown: boolean = false;
  @State scaleX: number = 1;
  @State scaleY: number = 1;
  @Link scrollX: number;
  @Link scrollXLockCon: number;
  private downX: number = 0;
  private moveX: number = 0;
  private left: number = -90;
  private right: number = 90;
  @StorageProp('curBp') curBp: string = '';
  @State circleColor: string = '#FFFFFF';
  @State fillOp: number = 1;
  @State viOp: Visibility = Visibility.Visible;
  @State isStartAnimation: boolean = false;
  private centerCirclePoint: number = 0;
  @Link isVideoCall: boolean;
  @StorageLink('LandscapeOrPortrait') @Watch('landscapeOrPortraitchange') landscapeOrPortrait: number = 1;
  @State space: number = 148
  @StorageLink('isRTL') isRTL: boolean = false;
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  @StorageLink('newFoldSplitPortraitScreenType') newFoldSplitPortraitScreenType: SplitScreenType =
    SplitScreenType.DEFAULT;
  private isDisappear: boolean = false;

  private onReject() {
    this.circleColor = '#E84826';
    this.scrollX = this.left;
    AppStorage.setOrCreate('lockAnswerOn', false);
    this.mIncomingVM.onReject();
  }

  /**
   * Answer the phone interface
   */
  private onAnswer() {
    LogUtils.i(TAG, 'onAnswer :');
    this.circleColor = '#64BB5C';
    this.scrollX = this.right;
    AppStorage.setOrCreate('lockAnswerOn', true);
    this.mIncomingVM.onAnswer(this.isVideoCall);
    let isSuperPrivacy: boolean | undefined = AppStorage.get('isSuperPrivacy');
    if (isSuperPrivacy) {
      this.returnToOrigin();
    }
  }

  returnToOrigin() {
    LogUtils.i(TAG, 'return to origin');
    // Reset color to initial state before animation
    this.circleColor = '#FFFFFF';
    this.touchDown = false;
    this.fillOp = 1;
    this.viOp = Visibility.Visible;
    animateTo({
      curve: curves.interpolatingSpring(0, 1, 439, 42), onFinish: () => {
      }
    }, () => {
      this.scaleY = this.scaleX = 1;
      this.scrollX = 0;
      LogUtils.i(TAG, 'circle return Origin');
    })
  }

  private getDistance() {
    let scrollDistance = this.moveX - this.downX;
    if (scrollDistance >= this.right) {
      this.circleColor = this.isRTL ? '#E84826' : '#64BB5C';
      scrollDistance = this.right;
    } else if (scrollDistance <= this.left) {
      this.circleColor = this.isRTL ? '#64BB5C' : '#E84826';
      scrollDistance = this.left;
    } else {
      this.circleColor = '#FFFFFF';
    }

    this.scrollX = scrollDistance;
    if (this.scrollX > 0) {
      this.scaleY = this.scaleX = 1 - this.scrollX / this.right * 0.2;
    }
    if (this.scrollX < 0) {
      this.scaleY = this.scaleX = 1 - this.scrollX / this.left * 0.2;
    }
    return scrollDistance;
  }

  touchEvent(event: TouchEvent) {
    hiTraceMeter.startTrace('LockIncomingCom', 1188);
    LogUtils.i(TAG, `touchEvent ${event.type}`);
    switch (event.type) {
      case TouchType.Down:
        this.eventTouchDownFunc(event);
        break;
      case TouchType.Move:
        this.moveX = event.touches[0].screenX;
        this.getDistance();
        break;
      case TouchType.Up:
        this.eventTouchUpFunc(event);
        break;
      case TouchType.Cancel:
        this.returnToOrigin();
        break;
    }
    hiTraceMeter.finishTrace('LockIncomingCom', 1188);
  }

  private eventTouchDownFunc(event: TouchEvent) {
    if (event.touches[0].x > 0 && event.touches[0].x <= 70 && event.touches[0].y >= 0 && event.touches[0].y <= 70) {
      let answerX: number | undefined = AppStorage.get<number>('LockIncomingCenterPoint');
      this.right = answerX!! - this.centerCirclePoint - CIRCLE_OFFSET;
      if (this.isRTL) {
        this.right = -(answerX!! - this.centerCirclePoint + CIRCLE_OFFSET);
      }
      this.left = -this.right;
      AppStorage.setOrCreate('LockIncomingTranslate', this.right);
      this.touchDown = true;
      this.downX = event.touches[0].screenX;
      this.moveX = this.downX;
      this.fillOp = 0;
      this.viOp = Visibility.Hidden;
      LogUtils.i(TAG, `touchEvent downX:${JSON.stringify(this.downX)}`);
    }
  }

  private eventTouchUpFunc(event: TouchEvent) {
    if (this.isDisappear) {
      return;
    }
    let scrollDistance = this.getDistance();
    this.moveX = event.touches[0].x;
    LogUtils.i(TAG, `touchEvent up scollDistance:${JSON.stringify(scrollDistance)}`);
    if ((scrollDistance >= 0 && scrollDistance < this.right) || (scrollDistance <= 0 && scrollDistance > this.left)) {
      this.returnToOrigin();
    } else {
      LogUtils.i(TAG, 'scrollDistance' + this.scrollX);
      if (this.isRTL) {
        this.scrollX > 0 ? this.onReject() : this.onAnswer();
      } else {
        this.scrollX > 0 ? this.onAnswer() : this.onReject();
      }
      if (this.mIncomingVM.hasSecondaryIncoming()) {
        // We should reset the animation state when secondary incoming call exists
        this.returnToOrigin();
      }
    }
  }

  aboutToDisappear() {
    this.isDisappear = true;
    LogUtils.i(TAG, 'aboutToDisappear: isStartAnimation = ' + this.isStartAnimation);
  }

  landscapeOrPortraitchange() {
    if (this.landscapeOrPortrait === 1) {
      // Portrait
      this.space = 148;
    } else {
      // Landscape
      this.space = 182;
    }
  }

  build() {
    Stack() {
      CometsEmit({
        touchDown: this.touchDown
      })
      this.StackCircle();
    }
    .width(this.isNewFoldPhoneExternalScreen ? 'calc(100% - 132vp)' : this.curBp === 'sm' ? 160 : this.space)
    .id('callui_ParticleLayout_Stack')
  }

  @Builder
  StackCircle() {
    Stack() {
      Circle()
        .width(this.isNewFoldPhoneExternalScreen || this.newFoldSplitPortraitScreenType > SplitScreenType.DEFAULT ?
          64 : 70)
        .height(this.isNewFoldPhoneExternalScreen || this.newFoldSplitPortraitScreenType > SplitScreenType.DEFAULT ?
          64 : 70)
        .fillOpacity(0)
        .strokeOpacity(1)
        .stroke(this.circleColor)
        .strokeWidth(1.25)
        .draggable(false)
        .id('callUI_animation_ParticleLayout_stack_circle_circleColor')
        .onAreaChange((oldValue: Area, newValue: Area) => {
          LogUtils.i(TAG, 'oldValue is' + oldValue + ' ,newValue is' + newValue);
        })

      Circle()
        .width(2)
        .height(2)
        .stroke('white')
        .fillOpacity(this.fillOp)
        .fill(Color.White)
        .draggable(false)
        .visibility(this.viOp)
        .id('callUI_animation_ParticleLayout_stack_circle_fillOp');
    }
    .scale({ x: this.scaleX, y: this.scaleY })
    .onAreaChange((oldValue: Area, newValue: Area) => {
      this.centerCirclePoint = Number(newValue.globalPosition.x) + 35;
    })
    .onTouch((event: TouchEvent) => {
      this.touchEvent(event);
    })
    .translate({ x: this.scrollX })
  }
}
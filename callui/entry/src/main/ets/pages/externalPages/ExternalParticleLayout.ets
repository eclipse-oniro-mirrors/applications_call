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

import curves from '@ohos.curves';
import LogUtils from '../../common/utils/LogUtils';
import * as Constants from '../../common/utils/Constants';
import DefaultCallData from '../../common/struct/TypeUtils';
import { isIncomingCall, isIncomingVoiceSilencedCall, isSilencedCall,
  isVideoCall } from '../../common/utils/CallListHelper';
import { ExternalCallModel } from '../../model/ExternalCallModel';
import { image } from '@kit.ImageKit';

const TAG = 'ExternalParticleLayout';
const LEFT_DISTANCE: number = -65;
const RIGHT_DISTANCE: number = 65;
const BOTTOM_DISTANCE: number = 65;
const IMAGE_WIDTH: number = 72;
const IMAGE_HEIGHT: number = 72;
const SCALE_MODIFY: number = 0.2;
const PSD_IMAGE_WIDTH: number = 64;
const PSD_IMAGE_HEIGHT: number = 64;

@Component
export default struct ExternalParticleLayout {
  @Link touchDown: boolean;
  @State scrollX: number = 0;
  @State scrollY: number = 0;
  @Link scaleLeftX: number;
  @Link scaleLeftY: number;
  @Link scaleRightX: number;
  @Link scaleRightY: number;
  @Link scaleButtonX: number;
  @Link scaleButtonY: number;
  @State isHorizontalMove: boolean = false;
  @State isVerticalMove: boolean = false;
  @Consume('contactImage') contactImage: Resource | null | image.PixelMap | undefined;
  @Consume('leftValue') leftValue: number;
  @Consume('leftAngle') leftAngle: number;
  @Consume('rightValue') rightValue: number;
  @Consume('rightAngle') rightAngle: number;
  @Consume('bottomValue') bottomValue: number;
  @Consume('bottomAngle') bottomAngle: number;
  @StorageProp(Constants.CALL_DATA) callData: DefaultCallData = new DefaultCallData();
  private downX: number = 0;
  private downY: number = 0;
  private moveX: number = 0;
  private moveY: number = 0;
  private isPsd: boolean = ExternalCallModel.sIsPsd;

  aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear');
  }

  aboutToDisappear() {
    LogUtils.i(TAG, 'aboutToDisappear');
  }

  private returnToOrigin() {
    animateTo({
      curve: curves.interpolatingSpring(0, 1, 439, 42), onFinish: () => {
        this.isHorizontalMove = false;
        this.isVerticalMove = false;
      }
    }, () => {
      this.scrollX = 0;
      this.scrollY = 0;
      this.leftValue = Constants.MIN_ANGLE;
      this.rightValue = Constants.MIN_ANGLE;
      this.bottomValue = Constants.MIN_ANGLE;
      this.leftAngle = Constants.LEFT_ANGLE - Constants.MIN_ANGLE / Constants.ANGLE_DIVIDE;
      this.rightAngle = Constants.RIGHT_ANGLE - Constants.MIN_ANGLE / Constants.ANGLE_DIVIDE;
      this.bottomAngle = Constants.BOTTOM_ANGLE - Constants.MIN_ANGLE / Constants.ANGLE_DIVIDE;
      this.scaleLeftX = this.scaleLeftY = this.scaleRightX = this.scaleRightY =
        this.scaleButtonX = this.scaleButtonY = Constants.FULL_SCALE;
    })
  }

  private touchEvent(event: TouchEvent) {
    if (event.type == TouchType.Down) {
      this.onDown(event);
    }
    if (event.type == TouchType.Move) {
      this.onMove(event);
    }
    let scrollDistanceX = this.moveX - this.downX;
    let scrollDistanceY = this.moveY - this.downY;
    if (!isIncomingCall(this.callData.callState)) {
      this.handleVerticalMove(scrollDistanceY);
    } else {
      if (!(isSilencedCall(this.callData) && !isVideoCall(this.callData.videoState)) && scrollDistanceY > 0 &&
        Math.abs(scrollDistanceX) < Math.abs(scrollDistanceY)) {
        this.handleVerticalMove(scrollDistanceY);
      } else {
        this.handleHorizontalMove(scrollDistanceX);
      }
    }
    if (event.type == TouchType.Up) {
      this.onUp(event, scrollDistanceX, scrollDistanceY);
    }
  }

  private onDown(event: TouchEvent) {
    this.touchDown = true;
    if (event.touches[0].x > 0 && event.touches[0].x <= IMAGE_WIDTH && event.touches[0].y >= 0 &&
      event.touches[0].y <= IMAGE_HEIGHT) {
      this.downX = event.touches[0].windowX;
      this.downY = event.touches[0].windowY;
      this.moveX = this.downX;
      this.moveY = this.downY;
    }
  }

  private onUp(event: TouchEvent, scrollDistanceX: number, scrollDistanceY: number) {
    this.touchDown = false;
    if (this.isHorizontalMove && ((scrollDistanceX >= 0 && scrollDistanceX < RIGHT_DISTANCE) ||
      (scrollDistanceX <= 0 && scrollDistanceX > LEFT_DISTANCE))) {
      this.returnToOrigin();
      return;
    }
    if (this.isVerticalMove && scrollDistanceY < BOTTOM_DISTANCE) {
      this.returnToOrigin();
      return;
    }
    if (this.isVerticalMove) {
      ExternalCallModel.onBottomMethod();
      this.returnToOrigin();
      return;
    }
    if (this.isHorizontalMove) {
      this.scrollX > 0 ? ExternalCallModel.onRightMethod() : ExternalCallModel.onLeftMethod();
      this.returnToOrigin();
    }
  }

  private onMove(event: TouchEvent) {
    this.moveX = event.touches[0].windowX;
    this.moveY = event.touches[0].windowY;
  }

  private handleHorizontalMove(scrollDistanceX: number) {
    this.isHorizontalMove = true;
    this.isVerticalMove = false;
    if (scrollDistanceX >= RIGHT_DISTANCE) {
      scrollDistanceX = RIGHT_DISTANCE;
    } else if (scrollDistanceX <= LEFT_DISTANCE) {
      scrollDistanceX = LEFT_DISTANCE;
    }

    this.scrollX = scrollDistanceX;
    if (this.scrollX > 0) {
      this.scaleRightY = this.scaleRightX = Constants.FULL_SCALE - this.scrollX / RIGHT_DISTANCE * SCALE_MODIFY;
      this.rightValue = Constants.MIN_ANGLE + this.scrollX / RIGHT_DISTANCE *
        (Constants.MAX_ANGLE - Constants.MIN_ANGLE);
      this.rightAngle = Constants.RIGHT_ANGLE - this.rightValue / Constants.ANGLE_DIVIDE;
    }
    if (this.scrollX < 0) {
      this.scaleLeftY = this.scaleLeftX = Constants.FULL_SCALE - this.scrollX / LEFT_DISTANCE * SCALE_MODIFY;
      this.leftValue = Constants.MIN_ANGLE + this.scrollX / LEFT_DISTANCE *
        (Constants.MAX_ANGLE - Constants.MIN_ANGLE);
      this.leftAngle = Constants.LEFT_ANGLE - this.leftValue / Constants.ANGLE_DIVIDE;
    }
  }

  private handleVerticalMove(scrollDistanceY: number) {
    if (scrollDistanceY <= 0 || isIncomingVoiceSilencedCall(this.callData)) {
      this.scrollY = 0;
      return;
    }
    this.isHorizontalMove = false;
    this.isVerticalMove = true;
    if (scrollDistanceY >= BOTTOM_DISTANCE) {
      scrollDistanceY = BOTTOM_DISTANCE;
    }
    this.scrollY = scrollDistanceY;
    this.scaleButtonY = this.scaleButtonX = Constants.FULL_SCALE - this.scrollY / BOTTOM_DISTANCE * SCALE_MODIFY;
    this.bottomValue = Constants.MIN_ANGLE + this.scrollY / BOTTOM_DISTANCE *
      (Constants.MAX_ANGLE - Constants.MIN_ANGLE);
    this.bottomAngle = Constants.BOTTOM_ANGLE - this.bottomValue / Constants.ANGLE_DIVIDE;
  }

  build() {
    Stack() {
      Circle()
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Black)
      Image(this.contactImage)
        .onError((err) => {
          this.contactImage = $r('app.media.ic_user_40_40dark');
          LogUtils.e(TAG, 'Err loading contactImage : ' + err.message);
        })
        .clip(true) // If clip not true, the rounded corners of the component do not limit the Image component.
        .borderRadius($r('sys.float.corner_radius_level16'))
        .draggable(false)
    }
    .width(this.isPsd ? `${PSD_IMAGE_WIDTH}vp` : `${IMAGE_WIDTH}vp`)
    .height(this.isPsd ? `${PSD_IMAGE_HEIGHT}vp` : `${IMAGE_HEIGHT}vp`)
    .onTouch((event: TouchEvent) => {
      this.touchEvent(event);
    })
    .translate({ x: this.isHorizontalMove ? this.scrollX : 0, y: this.isVerticalMove ? this.scrollY : 0 })
    .margin({ top: this.isPsd ? '13.5vp' : '9.75vp' })
  }
}

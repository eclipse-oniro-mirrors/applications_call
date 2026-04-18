/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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
import { LeatherEmit } from './LeatherEmit';

const MAX_OFFSET = 18;

@Component
export default struct LeatherAnsweringLayout {
  @Link scrollY: number;
  @Link answerVisible: Visibility;
  @Prop isPrivacyMode: boolean = false;
  @Prop isWideMode: boolean = true;
  @State touchDown: boolean = false;
  @State circleColor: string = '#FFFFFF';
  @State scaleX: number = 1;
  @State scaleY: number = 1;
  @State viOp: Visibility = Visibility.Visible;
  public onAnswerCallBack: () => void = () => {
  };
  public onRejectCallBack: () => void = () => {
  };
  private upWide: number = -120 + MAX_OFFSET;
  private downWide: number = 120 - MAX_OFFSET;
  private up: number = -100 + MAX_OFFSET;
  private down: number = 100 - MAX_OFFSET;
  private downY: number = 0;
  private moveY: number = 0;
  private lastMoveY: number = 0;

  build() {
    Stack({ alignContent: Alignment.Center }) {
      LeatherEmit({
        isIncoming: true,
        touchDown: this.touchDown,
        isWideMode: this.isWideMode
      })
      this.StackCircle()
    }
    .height(this.isWideMode ? 168 + 64 * 2 : 168 + 32 * 2)
  }

  @Builder
  StackCircle() {
    Stack() {
      Circle()
        .width(this.isWideMode ? $r('app.float.leather_circle_wide_width') : $r('app.float.leather_circle_width'))
        .height(this.isWideMode ? $r('app.float.leather_circle_wide_width') : $r('app.float.leather_circle_width'))
        .fillOpacity(0)
        .strokeOpacity(1)
        .stroke(this.circleColor)
        .strokeWidth(2)
        .draggable(false)
        .id('callUI_animation_ParticleLayout_stack_circle_circleColor');

      Circle()
        .width(2)
        .height(2)
        .stroke('white')
        .fillOpacity(1)
        .fill(Color.White)
        .draggable(false)
        .visibility(this.viOp)
        .id('callUI_animation_ParticleLayout_stack_circle_fillOp');
    }
    .scale({ x: this.scaleX, y: this.scaleY })
    .onTouch((event: TouchEvent) => {
      this.touchEvent(event);
    })
    .translate({ y: this.scrollY })
  }

  touchEvent(event: TouchEvent) {
    if (event.type == TouchType.Down && event.touches[0].y > 0 &&
      event.touches[0].y <= (this.isWideMode ? this.downWide : this.down)) {
      this.eventTouchDownFunc(event);
    }

    if (event.type == TouchType.Move) {
      this.moveY = event.touches[0].screenY;
    }

    let scrollDistance = this.moveY - this.downY + this.lastMoveY;
    if (scrollDistance >= (this.isWideMode ? this.downWide : this.down)) {
      this.circleColor = '#E84826';
      scrollDistance = (this.isWideMode ? this.downWide : this.down);
    } else if (scrollDistance <= (this.isWideMode ? this.upWide : this.up)) {
      this.circleColor = '#64BB5C';
      scrollDistance = (this.isWideMode ? this.upWide : this.up);
    } else {
      this.circleColor = '#FFFFFF';
    }

    this.scrollY = scrollDistance;

    if (this.scrollY > 0) {
      this.scaleY = this.scaleX = 1 - this.scrollY / (this.isWideMode ? this.downWide : this.down) * 0.2;
    }
    if (this.scrollY < 0) {
      this.scaleY = this.scaleX = 1 - this.scrollY / (this.isWideMode ? this.upWide : this.up) * 0.2;
    }
    if (event.type == TouchType.Up) {
      this.eventTouchUpFunc(event, scrollDistance);
    }
  }

  private eventTouchDownFunc(event: TouchEvent) {
    this.touchDown = true;
    this.downY = event.touches[0].screenY;
    this.moveY = this.downY;
    this.viOp = Visibility.Hidden;
  }

  private eventTouchUpFunc(event: TouchEvent, scrollDistance: number) {
    this.moveY = event.touches[0].y;
    if ((scrollDistance >= 0 && scrollDistance < (this.isWideMode ? this.downWide : this.down)) ||
      (scrollDistance <= 0 && scrollDistance > (this.isWideMode ? this.upWide : this.up))) {
      this.returnToOrigin();
    } else if (this.isPrivacyMode && this.scrollY < 0) {
      this.returnToOrigin();
      AppStorage.setOrCreate('superShow', true);
    } else {
      this.scrollY > 0 ? this.onReject() : this.onAnswer();
    }
    this.lastMoveY = this.scrollY;
  }

  private onReject() {
    this.scrollY = (this.isWideMode ? this.downWide : this.down);
    this.onRejectCallBack();
  }

  private onAnswer() {
    this.scrollY = (this.isWideMode ? this.upWide : this.up);
    this.answerVisible = Visibility.Hidden;
    this.onAnswerCallBack();
  }

  returnToOrigin() {
    this.touchDown = false;
    this.circleColor = '#FFFFFF';
    this.viOp = Visibility.Visible;
    if (this.isPrivacyMode) {
      this.scaleX = 1;
      this.scaleY = 1;
    }
    animateTo({
      curve: curves.interpolatingSpring(0, 1, 439, 42), onFinish: () => {
      }
    }, () => {
      this.scrollY = (this.lastMoveY == (this.isWideMode ? this.downWide : this.down) ||
        this.lastMoveY == (this.isWideMode ? this.upWide : this.up)) ? this.lastMoveY : 0;
    })
  }
}
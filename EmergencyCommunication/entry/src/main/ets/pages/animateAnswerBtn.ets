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
import { CallPageButtonStyle } from '../emergencyrescue/attributemodifier/EmergencyRescueCommonStyle';

const TAG = 'AnimateAnswerBtn';

@ComponentV2
export struct AnimateAnswerBtn {
  private answerBtnBcgColor: Resource = $r('sys.color.confirm');
  @Local innerScaleX: number = 0.88;
  @Local innerScaleY: number = 0.88;
  @Local middleScaleX: number = 1.2;
  @Local middleScaleY: number = 1.2;
  @Local outerScaleX: number = 1.4;
  @Local outerScaleY: number = 1.4;
  @Local outerOpacity: number = 0.08;
  @Local isStopAnimation: boolean = false;
  @Local animationCount: number = 0;

  private startIncomingAnimation() {
    this.showIncomingA();
    this.circleTwoA();
    this.circleThreeScaleA();
    this.circleThreeAlphaA();
    this.animationCount = 0;
  }

  private showIncomingA(): void {
    animateTo({
      duration: 300, curve: Curve.FastOutSlowIn, onFinish: () => {
        this.showIncomingB();
      }
    }, () => {
      this.innerScaleX = 1;
      this.innerScaleY = 1;
    })
  }

  private showIncomingB(): void {
    animateTo({
      duration: 700, curve: Curve.FastOutSlowIn, onFinish: () => {
        if (this.isStopAnimation) {
          return;
        }
        this.animationCount++;
        if (this.animationCount === 4) {
          this.startIncomingAnimation();
        }
      }
    }, () => {
      this.innerScaleX = 0.88;
      this.innerScaleY = 0.88;
    })
  }

  private circleTwoA(): void {
    animateTo({
      duration: 200, curve: Curve.FastOutSlowIn, onFinish: () => {
        this.circleTwoB();
      }
    }, () => {
      this.middleScaleX = 1.1;
      this.middleScaleY = 1.1;
    })
  }

  private circleTwoB(): void {
    animateTo({
      duration: 250, curve: Curve.FastOutSlowIn, onFinish: () => {
        this.circleTwoC();
      }
    }, () => {
      this.middleScaleX = 1.4;
      this.middleScaleY = 1.4;
    })
  }

  private circleTwoC(): void {
    animateTo({
      duration: 550, curve: Curve.FastOutSlowIn, onFinish: () => {
        if (this.isStopAnimation) {
          return;
        }
        this.animationCount++;
        if (this.animationCount === 4) {
          this.startIncomingAnimation();
        }
      }
    }, () => {
      this.middleScaleX = 1.2;
      this.middleScaleY = 1.2;
    })
  }

  private circleThreeScaleA(): void {
    animateTo({
      duration: 250, curve: Curve.FastOutSlowIn, onFinish: () => {
        this.circleThreeScaleB();
      }
    }, () => {
      this.outerScaleX = 1.3;
      this.outerScaleY = 1.3;
    })
  }

  private circleThreeScaleB(): void {
    animateTo({
      duration: 383, curve: Curve.FastOutSlowIn, onFinish: () => {
        this.circleThreeScaleC();
      }
    }, () => {
      this.outerScaleX = 1.7;
      this.outerScaleY = 1.7;
    })
  }

  private circleThreeScaleC(): void {
    animateTo({
      duration: 367, curve: Curve.FastOutSlowIn, onFinish: () => {
        if (this.isStopAnimation) {
          return;
        }
        this.animationCount++;
        if (this.animationCount === 4) {
          this.startIncomingAnimation();
        }
      }
    }, () => {
      this.outerScaleX = 1.4;
      this.outerScaleY = 1.4;
    })
  }

  private circleThreeAlphaA(): void {
    animateTo({
      duration: 283,
      delay: 350,
      curve: Curve.Sharp,
      onFinish: () => {
        this.circleThreeAlphaB();
      }
    }, () => {
      this.outerOpacity = 0.11;
    })
  }

  private circleThreeAlphaB(): void {
    animateTo({
      duration: 367, curve: Curve.Sharp, onFinish: () => {
        if (this.isStopAnimation) {
          return;
        }
        this.animationCount++;
        if (this.animationCount === 4) {
          this.startIncomingAnimation();
        }
      }
    }, () => {
      this.outerOpacity = 0.08;
    })
  }

  build() {
    Stack() {
      Button()
        .backgroundColor(this.answerBtnBcgColor)
        .scale({ x: this.innerScaleX, y: this.innerScaleY })
        .btnStyle()

      Button()
        .backgroundColor(this.answerBtnBcgColor)
        .opacity(0.18)
        .scale({ x: this.middleScaleX, y: this.middleScaleY })
        .btnStyle()

      Button()
        .backgroundColor(this.answerBtnBcgColor)
        .opacity(this.outerOpacity)
        .scale({ x: this.outerScaleX, y: this.outerScaleY })
        .btnStyle()

      SymbolGlyph($r('sys.symbol.phone_fill'))
        .fontColor(['#FFFFFF'])
        .scale({ x: this.innerScaleX, y: this.innerScaleY })
        .opacity(1)
        .draggable(false)
        .attributeModifier(new CallPageButtonStyle('symbolAnswer'))
    }
    .onAppear(() => {
      this.startIncomingAnimation();
    })
  }
}


@Extend(Button)
function btnStyle() {
  .width(64)
  .height(64)
}
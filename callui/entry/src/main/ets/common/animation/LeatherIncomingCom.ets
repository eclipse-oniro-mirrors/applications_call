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
import LeatherAnsweringLayout from './LeatherAnsweringLayout';

const MAX_OFFSET = 18;

@Component
export default struct LeatherIncomingCom {
  public onAnswerCallBack: () => void = () => {
  };
  public onRejectCallBack: () => void = () => {
  };
  @Prop isPrivacyMode: boolean = false;
  @Prop isWideMode: boolean = true;
  @State scrollY: number = 0;
  @State answerVisible: Visibility = Visibility.Visible;
  @State MAX_OFFSET:number = this.isWideMode ? 18 : 12.5;
  build() {
    Stack() {
      Column({ space: this.isWideMode ? 168 : 146 }) {
        this.anwserBtn();
        this.hungUpBtn();
      }

      LeatherAnsweringLayout({
        scrollY: $scrollY,
        answerVisible: $answerVisible,
        isPrivacyMode: this.isPrivacyMode,
        onAnswerCallBack: this.onAnswerCallBack,
        onRejectCallBack: this.onRejectCallBack,
        isWideMode: this.isWideMode
      })
    }
  }

  @Builder
  hungUpBtn() {
    Column() {
      SymbolGlyph($r('sys.symbol.phone_down_fill'))
        .fontSize(this.isWideMode ? $r('app.float.answer_button_image_width') :
        $r('app.float.leather_answer_button_image_width'))
        .fontColor(['#e84826'])
        .width(this.isWideMode ? $r('app.float.answer_button_image_width') :
        $r('app.float.leather_answer_button_image_width'))
        .height(this.isWideMode ? $r('app.float.answer_button_image_width') :
        $r('app.float.leather_answer_button_image_width'))
        .draggable(false)
        .id('callUI_animation_LockIncomingCom_hungUpBtn_Image_hung_up_icon')
        .translate({
          y: this.hungUpTranslate()
        })
        .rotate({ angle: this.isWideMode ? 0 : 90 })
    }
    .width(this.isWideMode ? $r('app.float.call_button_width') :
    $r('app.float.leather_answer_button_image_bgGiew_width'))
    .height(this.isWideMode ? $r('app.float.call_button_width') :
    $r('app.float.leather_answer_button_image_bgGiew_width'))
    .alignSelf(ItemAlign.Center)
    .justifyContent(FlexAlign.Center)
    .accessibilityLevel('yes')
  }

  @Builder
  anwserBtn() {
    Column() {
      SymbolGlyph($r('sys.symbol.phone_fill'))
        .fontSize(this.isWideMode ? $r('app.float.answer_button_image_width') :
        $r('app.float.leather_answer_button_image_width'))
        .fontColor(['#64BB5C'])
        .width(this.isWideMode ? $r('app.float.answer_button_image_width') :
        $r('app.float.leather_answer_button_image_width'))
        .height(this.isWideMode ? $r('app.float.answer_button_image_width') :
        $r('app.float.leather_answer_button_image_width'))
        .id('callUI_animation_LockIncomingCom_anwserBtn_Image_incomingIcon')
        .draggable(false)
        .visibility(this.answerVisible)
        .translate({
          y: this.anwserTranslate()
        })
        .rotate({
          angle: this.isWideMode ? 0 : 90,
        });
    }
    .width(this.isWideMode ? $r('app.float.call_button_width') :
    $r('app.float.leather_answer_button_image_bgGiew_width'))
    .height(this.isWideMode ? $r('app.float.call_button_width') :
    $r('app.float.leather_answer_button_image_bgGiew_width'))
    .alignSelf(ItemAlign.Center)
    .justifyContent(FlexAlign.Center)
    .accessibilityLevel('yes')
    .id('callUI_LockIncomingCom_answerBtn')
    .margin({
      top: 0
    })
  }

  private hungUpTranslate(): number {
    return this.scrollY > 0 ? -this.scrollY * 0.2 < -this.MAX_OFFSET ? -this.MAX_OFFSET : -this.scrollY * 0.2 : 0;
  }

  private anwserTranslate(): number {
    return this.scrollY < 0 ? -this.scrollY * 0.2 > this.MAX_OFFSET ? this.MAX_OFFSET : -this.scrollY * 0.2 : 0;
  }
}
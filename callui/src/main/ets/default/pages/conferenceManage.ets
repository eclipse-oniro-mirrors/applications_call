/**
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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
 * @file: Conference call
 */

import router from '@system.router';
import CallServiceProxy from "../model/callServiceProxy.ets";

@Entry
@Component
struct ConferenceManage {
  @State callList: any = [];
  mCallServiceProxy: CallServiceProxy= null;

  private aboutToAppear(): void {
    this.mCallServiceProxy = CallServiceProxy.getInstance()
  }

  /**
   * Return to the conference call interface by Lu You
   */
  returnBtn() {
    router.back();
  }

  /**
   * Call hangup interface
   *
   * @param {number} callID - callId
   */
  hangUp(callId) {
    this.mCallServiceProxy.hangUpCall(callId);
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center }) {
      Row() {
        Image('/common/return.png')
          .width(65)
          .height(65)
          .margin({ left: 52 })
          .onClick(() => {
            this.returnBtn()
          })

        Text($r("app.string.manageUsers"))
          .margin({ left: 36 })
          .fontSize(48)
          .fontColor(0xCCCCCC)
      }
      .width('100%')
      .height(112)
      .align(Alignment.Center)

      ForEach(this.callList, (item) => {
        Flex({ alignItems: ItemAlign.Center }) {
          Text('$item.accountNumber')
            .fontColor(0xCCCCCC)

          Image('/common/shunt.png')
            .margin({ top:34 })
            .margin({ left:42.78 })
            .width(60)
            .height(60)

          Image('/common/shuntHang.png')
            .margin({ top:34 })
            .margin({ left:54 })
            .width(60)
            .height(60)
        }
        .width('100%')
        .height(128)
        .onClick(() => {
          this.hangUp(item.callId);
        })

        Divider()
          .strokeWidth(1)
          .color(0X989A9C)
      })
    }
    .backgroundImage('common/wallpaper.png', ImageRepeat.NoRepeat)
    .backgroundImageSize(ImageSize.Cover)
    .height('100%')
  }
}
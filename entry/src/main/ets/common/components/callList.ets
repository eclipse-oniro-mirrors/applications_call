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
 * @file: User list component
 */

import CallStateConst from '../constant/CallStateConst';
import CallServiceProxy from '../../model/CallServiceProxy';
import app from '@system.app';
import LogUtils from '../utils/LogUtils';

const TAG = "CallList";
const font_color = "rgba(255, 255, 255, 0.60)";

@Component
export default struct callList {
  @State callList: any = [];
  @State callTimeList: any = [];
  @State callState: number = CallStateConst.CALL_STATUS_IDLE;
  @State callStateObj: any = {};
  @State callStateTextMap: object = {};
  private mCallStateConst: CallStateConst;
  private mCallServiceProxy: CallServiceProxy;

  public aboutToAppear(): void  {
    LogUtils.i(TAG, "aboutToAppear");
    this.mCallStateConst = new CallStateConst();
    this.mCallServiceProxy = CallServiceProxy.getInstance();
  }

  /**
   * Three-way call list
   *
   * @return {boolean} - Three-way call list
   */
  list() {
    let arr = this.callList.map((item) => {
      const obj = {};
      const callTimeObj = this.callTimeList.find((o) => o.callId === item.callId);
      callTimeObj && Object.assign(obj, {
        ...callTimeObj
      });
      return Object.assign({}, {
        ...obj,
        ...item
      });
    });
    return arr.filter((v) => v.callState !== CallStateConst.CALL_STATUS_WAITING);
  }

  /**
   * Phone number display
   *
   * @return {string} Phone number
   */
  public phoneNumber(item) {
    return item.accountNumber || $r('app.string.unknownNumber');
  }

  /**
   * Internationalized text
   *
   * @return {string} key - getCallStateText Internationalized text
   */
  public callStateText() {
    const key = this.mCallStateConst.getCallStateText(this.callState) || '';
    return key && $r(`app.string.${key}`);
  }

  /**
   * hang up
   *
   * @param {number} callId - callId
   */
  public onHangUp(callId) {
    this.mCallServiceProxy.hangUpCall(callId);
    if (this.callList.length === 1) {
      globalThis.calluiAbilityContext?.terminateSelf().then((data) => {
        LogUtils.i(TAG, "onHangUp terminateSelfCallBack");
      });
    }
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center }) {
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        List() {
          ForEach(this.list(), (item) => {
            ListItem() {
              Row() {
                Text(this.phoneNumber(item))
                  .fontColor('#fff')
                  .fontSize(30)

                Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
                  if (item.callState === CallStateConst.callStateObj.CALL_STATUS_ACTIVE) {
                    Text(item.callTime)
                      .margin({ left: 18 })
                      .fontColor('#fff')
                      .fontSize(30)
                      .opacity(0.60)

                    if (this.callState === CallStateConst.callStateObj.CALL_STATUS_WAITING) {
                      Column() {
                      }
                      .margin({ left: 30, bottom: 10 })
                      .width(50)
                      .height(40)
                      .backgroundImage("/assets/picture/userCall.png", ImageRepeat.NoRepeat)
                      .backgroundImageSize(50)
                      .onClick(() => {
                        this.onHangUp(this);
                      })
                    } else {
                      Column() {
                        Text(CallStateConst.callStateTextMap[item.callState])
                          .fontSize(28)
                          .fontColor(font_color)
                      }
                    }
                  }
                }
              }
            }
          })
        }
        .width('100%')
        .margin({ left: 48, right: 48 })
        .height(128)

        Divider()
          .color(Color.Gray)
      }
    }
    .backgroundColor(Color.Green)
    .width('100%')
    .height(256)
    .padding({ top: -100 })
  }
}
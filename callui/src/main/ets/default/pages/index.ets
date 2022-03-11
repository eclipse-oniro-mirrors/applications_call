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
 * @file: Main interface
 */

import ContactCard from '../common/components/ContactCard.ets';
import FuncBtnGroup from '../common/components/FuncBtnGroup.ets';
import Keyboard from '../common/components/Keyboard.ets';
import BottomBtn from '../common/components/BottomBtn.ets';
import IncomingCom from '../common/components/IncomingCom.ets';
import CallStateConst from '../common/constant/CallStateConst.ets';
import SendNotification from '../model/sendNotification.ets';
import NotificationManager from '../model/NotificationManager.ets';
import call from '@ohos.telephony.call';
import CallManager from '../model/CallManager.ets';
import HiLog from '../common/utils/Hilog.ets';
//import Test from "../common/components/Test.ets";

const TAG = "Index";
const prefixLog = 'callUI app:@ohos.telephony.call:';
const MARGIN_VALUE = 60;
const SIM_CARD_DELAYED_DISPLAY = 100;
const TIMER_DELAY = 0;
const textMap =
  {
    'answer': $r('app.string.answer'),
    'reject': $r('app.string.reject'),
    'hangUp': $r('app.string.hangUp'),
    'mute': $r('app.string.mute'),
    'callHold': $r('app.string.callHold'),
  };

/**
 * @file: Main interface
 */
@Entry
@Component
export default struct Index {
  @StorageLink("InputNum") inputNum: any = [];
  @State callData: any = CallStateConst.defaultCallData;
  @State isShowKeyboard: boolean = false;
  private appInactiveState = false
  @State callList: Array<any> = [];
  @State inputValue: string = '';
  private consoleTxt: '';
  private callStateConst;
  private contactCard;
  private funcBtnGroup;
  private sendNotificationHandle;
  private addCallBack;
  private notificationManager: NotificationManager;

  /**
   * Call status
   *
   * @return {number} -  callState
   */
  private callState() {
    return this.callData.callState;
  }

  /**
   * Input content
   *
   * @param {boolean} bool - Incoming value
   */
  public showKeyboard() {
    this.isShowKeyboard = !this.isShowKeyboard;
  }

  /**
   * Dialing function
   */
  public dialCall(phoneNumber, accountId = 0, videoState = 0, dialScene = 0) {
    HiLog.i(TAG, "dialCall phoneNumber : ")
    call.dial(phoneNumber, {
      accountId,
      videoState,
      dialScene
    });
  }
 
  /**
   * Create timer
   *
   * @param {number} newVal - Incoming number
   */
  onCallStateChange(newVal) {
    //    this.contactCard.onCallStateChange(newVal);
    //    let timer = setTimeout(() => {
    //      const funcBtnGroupDom = this.funcBtnGroup;
    //      if (funcBtnGroupDom && typeof funcBtnGroupDom.onCallStateChange === 'function') {
    //        funcBtnGroupDom.onCallStateChange(newVal);
    //      }
    //      clearTimeout(timer);
    //    }, TIMER_DELAY);
  }

  private aboutToAppear(): void {
    HiLog.i(TAG, "aboutToAppear :")
    this.callStateConst = new CallStateConst();
    this.notificationManager = new NotificationManager();
    globalThis.callManager = new CallManager(this)
    AppStorage.SetOrCreate<NotificationManager>('notificationManager', this.notificationManager);
    globalThis.callManager.addCallBack(this.onCallStateChange.bind(this));
    this.sendNotificationHandle = SendNotification;
    this.onCallStateChange(this.callData.callState);
    let delayMethod = setTimeout(() => {
      clearTimeout(delayMethod);
    }, SIM_CARD_DELAYED_DISPLAY);
    this.callStateConst = new CallStateConst();
    this.contactCard = new ContactCard();
    this.funcBtnGroup = new FuncBtnGroup();
  }

  onPageShow() {
    HiLog.i(TAG, "onPageShow : ")
    this.appInactiveState = false;
    this.notificationManager.cancelNotification();
    this.notificationManager.sendCapsuleNotification(this.callData, false);
    HiLog.i(TAG, "onPageShow end : " )
  }

  onPageHide() {
    HiLog.i(TAG, "onPageHide :")
    this.appInactiveState = true;
    const {callState, accountNumber, contactName, callId} = this.callData;
    let fool = (callState !== CallStateConst.callStateObj.CALL_STATUS_DISCONNECTED && callId)
    if (callState !== CallStateConst.callStateObj.CALL_STATUS_DISCONNECTED && callId) {
      const key = this.callStateConst.getCallStateText(callState) || '';
//      let callStateText = key ? textMap[key] : '';
//      if (callState === CallStateConst.callStateObj.CALL_STATUS_INCOMING) {
//        callStateText = $r("app.string.incomingCall")
//      }
//      if (callState === CallStateConst.callStateObj.CALL_STATUS_ACTIVE) {
//        callStateText = $r("app.string.calling")
//      }
      let text = contactName + '  ' + accountNumber + '  ';
      if (!contactName) {
        text = accountNumber + '  ' ;
      }
      this.notificationManager.sendNotification(text, this.callData);
      this.notificationManager.sendCapsuleNotification(this.callData, true);
      HiLog.i(TAG, "onPageHide end :  ")
    }
  }

  build() {
    Column() {
      Stack() {
        Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
          Column() {
            ContactCard({
              callData: $callData,
              isShowKeyboard: this.isShowKeyboard,
              kbCommand: this.inputValue,
              callList: $callList
            })
          }
          .margin({ top: 56 })

          if (this.callState() !== CallStateConst.callStateObj.CALL_STATUS_WAITING
          && this.callState() !== CallStateConst.callStateObj.CALL_STATUS_INCOMING) {
            Column() {
              if (!this.isShowKeyboard) {
                Column() {
                  FuncBtnGroup({ callData: $callData, callList: $callList })
                }
                .margin({ bottom: 29.5 })
              } else {
                Column() {
                  Keyboard({ callData: $callData })
                }
                .margin({ bottom: 32 })
              }

              Column() {
                BottomBtn({
                  callData: $callData,
                  onItemClick: () => {
                    this.showKeyboard()
                  }
                })
              }
            }
            .margin({ bottom: 106 })
          } else {
            Column() {
              IncomingCom({
                callData: $callData,
              })
            }
            .margin({ bottom: 106 })
          }
        }

//        Column() {
//          Test({
//            callData: $callData,
//            callList: $callList
//          })

//          Column() {
//            Button("拨号开始")
//              .onClick(() => {
//                console.info("wuchaoert" + this.inputNum.join().replace(/,/g, ""))
//                this.dialCall(this.inputNum.join().replace(/,/g, ""))
//              })
//          }
//          .margin({ top: 15 })

//        }
//        .position({
//          x: 15,
//          y: 15
//        })
      }
    }
    .width("100%")
    .height("100%")
    .backgroundImage('assets/picture/wallpaper.png', ImageRepeat.NoRepeat)
    .backgroundImageSize(ImageSize.Cover)
  }
}

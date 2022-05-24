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

import ContactCard from '../common/components/ContactCard';
import FuncBtnGroup from '../common/components/FuncBtnGroup';
import Keyboard from '../common/components/Keyboard';
import BottomBtn from '../common/components/BottomBtn';
import IncomingCom from '../common/components/IncomingCom';
import CallStateConst from '../common/constant/CallStateConst';
import NotificationManager from '../model/NotificationManager';
import call from '@ohos.telephony.call';
import CallManager from '../model/CallManager';
import HiLog from '../common/utils/Hilog';
import bundle from '@ohos.bundle';
import abilityAccessCtrl from "@ohos.abilityAccessCtrl";
import featureAbility from "@ohos.ability.featureAbility"

const TAG = "Index";
const prefixLog = 'callUI app:@ohos.telephony.call:';
const SIM_CARD_DELAYED_DISPLAY = 100;
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
  private consoleTxt: '';
  private callStateConst;
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
   * method to control the display of DTMF keyboard
   *
   * parent component pass by value child component
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


  private aboutToAppear(): void {
    HiLog.i(TAG, "aboutToAppear :")
    this.callStateConst = new CallStateConst();
    this.notificationManager = new NotificationManager();
    globalThis.callManager = new CallManager(this)
    AppStorage.SetOrCreate<NotificationManager>('notificationManager', this.notificationManager);
    let delayMethod = setTimeout(() => {
      clearTimeout(delayMethod);
    }, SIM_CARD_DELAYED_DISPLAY);
  }

  onPageShow() {
    HiLog.i(TAG, "onPageShow : ")
    this.appInactiveState = false;
    this.notificationManager.cancelNotification();
    this.notificationManager.sendCapsuleNotification(this.callData, false);
    this.initPermissions()
    HiLog.i(TAG, "onPageShow end : ")
  }

  async initPermissions() {
    let requestPermissions: Array<string> = ["ohos.permission.READ_CONTACTS", "ohos.permission.SEND_MESSAGES"];
    HiLog.i(TAG, "initPermissions requestPermissions : " + requestPermissions.length)
    if (requestPermissions.length > 0) {
      let context = featureAbility.getContext()
      context.requestPermissionsFromUser(requestPermissions, 2345, (results) => {
        let data:any = results;
        for (let i = 0;i < data.authResults.length; i++) {
          if(data.permissions[i] === "ohos.permission.READ_CONTACTS"){
            if (data.authResults[i] === 0) {
              globalThis.permissionFlag = true
              globalThis.callManager.update(this.callData)
            } else {
              globalThis.permissionFlag = false
              globalThis.sendPermissionFlag = true
            }
          }
          if(data.permissions[i] === "ohos.permission.SEND_MESSAGES"){
            if (data.authResults[i] === 0) {
              globalThis.sendPermissionFlag = true
            } else {
              globalThis.permissionFlag = true
              globalThis.callManager.update(this.callData)
              globalThis.sendPermissionFlag = false
            }
          }
        }
      })
    }
    HiLog.i(TAG, "Application requestPermissionsFromUser end")
  }

  onPageHide() {
    HiLog.i(TAG, "onPageHide :")
    this.appInactiveState = true;
    const {callState, accountNumber, contactName, callId} = this.callData;
    let fool = (callState !== CallStateConst.callStateObj.CALL_STATUS_DISCONNECTED && callId)
    if (callState !== CallStateConst.callStateObj.CALL_STATUS_DISCONNECTED && callId) {
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
              callList: $callList
            })
          }
          .margin({ top: 56 })

          if (this.callState() !== CallStateConst.callStateObj.CALL_STATUS_WAITING
          && this.callState() !== CallStateConst.callStateObj.CALL_STATUS_INCOMING) {
            Column() {
              Column() {
                Column() {
                  FuncBtnGroup({ callData: $callData, callList: $callList })
                }
                .margin({ bottom: 29.5 })
              }
              .visibility(!this.isShowKeyboard ? Visibility.Visible : Visibility.None)

              Column() {
                Column() {
                  Keyboard({ callData: $callData })
                }
                .margin({ bottom: 32 })
              }
              .visibility(this.isShowKeyboard ? Visibility.Visible : Visibility.None)

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
      }
    }
    .width("100%")
    .height("100%")
    .backgroundImage('assets/picture/wallpaper.png', ImageRepeat.NoRepeat)
    .backgroundImageSize(ImageSize.Cover)
  }
}

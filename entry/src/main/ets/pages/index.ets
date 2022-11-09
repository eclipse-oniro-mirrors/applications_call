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

import mediaQuery from '@ohos.mediaquery';
import wantAgent from '@ohos.wantAgent';
import ContactCard from '../common/components/ContactCard';
import FuncBtnGroup from '../common/components/FuncBtnGroup';
import BottomBtn from '../common/components/BottomBtn';
import Keyboard from '../common/components/Keyboard';
import IncomingCom from '../common/components/IncomingCom';
import CallStateConst from '../common/constant/CallStateConst';
import LogUtils from '../common/utils/LogUtils';
import byTrace from "@ohos.bytrace"
import NotificationManager from '../model/NotificationManager';
import CallManager from '../model/CallManager';
import backgroundTaskManager from '@ohos.backgroundTaskManager';
import Constants from '../common/utils/Constants';
import CallDataManager from '../model/CallDataManager';

const TAG = "MainAbility";

/**
 * @file: Main interface
 */
@Entry
@Component
struct Index {
  @StorageLink("InputNum") inputNum: any = [];
  @State callData: any = CallStateConst.defaultCallData;
  @State isShowKeyboard: boolean = false;
  @State callList: Array<any> = [];
  @State callTimeList: Array<any> = [];
  private notificationManager: NotificationManager;
  private mCallDataManager: CallDataManager;
  @State curBp: string = 'md';
  private smListener: mediaQuery.MediaQueryListener;
  private mdListener: mediaQuery.MediaQueryListener;
  private lgListener: mediaQuery.MediaQueryListener;
  isBreakpointSM = (mediaQueryResult) => {
    if (mediaQueryResult.matches) {
      this.curBp = 'sm'
      AppStorage.SetOrCreate('curBp', this.curBp)
    }
  }
  isBreakpointMD = (mediaQueryResult) => {
    if (mediaQueryResult.matches) {
      this.curBp = 'md'
      AppStorage.SetOrCreate('curBp', this.curBp)
    }
  }
  isBreakpointLG = (mediaQueryResult) => {
    if (mediaQueryResult.matches) {
      this.curBp = 'lg'
      AppStorage.SetOrCreate('curBp', this.curBp)
    }
  }

  aboutToAppear(): void {
    LogUtils.i(TAG, "aboutToAppear")
    byTrace.startTrace('aboutToAppear', 0);
    this.notificationManager = new NotificationManager();
    globalThis.callManager = new CallManager(this)
    AppStorage.SetOrCreate<NotificationManager>('notificationManager', this.notificationManager);
    this.mCallDataManager = CallDataManager.getInstance();
    byTrace.finishTrace('aboutToAppear', 0);
    this.smListener = mediaQuery.matchMediaSync('(320vp<width<=520vp)');
    this.smListener.on("change", this.isBreakpointSM);
    this.mdListener = mediaQuery.matchMediaSync('(520vp<width<=840vp)');
    this.mdListener.on("change", this.isBreakpointMD);
    this.lgListener = mediaQuery.matchMediaSync('(840vp<width)');
    this.lgListener.on("change", this.isBreakpointLG);
  }

  aboutToDisappear(): void {
    this.smListener.off('change', this.isBreakpointSM);
    this.mdListener.off('change', this.isBreakpointMD);
    this.lgListener.off('change', this.isBreakpointLG);
  }

  onPageShow() {
    LogUtils.i(TAG, "onPageShow")
    byTrace.startTrace('onPageShow', 1);
    globalThis.appInactiveState = false;
    this.stopBackgroundRunning();
    this.notificationManager.cancelNotification();
    this.notificationManager.sendCapsuleNotification(this.callData, false);
    byTrace.finishTrace('onPageShow', 1);
    LogUtils.i(TAG, "onPageShow end")
  }

  onPageHide() {
    LogUtils.i(TAG, "onPageHide")
    globalThis.appInactiveState = true;
    const {callState, accountNumber, contactName, callId} = this.callData;
    let fool = (callState !== CallStateConst.callStateObj.CALL_STATUS_DISCONNECTED && callId)
    if (callState !== CallStateConst.callStateObj.CALL_STATUS_DISCONNECTED && callId) {
      let text = '';
      if (contactName) {
        text = contactName + '  ' + accountNumber + '  ';
      } else {
        text = accountNumber + '  ';
      }
      if (this.mCallDataManager.hasAliveCall()) {
        this.startBackgroundRunning();
      }
      this.notificationManager.sendNotification(text, this.callData);
      this.notificationManager.sendCapsuleNotification(this.callData, true);
      LogUtils.i(TAG, "onPageHide end")
    }
  }

  aboutToDisappear() {
    LogUtils.i(TAG, "aboutToDisappear")
    this.stopBackgroundRunning();
  }

  private stopBackgroundRunning() {
    backgroundTaskManager.stopBackgroundRunning(globalThis.calluiAbilityContext).then(() => {
      LogUtils.i(TAG, "stopBackgroundRunning succeeded")
    }).catch((err) => {
      LogUtils.i(TAG, "stopBackgroundRunning failed")
    });
  }

  private startBackgroundRunning() {
    let wantAgentInfo = {
      wants: [{
                bundleName: Constants.CALL_BUNDLE_NAME,
                abilityName: Constants.CALL_ABILITY_NAME,
              }],
      requestCode: 0,
      operationType: wantAgent.OperationType.START_ABILITY,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };
    wantAgent.getWantAgent(wantAgentInfo).then((wantAgentObj) => {
      backgroundTaskManager.startBackgroundRunning(globalThis.calluiAbilityContext,
      backgroundTaskManager.BackgroundMode.VOIP, wantAgentObj).then(() => {
        LogUtils.i(TAG, "startBackgroundRunning succeeded")
      }).catch((err) => {
        LogUtils.i(TAG, "startBackgroundRunning failed cause:" + JSON.stringify(err))
      });
    });
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
   * Call status
   *
   * @return {number} -  callState
   */
  private callState() {
    LogUtils.i(TAG, "callState : " + this.callData.callState)
    return this.callData.callState;
  }

  build() {
    Flex({
      direction: FlexDirection.Column,
      alignItems: ItemAlign.Center,
      justifyContent: FlexAlign.SpaceBetween
    }) {
      ContactCard({
        callData: $callData,
        isShowKeyboard: this.isShowKeyboard,
        callList: $callList
      })
        .margin({ top: this.isShowKeyboard ? 0 : 56 })
        .layoutWeight(this.isShowKeyboard ? 1 : 0)
      if (this.callState() !== CallStateConst.callStateObj.CALL_STATUS_WAITING
      && this.callState() !== CallStateConst.callStateObj.CALL_STATUS_INCOMING) {
        Column() {
          if (!this.isShowKeyboard) {
            FuncBtnGroup({ callData: $callData, callList: $callList })
              .margin({ bottom: 32 })
          } else {
            Keyboard({ callData: $callData })
              .margin({ bottom: 32 })
          }
          BottomBtn({
            callData: $callData,
            onItemClick: () => {
              this.showKeyboard()
            }
          })
        }
      } else {
        IncomingCom({ callData: $callData })
      }
    }
    .padding({ bottom: 106 })
    .width("100%")
    .height("100%")
    .backgroundImage('assets/picture/wallpaper.png', ImageRepeat.NoRepeat)
    .backgroundImageSize(ImageSize.Cover)
  }
}

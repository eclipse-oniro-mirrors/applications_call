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

import DefaultCallData from '../common/struct/TypeUtils';
import CallTimeListStruct from '../common/struct/CallTimeListStruct';
import HiCarBottomBtn from '../common/components/hicar/HiCarBottomBtn';
import HiCarKeyboardPage from '../common/components/hicar/HiCarKeyboardPage';
import HiCarIncomingCom from '../common/components/hicar/HiCarIncomingCom';
import HiCarCallCard from '../common/components/hicar/HiCarCallCard';
import { isIncomingCall, isVideoCall } from '../common/utils/CallListHelper';
import ConferenceConst from '../common/constant/ConferenceConst';
import CallDataManager from '../model/CallDataManager';
import LogUtils from '../common/utils/LogUtils';
import * as Constants from '../common/utils/Constants';
import { HiCarManager } from '../model/HiCarManager';
import Utils from '../common/utils/utils';

const TAG = 'CallUIHiCarIndex';

/**
 * @file: Main interface
 */
@Component
@Entry
export struct IndexInHiCar {
  private oldLength: number = 0;
  @StorageLink('hangUp') mHangup: boolean = false;
  @StorageLink('isShowVideoKeyBoard') isShowKeyboard: boolean = false;
  @StorageProp(Constants.CALL_DATA) @Watch('getBtnCallState') callData: DefaultCallData = new DefaultCallData();
  @StorageProp(Constants.CALL_LIST) @Watch('getCallCount') callList: Array<DefaultCallData> = [];
  @State callTimeList: Array<CallTimeListStruct> = [];
  @State callListCount: number = 0;
  @State translateName: string = '0';
  @State translateTime: string = '0';
  @State contactAppear: boolean = true;
  @State isIncomingState: boolean = false;
  @State showConferenceDetail: boolean = false;
  @State isShowKeyboardPage: boolean = false;
  @State avoidAreaLeft: number = 0;
  @State avoidAreaRight: number = 0;
  @State avoidAreaTop: number = 0;
  @State avoidAreaBottom: number = 0;
  @State isShowSim: boolean = true;
  @Provide isConferenceMode: boolean = false;

  private getBtnCallState(): void {
    // For multi call case, the ANSWER state should be considered as incoming state
    // For video call case, the ANSWER state should be considered as active state
    let currentIncoming =
      isIncomingCall(this.callData.callState, this.callListCount > 1 && !isVideoCall(this.callData.videoState));
    if (this.isIncomingState === currentIncoming && this.callList.length === this.oldLength) {
      // Ignore if nothing updated
      return;
    }
    if (currentIncoming) {
      this.translateName = '0';
      this.translateTime = '0';
      this.contactAppear = true;
      this.showConferenceDetail = false;
    } else if (this.callList.length <= 1 && this.oldLength > 1) {
      this.translateName = '0';
      this.translateTime = '0';
      this.contactAppear = true;
    }
    this.isIncomingState = currentIncoming;
    this.oldLength = this.callList.length;
  }

  private getCallCount(): void {
    this.getBtnCallState();
    let hasConference: boolean = false;
    let callCount = 0;
    for (let i = 0; i < this.callList.length; i++) {
      let curCallData = this.callList[i];
      if (Utils.getInstance().isConferenceCall(curCallData)) {
        if (!hasConference) {
          hasConference = true;
          callCount++;
        }
      } else {
        callCount++;
      }
    }
    this.callListCount = callCount;
  }

  private checkSimCard(): void {
    let simCount = AppStorage.get('simCount') || 0;
    LogUtils.i(TAG, `checkSimCard simCount = ${simCount}`);
    if (simCount === -1) {
      LogUtils.i(TAG, 'checkSimCard -1');
      return;
    }
    this.isShowSim = simCount > 1;
  }

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    CallDataManager.getInstance().addTimeUpdateCallback((callTimeList: CallTimeListStruct[]) => {
      this.callTimeList = callTimeList;
    });
    this.getCallCount();
    this.checkSimCard();
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear');
    CallDataManager.getInstance().removeTimeUpdateListener();
  }

  onPageShow() {
    LogUtils.i(TAG, 'onPageShow');
    HiCarManager.getInstance().setIsHiCarPageShow(true);
    CallDataManager.getInstance().refreshCallTime();
  }

  onPageHide() {
    LogUtils.i(TAG, 'onPageHide');
    HiCarManager.getInstance().setIsHiCarPageShow(false);
  }

  @Builder
  buildCommonCallCard() {
    HiCarCallCard({
      callData: $callData,
      isShowKeyboard: this.isShowKeyboard,
      callList: $callList,
      callTimeList: $callTimeList,
      translateName: this.translateName,
      translateTime: this.translateTime,
      contactAppear: this.contactAppear,
      showConferenceDetail: $showConferenceDetail,
      callListCount: this.callListCount,
      hangup: $mHangup,
      isShowSim: this.isShowSim,
      isIncomingState: $isIncomingState
    })
  }

  @Builder
  buildIncomingBtns() {
    HiCarIncomingCom({
      callList: $callList,
      callData: $callData
    })
  }

  @Builder
  buildInCallBtns() {
    HiCarBottomBtn({
      callData: $callData,
      callList: $callList,
      hangup: $mHangup,
      callListCount: $callListCount,
      isShowKeyboardPage: $isShowKeyboardPage
    })
  }

  @Builder
  buildMainPage() {
    Column() {
      Column() {
        this.buildCommonCallCard()
      }
      .size({
        width: '100%',
        height: '60%'
      })
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)

      Column() {
        if (this.isIncomingState) {
          this.buildIncomingBtns()
        } else {
          this.buildInCallBtns()
        }
      }
      .size({
        width: '100%',
        height: '40%'
      })
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .size({
      width: '100%',
      height: '100%'
    })
    .backgroundColor('#000000')
    .zIndex(1)
  }

  @Builder
  buildKeyboardPage() {
    HiCarKeyboardPage({
      callData: $callData,
      callList: $callList,
      callListCount: $callListCount,
      hangup: $mHangup,
      isShowKeyboardPage: $isShowKeyboardPage
    })
      .backgroundColor('#000000')
      .zIndex(2)
  }

  build() {
    Stack() {
      this.buildMainPage()
      if (this.isShowKeyboardPage) {
        this.buildKeyboardPage()
      }
    }
    .size({
      width: '100%',
      height: '100%'
    })
    .padding({
      left: 16,
      right: 16
    })
    .backgroundColor('#000000')
  }
}
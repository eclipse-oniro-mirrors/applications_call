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

import LogUtils from '../../common/utils/LogUtils';
import callStateConst from '../../common/constant/CallStateConst';
import DefaultCallData, { getSimIcon } from '../../common/struct/TypeUtils';
import CallTimeListStruct from '../../common/struct/CallTimeListStruct';
import * as Constants from '../../common/utils/Constants';
import CallStateConst from '../../common/constant/CallStateConst';
import CallUtils from '../../common/utils/CallUtils';
import {
  isHdVideoRbt,
  isIncomingCall,
  isOutgoingCall,
  isUpgradingToVideo,
  isVideoCall
} from '../../common/utils/CallListHelper';
import CallDataManager from '../../model/CallDataManager';
import { getCallLabelPrimary, getCallLabelThird } from '../../common/utils/CallLabelUtils';
import { ExternalCallModel } from '../../model/ExternalCallModel';

const TAG = 'ExternalCallCard';
const TIME_BEGIN = '00:00';
const FADE_BLEND_INNER: number = 7;
const FADE_SCALE_OUTER: number = 1000;

@Component
export default struct ExternalCallCard {
  @State dialing: string = '.';
  @Prop callTimeList: Array<CallTimeListStruct>;
  @State visible1: Visibility = Visibility.Hidden;
  @State visible2: Visibility = Visibility.Hidden;
  @StorageProp(Constants.CALL_DATA) @Watch('onCallDataChange') callData: DefaultCallData = new DefaultCallData();
  @StorageProp('simOperatorNameFirst') simOperatorNameFirst: string = '';
  @StorageProp('simOperatorNameSecond') simOperatorNameSecond: string = '';
  @Consume('isConferenceMode') isConferenceMode: boolean;
  private isStartAnimation: boolean = false;
  private animateFlag: boolean = false;
  private array: Array<number> = [];
  private timer: number = Constants.INVALID_NUM;
  @State callState: number = -1;
  @State conferenceState: number = -1;
  @State contactName: string = '';
  @State accountId: number = -1;
  @State callId: number = -1;
  @State videoState: number = -1;
  @State callLabelPrimary: Resource | string = '';
  @State isToVideo: boolean = false;
  private isPsd: boolean = ExternalCallModel.sIsPsd;

  aboutToAppear(): void {
    this.refreshingData();
    LogUtils.i(TAG, 'aboutToAppear');
  }

  private dialingOperate(): void {
    if (this.callState === CallStateConst.CALL_STATUS_DIALING && this.timer === Constants.INVALID_NUM) {
      this.timer = setInterval(() => {
        if (this.dialing === '...') {
          this.dialing = '';
        }
        this.dialing += '.';
      }, 500);
    }
    if (this.callState !== CallStateConst.CALL_STATUS_DIALING && this.timer !== Constants.INVALID_NUM) {
      clearInterval(this.timer);
      this.timer = Constants.INVALID_NUM;
    }
  }

  private checkIsInConferenceHold(): boolean {
    let isInConferenceHold: boolean = false;
    let callList = CallDataManager.getInstance().callList;
    if (this.isConferenceMode && this.conferenceState) {
      for (let i = 0; i < callList.length; i++) {
        if (callList[i].conferenceState && callList[i].callState === CallStateConst
          .CALL_STATUS_HOLDING) {
          isInConferenceHold = true;
          break;
        }
      }
    }
    return isInConferenceHold;
  }

  refreshingData(): void {
    this.callState = this.callData.callState;
    this.conferenceState = this.callData.conferenceState;
    this.contactName = this.callData.contactName;
    this.accountId = this.callData.accountId;
    this.callId = this.callData.callId;
    this.videoState = this.callData.videoState;
    this.callLabelPrimary = getCallLabelPrimary(this.callData);
  }

  private onCallDataChange() {
    this.refreshingData();
    this.isToVideo = isUpgradingToVideo(this.callData);
    this.dialingOperate();
    if (this.checkStartAnimation()) {
      this.startAnimate();
      return;
    }
    if (this.checkStopAnimation()) {
      this.stopAnimation();
    }
  }

  private checkStartAnimation(): boolean {
    if (this.isStartAnimation) {
      return false;
    }
    if (!isIncomingCall(this.callState)) {
      return false;
    }
    if (!CallUtils.isMultiSimActive() && !this.contactName) {
      return false;
    }
    return true;
  }

  private checkStopAnimation(): boolean {
    if (this.isStartAnimation && !isIncomingCall(this.callState)) {
      return true;
    }
    return false;
  }

  private isShowTime(): boolean {
    if (this.callState === callStateConst.CALL_STATUS_ACTIVE ||
      this.callState === callStateConst.CALL_STATUS_ANSWER) {
      return true;
    }
    let callList = CallDataManager.getInstance().callList;
    if (callList.length === 1 && this.isConferenceMode) {
      return true;
    }

    return false;
  }

  private startAnimate() {
    this.isStartAnimation = true;
    this.animateFlag = !this.animateFlag;
    let oneId = setTimeout(() => {
      animateTo({ duration: 350, curve: Curve.Linear }, () => {
        if (this.animateFlag) {
          this.visible1 = this.visible1 === Visibility.Visible ? Visibility.Hidden : Visibility.Visible;
        } else {
          this.visible2 = this.visible2 === Visibility.Visible ? Visibility.Hidden : Visibility.Visible;
        }
      })
      let twoId = setTimeout(() => {
        animateTo({ duration: 350, curve: Curve.Linear }, () => {
          if (this.animateFlag) {
            this.visible1 = this.visible1 === Visibility.Visible ? Visibility.Hidden : Visibility.Visible;
          } else {
            this.visible2 = this.visible2 === Visibility.Visible ? Visibility.Hidden : Visibility.Visible;
          }
          let threeId = setTimeout(() => {
            this.startAnimate();
          }, 500);
          this.array.push(threeId);
        })
      }, 1500);
      this.array.push(twoId);
    }, 500)
    this.array.push(oneId);
  }

  private stopAnimation() {
    this.animateFlag = false;
    this.isStartAnimation = false;
    this.array.forEach((id: number) => {
      clearTimeout(id);
    })
    this.array = [];
    animateTo({ duration: 0 }, () => {
      LogUtils.i(TAG, 'stopAnimation');
      this.visible1 = Visibility.Hidden;
      this.visible2 = Visibility.Hidden;
    })
  }

  private getStatusDisplay(): Resource | string {
    if (this.isToVideo || (isOutgoingCall(this.callState) && isVideoCall(this.videoState)) ||
    isHdVideoRbt(this.callState, this.videoState)) {
      return $r('app.string.waitingInvitation');
    }
    if (this.isShowTime()) {
      return this.getPrimaryCallTime();
    }
    if (this.checkIsInConferenceHold()) {
      return $r('app.string.callHold');
    }
    return CallStateConst.callStateTextArray[this.callState];
  }

  private getPrimaryCallTime(): string {
    if (!this.callTimeList) {
      return TIME_BEGIN;
    }
    let index = this.callTimeList.findIndex((v: CallTimeListStruct) => v.callId === this.callId);
    if (index < 0 || index >= this.callTimeList.length || !this.callTimeList[index]) {
      return TIME_BEGIN;
    }
    return this.callTimeList[index].callTime;
  }

  private getNumberLocation() {
    if (this.callData.numberLocation) {
      return this.callData.numberLocation;
    } else {
      return this.callData.formatNumber;
    }
  }

  private getContactNumberOrCompany() {
    let callLabel = getCallLabelThird(this.callData);
    return callLabel !== '' ? callLabel : this.callData.formatNumber;
  }

  private getSimCardName(): string {
    if (!this.callData) {
      return '';
    }
    let simName = this.callData.accountId ? this.simOperatorNameSecond : this.simOperatorNameFirst;
    let contactNameOrCompanyInfo = this.callData.contactName ? ' ' + this.getContactNumberOrCompany() : '';
    return simName + contactNameOrCompanyInfo;
  }

  @Builder
  private cardInfoAndCallStatus() {
    if (!isIncomingCall(this.callState)) {
      this.callStatus();
    } else {
      if (CallUtils.isMultiSimActive()) {
        this.multiCardInfo();
      } else {
        this.singleCardInfo();
      }
    }
  }

  @Builder
  private callStatus() {
    Text(this.getStatusDisplay())
      .maxLines(1)
      .width('177vp')
      .textExtend(this.isPsd)
      .textAlign(TextAlign.Center)
      .margin({ top: this.isPsd ? '4vp' : '2vp' })
      .height(this.isPsd ? '19vp' : '21.5vp')
      .visibility(!isIncomingCall(this.callState) ? Visibility.Visible : Visibility.None)
  }

  @Builder
  private multiCardInfo() {
    Stack() {
      Row() {
        SymbolGlyph(getSimIcon(this.accountId))
          .fontColor(['#FFFFFF'])
          .fontSize(this.isPsd ? $r('app.float.call_conference_detail_list_titel_text_font') : $r('app.float.call_conference_detail_titel_font'))
          .opacity(0.7)
          .margin({ top: '1vp', right: '2vp' })

        Text(this.getSimCardName())
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textExtend(this.isPsd)
          .textAlign(TextAlign.Start)
          .height(this.isPsd ? '19vp' : '21.5vp')
      }
      .justifyContent(FlexAlign.Center)
      .height(this.isPsd ? '19vp' : '21.5vp')
      .width('166.5vp')
      .visibility(this.visible1)
      .margin({ bottom: 0 })

      Text(this.getNumberLocation())
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .visibility(this.visible2)
        .textExtend(this.isPsd)
        .textAlign(TextAlign.Center)
        .margin({ bottom: 0 })
    }
    .align(Alignment.Center)
    .width(this.isPsd ? '178vp' : '177vp')
    .height(this.isPsd ? '19vp' : '21.5vp')
    .margin({ top: this.isPsd ? '4vp' : '2vp' })
    .visibility(isIncomingCall(this.callState) ? Visibility.Visible : Visibility.None)
  }

  @Builder
  private singleCardInfo() {
    Stack() {
      Text(this.contactName ? this.getContactNumberOrCompany() : '')
        .maxLines(1)
        .textExtend(this.isPsd)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Center)
        .height(this.isPsd ? '19vp' : '21.5vp')
        .width('166.5vp')
        .visibility(this.callData.contactName ? this.visible1 : Visibility.None)
        .margin({ bottom: 0 })

      Text(this.getNumberLocation())
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .visibility(this.contactName ? this.visible2 : Visibility.Visible)
        .textExtend(this.isPsd)
        .textAlign(TextAlign.Center)
        .margin({ bottom: 0 })
        .height(this.isPsd ? '19vp' : '21.5vp')
    }
    .align(Alignment.Center)
    .width(this.isPsd ? '178vp' : '177vp')
    .height(this.isPsd ? '19vp' : '21.5vp')
    .margin({ top: this.isPsd ? '4vp' : '2vp' })
    .visibility(isIncomingCall(this.callState) ? Visibility.Visible : Visibility.None)
  }

  @Builder
  private nameAndNumber() {
    Stack() {
      Text(this.callLabelPrimary)
        .fontSize(this.isPsd ? '20vp' : '24vp')
        .lineHeight(this.isPsd ? '26vp' : '32vp')
        .textAlign(TextAlign.Center)
        .fontFamily('HarmonyHeiTi')
        .fontWeight(this.isPsd ? 600 : 'SemiBold')
        .fontColor('#ffffff')
        .textOverflow({ overflow: TextOverflow.MARQUEE })
      Column()
      .width('100%')
      .height('100%')
      .blendMode(FADE_BLEND_INNER)
      .linearGradient({
        direction: GradientDirection.Right,
        colors: [[Color.Transparent, 0], [$r('sys.color.ohos_id_color_text_primary_contrary'), 0.18],
          [$r('sys.color.ohos_id_color_text_primary_contrary'), 0.82], [Color.Transparent, 1]]
      })
    }
    .blendMode(FADE_SCALE_OUTER)
    .height(this.isPsd ? '26vp' : '32vp')
    .width(this.isPsd ? '178vp' : '135.5vp')
  }

  @Builder
  private dialingText() {
    RelativeContainer() {
      Text($r('app.string.dialing'))
        .textExtend(this.isPsd)
        .id('text')
        .alignRules({
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
      Text(this.dialing)
        .id('flag')
        .textExtend(this.isPsd)
        .alignRules({
          left: { anchor: 'text', align: HorizontalAlign.End }
        })
    }
    .margin({ top: '2vp' })
    .height(this.isPsd ? '19vp' : '21.5vp')
    .width(this.isPsd ? '178vp' : '177vp')
    .visibility(this.callState === CallStateConst.CALL_STATUS_DIALING ? Visibility.Visible :
    Visibility.None)
  }

  build() {
    Column() {
      this.nameAndNumber();
      if (this.callState === CallStateConst.CALL_STATUS_DIALING) {
        this.dialingText();
      } else {
        this.cardInfoAndCallStatus();
      }
    }
    .height(this.isPsd ? '47.5vp' : '55.5vp')
    .width(this.isPsd ? '178vp' : '177vp')
    .margin(this.isPsd ? { left: '12vp', right: '12vp', top: '8vp'} :
      { left: '24.5vp', right: '24.5vp', top: '12vp' })
    .onAppear(() => {
      LogUtils.i(TAG, 'onAppear');
      this.dialingOperate();
      if (this.checkStartAnimation()) {
        this.startAnimate();
      }
    })
  }
}

@Extend(Text)
function textExtend(isPsd?: boolean) {
  .fontSize(isPsd ? '14vp' : '16vp')
  .lineHeight(isPsd ? '19vp' : '21.5vp')
  .fontFamily('HarmonyHeiTi')
  .fontWeight('Regular')
  .fontColor($r('sys.color.ohos_id_color_text_secondary_dark'))
}

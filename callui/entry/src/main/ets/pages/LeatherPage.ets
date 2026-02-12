/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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

import CallStateConst from '../common/constant/CallStateConst';
import DefaultCallData, { callDataToSafeString, MarkType } from '../common/struct/TypeUtils';
import { isActiveCall, isIncomingCall, isOutgoingCall } from '../common/utils/CallListHelper';
import CallServiceProxy from '../model/CallServiceProxy';
import json from '@ohos.util.json';
import { preferences } from '@kit.ArkData';
import { systemDateTime } from '@kit.BasicServicesKit';
import LeatherIncomingCom from '../common/animation/LeatherIncomingCom';
import LeatherRejectCom from '../common/animation/LeatherRejectCom';
import ConferenceConst from '../common/constant/ConferenceConst';
import { call } from '@kit.TelephonyKit';
import i18n from '@ohos.i18n';
import { common } from '@kit.AbilityKit';
import { createQueryContactTask } from '../model/ContactManager';
import { Context } from '@kit.AbilityKit';
import LogUtils from '../common/utils/LogUtils';
import Utils from '../common/utils/utils';
import { ReportUtil } from '../common/utils/ReportUtils/ReportUtil';
import CallUtils from '../common/utils/CallUtils';

let localStorage = LocalStorage.getShared();

const TAG = 'LeatherPage';
const leatherPagePreferencesOptions: preferences.Options = { name: 'LeatherPagePreferences' };
const leatherPreferencesSuperPrivacy: string = 'leatherPreferencesSuperPrivacy';

const leatherWindowWidth: number = px2vp(300)
const overLongText:number = 358;
const shortText:number = 516;
const widescreenOutsideMargin: number = 74;
const widescreenRatio: number = 0.4;
const markTypes = [MarkType.MARK_TYPE_PROMOTE_SALES, MarkType.MARK_TYPE_HOUSE_AGENT, MarkType.MARK_TYPE_CRANK,
  MarkType.MARK_TYPE_EXPRESS, MarkType.MARK_TYPE_INSURANCE, MarkType.MARK_TYPE_TAXI, MarkType.MARK_TYPE_FRAUD];
interface SimpleButtonProps {
  text: Resource;
}

interface PredefinedMark extends SimpleButtonProps {
  markType: MarkType;
}

@Entry(localStorage)
@Component
struct LeatherPage {
  @State isSuperPrivacy: boolean = false;
  @State callList: Array<DefaultCallData> = [];
  @State callData: DefaultCallData = new DefaultCallData();
  @State firCallData: DefaultCallData = new DefaultCallData();
  @State titleText: ResourceStr = '';
  @State subTitleText: ResourceStr = '';
  @State firTitleText: ResourceStr = '';
  @State firSubTitleText: ResourceStr = '';
  @State callStateTitleText: ResourceStr = '00:00';
  holdCallState: ResourceStr = $r('app.string.callHold');
  @State firCallStateTitleText: ResourceStr = '00:00';
  callTimeText: string = '00:00';
  callIntervalID: number = 0;
  @State @Watch('watchCallTimestamp') callTimestamp: number = 0;
  @State screenHeight: number = 0;
  @State screenWidth: number = 0;
  @State isAnimatedBeginning: boolean = false;
  @State isOnAnswer: boolean = false;
  @StorageLink('superShow') superShow: boolean = false;
  markTypeLeather: PredefinedMark[] = [
    {
      markType: MarkType.MARK_TYPE_PROMOTE_SALES,
      text: $r('app.string.advertising_and_promotion')
    },
    {
      markType: MarkType.MARK_TYPE_HOUSE_AGENT,
      text: $r('app.string.Real_Estate_Agency')
    },
    {
      markType: MarkType.MARK_TYPE_FRAUD,
      text: $r('app.string.fraud_phone_call')
    },
    {
      markType: MarkType.MARK_TYPE_CRANK,
      text: $r('app.string.harassing_call')
    },
    {
      markType: MarkType.MARK_TYPE_EXPRESS,
      text: $r('app.string.courier_and_food_delivery')
    },
    {
      markType: MarkType.MARK_TYPE_INSURANCE,
      text: $r('app.string.financial_management_insurance')
    },
    {
      markType: MarkType.MARK_TYPE_TAXI,
      text: $r('app.string.taxi')
    }
  ];

  aboutToAppear(): void {
    LogUtils.e(TAG, `aboutToAppear`);
    let dataPreferences: preferences.Preferences | undefined = undefined;
    try {
      dataPreferences = preferences.getPreferencesSync(getContext(), leatherPagePreferencesOptions);
    } catch (error) {
      LogUtils.e(TAG, 'An exception occurs in the getDefaultDisplaySync method of display.');
    }
    let dataPreferencesSuperPrivacy = dataPreferences?.getSync(leatherPreferencesSuperPrivacy, false);
    this.isSuperPrivacy = dataPreferencesSuperPrivacy as boolean;

    this.registerCallStateCallback((data: DefaultCallData) => {
      clearInterval(this.callIntervalID)
      let index = this.callList.findIndex(item => item.callId === data.callId);
      if (index >= 0) {
        if (data.callState === CallStateConst.CALL_STATUS_DISCONNECTED ||
          data.callState === CallStateConst.CALL_STATUS_DISCONNECTING) {
          this.callList.splice(index, 1);
        } else {
          this.callList.splice(index, 1, data);
        }
      } else {
        if (data.callState !== CallStateConst.CALL_STATUS_DISCONNECTED &&
          data.callState !== CallStateConst.CALL_STATUS_DISCONNECTING) {
          this.callList.push(data);
        }
      }
      try {
        createQueryContactTask(data, (callDataContact) => {
          if (callDataContact.contactName !== undefined && callDataContact.contactName.length > 0) {
            if (this.callList.length <= 1) {
              this.firTitleText = callDataContact.contactName;
            }
            this.titleText = callDataContact.contactName;
          }
          this.initData()
        }, getContext() as Context)
      } catch (err) {
        LogUtils.i(TAG, json.stringify(err));

      }
    })
  }

  registerCallStateCallback(callBack: Function) {
    try {
      call.on('callDetailsChange', (data: call.CallAttributeOptions) => {
        if (!data) {
          return;
        }
        if (!data.numberMarkInfo) {
          data.numberMarkInfo = {
            markType: MarkType.MARK_TYPE_NONE, markContent: ''
          };
        }
        callBack(data);
      });
    } catch (err) {
    }
  }

  initData() {
    if (this.callList.length > 0) {
      this.callData = this.callList[this.callList.length - 1];
      this.firCallData = this.callList[0];
      LogUtils.i(TAG, `callData: ${callDataToSafeString(this.firCallData)}`);
      LogUtils.i(TAG, `firCallData: ${callDataToSafeString(this.firCallData)}`)
      this.titleTextEvent();
    }

    if (this.isMultiChannelAndActiveCall() && isActiveCall(this.callData.callState) && this.callData.startTime > 0 &&
      this.callData.callState !== CallStateConst.CALL_STATUS_HOLDING &&
      this.callData.callState !== CallStateConst.CALL_STATUS_ANSWER) {
      clearInterval(this.callIntervalID);
      this.callTimestamp = (systemDateTime.getTime() / 1000) - this.callData.startTime;
      this.openInterval();
    }

    if (this.firCallData.callState === CallStateConst.CALL_STATUS_HOLDING) {
      this.firCallStateTitleText = this.holdCallState;
    }
    if (this.callData.callState === CallStateConst.CALL_STATUS_HOLDING) {
      this.callStateTitleText = this.holdCallState;
    }

    if (isActiveCall(this.firCallData.callState) &&
      this.firCallData.startTime > 0 &&
      this.firCallData.callState !== CallStateConst.CALL_STATUS_HOLDING) {
      clearInterval(this.callIntervalID)
      let tmpConferenceData =
        this.callList.find((item) => Utils.getInstance().isConferenceCall(item));
      const tmpConferenceDataStartTime = tmpConferenceData ? tmpConferenceData.startTime : 0;
      this.callTimestamp =
        Utils.getInstance().isConferenceCall(this.firCallData) ?
          (systemDateTime.getTime() / 1000) - tmpConferenceDataStartTime :
          (systemDateTime.getTime() / 1000) - this.firCallData.startTime;
      this.openInterval();
    }

    this.isAnimatedBeginning =
      (this.isMultiChannelAndActiveCall()) ? true : false;

    if (Utils.getInstance().isConferenceCall(this.callData)) {
      this.isAnimatedBeginning = false;
    }

    if (isOutgoingCall(this.callData.callState) && this.callList.length > 1) {
      this.isAnimatedBeginning = true;
    }
    AppStorage.setOrCreate('superShow', false)
  }

  formatPhoneNumberEvent(phoneNum: string, callback: (formatNumber: string) => void) {
    let countryId = i18n.System.getSystemRegion();
    let options: call.NumberFormatOptions = {
      countryCode: countryId
    };
    call.formatPhoneNumber(phoneNum, options, (err, formatPhoneNum) => {
      callback(formatPhoneNum)
    });
  }

  getMarkTitleText(callData: DefaultCallData): ResourceStr {
    for (let element of this.markTypeLeather) {
      if (element.markType === callData.numberMarkInfo.markType) {
        return element.text;
      }
    }
    return '';
  }

  titleTextEvent() {
    this.formatPhoneNumberEvent(this.firCallData.accountNumber, (formatNumber) => {
      if (this.firCallData.contactName !== undefined && this.firCallData.contactName!.length > 0) {
        this.firTitleText = this.firCallData.contactName;
        this.firSubTitleText = this.firCallData.numberLocation;
      } else if (this.firCallData.numberMarkInfo.markContent.length > 0) {
        this.firTitleText = this.firCallData.numberMarkInfo.markContent;
        this.firSubTitleText = `${formatNumber} ${this.firCallData.numberLocation}`;
      } else if (markTypes.includes(this.firCallData.numberMarkInfo.markType)) {
        LogUtils.i(TAG, 'getMarkTitleText from firCallData');
        this.firTitleText = this.getMarkTitleText(this.firCallData);
        this.firSubTitleText = `${formatNumber} ${this.firCallData.numberLocation}`;
      } else {
        this.firTitleText = formatNumber;
        this.firSubTitleText = this.firCallData.numberLocation;
      }

      if (Utils.getInstance().isConferenceCall(this.firCallData)) {
        this.firTitleText = $r('app.string.telephone_Conference');
        this.firSubTitleText = '';
      }
    })

    this.formatPhoneNumberEvent(this.callData.accountNumber, (formatNumber) => {
      if (this.callData.contactName !== undefined && this.callData.contactName!.length > 0) {
        this.titleText = this.callData.contactName;
        if (this.screenWidth > leatherWindowWidth) {
          this.subTitleText = this.callData.numberLocation;
        } else {
          this.subTitleText = formatNumber + ' ' + this.callData.numberLocation;
        }
      } else if (this.callData.numberMarkInfo.markContent.length > 0) {
        this.titleText = this.callData.numberMarkInfo.markContent;
        this.subTitleText = `${formatNumber} ${this.callData.numberLocation}`;
      } else if (markTypes.includes(this.callData.numberMarkInfo.markType)) {
        LogUtils.i(TAG, 'getMarkTitleText from callData');
        this.titleText = this.getMarkTitleText(this.callData);
        this.subTitleText = `${formatNumber} ${this.callData.numberLocation}`;
      } else {
        this.titleText = formatNumber;
        this.subTitleText = this.callData.numberLocation;
      }
    })

    this.formatPhoneNumberEvent(this.callData.accountNumber, (formatNumber) => {
      if (isOutgoingCall(this.callData.callState)) {
        if (isActiveCall(this.callData.callState)) {
          this.callStateTitleText = this.callTimeText;
          this.firCallStateTitleText = this.callTimeText;
        } else if (this.callData.callState === CallStateConst.CALL_STATUS_ALERTING) {
          let context = getContext(this) as common.UIAbilityContext;
          if (context) {
            context.resourceManager.getStringValue($r('app.string.partyIsRinging'), (err, value) => {
              this.callStateTitleText = value;
              if (this.screenWidth > leatherWindowWidth) {
                this.firCallStateTitleText = value;
              } else {
                if (this.callData.contactName !== undefined && this.callData.contactName!.length > 0) {
                  this.subTitleText = formatNumber + ' ' + this.callData.numberLocation;
                }
                this.firCallStateTitleText = value;
              }
            })
          }
        } else {
          let context = getContext(this) as common.UIAbilityContext;
          if (context) {
            context.resourceManager.getStringValue($r('app.string.dialing'), (err, value) => {
              this.callStateTitleText = value + '...';
              if (this.screenWidth > leatherWindowWidth) {
                this.firCallStateTitleText = value + '...';
              } else {
                this.firCallStateTitleText = value + '...';
              }
            })
          }
        }
      }
    })
  }

  getCallLabelPrimary(): ResourceStr {
    // 多路通话处理逻辑
    if (this.isMultiChannelAndActiveCall()) {
      if (this.firCallData.numberMarkInfo.markType === MarkType.MARK_TYPE_FRAUD &&
        this.firCallData.contactName == undefined &&
        Utils.getInstance().isConferenceCall(this.callData) === false) {
        return $r('app.string.fraud_phone_call');
      } else if (this.firCallData.callType === CallStateConst.TYPE_VOIP) {
        return this.firCallData.voipCallAttribute?.userName || '';
      } else {
        return this.firTitleText;
      }
    }
    // 非多路通话
    if (this.callData.numberMarkInfo.markType === MarkType.MARK_TYPE_FRAUD &&
      this.callData.contactName == undefined &&
      Utils.getInstance().isConferenceCall(this.callData) === false) {
      return $r('app.string.fraud_phone_call');
    } else if (this.callData.callType === CallStateConst.TYPE_VOIP) {
      return this.callData.voipCallAttribute?.userName || '';
    } else {
      return this.titleText;
    }
  }

  openInterval() {
    this.callIntervalID = setInterval(() => {
      this.callIntervalEvent();
    }, 1000)
  }

  onPageHide(): void {
    clearInterval(this.callIntervalID);
  }

  callIntervalEvent() {
    this.callTimestamp += 1;
  }

  watchCallTimestamp() {
    let seconds = this.callTimestamp % 60;
    let minute = this.callTimestamp / 60 % 60;
    let hours = this.callTimestamp / 60 / 60;
    if (Math.floor(hours) > 0) {
      this.callTimeText = `${String(Math.floor(hours)).padStart(2, '0')}:${String(Math.floor(minute))
        .padStart(2, '0')}:${String(Math.floor(seconds)).padStart(2, '0')}`;
    } else if (Math.floor(minute) > 0) {
      this.callTimeText =
        `${String(Math.floor(minute)).padStart(2, '0')}:${String(Math.floor(seconds)).padStart(2, '0')}`;
    } else if (Math.floor(seconds) > 0) {
      this.callTimeText = `00:${String(Math.floor(seconds)).padStart(2, '0')}`;
    } else {
      this.callTimeText = '00:00';
    }

    if (this.isOnAnswer !== true) {
      this.firCallStateTitleTextEvent();
    }
    if (this.isMultiChannelAndActiveCall() &&
      this.callData.callState !== CallStateConst.CALL_STATUS_ANSWER) {
      this.callStateTitleTextEvent();

    }
  }

  firCallStateTitleTextEvent() {
    if (this.firCallData.callState === CallStateConst.CALL_STATUS_HOLDING) {
      this.firCallStateTitleText = this.holdCallState;
    } else if (this.firCallData.callState === CallStateConst.CALL_STATUS_ANSWER ||
      this.firCallData.callState === CallStateConst.CALL_STATUS_ACTIVE) {
      this.firCallStateTitleText = this.callTimeText;
    } else {
      this.firCallStateTitleText = '';
    }
  }

  callStateTitleTextEvent() {
    if (this.callData.callState === CallStateConst.CALL_STATUS_ANSWER ||
      this.callData.callState === CallStateConst.CALL_STATUS_ACTIVE) {
      this.callStateTitleText = this.callTimeText;
    } else if (this.callData.callState === CallStateConst.CALL_STATUS_HOLDING) {
      this.callStateTitleText = this.holdCallState;
    } else {
      this.callStateTitleText = '';
    }
  }

  isMultiChannelAndActiveCall() {
    return (this.callList.length > 1 && isActiveCall(this.callData.callState) &&
      this.firCallData.callId !== this.callData.callId);
  }

  onAnswer() {
    if (this.callList.length > 1) {
      this.callTimestamp = (systemDateTime.getTime() / 1000);
      this.callStateTitleText = '00:00';
      this.firCallStateTitleText = this.holdCallState;
      this.isOnAnswer = true;
    }

    CallServiceProxy.getInstance().acceptCall(this.callData.callId, false);
  }

  @Builder
  leatherContentBuilder() {
    List() {
      ListItem() {
        Column() {
          if (this.isMultiChannelAndActiveCall() && Utils.getInstance().isConferenceCall(this.callData) === false) {
            Blank()
          }

          Row() {
            if (this.isMultiChannelAndActiveCall()) {
              if (this.firCallData.numberMarkInfo.markType === MarkType.MARK_TYPE_FRAUD) {
                Image($r('app.media.leather_ic_public_error'))
                  .width($r('app.float.leather_image_height'))
                  .height($r('app.float.leather_image_height'))
              }
            } else {
              if (this.callData.numberMarkInfo.markType === MarkType.MARK_TYPE_FRAUD) {
                Image($r('app.media.leather_ic_public_error'))
                  .width($r('app.float.leather_image_height'))
                  .height($r('app.float.leather_image_height'))
              }
            }

            Text(this.getCallLabelPrimary())
              .textOverflow({ overflow: TextOverflow.MARQUEE })
              .textAlign(TextAlign.Center)
              .backgroundColor('#00000000')
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.font_on_primary'))
              .fontSize(this.isMultiChannelAndActiveCall() ? $r('app.float.leather_text_font') :
              $r('app.float.call_callList_conference_text_height'))
              .margin({
                left: this.firCallData.numberMarkInfo.markType === MarkType.MARK_TYPE_FRAUD ? 4 : 0
              })
              .textAlign(this.firCallData.numberMarkInfo.markType === MarkType.MARK_TYPE_FRAUD ? TextAlign.Start :
              TextAlign.Center)
              .lineHeight(27)
              .layoutWeight(1)
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .width('100%')

          if ((this.isMultiChannelAndActiveCall() || isOutgoingCall(this.firCallData.callState)) === false) {
            Text(this.subTitleText)
              .textOverflow({ overflow: TextOverflow.MARQUEE })
              .textAlign(TextAlign.Center)
              .backgroundColor('#00000000')
              .fontSize($r('app.float.call_calllist_time_or_status_font'))
              .fontColor($r('sys.color.font_on_primary'))
              .margin({
                top: 5
              })
          }

          if (isActiveCall(this.callData.callState) || isOutgoingCall(this.callData.callState)) {
            Text((this.isMultiChannelAndActiveCall() || this.callList.length <= 1) ? this.firCallStateTitleText :
            this.callStateTitleText)
              .style()
              .fontSize($r('app.float.call_calllist_time_or_status_font'))
              .fontColor(this.isMultiChannelAndActiveCall() ? $r('sys.color.font_on_secondary') :
              $r('sys.color.font_on_primary'))
              .margin({
                top: this.isMultiChannelAndActiveCall() ? 2.5 : 2
              })
          }

          if (this.isMultiChannelAndActiveCall() && Utils.getInstance().isConferenceCall(this.callData) === false) {
            Blank()
          }
          Divider()
            .strokeWidth('1px')
            .color($r('sys.color.ohos_id_color_list_separator_dark'))
            .margin({
              bottom: 0,
            })
            .visibility((this.isMultiChannelAndActiveCall() &&
              Utils.getInstance().isConferenceCall(this.callData) === false) ?
            Visibility.Visible : Visibility.Hidden)
        }
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
      .height(64)

      if (this.isMultiChannelAndActiveCall() && Utils.getInstance().isConferenceCall(this.callData) === false) {
        ListItem() {
          Column() {
            Blank()
            Row() {
              if (this.callData.numberMarkInfo.markType === MarkType.MARK_TYPE_FRAUD) {
                Image($r('app.media.leather_ic_public_error'))
                  .width($r('app.float.leather_image_height'))
                  .height($r('app.float.leather_image_height'))
              }

              Text(this.callData.numberMarkInfo.markType === MarkType.MARK_TYPE_FRAUD ?
              $r('app.string.fraud_phone_call') : this.titleText)
                .style()
                .fontWeight(FontWeight.Medium)
                .fontColor($r('sys.color.font_on_primary'))
                .fontSize($r('app.float.leather_text_font'))
                .layoutWeight(1)
                .margin({
                  left: this.callData.numberMarkInfo.markType === MarkType.MARK_TYPE_FRAUD ? 4 : 0
                })
                .textAlign(this.callData.numberMarkInfo.markType === MarkType.MARK_TYPE_FRAUD ? TextAlign.Start :
                TextAlign.Center)
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)

            Text(this.callStateTitleText)
              .style()
              .fontSize($r('app.float.call_calllist_time_or_status_font'))
              .fontColor($r('sys.color.font_on_secondary'))
              .margin({
                top: 2.5
              })

            Blank()
            Divider()
              .strokeWidth('1px')
              .color($r('sys.color.ohos_id_color_list_separator_dark'))
              .margin({
                bottom: 0,
              })
          }
          .height('100%')
          .justifyContent(FlexAlign.Center)
        }
        .height(64)
      }
    }
    .margin({
      top: this.isMultiChannelAndActiveCall() ? 64 : 0
    })
    .backgroundColor(Color.Black)
  }

  @Builder
  leatherExtremelyNarrowLayout() {
    RelativeContainer() {
      Column() {
        this.leatherExtremelyNarrowContentBuilder();
      }
      .height(this.isMultiChannelAndActiveCall() && Utils.getInstance().isConferenceCall(this.callData) === false ?
        this.screenHeight - shortText : this.screenHeight - overLongText)
      .justifyContent((this.isMultiChannelAndActiveCall() &&
        Utils.getInstance().isConferenceCall(this.callData) === false) ?
      FlexAlign.Start : FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .height(this.isMultiChannelAndActiveCall() && Utils.getInstance().isConferenceCall(this.callData) === false ?
      this.screenHeight - shortText : this.screenHeight - overLongText)
    .margin({
      bottom: 32
    })

    Column() {
      if (this.isMultiChannelAndActiveCall() && Utils.getInstance().isConferenceCall(this.callData) === false) {
        Column() {
          Column() {
            Text(this.isMultiChannelAndActiveCall() ? $r('app.string.LeatherUIExtAbility_switch_between_calls') :
              '')
              .fontFamily('HarmonyHeiTi')
              .width(127)
              .maxLines(1)
              .fontColor($r('sys.color.icon_on_primary'))
              .fontSize($r('app.float.call_calllist_time_or_status_font'))
              .fontWeight(FontWeight.Regular)
              .lineHeight(19)
              .textOverflow({ overflow: TextOverflow.MARQUEE })
          }
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .width(126)
          .height(this.screenWidth)
          .rotate({ angle: 90 })
        }
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .height(126)
        .width(this.screenWidth)
        .margin({
          bottom: 32
        })
      }
      Row() {
        if (isActiveCall(this.callData.callState) || isOutgoingCall(this.callData.callState)) {
          this.hangUpContentBuilder()
        } else if (isIncomingCall(this.callData.callState)) {
          this.incomingContentBuilder()
        }
      }
      .height(231)
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .margin({ bottom: 64 })
  }

  @Builder
  leatherExtremelyNarrowContentBuilder() {
    Column() {
      Column() {
        Column() {
          Row() {
            if (this.isMultiChannelAndActiveCall()) {
              if (this.firCallData.numberMarkInfo.markType === MarkType.MARK_TYPE_FRAUD &&
                this.firCallData.contactName == undefined &&
                Utils.getInstance().isConferenceCall(this.callData) === false) {
                Image($r('app.media.leather_ic_public_error'))
                  .width($r('app.float.leather_image_height'))
                  .height($r('app.float.leather_image_height'))
                  .margin({ right: 4 })
              }
            } else {
              if (this.callData.numberMarkInfo.markType === MarkType.MARK_TYPE_FRAUD &&
                this.firCallData.contactName == undefined &&
                Utils.getInstance().isConferenceCall(this.callData) === false) {
                Image($r('app.media.leather_ic_public_error'))
                  .width($r('app.float.leather_image_height'))
                  .height($r('app.float.leather_image_height'))
                  .margin({ right: 4 })
              }
            }

            Row(){
              Text(this.getCallLabelPrimary())
                .fontWeight(this.isMultiChannelAndActiveCall() ? FontWeight.Medium :
                  isActiveCall(this.callData.callState) ? 600 : 600)
                .fontColor($r('sys.color.font_on_primary'))
                .fontFamily('HarmonyHeiTi')
                .fontSize(this.isMultiChannelAndActiveCall() ? $r('app.float.leather_text_font') :
                $r('app.float.call_dtmf_add_text_line_height'))
                .lineHeight(this.isMultiChannelAndActiveCall() &&
                  Utils.getInstance().isConferenceCall(this.callData) === false ?
                  21 : 32)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .layoutWeight(1)

            if (this.isMultiChannelAndActiveCall() && Utils.getInstance().isConferenceCall(this.callData) === false) {
              if (isActiveCall(this.callData.callState) || isOutgoingCall(this.callData.callState)) {
                Row() {
                }
                .width(8)

                Row() {
                  Text((this.isMultiChannelAndActiveCall() || this.callList.length <= 1) ?
                  this.firCallStateTitleText : this.callStateTitleText)
                    .fontSize($r('app.float.call_calllist_time_or_status_font'))
                    .lineHeight(19)
                    .fontFamily('HarmonyHeiTi')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .fontColor(this.isMultiChannelAndActiveCall() ? $r('sys.color.font_on_secondary') :
                    $r('sys.color.font_on_primary'))
                }
                .width(37)
                .justifyContent(FlexAlign.End)
              }
            }

          }
          .alignItems(VerticalAlign.Center)
          .margin({
            bottom: this.isMultiChannelAndActiveCall() &&
              Utils.getInstance().isConferenceCall(this.callData) === false ? 8 : 5
          })
          .width(this.isMultiChannelAndActiveCall() && Utils.getInstance().isConferenceCall(this.callData) === false ?
            this.screenHeight - shortText : this.screenHeight - overLongText)

          Row() {
            if ((this.isMultiChannelAndActiveCall() || isOutgoingCall(this.firCallData.callState)) === false) {
              Row() {
                Text(this.subTitleText)
                  .fontSize($r('app.float.call_calllist_time_or_status_font'))
                  .fontColor($r('sys.color.font_on_primary'))
                  .lineHeight(19)
                  .fontFamily('HarmonyHeiTi')
                  .fontWeight(FontWeight.Regular)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }

              Row() {
              }
              .width(8)
            }
            if (isOutgoingCall(this.firCallData.callState) === true) {
              Row() {
                Text(this.subTitleText)
                  .fontSize($r('app.float.call_calllist_time_or_status_font'))
                  .fontColor($r('sys.color.font_on_primary'))
                  .lineHeight(19)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }

              Row() {
              }
              .width(8)
            }
            if (!(this.isMultiChannelAndActiveCall() &&
              Utils.getInstance().isConferenceCall(this.callData) === false)) {
              if (isActiveCall(this.callData.callState) || isOutgoingCall(this.callData.callState)) {
                Text((this.isMultiChannelAndActiveCall() || this.callList.length <= 1) ? this.firCallStateTitleText :
                this.callStateTitleText)
                  .fontSize($r('app.float.call_calllist_time_or_status_font'))
                  .fontColor(this.isMultiChannelAndActiveCall() ? $r('sys.color.font_on_secondary') :
                  $r('sys.color.font_on_primary'))
                  .lineHeight(19)
                  .fontFamily('HarmonyHeiTi')
                  .fontWeight(FontWeight.Regular)
              }
            }
          }
          .width(this.callList.length > 1 ? this.screenHeight - shortText :
            this.screenHeight - overLongText)
        }
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        if (this.isMultiChannelAndActiveCall() && Utils.getInstance().isConferenceCall(this.callData) === false) {
          Row() {
            Row() {
              if (this.callData.numberMarkInfo.markType === MarkType.MARK_TYPE_FRAUD &&
                this.callData.contactName == undefined &&
                Utils.getInstance().isConferenceCall(this.callData) === false) {
                Image($r('app.media.leather_ic_public_error'))
                  .width($r('app.float.leather_image_height'))
                  .height($r('app.float.leather_image_height'))
                  .margin({ right: 4 })
              }
              Row(){
                Text(this.callData.numberMarkInfo.markType === MarkType.MARK_TYPE_FRAUD &&
                  this.callData.contactName == undefined &&
                  Utils.getInstance().isConferenceCall(this.callData) === false ? $r('app.string.fraud_phone_call') :
                this.titleText)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('sys.color.font_on_primary'))
                  .lineHeight(21)
                  .fontSize($r('app.float.leather_text_font'))
                  .maxLines(1)
                  .fontFamily('HarmonyHeiTi')
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .layoutWeight(1)

              Row() {
              }
              .width(8)

              Row() {
                Text(this.callStateTitleText)
                  .lineHeight(19)
                  .fontFamily('HarmonyHeiTi')
                  .fontSize($r('app.float.call_calllist_time_or_status_font'))
                  .fontWeight(FontWeight.Regular)
                  .fontColor($r('sys.color.font_on_secondary'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width(37)
              .justifyContent(FlexAlign.End)
            }
          }
          .width('100%')
          .backgroundColor(Color.Black)
        }
      }
      .width(this.isMultiChannelAndActiveCall() && Utils.getInstance().isConferenceCall(this.callData) === false ?
        this.screenHeight - shortText : this.screenHeight - overLongText)
      .height(this.screenWidth)
      .rotate({ angle: 90 })
      .translate({
        y: this.isMultiChannelAndActiveCall() && Utils.getInstance().isConferenceCall(this.callData) === false ?
          (this.screenHeight - shortText) / 2 - (this.screenWidth / 2) :
          (this.screenHeight - overLongText) / 2 - (this.screenWidth / 2)
      })
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)

  }

  @Builder
  incomingContentBuilder() {
    Column() {
      LeatherIncomingCom({
        onAnswerCallBack: () => {
          this.onAnswer();
          // 皮套模式下接听电话
          ReportUtil.getInstance().reportAnswerCallInLeatherMode();
        },
        onRejectCallBack: () => {
          CallServiceProxy.getInstance().rejectCall(this.callData.callId);
          // 皮套模式下拒接电话
          ReportUtil.getInstance().reportRejectCallInLeatherMode();
        },
        isPrivacyMode: this.isSuperPrivacy,
        isWideMode: (this.screenWidth > leatherWindowWidth) ? true : false
      })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.End)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.Black)
  }

  @Builder
  hangUpContentBuilder() {
    Column() {
      LeatherRejectCom({
        onRejectCallBack: () => {
          if (this.callList.length > 1) {
            for (let element of this.callList) {
              if ((element.callState === CallStateConst.CALL_STATUS_ACTIVE ||
                element.callState === CallStateConst.CALL_STATUS_ANSWER)) {
                const tmpData = this.callList.find(item => item.callId === element.callId) as DefaultCallData
                if (Utils.getInstance().isConferenceCall(tmpData)) {
                  CallServiceProxy.getInstance().hangUpConference(tmpData.callId).then(() => {
                  })
                } else {
                  CallServiceProxy.getInstance().hangUpCall(tmpData.callId).then(() => {
                  });
                }
              } else if (element.callState === CallStateConst.CALL_STATUS_ALERTING ||
                element.callState === CallStateConst.CALL_STATUS_DIALING) {
                CallServiceProxy.getInstance().hangUpCall(this.callData.callId).then(() => {
                });
              }
            }
          } else {
            CallServiceProxy.getInstance().hangUpCall(this.callData.callId).then(() => {
            });
          }
          // 皮套模式下挂断电话
          CallUtils.reportHangupCount();
          ReportUtil.getInstance().reportHangUpCallInLeatherMode();
          this.isOnAnswer = false
        },
        isAnimatedBeginning: this.isAnimatedBeginning,
        isWideMode: (this.screenWidth > leatherWindowWidth) ? true : false
      })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.End)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.Black)
  }

  build() {
    Column() {
      if (this.screenWidth > leatherWindowWidth) {
        RelativeContainer() {
          Column() {
            this.leatherContentBuilder()
          }
          .height((this.screenHeight - widescreenOutsideMargin) * widescreenRatio)
          .justifyContent((this.isMultiChannelAndActiveCall() &&
            Utils.getInstance().isConferenceCall(this.callData) === false) ?
          FlexAlign.Start : FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

          if (this.isSuperPrivacy) {
            Text($r('app.string.LeatherUIExtAbility_in_super_privacy'))
              .fontColor($r('sys.color.icon_on_primary'))
              .textAlign(TextAlign.Start)
              .width('100%')
              .fontSize($r('app.float.call_calllist_time_or_status_font'))
              .maxLines(4)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({
                top: 16
              })
          }
        }
        .height((this.screenHeight - widescreenOutsideMargin) * widescreenRatio)

        Column() {
          if (isActiveCall(this.callData.callState) || isOutgoingCall(this.callData.callState)) {
            this.hangUpContentBuilder()
          } else if (isIncomingCall(this.callData.callState)) {
            this.incomingContentBuilder()
          }

          if (this.isMultiChannelAndActiveCall()) {
            Text($r('app.string.LeatherUIExtAbility_switch_between_calls'))
              .textAlign(TextAlign.Center)
              .width('100%')
              .height(38)
              .fontColor($r('sys.color.icon_on_primary'))
              .fontSize($r('app.float.call_calllist_time_or_status_font'))
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({
                top: 16
              })
          }
        }
        .justifyContent(FlexAlign.End)
        .layoutWeight(1)
        .margin({
          bottom: this.isMultiChannelAndActiveCall() ? 10 : 64
        })
      } else {
        if (this.superShow) {
          Row() {
            Text($r('app.string.LeatherUIExtAbility_in_super_privacy'))
              .fontSize(14)
              .textAlign(TextAlign.Center)
              .rotate({ angle: 90 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.MARQUEE })
              .width(this.screenHeight - 64)
              .translate({
                x: -((this.screenHeight - 64) / 2 - this.screenWidth / 2)
              })
              .fontColor($r('sys.color.icon_on_primary'))
          }
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .width(this.screenWidth)
          .height(this.screenHeight - 64)
          .margin({ bottom: 32 })
        } else {
          this.leatherExtremelyNarrowLayout()
        }
      }
    }
    .backgroundColor(Color.Black)
    .height('100%')
    .width('100%')
    .onAreaChange((oldValue, newValue) => {
      this.screenHeight = newValue.height as number
      this.screenWidth = newValue.width as number
    })
    .padding({
      left: this.screenWidth > leatherWindowWidth ? 15 : 0,
      right: this.screenWidth > leatherWindowWidth ? 10 : 0,
      top: this.screenWidth > leatherWindowWidth ? 5 : 32,
      bottom: this.screenWidth > leatherWindowWidth ? 5 : 0
    })
  }
}

@Extend(Text)
function style() {
  .textOverflow({ overflow: TextOverflow.MARQUEE })
  .textAlign(TextAlign.Center)
  .width('100%')
  .backgroundColor('#00000000')
}

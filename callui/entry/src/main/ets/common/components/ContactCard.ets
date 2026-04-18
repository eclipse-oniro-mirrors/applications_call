/**
 * Copyright (c) 2022-2024 Huawei Device Co., Ltd.
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
 * @file: Header information display component
 */
import LogUtils from '../utils/LogUtils';
import CallStateConst from '../constant/CallStateConst';
import DefaultCallData, { getSimIcon, MarkType } from '../struct/TypeUtils';
import CallTimeListStruct from '../struct/CallTimeListStruct';
import curves from '@ohos.curves';
import ConferenceTitle from './ConferenceTitle';
import { StringUtil } from '../utils/StringUtil';
import { isIncomingCall, isOutgoingCall } from '../utils/CallListHelper';
import CallColumnUtils from '../utils/CallColumnUtils';
import {
  getCallLabelPrimary,
  getFormatCallLabelPrimary,
  getCallLabelSecondary,
  getCallLabelThird,
  getFormattedNumber,
  getMarkContentResource
} from '../utils/CallLabelUtils';
import { ScreenInfo } from '../struct/CallUiDataStruct';
import {
  ACCESSIBILITY_LEVEL_YES,
  IMS_DOMAIN, START_CHECK_CALL_RISK, STRANGE_NUMBER_CALL_DATA } from '../utils/Constants';
import { LengthMetrics } from '@kit.ArkUI';
import SplitScreenManager, { SplitScreenType } from '../../model/SplitScreenManager';
import I18n from '@ohos.i18n';
import Intl from '@ohos.intl';
import Utils from '../utils/utils';
import { isTwoInOne } from '../utils/DeviceTypeUtils';
import { TrifoldManager } from '../utils/TrifoldManager';
import { ReportUtil } from '../utils/ReportUtils/ReportUtil';
import measure from '@ohos.measure';
import CallUtils from '../utils/CallUtils';
import { AccessibilityUtil } from '../utils/AccessiblityUtil';
import { NewCallIcon } from './NewCallIcon';

const TAG = 'ContactCard';

@Component
export default struct ContactCard {
  @State callStateText: string = '';
  @State antiTip: string = '.';
  @State antiFraudIdentifies: Resource = $r('app.string.anti_fraud_identifies');
  @State satelliteDialingTips: Resource | string = '';
  @Prop isShowKeyboard: boolean = false;
  @Prop translateName: string = '';
  @Prop translateTime: string = '';
  @Prop contactAppear: boolean = false;
  @Link @Watch('callListChange') callList: Array<DefaultCallData>;
  @Link @Watch('refreshingData') callData: DefaultCallData;
  @Link @Watch('initCompanyTimer') callState: number;
  @Link @Watch('initCompanyTimer') callType: number;
  @Link contactNameLine: number;
  @Link accountId: number;
  @Link contactAvatar?: PixelMap | null;
  @Link callTimeList: Array<CallTimeListStruct>;
  @Consume isConferenceMode: boolean;
  @State conferenceMemberStr: string = '';
  @State conferenceMemberCountNumber: number = 0;
  @Link showConferenceDetail: boolean;
  @State showMarquee: boolean = false;
  @Link isShowSim: boolean;
  @StorageLink('TextInput') textInput: string = '';
  @StorageLink('TextInputValue') textInputValue: string = '';
  @StorageLink('AccountNumber') accountNumber: string = '';
  @StorageLink('simOperatorNameFirst') simOperatorNameFirst: string = '';
  @StorageLink('simOperatorNameSecond') simOperatorNameSecond: string = '';
  @StorageProp('curBp') curBp: string = '';
  @StorageProp('windowSizeChangeMd') @Watch('windowSizeChange') windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  }
  @StorageProp('navigationHeight') navigationHeight: number = 0;
  @StorageLink('onAnswer') @Watch('onAnswerStatusChange') onAnswer: boolean = false;
  @StorageLink('hangUp') hangup: boolean = false;
  @StorageLink(STRANGE_NUMBER_CALL_DATA) strangeNumberCallData: DefaultCallData | null = null;
  @State marqueeLoop: number = -1;
  @State callStateScore: boolean = false;
  private conferenceModeTranslate: string = '-20';
  private timeTmp: string = '00:00';
  @State nickFontSize: string = '38vp';
  @StorageLink('clickMergeAction') @Watch('changeMerge') mergeAction: boolean = false;
  @StorageLink('Density') @Watch('densityDidChange') density: number = 1;
  @Prop textAreaTop: string | Resource;
  @State showSimFirstFlag: boolean = true;
  private companyTimer: number = -1;
  @StorageLink('SplitScreenType') splitScreenType: SplitScreenType = SplitScreenType.DEFAULT;
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  private isDistributeSink: boolean = false;
  private distributeName: string = '';
  @State callLabelThird: string = '';
  @StorageLink('screenReaderStatus') screenReaderStatus: boolean = false;
  @State @Watch('densityDidChange') callLabelPrimary: Resource | string = '';
  @State callLabelSecondary: string = '';
  @State isDot1Visible: boolean = true; // indicate steady on
  @State isDot2Visible: boolean = false;
  @State isDot3Visible: boolean = false;
  @State antiFraudState: number = 0;
  @State isAntiFraud?: boolean = false;
  @State antiTimer: number = -1;
  @StorageLink('isNewFoldPhoneInnerFullScreen') @Watch('densityDidChange') isNewFoldPhoneInnerFullScreen: boolean =
    false;
  private scrollController: Scroller = new Scroller();
  private marqueeMaxWidth = 0;
  @StorageProp('isHyacinthMode') isHyacinthMode: boolean = false;
  @State isShowcCallSecondary: boolean = true;
  private controller: TextController = new TextController();
  @Prop celiaAssistantShow:boolean;
  @State showNewCall: boolean = false;

  @Styles
  iconStyles() {
    .visibility(this.showSimFirstFlag ? Visibility.Visible : Visibility.None)
    .opacity(this.showSimFirstFlag ? 1 : 0)
    .transition(TransitionEffect.OPACITY.animation({
      duration: this.onAnswer || this.companyTimer === -1 ? 0 : 1000,
      delay: 0,
      curve: Curve.EaseInOut,
      iterations: 1
    }))
    .translate({ y: this.isConferenceMode ? this.conferenceModeTranslate : this.getTranslateY(this.translateTime) })
    .animation({
      curve: this.isShowKeyboard ?
      curves.interpolatingSpring(0, 1, 480, 44) : curves.interpolatingSpring(0, 1, 342, 37)
    })
  }

  public aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear ' + this.isShowSim);
    LogUtils.i(TAG, 'aboutToAppear isDistributeSink = ' + this.isDistributeSink);
    if (this.isDistributeSink) {
      let distributeDeviceName: string = AppStorage.get<string>('distributeDeviceName') as string;
      this.distributeName = StringUtil.formatResourceToString($r('app.string.hop_with_device_name'),
        distributeDeviceName);
    }
    this.showSimFirstFlag = this.isShowSim;
    this.refreshingData();
    this.changeMerge();
    this.initCompanyTimer();
    let timer: number = -1;
    let satelliteDialingTimer = -1;
    if (this.callState === 2) {
      timer = setInterval(() => {
        if (this.callState !== 2) {
          clearInterval(timer);
          clearTimeout(satelliteDialingTimer);
          this.satelliteDialingTips = '';
          return;
        }
        if (!this.isDot2Visible && !this.isDot3Visible) {
          this.isDot2Visible = true;
        } else if (this.isDot2Visible && !this.isDot3Visible) {
          this.isDot3Visible = true;
        } else if (this.isDot2Visible && this.isDot3Visible) {
          this.isDot2Visible = false;
          this.isDot3Visible = false;
        }
      }, 500);

      if (this.callType === CallStateConst.TYPE_SATELLITE) {
        satelliteDialingTimer = setTimeout(() => {
          this.satelliteDialingTips = $r('app.string.satellite_dialing_tips')
        }, 5000);
      }
    }
  }

  onAnswerStatusChange() {
    if (this.onAnswer) {
      AccessibilityUtil.requestFocusForAccessibility('contactCard_column');
    }
  }

  refreshingData(): void {
    const antiFraudState = this.callData.extraParams?.antiFraudState as number;
    if (antiFraudState !== undefined) {
      this.antiFraudState = antiFraudState;
    }
    this.isAntiFraud = this.callData.isAntiFraud;
    if (this.antiFraudState === 1 && this.antiTimer === -1) {
      ReportUtil.getInstance().reportAntiFraudEvent(START_CHECK_CALL_RISK);
      this.antiTimer = setInterval(() => {
        if (this.antiFraudState !== 1) {
          clearTimeout(this.antiTimer)
          this.antiTip = '.';
          this.antiTimer = -1;
          return
        }
        if ('.' === this.antiTip) {
          this.antiTip = '..';
        } else if ('..' === this.antiTip) {
          this.antiTip = '...';
        } else {
          this.antiTip = '.';
        }
      }, 500);
    }
    if (this.antiFraudState === 2) {
      this.antiFraudIdentifies = $r('app.string.anti_fraud_beware_being_deceived')
    }
    this.callLabelPrimary = getCallLabelPrimary(this.callData);
    this.callLabelSecondary = getCallLabelSecondary(this.callData);
    // 没有归属地的号码并且没有被存储为联系人，不把归属地显示为号码
    this.isShowcCallSecondary = this.callLabelSecondary === getFormattedNumber(this.callData) &&
      this.callData.contactName === '' && getMarkContentResource(this.callData) === '' ? false : true;
    this.callLabelThird = getCallLabelThird(this.callData);
  }

  public aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear');
    this.clearCompanyTimer();
  }

  clearCompanyTimer() {
    if (this.companyTimer !== -1) {
      this.showSimFirstFlag = this.isShowSim;
      clearInterval(this.companyTimer);
      this.companyTimer = -1;
      LogUtils.i(TAG, 'clearInterval companyTimer');
    }
  }

  initCompanyTimer() {
    if (this.callType === CallStateConst.TYPE_SATELLITE || !isIncomingCall(this.callData?.callState)) {
      this.clearCompanyTimer();
      return;
    }
    if (this.showSimFirstFlag && this.callLabelThird.length > 0) {
      if (this.companyTimer !== -1) {
        LogUtils.i(TAG, 'companyTimer already exist');
      } else {
        this.companyTimer = setInterval(() => {
          this.showSimFirstFlag = !this.showSimFirstFlag;
        }, 3000);
        LogUtils.i(TAG,
          `companyTimer create success:${this.companyTimer},companyInfoLength:${this.callLabelThird.length}`);
      }
    }
  }

  private densityDidChange() {
    this.nickFontSize =
      CallColumnUtils.getInstance().getDisplayNameForAutoSize(this.callLabelPrimary, this.curBp, false);
  }

  changeMerge() {
    if (this.mergeAction) {
      LogUtils.i(TAG, 'mergeAction is changed');
      this.callListChange();
    }
  }

  /**
   * checkIsInConferenceHold
   *
   * @return checkIsInConferenceHold
   */
  public checkIsInConferenceHold(): boolean {
    let isInConferenceHold: boolean = false;
    if (this.isConferenceMode && this.callData.conferenceState) {
      for (let i = 0; i < this.callList.length; i++) {
        if (this.callList[i].conferenceState && this.callList[i].callState === CallStateConst.CALL_STATUS_HOLDING) {
          isInConferenceHold = true;
          break;
        }
      }
    }
    return isInConferenceHold;
  }

  /**
   * Call status
   *
   * @return {number} - Call status
   */
  /**
   * when call list data change
   *
   * @return {void}
   */
  private callListChange() {
    let isConferenceMode = false;
    let conferenceStr = '';
    const isInConferenceHold: boolean = this.checkIsInConferenceHold();
    this.callStateScore = isInConferenceHold;
    const SYMBOL_COMMA = StringUtil.formatResourceToString($r('app.string.symbol_comma'))
    for (let i = 0; i < this.callList.length; i++) {
      let curCallData = this.callList[i];
      if (curCallData.callState === CallStateConst.CALL_STATUS_INCOMING ||
        curCallData.callState === CallStateConst.CALL_STATUS_WAITING) {
        isConferenceMode = false;
        break;
      }
      if (i !== 0) {
        conferenceStr += SYMBOL_COMMA;
      }
      conferenceStr += getFormatCallLabelPrimary(curCallData, false);
      if (Utils.getInstance().isConferenceCall(curCallData)) {
        isConferenceMode = true;
      }
    }
    this.conferenceMemberStr = conferenceStr;
    if (this.callList.length > 1) {
      this.isConferenceMode = isConferenceMode;
    } else {
      this.isConferenceMode = false;
    }
    this.conferenceMemberCountNumber = this.callList.length;
    if (!this.isConferenceMode) {
      this.showConferenceDetail = this.isConferenceMode;
    }
    this.marqueeTextWidth();
  }

  /**
   * Whether to display the time
   *
   * @return {boolean} - return success true fail false
   */
  private isShowTime(): boolean {
    if (this.onAnswer) {
      return true;
    }
    if (this.callState === CallStateConst.CALL_STATUS_ACTIVE ||
      this.callState === CallStateConst.CALL_STATUS_ANSWER) {
      return true;
    }
    if (this.callList.length === 1 && this.isConferenceMode) {
      return true;
    }
    return false;
  }

  /**
   * Whether to display the third when incoming call
   *
   * @return {boolean} - return success true fail false
   */
  private isIncomingAndNotShowThird(): boolean {
    return isIncomingCall(this.callState) && !this.isShowSim &&
      this.callLabelThird.length <= 0 && this.callType !== CallStateConst.TYPE_SATELLITE && !this.isDistributeSink;
  }

  windowSizeChange() {
    this.nickFontSize = CallColumnUtils.getInstance().getDisplayNameForAutoSize(this.callLabelPrimary, this.curBp);
    LogUtils.i(TAG, `windowSizeChange nickFontSize:${this.nickFontSize}`);
  }

  private isShowSetNumberMark(): boolean {
    return this.strangeNumberCallData !== null;
  }

  private layoutWeightNumber(): number | null {
    if ((this.contactAvatar !== null || this.contactAvatar !== undefined) && !this.isShowKeyboard) {
      return 0;
    } else {
      return 1;
    }
  }

  private justifyContentLeve(isNewFoldPhoneExternalScreen: boolean) {
    if (isNewFoldPhoneExternalScreen) {
      return FlexAlign.Center;
    }
    if ((this.contactAvatar !== null || this.contactAvatar !== undefined) && !this.isShowKeyboard) {
      return FlexAlign.End;
    } else {
      return FlexAlign.Center;
    }
  }

  private getDistributedStringByStr(label: string): string {
    if (!this.isDistributeSink) {
      return label;
    }
    if (!label || label === '') {
      return this.distributeName;
    }
    return this.distributeName + ' | \u2068' + label;
  }

  private getDistributedStringByRes(label: Resource): string {
    if (!this.isDistributeSink) {
      //使用资源管理器的方式获取Resource字符串
      return StringUtil.formatResourceToStringForContactCard(label);
    }
    return this.distributeName + ' | \u2068' + StringUtil.formatResourceToStringForContactCard(label);
  }

  private getNickFontSize() {
    let splitFontSize = SplitScreenManager.getInstance().getDisplayNameFontSize(this.splitScreenType);
    if (splitFontSize.length > 0) {
      return splitFontSize;
    }
    let textStr = this.callLabelPrimary;
    this.nickFontSize = CallColumnUtils.getInstance().getDisplayNameForAutoSize(textStr, this.curBp);
    return this.nickFontSize;
  }

  private formatResourceToString(resource: Resource | string): string {
    return typeof resource === 'string' ? resource : StringUtil.formatResourceToString(resource);
  }

  @Builder
  private dialingDotBuilder() {
    Row() {
      Text('.')
        .dialingDotExtend(this.isDot1Visible)
      Text('.')
        .dialingDotExtend(this.isDot2Visible)
      Text('.')
        .dialingDotExtend(this.isDot3Visible)
    }
  }

  getCallPrimaryLabelMarginBottom() {
    if (this.isNewFoldPhoneExternalScreen) {
      if (this.isShowKeyboard) {
        return 0;
      }
      return '5vp';
    }
    if (this.isNewFoldPhoneInnerFullScreen) {
      return $r('sys.float.padding_level2');
    }
    if (isTwoInOne() || TrifoldManager.getInstance().isTrifold()) {
      return '5vp';
    }
    return $r('sys.float.padding_level1');
  }

  getGroupAccessibilityText() {
    let screenReaderStatus = AppStorage.get<boolean>('screenReaderStatus');
    if (!screenReaderStatus) {
      return '';
    }
    let textResult = '';
    if (this.isShowKeyboard && this.textInput.length !== 0) {
      textResult += this.textInputValue + ' '
    } else {
      if (this.isConferenceMode) {
        textResult += StringUtil.formatPluralResourceToString($r('app.plural.conference_member_number'),
          this.conferenceMemberCountNumber) + ' '
        textResult += this.conferenceMemberStr
        textResult += StringUtil.formatPluralResourceToString($r('app.plural.conference_member_number'),
          this.conferenceMemberCountNumber) + ' '
      } else {
        textResult += this.formatResourceToString(this.callLabelPrimary) + ' '
      }
    }
    // 该位置添加卫星通话图标，无障碍整组播报阅读内容

    textResult += getCallLabelSecondary(this.callData) + ' '
    if (!this.hangup) {
      if (this.callType === CallStateConst.TYPE_SATELLITE && !isIncomingCall(this.callState)) {
      } else {
        if (this.isShowSim) {
          if (this.callType === CallStateConst.TYPE_SATELLITE) {
          } else {
            textResult += this.screenReaderStatus ? (this.callData.accountId == 0 ?
              StringUtil.formatResourceToString($r('app.string.sim_card_num_no_space'), StringUtil.simIdFormat(1)) + ' ' :
              StringUtil.formatResourceToString($r('app.string.sim_card_num_no_space'),
                StringUtil.simIdFormat(2))) + ' ' :
              ''
          }
          if (isIncomingCall(this.callState) && !this.isShowTime()) {
            textResult += this.accountId == 1 ? this.simOperatorNameSecond : this.simOperatorNameFirst + ' '
          }
        }
        if (isIncomingCall(this.callState) &&
          (this.callLabelThird.length > 0 || this.isDistributeSink)) {
          textResult += this.getDistributedStringByStr(this.callLabelThird) + ' '
        }
      }
      if (this.callState === 1 || this.callStateScore) {
        textResult += this.screenReaderStatus ? StringUtil.formatResourceToString($r('app.string.maintain')) + ' ' : ''
      }
      if (this.callState === 2) {
        if (this.callType === CallStateConst.TYPE_SATELLITE) {
          textResult += StringUtil.formatResourceToString($r('app.string.satellite_dialing')) + ' '
        } else {
          textResult += this.getDistributedStringByRes($r('app.string.dialing')) + ' '
        }
      }
      if (this.callState === 3) {
        textResult += this.getDistributedStringByRes($r('app.string.partyIsRinging')) + ' '
      }
      if (this.isShowTime() && !this.callStateScore) {
        if (this.callType === 1) {
          textResult += this.screenReaderStatus ?
            StringUtil.formatResourceToString($r('app.string.call_hd_symbol')) + ' ' : ''
        }
        textResult += this.screenReaderStatus ?
          Utils.getInstance().getAccessibilityTextOfTime(this.callTimeList[0]?.callTime) + ' ' : ''
      }
      if (this.callState === 6 || this.callState === 7) {
        textResult += this.getDistributedStringByRes(
          this.callState === 6 ? $r('app.string.hangUpCompleted') : $r('app.string.hangingUp'))
      }
      if (this.callState === 2 &&
        this.callType === CallStateConst.TYPE_SATELLITE && this.satelliteDialingTips !== '') {
        textResult += this.formatResourceToString(this.satelliteDialingTips) + ' '
      }
    }
    if (this.hangup) {
      textResult += this.formatResourceToString(CallStateConst.callStateTextArray[7])
    }
    return textResult;
  }

  marqueeTextWidth() {
    let num = px2vp(measure.measureText({
      textContent: this.conferenceMemberStr,
      fontSize: $r('app.float.call_card_body_m_font'),
      fontWeight: FontWeight.Regular
    }));
    this.showMarquee = num > this.marqueeMaxWidth;
  }

  private getAccessSimString(): string {
    let accessText = this.screenReaderStatus ? (this.callData.accountId == 0 ?
      StringUtil.formatResourceToString($r('app.string.sim_card_num_no_space'), StringUtil.simIdFormat(1)) :
      StringUtil.formatResourceToString($r('app.string.sim_card_num_no_space'), StringUtil.simIdFormat(2))) : ''
    return accessText;
  }

  private checkIsShowCallSecondInfo(): boolean {
    if (this.isShowKeyboard && this.isNewFoldPhoneExternalScreen) {
      return false;
    }
    if (!this.isShowcCallSecondary && !this.isConferenceMode) {
      return false;
    }
    return true;
  }

  getTranslateY(translateTime: string) {
    if (this.isShowcCallSecondary) {
      return translateTime;
    } else {
      return '0';
    }
  }

  getCallTime(): string {
    if (this.callTimeList[0] === undefined) {
      return Utils.dateTime(this.timeTmp);
    }
    return Utils.dateTime(this.callTimeList[0].callTime)
  }

  // 获取小艺通话标志及折叠类型
  getCeliaTypeAndSplitScreenType(): boolean {
    return this.celiaAssistantShow && (this.curBp === 'md' || this.curBp === 'lg');
  }

  build() {
    GridRow({ columns: { xs: 2, sm: 4, md: this.getCeliaTypeAndSplitScreenType() ? 4 : 8, lg: 12 }, gutter: 24 }) {
      GridCol({ span: { xs: 2, sm: 4, md: this.getCeliaTypeAndSplitScreenType() ? 4 : 6, lg: 8 },
        offset: { md: this.getCeliaTypeAndSplitScreenType() ? 0 : 1, lg: 2 }
      }) {
        Column() {
          Column() {
            if (this.isShowKeyboard && this.textInput.length !== 0) {
              Scroll(this.scrollController) {
                Text(this.textInputValue)
                  .height(this.isNewFoldPhoneExternalScreen ? '26vp' : $r('app.float.call_card_textunput_text_height'))
                  .fontSize(this.isNewFoldPhoneExternalScreen ? '20vp' : $r('app.float.call_card_textinput_text_font'))
                  .lineHeight(this.isNewFoldPhoneExternalScreen ? '26vp' : $r('app.float.call_card_textunput_text_height'))
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('sys.color.font_on_primary'))
                  .textAlign(TextAlign.Center)
                  .constraintSize({ minWidth: '100%' })
                  .onTouch((event?: TouchEvent) => {
                    if (event?.type === TouchType.Move) {
                      this.textInputValue = this.textInput
                    }
                  })
                  .onSizeChange((old, newArea) => {
                    // 记录内部的高度
                    let scrollWidth = newArea.width as number;
                    const offset = this.scrollController.currentOffset();
                    this.scrollController.scrollTo({
                      yOffset: offset.yOffset,
                      xOffset: scrollWidth,
                      animation: false
                    });
                  })
                  .accessibilityLevel(ACCESSIBILITY_LEVEL_YES)
              }
              .scrollable(ScrollDirection.Horizontal)
              .scrollBar(BarState.Off)
              .width('100%')
              .translate({ y: this.translateName })
            } else {
              if (this.isConferenceMode) {
                Column() {
                  ConferenceTitle({ showConferenceDetail: $showConferenceDetail, isShowKeyboard: this.isShowKeyboard, })
                    .translate({ y: this.translateName })
                  Stack() {
                    Row() {
                      Marquee({ start: true, src: this.conferenceMemberStr, loop: this.marqueeLoop })
                        .width('85%')
                        .fontSize($r('app.float.call_card_body_m_font'))
                        .fontColor($r('sys.color.font_on_primary'))
                        .fontWeight(FontWeight.Regular)
                        .onAreaChange((oldValue: Area, newValue: Area) => {
                          LogUtils.i(TAG, `Marquee oldValue ${oldValue.width}, newValue ${newValue.width}`);
                          this.marqueeMaxWidth = Number(newValue.width);
                          this.marqueeTextWidth();
                        });

                      Text(StringUtil.formatPluralResourceToString($r('app.plural.conference_member_number'),
                        this.conferenceMemberCountNumber))
                        .maxLines(1)
                        .fontSize($r('app.float.call_card_body_m_font'))
                        .fontColor($r('sys.color.font_on_primary'))
                        .fontWeight(FontWeight.Regular)
                        .textAlign(TextAlign.Center)
                        .height($r('app.float.call_card_body_m_height'))
                        .lineHeight($r('app.float.call_card_body_m_line_height'))
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.Center)
                    .accessibilityGroup(true)
                    .accessibilityLevel('yes')
                    .visibility(this.showMarquee ? Visibility.Visible : Visibility.Hidden)

                    Row() {
                      Text(this.conferenceMemberStr)
                        .maxLines(1)
                        .fontSize($r('app.float.call_card_body_m_font'))
                        .fontColor($r('sys.color.font_on_primary'))
                        .fontWeight(FontWeight.Regular)
                        .height($r('app.float.call_card_body_m_height'))
                        .lineHeight($r('app.float.call_card_body_m_line_height'))

                      Text(StringUtil.formatPluralResourceToString($r('app.plural.conference_member_number'),
                        this.conferenceMemberCountNumber))
                        .maxLines(1)
                        .fontSize($r('app.float.call_card_body_m_font'))
                        .fontColor($r('sys.color.font_on_primary'))
                        .fontWeight(FontWeight.Regular)
                        .textAlign(TextAlign.Center)
                        .height($r('app.float.call_card_body_m_height'))
                        .lineHeight($r('app.float.call_card_body_m_line_height'))
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.Center)
                    .visibility(!this.showMarquee ? Visibility.Visible : Visibility.Hidden)
                    .accessibilityGroup(true)
                    .accessibilityLevel('yes')
                  }
                  .visibility((this.isNewFoldPhoneExternalScreen && this.isShowKeyboard) ? Visibility.None :
                  Visibility.Visible)
                }
                .width('100%')
                .translate({ y: this.getTranslateY(this.translateTime) })
                .animation({
                  curve: this.isShowKeyboard ?
                  curves.interpolatingSpring(0, 1, 480, 44) : curves.interpolatingSpring(0, 1, 342, 37)
                })
              } else {
                Row() {
                  if (this.callData.numberMarkInfo.markType === MarkType.MARK_TYPE_FRAUD) {
                    Image($r('app.media.leather_ic_public_error'))
                      .width('22vp')
                      .height('22vp')
                      .margin({ right: '9vp' })
                  }
                  Text(this.formatResourceToString(this.callLabelPrimary), { controller: this.controller })
                    .fontSize(this.isNewFoldPhoneExternalScreen ? (this.isShowKeyboard ? '20vp' : '30vp') :
                      this.getCeliaTypeAndSplitScreenType() ? '30vp' : this.getNickFontSize())
                    .fontWeight(600)
                    .fontColor($r('sys.color.font_on_primary'))
                    .maxLines((this.isNewFoldPhoneExternalScreen ||
                    SplitScreenManager.getInstance().isNicknameOneLine(this.splitScreenType, this.callData)) ? 1 : 2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .textAlign(TextAlign.Center)
                    .accessibilityLevel('yes')
                    .onAreaChange(() => {
                      let layoutManager: LayoutManager = this.controller.getLayoutManager();
                      this.contactNameLine = layoutManager.getLineCount();
                    })
                }
                .translate({ y: this.translateName })
                .animation({
                  curve: this.isShowKeyboard ?
                  curves.interpolatingSpring(0, 1, 480, 44) : curves.interpolatingSpring(0, 1, 342, 37)
                })
                .justifyContent(FlexAlign.Center)
                .alignItems(VerticalAlign.Center)
                .id('callui_callLabelPrimary_Row')
              }
            }
          }
          .margin({
            bottom: this.getCallPrimaryLabelMarginBottom()
          })

          Row() {
            Text($r('app.string.fraud_phone_call'))
              .fontSize($r('app.float.call_card_body_m_font'))
              .height($r('app.float.call_card_body_m_height'))
              .lineHeight($r('app.float.call_card_body_m_height'))
              .fontColor($r('sys.color.font_on_primary'))
              .margin({ end: LengthMetrics.vp(4) })
              .visibility((this.isAntiFraud ||
                (this.callData.numberMarkInfo.markType.valueOf() === 12 && isIncomingCall(this.callState))) &&
                !this.isShowKeyboard ?
              Visibility.Visible : Visibility.None)
            if (this.callType === CallStateConst.TYPE_SATELLITE && isIncomingCall(this.callState) &&
              !this.isShowSim) {
              Image(this.isHyacinthMode ? $r('app.media.ic_hyacinth_call') : $r('app.media.ic_satellite_call'))
                .margin({ end: LengthMetrics.vp(4) })
                .width(14)
                .height(14)
                .draggable(false)
                .translate({
                  y: this.isConferenceMode ? this.conferenceModeTranslate : this.getTranslateY(this.translateTime)
                })
                .animation({
                  curve: this.isShowKeyboard ?
                  curves.interpolatingSpring(0, 1, 480, 44) : curves.interpolatingSpring(0, 1, 342, 37)
                })
                .align(Alignment.Center)
            }
            Text(this.callLabelSecondary)
              .fontSize($r('app.float.call_card_body_m_font'))
              .height($r('app.float.call_card_body_m_height'))
              .lineHeight($r('app.float.call_card_body_m_height'))
              .fontColor($r('sys.color.font_on_primary'))
              .transition(
                TransitionEffect.opacity(this.contactAppear ? 1 : 0)
                  .animation({ duration: 100, curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1) }))
              .visibility((!this.isShowKeyboard && !this.isConferenceMode) ? Visibility.Visible : Visibility.Hidden)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .textAlign(TextAlign.Center)
              .accessibilityText('"' + getCallLabelSecondary(this.callData) + '"')
              .accessibilityLevel('yes')
          }
          .height(19)
          .margin({ bottom: $r('sys.float.padding_level1') })
          .alignSelf(ItemAlign.Center)
          .visibility(this.checkIsShowCallSecondInfo() ? Visibility.Visible : Visibility.None)

          if (!this.hangup) {
            Row() {
              if (this.callType === CallStateConst.TYPE_SATELLITE && !isIncomingCall(this.callState)) {
                Image(this.isHyacinthMode ? $r('app.media.ic_hyacinth_call') : $r('app.media.ic_satellite_call'))
                  .margin({ end: LengthMetrics.vp(4) })
                  .width(14)
                  .height(14)
                  .draggable(false)
                  .translate({
                    y: this.isConferenceMode ? this.conferenceModeTranslate : this.getTranslateY(this.translateTime)
                  })
                  .animation({
                    curve: this.isShowKeyboard ?
                    curves.interpolatingSpring(0, 1, 480, 44) : curves.interpolatingSpring(0, 1, 342, 37)
                  })
              } else {
                if (this.isShowSim) {
                  if (this.callType === CallStateConst.TYPE_SATELLITE) {
                    Image(this.isHyacinthMode ? $r('app.media.ic_hyacinth_call') : $r('app.media.ic_satellite_call'))
                      .margin({ end: LengthMetrics.vp(4) })
                      .width(14)
                      .height(14)
                      .draggable(false)
                      .iconStyles()
                  } else {
                    SymbolGlyph(getSimIcon(this.accountId))
                      .fontColor(['#FFFFFF'])
                      .fontSize($r('app.float.wh_value_12'))
                      .margin({ end: LengthMetrics.vp(4) })
                      .width(12)
                      .height(12)
                      .draggable(false)
                      .iconStyles()
                      .accessibilityText(this.getAccessSimString())
                      .accessibilityLevel('yes')
                  }
                  if (isIncomingCall(this.callState) && !this.isShowTime()) {
                    Text(this.accountId == 1 ? this.simOperatorNameSecond : this.simOperatorNameFirst)
                      .textExtend()
                      .textFadeInOutExtend(this.showSimFirstFlag && !this.onAnswer,
                        this.onAnswer || this.companyTimer === -1)
                      .accessibilityLevel('yes')
                      .id('sim_operator_name_id')
                      .onAppear(() => {
                        LogUtils.i(TAG, 'simOperatorName show');
                      })
                  }
                }

                if (isIncomingCall(this.callState) &&
                  (this.callLabelThird.length > 0 || this.isDistributeSink)) {
                  Text(this.getDistributedStringByStr(this.callLabelThird))
                    .enabled(false)
                    .textExtend(this.isNewFoldPhoneExternalScreen)
                    .textAlign(TextAlign.Center)
                    .textFadeInOutExtend(!this.showSimFirstFlag && !this.onAnswer,
                      this.onAnswer || this.companyTimer === -1)
                    // 联系人部门详情 verde外屏最多显示1行 其他场景显示两行
                    .maxLines(this.isNewFoldPhoneExternalScreen ? 1 : 2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .accessibilityLevel('yes')
                    .accessibilityText(this.screenReaderStatus ?
                      StringUtil.formatResourceToString($r(this.callLabelThird)) : '')
                }
              }
              if (this.callState === 1 || this.callStateScore) {
                Text(this.getDistributedStringByRes($r('app.string.callHold')))
                  .textExtend()
                  .fontWeight(FontWeight.Medium)
                  .translate({
                    y: this.isConferenceMode ? this.conferenceModeTranslate : this.getTranslateY(this.translateTime)
                  })
                  .animation({
                    curve: this.isShowKeyboard ?
                    curves.interpolatingSpring(0, 1, 480, 44) : curves.interpolatingSpring(0, 1, 342, 37)
                  })
                  .accessibilityLevel('yes')
              }

              if (this.callState === 2) {
                if (this.callType === CallStateConst.TYPE_SATELLITE) {
                  Row() {
                    Text(this.isHyacinthMode ? $r('app.string.hyacinth_dialing') : $r('app.string.satellite_dialing'))
                      .textExtend()
                      .align(Alignment.Center)
                    this.dialingDotBuilder();
                  }
                  .justifyContent(FlexAlign.Center)
                  .translate({ y: this.getTranslateY(this.translateTime) })
                  .animation({
                    curve: this.isShowKeyboard ?
                    curves.interpolatingSpring(0, 1, 480, 44) : curves.interpolatingSpring(0, 1, 342, 37)
                  })
                } else {
                  Row() {
                    Text(this.getDistributedStringByRes($r('app.string.dialing')))
                      .textExtend()
                      .align(Alignment.Start)
                    if (!this.isDistributeSink) {
                      this.dialingDotBuilder();
                    }
                  }
                  .justifyContent(FlexAlign.Center)
                  .translate({ y: this.getTranslateY(this.translateTime) })
                  .animation({
                    curve: this.isShowKeyboard ?
                    curves.interpolatingSpring(0, 1, 480, 44) : curves.interpolatingSpring(0, 1, 342, 37)
                  })
                }
              }

              if (this.callState === 3) {
                Text(this.getDistributedStringByRes($r('app.string.partyIsRinging')))
                  .textExtend()
                  .translate({ y: this.getTranslateY(this.translateTime) })
                  .animation({
                    curve: this.isShowKeyboard ?
                    curves.interpolatingSpring(0, 1, 480, 44) : curves.interpolatingSpring(0, 1, 342, 37)
                  })
                  .accessibilityLevel('yes')
                  .accessibilityText(this.screenReaderStatus ?
                  StringUtil.formatResourceToString($r('app.string.partyIsRinging')) : '')
              }

              if (this.isShowTime() && !this.callStateScore) {
                Row() {
                  if (CallUtils.getImsDomain(this.callData) === IMS_DOMAIN.IMS_DOMAIN_VOWIFI) {
                    Image($r('app.media.vowifi'))
                      .margin({ end: LengthMetrics.vp(4) })
                      .width(22)
                      .height(12)
                      .draggable(false)
                      .translate({ y: this.isConferenceMode ? this.conferenceModeTranslate : 0 })
                  } else if (this.callType === CallStateConst.TYPE_IMS) {
                    NewCallIcon({
                      isHDMode: this.showNewCall,
                      iconColor: '#FFFFFF',
                    })
                      .margin({ end: LengthMetrics.vp(4) })
                      .translate({ y: this.isConferenceMode ? this.conferenceModeTranslate : 0 })
                      .accessibilityLevel('yes')
                      .accessibilityText(this.screenReaderStatus ?
                        StringUtil.formatResourceToString($r('app.string.call_hd_symbol')) : '')
                  }

                  Text(this.getDistributedStringByStr(this.getCallTime()))
                    .textExtend()
                    .translate({ y: this.isConferenceMode ? this.conferenceModeTranslate : 0 })
                    .fontFeature('\'ss01\' on')
                    .accessibilityLevel('yes')
                    .accessibilityText(this.screenReaderStatus ?
                    Utils.getInstance().getAccessibilityTextOfTime(this.callTimeList[0]?.callTime) : '')
                    .id('call_time_id')
                    .onAppear(() => {
                      LogUtils.i(TAG, 'callTime show');
                    })
                }
                .translate({ y: this.getTranslateY(this.translateTime) })
                .animation({
                  curve: this.isShowKeyboard ?
                  curves.interpolatingSpring(0, 1, 480, 44) : curves.interpolatingSpring(0, 1, 342, 37)
                })
              }
              if (this.callState === 6 || this.callState === 7) {
                Text(this.getDistributedStringByRes(
                  this.callState === 6 ? $r('app.string.hangUpCompleted') : $r('app.string.hangingUp')))
                  .textExtend()
                  .translate({ y: this.getTranslateY(this.translateTime) })
                  .accessibilityLevel(ACCESSIBILITY_LEVEL_YES)
              }
            }
            .constraintSize({ minHeight: 19 })
            .margin({ bottom: $r('sys.float.padding_level1') })
            .visibility((this.isShowKeyboard && this.isNewFoldPhoneExternalScreen) || this.isIncomingAndNotShowThird() ?
            Visibility.None :
            Visibility.Visible)

            if (this.callState === 2 &&
              this.callType === CallStateConst.TYPE_SATELLITE && this.satelliteDialingTips !== '') {
              Row() {
                Text(this.satelliteDialingTips)
                  .textExtend()
                  .align(Alignment.Start)
              }
              .translate({ y: this.getTranslateY(this.translateTime) })
              .animation({
                curve: this.isShowKeyboard ?
                curves.interpolatingSpring(0, 1, 480, 44) : curves.interpolatingSpring(0, 1, 342, 37)
              })
              .visibility((this.isShowKeyboard && this.isNewFoldPhoneExternalScreen) ? Visibility.None :
              Visibility.Visible)
            }
          }

          if (this.hangup) {
            Column() {
              Text(CallStateConst.callStateTextArray[7])
                .textExtend()
                .translate({ y: this.getTranslateY(this.translateTime) })
            }
            .visibility((this.isShowKeyboard && this.isNewFoldPhoneExternalScreen) ? Visibility.None :
            Visibility.Visible)
          }

          Row() {
            Image($r('app.media.security_shield_white'))
              .height('12vp')
              .width('12vp')
              .margin({ end: LengthMetrics.vp(4) })
            Text(this.antiFraudIdentifies)
              .fontSize($r('app.float.call_card_body_m_font'))
              .height($r('app.float.call_card_body_m_height'))
              .lineHeight($r('app.float.call_card_body_m_height'))
              .fontColor($r('sys.color.icon_on_primary'))
            Text(this.antiTip)
              .dialingDotExtend(true)
              .visibility(this.antiFraudState === 1 ? Visibility.Visible : Visibility.None)
          }
          .visibility((this.antiFraudState === 1 || this.antiFraudState === 2) ?
          Visibility.Visible : Visibility.None)
        }
        .justifyContent(this.justifyContentLeve(this.isNewFoldPhoneExternalScreen))
        .layoutWeight(this.layoutWeightNumber())
        .transition(isIncomingCall(this.callState) ? TransitionEffect.OPACITY
          .animation({ duration: 100, delay: 100, curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1) }) : undefined)
        .accessibilityLevel('yes')
        .accessibilityGroup(true, { accessibilityPreferred : true })
        .onAppear(() => {
          AccessibilityUtil.requestFocusForAccessibility('contactCard_column');
        })
        .id('contactCard_column')
      }
    }
    .margin({
      left: this.isNewFoldPhoneInnerFullScreen ? '56vp' :
      CallColumnUtils.getInstance().getPaddingSpace(this.getCeliaTypeAndSplitScreenType() ? 'sm' : this.curBp),
      right: this.isNewFoldPhoneInnerFullScreen ? '56vp' :
      CallColumnUtils.getInstance().getPaddingSpace(this.getCeliaTypeAndSplitScreenType() ? 'sm' : this.curBp)
    })
  }
}

@Extend(Text)
function textExtend(limitLineHeight: boolean = true) {
  .fontSize($r('app.float.call_card_body_m_font'))
  .height(limitLineHeight ? $r('app.float.call_card_body_m_height') : 'auto')
  .lineHeight(limitLineHeight ? $r('app.float.call_card_body_m_height') : 0)
  .fontColor($r('sys.color.font_on_primary'))
  .accessibilityLevel('yes')
}

@Extend(Text)
function textFadeInOutExtend(showFlag: boolean, noAnimationFlag: boolean) {
  .visibility(showFlag ? Visibility.Visible : Visibility.None)
  .opacity(showFlag ? 1 : 0)
  .transition(TransitionEffect.OPACITY.animation({
    duration: noAnimationFlag ? 0 : 1000,
    delay: 0,
    curve: Curve.EaseInOut,
    iterations: 1
  }))
}

@Extend(Text)
function dialingDotExtend(isDotVisible: boolean) {
  .fontSize($r('app.float.call_card_body_m_font'))
  .height($r('app.float.call_card_body_m_height'))
  .lineHeight($r('app.float.call_card_body_m_height'))
  .fontColor($r('sys.color.font_on_secondary'))
  .visibility(isDotVisible ? Visibility.Visible : Visibility.Hidden)
}
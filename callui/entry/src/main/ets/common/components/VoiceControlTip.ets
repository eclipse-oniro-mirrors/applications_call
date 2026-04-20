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
import DefaultCallData from '../struct/TypeUtils';
import CallStateConst from '../constant/CallStateConst';
import { isVideoCall, isVoiceCall } from '../utils/CallListHelper';
import CallColumnUtils from '../utils/CallColumnUtils';
import { StringUtil } from '../utils/StringUtil';
import LogUtils from '../utils/LogUtils';

const TAG = 'VoiceControlTip';

let textSrcMap: Record<string, string> = {
  'answerTextTip': StringUtil.formatResourceToString($r('app.string.answering_call_prompt'),
    StringUtil.formatResourceToString($r('app.string.answering_call_words'))),
  'rejectTextTip': StringUtil.formatResourceToString($r('app.string.reject_call_prompt'),
    StringUtil.formatResourceToString($r('app.string.hangup_call_words'))),
  'hangUpTextTip': StringUtil.formatResourceToString($r('app.string.end_call_prompt'),
    StringUtil.formatResourceToString($r('app.string.hangup_call_words')))
}

@Component
export struct VoiceControlTip {
  @Link @Watch('shouldShowVoiceTips') callData: DefaultCallData;
  @Link @Watch('shouldShowVoiceTips') callList: Array<DefaultCallData>;
  @StorageProp('curBp') @Watch('shouldShowVoiceTips') curBp: string = '';
  @StorageProp('isSuperPrivacy') @Watch('shouldShowVoiceTips') isSuperPrivacy: boolean = false;
  @StorageProp('statusBarHeight') @Watch('shouldShowVoiceTips') statusBarHeight: number = 0;
  @State videoStatusBarHeight: number = 0;
  @State textLines: string[] = [];
  @State textMaxWidth: number | string = 'auto';

  shouldShowVoiceTips(): void {
    // not show voice prompts for incoming call or outgoing call
    // 1. no call
    // 2. enable super privacy mode
    // 3. no active or hold call
    LogUtils.i(TAG,
      `shouldShowVoiceTips callId:${this.callData?.callId},videoState:${this.callData?.videoState},curBp:${this.curBp}`);
    if (!this.callList || this.callList.length === 0 || !this.callData || this.isSuperPrivacy) {
      LogUtils.i(TAG, `shouldShowVoiceTips hideReason:no call or super privacy mode`);
      this.initData();
      return;
    }
    let callStateList: number[] = [
      CallStateConst.callStateObj.CALL_STATUS_ACTIVE,
      CallStateConst.callStateObj.CALL_STATUS_HOLDING
    ];
    let hasActiveOrHoldCall = this.callList.some(call => callStateList.includes(call.callState));
    if (hasActiveOrHoldCall) {
      LogUtils.i(TAG, `shouldShowVoiceTips hideReason:hasActiveOrHoldCall,callId:${this.callData.callId}`);
      this.initData();
      return;
    }
    // show voice prompts for incoming call or outgoing call
    // incoming: incoming call, and the call is not connected.
    // outgoing: outgoing call, and the other party does not answer
    let currentCallData = this.callData;
    if (currentCallData.callState === CallStateConst.CALL_STATUS_INCOMING) {
      LogUtils.i(TAG, `shouldShowVoiceTips voiceTipInComingAppear callId:${currentCallData.callId}`);
      this.calcTextWidth(CallStateConst.CALL_DIRECTION_INCOMING);
      return;
    } else if (currentCallData.callState === CallStateConst.CALL_STATUS_ALERTING ||
      currentCallData.callState === CallStateConst.CALL_STATUS_DIALING) {
      this.calcTextWidth(CallStateConst.CALL_DIRECTION_OUTGOING);
      if (isVideoCall(currentCallData.videoState)) {
        this.videoStatusBarHeight = this.statusBarHeight;
      } else if (isVoiceCall(currentCallData)) {
        this.videoStatusBarHeight = 0;
      }
      LogUtils.i(TAG,
        `shouldShowVoiceTips voiceTipOutingAppear callId:${currentCallData.callId},barHeight:${this.videoStatusBarHeight}`);
      return;
    }
    // not show voice prompts for incoming call or outgoing call
    this.initData();
    LogUtils.i(TAG,
      `shouldShowVoiceTips not show voice prompts,callId:${currentCallData.callId},callState:${currentCallData.callState}`);
  }

  private initData() {
    this.textMaxWidth = 'auto';
    this.textLines = [];
    this.videoStatusBarHeight = 0;
  }

  private calcTextWidth(inOrOut: number) {
    LogUtils.i(TAG, `calcTextWidth inOrOut:${inOrOut},inComing:${inOrOut === CallStateConst.CALL_DIRECTION_INCOMING}`);
    let uiMaxWidth = CallColumnUtils.getInstance().getUiMaxWidth(this.curBp, 24);
    // text maxWith (- image 16 - margin 4)
    uiMaxWidth = uiMaxWidth - 20;
    LogUtils.i(TAG, `uiMaxWidth:${uiMaxWidth}`);

    // calculating the width of the voice prompt text
    if (inOrOut === CallStateConst.CALL_DIRECTION_INCOMING) {
      this.calcIncomingTextWidth(uiMaxWidth);
    } else if (inOrOut === CallStateConst.CALL_DIRECTION_OUTGOING) {
      this.calcOutGoingTextWidth(uiMaxWidth);
    } else {
      LogUtils.w(TAG, `invalid param ${inOrOut}`);
    }
    LogUtils.i(TAG, `textMaxWidth:${this.textMaxWidth}`);
  }

  private calcOutGoingTextWidth(uiMaxWidth: number) {
    let text1Width =
      CallColumnUtils.getInstance().getTextWidth(textSrcMap['hangUpTextTip'], $r('app.float.call_card_body_m_font'));
    let currentTextLines: string[] = [];
    if (text1Width > uiMaxWidth) {
      this.textMaxWidth = uiMaxWidth;
      currentTextLines.push(...CallColumnUtils.getInstance()
        .splitTextIntoLines(textSrcMap['hangUpTextTip'],
          $r('app.float.call_card_body_m_font'),
          uiMaxWidth));
    } else {
      this.textMaxWidth = text1Width;
      currentTextLines.push(textSrcMap['hangUpTextTip']);
    }
    this.compareAndSetTextLine(currentTextLines);
  }

  private calcIncomingTextWidth(uiMaxWidth: number) {
    let text1Width =
      CallColumnUtils.getInstance().getTextWidth(textSrcMap['answerTextTip'], $r('app.float.call_card_body_m_font'));
    let text2Width =
      CallColumnUtils.getInstance().getTextWidth(textSrcMap['rejectTextTip'], $r('app.float.call_card_body_m_font'));
    let textMaxWidth = Math.max(text1Width, text2Width);
    let currentTextLines: string[] = [];
    if (textMaxWidth > uiMaxWidth) {
      this.textMaxWidth = uiMaxWidth;
      currentTextLines.push(...CallColumnUtils.getInstance()
        .splitTextIntoLines(textSrcMap['answerTextTip'],
          $r('app.float.call_card_body_m_font'),
          uiMaxWidth));
      currentTextLines.push(...CallColumnUtils.getInstance()
        .splitTextIntoLines(textSrcMap['rejectTextTip'],
          $r('app.float.call_card_body_m_font'),
          uiMaxWidth));
    } else {
      this.textMaxWidth = textMaxWidth;
      currentTextLines.push(textSrcMap['answerTextTip']);
      currentTextLines.push(textSrcMap['rejectTextTip']);
    }
    this.compareAndSetTextLine(currentTextLines);
  }

  private compareAndSetTextLine(currentTextLines: string[]) {
    if (this.textLines.length !== currentTextLines.length) {
      LogUtils.i(TAG, `compareAndSetTextLine update1 ${currentTextLines.length}`);
      this.textLines = currentTextLines;
      return;
    }
    let changeFlag = false;
    for (let i = 0; i < currentTextLines.length; i++) {
      if (this.textLines[i] !== currentTextLines[i]) {
        this.textLines = currentTextLines;
        changeFlag = true;
        break;
      }
    }
    if (changeFlag) {
      LogUtils.i(TAG, `compareAndSetTextLine update2 ${currentTextLines.length}`);
      this.textLines = currentTextLines;
      return;
    }
    LogUtils.i(TAG, `compareAndSetTextLine no need to update`);
  }

  aboutToAppear() {
    this.shouldShowVoiceTips();
    LogUtils.i(TAG, `aboutToAppear textLines:${this.textLines.length}`);
  }

  aboutToDisappear() {
    LogUtils.i(TAG, `aboutToDisappear`);
  }

  @Builder
  voiceControlTip() {
    if (this.textLines.length > 0) {
      Row() {
        SymbolGlyph($r('sys.symbol.mic_fill'))
          .fontSize(16)
          .height($r('app.float.radius_16'))
          .width($r('app.float.radius_16'))
          .fontColor([$r('sys.color.icon_on_primary')])
          .draggable(false)
          .opacity(0.6)

        this.swiperText();
      }
      .width('100%')
      .height('100%')
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .onAppear(() => {
        LogUtils.i(TAG,
          `onAppear statusBarHeight:${this.statusBarHeight},videoHeight:${this.videoStatusBarHeight}`);
      })
    }
  }

  @Builder
  swiperText() {
    Row() {
      Swiper() {
        ForEach(this.textLines, (item: string) => {
          Text(item)
            .fontSize($r('app.float.call_card_body_m_font'))
            .height($r('app.float.call_card_body_m_height'))
            .lineHeight($r('app.float.call_card_body_m_height'))
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Regular)
            .fontColor($r('sys.color.font_on_secondary'))
            .id('voice_hang_up_call_tip')
            .textAlign(TextAlign.Center)
            .width(this.textMaxWidth)
        }, (item: string) => item)
      }
      .autoPlay(this.textLines.length === 1 ? false : true)
      .loop(true)
      .indicator(false)
      .vertical(true)
      .enabled(false)
      .cachedCount(this.textLines.length)
      .interval(3000)
      .duration(500)
      .curve(Curve.Friction)
    }
    .height('100%')
    .margin({ left: 4 })
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: 24 }) {
        GridCol({ span: { xs: 2, sm: 4, md: 6, lg: 8 }, offset: { md: 1, lg: 2 } }) {
          this.voiceControlTip();
        }
      }
      .onBreakpointChange((bp: string) => {
        LogUtils.i(TAG, `onBreakpointChange bp:${bp}`);
      })
    }
    .height('100%')
    .margin({
      top: this.videoStatusBarHeight,
      left: CallColumnUtils.getInstance().getPaddingSpace(this.curBp),
      right: CallColumnUtils.getInstance().getPaddingSpace(this.curBp)
    })
  }
}

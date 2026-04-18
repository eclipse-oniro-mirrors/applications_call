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
import DefaultCallData from '../struct/TypeUtils';
import CallTimeListStruct from '../struct/CallTimeListStruct';
import MultiContactCard from './MultiContactCard';
import ContactCard from './ContactCard';
import { getActiveSimCount, getSimOperatorNames } from '../../model/SimManager';
import { ScreenInfo } from '../struct/CallUiDataStruct';
import CallCardScreen from '../utils/CallCardScreen';
import SplitScreenManager, { SplitScreenType } from '../../model/SplitScreenManager';
import BottomViewModel from '../../viewmodel/BottomViewModel';
import { soundzoneSupport } from '../../ServiceAbility/CallManagerService';
import CallStateConst from '../../common/constant/CallStateConst';
import AudioDeviceManager from '../../model/audio/AudioDeviceManager';
import { isTwoInOne } from '../utils/DeviceTypeUtils';
import ScreenAdapterUtils from '../utils/ScreenAdapterUtils';
import * as Constants from '../utils/Constants';
import { isIncomingCall } from '../utils/CallListHelper';

const TAG = 'CallCard';

// 776是三折叠竖屏时的高度，707是Delphi横屏高度，有盈余再压缩下取700
const BREAKPOINT_OF_2LINE_NAME: number = 776;
const BREAKPOINT_OF_1LINE_NAME: number = 700;

@Component
export default struct CallCard {
  @State callStateText: string = '';
  @State dialing: string = '.';
  @Prop isShowKeyboard: boolean = false;
  @Link callList: Array<DefaultCallData>;
  @Link @Watch('refreshingData') callData: DefaultCallData;
  @Link callTimeList: Array<CallTimeListStruct>;
  @Link showConferenceDetail: boolean;
  @Link callType: number;
  @Link contactAvatar?: PixelMap | null;
  @Link callState: number;
  @State accountId: number = -1;
  @State callId: number = -1
  @State isShowSim: boolean = false;
  @Prop callListCount: number = 0;
  @Prop translateName: string = '';
  @Prop translateTime: string = '';
  @Prop contactAppear: boolean = false;
  @Prop @Watch('isHideAvatarNoSpace') contactNameLine: number = 1;
  @StorageLink('isShowSmartWindow') isShowSmartWindow: boolean = false;
  @State multiContactName: string = '';
  @State multiContactNumber: string = '';
  @State imageWidthorHeight: number = 110;
  @State callLableMarginTop: string | Resource = $r('app.float.calling_name_top');
  @State callImageTop: string | Resource = $r('app.float.calling_photo_top');
  @State callImageBottom: string | Resource = $r('app.float.wh_value_24');
  @State silentCallDisplay: boolean = AudioDeviceManager.getInstance().isCurEarpiece();
  @Consume isConferenceMode: boolean;
  @StorageProp('statusBarHeight') @Watch('isImageWidth') statusBarHeight: number = 0;
  @StorageProp('windowSizeChangeMd') @Watch('isImageWidth') windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  }
  @StorageProp('curBp') curBp: string = '';
  @StorageLink('FoldStatus') @Watch('isImageWidth') foldStatus: number = 0;
  @StorageProp('TwoWayPrivacyEnhancedCall') twoWayPrivacyEnhancedCallState: boolean = false;
  @StorageProp('isSuperPrivacy') isSuperPrivacy: boolean = false;
  @StorageProp(Constants.VOICE_CONTROL_SWITCH) voiceControlSwitch: boolean = false;
  @StorageLink('LandscapeOrPortrait') @Watch('isImageWidth') landscapeOrPortrait: number = -1;
  @StorageLink('SplitScreenType') splitScreenType: SplitScreenType = SplitScreenType.DEFAULT;
  @StorageLink('SplitScreenHeight') splitHeight: number = 0;
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  @StorageLink('isNewFoldPhoneInnerFullScreen') isNewFoldPhoneInnerFullScreen: boolean = false;
  @StorageLink('newFoldSplitPortraitScreenType') newFoldSplitPortraitScreenType: SplitScreenType =
    SplitScreenType.DEFAULT;
  @StorageLink('isApplyNewStyle') isApplyNewStyle: boolean = false;
  @Prop celiaAssistantShow: boolean;

  private mCallCardScreen: CallCardScreen = CallCardScreen.getInstance();
  private imageWidthorHeightHalf: number = 2;
  private showSmartWindowBottom: number = 10;
  private showBigWindowBottom: number = 24;
  private mDeviceChange: BottomViewModel = BottomViewModel.getInstance();
  private callback = (isCurEarpiece: boolean) => {
    this.silentCallDisplay = isCurEarpiece;
  };

  public aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    this.mDeviceChange.addIsCurEarpieceListener(this.callback);
    this.refreshingData();
    this.initInstance();
    this.checkSimCard();
  }

  public aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear');
    this.mDeviceChange.removeIsCurEarpieceListener(this.callback);
  }

  checkSimCard() {
    let simCount = AppStorage.get<number>('simCount') || 0;
    // 打开联系人初始化CallManagerService的时候还未插卡，这里再查一次
    if (simCount < 2) {
      getActiveSimCount(activeSimCount => {
        LogUtils.i(TAG, `retry simCount is: ${activeSimCount}`);
        simCount = activeSimCount;
        AppStorage.setOrCreate('simCount', activeSimCount);
      });
    }
    LogUtils.i(TAG, `checkSimCard simCount = ${simCount} IsEmergencyPhoneNumber: ${this.callData.isEcc}`);
    if (simCount === -1) {
      LogUtils.i(TAG, 'checkSimCard -1');
      return;
    }
    this.isShowSim = simCount > 1;
    if (this.isShowSim) {
      getSimOperatorNames();
    }
  }

  refreshingData(): void {
    this.accountId = this.callData.accountId;
    this.callId = this.callData.callId;
  }

  initInstance() {
    this.callLableMarginTop = this.mCallCardScreen.callLableTop(this.isShowSmartWindow, this.statusBarHeight,
      this.isShowKeyboard, this.isConferenceMode);
    if (this.contactAvatar) {
      this.callImageTop = this.mCallCardScreen.callImageTop(this.isShowSmartWindow,
        this.statusBarHeight, this.windowSizeChangeMd, this.landscapeOrPortrait);
      this.callImageBottom = this.mCallCardScreen.callImageBottom(this.isShowSmartWindow,
        this.statusBarHeight, this.windowSizeChangeMd, this.landscapeOrPortrait);
    }
  }

  isShowKeyboardChange() {
    this.callLableMarginTop = this.mCallCardScreen.callLableTop(this.isShowSmartWindow, this.statusBarHeight,
      this.isShowKeyboard, this.isConferenceMode);
  }

  /**
   * Call status
   *
   * @return {number} - Call status
   */

  isImageWidth() {
    if (this.contactAvatar) {
      if (ScreenAdapterUtils.isTrifoldPhone()) {
        this.imageWidthorHeight = 110;
      } else {
        this.imageWidthorHeight = this.mCallCardScreen.getImageWidth($r('app.float.call_avatar_width'),
          this.windowSizeChangeMd, this.landscapeOrPortrait, this.curBp);
      }
    }
  }

  landscapeOrPortraitChange() {
    if (this.windowSizeChangeMd.height) {
      this.isImageWidth();
    }
  }

  private columnJustifyContent(isNewFoldPhoneExternalScreen: boolean) {
    if (isNewFoldPhoneExternalScreen || this.isNewFoldPhoneInnerFullScreen || this.isApplyNewStyle) {
      return FlexAlign.Center;
    }
    if (SplitScreenManager.getInstance().isContactCardTop(this.splitHeight) ||
      this.newFoldSplitPortraitScreenType > SplitScreenType.DEFAULT) {
      return FlexAlign.Start
    }
    let alignR = this.isShowAvatar() && !this.isHideAvatarNoSpace();
    return alignR ? FlexAlign.End : FlexAlign.Center;
  }

  private isShowAvatar(isNewFoldPhoneExternalScreen: boolean = false): boolean {
    if (!SplitScreenManager.getInstance().isCallHeadShow(this.splitScreenType)) {
      return false;
    }
    if (isIncomingCall(this.callState) && this.callData.extraParams?.['VideoRingPath'] &&
      this.callData.extraParams?.['VideoRingPath'] !== '') {
      return false;
    }
    return this.contactAvatar !== undefined && this.contactAvatar !== null && !this.isShowKeyboard &&
      !this.isConferenceMode && !this.callData.isVoiceMailNumber &&
      (!this.isShowSmartWindow || (isTwoInOne() && this.isShowSmartWindow)) &&
      !isNewFoldPhoneExternalScreen;
  }

  // 当页面放不下时隐藏头像，直接在isShowAvatar加条件判断旋转有残影
  private isHideAvatarNoSpace() {
    if (this.contactNameLine === 2 && px2vp(this.windowSizeChangeMd?.height) < BREAKPOINT_OF_2LINE_NAME) {
      return true;
    } else if (this.contactNameLine === 1 && px2vp(this.windowSizeChangeMd?.height) < BREAKPOINT_OF_1LINE_NAME) {
      return true
    } else {
      LogUtils.i(TAG, `windowHeight=${px2vp(this.windowSizeChangeMd?.height)} nameLine:${this.contactNameLine}`);
    }
    return false;
  }

  getContactCardTop(): number {
    let spliteTop = SplitScreenManager.getInstance().getContactCardTop(this.splitHeight);
    if (spliteTop >= 0) {
      return spliteTop;
    }
    return 0;
  }

  getMultiContactCardTop(isNewFoldPhoneExternalScreen: boolean): string {
    if (isNewFoldPhoneExternalScreen) {
      return '0vp';
    }
    if (SplitScreenManager.getInstance().isSplitScreen(this.splitScreenType)) {
      return SplitScreenManager.getInstance().getMultiContactCardTop(this.callList, this.splitScreenType);
    }
    if (this.isShowSmartWindow) {
      return '30vp'
    }
    return '56vp';
  }

  getAvatarMarginBottom() {
    if (this.isShowSmartWindow && !isTwoInOne()) {
      return this.showSmartWindowBottom;
    }
    if (this.isNewFoldPhoneInnerFullScreen) {
      return '8vp';
    }
    return this.showBigWindowBottom;
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      if (!SplitScreenManager.getInstance().isSplitScreen(this.splitScreenType)) {
        if (this.twoWayPrivacyEnhancedCallState && !(this.voiceControlSwitch || this.isSuperPrivacy)) {
          this.twoWayPrivacyEnhancedCall();
        } else if (soundzoneSupport && this.silentCallDisplay &&
          (this.callState === CallStateConst.CALL_STATUS_ACTIVE)) {
          this.silentCall();
        }
      }
      if (this.callListCount > 1) {
        MultiContactCard({
          callData: $callData,
          callState: $callState,
          accountId: $accountId,
          callId: $callId,
          isShowKeyboard: this.isShowKeyboard,
          callList: $callList,
          callTimeList: $callTimeList,
          showConferenceDetail: $showConferenceDetail,
          isShowSim: $isShowSim,
          celiaAssistantShow: this.celiaAssistantShow,
        })
          .margin({ top: this.getMultiContactCardTop(this.isNewFoldPhoneExternalScreen) })
          .layoutWeight(1)
          .id('callui_compid_MultiContactCard')
      } else {
        this.oneCallListCard()
      }
    }
  }

  @Builder
  oneCallListCard() {
    Column() {
      // contact avatar
      if (this.isShowAvatar(this.isNewFoldPhoneExternalScreen)) {
        this.userHeadPhoto()
      }
      ContactCard({
        callData: $callData,
        isShowKeyboard: this.isShowKeyboard,
        callState: $callState,
        callType: $callType,
        accountId: $accountId,
        contactAvatar: $contactAvatar,
        callList: $callList,
        callTimeList: $callTimeList,
        translateName: this.translateName,
        translateTime: this.translateTime,
        contactAppear: this.contactAppear,
        showConferenceDetail: $showConferenceDetail,
        contactNameLine: this.contactNameLine,
        isShowSim: $isShowSim,
        textAreaTop: this.callImageBottom,
        celiaAssistantShow: this.celiaAssistantShow
      }).margin({ top: this.getContactCardTop(), bottom: 0 });
    }
    .height(this.newFoldSplitPortraitScreenType > SplitScreenType.DEFAULT ? 'auto' : '100%')
    .justifyContent(this.columnJustifyContent(this.isNewFoldPhoneExternalScreen))
  }

  @Builder
  userHeadPhoto() {
    Column() {
      Image(this.contactAvatar)
        .onError((err) => {
          LogUtils.e(TAG, 'Err loading contactAvatar.');
        });
    }
    .clip(true) // If clip not true, the rounded corners of the component do not limit the Image component.
    .borderRadius(this.imageWidthorHeight / this.imageWidthorHeightHalf)
    .width(this.isNewFoldPhoneInnerFullScreen ? '84vp' : this.imageWidthorHeight)
    .height(this.isNewFoldPhoneInnerFullScreen ? '84vp' : this.imageWidthorHeight)
    .draggable(false)
    .visibility(this.isHideAvatarNoSpace() ? Visibility.None : Visibility.Visible)
    .margin({
      bottom: this.getAvatarMarginBottom()
    })
  }

  @Builder
  silentCall() {
    Row() {
      Row({ space: 4 }) {
        SymbolGlyph($r('sys.symbol.audiphonen'))
          .fontSize($r('app.float.call_card_body_m_line_height'))
          .height($r('app.float.call_card_body_m_line_height'))
          .width($r('app.float.call_card_body_m_line_height'))
          .fontColor(['#999999'])
          .fontWeight(FontWeight.Medium)
          .opacity(1)
          .draggable(false)
        Text($r('app.string.silent_call_symbol'))
          .fontSize($r('app.float.call_card_body_m_font'))
          .height($r('app.float.call_card_body_m_line_height'))
          .lineHeight($r('app.float.call_card_body_m_line_height'))
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
      }.justifyContent(FlexAlign.Center)
    }.margin({ left: 16, right: 16, top: 0 })
    .height('24')
    .width('328')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  twoWayPrivacyEnhancedCall() {
    Row() {
      Text($r('app.string.two_way_silent_call'))
        .fontSize($r('app.float.call_card_body_m_font'))
        .height($r('app.float.call_card_body_m_line_height'))
        .lineHeight($r('app.float.call_card_body_m_line_height'))
        .fontColor('#999999')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }
}
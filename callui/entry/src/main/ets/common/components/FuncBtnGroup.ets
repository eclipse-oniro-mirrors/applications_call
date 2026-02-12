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
import FuncBtn from './FuncBtn';
import CallStateConst from '../constant/CallStateConst';
import CallServiceProxy from '../../model/CallServiceProxy';
import Clone from '../utils/Clone';
import { callButtons } from '../../model/configs/BtnGroupConfig';
import LogUtils from '../utils/LogUtils';
import screenLock from '@ohos.screenLock';
import DefaultCallData, { AppBtnStyleData, AppFuncBtnStyleData, AppWindowStyleData } from '../struct/TypeUtils';
import { BusinessError } from '@ohos.base';
import { GlobalContextHelper } from '../utils/GlobalContextHelper';
import * as Constants from '../utils/Constants';
import common from '@ohos.app.ability.common';
import CallColumnUtils from '../utils/CallColumnUtils';
import { canMerge, getActiveCallId, getWasConnectedCallCount, isOutgoingCall } from '../utils/CallListHelper';
import { ImsCallMode, VideoStateType } from '../../common/utils/VideoCallApi';
import Recording from '../../common/utils/Recording';
import IdlServiceExtProxy from '../../idl/idl_service_ext_proxy';
import { RecordInputData } from '../struct/RecordingStruct';
import VideoCallManager from '../../model/VideoCallManager';
import RecordTimer from '../utils/RecordTimer';
import { ReportUtil } from '../utils/ReportUtils/ReportUtil';
import CallTypeConst from '../constant/CallTypeConst';
import CallUtils from '../utils/CallUtils';
import { RECORDER_DISABLED_STATUS, RECORDER_START_STATUS, RECORDER_STOP_STATUS } from '../constant/CallRecorderConst';
import lazy { AlertDialog } from '@ohos.arkui.advanced.Dialog';
import { isScreenLocked } from '../utils/DeviceTypeUtils';
import Utils from '../utils/utils';
import { ScreenInfo } from '../struct/CallUiDataStruct';
import { accessibility } from '@kit.AccessibilityKit';
import SplitScreenManager, { SplitScreenType } from '../../model/SplitScreenManager';
import { BehaviorDotting } from '../utils/ReportUtils/BehaviorDotting';
import { fileNameString } from '../utils/CallLabelUtils';
import { VisionGlassConstants } from '../constant/VisionGlassConstants';
import { isOperatorVtAvailable } from '../../model/SimManager';
import { DELAY_SEND_DURATION } from '../constant/AccessibilityDelayConst';
import { curves, display, window } from '@kit.ArkUI';

const TAG = 'FuncBtnGroup';
const prefixLog = 'callUI app:@ohos.telephony.call:';

interface BtnStruct {
  type: string
  iconDisableUrl: string
  iconDefaultUrl: string
  iconActiveUrl: string
  iconTouchUrl: string
  iconDisableFontColor?: string
  iconDefaultFontColor?: string
  iconActiveFontColor?: string
  iconTouchFontColor?: string
  isDisable: boolean
  isActive: boolean
  iconText: Resource
}

const textMap: Record<string, Resource> = {
  'record': $r('app.string.recording'),
  'keep': $r('app.string.keep'),
  'add': $r('app.string.addCall'),
  'addnew': $r('app.string.addCall'),
  'video': $r('app.string.videoCall'),
  'notepad':$r('app.string.notepad'),
  'mute': $r('app.string.mute'),
  'contact': $r('app.string.contactPerson'),
  'exchange': $r('app.string.exchange'),
  'merge': $r('app.string.mergeCall'),
  'summarize':$r('app.string.call_assistant_brief') //新添加，摘要
};

@Component
export default struct FuncBtnGroup {
  @Link @Watch('updateBtnList') callData: DefaultCallData;
  @State callState: number = 0;
  @Link @Watch('updateBtnList') callList: Array<DefaultCallData>;
  @Link @Watch('updateBtnList') callListCount: number;
  @Prop hasConference: boolean;
  @State btnList: Array<BtnStruct> = [];
  @StorageLink('isMute') @Watch('updateMuteState') isMute: boolean = false;
  @StorageProp('curBp') curBp: string = '';
  @StorageLink('recorderStatus') @Watch('updateRecordBtnText') recorderStatus: string = RECORDER_STOP_STATUS;
  private mCallServiceProxy?: CallServiceProxy;
  private mClone?: Clone;
  @StorageLink('onPageShow') @Watch('onPageShow') isOnPageShow: boolean = true;
  @StorageLink('screenOff') @Watch('onPageShow') screenOff: boolean = false;
  @State recordBtnText: string = '';
  @State isRecordAnimationActive: boolean = false;
  @Consume lightUpdate: boolean;
  @Consume isConferenceMode: boolean;
  touchStatusCallBack: (isTouchDown: boolean) => void = () => {
  };

  private recordTimerCallback = (text: string) => {
    this.recordBtnText = text;
  };
  @StorageLink('isShowSmartWindow') isShowSmartWindow: boolean = false;
  @StorageLink('isSmartWindowSplitScreen') isSmartWindowSplitScreen: boolean = false;
  @StorageLink('windowSizeChangeMd') windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  }
  @StorageLink('statusBarHeight') statusBarHeight: number = 0;
  @StorageLink('navigationHeight') airbarHeight: number = 0;
  @StorageLink('currentAudioDeviceIcon') @Watch('updateBtnList') currentAudioDeviceIcon: Resource =
    $r('sys.symbol.speaker_wave_3_fill');
  @StorageLink('LandscapeOrPortrait') landscapeOrPortrait: number = 1;
  @StorageLink('SplitScreenType') splitScreenType: SplitScreenType = SplitScreenType.DEFAULT;
  @StorageLink('isNewFoldPhoneExternalScreen') @Watch('onFoldStatusChange') isNewFoldPhoneExternalScreen: boolean = false;
  @StorageLink('isOsAccountUnlocked') @Watch('screenLokedCahnge') screenUnLoked: boolean = false;
  // 是否显示在VisionGlass
  @StorageProp(VisionGlassConstants.SHOW_IN_VISION_GLASS) @Watch('isShowVisionGlassChange') showInVisionGlass: boolean =
    false;
  @StorageLink('isNewFoldPhoneInnerFullScreen') isNewFoldPhoneInnerFullScreen: boolean = false;
  @StorageLink('newFoldSplitPortraitScreenType') newFoldSplitPortraitScreenType: SplitScreenType =
    SplitScreenType.DEFAULT;
  @StorageLink('isApplyNewStyle') isApplyNewStyle: boolean = false;
  @StorageLink('appWindow') appWindow: AppWindowStyleData = {
    maxWidth: undefined,
    maxHeight: undefined
  };
  @StorageLink('appBtnStyle') appBtnStyle: AppBtnStyleData = {
    btnWidth: 64,
    rowsGap: 20
  };
  @StorageLink('funcBtnStyle') funcBtnStyle: AppFuncBtnStyleData = new AppFuncBtnStyleData();
  @StorageLink('btnLeftGap') btnLeftGap: number = 0;
  @StorageProp('isHyacinthMode') isHyacinthMode: boolean = false;
  private isSupportSummary: boolean = false; //根据小艺参数，机型是否支持通话摘要
  @State rowWidth: number = 0;
  @State newCallWidth: number = 0;
  @State rowAlign: FlexAlign = FlexAlign.Center;
  @State showNewCallTip: boolean = false;
  @State showNewCallAgreement: boolean = false;
  @StorageLink('windowStatus') windowStatus: window.WindowStatusType = window.WindowStatusType.UNDEFINED;
  @StorageLink('foldDisplayMode') foldDisplayMode: display.FoldDisplayMode =
    display.FoldDisplayMode.FOLD_DISPLAY_MODE_UNKNOWN;
  @StorageLink('isDistributeSink') isDistributeSink: boolean = false;

  aboutToAppear() {
    LogUtils.i(TAG, `aboutToAppear`);
    this.callState = this.callData.callState;
    this.mClone = Clone.getInstance();
    this.mCallServiceProxy = CallServiceProxy.getInstance();
    callButtons.allButtonsList.forEach(v => v.iconText = textMap[v.type as string]);
    this.updateBtnList();
    this.updateMuteState(false);
    this.updateRecordBtnText();
  }

  aboutToDisappear(): void {
    this.errorCodeDialogController = undefined;
  }

  onPageShow() {
    LogUtils.i(TAG, `onPageShow ${this.isOnPageShow}`);
    if (!this.isOnPageShow || this.screenOff) {
      RecordTimer.getInstance().removeTimerCallback();
      this.isRecordAnimationActive = false;
      return;
    }
    this.isRecordAnimationActive = true;
    RecordTimer.getInstance().startTimer(this.recordTimerCallback);
  }

  screenLokedCahnge() {
    LogUtils.i(TAG, `screenUnLoked value is ${this.screenUnLoked}`);
    if (this.screenUnLoked) {
      this.updateBtnList();
    }
  }

  isShowVisionGlassChange() {
    this.updateBtnList();
  }
  /**
   * Update call buttons
   *
   * Button   | Visible                             | Disable                            | Active
   * -------- | ----------------------------------- | ---------------------------------- | ----------------------
   * Record   | Always visible                      | Foreground is not active           | Check 'recorderStatus'
   * Keep     | Only one was connected call         | Foreground is not hold/active      | Foreground is holding
   * Exchange | Opposite with 'Keep' logic          | Never disable                      | Never active
   * Add      | DSDA or only one was connected call | If any outgoing call               | Never active
   * Merge    | Opposite with 'Add' logic           | Never disable                      | Never active
   * Video    | Always visible                      | Outgoing/Multi/CS call             | Never active
   * Mute     | Always visible                      | Foreground is holding/outgoing     | Check 'isMute'
   * Contact  | Always visible                      | Never disable                      | Never active
   */
  updateBtnList() {
    if (this.mClone) {
      this.callState = this.callData.callState;
      if (this.isNewFoldPhoneExternalScreen) {
        this.btnList = this.mClone.clone([
          callButtons.record,
          callButtons.mute,
          this.getCallButtonAtSlotKeepExchange(),
        ]);
      } else if (this.isSupportSummary) {
        this.btnList = this.mClone.clone([
          callButtons.record,
          // summarize button object's position
          this.getCallButtonAtSlotSummarizeExchange(),
          this.getCallButtonAtSlotKeepMerge(),
          callButtons.video,
          callButtons.mute,
          callButtons.addnew
        ]);
      } else {
        this.btnList = this.mClone.clone([
          callButtons.record,
          this.getCallButtonAtSlotKeepExchange(),
          this.getCallButtonAtSlotAddMerge(),
          this.getCallButtonAtSlotVideo(),
          callButtons.mute,
          callButtons.contact,
        ]);
      }
      for (let btn of this.btnList) {
        this.updateButtonState(btn);
      }
    }
  }

  private updateButtonState(btn: BtnStruct): void {
    let isForegroundCallActive = this.callState === CallStateConst.CALL_STATUS_ACTIVE;
    let isForegroundCallHolding = this.callState === CallStateConst.CALL_STATUS_HOLDING;
    let isSinkDistributeCall = AppStorage.get<boolean>('isDistributeSink') ?? false;
    let isSourceDistributeCall = AppStorage.get<boolean>('isDistributeSource') ?? false;
    let hasOutgoingCall = isOutgoingCall(this.callState);
    let recorderStatus: string = AppStorage.get<string>('recorderStatus') ?? '';
    let isRecordingRecordingActive = recorderStatus === RECORDER_START_STATUS;
    let isCsCall = this.callData.callType === CallTypeConst.CALL_TYPE_CS;
    let isSatelliteCall = this.callData.callType === CallStateConst.TYPE_SATELLITE;
    let isInOobe = AppStorage.get<boolean>('isInOobe') as boolean;
    let isAudioOnPad = (JSON.stringify(this.currentAudioDeviceIcon) === JSON.stringify($r('sys.symbol.pad')));

    switch (btn.type) {
      case 'record':
        btn.isDisable = this.retRecordingStoped(isForegroundCallActive, recorderStatus, isSinkDistributeCall);
        btn.isActive = isRecordingRecordingActive;
        break;
      case 'keep':
        btn.isDisable = isSatelliteCall || (!isForegroundCallActive && !isForegroundCallHolding);
        btn.isActive = isForegroundCallHolding;
        break;
      case 'add':
        btn.isDisable = isSatelliteCall || hasOutgoingCall || this.callData.isEcc || isInOobe ||
          isSinkDistributeCall || (isSourceDistributeCall && isAudioOnPad) ||
        this.isChangeAddIconState();
        btn.isActive = false;
        break;
      case 'mute':
        btn.isDisable = this.callData.isEcc || isForegroundCallHolding;
        btn.isActive = this.isMute;
        break;
      case 'video':
        btn.isDisable = isSatelliteCall || isCsCall || isSinkDistributeCall ||
          (isSourceDistributeCall && isAudioOnPad) || hasOutgoingCall ||
          isForegroundCallHolding || this.callList.length !== 1 || !isOperatorVtAvailable(this.callData.accountId) ||
        this.showInVisionGlass;
        btn.isActive = false;
        break;
      case 'notepad':
        break;
      case 'contact':
        btn.isDisable = isInOobe;
        btn.isActive = false;
        break;
      case 'exchange':
      case 'merge':
        btn.isDisable = false;
        btn.isActive = false;
        break;
      default:
        break;
    }
  }

  private retRecordingStoped(isForegroundCallActive: boolean, recorderStatus: string,
    isSinkDistributeCall: boolean): boolean {
    LogUtils.i(TAG, `callState: ${this.callState}, recorderStatus: ${recorderStatus}`);
    if (!isForegroundCallActive) {
      return true;
    }
    if (recorderStatus === RECORDER_DISABLED_STATUS) {
      return true;
    }
    if (isSinkDistributeCall) {
      return true;
    }
    let isAccountLocked = !(AppStorage.get<boolean>('isOsAccountUnlocked') ?? false);
    LogUtils.i(TAG, `isAccounUnlocked value is ${isAccountLocked}`);
    if (isAccountLocked) {
      return true;
    }
    return false;
  }

  private isChangeAddIconState(): boolean {
    return this.isSupportSummary && this.callListCount > 1;
  }

  /**
   * 函数描述 是否改变通话摘摘要图标状态
   *    如果不支持摘要模式，无需改动
   *    如果通话数量大于1，置灰
   *    如果通话保持，置灰
   *    如果电话会议，置灰
   *    如果新通话中，置灰
   * 函数名称：isChangeSummaryIconState
   * 返回值类型：boolean
   */
  private isChangeSummaryIconState(): boolean {
    if (!this.isSupportSummary) {
      return false;
    }
    if (this.callListCount > 1) {
      return true;
    }
    if (this.callState === CallStateConst.CALL_STATUS_HOLDING) {
      return true;
    }
    if (this.isConferenceMode) {
      return true;
    }
    return false;
  }

  private updateMuteState(firstShow: boolean) {
    if (this.isNewFoldPhoneExternalScreen) {
      this.btnList[1].isActive = this.isMute;
    } else {
      this.btnList[4].isActive = this.isMute;
    }
    try {
      this.btnList = JSON.parse(JSON.stringify(this.btnList));
    } catch (err) {
      LogUtils.e(TAG, `updateMuteState exception, err: ${err?.message} ${this.btnList?.length}`);
    }
    if (firstShow) {
      this.delaySendAccessibilityEvent();
    }
  }

  onFoldStatusChange(): void {
    this.updateBtnList();
    this.updateMuteState(true);
  }

  private delaySendAccessibilityEvent() {
    setTimeout(() => {
      let eventInfo: accessibility.EventInfo = ({
        type: 'requestFocusForAccessibility',
        bundleName: 'com.ohos.callui',
        triggerAction: 'common',
        customId: 'mute'
      });
      try {
        accessibility.sendAccessibilityEvent(eventInfo).then(() => {
        });
      } catch (err) {
        LogUtils.e(TAG, `sendAccessibilityEvent exception, err: ${err?.message}`);
      }
    }, DELAY_SEND_DURATION);
  }

  private getCallButtonAtSlotKeepMerge(): Record<string, string | boolean | Resource> {
    if (this.callListCount > 1 && canMerge(this.callList)) {
      return callButtons.merge;
    } else {
      return callButtons.keep;
    }
  }

  private getCallButtonAtSlotSummarizeExchange(): Record<string, string | boolean | Resource> {
    if (this.callListCount <= 1 || getWasConnectedCallCount(this.callList) <= 1) {
      return callButtons.summarize;
    } else {
      return callButtons.exchange;
    }
  }

  private getCallButtonAtSlotKeepExchange(): Record<string, string | boolean | Resource> {
    if (this.callListCount <= 1 || getWasConnectedCallCount(this.callList) <= 1) {
      return callButtons.keep;
    } else {
      return callButtons.exchange;
    }
  }

  private getCallButtonAtSlotAddMerge(): Record<string, string | boolean | Resource> {
    if (this.callListCount > 1 && canMerge(this.callList)) {
      return callButtons.merge;
    } else {
      return callButtons.add;
    }
  }

  private getCallButtonAtSlotVideo(): Record<string, string | boolean | Resource> {
    if (this.isHyacinthMode) {
      return callButtons.notepad;
    } else {
      return callButtons.video;
    }
  }

  /**
   * Display the buttons of the button group
   *
   * @param {Object} obj - object
   */
  btnClick(obj: BtnStruct) {
    LogUtils.i(TAG, 'btnClick get icon type : ' + JSON.stringify(obj));
    this.touchStatusCallBack(false);
    switch (obj.type) {
      case 'record':
        this.recordHandle();
        break;
      case 'keep':
        this.keepHandle('keep');
        break;
      case 'exchange':
        this.exchangeMethod('exchange');
        break;
      case 'add':
        this.startContact('page_flag_dialer');
        ReportUtil.getInstance().reportCallInterfaceClickBtn('add');
        break;
      case 'video':
        LogUtils.i(TAG, 'video button clicked');
        if (this.callList.length === 1 && this.callListCount === 1) {
          VideoCallManager.getInstance().modifyImsCallMode(this.callData, ImsCallMode.CALL_MODE_SEND_RECEIVE,
            updatedCall => {
              updatedCall.videoState = VideoStateType.TYPE_VIDEO_BIDIRECTIONAL; // manually to show the VideCall UI
              updatedCall.imsCallMode = ImsCallMode.CALL_MODE_AUDIO_ONLY; // manually for video upgrading
              BehaviorDotting.getInstance().updatedCallTypeDotting(this.callData, 'active');
            });
        }
        break;
      case 'notepad':
        LogUtils.i(TAG, 'notepad button clicked');
        this.startNotepad();
        break;
      case 'mute':
        LogUtils.i(TAG, 'toggleMute: set to' + !this.isMute);
        this.isMute ? this.mCallServiceProxy?.cancelMuted() : this.mCallServiceProxy?.setMuted();
        ReportUtil.getInstance().reportCallInterfaceClickBtn('mute', this.isMute ? false : true);
        break;
      case 'contact':
        this.startContact('page_flag_choose_contacts');
        ReportUtil.getInstance().reportCallInterfaceClickBtn('contact');
        break;
      case 'merge':
        LogUtils.i(TAG, 'clickMergeAction');
        AppStorage.setOrCreate('clickMergeAction', true);
        this.handleMergeAction();
        Recording.getInstance().changeRecorderStatus();
        ReportUtil.getInstance().reportMultiCallClickMerge();
        break;
      default:
        break;
    }
  }

  startNotepad(){
    if (isScreenLocked()) {
      try {
        screenLock.unlock((err: BusinessError, isUnlock: boolean) => {
          if (isUnlock) {
            this.startNotepadAbility();
          } else {
            LogUtils.i(TAG, 'startNotepad screen isLocked');
          }
        });
      } catch (err) {
        LogUtils.e(TAG, `startNotepad screen isLocked error ${err?.code}`);
      }
    } else {
      this.startNotepadAbility();
    }
  }

  startNotepadAbility(){
    try {
      GlobalContextHelper.getContext().getValue<common.UIAbilityContext>(Constants.CALL_ABILITY_CONTEXT)?.
      startAbility({
        bundleName: 'com.ohos.notepad',
        abilityName: 'MainAbility',
      });
    } catch (err) {
      let code = (err as BusinessError).code;
      let message = (err as BusinessError).message;
      LogUtils.i(TAG, `startAbility failed, code is ${code}, message is ${message}`);
    }
  }

  errorCodeDialogController?: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.combine_conference_upper_limit'),
      primaryButton: {
        value: $r('app.string.gotIt'),
        fontColor: $r('sys.color.font_emphasize'),
        action: () => {
          LogUtils.i(TAG, prefixLog + 'AlertDialog combineConference action');
          this.errorCodeDialogController?.close();
        }
      }
    }),
    autoCancel: false
  })

  private exchangeMethod(type: string) {
    if (CallUtils.isFastClick(type)) {
      return;
    }
    Recording.getInstance().changeRecorderStatus();
    let changeFlag: boolean = false;
    this.callList.forEach((item: DefaultCallData) => {
      if (item.callState === CallStateConst.CALL_STATUS_HOLDING && !changeFlag) {
        changeFlag = true;
        if (Utils.getInstance().isConferenceCall(item)) {
          this.mCallServiceProxy?.unHoldConference(item.callId);
        } else {
          this.mCallServiceProxy?.unHoldCall(item.callId);
        }
        return;
      }
    });
    ReportUtil.getInstance().reportMultiCallClickExchange(this.callList.length);
  }

  private handleMergeAction() {
    let activeCallID: number = -1;
    for (let i = 0; i < this.callList.length; i++) {
      let item = this.callList[i];
      if (item.callState === CallStateConst.CALL_STATUS_ACTIVE) {
        activeCallID = item.callId;
        break;
      }
    }
    this.mCallServiceProxy?.combineConference(activeCallID, (err: BusinessError) => {
      if (err.code === 8300007) {
        this.errorCodeDialogController?.open();
      } else {
        Utils.getInstance().showToast(err.message);
      }
    });
  }

  startContact(pageFlag: string) {
    if (isScreenLocked()) {
      try {
        screenLock.unlock((err: BusinessError, isUnlock: boolean) => {
          if (isUnlock) {
            this.startContactAbility(pageFlag);
          } else {
            LogUtils.i(TAG, 'startContact screen isLocked');
          }
        });
      } catch (exception) {
        LogUtils.e(TAG, 'startContact screen isLocked err :' + JSON.stringify(exception));
      }
    } else {
      this.startContactAbility(pageFlag);
    }
  }

  startContactAbility(pageFlag: string) {
    GlobalContextHelper.getContext().getValue<common.UIAbilityContext>(Constants.CALL_ABILITY_CONTEXT)?.
    startAbility({
      bundleName: 'com.ohos.contacts',
      abilityName: 'com.ohos.contacts.MainAbility',
      parameters: {
        pageFlag: pageFlag
      }
    });
  }

  async updateRecordBtnText() {
    let btnListClone: BtnStruct[] = JSON.parse(JSON.stringify(this.btnList));
    let recordBtn: BtnStruct | undefined = btnListClone[0];
    let isRecordingRecordingActive = AppStorage.get<string>('recorderStatus');
    LogUtils.i(TAG, 'isRecordingRecordingActive:' + isRecordingRecordingActive);
    if (isRecordingRecordingActive === RECORDER_DISABLED_STATUS ||
      this.callState !== CallStateConst.CALL_STATUS_ACTIVE) {
      btnListClone[0].isDisable = true;
      btnListClone[0].isActive = false;
    } else {
      btnListClone[0].isDisable = false;
      btnListClone[0].isActive = isRecordingRecordingActive === RECORDER_START_STATUS;
    }
    this.btnList = btnListClone;
    if (recordBtn === undefined) {
      LogUtils.i(TAG, 'updateRecordBtnText: recordBtn not in list');
      return;
    }
    if (!recordBtn.isActive) {
      RecordTimer.getInstance().stopTimer();
      LogUtils.i(TAG, 'updateRecordBtnText: recordBtn not active');
      return;
    }
    if (isRecordingRecordingActive === RECORDER_DISABLED_STATUS) {
      LogUtils.i(TAG, 'updateRecordBtnText: recordBtn is disabled');
      return;
    }
    this.isRecordAnimationActive = recordBtn.isActive;
    RecordTimer.getInstance().startTimer(this.recordTimerCallback);
  }

  recordHandle() {
    let currentStatus = this.btnList[0].isActive;
    if (!currentStatus) {
      let fileNameStr: string = fileNameString(this.callData);
      let sendParams: RecordInputData = {
        callId: getActiveCallId(this.callList),
        accountNumber: this.callData.accountNumber,
        startTime: this.callData.startTime,
        mode: IdlServiceExtProxy.RECORDING_MANUAL,
        fileNameStr: fileNameStr
      }
      if (this.hasConference) {
        sendParams.mode = IdlServiceExtProxy.RECORDING_MEETING;
        sendParams.callList = this.callList;
      }
      Recording.getInstance().recordingStart(sendParams);
      ReportUtil.getInstance().reportCallInterfaceClickBtn('record', true);
    } else {
      LogUtils.i(TAG, 'recordHandle stopRecording');
      Recording.getInstance().recordingStop(RECORDER_STOP_STATUS);
      ReportUtil.getInstance().reportCallInterfaceClickBtn('record', false);
    }
    if (!this.isConferenceMode) {
      this.setBtnDisable(1, !currentStatus);
    }
  }

  private setBtnDisable(index: number, isDisable: boolean) {
    if (!this.isSupportSummary) {
      return;
    }
    if (index < 0 || index >= this.btnList.length) {
      return;
    }
    this.btnList[index].isDisable = isDisable;
  }

  /**
   * Call hold interface
   *
   * @param {string} type - Click the hold button
   */
  keepHandle(type: string) {
    if (CallUtils.isFastClick(type)) {
      return;
    }
    const awaitIsActive = this.btnList.find((v: BtnStruct) => v.type === type)?.isActive;
    LogUtils.i(TAG, 'keep handle awaitIsActive : ' + !awaitIsActive);
    if (this.callData.conferenceState) {
      this.mCallServiceProxy?.getMainCallId(this.callData.callId, (mainId: number) => {
        !awaitIsActive ? this.mCallServiceProxy?.holdCall(mainId) :
        this.mCallServiceProxy?.unHoldCall(mainId);
      });
    } else {
      !awaitIsActive ? this.mCallServiceProxy?.holdCall(this.callData.callId) :
      this.mCallServiceProxy?.unHoldCall(this.callData.callId);
    }
    ReportUtil.getInstance().reportCallInterfaceClickBtn('wait', !awaitIsActive);
  }

  rowsGap(): number {
    if (this.isApplyNewStyle && this.appBtnStyle.rowsGap) {
      let rowsGap: number = this.appBtnStyle.rowsGap;
      return rowsGap;
    }
    let rowsGapNum = CallColumnUtils.getInstance().rowsGap(this.windowSizeChangeMd, this.isShowSmartWindow,
      this.statusBarHeight, this.airbarHeight, this.curBp,
      this.isSmartWindowSplitScreen);
    return rowsGapNum;
  }

  getColumnsGap() {
    if (this.isApplyNewStyle) {
      return this.btnLeftGap;
    }
    if (this.isNewFoldPhoneInnerFullScreen || this.newFoldSplitPortraitScreenType > SplitScreenType.DEFAULT) {
      return $r('app.float.new_form_foldphone_func_btn_columns_gap');
    }
    return CallColumnUtils.getInstance()
      .getItemSpace(this.curBp, this.isNewFoldPhoneExternalScreen);
  }

  getGridRowMarginLeft() {
    if (this.isApplyNewStyle) {
      return 0;
    }
    if (this.isNewFoldPhoneExternalScreen) {
      return $r('sys.float.padding_level11');
    }
    if (this.isNewFoldPhoneInnerFullScreen || this.newFoldSplitPortraitScreenType > SplitScreenType.DEFAULT) {
      return $r('app.float.new_form_foldphone_func_btn_margin_space');
    }
    return CallColumnUtils.getInstance()
      .getKeyBordMarginSpace(this.curBp);
  }

  checkNewCallValid() {
    const foldModeValid = this.foldDisplayMode !== display.FoldDisplayMode.FOLD_DISPLAY_MODE_SUB;
    const windowStatusValid = this.windowStatus !== window.WindowStatusType.FLOATING &&
      this.windowStatus !== window.WindowStatusType.SPLIT_SCREEN;
    return foldModeValid && windowStatusValid && !this.isDistributeSink;
  }

  build() {
    Column() {
      this.gridLayout();
    }
  }

  @Builder
  gridLayout() {
    GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: 24 }) {
      GridCol({
        span: {
          xs: 2,
          sm: 4,
          md: this.isApplyNewStyle ? 8 : 6,
          lg: this.isApplyNewStyle ? 12 : 8
        },
        offset: { md: this.isApplyNewStyle ? 0 : 1,
          lg: this.isApplyNewStyle ? 0 : 2
        }
      }) {
        Grid() {
          ForEach(this.btnList, (item: BtnStruct) => {
            GridItem() {
              FuncBtn({
                btnType: item.type,
                isDisable: item.isDisable,
                isActive: !item.isDisable && item.isActive,
                iconText: item.iconText,
                iconDisableUrl: item.iconDisableUrl,
                iconDefaultUrl: item.iconDefaultUrl,
                iconActiveUrl: item.iconActiveUrl,
                iconTouchUrl: item.iconTouchUrl,
                iconDisableFontColor: item.iconDisableFontColor,
                iconDefaultFontColor: item.iconDefaultFontColor,
                iconActiveFontColor: item.iconActiveFontColor,
                iconTouchFontColor: item.iconTouchFontColor,
                recordBtnText: this.recordBtnText,
                isRecordAnimationActive: this.isRecordAnimationActive,
                isIncoming: false,
                btnClick: () => {
                  this.btnClick(item);
                },
                touchStatusCallBack: (isTouchDown) => {
                  this.touchStatusCallBack(isTouchDown);
                }
              })
            }
            .align(this.isNewFoldPhoneExternalScreen ? Alignment.Bottom : Alignment.Center)
          })
        }
        .clip(false)
        .opacity(1)
        .columnsGap(this.getColumnsGap())
        .rowsGap(this.isNewFoldPhoneInnerFullScreen || this.newFoldSplitPortraitScreenType > SplitScreenType.DEFAULT ?
        $r('app.float.new_form_foldphone_func_btn_rows_gap') : this.rowsGap())
        .width(this.isApplyNewStyle ? (this.appBtnStyle.btnWidth * 3 + this.btnLeftGap * 2) : 'auto')
        .height(this.isApplyNewStyle ? this.funcBtnStyle.funcBtnGroupHeight :
          (this.isNewFoldPhoneInnerFullScreen || this.newFoldSplitPortraitScreenType > SplitScreenType.DEFAULT ? 191 :
            (174 + this.rowsGap())))
        .columnsTemplate('1fr 1fr 1fr')
        .rowsTemplate('1fr 1fr')
      }.onAreaChange((_, area) => {
        const rm = getContext(this).resourceManager;
        const gridWidth = area.width as number;
        let columnsGap = this.getColumnsGap();
        if (typeof columnsGap !== 'number') {
          columnsGap = rm.getNumber(columnsGap);
        }
        const columnWidth = (gridWidth - columnsGap * 2) / 3;
        const btnWidth = rm.getNumber($r('app.float.call_button_width'));
        this.rowWidth = gridWidth - columnWidth + btnWidth;
        this.newCallWidth = columnWidth + btnWidth + columnsGap;
      })
    }
    .margin({
      left: this.getGridRowMarginLeft(),
      right: this.getGridRowMarginLeft()
    })
    .id('callui_FuncBtnGroup_GridRow')
  }
}

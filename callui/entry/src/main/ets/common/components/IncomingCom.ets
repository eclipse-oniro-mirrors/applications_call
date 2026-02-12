/**
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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
import LogUtils from '../utils/LogUtils';
import DefaultCallData, { AppFuncBtnStyleData, MarkType } from '../struct/TypeUtils';
import { StringUtil } from '../utils/StringUtil';
import IncomingComVM from '../../viewmodel/IncomingComVM';
import { btn } from '../../model/configs/IncomingModel';
import CallColumnUtils from '../utils/CallColumnUtils';
import AnswerBtn from '../animation/AnswerBtn';
import LockIncomingCom from '../animation/LockIncomingCom';
import { isVideoCall } from '../utils/CallListHelper';
import CallServiceProxy from '../../model/CallServiceProxy';
import { ReportUtil, UE_CALLBACK_REMIND_CANCEL } from '../utils/ReportUtils/ReportUtil';
import CallStateConst from '../constant/CallStateConst';
import call from '@ohos.telephony.call';
import { CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import { isScreenLocked, isTwoInOne } from '../utils/DeviceTypeUtils';
import Utils from '../utils/utils';
import CustomButtons from './CustomButtons';
import { RejectMsgContent } from './RejectMsgContent';
import { RemindContent } from './RemindContent';
import SplitScreenManager, { SplitScreenType } from '../../model/SplitScreenManager';
import { bundleManager, common } from '@kit.AbilityKit';
import { BusinessError, settings } from '@kit.BasicServicesKit';
import { TimeOutManager } from '../../model/TimeOutManager';
import { ProximityUtils } from '../utils/ProximityUtils';
import { hiSysEvent } from '@kit.PerformanceAnalysisKit';

const TAG = 'IncomingCom';
const FLOWING_LIGHT = 'INTELLIGENT_FLOWING_LIGHT';
const CLICK_CELIA_ANSWER = 'INTELLIGENT_CLICK_ANSWER'

@Component
export default struct IncomingCom {
  @State confirmButtonEnabled: boolean = false;
  @State customTextInputFocus: boolean = false;
  isFromPhoneNumberMarkAs: boolean = false;
  cancelButtonText: ResourceStr = $r('app.string.cancel');
  confirmButtonText: ResourceStr = $r('app.string.sent');
  onCancel: () => void = () => {
  };
  onConfirm: (value: string) => void = (value: string) => {
  };
  @Link @Watch('initData') callList: Array<DefaultCallData>;
  @Link @Watch('initData') callData: DefaultCallData;
  @State isLock?: boolean = false;
  @State animationCount: number = 0;
  @State isCalendarInstalled: boolean = true;
  @State mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  @State isMaintenanceMode: boolean = false;
  @State dsdaConflictsLabel: Resource = $r('app.string.emptyStr');
  @State isVideoCall: boolean = false;
  @State isSatelliteCall: boolean = false;
  private isClickRemind: boolean = false;
  @StorageProp('powerClickFlag') @Watch('powerClickFlagChange') powerClickFlag: boolean = false;
  @StorageProp('curBp') curBp: string = '';
  @State inputValue: string = '';
  @State focusAble: boolean = false;
  confirm: (data: string) => void = (data: string) => {
  };
  @State funcBtnRowWidth: number = 0;
  @State incomingBtnWidth: number = 0;
  @StorageLink('LandscapeOrPortrait') @Watch('landscapeOrPortraitchange') landscapeOrPortrait: number = 1;
  @StorageLink('FoldStatus') @Watch('foldStatusChange') foldStatus: number = 0;
  @StorageLink('screenReaderStatus') screenReaderStatus: boolean = false;
  @StorageLink('isShowSmartWindow') isShowSmartWindow: boolean = false;
  @State btnList?: btn[] = undefined;
  @StorageLink('SplitScreenType') @Watch('changeSpliteScreenType') splitScreenType: SplitScreenType = SplitScreenType.DEFAULT;
  @StorageLink('SplitScreenHeight') splitScreenHeight: number = 0;
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  @StorageLink('isOsAccountUnlocked') isOsAccountUnlocked: boolean = true;
  @StorageLink('distributeSmsEnable') distributeSmsEnable: boolean = false;
  @StorageLink('isDistributeSink') isDistributeSink: boolean = false;
  @State timeOutManager: TimeOutManager = TimeOutManager.getInstance();
  @StorageLink('newFoldSplitPortraitScreenType') newFoldSplitPortraitScreenType: SplitScreenType =
    SplitScreenType.DEFAULT;
  @StorageLink('navigationHeight') navigationHeight: number = 0;
  @StorageLink('isApplyNewStyle') isApplyNewStyle: boolean = false;
  @StorageLink('btnBottomGap') btnBottomGap: number = 0;
  @StorageLink('funcBtnStyle') funcBtnStyle: AppFuncBtnStyleData = new AppFuncBtnStyleData();

  @Builder
  CustomRejectMessage() {
    Scroll() {
      Column() {
        Row() {
          this.IncomingTextInput()
        }
        .width('100%')
        .constraintSize({ minHeight: 48 })
        .padding({
          top: $r('sys.float.padding_level2'),
          bottom: $r('sys.float.padding_level2')
        })

        CustomButtons({
          confirmButtonEnabled: this.confirmButtonEnabled,
          cancelButtonText: this.cancelButtonText,
          confirmButtonText: this.confirmButtonText,
          onCancel: () => {
            this.customRejectMessageDialog?.close();
            this.focusAble = false;
            ReportUtil.getInstance().reportIncomingSendCustomMessageReject(this.isVideoCall ? 1 : 0, 0);
          },
          onConfirm: () => {
            this.mIncomingVM.sendMessageAndRejectCall(this.inputValue);
            this.customRejectMessageDialog?.close();
            this.focusAble = false;
            ReportUtil.getInstance().reportIncomingSendCustomMessageReject(this.isVideoCall ? 1 : 0, 1);
          }
        })
          .margin({ bottom: $r('sys.float.padding_level8')})
      }
    }
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
  }

  @Builder
  IncomingTextInput() {
    TextInput({ text: this.inputValue })
      .width('100%')
      .constraintSize({ minHeight: 48 })
      .align(Alignment.Center)
      .fontColor($r('sys.color.font_primary'))
      .fontSize($r('sys.float.Body_L'))
      .backgroundColor(Color.Transparent)
      .caretColor($r('sys.color.font_emphasize'))
      .borderRadius($r('sys.float.corner_radius_none'))
      .fontWeight(FontWeight.Regular)
      .draggable(false)
      .focusable(true)
      .defaultFocus(true)
      .showUnderline(true)
      .padding({
        left: $r('sys.float.padding_level12'),
        right: $r('sys.float.padding_level12')
      })
      .onChange((value) => {
        this.inputValue = value;
        if (!StringUtil.isEmpty(this.inputValue)) {
          this.confirmButtonEnabled = true;
        } else {
          this.confirmButtonEnabled = false;
        }
      })
  }

  @Builder
  rejectMsgList() {
    RejectMsgContent({
      dialogController: this.msgDialogController,
      mIncomingVM: this.mIncomingVM,
      clickCustomMsg:() => {
        this.showCustomRejectMessageDialog();
      }
    })
  }

  @Builder
  remindList() {
    RemindContent({
      dialogController: this.msgDialogController,
      mIncomingVM: this.mIncomingVM
    })
  }

  checkCalendarInstalled(): void {
    try {
      bundleManager.getBundleInfo('com.ohos.calendar', bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
        .then((data) => {
          LogUtils.i(TAG, 'checkCalendarInstalled getBundleInfo successfully.');
          this.isCalendarInstalled = data.appInfo?.systemApp;
        }).catch((err: BusinessError) => {
          this.isCalendarInstalled = false;
          LogUtils.e(TAG, `getBundleInfo failed:${JSON.stringify(err)}`);
      });
    } catch (err) {
      this.isCalendarInstalled = false;
      LogUtils.e(TAG, `getBundleInfo failed:${JSON.stringify(err)}`);
    }
  }

  msgDialogController?: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.hangUpReply'),
      contentBuilder: () => {
        this.rejectMsgList();
      },
      contentAreaPadding: { left: $r('sys.float.padding_level0'), right: $r('sys.float.padding_level0') },
      buttons: [
        {
          value: $r('app.string.cancel'),
          fontColor: $r('sys.color.font_emphasize'),
          action: () => {
            this.msgDialogController?.close();
          }
        }
      ]
    }),
    autoCancel: true,
    customStyle: false,
    maskColor: $r('sys.color.mask_fourth'),
  });

  customRejectMessageDialog?: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.customSMS'),
      contentBuilder: () => {
        this.CustomRejectMessage();
      },
      contentAreaPadding: { left: $r('sys.float.padding_level0'), right: $r('sys.float.padding_level0') },
    }),
  autoCancel: true,
})

  remindDialogController?: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.callBackReminder'),
      contentBuilder: () => {
        this.remindList();
      },
      contentAreaPadding: { left: $r('sys.float.padding_level0'), right: $r('sys.float.padding_level0') },
      buttons: [
        {
          value: $r('app.string.cancel'),
          fontColor: $r('sys.color.font_emphasize'),
          action: () => {
            this.remindDialogController?.close();
            ReportUtil.getInstance().reportCallBackRemindAction(UE_CALLBACK_REMIND_CANCEL);
          }
        }
      ]
    }),
    autoCancel: true,
    customStyle: false,
    maskColor: $r('sys.color.mask_fourth'),
  });

  aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear');
    this.mIncomingVM.aboutToAppear();
    this.initData();
    this.isLock = isScreenLocked();
    LogUtils.i(TAG, `isLock: ${this.isLock}`);
    this.getIsMaintenanceMode();
    ProximityUtils.wakeUpScreenByProximity();
    ProximityUtils.keepScreenOn(true);
    this.updateBtnsRowWidth();
    this.checkCalendarInstalled();
  }


  initData() {
    this.mIncomingVM.initData(this.callData, this.callList);
    this.dsdaConflictsLabel = this.mIncomingVM.getDsdaConflictsLabel();
    this.isVideoCall = isVideoCall(this.callData.videoState);
    this.isSatelliteCall = this.callData?.callType === CallStateConst.TYPE_SATELLITE;
    if (this.isSatelliteCall) {
      ReportUtil.getInstance().reportIncomingCallInSatelliteConnected();
    }
    this.btnList = this.mIncomingVM.btnList;
  }

  powerClickFlagChange() {
    this.customRejectMessageDialog?.close();
    this.remindDialogController?.close();
    this.msgDialogController?.close();
  }

  private landscapeOrPortraitchange() {
    this.updateBtnsRowWidth();
  }

  private foldStatusChange() {
    this.updateBtnsRowWidth();
  }

  private changeSpliteScreenType() {
    if (SplitScreenManager.getInstance().incomingCallFuncBtn(this.callList, this.splitScreenType,
      this.isOsAccountUnlocked) === Visibility.None) {
      this.msgDialogController?.close();
      this.remindDialogController?.close();
    }
  }

  aboutToDisappear() {
    ProximityUtils.keepScreenOn(isVideoCall(this.callData.videoState) || this.isSatelliteCall);
    this.powerClickFlagChange();
    this.msgDialogController = undefined;
    this.remindDialogController = undefined;
    this.customRejectMessageDialog = undefined;
  }

  showCustomRejectMessageDialog() {
    setTimeout(() => {
      this.focusAble = true;
    }, 500)
    this.customRejectMessageDialog?.open();
  }

  /**
   * Enable the SMS reply pop-up
   */
  private btnClick(type: string) {
    LogUtils.i(TAG, 'btnClick :' + JSON.stringify(type));
    if (type === 'msg') {
      if (this.isMaintenanceMode) {
        LogUtils.i(TAG, 'is maintenance mode, return');
        return;
      }
      if (this.isDistributeSink && !this.distributeSmsEnable) {
        LogUtils.i(TAG, 'is distributed sink and sms enable, return');
        return;
      }
      if (this.isSatelliteCall) {
        LogUtils.i(TAG, 'is satellite call, return');
        return;
      }
      this.msgDialogController?.open();
      CallServiceProxy.getInstance()?.muteRinger();
    } else if (type === 'remind') {
      if (!this.isCalendarInstalled) {
        LogUtils.i(TAG, 'calendar is not installed, return');
        return;
      }
      if (!this.isClickRemind) {
        this.mIncomingVM.getRemindList();
        this.isClickRemind = false;
      }
      this.remindDialogController?.open();
      CallServiceProxy.getInstance()?.muteRinger();
      ReportUtil.getInstance().reportIncomingRemindButton(this.callData.videoState === call.VideoStateType.TYPE_VIDEO
        ? 0 : 1, this.callData.callType === CallStateConst.TYPE_VOIP ? 1 : 0);
    } else if (type === 'voiceCall') {
      this.mIncomingVM.onAnswer(false);
    }
  }

  private getFlexAlign(type: string) {
    if (this.curBp === 'sm' || this.curBp === 'xs' || this.curBp === 'lg') {
      return FlexAlign.Center;
    }
    if (type === 'msg') {
      return FlexAlign.Center;
    } else if (type === 'remind') {
      return FlexAlign.Center;
    }
    return FlexAlign.Center;
  }

  private async getIsMaintenanceMode() {
    this.isMaintenanceMode = await Utils.getInstance().isMaintenanceMode();
  }

  private updateBtnsRowWidth() {
    if (this.btnList?.length !== 3 || this.curBp === 'sm' || this.curBp === 'xs') {
      return;
    }
    let gridWidth = CallColumnUtils.getInstance().getGridWidth(this.curBp);
    let rowSpaceSize: number = CallColumnUtils.getInstance().getRowSpace(this.curBp);
    let btnWidth = (((gridWidth + rowSpaceSize) * (this.curBp === 'md' ? 3 : 4)) - 16) / 2;
    this.funcBtnRowWidth = btnWidth * 3 + 16;
    this.incomingBtnWidth = (gridWidth + rowSpaceSize) * (this.curBp === 'md' ? 6 : 8) - rowSpaceSize;
  }

  getFuncBtnRowWidth(): number {
    this.updateBtnsRowWidth();
    return this.funcBtnRowWidth;
  }

  getLockIncomingComTop(): number {
    if (this.isApplyNewStyle && this.funcBtnStyle.btnWidth > 64) {
      return this.getAnswerBtnTop();
    }
    if (SplitScreenManager.getInstance().isIncomingSpliteScreenMedium(this.splitScreenHeight)) {
      return 12;
    }
    return 24;
  }

  getAnswerBtnTop(): number {
    if (SplitScreenManager.getInstance().isIncomingSpliteScreenMedium(this.splitScreenHeight)) {
      return 16;
    }
    return 32;
  }

  getIncomingTextTop(): Resource {
    if (this.newFoldSplitPortraitScreenType > SplitScreenType.DEFAULT) {
      return $r('sys.float.padding_level0');
    }
    if (SplitScreenManager.getInstance().isIncomingPhoneSpliteScreen(this.splitScreenHeight)) {
      return $r('sys.float.padding_level2');
    }
    return $r('sys.float.padding_level8');
  }

  getDsdaConflictsTextBottom(): string {
    if (this.newFoldSplitPortraitScreenType > SplitScreenType.DEFAULT) {
      return this.navigationHeight === 0 ? '28vp' : '0vp';
    }
    if (this.isApplyNewStyle) {
      // 19: text_dsdaConflictsLabel height, 16: getIncomingTextTop
      return `${this.btnBottomGap - 19 - 16}vp`;
    }
    if (this.isNewFoldPhoneExternalScreen) {
      return '9vp';
    }
    if (isTwoInOne()) {
      return '29vp'
    }
    return '0vp';
  }

  private isThreeBtnOrCurbpType(): boolean {
    return this.btnList?.length === 3 && this.curBp !== 'sm' && this.curBp !== 'xs';
  }

  private isDsdaConflictsLabelEmpty(): boolean {
    if (this.timeOutManager.isAnsweredTimeOut) {
      return true;
    }
    if (this.dsdaConflictsLabel.id === $r('app.string.emptyStr').id) {
      return true;
    }
    return false;
  }

  build() {
    GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: 24 }) {
      GridCol({ span: { xs: 2, sm: 4, md: this.btnList?.length === 3 ? 8 : 6,
        lg: this.btnList?.length === 3 ? 12 : 8 },
        offset: { md: this.btnList?.length === 3 ? 0 : 1,
          lg: this.btnList?.length === 3 ? 0 : 2 } }) {
        this.builderIncoming()
      }
    }
    .margin({
      left: this.isApplyNewStyle ? 0 : CallColumnUtils.getInstance().getPaddingSpace(this.curBp),
      right: this.isApplyNewStyle ? 0 : CallColumnUtils.getInstance().getPaddingSpace(this.curBp)
    })
  }

  @Builder
  builderIncoming() {
    Column() {
      this.buildFuncBtns();
      Column() {
        if (this.isLock && !this.screenReaderStatus) {
          LockIncomingCom({ mIncomingVM: $mIncomingVM, isVideoCall: $isVideoCall })
            .margin({
              top: this.isNewFoldPhoneExternalScreen ? 12 : this.getLockIncomingComTop(),
              bottom: this.isApplyNewStyle && this.funcBtnStyle.btnWidth > 64 ? 0 :
                this.isNewFoldPhoneExternalScreen ? -4 : -8,
              left: this.isNewFoldPhoneExternalScreen ? 16 : 0,
              right: this.isNewFoldPhoneExternalScreen ? 16 : 0,
            })
            .width(this.isThreeBtnOrCurbpType() ? this.incomingBtnWidth : null);
        } else {
          AnswerBtn({ mIncomingVM: $mIncomingVM, isVideoCall: $isVideoCall, isSatelliteCall: $isSatelliteCall })
            .margin({ top: this.isNewFoldPhoneExternalScreen ? 16 : this.getAnswerBtnTop() })
            .width(this.isThreeBtnOrCurbpType() ? this.incomingBtnWidth : null);
        }

        Text(this.timeOutManager.isAnsweredTimeOut ? '' : this.dsdaConflictsLabel)
          .fontSize(this.newFoldSplitPortraitScreenType > SplitScreenType.DEFAULT ? '12vp' : $r('app.float.call_incoming_body_m_font'))
          .fontColor($r('sys.color.font_on_primary'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .height(this.newFoldSplitPortraitScreenType > SplitScreenType.DEFAULT ? '16vp' : $r('app.float.call_incoming_body_m_height'))
          .lineHeight(this.newFoldSplitPortraitScreenType > SplitScreenType.DEFAULT ? '16vp' : $r('app.float.call_incoming_body_m_height'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({
            top: this.isNewFoldPhoneExternalScreen ? '4vp' : this.getIncomingTextTop(),
            bottom: this.getDsdaConflictsTextBottom(),
          })
          .accessibilityLevel(this.isDsdaConflictsLabelEmpty() ? 'no' : 'yes')
          .id('callUI_components_IncomingCom_text_dsdaConflictsLabel');
      }
      .visibility(Visibility.Visible)
    }
  }

  @Builder
  buildFuncBtns() {
    Row({ space: this.isThreeBtnOrCurbpType() ? 8 :
    CallColumnUtils.getInstance().getRowSpace(this.curBp) }) {
      ForEach(this.btnList, (item: btn) => {
        Row() {
          this.btnBuilder(item);
        }
        .justifyContent(this.getFlexAlign(item.type))
        .layoutWeight(1)
      })
    }
    .height(this.isApplyNewStyle ? 'auto' : (this.isNewFoldPhoneExternalScreen ? 45 : 51))
    .width(this.isThreeBtnOrCurbpType() ? this.getFuncBtnRowWidth() : null)
    .visibility(SplitScreenManager.getInstance().incomingCallFuncBtn(this.callList, this.splitScreenType,
      this.isOsAccountUnlocked))
  }

  @Builder
  btnBuilder(item: btn) {
    FuncBtn({
      btnType: item.type,
      iconDisableUrl: item.iconDefaultUrl,
      iconDefaultUrl: item.iconDefaultUrl,
      iconTouchUrl: item.iconTouchUrl,
      iconText: item.iconText,
      isDisable: item.isDisable,
      isIncoming: true,
      isNotContacted: false,
      isSatelliteCall: this.isSatelliteCall,
      btnClick: (type: string) => {
        this.btnClick(type);
      }
    })
      .opacity(((this.isMaintenanceMode || this.isSatelliteCall ||
        (this.isDistributeSink && !this.distributeSmsEnable)) &&
        item.type === 'msg') ||
        (!this.isCalendarInstalled && item.type === 'remind') ? $r('sys.float.alpha_disable') : 1)
  }
}
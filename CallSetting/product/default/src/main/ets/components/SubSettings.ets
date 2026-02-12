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
import * as CallSettingsConstant from '../common/constant/CallSettingsConstant';
import { BusinessError } from '@ohos.base';
import { StringUtil } from '../common/utils/StringUtil';
import CallColumnUtils from '../common/utils/CallColumnUtils';
import CallSettingVM from '../viewModel/CallSettingVM';
import { LogUtils, ReportUtil, CallSettingGlobalContextHelper, Constants } from '@ohos/common/CommonIndex';
import prompt from '@ohos.promptAction';
import queryAddData from '../common/utils/queryAddData';
import SubData from '../common/struct/SubSettingsData';
import SubSettingVM from '../viewModel/SubSettingVM';
import { SelectDialog, CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import { setCallBarringPwd } from '../model/CallServiceProxy';
import { getSimCardPhoneNumber } from '../common/model/getSimTelephoneNumberApi';
import {
  addRegisterDistributedStateListener,
  queryDistributedState,
  removeRegisterDistributedStateListener
} from '../common/utils/DistributeUtils';
import { emitter, settings } from '@kit.BasicServicesKit';
import { getRingToneAttrsArray, getRingToneName } from '../common/utils/CommonFunUtil';
import { systemSoundManager } from '@kit.AudioKit';
import { isTwoInOne } from '../common/utils/Utils';
import { display, LengthMetrics, window } from '@kit.ArkUI';
import { SystemMode } from '../model/SystemMode';

const OPACITY_ENABLE = 1;
const OPACITY_DISABLE_ITEM_CHILD = 0.4;
const TAG = 'SubSettings';
const SETTING_BUNDLE_NAME: string = 'com.ohos.settings'; // BundleName of setting app.
const SETTING_ABILITY_NAME: string = 'com.ohos.settings.MainAbility'; // ability name of setting app.
const SETTING_URI_NAME: string = 'ring_tone_settings'; // uri of setting app ringtone.

const commons: queryAddData = new queryAddData();

export interface RouterOptions {
  url: string,
  params: Record<string, number | boolean | String>
}

interface ContentItem {
  name: Resource,
  id: number
}

@Component
export struct SubSettings {
  @Consume('pathInfos') pathInfos: NavPathStack;
  @Link subData: SubData;
  @Link slotId: number;
  @Link isEnable: boolean;
  @Link airPlaneOn: boolean;
  subSettingVM: SubSettingVM = SubSettingVM.getInstance();
  @State callTextArray: SheetInfo[] = [
    {
      title: $r('app.string.by_time'),
      action: () => {
        this.callText = $r('app.string.by_time');
        this.radioId = 0;
        commons.addCallMergeListener('time');
        ReportUtil.getInstance().reportHistoryMergeAction(this.radioId)
      }
    },
    {
      title: $r('app.string.by_contact'),
      action: () => {
        this.callText = $r('app.string.by_contact');
        this.radioId = 1;
        commons.addCallMergeListener('contacts');
        ReportUtil.getInstance().reportHistoryMergeAction(this.radioId)
      }
    }
  ];
  @Link callText: ResourceStr;
  @Link radioId: number;
  @StorageProp('curBp') curBp: string = '';
  @StorageProp('ratio') ratio: number = 0;
  private mCallColumnUtils: CallColumnUtils = CallColumnUtils.getInstance();
  @LocalStorageLink('CallNotifiesText') getCallNotifiesText: Resource = $r('app.string.banner');
  @LocalStorageLink('numberIdentityStatus') numberIdentityStatus: boolean = false;
  @LocalStorageLink('CeliaCallSummaryStatusText') getCeliaCallSummaryStatusText: Resource = $r('app.string.closed');
  @State changeContentItems: Array<ContentItem> = [
    { name: $r('app.string.emptyStr'), id: 0, },
    { name: $r('app.string.emptyStr'), id: 1, },
    { name: $r('app.string.emptyStr'), id: 2, }];
  @State oldInputText: string = '';
  @State newInputText: string = '';
  @State confirmInputText: string = '';
  @State activeId: number = -1;
  @State inputFocus: boolean = false;
  controller?: CustomDialogController
  selectedRadio: number = -1;
  @State simRingtoneOne: string = CallSettingVM.getInstance().simRingtoneOne;
  @State context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('fontSizeScaleMargin') fontSizeScaleMargin: string = '0vp';
  // 判断是否使用模态窗口拉起
  @State isFromExternal: boolean = CallSettingVM.getInstance().getIsFromExternal();
  private isDistributeSink = false;
  @StorageLink('wifiCallingSwitchStateCard1') @Watch('onWifiCallingSwitchStateChange') wifiCallingSwitchStateCard1: boolean =
    false;
  @StorageLink('wifiCallingSwitchStateCard2') @Watch('onWifiCallingSwitchStateChange') wifiCallingSwitchStateCard2: boolean =
    false;
  @State wifiCallingSwitchState: boolean = false;
  @State phoneNumber: string = '';
  @StorageLink('windowStatus') windowStatus: window.WindowStatusType = window.WindowStatusType.UNDEFINED;
  @StorageLink('foldDisplayMode') foldDisplayMode: display.FoldDisplayMode =
    display.FoldDisplayMode.FOLD_DISPLAY_MODE_UNKNOWN;
  private isPrivacyModeEnabled: boolean = false;

  aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear');
    this.subSettingInit();
  }

  private subSettingInit() {
    let context = CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT);
    if (this.subData.displayName.id === $r('app.string.Call_forward').id ||
      this.subData.displayName.id === $r('app.string.wifi_calling').id ||
      this.subData.displayName.id === $r('app.string.more').id) {
      addRegisterDistributedStateListener(context, (data: string) => {
        LogUtils.i(TAG, `addRegisterDistributedStateListener: ${data}`);
        this.isDistributeSink = data === Constants.DISTRIBUTE_SINK_CALL;
      });
      queryDistributedState(context, (data: string) => {
        LogUtils.i(TAG, `queryDistributedState: ${data}`);
        this.isDistributeSink = data === Constants.DISTRIBUTE_SINK_CALL;
      });
      return
    } else {
      this.isDistributeSink = false;
    }
    if (this.subData.displayName.id === $r('app.string.call_history_merging').id) {
      LogUtils.i(TAG, ' onClick pushUrl');
      commons.getValue(undefined, (data: string) => {
        LogUtils.i(TAG, ' onClick pushUrl' + data);
        data === 'contacts' ? this.radioId = 1 : this.radioId = 0;
        this.callText = data === 'contacts' ? $r('app.string.by_contact') : $r('app.string.by_time');
      });
      return
    }

    if (this.subData.displayName.id === $r('app.string.unlock_after_call_notification').id) {
      commons.queryCallNotifiesType((data: string) => {
        this.getCallNotifiesText =
          data === CallSettingsConstant.FULL_SCREEN ? $r('app.string.full_screen') : $r('app.string.banner');
        if (SystemMode.getInstance().isModePenglai()) {
          this.getCallNotifiesText = $r('app.string.full_screen');
        }
      });
      return
    }

    if (this.subData.displayName.id === $r('app.string.phone_ring_tone').id) {
      LogUtils.i(TAG, 'get ringtone');
      if (StringUtil.isEmpty(this.simRingtoneOne)) {
        this.updateRingTone();
      }
      emitter.on({ eventId: CallSettingsConstant.EMIT_GET_RINGTONE_EVENT_ID }, () => {
        LogUtils.i(TAG, 'emitter.on, eventId = ' + CallSettingsConstant.EMIT_GET_RINGTONE_EVENT_ID);
        this.updateRingTone();
      });
      return
    }

    if (this.subData.displayName.id === $r('app.string.wifi_calling').id) {
      this.onWifiCallingSwitchStateChange();
      return
    }
  }

  async updateRingTone() {
    try {
      getRingToneAttrsArray(this.context, async (ringtoneAttrsArr: systemSoundManager.ToneAttrsArray) => {
        if (ringtoneAttrsArr.length > 0) {
          this.simRingtoneOne = await getRingToneName(this.context, 0, ringtoneAttrsArr);
        }
      });
    } catch (err) {
      LogUtils.e(TAG, `updateRingTone error, exception:${JSON.stringify(err)}`);
    }
  }

  aboutToDisappear(): void {
    let context = CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT);
    removeRegisterDistributedStateListener();
    if (this.subData.displayName.id === $r('app.string.phone_ring_tone').id && this.isFromExternal) {
      emitter.off(CallSettingsConstant.EMIT_GET_RINGTONE_EVENT_ID);
    }
    if (this.isPrivacyModeEnabled) {
      this.setWindowPrivacyMode(false);
    }
  }

  jumpCallRingTonePage(context: common.UIAbilityContext): void {
    let want: Want = {
      'bundleName': SETTING_BUNDLE_NAME,
      'abilityName': SETTING_ABILITY_NAME,
      'uri': SETTING_URI_NAME,
    }
    context.startAbility(want).then((data) => {
      LogUtils.i(TAG, `msg:${data}`);
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, `start setting app failed, code: ${err?.code}`);
    });
  }

  onWifiCallingSwitchStateChange() {
    this.wifiCallingSwitchState =
      this.slotId === Constants.SLOT_ID_ONE ? this.wifiCallingSwitchStateCard1 : this.wifiCallingSwitchStateCard2;
    LogUtils.i(TAG,
      `onWifiCallingSwitchStateChange, slotId: ${this.slotId}, wifiCallingSwitchState: ${this.wifiCallingSwitchState}`);
  }

  updateWifiCallingEnabled() {
    const key = `${CallSettingsConstant.WIFI_CALLING_ENABLED}_${this.slotId}`;
    const defValue = CallSettingsConstant.WIFI_CALLING_SWITCH_OFF;
    try {
      const result: string = settings.getValueSync(this.context, key, defValue, settings.domainName.USER_PROPERTY);
      LogUtils.i(TAG, `getWifiCallingSwitchState ${key}: ${result}`);
      this.wifiCallingSwitchState = result === CallSettingsConstant.WIFI_CALLING_SWITCH_ON;
    } catch (err) {
      LogUtils.e(TAG, `getWifiCallingSwitchState failed, err: ${JSON.stringify(err)}`);
    }
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.interactive_click'))
  }

  @Styles
  normalStyles() {
    .backgroundColor(Color.Transparent)
  }


  showToast(msg?: string) {
    let showMsg = StringUtil.getErrorMsg(msg);
    prompt.showToast({
      message: (msg && !StringUtil.isEmpty(msg)) ?
      StringUtil.formatResourceToString(showMsg) :
      StringUtil.formatResourceToString($r('app.string.emptyStr'))
    });
  }

  /**
   * 设置窗口隐私模式，禁止或允许截屏/录屏
   * @param enabled true表示禁止截屏/录屏，false表示允许截屏/录屏
   */
  private setWindowPrivacyMode(enabled: boolean) {
    try {
      if (this.isPrivacyModeEnabled === enabled) {
        return;
      }
      let windowStage = this.context.windowStage;
      if (!windowStage) {
        LogUtils.e(TAG, 'setWindowPrivacyMode: windowStage is null');
        return;
      }
      let mainWindow = windowStage.getMainWindowSync();
      if (!mainWindow) {
        LogUtils.e(TAG, 'setWindowPrivacyMode: mainWindow is null');
        return;
      }
      mainWindow.setWindowPrivacyMode(enabled).then(() => {
        this.isPrivacyModeEnabled = enabled;
        LogUtils.i(TAG, `setWindowPrivacyMode success: ${enabled}`);
      }).catch((err: BusinessError) => {
        LogUtils.e(TAG, `setWindowPrivacyMode failed, code: ${err?.code}, message: ${err?.message}`);
      });
    } catch (err) {
      LogUtils.e(TAG, `setWindowPrivacyMode error: ${JSON.stringify(err)}`);
    }
  }

  @Builder
  dialogContent() {
    List() {
      ForEach(this.changeContentItems, (item: ContentItem, index?: number) => {
        ListItem() {
          Column() {
            Row() {
              Text(item.name)
                .fontSize($r('sys.float.Subtitle_M'))
                .constraintSize({ minHeight: 21 })
                .fontColor($r('sys.color.font_primary'))
                .fontWeight(FontWeight.Regular)
                .width('100%')
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }

            Row() {
              TextInput({
                text: index === 0 ? this.oldInputText : index === 1 ? this.newInputText : this.confirmInputText
              })
                .borderRadius($r('sys.float.corner_radius_none'))
                .fontColor(item.id === this.activeId ? $r('sys.color.font_primary') :
                $r('sys.color.font_secondary'))
                .fontSize($r('sys.float.Body_L'))
                .backgroundColor(Color.Transparent)
                .type(InputType.Password)
                .showPasswordIcon(true)
                .fontWeight(FontWeight.Regular)
                .caretColor($r('sys.color.font_emphasize'))
                .constraintSize({ minHeight: 48 })
                .focusable(this.inputFocus)
                .padding({ left: $r('sys.float.padding_level0') })
                .margin({ right: -16 })
                .onFocus(() => {
                  this.activeId = item.id;
                  this.setWindowPrivacyMode(true);
                })
                .onBlur(() => {
                  this.setWindowPrivacyMode(false);
                })
                .onChange((value: string) => {
                  if (index === 0) {
                    this.oldInputText = value;
                  } else if (index === 1) {
                    this.newInputText = value;
                  } else {
                    this.confirmInputText = value;
                  }
                })
                .onTouch(() => {
                  this.inputFocus = true;
                })
            }
            .alignItems(VerticalAlign.Center)
            .justifyContent(FlexAlign.Start)
            .constraintSize({ minHeight: 56 })
            .margin({ top: $r('sys.float.padding_level2') })

            Divider()
              .strokeWidth(item.id === this.activeId ? '2px' : '1px')
              .color(item.id === this.activeId ? $r('sys.color.icon_primary') :
              $r('sys.color.comp_divider'))
              .opacity(item.id === this.activeId ? 0.6 : 1)
              .margin({ top: -5 })
          }.alignItems(HorizontalAlign.Start)
          .padding({
            bottom: index == this.changeContentItems.length - 1 ?
            $r('sys.float.padding_level2') : $r('sys.float.padding_level6')
          })
        }
      })
    }
  }

  dialogController: CustomDialogController = new CustomDialogController({
    builder: SelectDialog({
      title: $r('app.string.call_history_merging'),
      selectedIndex: this.radioId,
      radioContent: this.callTextArray,
      confirm: {
        value: $r('app.string.cancel_space'),
        action: () => {
          this.selectedRadio = -1;
          this.controller?.close();
          ReportUtil.getInstance().reportHistoryMergeAction(2);
        }
      },
    }),
    autoCancel: false
  })

  @Builder
  fontSizeScaleBig() {
    Column() {
      Column() {
        Text(this.subData.displayName)
          .fontSize($r('sys.float.Subtitle_M'))
          .fontColor($r('sys.color.font_primary'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: 2 })

      if (this.subData.isLineBreak && this.subData.description !== undefined) {
        Column() {
          this.bigFontSizeSubText(this.subData.description);
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 16 })
      }

      Column() {
        Row() {
          this.textContentBuilder()
          Image($r('app.media.ic_public_arrow_right'))
            .fillColor($r('sys.color.icon_fourth'))
            .height($r('app.float.wh_value_24'))
            .width($r('app.float.wh_value_12'))
            .align(Alignment.End)
            .matchTextDirection(true)
            .draggable(false)
            .id(`callSetting_components_subSetting_Image_arrow_right_${this.subData.displayName.id}`)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .fontSizeScaleStyles()
  }

  @Builder
  textContentBuilder() {
    if (this.subData.displayName?.id === $r('app.string.call_history_merging').id) {
      Text(this.callText)
        .fontSize($r('sys.float.Subtitle_S'))
        .fontColor($r('sys.color.font_secondary'))
        .margin({ right: $r('sys.float.padding_level2') })
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .textAlign(TextAlign.Start)
        .flexShrink(1)
        .align(Alignment.End)
        .id(`callSetting_components_subSetting_rowText_call_history_merging_${this.subData.displayName.id}`);
    }
    if (this.subData.displayName?.id === $r('app.string.unlock_after_call_notification').id) {
      Text(this.getCallNotifiesText)
        .fontSize($r('sys.float.Subtitle_S'))
        .fontColor($r('sys.color.font_secondary'))
        .margin({ right: $r('sys.float.padding_level2') })
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .textAlign(TextAlign.Start)
        .flexShrink(1)
        .align(Alignment.End)
        .id(`callSetting_components_subSetting_rowText_notification_${this.subData.displayName.id}`);
    }
    if (this.subData.displayName?.id === $r('app.string.number_identity_setting_title').id) {
      Text(this.numberIdentityStatus ? $r('app.string.opened') : $r('app.string.closed'))
        .fontSize($r('sys.float.Subtitle_S'))
        .fontColor($r('sys.color.font_secondary'))
        .margin({ right: 4 })
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .textAlign(TextAlign.Start)
        .flexShrink(1)
        .align(Alignment.End)
        .id(`callSetting_components_subSetting_identity_setting_title_${this.subData.displayName.id}`);
    }
    if (this.subData.displayName?.id === $r('app.string.phone_ring_tone').id) {
      Text(this.simRingtoneOne)
        .fontSize($r('sys.float.Subtitle_S'))
        .fontColor($r('sys.color.font_secondary'))
        .margin({ right: $r('sys.float.padding_level2') })
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .maxLines(4)
        .textAlign(TextAlign.End)
        .flexShrink(1)
        .align(Alignment.End);
    }
    if (this.subData.displayName?.id === $r('app.string.wifi_calling').id) {
      Text(this.slotId ? $r('app.string.opened') : $r('app.string.closed'))
        .fontSize($r('sys.float.Subtitle_S'))
        .fontColor($r('sys.color.font_secondary'))
        .margin({ right: $r('sys.float.padding_level2') })
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .maxLines(4)
        .textAlign(TextAlign.Start)
        .flexShrink(1)
        .align(Alignment.End)
        .margin({ right: $r('sys.float.padding_level2') })
        .maxLines(4)
        .id(`callSetting_components_subSetting_wifi_calling_switch_state_text_${this.subData.displayName.id}`);
    }
  }

  @Builder
  bigFontSizeSubText(text: Resource) {
    Text(text)
      .fontSize($r('sys.float.Subtitle_S'))
      .fontColor($r('sys.color.font_secondary'))
      .margin({ right: $r('sys.float.padding_level2') })
      .fontFamily('HarmonyHeiTi')
      .fontWeight(FontWeight.Regular)
      .maxLines(4)
      .flexShrink(1)
      .align(Alignment.End);
  }

  private getFontSizeScaleMargin(): string {
    if (isTwoInOne()) {
      return '8vp';
    }
    if (this.fontSizeScale > 1) {
      return this.fontSizeScaleMargin;
    }
    return '0vp';
  }

  @Styles
  fontSizeScaleStyles() {
    .enabled((this.subData.displayName.id === $r('app.string.wifi_calling').id ?
      this.isEnable && !this.isDistributeSink : this.isEnable && !this.airPlaneOn && !this.isDistributeSink))
    .onClick(() => {
      LogUtils.i(TAG, ' onClick id: ' + this.subData.displayName?.id);
      this.itemLickEvent();
    })
    .width('100%')
    .borderRadius($r('sys.float.corner_radius_level8'))
    .padding({
      left: $r('sys.float.padding_level4'),
      right: $r('sys.float.padding_level4'),
      top: this.getFontSizeScaleMargin(),
      bottom: this.getFontSizeScaleMargin()
    })
    .stateStyles({
      pressed: this.pressedStyles,
      normal: this.normalStyles
    })
  }

  itemLickEvent() {
    let routerOptions: RouterOptions = { url: '', params: {} };
    if (this.subData.displayName?.id === $r('app.string.call_history_merging').id) {
      LogUtils.i(TAG, ' onClick pushUrl');
      commons.getValue(undefined, (data: string) => {
        LogUtils.i(TAG, ' onClick pushUrl' + data);
        data === 'contacts' ? this.radioId = 1 : this.radioId = 0;
      })
      this.radioId = this.selectedRadio === -1 ? this.radioId : this.selectedRadio;
      this.dialogController.open();
      ReportUtil.getInstance().reportClickCallHistoryMerge();
    } else if (this.subData.displayName?.id === $r('app.string.Call_forward').id) {
      routerOptions.url = 'CallForward';
      ReportUtil.getInstance().reportClickForwarding(this.slotId);
    } else if (this.subData.displayName?.id === $r('app.string.more').id) {
      routerOptions.url = 'More';
      ReportUtil.getInstance().reportClickMore(this.slotId);
    } else if (this.subData.displayName?.id === $r('app.string.unlock_after_call_notification').id) {
      routerOptions.url = 'CallNotifies';
      ReportUtil.getInstance().reportClickUnLockNotify();
    } else if (this.subData.displayName?.id === $r('app.string.incoming_call_rejection_sms').id) {
      routerOptions.url = 'IncomingCallRejectionSms';
      ReportUtil.getInstance().reportClickIncomingRejectSms();
    } else if (this.subData.displayName?.id === $r('app.string.wifi_calling').id) {
      routerOptions.url = 'WifiCallingSettings';
      ReportUtil.getInstance().reportClickWifiCalling();
    } else {
      this.itemLickEvent2(routerOptions);
    }
    if (routerOptions.url !== '') {
      routerOptions.params = { 'slotId': this.slotId };
      LogUtils.i(TAG, ' onClick pushUrl');
      this.pathInfos.pushPathByName(routerOptions.url, routerOptions.params);
    }
  }

  itemLickEvent2(routerOptions: RouterOptions) {
    if (this.subData.displayName?.id === $r('app.string.speedDial').id) {
      this.subSettingVM.clickToContactsSpeedDail();
      ReportUtil.getInstance().reportClickSpeedDial();
    } else if (this.subData.displayName?.id === $r('app.string.voicemail').id) {
      this.subSettingVM.clickToContactsVoicemail(this.slotId);
      ReportUtil.getInstance().reportClickVoiceMail(this.slotId);
    } else if (this.subData.displayName?.id === $r('app.string.call_about').id) {
      routerOptions.url = 'CallAbout';
      ReportUtil.getInstance().reportClickAbout();
    } else if (this.subData.displayName?.id === $r('app.string.phone_ring_tone').id) {
      this.jumpCallRingTonePage(this.context);
      ReportUtil.getInstance().reportClickIncomingRingTone(this.simRingtoneOne);
    } else if (this.subData.displayName?.id === $r('app.string.advance_options_title').id) {
      routerOptions.url = 'AdvanceOptions';
      ReportUtil.getInstance().reportClickAdvance();
    }
  }

  build() {
    Column() {
      if (this.fontSizeScale >= 1.75 && (this.subData.displayName?.id === $r('app.string.call_history_merging').id ||
        this.subData.displayName?.id === $r('app.string.unlock_after_call_notification').id ||
        this.subData.displayName?.id === $r('app.string.number_identity_setting_title').id ||
        this.subData.displayName?.id === $r('app.string.anti_fraud').id ||
        this.subData.displayName?.id === $r('app.string.wifi_calling').id || this.subData.itemKey ===  'celia')) {
        this.fontSizeScaleBig();
      } else {
        Row() {
          if (this.subData.description !== undefined) {
            this.twoLineBuilder()
          } else {
            Text(this.subData.displayName)
              .fontSize($r('sys.float.Subtitle_M'))
              .fontColor($r('sys.color.font_primary'))
              .fontFamily('HarmonyHeiTi')
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
              .id(`callSetting_components_subSetting_rowText_${this.subData.displayName.id}`)
          }
          Row() {
            this.rowContentBuilder()
          }
          .justifyContent(FlexAlign.End)
          .width('auto')
        }
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.SpaceBetween)
        .constraintSize({
          minHeight: (this.subData.displayName.id === $r('app.string.anti_fraud').id ? '64vp' :
            isTwoInOne() ? $r('app.float.wh_value_40') : $r('app.float.wh_value_48'))
        })
        .fontSizeScaleStyles()
      }

      if (this.subData.showDivider) {
        Divider()
          .color($r('sys.color.comp_divider'))
          .lineCap(LineCapStyle.Round)
          .width('100%')
          .padding({
            left: $r('sys.float.padding_level4'),
            right: $r('sys.float.padding_level4')
          })
      }
    }
    .padding({ left: $r('sys.float.padding_level2'), right: $r('sys.float.padding_level2') })
    .constraintSize({ minHeight: isTwoInOne() ? $r('app.float.wh_value_40') : $r('app.float.wh_value_48') })
    .borderRadius($r('sys.float.corner_radius_level8'))
    .opacity((this.subData.displayName.id === $r('app.string.wifi_calling').id ?
      this.isEnable && !this.isDistributeSink : this.isEnable && !this.airPlaneOn && !this.isDistributeSink) ?
      OPACITY_ENABLE : OPACITY_DISABLE_ITEM_CHILD)
    .expandSafeArea([SafeAreaType.KEYBOARD])
  }

  @Builder
  twoLineBuilder() {
    Column() {
      Text(this.subData.displayName)
        .fontSize($r('sys.float.Subtitle_M'))
        .fontColor($r('sys.color.font_primary'))
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Medium)
        .constraintSize({ maxWidth: '100%', minHeight: '22vp' })
        .id(`callSetting_components_subSetting_rowText_${this.subData.displayName.id}`);
      Text(this.subData.description)
        .fontSize($r('sys.float.Subtitle_S'))
        .fontColor($r('sys.color.font_secondary'))
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .margin({ top: '2vp' })
        .constraintSize({ maxWidth: '100%', minHeight: '19vp' })
        .id('callSetting_components_subSetting_rowDescriptionText');
    }
    .layoutWeight(1)
    .margin({ right: $r('sys.float.padding_level4') })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  rowContentBuilder() {
    if (this.subData.displayName?.id === $r('app.string.call_history_merging').id) {
      Text(this.callText)
        .fontSize($r('sys.float.Subtitle_S'))
        .fontColor($r('sys.color.font_secondary'))
        .margin({ right: $r('sys.float.padding_level2') })
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .textAlign(TextAlign.Start)
        .flexShrink(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .align(Alignment.End)
        .id(`callSetting_components_subSetting_rowText_call_history_merging_${this.subData.displayName.id}`);
    }
    if (this.subData.displayName?.id === $r('app.string.unlock_after_call_notification').id) {
      Text(this.getCallNotifiesText)
        .fontSize($r('sys.float.Subtitle_S'))
        .fontColor($r('sys.color.font_secondary'))
        .margin({ right: $r('sys.float.padding_level2') })
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .textAlign(TextAlign.Start)
        .flexShrink(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .align(Alignment.End)
        .id(`callSetting_components_subSetting_rowText_notification_${this.subData.displayName.id}`);
    }
    if (this.subData.displayName?.id === $r('app.string.number_identity_setting_title').id) {
      Text(this.numberIdentityStatus ? $r('app.string.opened') : $r('app.string.closed'))
        .fontSize($r('sys.float.Subtitle_S'))
        .fontColor($r('sys.color.font_secondary'))
        .margin({ right: 4 })
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .textAlign(TextAlign.Start)
        .flexShrink(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .align(Alignment.End)
        .id(`callSetting_components_subSetting_identity_setting_title_${this.subData.displayName.id}`);
    }
    if (this.subData.displayName?.id === $r('app.string.phone_ring_tone').id) {
      Text(this.simRingtoneOne)
        .fontSize($r('sys.float.Subtitle_S'))
        .fontColor($r('sys.color.font_secondary'))
        .margin({ right: $r('sys.float.padding_level2') })
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .maxLines(4)
        .textAlign(TextAlign.End)
        .flexShrink(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .align(Alignment.End);
    }
    if (this.subData.displayName?.id === $r('app.string.wifi_calling').id) {
      Text(this.wifiCallingSwitchState ? $r('app.string.opened') : $r('app.string.closed'))
        .isOpenedTextExtend()
        .id(`callSetting_components_subSetting_wifi_calling_switch_state_text_${this.subData.displayName.id}`);
    }
    SymbolGlyph($r('sys.symbol.chevron_right'))
      .fontColor([$r('sys.color.icon_fourth')])
      .fontSize($r('app.float.wh_value_24'))
      .align(Alignment.End)
      .draggable(false)
      .fontWeight(FontWeight.Regular)
      .id(`callSetting_components_subSetting_Image_arrow_right_${this.subData.displayName.id}`)
  }
}


@Extend(Text)
function isOpenedTextExtend() {
  .fontSize($r('sys.float.Subtitle_S'))
  .fontColor($r('sys.color.font_secondary'))
  .margin({ end: LengthMetrics.vp(4) })
  .fontFamily('HarmonyHeiTi')
  .fontWeight(FontWeight.Regular)
  .textAlign(TextAlign.Start)
  .flexShrink(1)
  .align(Alignment.End)
}

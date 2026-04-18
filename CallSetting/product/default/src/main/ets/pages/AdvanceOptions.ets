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

import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { StringUtil } from '../common/utils/StringUtil';
import { LogUtils, CallSettingGlobalContextHelper, ReportUtil, TitleParams,
  TitleBarLayout } from '@ohos/common/CommonIndex';
import { RouterOptions } from '../components/SubSettings';
import settings from '@ohos.settings';
import * as CallSettingsConstant from '../common/constant/CallSettingsConstant';
import { BusinessError } from '@ohos.base';
import { call, observer, sim } from '@kit.TelephonyKit';
import CallColumnUtils from '../common/utils/CallColumnUtils';
import SystemParameterEnhance from '@ohos.systemParameterEnhance';
import {
  getMaxSimCount,
  registerSimStateChangeForSlotId,
  registerCallStateChange,
  unRegisterSimStateChange,
  unRegisterCallStateChange,
  registericcAccountInfoChange
} from '../model/RegisterSimStateApi';
import { isFusionCallEnabled } from '../common/utils/Utils';
import { SystemMode } from '../model/SystemMode';
import { LengthMetrics, promptAction } from '@kit.ArkUI';
import CallSettingVM from '../viewModel/CallSettingVM';
// import { NavDestination,  HdsNavDestinationAttribute, HdsNavDestinationTitleMode } from '@kit.UIDesignKit';
import { BOTTOM_MARGIN } from '../common/constant/CallSettingsConstant';

const TAG = 'AdvanceOptions';
const INCALL_POWER_KEY: string = 'incall_power_button_behavior';
const FUSION_CALL_KEY: string = 'fusion_call_switch';
const FULL_OP = 1;
const MAX_SIM_COUNTS = 2;
const VIDEO_RING_TONE_SETTINGS = 'video_ringback_tone_settings';
const VIDEO_RINGTONE_SWITCH_STATUS = 'video_ringtone_switch_status';
const VIDEO_RBI_SWITCH_SHOW = 'show';
const VIDEO_RBI_SWITCH_HIDE_AND_RECOVER = 'hide_and_recover';
const VIDEO_RBI_SWITCH_HIDE_AND_NOT_RECOVER = 'hide_and_not_recover';

@Component
export default struct AdvanceOptions {
  scroller: Scroller = new Scroller();
  @StorageProp('airPlaneOn') airPlaneOn: boolean = false;
  @Consume('pathInfos') pathInfos: NavPathStack;
  @LocalStorageLink('FusionCallSwitchStatus') fusionCallSwitchStatus: boolean = false;
  @LocalStorageLink('VideoRingToneSwitchStatus') videoRingToneSwitchStatus: boolean = true;
  @State currentColorMode: ConfigurationConstant.ColorMode | undefined = 1;
  @State @Watch('simStateCardChange') simStateCardOne: boolean = false;
  @State @Watch('simStateCardChange') simStateCardTwo: boolean = false;
  @State fusionCallNotificationSub1: string = '';
  @State fusionCallNotificationSub2: string = '';
  @State fusionCallNotificationSub3: string = '';
  @State isShowVideoRingTone: boolean = true;
  @State enabledVideoRingTone: boolean = true;
  @State isPenglai: boolean = false;
  @State isShowFusionCallSwitch: boolean = true;
  @StorageProp('curBp') curBp: string = '';
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('currentLanguage') @Watch('updateResource') currentLanguage: string = '';
  @LocalStorageLink('EndCallSwitchStatus') endCallSwitchStatus: boolean = false;
  // 判断是否使用模态窗口拉起
  @State isFromExternal: boolean = CallSettingVM.getInstance().getIsFromExternal();
  // 判断半模态是否有叉号
  @State isCrossMarkExists: boolean = CallSettingVM.getInstance().getIsFromExternal();
  @State isSearchPush: boolean = false;
  private naviIndicatorHeight: number = 28;

  simStateCardChange() {
    if (!this.simStateCardOne && !this.simStateCardTwo) {
      this.enabledVideoRingTone = false;
    } else {
      let callin: boolean = this.checkCallStatus();
      if (callin) {
        this.enabledVideoRingTone = false;
      } else {
        this.enabledVideoRingTone = true;
      }
    }
  }

  aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear');
    let fusionCallSwitch: string = settings.getValueSync(CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT), FUSION_CALL_KEY, '0',
      settings.domainName.USER_PROPERTY);
    LogUtils.i(TAG, 'aboutToAppear, fusionCallSwitch: ' + fusionCallSwitch);
    this.fusionCallSwitchStatus = (fusionCallSwitch === '1');
    this.isShowFusionCallSwitch = isFusionCallEnabled();

    // end call by click power
    let endCallSwitch: string = settings.getValueSync(CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT), INCALL_POWER_KEY, '0',
      settings.domainName.USER_PROPERTY);
    LogUtils.i(TAG, 'aboutToAppear, incall_power_button_behavior: ' + endCallSwitch);
    this.endCallSwitchStatus = (endCallSwitch === '1');

    let videoRingToneSwitch: string = settings.getValueSync(CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT),
      VIDEO_RING_TONE_SETTINGS, '1',
      settings.domainName.USER_PROPERTY);
    LogUtils.i(TAG, 'aboutToAppear, videoRingToneSwitch: ' + videoRingToneSwitch);
    this.videoRingToneSwitchStatus = (videoRingToneSwitch == '1');

    let simIsActive = this.checkSimIsActive();
    LogUtils.i(TAG, 'aboutToAppear, simIsActive: ' + simIsActive);
    let callActice = this.checkCallStatus();
    LogUtils.i(TAG, 'aboutToAppear, callActice: ' + callActice);
    if (callActice || !simIsActive) {
      this.enabledVideoRingTone = false;
    }
    this.checkIsShowVideoRingToneSetting();
    this.getProductLevelConfigurationAndSet();
    this.updateResource();
    this.registerRingToneSwitchStatusObserver();
    this.registerSimStateChangeForCard();
    this.registerCallStateChangeForCard();
    this.isPenglai = SystemMode.getInstance().isModePenglai();
    this.setIsSearchPush();
  }

  setIsSearchPush() {
    let param: Record<string, boolean> = this.pathInfos.getParamByIndex(0) as Record<string, boolean>;
    if (param) {
      this.isSearchPush = param['isSearchPush'];
    }
  }

  getProductLevelConfigurationAndSet() {
    let configurationUse = SystemParameterEnhance.getSync('const.telephony.show_video_ringback_tone_switch', 'true');
    LogUtils.i(TAG, 'getProductLevelConfigurationAndSet-configurationUse: ' + configurationUse);
    if (this.isShowVideoRingTone && configurationUse == 'false') {
      this.isShowVideoRingTone = false;
    }
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear');
    unRegisterSimStateChange();
    unRegisterCallStateChange();
    settings.unregisterKeyObserver(CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT),
      VIDEO_RINGTONE_SWITCH_STATUS, settings.domainName.USER_PROPERTY);
    LogUtils.i(TAG, 'aboutToDisappear');
  }

  registerRingToneSwitchStatusObserver() {
    try {
      settings.registerKeyObserver(CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT),
        VIDEO_RINGTONE_SWITCH_STATUS, settings.domainName.USER_PROPERTY, () => {
          this.checkIsShowVideoRingToneSetting();
        });
    } catch (err) {
      LogUtils.e(TAG, `registerRingToneSwitchStatusObserver error: ${err?.code} ${err?.message}`);
    }
  }

  initVideoRingToneSwitchStatus(value: string) {
    try {
      settings.setValueSync(CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT),
        VIDEO_RINGTONE_SWITCH_STATUS, value, settings.domainName.USER_PROPERTY);
    } catch (err) {
      LogUtils.e(TAG, `initVideoRingToneSwitchStatus error: ${err?.code} ${err?.message}`);
    }
  }

  checkIsShowVideoRingToneSetting() {
    let videoRingtonePushMes: string = settings.getValueSync(CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT),
      VIDEO_RINGTONE_SWITCH_STATUS, '',
      settings.domainName.USER_PROPERTY);
    LogUtils.i(TAG, 'videoRingtonePushMes: ' + videoRingtonePushMes);
    if (VIDEO_RBI_SWITCH_SHOW == videoRingtonePushMes) {
      this.isShowVideoRingTone = true;
      LogUtils.i(TAG, 'videoRingtonePushMes:' + videoRingtonePushMes);
      return;
    } else if (VIDEO_RBI_SWITCH_HIDE_AND_RECOVER == videoRingtonePushMes) {
      LogUtils.i(TAG, 'videoRingtonePushMes:' + videoRingtonePushMes);
      this.isShowVideoRingTone = false;
      this.setVideoRingToneSwitch('1').then((data: boolean | BusinessError) => {
        LogUtils.i(TAG, 'setVideoRingToneSwitch success, data: ' + data);
      }).catch((err: BusinessError) => {
        LogUtils.e(TAG, 'setVideoRingToneSwitch error' + JSON.stringify(err));
      });
    } else if (VIDEO_RBI_SWITCH_HIDE_AND_NOT_RECOVER == videoRingtonePushMes) {
      this.isShowVideoRingTone = false;
      LogUtils.i(TAG, 'videoRingtonePushMes' + videoRingtonePushMes);
    } else {
      this.initVideoRingToneSwitchStatus(VIDEO_RBI_SWITCH_SHOW);
    }
  }

  checkCallStatus() {
    let callState: call.CallState = call.getCallStateSync();
    if (callState == call.CallState.CALL_STATE_OFFHOOK || callState == call.CallState.CALL_STATE_ANSWERED ||
      callState == call.CallState.CALL_STATE_RINGING) {
      return true;
    } else {
      return false;
    }
  }

  checkSimIsActive() {
    let isSimActive1: boolean = sim.isSimActiveSync(0);
    this.simStateCardOne = isSimActive1;
    LogUtils.i(TAG, 'checkSimIsActive, isSimActive1: ' + isSimActive1);
    let isSimActive2: boolean = false;
    if (MAX_SIM_COUNTS == getMaxSimCount()) {
      isSimActive2 = sim.isSimActiveSync(1);
      this.simStateCardTwo = isSimActive2;
      LogUtils.i(TAG, 'checkSimIsActive, isSimActive2: ' + isSimActive2);
    }
    return isSimActive1 || isSimActive2;
  }

  registerSimStateChangeForCard() {
    registericcAccountInfoChange(() => {
      LogUtils.i(TAG, 'registericcAccountInfoChange');
      let simIsActive = this.checkSimIsActive();
      LogUtils.i(TAG, 'aboutToAppear, simIsActive: ' + simIsActive);
      let callActice = this.checkCallStatus();
      LogUtils.i(TAG, 'aboutToAppear, callActice: ' + callActice);
      if (callActice || !simIsActive) {
        this.enabledVideoRingTone = false;
      }
    })
    registerSimStateChangeForSlotId(0, async (simStateInfo: observer.SimStateData) => {
      this.simStateCardOne = simStateInfo.state === sim.SimState.SIM_STATE_READY || simStateInfo.state ===
      sim.SimState.SIM_STATE_LOADED ? true : false;
    });
    if (MAX_SIM_COUNTS == getMaxSimCount()) {
      registerSimStateChangeForSlotId(1, async (simStateInfo: observer.SimStateData) => {
        this.simStateCardTwo = simStateInfo.state === sim.SimState.SIM_STATE_READY || simStateInfo.state ===
        sim.SimState.SIM_STATE_LOADED ? true : false;
      });
    }
  }

  registerCallStateChangeForCard() {
    let optionsOne: observer.ObserverOptions = {
      slotId: 0
    }
    registerCallStateChange(optionsOne, async (callStateInfo: observer.CallStateInfo) => {
      this.setEnabledVideoRingTone(callStateInfo);
    });
    if (MAX_SIM_COUNTS == getMaxSimCount()) {
      let optionsTwo: observer.ObserverOptions = {
        slotId: 1
      }
      registerCallStateChange(optionsTwo, async (callStateInfo: observer.CallStateInfo) => {
        this.setEnabledVideoRingTone(callStateInfo);
      });
    }
  }

  setEnabledVideoRingTone(callStateInfo: observer.CallStateInfo) {
    LogUtils.i(TAG, 'setEnabledVideoRingTone, CallState: ' + callStateInfo.state);
    if (callStateInfo.state == call.CallState.CALL_STATE_OFFHOOK ||
      callStateInfo.state == call.CallState.CALL_STATE_ANSWERED ||
      callStateInfo.state == call.CallState.CALL_STATE_RINGING) {
      this.enabledVideoRingTone = false;
    } else if (callStateInfo.state == 0) {
      setTimeout(() => {
        let callActice: boolean = false;
        callActice = this.checkCallStatus();
        LogUtils.i(TAG, 'setEnabledVideoRingTone, callActice: ' + callActice);
        if (!callActice && (this.simStateCardOne || this.simStateCardTwo)) {
          this.enabledVideoRingTone = true;
        }
      }, 50)
    }
  }

  updateResource() {
    let fusionCallNotification: string =
      StringUtil.formatResourceToString($r('app.string.fusion_call_switch_short_notification'));
    const parts = fusionCallNotification.split('%1$s');
    if (parts.length !== 2) {
      LogUtils.e(TAG, 'update resource fail');
      return;
    }

    this.fusionCallNotificationSub1 = parts[0];
    this.fusionCallNotificationSub3 = parts[1];
    this.fusionCallNotificationSub2 =
      StringUtil.formatResourceToString($r('app.string.fusion_call_switch_short_notification_sub2'));
  }

  async onEndCallSwitchChange(isOn: boolean) {
    LogUtils.i(TAG, 'onEndCallSwithcChange, isOn:' + isOn);
    if (isOn === this.endCallSwitchStatus) {
      return;
    }
    let value: string = isOn ? '1' : '0';
    this.setEndCallSwitch(value).then((data: boolean | BusinessError) => {
      LogUtils.i(TAG, 'setEndCallSwitch success, data: ' + data);
      this.endCallSwitchStatus = isOn;
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, 'setEndCallSwitch error' + JSON.stringify(err));
    });
  }

  async setEndCallSwitch(value: string): Promise<boolean | BusinessError> {
    return new Promise((resolve, reject) => {
      try {
        settings.setValue(CallSettingGlobalContextHelper.getContext()
          .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT),
          INCALL_POWER_KEY, value, settings.domainName.USER_PROPERTY).then((data) => {
          resolve(data);
        }).catch((error: BusinessError) => {
          reject(error);
        });
      } catch (error) {
        reject(error);
      }
    });
  }

  async onFusionCallSwitchChange(isOn: boolean) {
    LogUtils.i(TAG, 'onFusionCallSwitchChange, isOn: ' + isOn);
    if (isOn === this.fusionCallSwitchStatus) {
      return;
    }
    let value: string = isOn ? '1' : '0';
    this.setFusionCallSwitch(value).then((data: boolean | BusinessError) => {
      LogUtils.i(TAG, 'setFusionCallSwitch success, data: ' + data);
      this.fusionCallSwitchStatus = isOn;
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, 'setFusionCallSwitch error' + JSON.stringify(err));
    });
  }

  async onVideoRingToneSwitchChange(isOn: boolean) {
    LogUtils.i(TAG, 'onVideoRingToneSwitchChange, isOn: ' + isOn);
    if (isOn === this.videoRingToneSwitchStatus) {
      return;
    }
    let value: string = isOn ? '1' : '0';
    this.setVideoRingToneSwitch(value).then((data: boolean | BusinessError) => {
      this.videoRingToneSwitchStatus = isOn;
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, 'setVideoRingToneSwitch error' + JSON.stringify(err));
    });
  }

  async setFusionCallSwitch(value: string): Promise<boolean | BusinessError> {
    return new Promise((resolve, reject) => {
      try {
        settings.setValue(CallSettingGlobalContextHelper.getContext()
          .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT),
          FUSION_CALL_KEY, value, settings.domainName.USER_PROPERTY).then((data) => {
          resolve(data);
        }).catch((error: BusinessError) => {
          reject(error);
        });
      } catch (error) {
        reject(error);
      }
    });
  }

  private getFusionCallNotiTextLineHeight() {
    if (this.currentLanguage.startsWith('bo-CN')) {
      return 17;
    }
    return 13;
  }

  @Builder
  SubEndSwitchOptions(title: Resource) {
    Column() {
      Flex({
        direction: FlexDirection.Row,
        justifyContent: FlexAlign.SpaceBetween,
        alignItems: ItemAlign.Center
      }) {
        this.endCallContent(title)
      }
      .constraintSize({ minHeight: 48 })
      .margin({
        top: $r('sys.float.padding_level2'),
        left: $r('sys.float.padding_level6'),
        right: $r('sys.float.padding_level6')
      })
      .opacity(!this.airPlaneOn ? 1 : $r('sys.float.alpha_disable'))
      .enabled(!this.airPlaneOn)
      .accessibilityGroup(true)
    }
  }

  @Builder
  endCallContent(title: Resource) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .fontWeight(FontWeight.Medium)
        .fontFamily('HarmonyHeiTi')
        .constraintSize({ minHeight: 21 });
    }
    .margin({
      right: $r('sys.float.ohos_id_text_margin_horizontal')
    })
    .layoutWeight(1)

    Toggle({ type: ToggleType.Switch, isOn: this.endCallSwitchStatus })
      .width('36vp')
      .height('20vp')
      .margin(0)
      .hoverEffect(HoverEffect.None)
      .onChange((isOn: boolean) => {
        LogUtils.i(TAG, 'end_call_onChange, isOn: ' + isOn);
        if (title.id === $r('app.string.end_call_by_power').id) {
          this.onEndCallSwitchChange(isOn);
          // 按电源键结束通话开关
          ReportUtil.getInstance().reportEndCallSwitch(isOn);
        }
      })
      .accessibilityLevel('yes')
  }

  async setVideoRingToneSwitch(value: string): Promise<boolean | BusinessError> {
    return new Promise((resolve, reject) => {
      try {
        settings.setValue(CallSettingGlobalContextHelper.getContext()
          .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT),
          VIDEO_RING_TONE_SETTINGS, value, settings.domainName.USER_PROPERTY).then((data) => {
          resolve(data);
        }).catch((error: BusinessError) => {
          reject(error);
        });
      } catch (error) {
        reject(error);
      }
    });
  }

  @Builder
  SubAdvanceOptions(title: Resource) {
    Column() {
      Flex({
        direction: FlexDirection.Row,
        justifyContent: FlexAlign.SpaceBetween,
        alignItems: ItemAlign.Center
      }) {
        Row() {
          Text(title)
            .fontSize(16)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .fontWeight(FontWeight.Medium)
            .fontFamily('HarmonyHeiTi')
            .constraintSize({ minHeight: 21 })
        }
        .layoutWeight(1)
        .margin({
          right: $r('sys.float.ohos_id_text_margin_horizontal')
        })

        Toggle({ type: ToggleType.Switch, isOn: this.fusionCallSwitchStatus })
          .width('36vp')
          .height('20vp')
          .margin(0)
          .hoverEffect(HoverEffect.None)
          .onChange((isOn: boolean) => {
            LogUtils.i(TAG, 'onChange, isOn: ' + isOn);
            if (title.id === $r('app.string.improve_call_quality').id) {
              this.onFusionCallSwitchChange(isOn);
              ReportUtil.getInstance().reportImproveCallQualityStatus(isOn);
            }
          })
          .accessibilityLevel('yes')
      }
      .constraintSize({ minHeight: 48 })
      .margin({
        top: $r('sys.float.padding_level2'),
        bottom: $r('sys.float.padding_level2'),
        left: $r('sys.float.padding_level6'),
        right: $r('sys.float.padding_level6')
      })
      .accessibilityGroup(true)
    }
  }

  getVideoRingtoneEnable() {
    return !this.airPlaneOn && this.enabledVideoRingTone && !this.isPenglai;
  }

  @Builder
  RingToneAndVideoSwitch(title: Resource, desc: Resource) {
    Row() {
      Column() {
        Row() {
          Text(title)
            .textAlign(TextAlign.Start)
            .fontSize(16)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .fontWeight(FontWeight.Medium)
            .fontFamily('HarmonyHeiTi')
            .constraintSize({ minHeight: 22, maxWidth: '100%' })
            .layoutWeight(1)
            .margin({
              top: 10
            })
        }
        .margin({
          right: $r('sys.float.ohos_id_text_margin_horizontal')
        })

        Row() {
          Text(desc)
            .textAlign(TextAlign.Start)
            .fontSize(14)
            .fontColor($r('sys.color.font_secondary'))
            .fontFamily('HarmonyHeiTi')
            .constraintSize({ minHeight: 19, maxWidth: '100%' })
            .layoutWeight(1)
        }
        .margin({
          top: 2,
          bottom: 10,
          right: $r('sys.float.ohos_id_text_margin_horizontal')
        })
      }
    }
    .opacity(this.getVideoRingtoneEnable() ? FULL_OP : $r('sys.float.alpha_disable'))
    .layoutWeight(1)

    Toggle({
      type: ToggleType.Switch,
      isOn: this.videoRingToneSwitchStatus && !this.isPenglai
    })
      .width('36vp')
      .height('20vp')
      .margin(0)
      .onChange((isOn: boolean) => {
        if (title.id === $r('app.string.video_ring_tone').id) {
          this.onVideoRingToneSwitchChange(isOn);
          // 视频彩铃开关
          ReportUtil.getInstance().reportVideoRingToneSwitch(isOn);
        }
      })
      .enabled(this.getVideoRingtoneEnable())
      .accessibilityLevel('yes')
  }

  @Builder
  RingToneAndVideoSwitchSettingChild() {
    Column() {
      Flex({
        direction: FlexDirection.Row,
        justifyContent: FlexAlign.SpaceBetween,
        alignItems: ItemAlign.Center
      }) {
        this.RingToneAndVideoSwitch($r('app.string.video_ring_tone'),
          $r('app.string.video_ring_tone_desc'))
      }
      .enabled(this.getVideoRingtoneEnable())
      .constraintSize({ minHeight: 64 })
      .margin({
        bottom: $r('sys.float.padding_level2'),
        left: $r('sys.float.padding_level6'),
        right: $r('sys.float.padding_level6')
      })
      .accessibilityLevel('yes')
      .accessibilityGroup(true)
    }
  }

  @Builder
  RingToneAndVideoSwitchSetting() {
    if (this.isShowVideoRingTone) {
      this.RingToneAndVideoSwitchSettingChild();
    }
  }

  @Builder
  FusionCallNotificationText() {
    Text() {
      Span(this.fusionCallNotificationSub1)
        .fontSize(10)
        .fontWeight(FontWeight.Regular)
        .fontFamily('HarmonyHeiTi')
        .fontColor($r('sys.color.font_secondary'))
      Span(this.fusionCallNotificationSub2)
        .fontSize(10)
        .fontWeight(FontWeight.Medium)
        .fontFamily('HarmonyHeiTi')
        .fontColor($r('sys.color.font_emphasize'))
        .onClick(() => {
          let routerOptions: RouterOptions = { url: '', params: {} };
          routerOptions.url = 'FusionCallAgreement';
          this.pathInfos.pushPathByName(routerOptions.url, routerOptions.params);
        })
        .accessibilityDescription(' ')
      Span(this.fusionCallNotificationSub3)
        .fontSize(10)
        .fontWeight(FontWeight.Regular)
        .fontFamily('HarmonyHeiTi')
        .fontColor($r('sys.color.font_secondary'))
    }
    .width('100%')
    .lineHeight(this.getFusionCallNotiTextLineHeight())
  }

  build() {
    NavDestination() {
      GridRow({ columns: { xs: 4, sm: 4, md: 8, lg: 12 }, gutter: 24 }) {
        GridCol({
          span: this.isFromExternal ? { xs: 4, sm: 4, md: 8, lg: 12 } : { xs: 4, sm: 4, md: 6, lg: 8 },
          offset: this.isFromExternal ? 0 : { md: 1, lg: 2 }
        }) {
          List() {
            ListItemGroup() {
              ListItem() {
                this.SubEndSwitchOptions($r('app.string.end_call_by_power'));
              }

              ListItem() {
                this.RingToneAndVideoSwitchSetting();
              }.onClick(() => {
                if (this.isPenglai) {
                  try {
                    promptAction.showToast({
                      message: $r('app.string.not_support_toast'),
                      duration: 2000
                    });
                  } catch (e) {
                    LogUtils.e(TAG, `showToast error ${e.message}`);
                  }
                }
              })
              .accessibilityLevel('no')
            }
            .borderRadius($r('sys.float.corner_radius_level10'))
            .backgroundColor(this.isFromExternal ? $r('sys.color.comp_background_list_card') :
              $r('sys.color.ohos_id_color_card_bg'))
            .divider({
              strokeWidth: '1px',
              color: $r('sys.color.comp_divider'),
              startMargin: $r('sys.float.padding_level6'),
              endMargin: $r('sys.float.padding_level6')
            })

            if (this.isShowFusionCallSwitch) {
              ListItemGroup() {
                ListItem() {
                  this.SubAdvanceOptions($r('app.string.improve_call_quality'))
                }
                .backgroundColor(this.isFromExternal ? $r('sys.color.comp_background_list_card') :
                  $r('sys.color.ohos_id_color_card_bg'))
                .borderRadius($r('sys.float.corner_radius_level10'))

                ListItem() {
                  this.FusionCallNotificationText();
                }
                .margin({
                  left: this.curBp === 'sm' ? 12 : $r('sys.float.padding_level0'),
                  right: this.curBp === 'sm' ? 12 : $r('sys.float.padding_level0'),
                  top: $r('sys.float.padding_level4')
                })
                .padding({
                  left: this.curBp === 'sm' ? $r('sys.float.padding_level0') : $r('sys.float.padding_level6'),
                  right: this.curBp === 'sm' ? $r('sys.float.padding_level0') : $r('sys.float.padding_level6'),
                })
              }
              .margin({
                top: $r('sys.float.padding_level6'),
              })
            }
          }
          .margin({
            top: this.isFromExternal ? $r('sys.float.padding_level4') : $r('sys.float.padding_level8')
          })
          .height('100%')
          .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
          .scrollBar(BarState.Off)
          .contentEndOffset(BOTTOM_MARGIN + this.naviIndicatorHeight)
          .clip(false)
        }
      }
      .margin({
        left: this.isFromExternal ? $r('sys.float.padding_level8') :
        CallColumnUtils.getInstance().getPaddingSpace(this.curBp),
        right: this.isFromExternal ? $r('sys.float.padding_level8') :
        CallColumnUtils.getInstance().getPaddingSpace(this.curBp)
      })
    }
    // .titleMode(this.isFromExternal ? HdsHdsNavDestinationTitleMode.MODAL : HdsHdsNavDestinationTitleMode.MINI)
    // .titleBar(TitleParams.MiniTitleParams($r('app.string.advance_options_title'),
    //     this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
    //     $r('sys.color.ohos_id_color_sub_background'), this.isCrossMarkExists))
    .title(this.myTitleBar)
    .backgroundColor(this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
      $r('sys.color.ohos_id_color_sub_background'))
    .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.KEYBOARD], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .onBackPressed(() => {
      LogUtils.i(TAG, 'onBackPressed');
      if (this.isSearchPush) {
        LogUtils.i(TAG, 'onBackPressed SearchPush');
        CallSettingGlobalContextHelper.getContext()
          .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT)
          .terminateSelf();
        return true;
      }
      return false;
    })
  }
  @Builder
  myTitleBar(){
    TitleBarLayout($r('app.string.advance_options_title'),
      this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
       $r('sys.color.ohos_id_color_sub_background'), this.isCrossMarkExists)
  }
}
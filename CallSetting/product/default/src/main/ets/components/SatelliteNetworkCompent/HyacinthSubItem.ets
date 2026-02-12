/**
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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
import {
  LogUtils,
  ReportUtil,
  SatelliteSimCardInfoStruct,
  CallSettingGlobalContextHelper,
  sharedPreferencesUtils,
  PrivacyStatement,
  Constants
} from '@ohos/common/CommonIndex';
import { call } from '@kit.TelephonyKit';
import { AlertDialog, CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import {
  getSatelliteModeKey,
  addSatelliteToggleStateListener,
  insert,
  querySatellite,
  removeSatelliteToggleStateListener,
} from '../../common/utils/SateToggleStateManager';
import {
  querySatelliteWithParam,
} from '../../common/utils/SateToggleStateManager';
import HyacinthDataShareManager from '../../manager/HyacinthDataShareManager';
import SimCardSelectedDialog from '../../common/dialog/SimCardSelectedDialog';
import { getShowName } from '../../model/SatelliteServiceSettingModel';
import { abilityAccessCtrl, Context, common } from '@kit.AbilityKit';
import {
  CALL_SETTING_SATELLITE_ABILITY_CONTEXT,
  IS_START_SERVICE,
  HYACINTH_DIALOG_TIPS,
  MAX_TIME_COUNT
} from '../../common/constant/CallSettingsConstant';
import { BusinessError, settings } from '@kit.BasicServicesKit';
import {
  HYACINTH_SIM_SHOW_NAME,
  SatelliteType,
  SATELLITE_KEY_SLOT_ID,
  SATELLITE_TOAST_DURATION,
  BatteryCapacityLevel,
  HYACINTH_LOCATION_ALLOWED
} from '../../common/constant/SatelliteSearchConst';
// import vsim from '@hms.telephony.vsim';
import ServiceExtensionContext from '@ohos.app.ability.common';
import { display, LengthMetrics, promptAction, window } from '@kit.ArkUI';
import { insertSatelliteNumber } from '../../datashareability/SatelliteDataShare';
import { isTablet } from '../../common/utils/DeviceTypeUtils';
import { isSupportRegionCard, saveCarrierType } from '../../model/SimManager';
import CommonEventManager from '@ohos.commonEventManager';
import { TrifoldManager } from '../../manager/TrifoldManager';
import SatelliteExpandDialog from './SatelliteExpandDialog';
import SystemParameterEnhance from '@ohos.systemParameterEnhance';
import ScreenAdapterUtils from '../../common/utils/ScreenAdapterUtils'
import SatelliteServiceSettingsVM from '../../viewModel/SatelliteServiceSettingsVM'
import { StringUtil } from '../../common/utils/StringUtil';
import SatelliteSearchManager from '../../manager/SatelliteSearchManager';
import { SatUsableTimeInfo } from '../../manager/SatelliteSearchManager';
import { reRequestLocation } from '../../common/utils/Utils';
import { geoLocationManager } from '@kit.LocationKit';

const TAG = 'HyacinthSubItem';

const SATELLITE_STATUS_BEIDOU_WORKING: number = 2;

@Component
export default struct HyacinthSubItem {
  @Consume('pathInfos') pathInfos: NavPathStack;
  @State subId: number = 1;
  @State title: Resource = $r('app.string.start_hyacinth_satellite_communications');
  @State controlSwitch: boolean = false;
  @State isOpenDialog: boolean = false;
  @State isSimActiveChange: boolean = false;
  @State mHyacinthSatelliteService: SatelliteServiceSettingsVM = SatelliteServiceSettingsVM.getInstance(
    SatelliteType.HYACINTH);
  @Prop nextTime: string = '';
  @Prop queryingOverTime: boolean = false;
  @ObjectLink satUsableTimeInfo: SatUsableTimeInfo[];
  @StorageProp(HYACINTH_LOCATION_ALLOWED) isLocationAllowed: boolean = false;
  @StorageLink(HYACINTH_SIM_SHOW_NAME) showName: Resource | string = $r('app.string.satellite_service_no_sim_card');
  @StorageLink('subtitleForHyacinth') subtitle: Resource = $r('app.string.hyacinth_satellite_service_no_available_time');
  @StorageLink('hyacinthSimCardInfoList') simCardInfoList: SatelliteSimCardInfoStruct[] = [];
  @StorageLink('isStartService') @Watch('closeService') isStartService: boolean = false;

  private showInSubWindow: boolean = !ScreenAdapterUtils.isNewFormFoldPhone();
  private subscriber: CommonEventManager.CommonEventSubscriber | undefined;
  private satelliteSwitch: boolean = false;
  private hyacinthDataShareManager: HyacinthDataShareManager = HyacinthDataShareManager.getInstance();

  private hyacinthContext = CallSettingGlobalContextHelper.getContext()
    .getValue<common.UIExtensionContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT);

  scroller: Scroller = new Scroller();

  airPlaneModeControllerConfirm: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.hyacinth_satellite_service_airplane_mode'),
      primaryButton: {
        value: $r('app.string.gotIt'),
        action: () => {
          this.airPlaneModeControllerConfirm.close();
          this.closeToggle();
        }
      },
    }),
    autoCancel: false,
    showInSubWindow: this.showInSubWindow,
    cancel: () => {
      this.closeToggle();
    }
  })

  vSimControllerConfirm: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.hyacinth_service_settings_skytone_mode'),
      primaryButton: {
        value: $r('app.string.gotIt'),
        action: () => {
          this.vSimControllerConfirm.close();
          this.closeToggle();
        }
      },
    }),
    autoCancel: false,
    showInSubWindow: this.showInSubWindow,
    cancel: () => {
      this.closeToggle();
    }
  })

  tianTongModeControllerConfirm: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.hyacinth_satellite_service_tiantong_mode'),
      primaryButton: {
        value: $r('app.string.gotIt'),
        action: () => {
          this.tianTongModeControllerConfirm.close();
          this.closeToggle();
        }
      },
    }),
    autoCancel: false,
    showInSubWindow: this.showInSubWindow,
    cancel: () => {
      this.closeToggle();
    }
  })

  hasCallControllerConfirm: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.hyacinth_satellite_service_enter_in_call'),
      primaryButton: {
        value: $r('app.string.gotIt'),
        action: () => {
          this.hasCallControllerConfirm.close();
          this.closeToggle();
        }
      },
    }),
    autoCancel: false,
    showInSubWindow: true,
    cancel: () => {
      this.closeToggle();
    }
  })

  exitHyacinthSatelliteService: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.exit_hyacinth_satellite_service_tips'),
      primaryButton: {
        value: $r('app.string.cancel_space'),
        action: () => {
          this.exitHyacinthSatelliteService.close();
          this.controlSwitch = true;
        }
      },
      secondaryButton: {
        value: $r('app.string.satellite_exit'),
        action: () => {
          LogUtils.i(TAG, `exit_hyacinth_satellite_service Value: 0 satelliteType: ${SatelliteType.HYACINTH}`);
          insert(0, this.hyacinthContext, SatelliteType.HYACINTH);
          this.exitHyacinthSatelliteService.close();
        }
      }
    }),
    autoCancel: false,
    showInSubWindow: this.showInSubWindow,
    cancel: () => {
      this.controlSwitch = true;
    }
  })

  noCardDialogController: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.hyacinth_satellite_service_no_sim_card'),
      primaryButton: {
        value: $r('app.string.gotIt'),
        action: () => {
          this.noCardDialogController.close();
          this.closeToggle();
        }
      }
    }),
    autoCancel: false,
    showInSubWindow: true,
    cancel: () => {
      this.closeToggle();
    }
  })

  noNoSupportRegionDialogController: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.hyacinth_satellite_service_no_region_card'),
      primaryButton: {
        value: $r('app.string.gotIt'),
        action: () => {
          this.noNoSupportRegionDialogController.close();
          this.closeToggle();
        }
      }
    }),
    autoCancel: false,
    showInSubWindow: this.showInSubWindow,
    cancel: () => {
      this.closeToggle();
    }
  })

  notAvailableHyacinthSatellites: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.hyacinth_satellites_not_available'),
      primaryButton: {
        value: $r('app.string.cancel_space'),
        action: () => {
          this.notAvailableHyacinthSatellites.close();
          this.closeToggle();
        }
      },
      secondaryButton: {
        value: $r('app.string.confim_space'),
        action: async () => {
          this.notAvailableHyacinthSatellites.close();
          await this.openHyacinthSatelliteDialog();
        }
      }
    }),
    autoCancel: false,
    showInSubWindow: this.showInSubWindow,
    cancel: () => {
      this.closeToggle();
    }
  })

  noPermissionHyacinth: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.hyacinth_request_location_permission'),
      primaryButton: {
        value: $r('app.string.cancel_space'),
        action: () => {
          this.noPermissionHyacinth.close();
          this.closeToggle();
        }
      },
      secondaryButton: {
        value: $r('app.string.hyacinth_location_enable_permission'),
        action: async () => {
          this.noPermissionHyacinth.close();
          reRequestLocation(this.hyacinthContext).then((result) => {
            if (result) {
              this.openHyacinthSatelliteDialog();
            } else {
              this.closeToggle();
            }
          });
        }
      }
    }),
    autoCancel: false,
    showInSubWindow: this.showInSubWindow,
    cancel: () => {
      this.closeToggle();
    }
  })

  openSatelliteDialog: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.start_hyacinth_satellite_communications'),
      contentBuilder: () => {
        this.buildContent();
      },
      buttons: [{
        value: $r('app.string.cancel_space'), buttonStyle: ButtonStyleMode.TEXTUAL, action: () => {
          this.closeToggle();
          ReportUtil.getInstance().reportOpenSatelliteDialogAction(0);
        }
      },
      {
        value: $r('app.string.enabled'),
        buttonStyle: ButtonStyleMode.EMPHASIZED,
        action: async () => {
          ReportUtil.getInstance().reportOpenSatelliteDialogAction(1);
          if (this.checkMultiWindow()) {
            return;
          }
          if (this.simCardInfoList === undefined || this.simCardInfoList === null ||
            this.simCardInfoList.length === 0) {
            this.noCardDialogController.open();
            ReportUtil.getInstance().reportOpenSatelliteCallIssue(1);
            return;
          }
          if (!await this.checkHasSupportRegionCard()) {
            this.noNoSupportRegionDialogController.open();
            ReportUtil.getInstance().reportOpenSatelliteCallIssue(1);
            return;
          }
          if (this.mHyacinthSatelliteService.hasTwoCard()) {
            let simInfo = this.simCardInfoList.find(
              (simInfo: SatelliteSimCardInfoStruct) => simInfo.isHyacinthChecked === true);
            if (simInfo === undefined) {
              this.isSimActiveChange = false;
              if (await this.getSupportRegionCardCount() > 1) {
                this.simCardDialogController.open();
              } else {
                let simInfo: SatelliteSimCardInfoStruct | undefined = await this.getSupportRegionCard();
                if (simInfo === undefined) {
                  return;
                }
                this.simCardAccept(simInfo);
              }
            } else {
              try {
                if (await isSupportRegionCard(simInfo.slotId)) {
                  this.controlSwitch = true;
                  SatelliteServiceSettingsVM.getInstance(SatelliteType.HYACINTH).startSatelliteService();
                } else {
                  this.noNoSupportRegionDialogController.open();
                }
              } catch (error) {
                LogUtils.e(TAG, `isSupportRegionCard failed: ${error?.code}`);
                this.noNoSupportRegionDialogController.open();
              }
            }
          } else {
            if (this.simCardInfoList !== undefined && this.simCardInfoList.length === 1) {
              let simInfo: SatelliteSimCardInfoStruct = this.simCardInfoList[0];
              let info: string[] = [`${simInfo.slotId}`, `${simInfo.showNumber}`, `${simInfo.isPreferences}`, `${simInfo.iMsi}`];
              LogUtils.i(TAG, 'openSatelliteDialog, simCardInfoList has one simInfo');
              try {
                if (!await isSupportRegionCard(simInfo.slotId)) {
                  this.noNoSupportRegionDialogController.open();
                  return;
                }
              } catch (error) {
                LogUtils.e(TAG, `isSupportRegionCard failed: ${error?.code}`);
                this.noNoSupportRegionDialogController.open();
              }
              sharedPreferencesUtils.init(this.hyacinthContext);
              sharedPreferencesUtils.saveToPreferences(HYACINTH_DIALOG_TIPS.HYACINTH_DIALOG_TIPS, info);
              insertSatelliteNumber(this.hyacinthContext, simInfo.showNumber);
            }
            this.openSateService(this.simCardInfoList[0]);
          }
        }
      }]
    }),
    autoCancel: false,
    showInSubWindow: this.showInSubWindow,
    cancel: () => {
      this.closeToggle();
    }
  })

  simCardDialogController: CustomDialogController = new CustomDialogController({
    builder: SimCardSelectedDialog({
      controlSwitch: $controlSwitch,
      isSimActiveChange: $isSimActiveChange,
      simCardInfoList: $simCardInfoList,
      accept: this.simCardAccept,
      satelliteType: SatelliteType.HYACINTH
    }),
    autoCancel: false,
    showInSubWindow: this.showInSubWindow,
    cancel: () => {
      if (!this.isSimActiveChange) {
        this.closeToggle();
      }
    }
  })

  @Builder
  expandDialog() {
    SatelliteExpandDialog();
  }

  openExpandDialog: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      contentBuilder: () => {
        this.expandDialog();
      },
      contentAreaPadding: { left: $r('sys.float.padding_level0'), right: $r('sys.float.padding_level0') },
      buttons: [
        {
          value: $r('app.string.gotIt'),
          fontColor: $r('sys.color.font_emphasize'),
          action: () => {
            this.openExpandDialog?.close();
            this.closeToggle();
          }
        }
      ]
    }),
    autoCancel: false,
    showInSubWindow: this.showInSubWindow,
    cancel: () => {
      this.closeToggle();
    }
  })

  closeService() {
    LogUtils.i(TAG, `closeService: ${this.isStartService}`);
    let options: PrivacyStatement = {
      isStartService: this.isStartService,
      agreeTime: new Date().valueOf(),
      privacyVersion: Constants.PRIVACY_STATEMENT_VERSION,
      appVersion: ReportUtil.getInstance().versionName
    }
    sharedPreferencesUtils.init(this.hyacinthContext);
    sharedPreferencesUtils.saveToPreferences(IS_START_SERVICE, options);
    if (!this.isStartService) {
      this.closeDialog();
    }
  }

  checkMultiWindow(): boolean {
    let context = CallSettingGlobalContextHelper.getContext()
      .getValue<ServiceExtensionContext.ServiceExtensionContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT);
    let windowMode: number = Number(settings.getValueSync(context, 'settings.windowMode', '-1'));
    LogUtils.i(TAG, `windowMode: ${windowMode}`);
    // if (windowMode === window.WindowStatusType.SPLIT_SCREEN || windowMode === window.WindowStatusType.FLOATING) {
    //   promptAction.showToast({
    //     message: isTablet() ? $r('app.string.hyacinth_satellite_service_settings_window_suggest') :
    //     $r('app.string.hyacinth_satellite_service_settings_window_mode'),
    //     duration: SATELLITE_TOAST_DURATION
    //   });
    //   this.closeToggle();
    //   return true;
    // }
    // if (windowMode === window.WindowStatusType.MINIMIZE && isTablet()) {
    //   promptAction.showToast({
    //     message: $r('app.string.hyacinth_satellite_service_settings_window_suggest'),
    //     duration: SATELLITE_TOAST_DURATION
    //   });
    //   this.closeToggle();
    //   return true;
    // }
    return false;
  }

  checkGmodel(): boolean {
    if (ScreenAdapterUtils.isTrifoldPhone() && !TrifoldManager.getInstance().isTrifold()) {
      this.openExpandDialog.open();
      return true;
    }
    return false;
  }

  closeDialog() {
    LogUtils.i(TAG, `closeDialog`);
    this.closeToggle();
    this.hasCallControllerConfirm?.close();
    this.openSatelliteDialog?.close();
    this.noCardDialogController?.close();
    this.noNoSupportRegionDialogController?.close();
    this.simCardDialogController?.close();
    this.airPlaneModeControllerConfirm?.close();
    this.tianTongModeControllerConfirm?.close();
    this.vSimControllerConfirm?.close();
  }

  /**
   * 关闭启动选项
   */
  closeToggle() {
    LogUtils.i(TAG, `closeToggle: ${this.controlSwitch}`);
    this.controlSwitch = false;
  }

  @Builder
  buildContent(): void {
    Scroll(this.scroller) {
      Text($r('app.string.satellite_service_settings_enable_tips'))
        .fontColor($r('sys.color.ohos_id_color_primary'))
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
    }.nestedScroll({ scrollForward: NestedScrollMode.PARALLEL, scrollBackward: NestedScrollMode.PARALLEL })
  }

  openSateService(simInfo: SatelliteSimCardInfoStruct | undefined) {
    LogUtils.i(TAG, 'openSateService');
    this.controlSwitch = true;
    this.saveToPreference(simInfo);
    SatelliteServiceSettingsVM.getInstance(SatelliteType.HYACINTH).startSatelliteService();
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
    .borderRadius(16)
    .constraintSize({ minHeight: $r('app.float.wh_value_48') })
    .opacity(1)
  }

  @Styles
  normalStyles() {
    .backgroundColor(Color.Transparent)
  }

  simCardAccept(simInfo: SatelliteSimCardInfoStruct) {
    LogUtils.i(TAG, 'simCardAccept');
    let showName = getShowName(simInfo);
    AppStorage.setOrCreate(HYACINTH_SIM_SHOW_NAME, showName);
    simInfo.isPreferences = true;
    let info: string[] = [`${simInfo.slotId}`, `${simInfo.showNumber}`, `${simInfo.isPreferences}`, `${simInfo.iMsi}`];
    let callSettingContext = CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT);
    sharedPreferencesUtils.init(callSettingContext);
    sharedPreferencesUtils.saveToPreferences(HYACINTH_DIALOG_TIPS.HYACINTH_DIALOG_TIPS, info);
    insertSatelliteNumber(callSettingContext, simInfo.showNumber);
    try {
      settings.setValueSync(callSettingContext, SATELLITE_KEY_SLOT_ID, String(simInfo.slotId));
    } catch (err) {
      LogUtils.e(TAG, `simCardAccept error: ${err?.code}, ${err?.message}`);
    }
    saveCarrierType(callSettingContext, simInfo.slotId);
    if (!this.isSimActiveChange) {
      SatelliteServiceSettingsVM.getInstance(SatelliteType.HYACINTH).startSatelliteService();
    }
  }

  /**
   * 保存选择的卡、以及运营商
   */
  saveToPreference(simInfo: SatelliteSimCardInfoStruct | undefined) {
    if (simInfo !== undefined) {
      let slotId = simInfo?.slotId;
      LogUtils.i(TAG, `saveToPreference: ${slotId}`);
      try {
        settings.setValueSync(this.hyacinthContext, SATELLITE_KEY_SLOT_ID, String(slotId));
      } catch (err) {
        LogUtils.e(TAG, `saveToPreference error: ${err?.code}, ${err?.message}`);
      }
      saveCarrierType(this.hyacinthContext, slotId);
    }
  }

  aboutToAppear(): void {
    this.mHyacinthSatelliteService.addSimStateActiveChangeListener((bol: boolean) => {
      LogUtils.i(TAG, `addSimStateActiveChangeListener: closeDialog: ${bol}`);
      if (!bol) {
        this.closeDialog();
      }
    });
    if (this.subId === 1) {
      LogUtils.i(TAG, 'aboutToAppear addHyacinthDataShareListener');
      this.hyacinthDataShareManager.addHyacinthDataShareListenerCallback((data: number) => {
        LogUtils.i(TAG, `addHyacinthDataShareListener Listener: ${data}`);
        this.handleControlSwitch(data);
        if (data === 0) {
          this.exitHyacinthSatelliteService?.close();
        }
      }, SatelliteType.HYACINTH);
      this.querySatellite();
      this.subscribeSatelliteEvent();
    }
    this.addFoldStatusListen();
  }

  querySatellite() {
    querySatellite(this.hyacinthContext, (data: number) => {
      LogUtils.i(TAG, `querySatellite: ${data}`);
      this.handleControlSwitch(data);
    }, SatelliteType.HYACINTH);
  }

  aboutToDisappear(): void {
    if (this.subId === 1) {
      this.unsubscribe();
    }
    this.removeFoldStatusListen();
  }

  public subscribeSatelliteEvent() {
    let satelliteEventInfo: CommonEventManager.CommonEventSubscribeInfo = {
      events: ['event.custom.satellite.ACTION_SATELLITE_DIALOG_CLOSE'],
      publisherPermission: 'ohos.permission.SET_TELEPHONY_STATE'
    };
    CommonEventManager.createSubscriber(satelliteEventInfo,
      (err: BusinessError, commonEventSubscriber: CommonEventManager.CommonEventSubscriber) => {
      if (err) {
        LogUtils.e(TAG, `subscribeSatelliteEvent: createSubscriber err: ${err?.code}`);
        return;
      }
      this.subscriber = commonEventSubscriber
      CommonEventManager.subscribe(commonEventSubscriber,
        (err: BusinessError, data: CommonEventManager.CommonEventData) => {
        if (err) {
          LogUtils.e(TAG, `subscribeSatelliteEvent: callback err: ${err?.code}`);
          return;
        }
        this.exitHyacinthSatelliteService?.close();
        this.querySatellite();
      });
    });
  }

  public unsubscribe() {
    if (this.subscriber && this.subscriber !== undefined) {
      CommonEventManager.unsubscribe(this.subscriber, (err) => {
        if (err?.code !== 0) {
          LogUtils.i(TAG, `commonEvent.unsubscribe err: ${err?.code}`);
        }
      });
    }
  }

  handleControlSwitch(data: number) {
    LogUtils.i(TAG, 'handleControlSwitch data = ' + data);
    this.controlSwitch = data === 1;
    this.satelliteSwitch = data === 1;
    if (this.controlSwitch) {
      this.isStartService = true;
    }
    this.mHyacinthSatelliteService.isStartSatelliteService = data === 1;
  }

  async openDialog() {
    LogUtils.i(TAG, 'openDialog');
    if (this.checkMultiWindow()) {
      return;
    }
    if (this.checkGmodel()) {
      return;
    }
    let context = CallSettingGlobalContextHelper.getContext()
      .getValue<ServiceExtensionContext.ServiceExtensionContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT);
    let airplaneMode: number = Number(settings.getValueSync(context, 'settings.telephony.airplanemode', '-1'));
    LogUtils.i(TAG, `airplaneMode: ${airplaneMode}`);
    // let isVSimOn: boolean = vsim.getVSimStatus().isVSimEnabled;
    // LogUtils.i(TAG, `isVSimOn: ${isVSimOn}`);
    let beiDouMode: number = Number(SystemParameterEnhance.getSync('persist.telephony.satellite.satelliteStatus', '0'));
    LogUtils.i(TAG, `beiDouMode: ${beiDouMode}`);

    let tianTongMode = await querySatelliteWithParam(getSatelliteModeKey(SatelliteType.TIAN_TONG),
      this.hyacinthContext);
    LogUtils.i(TAG, 'tianTongMode: ' + tianTongMode);

    if (!this.simCardInfoList === undefined || this.simCardInfoList === null || this.simCardInfoList.length === 0) {
      this.noCardDialogController.open();
      ReportUtil.getInstance().reportOpenSatelliteCallIssue(Constants.UE_IS_NOT_CTCARD);
    } else if (call.hasCallSync()) {
      this.hasCallControllerConfirm.open();
      ReportUtil.getInstance().reportOpenSatelliteCallIssue(Constants.UE_INCALL);
    } else if (airplaneMode == 1) {
      this.airPlaneModeControllerConfirm.open();
      ReportUtil.getInstance().reportOpenSatelliteCallIssue(Constants.UE_IN_AIRPLANE);
    // } else if (isVSimOn) {
    //   this.vSimControllerConfirm.open();
    //   ReportUtil.getInstance().reportOpenSatelliteCallIssue(Constants.UE_TIANJITONG_OPEND);
    } else if (!await this.checkHasSupportRegionCard()) {
      this.noNoSupportRegionDialogController.open();
      ReportUtil.getInstance().reportOpenSatelliteCallIssue(Constants.UE_IS_NOT_CTCARD);
    } else if (beiDouMode == SATELLITE_STATUS_BEIDOU_WORKING) {
      this.closeToggle();
      promptAction.showToast({
        message: $r('app.string.using_beidou_toast'),
        duration: SATELLITE_TOAST_DURATION
      });
    } else if (tianTongMode === 1) {
      this.tianTongModeControllerConfirm.open();
    } else {
      if (this.nextTime === '') {
        this.notAvailableHyacinthSatellites.open();
      } else if (this.satUsableTimeInfo != undefined && this.satUsableTimeInfo.length > 0) {
        let satelliteAvailable = false;
        for (let i = 0; i < this.satUsableTimeInfo.length; i++) {
          if (i >= MAX_TIME_COUNT) {
            break;
          }
          let info = this.satUsableTimeInfo[i];
          let now = new Date().getTime() / 1000;
          // 已超过结束时间则弹窗提示
          if (now >= info.startTime && now <= info.endTime) {
            satelliteAvailable = true;
          }
        }
        if (!satelliteAvailable) {
          this.notAvailableHyacinthSatellites.open();
        } else {
          await this.openHyacinthSatelliteDialog();
        }
      } else {
        await this.openHyacinthSatelliteDialog();
      }
    }
    ReportUtil.getInstance().reportOpenSatelliteSimCardInfo(this.simCardInfoList);
  }

  private isSimCardChecked(): boolean {
    let index = this.simCardInfoList.findIndex((simInfo: SatelliteSimCardInfoStruct) =>
      simInfo.isHyacinthChecked === true);
    return index !== -1;
  }

  private async openHyacinthSatelliteDialog() {
    let simInfo = this.simCardInfoList.find((simInfo: SatelliteSimCardInfoStruct) =>
      simInfo.isHyacinthChecked === true);
    if (simInfo) {
      try {
        if (!await isSupportRegionCard(simInfo.slotId)) {
          this.noNoSupportRegionDialogController.open();
          ReportUtil.getInstance().reportOpenSatelliteCallIssue(Constants.UE_IS_NOT_CTCARD);
        } else {
          this.openSatelliteDialog.open();
          ReportUtil.getInstance().reportSatelliteOpenDialog();
        }
      } catch (error) {
        LogUtils.e(TAG, `isSupportRegionCard failed: ${error?.code}`);
        this.noNoSupportRegionDialogController.open();
      }
    } else {
      this.openSatelliteDialog.open();
      ReportUtil.getInstance().reportSatelliteOpenDialog();
    }
  }

  private onFoldChangeCallBack = (foldStatus: display.FoldStatus) => {
    LogUtils.i(TAG, 'on--foldStatusChangefoldStatus=' + foldStatus);
    AppStorage.setOrCreate('foldStatus', foldStatus);
  };

  private addFoldStatusListen() {
    // try {
    //   let foldStatus = display.getFoldStatus();
    //   AppStorage.setOrCreate<number>('foldStatus', foldStatus);
    //   display.on('foldStatusChange', this.onFoldChangeCallBack);
    // } catch (exception) {
    //   LogUtils.e(TAG, 'addFoldStatusListen Failed code');
    // }
  }

  private removeFoldStatusListen() {
    // try {
    //   display.off('foldStatusChange', this.onFoldChangeCallBack);
    // } catch (exception) {
    //   LogUtils.e(TAG, 'removeFoldStatusListen Failed code');
    // }
  }

  async checkHasSupportRegionCard(): Promise<boolean> {
    try {
      for (let i = 0; i < this.simCardInfoList.length; i++) {
        if (await isSupportRegionCard(this.simCardInfoList[i].slotId)) {
          LogUtils.i(TAG, 'checkSupportRegionCard return true');
          return true;
        }
      }
    } catch (error) {
      LogUtils.e(TAG, `isSupportRegionCard failed: ${error?.code}`);
    }
    LogUtils.i(TAG, 'checkSupportRegionCard return false');
    return false;
  }

  async getSupportRegionCardCount(): Promise<number> {
    let result: number = 0;
    try {
      for (let i = 0; i < this.simCardInfoList.length; i++) {
        if (await isSupportRegionCard(this.simCardInfoList[i].slotId)) {
          result += 1;
        }
      }
    } catch (error) {
      LogUtils.e(TAG, `isSupportRegionCard failed: ${error?.code}`);
    }
    LogUtils.i(TAG, 'getSupportRegionCard count = ' + result);
    return result;
  }

  async getSupportRegionCard(): Promise<SatelliteSimCardInfoStruct | undefined> {
    let result: SatelliteSimCardInfoStruct | undefined = undefined;
    try {
      for (let i = 0; i < this.simCardInfoList.length; i++) {
        if (await isSupportRegionCard(this.simCardInfoList[i].slotId)) {
          return this.simCardInfoList[i];
        }
      }
    } catch (error) {
      LogUtils.e(TAG, `isSupportRegionCard failed: ${error?.code}`);
    }
    return result;
  }

  @Builder
  hyacinthSatelliteSwitch(title: Resource, subtitle: Resource) {
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
              start: LengthMetrics.vp(12),
              top: LengthMetrics.vp(10)
            })
        }
        .margin({ right: $r('sys.float.ohos_id_text_margin_horizontal') })

        Row() {
          if (this.queryingOverTime) {
            LoadingProgress()
              .width('24vp')
              .height('24vp')
              .margin({
                top:-2,
                right: 2,
              })
          }
          Text(this.nextTime ? this.nextTime : subtitle)
            .textAlign(TextAlign.Start)
            .fontSize(14)
            .fontColor($r('sys.color.font_secondary'))
            .fontWeight(FontWeight.Regular)
            .fontFamily('HarmonyHeiTi')
            .constraintSize({ minHeight: 19, maxWidth: '100%' })
            .layoutWeight(1)
            .margin({
              bottom: LengthMetrics.vp(10)
            })
        }
        .margin({
          top: 2,
          left: 12,
          right: $r('sys.float.ohos_id_text_margin_horizontal'),
        })
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Top)
      }
    }
    .layoutWeight(1)

    Row() {
      Toggle({ type: ToggleType.Switch, isOn: this.controlSwitch })
        .width(36)
        .height(20)
        .enabled(true)
        .margin({ end: LengthMetrics.vp(12) })
        .onChange((isOn) => {
          LogUtils.i(TAG, `onChange: toggle isOn: ${this.controlSwitch}`)
          ReportUtil.getInstance().reportHyacinthSwitch(this.controlSwitch ? 1 : 0);
          if (isOn === this.controlSwitch) {
            return;
          }
          if (this.controlSwitch) {
            if (this.satelliteSwitch) {
              this.controlSwitch = false;
              this.exitHyacinthSatelliteService.open();
              ReportUtil.getInstance().reportEnterSatelliteCall(2);
            }
          } else {
            this.controlSwitch = true;
            AppStorage.setOrCreate('isStartService', true);
            this.openDialog();
            ReportUtil.getInstance().reportEnterSatelliteCall(1);
          }
        })
    }
    .justifyContent(FlexAlign.Center)
    .width('48vp')
    .height('48vp')
  }

  build() {
    Column() {
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        if (this.subId === 1 && this.subtitle) {
          this.hyacinthSatelliteSwitch(this.title, this.subtitle);
        }

        if (this.subId === 2) {
          Text(this.title)
            .textStyle()
          Row() {
            Text(this.showName)
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .fontFamily('HarmonyHeiTi')
              .fontWeight(FontWeight.Regular)
              .lineHeight(14)
              .margin({
                end: LengthMetrics.vp((this.simCardInfoList !== undefined &&
                  this.simCardInfoList.length === 2) ? 4 : 0)
              })

            Image($r('app.media.ic_public_arrow_right'))
              .fillColor($r('sys.color.ohos_id_color_fourth'))
              .height($r('app.float.wh_value_24'))
              .width($r('app.float.wh_value_12'))
              .draggable(false)
              .matchTextDirection(true)
              .visibility((this.simCardInfoList !== undefined && this.simCardInfoList.length === 2) ?
              Visibility.Visible : Visibility.None)
          }
          .margin({ end: LengthMetrics.vp(12) })
        }
        if (this.subId === 3) {
          Text(this.title)
            .textStyle()
          Image($r('app.media.ic_public_arrow_right'))
            .fillColor($r('sys.color.ohos_id_color_fourth'))
            .height($r('app.float.wh_value_24'))
            .width($r('app.float.wh_value_12'))
            .margin({ end: LengthMetrics.vp(12) })
            .matchTextDirection(true)
            .draggable(false)
        }
      }
      .constraintSize({ minHeight: $r('app.float.wh_value_48') })
      .margin({ top: 4, bottom: 4 })
    }
    .onClick(() => {
      if (this.subId === 2) {
        if (this.simCardInfoList !== undefined && this.simCardInfoList.length === 2) {
          this.isSimActiveChange = true;
          this.simCardDialogController.open();
          LogUtils.i(TAG, 'onclick simCardDialogController open.');
        }
      } else if (this.subId === 3) {
        // 运营资料刷新
        SatelliteServiceSettingsVM.getInstance(SatelliteType.HYACINTH).jumpPhoneWidget();
        ReportUtil.getInstance().reportClickCommonQuestion();
      }
    })
    .constraintSize({ minHeight: 56 })
    .borderRadius($r('sys.float.corner_radius_level10'))
    .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
  }
}

@Extend(Text)
function textStyle() {
  .fontSize($r('sys.float.ohos_id_text_size_body1'))
  .fontColor($r('sys.color.ohos_id_color_primary'))
  .fontWeight(FontWeight.Medium)
  .fontFamily('HarmonyHeiTi')
  .margin({ start: LengthMetrics.vp(12) })
}
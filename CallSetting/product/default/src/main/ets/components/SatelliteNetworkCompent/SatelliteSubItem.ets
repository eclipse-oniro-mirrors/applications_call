/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
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
  Constants,
  CallSettingGlobalContextHelper,
  sharedPreferencesUtils,
  ReportUtil,
  SatelliteSimCardInfoStruct,
  PrivacyStatement
} from '@ohos/common/CommonIndex';
import SatelliteToggleSelectedVM from '../../viewModel/SatelliteServiceSettingsVM';
import { call } from '@kit.TelephonyKit';
import { AlertDialog, CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import { addSatelliteToggleStateListener, insert, querySatellite,
  getSatelliteModeKey,
  querySatelliteWithParam,
  removeSatelliteToggleStateListener } from '../../common/utils/SateToggleStateManager';
import * as CallSettingsConstant from '../../common/constant/CallSettingsConstant';
import SimCardSelectedDialog from '../../common/dialog/SimCardSelectedDialog';
import { getShowName } from '../../model/SatelliteServiceSettingModel';
import { common } from '@kit.AbilityKit';
import {
  CALL_SETTING_SATELLITE_ABILITY_CONTEXT,
  CELLULAR_NETWORK_NOTIFY_ID
} from '../../common/constant/CallSettingsConstant';
import { notificationManager } from '@kit.NotificationKit';
import { BusinessError, settings } from '@kit.BasicServicesKit';
import { SATELLITE_KEY_SLOT_ID,
  SatelliteType,
  SATELLITE_TOAST_DURATION } from '../../common/constant/SatelliteSearchConst';
import { display, LengthMetrics, promptAction, window } from '@kit.ArkUI';
// import vsim from '@hms.telephony.vsim';
import ServiceExtensionContext from '@ohos.app.ability.common';
import { insertSatelliteNumber } from '../../datashareability/SatelliteDataShare';
import { isTablet } from '../../common/utils/DeviceTypeUtils';
import { isSupportRegionCard, saveCarrierType } from '../../model/SimManager';
import ScreenAdapterUtils from '../../common/utils/ScreenAdapterUtils';
import CommonEventManager from '@ohos.commonEventManager';
import SatelliteExpandDialog from './SatelliteExpandDialog';
import { TrifoldManager } from '../../manager/TrifoldManager';
import SystemParameterEnhance from '@ohos.systemParameterEnhance';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';

const TAG = 'SatelliteSubItem';

const SATELLITE_STATUS_BEIDOU_WORKING: number = 2;

// 三折或平板设置当前屏幕方向window.Orientation.LANDSCAPE
const CHANGE_WINDOW_ORIENTATION: string = 'changeWindowOrientation';
// 三折当前当前屏幕方向window.Orientation.LANDSCAPE
const KEEP_WINDOW_ORIENTATION: string = 'keepWindowOrientation';
// 三折或平板恢复屏幕方向
const RESET_WINDOW_ORIENTATION: string = 'resetWindowOrientation';

let satelliteEventInfo: CommonEventManager.CommonEventSubscribeInfo = {
  events: ['event.custom.satellite.ACTION_SATELLITE_DIALOG_CLOSE'],
  publisherPermission: 'ohos.permission.SET_TELEPHONY_STATE'
};


@Component
export default struct SatelliteSubItem {
  @Consume('pathInfos') pathInfos: NavPathStack;
  // 页面栈关联的session
  @Consume('session') session: UIExtensionContentSession;
  @State subId: number = 1;
  @State title: Resource = $r('app.string.satellite_service_network_descriptions');
  @State controlSwitch: boolean = false;
  @StorageLink('showName') showName: Resource | string = $r('app.string.satellite_service_no_sim_card');
  @State mSatelliteServiceSettingsVM: SatelliteToggleSelectedVM = SatelliteToggleSelectedVM.getInstance();
  @State isOpenDialog: boolean = false;
  @StorageLink('simCardInfoList') simCardInfoList: SatelliteSimCardInfoStruct[] = [];
  @State radioIndex: number = -1;
  @State isSimActiveChange: boolean = false;
  @StorageLink('isStartService') @Watch('closeService') isStartService: boolean = false;
  private showInSubWindow: boolean = !ScreenAdapterUtils.isNewFormFoldPhone();
  private satelliteSwitch: boolean = false;
  private subscriber: CommonEventManager.CommonEventSubscriber | undefined;
  scroller: Scroller = new Scroller();

  airPlaneModeControllerConfirm: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.satellite_service_settings_airplane_mode'),
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
      content: $r('app.string.satellite_service_settings_skytone_mode'),
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

  dialogHasCallControllerConfirm: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.enter_in_call'),
      primaryButton: {
        value: $r('app.string.gotIt'),
        action: () => {
          this.dialogHasCallControllerConfirm.close();
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
  exitSatelliteService: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.exit_satellite_service_tips'),
      primaryButton: {
        value: $r('app.string.cancel_space'),
        action: () => {
          this.exitSatelliteService.close();
          this.controlSwitch = this.satelliteSwitch;
        }
      },
      secondaryButton: {
        value: $r('app.string.satellite_exit'),
        action: () => {
          LogUtils.i(TAG, `exit_satellite_service Value: 0 satelliteType: default`);
          insert(0, CallSettingGlobalContextHelper.getContext()
            .getValue<common.UIExtensionContext>(CallSettingsConstant.CALL_SETTING_SATELLITE_ABILITY_CONTEXT));
          this.exitSatelliteService.close();
          notificationManager.cancel(CELLULAR_NETWORK_NOTIFY_ID);
        }
      }
    }),
    autoCancel: false,
    showInSubWindow: this.showInSubWindow,
    cancel: () => {
      this.controlSwitch = this.satelliteSwitch;
    }
  })
  noCardDialogController: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.satellite_service_no_sim_card_descriptions'),
      primaryButton: {
        value: $r('app.string.gotIt'),
        action: () => {
          this.noCardDialogController.close();
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

  noNoSupportRegionDialogController: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.satellite_service_no_region_card_descriptions'),
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

  // 向settings传递消息，设置横竖屏
  private setWindowOrientation(action: string) {
    try {
      this.session?.sendData({
        action: action
      });
      LogUtils.i(TAG, 'setWindowOrientation success');
    } catch (err) {
      LogUtils.e(TAG, `setWindowOrientation err: ${err?.code},  message:${err?.message}`);
    }
  }

  private addFoldStatusListener(): void {
    if (!ScreenAdapterUtils.isTrifoldPhone()) {
      return;
    }
    ScreenAdapterUtils.registerFoldStatusChange(this.onFoldChangeWindowOrientationCallBack);
  }

  private removeFoldStatusListener(): void {
    if (!ScreenAdapterUtils.isTrifoldPhone()) {
      return;
    }
    ScreenAdapterUtils.unRegisterFoldStatusChange(this.onFoldChangeWindowOrientationCallBack);
  }

  private onFoldChangeWindowOrientationCallBack = (status: number) => {
    this.setWindowOrientation(KEEP_WINDOW_ORIENTATION);
  };

  hyacinthModeControllerConfirm: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.tiantong_satellite_service_hyacinth_mode'),
      primaryButton: {
        value: $r('app.string.gotIt'),
        action: () => {
          this.hyacinthModeControllerConfirm.close();
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

  openSatelliteDialog: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.start_skycom_satellite_communications'),
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
            LogUtils.i(TAG,'set open setting')
            try {
              let context = CallSettingGlobalContextHelper.getContext()
                .getValue<ServiceExtensionContext.ServiceExtensionContext>(CallSettingsConstant
                  .CALL_SETTING_SATELLITE_ABILITY_CONTEXT);
              let isOn = settings.getValueSync(context, Constants.TIAN_TONG_SATELLITE_OPEN_EVENT,
                Constants.TIAN_TONG_SATELLITE_STATE_CLOSE);
              settings.setValueSync(context, Constants.TIAN_TONG_SATELLITE_OPEN_EVENT,
                isOn === Constants.TIAN_TONG_SATELLITE_STATE_CLOSE ? Constants.TIAN_TONG_SATELLITE_STATE_OPEN :
                Constants.TIAN_TONG_SATELLITE_STATE_CLOSE);
            } catch (err) {
              LogUtils.e(TAG, `settings set tian_tong_satellite_open error: ${err?.code} ${err?.message}`);
            }
            ReportUtil.getInstance().reportOpenSatelliteDialogAction(1);
            if (this.checkMultiWindow()) {
              return;
            }
            if (!this.simCardInfoList === undefined || this.simCardInfoList === null ||
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
            if (this.mSatelliteServiceSettingsVM.hasTwoCard()) {
              let simInfo = this.simCardInfoList.find(
                (simInfo: SatelliteSimCardInfoStruct) => simInfo.isChecked === true);
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
                    SatelliteToggleSelectedVM.getInstance().startSatelliteService();
                  } else {
                    this.noNoSupportRegionDialogController.open();
                  }
                } catch (error) {
                  LogUtils.e(TAG, `isSupportRegionCard failed: ${error?.code}`);
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
                }
                let context = CallSettingGlobalContextHelper.getContext()
                  .getValue<common.UIExtensionContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT);
                sharedPreferencesUtils.init(context);
                sharedPreferencesUtils.saveToPreferences(
                  CallSettingsConstant.SATELLITE_DIALOG_TIPS.SATELLITE_DIALOG_TIPS, info);
                insertSatelliteNumber(context, simInfo.showNumber);
              }
              this.openSateService(this.simCardInfoList[0]);
            }
            LogUtils.i(TAG, 'setWindowOrientation is changeWindowOrientation');
            this.setWindowOrientation(CHANGE_WINDOW_ORIENTATION);
            this.addFoldStatusListener();
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
      accept: this.simCardAccept
    }),
    autoCancel: false,
    showInSubWindow: this.showInSubWindow,
    cancel: () => {
      if (!this.isSimActiveChange) {
        this.closeToggle();
      }
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
    let context = CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT);
    sharedPreferencesUtils.init(context);
    sharedPreferencesUtils.saveToPreferences(CallSettingsConstant.IS_START_SERVICE, options);
    if (!this.isStartService) {
      this.closeDialog();
    }
  }

  checkMultiWindow(): boolean {
    let context = CallSettingGlobalContextHelper.getContext()
      .getValue<ServiceExtensionContext.ServiceExtensionContext>(CallSettingsConstant
        .CALL_SETTING_SATELLITE_ABILITY_CONTEXT);
    let windowMode: number = Number(settings.getValueSync(context, 'settings.windowMode', '-1'));
    LogUtils.i(TAG, 'windowMode:' + windowMode);
    if (windowMode == window.WindowStatusType.SPLIT_SCREEN || windowMode == window.WindowStatusType.FLOATING ||
      (windowMode == window.WindowStatusType.MINIMIZE && isTablet())) {
      promptAction.showToast({
        message: isTablet() ? $r('app.string.satellite_service_settings_window_suggest') :
        $r('app.string.satellite_service_settings_window_mode'),
        duration: SATELLITE_TOAST_DURATION
      });
      this.closeToggle();
      return true;
    }
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
    this.dialogHasCallControllerConfirm?.close();
    this.openSatelliteDialog?.close();
    this.noCardDialogController?.close();
    this.noNoSupportRegionDialogController?.close();
    this.simCardDialogController?.close();
    this.airPlaneModeControllerConfirm?.close();
    this.vSimControllerConfirm?.close();
    this.hyacinthModeControllerConfirm?.close();
  }

  closeToggle() {
    LogUtils.i(TAG, 'closeToggle:' + JSON.stringify(this.controlSwitch))
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
    SatelliteToggleSelectedVM.getInstance().startSatelliteService();
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
    LogUtils.i(TAG, `simCardAccept ${simInfo.slotId}`);
    let showName = getShowName(simInfo);
    AppStorage.setOrCreate('showName', showName);
    simInfo.isPreferences = true;
    let info: string[] = [`${simInfo.slotId}`, `${simInfo.showNumber}`, `${simInfo.isPreferences}`, `${simInfo.iMsi}`];
    LogUtils.i(TAG, `isOpened simCardAccept`);
    let context = CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT);
    sharedPreferencesUtils.init(context);
    sharedPreferencesUtils.saveToPreferences(CallSettingsConstant.SATELLITE_DIALOG_TIPS.SATELLITE_DIALOG_TIPS, info);
    insertSatelliteNumber(context, simInfo.showNumber);
    try {
      settings.setValueSync(context, SATELLITE_KEY_SLOT_ID, String(simInfo.slotId));
    } catch (err) {
      LogUtils.e(TAG, `simCardAccept error: ${err?.code} ${err?.message}`);
    }
    saveCarrierType(context, simInfo.slotId);
    if (!this.isSimActiveChange) {
      SatelliteToggleSelectedVM.getInstance().startSatelliteService();
    }
  }

  saveToPreference(simInfo: SatelliteSimCardInfoStruct | undefined) {
    if (simInfo !== undefined) {
      let slotId = simInfo?.slotId;
      LogUtils.i(TAG, 'saveToPreference ' + JSON.stringify(slotId));
      let context = CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIExtensionContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT);
      try {
        settings.setValueSync(context, SATELLITE_KEY_SLOT_ID, String(slotId));
      } catch (err) {
        LogUtils.e(TAG, `saveToPreference error: ${err?.code} ${err?.message}`);
      }
      saveCarrierType(context, slotId);
    }
  }

  aboutToAppear(): void {
    this.mSatelliteServiceSettingsVM.addSimStateActiveChangeListener((bol: boolean) => {
      LogUtils.i(TAG, 'addSimStateActiveChangeListener: closeDialog:' + JSON.stringify(bol));
      if (!bol) {
        this.closeDialog();
      }
    });
    if (this.subId === 1) {
      LogUtils.i(TAG, 'aboutToAppear addSatelliteToggleStateListener');
      addSatelliteToggleStateListener(CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIExtensionContext>(CallSettingsConstant.CALL_SETTING_SATELLITE_ABILITY_CONTEXT),
        (data: number) => {
          LogUtils.i(TAG, 'addSatelliteToggleStateListener:' + JSON.stringify(data));
          this.handleControlSwitch(data);
          if (data == 0) {
            this.exitSatelliteService?.close();
            this.setWindowOrientation(RESET_WINDOW_ORIENTATION);
            this.removeFoldStatusListener();
          }
        });

      this.querySatellite();
      this.subscribeSatelliteEvent();
    }
    this.addFoldStatusListen();
  }

  querySatellite() {
    querySatellite(CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(CallSettingsConstant.CALL_SETTING_SATELLITE_ABILITY_CONTEXT),
      (data: number) => {
        LogUtils.i(TAG, 'querySatellite:' + JSON.stringify(data));
        this.handleControlSwitch(data);
      })
  }

  aboutToDisappear(): void {
    if (this.subId === 1) {
      this.unsubscribe();
    }
    this.removeFoldStatusListen();
  }

  /**
   * Register to listen to the change event of the satellite.
   */
  public subscribeSatelliteEvent() {
    CommonEventManager.createSubscriber(satelliteEventInfo, (err: BusinessError, commonEventSubscriber:
      CommonEventManager.CommonEventSubscriber) => {
      if (err) {
        LogUtils.e(TAG, 'subscribeSatelliteEvent: createSubscriber err=' + JSON.stringify(err));
        return;
      }
      this.subscriber = commonEventSubscriber
      CommonEventManager.subscribe(commonEventSubscriber, (err: BusinessError,
        data: CommonEventManager.CommonEventData) => {
        if (err) {
          LogUtils.e(TAG, 'subscribeSatelliteEvent: callback err=' + JSON.stringify(err));
          return;
        }
        this.exitSatelliteService?.close();
        this.querySatellite();
      });
    });
  }

  /**
   * unsubscribe
   */
  public unsubscribe() {
    if (this.subscriber && this.subscriber !== undefined) {
      CommonEventManager.unsubscribe(this.subscriber, (err) => {
        if (err?.code !== 0) {
          LogUtils.i(TAG, 'commonEvent.unsubscribe err: %s' + JSON.stringify(err))
        }
      });
    }
  }

  handleControlSwitch(data: number) {
    LogUtils.i(TAG, `handleControlSwitch data = ${data}`);
    this.satelliteSwitch = data === 1;
    this.controlSwitch = data === 1;
    if (this.controlSwitch) {
      this.isStartService = true;
    }
    this.mSatelliteServiceSettingsVM.isStartSatelliteService = data === 1;
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
      .getValue<common.UIExtensionContext>(CallSettingsConstant.CALL_SETTING_SATELLITE_ABILITY_CONTEXT);
    let windowMode: number = Number(settings.getValueSync(context, 'settings.windowMode', '-1'));
    LogUtils.i(TAG, 'windowMode:' + windowMode);
    let airplanemode: number = Number(settings.getValueSync(context, 'settings.telephony.airplanemode', '-1'));
    LogUtils.i(TAG, 'airplanemode: ' + airplanemode);
    // let isVSimOn: boolean = vsim.getVSimStatus().isVSimEnabled;
    // LogUtils.i(TAG, 'isVSimOn: ' + isVSimOn);
    let isBeidouWorking: number = Number(SystemParameterEnhance.getSync('persist.telephony.satellite.satelliteStatus', '0'));
    LogUtils.i(TAG, 'isBeidouWorking: ' + isBeidouWorking);

    let hyacinthMode = await querySatelliteWithParam(getSatelliteModeKey(SatelliteType.HYACINTH), context);
    LogUtils.i(TAG, 'hyacinthMode: ' + hyacinthMode);

    if (this.simCardInfoList === undefined || this.simCardInfoList === null || this.simCardInfoList.length === 0) {
      this.noCardDialogController.open();
      ReportUtil.getInstance().reportOpenSatelliteCallIssue(Constants.UE_IS_NOT_CTCARD);
    } else if (call.hasCallSync()) {
      this.dialogHasCallControllerConfirm.open();
      ReportUtil.getInstance().reportOpenSatelliteCallIssue(Constants.UE_INCALL);
    } else if (airplanemode == 1) {
      this.airPlaneModeControllerConfirm.open();
      ReportUtil.getInstance().reportOpenSatelliteCallIssue(3);
    // } else if (isVSimOn) {
    //   this.vSimControllerConfirm.open();
    //   ReportUtil.getInstance().reportOpenSatelliteCallIssue(4);
    } else if (!await this.checkHasSupportRegionCard()) {
      this.noNoSupportRegionDialogController.open();
      ReportUtil.getInstance().reportOpenSatelliteCallIssue(Constants.UE_IS_NOT_CTCARD);
    } else if (isBeidouWorking == SATELLITE_STATUS_BEIDOU_WORKING) {
      this.closeToggle();
      promptAction.showToast({
        message: $r('app.string.using_beidou_toast'),
        duration: SATELLITE_TOAST_DURATION
      });
    } else if (hyacinthMode === 1) {
      this.hyacinthModeControllerConfirm.open();
    } else {
      let simInfo = this.simCardInfoList.find((simInfo: SatelliteSimCardInfoStruct) => simInfo.isChecked === true);
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
        }
      } else {
        this.openSatelliteDialog.open();
        ReportUtil.getInstance().reportSatelliteOpenDialog();
      }
    }
    ReportUtil.getInstance().reportOpenSatelliteSimCardInfo(this.simCardInfoList);
  }

  private onFoldChangeCallBack = (foldStatus: display.FoldStatus) => {
    LogUtils.i(TAG, 'on--foldStatusChangefoldStatus=' + foldStatus);
    AppStorage.setOrCreate('foldStatus', foldStatus);
  };

  private addFoldStatusListen() {
    try {
      let foldStatus = display.getFoldStatus()
      AppStorage.setOrCreate<number>('foldStatus', foldStatus);
      display.on('foldStatusChange', this.onFoldChangeCallBack)
    } catch (exception) {
      LogUtils.e(TAG, 'addFoldStatusListen Failed code' + JSON.stringify(exception));
    }
  }

  private removeFoldStatusListen() {
    try {
      display.off('foldStatusChange', this.onFoldChangeCallBack);
    } catch (exception) {
      LogUtils.e(TAG, 'removeFoldStatusListen Failed code' + JSON.stringify(exception));
    }
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

  build() {
    Column() {
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Text(this.title)
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor($r('sys.color.ohos_id_color_primary'))
          .fontWeight(FontWeight.Medium)
          .fontFamily('HarmonyHeiTi')
          .margin({ start: LengthMetrics.vp(12) })

        if (this.subId === 1) {
          Toggle({ type: ToggleType.Switch, isOn: this.controlSwitch })
            .width(36)
            .height(20)
            .enabled(true)
            .margin({ end: LengthMetrics.vp(12) })
            .onChange((isOn) => {
              LogUtils.i(TAG, `onChange: toggle isOn: ${this.controlSwitch}`)
              if (isOn == this.controlSwitch) {
                return;
              }
              if (this.controlSwitch && this.satelliteSwitch) {
                this.controlSwitch = false;
                this.exitSatelliteService.open();
                ReportUtil.getInstance().reportEnterSatelliteCall(2);
              } else {
                this.controlSwitch = true;
                AppStorage.setOrCreate('isStartService', true);
                this.openDialog();
                ReportUtil.getInstance().reportEnterSatelliteCall(1);
              }
            })
        }

        if (this.subId === 2) {
          Row() {
            Text(this.showName)
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .fontFamily('HarmonyHeiTi')
              .fontWeight(FontWeight.Regular)
              .lineHeight(14)
              .margin({ end: LengthMetrics.vp((this.simCardInfoList !== undefined &&
                this.simCardInfoList.length === 2) ? 4 : 0) })
            Image($r('app.media.ic_public_arrow_right'))
              .fillColor($r('sys.color.ohos_id_color_fourth'))
              .height($r('app.float.wh_value_24'))
              .width($r('app.float.wh_value_12'))
              .draggable(false)
              .visibility((this.simCardInfoList !== undefined && this.simCardInfoList.length === 2) ?
              Visibility.Visible : Visibility.None)
              .matchTextDirection(true)
          }
          .margin({ end: LengthMetrics.vp(12) })
        }
        if (this.subId === 3) {
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
          LogUtils.i(TAG, 'onclick simCardDialogController open: ');
        }
      } else if (this.subId === 3) {
        this.mSatelliteServiceSettingsVM.jumpPhoneWidget();
        ReportUtil.getInstance().reportClickCommonQuestion();
      }
    })
    .constraintSize({ minHeight: 56 })
    .borderRadius($r('sys.float.corner_radius_level10'))
    .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
    .accessibilityDescription(this.subId === 1 ? ' ' : '')
  }
}
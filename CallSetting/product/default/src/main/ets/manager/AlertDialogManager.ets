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

import { display, window } from '@kit.ArkUI';
import { SATELLITE_SERVICE_CONTEXT, CELLULAR_NETWORK_NOTIFY_ID } from '../common/constant/CallSettingsConstant';
import { LogUtils, CallSettingGlobalContextHelper, ReportUtil, Constants } from '@ohos/common/CommonIndex';
import { ALERT_DIALOG } from '../common/constant/SatelliteSearchConst';
import SatelliteSearchManager from './SatelliteSearchManager';
import ServiceExtensionContext from '@ohos.app.ability.common';
import notificationManager from '@ohos.notificationManager';
import Base, { BusinessError } from '@ohos.base';
import image from '@ohos.multimedia.image';
import WantAgent from '@ohos.app.ability.wantAgent';
import { common } from '@kit.AbilityKit';
import { settings } from '@kit.BasicServicesKit';
import { setFloatWindowKeepScreen } from '../common/utils/WindowUtils';

type Window = window.Window | null;

/**
 * @file: Alert dialog manager
 */

const TAG = 'AlertDialogManager';

/**
 * class AlertDialogManager
 */
export default class AlertDialogManager {

  private static sAlertDialogManager: AlertDialogManager;

  public static SATELLITE_SEARCH_TIMEOUT: number = 60;

  public static SATELLITE_CLOSE_TIMEOUT: number = 5;

  public static TYPE_CLOSE_SATELLITE_TIPS = 1;

  public static TYPE_CLOSE_SATELLITE_BY_CALL_STATE = 2;

  public static TYPE_CLOSE_SATELLITE_BY_TIMEOUT = 3;

  public static TYPE_SERVICE_STATUS_TIMEOUT = 4;

  public static ERROR_CODE_NOT_ACTIVATED_SIM = 5;

  public static ERROR_CODE_NOT_OPENED_ROAMING = 6;

  public static ERROR_CODE_NOT_OPENED_TIANDIWINGCARD = 7;

  public static ERROR_CODE_NOT_SUPPORT_CARD = 8;

  public static ERROR_CODE_OTHERS = 9;

  public static IS_ALERT_DIALOG_WINDOW_SHOW: boolean = false;

  private typeList: number[] = [
    AlertDialogManager.TYPE_CLOSE_SATELLITE_TIPS,
    AlertDialogManager.TYPE_SERVICE_STATUS_TIMEOUT,
    AlertDialogManager.TYPE_CLOSE_SATELLITE_BY_CALL_STATE,
    AlertDialogManager.TYPE_CLOSE_SATELLITE_BY_TIMEOUT,
    AlertDialogManager.ERROR_CODE_NOT_ACTIVATED_SIM,
    AlertDialogManager.ERROR_CODE_NOT_OPENED_ROAMING,
    AlertDialogManager.ERROR_CODE_NOT_OPENED_TIANDIWINGCARD,
    AlertDialogManager.ERROR_CODE_NOT_SUPPORT_CARD,
    AlertDialogManager.ERROR_CODE_OTHERS,
  ];

  public dialogType: number = 0;

  private dialogCallbacks: Function[] = [];

  private hyacinthContext = CallSettingGlobalContextHelper.getContext()
    .getValue<common.UIExtensionContext>(SATELLITE_SERVICE_CONTEXT);

  /**
   * create satellite dialog manager
   *
   * @returns {Object} - SatelliteDialogManager object
   */
  public static getInstance(): AlertDialogManager {
    if (!AlertDialogManager.sAlertDialogManager) {
      AlertDialogManager.sAlertDialogManager = new AlertDialogManager()
    }
    return AlertDialogManager.sAlertDialogManager;
  }

  /**
   * Create alert dialog window
   */
  public async createAlertDialogWindow(): Promise<Window> {
    LogUtils.i(TAG, 'Create alert dialog window.');
    let alertDialogWindow: Window = null;
    let config: window.Configuration = {
      name: ALERT_DIALOG,
      windowType: SatelliteSearchManager.getInstance().getWindowType(),
      ctx: CallSettingGlobalContextHelper.getContext()
        .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT)
    };
    try {
      alertDialogWindow = await window.createWindow(config);
      setFloatWindowKeepScreen(alertDialogWindow, true, ALERT_DIALOG);
      const displayWidth = display.getDefaultDisplaySync().width;
      const displayHeight = display.getDefaultDisplaySync().height;
      await alertDialogWindow.resize(displayWidth, displayHeight);
      await alertDialogWindow.setUIContent('pages/AlertDialogPage');
      await alertDialogWindow.showWindow();
      AlertDialogManager.IS_ALERT_DIALOG_WINDOW_SHOW = true;
      LogUtils.i(TAG, 'Succeeded in creating the alert dialog window.');
    } catch (err) {
      LogUtils.e(TAG, 'Failed to create the alert dialog window, Cause: ' + JSON.stringify(err));
    }
    return alertDialogWindow;
  }

  /**
   * Close current alert dialog window
   */
  public async closeAlertDialogWindow(): Promise<void> {
    LogUtils.i(TAG, 'closeAlertDialogWindow is called')
    let alertDialogWindow: Window = null;
    try {
      alertDialogWindow = window.findWindow(ALERT_DIALOG);
      if (alertDialogWindow) {
        await alertDialogWindow.destroyWindow();
      }
      AlertDialogManager.IS_ALERT_DIALOG_WINDOW_SHOW = false;
    } catch (err) {
      LogUtils.e(TAG, 'Failed to close the alert dialog window, Cause: ' + JSON.stringify(err))
    }
  }

  /**
   * show alertDialog window
   */
  public async showDialogWindow(): Promise<void> {
    try {
      // only alertDialog window is present can show
      if (AlertDialogManager.IS_ALERT_DIALOG_WINDOW_SHOW) {
        window.findWindow(ALERT_DIALOG)?.showWindow();
        LogUtils.i(TAG, 'show window');
      }
    } catch (err) {
      LogUtils.e(TAG, 'Failed to showDialogWindow, Cause: ' + JSON.stringify(err))
    }
  }

  /**
   * Find alert dialog window by window name
   *
   * @returns alert dialog window
   */
  private findAlertDialogWindow(): Window {
    let alertDialogWindow: Window = null;
    try {
      alertDialogWindow = window.findWindow(ALERT_DIALOG);
      LogUtils.i(TAG, 'Succeeded in finding the alert dialog window.');
    } catch (err) {
      LogUtils.i(TAG, 'Failed to find the alert dialog window, Cause: ' + JSON.stringify(err));
    }
    return alertDialogWindow;
  }

  addDialogCallback(fn: Function): void {
    this.dialogCallbacks.push(fn);
  }

  removeDialogCallback(fn: Function): void {
    let index: number = this.dialogCallbacks.indexOf(fn);
    if (index < 0 || index >= this.dialogCallbacks.length) {
      return;
    }
    this.dialogCallbacks.splice(index, 1);
    LogUtils.i(TAG, 'removeDialogCallback index = ' + index);
  }

  public updateDialogListeners(type: number) {
    this.dialogCallbacks.forEach((fn: Function) => {
      fn(type);
    });
  }

  public closeNotLinkSatelliteDialog(): void {
    if (this.dialogType === AlertDialogManager.TYPE_CLOSE_SATELLITE_BY_TIMEOUT) {
      LogUtils.i(TAG, 'closeNotLinkSatelliteDialog is called');
      this.closeAlertDialogWindow();
    }
  }

  public showDialogByDialogType(type: number) {
    LogUtils.i(TAG, 'showDialogByDialogType type = ' + type);
    let index: number = this.typeList.indexOf(type);
    if (index < 0 || index >= this.typeList.length) {
      return;
    }
    this.dialogType = type;
    const alertDialogWindow: Window = this.findAlertDialogWindow();
    if (!alertDialogWindow) {
      this.createAlertDialogWindow();
      return;
    }
    this.createDialogByType();
  }

  public createDialogByType() {
    LogUtils.i(TAG, 'createDialogByType type = ' + this.dialogType);
    switch (this.dialogType) {
      case AlertDialogManager.TYPE_CLOSE_SATELLITE_TIPS:
        this.exitSatelliteDialog();
        break;
      case AlertDialogManager.TYPE_CLOSE_SATELLITE_BY_TIMEOUT:
      case AlertDialogManager.ERROR_CODE_NOT_ACTIVATED_SIM:
      case AlertDialogManager.ERROR_CODE_NOT_OPENED_ROAMING:
      case AlertDialogManager.ERROR_CODE_NOT_OPENED_TIANDIWINGCARD:
      case AlertDialogManager.ERROR_CODE_NOT_SUPPORT_CARD:
      case AlertDialogManager.ERROR_CODE_OTHERS:
        this.updateDialogListeners(this.dialogType);
        break;
      case AlertDialogManager.TYPE_SERVICE_STATUS_TIMEOUT:
        this.sysStatusTimeoutDialog();
        break;
      case AlertDialogManager.TYPE_CLOSE_SATELLITE_BY_CALL_STATE:
        this.closeSatelliteByCallDialog();
        break;
    }
  }
  
  closeAlertDialogByType(displayType: number) {
    if (!AlertDialogManager.IS_ALERT_DIALOG_WINDOW_SHOW) {
      return;
    }
    switch (displayType) {
      case AlertDialogManager.TYPE_CLOSE_SATELLITE_TIPS:
        this.closeAlertDialogWindow();
        break;
      default:
        break;
    }
  }

  // 关闭蒲公英提示框
  private exitSatelliteDialog() {
    AlertDialog.show({
      isModal: true,
      message: SatelliteSearchManager.getInstance().isTianTong() ? $r('app.string.exit_satellite_service_tips') :
      $r('app.string.exit_hyacinth_satellite_service_tips'),
      autoCancel: false,
      alignment: DialogAlignment.Default,
      gridCount: 4,
      showInSubWindow: false,
      offset: {
        dx: 0, dy: -16
      },
      primaryButton: {
        value: $r('app.string.cancel_space'),
        action: () => {
          this.closeAlertDialogWindow()
        }
      },
      secondaryButton: {
        value: $r('app.string.satellite_exit'),
        action: () => {
          if (SatelliteSearchManager.getInstance().isTianTong()) {
            LogUtils.i(TAG,'set close setting')
            try {
              let context: Context = CallSettingGlobalContextHelper.getContext()
                .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT);
              let isOn = settings.getValueSync(context, Constants.TIAN_TONG_SATELLITE_CLOSE_EVENT,
                Constants.TIAN_TONG_SATELLITE_STATE_CLOSE);
              settings.setValueSync(context, Constants.TIAN_TONG_SATELLITE_CLOSE_EVENT,
                isOn === Constants.TIAN_TONG_SATELLITE_STATE_CLOSE ? Constants.TIAN_TONG_SATELLITE_STATE_OPEN :
                Constants.TIAN_TONG_SATELLITE_STATE_CLOSE);
            } catch (err) {
              LogUtils.e(TAG, `settings set tian_tong_satellite_close error: ${err?.code} ${err?.message}`);
            }
          }
          LogUtils.i(TAG, 'exitSatelliteDialog set close setting')
          SatelliteSearchManager.getInstance().finishSatellite(false);
          this.closeAlertDialogWindow();
          notificationManager.cancel(CELLULAR_NETWORK_NOTIFY_ID);
          ReportUtil.getInstance().reportSatelliteCallQuit(Constants.UE_INITIATIVE_QUIT);
        }
      },
      cancel: () => {
        this.closeAlertDialogWindow();
      }
    })
  }

  // 卫星服务timeout异常弹框
  private sysStatusTimeoutDialog() {
    LogUtils.i(TAG, 'sysStatusTimeoutDialog');
    AlertDialog.show({
      isModal: true,
      message:  SatelliteSearchManager.getInstance().isTianTong() ? $r('app.string.satellite_exited_for_system_error') :
      $r('app.string.hyacinth_satellite_exited_for_system_error'),
      autoCancel: false,
      alignment: DialogAlignment.Default,
      gridCount: 4,
      showInSubWindow: false,
      textStyle: { wordBreak: WordBreak.BREAK_WORD },
      offset: {
        dx: 0, dy: -16
      },
      primaryButton: {
        value: $r('app.string.gotIt'),
        action: () => {
          LogUtils.i(TAG, 'sysStatusTimeoutDialog primaryButton is called');
          this.closeAlertDialogWindow();
          CallSettingGlobalContextHelper.getContext()
            .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT)?.terminateSelf();
        }
      },
      cancel: () => {
        LogUtils.i(TAG, 'sysStatusTimeoutDialog cancel is called');
        this.closeAlertDialogWindow();
        CallSettingGlobalContextHelper.getContext()
          .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT)?.terminateSelf();
      }
    })
  }

  private closeSatelliteByCallDialog() {
    LogUtils.i(TAG, 'closeSatelliteByCallDialog');
    AlertDialog.show({
      isModal: true,
      message:  $r('app.string.enter_in_call'),
      autoCancel: false,
      alignment: DialogAlignment.Default,
      gridCount: 4,
      showInSubWindow: false,
      offset: {
        dx: 0, dy: -16
      },
      primaryButton: {
        value: $r('app.string.gotIt'),
        action: () => {
          LogUtils.i(TAG, 'closeSatelliteByCallDialog primaryButton is called');
          this.closeAlertDialogWindow();
          CallSettingGlobalContextHelper.getContext()
            .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT)?.terminateSelf();
        }
      },
      cancel: () => {
        LogUtils.i(TAG, 'closeSatelliteByCallDialog cancel is called');
        this.closeAlertDialogWindow();
        CallSettingGlobalContextHelper.getContext()
          .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT)?.terminateSelf();
      }
    })
  }

  private getStringFromResourceArgs(context: Context, resource: Resource, param?: string | number): string {
    if (param) {
      return context.resourceManager.getStringSync(resource.id, param);
    } else {
      return context.resourceManager.getStringSync(resource.id);
    }
  }

  public async createNotifyLeftIcon(context: Context): Promise<PixelMap | undefined> {
    let notifyIcon: PixelMap | undefined = undefined;
    try {
      let fileData = await context.resourceManager.getMediaContent(SatelliteSearchManager.getInstance().isTianTong() ? $r('app.media.ic_notification_new') : $r('app.media.ic_notification_hyacinth'));
      let imageSource = image.createImageSource(fileData.buffer);
      if (imageSource !== undefined) {
        notifyIcon = await imageSource.createPixelMap();
        imageSource.release().catch((error: BusinessError) => {
          LogUtils.e(TAG, 'release imageSource error: ' + JSON.stringify(error));
        })
      }
    } catch (err) {
      LogUtils.e(TAG, `filed: err = ${JSON.stringify(err)}`);
    }
    return notifyIcon;
  }

  public async pushSatelliteSearchTimeoutNotification(callback: Function) {
    let notifyLeftIcon: PixelMap | undefined = undefined;
    let context: Context = CallSettingGlobalContextHelper.getContext()
      .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT);
    notifyLeftIcon = await this.createNotifyLeftIcon(context);

    let wantAgentInfo: WantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: 'com.ohos.callsetting',
          abilityName: 'com.ohos.callsetting.CallSettingAbility',
          uri: SatelliteSearchManager.getInstance().isTianTong() ?
            'SatelliteNetworkExtensionAbility' : 'HyacinthExtensionAbility'
        }
      ],
      actionType: WantAgent.OperationType.START_ABILITIES,
      requestCode: 100,
      wantAgentFlags: [WantAgent.WantAgentFlags.CONSTANT_FLAG]
    }
    const wantAgent = await WantAgent.getWantAgent(wantAgentInfo);
    let notificationRequest: notificationManager.NotificationRequest = {
      id: 1,
      notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: this.getStringFromResourceArgs(context, SatelliteSearchManager.getInstance().isTianTong() ?
          $r('app.string.satellite_notification_title') : $r('app.string.hyacinth_satellite_notification_title')),
          text: SatelliteSearchManager.getInstance().isTianTong() ?
            context.resourceManager.getStringSync($r('app.string.not_link_satellite_auto_exit_notification_Text'), 60):
            this.hyacinthContext.resourceManager
              .getPluralStringValueSync($r('app.plural.not_link_hyacinth_satellite_auto_exit_notification_Text').id, 60)
        }
      },
      smallIcon: notifyLeftIcon,
      isFloatingIcon: true,
      wantAgent: wantAgent
    };

    let publishCallback = (err: Base.BusinessError): void => {
      if (err) {
        LogUtils.i(TAG, `publish failed, code is ${err.code}, message is ${err.message}`);
      } else {
        LogUtils.i(TAG, 'publish success');
      }
      callback();
    }
    notificationManager.publish(notificationRequest, publishCallback);
  }
}
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

import account_osAccount from '@ohos.account.osAccount';
import observer from '@ohos.telephony.observer';
import { call, radio, sim } from '@kit.TelephonyKit';
import { LogUtils, CallSettingGlobalContextHelper, ReportUtil, Constants } from '@ohos/common/CommonIndex';
import {
  addAirPlaneModeListener,
  offCallStateChange,
  offSignalInfoChange,
  onCallStateChange,
  onSignalInfoChange,
  removeAirPlaneModeListener
} from '../model/RegisterStateApiForSatellite';
import { isDevicePortrait, isTablet } from '../common/utils/DeviceTypeUtils'
import {
  EMIT_NEW_FOLD_PHONE_EXTERNAL_EVENT_ID,
  SATELLITE_SERVICE_CONTEXT,
  CELLULAR_NETWORK_NOTIFY_ID,
  CLOSE_SATELLITE_NETWORK_BUTTON,
  IGNORE_NOTIFY_BUTTON
} from '../common/constant/CallSettingsConstant';
import { DetectCellularNetwork } from '../common/data/commonData';
import SatelliteFloatWindowManager from './SatelliteFloatWindowManager';
import SatelliteDialogManager from './SatelliteDialogManager';
import SatelliteStrongNotifyManager from './SatelliteStrongNotifyManager';
import {
  ERROR_CODE_NOT_ACTIVATED_SIM,
  ERROR_CODE_NOT_OPENED_ROAMING,
  ERROR_CODE_NOT_OPENED_TIANDIWINGCARD,
  ERROR_CODE_NOT_SUPPORT_CARD,
  ERROR_CODE_OTHERS,
  MAIN_ACCOUNT_ID,
  SATELLITE_CONNECTING_OFF,
  SATELLITE_CONNECTING_ON,
  SATELLITE_SWITCH_ON,
  SATELLITE_TOAST_AIRPLANE_CODE,
  SYS_STATUS_CP_TIMEOUT,
  SYS_STATUS_DEFAULT,
  SYS_STATUS_HOT_PLUG,
  SYS_STATUS_NWREJ,
  SYS_STATUS_RESOURCE_READY,
  SYS_STATUS_SATELLITE_CONNECTING,
  SYS_STATUS_SEARCHING_SATELLITE,
  SYS_STATUS_SEARCH_SATELLITE_FAIL,
  SYS_STATUS_SEARCH_SATELLITE_SUCC,
  SYS_STATUS_SIMST_OFF,
  SYS_STATUS_WAIT_CALIBRATING,
  SYS_STATUS_WAIT_LOADING,
  SYS_STATUS_WAIT_BLOCKING,
  WAIT_STATE_TIME,
  SENDING_TIME,
  RECEIVER_STATUS_RECEIVING,
  SatelliteState,
  SatelliteOperationType,
  SYS_STATUS_NETWORK_REGED,
  SYS_STATUS_NETWORK_UNREGED,
  SYS_STATUS_SATELLITE_KEEPING,
  SYS_STATUS_SERVICE_DIED,
  SYS_STATUS_UPDATE_DELTA,
  SYS_STATUS_CELLULAR_NETWORK,
  WAIT_STATE_TIME_CACTUS,
  SYS_STATUS_ENHANCES_CONNECT,
  SATELLITE_CONNECTING_STRONG_N0TIFY,
  SATELLITE_CLOSE_DIALOG_CODE,
  SATELLITE_FLOAT_WINDOW,
  SATELLITE_DIALOG,
  ALERT_DIALOG,
  EVENT_SATELLITE_WINDOW_SHOW,
  EVENT_SATELLITE_WINDOW_HIDE,
  SatelliteType,
  SYS_DISCONNECT,
  SATELLITE_SWITCH_OFF,
  SatelliteFromType
} from '../common/constant/SatelliteSearchConst';
import AlertDialogManager from './AlertDialogManager';
import * as SatelliteLocation from '../common/utils/SatelliteLocation';
import {
  notifySatelliteInfo,
  notifySatelliteStatus,
  queryNextOverTime,
  notifySmcSatelliteInfo,
  offSatelliteInfo,
  offSatelliteStatus,
  offSmcSatelliteInfo,
  startSatelliteService, stopSatelliteService,
  notifyOverTimeInfo,
  offOverTimeInfo} from '../common/model/SatelliteServiceApi';
import {
  getSatelliteModeKey,
  insert,
  insertConnectState,
  ON_SETTING_SATELLITE_SERVICE_URI,
  QUERY_SATELLITE_MODE_KEY,
  SETTING_SATELLITE_SERVICE_URI} from '../common/utils/SateToggleStateManager';
import { BusinessError, emitter, settings } from '@kit.BasicServicesKit';
import CommonEventManager from '@ohos.commonEventManager';
import { JSON } from '@kit.ArkTS';
import { Queue } from '@kit.ArkTS';
import sensor from '@ohos.sensor'
import ServiceExtensionContext from '@ohos.app.ability.common';
import { geoLocationManager } from '@kit.LocationKit';
import { isCorrectionEnable, isSupportCactus, isSupportDandelion } from '../common/utils/Utils';
import { ConfigurationConstant, contextConstant, wantAgent } from '@kit.AbilityKit';
import data_preferences from '@ohos.data.preferences';
import preferences from '@ohos.data.preferences';
import { notificationManager } from '@kit.NotificationKit';
import { UIExtensionContentSession } from '@kit.AbilityKit';
import { dataShare } from '@kit.ArkData';
import { registerSimStateChangeForSlotId } from '../model/RegisterSimStateApi';
import SatelliteUtils from '../common/utils/SatelliteUtils';
import { display, window } from '@kit.ArkUI';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import NewFoldScreenAlertDialogManager from './NewFoldScreenAlertDialogManager';
import ScreenAdapterUtils from '../common/utils/ScreenAdapterUtils';
import { TrifoldManager } from './TrifoldManager';
import { commonEventManager } from '@kit.BasicServicesKit';
import { SystemMode } from '../model/SystemMode';
import { createSubscriber, subscribeEvent, unSubscribeEvent, publishSatelliteCallHangupEvent} from '../common/utils/CommonFunUtil';
import { IMediaPlayer } from '../components/IMediaPlayere';
import VibrateUtil from '../common/utils/VibrateUtil';
import { DateUtil } from '../common/utils/DateUtil';
import { NotifyOverTimeEnum } from '../components/SatelliteCommonData';


/**
 * @file: Satellite search manager
 */
const TAG = 'SatelliteSearchManager';

// 未与卫星连接最长60s
const TYPE_CLOSE_SATELLITE_BY_TIMEOUT: number = 60;

// delete count
const DELETE_COUNT_ONE = 1;

const INVALID_SLOT_ID = -1;

const COUNTDOWN_TIMER: number = 1 * 1000;

const DEFAULT_CONVERT_DATA: number = 361;

const EXTREME_SAVE_MODE: number = 603;

const OPEN_OVER_TIME_INFO_LISTENER_SUCCESS: number = 1;
const OPEN_OVER_TIME_INFO_LISTENER_FAIL: number = -1;

export const QUERY_SATELLITE_MODE_TIANTONG_KEY = 'satellite_mode_switch_tiantong';
export const QUERY_SATELLITE_MODE_HYACINTH_KEY = 'satellite_mode_switch_hyacinth';

let primarySubscriberQueue: Queue<CommonEventManager.CommonEventSubscriber> = new Queue();

let satelliteSubscribeInfo: CommonEventManager.CommonEventSubscribeInfo = {
  events: ['event.custom.satellite.ACTION_SATELLITE_CONNECT'],
  publisherPermission: 'ohos.permission.SET_TELEPHONY_STATE'
};

let shutdownSubscribeInfo:CommonEventManager.CommonEventSubscribeInfo = {
  events: ['usual.event.SHUTDOWN']
};

let batteryModeSubscribeInfo:CommonEventManager.CommonEventSubscribeInfo = {
  events: ['usual.event.POWER_SAVE_MODE_CHANGED']
};

let SATELLITE_LOCATION_REFERENCE_NAME: string = 'SATELLITE_LOCATION';

let SATELLITE_LOCATION_REFERENCE_KEY: string = 'location_mode';

/**
 * class SatelliteSearchManager
 */
export default class SatelliteSearchManager {
  private static sSatelliteSearchManager: SatelliteSearchManager;
  private mSatelliteDialogManager: SatelliteDialogManager = SatelliteDialogManager.getInstance();
  private mSatelliteFloatWindowManager: SatelliteFloatWindowManager = SatelliteFloatWindowManager.getInstance();
  private mStrongNotifyWindowManager: SatelliteStrongNotifyManager = SatelliteStrongNotifyManager.getInstance();
  private mAlertDialogManager: AlertDialogManager = AlertDialogManager.getInstance();
  private mNewFoldScreenAlertDialogManager = NewFoldScreenAlertDialogManager.getInstance();
  private mCacheSatelliteData : SatelliteData = SatelliteData.getInstance();
  private mCurrentStatus: number = SYS_STATUS_DEFAULT;
  private mSlotId: number = -1;
  private mSignal: number = 0;
  private mServiceState: number = 0;
  private mAlertState: number = 0;
  private statusCallbacks: Function[] = [];
  private satelliteDataCallbacks: Function[] = [];
  private alertStatebacks: Function[] = [];
  private locationCallbacks: Function[] = [];
  private deviceDirectionCallbacks: Function[] = [];
  private isFirst: boolean = false;

  private isFromMeetime: boolean = false;

  private mConvertLongitude: number = DEFAULT_CONVERT_DATA;

  private mConvertLatitude: number = DEFAULT_CONVERT_DATA;

  private isLandscape: boolean = false;

  private uiOrientation?: number = ConfigurationConstant.Direction.DIRECTION_VERTICAL;

  // 连接中倒计时，存储于manager中，界面切换是可以来这里读取值
  private connectTime: number = WAIT_STATE_TIME;

  private defaultConnectTime: number = WAIT_STATE_TIME;

  // 时间倒计时，存储于manager 中，界面切换是可以来这里读取值
  private time: number = SENDING_TIME;

  private strongNotifyTime: number = 0;

  private strongNotifyRingTime: number = 0;

  private isStrongNotifyRing: boolean = false;

  private showReConnect: boolean = false;

  private showReCalibrate: boolean = false;

  private showReSearch: boolean = false;

  private satelliteSearchTime = TYPE_CLOSE_SATELLITE_BY_TIMEOUT;

  private satelliteSearchTimerId: number = -1;
  private mDisplayOrientation: number = 0;

  public satelliteSearchStarted: boolean = false;

  private sysStatusCpTimeout: boolean = false;

  private closeSatelliteByCallState: boolean = false;

  private dataShareHelper: dataShare.DataShareHelper | undefined = undefined;
  private startConnectTime: number = 0;
  private loadingStartTime: number = 0;
  // is satellite dialog show or not
  private isSatelliteDialogShow = false;
  // is float window show or not
  private isFloatWindowShow = false;
  // is strong notify window show or not
  private isStrongNotifyWindowShow = false;

  private foldStatus = display.FoldStatus.FOLD_STATUS_UNKNOWN;

  private accountManager: account_osAccount.AccountManager = account_osAccount.getAccountManager();

  private session: UIExtensionContentSession | undefined = undefined;
  private satelliteNeedEndCallbacks: Function[] = [];

  private satelliteConnectTimeCallbacks: Function[] = [];

  private isConnecting: boolean = false;

  private connectTimerId: number = -1;

  private shouldResetFloatWindow: boolean = false;

  private mediaPlayer: IMediaPlayer = new IMediaPlayer(CallSettingGlobalContextHelper.getContext()
    .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT));

  private windowShowEvent?: commonEventManager.CommonEventSubscriber;
  private windowHideEvent?: commonEventManager.CommonEventSubscriber;

  private satelliteType: number = SatelliteType.TIAN_TONG; // 默认天通

  private _satUsableTimeList: SatUsableTimeInfo[] = [];
  private _inSatUsableTIme: boolean = false;
  private _applyOverTimeCallback: Function = () => {};
  private _queryOverTimeCallback: Function = () => {};

  public timeOutId: number = -1;

  public static getInstance(): SatelliteSearchManager {
    if (!SatelliteSearchManager.sSatelliteSearchManager) {
      SatelliteSearchManager.sSatelliteSearchManager = new SatelliteSearchManager()
    }
    return SatelliteSearchManager.sSatelliteSearchManager;
  }

  //绑定寻星服务
  public async bindSatelliteService() {
    LogUtils.i(TAG, 'bindSatelliteService is called');
    this.mSlotId = await this.getSlotId();
    LogUtils.i(TAG, `startSatelliteService slotId = ${this.mSlotId}, satelliteType = ${this.satelliteType}`);
    let result = await startSatelliteService(this.mSlotId, this.satelliteType);
    if (result == 0) {
      this.addSatelliteStatusCallback();
      this.addSatelliteDataCallBack();
      this.satelliteType === SatelliteType.HYACINTH && SatelliteSearchManager.getInstance().openOverTimeInfoListener();
      ReportUtil.getInstance().satelliteUseStartTime = new Date().valueOf();
    }
    await this.registerSignalInfoChange();
    await this.registerAccelerometerListener();
  }

  public async queryNextOverTime(): Promise<number> {
    return new Promise(async (resolve, reject) => {
      try {
        let res = await queryNextOverTime();
        resolve(res);
      } catch (error) {
        LogUtils.e(TAG, `queryNextOverTime failed! msg=${error.message}`);
        resolve(-1);
      }
    })
  }

  public set inSatUsableTIme(flag: boolean) {
    this._inSatUsableTIme = flag;
  }

  public get inSatUsableTIme(): boolean {
    return this._inSatUsableTIme;
  }

  public set satUsableTimeList(list: SatUsableTimeInfo[]) {
    this._satUsableTimeList = list;
  }

  public get satUsableTimeList(): SatUsableTimeInfo[] {
    return this._satUsableTimeList;
  }

  private addSatelliteStatusCallback() {
    try {
      notifySatelliteStatus(async (serviceStatusInfo: SatelliteStatus) => {
        LogUtils.i(TAG, 'addSatelliteStatusCallback service status:' + serviceStatusInfo.serviceStatus +
          'service cause:' + serviceStatusInfo.cause + 'service alertState:' + serviceStatusInfo.alertState +
          ' mCurrentStatus:' + this.mCurrentStatus);
        if (serviceStatusInfo.serviceStatus == SYS_STATUS_RESOURCE_READY) {
          this.mConvertLongitude = serviceStatusInfo.convertLongitude;
          this.mConvertLatitude = serviceStatusInfo.convertLatitude;
          SatelliteLocation.updateLocation();
          this.updateLocationListeners();
          this.updateStatusByService();
        } else if (serviceStatusInfo.serviceStatus == SYS_STATUS_HOT_PLUG ||
          serviceStatusInfo.serviceStatus == SYS_STATUS_SIMST_OFF) {
          LogUtils.i(TAG, 'addSatelliteStatusCallback SYS_STATUS_SIMST_OFF finishSatellite');
          this.finishSatellite(false);
          ReportUtil.getInstance().reportSatelliteCallQuit(Constants.UE_PLUG_AND_UNPLUG);
        } else if (serviceStatusInfo.serviceStatus == SYS_STATUS_CP_TIMEOUT) {
          if (this.satelliteType === SatelliteType.HYACINTH) {
            this.mCurrentStatus = SYS_DISCONNECT;
            this.updateStatusListeners();
          }
          this.mAlertDialogManager.showDialogByDialogType(AlertDialogManager.TYPE_SERVICE_STATUS_TIMEOUT);
          this.sysStatusCpTimeout = true;
          LogUtils.i(TAG, 'addSatelliteStatusCallback SYS_STATUS_CP_TIMEOUT finishSatellite');
          this.finishSatellite(false);
        } else if (serviceStatusInfo.serviceStatus == SYS_STATUS_NWREJ &&
          this.mCurrentStatus != SYS_STATUS_SEARCH_SATELLITE_FAIL) {
          this.sysStatusSwitch(serviceStatusInfo.cause);
        } else if (serviceStatusInfo.serviceStatus == SYS_STATUS_ENHANCES_CONNECT) {
          this.mAlertState = serviceStatusInfo.alertState;
          this.updateAlertState();
          if (this.mAlertState == SATELLITE_CONNECTING_STRONG_N0TIFY) {
            this.createStrongNotifyWindow();
          }
        } else if (serviceStatusInfo.serviceStatus == SYS_STATUS_NETWORK_REGED ||
          serviceStatusInfo.serviceStatus == SYS_STATUS_NETWORK_UNREGED) {
          this.updateStatusForReg(serviceStatusInfo.serviceStatus);
        } else if (serviceStatusInfo.serviceStatus == SYS_STATUS_SERVICE_DIED) {
          this.sysStatusCpTimeout = true;
          LogUtils.i(TAG, 'addSatelliteStatusCallback SYS_STATUS_SERVICE_DIED finishSatellite');
          await this.finishSatellite(false);
          await this.bindSatelliteService();
          await this.unbindSatelliteService(true);
          this.mAlertDialogManager.showDialogByDialogType(AlertDialogManager.TYPE_SERVICE_STATUS_TIMEOUT);
        } else if (serviceStatusInfo.serviceStatus == SYS_STATUS_UPDATE_DELTA) {
          if (SatelliteUtils.updateSuccessDelta(
            serviceStatusInfo.alignSectorPitch, serviceStatusInfo.alignSectorAzimuth)) {
            this.updateDialogAndFloatWindow();
          }
          this.updateStatusByService();
        } else if (serviceStatusInfo.serviceStatus == SYS_STATUS_CELLULAR_NETWORK) {
          if (serviceStatusInfo.cellularDetectionRes === DetectCellularNetwork.EXIST) {
            LogUtils.i(TAG, 'detection complete, cellular network available');
            this.publishNetworkNotify();
            ReportUtil.getInstance().reportDetectCellularNetwork(DetectCellularNetwork.EXIST);
          } else if (serviceStatusInfo.cellularDetectionRes === DetectCellularNetwork.NOT_EXIST) {
            LogUtils.i(TAG, 'detection complete, cellular network not available');
            notificationManager.cancel(CELLULAR_NETWORK_NOTIFY_ID);
            ReportUtil.getInstance().reportDetectCellularNetwork(DetectCellularNetwork.NOT_EXIST);
          } else if (serviceStatusInfo.cellularDetectionRes === DetectCellularNetwork.INTERRUPTED) {
            LogUtils.i(TAG, 'detection complete, cellular network interrupt');
          }
        }
      })
    } catch (err) {
      LogUtils.e(TAG, 'notifySatelliteStatus error = ' + JSON.stringify(err));
    }
  }

  private async publishNetworkNotify() {
    let notifyLeftIcon: PixelMap | undefined = undefined;
    let context: Context = CallSettingGlobalContextHelper.getContext()
      .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT);
    let alertDialogManager = new AlertDialogManager();
    notifyLeftIcon = await alertDialogManager.createNotifyLeftIcon(context);
    let notificationRequest: notificationManager.NotificationRequest = {
      id: CELLULAR_NETWORK_NOTIFY_ID,
      notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: this.getStringFromResourceArgs(context, $r('app.string.cellular_network_notify_title')),
          text: this.getStringFromResourceArgs(context, $r('app.string.cellular_network_notify_text')),
        }
      },
      wantAgent: await this.getWantAgent(),
      smallIcon: notifyLeftIcon,
      isFloatingIcon: true
    };
    let actionButton = await this.getActionButton(context);
    if (actionButton.length > 0) {
      notificationRequest.actionButtons = actionButton;
    }
    notificationManager.publish(notificationRequest);
  }

  private async getWantAgent() {
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: 'com.ohos.settings',
          abilityName: 'com.ohos.settings.MainAbility',
          uri: 'satellite_network_entry',
          parameters: {
            pushParams: 'SatelliteCommunication'
          }
        }
      ],
      actionType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      wantAgentFlags: [wantAgent.WantAgentFlags.CONSTANT_FLAG]
    };
    let jumpWantAgentData = await wantAgent.getWantAgent(wantAgentInfo);
    return jumpWantAgentData;
  }

  private async getActionButton(context: Context) {
    let actionButtons: notificationManager.NotificationActionButton[] = [];
    let ignoreNotify: wantAgent.WantAgentInfo = {
      wants: [
        {
          deviceId: '',
          bundleName: 'com.ohos.callsetting',
          abilityName: 'com.ohos.callsetting.SatelliteService',
          parameters: {
            callerName: IGNORE_NOTIFY_BUTTON,
          }
        }
      ],
      actionType: wantAgent.OperationType.START_SERVICE,
      requestCode: 0,
      wantAgentFlags: [wantAgent.WantAgentFlags.CONSTANT_FLAG],
    };

    let closeSatellite: wantAgent.WantAgentInfo = {
      wants: [
        {
          deviceId: '',
          bundleName: 'com.ohos.callsetting',
          abilityName: 'com.ohos.callsetting.SatelliteService',
          parameters: {
            callerName: CLOSE_SATELLITE_NETWORK_BUTTON,
          }
        }
      ],
      actionType: wantAgent.OperationType.START_SERVICE,
      requestCode: 0,
      wantAgentFlags: [wantAgent.WantAgentFlags.CONSTANT_FLAG]
    };
    try {
      let ignoreWantAgentData = await wantAgent.getWantAgent(ignoreNotify);
      let closeWantAgentData = await wantAgent.getWantAgent(closeSatellite);
      actionButtons = [{
        title: this.getStringFromResourceArgs(context, $r('app.string.cellular_network_notify_ignore_button')),
        wantAgent: ignoreWantAgentData
      }, {
        title: this.getStringFromResourceArgs(context, $r('app.string.cellular_network_notify_close_button')),
        wantAgent: closeWantAgentData
      }]
    } catch (error) {
      LogUtils.e(TAG, 'Get actionButton error：' + JSON.stringify(error))
    }
    return actionButtons;
  }

  private getStringFromResourceArgs(context: Context, resource: Resource, param?: string | number): string {
    if (param) {
      return context.resourceManager.getStringSync(resource.id, param);
    } else {
      return context.resourceManager.getStringSync(resource.id);
    }
  }

  private updateStatusByService() {
    LogUtils.i(TAG, 'updateStatusByService mCurrentStatus:' + this.mCurrentStatus +
      ', successAzimuthDelta:' + SatelliteUtils.successAzimuthDelta);
    if (this.mCurrentStatus == SYS_STATUS_WAIT_LOADING && SatelliteUtils.successAzimuthDelta != 0 &&
      this.mConvertLongitude != DEFAULT_CONVERT_DATA) {
      this.unRegisterSimStateChange();
      if (!(ScreenAdapterUtils.isNewFormFoldPhone() || ScreenAdapterUtils.isTrifoldPhone())) {
        this.removeFoldStatusListener();
      }
      insert(SATELLITE_SWITCH_ON, CallSettingGlobalContextHelper.getContext()
        .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT), this.satelliteType);
      LogUtils.i(TAG, `End Switch Interpolation`);
      this.setCurrentStatus(SYS_STATUS_SEARCHING_SATELLITE);
      this.updateStatusListeners();
      if (isSupportDandelion()) {
        let locationMode: boolean = geoLocationManager.isLocationEnabled();
        if (locationMode) {
          try {
            geoLocationManager.disableLocation();
          } catch (err) {
            LogUtils.e(TAG, `updateStatusByService disableLocation error: ${err?.code} ${err?.message}`);
          }
        }
      }
    }
  }

  updateStatusForReg(serviceStatus: number) {
    if (serviceStatus == SYS_STATUS_NETWORK_REGED) {
      if (this.mCurrentStatus != SYS_STATUS_SATELLITE_CONNECTING &&
        this.mCurrentStatus != SYS_STATUS_SEARCHING_SATELLITE &&
        this.mCurrentStatus != SYS_STATUS_SEARCH_SATELLITE_FAIL) {
        return;
      }
      let status = this.mCurrentStatus;
      this.setCurrentStatus(SYS_STATUS_SEARCH_SATELLITE_SUCC);
      this.updateStatusListeners();
      this.mCacheSatelliteData.signal = this.mSignal;
      this.updateSatelliteDataListeners(this.mCacheSatelliteData);
      if (status === SYS_STATUS_SEARCH_SATELLITE_FAIL) {
        this.showReConnect = false;
        this.updateStatusListeners();
      }
    } else if (serviceStatus == SYS_STATUS_NETWORK_UNREGED) {
      if (this.mCurrentStatus != SYS_STATUS_SEARCH_SATELLITE_SUCC) {
        return;
      }
      if (this.isGuide()) {
        this.setCurrentStatus(SYS_STATUS_SATELLITE_CONNECTING);
      } else {
        this.setCurrentStatus(SYS_STATUS_SEARCHING_SATELLITE);
      }
      this.updateStatusListeners();
    }
  }

  private isGuide(): boolean {
    LogUtils.i(TAG, `isGuide ${this.satelliteType}`);
    if (this.satelliteType === SatelliteType.TIAN_TONG) {
      return SatelliteUtils.checkAzimuthOk(this.mCacheSatelliteData.azimuthDelta) &&
      SatelliteUtils.checkPitchOk(this.mCacheSatelliteData.pitchAngleDelta);
    } else if (this.satelliteType === SatelliteType.HYACINTH) {
      return SatelliteUtils.isGuideAzimuth(this.mCacheSatelliteData.guideAzimuth) &&
      SatelliteUtils.isGuidePitch(this.mCacheSatelliteData.guidePitch);
    }
    return false;
  }

  // 寻星中错误码弹窗
  async sysStatusSwitch(cause: number) {
    LogUtils.i(TAG, 'cause: ' + cause);
    if (cause == ERROR_CODE_NOT_ACTIVATED_SIM) {
      this.mAlertDialogManager.showDialogByDialogType(AlertDialogManager.ERROR_CODE_NOT_ACTIVATED_SIM);
    } else if (cause == ERROR_CODE_NOT_OPENED_ROAMING) {
      this.mAlertDialogManager.showDialogByDialogType(AlertDialogManager.ERROR_CODE_NOT_OPENED_ROAMING);
    } else if (cause == ERROR_CODE_NOT_OPENED_TIANDIWINGCARD) {
      this.mAlertDialogManager.showDialogByDialogType(AlertDialogManager.ERROR_CODE_NOT_OPENED_TIANDIWINGCARD);
    } else if (cause == ERROR_CODE_NOT_SUPPORT_CARD) {
      this.mAlertDialogManager.showDialogByDialogType(AlertDialogManager.ERROR_CODE_NOT_SUPPORT_CARD);
    } else if (cause == ERROR_CODE_OTHERS) {
      this.mAlertDialogManager.showDialogByDialogType(AlertDialogManager.ERROR_CODE_OTHERS);
    }
    this.showReConnect = true;
    this.setCurrentStatus(SYS_STATUS_SEARCH_SATELLITE_FAIL);
    this.updateStatusListeners();
    ReportUtil.getInstance().reportSatelliteErrorCode(cause);
  }

  async saveLocationToPreferences(locationMode: boolean) {
    try {
      let ctx: Context = CallSettingGlobalContextHelper.getContext()
        .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT);
      ctx.area = contextConstant.AreaMode.EL1
      let preferences: data_preferences.Preferences = await data_preferences.getPreferences(ctx,
        SATELLITE_LOCATION_REFERENCE_NAME);
      await preferences.putSync(SATELLITE_LOCATION_REFERENCE_KEY, locationMode);
      preferences.flush();
    } catch (err) {
      LogUtils.e(TAG, `saveLocationToPreferences error: ${err?.code} ${err?.message}`);
    }
  }

  async getLocationFromPreferences() {
    try {
      let ctx: Context = CallSettingGlobalContextHelper.getContext()
        .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT);
      ctx.area = contextConstant.AreaMode.EL1
      let preferences: data_preferences.Preferences = await data_preferences.getPreferences(ctx,
        SATELLITE_LOCATION_REFERENCE_NAME);
      return await preferences.get(SATELLITE_LOCATION_REFERENCE_KEY, false) as boolean;
    } catch (err) {
      LogUtils.e(TAG, `getLocationFromPreferences error: ${err?.code} ${err?.message}`);
      return false;
    }
  }

  // rollback location info switch
  private rollBackLocationMode() {
    this.getLocationFromPreferences().then((data: preferences.ValueType) => {
      if (data) {
        if (isSupportDandelion()) {
          this.enableLocation(false);
        }
      } else if (this.mCurrentStatus !== SYS_STATUS_WAIT_CALIBRATING) {
        try {
          geoLocationManager.disableLocation();
        } catch (err) {
          LogUtils.e(TAG, `rollBackLocationMode error: ${err?.code} ${err?.message}`);
        }
      }
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, `getLocationFromPreferences error: code: ${err?.code}, message: ${err?.message} `);
    });
  }

  private addSatelliteDataCallBack() {
    try {
      notifySatelliteInfo(async (satelliteInfo : SatelliteData) => {
        if (!this.satelliteSearchStarted) {
          LogUtils.i(TAG, 'Satellite service has been finish, do not need update.');
          return;
        }
        this.mCacheSatelliteData.azimuthDelta = satelliteInfo.azimuthDelta;
        this.mCacheSatelliteData.pitchAngleDelta = satelliteInfo.pitchAngleDelta;
        this.mCacheSatelliteData.signal = this.mCurrentStatus == SYS_STATUS_SEARCH_SATELLITE_SUCC ? this.mSignal : 0;
        this.mCacheSatelliteData.sateIdx = satelliteInfo.sateIdx;
        this.mCacheSatelliteData.sateShow = satelliteInfo.sateShow;
        this.mCacheSatelliteData.availableTime = satelliteInfo.availableTime;
        this.mCacheSatelliteData.guideAzimuth = satelliteInfo.guideAzimuth;
        this.mCacheSatelliteData.guidePitch = satelliteInfo.guidePitch;

        this.updateSatelliteDataListeners(this.mCacheSatelliteData);
      })
    } catch (err) {
      LogUtils.e(TAG, 'notifySatelliteInfo error = ' + JSON.stringify(err));
    }
  }

  // 解除寻星服务绑定
  public async unbindSatelliteService(isStoppedByServiceDied: boolean = false) {
    if (call.hasCallSync()) {
      LogUtils.i(TAG, 'hangUpCall is called');
      publishSatelliteCallHangupEvent();
      setTimeout(() => {
        this.unbindSatelliteService1(isStoppedByServiceDied);
      }, 1000);
    } else {
      await this.unbindSatelliteService1(isStoppedByServiceDied);
    }
  }

  private async unbindSatelliteService1(isStoppedByServiceDied: boolean = false) {
    LogUtils.i(TAG, 'unbindSatelliteService is called');
    try {
      await offSatelliteInfo(async () => {
        LogUtils.i(TAG, 'offSatelliteInfo is called, result = ');
      });
    } catch (err) {
      LogUtils.e(TAG, `offSatelliteInfo error: ${err?.code} ${err?.message}`);
    }
    try {
      await offSatelliteStatus(async () => {
        LogUtils.i(TAG, 'offSatelliteStatus is called');
      });
    } catch (err) {
      LogUtils.e(TAG, `offSatelliteStatus error: ${err?.code} ${err?.message}`);
    }
    try {
      LogUtils.i(TAG, `stopSatelliteService slotId = ${this.mSlotId}, satelliteType = ${this.satelliteType}`);
      if (isStoppedByServiceDied) {
        let result = await stopSatelliteService(INVALID_SLOT_ID, this.satelliteType);
        LogUtils.i(TAG, 'isStoppedByServiceDied, result = ' + result);
      } else {
        let result = await stopSatelliteService(this.mSlotId, this.satelliteType);
        LogUtils.i(TAG, 'stopSatelliteService is called, result = ' + result);
      }
    } catch (err) {
      LogUtils.e(TAG, `stopSatelliteService error: ${err?.code} ${err?.message}`);
    }
    this.unRegisterSignalInfoChange();
    this.unRegisterAccelerometerListener();
  }

  // 创建半膜态界面
  public createSatelliteDialog() {
    if (!this.isSatelliteDialogShow) {
      this.mSatelliteDialogManager.createSatelliteDialog();
      this.isSatelliteDialogShow = true;
    }
    if (this.isFloatWindowShow) {
      this.publishCloseSatelliteDialogEvent();
      this.mSatelliteFloatWindowManager.closeFloatWindow();
      this.isFloatWindowShow = false;
    }
    if (this.isStrongNotifyWindowShow) {
      this.mStrongNotifyWindowManager.closeStrongNotify();
      this.isStrongNotifyWindowShow = false;
    }
  }

  public isTianTong(): boolean {
    return this.satelliteType === SatelliteType.TIAN_TONG;
  }

  public isHyacinth(): boolean {
    return this.satelliteType === SatelliteType.HYACINTH;
  }

  // 创建悬浮卡片界面
  public async createFloatWindow() {
    if (!this.isFloatWindowShow) {
      this.mSatelliteFloatWindowManager.createFloatWindow();
      this.isFloatWindowShow = true;
    }
    if (this.isSatelliteDialogShow) {
      this.mSatelliteDialogManager.closeSatelliteDialog();
      this.isSatelliteDialogShow = false;
    }
    if (this.isStrongNotifyWindowShow) {
      this.mStrongNotifyWindowManager.closeStrongNotify();
      this.isStrongNotifyWindowShow = false;
    }
  }

  // 创建强提醒界面
  public async createStrongNotifyWindow() {
    if (!this.isStrongNotifyWindowShow) {
      this.mStrongNotifyWindowManager.createStrongNotify();
      this.isStrongNotifyWindowShow = true;
    }
    if (ScreenAdapterUtils.getInstance().isNewFoldPhoneExternalScreen()) {
      // 外屏仅提醒,不销毁半模态和悬浮卡片
      LogUtils.i(TAG, 'createStrongNotifyWindow no need destroy other window');
      return;
    }
    if (this.isSatelliteDialogShow) {
      this.mSatelliteDialogManager.closeSatelliteDialog();
      this.isSatelliteDialogShow = false;
    }
    if (this.isFloatWindowShow) {
      this.mSatelliteFloatWindowManager.closeFloatWindow();
      this.isFloatWindowShow = false;
    }
  }

  //蒲公英开启入口，点击设置里开关，调用此方法即可
  public startSatellite(satelliteType: number) {
    this.satelliteType = satelliteType;
    if (this.isHyacinth()) {
      this.defaultConnectTime = WAIT_STATE_TIME * 2;
      this.connectTime = WAIT_STATE_TIME * 2;
    } else if (isSupportCactus()) {
      this.defaultConnectTime = WAIT_STATE_TIME_CACTUS;
      this.connectTime = WAIT_STATE_TIME_CACTUS;
    } else {
      this.defaultConnectTime = WAIT_STATE_TIME;
      this.connectTime = WAIT_STATE_TIME;
    }
    this.satelliteSearchStarted = true;
    //创建半膜态界面
    this.mSatelliteDialogManager.createSatelliteDialog();
    this.isSatelliteDialogShow = true;
    //添加飞行模式监听
    this.addAirPlanListener();
    //添加监听通话状态
    this.registerCallStateChange();

    this.subscribeSatelliteEvent();

    this.addSatelliteSwitchListener(this.satelliteType);

    this.registerAccountListener();

    this.registerSimStateChange();

    this.addFoldStatusListener();

    this.startBackgroundTaskResourceApply();

    this.subscribeBatteryModeEvent();

    let island = isTablet() || TrifoldManager.getInstance().isTrifold();
    this.isLandscape = island ? true : false;

    this.uiOrientation = island ? ConfigurationConstant.Direction.DIRECTION_HORIZONTAL
      : ConfigurationConstant.Direction.DIRECTION_VERTICAL;
  }

  public getMaxConnectTime(): number {
    return this.defaultConnectTime;
  }

  async registerSimStateChange() {
    this.mSlotId = await this.getSlotId();
    registerSimStateChangeForSlotId(this.mSlotId, async (callStateInfo: observer.SimStateData) => {
      let isSimActive: boolean = callStateInfo?.state === sim.SimState.SIM_STATE_LOADED ||
        callStateInfo?.state === sim.SimState.SIM_STATE_READY ? true : false;
      LogUtils.i(TAG, `registerSimSateChange isSimActive: ${isSimActive}`);
      if (!isSimActive) {
        this.finishSatellite(false);
      }
    })
  }

  unRegisterSimStateChange() {
    LogUtils.i(TAG, `unRegisterSimStateChange`);
    observer.off('simStateChange');
  }

  //仙人掌结束退出
  public async finishSatellite(isFromSwitchOff: boolean) {
    if (!this.satelliteSearchStarted) {
      LogUtils.i(TAG, 'has been finished, return');
      return;
    }
    LogUtils.i(TAG, 'finishSatellite');
    this.satelliteSearchStarted = false;
    this.finishDialogAndFloatWindow();
    //移除飞行模式监听
    removeAirPlaneModeListener();
    //移除监听通话状态
    this.unRegisterCallStateChange();
    //重置缓存数据
    this.mCurrentStatus = SYS_STATUS_DEFAULT;
    this.mAlertState = 0;
    this.connectTime = this.defaultConnectTime;
    this.stopConnectTimer();
    this.mSignal = 0;
    this.isLandscape = (isTablet() || TrifoldManager.getInstance().isTrifold()) ? true : false;
    //设置关闭蒲公英开关值未关闭
    if (!isFromSwitchOff) {
      LogUtils.i(TAG, `finishSatellite SwitchOff Value: 0 satelliteType: ${this.satelliteType}`);
      insert(0, CallSettingGlobalContextHelper.getContext()
        .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT), this.satelliteType);
    }
    this.mConvertLongitude = DEFAULT_CONVERT_DATA;
    this.mConvertLatitude = DEFAULT_CONVERT_DATA;
    SatelliteUtils.updateSuccessDelta(0, 0);
    this.isStrongNotifyRing = false;

    this.satelliteSearchTime = TYPE_CLOSE_SATELLITE_BY_TIMEOUT;
    // 关闭倒计时
    this.stopSatelliteSearchTimer();
    await this.unbindSatelliteService();
    this.mSlotId = -1;
    this.showReConnect = false;
    this.showReCalibrate = false;
    this.showReSearch = false;
    this.unSubscribeChangedEvent();
    this.unRegisterAccountListener();
    this.unRegisterSimStateChange();
    this.isFirst = false;
    this.removeSatelliteSwitchListener();
    this.rollBackLocationMode();
    VibrateUtil.stopVibrate();
    this.mediaPlayer.release();
    insertConnectState(SATELLITE_CONNECTING_OFF, CallSettingGlobalContextHelper.getContext()
      .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT));
    LogUtils.i(TAG, 'finishSatellite, sysStatusCpTimeout = ' + this.sysStatusCpTimeout +
      'closeSatelliteByCallState = ' + this.closeSatelliteByCallState);
    if (this.isStrongNotifyWindowShow) {
      this.mStrongNotifyWindowManager.closeStrongNotify();
      this.isStrongNotifyWindowShow = false;
    }
    if (!this.sysStatusCpTimeout && !this.closeSatelliteByCallState) {
      this.mAlertDialogManager.closeAlertDialogWindow();
      CallSettingGlobalContextHelper.getContext()
        .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT)?.terminateSelf();
    } else {
      this.sysStatusCpTimeout = false;
      this.closeSatelliteByCallState = false;
    }
    SatelliteUtils.successAzimuthDelta = 0;
    SatelliteUtils.successPitchDelta = 0;
    this.removeFoldStatusListener();
    this.endBackgroundTaskReleaseResources();
    this.closeNewFoldScreenDialog();
    this.shouldResetFloatWindow = false;
  }

  async createNewFoldScreenDialog() {
    if (this.isStrongNotifyWindowShow) {
      LogUtils.i(TAG, 'no need createNewFoldScreenDialog');
      return;
    }
    if (NewFoldScreenAlertDialogManager.IS_SHOW) {
      await this.mNewFoldScreenAlertDialogManager.closeNewFoldAlertDialogWindow();
    }
    this.mNewFoldScreenAlertDialogManager.createNewFoldAlertDialogWindow();
  }

  async closeNewFoldScreenDialog() {
    if (NewFoldScreenAlertDialogManager.IS_SHOW) {
      this.mNewFoldScreenAlertDialogManager.closeNewFoldAlertDialogWindow();
    }
  }

  closeStrongNotifyInNewFoldScreen(delayTime: number) {
    this.isStrongNotifyWindowShow = false;
    setTimeout(async () => {
      // 关闭强提醒窗口
      await this.mStrongNotifyWindowManager.closeStrongNotify();
    }, delayTime);
  }

  finishDialogAndFloatWindow() {
    this.mSatelliteFloatWindowManager.setLeftMovingDirection(0);
    this.mSatelliteFloatWindowManager.setTopMovingDirection(0);
    if (this.isSatelliteDialogShow) {
      this.mSatelliteDialogManager.closeSatelliteDialog();
      this.isSatelliteDialogShow = false;
    }
    if (this.isFloatWindowShow) {
      this.mSatelliteFloatWindowManager.closeFloatWindow();
      this.isFloatWindowShow = false;
    }
  }

  isShowOrientationRemind() : boolean {
    let island = isTablet() || TrifoldManager.getInstance().isTrifold();
    if (this.isFromMeetime) {
      return false;
    }
    if (this.mCurrentStatus === SYS_STATUS_WAIT_LOADING || this.mCurrentStatus === SYS_STATUS_WAIT_CALIBRATING ||
      this.mCurrentStatus === SYS_STATUS_DEFAULT || this.mCurrentStatus === SYS_STATUS_SEARCH_SATELLITE_FAIL) {
      return false;
    }

    if (this.isGuide()) {
      return false;
    }
    if (this.uiOrientation ==
    ConfigurationConstant.Direction.DIRECTION_VERTICAL && island) {
      return true;
    }
    if (this.uiOrientation ==
    ConfigurationConstant.Direction.DIRECTION_HORIZONTAL && !island) {
      return true;
    }
    if (this.isLandscape && !island) {
      return true;
    } else if (!this.isLandscape && island) {
      return true;
    }
    return false;
  }

  public getUIOrientation(): number | undefined {
    return this.uiOrientation;
  }

  public refreshUIOrientation(): void {
    if (isDevicePortrait()) {
      this.uiOrientation = ConfigurationConstant.Direction.DIRECTION_VERTICAL;
    } else {
      this.uiOrientation = ConfigurationConstant.Direction.DIRECTION_HORIZONTAL;
    }
  }

  async reCreateDialogOrFloatWindow(orientation?: number) {
    try {
      this.mAlertDialogManager.closeAlertDialogWindow();
      this.publishCloseSatelliteDialogEvent();
      this.uiOrientation = orientation;
      this.mSatelliteFloatWindowManager.setLeftMovingDirection(0);
      this.mSatelliteFloatWindowManager.setTopMovingDirection(0);
      await this.mSatelliteDialogManager.closeSatelliteDialog();
      await this.mSatelliteFloatWindowManager.closeFloatWindow();
      await this.mStrongNotifyWindowManager.closeStrongNotify();
      this.mAlertDialogManager.closeAlertDialogByType(AlertDialogManager.TYPE_CLOSE_SATELLITE_TIPS);
      if (this.isSatelliteDialogShow) {
        await this.mSatelliteDialogManager.createSatelliteDialog();
        this.isFloatWindowShow = false;
        this.isStrongNotifyWindowShow = false;
      } else if (this.isFloatWindowShow) {
        await this.mSatelliteFloatWindowManager.createFloatWindow();
        this.isSatelliteDialogShow = false;
        this.isStrongNotifyWindowShow = false;
      } else if (this.isStrongNotifyWindowShow) {
        await this.mStrongNotifyWindowManager.createStrongNotify();
        this.isFloatWindowShow = false;
        this.isSatelliteDialogShow = false;
      }
    } catch (err) {
      LogUtils.e(TAG, 'reCreateDialogOrFloatWindow error: code: ' + err?.code + ', message: ' + err?.message);
    }
  }

  async updateDialogAndFloatWindow() {
    LogUtils.i(TAG, `updateDialogAndFloatWindow`);
    if (ScreenAdapterUtils.isNewFormFoldPhone()) {
      LogUtils.i(TAG, 'updateDialogAndFloatWindow newFoldPhone no need updateDialogAndFloatWindow exclude strongNotify');
      if (this.isStrongNotifyWindowShow) {
        await this.mStrongNotifyWindowManager.closeStrongNotify();
        await this.mStrongNotifyWindowManager.createStrongNotify();
        LogUtils.i(TAG, 'updateDialogAndFloatWindow createStrongNotify');
      }
      return;
    }
    this.mAlertDialogManager.closeAlertDialogByType(AlertDialogManager.TYPE_CLOSE_SATELLITE_TIPS);
    this.publishCloseSatelliteDialogEvent();
    if (this.isSatelliteDialogShow) {
      await this.mSatelliteDialogManager.closeSatelliteDialog();
      await this.mSatelliteDialogManager.createSatelliteDialog();
    }
    if (this.isFloatWindowShow) {
      await this.mSatelliteFloatWindowManager.closeFloatWindow();
      await this.mSatelliteFloatWindowManager.createFloatWindow();
    }
    if (this.isStrongNotifyWindowShow) {
      await this.mStrongNotifyWindowManager.closeStrongNotify();
      await this.mStrongNotifyWindowManager.createStrongNotify();
    }
  }

  public addSatelliteSwitchListener(satelliteType: SatelliteType = SatelliteType.TIAN_TONG) {
    LogUtils.i(TAG, 'addSatelliteSwitchListener');
    try {
      dataShare.createDataShareHelper(CallSettingGlobalContextHelper.getContext()
        .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT),
        SETTING_SATELLITE_SERVICE_URI, (err: BusinessError, data: dataShare.DataShareHelper) => {
          if (err != undefined) {
            LogUtils.e(TAG, 'addSatelliteSwitchListener error: code: ' + err.code + ', message: ' + err.message);
            return;
          }
          this.dataShareHelper = data;
          this.satelliteType = satelliteType;
          if (satelliteType === SatelliteType.TIAN_TONG) {
            this.dataShareHelper.on('dataChange',
              ON_SETTING_SATELLITE_SERVICE_URI + '?key=' + QUERY_SATELLITE_MODE_TIANTONG_KEY, () => {
                LogUtils.i(TAG, 'addSatelliteSwitchListener tian tong dataChange success');
                this.querySatelliteSwitch();
              });
          }
          if (satelliteType === SatelliteType.HYACINTH) {
            this.dataShareHelper.on('dataChange',
              ON_SETTING_SATELLITE_SERVICE_URI + '?key=' + QUERY_SATELLITE_MODE_HYACINTH_KEY, () => {
                LogUtils.i(TAG, 'addSatelliteSwitchListener hyacinth dataChange success');
                this.querySatelliteSwitch();
              });
          }
        });
    } catch (err) {
      let error = err as BusinessError;
      LogUtils.e(TAG, 'addSatelliteSwitchListener createDataShareHelper error: code: ' + error.code + ', message: ' + error.message);
    }
  }

  private querySatelliteSwitch() {
    settings.getValue(CallSettingGlobalContextHelper.getContext()
      .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT),
      getSatelliteModeKey(this.satelliteType)).then((data) => {
      LogUtils.i(TAG, `querySatelliteSwitch: data->${JSON.stringify(data)}`);
      if (data === '0.0') {
        this.finishSatellite(true);
        ReportUtil.getInstance().reportSatelliteCallQuit(Constants.UE_INITIATIVE_QUIT);
      }
    }).catch((error: BusinessError) => {
      LogUtils.e(TAG, `querySatelliteSwitch fail, promise: err->${JSON.stringify(error)}`);
    });
  }

  public removeSatelliteSwitchListener() {
    LogUtils.i(TAG, 'removeSatelliteSwitchListener');
    if (!this.dataShareHelper) {
      LogUtils.e(TAG, 'removeSatelliteSwitchListener dataShareHelper null');
      return;
    }
    try {
      let uri = ON_SETTING_SATELLITE_SERVICE_URI + '?key=' +
        (this.satelliteType === SatelliteType.HYACINTH ? QUERY_SATELLITE_MODE_HYACINTH_KEY :
          QUERY_SATELLITE_MODE_TIANTONG_KEY);
      this.dataShareHelper.off('dataChange', uri);
      this.dataShareHelper = undefined;
    } catch (err) {
      let error = err as BusinessError;
      LogUtils.e(TAG, 'removeSatelliteSwitchListener error: code: ' + error.code + ', message: ' + error.message);
    }
  }

  /**
   * get satellite search status
   *
   * @return current satellite status
   */
  public getCurrentStatus() {
    return this.mCurrentStatus;
  }

  /**
   * get should show landscape remind page
   *
   * @return isLandscape
   */
  public getisLandscape() {
    return this.isLandscape;
  }

  /**
   * get Longitude
   *
   * @return mConvertLongitude
   */
  public getLocationLongitude() {
    return this.mConvertLongitude;
  }

  /**
   * get getLocationLatitude
   *
   * @return mConvertLatitude
   */
  public getLocationLatitude() {
    return this.mConvertLatitude
  }

  /**
   * get connecting time
   *
   * @return connectTime
   */
  public getConnectingTime() {
    if (this.getIsFromMeetime() && this.connectTime === this.defaultConnectTime) {
      this.connectTime = 0;
    }
    return this.connectTime;
  }

  /**
   * set connecting time
   *
   * @return connectTime
   */
  public setConnectingTime(connectTime: number) {
    this.connectTime = connectTime;
  }

  /**
   * get strong notify time
   *
   * @return strongNotifyTime
   */
  public getStrongNotifyTime() {
    return this.strongNotifyTime;
  }

  /**
   * set strong notify time
   *
   * @return strongNotifyTime
   */
  public setStrongNotifyTime(strongNotifyTime: number) {
    this.strongNotifyTime = strongNotifyTime;
  }

  /**
   * get is strong notify ring
   *
   * @return isStrongNotifyRing
   */
  public getIsStrongNotifyRing() {
    return this.isStrongNotifyRing;
  }

  /**
   * set is strong notify ring
   *
   * @return isStrongNotifyRing
   */
  public setIsStrongNotifyRing(isStrongNotifyRing: boolean) {
    this.isStrongNotifyRing = isStrongNotifyRing;
  }

  /**
   * get strong notify ring time
   *
   * @return strongNotifyRingTime
   */
  public getStrongNotifyRingTime() {
    return this.strongNotifyRingTime;
  }

  /**
   * set strong notify ring time
   *
   * @return strongNotifyRingTime
   */
  public setStrongNotifyRingTime(strongNotifyRingTime: number) {
    this.strongNotifyRingTime = strongNotifyRingTime;
  }

  /**
   * Get time
   *
   * @return time
   */
  public getTime(): number {
    return this.time;
  }

  /**
   * Set time
   *
   * @param time
   */
  public setTime(time: number): void {
    this.time = time;
  }

  /**
   * get show reconnect
   *
   * @return showReConnect
   */
  public getShowReconnect() {
    return this.showReConnect;
  }

  /**
   * set show reconnect result
   *
   * @return connectTime
   */
  public setShowReconnect(showReConnect: boolean) {
    this.showReConnect = showReConnect;
  }

  /**
   * get show reSearch
   *
   * @return showReSearch
   */
  public getShowReSearch() {
    return this.showReSearch;
  }

  /**
   * set show reSearch result
   *
   * @return connectTime
   */
  public setShowReSearch(showReSearch: boolean) {
    this.showReSearch = showReSearch;
  }

  /**
   * get alertState
   *
   * @return alertState
   */
  public getAlertState() {
    return this.mAlertState;
  }

  /**
   * get cacheSatelliteData
   *
   * @return cacheSatelliteData
   */
  public getCacheSatelliteData() {
    return this.mCacheSatelliteData;
  }

  /**
   * get show reCalibrate
   *
   * @return showReCalibrate
   */
  public getShowReCalibrate() {
    return this.showReCalibrate;
  }

  /**
   * set show reCalibrate result
   *
   * @return connectTime
   */
  public setShowReCalibrate(showReCalibrate: boolean) {
    this.showReCalibrate = showReCalibrate;
  }

  /**
   * Set from meetime flag
   *
   * @param from meetime flag
   */
  public setIsFromMeetime(isFromMeetime: boolean): void {
    this.isFromMeetime = isFromMeetime;
  }

  /**
   * Get from meetime flag
   *
   * @return from meetime flag
   */
  public getIsFromMeetime(): boolean {
    return this.isFromMeetime;
  }

  /**
   * Is only from meetime
   *
   * @return Is only from meetime
   */
  public isOnlyFromMeetime(from: string): boolean {
    return from === SatelliteFromType.SATELLITE_FROM_TYPE_MEETIME;
  }

  /**
   * get satellite search status
   *
   * @param currentStatus
   */
  public setCurrentStatus(currentStatus: number) {
    if (currentStatus == this.mCurrentStatus) {
      return;
    }
    if (!this.isFromMeetime && !this.satelliteSearchStarted) {
      LogUtils.i(TAG, 'setCurrentStatus, satellite has been finished, return. currentStatus:' + currentStatus);
      return;
    }
    LogUtils.i(TAG, 'setCurrentStatus:' + currentStatus);
    if (currentStatus == SYS_STATUS_SATELLITE_CONNECTING) {
      this.startConnectTime = new Date().valueOf();
      if (!this.isConnecting) {
        this.startSatelliteConnectTimer();
      }
    } else {
      this.stopConnectTimer();
    }
    if (this.getIsFromMeetime()) {
      this.mCurrentStatus = currentStatus;
      return;
    }
    if (currentStatus == SYS_STATUS_WAIT_LOADING) {
      this.handleWaitLoadingStatus();
    }
    if (currentStatus == SYS_STATUS_SEARCHING_SATELLITE || currentStatus == SYS_STATUS_SEARCH_SATELLITE_FAIL) {
      // start no link satellite timer
      this.startSatelliteSearchTimer();
      if (this.loadingStartTime > 0) {
        ReportUtil.getInstance().reportSatelliteLoadingInfo(new Date().valueOf() - this.loadingStartTime, 1);
        this.loadingStartTime = 0;
      }
    } else {
      // stop not link satellite timer
      this.stopSatelliteSearchTimer();
      this.mAlertDialogManager.closeNotLinkSatelliteDialog();
    }
    if (currentStatus == SYS_STATUS_SEARCH_SATELLITE_SUCC) {
      insertConnectState(SATELLITE_CONNECTING_ON, CallSettingGlobalContextHelper.getContext()
        .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT));
      if (this.startConnectTime > 0) {
        if (this.isTianTong()) {
          ReportUtil.getInstance().reportSatelliteConnectInfo(new Date().valueOf() - this.startConnectTime, 1);
        } else if (this.isHyacinth()){
          ReportUtil.getInstance().reportHyacinthConnectTime();
        }
        this.startConnectTime = 0;
      }
      this.mediaPlayer.doPlay('connectSucc.ogg');
      VibrateUtil.startVibrate();
    } else {
      if (this.mCurrentStatus == SYS_STATUS_SEARCH_SATELLITE_SUCC) {
        insertConnectState(SATELLITE_CONNECTING_OFF, CallSettingGlobalContextHelper.getContext()
          .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT));
      }
      if (currentStatus === SYS_STATUS_SEARCH_SATELLITE_FAIL) {
        this.mediaPlayer.doPlay('connectFail.ogg');
        VibrateUtil.startVibrate();
      }
    }
    if (currentStatus == SYS_STATUS_SEARCH_SATELLITE_FAIL && this.startConnectTime > 0) {
      ReportUtil.getInstance().reportSatelliteConnectInfo(new Date().valueOf() - this.startConnectTime, 0);
      this.startConnectTime = 0;
    }
    this.mCurrentStatus = currentStatus;
    if (this.mCurrentStatus === SYS_STATUS_SATELLITE_CONNECTING ||
      this.mCurrentStatus === SYS_STATUS_SEARCHING_SATELLITE ||
      this.mCurrentStatus === SYS_STATUS_SEARCH_SATELLITE_SUCC) {
      this.updateDeviceDirectionListeners();
    }
    SatelliteLocation.updateStatus();
  }

  handleWaitLoadingStatus(): void {
    this.loadingStartTime = new Date().valueOf();
    this.subscribeShutdownEvent();
    let locationMode: boolean = geoLocationManager.isLocationEnabled();
    this.saveLocationToPreferences(locationMode);
  }

  /**
   * Set session
   *
   * @param session UIExtensionContentSession
   */
  public setSession(session: UIExtensionContentSession | undefined) {
    this.session = session;
  }

  //监听电话状态
  /**
   * Monitor the call state
   *
   * @param {function} callBack - call-back
   */
  public registerCallStateChange() {
    LogUtils.i(TAG, 'registerCallStateChange')
    onCallStateChange(
      async (data: observer.CallStateInfo): Promise<void> => {
        LogUtils.i(TAG, 'onCallStateChange: json = ' + JSON.stringify(data))
        if (data.state != call.CallState.CALL_STATE_IDLE && data.state != call.CallState.CALL_STATE_UNKNOWN) {
          if (!this.satelliteSearchStarted) {
            return;
          }
          if (this.mCurrentStatus == SYS_STATUS_WAIT_CALIBRATING ||
            this.mCurrentStatus == SYS_STATUS_WAIT_LOADING || this.mCurrentStatus == SYS_STATUS_DEFAULT) {
            this.mAlertDialogManager.showDialogByDialogType(AlertDialogManager.TYPE_CLOSE_SATELLITE_BY_CALL_STATE);
            this.closeSatelliteByCallState = true;
            LogUtils.i(TAG, 'registerCallStateChange onCallStateChange finishSatellite');
            this.finishSatellite(false);
          } else {
            this.showFloatWindowByCall(data.state);
          }
        }
      });
  }

  private showFloatWindowByCall(callState: number) {
    if (this.mCurrentStatus == SYS_STATUS_SEARCH_SATELLITE_SUCC && this.isSatelliteDialogShow) {
      if (callState == call.CallState.CALL_STATE_RINGING) {
        LogUtils.i(TAG, 'showFloatWindowByCall is called');
        this.createFloatWindow();
        this.shouldResetFloatWindow = ScreenAdapterUtils.getInstance().isNewFoldPhoneExternalScreen();
      } else if (callState == call.CallState.CALL_STATE_OFFHOOK &&
      ScreenAdapterUtils.getInstance().isNewFoldPhoneExternalScreen()) {
        this.createFloatWindow();
        this.shouldResetFloatWindow = true;
      }
    }
  }

  public unRegisterCallStateChange() {
    LogUtils.i(TAG, 'unRegisterCallStateChange')
    offCallStateChange()
  }

  //监听信号格数
  /**
   * Monitor the Signal info
   *
   * @param {function} callBack - call-back
   */
  registerSignalInfoChange() {
    LogUtils.i(TAG, 'registerSignalInfoChange')
    onSignalInfoChange(this.mSlotId,
      async (data: Array<radio.SignalInformation>): Promise<void> => {
        if (data.length > 0) {
          if (this.mSignal != data[0].signalLevel) {
            this.mSignal = data[0].signalLevel;
            this.mCacheSatelliteData.signal = this.mCurrentStatus ==
              SYS_STATUS_SEARCH_SATELLITE_SUCC ? this.mSignal : 0;
            LogUtils.i(TAG, 'onSignalInfoChange: ' + 'this.mSignal ' + this.mSignal +
              ' this.mCacheSatelliteData.signal ' + this.mCacheSatelliteData.signal);
            this.updateSatelliteDataListeners(this.mCacheSatelliteData);
            ReportUtil.getInstance().reportSatelliteSignalChange(this.mCurrentStatus, data[0].signalLevel, data[0].dBm);
          }
        }
      });
  }

  unRegisterSignalInfoChange() {
    LogUtils.i(TAG, 'unRegisterSignalInfoChange')
    offSignalInfoChange()
  }

  // 跳转到拨号界面
  public async jumpToDialCall() {
    LogUtils.i(TAG, 'jumpToDialCall is called');
    CallSettingGlobalContextHelper.getContext()
      .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT)?.
    startAbility({
      bundleName: 'com.ohos.contacts',
      abilityName: 'com.ohos.contacts.MainAbility',
      parameters: {
        pageFlag: 'page_flag_dialer',
        'ability.params.backToOtherMissionStack': true,
      }
    });
    this.createFloatWindow();
  }

  // 跳转到短信界面
  public async jumpToMms() {
    LogUtils.i(TAG, 'jumpToMms is called');
    CallSettingGlobalContextHelper.getContext()
      .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT)?.
    startAbility({
      bundleName: 'com.ohos.mms',
      abilityName: 'com.ohos.mms.MainAbility',
      parameters: {
        'ability.params.backToOtherMissionStack': true,
      }
    });
    this.createFloatWindow();
  }

  // 添加状态监听回调，用户状态变化是，刷新半膜态与悬浮卡片
  addStatusUpdateCallback(fn: Function): void {
    this.statusCallbacks.push(fn);
  }

  // 删除状态监听
  removeStatusUpdateCallback(fn: Function): void {
    let index: number = this.statusCallbacks.indexOf(fn);
    if (index < 0 || index >= this.statusCallbacks.length) {
      return;
    }
    this.statusCallbacks.splice(index, 1);
    LogUtils.i(TAG, 'removeTimeUpdateCallback index = ' + index);
  }

  //刷新状态变化到界面
  public updateStatusListeners() {
    this.statusCallbacks.forEach((fn: Function) => {
      fn(this.mCurrentStatus);
    });
  }

  // 添加经纬度信息监听回调
  addLocationChangeCallback(fn: Function): void {
    this.locationCallbacks.push(fn);
  }

  // 删除经纬度信息监听
  removeLocationChangeCallback(fn: Function): void {
    let index: number = this.locationCallbacks.indexOf(fn);
    if (index < 0 || index >= this.locationCallbacks.length) {
      return;
    }
    this.locationCallbacks.splice(index, 1);
    LogUtils.i(TAG, 'removeLocationChangeCallback index = ' + index);
  }

  //刷新经纬度信息变化到界面
  public updateLocationListeners() {
    this.locationCallbacks.forEach((fn: Function) => {
      fn(this.mConvertLongitude, this.mConvertLatitude);
    });
  }

  // 添加增强寻呼监听
  addAlertStateCallback(fn: Function): void {
    this.alertStatebacks.push(fn);
  }

  // 删除增强寻呼监听
  removeAlertStateCallback(fn: Function): void {
    let index: number = this.alertStatebacks.indexOf(fn);
    if (index < 0 || index >= this.alertStatebacks.length) {
      return;
    }
    this.alertStatebacks.splice(index, 1);
    LogUtils.i(TAG, 'removeAlertStateCallback index = ' + index);
  }

  //刷新增强寻呼数据到界面
  public updateAlertState() {
    this.alertStatebacks.forEach((fn: Function) => {
      fn(this.mAlertState);
    });
  }

  // 添加设备方向监听
  public addDeviceDirectionChangeCallback(fn: Function): void {
    this.deviceDirectionCallbacks.push(fn);
  }

  // 删除设备方向监听
  public removeDeviceDirectionChangeCallback(fn: Function): void {
    let index: number = this.deviceDirectionCallbacks.indexOf(fn);
    if (index < 0 || index >= this.deviceDirectionCallbacks.length) {
      return;
    }
    this.deviceDirectionCallbacks.splice(index, 1);
  }

  //刷新设备方向变化到界面
  private updateDeviceDirectionListeners() {
    this.deviceDirectionCallbacks.forEach((fn: Function) => {
      fn(this.isLandscape);
    });
  }

  // 添加寻星数据监听，寻星数据变化是，刷新半膜态与悬浮卡片
  addSatelliteDataCallback(fn: Function): void {
    this.satelliteDataCallbacks.push(fn);
  }

  // 删除寻星角度数据监听
  removeSatelliteDataCallback(fn: Function): void {
    let index: number = this.satelliteDataCallbacks.indexOf(fn);
    if (index < 0 || index >= this.satelliteDataCallbacks.length) {
      return;
    }
    this.satelliteDataCallbacks.splice(index, 1);
    LogUtils.i(TAG, 'removeTimeUpdateCallback index = ' + index);
  }

  //刷新寻星角度数据到界面
  public updateSatelliteDataListeners(satelliteData: SatelliteData) {
    this.satelliteDataCallbacks.forEach((fn: Function) => {
      fn(satelliteData);
    });
  }

  //监听飞行模式
  public addAirPlanListener() {
    try {
      addAirPlaneModeListener((data: number) => {
        if (data == 1) {
          this.publishSatelliteAirplaneToastEvent();
          LogUtils.i(TAG, 'addAirPlanListener finishSatellite');
          this.finishSatellite(false)
          ReportUtil.getInstance().reportSatelliteCallQuit(Constants.UE_AIRPLAN_QUIT);
        }
      });
    } catch (err) {
      LogUtils.i(TAG, 'addAirPlaneModeListener: err = ' + JSON.stringify(err))
    }
  }

  startSatelliteSearchTimer() {
    if (this.satelliteSearchTime != TYPE_CLOSE_SATELLITE_BY_TIMEOUT) {
      return;
    }
    if (this.satelliteSearchTimerId != -1) {
      LogUtils.i(TAG, 'should call stopSatelliteSearchTimer at first');
      this.stopSatelliteSearchTimer();
    }
    LogUtils.i(TAG, 'startSatelliteSearchTimer is called');
    this.satelliteSearchTimerId = setInterval(() => {
      this.satelliteSearchTime = this.satelliteSearchTime - 1;
      if (this.satelliteSearchTime == 0) {
        this.mAlertDialogManager.showDialogByDialogType(AlertDialogManager.TYPE_CLOSE_SATELLITE_BY_TIMEOUT);
        this.stopSatelliteSearchTimer();
      }
    }, 1 * 1000);
  }

  stopSatelliteSearchTimer() {
    LogUtils.i(TAG, 'stopSatelliteSearchTimer, satelliteSearchTimerId = ' + this.satelliteSearchTimerId);
    clearInterval(this.satelliteSearchTimerId);
    this.satelliteSearchTimerId = -1;
    this.satelliteSearchTime = TYPE_CLOSE_SATELLITE_BY_TIMEOUT;
  }

  private publishSatelliteAirplaneToastEvent() {
    LogUtils.i(TAG, 'publishSatelliteAirplaneToastEvent');
    try {
      CommonEventManager.publish('event.custom.satellite.ACTION_SATELLITE_TOAST', {
        subscriberPermissions:['ohos.permission.SET_TELEPHONY_STATE'],
        isOrdered: false,
        code: SATELLITE_TOAST_AIRPLANE_CODE
      }, () => {
      });
    } catch (err) {
      LogUtils.e(TAG, `publishSatelliteAirplaneToastEvent publish error: ${err?.code} ${err?.message}`);
    }
  }

  private publishCloseSatelliteDialogEvent() {
    LogUtils.i(TAG, 'private publishCloseSatelliteDialogEvent');
    try {
      CommonEventManager.publish('event.custom.satellite.ACTION_SATELLITE_DIALOG_CLOSE', {
        subscriberPermissions:['ohos.permission.SET_TELEPHONY_STATE'],
        isOrdered: false,
        code: SATELLITE_CLOSE_DIALOG_CODE
      }, () => {
      });
    } catch (err) {
      LogUtils.e(TAG, `publishCloseSatelliteDialogEvent publish error: ${err?.code} ${err?.message}`);
    }
  }

  /**
   * Register to listen to the change event of the primary card.
   *
   * @param onPrimaryChanged Callback interface of the primary card change event.
   */
  public subscribeSatelliteEvent() {
    LogUtils.i(TAG, 'subscribeSatelliteEvent');
    CommonEventManager.createSubscriber(satelliteSubscribeInfo, (err: BusinessError, commonEventSubscriber:
      CommonEventManager.CommonEventSubscriber) => {
      if (err) {
        LogUtils.i(TAG, 'subscribeSatelliteEvent: createSubscriber err=' + JSON.stringify(err));
        return;
      }
      primarySubscriberQueue.add(commonEventSubscriber);
      LogUtils.i(TAG, 'subscribeSatelliteEvent primarySubscriberQueue size = ' + primarySubscriberQueue.length);
      CommonEventManager.subscribe(commonEventSubscriber, (err: BusinessError,
        data: CommonEventManager.CommonEventData) => {
        if (err) {
          LogUtils.i(TAG, 'subscribeSatelliteEvent: callback err=' + JSON.stringify(err));
          return;
        }
        // 外屏创建半模态
        if (ScreenAdapterUtils.getInstance().isNewFoldPhoneExternalScreen()) {
          LogUtils.i(TAG, 'subscribeSatelliteEvent: isNewFoldPhoneExternalScreen need createNewFoldScreenDialog');
          this.createNewFoldScreenDialog();
          return;
        }
        if (data.event === 'event.custom.satellite.ACTION_SATELLITE_CONNECT' && data !== null &&
          data.parameters !== null) {
          this.createSatelliteDialog();
          LogUtils.i(TAG, 'subscribeSatelliteEvent: onSetDefaultDataEvent' + JSON.stringify(data));
        }
      });
    });
  }

  /**
   * Unregister the change event of the primary card.
   */
  public unSubscribeChangedEvent() {
    LogUtils.i(TAG, 'unSubscribePrimaryChangedEvent');
    if (primarySubscriberQueue.length === 0) {
      return;
    }
    try {
      let primarySubscriber = primarySubscriberQueue.pop();
      LogUtils.i(TAG, 'unSubscribePrimaryChangedEvent primarySubscriberQueue size = ' + primarySubscriberQueue.length);
      if (primarySubscriber === null) {
        LogUtils.i(TAG, 'unSubscribePrimaryChangedEvent primarySubscriber is null');
        return;
      }
      CommonEventManager.unsubscribe(primarySubscriber, (err: BusinessError) => {
        if (err) {
          LogUtils.i(TAG, 'unSubscribePrimaryChangedEvent failed, err = ' + JSON.stringify(err));
        }
      });
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtils.i(TAG, `unSubscribePrimaryChangedEvent failed, code is ${err.code}, message is ${err.message}`);
    }
    this.unSubscribeChangedEvent()
  }

  /**
   * Register to listen to the phone shutdown.
   */
  public subscribeShutdownEvent() {
    LogUtils.i(TAG, 'subscribeShutdownEvent');
    CommonEventManager.createSubscriber(shutdownSubscribeInfo, (err: BusinessError, commonEventSubscriber:
      CommonEventManager.CommonEventSubscriber) => {
      if (err) {
        LogUtils.e(TAG, 'subscribeShutdownEvent: createSubscriber err=' + JSON.stringify(err));
        return;
      }
      primarySubscriberQueue.add(commonEventSubscriber);
      LogUtils.i(TAG, 'subscribeShutdownEvent primarySubscriberQueue size = ' + primarySubscriberQueue.length);
      CommonEventManager.subscribe(commonEventSubscriber, (err: BusinessError,
        data: CommonEventManager.CommonEventData) => {
        if (err) {
          LogUtils.e(TAG, 'subscribeShutdownEvent: callback err=' + JSON.stringify(err));
          return;
        }
        if (data.event === 'usual.event.SHUTDOWN') {
          try {
            let context = CallSettingGlobalContextHelper.getContext()
              .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT);
            settings.setValueSync(context,  getSatelliteModeKey(this.satelliteType), '0.0');
            settings.setValueSync(context,  QUERY_SATELLITE_MODE_KEY, '0');
            this.rollBackLocationMode();
            this.unbindSatelliteService();
            LogUtils.i(TAG, 'subscribeShutdownEvent: onSetDefaultDataEvent' + JSON.stringify(data));
          } catch (err) {
            LogUtils.e(TAG, `subscribeShutdownEvent: setValueSync error: ${err?.code} ${err?.message}`);
          }
        }
      });
    });
  }

  public subscribeBatteryModeEvent() {
    LogUtils.i(TAG, 'subscribeBatteryModeEvent');
    CommonEventManager.createSubscriber(batteryModeSubscribeInfo, (err: BusinessError, commonEventSubscriber:
      CommonEventManager.CommonEventSubscriber) => {
      if (err) {
        LogUtils.e(TAG, `subscribeBatteryModeEvent: createSubscriber err= ${err.code}`);
        return;
      }
      // 监听事件加入队列，退出时统一取消订阅
      primarySubscriberQueue.add(commonEventSubscriber);
      LogUtils.i(TAG, 'subscribeBatteryModeEvent primarySubscriberQueue size = ' + primarySubscriberQueue.length);
      CommonEventManager.subscribe(commonEventSubscriber, async (err: BusinessError,
        data: CommonEventManager.CommonEventData) => {
        if (err) {
          LogUtils.e(TAG, `subscribeBatteryModeEvent: callback err= ${err.code}`);
          return;
        }
        if (data.event === 'usual.event.POWER_SAVE_MODE_CHANGED') {
          try {
            if (data.code === EXTREME_SAVE_MODE) {
              LogUtils.i(TAG,
                `subscribeBatteryModeEvent Value: ${SATELLITE_SWITCH_OFF} satelliteType: ${this.satelliteType}`);
              insert(SATELLITE_SWITCH_OFF, CallSettingGlobalContextHelper.getContext()
                .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT),
                this.satelliteType);
            }
          } catch (err) {
            LogUtils.e(TAG, `subscribeBatteryModeEvent: setValueSync error: ${err?.code} ${err?.message}`);
          }
        }
      });
    });
  }

  public registerAccelerometerListener() {
    try {
      sensor.on(sensor.SensorId.ACCELEROMETER, (data: sensor.AccelerometerResponse) => {
        let currentDegree = 0;
        if (isCorrectionEnable() && TrifoldManager.getInstance().isTripleFoldG()) {
          currentDegree = this.calcAngel(data.y, -data.x, data.z);
        } else {
          currentDegree = this.calcAngel(data.x, data.y, data.z);
        }
        if (currentDegree == -1) { // 水平方向不处理
          return;
        }
        let displayOrientation = -1;
        if (currentDegree > 300 || currentDegree <= 60) {
          displayOrientation = 0;
        } else if (currentDegree > 80 && currentDegree <= 100) {
          displayOrientation = 270;
        } else if (currentDegree > 120 && currentDegree <= 240) {
          displayOrientation = 180;
        } else if (currentDegree > 260 && currentDegree <= 280) {
          displayOrientation = 90;
        }
        if (displayOrientation != this.mDisplayOrientation) {
          if (TrifoldManager.getInstance().isTrifold()) {
            if (displayOrientation == 90 || displayOrientation == 270) {
              this.isLandscape = false;
              LogUtils.i(TAG, 'sensor ACCELEROMETER, x: ' + data.x + ' y: ' + data.y + ' z: ' + data.z);
            } else if (displayOrientation == 0 || displayOrientation == 180) {
              this.isLandscape = true;
            }
          } else {
            if (displayOrientation == 90 || displayOrientation == 270) {
              this.isLandscape = true;
              LogUtils.i(TAG, 'sensor ACCELEROMETER, x: ' + data.x + ' y: ' + data.y + ' z: ' + data.z);
            } else if (displayOrientation == 0 || displayOrientation == 180) {
              this.isLandscape = false;
            }
          }
          this.updateDeviceDirectionListeners();
          this.mDisplayOrientation = displayOrientation;
        }
      }, { interval: 100000000});
    } catch (err) {
      let e: BusinessError = err as BusinessError;
      LogUtils.e(TAG, 'registerRotationVectorListener fail, errCode: ' + e.code + ' ,msg: ' + e.message);
    }
  }

  private calcAngel(rx: number, ry: number, rz: number): number {
    let relativeX = -rx;
    let relativeY = -ry;
    let relativeZ = -rz;
    let sensorDegree: number = -1;
    let magnitude = relativeX * relativeX + relativeY * relativeY;
    if (magnitude * 4 >= relativeZ * relativeZ) {
      let oneEightyOverPi = 57.29577957855;
      let angle = Math.atan2(-relativeY, relativeX) * oneEightyOverPi;
      sensorDegree = 90 - Math.round(angle);
      while (sensorDegree >= 360) {
        sensorDegree -= 360;
      }
      while (sensorDegree < 0) {
        sensorDegree += 360;
      }
    }
    return sensorDegree;
  }

  public unRegisterAccelerometerListener() {
    try {
      LogUtils.i(TAG, 'unRegisterAccelerometerListener');
      sensor.off(sensor.SensorId.ACCELEROMETER);
    } catch (err) {
      LogUtils.e(TAG, 'unRegisterAccelerometerListener off fail, errCode: ' + err?.code + ' ,msg: ' + err?.message);
    }
  }

  getProgressAnimationIsFirst(): boolean {
    return this.isFirst;
  }

  setProgressAnimationIsFirst(isFirst: boolean) {
    this.isFirst = isFirst;
  }

  async getSlotId() {
    let context = CallSettingGlobalContextHelper.getContext()
      .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT);
    let slotId: number = Number(settings.getValueSync(context, 'satellite_slot_id', '-1'));
    LogUtils.i(TAG, 'getSlotId:' + JSON.stringify(slotId));
    return slotId;
  }

  // turn on location info switch
  enableLocation(isFromStart: boolean) {
    try {
      geoLocationManager.enableLocation((err, data) => {
        if (isFromStart) {
          this.bindSatelliteService();
        }
        if (err) {
          LogUtils.e(TAG, 'enableLocation: err=' + JSON.stringify(err));
        }
      });
    } catch (err) {
      LogUtils.e(TAG, 'errCode:' + err.code + ', errMessage:' + err.message);
    }
  }

  registerAccountListener() {
    try {
      LogUtils.i(TAG, 'registerAccountListener');
      this.accountManager.on('switching', (accountEventData) => {
        if (accountEventData?.toAccountId != MAIN_ACCOUNT_ID) {
          LogUtils.i(TAG, 'registerAccountListener finishSatellite');
          this.finishSatellite(false);
        }
      });
    } catch (err) {
      LogUtils.e(TAG, 'errCode:' + err.code + ', errMessage:' + err.message);
    }
  }

  unRegisterAccountListener() {
    try {
      LogUtils.i(TAG, 'unRegisterAccountListener');
      this.accountManager.off('switching');
    } catch (err) {
      LogUtils.e(TAG, 'errCode:' + err.code + ', errMessage:' + err.message);
    }
  }

  /**
   * 打开畅连寻星监听
   */
  public openMeetimeSatelliteListener(): void {
    // 畅连方位角&信号信息监听
    try {
      LogUtils.i(TAG, 'openMeetimeSatelliteListener.');
      notifySmcSatelliteInfo(async (satelliteInfo: SmcSatelliteData) => {
        LogUtils.i(TAG,
          'openMeetimeSatelliteListener azimuthDelta: ' + satelliteInfo.azimuthDelta + ', pitchAngleDelta: ' +
          satelliteInfo.pitchAngleDelta + ', signal: ' + satelliteInfo.cnr +
            ', sateIdx: ' + satelliteInfo.sateIdx + ', mCurrentStatus: ' + this.mCurrentStatus);
        let satelliteData: SatelliteData = {
          azimuthDelta: satelliteInfo.azimuthDelta,
          pitchAngleDelta: satelliteInfo.pitchAngleDelta,
          signal: satelliteInfo.cnr,
          sateIdx: satelliteInfo.sateIdx
        };
        this.updateSatelliteDataListeners(satelliteData);
      })
    } catch (err) {
      const error = err as BusinessError
      LogUtils.e(TAG, 'openMeetimeSatelliteListener error, code:' + error?.code + ', message:' + error?.message);
    }
  }

  /**
   * 打开过顶时间监听
   */
  public openOverTimeInfoListener(): NotifyOverTimeEnum {
    let res: NotifyOverTimeEnum = NotifyOverTimeEnum.FAIL;
    // 过顶时间监听
    try {
      res = notifyOverTimeInfo((timeArray: [number, number][]) => {
        if (!timeArray || timeArray.length < 1) {
          LogUtils.e(TAG, `notifyOverTimeInfo failed! timeInfo is null.`);
          return;
        }
        this.satUsableTimeList = [];
        timeArray.forEach((info: [number, number]) => {
          let satUsableTimeInfo: SatUsableTimeInfo = new SatUsableTimeInfo(info);
          satUsableTimeInfo && this.satUsableTimeList.push(satUsableTimeInfo);
        })
        this._applyOverTimeCallback(this.satUsableTimeList);
        LogUtils.i(TAG, 'notifyOverTimeInfo finish.');
      })
      LogUtils.i(TAG, 'openOverTimeInfoListener result:' + res);
    } catch (err) {
      const error = err as BusinessError;
      LogUtils.e(TAG, `openOverTimeInfoListener error, code: ${error?.code}, message: ${error?.message}`);
    }
    return res;
  }

  /**
   * 注册过顶时间相关回调
   */
  public registerApplyOvertimeCallback(apply: Function, query: Function): void {
    this._applyOverTimeCallback = apply;
    this._queryOverTimeCallback = query;
  }

  /**
   * 关闭畅连寻星监听
   */
  public closeMeetimeSatelliteListener(): void {
    try {
      offSmcSatelliteInfo();
    } catch (err) {
      const error = err as BusinessError
      LogUtils.e(TAG, 'closeMeetimeSatelliteListener error, code:' + error?.code + ', message:' + error?.message);
    }
  }

  /**
   * 主动请求过顶时间
   */
  public async queryOverTime(): Promise<void> {
    const res = await this.openOverTimeInfoListener()
    LogUtils.i(TAG, 'openOverTimeInfoListener queryOverTime result:' + res);
    // 注册成功才调用查询过顶时间
    if (res === NotifyOverTimeEnum.SUCCESS) {
      this._queryOverTimeCallback();
    }
  }

  /**
   * 关闭过顶时间查询监听
   */
  public closeOverTimeInfoListener(): void {
    try {
      offOverTimeInfo();
    } catch (err) {
      const error = err as BusinessError;
      LogUtils.e(TAG, `closeOverTimeInfoListener error, code:${error?.code}, message:${error?.message}`);
    }
  }

  /**
   * 更新寻星状态
   *
   * @param serviceStatus 系统服务状态
   * @param expireTime 倒计时
   */
  public updateSearchSatelliteStatus(serviceStatus: string, expireTime: number): void {
    LogUtils.i(TAG, 'updateSearchSatelliteStatus serviceStatus: ' + serviceStatus + ', expireTime: ' + expireTime);
    if (serviceStatus === SatelliteOperationType.OPERATION_TYPE_SYS_STATUS_SEARCHING) {
      // 寻星中状态
      if (!expireTime || expireTime === 0) {
        // 状态如果是正在加载，则更新为寻星中
        if (this.mCurrentStatus == SYS_STATUS_WAIT_LOADING || this.mCurrentStatus == SYS_STATUS_WAIT_BLOCKING ||
          this.mCurrentStatus == SYS_STATUS_SATELLITE_CONNECTING) {
          this.setCurrentStatus(SYS_STATUS_SEARCHING_SATELLITE);
          this.updateStatusListeners();
          // 运营打点-寻星中
          this.sendSatelliteEventToMeetime(SatelliteState.STATE_SEARCHING);
        }
      } else {
        this.setConnectingTime(expireTime);
        this.setCurrentStatus(SYS_STATUS_SATELLITE_CONNECTING);
        this.updateStatusListeners();
        // 运营打点-卫星连接中
        this.sendSatelliteEventToMeetime(SatelliteState.STATE_CONNECTION);
      }
    } else if (serviceStatus === SatelliteOperationType.OPERATION_TYPE_SYS_STATUS_BLOCKING) {
      this.setCurrentStatus(SYS_STATUS_WAIT_BLOCKING);
      this.updateStatusListeners();
    } else if (serviceStatus === SatelliteOperationType.OPERATION_TYPE_SYS_STATUS_SENDING) {
      // 发送中状态
      this.setTime(expireTime);
      this.setCurrentStatus(SYS_STATUS_SEARCH_SATELLITE_SUCC);
      this.updateStatusListeners();
      // 运营打点-发送中
      this.sendSatelliteEventToMeetime(SatelliteState.STATE_SENDING);
    } else if (serviceStatus === SatelliteOperationType.OPERATION_TYPE_SYS_STATUS_RECEIVING) {
      // 接收中状态
      this.setTime(expireTime);
      this.setCurrentStatus(RECEIVER_STATUS_RECEIVING);
      this.updateStatusListeners();
      // 运营打点-接收中
      this.sendSatelliteEventToMeetime(SatelliteState.STATE_RECEIVING);
    }
  }

  startSatelliteConnectTimer() {
    this.connectTime = this.getConnectingTime();
    LogUtils.i(TAG, 'startConnectTimer connectTime = ' + this.connectTime)
    if (SatelliteSearchManager.getInstance().getIsFromMeetime() && this.connectTime === 0) {
      return;
    }
    if (this.isConnecting) {
      return;
    }
    this.isConnecting = true;
    this.connectTimerId = setInterval(() => {
      this.connectTime = this.connectTime - 1;
      this.updateSatelliteConnectTimeCallback(this.connectTime);
      if (this.connectTime == 0) {
        this.stopConnectTimer();
      }
    }, COUNTDOWN_TIMER);
  }

  stopConnectTimer() {
    if (this.isConnecting) {
      this.isConnecting = false;
      this.rollBackConnectTime();
      clearInterval(this.connectTimerId);
    }
  }

  rollBackConnectTime() {
    if (this.isFromMeetime) {
      this.connectTime = 0;
    } else if (this.isTianTong() || this.connectTime === 0) {
      this.connectTime = this.defaultConnectTime;
    }
  }

  /**
   * 将寻星事件发送给畅连
   *
   * @param action 寻星事件
   */
  public sendSatelliteEventToMeetime(action: string): void {
    if (!this.session) {
      LogUtils.e(TAG, 'sendSatelliteEventToMeetime session is invalid.');
      return;
    }
    try {
      this.session.sendData({
        action: action
      })
    } catch (err) {
      const error = err as BusinessError
      LogUtils.e(TAG, `sendSatelliteEventToMeetime error, code: ${error?.code}, message: ${error?.message}`);
    }
  }

  /**
   * Whether to update satellite data
   *
   * @returns true/false
   */
  public isUpdateSatelliteData(): boolean {
    if (!this.getIsFromMeetime()) {
      return true;
    }
    if (this.mCurrentStatus === SYS_STATUS_SEARCHING_SATELLITE ||
      this.mCurrentStatus === SYS_STATUS_SATELLITE_CONNECTING ||
      this.mCurrentStatus === SYS_STATUS_SEARCH_SATELLITE_SUCC || this.mCurrentStatus === RECEIVER_STATUS_RECEIVING ||
      this.mCurrentStatus === SYS_STATUS_SATELLITE_KEEPING) {
      return true;
    }
    return false;
  }

  /**
   * Add satellite need end callback
   *
   * @param fn Function
   */
  public addSatelliteNeedEndCallback(fn: Function): void {
    this.satelliteNeedEndCallbacks.push(fn);
  }

  /**
   * Remove satellite need end callback
   *
   * @param fn Function
   */
  public removeSatelliteNeedEndCallback(fn: Function): void {
    let index: number = this.satelliteNeedEndCallbacks.indexOf(fn);
    if (index < 0 || index >= this.satelliteNeedEndCallbacks.length) {
      LogUtils.e(TAG, 'removeSatelliteNeedEndCallback index is out of range.');
      return;
    }
    this.satelliteNeedEndCallbacks.splice(index, DELETE_COUNT_ONE);
    LogUtils.i(TAG, 'removeSatelliteNeedEndCallback index = ' + index);
  }

  /**
   * Update satellite need end callback
   *
   * @param isSatelliteNeedEnd true/false
   */
  public updateSatelliteNeedEndCallback(isSatelliteNeedEnd: boolean) {
    this.satelliteNeedEndCallbacks.forEach((fn: Function) => {
      fn(isSatelliteNeedEnd);
    });
  }

  /**
   * Add satellite connect time callback
   *
   * @param fn Function
   */
  public addSatelliteConnectTimeCallback(fn: Function): void {
    this.satelliteConnectTimeCallbacks.push(fn);
  }

  /**
   * Remove satellite connect time callback
   *
   * @param fn Function
   */
  public removeSatelliteConnectTimeCallback(fn: Function): void {
    let index: number = this.satelliteConnectTimeCallbacks.indexOf(fn);
    if (index < 0 || index >= this.satelliteConnectTimeCallbacks.length) {
      LogUtils.e(TAG, 'removeSatelliteConnectTimeCallback index is out of range.');
      return;
    }
    this.satelliteConnectTimeCallbacks.splice(index, DELETE_COUNT_ONE);
    LogUtils.i(TAG, 'removeSatelliteConnectTimeCallback index = ' + index);
  }

  /**
   * Update satellite connect time callback
   *
   * @param connectTime satellite connect time
   */
  public updateSatelliteConnectTimeCallback(connectTime: number) {
    this.satelliteConnectTimeCallbacks.forEach((fn: Function) => {
      fn(connectTime);
    });
  }

  /**
   * Finish meetime satellite
   */
  public finishMeetimeSatellite(): void {
    LogUtils.i(TAG, 'finishMeetimeSatellite.');
    // reset data
    this.mCurrentStatus = SYS_STATUS_DEFAULT;
    this.connectTime = 0;
    this.stopConnectTimer();
    SatelliteUtils.updateSuccessDelta(0, 0);
    this.time = SENDING_TIME;
    this.showReConnect = false;
    this.showReCalibrate = false;
    this.showReSearch = false;
  }

  public subscribeWindowAllEvent(windowName: string) {
    if (!SystemMode.getInstance().isModePenglai()) {
      return;
    }
    this.subscribeWindowShowEvent(windowName);
    this.subscribeWindowHideEvent(windowName);
  }

  public async subscribeWindowShowEvent(windowName: string) {
    this.windowShowEvent = await createSubscriber(EVENT_SATELLITE_WINDOW_SHOW);
    subscribeEvent(async (data?: string) => {
      const win = window.findWindow(windowName);
      if (!win.isWindowShowing()) {
        await win.showWindow();
        await window.findWindow(ALERT_DIALOG)?.showWindow();
      }
    }, this.windowShowEvent);
  }

  public unsubscribeWindowAllEvent() {
    if (!SystemMode.getInstance().isModePenglai()) {
      return;
    }
    unSubscribeEvent(this.windowShowEvent);
    unSubscribeEvent(this.windowHideEvent);
  }

  private async subscribeWindowHideEvent(windowName: string) {
    this.windowHideEvent = await createSubscriber(EVENT_SATELLITE_WINDOW_HIDE);
    subscribeEvent(async (data?: string) => {
      if (window.findWindow(windowName).isWindowShowing()) {
        await window.findWindow(windowName).hide();
        await window.findWindow(ALERT_DIALOG)?.hide();
      }
    }, this.windowHideEvent);
  }

  public async hideWindowForPenglai(): Promise<void> {
    if (!SystemMode.getInstance().isModePenglai()) {
      return;
    }
    try {
      LogUtils.i(TAG, `hideWindowForPenglai: ${this.isSatelliteDialogShow},  ${this.isFloatWindowShow}`);
      if (this.isSatelliteDialogShow && !window.findWindow(SATELLITE_DIALOG)?.isWindowShowing()) {
        await window.findWindow(ALERT_DIALOG).hide();
      }
      if (this.isFloatWindowShow && !window.findWindow(SATELLITE_FLOAT_WINDOW)?.isWindowShowing()) {
        await window.findWindow(ALERT_DIALOG).hide();
      }
    } catch (e) {
      LogUtils.e(TAG, `hideWindow exp= ${e.message}`);
    }
  }

  public getWindowType(): window.WindowType {
    if (SystemMode.getInstance().isModePenglai()) {
      return window.WindowType.TYPE_GLOBAL_SEARCH | window.WindowType.TYPE_SYSTEM_TOAST;
    }
    return window.WindowType.TYPE_GLOBAL_SEARCH;
  }

  /**
   * 注册监听的callback参数要采用对象传递.
   * 若使用匿名函数注册，每次调用会创建一个新的底层对象，引起内存泄漏问题。
   */
  private callback: Callback<display.FoldDisplayMode> = (data: display.FoldDisplayMode) => {
    SatelliteDialogManager.getInstance().resizeDisplaySize();
    SatelliteFloatWindowManager.getInstance().resizeDisplaySize();
    SatelliteStrongNotifyManager.getInstance().resizeDisplaySize();
    LogUtils.i(TAG, `Listening enabled. Data: ${data}`);
  };

  private addFoldStatusListener(): void {
    LogUtils.i(TAG, `addFoldStatusListener`);
    if (!this.isFoldable()) {
      LogUtils.i(TAG, `addFoldStatusListener return`);
      return;
    }
    try {
      this.foldStatus = display.getFoldStatus()
      AppStorage.setOrCreate<number>('foldStatus', this.foldStatus);
      display.on('foldStatusChange', (foldStatus: display.FoldStatus) => {
        LogUtils.i(TAG, 'foldStatusChange foldStatus=' + foldStatus);
        AppStorage.setOrCreate<number>('foldStatus', foldStatus);
        if ((foldStatus === display.FoldStatus.FOLD_STATUS_FOLDED &&
          this.foldStatus !== display.FoldStatus.FOLD_STATUS_FOLDED) ||
          (foldStatus !== display.FoldStatus.FOLD_STATUS_FOLDED &&
            this.foldStatus === display.FoldStatus.FOLD_STATUS_FOLDED)) {
          this.updateDialogAndFloatWindow();
        }
        this.foldStatus = foldStatus;
        this.updateNewScreenStatus();
      })
      LogUtils.i(TAG, 'addFoldStatusListener success');
    } catch (exception) {
      LogUtils.e(TAG, 'foldStatusChange exp=' + JSON.stringify(exception));
    }
    this.addFoldDisplayModeChange();
    if (!ScreenAdapterUtils.isTrifoldPhone()) {
      return;
    }
    try {
      display.on('change', (id: number) => {
        let orientation: display.Orientation;
        try {
          orientation = display.getDefaultDisplaySync().orientation;
        } catch (error) {
          LogUtils.e(TAG, 'Error getting default display');
          return;
        }
        if (orientation === display.Orientation.LANDSCAPE || orientation === display.Orientation.LANDSCAPE_INVERTED) {
          this.isLandscape = true;
        } else {
          this.isLandscape = false;
        }
      })
    } catch (error) {
      LogUtils.e(TAG, 'An exception occurs in the on method of display.');
    }
  }

  private addFoldDisplayModeChange() {
    try {
      display.on('foldDisplayModeChange', this.callback);
    } catch (err) {
      LogUtils.e(TAG, `foldStatusChange exp, code: ${err?.code}, message: ${err?.message}`);
    }
  }

  private async updateNewScreenStatus() {
    try {
      if (ScreenAdapterUtils.isNewFormFoldPhone()) {
        let isNewFoldPhoneExternalScreen: boolean = ScreenAdapterUtils.getInstance().isNewFoldPhoneExternalScreen();
        LogUtils.i(TAG, `updateNewScreenStatus isNewFoldPhoneExternalScreen ${isNewFoldPhoneExternalScreen}`);
        if (isNewFoldPhoneExternalScreen) {
          // 如果是新折叠外屏，需要提示外屏不支持卫星通信
          this.createNewFoldScreenDialog();
        } else {
          // 如果非新折叠外屏，外屏弹框需要在展开态时销毁
          this.closeNewFoldScreenDialog();
          if (this.isFloatWindowShow && this.shouldResetFloatWindow) {
            await this.mSatelliteFloatWindowManager.closeFloatWindow();
            await this.mSatelliteFloatWindowManager.createFloatWindow();
            AlertDialogManager.getInstance().showDialogWindow();
            this.shouldResetFloatWindow = false;
            return;
          }
        }
        emitter.emit({
          eventId: EMIT_NEW_FOLD_PHONE_EXTERNAL_EVENT_ID
        }, {
          data: {
            'isNewFoldPhoneExternalScreen': isNewFoldPhoneExternalScreen
          }
        });
      }
    } catch (e) {
      LogUtils.e(TAG, 'updateNewScreenStatus exp=' + JSON.stringify(e));
    }
  }

  async hideWindow(windowName: string): Promise<void> {
    try {
      if (ScreenAdapterUtils.getInstance().isNewFoldPhoneExternalScreen()) {
        await window.findWindow(windowName).hide();
        LogUtils.i(TAG, 'hideWindow ' + windowName);
      }
    } catch (e) {
      LogUtils.e(TAG, 'hideWindow exp=' + JSON.stringify(e));
    }
  }

  private isFoldable(): boolean {
    let ret: boolean = false;
    try {
      ret = display.isFoldable();
    } catch (exception) {
      LogUtils.e(TAG, 'Failed to check is foldable or not. exp=' + JSON.stringify(exception));
    }
    if (ret === undefined || !ret) {
      LogUtils.i(TAG, 'Failed to check is foldable or not.');
      return false;
    }
    return true;
  }

  private removeFoldStatusListener(): void {
    if (!this.isFoldable()) {
      return;
    }
    try {
      display.off('foldStatusChange');
      display.off('foldDisplayModeChange', this.callback);
      LogUtils.i(TAG, 'removeFoldStatusListener success');
    } catch (exception) {
      LogUtils.e(TAG, 'Failed to unregister foldStatusChange. Code: ' + JSON.stringify(exception));
    }
	try {
      display.off('change');
      LogUtils.i(TAG, 'remove change success');
    } catch (exception) {
      LogUtils.e(TAG, 'Failed to unregister change. Code: ' + JSON.stringify(exception));
    }
  }

  private startBackgroundTaskResourceApply() {
    try {
      let request: backgroundTaskManager.EfficiencyResourcesRequest = {
        resourceTypes: backgroundTaskManager.ResourceType.CPU, // 资源类型是CPU资源，保证应用进程不被挂起
        isApply: true, // 申请资源
        timeOut: 0, // 超时时间，超过超时时间后资源自动释放
        reason: 'satelliteService need', // 申请原因
        isPersist: true, // 永久持有资源
        isProcess: false, // 在应用级别申请
      };
      backgroundTaskManager.applyEfficiencyResources(request);
      LogUtils.i(TAG, 'Succeeded in invoking applyEfficiencyResources.');
    } catch (err) {
      LogUtils.e(TAG, 'Failed to startBackgroundTaskResourceApply. Code: ' + JSON.stringify(err));
    }
  }

  private endBackgroundTaskReleaseResources() {
    try {
      // 部分释放能效资源
      let request: backgroundTaskManager.EfficiencyResourcesRequest = {
        resourceTypes: backgroundTaskManager.ResourceType.CPU,
        isApply: false, // 释放资源
        timeOut: 0,
        reason: 'apply',
        isPersist: true,
        isProcess: false, // 在应用级别释放资源
      };
      backgroundTaskManager.applyEfficiencyResources(request);
      LogUtils.i(TAG, 'end BackgroundTask Release Resources.');
    } catch (err) {
      LogUtils.e(TAG, 'Failed to endBackgroundTaskReleaseResources. Code: ' + JSON.stringify(err));
    }
  }
}

export class SatelliteData {
  private static sSatelliteData: SatelliteData;
  public azimuthDelta: number = 0;
  public pitchAngleDelta: number = 0;
  public signal: number = 0;
  public sateIdx: number = -1;
  public sateShow?: number = 0;
  public availableTime?: number = -1;
  public guideAzimuth?: number = 0;
  public guidePitch?: number = -1;

  public static getInstance(): SatelliteData {
    if (!SatelliteData.sSatelliteData) {
      SatelliteData.sSatelliteData = new SatelliteData();
    }
    return SatelliteData.sSatelliteData;
  }
}

export class SmcSatelliteData {
  public azimuthDelta: number = 0;
  public pitchAngleDelta: number = 0;
  public cnr: number = 0;
  public sateIdx: number = -1;
}

export class SatelliteStatus {
  public serviceStatus: number = 0;
  public convertLongitude: number = 0;
  public convertLatitude: number = 0;
  public cause: number = 0;
  public alignSectorPitch: number = 0;
  public alignSectorAzimuth: number = 0;
  public alertState: number = 0;
  public height?: number = 0;
  public cellularDetectionRes: number = 0;
}

export class SatUsableTimeInfo {
  public startTime: number = -1;
  public startTimeList: string[] = [];
  public endTime: number = -1;
  public endTimeList: string[] = [];

  constructor(info: [number, number]) {
    this.startTime = info[0];
    this.endTime = info[1];
    this.startTimeList = DateUtil.getTimeList(info[0]);
    this.endTimeList = DateUtil.getTimeList(info[1]);
  }
}
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

import { display, curves, window } from '@kit.ArkUI';
import { LogUtils, ReportUtil } from '@ohos/common/CommonIndex';
import sensor from '@ohos.sensor'
import BusinessError from '@ohos.base';
import { UIExtensionContentSession } from '@kit.AbilityKit';
import CommonEventManager from '@ohos.commonEventManager';
import { emitter } from '@kit.BasicServicesKit';
import { ACCURACY_FINISH,
  MAX_FONT_SCALE,
  RECEIVER_STATUS_FAIL,
  RECEIVER_STATUS_NULL,
  RECEIVER_STATUS_RECEIVING,
  RECEIVER_STATUS_SUCCESS,
  SatelliteDirection,
  SatelliteFromType,
  SatelliteLevel,
  SatelliteState,
  SATELLITE_DIALOG,
  SATELLITE_TOAST_OFF_CODE,
  SEND_STATUS_FAIL,
  SEND_STATUS_SENT,
  SEND_STATUS_SUCC,
  SYS_DISCONNECT,
  SYS_STATUS_DEFAULT,
  SYS_STATUS_SATELLITE_CONNECTING,
  SYS_STATUS_SATELLITE_KEEPING,
  SYS_STATUS_SEARCHING_SATELLITE,
  SYS_STATUS_SEARCH_SATELLITE_FAIL,
  SYS_STATUS_SEARCH_SATELLITE_SUCC,
  SYS_STATUS_WAIT_BLOCKING,
  SYS_STATUS_WAIT_CALIBRATING,
  SYS_STATUS_WAIT_LOADING} from '../../common/constant/SatelliteSearchConst';
import ScreenAdapterUtils from '../../common/utils/ScreenAdapterUtils';
import SatelliteSearchManager, { SatelliteData } from '../../manager/SatelliteSearchManager';
import { EMIT_NEW_FOLD_PHONE_EXTERNAL_EVENT_ID } from '../../common/constant/CallSettingsConstant';
import AlertDialogManager from '../../manager/AlertDialogManager';
import SatelliteUtils from '../../common/utils/SatelliteUtils';
import { HyacinthSearchTop } from '../../components/hyacinth/HyacinthSearchTop';
import { HyacinthSearchProgress } from '../../components/hyacinth/HyacinthSearchProgress';
import { HyacinthSearch } from '../../components/hyacinth/HyacinthSearch';
import { HyacinthCalibrate } from '../../components/hyacinth/HyacinthCalibrate';
import { HyacinthLandscapeRemind } from '../../components/hyacinth/HyacinthLandscapeRemind';
import { isTablet } from '../../common/utils/DeviceTypeUtils';
import { DisplayUtil, hDividedW08, hDividedW13 } from '../../common/utils/DisplayUtil';
import { TrifoldManager } from '../../manager/TrifoldManager';
import { SatelliteSearchProgress } from '../../components/SatelliteComponents/SatelliteSearchProgress';
import { HyacinthSearchBottom } from '../../components/hyacinth/HyacinthSearchBottom';


const localStorage = LocalStorage.getShared();

const TAG = 'HyacinthDialog';

@Entry
@Component
export default struct HyacinthDialog {
  @Provide('session') session: UIExtensionContentSession | undefined = undefined;
  @State parameters: Record<string, Object> | undefined = undefined;
  // 来自畅连拉起弹框
  @State from: string = '';
  // 操作类型：发送/接收
  @State operationType: string = '';
  // sensor上报的校准精度
  @State calibrateAccuracy: number = 0;
  @State isShow: boolean = true;
  @State sheetHeight: number = 700;
  @State @Watch('compassControl') currentStatus: number = SYS_STATUS_DEFAULT;
  @State mAlertState: number = 0;
  @State isFoldStatusFolded: number = display.FoldStatus.FOLD_STATUS_UNKNOWN;
  // 重新连接
  @State showReConnect: boolean = false;
  // 重新校准磁场
  @State showReCalibrate: boolean = false;
  // 重新寻星
  @State showReSearch: boolean = false;
  // 是否跳过校准
  @State isSkipCalibrate: boolean = false;
  @State currentAccuracy: number = 0;
  @State @Watch('drawDirectArc') mAzimuthDelta: number = 0;
  @State availableTime: number = 0;
  @State @Watch('compassControl') mDirection: number = SatelliteDirection.NONE;
  @State mPitchDelta: number = 0;
  @State winkSatelliteOp: number = 0;
  @State mSatelliteData: SatelliteData | undefined = undefined;
  @State mOldSatelliteData: SatelliteData | undefined = undefined;
  // 卫星切换次数
  @State switchSatelliteTimes: number = 0;
  // 卫星切换时，老卫星的方位角
  @State mOldAzimuthDelta: number = 0;
  @State mBackAzimuthDelta: number = 0;
  @State showSatelliteChangeConnect: boolean = false;
  satelliteManager: SatelliteSearchManager = SatelliteSearchManager.getInstance();
  // 位置信息刷新
  @State location: Resource = $r('app.string.location_north_west')
  // 连接超时，自动切换卫星提示语开关
  @State changeSatelliteOp: number = 0;
  @State dialogWidth: number = 0;
  @State dialogHeight: number = 0;
  @State displayHeight: number = 0;
  @State displayWidth: number = 0;
  @State widthAspectRatio: number = 2.15;
  @State satelliteSearchWidth: number = 360;
  @State scaleSize: number = 1;
  @State isSatelliteNeedEnd: boolean = false;
  @State @Watch('compassControl') isShowOrientationRemind: boolean = false;
  @State dialogCompassOp: number = 0;
  @State backgroundBaseOp: number = 0;
  @StorageProp('currentColorMode') @Watch('drawSmcBackgroundImg') currentMode: number = 0;
  private statusUpdateCallback: Function | undefined;
  private satelliteDataCallback: Function | undefined;
  private alertStateCallback: Function | undefined;
  private locationChangeCallback: Function | undefined;
  private locationLongitude: number = 0;
  private locationLatitude: number = 0;
  private deviceDirChangeCallback: Function | undefined;
  private sateIndex: number = -1;
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private backgroundImg: ImageBitmap = new ImageBitmap('/common/images/meetime_search_sate_shading.png');
  private satelliteNeedEndCallback: Function | undefined;
  private isNewFormFoldPhone = ScreenAdapterUtils.isNewFormFoldPhone();
  private isNewFoldPhoneScreen: boolean = false;
  private isFocused: boolean = true;

  // 扇形角度
  private directionAngle: number = 120;

  aboutToAppear(): void {
    this.directionAngle = SatelliteUtils.getDefaultAngles();
    SatelliteSearchManager.getInstance().hideWindow(SATELLITE_DIALOG);
    this.initData();
    if (this.from === SatelliteFromType.SATELLITE_FROM_TYPE_MEETIME ||
      this.from === SatelliteFromType.SATELLITE_FROM_TYPE_MMS) {
      SatelliteSearchManager.getInstance().setIsFromMeetime(true);
      this.addSatelliteNeedEndCallback();
    } else {
      SatelliteSearchManager.getInstance().setIsFromMeetime(false);
      window.findWindow('satelliteDialog')?.setWindowBackgroundColor('#00000000');
    }
    this.currentStatus = this.satelliteManager.getCurrentStatus();
    this.mSatelliteData = this.satelliteManager.getCacheSatelliteData();
    this.mAlertState = this.satelliteManager.getAlertState();
    this.showReConnect = this.satelliteManager.getShowReconnect();
    this.showReCalibrate = this.satelliteManager.getShowReCalibrate();
    this.showReSearch = this.satelliteManager.getShowReSearch();
    this.mAzimuthDelta = this.mSatelliteData?.azimuthDelta;
    this.updateDirection();
    LogUtils.i(TAG, 'aboutToAppear currentStatus = ' + this.currentStatus);
    try {
      this.displayWidth = display.getDefaultDisplaySync().width;
      this.displayHeight = display.getDefaultDisplaySync().height;
      this.widthAspectRatio = this.displayHeight != 0 ? this.displayHeight / this.displayWidth : 2.15;
      this.isFoldStatusFolded = display.getFoldStatus();
    } catch (err) {
      LogUtils.e(TAG, `aboutToAppear getDefaultDisplaySync error: ${err?.code} ${err?.message}`);
    }
    this.satelliteSearchWidth = this.getSatelliteSearchWidth();
    this.scaleSize = this.satelliteSearchWidth / 360;
    if (this.currentStatus == SYS_STATUS_DEFAULT || this.currentStatus == SYS_STATUS_WAIT_CALIBRATING) {
      if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
        if (this.calibrateAccuracy >= ACCURACY_FINISH) {
          this.updateStateToWaitLoading();
        } else {
          this.currentStatus = SYS_STATUS_WAIT_CALIBRATING;
          // 运营打点-校准中
          SatelliteSearchManager.getInstance().sendSatelliteEventToMeetime(SatelliteState.STATE_CALIBRATING);
        }
        this.satelliteManager.setCurrentStatus(this.currentStatus);
      }
      this.registerAccuracyLevelListener();
    }
    // 添加状态变化监听接口
    this.addStatusCallback();
    // 添加寻星角度数据变化监听接口
    this.addSatelliteDataCallback();
    if (!SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      // 添加经纬度变化监听接口
      this.addLocationCallback();
      this.locationLongitude = this.satelliteManager.getLocationLongitude();
      this.locationLatitude = this.satelliteManager.getLocationLatitude();
      this.getLocationInfo(this.locationLongitude, this.locationLatitude);
    }
    SatelliteSearchManager.getInstance().refreshUIOrientation();
    this.isShowOrientationRemind = SatelliteSearchManager.getInstance().isShowOrientationRemind();
    this.initCompass();
    this.addDeviceDirChangeCallback();
    this.addAlertStateCallback();
    this.addTouchOutsideListener();
    if (this.isNewFormFoldPhone) {
      this.isNewFoldPhoneScreen = ScreenAdapterUtils.getInstance().isNewFoldPhoneExternalScreen();
      this.addEmitterListener();
    }
  }

  // 给direction 赋值
  updateDirection() {
    let guideAzimuth = this.mSatelliteData?.guideAzimuth;
    if (guideAzimuth === undefined || guideAzimuth === 0) {
      this.mDirection = SatelliteDirection.NONE;
      return;
    }

    if (this.mAzimuthDelta > 0) {
      this.mDirection = SatelliteDirection.RIGHT;
    } else if (this.mAzimuthDelta < 0) {
      this.mDirection = SatelliteDirection.LEFT;
    } else {
      this.mDirection = SatelliteDirection.NONE;
    }
    LogUtils.i(TAG, `getSateRotationAngles get direct: ${this.mDirection}`);
  }

  initData(): void {
    if (localStorage) {
      this.session = localStorage.get<UIExtensionContentSession>('session');
      SatelliteSearchManager.getInstance().setSession(this.session);
      this.parameters = localStorage.get<Record<string, Object>>('parameters');
      this.from = this.parameters?.from as string;
      this.operationType = this.parameters?.operationType as string;
      this.calibrateAccuracy = this.parameters?.calibrateAccuracy as number;
    }
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear');
    // 移除状态监听回调接口
    this.removeStatusCallback();
    this.removeSatelliteDataCallback();
    this.removeLocationCallback();
    try {
      sensor.off(sensor.SensorId.ORIENTATION);
    } catch (err) {
      LogUtils.e(TAG, 'aboutToDisappear off fail, errCode: ' + err?.code + ' ,msg: ' + err?.message);
    }
    this.removeDeviceDirListener();
    this.removeAlertState();
    this.removeTouchOutsideListener();
    if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      this.removeSatelliteNeedEndCallback();
    }
    if (this.isNewFormFoldPhone) {
      this.removeEmitterListener();
    }
    ReportUtil.getInstance().reportHyacinthUseTime();
  }

  private callback = (data: emitter.EventData): void => {
    this.isNewFoldPhoneScreen = data?.data?.isNewFoldPhoneExternalScreen;
    LogUtils.i(TAG, 'emitter.on, isNewFoldPhoneScreen = ' + this.isNewFoldPhoneScreen);
    this.newFoldPhoneChange();
  }

  addEmitterListener() {
    emitter.on({ eventId: EMIT_NEW_FOLD_PHONE_EXTERNAL_EVENT_ID }, this.callback);
  }

  removeEmitterListener() {
    emitter.off(EMIT_NEW_FOLD_PHONE_EXTERNAL_EVENT_ID, this.callback);
  }

  newFoldPhoneChange() {
    try {
      if (this.isNewFoldPhoneScreen) {
        window.findWindow(SATELLITE_DIALOG).hide();
        LogUtils.i(TAG, `hide window`);
      } else {
        window.findWindow(SATELLITE_DIALOG).showWindow()
          .then(() => {
            AlertDialogManager.getInstance().showDialogWindow();
          });
        LogUtils.i(TAG, `show window`);
      }
    } catch (err) {
      LogUtils.e(TAG, `newFoldPhoneChange error:${err?.code}:${err?.message}`);
    }
  }

  registerAccuracyLevelListener() {
    try {
      LogUtils.i(TAG, 'registerAccuracyLevelListener is called');
      sensor.on(sensor.SensorId.ORIENTATION, (data: sensor.OrientationResponse) => {
        if (this.currentAccuracy !== data.accuracy) {
          LogUtils.i(TAG, 'registerAccuracyLevelListener accuracy: ' + data.accuracy);
        }
        this.currentAccuracy = data.accuracy;
        if (this.currentStatus == SYS_STATUS_DEFAULT) {
          if (data.accuracy >= ACCURACY_FINISH) {
            this.updateStateToWaitLoading();
            ReportUtil.getInstance().reportEnterSatelliteIsNeedCalibration(0);
          } else {
            this.currentStatus = SYS_STATUS_WAIT_CALIBRATING;
            ReportUtil.getInstance().reportEnterSatelliteIsNeedCalibration(1);
            if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
              // 运营打点-校准中
              SatelliteSearchManager.getInstance().sendSatelliteEventToMeetime(SatelliteState.STATE_CALIBRATING);
            }
          }
          this.satelliteManager.setCurrentStatus(this.currentStatus);
        } else if (this.currentStatus == SYS_STATUS_WAIT_CALIBRATING) {
          if (data.accuracy >= ACCURACY_FINISH) {
            LogUtils.i(TAG, 'registerAccuracyLevelListener skip calibrate, accuracy is: ' + data.accuracy);
            this.isSkipCalibrate = true;
            this.updateStateToWaitLoading();
            this.satelliteManager.setCurrentStatus(SYS_STATUS_WAIT_LOADING);
            ReportUtil.getInstance().reportEnterSatelliteIsNeedCalibration(0);
          }
        }
      }, { interval: 1000000000 });
    } catch (error) {
      let e: BusinessError.BusinessError = error as BusinessError.BusinessError;
      LogUtils.i(TAG, `Failed to invoke on. Code: ${e.code}, message: ${e.message}`);
    }
  }

  // 更新状态到 加载中
  updateStateToWaitLoading() {
    LogUtils.i(TAG, 'updateStateToWaitLoading');
    this.currentStatus = SYS_STATUS_WAIT_LOADING;
    if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      // 运营打点-加载中
      SatelliteSearchManager.getInstance().sendSatelliteEventToMeetime(SatelliteState.STATE_LOADING);
    }
    try {
      sensor.off(sensor.SensorId.ORIENTATION);
    } catch (err) {
      LogUtils.e(TAG, 'updateStateToWaitLoading off fail, errCode: ' + err?.code + ' ,msg: ' + err?.message);
    }
  }

  //添加状态变化监听接口
  addStatusCallback() {
    if (this.statusUpdateCallback != undefined) {
      LogUtils.i(TAG, 'addStatusCallback: statusUpdateCallback has been added');
      return;
    }
    this.statusUpdateCallback = ((status: number) => {
      LogUtils.i(TAG, 'satelliteManager.addStatusUpdateCallback is called, status = ' + status);
      this.showReConnect = this.satelliteManager.getShowReconnect();
      this.currentStatus = status;
      if (this.currentStatus == SYS_STATUS_WAIT_LOADING) {
        try {
          sensor.off(sensor.SensorId.ORIENTATION);
        } catch (err) {
          LogUtils.e(TAG, 'statusUpdateCallback off fail, errCode: ' + err?.code + ' ,msg: ' + err?.message);
        }
      } else if (this.currentStatus == SYS_STATUS_SEARCH_SATELLITE_SUCC) {
        ReportUtil.getInstance().reportHyacinthConnectTime();
      }
    });
    this.satelliteManager.addStatusUpdateCallback(this.statusUpdateCallback)
  }

  //移除状态监听回调接口
  removeStatusCallback() {
    if (this.statusUpdateCallback) {
      this.satelliteManager.removeStatusUpdateCallback(this.statusUpdateCallback);
      this.statusUpdateCallback = undefined;
    }
  }

  //添加寻星角度数据监听接口
  addSatelliteDataCallback() {
    if (this.satelliteDataCallback != undefined) {
      LogUtils.i(TAG, 'addSatelliteDataCallback: callTimeListener has been added');
      return;
    }
    this.satelliteDataCallback = ((satelliteData: SatelliteData) => {
      if (this.showReConnect && this.currentStatus == SYS_STATUS_SEARCH_SATELLITE_FAIL) {
        return;
      }
      LogUtils.i(TAG, `addSatelliteDataCallback data, {sateShow:${satelliteData.sateShow},
       guideAzimuth:${satelliteData.guideAzimuth}, guidePitch:${satelliteData.guidePitch},
       azimuthDelta:${satelliteData.azimuthDelta}, pitchAngleDelta:${satelliteData.pitchAngleDelta},
       sateIdx:${satelliteData.sateIdx}, availableTime:${satelliteData.availableTime}}`)
      this.mBackAzimuthDelta = this.mAzimuthDelta;
      this.mSatelliteData = satelliteData;
      this.mAzimuthDelta = this.mSatelliteData?.azimuthDelta;
      if (satelliteData.availableTime != undefined && satelliteData.availableTime >= 0) {
        this.availableTime = satelliteData.availableTime
      }
      this.updateDirection();
      this.setIsConTimedOut(satelliteData);
    });
    this.satelliteManager.addSatelliteDataCallback(this.satelliteDataCallback);
  }

  private setIsConTimedOut(satelliteData: SatelliteData): void {
    if (!satelliteData) {
      LogUtils.e(TAG, 'setIsConTimedOut satelliteData is null.');
      return;
    }
    let sateIdx: number = satelliteData.sateIdx;

    if (this.sateIndex === -1) {
      LogUtils.i(TAG, 'setIsConTimedOut first sateIndex.');
    } else if (this.sateIndex !== sateIdx) {
      LogUtils.i(TAG, 'setIsConTimedOut change satellite.');
      // 运营打点-切星
      SatelliteSearchManager.getInstance().sendSatelliteEventToMeetime(SatelliteState.STATE_CHANGE);
      this.changeSatelliteOp = 1;

      if (this.currentStatus == SYS_STATUS_SEARCH_SATELLITE_SUCC) {
        // 切换卫星
        this.mOldAzimuthDelta = this.mBackAzimuthDelta;
        if (this.mOldAzimuthDelta === 0) {
          return;
        }
        this.switchSatelliteTimes = this.switchSatelliteTimes + 1;
        this.showSatelliteChangeConnect = true;
      }
    }
    this.sateIndex = sateIdx;
  }

  //移除寻星角度数据监听回调接口
  removeSatelliteDataCallback() {
    if (this.satelliteDataCallback) {
      this.satelliteManager.removeSatelliteDataCallback(this.satelliteDataCallback);
      this.satelliteDataCallback = undefined;
    }
  }

  //添加经纬度变化监听接口
  addLocationCallback() {
    if (this.locationChangeCallback != undefined) {
      LogUtils.i(TAG, 'locationChangeCallback: callTimeListener has been added');
      return;
    }
    this.locationChangeCallback = ((convertLongitude: number, convertLatitude: number) => {
      LogUtils.i(TAG, 'satelliteManager.updateLocationListeners is called');
      //刷新经纬度信息到界面
      this.getLocationInfo(convertLongitude, convertLatitude);
    });
    this.satelliteManager.addLocationChangeCallback(this.locationChangeCallback)
  }

  getLocationInfo(convertLongitude: number, convertLatitude: number) {
    //刷新经纬度信息到界面
    if (convertLatitude >= 0) {
      if (convertLongitude >= 0) {
        this.location = $r('app.string.location_north_east',
          SatelliteUtils.convertDigitalToLatitude(convertLatitude),
          SatelliteUtils.convertDigitalToLongitude(convertLongitude));
      } else {
        this.location = $r('app.string.location_north_west',
          SatelliteUtils.convertDigitalToLatitude(convertLatitude),
          SatelliteUtils.convertDigitalToLongitude(convertLongitude));
      }
    } else {
      if (convertLongitude >= 0) {
        this.location = $r('app.string.location_south_east',
          SatelliteUtils.convertDigitalToLatitude(convertLatitude),
          SatelliteUtils.convertDigitalToLongitude(convertLongitude));
      } else {
        this.location = $r('app.string.location_south_west',
          SatelliteUtils.convertDigitalToLatitude(convertLatitude),
          SatelliteUtils.convertDigitalToLongitude(convertLongitude));
      }
    }
  }

  //移除经纬度监听回调接口
  removeLocationCallback() {
    if (this.locationChangeCallback) {
      this.satelliteManager.removeLocationChangeCallback(this.locationChangeCallback);
      this.locationChangeCallback = undefined;
    }
  }

  // 添加设备方向变化监听
  addDeviceDirChangeCallback() {
    this.isShowOrientationRemind = SatelliteSearchManager.getInstance().isShowOrientationRemind();
    if (this.deviceDirChangeCallback) {
      LogUtils.i(TAG, 'deviceDirChangeCallback: callTimeListener has been added');
      return;
    }
    this.deviceDirChangeCallback = ((isLandscape: boolean) => {
      if (!this.shouldUploadOrentationMode()) {
        return;
      }
      this.isShowOrientationRemind = SatelliteSearchManager.getInstance().isShowOrientationRemind();
    });
    SatelliteSearchManager.getInstance().addDeviceDirectionChangeCallback(this.deviceDirChangeCallback);
  }

  // 移除设备方向变化监听
  removeDeviceDirListener() {
    if (this.deviceDirChangeCallback) {
      SatelliteSearchManager.getInstance().removeDeviceDirectionChangeCallback(this.deviceDirChangeCallback);
      this.deviceDirChangeCallback = undefined;
    }
  }

  //添加增强寻呼监听接口
  addAlertStateCallback() {
    if (this.alertStateCallback != undefined) {
      LogUtils.i(TAG, 'addAlertStateCallback: callTimeListener has been added');
      return;
    }
    this.alertStateCallback = ((mAlertState: number) => {
      if (this.showReConnect && this.currentStatus == SYS_STATUS_SEARCH_SATELLITE_FAIL) {
        return;
      }
      this.mAlertState = mAlertState;
    });
    SatelliteSearchManager.getInstance().addAlertStateCallback(this.alertStateCallback);
  }

  // 移除增强寻呼监听
  removeAlertState() {
    if (this.alertStateCallback) {
      SatelliteSearchManager.getInstance().removeAlertStateCallback(this.alertStateCallback);
      this.alertStateCallback = undefined;
    }
  }

  private addSatelliteNeedEndCallback(): void {
    if (this.satelliteNeedEndCallback) {
      LogUtils.i(TAG, 'addSatelliteNeedEndCallback callback has been added.');
      return;
    }
    this.satelliteNeedEndCallback = ((isSatelliteNeedEnd: boolean) => {
      LogUtils.i(TAG, 'addSatelliteNeedEndCallback isSatelliteNeedEnd: ' + isSatelliteNeedEnd);
      this.isSatelliteNeedEnd = isSatelliteNeedEnd;
    });
    SatelliteSearchManager.getInstance().addSatelliteNeedEndCallback(this.satelliteNeedEndCallback);
  }

  private removeSatelliteNeedEndCallback(): void {
    if (this.satelliteNeedEndCallback) {
      SatelliteSearchManager.getInstance().removeSatelliteNeedEndCallback(this.satelliteNeedEndCallback);
      this.satelliteNeedEndCallback = undefined;
    }
  }

  private shouldUploadOrentationMode(): boolean {
    let currentStatus = this.satelliteManager.getCurrentStatus();
    if (currentStatus === SYS_STATUS_WAIT_LOADING || currentStatus ===
      SYS_STATUS_WAIT_CALIBRATING || currentStatus === SYS_STATUS_SEARCH_SATELLITE_FAIL) {
      return false;

    }
    return true;
  }

  private publishSatelliteToastEvent() {
    LogUtils.i(TAG, 'publishSatelliteToastEvent');
    try {
      CommonEventManager.publish('event.custom.satellite.ACTION_SATELLITE_TOAST', {
        subscriberPermissions: ['ohos.permission.SET_TELEPHONY_STATE'],
        isOrdered: false,
        code: SATELLITE_TOAST_OFF_CODE
      }, () => {
      });
    } catch (err) {
      LogUtils.e(TAG, `publishSatelliteToastEvent publish error: ${err?.code} ${err?.message}`);
    }
  }

  compassControl() {
    // 寻星未成功时使用黑色罗盘
    if ((this.currentStatus === SYS_STATUS_SEARCHING_SATELLITE ||
      this.currentStatus === SYS_STATUS_SATELLITE_CONNECTING ||
      this.currentStatus === SYS_STATUS_SEARCH_SATELLITE_FAIL ||
      this.currentStatus === SYS_STATUS_WAIT_LOADING ||
      this.mDirection != SatelliteDirection.NONE) && !this.isShowOrientationRemind ||
      this.currentStatus === SYS_DISCONNECT) {
      this.getSatelliteOutAnimation();
    } else if (this.currentStatus === SYS_STATUS_SEARCH_SATELLITE_SUCC) {
      // 寻星成功时切换绿色罗盘
      this.getSatelliteInAnimation();
    }
  }

  initCompass() {
    // 寻星未成功时使用黑色罗盘
    if ((this.currentStatus === SYS_STATUS_SEARCHING_SATELLITE ||
      this.currentStatus === SYS_STATUS_SATELLITE_CONNECTING ||
      this.currentStatus === SYS_STATUS_SEARCH_SATELLITE_FAIL ||
      this.currentStatus === SYS_STATUS_WAIT_LOADING ||
      this.mDirection != SatelliteDirection.NONE) && !this.isShowOrientationRemind ||
      this.currentStatus === SYS_DISCONNECT) {
      this.backgroundBaseOp = 1;
    } else if (this.currentStatus === SYS_STATUS_SEARCH_SATELLITE_SUCC) {
      // 寻星成功时切换绿色罗盘
      this.dialogCompassOp = 1;
    }
  }

  getSatelliteInAnimation() {
    if (this.dialogCompassOp === 1) {
      return;
    }
    this.backgroundBaseOp = 1;
    this.dialogCompassOp = 0;
    animateTo({
      duration: 150, curve: Curve.Sharp, iterations: 1}, () => {
      this.backgroundBaseOp = 0;
    })
    animateTo({
      delay: 50,
      duration: 200,
      curve: Curve.Sharp,
      iterations: 1,
      onFinish: () => {
      }
    }, () => {
      this.dialogCompassOp = 1;
    })
  }

  getSatelliteOutAnimation() {
    if (this.backgroundBaseOp === 1) {
      return;
    }
    animateTo({
      duration: 150, curve: Curve.Sharp, iterations: 1, onFinish: () => {
      }
    }, () => {
      this.dialogCompassOp = 0;
    })
    animateTo({
      delay: 50,
      duration: 200,
      curve: Curve.Sharp,
      iterations: 1,
      onFinish: () => {
      }
    }, () => {
      this.backgroundBaseOp = 1;
    })
  }

  @Builder
  myBuilder() {
    NavDestination() {
      Column() {
        //顶部布局
        Column() {
          HyacinthSearchTop({
            currentStatus: $currentStatus,
            mSatelliteData: $mSatelliteData,
            isShowOrientationRemind: $isShowOrientationRemind,
            showReConnect: $showReConnect,
            showSatelliteChangeConnect: $showSatelliteChangeConnect,
            showReCalibrate: $showReCalibrate,
            showReSearch: $showReSearch,
            operationType: $operationType,
            changeSatelliteOp: $changeSatelliteOp,
            isSatelliteNeedEnd: $isSatelliteNeedEnd,
            widthAspectRatio: $widthAspectRatio,
            scaleSize: $scaleSize,
            mAlertState: $mAlertState,
            availableTime: this.availableTime
          })
        }
        .width('100%')
        .id('CallSetting_HyacinthDialog_HyacinthSearchTop')

        //中间布局
        Column() {
          Stack() {
            Image($r('app.media.hyacinth_dialog_base_compass'))
              .width(this.satelliteSearchWidth)
              .height(this.satelliteSearchWidth)
              .align(Alignment.Center)
              .draggable(false)
              .opacity(this.backgroundBaseOp)
              .id('CallSetting_HyacinthDialog_background_base')

            Image($r('app.media.hyacinth_dialog_connected_succ_compass'))
              .width(this.satelliteSearchWidth)
              .height(this.satelliteSearchWidth)
              .align(Alignment.Center)
              .draggable(false)
              .opacity(this.dialogCompassOp)
              .id('CallSetting_HyacinthDialog_background_base')

            if (this.currentStatus === SYS_STATUS_WAIT_LOADING) {
              HyacinthSearchProgress({ showReSearch: $showReSearch, scaleSize: $scaleSize })
                .width('100%')
                .height('100%')
                .id('CallSetting_HyacinthDialog_HyacinthSearchProgress')
            }

            //寻星
            if ((this.currentStatus === SYS_STATUS_SEARCHING_SATELLITE ||
              this.currentStatus === SYS_STATUS_SEARCH_SATELLITE_SUCC ||
              this.currentStatus === SYS_STATUS_SATELLITE_CONNECTING ||
              this.currentStatus === SYS_STATUS_SEARCH_SATELLITE_FAIL) && !this.isShowOrientationRemind ||
              this.currentStatus === SYS_DISCONNECT) {
              HyacinthSearch({
                currentStatus: $currentStatus,
                mSatelliteData: $mSatelliteData,
                showReConnect: $showReConnect,
                satelliteSearchWidth: $satelliteSearchWidth,
                switchSatelliteTimes: $switchSatelliteTimes,
                winkSatelliteOp: $winkSatelliteOp,
                mOldAzimuthDelta: $mOldAzimuthDelta,
              })
                .id('CallSetting_HyacinthDialog_HyacinthSearch')
                .width('100%')
                .height('100%')


              if (this.currentStatus != SYS_STATUS_SEARCH_SATELLITE_FAIL &&
                this.currentStatus != SYS_STATUS_WAIT_LOADING &&
                (this.mDirection === SatelliteDirection.LEFT || this.mDirection === SatelliteDirection.RIGHT)) {
                // 方位角弧度
                Canvas(this.context)
                  .width('100%')
                  .height('100%')
                  .onReady(() => {
                    this.drawDirectArc()
                  })
                  .id('CallSetting_HyacinthDialog_DirectionArc')
                // 方位角箭头
                Column() {
                  SymbolGlyph($r('sys.symbol.small_triangle_arrow_down_right_fill'))
                    .fontSize(30)
                    .fontColor(['#4986FF'])
                    .rotate({
                      centerX: '50%',
                      centerY: '50%',
                      angle: this.mDirection === SatelliteDirection.RIGHT ? -45 : 135
                    })
                    .margin({ top: this.mDirection === SatelliteDirection.RIGHT ? 9 : 21 })
                }
                .width(this.satelliteSearchWidth)
                .height(this.satelliteSearchWidth)
                .alignItems(HorizontalAlign.Center)
                .justifyContent(FlexAlign.Start)
                .rotate({
                  centerX: this.satelliteSearchWidth / 2,
                  centerY: this.satelliteSearchWidth / 2,
                  angle: this.mDirection === SatelliteDirection.RIGHT ?
                    // 角度余量，symbol图标自带一部分空白，旋转时需考虑，因此增加3度补偿值
                    this.mAzimuthDelta * 90 / (2 * 180) - 3 : this.mAzimuthDelta * 90 / (2 * 180) + 3
                })
                .id('CallSetting_HyacinthDialog_DirectionArrow')
              }
            }

            //罗盘校准
            if (this.currentStatus === SYS_STATUS_WAIT_CALIBRATING || this.currentStatus == SYS_STATUS_DEFAULT) {
              HyacinthCalibrate({
                megnecticAccuracy: this.currentAccuracy,
                showReCalibrate: this.showReCalibrate,
                isSkipCalibrate: this.isSkipCalibrate,
                satelliteSearchWidth: this.satelliteSearchWidth
              })
                .id('CallSetting_HyacinthDialog_HyacinthCalibrate')
                .width('100%')
                .height('100%')
            }

            //横竖屏提醒
            if (this.isShowOrientationRemind &&
              !(this.currentStatus === SYS_STATUS_WAIT_CALIBRATING || this.currentStatus == SYS_STATUS_DEFAULT)) {
              HyacinthLandscapeRemind({
                mSatelliteData: $mSatelliteData,
                isShowOrientationRemind: $isShowOrientationRemind
              })
                .id('CallSetting_HyacinthDialog_HyacinthLandscapeRemind')
                .width('100%')
                .height('100%')
                .margin({ bottom : this.isFoldStatusFolded === display.FoldStatus.FOLD_STATUS_EXPANDED ||
                  this.isFoldStatusFolded === display.FoldStatus.FOLD_STATUS_HALF_FOLDED
                  ? this.getSheetHeight() * 0.2 : 0 })
                .align(Alignment.Center)
            }
          }
          .height(this.satelliteSearchWidth)
        }
        .id('CallSetting_HyacinthDialog_HyacinthMiddle')
        .width(this.satelliteSearchWidth)
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
        .translate({ y: (this.widthAspectRatio <= hDividedW08 ? 28 * this.scaleSize : -5.5) })

        // 底部布局
        Stack({ alignContent: Alignment.Bottom }) {
          //底部按钮（电话，短信，重新连接，重新校准...)
          HyacinthSearchBottom({
            showReConnect: $showReConnect,
            showReCalibrate: $showReCalibrate,
            showReSearch: $showReSearch,
            currentStatus: $currentStatus,
            isSkipCalibrate: $isSkipCalibrate,
            scaleSize: $scaleSize
          })
          if (this.currentStatus === SYS_STATUS_SEARCHING_SATELLITE ||
            this.currentStatus === SYS_STATUS_SEARCH_SATELLITE_SUCC ||
            this.currentStatus === SYS_STATUS_SATELLITE_CONNECTING ||
            this.currentStatus === SYS_STATUS_SEARCH_SATELLITE_FAIL || this.currentStatus === SYS_DISCONNECT) {
            //经纬度信息显示
            Text(this.location)
              .width('100%')
              .fontSize(12)
              .maxLines(2)
              .fontColor($r('sys.color.ohos_id_color_text_secondary_dark'))
              .margin({ bottom: 28, left: 16, right: 16 })
              .textAlign(TextAlign.Center)
              .maxFontScale(MAX_FONT_SCALE)
              .transition(TransitionEffect.OPACITY.animation({
                duration: 150,
                curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1)
              }))
          }
        }
        .id('CallSetting_HyacinthDialog_HyacinthBottom')
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .linearGradient({
        angle: 90,
        colors: [[0x141618, 0.0], [0x282C30, 1.0]]
      })
    }
    .width('100%')
    .height('100%')
    .onFocus(() => {
      this.isFocused = true;
    })
    .onBlur(() => {
      this.isFocused = false;
    })
  }

  calculatePointOnCircle(x: number, y: number, r: number, degree: number): [number, number] {
    const radian = degree * Math.PI / 180;
    const px = x + r * Math.cos(radian);
    const py = y + r * Math.sin(radian);
    return [px, py];
  }

  // 绘制方位角箭头弧线
  drawDirectArc() {
    this.context.clearRect(0, 0, this.satelliteSearchWidth, this.satelliteSearchWidth);
    let angle = this.mAzimuthDelta;
    LogUtils.i(TAG, `getSateRotationAngles: ${angle}`);
    if (!angle) {
      return;
    }
    this.updateDirection();
    this.context.beginPath();
    // 弧度限制到120度以内
    angle = angle * 90 / 180;
    // 度数换算为弧度
    let degree = angle * Math.PI / 180;
    let startDegree = Math.PI + (Math.PI - degree) / 2;
    let endDegree = 2 * Math.PI - (Math.PI - degree) / 2;
    if (this.mDirection === SatelliteDirection.RIGHT) {
      let startCoordinate = this.calculatePointOnCircle(this.satelliteSearchWidth / 2,
        this.satelliteSearchWidth / 2, (this.satelliteSearchWidth / 2 - 30), startDegree);
      let endCoordinate = this.calculatePointOnCircle(this.satelliteSearchWidth / 2,
        this.satelliteSearchWidth / 2, (this.satelliteSearchWidth / 2 - 30), endDegree);
      LogUtils.e(TAG, `getSateRotationAngles right: ${startCoordinate}, ${endCoordinate}`);
      let grad = this.context.createLinearGradient(startCoordinate[0] - 50,
        startCoordinate[1], -endCoordinate[0] + 50, endCoordinate[1]);

      grad.addColorStop(0.0, '#4986FF');
      grad.addColorStop(0.2, '#4986FF');
      grad.addColorStop(0.5, '#293244');
      grad.addColorStop(0.28, '#2D3A53');
      grad.addColorStop(0.3, '#2A3342');
      grad.addColorStop(0.32, '#292E37');
      grad.addColorStop(0.34, '#262728');
      grad.addColorStop(0.35, '#272727');
      grad.addColorStop(1, '#272727');

      this.context.strokeStyle = grad;
      this.context.arc(this.satelliteSearchWidth / 2, this.satelliteSearchWidth / 2,
        (this.satelliteSearchWidth / 2 - 30), startDegree, endDegree);
    } else if (this.mDirection === SatelliteDirection.LEFT) {
      let startCoordinate = this.calculatePointOnCircle(this.satelliteSearchWidth / 2,
        this.satelliteSearchWidth / 2, (this.satelliteSearchWidth / 2 - 30), endDegree);
      let endCoordinate = this.calculatePointOnCircle(this.satelliteSearchWidth / 2,
        this.satelliteSearchWidth / 2, (this.satelliteSearchWidth / 2 - 30), startDegree);
      LogUtils.e(TAG, `getSateRotationAngles: ${startCoordinate}, ${endCoordinate}`);
      let grad = this.context.createLinearGradient(startCoordinate[0] - 50,
        startCoordinate[1], -endCoordinate[0] + 50, endCoordinate[1]);
      grad.addColorStop(0.0, '#272727');
      grad.addColorStop(0.01, '#262728');
      grad.addColorStop(0.03, '#292E37');
      grad.addColorStop(0.05, '#2A3342');
      grad.addColorStop(0.07, '#2D3A53');
      grad.addColorStop(0.1, '#293244');
      grad.addColorStop(0.15, '#2B3A59');
      grad.addColorStop(0.2, '#4986FF');
      grad.addColorStop(0.4, '#4986FF');
      grad.addColorStop(1, '#4986FF');
      this.context.strokeStyle = grad;
      this.context.arc(this.satelliteSearchWidth / 2, this.satelliteSearchWidth / 2,
        (this.satelliteSearchWidth / 2 - 30), endDegree, startDegree);
    } else {
      return;
    }
    this.context.lineWidth = 6;
    this.context.stroke();
  }

  removeTouchOutsideListener() {
    LogUtils.i(TAG, 'removeTouchOutsideListener');
    try {
      if (isTablet()) {
        return;
      }
      window.findWindow('satelliteDialog')?.off('touchOutside');
    } catch (err) {
      LogUtils.e(TAG, `satelliteDialog touchOutside error:${JSON.stringify(err)}`);
    }
  }

  addTouchOutsideListener() {
    LogUtils.i(TAG, 'addTouchOutsideListener');
    try {
      if (isTablet()) {
        return;
      }
      window.findWindow('satelliteDialog')?.on('touchOutside', () => {
        if (this.isFocused){
          this.isShow = false;
          LogUtils.i(TAG, 'satelliteDialog touchOutside');
        }
      });
    } catch (err) {
      LogUtils.e(TAG, `satelliteDialog touchOutside error:${JSON.stringify(err)}`);
    }
  }

  getPreferType() : SheetType {
    //宽屏设备
    if (isTablet() || TrifoldManager.getInstance().showCenter()) {
      return SheetType.CENTER;
    }
    //直板设备
    return SheetType.POPUP;
  }

  getSatelliteSearchWidth() : number {
    if (this.isNewFormFoldPhone ||
      this.isFoldStatusFolded === display.FoldStatus.FOLD_STATUS_EXPANDED ||
      this.isFoldStatusFolded === display.FoldStatus.FOLD_STATUS_HALF_FOLDED) {
      return 330;
    }
    if (isTablet() && SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      return 330;
    }
    if (this.widthAspectRatio > hDividedW13) {
      return 360;
    }
    return this.getSheetWidth() * 360 / 480;
  }

  getSheetWidth() : number {
    if (isTablet() || TrifoldManager.getInstance().isTrifold()) {
      return this.displayWidth > this.displayHeight ?
        px2vp(this.displayWidth) * 480 / 1280 : px2vp(this.displayHeight) * 480 / 1280;
    } else if (this.widthAspectRatio > hDividedW08 && this.widthAspectRatio <= hDividedW13) {
      return px2vp(this.displayWidth) * 480 / 740;
    }
    return px2vp(this.displayWidth);
  }

  getSheetHeight() : number {
    let statusBarHeight = px2vp(117);
    if (this.isNewFormFoldPhone) {
      let marginTop = 8;
      let height = px2vp(this.displayHeight) - marginTop - statusBarHeight;
      LogUtils.i(TAG, `newFormFoldPhone getSheetHeight: ${height}`);
      return height;
    }
    if (isTablet() || TrifoldManager.getInstance().isTrifold()) {
      return this.displayWidth > this.displayHeight ?
        710 * px2vp(this.displayHeight) / 800 : 710 * px2vp(this.displayWidth) / 800;
    } else if (this.widthAspectRatio > hDividedW08 && this.widthAspectRatio <= hDividedW13) {
      let minHeight = this.displayHeight > this.displayWidth ? this.displayWidth : this.displayHeight;
      return px2vp(minHeight) * 0.9;
    }
    return 700;
  }

  build() {
    NavDestination() {
      this.showDialogLayout();
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#00000000')
  }

  @Builder
  showDialogLayout() {
    if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      this.showSmcLayout();
    } else {
      Column() {
      }
      .justifyContent(FlexAlign.Center)
      .bindSheet($$this.isShow, this.myBuilder(), {
        height: this.getSheetHeight(),
        width: this.getSheetWidth(),
        preferType: this.getPreferType(),
        dragBar: false,
        showClose: false,
        enableOutsideInteractive: false,
        onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
          LogUtils.i(TAG, 'bindSheet onWillDismiss reason=' + dismissDialogAction.reason);
          if (dismissDialogAction.reason !== DismissReason.TOUCH_OUTSIDE) {
            // 注册dismiss行为
            dismissDialogAction.dismiss();
          }
        },
        onWillSpringBackWhenDismiss: ((springBackAction: SpringBackAction) => {
          // 没有注册springBack, 下拉半模态页面无回弹行为 springBackAction.springBack()
        }),
        onAppear: () => {
          console.log('BindSheet onAppear.');
        },
        onDisappear: () => {
          console.log('BindSheet onDisappear.');
          if (this.currentStatus == SYS_STATUS_WAIT_CALIBRATING ||
            this.currentStatus == SYS_STATUS_WAIT_LOADING) {
            this.publishSatelliteToastEvent();
            this.satelliteManager.finishSatellite(false);
          } else {
            this.satelliteManager.createFloatWindow();
            ReportUtil.getInstance().reportSatelliteChangeFloatWindow();
          }
        }
      })
      .width('100%')
      .height('100%')
      .backgroundColor('#00000000')
    }
  }

  @Builder
  showSmcLayout() {
    Stack() {
      this.showSmcBackgroundCanvasLayout();

      Column() {
        // 顶部布局
        Column() {
          HyacinthSearchTop({
            currentStatus: $currentStatus,
            mSatelliteData: $mSatelliteData,
            isShowOrientationRemind: $isShowOrientationRemind,
            showReConnect: $showReConnect,
            showSatelliteChangeConnect: $showSatelliteChangeConnect,
            showReCalibrate: $showReCalibrate,
            showReSearch: $showReSearch,
            operationType: $operationType,
            changeSatelliteOp: $changeSatelliteOp,
            isSatelliteNeedEnd: $isSatelliteNeedEnd,
            widthAspectRatio: $widthAspectRatio,
            scaleSize: $scaleSize,
            mAlertState: $mAlertState,
            availableTime: this.availableTime
          })
        }
        .width('100%')

        // 中间布局
        this.showSmcMiddleLayout();

        // 底部布局
        this.showSmcBottomLayout();
      }
      .key('SatelliteDialog_Smc_Layout_Column')
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .onAreaChange((oldValue: Area, newValue: Area) => {
        this.dialogWidth = newValue.width as number;
        this.dialogHeight = newValue.height as number;
        LogUtils.i(TAG, `onAreaChange dialogWidth: ${this.dialogWidth} , dialogHeight: ${this.dialogHeight}`)
      })
    }.backgroundColor($r('sys.color.ohos_id_color_panel_bg'))
  }

  @Builder
  showSmcMiddleLayout() {
    Column() {
      Stack() {
        if ((this.currentStatus === SYS_STATUS_SEARCHING_SATELLITE ||
          this.currentStatus === SYS_STATUS_SEARCH_SATELLITE_SUCC ||
          this.currentStatus === SYS_STATUS_SATELLITE_CONNECTING ||
          this.currentStatus === SYS_STATUS_WAIT_BLOCKING ||
          this.currentStatus === SYS_STATUS_WAIT_LOADING ||
        this.isSmcOperationType()) && !this.isShowOrientationRemind) {
          Image($r('app.media.meetime_background_base'))
            .key('SatelliteDialog_Middle_Layout_Background_Image')
            .width(this.satelliteSearchWidth)
            .height(this.satelliteSearchWidth)
            .align(Alignment.Center)
            .draggable(false)
        }

        if (this.currentStatus === SYS_STATUS_WAIT_LOADING || this.currentStatus === SYS_STATUS_WAIT_BLOCKING) {
          SatelliteSearchProgress({
            showReSearch: $showReSearch,
            scaleSize: $scaleSize
          })
            .width('100%')
            .height('100%')
        }

        // 寻星
        this.showSmcSatelliteLayout();

        // 罗盘校准
        if (this.currentStatus === SYS_STATUS_WAIT_CALIBRATING) {
          HyacinthCalibrate({
            megnecticAccuracy: this.currentAccuracy,
            showReCalibrate: this.showReCalibrate,
            isSkipCalibrate: this.isSkipCalibrate,
            satelliteSearchWidth: this.satelliteSearchWidth
          })
            .width('100%')
            .height('100%')
        }

        // 横竖屏提醒
        if (this.isShowOrientationRemind && this.currentStatus != SYS_STATUS_WAIT_CALIBRATING) {
          HyacinthLandscapeRemind({mSatelliteData: $mSatelliteData, isShowOrientationRemind: $isShowOrientationRemind})
            .width('100%')
            .height('100%')
            .align(Alignment.Center)
        }
      }
      .height(this.satelliteSearchWidth)
    }
    .width(this.satelliteSearchWidth)
    .layoutWeight(1)
    .justifyContent(FlexAlign.Start)
    .translate({ y: (isTablet() || DisplayUtil.isExpandedStatus()) ? -13 : -5 })
  }

  @Builder
  showSmcSatelliteLayout() {
    if ((this.currentStatus === SYS_STATUS_SEARCHING_SATELLITE ||
      this.currentStatus === SYS_STATUS_SEARCH_SATELLITE_SUCC ||
      this.currentStatus === SYS_STATUS_SATELLITE_CONNECTING ||
    this.isSmcOperationType()) && !this.isShowOrientationRemind) {
      HyacinthSearch({
        currentStatus: $currentStatus,
        mSatelliteData: $mSatelliteData,
        showReConnect: $showReConnect,
        satelliteSearchWidth: $satelliteSearchWidth,
        switchSatelliteTimes: $switchSatelliteTimes,
        winkSatelliteOp: $winkSatelliteOp,
        mOldAzimuthDelta: $mOldAzimuthDelta,
      })
        .width('100%')
        .height('100%')
    }
  }

  @Builder
  showSmcBottomLayout() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 底部按钮（重新校准...)
      HyacinthSearchBottom({
        showReConnect: $showReConnect,
        showReCalibrate: $showReCalibrate,
        showReSearch: $showReSearch,
        currentStatus: $currentStatus,
        isSkipCalibrate: $isSkipCalibrate,
        scaleSize: $scaleSize
      })
      // 卫星连接超时提示语显示
      Text($r('app.string.im_smc_receive_auto_change_01'))
        .fontSize(14)
        .maxLines(2)
        .fontColor($r('sys.color.ohos_id_color_warning'))
        .fontWeight(FontWeight.Regular)
        .fontFamily('HarmonyHeiTi')
        .lineHeight(19)
        .margin({ bottom: 24, left: 24, right: 24 })
        .textAlign(TextAlign.Center)
        .opacity(this.changeSatelliteOp)
        .maxFontScale(MAX_FONT_SCALE)
    }
    .width('100%')
  }

  @Builder
  showSmcBackgroundCanvasLayout() {
    Canvas(this.context)
      .key('SatelliteDialog_Background_Canvas')
      .width(this.dialogWidth)
      .height(this.dialogHeight)
      .onReady(() => {
        LogUtils.i(TAG, `onReady dialogWidth: ${this.dialogWidth} , dialogHeight: ${this.dialogHeight}`)
        this.drawSmcBackgroundImg();
      })
  }

  private isSmcOperationType(): boolean {
    if (this.currentStatus === SEND_STATUS_SUCC ||
      this.currentStatus === SEND_STATUS_SENT ||
      this.currentStatus === SEND_STATUS_FAIL ||
      this.currentStatus === RECEIVER_STATUS_RECEIVING ||
      this.currentStatus === RECEIVER_STATUS_SUCCESS ||
      this.currentStatus === RECEIVER_STATUS_FAIL ||
      this.currentStatus === RECEIVER_STATUS_NULL ||
      this.currentStatus === SYS_STATUS_SATELLITE_KEEPING) {
      return true;
    }
    return false;
  }

  private drawSmcBackgroundImg(): void {
    LogUtils.i(TAG, `drawSmcBackgroundImg currentMode: ${this.currentMode}`)
    this.backgroundImg = this.currentMode ? new ImageBitmap('/common/images/meetime_search_sate_shading.png') :
      new ImageBitmap('/common/images/meetime_search_sate_shading_dark.png');
    // 使用drawImage接口将背景图片画上去，背景图片高度为宽度的31/36
    this.context.drawImage(this.backgroundImg, 0, 0, this.dialogWidth, 31 * this.dialogWidth / 36);
  }
}
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

import window from '@ohos.window';
import {
  CarrierType,
  MAX_FONT_SCALE,
  SatelliteDirection,
  SATELLITE_FLOAT_WINDOW,
  SATELLITE_KEY_CARRIER_TYPE,
  SYS_STATUS_SATELLITE_CONNECTING,
  SYS_STATUS_SEARCHING_SATELLITE,
  SYS_STATUS_SEARCH_SATELLITE_FAIL,
  SYS_STATUS_SEARCH_SATELLITE_SUCC
} from '../common/constant/SatelliteSearchConst';
import {
  SatelliteFloatWindowLandscapeRemind
} from '../components/SatelliteComponents/SatelliteFloatWindowLandscapeRemind';
import { SatelliteFloatWindowSearch } from '../components/SatelliteComponents/SatelliteFloatWindowSearch';
import SatelliteFloatWindowManager, { DEFAULT_WINDOW_HEIGHT } from '../manager/SatelliteFloatWindowManager';
import SatelliteSearchManager, { SatelliteData } from '../manager/SatelliteSearchManager';
import display from '@ohos.display';
import { LogUtils, CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import { curves, LengthMetrics } from '@kit.ArkUI';
import SatelliteUtils from '../common/utils/SatelliteUtils';
import { getVisibilityByTextOp, isPhone, isSupportCactus } from '../common/utils/Utils';
import { isTablet } from '../common/utils/DeviceTypeUtils';
import {
  EMIT_NEW_FOLD_PHONE_EXTERNAL_EVENT_ID,
  SATELLITE_SERVICE_CONTEXT } from '../common/constant/CallSettingsConstant';
import ServiceExtensionContext from '@ohos.app.ability.common';
import settings from '@ohos.settings';
import AlertDialogManager from '../manager/AlertDialogManager';
import { emitter } from '@kit.BasicServicesKit';
import ScreenAdapterUtils from '../common/utils/ScreenAdapterUtils';
import { TrifoldManager } from '../manager/TrifoldManager';

const TAG = 'FloatWindow';

const MARGIN_TOP = 16;

const marginTopAndBottomPix = vp2px(MARGIN_TOP);

const marginBottomPix = vp2px(DEFAULT_WINDOW_HEIGHT);

interface Position {
  x: number,
  y: number
}
@Entry
@Component
struct FloatWindow {
  @State message: string = 'float window'
  private panOption: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.Vertical });
  @State @Watch('moveWindow') windowPosition: Position = { x: 0, y: 0 };
  floatWindow: window.Window | null = window.findWindow('floatWindow') ?? null;
  @State @Watch('statusChange') currentStatus: Number = SYS_STATUS_SEARCHING_SATELLITE;
  @State @Watch('changeSatelliteData') mSatelliteData: SatelliteData | undefined = undefined;
  @State oldStatusText: Resource = $r('app.string.device_calibrating');
  @State newStatusText: Resource = $r('app.string.device_calibrating');
  @State isStart: boolean = false;
  @State oldStatusTextOp: number = 0;
  @State newStatusTextOp: number = 0;
  @State newGuideTextOp: number = 0;
  @State oldGuideTextOp: number = 0;
  @State oldStatusTextColor: Resource = $r('sys.color.ohos_id_color_text_primary_contrary');
  @State newStatusTextColor: Resource = $r('sys.color.ohos_id_color_text_primary_contrary');
  @State oldGuideText: Resource = $r('app.string.device_calibrating_tips');
  @State newGuideText: Resource = $r('app.string.device_calibrating_tips');
  @State signalDescription: Resource = $r('app.string.satellite_signal_descriptions');

  @State @Watch('getText') mAlertState: number = 0;
  // 重新连接
  @State showReConnect: Boolean = true;
  // 重新寻星
  @State showReSearch: Boolean = false;
  @State connectingGuideNumber: number = -1;

  @State connectTime: number = SatelliteSearchManager.getInstance().getMaxConnectTime();

  @State @Watch('getText') isShowOrientationRemind: boolean = false;

  @State signalIcon: Resource = $r('app.media.ic_satellite_signal');
  @State signalIconOk: Resource = $r('app.media.ic_satellite_signal_ok');
  @State location: Resource = $r('app.string.location_north_west');
  private locationChangeCallback: Function | undefined;
  private locationLongitude: number = 0;
  private locationLatitude: number = 0;
  private deviceDirChangeCallback: Function | undefined;
  @State mAzimuthDelta: number = 0;
  @State mPitchDelta: number = 0;
  @State mSignal: number = 0;

  @State locationOp: number = 0;

  @State mDirection:number = SatelliteDirection.NONE;
  @State startSaltelliteOpAn: boolean = false;

  floatWindowManager: SatelliteFloatWindowManager = SatelliteFloatWindowManager.getInstance()

  satelliteManager: SatelliteSearchManager = SatelliteSearchManager.getInstance()

  private statusUpdateCallback: Function | undefined;
  private satelliteDataCallback: Function | undefined;
  private alertStateCallback: Function | undefined;
  private singleOkCubic = curves.cubicBezierCurve(0.33, 0, 0.67, 1);
  private arr: number[] = [0, 1, 2, 3];

  private satelliteConnectTimeCallBack: Function | undefined;

  private isNewFormFoldPhone = ScreenAdapterUtils.isNewFormFoldPhone();
  private isNewFoldPhoneScreen: boolean = false;

  getSignalDescription() {
    let context = CallSettingGlobalContextHelper.getContext()
      .getValue<ServiceExtensionContext.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT);
    let carrierType = settings.getValueSync(context, SATELLITE_KEY_CARRIER_TYPE, CarrierType.CARRIER_OTHER)
    if (carrierType === CarrierType.CARRIER_CT) {
      this.signalDescription = $r('app.string.satellite_signal_descriptions');
    } else {
      this.signalDescription = $r('app.string.new_satellite_signal_descriptions')
    }
  }

  startStatusTextAnimation() {
    this.oldStatusTextOp = 1;
    this.newStatusTextOp = 0;
    animateTo({ duration: 200, curve: Curve.Sharp }, () => {
      this.oldStatusTextOp = 0;
    })
    animateTo({ duration: 200, curve: Curve.Sharp }, () => {
      this.newStatusTextOp = 1;
    })
  }

  startGuideTextAnimation() {
    this.oldGuideTextOp = 1;
    this.newGuideTextOp = 0;
    animateTo({ duration: 200, curve: Curve.Sharp }, () => {
      this.oldGuideTextOp = 0;
    })
    animateTo({ duration: 200, curve: Curve.Sharp }, () => {
      this.newGuideTextOp = 1;
    })
  }

  statusChange() {
    if (this.currentStatus === SYS_STATUS_SATELLITE_CONNECTING) {
      this.connectTime = this.satelliteManager.getConnectingTime();
    }
    if (this.currentStatus != SYS_STATUS_SEARCH_SATELLITE_SUCC && this.mSignal != 0) {
      this.updateSignal(0);
    }
    this.getText();
  }

  aboutToAppear() {
    SatelliteSearchManager.getInstance().hideWindow(SATELLITE_FLOAT_WINDOW);
    window.findWindow(SATELLITE_FLOAT_WINDOW).setWindowBackgroundColor('#00000000'); //设置子窗口背景透明
    this.currentStatus = this.satelliteManager.getCurrentStatus();
    this.windowPosition = {
      x: this.floatWindowManager.getLeftMovingDirection(),
      y: this.floatWindowManager.getTopMovingDirection()
    };

    if (this.currentStatus == SYS_STATUS_SATELLITE_CONNECTING) {
      this.connectTime = this.satelliteManager.getConnectingTime();
    }
    this.mAlertState = this.satelliteManager.getAlertState();
    this.showReConnect = this.satelliteManager.getShowReconnect();
    this.mSatelliteData = this.satelliteManager.getCacheSatelliteData();
    // 添加状态变化监听接口
    this.addStatusCallback();
    this.addAlertStateCallback();
    this.addSatelliteDataCallback();
    this.getText();
    this.changeSatelliteData();

    // 添加经纬度变化监听接口
    this.addLocationCallback();
    this.locationLongitude = this.satelliteManager.getLocationLongitude();
    this.locationLatitude = this.satelliteManager.getLocationLatitude();
    this.getLocationInfo(this.locationLongitude, this.locationLatitude);
    SatelliteSearchManager.getInstance().refreshUIOrientation();
    this.addDeviceDirChangeCallback();
    this.addSatelliteConnectTimeCallback();

    this.getSignalDescription();
    if (this.isNewFormFoldPhone) {
      this.isNewFoldPhoneScreen = ScreenAdapterUtils.getInstance().isNewFoldPhoneExternalScreen();
      this.addEmitterListener();
    }
    SatelliteSearchManager.getInstance().subscribeWindowAllEvent(SATELLITE_FLOAT_WINDOW);
  }

  aboutToDisappear(): void {
    this.removeAlertState();
    //移除状态监听回调接口
    this.removeStatusCallback()
    this.removeSatelliteDataCallback();
    this.removeLocationCallback();
    this.removeDeviceDirListener();
    this.removeSatelliteConnectTimeCallback();
    if (this.isNewFormFoldPhone) {
      this.removeEmitterListener();
    }
    SatelliteSearchManager.getInstance().unsubscribeWindowAllEvent();
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
        window.findWindow(SATELLITE_FLOAT_WINDOW).hide();
        LogUtils.i(TAG, `hide window`);
      } else {
        window.findWindow(SATELLITE_FLOAT_WINDOW).showWindow()
          .then(() => {
            AlertDialogManager.getInstance().showDialogWindow();
          });
        LogUtils.i(TAG, `show window`);
      }
    } catch (err) {
      LogUtils.e(TAG, `newFoldPhoneChange error:${err?.code}:${err?.message}`);
    }
  }

  //卫星角度信息发生变化
  changeSatelliteData() {
    if (this.mSatelliteData == undefined) {
      return;
    }
    this.mAzimuthDelta = this.mSatelliteData.azimuthDelta;
    this.mPitchDelta = this.mSatelliteData.pitchAngleDelta;
    this.mSignal = this.mSatelliteData.signal;
    if (!SatelliteUtils.checkAzimuthOk(this.mAzimuthDelta) || !SatelliteUtils.checkPitchOk(this.mPitchDelta)) {
      let safeAzimuthDelta: number = SatelliteUtils.getSuccessAzimuth();
      let safePitchDelta: number = SatelliteUtils.getSuccessPitch();
      if (this.mAzimuthDelta > safeAzimuthDelta) {
        this.updateDirection(SatelliteDirection.RIGHT);
      } else if (this.mAzimuthDelta < -safeAzimuthDelta) {
        this.updateDirection(SatelliteDirection.LEFT);
      } else if (this.mPitchDelta > safePitchDelta) {
        this.updateDirection(SatelliteDirection.UP);
      } else if (this.mPitchDelta < -safePitchDelta) {
        this.updateDirection(SatelliteDirection.DOWN);
      }
    } else {
      this.updateDirection(SatelliteDirection.NONE);
    }
    this.updateSignal(this.mSignal);
  }

  // 给direction 赋值
  updateDirection(direction: number) {
    if (this.isShowOrientationRemind) {
      return;
    }
    if (this.mDirection != direction) {
      this.mDirection = direction;
      this.getAzimuthText();
      this.updateStatusAndGuideTextForSuccess();
    }
  }

  //刷新信号
  updateSignal(signal: number) {
    if (this.currentStatus != SYS_STATUS_SEARCH_SATELLITE_SUCC) {
      if (this.mSignal != 0) {
        LogUtils.i(TAG, 'updateSignal status != SYS_STATUS_SEARCH_SATELLITE_SUCC');
        this.mSignal = 0;
      }
    } else if (this.currentStatus == SYS_STATUS_SEARCH_SATELLITE_SUCC && signal != this.mSignal) {
      LogUtils.i(TAG, 'updateSignal status == SYS_STATUS_SEARCH_SATELLITE_SUCC signal = ' + signal);
      this.mSignal = signal;
    }
  }

  // 更新向左先转，向右旋转提示语
  getAzimuthText() {
    if (this.mDirection == SatelliteDirection.NONE) {
      return;
    }
    if (this.mDirection == SatelliteDirection.LEFT) {
      this.setStatusText(isPhone() ? $r('app.string.left_rotate_phone') : $r('app.string.smc_left_rotate_device'),
        $r('sys.color.ohos_id_color_text_primary_contrary'));
      this.setGuideText($r('app.string.float_left_right_phone'));
    } else if (this.mDirection == SatelliteDirection.RIGHT) {
      this.setStatusText(isPhone() ? $r('app.string.right_rotate_phone') : $r('app.string.smc_right_rotate_device'),
        $r('sys.color.ohos_id_color_text_primary_contrary'));
      this.setGuideText($r('app.string.float_left_right_phone'));
    } else if (this.mDirection == SatelliteDirection.UP) {
      this.setStatusText(isPhone() ? $r('app.string.upper_tilt_phone') : $r('app.string.im_smc_lift_device'),
        $r('sys.color.ohos_id_color_text_primary_contrary'));
      this.setGuideText($r('app.string.float_upper_down_phone'));
    } else if (this.mDirection == SatelliteDirection.DOWN) {
      this.setStatusText(isPhone() ? $r('app.string.lower_tilt_phone') : $r('app.string.im_smc_lower_device'),
        $r('sys.color.ohos_id_color_text_primary_contrary'));
      this.setGuideText($r('app.string.float_upper_down_phone'));
    }
  }

  getText() {
    this.isShowOrientationRemind = SatelliteSearchManager.getInstance().isShowOrientationRemind();
    if (this.showReSearch) {
      this.setStatusText($r('app.string.satellite_search_failed'), $r('sys.color.ohos_id_color_warning'))
      return;
    }
    if (this.currentStatus == SYS_STATUS_SEARCH_SATELLITE_FAIL) {
      this.oldStatusText = this.getWaitStateCountData();
      this.newStatusText = $r('app.string.satellite_hunt_failed');

      this.oldStatusTextColor = $r('sys.color.ohos_id_color_text_primary_contrary');
      this.newStatusTextColor = $r('sys.color.ohos_id_color_warning');
      this.startStatusTextAnimation();

      if (this.connectingGuideNumber === 0) {
        this.oldGuideText = $r('app.string.keep_current_posture_wait_patiently');
      } else if (this.connectingGuideNumber === 1) {
        this.oldGuideText = $r('app.string.keep_current_posture');
      } else if (this.connectingGuideNumber === 2) {
        this.oldGuideText = $r('app.string.keep_current_posture_check_occlusion');
      }
      this.newGuideText = $r('app.string.satellite_hunt_timeout');
      this.startGuideTextAnimation();
      return;
    }

    let island = isTablet() || TrifoldManager.getInstance().isTrifold();
    if (this.isShowOrientationRemind && !island) {
        this.setStatusText($r('app.string.landscape_reminder'), $r('sys.color.ohos_id_color_text_primary_contrary'));
        return;
    } else if (this.isShowOrientationRemind && island) {
        this.setStatusText($r('app.string.portrait_reminder'), $r('sys.color.ohos_id_color_text_primary_contrary'));
        return;
    }

    if (this.currentStatus == SYS_STATUS_SEARCH_SATELLITE_SUCC) {
      this.setStatusText($r('app.string.satellite_hunt_success'), $r('sys.color.ohos_id_color_text_primary_contrary'));
      this.setGuideText($r('app.string.float_keep_current_posture'));
    } else if (this.currentStatus == SYS_STATUS_SATELLITE_CONNECTING) {
      this.setStatusText(this.getWaitStateCountData(),
        $r('sys.color.ohos_id_color_text_primary_contrary'));
      this.updateConnectingGuideText();
    } else if (this.currentStatus == SYS_STATUS_SEARCHING_SATELLITE) {
      this.getAzimuthText();
    }
  }

  setStatusText(target: Resource, color: Resource) {
    this.oldStatusText = this.newStatusText;
    this.newStatusText = target;
    this.oldStatusTextColor = this.newStatusTextColor;
    this.newStatusTextColor = color
    this.startStatusTextAnimation();
  }

  setGuideText(target: Resource) {
    this.oldGuideText = this.newGuideText;
    this.newGuideText = target;
    if (JSON.stringify(this.oldGuideText) !== JSON.stringify(this.newGuideText)) {
      this.startGuideTextAnimation();
    }
  }

  updateConnectingGuideText() {
    if (this.currentStatus == SYS_STATUS_SATELLITE_CONNECTING) {
      let time = Math.trunc((this.connectTime - 1) / 10);
      switch (time % 3) {
        case 0:
          this.connectingGuideNumber = 0;
          this.setGuideText($r('app.string.float_window_keep_posture_wait_patiently'));
          break;
        case 1:
          this.connectingGuideNumber = 1;
          this.setGuideText($r('app.string.float_window_keep_posture'));
          break;
        case 2:
          this.connectingGuideNumber = 2;
          this.setGuideText($r('app.string.float_window_keep_posture_check_occlusion'));
          break;
        default:
          break;
      }
    }
  }

  updateStatusAndGuideTextForSuccess() {
    if (this.currentStatus == SYS_STATUS_SEARCH_SATELLITE_SUCC) {
      if (this.mDirection != SatelliteDirection.NONE) {
        this.setStatusText($r('app.string.device_offset_reminder'), $r('sys.color.ohos_id_color_text_primary_contrary'));
      } else {
        this.setStatusText($r('app.string.satellite_hunt_success'), $r('sys.color.ohos_id_color_text_primary_contrary'));
      }
    }
  }

  //添加状态变化监听接口
  addStatusCallback() {
    if (this.statusUpdateCallback) {
      LogUtils.i(TAG, 'addStatusCallback: callTimeListener has been added');
      return;
    }
    this.statusUpdateCallback = ((status: number) => {
      LogUtils.i(TAG, 'satelliteManager.addStatusUpdateCallback is called, status = ' + status);
      this.showReConnect = this.satelliteManager.getShowReconnect();
      this.currentStatus = status;
    });
    this.satelliteManager.addStatusUpdateCallback(this.statusUpdateCallback);
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
    if (this.satelliteDataCallback) {
      LogUtils.i(TAG, 'addSatelliteDataCallback: has been added');
      return;
    }
    this.satelliteDataCallback = ((satelliteData: SatelliteData) => {
      if (this.currentStatus == SYS_STATUS_SEARCH_SATELLITE_FAIL) {
        return;
      }
      this.mSatelliteData = satelliteData;
    });
    this.satelliteManager.addSatelliteDataCallback(this.satelliteDataCallback);
  }

  //移除寻星角度数据监听回调接口
  removeSatelliteDataCallback() {
    if (this.satelliteDataCallback) {
      this.satelliteManager.removeSatelliteDataCallback(this.satelliteDataCallback);
      this.satelliteDataCallback = undefined;
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

  //添加经纬度变化监听接口
  addLocationCallback() {
    if (this.locationChangeCallback) {
      LogUtils.i(TAG, 'locationChangeCallback: callTimeListener has been added');
      return;
    }
    this.locationChangeCallback = ((convertLongitude: number, convertLatitude: number) => {
      LogUtils.i(TAG, 'satelliteManager.updateLocationListeners is called');
      //刷新经纬度信息到界面
      this.getLocationInfo(convertLongitude, convertLatitude);
    });
    this.satelliteManager.addLocationChangeCallback(this.locationChangeCallback);
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
    if (this.deviceDirChangeCallback) {
      LogUtils.i(TAG, 'deviceDirChangeCallback: callTimeListener has been added');
      return;
    }
    this.deviceDirChangeCallback = ((isLandscape: boolean) => {
      if (!this.shouldUploadOrentationMode()) {
        return;
      }
      LogUtils.i(TAG, 'addDeviceDirChangeCallback, isNeedToShowRemind: ' + isLandscape);
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

  private shouldUploadOrentationMode(): boolean {
    let currentStatus = this.satelliteManager.getCurrentStatus();
    if (currentStatus === SYS_STATUS_SEARCH_SATELLITE_FAIL) {
      return false;
    }
    return true;
  }

  moveWindow() {
    if (this.floatWindow) {
      this.floatWindow.moveWindowTo(this.windowPosition.x, this.windowPosition.y);
    }
  }

  getLocationAni() {
    this.locationOp = 1;
  }

  build() {
    NavDestination() {
      Stack() {
        Stack() {
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#2E3033')
        .opacity(0.8) // 透明度0.8
        .border({ style: BorderStyle.Dotted })

        Stack({ alignContent: Alignment.End }) {
          Row() {
            SatelliteFloatWindowSearch({
              currentStatus: $currentStatus,
              mSatelliteData: $mSatelliteData,
              showReConnect: $showReConnect
            })
              .width(180)
              .visibility((this.currentStatus === SYS_STATUS_SEARCHING_SATELLITE ||
                this.currentStatus === SYS_STATUS_SEARCH_SATELLITE_SUCC ||
                this.currentStatus === SYS_STATUS_SEARCH_SATELLITE_FAIL ||
                this.currentStatus === SYS_STATUS_SATELLITE_CONNECTING) &&
                !this.isShowOrientationRemind ? Visibility.Visible : Visibility.None)
            SatelliteFloatWindowLandscapeRemind()
              .visibility(this.isShowOrientationRemind ? Visibility.Visible : Visibility.None)
          }
          .height('100%')
          .width('100%')
          .justifyContent(FlexAlign.End)

          Column() {
            Row() {
              if (this.mAlertState != 0) {
                Text($r('app.string.satellite_enhance_status'))
                  .fontSize('10vp')
                  .fontColor($r('sys.color.ohos_id_color_text_primary_dark'))
                  .fontWeight(FontWeight.Medium)
                  .fontFamily('HarmonyHeiTi')
                  .textAlign(TextAlign.Center)
                  .backgroundColor('#ED6F21')
                  .padding({ left: 8, right: 8 })
                  .height(22)
                  .borderRadius('11vp')
                  .maxFontScale(MAX_FONT_SCALE)
                  .accessibilityLevel('yes')
              } else {
              Text(this.signalDescription)
                  .fontSize(8)
                  .fontColor($r('sys.color.ohos_id_color_text_secondary_contrary'))
                  .fontWeight(FontWeight.Regular)
                  .fontFamily('HarmonyHeiTi')
                  .maxFontScale(MAX_FONT_SCALE)
                  .accessibilityLevel('yes')
                ForEach(this.arr, (item: number) =>{
                  Stack() {
                    Image(this.signalIcon)
                      .width(5)
                      .height(14)
                      .margin({ left: 4 })
                      .draggable(false)
                    if (this.mSignal > item) {
                      Image(this.signalIconOk)
                        .width(5)
                        .height(14)
                        .margin({ left: 4 })
                        .draggable(false)
                        .transition(TransitionEffect.OPACITY.animation({
                          duration: 200,
                          curve: this.singleOkCubic
                        }))
                    }
                  }
                })
              }
            }
            .justifyContent(FlexAlign.Center)
            .margin({ top: 12 })

            Stack() {
              Text(this.oldStatusText)
                .fontSize(18)
                .maxLines(1)
                .fontWeight(600)
                .textAlign(TextAlign.Start)
                .ellipsisMode(EllipsisMode.END)
                .fontColor(this.oldStatusTextColor)
                .fontFamily('HarmonyHeiTi')
                .visibility(getVisibilityByTextOp(Boolean(this.oldStatusTextOp)))
                .maxFontScale(MAX_FONT_SCALE)
                .accessibilityLevel('yes')

              Text(this.newStatusText)
                .fontSize(18)
                .maxLines(1)
                .fontWeight(FontWeight.Bold)
                .textAlign(TextAlign.Start)
                .ellipsisMode(EllipsisMode.END)
                .fontColor(this.newStatusTextColor)
                .fontFamily('HarmonyHeiTi')
                .visibility(getVisibilityByTextOp(Boolean(this.newStatusTextOp)))
                .maxFontScale(MAX_FONT_SCALE)
                .accessibilityLevel('yes')
            }
            .margin({ top: 10 })
            .alignContent(Alignment.Start)

            Stack() {
              Text(this.oldGuideText)
                .fontSize(14)
                .maxLines(2)
                .fontWeight(FontWeight.Regular)
                .ellipsisMode(EllipsisMode.END)
                .fontColor($r('sys.color.ohos_id_color_text_secondary_dark'))
                .textAlign(TextAlign.Center)
                .fontFamily('HarmonyHeiTi')
                .visibility(getVisibilityByTextOp(Boolean(this.oldGuideTextOp)))
                .maxFontScale(MAX_FONT_SCALE)
                .accessibilityLevel('yes')

              Text(this.newGuideText)
                .fontSize(14)
                .maxLines(2)
                .fontWeight(FontWeight.Regular)
                .ellipsisMode(EllipsisMode.END)
                .fontColor($r('sys.color.ohos_id_color_text_secondary_dark'))
                .textAlign(TextAlign.Center)
                .fontFamily('HarmonyHeiTi')
                .visibility(getVisibilityByTextOp(Boolean(this.newGuideTextOp)))
                .maxFontScale(MAX_FONT_SCALE)
                .accessibilityLevel('yes')
            }
            .alignContent(Alignment.Start)
            .visibility(this.isShowOrientationRemind ? Visibility.None : Visibility.Visible)
            .margin({ top: 2 })

            Stack({ alignContent: Alignment.Bottom }) {
              Text(this.location)
                .fontSize(8)
                .fontColor(Color.White)
                .fontColor($r('sys.color.ohos_id_color_text_secondary_dark'))
                .fontFamily('HarmonyHeiTi')
                .width('auto')
                .height('auto')
                .position({ x: 0, y: '100%' })
                .translate({ y: '-100%' })
                .maxFontScale(MAX_FONT_SCALE)
                .transition(TransitionEffect.OPACITY.animation({
                  duration: 150,
                  curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1)
                }))
                .accessibilityLevel('yes')
            }
            .alignContent(Alignment.Start)
            .width('100%')
            .layoutWeight(1)
            .margin({ bottom: 16 })
          }
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Start)
          .align(Alignment.Start)
          .height('100%')
          .margin({ start: LengthMetrics.vp(16) })
        }
        .width('100%')
        .height('100%')
        .borderRadius(18)
        .border({ style: BorderStyle.Dotted })
        .gesture(
          // 绑定PanGesture事件，监听拖拽动作
          PanGesture(this.panOption)
            .onActionStart((event: GestureEvent) => {
              console.info('Pan start');
            })
            .onActionUpdate((event: GestureEvent) => {
              try {
                if ((this.windowPosition.y + event.offsetY) < vp2px(marginTopAndBottomPix) ||
                  (this.windowPosition.y + event.offsetY + marginBottomPix) >
                    (display.getDefaultDisplaySync().height - vp2px(marginTopAndBottomPix))) {
                  return
                }
                // 暂定x轴不允许移动，只能上下移动
                this.windowPosition.y += event.offsetY;
              } catch (err) {
                LogUtils.e(TAG, `onActionUpdate error: ${err?.code} ${err?.message}`);
              }
            })
            .onActionEnd(() => {
              this.floatWindowManager.setLeftMovingDirection(this.windowPosition.x)
              this.floatWindowManager.setTopMovingDirection(this.windowPosition.y)
              console.info('Pan end');
            })
        )
      }
      .onClick(() => {
        this.startSaltelliteOpAn = !this.startSaltelliteOpAn;
        this.satelliteManager.createSatelliteDialog()
      })
      .accessibilityGroup(true)
    }
    .backgroundColor('#00000000')
    .backdropBlur(50)
    .width('100%')
    .height('100%')
    .border({ style: BorderStyle.Dotted })
  }

  private addSatelliteConnectTimeCallback(): void {
    if (this.satelliteConnectTimeCallBack) {
      LogUtils.i(TAG, 'addSatelliteConnectTimeCallback callback has been added.');
      return;
    }
    this.satelliteConnectTimeCallBack = ((connectTime: number) => {
      LogUtils.i(TAG, 'addSatelliteConnectTimeCallback connectTime: ' + connectTime);
      this.connectTime = connectTime;
      this.newStatusText = this.getWaitStateCountData();
      this.updateConnectingGuideText();
      if (this.connectTime == 0) {
        this.showReConnect = true;
        SatelliteSearchManager.getInstance().setShowReconnect(true);
        this.currentStatus = SYS_STATUS_SEARCH_SATELLITE_FAIL;
        this.satelliteManager.setCurrentStatus(SYS_STATUS_SEARCH_SATELLITE_FAIL);
        this.connectTime = SatelliteSearchManager.getInstance().getMaxConnectTime();
      }
    });
    SatelliteSearchManager.getInstance().addSatelliteConnectTimeCallback(this.satelliteConnectTimeCallBack);
  }

  private getWaitStateCountData(): Resource {
    let res: Resource;
    if (isSupportCactus()) {
      if (this.connectTime > 15) {
        res = $r('app.string.satellite_connecting', this.connectTime - 15)
      } else {
        res = $r('app.plural.satellite_reconnecting', this.connectTime, this.connectTime);
      }
    } else {
      res = $r('app.string.satellite_connecting', this.connectTime)
    }
    return res;
  }

  private removeSatelliteConnectTimeCallback(): void {
    if (this.satelliteConnectTimeCallBack) {
      SatelliteSearchManager.getInstance().removeSatelliteConnectTimeCallback(this.satelliteConnectTimeCallBack);
      this.satelliteConnectTimeCallBack = undefined;
    }
  }
}
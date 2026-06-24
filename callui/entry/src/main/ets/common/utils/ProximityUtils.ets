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

import { getForegroundCall, isVideoCall } from './CallListHelper';
import CallDataManager from '../../model/CallDataManager';
import LogUtils from './LogUtils';
import CallStateConst from '../constant/CallStateConst';
import runningLock from '@ohos.runningLock';
import { ExternalCallModel } from '../../model/ExternalCallModel';
import DefaultCallData from '../struct/TypeUtils';
import { BusinessError } from '@ohos.base';
import Utils from './utils';
import { settings } from '@kit.BasicServicesKit';
import * as Constants from './Constants';
import * as BannerNotificationProxy from './BannerNotificationProxy';
import AudioDeviceManager from '../../model/audio/AudioDeviceManager';
import * as DeviceTypeConst from '../constant/DeviceTypeConst';
import sensor from '@ohos.sensor';
import { GlobalContextHelper } from './GlobalContextHelper';
import window from '@ohos.window';
import CallManagerService from '../../ServiceAbility/CallManagerService';

const TAG = 'ProximityUtils';

export class ProximityUtils {

  private static recordLock: runningLock.RunningLock | null = null;
  private static sIsInfraredProximitySensor: boolean = true;
  private static isKeepOn: boolean = false;
  private static isPickup: boolean = false;
  private static isAcc: boolean = false;
  private static isGyr: boolean = false;
  private static isUnregAcc: boolean = false;
  private static isUnregGyr: boolean = false;

  static {
    ProximityUtils.getSensorList();
  }

  public static updateProximityLock(call?: DefaultCallData) {
    call = call ? call : getForegroundCall(CallDataManager.getInstance().callList);
    if (!call) {
      return;
    }
    LogUtils.i(TAG, `call.callId is ${call.callId}, call.callState is ${call.callState}`);
    if (call.callState === CallStateConst.CALL_STATUS_INCOMING ||
      call.callState === CallStateConst.CALL_STATUS_DISCONNECTED ||
      call.callState === CallStateConst.CALL_STATUS_DISCONNECTING) {
      ProximityUtils.unHoldProximityLock();
      return;
    }

    if (ProximityUtils.isCoverMode()) {
      LogUtils.i(TAG, 'CoverMode is true');
      ProximityUtils.unHoldProximityLock();
      return
    }

    if (ExternalCallModel.getInstance().isSmallExternalAndFolded()) {
      ProximityUtils.unHoldProximityLock();
      return;
    }

    if (!AppStorage.get('onPageShow') && AppStorage.get('LandscapeOrPortrait') !== 1) {
      ProximityUtils.checkImmersiveWindow(call);
      return;
    }

    ProximityUtils.checkAudioTypeAndVideoCall(call);
  }

  private static setPickup() {
    if (ProximityUtils.isAcc && ProximityUtils.isGyr) {
      ProximityUtils.isPickup = true;
      LogUtils.i(TAG, 'isPickup ' + ProximityUtils.isPickup);
      AppStorage.setOrCreate('isPickup', ProximityUtils.isPickup);
    }
    ProximityUtils.isPickup = false;
  }

  public static registerAcc() {
    try {
      sensor.on(sensor.SensorId.ACCELEROMETER, (data: sensor.AccelerometerResponse) => {
        const x = data.x;
        if (x > 3) {
          ProximityUtils.isAcc = true;
          ProximityUtils.setPickup();
        } else {
          ProximityUtils.isAcc = false;
        }
      }, { interval: 200000000 });
    } catch (error) {
      let e: BusinessError = error as BusinessError;
      LogUtils.e(TAG, `registerAcc Failed. Code: ${e.code}, message: ${e.message}`);
    }
  }

  public static unRegisterAcc() {
    try {
      if (!ProximityUtils.isUnregAcc) {
        sensor.off(sensor.SensorId.ACCELEROMETER);
        ProximityUtils.isUnregAcc = true;
      }
    } catch (error) {
      let e: BusinessError = error as BusinessError;
      LogUtils.e(TAG, `unRegisterAcc Failed. Code: ${e.code}, message: ${e.message}`);
    }
  }

  public static registerGyr() {
    try {
      sensor.on(sensor.SensorId.GYROSCOPE, (data: sensor.GyroscopeResponse) => {
        const y = data.y;
        if (y > 0.4) {
          ProximityUtils.isGyr = true;
          ProximityUtils.setPickup();
        } else {
          ProximityUtils.isGyr = false;
        }
      }, { interval: 200000000 });
    } catch (error) {
      let e: BusinessError = error as BusinessError;
      LogUtils.e(TAG, `registerGry Failed. Code: ${e.code}, message: ${e.message}`);
    }
  }

  public static unRegisterGyr() {
    try {
      if (!ProximityUtils.isUnregGyr) {
        sensor.off(sensor.SensorId.GYROSCOPE);
        ProximityUtils.isUnregGyr = true;
      }
    } catch (error) {
      let e: BusinessError = error as BusinessError;
      LogUtils.e(TAG, `unRegisterGry Failed. Code: ${e.code}, message: ${e.message}`);
    }
  }

  /**
   * hold Proximity Lock
   */
  public static holdProximityLock(): void {
    if (ProximityUtils.recordLock) {
      if (!ProximityUtils.recordLock.isHolding()) {
        LogUtils.i(TAG, 'holdProximityLock, not holding to hold');
        ProximityUtils.recordLock.hold(-1);
      }
    } else {
      runningLock.create('call_lock', runningLock.RunningLockType.PROXIMITY_SCREEN_CONTROL).then(lock => {
        LogUtils.d(TAG, 'holdProximityLock create running lock success');
        if (ProximityUtils.recordLock != undefined) {
          LogUtils.i(TAG, 'holdProximityLock recordLock not is null');
          return;
        }
        try {
          ProximityUtils.recordLock = lock;
          LogUtils.i(TAG, 'holdProximityLock, create hold');
          lock.hold(-1);
        } catch (err) {
          LogUtils.e(TAG, 'holdProximityLock hold running lock failed, err: ' + err);
        }
      }).catch((err: BusinessError) => {
        LogUtils.e(TAG, 'holdProximityLock create running lock failed, err: ' + err);
      });
    }
  }

  /**
   * unHold Proximity Lock
   */
  public static unHoldProximityLock(): void {
    if (ProximityUtils.recordLock) {
      if (ProximityUtils.recordLock.isHolding()) {
        LogUtils.i(TAG, 'unHoldProximityLock unhold');
        ProximityUtils.recordLock.unhold();
      }
    } else {
      runningLock.create('call_lock', runningLock.RunningLockType.PROXIMITY_SCREEN_CONTROL).then(lock => {
        LogUtils.i(TAG, 'unHoldProximityLock create running lock success');
        if (ProximityUtils.recordLock != undefined) {
          LogUtils.i(TAG, 'unHoldProximityLock recordLock not is null');
          return;
        }
        try {
          ProximityUtils.recordLock = lock;
          lock.unhold();
          LogUtils.i(TAG, 'unHoldProximityLock create unhold');
        } catch (err) {
          LogUtils.e(TAG, 'unHoldProximityLock unhold running lock failed, err: ' + err);
        }
      }).catch((err: BusinessError) => {
        LogUtils.e(TAG, 'unHoldProximityLock create running lock failed, err: ' + err);
      });
    }
  }

  private static isCoverMode() {
    let context = Utils.getInstance().getContext();
    let cover: boolean = false;
    if (!context) {
      LogUtils.e(TAG, 'isCoverMode context is null')
      return;
    }
    let coverModel: boolean | undefined = CallManagerService.getInstance().getCoverModel();
    LogUtils.i(TAG, `coverModel value is ${coverModel}`);
    if (coverModel === null || coverModel === undefined) {
      cover = settings.getValueSync(context, Constants.COVER_WINDOW_SHOWING, 'false') === 'true';
      CallManagerService.getInstance().setCoverModel(cover);
      return cover;
    } else {
      return coverModel;
    }
  }

  private static async checkImmersiveWindow(call: DefaultCallData) {
    const hasImmersiveWindow = await BannerNotificationProxy.hasImmersiveWindow();
    if (hasImmersiveWindow) {
      ProximityUtils.unHoldProximityLock();
      return;
    }
    ProximityUtils.checkAudioTypeAndVideoCall(call);
  }

  private static checkAudioTypeAndVideoCall(call: DefaultCallData) {
    let curAudioType = AudioDeviceManager.getInstance().audioDeviceInfo.currentAudioDevice.deviceType;
    LogUtils.i(TAG, 'curAudioType is ' + curAudioType);
    if (curAudioType === DeviceTypeConst.DEVICE_EARPIECE && !isVideoCall(call.videoState)) {
      ProximityUtils.holdProximityLock();
    } else {
      ProximityUtils.unHoldProximityLock();
    }
  }

  static getSensorList(): void {
    sensor.getSensorList((err: BusinessError, sensorList: sensor.Sensor[]) => {
      ProximityUtils.findInfraredProximitySensor(err, sensorList);
    });
  }

  static findInfraredProximitySensor(err?: BusinessError, sensorList?: sensor.Sensor[]) {
    if (err) {
      LogUtils.e(TAG, `Failed to getSensorList. Code: ${err.code}, message: ${err.message}`);
      return;
    }
    if (!sensorList || sensorList.length === 0) {
      LogUtils.e(TAG, `Failed to getSensorList. list is ${sensorList?.length}`);
      return;
    }
    let isInfraredProximitySensor = false;
    const sensorTypeId = ExternalCallModel.isSmallExternalDevice() ? 18 : 12;
    for (let index = 0; index < sensorList.length; index++) {
      if (sensorTypeId !== sensorList[index].sensorId) {
        continue;
      }
      const strSensorName = sensorList[index].sensorName;
      if (strSensorName.indexOf('ps_s') >= 0) {
        isInfraredProximitySensor = true;
        LogUtils.i(TAG, 'isInfraredProximitySensor');
        break;
      }
    }
    ProximityUtils.sIsInfraredProximitySensor = isInfraredProximitySensor;
  }

  public static isInfraredProximitySensor() {
    return ProximityUtils.sIsInfraredProximitySensor;
  }

  /** query and get Proximity light value */
  public static wakeUpScreenByProximity() {
    try {
      sensor.getSingleSensor(sensor.SensorId.PROXIMITY, (err: BusinessError, data: sensor.Sensor) => {
        if (err) {
          LogUtils.e(TAG, `Failed to get singleSensor. Code: ${err.code}, message: ${err.message}`);
          ProximityUtils.wakeUpScreen(true);
          return;
        }
        try {
          sensor.on(sensor.SensorId.PROXIMITY, (data: sensor.ProximityResponse) => {
            LogUtils.i(TAG, 'Succeeded in invoking on. Distance: ' + data.distance);
            if (data.distance === CallStateConst.AWAY_FROM_PROXIMITY) {
              ProximityUtils.wakeUpScreen(true);
            }
          }, {
            interval: 100000000
          });
          setTimeout(() => {
            sensor.off(sensor.SensorId.PROXIMITY);
          }, 500);
        } catch (error) {
          ProximityUtils.wakeUpScreen(true);
          LogUtils.e(TAG, `Failed to invoke on. Code: ${error.code}, message: ${error.message}`);
        }
      });
    } catch (error) {
      ProximityUtils.wakeUpScreen(true);
      LogUtils.e(TAG, `Failed to get singleSensor. Code: ${error.code}, message: ${error.message}`);
    }
  }

  public static async wakeUpScreen(isWakeUp: boolean): Promise<void> {
    LogUtils.i(TAG, 'wakeUpScreen : ' + JSON.stringify(isWakeUp));
    await GlobalContextHelper.getContext().getValue<window.Window>(Constants.WINDOW)?.
    setWakeUpScreen(isWakeUp);
  }

  /**
   * keep screen on
   */
  public static keepScreenOn(isKeepOn: boolean) {
    if (ProximityUtils.isKeepOn === isKeepOn) {
      LogUtils.i(TAG, `isKeepOn: ${isKeepOn}`);
      return;
    }
    let windowObj = GlobalContextHelper.getContext().getValue<window.Window>(Constants.WINDOW);
    if (windowObj) {
      ProximityUtils.isKeepOn = isKeepOn;
      windowObj.setWindowKeepScreenOn(isKeepOn).then(() => {
        LogUtils.i(TAG, 'keepScreenOn : ' + isKeepOn);
      }).catch((err: BusinessError) => {
        LogUtils.e(TAG, 'keepScreenOn catch : ' + JSON.stringify(err));
      });
    } else {
      ProximityUtils.isKeepOn = isKeepOn;
      LogUtils.e(TAG, 'windowObj is null or undefined');
    }
  }

  public static minimize(): boolean {
    let windowObj = GlobalContextHelper.getContext().getValue<window.Window>(Constants.WINDOW);
    if (windowObj === undefined) {
      LogUtils.i(TAG, 'Failed to minimize the window. Cause: windowObj === undefined');
      return false;
    }
    windowObj.minimize((err: BusinessError) => {
      if (err) {
        LogUtils.e(TAG, 'Failed to minimize the window. Cause: ' + JSON.stringify(err));
        return;
      }
      LogUtils.i(TAG, 'Succeeded in minimizing the window.');
    });
    return true;
  }
}
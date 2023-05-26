/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

/**
 * Vibration And Proximity Util
 *
 * standard:
 * 1. define TAG, recommend class name.
 * 2. switch IS_DEBUG_ON as true, when debugging.
 * 3. msg should be short and valuable.
 * 4. choose appropriate function.
 * 5. the function execute many times can not print.
 * 6. uniqueness.
 */
import audio from '@ohos.multimedia.audio';
import CallServiceProxy from '../../model/CallServiceProxy';
import LogUtils from './LogUtils';
import runningLock from '@ohos.runningLock';
import sensor from '@ohos.sensor';
import vibrator from '@ohos.vibrator';

const TAG = 'VibrationAndProximityUtils';
const PROXIMITY_INTERVAL = 10000000;
const VIBRATION_COUNT = 20;

/**
 *  Vibration And Proximity tool class
 */
export class VibrationAndProximityUtils {

  startVibrationFlag = false;
  addProximityListenerFlag = false;
  recordDistance = -1;
  recordLock = null;

  /**
   * add Proximity Listener
   */
  public addProximityListener() {
    try {
      if (this.addProximityListenerFlag) {
        LogUtils.e(TAG, 'addProximityListener return');
        return;
      }
      this.addProximityListenerFlag = true;
      let that = this
      sensor.on(sensor.SensorId.PROXIMITY, function (data) {
        if (data) {
          if (that.recordDistance != data.distance) {
            if (data.distance == 0) {
              that.suspendScreen();
            } else {
              that.wakeupScreen();
            }
          }
          that.recordDistance = data.distance;
        }
      }, { interval: PROXIMITY_INTERVAL });
    } catch (err) {
      LogUtils.e(TAG, 'addProximityListener sensor On fail, errCode: ' + err.code + ' ,msg: ' + err.message);
    }
  }

  /**
   * remove Proximity Listener Vibration
   */
  removeProximityListener() {
    try {
      if (!this.addProximityListenerFlag) {
        LogUtils.e(TAG, 'removeProximityListener return');
        return;
      }
      this.addProximityListenerFlag = false;
      sensor.off(sensor.SensorId.PROXIMITY, function () {
        LogUtils.i(TAG, 'removeProximityListener ');
      })
    } catch (err) {
      LogUtils.e(TAG, 'removeProximityListener sensor off fail, errCode: ' + err.code + ' ,msg: ' + err.message);
    }
  }

  /**
   * suspend Screen
   */
  public suspendScreen() {
    if (this.recordLock) {
      this.recordLock.hold(Number.MAX_VALUE);
      LogUtils.i(TAG, 'suspendScreen hold');
    } else {
      let that = this;
      runningLock.create('call_lock', runningLock.RunningLockType.PROXIMITY_SCREEN_CONTROL).then(lock => {
        LogUtils.i(TAG, 'suspendScreen create running lock success');
        try {
          that.recordLock = lock;
          lock.hold(Number.MAX_VALUE);
          LogUtils.i(TAG, 'suspendScreen hold');
        } catch(err) {
          LogUtils.e(TAG, 'suspendScreen hold running lock failed, err: ' + err);
        }
      }).catch(err => {
        LogUtils.e(TAG, 'suspendScreen create running lock failed, err: ' + err);
      });
    }
  }

  /**
   * wakeup Screen
   */
  public wakeupScreen() {
    if (this.recordLock) {
      this.recordLock.unhold();
      LogUtils.i(TAG, 'wakeupScreen unhold');
    } else {
      let that = this;
      runningLock.create('call_lock', runningLock.RunningLockType.PROXIMITY_SCREEN_CONTROL).then(lock => {
        LogUtils.i(TAG, 'wakeupScreen create running lock success');
        try {
          that.recordLock = lock;
          lock.unhold();
          LogUtils.i(TAG, 'wakeupScreen unhold');
        } catch(err) {
          LogUtils.e(TAG, 'wakeupScreen unhold running lock failed, err: ' + err);
        }
      }).catch(err => {
        LogUtils.e(TAG, 'wakeupScreen create running lock failed, err: ' + err);
      });
    }
  }

  /**
   * start Vibration
   */
  public startVibration() {
    try {
      if (this.startVibrationFlag) {
        LogUtils.e(TAG, 'startVibration return');
        return;
      }
      let that = this;
      vibrator.startVibration({
        type: 'preset',
        effectId: 'haptic.ringtone.T-Mobile_Ring',
        count: VIBRATION_COUNT
      }, {
        usage: 'ring'
      }, (error) => {
        if (error) {
          LogUtils.e(TAG, 'startVibration fail, error.code: ' + error.code + ', error.message: ' + error.message);
        } else {
          that.startVibrationFlag = true;
          LogUtils.i(TAG, 'startVibration Callback returned to indicate a successful vibration.');
        }
      });
    } catch (err) {
      LogUtils.e(TAG, 'startVibration errCode: ' + err.code + ' ,msg: ' + err.message);
    }
  }

  /**
   * stop Vibration
   */
  public stopVibration() {
    if (!this.startVibrationFlag) {
      LogUtils.e(TAG, 'stopVibration return');
      return;
    }
    try {
      let that = this;
      vibrator.stopVibration(vibrator.VibratorStopMode.VIBRATOR_STOP_MODE_PRESET, function (error) {
        if (error) {
          LogUtils.e(TAG, 'stopVibration error.code: ' + error.code + ', error.message: ' + error.message);
          return;
        }
        that.startVibrationFlag = false;
        LogUtils.i(TAG, 'stopVibration Callback returned to indicate successful.');
      })
    } catch (err) {
      LogUtils.e(TAG, 'stopVibration errCode: ' + err.code + ' ,msg: ' + err.message);
    }
  }

  /**
   * add Voice Observe
   */
  addVoiceObserver() {
    audio.getAudioManager().on('volumeChange', () => {
      LogUtils.i(TAG, 'addVoiceObserver volumeChange');
      this.stopVibration();
      CallServiceProxy.getInstance().muteRinger();
    });
  }
}

let mVibrationAndProximityUtils = new VibrationAndProximityUtils();

export default mVibrationAndProximityUtils as VibrationAndProximityUtils;


/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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

import { LogUtils, ReportUtil } from '@ohos/common/CommonIndex';
import sensor from '@ohos.sensor'
import BusinessError from '@ohos.base';
import { ACCURACY_FINISH,
  SatelliteEvent,
  SatelliteState,
  SYS_STATUS_WAIT_LOADING, } from '../../common/constant/SatelliteSearchConst';
import SatelliteSearchManager from '../../manager/SatelliteSearchManager';
import { isTablet } from '../../common/utils/DeviceTypeUtils';
import { TrifoldManager } from '../../manager/TrifoldManager';
import { isCorrectionEnable } from '../../common/utils/Utils';

const TAG: string = 'SatelliteCalibrate'

const tickMarkNum: number = 180;
const tickMarkLength: number = 8;
const FLOAT_DEGREES_180: number = 180.0;
const DEGREES_90: number = 90;
const DEGREES_180: number = 180;
const DEGREES_270: number = 270;
const DEGREES_360: number = 360;
const DEGREES_720: number = 720;
const ELEMENT_COUNT: number = 10;
const DEFAULT_NUM: number = -1;
const MINIFLOAT = 0.00001;
const NEGATIVE_FLOAT_DEGREES_180 = -180.0;
const CALIBRATE_ROTATE_DEGREE = 10.0;
const CALIBRATE_PERCENTAGE_FAST = 0.59;
const COMPASS_PERCENTAGE_SLOW = 0.25;
const SWITCH_NEGATIVE_FLOAT = -1.0;
const BE_ON_LEVEL_DIRECTION_MAX: number = 5.0;
const DEGREES_45 = 45;
const DEGREES_135 = 135;
const DEGREES_225 = 225;
const DEGREES_315 = 315;
const BE_ON_LEVEL_TIME_MAX = 1000;
const MATH_ABS_DEFAULT = 0.1;
const TRACK_LEVEL_MAX = 135.0;
const TRACK_LEVEL_MID = 90.0;
const SCALE_MAX_LEVEL = 0.125;
const SCALE_MID_LEVEL = 0.167;
const TRACK_LEVEL_MIN = 30.0;
const SCALE_MIX_LEVEL = 0.25;
const TRACK_LEVEL_LARGE = 15.0;
const DEFAULT_SCALE = 0.5;
const ALPHA_MAX = 10;
const ALPHA_DEFAULT = 25;
const FLOAT_ARRAY_SIZE = 2;
const HALF_F = 2.0;
const LAST_IDX_DEFAULT = -5;
const ARRAY_SECOND_ELEMENT = 2;
const MAX_CALIBRATE_FAILED_TIME = 2;

@Entry
@Component
export struct SatelliteCalibrate {
  private settings: RenderingContextSettings = new RenderingContextSettings(true); // true is Turn on anti-aliasing
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private ballSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private ballContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.ballSettings);
  private canvasWidth: number = 236; // disc size
  private radius: number = 118; // disk radius
  private mOrientation: number[] = new Array(3);
  private mPosition: number = 0;
  private mSensorOrientationYs: Array<number> = new Array(10);
  private mSensorOrientationZs: Array<number> = new Array(10);
  private mValues: number[] = new Array(2);
  private mDirectAngelY: number = 0.0;
  private mCount: number = 0;
  private mBeOnLevelTime: number = 0;
  private mBeOnLevelDirection: number = 0.0;
  private mStats: number[] = new Array(180);
  private mLastIdx = LAST_IDX_DEFAULT;
  private mTheta = DEGREES_90;
  private mIsCalibrateFinish: boolean = false;
  private mCheckTurn: number = 0;
  private mIsCalibrateFail: boolean = false;
  private mLastAngel: number = 0;
  @State private mLastDrawingAngle: number = 0;
  @Prop megnecticAccuracy: number = 1;
  @Link @Watch('needToReCalibrate') showReCalibrate: boolean;
  @Link @Watch('skipCalibrate') isSkipCalibrate: boolean;
  @Link satelliteSearchWidth: number;
  private calibrateImg:ImageBitmap = new ImageBitmap('/common/images/calibrate_ball.png');
  private calibrateBaseImg: Resource =
    SatelliteSearchManager.getInstance().getIsFromMeetime() ? $r('app.media.meetime_background_calibrate_base') :
    $r('app.media.background_calibrate_base');
  private startCalibrateTime: number = 0;
  private mCalibrateFailedTime: number = 0;
  private beforeAccuracy: number = 1;
  private isPrintSensorResponseLog: boolean = true;

  aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear');
    this.satelliteSearchWidth = this.satelliteSearchWidth == 0 ? 360 : this.satelliteSearchWidth;
    this.canvasWidth = 236 * this.satelliteSearchWidth / 360;
    this.radius = this.canvasWidth / 2;
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear');
    this.unregisterSensor();
  }

  needToReCalibrate() {
    if (!this.showReCalibrate && this.mIsCalibrateFail) {
      this.resetCalibrateParam();
      this.context.clearRect(-this.radius, -this.radius, this.canvasWidth, this.canvasWidth);
      this.drawTickMarks();
      this.startCalibrateTime = new Date().valueOf();
    }
  }

  calibrateSensorListener() {
    try {
      LogUtils.i(TAG, `begin regist sensor`);
      sensor.on(sensor.SensorId.ROTATION_VECTOR, (data: sensor.RotationVectorResponse) => {
        if (this.isPrintSensorResponseLog) {
          LogUtils.i(TAG,
            'rotation vector response, w: ' + data.w + ', x: ' + data.x + ', y: ' + data.y + ', z: ' + data.z +
              ', accuracy: ' + data.accuracy);
          this.isPrintSensorResponseLog = false;
        }
        if (isCorrectionEnable() && TrifoldManager.getInstance().isTripleFoldG()) {
          this.convertToOrientation(data.w, data.y, -data.x, data.z);
        } else {
          this.convertToOrientation(data.w, data.x, data.y, data.z);
        }
      }, { interval: 'game'}); // game level sensitivity
    } catch (err) {
      LogUtils.e(TAG, 'On fail, errCode: ' + err?.code + ' ,msg: ' + err?.message);
    }
  }

  unregisterSensor() {
    LogUtils.i(TAG, 'unregisterSensor');
    try {
      sensor.off(sensor.SensorId.ROTATION_VECTOR);
    } catch (err) {
      LogUtils.e(TAG, 'unregisterSensor off fail, errCode: ' + err?.code + ' ,msg: ' + err?.message);
    }
  }

  convert180To360Float(value: number): number {
    let result: number;
    if (value <= 0) {
      result = -value;
    } else {
      result = DEGREES_360 - value;
    }
    return result;
  }

  getAverage(values: number[]): number {
    let sum: number = 0.0;
    if (values == null || values.length == 0) {
      return sum;
    }
    for (let value of values) {
      sum += value;
    }
    return sum / values.length;
  }

  isBiggerFloat(f1: number, f2: number): boolean {
    return (f1 - f2) > MINIFLOAT;
  }

  isSmallerFloat(f1: number, f2: number): boolean {
    return (f2 - f1) > MINIFLOAT;
  }

  normalizeDegree(degree: number): number {
   return (degree + DEGREES_720) % DEGREES_360;
 }

  getInterpolation(input: number): number {
    return input * input;
  }

  equalFloat(f1: number, f2: number): boolean {
    return Math.abs(f1 - f2) <= MINIFLOAT;
}

  getStableAngle(lastAngle: number) {
  if (lastAngle >= DEGREES_315 && lastAngle < DEGREES_45) {
    return 0;
  } else if (lastAngle >= DEGREES_45 && lastAngle < DEGREES_135) {
    return DEGREES_90;
  } else if (lastAngle >= DEGREES_135 && lastAngle < DEGREES_225) {
    return DEGREES_180;
  } else {
    return DEGREES_270;
  }
}

  setDegreeAngelWithoutAnimation(angelX: number, direcangelX: number): number {
    let to: number = angelX;
    if (this.isBiggerFloat(to - direcangelX, DEGREES_180)) {
      to -= DEGREES_360;
    } else {
      if (this.isSmallerFloat(to - direcangelX, NEGATIVE_FLOAT_DEGREES_180)) {
        to += DEGREES_360;
      }
    }
    let distance: number = to - direcangelX;
    if (this.isBiggerFloat(Math.abs(distance), CALIBRATE_ROTATE_DEGREE)) {
        distance = distance > 0 ? CALIBRATE_ROTATE_DEGREE : (SWITCH_NEGATIVE_FLOAT * CALIBRATE_ROTATE_DEGREE);
    }
    return this.normalizeDegree(direcangelX + ((to - direcangelX) * this.getInterpolation(
    Math.abs(distance) > CALIBRATE_ROTATE_DEGREE ? CALIBRATE_PERCENTAGE_FAST : COMPASS_PERCENTAGE_SLOW)));
  }

  // convert rotation vector sensor data to angles
  convertToOrientation(x: number, y: number, z:number, w:number) {
    let squareY: number = y * y;
    let angleX: number = Math.atan2(2 * (w * x + z * y), 1 - 2 * (x * x + squareY));
    let angleY: number = Math.asin(2 * (w * y - z * x));
    let angleZ: number = Math.atan2(2 * (w * z + x * y), 1 - 2 * (z * z + squareY));

    let mAngleX: number = 180 * angleX / Math.PI;
    let mAngleY: number = 180 * angleY / Math.PI;
    let mAngleZ: number = 180 * angleZ / Math.PI;

    mAngleX = this.convert180To360Float(mAngleX);
    mAngleY = this.convert180To360Float(mAngleY);
    mAngleZ = this.convert180To360Float(mAngleZ);

    this.setOrientation(mAngleX, mAngleY, mAngleZ);
    if (Math.round(this.mDirectAngelY) != Math.round(this.mValues[0]) || Math.round(this.mValues[1]) != 0) {
      this.mDirectAngelY = this.mValues[0];
      if (this.mCount == 0) {
        this.mCount = DEFAULT_NUM;
      } else {
        this.mDirectAngelY = this.setDegreeAngelWithoutAnimation(this.mValues[0], this.mDirectAngelY);
      }
      this.doNext();
    }
  }

  setOrientation(x: number, y: number, z:number) {
    this.mOrientation[0] = x;
    this.mOrientation[1] = y;
    this.mOrientation[2] = z - FLOAT_DEGREES_180;

    if (this.mOrientation[1] > DEGREES_180) {
      this.mOrientation[1] = DEGREES_360 - this.mOrientation[1];
    } else {
      this.mOrientation[1] = 0 - this.mOrientation[1];
    }

    if (z >= DEGREES_270 || z <= DEGREES_90) {
      this.mOrientation[2] = z;
      if (this.mOrientation[2] > DEGREES_180) {
        this.mOrientation[2] = DEGREES_360 - this.mOrientation[2];
      } else {
        this.mOrientation[2] = 0 - this.mOrientation[2];
      }
    }

    if (this.mPosition == ELEMENT_COUNT - 1) {
      this.mPosition = 0;
    } else {
      this.mPosition++;
    }
    this.mSensorOrientationYs[this.mPosition] = this.mOrientation[1];
    this.mSensorOrientationZs[this.mPosition] = this.mOrientation[2];

    this.mOrientation[1] = this.getAverage(this.mSensorOrientationYs);
    this.mOrientation[2] = this.getAverage(this.mSensorOrientationZs);

    this.mValues[0] = FLOAT_DEGREES_180 * (Math.atan2(this.mOrientation[1], this.mOrientation[2]) / Math.PI);
    if (this.mValues[0] < 0) {
      this.mValues[0] = DEGREES_360 + this.mValues[0];
    }
    let island = isTablet() || TrifoldManager.getInstance().isTrifold();
    this.mValues[0] =
      (SatelliteSearchManager.getInstance().getIsFromMeetime() && island) ? (this.mValues[0] % DEGREES_360) :
        ((this.mValues[0] + DEGREES_90) % DEGREES_360);
    let orientation1: number = Math.abs(this.mOrientation[1]);
    let orientation2: number = Math.abs(this.mOrientation[2]);
    this.mValues[1] = Math.max(orientation1, orientation2);
  }

  calcNextTrack(start: number, dest: number) {
    let startAngle: number = this.normalizeDegree(start);
    let destAngle: number = this.normalizeDegree(dest);
    if (Math.abs(destAngle - startAngle) > MATH_ABS_DEFAULT) {
      let diff: number = destAngle - startAngle;
      let diffAbs: number = Math.abs(diff);
      let ascFlag: number = diff > 0 ? 1 : 0;
      let largeSpan: number = Math.abs(diff) > DEGREES_180 ? 1 : 0;
      let angleChg: number = ((ascFlag ^ largeSpan) == 1 ? 1 : DEFAULT_NUM) *
        ((largeSpan & 1) == 1 ? DEGREES_360 - diffAbs : diffAbs);
      let scale: number = 1.0; // default value

      if (Math.abs(angleChg) > TRACK_LEVEL_MAX) {
        scale = SCALE_MAX_LEVEL;
      } else if (Math.abs(angleChg) > TRACK_LEVEL_MID) {
        scale = SCALE_MID_LEVEL;
      } else if (Math.abs(angleChg) > TRACK_LEVEL_MIN) {
        scale = SCALE_MIX_LEVEL;
      } else if (Math.abs(angleChg) > TRACK_LEVEL_LARGE) {
        scale = DEFAULT_SCALE;
      } else {
        // calcNextTrack other
      }
      let cell: number = angleChg * scale;
      let value: number = startAngle + cell;
      return this.normalizeDegree(value);
    } else {
      return startAngle;
    }
  }

  setDegreeAndAngel(alpha: number, theta: number) {
    let idx: number = parseInt((theta / HALF_F).toString());
    if (idx < 0 || idx >= DEGREES_180) {
      this.mLastIdx = LAST_IDX_DEFAULT;
      return;
    }
    if ((alpha > ALPHA_MAX) && (alpha <= ALPHA_DEFAULT)) {
      if (this.mStats[idx] == 0) {
        this.mStats[idx] = 1;
      }
      if (((this.mLastIdx + FLOAT_ARRAY_SIZE) == idx) || ((this.mLastIdx - FLOAT_ARRAY_SIZE) == idx)) {
        let tmp: number = (this.mLastIdx + idx) >>> 1;
        if (this.mStats[tmp] == 0) {
          this.mStats[tmp] = 1;
        }
      }
    } else if (alpha > ALPHA_DEFAULT) {
      this.mStats[idx] = FLOAT_ARRAY_SIZE;
      if (((this.mLastIdx + FLOAT_ARRAY_SIZE) == idx) || ((this.mLastIdx - FLOAT_ARRAY_SIZE) == idx)) {
        let tmp: number = (this.mLastIdx + idx) >>> 1;
        this.mStats[tmp] = FLOAT_ARRAY_SIZE;
      }
    } else {
      LogUtils.i(TAG, 'setDegreeAndAngel other');
    }
    this.mTheta = theta;
    this.mLastAngel = Math.round(this.mTheta);
    this.mLastIdx = idx;
  }

  doNext() {
    if (this.mValues[1] <= 4) {
      if (this.mBeOnLevelTime == 0) {
        this.mBeOnLevelTime = new Date().valueOf();
        this.mBeOnLevelDirection = this.mDirectAngelY;
      } else if (Math.abs(this.mDirectAngelY - this.mBeOnLevelDirection) > BE_ON_LEVEL_DIRECTION_MAX) {
        if (!this.equalFloat(this.mLastDrawingAngle, this.getStableAngle(this.mLastDrawingAngle))) {
          this.mBeOnLevelTime = 0;
        } else {
          this.mDirectAngelY = this.mLastDrawingAngle;
        }
      } else {
        LogUtils.i(TAG, 'doNext other');
      }
    } else {
      this.mBeOnLevelTime = 0;
    }

    let next: number;
    let currAngle: number;
    if (this.mValues[1] <= 4 && this.mBeOnLevelTime != 0 &&
      (new Date().valueOf() - this.mBeOnLevelTime) > BE_ON_LEVEL_TIME_MAX &&
      Math.abs(this.mDirectAngelY - this.mBeOnLevelDirection) < BE_ON_LEVEL_DIRECTION_MAX) {
      currAngle = this.getStableAngle(this.mLastDrawingAngle);
      next = this.calcNextTrack(this.mLastDrawingAngle, currAngle);
    } else {
      this.setDegreeAndAngel(this.mValues[1], this.mDirectAngelY);
      currAngle = this.mTheta;
      next = this.calcNextTrack(this.mLastDrawingAngle, currAngle);
    }
    this.doDraw(next);
    this.mLastDrawingAngle = next;
  }

  getCountstat(): number {
    let countstat1: number = 0;
    let isTripleFoldG = isCorrectionEnable() && TrifoldManager.getInstance().isTripleFoldG();
    this.context.beginPath();
    for (let i = 0; i < tickMarkNum; i++) {
      if (this.mStats[i] != ARRAY_SECOND_ELEMENT) {
        countstat1++;
      } else {
        let rad = 2 * i * Math.PI / tickMarkNum;
        let x = Math.cos(rad) * this.radius;
        let y = Math.sin(rad) * this.radius;
        this.context.moveTo(isTripleFoldG ? -x : x, isTripleFoldG ? -y : y);
        let x1 = Math.cos(rad) * (this.radius - tickMarkLength);
        let y1 = Math.sin(rad) * (this.radius - tickMarkLength);
        this.context.lineTo(isTripleFoldG ? -x1 : x1, isTripleFoldG ? -y1 : y1);
      }
    }
    return countstat1;
  }

  countstat() {
    let countstat: number = this.getCountstat();
    this.context.strokeStyle = '#5291FF';
    this.context.stroke();
    if (countstat > 1) {
      return;
    }
    if (this.mIsCalibrateFinish) {
      return;
    }
    if (this.beforeAccuracy !== this.megnecticAccuracy) {
      LogUtils.i(TAG, 'countstat megnecticAccuracy: ' + this.megnecticAccuracy);
    }
    this.beforeAccuracy = this.megnecticAccuracy;
    if (this.megnecticAccuracy >= ACCURACY_FINISH) {
      this.mIsCalibrateFinish = true;
      ReportUtil.getInstance().reportSatelliteCalibrationInfo(new Date().valueOf() - this.startCalibrateTime, 1);
    } else {
      this.mCheckTurn++;
      LogUtils.i(TAG, 'mCheckTurn: ' + this.mCheckTurn);
      if (this.mCheckTurn > 187) { // 3s
        LogUtils.i(TAG, 'mCheckTurn over time.');
        this.setIsSkipCalibrate();
        this.mIsCalibrateFail = true;
        this.mIsCalibrateFinish = true;
        this.showReCalibrate = true;
        SatelliteSearchManager.getInstance().setShowReCalibrate(this.showReCalibrate);
        ReportUtil.getInstance().reportSatelliteCalibrationInfo(new Date().valueOf() - this.startCalibrateTime, 0);
        this.startCalibrateTime = 0;
      }
    }
  }

  private setIsSkipCalibrate(): void {
    if (!SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      return;
    }
    this.mCalibrateFailedTime++;
    LogUtils.i(TAG, 'setIsSkipCalibrate mCalibrateFailedTime: ' + this.mCalibrateFailedTime);
    if (this.mCalibrateFailedTime >= MAX_CALIBRATE_FAILED_TIME) {
      this.isSkipCalibrate = true;
    }
  }

  private skipCalibrate(): void {
    if (!SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      return;
    }
    if (!this.isSkipCalibrate && this.mCalibrateFailedTime >= MAX_CALIBRATE_FAILED_TIME) {
      LogUtils.i(TAG, 'skipCalibrate.');
      this.finishCalibrate();
      this.destroy();
    }
  }

  doDraw(angle: number) {
    this.countstat();
    if (this.mIsCalibrateFinish && !this.mIsCalibrateFail) {
      this.finishCalibrate();
      this.destroy();
    }
  }

  finishCalibrate() {
    let satelliteManager: SatelliteSearchManager = SatelliteSearchManager.getInstance();
    satelliteManager.setCurrentStatus(SYS_STATUS_WAIT_LOADING);
    satelliteManager.updateStatusListeners();
    if (satelliteManager.getIsFromMeetime()) {
      satelliteManager.sendSatelliteEventToMeetime(SatelliteEvent.EVENT_FINISH_CALIBRATE);
      // operation-loading
      satelliteManager.sendSatelliteEventToMeetime(SatelliteState.STATE_LOADING);
    }
    try {
      sensor.off(sensor.SensorId.ORIENTATION);
    } catch (err) {
      LogUtils.e(TAG, 'finishCalibrate off fail, errCode: ' + err?.code + ' ,msg: ' + err?.message);
    }
  }

  destroy() {
    LogUtils.i(TAG, 'destroy.');
    this.unregisterSensor();
    this.resetCalibrateParam();
}

  resetCalibrateParam() {
    LogUtils.i(TAG, 'resetCalibrateParam.');
    this.mIsCalibrateFinish = false;
    this.mIsCalibrateFail = false;
    this.mCheckTurn = 0;
    for (let i = 0; i < 180; i++) {
      this.mStats[i] = 0;
    }
  }

  drawTickMarks() {
    this.context.beginPath();
    for (let i = 0; i < tickMarkNum; i++) {
      let rad = 2 * Math.PI / tickMarkNum * i;
      let x = Math.cos(rad) * this.radius;
      let y = Math.sin(rad) * this.radius;
      this.context.moveTo(x, y);
      let x1 = Math.cos(rad) * (this.radius - tickMarkLength);
      let y1 = Math.sin(rad) * (this.radius - tickMarkLength);
      this.context.lineTo(x1, y1);
    }
    this.context.strokeStyle = '#CCCCCC';
    this.context.lineWidth = 1;
    this.context.stroke();
  }

  build() {
      Stack() {
        Image(this.calibrateBaseImg)
          .width('100%')
          .height('100%')
          .draggable(false)
        Canvas(this.context)
          .width(this.canvasWidth)
          .height(this.canvasWidth)
          .onReady(() => {
            this.context.translate(this.radius, this.radius); // move coordinate origin
            this.drawTickMarks();
            this.calibrateSensorListener();
            this.startCalibrateTime = new Date().valueOf();
          })

        Canvas(this.ballContext)
          .width(this.canvasWidth - (2 * tickMarkLength))
          .height(this.canvasWidth - (2 * tickMarkLength))
          .onReady(() => {
            this.ballContext.translate(this.radius - 8, this.radius - 8);
            this.ballContext.drawImage(this.calibrateImg,
              this.radius - 8 - 12 - 2 - 12, -12, 24, 24); // horizontal right
          })
          .rotate({ // around center point
            x: 0,
            y: 0,
            z: 1,
            centerX: '50%',
            centerY: '50%',
            angle: this.mLastDrawingAngle +
              (isCorrectionEnable() && TrifoldManager.getInstance().isTripleFoldG() ? 180 : 0)
          })
      }
      .width(this.satelliteSearchWidth)
      .height(this.satelliteSearchWidth)
    }
}
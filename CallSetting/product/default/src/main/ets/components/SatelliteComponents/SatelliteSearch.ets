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

import { curves } from '@kit.ArkUI';
import Curves from '@ohos.curves'
import { LogUtils } from '@ohos/common/CommonIndex';
import SatelliteUtils, { Y_MAX_DISTANCE, Y_MIN_DISTANCE } from '../../common/utils/SatelliteUtils';
import SatelliteSearchManager, { SatelliteData } from '../../manager/SatelliteSearchManager';
import {
  RECEIVER_STATUS_NULL,
  RECEIVER_STATUS_RECEIVING,
  RECEIVER_STATUS_SUCCESS,
  SatelliteDirection,
  SEND_STATUS_SENT,
  SEND_STATUS_SUCC,
  SYS_STATUS_SATELLITE_CONNECTING,
  SYS_STATUS_SATELLITE_KEEPING,
  SYS_STATUS_SEARCHING_SATELLITE,
  SYS_STATUS_SEARCH_SATELLITE_FAIL,
  SYS_STATUS_SEARCH_SATELLITE_SUCC
} from '../../common/constant/SatelliteSearchConst';
import { isTablet } from '../../common/utils/DeviceTypeUtils';
import { TrifoldManager } from '../../manager/TrifoldManager';

const TAG = 'SatelliteSearch';
const PITCH_SCALE: number = 1.3667;
const MAX_DIRECTION: number = 100;
const MIN_DIRECTION: number = -100;

let centerAngle: number = 130;
//小圆半径
let directionSmallRadius: number = 31;
//画圆
let directionLargeRadius: number = 118;


@Entry
@Component
export struct SatelliteSearch {
  @State show: boolean = true;
  uiContext: UIContext = this.getUIContext();
  @State arrowRightRotate: number = 0;
  @State satelliteOp: number = 0;
  @State failedSatelliteOp: number = 0;
  @State arrowOp: number = 0;
  @State satelliteBlueOp: number = 0;
  @State satelliteGreenOp: number = 0;
  @State arrowScale: number = 0.9;
  @State arrowTranslate: number = 19;
  @State ringOp: number = 0;
  @State maskOp: number = 0;
  @State ringScale: number = 0.15;
  @State maskScale: number = 0.15;
  @State lightScale: number = 0.15;
  @State rippleOp3: number = 1;
  @State connecting_wd_he_1: number = 64;
  @State connecting_wd_he_2: number = 64;
  @State connecting_wd_he_3: number = 64;
  @State connecting_op1: number = 0;
  @State connecting_op2: number = 0;
  @State connecting_op3: number = 0;
  @State isStopConnectingAnimation: boolean = false;
  @State isStartConnectingAnimation: boolean = false;
  @State connectedScale: number = 0.21;
  @State connectedOp: number = 0;
  @State lightY: number = 0;
  @State showLightGreen: boolean = false;
  @State azimuthImage: Resource = $r('app.media.turn_right')
  @State pitchImage: Resource =
    SatelliteSearchManager.getInstance().getIsFromMeetime() ? $r('app.media.meetime_dialog_center_blue') :
    $r('app.media.dialog_center_blue');
  @State pitchTranslationY: number = 0;
  @State satelliteBallOp: number = 0;
  @State mAzimuthDelta: number = 0;
  @State mPitchDelta: number = 0;
  @State radius: number = 120;
  @State angle: number = Math.PI / 4;
  @State radiusSmall: number = 31;
  @State radiusLar: number = 0;
  @State radiusToPxSmall: number = 0;
  @State startLarX: number = 0;
  @State startLarY: number = 0;
  @State targetLarX: number = 0;
  @State targetLarY: number = 0;
  @State radiusX: number = 180;
  @State radiusCircle: number = 180;
  @State startSmallX: number = 0;
  @State startSmallY: number = 0;
  @State targetSmallX: number = 0;
  @State targetSmallY: number = 0;
  @State scaleSize:number = 1;
  @Link satelliteSearchWidth: number;
  @Link @Watch('statusChange') currentStatus: number;
  @Link @Watch('changeSatelliteData') mSatelliteData: SatelliteData;
  @Link @Watch('changeSatelliteData') showReConnect: boolean;

  private mDirectionAzimuth = SatelliteDirection.NONE;
  @State mDirectionPitch: number = SatelliteDirection.NONE;
  private directionAngle: number = 60
  // 是否正在播放out动画
  private mSatelliteOutAnimate = false;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private settingsGreen: RenderingContextSettings = new RenderingContextSettings(true);
  private contextGreen: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settingsGreen);
  private settingsBlue: RenderingContextSettings = new RenderingContextSettings(true);
  private contextBlue: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settingsBlue);

  aboutToAppear(): void {
    if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      this.mAzimuthDelta = this.mSatelliteData?.azimuthDelta;
      this.mPitchDelta = this.mSatelliteData?.pitchAngleDelta;
    }
    this.currentStatus = SatelliteSearchManager.getInstance().getCurrentStatus();
    this.scaleSize = this.satelliteSearchWidth / 360;
    LogUtils.i(TAG, 'aboutToAppear is called, current status = ' + this.currentStatus);
    this.directionAngle = SatelliteUtils.getDefaultAngles();
    this.initData();
    this.getSweepCalculation();
    if (this.isStartAnimation()) {
      this.startConnectingAnimation();
    }
  }

  isStartAnimation(): boolean {
    if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      if ((this.currentStatus == SYS_STATUS_SATELLITE_CONNECTING ||
        this.currentStatus == SYS_STATUS_SEARCH_SATELLITE_SUCC || this.currentStatus == RECEIVER_STATUS_RECEIVING) &&
        !this.isStartConnectingAnimation) {
        return true;
      }
    } else {
      if (this.currentStatus == SYS_STATUS_SATELLITE_CONNECTING && !this.isStartConnectingAnimation) {
        return true;
      }
    }
    return false;
  }

  initData() {
    LogUtils.i(TAG, 'initData is called');
    this.resetSatelliteVis();
    if (this.currentStatus === SYS_STATUS_SEARCH_SATELLITE_FAIL) {
      this.failedSatelliteOp = 1;
      this.satelliteOp = 0;
      this.satelliteGreenOp = 0;
      this.satelliteBlueOp = 1;
    }
  }

  getSweepCalculation() {
    this.radius = this.radius * this.scaleSize;
    this.radiusCircle = this.radiusCircle * this.scaleSize;
    this.radiusLar = vp2px(this.radius);
    this.radiusToPxSmall = vp2px(directionSmallRadius);
    this.angle = 1 / 2 * Math.PI - this.directionAngle * Math.PI / 360;
    this.startLarX = vp2px(this.radiusCircle - this.radius * Math.cos(this.angle));
    this.startLarY = vp2px(this.radiusCircle - this.radius * Math.sin(this.angle));
    this.targetLarX = vp2px(this.radiusCircle + this.radius * Math.cos(this.angle));
    this.targetLarY = vp2px(this.radiusCircle - this.radius * Math.sin(this.angle));
    this.startSmallX = vp2px(this.radiusCircle + this.radiusSmall * Math.cos(this.angle));
    this.startSmallY = vp2px(this.radiusCircle - this.radiusSmall * Math.sin(this.angle));
    this.targetSmallX = vp2px(this.radiusCircle - this.radiusSmall * Math.cos(this.angle));
    this.targetSmallY = vp2px(this.radiusCircle - this.radiusSmall * Math.sin(this.angle));
    this.radiusX = vp2px(this.radiusCircle);
  }

  resetArrow() {
    this.arrowScale = 0.9;
    this.arrowTranslate = 19;
    this.arrowRightRotate = 0;
    this.stopArrowRightAnimation();
  }

  startArrowRightAnimation() {
    this.resetArrow();
    animateTo({
      duration: 450, curve: Curve.Friction, iterations: 1, onFinish: () => {
        setTimeout(() => {
          this.startArrowRightAnimationCycled();
        }, 500);
      }
    }, () => {
      this.arrowScale = 1;
      this.arrowTranslate = 0;
    })
  }

  startArrowRightAnimationCycled() {
    this.arrowRightRotate = 0;
    let isFirst = true;
    this.uiContext.keyframeAnimateTo({
      delay: isFirst ? 0 : 1000, iterations: -1, onFinish: () => {
        isFirst = false;
      }
    }, [
      {
        duration: 300,
        curve: Curves.cubicBezierCurve(0.30, 0, 0.70, 1),
        event: () => {
          this.arrowRightRotate = -8;
        }
      },
      {
        duration: 550,
        curve: Curves.cubicBezierCurve(0.30, 0, 0.40, 1),
        event: () => {
          this.arrowRightRotate = 10;
        }
      },
      {
        duration: 1200,
        curve: Curves.cubicBezierCurve(0.20, 0, 0.40, 1),
        event: () => {
          this.arrowRightRotate = 0;
        }
      },
    ])
  }

  stopArrowRightAnimation() {
    this.arrowRightRotate = -1;
    animateTo({ duration: 0 }, () => {
      this.arrowRightRotate = 0;
    })
  }

  getSatelliteVisAnimation() {
    this.getProgressAnimation();
    this.satelliteOp = 0;
    this.satelliteBlueOp = 0;
    this.satelliteGreenOp = 0;
    this.arrowOp = 0;
    this.satelliteBallOp = 0;
    animateTo({
      duration: 200, curve: Curve.Sharp, iterations: 1, onFinish: () => {
        SatelliteSearchManager.getInstance().setProgressAnimationIsFirst(true);
      }
    }, () => {
      this.resetSatelliteVis();
    })
  }

  resetSatelliteVis() {
    this.satelliteOp = 1;
    this.satelliteBallOp = 1;
    if (!SatelliteUtils.checkAzimuthOk(this.mAzimuthDelta)) {
      this.arrowOp = 1;
      this.satelliteBlueOp = 1;
    } else {
      this.satelliteGreenOp = 1;
    }
  }

  resetAnimiation() {
    this.ringOp = 0;
    this.ringScale = 0.3;
    this.maskScale = 0.25;
  }

  getProgressAnimation() {
    this.resetAnimiation();
    animateTo({
      duration: 1250, curve: curves.cubicBezierCurve(0.2, 0, 0.2, 1), iterations: 1 }, () => {
      this.ringScale = 1.2;
      this.maskScale = 1.3;
    })

    this.uiContext.keyframeAnimateTo({ iterations: 1 }, [
      {
        duration: 250,
        curve: Curve.Sharp,
        event: () => {
          this.ringOp = 0.75;
        }
      },
      {
        duration: 250,
        curve: Curve.Sharp,
        event: () => {
          this.ringOp = 0;
        }
      }
    ])

    this.uiContext.keyframeAnimateTo({ iterations: 1 }, [
      {
        duration: 500,
        curve: Curve.Sharp,
        event: () => {
          this.maskOp = 1;
        }
      },
      {
        duration: 500,
        curve: Curve.Sharp,
        event: () => {
          this.maskOp = 0;
        }
      }
    ])
  }

  getSatelliteInAnimation() {
    this.mSatelliteOutAnimate = false;
    this.stopArrowRightAnimation();
    this.satelliteBlueOp = 1;
    this.satelliteGreenOp = 0;
    this.arrowOp = 1;
    animateTo({
      duration: 150, curve: Curve.Sharp, iterations: 1}, () => {
      this.satelliteBlueOp = 0;
    })
    animateTo({
      delay: 50,
      duration: 200,
      curve: Curve.Sharp,
      iterations: 1,
      onFinish: () => {
      }
    }, () => {
      this.satelliteGreenOp = 1;
    })
    animateTo({
      duration: 400, curve: Curve.Friction, iterations: 1, onFinish: () => {
      }
    }, () => {
      this.arrowScale = 0.9;
    })
    animateTo({
      duration: 200, curve: Curve.Sharp, iterations: 1, onFinish: () => {
      }
    }, () => {
      this.arrowOp = 0;
    })
    this.startLightUpAnimation();
  }

  getSatelliteOutAnimation() {
    this.mSatelliteOutAnimate = true;
    this.startArrowRightAnimation();
    animateTo({
      duration: 150, curve: Curve.Sharp, iterations: 1, onFinish: () => {
      }
    }, () => {
      this.arrowOp = 1;
      this.satelliteGreenOp = 0;
    })
    animateTo({
      delay: 50,
      duration: 200,
      curve: Curve.Sharp,
      iterations: 1,
      onFinish: () => {
      }
    }, () => {
      this.satelliteBlueOp = 1;
    })
  }

  startConnectingAnimation() {
    this.resetConnect();
    this.isStopConnectingAnimation = false;
    this.isStartConnectingAnimation = true;
    this.startAnimationKeyFrame();
    this.startAnimationKeyFrame2();
    this.startAnimationKeyFrame3();
  }

  stopConnectingAnimation() {
    this.isStopConnectingAnimation = true;
    this.isStartConnectingAnimation = false;
    this.connecting_op3 = 0.2;
    this.connecting_op2 = 0.2;
    this.connecting_op1 = 0.2;
    this.connecting_wd_he_3 = 67;
    this.connecting_wd_he_2 = 67;
    this.connecting_wd_he_1 = 67;
    animateTo({ duration: 0 }, () => {
      this.resetConnect();
    })
  }

  startAnimationKeyFrame() {
    animateTo({
      duration: 1700, curve: Curve.Sharp, iterations: 1}, () => {
      this.connecting_wd_he_1 = 660;
    })
    this.uiContext.keyframeAnimateTo({ iterations: 1 }, [
      {
        duration: 400,
        curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1),
        event: () => {
          this.connecting_op1 = 1;
        }
      },
      {
        duration: 1300,
        curve: curves.cubicBezierCurve(0.2, 0, 0.4, 1),
        event: () => {
          this.connecting_op1 = 0;
        }
      }
    ])
  }

  startAnimationKeyFrame2() {
    animateTo({
      delay: 400,
      duration: 1700,
      curve: Curve.Sharp,
      iterations: 1,
      onFinish: () => {
      }
    }, () => {
      this.connecting_wd_he_2 = 660;
    })
    this.uiContext.keyframeAnimateTo({ delay: 400, iterations: 1 }, [
      {
        duration: 400,
        curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1),
        event: () => {
          this.connecting_op2 = 1;
        }
      },
      {
        duration: 1300,
        curve: curves.cubicBezierCurve(0.2, 0, 0.4, 1),
        event: () => {
          this.connecting_op2 = 0;
        }
      }
    ])
  }

  resetConnect() {
    this.connecting_op3 = 0;
    this.connecting_op2 = 0;
    this.connecting_op1 = 0;
    this.connecting_wd_he_3 = 64;
    this.connecting_wd_he_2 = 64;
    this.connecting_wd_he_1 = 64;
  }

  startAnimationKeyFrame3() {
    animateTo({
      delay: 800,
      duration: 1700,
      curve: Curve.Sharp,
      iterations: 1,
      onFinish: () => {
        if (this.isStopConnectingAnimation) {
          return;
        }
        this.startConnectingAnimation();
      }
    }, () => {
      this.connecting_wd_he_3 = 660;
    })
    this.uiContext.keyframeAnimateTo({ delay: 800, iterations: 1 }, [
      {
        duration: 400,
        curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1),
        event: () => {
          this.connecting_op3 = 1;
        }
      },
      {
        duration: 1300,
        curve: curves.cubicBezierCurve(0.2, 0, 0.4, 1),
        event: () => {
          this.connecting_op3 = 0;
        }
      }
    ])
  }

  resetConnectedAni() {
    this.connectedScale = 0.21;
    this.connectedOp = 0;
  }

  startConnectedSuccessAnimation() {
    this.resetConnectedAni();
    animateTo({
      duration: 1000,
      curve: curves.cubicBezierCurve(0.2, 0, 0.4, 1),
      iterations: 1
    }, () => {
      this.connectedScale = 1.1;
    })

    this.uiContext.keyframeAnimateTo({ iterations: 1 }, [
      {
        duration: 300,
        curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1),
        event: () => {
          this.connectedOp = 0.8;
        }
      },
      {
        duration: 700,
        curve: curves.cubicBezierCurve(0.2, 0, 0.2, 1),
        event: () => {
          this.connectedOp = 0;
        }
      }
    ])
  }

  getFailedAnimation() {
    this.getSatelliteOutAnimation();
    this.satelliteOp = 1;
    this.failedSatelliteOp = 0;
    this.getLightDownAnimation();
    animateTo({ duration: 150, curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1) }, () => {
      this.satelliteOp = 0;
    })
    animateTo({
      duration: 200, curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1), onFinish: () => {
        if (this.currentStatus != SYS_STATUS_SEARCH_SATELLITE_FAIL) {
          this.satelliteOp = 0;
          this.failedSatelliteOp = 1;
        }
      }
    }, () => {
      this.failedSatelliteOp = 1;
    })
  }

  getLightDownAnimation() {
    this.lightY = -150;
    this.showLightGreen = true;
    animateTo({
      duration: 500, curve: Curves.cubicBezierCurve(0, 0, 0.6, 1), onFinish: () => {
        this.showLightGreen = false;
      }
    }, () => {
      this.lightY = 21;
    })
  }

  startLightUpAnimation() {
    this.lightY = 21;
    this.showLightGreen = true;
    animateTo({
      duration: 700, curve: Curves.cubicBezierCurve(0.2, 0, 0.4, 1), onFinish: () => {
        this.showLightGreen = false;
      }
    }, () => {
      this.lightY = -150;
    })
  }

  //旋转方位角
  changeByAzimuth() {
    //方位角未对其，根据角度来判断如何显示知识箭头
    let safeAzimuthDelta: number = SatelliteUtils.getSuccessAzimuth();
    if (!SatelliteUtils.checkAzimuthOk(this.mAzimuthDelta)) {
      if (this.mAzimuthDelta > safeAzimuthDelta && this.mDirectionAzimuth != SatelliteDirection.RIGHT) {
        this.mDirectionAzimuth = SatelliteDirection.RIGHT;
        this.azimuthImage = $r('app.media.turn_right');
      } else if (this.mAzimuthDelta < -safeAzimuthDelta && this.mDirectionAzimuth != SatelliteDirection.LEFT) {
        this.mDirectionAzimuth = SatelliteDirection.LEFT;
        this.azimuthImage = $r('app.media.turn_left');
      }
    }
    if (this.satelliteGreenOp == 0 && SatelliteUtils.checkAzimuthOk(this.mAzimuthDelta)) {
      this.mDirectionAzimuth = SatelliteDirection.NONE;
      // 方位角对齐，但是当前扇形不是绿色，变为绿色扇形
      this.getSatelliteInAnimation();
    } else if (this.satelliteBlueOp == 0 && !SatelliteUtils.checkAzimuthOk(this.mAzimuthDelta)) {
      // 方位角未对齐，但是当前扇形不是蓝色，变为蓝色扇形
      this.getSatelliteOutAnimation();
    }
  }

  // 旋转俯仰角
  changeByPitchDelta() {
    let translationY: number = this.getTranslationY();
    let maxDistance: number = SatelliteSearchManager.getInstance().getIsFromMeetime() ? MAX_DIRECTION : Y_MAX_DISTANCE;
    let minDistance: number = SatelliteSearchManager.getInstance().getIsFromMeetime() ? MIN_DIRECTION : Y_MIN_DISTANCE;
    if (translationY >= maxDistance) {
      translationY = maxDistance;
    } else if (translationY <= minDistance) {
      translationY = minDistance;
    }
    this.pitchTranslationY = translationY;
    if (SatelliteUtils.checkPitchOk(this.mPitchDelta)) {
      this.mDirectionPitch = SatelliteDirection.NONE;
      this.pitchImage =
        SatelliteSearchManager.getInstance().getIsFromMeetime() ? $r('app.media.meetime_dialog_center_green') :
        $r('app.media.dialog_center_green');
    } else {
      if (translationY > 0 && this.mDirectionPitch != SatelliteDirection.UP) {
        this.mDirectionPitch = SatelliteDirection.UP;
      } else if (translationY < 0 && this.mDirectionPitch != SatelliteDirection.DOWN) {
        this.mDirectionPitch = SatelliteDirection.DOWN;
      }
      this.pitchImage =
        SatelliteSearchManager.getInstance().getIsFromMeetime() ? $r('app.media.meetime_dialog_center_blue') :
        $r('app.media.dialog_center_blue');
    }
    this.drawBallGuideDottedLine(translationY);
  }

  getTranslationY(): number {
    if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      return this.mPitchDelta * PITCH_SCALE;
    } else {
      return SatelliteUtils.getPitchTranslationY(this.mPitchDelta);
    }
  }

  drawBallGuideDottedLine(translationY: number) {
    if (this.context) {
      this.context.clearRect(0, 0, 80, 240);
      if (this.mDirectionPitch === SatelliteDirection.NONE) {
        return;
      }
      let y: number = 0;
      let y1: number = 0;
      if (this.mDirectionPitch === SatelliteDirection.UP) {
        y = 120 + translationY - 25;
        y1 = 131;
      } else {
        y = (120 - Math.abs(translationY)) + 25;
        y1 = 109;
      }
      if (Math.abs(y1 - y) <= 11) {
        this.context.clearRect(0, 0, 80, 240);
        return;
      }
      this.context.beginPath();
      this.context.moveTo(40, y1);
      this.context.lineTo(40, y);
      this.context.setLineDash([0.6, 12]);
      this.context.stroke();
    }
  }

  // 卫星角度信息发生变化
  changeSatelliteData() {
    if (this.mSatelliteData == undefined) {
      return;
    }
    if (!SatelliteSearchManager.getInstance().isUpdateSatelliteData()) {
      return;
    }
    this.mAzimuthDelta = this.mSatelliteData.azimuthDelta;
    this.mPitchDelta = this.mSatelliteData.pitchAngleDelta;
    if (this.isEnterSatelliteConnecting()) {
      if (this.currentStatus == SYS_STATUS_SEARCHING_SATELLITE || (!this.showReConnect && this.currentStatus ==
        SYS_STATUS_SEARCH_SATELLITE_FAIL)) {
        this.satelliteOp = 1;
        this.failedSatelliteOp = 0;
        if (!SatelliteSearchManager.getInstance().getIsFromMeetime()) {
          this.currentStatus = SYS_STATUS_SATELLITE_CONNECTING
          SatelliteSearchManager.getInstance().setCurrentStatus(SYS_STATUS_SATELLITE_CONNECTING);
        } else {
          this.currentStatus = SYS_STATUS_SATELLITE_KEEPING;
          SatelliteSearchManager.getInstance().setCurrentStatus(SYS_STATUS_SATELLITE_KEEPING);
        }
      }
    } else {
      if (this.isNeedUpdateStatus()) {
        this.currentStatus = SYS_STATUS_SEARCHING_SATELLITE;
        this.satelliteOp = 1;
        this.failedSatelliteOp = 0;
        SatelliteSearchManager.getInstance().setCurrentStatus(SYS_STATUS_SEARCHING_SATELLITE);
      }
    }
    if (this.currentStatus != SYS_STATUS_SEARCH_SATELLITE_FAIL) {
      this.changeByAzimuth();
      this.changeByPitchDelta();
    }
  }

  private isEnterSatelliteConnecting(): boolean {
    if (!SatelliteUtils.checkAzimuthOk(this.mAzimuthDelta)) {
      return false;
    }
    if (!SatelliteUtils.checkPitchOk(this.mPitchDelta)) {
      return false;
    }
    if (this.mSatelliteData.sateIdx === -1) {
      return false;
    }
    return true;
  }

  isNeedUpdateStatus(): boolean {
    if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      if (this.currentStatus == SYS_STATUS_SATELLITE_KEEPING ||
        (!this.showReConnect && this.currentStatus == SYS_STATUS_SEARCH_SATELLITE_FAIL)) {
        return true;
      }
    } else {
      if (this.currentStatus == SYS_STATUS_SATELLITE_CONNECTING ||
        (!this.showReConnect && this.currentStatus == SYS_STATUS_SEARCH_SATELLITE_FAIL)) {
        return true;
      }
    }
    return false;
  }

  statusChange() {
    if (this.isStopAnimation()) {
      this.stopConnectingAnimation();
    } else if (this.isStartAnimation()) {
      this.startConnectingAnimation();
    }
    LogUtils.i(TAG, 'statusChange currentStatus = ' + this.currentStatus);
    if (this.isSuccessStatus()) {
      this.satelliteOp = 1;
      this.failedSatelliteOp = 0;
      this.startConnectedSuccessAnimation();
    } else if (this.currentStatus == SYS_STATUS_SEARCH_SATELLITE_FAIL) {
      if (this.isStartConnectingAnimation) {
        this.stopConnectingAnimation();
      }
      if (!this.mSatelliteOutAnimate) {
        this.getSatelliteOutAnimation();
      }
      this.pitchImage =
        SatelliteSearchManager.getInstance().getIsFromMeetime() ? $r('app.media.meetime_dialog_center_blue') :
        $r('app.media.dialog_center_blue');
      this.pitchTranslationY = 0;
      this.mDirectionPitch == SatelliteDirection.NONE;
      this.mDirectionAzimuth == SatelliteDirection.NONE;
      this.getFailedAnimation();
    }
  }

  isSuccessStatus(): boolean {
    if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      if (this.currentStatus === SEND_STATUS_SENT || this.currentStatus === SEND_STATUS_SUCC ||
        this.currentStatus === RECEIVER_STATUS_SUCCESS || this.currentStatus === RECEIVER_STATUS_NULL) {
        return true;
      }
    } else {
      if (this.currentStatus == SYS_STATUS_SEARCH_SATELLITE_SUCC) {
        return true;
      }
    }
    return false;
  }

  isStopAnimation(): boolean {
    if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      if ((this.currentStatus != SYS_STATUS_SATELLITE_CONNECTING &&
        this.currentStatus != SYS_STATUS_SEARCH_SATELLITE_SUCC && this.currentStatus != RECEIVER_STATUS_RECEIVING) &&
      this.isStartConnectingAnimation) {
        return true;
      }
    } else {
      if (this.currentStatus != SYS_STATUS_SATELLITE_CONNECTING && this.isStartConnectingAnimation) {
        return true;
      }
    }
    return false;
  }

  build() {
    Stack() {
      // 左右旋转箭头 360
      if (!SatelliteSearchManager.getInstance().getIsFromMeetime() &&
        this.currentStatus != SYS_STATUS_SEARCH_SATELLITE_FAIL) {
        Image(this.azimuthImage)
          .width('100%')
          .rotate({ angle: this.arrowRightRotate })
          .scale({ x: this.arrowScale })
          .opacity(this.arrowOp)
          .draggable(false)
      }
      // 中心黑圆
      Image(this.pitchImage)
        .width(60 * this.scaleSize)
        .height(60 * this.scaleSize)
        .draggable(false)
      // 卫星角度
      Canvas(this.contextBlue)
        .width(260 * this.scaleSize)
        .height(260 * this.scaleSize)
        .onReady(() => {
          this.contextBlue.beginPath();
          let radius =
            SatelliteSearchManager.getInstance().getIsFromMeetime() ? (directionLargeRadius + 1) : directionLargeRadius;
          radius = radius * this.scaleSize;
          this.contextBlue.arc(centerAngle * this.scaleSize, centerAngle * this.scaleSize, radius,
            Math.PI * (270 - this.directionAngle / 2) / 180, Math.PI * (270 + this.directionAngle / 2) / 180, false);
          this.contextBlue.lineWidth = 1.73;
          this.contextBlue.strokeStyle = 'rgba(66, 129, 255, 0.6)';
          this.contextBlue.stroke();
          this.contextBlue.arc(centerAngle * this.scaleSize, centerAngle * this.scaleSize,
            (directionSmallRadius - 1 ) * this.scaleSize, Math.PI * (270 + this.directionAngle / 2) / 180,
            Math.PI * (270 - this.directionAngle / 2) / 180, true);
          this.contextBlue.closePath();
          let x = this.radiusCircle - (directionLargeRadius - 1) * Math.cos(this.angle) * this.scaleSize;
          let gradient = this.contextBlue.createLinearGradient(x, centerAngle - directionLargeRadius + 2,
            x, centerAngle - directionSmallRadius + 10);
          gradient.addColorStop(0, 'rgba(66, 129, 255, 0.4)');
          gradient.addColorStop(1, 'rgba(66, 129, 255, 0)')
          this.contextBlue.fillStyle = gradient;
          this.contextBlue.fill();
          this.contextBlue.clip();
        })
        .opacity(this.satelliteBlueOp)
      Canvas(this.contextGreen)
        .width(260 * this.scaleSize)
        .height(260 * this.scaleSize)
        .onReady(() => {
          this.contextGreen.beginPath();
          let radius =
            SatelliteSearchManager.getInstance().getIsFromMeetime() ? (directionLargeRadius + 1) : directionLargeRadius;
          radius = this.scaleSize * radius;
          this.contextGreen.arc(centerAngle * this.scaleSize, centerAngle * this.scaleSize, radius,
            Math.PI * (270 - this.directionAngle / 2) / 180, Math.PI * (270 + this.directionAngle / 2) / 180, false);
          this.contextGreen.lineWidth = 1.73;
          this.contextGreen.strokeStyle =
            SatelliteSearchManager.getInstance().getIsFromMeetime() ? 'rgba(115, 214, 105, 0.5)' :
              'rgba(136, 238, 125, 0.6)';
          this.contextGreen.stroke();
          this.contextGreen.arc(centerAngle * this.scaleSize,
            centerAngle * this.scaleSize, (directionSmallRadius - 1) * this.scaleSize,
            Math.PI * (270 + this.directionAngle / 2) / 180, Math.PI * (270 - this.directionAngle / 2) / 180, true);
          this.contextGreen.closePath();
          let x = this.radiusCircle - (directionLargeRadius - 1) * Math.cos(this.angle);
          let gradient = this.contextGreen.createLinearGradient(x, centerAngle - directionLargeRadius + 2,
            x, centerAngle - directionSmallRadius + 10);
          gradient.addColorStop(0,
            SatelliteSearchManager.getInstance().getIsFromMeetime() ? 'rgba(115, 214, 105, 0.5)' :
              'rgba(136, 238, 125, 0.4)');
          gradient.addColorStop(1,
            SatelliteSearchManager.getInstance().getIsFromMeetime() ? 'rgba(100, 187, 92, 0)' :
              'rgba(136, 238, 125, 0)')
          this.contextGreen.fillStyle = gradient;
          this.contextGreen.fill();
          this.contextGreen.clip();
        })
        .opacity(this.satelliteGreenOp)
      
      Shape() {
        Image($r('app.media.light_sweep'))
          .width(260 * this.scaleSize)
          .height(260 * this.scaleSize)
          .translate({ y: (isTablet() || TrifoldManager.getInstance().isTrifold()) ? 0 : this.lightY * this.scaleSize })
          .visibility(this.showLightGreen ? Visibility.Visible : Visibility.Hidden)
          .draggable(false)
      }
      .width(360 * this.scaleSize)
      .height(360 * this.scaleSize)
      .align(Alignment.Center)
      .clip(new Path({
        commands: `M${this.startLarX} ${this.startLarY} A${this.radiusLar}
       ${this.radiusLar} ${this.directionAngle} 0 1 ${this.targetLarX} ${this.targetLarY} L${this.startSmallX}
       ${this.startSmallY} A${this.radiusToPxSmall} ${this.radiusToPxSmall} ${this.directionAngle} 0 0
       ${this.targetSmallX} ${this.targetSmallY}Z`
      }))

      this.showAnimationImageLayout();

      // 引导小球虚线画布
      Canvas(this.context)
        .width(80)
        .height(240 * this.scaleSize)
        .onReady(() => {
          this.context.strokeStyle = 'rgba(66, 129, 255, 0.6)';
          this.context.lineWidth = 3;
          this.context.lineCap = 'round';
        })
    }
    .onAppear(() => {
      LogUtils.i(TAG, 'getSatelliteVisAnimation:' + JSON.stringify(this.currentStatus));
      if (!SatelliteSearchManager.getInstance().getProgressAnimationIsFirst()) {
        this.getSatelliteVisAnimation();
      }
      if (SatelliteSearchManager.getInstance().getCurrentStatus() != SYS_STATUS_SEARCH_SATELLITE_FAIL) {
        this.changeSatelliteData();
      }
    })
    .width('100%')
    .height('100%')
  }

  @Builder
  showAnimationImageLayout() {
    // 中心小球
    Image($r('app.media.satellite_search_ball'))
      .key('SatelliteSearch_Animation_Search_Ball_Image')
      .width(30 * this.scaleSize)
      .height(30 * this.scaleSize)
      .translate({ y: this.pitchTranslationY})
      .opacity(this.satelliteBallOp)
      .draggable(false)

    if (this.mDirectionPitch == SatelliteDirection.UP && this.currentStatus != SYS_STATUS_SEARCH_SATELLITE_FAIL) {
      Image(SatelliteSearchManager.getInstance().getIsFromMeetime() ? $r('app.media.meetime_direction_up') :
      $r('app.media.direction_up'))
        .key('SatelliteSearch_Animation_Direction_Up_Image')
        .width(15 * this.scaleSize)
        .height(10 * this.scaleSize)
        .translate({ y: this.pitchTranslationY - 20 })
        .draggable(false)
    } else if (this.mDirectionPitch == SatelliteDirection.DOWN && this.currentStatus !=
      SYS_STATUS_SEARCH_SATELLITE_FAIL) {
      Image(SatelliteSearchManager.getInstance().getIsFromMeetime() ? $r('app.media.meetime_direction_down') :
      $r('app.media.direction_down'))
        .key('SatelliteSearch_Animation_Direction_Down_Image')
        .width(15 * this.scaleSize)
        .height(10 * this.scaleSize)
        .translate({ y: this.pitchTranslationY + 20 })
        .draggable(false)
    }

    Image($r('app.media.sweep_ring'))
      .key('SatelliteSearch_Animation_Sweep_Ring_Image')
      .width(360 * this.scaleSize)
      .height(360 * this.scaleSize)
      .align(Alignment.Center)
      .opacity(this.ringOp)
      .scale({ x: this.ringScale, y: this.ringScale })
      .draggable(false)

    Image($r(SatelliteSearchManager.getInstance().getIsFromMeetime() ? 'app.media.meetime_blue_mask' :
      'app.media.blue_mask'))
      .key('SatelliteSearch_Animation_Blue_Mask_Image')
      .width(432 * this.scaleSize)
      .height(432 * this.scaleSize)
      .align(Alignment.Center)
      .scale({ x: this.maskScale, y: this.maskScale })
      .opacity(this.maskOp)
      .draggable(false)

    this.showConnectLayout();
  }

  @Builder
  showConnectLayout() {
    Image(SatelliteSearchManager.getInstance().getIsFromMeetime() ? $r('app.media.meetime_connecting_ring') :
    $r('app.media.connecting_ring'))
      .key('SatelliteSearch_Animation_Connecting_Ring1_Image')
      .width(this.connecting_wd_he_1)
      .height(this.connecting_wd_he_1)
      .align(Alignment.Center)
      .opacity(this.connecting_op1)
      .draggable(false)

    Image(SatelliteSearchManager.getInstance().getIsFromMeetime() ? $r('app.media.meetime_connecting_ring') :
    $r('app.media.connecting_ring'))
      .key('SatelliteSearch_Animation_Connecting_Ring2_Image')
      .width(this.connecting_wd_he_2)
      .height(this.connecting_wd_he_2)
      .align(Alignment.Center)
      .opacity(this.connecting_op2)
      .draggable(false)

    Image(SatelliteSearchManager.getInstance().getIsFromMeetime() ? $r('app.media.meetime_connecting_ring') :
    $r('app.media.connecting_ring'))
      .key('SatelliteSearch_Animation_Connecting_Ring3_Image')
      .width(this.connecting_wd_he_3)
      .height(this.connecting_wd_he_3)
      .align(Alignment.Center)
      .opacity(this.connecting_op3)
      .draggable(false)

    Image($r(SatelliteSearchManager.getInstance().getIsFromMeetime() ? 'app.media.meetime_connected_succ' :
      'app.media.connected_succ'))
      .key('SatelliteSearch_Animation_Connected_Success_Image')
      .width(330 * this.scaleSize)
      .height(330 * this.scaleSize)
      .align(Alignment.Center)
      .scale({ x: this.connectedScale, y: this.connectedScale })
      .opacity(this.connectedOp)
      .draggable(false)

    // 卫星
    Image(SatelliteSearchManager.getInstance().getIsFromMeetime() ? $r('app.media.meetime_sate') :
    $r('app.media.sate'))
      .key('SatelliteSearch_Animation_Satellite_Image')
      .width(260 * this.scaleSize)
      .height(260 * this.scaleSize)
      .rotate({ angle: SatelliteUtils.getSateRotationAngles(this.mAzimuthDelta, this.directionAngle) })
      .opacity(this.satelliteOp)
      .draggable(false)

    Image($r('app.media.sate_dialog_dotted'))
      .key('SatelliteSearch_Animation_Dotted_Image')
      .width(260 * this.scaleSize)
      .height(260 * this.scaleSize)
      .opacity(this.failedSatelliteOp)
      .draggable(false)
  }
}

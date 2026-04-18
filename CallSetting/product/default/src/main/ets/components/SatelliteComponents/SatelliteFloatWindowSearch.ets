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

import Curves from '@ohos.curves'
import SatelliteSearchManager, { SatelliteData } from '../../manager/SatelliteSearchManager';
import SatelliteUtils, { Y_MAX_DISTANCE, Y_MIN_DISTANCE } from '../../common/utils/SatelliteUtils';
import { SatelliteDirection, SYS_STATUS_SATELLITE_CONNECTING,
  SYS_STATUS_SEARCHING_SATELLITE,
  SYS_STATUS_SEARCH_SATELLITE_FAIL,
  SYS_STATUS_SEARCH_SATELLITE_SUCC } from '../../common/constant/SatelliteSearchConst';
import { LogUtils } from '@ohos/common/CommonIndex';
import { curves } from '@kit.ArkUI';

const TAG = 'SatelliteFloatWindowSearch';

@Entry
@Component
export struct SatelliteFloatWindowSearch {
  @Link @Watch('statusChange') currentStatus: number;
  @Link @Watch('changeSatelliteData') mSatelliteData: SatelliteData;
  @Link @Watch('changeSatelliteData') showReConnect: boolean;
  @State isSatelliteOp: number = 0;
  @State isSatelliteDottedOp: number = 0;
  @State satelliteWarnDottedLeftOp: number = 0;
  @State satelliteWarnDottedRightOp: number = 0;
  @State dottedAngle: number = 0;
  @State isStartAlertDottedRightAnimation: boolean = false;
  @State isStartAlertDottedLeftAnimation: boolean = false;
  @State warnMaskRightOp: number = 0;
  @State warnMaskLeftOp: number = 0;
  @State warnLeftVisibility: boolean = true;
  @State warnRightVisibility: boolean = true;
  @State warnMaskTranX: number = 0;
  @State warnMaskTranY: number = 0;
  @State upBase: boolean = false;
  @State arrowRightRotate: number = 0;
  @State arrowOp: number = 0;
  @State arrowScale: number = 0.9;
  @State satelliteBlueOp: number = 0;
  @State satelliteGreenOp: number = 0;
  @State backgroundTranslate: number = 0;
  @State lightY: number = 13;
  @State showLightSweep: boolean = false;
  uiContext: UIContext = this.getUIContext();
  scroller: Scroller = new Scroller();
  @State azimuthImage: Resource = $r('app.media.float_turn_left');
  @State pitchImage: Resource = $r('app.media.float_center_blue');
  @State pitchTranslationY: number = 0;
  @State mAzimuthDelta: number = 0;
  @State mPitchDelta: number = 0;
  @State radius: number = 75; //81;
  @State angle: number = Math.PI / 4;
  @State radiusSmall: number = 19;
  @State radiusLar: number = 0;
  @State radiusToPxSmall: number = 0;
  @State startLarX: number = 0;
  @State startLarY: number = 0;
  @State targetLarX: number = 0;
  @State targetLarY: number = 0;
  @State radiusX: number = 81;
  @State radiusCircle: number = 81;
  @State startSmallX: number = 0;
  @State startSmallY: number = 0;
  @State targetSmallX: number = 0;
  @State targetSmallY: number = 0;
  private mDirectionAzimuth = SatelliteDirection.NONE;
  @State mDirectionPitch: number = SatelliteDirection.NONE;
  @State connecting_wd_he_1: number = 95;
  @State connecting_wd_he_2: number = 95;
  @State connecting_wd_he_3: number = 95;
  @State connecting_op1: number = 0;
  @State connecting_op2: number = 0;
  @State connecting_op3: number = 0;
  @State isStopConnectingAnimation: boolean = false;
  @State isStartConnectingAnimation: boolean = false;
  @State connectedScale: number = 0.21;
  @State connectedOp: number = 0;
  @State isNeedBaseUp: boolean = true;
  @State directionLargeRadius: number = 74;
  // 小圆半径
  @State directionSmallRadius: number = 19;
  @State markAlertTranX: number = 42;
  @State markAlertTranY: number = 32;

  @State centerAngle: number = 81;
  @State reconnectOP: number = 0;
  private settingsGreen: RenderingContextSettings = new RenderingContextSettings(true);
  private contextGreen: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settingsGreen);
  private settingsBlue: RenderingContextSettings = new RenderingContextSettings(true);
  private contextBlue: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settingsBlue);
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  // 是否正在播放out动画
  private mSatelliteOutAnimate = false;
  private alertCubic = Curves.cubicBezierCurve(0.33, 0, 0.67, 1);

  // 扇形角度
  private directionAngle: number = 60;

  aboutToAppear(): void {
    this.currentStatus = SatelliteSearchManager.getInstance().getCurrentStatus();
    LogUtils.i(TAG, 'aboutToAppear is called, current status = ' + this.currentStatus);
    this.mSatelliteData = SatelliteSearchManager.getInstance().getCacheSatelliteData();
    this.directionAngle = SatelliteUtils.getDefaultAngles();
    this.getSweepCalculation();
    this.initData();
    if (this.currentStatus == SYS_STATUS_SATELLITE_CONNECTING && !this.isStartConnectingAnimation) {
      this.startConnectingAnimation();
    }
  }

  initData() {
    this.isSatelliteOp = 1;
    if (!SatelliteUtils.checkAzimuthOk(this.mAzimuthDelta)) {
      this.arrowOp = 1;
      this.satelliteBlueOp = 1;
    } else {
      this.satelliteGreenOp = 1;
    }
    if (this.currentStatus === SYS_STATUS_SEARCH_SATELLITE_FAIL) {
      this.isSatelliteDottedOp = 1;
      this.isSatelliteOp = 0;
      this.satelliteGreenOp = 0;
      this.satelliteBlueOp = 1;
    }
  }

  resetArrow() {
    this.arrowScale = 0.9;
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

  startLightUpAnimation() {
    this.lightY = 13;
    this.showLightSweep = true;
    animateTo({
      duration: 700, curve: Curves.cubicBezierCurve(0.2, 0, 0.4, 1), onFinish: () => {
        this.showLightSweep = false;
      }
    }, () => {
      this.lightY = -100;
    })
  }

  setAngle(angle: number) {
    this.angle = Math.PI * angle / 180;
  }

  getSweepCalculation() {
    this.radiusLar = vp2px(this.radius);
    this.radiusToPxSmall = vp2px(this.radiusSmall);
    this.angle = 1 / 2 * Math.PI - this.directionAngle * Math.PI / 360;
    this.startLarX = vp2px(this.radiusCircle - this.radius * Math.cos(this.angle));
    this.startLarY = vp2px(this.radiusCircle - this.radius * Math.sin(this.angle));
    this.targetLarX = vp2px(this.radiusCircle + this.radius * Math.cos(this.angle));
    this.targetLarY = vp2px(this.radiusCircle - this.radius * Math.sin(this.angle));
    this.startSmallX = vp2px(this.radiusCircle + this.radiusSmall * Math.cos(this.angle));
    this.startSmallY = vp2px(this.radiusCircle - this.radiusSmall * Math.sin(this.angle));
    this.targetSmallX = vp2px(this.radiusCircle - this.radiusSmall * Math.cos(this.angle))
    this.targetSmallY = vp2px(this.radiusCircle - this.radiusSmall * Math.sin(this.angle))
    this.radiusX = vp2px(this.radiusCircle)
  }

  getSatelliteInAnimation() {
    this.mSatelliteOutAnimate = false;
    this.stopArrowRightAnimation();
    this.satelliteBlueOp = 1;
    this.satelliteGreenOp = 0;
    this.arrowOp = 1;
    animateTo({
      duration: 150, curve: Curve.Sharp, iterations: 1, onFinish: () => {

      }
    }, () => {
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
      duration: 150, curve: Curve.Sharp, iterations: 1, onFinish: () => {
      }
    }, () => {
      this.arrowOp = 0;
    })
    this.startLightUpAnimation();
  }

  startAlertDottedLeftAnimation() {
    this.satelliteWarnDottedLeftOp = 0.5;
    this.warnMaskLeftOp = 0.5;
    let isFirst = true;
    this.uiContext.keyframeAnimateTo({
      delay: isFirst ? 0 : 200, iterations: -1, onFinish: () => {
        isFirst = false;
      }
    }, [
      {
        duration: 700,
        curve: this.alertCubic,
        event: () => {
          this.warnMaskLeftOp = 1;
          this.satelliteWarnDottedLeftOp = 1;
        }
      },
      {
        duration: 700,
        curve: this.alertCubic,
        event: () => {
          this.warnMaskLeftOp = 0.5;
          this.satelliteWarnDottedLeftOp = 0.5;
        }
      }
    ])
  }

  stopAlertMaskLeftAnimation() {
    this.satelliteWarnDottedLeftOp = 0.02;
    this.warnMaskLeftOp = 0.02;
    this.isStartAlertDottedLeftAnimation = false;
    animateTo({
      duration: 0, iterations: 1, onFinish: () => {
      }
    }, () => {
      this.satelliteWarnDottedLeftOp = 0;
      this.warnMaskLeftOp = 0;
    })
  }

  startAlertDottedRightAnimation() {
    this.satelliteWarnDottedRightOp = 0.5;
    this.warnMaskRightOp = 0.5;
    let isFirst = true;
    this.uiContext.keyframeAnimateTo({
      delay: isFirst ? 0 : 200, iterations: -1, onFinish: () => {
        isFirst = false;
      }
    }, [
      {
        duration: 700,
        curve: this.alertCubic,
        event: () => {
          this.warnMaskRightOp = 1;
          this.satelliteWarnDottedRightOp = 1;
        }
      },
      {
        duration: 700,
        curve: this.alertCubic,
        event: () => {
          this.warnMaskRightOp = 0.5;
          this.satelliteWarnDottedRightOp = 0.5;
        }
      }
    ])
  }

  stopAlertMaskRightAnimation() {
    this.satelliteWarnDottedRightOp = 0.2;
    this.warnMaskRightOp = 0.2;
    this.isStartAlertDottedRightAnimation = false;
    animateTo({
      duration: 0, iterations: 1, onFinish: () => {
      }
    }, () => {
      this.satelliteWarnDottedRightOp = 0;
      this.warnMaskRightOp = 0;
    })
  }

  getBaseUpAnimation() {
    this.warnLeftVisibility = false;
    this.warnRightVisibility = false;
    this.backgroundTranslate = -68;
    this.upBase = true;
  }

  getBaseDownAnimation() {
    this.isNeedBaseUp = true;
    this.warnLeftVisibility = true;
    this.warnRightVisibility = true;
    this.backgroundTranslate = 0;
    this.upBase = false;
  }

  resetConnectedAni() {
    this.connectedScale = 0.3;
    this.connectedOp = 0;
  }

  startConnectedSuccessAnimation() {
    this.resetConnectedAni();
    animateTo({
      duration: 1000,
      curve: curves.cubicBezierCurve(0.2, 0, 0.4, 1),
      iterations: 1,
      onFinish: () => {
        this.resetConnectedAni();
      }
    }, () => {
      this.connectedScale = 1.3;
    })

    this.uiContext.keyframeAnimateTo({ iterations: 1 }, [
      {
        duration: 300,
        curve: Curve.Sharp,
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

  resetConnect() {
    this.connecting_op3 = 0;
    this.connecting_op2 = 0;
    this.connecting_op1 = 0;
    this.connecting_wd_he_3 = 38;
    this.connecting_wd_he_2 = 38;
    this.connecting_wd_he_1 = 38;
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
      duration: 1700, curve: Curve.Sharp, iterations: 1, onFinish: () => {
      }
    }, () => {
      this.connecting_wd_he_1 = 405;
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
      this.connecting_wd_he_2 = 405;
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
      this.connecting_wd_he_3 = 405;
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

  getLightDownAnimation() {
    this.lightY = -100;
    this.showLightSweep = true;
    animateTo({
      duration: 700, curve: Curves.cubicBezierCurve(0.2, 0, 0.4, 1), onFinish: () => {
        this.showLightSweep = false;
      }
    }, () => {
      this.lightY = 13;
    })
  }

  //旋转方位角
  changeByAzimuth() {
    //方位角未对其，根据角度来判断如何显示知识箭头
    let safeAzimuthDelta: number = SatelliteUtils.getSuccessAzimuth();
    if (!SatelliteUtils.checkAzimuthOk(this.mAzimuthDelta)) {
      if (this.mAzimuthDelta > safeAzimuthDelta && this.mDirectionAzimuth != SatelliteDirection.RIGHT) {
        this.mDirectionAzimuth = SatelliteDirection.RIGHT;
        this.azimuthImage = $r('app.media.float_turn_right');
      } else if (this.mAzimuthDelta < -safeAzimuthDelta && this.mDirectionAzimuth != SatelliteDirection.LEFT) {
        this.mDirectionAzimuth = SatelliteDirection.LEFT;
        this.azimuthImage = $r('app.media.float_turn_left');
      }

      if (this.mAzimuthDelta > 130) {
        if (!this.isStartAlertDottedRightAnimation && !this.upBase) {
          LogUtils.i(TAG, 'isStartAlertDottedAnimation if > 130: getAlertDottedAnimation:' +
            JSON.stringify(this.isStartAlertDottedRightAnimation))
          this.isStartAlertDottedRightAnimation = true;
          //右
          this.warnLeftVisibility = false;
          this.warnRightVisibility = true;
          this.startAlertDottedRightAnimation();
          this.stopAlertMaskLeftAnimation();
        }
      } else if (this.mAzimuthDelta < -130 && !this.upBase) {
        if (!this.isStartAlertDottedLeftAnimation) {
          this.isStartAlertDottedLeftAnimation = true;
          LogUtils.i(TAG, 'isStartAlertDottedAnimation if < -130: getAlertDottedAnimation');
          this.warnLeftVisibility = true;
          this.warnRightVisibility = false;
          this.startAlertDottedLeftAnimation();
          this.stopAlertMaskRightAnimation();
        }
      } else {
        LogUtils.i(TAG, 'isStartAlertDottedAnimation else < 130: stopAlertMaskAnimation : ' +
          JSON.stringify(this.isStartAlertDottedRightAnimation));
        this.stopAlertMaskLeftAnimation();
        this.stopAlertMaskRightAnimation();
      }
    }
    if (this.satelliteGreenOp == 0 && SatelliteUtils.checkAzimuthOk(this.mAzimuthDelta)) {
      this.mDirectionAzimuth = SatelliteDirection.NONE;
      //方位角对齐，但是当前扇形不是绿色，变为绿色扇形
      this.getSatelliteInAnimation();
    } else if (this.satelliteBlueOp == 0 && !SatelliteUtils.checkAzimuthOk(this.mAzimuthDelta)) {
      //方位角未对齐，但是当前扇形不是蓝色，变为蓝色扇形
      this.getSatelliteOutAnimation();
    }
  }

  //旋转俯仰角
  changeByPitchDelta() {
    let translationY: number = SatelliteUtils.getFloatPitchTranslationY(this.mPitchDelta);
    if (translationY >= Y_MAX_DISTANCE) {
      translationY = Y_MAX_DISTANCE;
    } else if (translationY <= Y_MIN_DISTANCE) {
      translationY = Y_MIN_DISTANCE;
    }
    this.pitchTranslationY = translationY;
    if (SatelliteUtils.checkPitchOk(this.mPitchDelta)) {
      this.mDirectionPitch = SatelliteDirection.NONE;
      this.pitchImage = $r('app.media.float_center_green');
      if (!this.isNeedBaseUp) {
        this.getBaseDownAnimation();
        this.isNeedBaseUp = true;
      }
    } else {
      if (translationY > 0) {
        if (this.mDirectionPitch != SatelliteDirection.UP) {
          this.mDirectionPitch = SatelliteDirection.UP;
        }
        //需要上移
        if (this.isNeedBaseUp && SatelliteUtils.checkAzimuthOk(this.mAzimuthDelta)) {
          this.getBaseUpAnimation();
          this.isNeedBaseUp = false;
        }
        //小球在上面
      } else if (translationY < 0) {
        if (this.mDirectionPitch != SatelliteDirection.DOWN) {
          this.mDirectionPitch = SatelliteDirection.DOWN;
        }
        if (!this.isNeedBaseUp) {
          this.getBaseDownAnimation();
          this.isNeedBaseUp = true;
        }
      }
      this.pitchImage = $r('app.media.float_center_blue');
    }
    this.drawBallGuideDottedLine(translationY);
  }

  drawBallGuideDottedLine(translationY: number) {
    if (this.context) {
      this.context.clearRect(0, 0, 40, 162);
      if (this.mDirectionPitch === SatelliteDirection.NONE) {
        return;
      }
      let y: number = 0;
      let y1: number = 0;
      if (this.mDirectionPitch === SatelliteDirection.UP) {
        y = 81 + translationY - 23;
        y1 = 91;
      } else {
        y = (81 - Math.abs(translationY)) + 23;
        y1 = 71;
      }
      if (Math.abs(y1 - y) <= 8) {
        this.context.clearRect(0, 0, 40, 162);
        return;
      }
      this.context.beginPath();
      this.context.moveTo(20, y1);
      this.context.lineTo(20, y);
      this.context.setLineDash([0.7, 12.6]);
      this.context.stroke();
    }
  }

  //卫星角度信息发生变化
  changeSatelliteData() {
    if (this.mSatelliteData == undefined) {
      return;
    }
    this.mAzimuthDelta = this.mSatelliteData.azimuthDelta;
    this.mPitchDelta = this.mSatelliteData.pitchAngleDelta;
    if (SatelliteUtils.checkAzimuthOk(this.mAzimuthDelta) && SatelliteUtils.checkPitchOk(this.mPitchDelta)) {
      if (this.currentStatus == SYS_STATUS_SEARCHING_SATELLITE || (!this.showReConnect && this.currentStatus ==
        SYS_STATUS_SEARCH_SATELLITE_FAIL)) {
        this.currentStatus = SYS_STATUS_SATELLITE_CONNECTING
        SatelliteSearchManager.getInstance().setCurrentStatus(SYS_STATUS_SATELLITE_CONNECTING)
        if (!this.isStartConnectingAnimation) {
          this.startConnectingAnimation();
        }
      }
    } else {
      if (this.currentStatus == SYS_STATUS_SATELLITE_CONNECTING || (!this.showReConnect && this.currentStatus ==
        SYS_STATUS_SEARCH_SATELLITE_FAIL)) {
        this.currentStatus = SYS_STATUS_SEARCHING_SATELLITE;
        SatelliteSearchManager.getInstance().setCurrentStatus(SYS_STATUS_SEARCHING_SATELLITE);
      }
    }
    if (this.currentStatus != SYS_STATUS_SEARCH_SATELLITE_FAIL) {
      this.changeByAzimuth();
      this.changeByPitchDelta();
    }
  }

  statusChange() {
    LogUtils.i(TAG, 'statusChange is called status = ' + this.currentStatus);
    if (this.currentStatus != SYS_STATUS_SATELLITE_CONNECTING && this.isStartConnectingAnimation) {
      this.stopConnectingAnimation();
    } else if (this.currentStatus == SYS_STATUS_SATELLITE_CONNECTING && !this.isStartConnectingAnimation) {
      this.startConnectingAnimation();
    }
    if (this.currentStatus == SYS_STATUS_SEARCH_SATELLITE_SUCC) {
      this.isSatelliteOp = 1;
      this.isSatelliteDottedOp = 0;
      this.startConnectedSuccessAnimation();
    } else if (this.currentStatus == SYS_STATUS_SEARCH_SATELLITE_FAIL) {
      if (this.isStartConnectingAnimation) {
        this.stopConnectingAnimation();
      }
      if (!this.mSatelliteOutAnimate) {
        this.getSatelliteOutAnimation();
      }
      this.pitchImage = $r('app.media.float_center_blue')
      this.pitchTranslationY = 0;
      this.mDirectionPitch == SatelliteDirection.NONE;
      this.mDirectionAzimuth == SatelliteDirection.NONE;
      this.getFailedAnimation();
    }
  }

  getFailedAnimation() {
    this.getSatelliteOutAnimation();
    this.isSatelliteOp = 1;
    this.isSatelliteDottedOp = 0;
    this.getLightDownAnimation();
    animateTo({ duration: 150, curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1) }, () => {
      this.isSatelliteOp = 0;
    })
    animateTo({
      duration: 200, curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1), onFinish: () => {
        if (this.currentStatus != SYS_STATUS_SEARCH_SATELLITE_FAIL) {
          this.isSatelliteOp = 0;
          this.isSatelliteDottedOp = 1;
        }
      }
    }, () => {
      this.isSatelliteDottedOp = 1;
    })
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

  setWarnDirection(direction: number) {
    if (direction) {
      //left
      this.warnMaskTranX = -35;
      this.dottedAngle = -90;
    } else {
      this.warnMaskTranX = 35;
      this.dottedAngle = 90;
    }
    this.warnMaskTranY = 42;
  }

  build() {
    Scroll(this.scroller) {
      Column() {
        Stack({ alignContent: Alignment.Center }) {
          // 左右旋转箭头
          if (this.currentStatus != SYS_STATUS_SEARCH_SATELLITE_FAIL) {
            Image(this.azimuthImage)
              .width(200)
              .draggable(false)// .height(162)
              .rotate({ angle: this.arrowRightRotate })
              .scale({ x: this.arrowScale })
              .opacity(this.arrowOp)
              .draggable(false)
          }

          // 背景圆盘
          Image($r('app.media.float_background_base'))
            .width($r('app.float.satellite_float_base_wh'))
            .height($r('app.float.satellite_float_base_wh'))
            .draggable(false)
          //中心黑圆
          Image(this.pitchImage)
            .width(38)
            .height(38)
            .draggable(false)

          //卫星角度
          Canvas(this.contextBlue)
            .width($r('app.float.satellite_float_base_wh'))
            .height($r('app.float.satellite_float_base_wh'))
            .onReady(() => {
              this.contextBlue.beginPath();
              this.contextBlue.arc(this.centerAngle, this.centerAngle, this.directionLargeRadius,
                Math.PI * (270 - this.directionAngle / 2) / 180, Math.PI * (270 + this.directionAngle / 2) / 180,
                false);
              this.contextBlue.lineWidth = 1;
              this.contextBlue.strokeStyle = 'rgba(27,117, 255, 0.6)';
              this.contextBlue.stroke();
              this.contextBlue.arc(this.centerAngle, this.centerAngle, this.directionSmallRadius - 1,
                Math.PI * (270 + this.directionAngle / 2) / 180, Math.PI * (270 - this.directionAngle / 2) / 180, true);
              this.contextBlue.closePath();
              let x = this.radiusCircle - (this.directionLargeRadius - 1) * Math.cos(this.angle);
              let graient = this.contextBlue.createLinearGradient(x, this.centerAngle - this.directionLargeRadius + 2,
                x, this.centerAngle - this.directionSmallRadius + 5);
              graient.addColorStop(0, 'rgba(27,117, 255, 0.4)');
              graient.addColorStop(1, 'rgba(27,117, 255, 0)');
              this.contextBlue.fillStyle = graient;
              this.contextBlue.fill();
              this.contextBlue.clip();
            })
            .opacity(this.satelliteBlueOp)
          Canvas(this.contextGreen)
            .width($r('app.float.satellite_float_base_wh'))
            .height($r('app.float.satellite_float_base_wh'))
            .onReady(() => {
              this.contextGreen.beginPath();
              this.contextGreen.arc(this.centerAngle, this.centerAngle, this.directionLargeRadius,
                Math.PI * (270 - this.directionAngle / 2) / 180, Math.PI * (270 + this.directionAngle / 2) / 180,
                false);
              this.contextGreen.lineWidth = 1;
              this.contextGreen.strokeStyle = 'rgba(136,238, 125, 0.6)';
              this.contextGreen.stroke();
              this.contextGreen.arc(this.centerAngle, this.centerAngle, this.directionSmallRadius - 1,
                Math.PI * (270 + this.directionAngle / 2) / 180, Math.PI * (270 - this.directionAngle / 2) / 180, true);
              this.contextGreen.closePath();
              let x = this.radiusCircle - (this.directionLargeRadius - 1) * Math.cos(this.angle);
              let graient = this.contextGreen.createLinearGradient(x, this.centerAngle - this.directionLargeRadius + 2,
                x, this.centerAngle - this.directionSmallRadius + 5);
              graient.addColorStop(0, 'rgba(136,238, 125, 0.4)');
              graient.addColorStop(1, 'rgba(136,238, 125, 0)')
              this.contextGreen.fillStyle = graient;
              this.contextGreen.fill();
              this.contextGreen.clip();
            })
            .opacity(this.satelliteGreenOp)

          Shape() {
            Image($r('app.media.light_sweep'))
              .width($r('app.float.satellite_float_base_wh'))
              .height($r('app.float.satellite_float_base_wh'))
              .translate({ y: this.lightY })
              .visibility(this.showLightSweep ? Visibility.Visible : Visibility.Hidden)
              .draggable(false)
          }
          .width($r('app.float.satellite_float_base_wh'))
          .height($r('app.float.satellite_float_base_wh'))
          .align(Alignment.Center)
          .clip(new Path({
            commands: `M${this.startLarX} ${this.startLarY} A${this.radiusLar} ${this.radiusLar}
       ${this.directionAngle} 0 1 ${this.targetLarX} ${this.targetLarY} L${this.startSmallX}
       ${this.startSmallY} A${this.radiusToPxSmall} ${this.radiusToPxSmall} ${this.directionAngle} 0 0
       ${this.targetSmallX} ${this.targetSmallY}Z`
          }))

          Image($r('app.media.connecting_ring'))
            .width(this.connecting_wd_he_1)
            .height(this.connecting_wd_he_1)
            .align(Alignment.Center)
            .opacity(this.connecting_op1)
            .draggable(false)

          Image($r('app.media.connecting_ring'))
            .width(this.connecting_wd_he_2)
            .height(this.connecting_wd_he_2)
            .align(Alignment.Center)
            .opacity(this.connecting_op2)
            .draggable(false)

          Image($r('app.media.connecting_ring'))
            .width(this.connecting_wd_he_3)
            .height(this.connecting_wd_he_3)
            .align(Alignment.Center)
            .opacity(this.connecting_op3)
            .draggable(false)

          Image($r('app.media.connected_succ'))
            .width($r('app.float.satellite_float_base_wh'))
            .height($r('app.float.satellite_float_base_wh'))
            .align(Alignment.Center)
            .scale({ x: this.connectedScale, y: this.connectedScale })
            .opacity(this.connectedOp)
            .draggable(false)

          if (this.currentStatus != SYS_STATUS_SEARCH_SATELLITE_FAIL) {
            //卫星
            Image($r('app.media.float_sate'))
              .width($r('app.float.satellite_float_sate_wh'))
              .height($r('app.float.satellite_float_sate_wh'))
              .rotate({ angle: SatelliteUtils.getSateRotationAngles(this.mAzimuthDelta, this.directionAngle) })
              .opacity(this.isSatelliteOp)
              .draggable(false)
          } else {
            //虚线卫星
            Image($r('app.media.sate_float_dotted'))
              .width($r('app.float.satellite_float_sate_wh'))
              .height($r('app.float.satellite_float_sate_wh'))
              .opacity(this.isSatelliteDottedOp)
              .draggable(false)
          }
          Stack() {
            Image($r('app.media.sate_float_dotted'))
              .width($r('app.float.satellite_float_sate_wh'))
              .height($r('app.float.satellite_float_sate_wh'))
              .opacity(this.satelliteWarnDottedLeftOp)
              .rotate({ angle: -90 })
              .translate({ y: this.markAlertTranY })
              .draggable(false)

            Image($r('app.media.warn_mask'))
              .width($r('app.float.satellite_float_sate_wh'))
              .height(220)
              .scale({ x: 1.6 })
              .translate({ x: -this.markAlertTranX, y: this.markAlertTranY })
              .opacity(this.warnMaskLeftOp)
              .draggable(false)

            Image($r('app.media.warn_light'))
              .width($r('app.float.satellite_float_sate_wh'))
              .height(200)
              .scale({ x: 1.6 })
              .translate({ x: -this.markAlertTranX, y: this.markAlertTranY })
              .opacity(this.warnMaskLeftOp)
              .draggable(false)
          }
          .visibility(this.warnLeftVisibility ? Visibility.Visible : Visibility.None)

          Stack() {
            Image($r('app.media.sate_float_dotted'))
              .width($r('app.float.satellite_float_sate_wh'))
              .height($r('app.float.satellite_float_sate_wh'))
              .opacity(this.satelliteWarnDottedRightOp)
              .rotate({ angle: 90 })
              .translate({ y: this.markAlertTranY })
              .draggable(false)

            Image($r('app.media.warn_mask'))
              .width(210)
              .height(200)
              .scale({ x: 1.6 })
              .translate({ x: this.markAlertTranX, y: this.markAlertTranY })
              .opacity(this.warnMaskRightOp)
              .draggable(false)

            Image($r('app.media.warn_light'))
              .width(210)
              .height(200)
              .scale({ x: 1.6 })
              .translate({ x: this.markAlertTranX, y: this.markAlertTranY })
              .opacity(this.warnMaskRightOp)
              .draggable(false)
          }
          .visibility(this.warnMaskRightOp ? Visibility.Visible : Visibility.None)

          // 中心小球
          Image($r('app.media.float_search_ball'))
            .width(27)
            .height(27)
            .translate({ y: this.pitchTranslationY })
            .draggable(false)
          if (this.mDirectionPitch == SatelliteDirection.UP && this.currentStatus != SYS_STATUS_SEARCH_SATELLITE_FAIL) {
            Image($r('app.media.float_direction_up'))
              .width(15)
              .height(10)
              .translate({ y: this.pitchTranslationY - 18 })
              .draggable(false)
          } else if (this.mDirectionPitch == SatelliteDirection.DOWN && this.currentStatus !=
            SYS_STATUS_SEARCH_SATELLITE_FAIL) {
            Image($r('app.media.float_direction_down'))
              .width(15)
              .height(10)
              .translate({ y: this.pitchTranslationY + 18 })
              .draggable(false)
          }
          // 引导小球虚线画布
          Canvas(this.context)
            .width(40)
            .height(162)
            .onReady(() => {
              this.context.strokeStyle = 'rgba(66, 129, 255, 0.6)';
              this.context.lineWidth = 3;
              this.context.lineCap = 'round';
            })
        }
        .width(200)
        .height('100%')
      }
      .translate({ y: this.backgroundTranslate })
      .animation({ delay: 200, curve: Curves.interpolatingSpring(0, 1, 228, 30) })
      .justifyContent(FlexAlign.Start)
      .height('100%')
    }.height(222)
    .scrollBar(BarState.Off)
  }
}
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
import { SatelliteDirection,
  SYS_STATUS_SATELLITE_CONNECTING,
  SYS_STATUS_SEARCHING_SATELLITE,
  SYS_STATUS_SEARCH_SATELLITE_FAIL,
  SYS_DISCONNECT,
  HYACINTH_DIALOG_SWITCH_SATELLITE_START_TIMES,
  HYACINTH_DIALOG_OLD_SATELLITE_WINKED_TIMES,
  HYACINTH_DIALOG_OLD_SATELLITE_AZIMUTH,
  HYACINTH_FLOAT_OLD_SATELLITE_AZIMUTH,
  HYACINTH_FLOAT_OLD_SATELLITE_WINKED_TIMES,
  HYACINTH_FLOAT_SWITCH_SATELLITE_START_TIMES,
  SYS_STATUS_SEARCH_SATELLITE_SUCC } from '../../common/constant/SatelliteSearchConst';
import { LogUtils } from '@ohos/common/CommonIndex';
import { curves } from '@kit.ArkUI';
import lottie, { AnimationItem } from '@ohos/lottie';
import util from '@ohos.util';
import { Queue } from '@kit.ArkTS';
import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@ohos.base';

const TAG = 'HyacinthFloatWindowSearch';

@Entry
@Component
export struct HyacinthFloatWindowSearch {
  @Link @Watch('statusChange') currentStatus: number;
  @Link @Watch('changeSatelliteData') mSatelliteData: SatelliteData;
  @Link @Watch('changeSatelliteData') showReConnect: boolean;
  @Link mOldAzimuthDelta: number;
  @Link @Watch('switchSatellite') switchSatelliteTimes: number;
  @StorageLink(HYACINTH_DIALOG_SWITCH_SATELLITE_START_TIMES) hyacinthDialogSwitchSatelliteStartTimes: number = 0;
  @StorageLink(HYACINTH_DIALOG_OLD_SATELLITE_WINKED_TIMES) hyacinthDialogOldSatelliteWinkedTimes: number = 0;
  @StorageLink(HYACINTH_DIALOG_OLD_SATELLITE_AZIMUTH) hyacinthDialogOldSatelliteAzimuth: number = 0;
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
  @State isLottieShow: boolean = false; // 动画组件是否显示
  @State oldSatelliteChangeOp:number = 0;
  @State winkSatelliteOp:number = 0;

  private  timoutQueue: Queue<number> = new Queue();
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  // 是否正在播放out动画
  private mSatelliteOutAnimate = false;
  private alertCubic = Curves.cubicBezierCurve(0.33, 0, 0.67, 1);
  private settingsLottie: RenderingContextSettings = new RenderingContextSettings(true);
  private contextLottie: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settingsLottie);
  private animationItem: AnimationItem | undefined = undefined;

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
    if (this.currentStatus == SYS_STATUS_SEARCH_SATELLITE_SUCC &&
      this.hyacinthDialogSwitchSatelliteStartTimes != undefined &&
      this.hyacinthDialogSwitchSatelliteStartTimes > 0) {
      let now = new Date().getTime();
      if (now < this.hyacinthDialogOldSatelliteWinkedTimes) {
        // 老卫星动效未执行完,老卫星闪烁三轮，然后消失
        this.winkOldSatellite();
        // 新卫星闪烁三轮，然后常显
        this.winkNewSatellite();
      } else if (now - this.hyacinthDialogSwitchSatelliteStartTimes < 3 * 1000) {
        // 半模态切星闪烁动效未执行完
        if (this.hyacinthDialogOldSatelliteWinkedTimes < this.hyacinthDialogSwitchSatelliteStartTimes) {
          // 老卫星闪烁动效未执行完
          this.mOldAzimuthDelta = this.hyacinthDialogOldSatelliteAzimuth;
          // 执行老卫星消失动效
          animateTo({
            duration: 400,
            curve: Curve.Linear,
          }, () => {
            this.oldSatelliteChangeOp = 0;
          });
          // 执行新卫星出现动效
          this.doWinkNewSatellite(0);
        } else {
          // 执行新卫星出现动效
          this.doWinkNewSatellite(0);
        }
      }
    }
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'hyacinth float window search aboutToDisappear');
    this.clearTimeoutId();
  }

  initData() {
    this.isSatelliteOp = this.mSatelliteData.sateShow === 0 ? 0 : 1;
    if (!SatelliteUtils.isGuideAzimuth(this.mSatelliteData.guideAzimuth)) {
      this.arrowOp = 1;
      this.satelliteBlueOp = 1;
    } else {
      this.satelliteGreenOp = 1;
    }
    if (this.currentStatus === SYS_STATUS_SEARCH_SATELLITE_FAIL) {
      this.isSatelliteDottedOp = 1;
      this.isSatelliteOp = 0;
      this.satelliteGreenOp = 0;
      this.satelliteBlueOp = 0;
    }
    this.switchSatelliteTimes = 0;
  }

  clearTimeoutId() {
    LogUtils.i(TAG, 'clearTimeoutId timoutQueue length is :' + this.timoutQueue.length);
    while (this.timoutQueue.length > 0) {
      let timerId = this.timoutQueue.pop();
      clearTimeout(timerId);
    }
    LogUtils.i(TAG, 'clearTimeoutId timoutQueue length is :' + this.timoutQueue.length);
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
    this.isLottieShow = true;
    this.animationItem?.stop();
    this.animationItem?.goToAndPlay(0);
  }

  setAngle(angle: number) {
    this.angle = Math.PI * angle / 180;
  }

  getAnimateData(): object | null {
    let result = getContext(this).resourceManager.getRawFileContentSync('lottie/hyacinthSearchAnimate.json');
    let decode = util.TextDecoder.create('utf-8', { fatal: false, ignoreBOM: false })
    let str = decode.decodeWithStream(result, { stream: false })
    return JSON.parse(str);
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
    if (!SatelliteUtils.isGuideAzimuth(this.mSatelliteData.guideAzimuth)) {
      if (this.mAzimuthDelta > 0) {
        this.mDirectionAzimuth = SatelliteDirection.RIGHT;
        this.azimuthImage = $r('app.media.float_turn_right');
        this.arrowOp = 1 ;
      } else if (this.mAzimuthDelta < 0) {
        this.mDirectionAzimuth = SatelliteDirection.LEFT;
        this.azimuthImage = $r('app.media.float_turn_left');
        this.arrowOp = 1;
      } else {
        this.arrowOp = 0;
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
    } else {
      this.arrowOp = 0;
    }
    if (this.satelliteGreenOp == 0 && SatelliteUtils.isGuideAzimuth(this.mSatelliteData.guideAzimuth)) {
      this.mDirectionAzimuth = SatelliteDirection.NONE;
      //方位角对齐，但是当前扇形不是绿色，变为绿色扇形
      this.getSatelliteInAnimation();
    } else if (this.satelliteBlueOp == 0 && !SatelliteUtils.isGuideAzimuth(this.mSatelliteData.guideAzimuth)) {
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
    if (SatelliteUtils.isGuidePitch(this.mSatelliteData.guidePitch)) {
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
        if (this.isNeedBaseUp && SatelliteUtils.isGuideAzimuth(this.mSatelliteData.guideAzimuth)) {
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
    if (SatelliteUtils.isGuideAzimuth(this.mSatelliteData.guideAzimuth) &&
    SatelliteUtils.isGuidePitch(this.mSatelliteData.guidePitch) && this.mSatelliteData.sateIdx != -1) {
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
    // 卫星是否显示以协议上报数据为准
    this.isSatelliteOp = this.mSatelliteData.sateShow === undefined ? 0 : this.mSatelliteData.sateShow;
    if (this.currentStatus != SYS_STATUS_SEARCH_SATELLITE_FAIL) {
      this.changeByAzimuth();
      this.changeByPitchDelta();
    }
  }

  switchSatellite() {
    LogUtils.i(TAG, 'switchFloatSatellite start.');
    let now = new Date().getTime()
    AppStorage.setOrCreate(HYACINTH_FLOAT_SWITCH_SATELLITE_START_TIMES, now);
    AppStorage.setOrCreate(HYACINTH_FLOAT_OLD_SATELLITE_AZIMUTH, this.mOldAzimuthDelta);
    this.startVibration(500);
    // 老卫星闪烁三轮，然后消失
    this.winkOldSatellite();
    // 新卫星闪烁三轮，然后常显
    this.winkNewSatellite();
  }

  private startVibration(duration: number): void {
    LogUtils.i(TAG, 'startVibration float start.');
    // 震动提醒
    vibrator.startVibration({
      type: 'time',
      duration: duration,
    }, {
      id: 0,
      usage: 'alarm'
    }, (error: BusinessError) => {
      if (error) {
        LogUtils.e(TAG, `Hyacinth float window Failed to start vibration. Code: ${error.code}, message: ${error.message}`);
        return;
      }
      LogUtils.i(TAG, 'Hyacinth float window Succeed in starting vibration');
    });
  }

  async winkOldSatellite() {
    LogUtils.i(TAG, 'switchSateShowOldSate start.');
    this.oldSatelliteChangeOp = 1;

    let waitTimes = 0;
    for (let i = 1; i <= 3; i ++) {
      // 变暗200ms 变亮 250ms 停留300ms
      let timerId = setTimeout(() => {
        this.changeOldSatelliteOpacityDown();
        let now = new Date().getTime()
        AppStorage.setOrCreate(HYACINTH_FLOAT_OLD_SATELLITE_WINKED_TIMES, now);
      }, waitTimes);
      this.timoutQueue.add(timerId);
      waitTimes = waitTimes + 750;
    }
    // 循环3次后老卫星消失
    let timerId = setTimeout(() => {
      animateTo({
        duration: 400,
        curve: Curve.Linear,
      }, () => {
        this.oldSatelliteChangeOp = 0;
      });
    }, waitTimes);
    this.timoutQueue.add(timerId);
  }

  changeOldSatelliteOpacityDown() {
    animateTo({
      duration: 200,
      curve: Curve.Linear,
      onFinish: () => {
        this.changeOldSatelliteOpacityUp();
      }
    }, () => {
      this.oldSatelliteChangeOp = 0.4; // 目标透明度为0.4
    });
  }

  changeOldSatelliteOpacityUp() {
    animateTo({
      duration: 250,
      curve: Curve.Linear,
    }, () => {
      this.oldSatelliteChangeOp = 1; // 目标透明度为1
    });
  }

  async winkNewSatellite() {
    LogUtils.i(TAG, 'winkNewSatellite start.');
    this.winkSatelliteOp = 0.01;

    animateTo({
      duration: 1000,
      curve: Curve.Linear,
    }, () => {
      this.winkSatelliteOp = 0.4;
    })

    this.doWinkNewSatellite(2250);
  }

  private doWinkNewSatellite(waitTimes: number) {
    animateTo({
      delay: waitTimes,
      duration: 400,
      curve: Curve.Linear,
    }, () => {
      this.winkSatelliteOp = 1;
    });
    waitTimes += 700; // 400变亮 + 300停留
    for (let i = 1; i <= 3; i++) {
      // 变亮 250ms 变暗200ms 停留300ms
      let timerId = setTimeout(() => {
        this.changeNewSatelliteOpacityDown();
      }, waitTimes);
      waitTimes = waitTimes + 750;
      this.timoutQueue.add(timerId);
    }

    // 循环3次后新卫星常显
    let timerId = setTimeout(() => {
      animateTo({
        duration: 250,
        curve: Curve.Linear,
      }, () => {
        this.winkSatelliteOp = 1;
      });
    }, waitTimes);
    this.timoutQueue.add(timerId);
  }

  changeNewSatelliteOpacityUp() {
    animateTo({
      duration: 250,
      curve: Curve.Linear,
    }, () => {
      this.winkSatelliteOp = 1; // 目标透明度为1
    });
  }

  changeNewSatelliteOpacityDown() {
    animateTo({
      duration: 200,
      curve: Curve.Linear,
      onFinish: () => {
        this.changeNewSatelliteOpacityUp();
      }
    }, () => {
      this.winkSatelliteOp = 0.4; // 目标透明度为0.4
    });
  }

  statusChange() {
    LogUtils.i(TAG, 'statusChange is called status = ' + this.currentStatus);
    if (this.currentStatus != SYS_STATUS_SATELLITE_CONNECTING && this.isStartConnectingAnimation) {
      this.stopConnectingAnimation();
    } else if (this.currentStatus == SYS_STATUS_SATELLITE_CONNECTING && !this.isStartConnectingAnimation) {
      this.startConnectingAnimation();
    }
    if (this.currentStatus == SYS_STATUS_SEARCH_SATELLITE_SUCC) {
      this.isSatelliteOp = this.mSatelliteData.sateShow === 0 ? 0 : 1;
      this.isSatelliteDottedOp = 0;
      this.startConnectedSuccessAnimation();
    } else if (this.currentStatus === SYS_STATUS_SEARCH_SATELLITE_FAIL || this.currentStatus === SYS_DISCONNECT) {
      if (this.isStartConnectingAnimation) {
        this.stopConnectingAnimation();
      }
      if (!this.mSatelliteOutAnimate) {
        this.getSatelliteOutAnimation();
      }
      this.pitchImage = $r('app.media.float_center_blue')
      this.pitchTranslationY = 0;
      this.mDirectionPitch = SatelliteDirection.NONE;
      this.mDirectionAzimuth = SatelliteDirection.NONE;
      this.getFailedAnimation();
    }
  }

  getFailedAnimation() {
    this.getSatelliteOutAnimation();
    this.isSatelliteOp = this.mSatelliteData.sateShow === 0 ? 0 : 1;
    this.isSatelliteDottedOp = 0;
    this.getLightDownAnimation();
    animateTo({ duration: 150, curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1) }, () => {
      this.isSatelliteOp = 0;
    })
    animateTo({
      duration: 200, curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1), onFinish: () => {
        if (this.currentStatus != SYS_STATUS_SEARCH_SATELLITE_FAIL || this.currentStatus != SYS_DISCONNECT) {
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
              .rotate({ angle: this.arrowRightRotate })
              .scale({ x: this.arrowScale })
              .opacity(this.arrowOp)
              .draggable(false)
          }

          // 背景圆盘
          if (this.currentStatus != SYS_STATUS_SEARCH_SATELLITE_SUCC) {
            //卫星
            Image($r('app.media.float_background_base'))
              .width($r('app.float.satellite_float_base_wh'))
              .height($r('app.float.satellite_float_base_wh'))
              .draggable(false)
          } else {
            Image($r('app.media.hyacinth_float_connected_succ_compass'))
              .width($r('app.float.satellite_float_base_wh'))
              .height($r('app.float.satellite_float_base_wh'))
              .draggable(false)
          }

          //中心黑圆
          Image(this.pitchImage)
            .width(38)
            .height(38)
            .draggable(false)

          Column() {
            Canvas(this.contextLottie)
              .width(220)
              .height(220)
              .translate({ y: -75 })
              .visibility(this.isLottieShow ? Visibility.Visible : Visibility.Hidden)
              .onReady(() => {
                this.isLottieShow = false;
                //抗锯齿的设置
                this.contextLottie.imageSmoothingEnabled = true;
                this.contextLottie.imageSmoothingQuality = 'medium'
                lottie.destroy(TAG); //加载动画前先销毁之前加载的动画
                this.animationItem = lottie.loadAnimation({
                  container: this.contextLottie, // 渲染上下文
                  renderer: 'canvas', // 渲染方式
                  loop: false, // 是否循环播放,默认true
                  autoplay: false, // 是否自动播放，默认true
                  name: TAG, // 动画名称
                  contentMode: 'Contain', // 填充的模式
                  frameRate: 60, //设置animator的刷帧率为30
                  animationData: this.getAnimateData(),
                })
              })
          }
          .width($r('app.float.satellite_float_base_wh'))
          .height($r('app.float.satellite_float_base_wh'))
          .align(Alignment.Center)

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

          Image($r(`app.media.hyacinth_float_connected_succ_sector`))
            .width($r('app.float.satellite_float_base_wh'))
            .height($r('app.float.satellite_float_base_wh'))
            .align(Alignment.Center)
            .scale({ x: this.connectedScale, y: this.connectedScale })
            .opacity(this.connectedOp)
            .draggable(false)

          if (this.currentStatus != SYS_STATUS_SEARCH_SATELLITE_FAIL) {
            Image($r('app.media.hyacinth_float_finding_sector'))
              .width(150)
              .height(150)
              .draggable(false)
              .opacity(this.satelliteBlueOp)

            Image(this.currentStatus == SYS_STATUS_SEARCH_SATELLITE_SUCC ?
            $r('app.media.hyacinth_float_success_sector') : $r('app.media.hyacinth_float_connecting_sector'))
              .width(150)
              .height(150)
              .draggable(false)
              .opacity(this.satelliteGreenOp)

            //卫星
            Image($r('app.media.hyacinth_float_sate'))
              .width($r('app.float.satellite_float_base_wh'))
              .height($r('app.float.satellite_float_base_wh'))
              .rotate({ angle: SatelliteUtils.getSateRotationAngles(this.mAzimuthDelta, this.directionAngle) })
              .opacity(this.winkSatelliteOp > 0 ? this.winkSatelliteOp : this.isSatelliteOp)
              .draggable(false)

            // 切换卫星时老的卫星
            Image($r('app.media.hyacinth_float_sate'))
              .width($r('app.float.satellite_float_base_wh'))
              .height($r('app.float.satellite_float_base_wh'))
              .rotate({ angle: SatelliteUtils.getSateRotationAngles(this.mOldAzimuthDelta, this.directionAngle) })
              .opacity(this.oldSatelliteChangeOp )
              .draggable(false)
          } else {
            Image($r('app.media.hyacinth_float_connected_fail_sector'))
              .width(150)
              .height(150)
              .draggable(false)
              .opacity(this.isSatelliteDottedOp)

            //虚线卫星
            Image($r('app.media.hyacinth_float_sate_dotted'))
              .width($r('app.float.satellite_float_sate_wh'))
              .height($r('app.float.satellite_float_sate_wh'))
              .opacity(this.isSatelliteDottedOp)
              .draggable(false)
          }
          Stack() {
            Image($r('app.media.hyacinth_float_sate_dotted'))
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
            Image($r('app.media.hyacinth_float_sate_dotted'))
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
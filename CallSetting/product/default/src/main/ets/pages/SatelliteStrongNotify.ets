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

import SatelliteSearchManager from '../manager/SatelliteSearchManager';
import { LogUtils, ReportUtil } from '@ohos/common/CommonIndex';
import { SATELLITE_TOAST_DURATION_NEW_FOLD, SHOW_TIME_FIFTEEN,
  STRONG_NOTIFY } from '../common/constant/SatelliteSearchConst';
import { isTablet } from '../common/utils/Utils';
import { vibrator } from '@kit.SensorServiceKit';
import { IMediaPlayer } from '../components/IMediaPlayere';
import { display, LengthMetrics, promptAction, window } from '@kit.ArkUI';
import { BusinessError } from '@ohos.base';
import { emitter, power} from '@kit.BasicServicesKit';
import { EMIT_NEW_FOLD_PHONE_EXTERNAL_EVENT_ID } from '../common/constant/CallSettingsConstant';
import ScreenAdapterUtils from '../common/utils/ScreenAdapterUtils';

const TAG = 'SatelliteStrongNotify';
const COUNTDOWN_TIMER: number = 1000;
const GRADIENT_CIRCLE_CENTER = -25;
const MAX_FONT_SCALE: number = 1.45;
const MAX_BUTTON_FONT_SCALE: number = 2;
@Entry
@Component

export struct SatelliteStrongNotify {
  @State message: string = 'satellite strong notify';
  satelliteManager: SatelliteSearchManager = SatelliteSearchManager.getInstance();
  @State notifyTimeMinute: number = 0;
  @State notifyTime: number = 0;
  @State vibrateRingTime: number = 0;
  @State oneTimeText: Resource = $r('app.string.satellite_message_just_now');
  @State twoTimeText: Resource = $r('app.plural.satellite_message_fifteen_minute', this.notifyTimeMinute, this.notifyTimeMinute);
  @State displayHeight: number = 0;
  @State displayWidth: number = 0;
  @State cavWidth: number = 0;
  @State cavHeight: number = 0;
  @State isScreenOn: boolean = true;
  @State isShow: boolean = true;
  private isTimer: boolean = false;
  private isVibrateAndRing: boolean = false;
  private mediaPlayer: IMediaPlayer = new IMediaPlayer(getContext(this));
  private notifyTimerId: number = -1;
  private vibrateRingTimerId: number = -1;
  private timeMinute: number = 60;
  private isNewFormFoldPhone = ScreenAdapterUtils.isNewFormFoldPhone();
  @State isNewFoldPhoneScreen: boolean = false;

  startVibrateAndRing() {
    this.vibrateRingTime = this.satelliteManager.getStrongNotifyRingTime();
    this.vibrateRingTimerId = setInterval(() => {
      this.isScreenOn = power.isActive();
      LogUtils.i(TAG, ' vibrateRingTime ' + this.vibrateRingTime);
      if (this.vibrateRingTime >= 27 || this.isScreenOn == false) {
        clearInterval(this.vibrateRingTimerId)
      }
      if (this.vibrateRingTime % 7 === 0) {
        vibrator.startVibration({
          type: 'time',
          duration: 2750,
        }, {
          id: 0,
          usage: 'alarm'
        }, (error: BusinessError) => {
          if (error) {
            LogUtils.e(TAG, ` Failed to start vibration. Code: ${error.code}, message: ${error.message}`);
            return;
          }
          LogUtils.i(TAG, ' Succeed in starting vibration');
        });
        this.mediaPlayer.doPlay('Birdsong.ogg');
      }
      this.vibrateRingTime = this.vibrateRingTime + 1;
      this.satelliteManager.setStrongNotifyRingTime(this.vibrateRingTime);
    }, 500)
  }

  stopVibrateAndRing() {
    vibrator.stopVibration();
    this.mediaPlayer.release();
    this.vibrateRingTime = 0;
    this.satelliteManager.setStrongNotifyRingTime(this.vibrateRingTime);
    clearInterval(this.vibrateRingTimerId);
  }

  startNotifyTimer() {
    this.notifyTime = this.satelliteManager.getStrongNotifyTime();
    this.notifyTimeMinute = this.notifyTime / this.timeMinute;
    if (this.notifyTimeMinute >= 1 && this.notifyTimeMinute <= 15) {
      this.twoTimeText =
        $r('app.plural.satellite_message_fifteen_minute', this.notifyTimeMinute, this.notifyTimeMinute);
    }
    this.notifyTimerId = setInterval(() => {
      this.notifyTime = this.notifyTime + 1;
      this.notifyTimeMinute = this.notifyTime / this.timeMinute;
      if (this.notifyTimeMinute >= 1 && this.notifyTimeMinute <= 15) {
        this.twoTimeText =
          $r('app.plural.satellite_message_fifteen_minute', this.notifyTimeMinute, this.notifyTimeMinute);
      }
      if (this.notifyTime == SHOW_TIME_FIFTEEN) {
        this.stopNotifyTimer();
      }
      this.satelliteManager.setStrongNotifyTime(this.notifyTime);
    }, COUNTDOWN_TIMER);
  }

  stopNotifyTimer() {
    this.isTimer = false;
    clearInterval(this.notifyTimerId);
  }

  getNotifyWidth( width:number ) : number {
    if (isTablet()) {
      return this.displayWidth > this.displayHeight ?
        px2vp(this.displayWidth) * width / 360 : px2vp(this.displayHeight) * width / 360;
    } else {
      return px2vp(this.displayWidth) * width / 360;
    }
  }

  getNotifyHeight( height:number ) : number {
    if (isTablet()) {
      return this.displayWidth > this.displayHeight ?
        px2vp(this.displayHeight) * height / 780 : px2vp(this.displayWidth) * height / 780;
    } else {
      return px2vp(this.displayHeight) * height / 780;
    }
  }

  closeStrongNotifyAndAlert(): void {
    this.hidePage();
    promptAction.showToast({
      message: $r('app.string.satellite_new_fold_un_support_toast'),
      duration: SATELLITE_TOAST_DURATION_NEW_FOLD
    });
    // 请展开手机使用卫星通信打点
    ReportUtil.getInstance().reportSatelliteExpandToUseToast();

    // 自动关闭强提醒窗口-5s后
    this.satelliteManager.closeStrongNotifyInNewFoldScreen(SATELLITE_TOAST_DURATION_NEW_FOLD);
  }

  hidePage() {
    try {
      this.isShow = false;
      let thisWindow = window.findWindow(STRONG_NOTIFY);
      if (thisWindow) {
        thisWindow.setWindowBackgroundColor(Color.Transparent.toString());
        thisWindow.setWindowTouchable(false);
        thisWindow.setWindowFocusable(false);
        LogUtils.i(TAG, `hidePage success`);
      }
    } catch (err) {
      LogUtils.e(TAG, `hidePage : ${err?.code} ${err?.message}`);
    }
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
      if (!this.isShow) {
        this.satelliteManager.closeStrongNotifyInNewFoldScreen(0);
      }
    } catch (err) {
      LogUtils.e(TAG, `newFoldPhoneChange error:${err?.code}:${err?.message}`);
    }
  }

  aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear');
    try {
      this.displayWidth = display.getDefaultDisplaySync().width;
      this.displayHeight = display.getDefaultDisplaySync().height;
    } catch (err) {
      LogUtils.e(TAG, `aboutToAppear getDefaultDisplaySync error: ${err?.code} ${err?.message}`);
    }
    this.isVibrateAndRing = this.satelliteManager.getIsStrongNotifyRing();
    if (this.isVibrateAndRing == false) {
      this.startVibrateAndRing();
      this.isVibrateAndRing = true;
      this.satelliteManager.setIsStrongNotifyRing(this.isVibrateAndRing);
    }
    this.startNotifyTimer();
    if (this.isNewFormFoldPhone) {
      this.isNewFoldPhoneScreen = ScreenAdapterUtils.getInstance().isNewFoldPhoneExternalScreen();
      this.addEmitterListener();
    }
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear.');
    this.stopNotifyTimer();
    this.stopVibrateAndRing();
    if (this.isNewFormFoldPhone) {
      this.removeEmitterListener();
    }
  }

  build() {
    NavDestination() {
      Column() {
        //强提醒信息
        Column() {
          GridRow({
            columns: { xs: 4, sm: 8, md: 12, lg: 12},
            breakpoints: {
              value: ['600vp', '840vp', '1440vp'],
              reference: BreakpointsReference.WindowSize
            },
            gutter: {
              x: {xs: 8, sm: 12, md: 16, lg: 20}
            },
          }) {
            this.ContentGridCol();
          }
          .margin({left: 12, right: 12})
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        //退出按键
        Column() {
          this.ExitImage();
        }
        .justifyContent(FlexAlign.End)
        .width('100%')
      }
      .backgroundColor('#ff4c4848')
      .backgroundBlurStyle(BlurStyle.Thick)
    }
    .visibility(this.isShow ? Visibility.Visible : Visibility.None)
  }

  @Builder
  ExitImage() {
      Stack() {
        Image($r('app.media.ic_bottom_notify_close'))
          .width(48)
          .height(48)
          .matchTextDirection(true)
          .accessibilityText($r('app.string.satellite_exit'))
          .margin({ bottom: this.isNewFoldPhoneScreen ? 12 : this.getNotifyHeight(92) })
          .onClick(() => {
            this.isVibrateAndRing = false;
            this.satelliteManager.setIsStrongNotifyRing(this.isVibrateAndRing);
            this.notifyTime = 0;
            this.satelliteManager.setStrongNotifyTime(this.notifyTime);
            this.stopVibrateAndRing();
            this.stopNotifyTimer();
            if (this.isNewFoldPhoneScreen) {
              this.closeStrongNotifyAndAlert();
              LogUtils.i(TAG, 'closeStrongNotifyAndAlert');
            } else {
              this.satelliteManager.createSatelliteDialog();
              LogUtils.i(TAG, 'createSatelliteDialog');
            }
          })
      }
      .alignContent(Alignment.Center)
  }

  @Builder
  MiddleImage() {
    RelativeContainer() {
      Image($r('app.media.ssm_strong_top'))
        .alignRules({
          top: { anchor: '__container__', align: VerticalAlign.Top },
          right: { anchor: '__container__', align: HorizontalAlign.End }
        })
        .borderRadius(16)
        .width(167)
      Image($r('app.media.ssm_strong_bottom'))
        .alignRules({
          bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
          left: { anchor: '__container__', align: HorizontalAlign.Start }
        })
        .width(113)
    }
    .width(this.cavWidth)
    .height(this.cavHeight)
    .direction(Direction.Ltr)
  }

  @Builder
  ContentGridCol() {
    GridCol({
      span: { xs: 4, sm: 6, md: 8, lg: 8 },
      offset: { xs: 0, sm: 1, md: 2, lg: 2 }
    }) {
      Column() {
        Stack() {
          this.MiddleImage();
          this.CoreColumn();
        }
        .margin({
          top: this.isNewFoldPhoneScreen ? 44 : this.getNotifyHeight(36),
          bottom: this.isNewFoldPhoneScreen ? 8 : 0
        })
        .alignContent(Alignment.Center)
        .backgroundColor('#EA460E')
        .borderRadius(16)
        .radialGradient({
          center: [this.cavWidth + GRADIENT_CIRCLE_CENTER, GRADIENT_CIRCLE_CENTER],
          radius: 100,
          colors: [['#FA6526', 0.0], ['#F77108', 0.7], ['#EA460E', 1.0]]
        })
      }
    }
  }

  @Builder
  CoreColumn() {
    Column() {
      this.CoreColumnTitle()
      this.CoreColumnContent()
      this.CoreColumnButton()
    }
    .padding({
      left: this.getNotifyWidth(12),
      right: this.getNotifyWidth(12),
      top: this.isNewFoldPhoneScreen ? 12 : this.getNotifyHeight(12),
      bottom: this.isNewFoldPhoneScreen ? 16 : this.getNotifyHeight(16)
    })
    .onAreaChange((oldValue: Area, newValue: Area) => {
      console.info(`Ace: on area change, oldValue is ${JSON.stringify(oldValue)} value is ${JSON.stringify(newValue)}`);
      this.cavWidth = Number(newValue.width);
      this.cavHeight = Number(newValue.height);
    })
  }

  @Builder
  CoreColumnTitle() {
    Column() {
      Row() {
        Image($r('app.media.ic_notification'))
          .width('16vp')
          .height('16vp')
          .margin({ end: LengthMetrics.vp(8) });
        Text($r('app.string.new_satellite_descriptions'))
          .fontSize(12)
          .lineHeight(16)
          .fontFamily('HarmonyHeiTi')
          .maxFontScale(MAX_FONT_SCALE)
          .fontWeight(FontWeight.Regular)
          .fontColor($r('sys.color.white'))
          .margin({ end: LengthMetrics.vp(8) });
        if (this.notifyTime / this.timeMinute < 1) {
          Text(this.oneTimeText)
            .fontSize(12)
            .lineHeight(16)
            .maxFontScale(MAX_FONT_SCALE)
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Regular)
            .fontColor($r('sys.color.white'));
        } else if (this.notifyTime / this.timeMinute >= 1 && this.notifyTime / this.timeMinute <= 15) {
          Text(this.twoTimeText)
            .fontSize(12)
            .lineHeight(16)
            .maxFontScale(MAX_FONT_SCALE)
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Regular)
            .fontColor($r('sys.color.white'));
        }
      }
      .width('100%');
    }
    .width('100%')
    .margin({ bottom: 22 })
  }

  @Builder
  CoreColumnContent() {
    Scroll() {
      Column() {
        Text($r('app.string.satellite_call_message_notice'))
          .fontSize(18)
          .lineHeight(24)
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Medium)
          .maxFontScale(MAX_FONT_SCALE)
          .fontColor($r('sys.color.white'))
          .textAlign(TextAlign.Start)
          .margin({ bottom: this.isNewFoldPhoneScreen ? 0 : 16 });
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .scrollBarColor('rgba(255, 255, 255, 0.4)')
    .width('100%')
    .constraintSize({ maxHeight: this.isNewFoldPhoneScreen ? 94 : undefined })
  }

  @Builder
  CoreColumnButton() {
    Column() {
      Button() {
        Text($r('app.string.aim_satellite'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.white'))
          .fontSize(12)
          .lineHeight(16)
          .maxFontScale(MAX_BUTTON_FONT_SCALE)
          .textAlign(TextAlign.Center)
          .constraintSize({ minWidth: 110 })
          .maxLines(2)
      }
      .backgroundColor(Color.Transparent)
      .padding({ left: 16, right: 16, top:6, bottom:6 })
      .border({ width: 1, radius: 14, color: $r('sys.color.white') })
      .onClick(() => {
        this.isVibrateAndRing = false;
        this.satelliteManager.setIsStrongNotifyRing(this.isVibrateAndRing);
        this.notifyTime = 0;
        this.satelliteManager.setStrongNotifyTime(this.notifyTime);
        this.stopNotifyTimer();
        this.stopVibrateAndRing();
        if (this.isNewFoldPhoneScreen) {
          this.closeStrongNotifyAndAlert();
          LogUtils.i(TAG, 'closeStrongNotifyAndAlert');
        } else {
          this.satelliteManager.createSatelliteDialog();
          LogUtils.i(TAG, 'createSatelliteDialog');
        }
      })
    }
    .width('100%')
    .margin({ top: this.isNewFoldPhoneScreen ? 8 : 0 });
  }
}
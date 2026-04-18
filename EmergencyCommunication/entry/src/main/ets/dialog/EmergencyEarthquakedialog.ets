/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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
import { TextPlayer } from '../EmergencyEarthquakeAlarm/EarthquakeInfoSpeaker';
import { IMediaPlayer } from '../EmergencyEarthquakeAlarm/IMediaPlayere';
import audio from '@ohos.multimedia.audio';
import LogUtils from '../utils/HiLog';
import { common } from '@kit.AbilityKit';
import Want from '@ohos.app.ability.Want';
import { BusinessError, emitter, screenLock, systemDateTime } from '@kit.BasicServicesKit';
import { EmergencyGlobalContextHelper } from '../utils/EmergencyGlobalContextHelper';
import { promptAction, window } from '@kit.ArkUI';
import * as Constants from '../utils/Constants';
import { ReportUtil } from '../utils/ReportUtil';
import { LengthMetrics } from '@kit.ArkUI';
import { display } from '@kit.ArkUI';
import deviceInfo from '@ohos.deviceInfo';
import commonData, { EarthquakeSource } from '../data/CommonData';
import { bundleManager } from '@kit.AbilityKit';
import { EARTHQUAKE_EMITTER_CANCEL_MSG, FONT_COLOR } from '../utils/Constants';

const TAG = 'WarningDialogExample';
let outputAudioDeviceDescriptor: audio.AudioDeviceDescriptors = [{
  deviceRole: audio.DeviceRole.OUTPUT_DEVICE,
  deviceType: audio.DeviceType.SPEAKER,
  id: 1,
  name: '',
  address: '',
  sampleRates: [44100],
  channelCounts: [2],
  channelMasks: [0],
  networkId: audio.LOCAL_NETWORK_ID,
  interruptGroupId: 1,
  volumeGroupId: 1,
  displayName: '',
}];

let innerEventCancel: emitter.InnerEvent = {
  eventId: EARTHQUAKE_EMITTER_CANCEL_MSG
};

@CustomDialog
export struct WarningDialogExample {
  @Link distance: number
  @Link countDown: number
  @Link location: string
  @Link magnitude: number
  @Link intensity: number
  @Link feeling: Resource
  @Link feelingTitle: Resource
  @Link backColor: Resource
  @Link fontColor: Resource
  @Link signature: string
  @Link state: number
  @Link isNewFoldPhoneExternalScreen: boolean;
  private readyTimeoutId: number = 0;
  private didiTimeoutId: number = 0;
  jumpToInfo: () => void = () => {
  }
  jumpToEdit: () => void = () => {
  }
  setVolumeBack: () => void = () => {
  }
  private mediaPlayer: IMediaPlayer = new IMediaPlayer(getContext(this), audio.StreamUsage.STREAM_USAGE_ALARM)
  private textPlayer: TextPlayer = new TextPlayer(0, '');
  private audioManager: audio.AudioManager = audio.getAudioManager()
  @State private visible1: Visibility = Visibility.Visible
  @State private visible2: Visibility = Visibility.None
  private source: number | undefined = AppStorage.get<number>('source');
  @State private stateText: Resource =
    AppStorage.get<number>('source') ? $r('app.string.earthquake_about_to_arrive') :
    $r('app.string.EarthquakeWarningTitle1')
  private stateText1: Resource = $r('app.string.earthquake_feeling_reminder_1')
  private closeButtonState: string = 'countdown'
  private subColor: string = '#f54327'
  private dividerColor: Resource = $r('sys.color.ohos_id_color_list_separator_transparent')
  private fontColor2: Resource = $r('sys.color.ohos_id_color_text_secondary_contrary')
  private countDown2: number = this.countDown.valueOf()
  private wave: Resource = $r('app.media.ic_earthquakewave')
  private quakeCenter = getContext().resourceManager.
  getPluralStringValueSync($r('app.plural.EarthquakeWarningTitle2').id, this.distance)
  private countDownSecond = getContext().resourceManager.
  getPluralStringValueSync($r('app.plural.Earthquake_second').id, this.countDown).replace('' + this.countDown, '')
  @State defaultDisplayValue: boolean = false;
  public deviceTypeInfo = deviceInfo.deviceType;
  private numberArray: string[] = ['one.mp3', 'two.mp3', 'three.mp3', 'four.mp3',
    'five.mp3', 'six.mp3', 'seven.mp3', 'eight.mp3', 'nine.mp3'];
  public displayChangeCallback: Callback<number> = (data: number) => {
    try {
      let displayInfo = display.getDefaultDisplaySync();
      let isDirectionRow =
        displayInfo.orientation === commonData.int.DEVICE_DISPLAY_ROW ||
          displayInfo.orientation === commonData.int.DEVICE_DISPLAY_ROW_REVERSE
      this.defaultDisplayValue = isDirectionRow;
    } catch (e) {
      LogUtils.e(TAG, 'displayChangeCallback error:' + JSON.stringify(e));
    }
  }
  public finishTime: number = (this.countDown ? this.countDown : 0) * 1000 + systemDateTime.getTime()
  scroller: Scroller = new Scroller();

  controller: CustomDialogController = new CustomDialogController({
    builder: WarningDialogExample({
      distance: $distance,
      countDown: $countDown,
      location: $location,
      magnitude: $magnitude,
      intensity: $intensity,
      feeling: $feeling,
      feelingTitle: $feelingTitle,
      backColor: $backColor,
      fontColor: $fontColor,
      signature: $signature,
      state: $state,
      isNewFoldPhoneExternalScreen: $isNewFoldPhoneExternalScreen,
    }),
    showInSubWindow: true,
  })

  private canOpenLink(link: string): boolean {
    if (!link) {
      LogUtils.e(TAG, `canOpenLink failed, package name is empty.`);
      return false;
    }
    try {
      return bundleManager.canOpenLink(link);
    } catch (err) {
      LogUtils.e(TAG, `canOpenLink failed: ${err?.message}.`);
    }
    return false;
  }

  private showStatusBar(isShow: boolean): void {
    try {
      let getCtx = EmergencyGlobalContextHelper.getContext();
      let windowStage = getCtx?.getValue<window.WindowStage>(Constants.EMERGENCY_CALL_EARTHQUAKE_WINDOW_STAGE);
      let win: window.Window = windowStage?.getMainWindowSync();
      if (!win) {
        LogUtils.i(TAG, 'get window failed');
      }
      if (isShow) {
        win.setWindowSystemBarProperties({
          statusBarContentColor: FONT_COLOR.WHITE
        });
      } else {
        win.setWindowSystemBarProperties({
          statusBarContentColor: FONT_COLOR.BLACK
        });
      }
    } catch (e) {
      LogUtils.i(TAG, 'Failed to set window system bar');
    }
  }

  private async openDeeplink(want: Want, isValidate?: boolean, isOpenAppstore?: boolean): Promise<boolean> {
    return new Promise((reject: Function) => {
      try {
        let validateResult: boolean = true;
        if (isValidate) {
          validateResult = this.canOpenLink(String(want?.uri));
        }
        if (!validateResult) {
          if (isOpenAppstore) {
            promptAction.showToast({
              message: $r('app.string.earthquake_shelter_setting_dialog'),
              duration: 2500
            });
            reject(LogUtils.e(TAG, 'The app is not installed or the deeplink is unavailable.'))
          }
        }
        let context = getContext() as common.UIAbilityContext;
        context.startAbility(want).catch((e: Error) => {
          LogUtils.e(TAG, `Open deeplink failed: ${e}`);
        })
      } catch (e) {
        LogUtils.e(TAG, `Open deeplink failed: ${e}`);
      }
    });
  }

  async isScreenUnlock(): Promise<boolean> {
    if (screenLock.isLocked()) {
      try {
        const unlocked = await screenLock.unlock();
        if (!unlocked) {
          LogUtils.i(TAG, 'Screen Lock not unlock.');
          return false;
        }
      } catch (e) {
        LogUtils.i(TAG, 'Screen unLock error.');
        return false;
      }
    }
    return true;
  }

  async openMap() {
    try {
      let context = getContext(this) as common.UIAbilityContext;
      let petalMapWant: Want = {
        bundleName: 'com.ohos.maps.app',
        uri: 'maps://textSearch',
        abilityName: 'EntryAbility',
        parameters: {
          'ability.params.backToOtherMissionStack': true,
          linkSource: 'com.ohos.emergencycommunication',
          destinationName: context.resourceManager
            .getStringSync($r('app.string.list_learn_about_emergency_shelters_title').id),
        }

      }
      this.openDeeplink(petalMapWant, true, true)
      LogUtils.i(TAG, `explicit start ability succeed`)
    } catch (error) {
      LogUtils.i(TAG, `explicit start ability failed with ${error.code}`)
    }
  }

  async ready(): Promise<void> {
    if (this.state === 1) {
      this.visible1 = Visibility.None
      this.visible2 = Visibility.Visible
      this.stateText = this.source === EarthquakeSource.EARTHQUAKE_NORMAL_SOURCE ? $r('app.string.earthquake_arrived') :
      $r('app.string.EarthquakeWarningTitle1_2')
      this.closeButtonState = 'static'
    } else {
      if (this.intensity >= 3 && this.intensity < 5) {
        await this.textPlayer.ttsPlaySync(this.countDown.toString())
        await this.mediaPlayer.doPlaySync('di.mp3')
        await this.playEarthAlam('di.mp3');
      } else if (this.intensity >= 5) {
        await this.playEarthAlam('didi.mp3');
      } else { // intensity 小于3 do nothing
        return;
      }
    }
    this.playWuWarning();
  }

  private turnWindowAlwaysOn() {
    try {
      let getCtx = EmergencyGlobalContextHelper.getContext();
      let windowStage = getCtx.getValue<window.WindowStage>(Constants.EMERGENCY_CALL_EARTHQUAKE_WINDOW_STAGE);
      windowStage.setShowOnLockScreen(true);
      if (windowStage) {
        let window = windowStage.getMainWindowSync();
        window.setWakeUpScreen(true);
        window.setWindowBrightness(1.0);
        window.showWindow();
        if (window) {
          window.setWindowKeepScreenOn(true, (err: BusinessError) => {
            const errCode: number = err.code;
            if (errCode) {
              LogUtils.i(TAG, `Failed to set the screen. Cause code: ${err.code}`);
              return;
            }
            LogUtils.i(TAG, 'Succeeded in setting the screen to be on.');
          });
        }
      }
    } catch (e) {
      LogUtils.e(TAG, 'aboveScreen: ' + JSON.stringify(e));
    }
  }

  private playWuWarning() {
    let numCount = 0;
    let wuCount = 0;
    let timeoutID1 = setInterval(() => {
      numCount++;
      if (numCount % 2 === 1 && this.state === 1) {
        wuCount++;
        if (this.intensity >= 5.0) {
          this.mediaPlayer.doPlay('wu.mp3');
        }
      }
      if (wuCount >= 5) {
        clearInterval(timeoutID1);
        this.turnOffAlwaysOn();
      }
    }, 1000);
  }

  private turnOffAlwaysOn() {
    try {
      let getCtx = EmergencyGlobalContextHelper.getContext();
      let windowStage = getCtx.getValue<window.WindowStage>(Constants.EMERGENCY_CALL_EARTHQUAKE_WINDOW_STAGE);
      if (windowStage) {
        let window = windowStage.getMainWindowSync();
        if (window) {
          window.setWindowKeepScreenOn(false, (err: BusinessError) => {
            const errCode: number = err.code;
            if (errCode) {
              LogUtils.i(TAG, `Failed to set the screen. Cause code: ${err.code}`);
              return;
            }
            LogUtils.i(TAG, 'Succeeded in setting the screen to be off.');
          });
        }
      }
    } catch (e) {
      LogUtils.e(TAG, 'aboveScreen: ' + JSON.stringify(e));
    }
  }

  // 1. 播放倒计时使用的是TextToSpeechEngine
  // 2. 播放didi 或者di 使用的是 avplay 。 1和 2不能同时播放，需要等一个播放完播放另外一个
  private async playEarthAlam(alamDi: string) {
    LogUtils.i(TAG, 'playEarthAlam');
    if (this.countDown >= 1) {
      if (this.countDown !== 0) {
        let nowCountDown = (this.finishTime - systemDateTime.getTime()) / 1000;
        LogUtils.i(TAG, 'dialog play di NowCountDown :' + nowCountDown);
        let newCount = nowCountDown > 0 ? Math.round(nowCountDown) : 0;
        if (this.countDown !== newCount) {
          this.countDown = nowCountDown > 0 ? Math.round(nowCountDown) : 0;
        }
      }
      let count = 12; // 10秒倒计时前的一个数字
      if (this.countDown >= count) {
        await this.textPlayer.ttsPlaySync(this.countDown.toString());
        await this.mediaPlayer.doPlaySync(alamDi);
        await this.playEarthAlam(alamDi);
      } else if (this.countDown > 0 && this.countDown < count) {
        if (this.countDown === 11) {
          await this.textPlayer.ttsPlaySync(this.countDown.toString());
          setTimeout(async () => {
            await this.playEarthAlam(alamDi);
          }, 100);
          return;
        }
        this.mediaPlayer.doPlayThread(alamDi);
        this.textPlayer.ttsPlaySyncOneSecond(this.countDown.toString());
        this.didiTimeoutId = setInterval(() => {
          this.mediaPlayer.doPlayThread(alamDi);
          let number = this.getNumberFile(this.countDown);
          LogUtils.i(TAG, 'playEarthAlam NowCountDown :' + number);
          if (number != '') {
            this.mediaPlayer.doPlayThread(number, 0);
          }
          if (this.countDown <= 1) {
            clearInterval(this.didiTimeoutId);
          }
        }, 1000);
      } else if (this.countDown === 0) {
        await this.textPlayer.ttsPlaySyncOneSecond(this.countDown.toString());
      } else {
        LogUtils.e(TAG, 'playEarthAlam countDown is <= 0');
      }
    } else {
      this.state = 1;
      this.visible1 = Visibility.None;
      this.visible2 = Visibility.Visible;
      this.stateText =
        this.source === EarthquakeSource.EARTHQUAKE_NORMAL_SOURCE ? $r('app.string.earthquake_arrived') :
        $r('app.string.EarthquakeWarningTitle1_2');
    }
  }

  private getNumberFile(countDown: number): string {
    if (countDown > 10) {
      return '';
    }
    return this.numberArray[countDown - 1]
  }

  aboutToAppear() {
    try {
      let displayInfo = display.getDefaultDisplaySync();
      this.defaultDisplayValue =
        displayInfo.orientation === commonData.int.DEVICE_DISPLAY_ROW ||
          displayInfo.orientation === commonData.int.DEVICE_DISPLAY_ROW_REVERSE;
    } catch (e) {
      LogUtils.e(TAG, 'getDefaultDisplaySync error: ' + JSON.stringify(e));
    }
    try {
      display.on('change', this.displayChangeCallback);
    } catch (e) {
      LogUtils.e(TAG, 'Register the callback for display changes error: ' + JSON.stringify(e));
    }
    if (this.intensity < 3.0) {
      this.wave = $r('app.media.ic_wave_blue')
      this.subColor = '#1B64F5'
      this.dividerColor = $r('sys.color.ohos_id_color_list_separator_transparent')
      this.fontColor2 = $r('sys.color.ohos_id_color_text_secondary_contrary')
    } else if (this.intensity >= 3.0 && this.intensity < 5.0) {
      this.subColor = '#F5D431'
      this.dividerColor = $r('sys.color.ohos_id_color_list_separator')
      this.fontColor2 = $r('sys.color.ohos_id_color_text_secondary')
    } else if (this.intensity >= 5.0 && this.intensity < 7.0) {
      this.subColor = '#F47527'
      this.dividerColor = $r('sys.color.ohos_id_color_list_separator_transparent')
      this.fontColor2 = $r('sys.color.ohos_id_color_text_secondary_contrary')
    } else if (this.intensity >= 7.0) {
      this.subColor = '#F54327'
      this.dividerColor = $r('sys.color.ohos_id_color_list_separator_transparent')
      this.fontColor2 = $r('sys.color.ohos_id_color_text_secondary_contrary')
    }
    if (this.countDown <= 0 || this.state === 1) {
      this.state = 1
      this.visible1 = Visibility.None
      this.visible2 = Visibility.Visible
      this.stateText = this.source === EarthquakeSource.EARTHQUAKE_NORMAL_SOURCE ? $r('app.string.earthquake_arrived') :
        $r('app.string.EarthquakeWarningTitle1_2')
      this.closeButtonState = 'static'
    }
    // 收到取消地震的消息
    emitter.on(innerEventCancel, async (data) => {
      LogUtils.i(TAG, 'emitter.on innerEventCancel');
      this.onCancel();
    });
    this.showStatusBar(true);
    this.playAlarmVideo();
  }

  private playAlarmVideo() {
    this.turnWindowAlwaysOn();
    this.mediaPlayer.setActivateAudioSession();
    if (this.intensity >= 3) {
      this.mediaPlayer.doPlay('dingdong.mp3');
      setTimeout(() => {
        this.mediaPlayer.doPlay('earthquake_alarm.mp3');
      }, 1500);
    }
    let timeoutID = setInterval(() => {
      if (this.countDown === 0) {
        this.state = 1;
        this.visible1 = Visibility.None;
        this.visible2 = Visibility.Visible;
        this.stateText =
          this.source === EarthquakeSource.EARTHQUAKE_NORMAL_SOURCE ? $r('app.string.earthquake_arrived') :
          $r('app.string.EarthquakeWarningTitle1_2');
        this.closeButtonState = 'static';
        clearInterval(timeoutID);
      }
      if (this.countDown !== 0) {
        let nowCountDown = (this.finishTime - systemDateTime.getTime()) / 1000
        let newCount = nowCountDown > 0 ? Math.round(nowCountDown) : 0
        if (this.countDown !== newCount) {
          this.countDown = nowCountDown > 0 ? Math.round(nowCountDown) : 0
        }
        LogUtils.i(TAG, `dialog play dingdong nowCountDown: ${nowCountDown} ,countDown: ${this.countDown}`);
      }
    }, 100);
    this.readyTimeoutId = setTimeout(() => {
      this.ready();
    }, 2500);
  }

  aboutToDisappear(): void {
    try {
      if (this.readyTimeoutId > 0) {
        clearTimeout(this.readyTimeoutId);
      }
      if (this.didiTimeoutId > 0) {
        clearInterval(this.didiTimeoutId);
      }
      this.mediaPlayer.deactivateAudioSession();
      display.off('change', this.displayChangeCallback);
    } catch (e) {
      LogUtils.i(TAG, 'display off change failed, error:' + JSON.stringify(e));
    }
    this.showStatusBar(false);
  }

  onCancel() {
    this.controller.close();
    setTimeout(() => {
      this.countDown = 0;
      this.mediaPlayer.release();
      this.textPlayer.shutdown();
    }, 150)
    this.setVolumeBack();
  }

  build() {
    GridRow({
      columns: { xs: 2, sm: 4, md: 8, lg: this.defaultDisplayValue ? 12 : 8 } }) {
      GridCol({
        span: { xs: 2, sm: 4, md: 6, lg: this.defaultDisplayValue ? 8 : 6, },
        offset: { xs: 0, sm: 0, md: 1, lg: this.defaultDisplayValue ? 2 : 1, }
      }) {
        Stack({ alignContent: Alignment.Bottom }) {
          Scroll(this.scroller) {
            Column() {
              Column() {
                if (!this.isNewFoldPhoneExternalScreen) {
                  Blank().height(38.857142857142854)
                }
                Column() {
                  Column() {
                    Flex() {
                      Column() {
                        Text(this.stateText)
                          .fontSize(this.isNewFoldPhoneExternalScreen ? $r('sys.float.ohos_id_text_size_headline9') :
                          $r('sys.float.ohos_id_text_size_headline8'))
                          .fontColor(this.fontColor)
                          .width(158)// 个别语言显示长度较长，需要增加宽度
                          .lineHeight(27)
                          .fontWeight(FontWeight.Medium)
                          .maxFontScale(1)
                        Text(this.feelingTitle)
                          .fontSize(this.isNewFoldPhoneExternalScreen ? $r('sys.float.ohos_id_text_size_headline9') :
                          $r('sys.float.ohos_id_text_size_headline8'))
                          .fontColor(this.fontColor)
                          .width(158)// 个别语言显示长度较长，需要增加宽度
                          .lineHeight(27)
                          .fontWeight(FontWeight.Medium)
                          .maxFontScale(1)
                          .visibility(this.source ? Visibility.Visible : Visibility.None)
                        Text(this.quakeCenter)
                          .margin({ top: 14, bottom:22})
                          .fontColor(this.fontColor)
                          .width(this.isNewFoldPhoneExternalScreen ? 200 : 220)
                          .fontSize($r('sys.float.ohos_id_text_size_body1'))
                          .maxFontScale(1)
                      }
                      .alignItems(HorizontalAlign.Start)
                      .margin({ start: LengthMetrics.vp(22), top: LengthMetrics.vp(22) })

                      Column() {
                        Column() {
                          Image(this.wave)
                            .height(203)
                            .width(203)
                            .offset({ start: LengthMetrics.vp(43), top: LengthMetrics.vp(-48) })
                        }
                        .visibility(this.visible2)
                        .layoutWeight(1)
                        .alignItems(HorizontalAlign.End)
                        .width('100%')
                        .height('100%')

                        Column() {
                          Text('' + this.countDown.toFixed(0))
                            .fontSize(this.isNewFoldPhoneExternalScreen ? $r('sys.float.ohos_id_text_size_headline4') :
                            $r('sys.float.ohos_id_text_size_headline4'))
                            .fontColor(this.fontColor)
                            .fontWeight(FontWeight.Medium)
                            .lineHeight(80)
                            .maxFontScale(1)
                          Text(this.countDownSecond)
                            .fontColor(this.fontColor)
                            .fontSize($r('sys.float.ohos_id_text_size_body1'))
                            .lineHeight(21)
                            .maxFontScale(1)
                        }
                        .visibility(this.visible1)
                        .padding({ left: this.isNewFoldPhoneExternalScreen ? 16 : 35, top: 9,
                          right: this.isNewFoldPhoneExternalScreen ? 18 : 22 })
                        .alignItems(HorizontalAlign.End)
                        .width('100%')
                        .height('100%')
                      }.height(131)
                    }.height('auto')

                    Flex({
                      alignContent: FlexAlign.SpaceBetween,
                      alignItems: ItemAlign.Center,
                      justifyContent: FlexAlign.Center
                    }) {
                      Column() {
                        Text($r('app.string.epicenter_location'))
                          .fontSize($r('sys.float.ohos_id_text_size_body3'))
                          .fontColor(this.fontColor2)
                          .maxFontScale(1)
                        Text(this.location)
                          .margin({ top: 4, left: 8, right: 8 })
                          .fontColor(this.fontColor)
                          .fontWeight(FontWeight.Medium)
                          .fontSize($r('sys.float.ohos_id_text_size_body1'))
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .maxLines(2)
                          .textAlign(TextAlign.Center)
                          .maxFontScale(1)
                      }.width('33%')

                      Divider()
                        .strokeWidth('1px')
                        .color(this.dividerColor)
                        .lineCap(LineCapStyle.Round)
                        .height(44)
                        .vertical(true)
                      Column() {
                        Text($r('app.string.EarthquakeMagnitude'))
                          .fontSize($r('sys.float.ohos_id_text_size_body3'))
                          .fontColor(this.fontColor2)
                          .maxFontScale(1)
                        Text('' + this.magnitude.toFixed(1))
                          .fontWeight(FontWeight.Medium)
                          .margin({ top: 4 })
                          .fontColor(this.fontColor)
                          .maxFontScale(1)
                          .fontSize($r('sys.float.ohos_id_text_size_body1'))
                      }.width('33%')

                      Divider()
                        .strokeWidth('1px')
                        .color(this.dividerColor)
                        .lineCap(LineCapStyle.Round)
                        .height(44)
                        .vertical(true)
                      Column() {
                        Row() {
                          Text($r('app.string.estimated_intensity', String(this.intensity)))
                            .fontSize($r('sys.float.ohos_id_text_size_body3'))
                            .fontColor(this.fontColor2)
                            .maxFontScale(1)
                        }

                        Text(this.feeling)
                          .margin({ top: 4 })
                          .fontColor(this.fontColor)
                          .fontWeight(FontWeight.Medium)
                          .fontSize($r('sys.float.ohos_id_text_size_body1'))
                          .maxFontScale(1)
                          .maxLines(2)
                      }.width('33%')
                    }
                    .backgroundColor(this.subColor)
                    .padding({ left: 2, right: 2, top: 9, bottom: 9 })
                    .constraintSize({ minHeight: 80 })
                    .borderRadius({ bottomLeft: 16, bottomRight: 16})
                  }
                  .backgroundColor(this.backColor)
                  .height('auto')
                  .borderRadius(16)

                  Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
                    Column() {
                      Image($r('app.media.ic_warning_mark'))
                    }.height(24).width(24)

                    Text(this.source === EarthquakeSource.EARTHQUAKE_NORMAL_SOURCE ?
                      $r('app.string.earthquake_warning_info') : $r('app.string.EarthquakeWarningTitle3'))
                      .fontSize(38)
                      .fontSize($r('sys.float.ohos_id_text_size_body2'))
                      .fontColor($r('sys.color.ohos_id_color_primary_dark'))
                      .margin({ start: LengthMetrics.vp(12) })
                      .maxFontScale(1)
                  }
                  .padding({
                    top: 22,
                    bottom: 22,
                    left: 12,
                    right: 12
                  })
                  .borderRadius(20)
                  .backgroundColor('#1affffff')
                  .margin({ top: 12 })

                  Flex({ alignItems: ItemAlign.Start, justifyContent: FlexAlign.Center }) {
                    this.jumpMapButton()

                    this.jumpContactButton()

                    this.emergencyInfoArea()
                  }
                  .padding({
                    left: 4,
                    right: 4,
                    top: 20,
                    bottom: 20
                  })
                  .constraintSize({ minHeight: 120 })
                  .borderRadius(20)
                  .backgroundColor('#1affffff')
                  .margin({ top: 12 })
                  .visibility(this.isNewFoldPhoneExternalScreen ? Visibility.None : this.visible2)
                  if (this.source === EarthquakeSource.EARTHQUAKE_NORMAL_SOURCE) {
                    Text(this.signature)
                      .fontSize($r('sys.float.ohos_id_text_size_body2'))
                      .margin({ top: this.isNewFoldPhoneExternalScreen ? 16 : 15 })
                      .textAlign(TextAlign.Center)
                      .maxFontScale(1)
                      .fontColor($r('sys.color.ohos_id_color_text_secondary_dark'))
                  } else {
                    Text($r('app.string.EarthquakeInfofrom', this.signature))
                      .fontSize($r('sys.float.ohos_id_text_size_body2'))
                      .margin({ top: this.isNewFoldPhoneExternalScreen ? 16 : 15 })
                      .textAlign(TextAlign.Center)
                      .maxFontScale(1)
                      .fontColor($r('sys.color.ohos_id_color_text_secondary_dark'))
                  }
                }.alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
                .layoutWeight(this.isNewFoldPhoneExternalScreen ? 0 : 1)
              }
              .width('100%')
              .height('auto')
              .justifyContent(FlexAlign.Center)
              .padding({ right: 12, left: 12, bottom: 40 })
              .margin({ bottom: this.isNewFoldPhoneExternalScreen? 162 : 0 })
            }
            .width('100%')
          }
          .align(Alignment.Center)
          .edgeEffect(EdgeEffect.Spring)
          .position({ top: 12 })
          .scrollBar(BarState.Off)
          .scrollBarColor('rgba(255, 255, 255, 0.4)')
          .scrollable(ScrollDirection.Vertical)
          .margin({ top: this.isNewFoldPhoneExternalScreen ? 12 : 0 })


          Stack({ alignContent: Alignment.Bottom }) {
            Row() {
            }
            .position({ top: 0 })
            .width('100%')
            .height('100%')
            .linearGradient({
              angle: 180,
              colors: [['rgba(0, 0, 0, 0)', 0], ['rgba(0, 0, 0, 0.6)', 1]]
            })
            .responseRegion({
              x: 0,
              y: 0,
              width: '0%',
              height: '0%'
            });

            this.buildCancelButton();
          }
          .width('100%')
          .height(112)
          .position({ bottom: 0 })
        }
        .width('100%')
      }
    }
  }

  @Builder
  buildCancelButton() {
    Button() {
      SymbolGlyph($r('sys.symbol.xmark'))
        .fontSize(this.isNewFoldPhoneExternalScreen ? '32vp' : $r('app.float.emc_margin_level12'))
        .fontColor(this.isNewFoldPhoneExternalScreen ? [$r('sys.color.icon_on_primary')] :
          [$r('sys.color.ohos_id_color_primary_contrary')])
    }
    .clipShape(new Circle({ width: 56, height: 56 }))
    .backgroundColor($r('sys.color.ohos_id_color_fourth_dark'))
    .backgroundEffect({
      radius: 120,
      saturation: 1.1,
      brightness: 1.0,
      color: '#0CFFFFFF'
    })
    .height(56)
    .width(56)
    .margin({ bottom: this.isNewFoldPhoneExternalScreen ? 32 : 68})
    .onClick(() => {
      this.onCancel()
      if (this.closeButtonState === 'countdown') {
        ReportUtil.getInstance().reportClickCloseButtonBeforeCountdown();
      } else if (this.closeButtonState === 'static') {
        ReportUtil.getInstance().reportClickCloseButtonStatic();
      }
    })
  }

  @Builder
  jumpContactButton() {
    Column() {
      Column() {
        SymbolGlyph($r('sys.symbol.person_fill'))
          .fontSize($r('app.float.emc_margin_level12'))
          .fontColor([$r('sys.color.ohos_id_color_primary_contrary')]);
      }
      .width(56)
      .height(56)
      .backgroundColor($r('sys.color.ohos_id_icon_color_active'))
      .justifyContent(FlexAlign.Center)
      .clipShape(new Circle({ width: 56, height: 56 }));

      Text($r('app.string.emergencyContact'))
        .fontSize($r('sys.float.ohos_id_text_size_body3'))
        .fontColor($r('sys.color.ohos_id_color_primary_dark'))
        .margin({ top: 8 })
        .maxLines(2)
        .textAlign(TextAlign.Center)
        .maxFontScale(1);
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .borderRadius(16)
    .stateStyles({
      pressed: {
        .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
        .opacity(1)
      },
    })
    .onClick(() => {
      this.jumpToEdit();
      this.controller.close();
      setTimeout(() => {
        this.countDown = 0;
        this.mediaPlayer.release();
        this.textPlayer.shutdown();
      }, 150);
      ReportUtil.getInstance().reportClickEmergencyContacts();
    })
  }

  @Builder
  jumpMapButton() {
    Column() {
      Column() {
        SymbolGlyph($r('sys.symbol.emergency_shelter'))
          .fontSize($r('app.float.emc_margin_level12'))
          .fontColor([$r('sys.color.ohos_id_color_primary_contrary')]);
      }
      .width(56)
      .height(56)
      .backgroundColor($r('sys.color.ohos_id_color_palette4'))
      .justifyContent(FlexAlign.Center)
      .clipShape(new Circle({ width: 56, height: 56 }));

      Text($r('app.string.list_learn_about_emergency_shelters_title'))
        .fontSize($r('sys.float.ohos_id_text_size_body3'))
        .fontColor($r('sys.color.ohos_id_color_primary_dark'))
        .margin({ top: 8 })
        .maxLines(2)
        .textAlign(TextAlign.Center)
        .maxFontScale(1);
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .borderRadius(16)
    .stateStyles({
      pressed: {
        .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
        .opacity(1)
      },
    })
    .onClick(async () => {
      if (await this.isScreenUnlock()) {
        this.openMap();
      }
      ReportUtil.getInstance().reportClickEmergencyShelters();
    })
  }

  @Builder
  emergencyInfoArea() {
    Column() {
      Column() {
        Image($r('app.media.ic_emergency_info'))
          .width(24)
          .height(31)
          .fillColor($r('sys.color.ohos_id_color_primary_contrary'));
      }
      .width(56)
      .height(56)
      .backgroundColor($r('sys.color.ohos_id_color_warning'))
      .justifyContent(FlexAlign.Center)
      .clipShape(new Circle({ width: 56, height: 56 }));

      Text($r('app.string.personalEmergencyInfo'))
        .fontSize($r('sys.float.ohos_id_text_size_body3'))
        .fontColor($r('sys.color.ohos_id_color_primary_dark'))
        .maxFontScale(1)
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 8 });
    }.layoutWeight(1).justifyContent(FlexAlign.Center)
    .borderRadius(16)
    .stateStyles({
      pressed: {
        .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
        .opacity(1)
      },
    })
    .onClick(() => {
      this.jumpToInfo();
      this.controller.close();
      setTimeout(() => {
        this.countDown = 0;
        this.mediaPlayer.release();
        this.textPlayer.shutdown();
      }, 150);
      ReportUtil.getInstance().reportClickPersonalInfo();
    })
  }
}

@Entry
@Component
export struct WarningDialogUser {
  @State distance: number = 0
  @State countDown: number = 0
  @State location: string = ''
  @State magnitude: number = 0
  @State intensity: number = 0
  @State feeling: Resource = $r('app.string.EarthquakeFelling1')
  @State backColor: Resource = $r('sys.color.ohos_id_color_palette8');
  @State fontColor: Resource = $r('sys.color.ohos_id_color_text_primary_contrary');
  @State signature: string = ''
  @State state: number = 0
  dialogController: CustomDialogController = new CustomDialogController({
    cancel: () => {
      setTimeout(() => {
        this.countDown = 0
      }, 200)
    },
    builder: WarningDialogExample({
      distance: $distance,
      countDown: $countDown,
      location: $location,
      magnitude: $magnitude,
      intensity: $intensity,
      feeling: $feeling,
      feelingTitle: $feelingTitle,
      backColor: $backColor,
      fontColor: $fontColor,
      signature: $signature,
      state: $state,
      isNewFoldPhoneExternalScreen: $isNewFoldPhoneExternalScreen,
    }),
    autoCancel: false,
    alignment: DialogAlignment.Bottom,
    gridCount: 4,
    showInSubWindow: true,
    customStyle: true,
    maskColor: Color.Black
  })

  private mediaPlayer: IMediaPlayer = new IMediaPlayer(getContext(this))
  private textPlayer: TextPlayer = new TextPlayer(0, '');
  private countDown2: number = this.countDown.valueOf()

  async openDialog() {
    this.mediaPlayer = new IMediaPlayer(getContext(this))
    this.textPlayer = new TextPlayer(0, '');
    this.countDown2 = this.countDown.valueOf()
    if (this.dialogController !== undefined) {
      if (this.intensity < 3.0) {
        setTimeout(() => {
          this.dialogController.open()
        }, (this.countDown2 * 1000 + 2000))
      } else {
        this.dialogController.open()
      }
    }
  }

  build() {
  }
}

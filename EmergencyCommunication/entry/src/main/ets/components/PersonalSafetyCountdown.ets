/**
 * Copyright (c) 2025-2025 Huawei Device Co., Ltd.
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
import { SosEmergencyCallController } from '../control/SosEmergencyCallController';
import SOSEmergencyCallAbility from '../sosemergencycallability/SOSEmergencyCallAbility';
import LogUtils from '../utils/HiLog';
import { ReportUtil } from '../utils/ReportUtil';
import { IMediaPlayer } from '../EmergencyEarthquakeAlarm/IMediaPlayere';
import { Utils } from '../utils/Utils';
import { BusinessError } from '@kit.BasicServicesKit';
import { audio } from '@kit.AudioKit';
import { VibratorUtil } from '../utils/VibratorUtil';
import { display } from '@kit.ArkUI';
import { CAR_ACCIDENT, FALL_DOWN } from '../utils/Constants'
import { PersonalSafetyAccidentType } from '../utils/ClassStruct'

const TAG = 'PersonalSafetyCountdown';
const INIT_COUNT_DOWN_VALUE = 90;
const STRONG_WARN_COUNT_DOWN_VALUE = 30;
const STAGE_ONE_AUDIO_RATIO = 0.8;
const STAGE_TWO_AUDIO_RATIO = 1.0;

@Component
export struct PersonalSafetyCountdown {
  @State countdownSeconds: number = 30;
  onCountdownComplete = (autoTrigger: boolean, sosType: string) => {
  }
  setTimeOutIdOfCountdown = (timeOutIdOfCountdown: number) => {
  }
  exitSos = (isDialogRemind: boolean) => {
  }
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0;
  @StorageLink(SOSEmergencyCallAbility.KEY_TOP_STATUS_BAR_HEIGHT) topStatusBarHeight: number = 0;
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  @State autoSendSmsAndCall: boolean = true;
  @State emergencyCallClicked: number = 0;
  @State minAudioValue: number = -1;
  @State maxAudioValue: number = -1;
  @State nowAudioValue: number = -1;
  @State stageOneAudioValueSet: boolean = false;
  @State stageTwoAudioValueSet: boolean = false;
  @State isPlaying: Boolean = false;
  private mediaPlayer: IMediaPlayer = new IMediaPlayer(getContext(this));
  private accidentMaydayAudio = ''
  @State carAccidentSlidingCircleShow: number = 0;
  @State carAccidentSliderAllowedMove: number = 0;
  @State carAccidentSlidingDeltaOffset: number = 0;
  @State sliderValue: number = 0;
  @State accidentType: PersonalSafetyAccidentType = 'none';
  @State screenHeight: number = 0;
  @State continueCount: Boolean = true;

  public oldMediaVolume: number = 0;
  public oldMuteType: number = 0;
  public oldRingtoneVolume: number = 0;

  async upPlaySosVolume() {
    const groupid: number = audio.DEFAULT_VOLUME_GROUP_ID;
    let audioManager: audio.AudioVolumeGroupManager =
      await audio.getAudioManager().getVolumeManager().getVolumeGroupManager(groupid);

    if (this.maxAudioValue === -1) {
      audioManager.mute(audio.AudioVolumeType.RINGTONE, false);
      audioManager.getMaxVolume(audio.AudioVolumeType.VOICE_ASSISTANT, (err: BusinessError, value: number) => {
        this.maxAudioValue = value;
      });
      audioManager.getVolume(audio.AudioVolumeType.VOICE_ASSISTANT, (err: BusinessError, value: number) => {
        this.nowAudioValue = value;
      });
    }

    audioManager.getVolume(audio.AudioVolumeType.VOICE_ASSISTANT, (err: BusinessError, value: number) => {
      let settingVolume = this.maxAudioValue *
        (this.countdownSeconds > STRONG_WARN_COUNT_DOWN_VALUE ? STAGE_ONE_AUDIO_RATIO : STAGE_TWO_AUDIO_RATIO);
      if (value < settingVolume) {
        audioManager.setVolume(audio.AudioVolumeType.VOICE_ASSISTANT, this.maxAudioValue *
          (this.countdownSeconds > STRONG_WARN_COUNT_DOWN_VALUE ? STAGE_ONE_AUDIO_RATIO : STAGE_TWO_AUDIO_RATIO),
          (err: BusinessError) => {
            if (err) {
              LogUtils.e(TAG, `Failed to set the volume. ${err}`);
              return;
            }
            LogUtils.i(TAG, `volume(${settingVolume}) setting successful.`);
          });
      }
    });
  }

  async restoreSystemVolume() {
    const groupid = audio.DEFAULT_VOLUME_GROUP_ID;
    let audioManager = await audio.getAudioManager().getVolumeManager().getVolumeGroupManager(groupid);
    audioManager.setVolume(audio.AudioVolumeType.VOICE_ASSISTANT, this.nowAudioValue, (err: BusinessError) => {
      if (err) {
        LogUtils.e(TAG, `Failed to restore the volume. ${err}`);
        return;
      }
      LogUtils.i(TAG, `volume(${this.nowAudioValue}) restore successful.`);
    });
  }

  getAccidentHappenTime() {
    const currentTime = new Date();
    const hours = ('0' + currentTime.getHours()).slice(-2)
    const minutes = ('0' + currentTime.getMinutes()).slice(-2)

    return hours + ':' + minutes
  }

  playAccidentSosHelpAudio(type: PersonalSafetyAccidentType) {
    if (!(type === CAR_ACCIDENT || type === FALL_DOWN)) {
      return;
    }

    this.isPlaying = true;
    const onPlayCompleted = () => {
      LogUtils.i(TAG, 'playAccidentSosHelpAudio:onPlayCompleted');
      this.isPlaying = false;
    }
    this.mediaPlayer.doPlay(this.accidentMaydayAudio, onPlayCompleted);
  }

  stopAccidentSosHelpAudio(): void {
    this.isPlaying = false
    this.mediaPlayer.reset();
  }

  @State longVibration: boolean = false;

  countdown() {
    const id = setTimeout(async () => {
      if (this.continueCount === false) {
        return;
      }
      if (this.countdownSeconds > 1) {
        this.countdownSeconds--;
        if (this.countdownSeconds > STRONG_WARN_COUNT_DOWN_VALUE) {
          await SosEmergencyCallController.shakeDeviceOnce();
          if (!this.stageOneAudioValueSet) {
            this.upPlaySosVolume();
            this.stageOneAudioValueSet = true;
          }
        } else if (this.longVibration === false) {
          this.longVibration = true;
          await SosEmergencyCallController.shakeDeviceContinuous(this.countdownSeconds * 1000);
          if (!this.stageTwoAudioValueSet) {
            this.upPlaySosVolume();
            this.stageTwoAudioValueSet = true;
          }
        }
        if (!this.isPlaying) {
          this.playAccidentSosHelpAudio(this.accidentType);
        }
        this.countdown();
      } else {
        this.stopAccidentSosHelpAudio();
        this.restoreSystemVolume();
        this.onCountdownComplete(this.autoSendSmsAndCall, this.accidentType === 'none' ? 'none' : this.accidentType);
      }
    }, 1000);
    this.setTimeOutIdOfCountdown(id);
  }

  async aboutToAppear(): Promise<void> {
    LogUtils.i(TAG, 'aboutToAppear');
    SosEmergencyCallController.getInstance().publishEventToTellPageName('PersonalSafetyCountdown');
    try {
      let displayInfo = display.getDefaultDisplaySync();
      this.screenHeight = px2vp(displayInfo.height);
    } catch (e) {
      LogUtils.e(TAG, `get screen height error: ${JSON.stringify(e)}`);
    }

    if (this.accidentType === CAR_ACCIDENT) {
      this.countdownSeconds = INIT_COUNT_DOWN_VALUE;
    } else if (this.accidentType === FALL_DOWN) {
      this.countdownSeconds = INIT_COUNT_DOWN_VALUE;
    }

    await SosEmergencyCallController.shakeDeviceOnce();
    this.countdown();
    if (this.accidentType === CAR_ACCIDENT) {
      this.accidentMaydayAudio = Utils.getPersonalSafetySosNoticeAudioFileName(CAR_ACCIDENT);
    } else if (this.accidentType === FALL_DOWN) {
      this.accidentMaydayAudio = Utils.getPersonalSafetySosNoticeAudioFileName(FALL_DOWN);
    }
  }

  @Builder
  renderTitleArea() {
    Column() {
      Text($r('app.string.warnLink'))// 车祸求助标题
        .textAlign(TextAlign.Center)
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Bold)
        .fontSize(30)
        .lineHeight(35)
        .fontColor($r('app.color.start_window_background'))
        .maxLines(1)
        .maxFontScale(1)
        .width('100%')
        .height('100%')
    }
    .height(64)
    .padding({
      top: '12vp',
      bottom: '12vp',
    })
    .margin({
      top: '92vp',
      left: '16vp',
      right: '16vp',
    })
  }

  @Builder
  renderNoticeArea(type: PersonalSafetyAccidentType) {
    Column() {
      Text(type == CAR_ACCIDENT ? ($r('app.string.car_accident_trigger_prompt', this.getAccidentHappenTime())) :
        (type === FALL_DOWN ? ($r('app.string.fall_down_trigger_prompt', this.getAccidentHappenTime())) :
          'none'))
        .textAlign(TextAlign.Center)
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .fontSize(16)
        .lineHeight(19)
        .fontColor($r('app.color.emc_font_on_secondary'))
        .width('100%')
        .height('100%')
    }
    .height(42)
    .margin({
      top: '8vp',
      left: '16vp',
      right: '16vp'
    })
  }

  @Builder
  renderCountDownCircleArea() {
    Stack({ alignContent: Alignment.Center }) {
      Circle({
        width: '128vp',
        height: '128vp'
      })
        .fill($r('app.color.emc_warning'));

      Text(String(this.countdownSeconds))
        .fontFamily('HarmonyHeiTi')
        .fontWeight(600)
        .fontSize(72)
        .lineHeight(84)
        .fontColor($r('app.color.start_window_background'))
        .maxFontScale(1)
        .margin({
          top: 16,
          bottom: 16,
          left: 21.5,
          right: 21.5,
        })
    }
    .width('128vp')
    .height('128vp')
    .margin({
      top: (this.screenHeight - 128) / 2 - 206,
      left: '116vp',
      right: '116vp',
      bottom: (this.screenHeight - 128) / 2 - 190,
    })
  }

  @Builder
  renderAccessEmergencyCallArea() {
    Stack() {
      Button()
        .width('calc(100% - 32vp)')
        .height('100%')
        .backgroundColor($r('app.color.emc_warning'))

      Text($r('app.string.emergencyCall'))
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Medium)
        .fontSize(16)
        .lineHeight(19)
        .fontColor($r('app.color.start_window_background'))
        .maxFontScale(1)
        .margin({
          top: 9.5,
          bottom: 9.5,
          left: 120,
          right: 120
        })
    }
    .width('100%')
    .height(40)
    .onClick(() => {
      this.countdownSeconds = 0;
      this.continueCount = false;
      this.autoSendSmsAndCall = false;
      this.stopAccidentSosHelpAudio();
      VibratorUtil.stopAllVibration();
      this.onCountdownComplete(this.autoSendSmsAndCall, this.accidentType === 'none' ? 'none' : this.accidentType);
    })
  }

  @Builder
  renderCancelArea() {
    // 取消按钮+文字
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontColor([$r('sys.color.icon_on_primary')])
          .fontSize($r('app.float.emc_widthLevel14'))
          .fontWeight(FontWeight.Medium)
          .align(Alignment.Center)
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .width('64vp')
      .height('64vp')
      .margin({
        left: '144vp',
        right: '144vp',
      })
      .borderRadius(40)
      .backgroundEffect({
        radius: 81.55,
        saturation: 1.1,
        brightness: 1.0,
        color: '#33ffffff'
      })
      .onTouch(e => {
        e.stopPropagation();
      })
      .onClick((e) => {
        LogUtils.i('SosButton', 'onIconClick')
        SosEmergencyCallController.getInstance().publishEventToTellPageName('None');
        this.exitSos(false);
      })

      Column()
        .height('4vp')

      Column() {
        Text($r('app.string.CANCEL'))
          .textAlign(TextAlign.Center)
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Regular)
          .fontSize(14)
          .lineHeight(16)
          .fontColor('#99ffffff')
          .maxFontScale(1)
      }
      .justifyContent(FlexAlign.Center)
      .height('19vp')
      .margin({
        left: '16vp',
        right: '16vp',
      })
    }
    .height(19 + 4 + 64)
    .margin({
      top: '24vp',
      bottom: '41vp'
    })
  }

  build() {
    Column() {
        this.renderTitleArea()

        this.renderNoticeArea(this.accidentType)

        this.renderCountDownCircleArea()

        this.renderAccessEmergencyCallArea()

        this.renderCancelArea()
    }
    .height('100%')
    .width('100%')
  }
}
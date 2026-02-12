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
import { SosEmergencyCallController } from '../../control/SosEmergencyCallController';
import SOSEmergencyCallAbility, {
  ABILITY_STATE_KEY,
  ABILITY_STATE_ON_BACKGROUND
} from '../../sosemergencycallability/SOSEmergencyCallAbility';
import { ContactListStruct } from '../../utils/ClassStruct';
import LogUtils from '../../utils/HiLog';
import { SosButton } from '../../pages/SosEmergencyCall';
import { ReportUtil } from '../../utils/ReportUtil';
import { SOS_EXIT_IN_COUNT_DOWN } from '../../utils/Constants';
import { formatNumberByLanguage } from '../../utils/CommonFunction';

const TAG = 'SosCountdown';

@Component
export struct SosCountdown {
  @Prop autoSendSOSMessageSwitchState: boolean;
  @State countdownSeconds: number = 3;
  @Prop emergencyContacts: ContactListStruct[];
  onCountdownComplete = () => {
  }
  setTimeOutIdOfCountdown = (timeOutIdOfCountdown: number) => {
  }
  exitSos = (isDialogRemind: boolean) => {
  }
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0;
  @StorageLink(SOSEmergencyCallAbility.KEY_TOP_STATUS_BAR_HEIGHT) topStatusBarHeight: number = 0;
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;

  countdown() {
    const id = setTimeout(async () => {
      if (this.countdownSeconds > 1) {
        this.countdownSeconds--;
        let abilityState = AppStorage.get<string>(ABILITY_STATE_KEY);
        if (abilityState !== ABILITY_STATE_ON_BACKGROUND) { //如果当前界面处于前台则震动
          await SosEmergencyCallController.shakeDeviceOnce();
        }
        this.countdown();
        LogUtils.i(TAG, `countdown: ${this.countdownSeconds} s remaining`);
      } else {
        this.onCountdownComplete();
      }
    }, 1000);
    this.setTimeOutIdOfCountdown(id);
  }

  async aboutToAppear(): Promise<void> {
    LogUtils.i(TAG, 'aboutToAppear');
    SosEmergencyCallController.getInstance().publishEventToTellPageName('SosCountdown');
    await SosEmergencyCallController.shakeDeviceOnce();
    this.countdown();
    // UE report continueClick 5 times to EmergencyPage
    ReportUtil.getInstance().reportContinueClickToEmergency();
  }

  @Builder
  renderCoutDownRedCircle() {
    //Countdown Red Circle
    Stack({ alignContent: Alignment.Center }) {
      Circle({
        width: this.isNewFoldPhoneExternalScreen ? 80 : 128,
        height: this.isNewFoldPhoneExternalScreen ? 80 : 128
      })
        .fill($r('app.color.emc_warning'));
      Text(String(formatNumberByLanguage(this.countdownSeconds)))
        .fontColor($r('sys.color.font_on_primary'))
        .fontSize(this.isNewFoldPhoneExternalScreen ? 48 : 72)
        .maxFontScale(1)
        .fontFamily('HarmonyHeiTi')
        .fontWeight(this.isNewFoldPhoneExternalScreen ? FontWeight.Medium : 600)
        .lineHeight(this.isNewFoldPhoneExternalScreen ? 64 : 96);
    }
    .width('100%')
    .height(this.isNewFoldPhoneExternalScreen ? 'calc(100% - 157vp)' : '100%')
  }

  @Builder
  renderCancelButton() {
    Row() {
      SosButton({
        onButtonClick: (event: ClickEvent) => {
          LogUtils.i(TAG, 'on exit button click');
          SosEmergencyCallController.getInstance().publishEventToTellPageName('None');
          this.exitSos(false);
          // sos 倒计时点击关闭打点
          ReportUtil.getInstance().reportSosClickCancelBtn(SOS_EXIT_IN_COUNT_DOWN);
        },
        buttonImage: $r('sys.symbol.xmark'),
        buttonText: $r('app.string.CANCEL'),
        isSymbol: true,
      })
    }
  }

  @Builder
  renderTitle() {
    //title
    Column() {
      Text($r('app.string.Sos_emergency_title'))
        .fontSize(this.isNewFoldPhoneExternalScreen ? $r('sys.float.Title_M') : $r('sys.float.Title_L'))
        .maxLines(1)
        .maxFontScale(1)
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_on_primary'))
        .lineHeight(this.isNewFoldPhoneExternalScreen ? 32 : 40)
        .padding({
          top: this.isNewFoldPhoneExternalScreen ? 0 : 12,
          bottom: this.isNewFoldPhoneExternalScreen ? 0 : 12
        });

      if (this.autoSendSOSMessageSwitchState && this.emergencyContacts && this.emergencyContacts.length > 0) {
        Text($r('app.string.send_sms_notify_emergency_contact'))
          .fontSize($r('sys.float.Body_L'))
          .maxFontScale(1)
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Regular)
          .fontColor($r('sys.color.font_on_secondary'))
          .lineHeight(21)
          .padding({
            top: this.isNewFoldPhoneExternalScreen ? 0 : 1.5,
            bottom: this.isNewFoldPhoneExternalScreen ? 0 : 1.5,
            left: $r('sys.float.padding_level8'),
            right: $r('sys.float.padding_level8')
          })
          .margin({ top: 8 });
      }
    }
  }

  build() {
    Stack() {
      //Countdown Red Circle
      if (!this.isNewFoldPhoneExternalScreen) {
        this.renderCoutDownRedCircle();
      }

      Column() {
        //title
        this.renderTitle();

        if (this.isNewFoldPhoneExternalScreen) {
          this.renderCoutDownRedCircle();
        }

        //Cancel Button
        this.renderCancelButton();
      }
      .padding({
        top: this.isNewFoldPhoneExternalScreen ? 8 : 56 + this.topStatusBarHeight,
        bottom: this.isNewFoldPhoneExternalScreen ? 11 : 13 + this.bottomRectHeight
      })
      .height('100%')
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.SpaceBetween)
    }
  }
}
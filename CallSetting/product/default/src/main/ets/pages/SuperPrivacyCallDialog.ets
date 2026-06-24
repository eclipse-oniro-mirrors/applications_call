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

import { LogUtils } from '@ohos/common/CommonIndex';
import Want from '@ohos.app.ability.Want';
import { AlertDialog } from '@ohos.arkui.advanced.Dialog';
import { SuperPrivacyEventUtil } from '../common/utils/SuperPrivacyEventUtil';
import { confirmSuperPrivacyDialog, terminalDialogAbility } from '../common/utils/Utils';

const TAG = 'SuperPrivacyCallDialog';

@Entry
@Component
export default struct SuperPrivacyCallDialog {
  @State resPrivacySure: ResourceStr = $r('app.string.disable_super_privacy_and_call');
  @State resPrivacyContent: ResourceStr = $r('app.string.super_privacy_dialog_video_call_summary');
  @State resPrivacyCancel: ResourceStr = $r('app.string.cancel');
  private mIsInCall = false;

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear.');
    let want: Want | undefined = AppStorage.get('want');
    switch (want?.parameters?.dialogReason) {
      case 'SUPER_PRIVACY_MODE':
        let isAnswer = want.parameters?.isAnswer as boolean;
        let videoState = want.parameters?.videoState as number;
        let isFold = want.parameters?.isFold as boolean;
        this.mIsInCall = want.parameters?.isInCall as boolean;
        if (videoState == SuperPrivacyEventUtil.TYPE_VIDEO) {
          this.resPrivacyContent = $r('app.string.super_privacy_dialog_video_call_summary');
        } else {
          this.resPrivacyContent = $r('app.string.super_privacy_dialog_call_summary');
        }
        if (isAnswer) {
          this.resPrivacySure = $r('app.string.disable_super_privacy_and_answer');
        } else {
          this.resPrivacySure = $r('app.string.disable_super_privacy_and_call');
        }
        this.resPrivacyCancel = this.mIsInCall ? $r('app.string.hangUp') : $r('app.string.cancel');
        if (isFold) {
          this.externalSuperPrivacyModeDialog.open()
        } else {
          this.superPrivacyModeDialogController.open();
        }
        break;
      default:
        break;
    }
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear');
    AppStorage.delete('want');
    AppStorage.delete('session');
  }

  onPageShow(): void {
    LogUtils.i(TAG, 'onPageShow.');
  }

  onPageHide(): void {
    LogUtils.i(TAG, 'onPageHide.');
  }

  build() {
  }

  superPrivacyModeDialogController: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      primaryTitle: $r('app.string.super_privacy_dialog_title'),
      content: this.resPrivacyContent,
      primaryButton: {
        value: $r('app.string.cancel'),
        action: () => {
          LogUtils.i(TAG, 'dial openSuperPrivacyModeDialog cancel');
          terminalDialogAbility();
        }
      },
      secondaryButton: {
        value: this.resPrivacySure,
        action: () => {
          LogUtils.i(TAG, 'dial openSuperPrivacyModeDialog confirm');
          confirmSuperPrivacyDialog();
          terminalDialogAbility();
        }
      },
    }),
    autoCancel: false,
    cancel: () => {
      terminalDialogAbility();
      console.info('Closed callbacks');
    }
  })

  externalSuperPrivacyModeDialog: CustomDialogController = new CustomDialogController({
    builder: ExternalSuperPrivacyDialog({
      resPrivacySure: this.resPrivacySure,
      resPrivacyContent: this.resPrivacyContent,
      resPrivacyCancel: this.resPrivacyCancel,
      isInCall: this.mIsInCall
    }),
    autoCancel: false,
    customStyle: true,
    cancel: () => {
      terminalDialogAbility();
      console.info('Closed callbacks');
    }
  })
}

@CustomDialog
struct ExternalSuperPrivacyDialog {
  controller?: CustomDialogController;
  @Prop resPrivacySure: ResourceStr = $r('app.string.disable_super_privacy_and_call');
  @Prop resPrivacyContent: ResourceStr = $r('app.string.super_privacy_dialog_video_call_summary');
  @Prop resPrivacyCancel: ResourceStr = $r('app.string.cancel');
  isInCall: boolean = false;

  @Builder
  private dialogImage() {
    Image($r('app.media.key_shield_fill'))
      .width('24vp')
      .height('24vp')
      .margin({
        top: '20vp'
      })
  }

  @Builder
  private dialogTitle() {
    Text($r('app.string.super_privacy_dialog_title'))
      .fontSize('18vp')
      .lineHeight('24vp')
      .fontFamily('HarmonyHeiTi')
      .fontWeight(FontWeight.Medium)
      .fontColor('#DBFFFFFF')
      .textAlign(TextAlign.Center)
      .width('178vp')
      .margin({
        top: '8vp'
      })
  }

  @Builder
  private dialogContent() {
    Text(this.resPrivacyContent)
      .fontSize('16vp')
      .lineHeight('21.5vp')
      .fontFamily('HarmonyHeiTi')
      .fontWeight(FontWeight.Medium)
      .fontColor('#99FFFFFF')
      .textAlign(TextAlign.Center)
      .width('178vp')
      .margin({
        top: '2vp'
      })
  }

  @Builder
  private confirmButton() {
    Button(this.resPrivacySure)
      .fontFamily('HarmonyHeiTi')
      .fontColor('#5291FF')
      .labelStyle({
        maxLines: 1,
        minFontSize: '13vp',
        maxFontSize: '16vp',
        overflow: TextOverflow.MARQUEE,
        font: {
          weight: FontWeight.Medium
        }
      })
      .width('140vp')
      .height('40vp')
      .backgroundColor('#19FFFFFF')
      .margin({
        top: '4vp'
      })
      .onClick(() => {
        LogUtils.i(TAG, 'external openSuperPrivacyModeDialog confirm');
        if (this.isInCall) {
          SuperPrivacyEventUtil.sendSuperPrivacyModeEvent(SuperPrivacyEventUtil
            .getInCallSuperPrivacyModeEventOptions(false));
        } else {
          confirmSuperPrivacyDialog();
        }
        terminalDialogAbility();
      })
  }

  @Builder
  private hangupOrCancelButton() {
    Button(this.resPrivacyCancel)
      .fontFamily('HarmonyHeiTi')
      .fontColor(this.isInCall ? '#E84026' : '#5291FF')
      .labelStyle({
        maxLines: 1,
        minFontSize: '13vp',
        maxFontSize: '16vp',
        overflow: TextOverflow.MARQUEE,
        font: {
          weight: FontWeight.Medium
        }
      })
      .width('140vp')
      .height('40vp')
      .backgroundColor('#19FFFFFF')
      .margin({
        top: '8vp',
        bottom: '24vp'
      })
      .onClick(() => {
        if (this.isInCall) {
          SuperPrivacyEventUtil.sendSuperPrivacyModeEvent(SuperPrivacyEventUtil
            .getInCallSuperPrivacyModeEventOptions(true));
        }
        LogUtils.i(TAG, 'external openSuperPrivacyModeDialog cancel');
        terminalDialogAbility();
      })
  }

  build() {
    Scroll() {
      Column() {
        this.dialogImage();
        this.dialogTitle();
        this.dialogContent();
        this.confirmButton();
        this.hangupOrCancelButton();
      }
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(Color.Black)
  }
}

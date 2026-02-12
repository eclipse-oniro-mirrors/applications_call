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

import LogUtils from '../common/utils/LogUtils';
import { CustomContentDialog } from '@kit.ArkUI';
import { ReportUtil } from '../common/utils/ReportUtils/ReportUtil';
import {
  DIALOG_CONTINUE_CALL,
  DIALOG_HANG_UP,
  DIALOG_HANG_UP_AND_BLOCKLIST,
  KEY_FOR_DIALOG_ACCOUNTNUMBER,
  KEY_FOR_DIALOG_CALLID,
  KEY_FOR_DIALOG_CALLLISTCOUNT,
  KEY_FOR_DIALOG_FORMATNUMBER
} from '../common/utils/Constants';
import BottomViewModel from '../viewmodel/BottomViewModel';
import { NumberMarkService } from '../model/NumberMarkService';
import call from '@ohos.telephony.call';
import EmptyWindowForDialog from '../common/utils/EmptyWindowForDialog';
import { VibrationUtils } from '../common/utils/VibrationUtils';

const TAG = 'PageForDialog';
const localStorage = LocalStorage.getShared();

@Entry(localStorage)
struct PageForDialog {
  @State timer: number = -1;
  @LocalStorageProp(KEY_FOR_DIALOG_CALLID) callId: number = 0;
  @LocalStorageProp(KEY_FOR_DIALOG_CALLLISTCOUNT) callListCount: number = 0;
  @LocalStorageProp(KEY_FOR_DIALOG_ACCOUNTNUMBER) accountNumber: string = '';
  @LocalStorageProp(KEY_FOR_DIALOG_FORMATNUMBER) formatNumber: string = '';

  private mBottomVM: BottomViewModel = BottomViewModel.getInstance();
  private antiFraudDialog: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      contentBuilder: () => {
        this.buildContent();
      },
      buttons: [
        {
          value: $r('app.string.hangUp'),
          buttonStyle: ButtonStyleMode.EMPHASIZED,
          action: () => {
            LogUtils.i(TAG, `antiFraudDialog hangUp ${this.callListCount} ${this.callId}`);
            ReportUtil.getInstance().reportAntiFraudEvent(DIALOG_HANG_UP);
            this.mBottomVM.hangUpCall(this.callId, this.callListCount);
            EmptyWindowForDialog.getInstance().killDialogContainerWindow();
          }
        },
        {
          value: $r('app.string.anti_fraud_hangup_black'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            LogUtils.i(TAG, `antiFraudDialog anti_fraud_hangup_black ${this.callListCount} ${this.callId}`);
            ReportUtil.getInstance().reportAntiFraudEvent(DIALOG_HANG_UP_AND_BLOCKLIST);
            this.mBottomVM.hangUpCall(this.callId, this.callListCount);
            let numberMarkService: NumberMarkService = new NumberMarkService();
            numberMarkService.addToBlockList(this.accountNumber, this.formatNumber);
            EmptyWindowForDialog.getInstance().killDialogContainerWindow();
          }
        },
        {
          value: $r('app.string.anti_fraud_continue_call'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            LogUtils.i(TAG, 'antiFraudDialog anti_fraud_continue_call');
            ReportUtil.getInstance().reportAntiFraudEvent(DIALOG_CONTINUE_CALL);
            try {
              call.sendCallUiEvent(this.callId, 'EVENT_FRAUD_WARNING_END');
            } catch (error) {
              LogUtils.e(TAG, `sendCallUiEvent failed, message:${error?.message}`);
            }
            EmptyWindowForDialog.getInstance().killDialogContainerWindow();
          }
        }
      ],
    }),
    autoCancel: false,
    onWillDismiss: (action: DismissDialogAction) => {
      LogUtils.i(TAG, `antiFraudDialog action.reason: ${action.reason}`);
    }
  });

  @Builder
  buildContent(): void {
    Column() {
      Image($r('app.media.security_shield'))
        .width('32vp')
        .height('32vp')
      Text($r('app.string.anti_fraud_deceived'))
        .fontSize($r('sys.float.Title_S'))
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .height('56vp')
        .lineHeight('23vp')
      Text($r('app.string.anti_fraud_risk_reminder'))
        .fontSize($r('sys.float.Body_M'))
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .fontColor($r('sys.color.font_primary'))
        .lineHeight('16vp')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
    }.onAppear(() => {
      LogUtils.i(TAG, 'PageForDialog load, open dialog');
      this.antiFraudDialog.open();
      this.timer = setInterval(() => {
        VibrationUtils.getInstance().onceVibrationFail();
      }, 1000);
    }).onDisAppear(() => {
      LogUtils.i(TAG, 'PageForDialog onDisAppear, clear dialog');
      this.antiFraudDialog.close();
      EmptyWindowForDialog.getInstance().killDialogContainerWindow();
      clearInterval(this.timer);
    })
  }
}
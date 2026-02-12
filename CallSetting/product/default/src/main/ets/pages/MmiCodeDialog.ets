/**
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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

import { AlertDialog } from '@ohos.arkui.advanced.Dialog';
import { call } from '@kit.TelephonyKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { UIExtensionContentSession} from '@kit.AbilityKit';
import { AlertType, CustomMmiCodeResult, LogUtils, MmiCodeUtils } from '@ohos/common';
import { CustomContentDialog } from '@kit.ArkUI';

const TAG = 'MmiCodeDialog';

@Entry
@Component
export struct MmiCodeDialog {
  private mmiCodeUtils = MmiCodeUtils.getInstance()
  private slotId: number = -1;
  private inputText: string = '';
  @State content: ResourceStr = '';
  @State title: ResourceStr = '';

  private terminalDialogAbility(): void {
    let session: UIExtensionContentSession | undefined = AppStorage.get('session');
    session?.terminateSelf();
  }

  private mmiSetTimeout() {
    this.mmiCodeUtils.setTimeout(()=>{
      LogUtils.i(TAG, `timeout`);
      try {
        call.off('mmiCodeResult')
      } catch (error) {
        let code = (error as BusinessError).code;
        let message = (error as BusinessError).message;
        LogUtils.e(TAG, `unregister mmiCodeResult failed, error code: ${code}, message: ${message}.`);
      }
      this.content = this.mmiCodeUtils.getInvalidContent();
      this.mmiModeDialogController.open()
    })
  }

  private processMmiResult(customData: CustomMmiCodeResult) {
    if (!customData) {
      LogUtils.i(TAG, 'customData is null');
      return;
    }
    this.mmiCodeUtils.clearTimeout();
    if (this.mmiCodeUtils.isMmiCase(customData)) {
      this.title = this.mmiCodeUtils.getTitle(customData)
      this.content = this.mmiCodeUtils.getContent(customData);
      this.mmiModeDialogController.open()
      return;
    }

    if (this.mmiCodeUtils.isUssdCase(customData)) {
      if (customData.result === AlertType.USSD_FINISH) {
        if (customData.message !== '') {
          this.content = customData.message;
        } else {
          this.content = 'MMI Done';
        }
        this.mmiModeDialogController.open()
      } else if (customData.result === AlertType.USSD_PENDING) {
        this.slotId = customData.action ?? -1;
        this.content = customData.message;
        this.ussdDialogController.open()
      } else if (customData.result === AlertType.USSD_ERROR) {
        this.content = this.mmiCodeUtils.getContent(customData);
        this.mmiModeDialogController.open()
      } else {
      }
    }
  }

  mmiModeDialogController: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      primaryTitle: this.title,
      content: this.content,
      primaryButton: {
        value: $r('[common].string.mmi_gotIt'),
        action: () => {
          LogUtils.i(TAG, 'mmi code dialog cancel');
          this.terminalDialogAbility();
        }
      },
    }),
    autoCancel: false,
  })

  ussdDialogController: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      contentBuilder: () => {
        this.buildUSSDContent();
      },
      buttons: [{ value: $r('[common].string.mmi_cancel'), buttonStyle: ButtonStyleMode.TEXTUAL, action: () => {
        // fixme 调用协议接口
        LogUtils.i(TAG, `closeUnfinishedUssd`);
        call.closeUnfinishedUssd(this.slotId);
        this.terminalDialogAbility();
      } }, { value: $r('[common].string.send'), buttonStyle: ButtonStyleMode.TEXTUAL, action: () => {
        this.mmiSetTimeout();
        LogUtils.i(TAG, `sendUssd length=${this.inputText.length}`);
        this.mmiCodeUtils.sendUssd(this.slotId, this.inputText);
        this.inputText = ''
      } }],
    }),
    autoCancel: false,
  });

  @Builder
  buildUSSDContent(): void {
    Column() {
      Text(this.content)
      TextInput()
        .onChange((value: string)=>{
          this.inputText = value
        })
    }
  }

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear.');
    if (MmiCodeUtils.mmiFeatureDebug) {
      this.processMmiResult(MmiCodeUtils.result);
      return;
    }
    // 设置超时的控制点：迟迟收不到协议侧消息，如用户拨号后和用户点击发送后
    this.mmiSetTimeout();
    try {
      call.on('mmiCodeResult', (data: call.MmiCodeResults) => {
        if (!data) {
          LogUtils.e(TAG, 'data is null');
          return;
        }
        let customData : CustomMmiCodeResult = data as CustomMmiCodeResult
        LogUtils.i(TAG, `callback: data->${JSON.stringify(data)}`);
        LogUtils.i(TAG, `callback: customData->${JSON.stringify(customData)}`);
        this.processMmiResult(customData)
      });
    } catch (error) {
      let code = (error as BusinessError).code;
      let message = (error as BusinessError).message;
      LogUtils.e(TAG, `register mmiCodeResult failed, error code: ${code}, message: ${message}.`);
    }
  }

  aboutToDisappear() {
    LogUtils.i(TAG, 'aboutToDisappear');
    try {
      call.off('mmiCodeResult')
    } catch (error) {
      let code = (error as BusinessError).code;
      let message = (error as BusinessError).message;
      LogUtils.e(TAG, `unregister mmiCodeResult failed, error code: ${code}, message: ${message}.`);
    }
    AppStorage.delete('want');
    AppStorage.delete('session');
  }

  build() {
  }
}

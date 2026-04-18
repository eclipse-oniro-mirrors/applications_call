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

import LogUtils from '../common/utils/LogUtils';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import Want from '@ohos.app.ability.Want';
import { AlertDialog } from '@ohos.arkui.advanced.Dialog';
import Intl from '@ohos.intl';
import I18n from '@ohos.i18n';
import connection from '@ohos.net.connection';
import { StringUtil } from '../common/utils/StringUtil';

const TAG = 'CallFailedDialog';

@Entry
@Component
export default struct CallFailedDialog {
  private session: UIExtensionContentSession | undefined = AppStorage.get('session');
  private chinaTelecomCustomerService: string = '10000';
  slotId: number = -1;

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear.');
    let want: Want | undefined = AppStorage.get('want');
    switch (want?.parameters?.dialogReason) {
      case 'CALL_FAILED_DUE_TO_FDN':
        this.openFdnOnlyDialog();
        break;
      case 'CALL_FAILED_NO_SIM_CARD':
        this.openNoSimCardDialog();
        break;
      case 'CALL_FAILED_NO_SERVICE':
        this.openNoNetworkDialog();
        break;
      case 'CALL_FAILED_CTCARD_NO_IMS':
        this.openNoIMSDialog(want?.parameters?.slotId as number);
        break;
      case 'CALL_FAILED_IN_AIRPLANE_MODE':
        this.openAirplaneModeDialog();
        break;
      default:
        break;
    }
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear');
    AppStorage.delete('want');
    AppStorage.delete('session');
    this.fdnOnlyDialogController = undefined;
    this.noIMSDialogController = undefined;
    this.noNetworkDialogController = undefined;
    this.airplaneModeDialogController = undefined;
    this.noSimCardDialogController = undefined;
  }

  onPageShow(): void {
    LogUtils.i(TAG, 'onPageShow.');
  }

  onPageHide(): void {
    LogUtils.i(TAG, 'onPageHide.');
  }

  build() {}

  exit() {
    this.session?.terminateSelf();
  }

  cancelCallBack() {
    LogUtils.i(TAG, 'cancel callbacks');
    this.exit();
  }

  fdnOnlyDialogController?: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.callFailed_fdn_only'),
      primaryButton: {
        value: $r('app.string.gotIt'),
        action: () => {
          LogUtils.i(TAG, 'Outgoing calls are restricted by FDN.');
          this.exit();
        }
      }
    }),
    autoCancel: false,
    cancel: this.cancelCallBack
  })
  noIMSDialogController?: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.no_cdma_volte_warn_text', StringUtil.simIdFormat(this.slotId + 1),
        this.chinaTelecomCustomerService),
      primaryButton: {
        value: $r('app.string.gotIt'),
        action: () => {
          LogUtils.i(TAG, 'Not registered with mobile network service. Unable to use call services.');
          this.exit();
        }
      }
    }),
    autoCancel: false,
    cancel: this.cancelCallBack
  })
  noNetworkDialogController?: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.mobileNetwork'),
      primaryButton: {
        value: $r('app.string.gotIt'),
        fontColor: $r('sys.color.font_emphasize'),
        action: () => {
          LogUtils.i(TAG, 'has no sim card or no service, clear call');
          this.exit();
        }
      }
    }),
    autoCancel: false,
    cancel: this.cancelCallBack
  })
  noSimCardDialogController?: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.noSimCard'),
      primaryButton: {
        value: $r('app.string.gotIt'),
        fontColor: $r('sys.color.font_emphasize'),
        action: () => {
          LogUtils.i(TAG, 'has no sim card or no service, clear call');
          this.exit();
        }
      }
    }),
    autoCancel: false,
    cancel: this.cancelCallBack
  })
  airplaneModeDialogController?: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.turn_off_airplane_and_calls'),
      primaryButton: {
        value: $r('app.string.cancel'),
        action: () => {
          LogUtils.i(TAG, 'dial openAirplaneModeDialog cancel');
          this.exit();
        }
      },
      secondaryButton: {
        value: $r('app.string.shutDown'),
        action: () => {
          LogUtils.i(TAG, 'dial openAirplaneModeDialog confirm');
          connection.disableAirplaneMode(() => {
            LogUtils.i(TAG, 'disableAirplaneMode');
          });
          this.exit();
        }
      },
    }),
    autoCancel: false,
    cancel: this.cancelCallBack
  })

  openFdnOnlyDialog() {
    LogUtils.i(TAG, 'openFdnOnlyDialog.');
    this.fdnOnlyDialogController?.open();
  }

  openNoIMSDialog(slotId: number) {
    this.slotId = slotId;
    LogUtils.i(TAG, 'openNoIMSDialog.');
    this.noIMSDialogController?.open();
  }

  openAirplaneModeDialog() {
    LogUtils.i(TAG, 'openAirplaneModeDialog.');
    this.airplaneModeDialogController?.open();
  }

  openNoSimCardDialog() {
    LogUtils.i(TAG, 'openNoSimCardDialog.');
    this.noSimCardDialogController?.open();
  }

  openNoNetworkDialog() {
    LogUtils.i(TAG, 'openNoNetworkDialog.');
    this.noNetworkDialogController?.open();
  }
}

export let simIdFormat = (formatNumber: number) => {
  let systemLanguage = I18n.System.getAppPreferredLanguage();
  LogUtils.i(TAG, 'systemLanguage:' + systemLanguage);
  let options: Intl.NumberOptions = { locale: 'Locale' };
  let numberFormat: Intl.NumberFormat = new Intl.NumberFormat(systemLanguage, options);
  return numberFormat.format(formatNumber);
}
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

import Want from '@ohos.app.ability.Want';
import { BusinessError } from '@ohos.base';
import { LogUtils } from '@ohos/common/CommonIndex';
import commonData from '../data/CommonData';
import CallSettingVM from '../viewModel/CallSettingVM';

const TAG = 'PermissionInfoDialog';

/**
 * 权限说明弹框
 */
@CustomDialog
export struct PermissionInfoDialog {
  dialogController?: CustomDialogController;
  // 判断是否使用模态窗口拉起
  @State isFromExternal: boolean = CallSettingVM.getInstance().getIsFromExternal();

  want: Want = {
    'bundleName': commonData.string.CALL_SETTING_BUNDLE_NAME,
    'abilityName': commonData.string.NUMBER_IDENTITY_EXT_ABILITY_NAME,
    'parameters': {
      'ability.want.params.uiExtensionType': 'sys/commonUI',
      'ability.want.params.IsNotifyOccupiedAreaChange': true,
      'type': 'permissionStatement',
      'isFromExternal' : this.isFromExternal
    }
  }

  @Builder
  buildPageContent(): void {
    Column() {
      // 权限说明页面Component
      UIExtensionComponent(this.want)
        .width('100%')
        .height('100%')
        .onError((error: BusinessError) => {
          LogUtils.e(TAG, `UIExtensionComponent onError, code=${JSON.stringify(error)}`);
          this.closeDialog();
        })
        .onRelease((code: number) => {
          LogUtils.i(TAG, `UIExtensionComponent onRelease, code=${JSON.stringify(code)}`);
          this.closeDialog();
        })
    }
    .width('100%')
    .height('100%')
    .clip(true)
  }

  /**
   * 关闭协议弹框
   */
  private closeDialog() {
    if (this.dialogController) {
      LogUtils.i(TAG, 'close privacy dialog');
      this.dialogController.close();
    }
  }

  build() {
    Column() {
      this.buildPageContent();
    }
    .width('100%')
    .height('100%')
  }
}
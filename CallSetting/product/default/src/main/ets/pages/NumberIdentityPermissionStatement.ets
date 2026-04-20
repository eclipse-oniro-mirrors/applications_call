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
import { UIExtensionContentSession } from '@kit.AbilityKit';
import { CustomContentDialog } from '@kit.ArkUI';

const TAG = 'NumberIdentityPermissionStatement';

@Entry
@Component
export default struct NumberIdentityPermissionStatement {
  private session: UIExtensionContentSession = LocalStorage.getShared()
    .get<UIExtensionContentSession>('session') as UIExtensionContentSession;
  permissionDescDlg: CustomDialogController | null = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.number_identity_permission_dialog_title'),
      secondaryTitle: $r('app.string.number_identity_permission_dialog_desc'),
      contentBuilder: () => {
        this.PermissionDescriptionContent()
      },
      buttons: [{
        value: $r('app.string.gotIt'),
        action: () => {
          this.session?.terminateSelf();
        },
      },
      ]
    }),
    alignment: DialogAlignment.Center,
    autoCancel: false,
    backgroundColor: $r('app.color.color_00000000_transparent'),
    maskColor: $r('app.color.color_00000000_transparent'),
    onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
      LogUtils.i(TAG, 'dialog onWillDismiss reason=' + JSON.stringify(dismissDialogAction.reason));
    }
  })

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    this.session?.setWindowBackgroundColor('#00000000');
    this.permissionDescDlg?.open()
  }

  @Builder
  PermissionDescriptionContent() {
    Scroll() {
      Column() {
        Text($r('app.string.number_identity_permission_dialog_name_1'))
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontWeight(FontWeight.Regular)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .lineHeight(21)
          .width('100%')
        Row() {
          Text($r('app.string.number_identity_permission_dialog_purpose_1'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontWeight(FontWeight.Regular)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .lineHeight(19)
            .width('100%')
        }.margin({ top: 2 })
      }
      .width('100%')
    }
    .nestedScroll({scrollForward: NestedScrollMode.PARALLEL, scrollBackward: NestedScrollMode.PARALLEL})
  }

  build() {
  }
}
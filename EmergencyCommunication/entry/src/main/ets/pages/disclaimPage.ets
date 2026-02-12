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

import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import { AlertDialog } from '@ohos.arkui.advanced.Dialog';

const storage: LocalStorage = LocalStorage.getShared();
const COLOR_TRANSPARENT = '#00000000';
@Entry
@Component
struct PermissionPage {
  build() {
    Column() {
      PermissionDefault();
    }
    .width('100%')
    .height('100%')
  }
}
@Component
struct PermissionDefault {
  private session: UIExtensionContentSession | undefined = storage.get<UIExtensionContentSession>('session');
  @StorageProp('curBp') curBp: string = '';
  @StorageProp('ratio') ratio: number = 0;
  @Builder
  PermissionDescriptionContent() {
    Scroll() {
      Column() {
        Text(getContext(this).resourceManager.getPluralStringValueSync($r('app.plural.PermissionDescriptionContent_1')
          .id, 1)).fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontWeight(FontWeight.Regular)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .lineHeight(19)
          .width('100%')
        Text($r('app.string.EmergencyWarningSettings_4'))
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontWeight(FontWeight.Regular)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .lineHeight(21)
          .margin({ top: 16 })
          .width('100%')
        Row() {
          Text($r('app.string.PermissionDescriptionContent_3'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontWeight(FontWeight.Regular)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .lineHeight(19)
            .width('100%')
        }.margin({ top: 2 })
      }
      .width('100%')
    }
  }
  disclaimerDialog: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      primaryTitle: $r('app.string.define_disclaimer'),
      content: $r('app.string.Disclaimer_Instructions'),
      primaryButton: {
        value: $r('app.string.permissionConfirm'),
        action: () => {
          this.session?.terminateSelf();
        },
      },
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
  });
  aboutToAppear() {
    this.session?.setWindowBackgroundColor(COLOR_TRANSPARENT);
    this.disclaimerDialog.open();
  }
  build() {
    Column() {
    }
  }
}

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

import web_webview from '@ohos.web.webview';
import LogUtils from '../utils/HiLog';
import { UIExtensionContentSession } from '@kit.AbilityKit';

const storage: LocalStorage = LocalStorage.getShared();
const TAG = 'EmergencyPrivacyStatementOobe';

@Component
export default struct EmergencyPrivacyStatementOobe {
  private readonly session: UIExtensionContentSession | undefined = storage.get<UIExtensionContentSession>('session');
  controller: web_webview.WebviewController = new web_webview.WebviewController();
  @State infoTitle: string = '';
  @State language: string = '';
  @State fileDir: string = '';

  aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear');
    this.language = getContext().resourceManager.getConfigurationSync().locale;
    if (this.language.startsWith('zh_Hans')) {
      this.infoTitle = 'location-privacy-statement-zh_Hans_CN.htm';
    } else if (this.language.startsWith('zh_Hant') && this.language.endsWith('TW')) {
      this.infoTitle = 'location-privacy-statement-zh_Hant_TW.htm';
    } else if (this.language.startsWith('zh_Hant')) {
      this.infoTitle = 'location-privacy-statement-zh_Hant_HK.htm';
    } else if (this.language.startsWith('bo')) {
      this.infoTitle = 'location-privacy-statement-bo_CN.htm';
    } else if (this.language.startsWith('en')) {
      this.infoTitle = 'location-privacy-statement-en_Latn_US.htm';
    } else if (this.language.startsWith('ug')) {
      this.infoTitle = 'location-privacy-statement-ug_CN.htm';
    } else {
      this.infoTitle = 'location-privacy-statement-en_Latn_US.htm';
    }
    LogUtils.i(TAG, 'location-privacy-statement for oobe' + this.language);
    LogUtils.i(TAG, 'location-privacy-statement for oobe this.infoTitle' + this.infoTitle);
  }

  build() {
    NavDestination() {
      Column() {
        Web({
          src: $rawfile(this.infoTitle),
          controller: this.controller
        })
          .width('100%')
          .height('100%')
          .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
          .zoomAccess(false)
          .geolocationAccess(false)
          .domStorageAccess(true)
      }
      .padding({ top: 64 })
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    .onBackPressed(() => {
      if (this.controller?.accessBackward()) {
        this.controller.backward();
      }
      this.session?.terminateSelf();
      return true;
    })
    .padding({})
  }
}

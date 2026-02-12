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
//import { HdsNavDestination, HdsNavDestinationAttribute } from '@kit.UIDesignKit';

const storage: LocalStorage = LocalStorage.getShared();
const TAG = 'PrivacyStatement';

@Component
export default struct PrivacyStatementOobe {
  private readonly session: UIExtensionContentSession | undefined = storage.get<UIExtensionContentSession>('session');
  controller: web_webview.WebviewController = new web_webview.WebviewController();
  @State infoTitle: string = '';
  @State language: string = '';
  @State fileDir: string = '';
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;

  aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear');
    this.language = getContext().resourceManager.getConfigurationSync().locale;
    if (this.language.startsWith('zh_Hans')) {
      this.infoTitle = 'privacy-statement-zh_Hans_CN.htm';
    } else if (this.language.startsWith('zh_Hant') && this.language.endsWith('TW')) {
      this.infoTitle = 'privacy-statement-zh_Hant_TW.htm';
    } else if (this.language.startsWith('zh_Hant')) {
      this.infoTitle = 'privacy-statement-zh_Hant_HK.htm';
    } else if (this.language.startsWith('bo')) {
      this.infoTitle = 'privacy-statement-bo_CN.htm';
    } else if (this.language.startsWith('en')) {
      this.infoTitle = 'privacy-statement-en_Latn_US.htm';
    } else if (this.language.startsWith('ug')) {
      this.infoTitle = 'privacy-statement-ug_CN.htm';
    } else {
      this.infoTitle = 'privacy-statement-en_Latn_US.htm';
    }
  }

  build() {
   /* HdsNavDestination() {
      Column() {
        Web({
          src: $rawfile(this.infoTitle),
          controller: this.controller
        })
          .width('100%')
          .height('100%')
          .zoomAccess(false)
          .geolocationAccess(false)
          .domStorageAccess(true)
          .textZoomRatio(this.fontSizeScale * 100)
      }
      .padding({ top: 64 })
      .width('100%')
      .height('100%')
    }*/
    NavDestination() {
      Column() {
        Web({
          src: $rawfile(this.infoTitle),
          controller: this.controller
        })
          .width('100%')
          .height('100%')
          .zoomAccess(false)
          .geolocationAccess(false)
          .domStorageAccess(true)
          .textZoomRatio(this.fontSizeScale * 100)
      }
      .padding({ top: 64 })
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .width('100%')
    .height('100%')
    .onBackPressed(() => {
      if (this.controller?.accessBackward()) {
        this.controller.backward();
        this.session?.terminateSelf();
        return true;
      } else {
        this.session?.terminateSelf();
        return true;
      }
    })
    .padding({})
  }
}

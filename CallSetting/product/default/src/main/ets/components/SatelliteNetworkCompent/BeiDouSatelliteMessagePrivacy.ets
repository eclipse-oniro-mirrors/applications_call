/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
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

import { LogUtils, TitleParams } from '@ohos/common/CommonIndex';
// import { PafWebViewController } from '@hms-paf/ui-widget-webview-v2';
// import { PafPrivacyStatementV2, PafPrivacyResource } from '@hms-paf/ui-widget-permission-v2';
import { webview } from '@kit.ArkWeb';
import { ConfigurationConstant } from '@kit.AbilityKit';
// import { NavDestination,  HdsNavDestinationAttribute } from '@kit.UIDesignKit';

const TAG = 'BeiDouSatelliteMessagePrivacy';

@Builder
export function BeiDouSatelliteMessagePrivacyLoader(isPrivacyNote: boolean): void {
  BeiDouSatelliteMessagePrivacy({ isPrivacyNote: isPrivacyNote });
}

@Component
export struct BeiDouSatelliteMessagePrivacy {
  @Consume('pathInfos') pathInfos: NavPathStack;
  webviewController: webview.WebviewController = new webview.WebviewController();
  @State userAgreementLink: string = 'resource://rawfile/beidoumessage/userAgreement/terms-';
  @State privacyStatementLink: string = 'resource://rawfile/beidoumessage/privacyStatement/privacy-statement-';
  // pafController: PafWebViewController = new PafWebViewController();
  @State isPrivacyNote: boolean = false;
  @State isNav: boolean = true;
  @State private webViewUrl: string = '';
  @State refreshLanguageCount: number = 0;
  @StorageProp('currentLanguage') @Watch('replaceUrl') currentLanguage: string = '';
  private language: string | undefined = '';
  @StorageProp('currentColorMode') @Watch('isDarkJudge') isDarkMode: boolean = false;
  private blackMode: string = '?bgmode=black';
  // @State pafResource: PafPrivacyResource = new PafPrivacyResource()

  aboutToAppear(): void {
    this.isDarkMode =
      (AppStorage.get('currentColorMode') === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? true : false)
    LogUtils.i(TAG, 'aboutToAppear');
    this.replaceUrl();
  }

  isDarkJudge() {
    this.isDarkMode =
      (AppStorage.get('currentColorMode') === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? true : false)
    this.replaceUrl()
  }

  replaceUrl() {
    LogUtils.i(TAG, 'replaceUrl');
    this.refreshLanguageCount++;
    if (this.isPrivacyNote) {
      this.webViewUrl = this.userAgreementLink;
    } else {
      this.webViewUrl = this.privacyStatementLink;
    }
    this.language = AppStorage.get('currentLanguage');
    if (this.language === undefined || this.language === '') {
      this.language = getContext().resourceManager.getConfigurationSync().locale;
    }
    if (this.language.startsWith('zh_Hans') || this.language.startsWith('zh-Hans')) {
      this.webViewUrl =
        this.isDarkMode ? this.webViewUrl + 'zh-cn.htm' + this.blackMode : this.webViewUrl + 'zh-cn.htm';
    } else if (this.language.startsWith('zh_Hant') || this.language.startsWith('zh-Hant')) {
      if (this.language == 'zh_Hant_TW') {
        this.webViewUrl =
          this.isDarkMode ? this.webViewUrl + 'zh-tw.htm' + this.blackMode : this.webViewUrl + 'zh-tw.htm';
      } else {
        this.webViewUrl =
          this.isDarkMode ? this.webViewUrl + 'zh-hk.htm' + this.blackMode : this.webViewUrl + 'zh-hk.htm'
      }
    } else if (this.language.startsWith('bo_Tibt') || this.language.startsWith('bo-Tibt')) {
      this.webViewUrl =
        this.isDarkMode ? this.webViewUrl + 'bo-cn.htm' + this.blackMode : this.webViewUrl + 'bo-cn.htm';
    } else if (this.language.startsWith('ug_Arab') || this.language.startsWith('ug-Arab')) {
      this.webViewUrl =
        this.isDarkMode ? this.webViewUrl + 'ug-cn.htm' + this.blackMode : this.webViewUrl + 'ug-cn.htm';
    } else {
      this.webViewUrl =
        this.isDarkMode ? this.webViewUrl + 'en-us.htm' + this.blackMode : this.webViewUrl + 'en-us.htm';
    }
    // this.pafResource.url = this.webViewUrl;
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear');
    AppStorage.delete('currentColorMode');
    AppStorage.delete('currentLanguage');
  }

  onBack(): void {
    LogUtils.i(TAG, 'onBack');
    if (this.pathInfos.size() > 0) {
      this.pathInfos.pop();
    }
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          // PafPrivacyStatementV2({
          //   src: this.pafResource,
          //   option: {
          //     isNav: false,
          //     isCustomTitleBar: true,
          //     forceDarkAccess: true
          //   },
          //   controller: this.pafController
          // })
        }
        .layoutWeight(1)
      }
    }
    // .titleBar(TitleParams.PrivatePageTitleParams(true))
    .hideTitleBar(false)
    .padding({ bottom: 29 })
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    .expandSafeArea([SafeAreaType.KEYBOARD])
    // .onBackPressed(() => {
    //   return this.pafController.onBackPress();
    // })
  }
}

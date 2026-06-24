/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { LogUtils } from '@ohos/common/CommonIndex';
import deviceInfo from '@ohos.deviceInfo';
import webView from '@ohos.web.webview';
import * as CallSettingsConstant from '../common/constant/CallSettingsConstant';
import { ability, UIExtensionContentSession } from '@kit.AbilityKit';
import { sim } from '@kit.TelephonyKit';

const TAG = 'CommonPrivacyStatementOOBE';

@Entry
@Component
export default struct CommonPrivacyStatementOOBE {
  @State private privacyStateUrl: string = '';
  @State private webViewUrl: string = '';
  @State private callerBundleName: string | undefined = '';
  private controller: webView.WebviewController = new webView.WebviewController();
  private deviceType: string = deviceInfo.deviceType;
  @StorageProp('currentLanguage') @Watch('replaceUrl') currentLanguage: string = '';
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;

  aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear');
    let privacyType: string | undefined = AppStorage.get('localPrivacyStatement');
    LogUtils.i(TAG, 'privacyType = ' + privacyType);
    switch (privacyType) {
      case 'satellite':
        this.privacyStateUrl = 'satellite_privacy_satement_html/satellite-service-and-privacy-';
        break;
      case 'phone':
        this.privacyStateUrl = sim.getMaxSimCount() !== 0 ? 'phone_privacy_statement_html/privacy-statement-' :
          'phone_pc_privacy_statement_html/privacy-statement-';
        break;
      case 'NumberIdentity':
        this.privacyStateUrl = 'number_identity_html/numberidentity-privacy-statement-';
        break;
      default:
        LogUtils.e(TAG, `privacyType is Invalid.`);
    }
    AppStorage.delete('localPrivacyStatement');
    this.replaceUrl();
    this.callerBundleName = AppStorage.get<string>('callerBundleName');
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear');
  }

  replaceUrl() {
    LogUtils.i(TAG, 'replaceUrl');
    if (this.currentLanguage.startsWith('zh_Hans')) {
      this.privacyStateUrl = this.privacyStateUrl + 'zh-cn.htm';
    } else if (this.currentLanguage.startsWith('zh_Hant')) {
      if (this.currentLanguage == 'zh_Hant_TW') {
        this.privacyStateUrl = this.privacyStateUrl + 'zh-tw.htm';
      } else {
        this.privacyStateUrl = this.privacyStateUrl + 'zh-hk.htm';
      }
    } else if (this.currentLanguage.startsWith('bo_Tibt')) {
      this.privacyStateUrl = this.privacyStateUrl + 'bo-cn.htm';
    } else if (this.currentLanguage.startsWith('ug_Arab')) {
      this.privacyStateUrl = this.privacyStateUrl + 'ug-cn.htm';
    } else {
      this.privacyStateUrl = this.privacyStateUrl + 'en-us.htm';
    }
    this.webViewUrl = this.privacyStateUrl;
    this.privacyStateUrl = '';
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.interactive_click'))
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_xs'))
    .opacity(1)
  }

  @Styles
  normalStyles() {
    .backgroundColor($r('app.color.color_00000000_transparent'))
    .opacity(1)
  }

  onBackPress(): void | boolean {
    LogUtils.i(TAG, 'onBackPress');
    this.terminateSelfWithResult();
    return true;
  }

  terminateSelfWithResult(): void {
    let session: UIExtensionContentSession = LocalStorage.getShared()
      .get<UIExtensionContentSession>('session') as UIExtensionContentSession;
    let parameters: Record<string, string> = {
      'contactObjects': JSON.stringify(false)
    };
    let want: Record<string, Record<string, string>> = {
      'parameters': parameters
    };
    let result: ability.AbilityResult = {
      'resultCode': 0,
      'want': want
    };
    session?.terminateSelfWithResult(result).then((data) => {
      LogUtils.i(TAG, 'terminateSelfCallBack');
    });
  }

  build() {
    Navigation() {
      Column() {
        Web({ src: $rawfile(this.webViewUrl), controller: this.controller })
          .zoomAccess(false)
          .flexGrow(1)
          .verticalScrollBarAccess(true)
          .backgroundColor(Color.Transparent)
          .key('ProtocolView_web')
          .width('100%')
          .fileAccess(false)
          .mixedMode(MixedMode.None)
          .geolocationAccess(false)
          .textZoomRatio(this.fontSizeScale * 100)
      }
    }
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    .padding({
      top: 8,
      bottom: 0
    })
    // .titleMode(HdsNavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .hideBackButton(this.callerBundleName === CallSettingsConstant.PRIVACY_CENTER_BUNDLE_NAME ? false : true)
  }
}

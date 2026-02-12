/**
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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
// import { PafPrivacyResource, PafPrivacyStatementV2 } from '@hms-paf/ui-widget-permission-v2';
// import { PafWebViewController } from '@hms-paf/ui-widget-webview-v2';
import { ability, common, UIExtensionContentSession } from '@kit.AbilityKit';
import { sim } from '@kit.TelephonyKit';

const TAG = 'PhonePrivacyStatement';

@Entry
@Component
export default struct PhonePrivacyStatement {
  private context: common.UIExtensionContext = LocalStorage.getShared()
    .get<common.UIExtensionContext>('context') as common.UIExtensionContext;
  // pafController: PafWebViewController = new PafWebViewController();
  @State isPrivacyNote: boolean = false;
  // @State pafResource: PafPrivacyResource = new PafPrivacyResource();
  @StorageProp('currentColorMode') @Watch('replaceUrl') currentMode: number = 0;
  @StorageProp('currentLanguage') @Watch('replaceUrl') currentLanguage: string = '';
  private protocol: string = sim.getMaxSimCount() !== 0 ? 'phone' : 'phone-pc-hmos';
  private code: string = 'cn';
  private version = sim.getMaxSimCount() !== 0 ? '20240603' : '20241213';
  private prefix: string = '/privacy-statement.htm';

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear.');
    this.replaceUrl();
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear.');
    AppStorage.delete('currentColorMode.');
    AppStorage.delete('currentLanguage.');
  }

  onBack(): void {
    LogUtils.i(TAG, 'onBack.');
    this.terminateSelfWithResult();
  }

  replaceUrl() {
    LogUtils.i(TAG, 'replaceUrl.');
    let privacyStateUrl = this.context?.resourceManager.getStringSync($r('app.string.privacy_state_url').id);
    privacyStateUrl = privacyStateUrl + this.protocol + this.prefix + '?code=' + this.code +
      '&branchid=0' + '&verison=' + this.version + '&bgmode=' + (this.currentMode ? 'white' : 'dark') +
      '&trsp=true' + '&language=' + this.currentLanguage + '&contenttag=default';
    // this.pafResource.url = privacyStateUrl;
  }

  terminateSelfWithResult(): void {
    let session: UIExtensionContentSession = LocalStorage.getShared()
      .get<UIExtensionContentSession>('session') as UIExtensionContentSession;
    let result: ability.AbilityResult = {
      'resultCode': 0
    };
    session?.terminateSelfWithResult(result).then((data) => {
      LogUtils.i(TAG, 'terminateSelfCallBack');
    });
  }

  onBackPress(): void | boolean {
    // let accessBackward = this.pafController.getWebNode()?.getParams()?.controller?.accessBackward();
    // LogUtils.i(TAG, `onBackPressed ${accessBackward}`);
    // if (!accessBackward) {
    //   this.onBack();
    //   return true;
    // }
    // return this.pafController.onBackPress();
  }

  build() {
    Navigation() {
      Column() {
        Row() {
          // PafPrivacyStatementV2({
          //   src: this.pafResource,
          //   option: {
          //     isNav: false,
          //     isCustomTitleBar: true,
          //     forceDarkAccess: true,
          //     navigationEvent: () => {
          //       this.onBack();
          //     }
          //   },
          //   controller: this.pafController
          // })
        }
        .layoutWeight(1)
      }
    }
    // .titleMode(HdsNavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
  }
}

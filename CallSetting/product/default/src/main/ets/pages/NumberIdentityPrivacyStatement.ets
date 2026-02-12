/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import { LogUtils, TitleBarLayout, TitleParams } from '@ohos/common/CommonIndex';
import { ability, common, UIExtensionContentSession } from '@kit.AbilityKit';
// import { PafPrivacyStatementV2, PafPrivacyResource } from '@hms-paf/ui-widget-permission-v2';
// import { PafWebViewController } from '@hms-paf/ui-widget-webview-v2';
import CallSettingVM from '../viewModel/CallSettingVM';
// import { Navigation, HdsHdsNavigationAttribute, HdsNavigationTitleMode } from '@kit.UIDesignKit';

const TAG = 'NumberIdentityPrivacyStatement';

@Entry
@Component
export default struct NumberIdentityPrivacyStatement {
  private context: common.UIAbilityContext = LocalStorage.getShared()
    .get<common.UIAbilityContext>('context') as common.UIAbilityContext;
  @Provide('pathInfos') pathInfos: NavPathStack = new NavPathStack();
  // pafController: PafWebViewController = new PafWebViewController();
  @State isPrivacyNote: boolean = true;
  // @State pafResource: PafPrivacyResource = new PafPrivacyResource();
  private protocol: string = 'phone';
  private code: string = 'cn';
  private version = '20240614';
  private prefix: string = '/numberidentity-privacy-statement.htm';
  private privacyStateUrl: string = this.formatResourceToString($r('app.string.privacy_state_url'));
  @StorageProp('currentColorMode') @Watch('replaceUrl') currentMode: number = 0;
  @StorageProp('currentLanguage') @Watch('replaceUrl') currentLanguage: string = '';
  // 判断是否使用模态窗口拉起
  @State isFromExternal: boolean = CallSettingVM.getInstance().getIsFromExternal();

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    this.replaceUrl();
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear');
    AppStorage.delete('currentColorMode');
    AppStorage.delete('currentLanguage');
  }

  onPageShow(): void {
    LogUtils.i(TAG, 'onPageShow');
    AppStorage.setOrCreate('currentColorMode', this.context.config.colorMode);
    AppStorage.setOrCreate('currentLanguage', this.context.resourceManager.getConfigurationSync().locale);
  }

  formatResourceToString(resource: ResourceStr): string {
    if (typeof resource === 'string') {
      return resource;
    }
    let result: string = getContext().resourceManager.getStringSync(resource.id);
    return result;
  }

  onBack(): void {
    LogUtils.i(TAG, 'onBack');
    this.terminateSelfWithResult();
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

  replaceUrl() {
    LogUtils.i(TAG, 'replaceUrl');
    this.privacyStateUrl = this.privacyStateUrl + this.protocol + this.prefix + '?code=' + this.code +
      '&branchid=0' + '&version=' + this.version + '&bgmode=' + (this.currentMode ? 'white' : 'dark') +
      '&trsp=true' + '&language=' + this.currentLanguage + '&contenttag=default';
    // this.pafResource.url = this.privacyStateUrl;
    this.privacyStateUrl = this.formatResourceToString($r('app.string.privacy_state_url'));
  }

  build() {
    Navigation() {
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
    }
    // .titleBar(TitleParams.PrivatePageTitleParams())
    .title(this.myTitleBar)
    .backgroundColor(this.isFromExternal ? $r('app.color.color_bind_sheet_background') : undefined)
    // .titleMode(this.isFromExternal ? HdsHdsNavigationTitleMode.MODAL : HdsHdsNavigationTitleMode.MINI)
    .mode(NavigationMode.Stack)
  }
  @Builder
  myTitleBar(): void {
    TitleBarLayout('',$r('sys.color.background_secondary'),false)
  }
}
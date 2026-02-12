/**
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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

import {
  LogUtils,
  Constants,
  ReportUtil,
  CallSettingGlobalContextHelper,
  TitleParams,
  TitleBarLayout
} from '@ohos/common/CommonIndex';
import * as CallSettingsConstant from '../../common/constant/CallSettingsConstant';
import { common } from '@kit.AbilityKit';
// import { PafWebViewController } from '@hms-paf/ui-widget-webview-v2';
import { AlertDialog } from '@ohos.arkui.advanced.Dialog';
// import { PafPrivacyStatementV2, PafPrivacyResource } from '@hms-paf/ui-widget-permission-v2';
import { webview } from '@kit.ArkWeb';
import { isTablet } from '../../common/utils/DeviceTypeUtils';
import { insert } from '../../common/utils/SateToggleStateManager';
import { SatelliteType } from '../../common/constant/SatelliteSearchConst';
// import { NavDestination,  HdsNavDestinationAttribute } from '@kit.UIDesignKit';

const TAG = 'HyacinthPrivacy';

@Builder
export function HyacinthPrivacyLoader(isPrivacyNote: boolean): void {
  HyacinthPrivacy({ isPrivacyNote: isPrivacyNote });
}

@Component
export struct HyacinthPrivacy {
  @Consume('pathInfos') pathInfos: NavPathStack;
  webviewController: webview.WebviewController = new webview.WebviewController();
  @State userAgreementLink: string = 'resource://rawfile/beidoumessage/userAgreement/terms-';
  @State privacyStatementLink: string = 'resource://rawfile/beidoumessage/privacyStatement/privacy-statement-';
  // pafController: PafWebViewController = new PafWebViewController();
  @State isPrivacyNote: boolean = false;
  // @State pafResource: PafPrivacyResource = new PafPrivacyResource();
  @State refreshLanguageCount: number = 0;
  @StorageProp('currentLanguage') @Watch('replaceUrl') currentLanguage: string = '';
  @StorageLink('isStartService') isStartService: boolean = false;
  @StorageProp('currentColorMode') @Watch('replaceUrl') currentMode: number = 0;
  private protocol: string = 'tiantong-satellite';
  private code: string = 'cn';
  private version = '20240719';
  private prefixPrivacyStatement: string = '/privacy-statement.htm';
  private prefixTerms: string = '/terms.htm';
  private language: string | undefined = '';
  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    this.replaceUrl();
  }

  stopServiceController: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.satellite_revoke_authorization_message'),
      primaryButton: {
        value: $r('app.string.cancel_space'),
        action: () => {
          this.stopServiceController.close();
          if (this.isPrivacyNote) {
            ReportUtil.getInstance().reportClickDisableProtocolBtn(Constants.UE_CLICK_CANCEL_BTN);
          } else {
            ReportUtil.getInstance().reportClickDisablePrivacyBtn(Constants.UE_CLICK_CANCEL_BTN);
          }
        }
      },
      secondaryButton: {
        value: $r('app.string.stop_dialog'),
        fontColor: $r('sys.color.ohos_id_color_warning'),
        action: () => {
          this.pathInfos.pop();
          this.isStartService = false;
          LogUtils.i(TAG, `satellite_revoke_authorization Value: 0 satelliteType: ${SatelliteType.HYACINTH}`);
           insert(0, CallSettingGlobalContextHelper.getContext()
             .getValue<common.UIExtensionContext>(CallSettingsConstant.CALL_SETTING_SATELLITE_ABILITY_CONTEXT),
             SatelliteType.HYACINTH);
          if (this.isPrivacyNote) {
            ReportUtil.getInstance().reportClickDisableProtocolBtn(Constants.UE_CLICK_STOP_BTN);
          } else {
            ReportUtil.getInstance().reportClickDisablePrivacyBtn(Constants.UE_CLICK_STOP_BTN);
          }
        }
      }
    }),
    autoCancel: false,
    showInSubWindow: true
  })

  replaceUrl() {
    LogUtils.i(TAG, 'replaceUrl');
    let privacyStateUrl = CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(CallSettingsConstant.CALL_SETTING_SATELLITE_ABILITY_CONTEXT)?.
    resourceManager.getStringSync($r('app.string.privacy_state_url').id);
    if (this.isPrivacyNote) {
      privacyStateUrl = privacyStateUrl + this.protocol + this.prefixTerms + '?code=' + this.code +
        '&branchid=0' + '&verison=' + this.version + '&bgmode=' + (this.currentMode ? 'white' : 'dark') +
        '&trsp=true' + '&language=' + this.currentLanguage + '&contenttag=default';
    } else {
      privacyStateUrl = privacyStateUrl + this.protocol + this.prefixPrivacyStatement + '?code=' + this.code +
        '&branchid=0' + '&verison=' + this.version + '&bgmode=' + (this.currentMode ? 'white' : 'dark') +
        '&trsp=true' + '&language=' + this.currentLanguage + '&contenttag=default';
    }
    // this.pafResource.url = privacyStateUrl;
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

  @Builder
  myTitleBar(){
    TitleBarLayout('',$r('sys.color.background_secondary'),false)
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
          //     forceDarkAccess: true,
          //     navigationEvent: () => {
          //       this.onBack();
          //     }
          //   },
          //   controller: this.pafController
          // })
        }
        .layoutWeight(1)

        if (this.isStartService) {
          Column() {
            Button($r('app.string.satellite_revoke_authorization'))
              .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
              .buttonStyle(ButtonStyleMode.NORMAL)
              .onClick(() => {
                this.stopServiceController.open();
              })
              .width('100%')
              .height(40)
              .margin({ top: 10 })
              .alignSelf(ItemAlign.Center)
              .align(Alignment.Center)
          }
          .width(isTablet() ? '25%' : '100%')
          .padding({ left: 16, right: 16 })
          .height(56)
          .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
        }
      }
      .padding({ bottom: 29 })
    }
    // .titleBar(TitleParams.PrivatePageTitleParams(true))
    .title(this.myTitleBar)
    .hideTitleBar(false)
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    .expandSafeArea([SafeAreaType.KEYBOARD])
    // .onBackPressed(() => {
    //     //   return this.pafController.onBackPress();
    //     // })
  }
}

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
import {
  LogUtils,
  Constants,
  CallSettingGlobalContextHelper,
  sharedPreferencesUtils,
  ReportUtil,
  PrivacyStatement,
  TitleParams
} from '@ohos/common/CommonIndex';
import { common } from '@kit.AbilityKit';
import * as CallSettingsConstant from '../../common/constant/CallSettingsConstant';
// import { PafWebViewController } from '@hms-paf/ui-widget-webview-v2';
// import { PafPrivacyStatementV2, PafPrivacyResource } from '@hms-paf/ui-widget-permission-v2';
import { AlertDialog } from '@ohos.arkui.advanced.Dialog';
import data_preferences from '@ohos.data.preferences';
import { insert } from '../../common/utils/SateToggleStateManager';
// import { NavDestination,  HdsNavDestinationAttribute } from '@kit.UIDesignKit';

const TAG = 'OnLineSatelliteServicePrivacy';

@Builder
export function OnLineSatelliteServicePrivacyLoader(isPrivacyNote: boolean): void {
  OnLineSatelliteServicePrivacy({isPrivacyNote:isPrivacyNote});
}

@Component
export struct OnLineSatelliteServicePrivacy {
  @Consume('pathInfos') pathInfos: NavPathStack;
  // pafController: PafWebViewController = new PafWebViewController();
  @State isPrivacyNote: boolean = false;
  // @State pafResource: PafPrivacyResource = new PafPrivacyResource();
  @StorageProp('currentColorMode') @Watch('replaceUrl') currentMode: number = 0;
  @StorageProp('currentLanguage') @Watch('replaceUrl') currentLanguage: string = '';
  private protocol: string = 'tiantong-satellite';
  private code: string = 'cn';
  private version = '20240719';
  private prefixPrivacyStatement: string = '/privacy-statement.htm';
  private prefixTerms: string = '/terms.htm';
  @StorageLink('isStartService') isStartService: boolean = false;

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
          LogUtils.i(TAG, `satellite_revoke_authorization Value: 0 satelliteType: default`);
          insert(0, CallSettingGlobalContextHelper.getContext()
            .getValue<common.UIExtensionContext>(CallSettingsConstant.CALL_SETTING_SATELLITE_ABILITY_CONTEXT));
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

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    this.replaceUrl();
    if (!this.isStartService) {
      let context = CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIExtensionContext>(CallSettingsConstant.CALL_SETTING_SATELLITE_ABILITY_CONTEXT);
      sharedPreferencesUtils.init(context);
      let options: PrivacyStatement = {
        isStartService: this.isStartService,
        agreeTime: new Date().valueOf(),
        privacyVersion: Constants.PRIVACY_STATEMENT_VERSION,
        appVersion: ReportUtil.getInstance().versionName
      }
      sharedPreferencesUtils.getFromPreferences(CallSettingsConstant.IS_START_SERVICE, options)
        .then((data: data_preferences.ValueType) => {
          let value = data as PrivacyStatement;
          let startService: boolean = value.isStartService;
          LogUtils.i(TAG, 'has it been saved isStartService: ' + JSON.stringify(startService));
          this.isStartService = startService;
        })
    }
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
          //   .accessibilityLevel('no')
          //   .accessibilityGroup(true)
        }
        .layoutWeight(1)
      }
      .padding({ bottom: 29 })
    }
    // .titleBar(TitleParams.PrivatePageTitleParams(true))
    .hideTitleBar(false)
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    .expandSafeArea([SafeAreaType.KEYBOARD])
    // .onBackPressed(() => {
    //   return this.pafController.onBackPress();
    // })
  }
}

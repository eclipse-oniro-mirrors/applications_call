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

import { LogUtils, TitleBarLayout, TitleParams } from '@ohos/common/CommonIndex';
import { common } from '@kit.AbilityKit';
// import { PafAboutSheetConfig, PafAboutV2, Version } from '@hms-paf/ui-widget-about-v2';
import { StringUtil } from '../common/utils/StringUtil';
import CallSettingVM from '../viewModel/CallSettingVM';
// import { PafListModel, PafRichText } from '@hms-paf/ui-widget-base-v2';
import { i18n } from '@kit.LocalizationKit';
// import { NavDestination,  HdsNavDestinationAttribute, HdsNavDestinationTitleMode } from '@kit.UIDesignKit';
import { CALL_UI_BUNDLE_NAME } from '../common/utils/CommonFunUtil';
import { phoneFormat } from '../common/utils/SimIdFormat';
import bundleManager from '@ohos.bundle.bundleManager';

const TAG = 'CallAbout';
const COPYRIGHT_START_YEAR = '2023';

@Component
export default struct CallAbout {
  @Consume('pathInfos') pathInfos: NavPathStack;
  // @State items: PafListModel.ListItemModelArray = [];
  // @State itemArrays: PafListModel.ListItemModelArrays = [];
  // @State footnotes: Array<PafRichText.TextModel> = [];
  // @State sheetShowConfig: PafAboutSheetConfig = new PafAboutSheetConfig();
  // @State version: Version = new Version().setUpgradeEnable(false)
  //   .setState(3)
  //   .setRedDot(false)
  //   .setIsLoading(false);
  @State version: string = '';
  @StorageProp('currentLanguage') @Watch('getDeclare') language: string = i18n.System.getSystemLanguage()
  @State isFromExternal: boolean = CallSettingVM.getInstance().getIsFromExternal();

  async aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear');
    this.getDeclare();
    this.version = await this.getAppVersion()
    // this.sheetShowConfig.setSheetShowStatus(this.isFromExternal);
  }

  async getAppVersion(): Promise<string> {
    let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION;

    try {
      // 使用await等待Promise的结果
      const data = await bundleManager.getBundleInfoForSelf(bundleFlags);

      if (data) {
        console.info('FileUtil', 'getBundleInfoForSelf successfully. Data: %s', JSON.stringify(data));
        return data.versionName; // 返回版本号
      } else {
        console.error('FileUtil', 'getBundleInfoForSelf returned an empty result.');
        return ''; // 返回空字符串
      }
    } catch (err) {
      console.error('FileUtil', 'getBundleInfoForSelf failed: %s', err.message);
      return ''; // 返回空字符串
    }
  }

  getDeclare() {
    // LogUtils.i(TAG, 'getDeclare');
    // this.footnotes = [PafRichText.newTextModel().appendHyperlink($r('app.string.icp_filing'), () => {
    //   let context = getContext(this) as common.UIAbilityContext;
    //   let wantInfo: Want = {
    //     action: 'ohos.want.action.viewData',
    //     entities: ['entity.system.browsable'],
    //     uri: StringUtil.formatResourceToString($r('app.string.filings_address'))
    //   }
    //   context.startAbility(wantInfo).then(() => {
    //     LogUtils.i(TAG, 'open phone Filings net success');
    //   }).catch(() => {
    //     LogUtils.e(TAG, 'open phone Filings net error');
    //   })
    // })];
    // this.footnotes.push(PafRichText.newTextModel().format($r('app.string.copyright_new'),
    //   [PafRichText.newSpanModel(phoneFormat(COPYRIGHT_START_YEAR)),
    //     PafRichText.newSpanModel(phoneFormat(`${new Date().getFullYear()}`))]));
  }

  build() {
    if (this.isFromExternal) {
      NavDestination() {
        this.pafAboutV2Builder();
      }
      // .titleBar(TitleParams.MiniTitleParams($r('app.string.call_about'), $r('app.color.color_bind_sheet_background'),
      //   true, false))
      .title($r('app.string.call_about'))
      .backgroundColor($r('app.color.color_bind_sheet_background'))
      // .titleMode(HdsHdsNavDestinationTitleMode.MODAL)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    } else {
      this.pafAboutV2Builder();
    }
  }

  @Builder
  myTitleBar() {
    TitleBarLayout($r('app.string.call_about'), $r('app.color.color_bind_sheet_background'), true)
  }

  @Builder
  pafAboutV2Builder() {
    Column({ space: 10 }) {
      Image($r('app.media.app_icon'))
        .width(80)
        .height(80)

      Text('电话')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)

      Column() {
        Text('版本信息')
          .fontWeight(FontWeight.Medium)
          .fontSize(14)

        Text(this.version)
          .fontSize(12)
      }
      .alignItems(HorizontalAlign.Start)
      .width('94%')
      .padding(10)
      .borderRadius(10)
      .margin({ top: 40 })
      .backgroundColor(Color.White)
    }

    // PafAboutV2({
    //   sceneTag: CALL_UI_BUNDLE_NAME,
    //   footnotes: $footnotes,
    //   version: this.version,
    //   sheetShowConfig: this.isFromExternal ? this.sheetShowConfig : undefined
    // })
  }
}

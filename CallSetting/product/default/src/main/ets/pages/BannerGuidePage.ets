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

import { LogUtils, CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import { BusinessError } from '@kit.BasicServicesKit';
import { UIExtensionContentSession } from '@kit.AbilityKit';
import { CALL_BANNER_ABILITY_SESSION } from '../common/constant/CallSettingsConstant';
import { CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import { display } from '@kit.ArkUI';
import { isTablet } from '../common/utils/DeviceTypeUtils';
import CallColumnUtils from '../common/utils/CallColumnUtils';

const TAG = 'BannerGuidePage';

@Entry
@Component
export default struct BannerGuidePage {
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  @State guideBanner: Resource = $r('app.media.ic_banner_change_icon');
  @StorageProp('foldStatus') @Watch('updateGuideBanner') foldStatus: display.FoldStatus = 0;

  scroller: Scroller = new Scroller();
  bannerGuideDialog: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      contentBuilder: () => {
        this.bannerBuildContent();
      },

      buttons: [{
        value: $r('app.string.gotIt'), buttonStyle: ButtonStyleMode.TEXTUAL, action: () => {
          this.terminateSelf();
        }
      },
        {
          value: $r('app.string.go_setting'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            this.jumpToCallSettingPage();
          }
        }]
    }),
    autoCancel: false,
    cancel: () => {
      this.terminateSelf();
    }
  });

  jumpToCallSettingPage(): void {
    let session = CallSettingGlobalContextHelper.getContext()
      .getValue<UIExtensionContentSession>(CALL_BANNER_ABILITY_SESSION);
    const actionData: Record<string, string> = {
      'pageFlag': 'callSetting'
    };
    const str: Record<string, Object> = {
      'bundleName': 'com.ohos.callsetting',
      'abilityName': 'com.ohos.callsetting.CallSettingAbility',
      'parameters': actionData,
      'uri': 'CallNotifies',
      'entities': [
        'entity.system.home'
      ]
    };
    session.startAbility(str).then(() => {
      this.terminateSelf();
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, 'startAbility error code:' + err?.code);
    });
  }

  terminateSelf() {
    this.bannerGuideDialog?.close();
    CallSettingGlobalContextHelper.getContext()
      .getValue<UIExtensionContentSession>(CALL_BANNER_ABILITY_SESSION).terminateSelf().then(() => {
      LogUtils.i(TAG, 'terminateSelf success');
    }, (err: BusinessError) => {
      LogUtils.e(TAG, `terminateSelf failed, code is ${err?.code}`);
    });
  }

  @Builder
  bannerBuildContent(): void {
    Column() {
      Scroll(this.scroller) {
        Column() {
          Column() {
            Image(this.guideBanner)
              .draggable(false)

            Text($r('app.string.incoming_notification_setting'))
              .fontSize($r('sys.float.ohos_id_text_size_dialog_tittle'))
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
              .constraintSize({ minHeight: 26 })
              .margin({ top: 15 })

            Text($r('app.string.incoming_notification_setting_tips'))
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .fontWeight(FontWeight.Medium)
              .margin({ top: 15 })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
      }
      .align(Alignment.Top)
      .initialOffset({ yOffset: this.isNewFoldPhoneExternalScreen ? 196 : 0 })
      .onAreaChange(() => {
        const yOffset = this.isNewFoldPhoneExternalScreen ? 196 : 0;
        this.scroller.scrollTo({ xOffset: 0, yOffset });
      })
    }
    .width('100%')
  }

  onPageHide() {
    this.bannerGuideDialog?.close();
    LogUtils.i(TAG, 'onPageHide');
  }

  onPageShow() {
    this.bannerGuideDialog?.open();
    LogUtils.i(TAG, 'onPageShow');
  }

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    this.updateGuideBanner();
  }

  private updateGuideBanner() {
    LogUtils.i(TAG, `updateGuideBanner isTablet`)
    if (isTablet()) {
      this.guideBanner = $r('app.media.ic_banner_change_icon_tablet');
    } else if (CallColumnUtils.getInstance().isFoldableExpand()) {
      this.guideBanner = $r('app.media.ic_banner_change_icon_foldable');
    } else {
      this.guideBanner = $r('app.media.ic_banner_change_icon');
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
    }.width(0).height(0)
  }
}
/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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
import policy from '@ohos.net.policy';
import bundleManager from '@ohos.bundle.bundleManager';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import bundleResourceManager from '@ohos.bundle.bundleResourceManager';
import { LogUtil } from '../util/LogUtil';
import { isTablet, IsWiFiOnly } from '../util/DeviceUtil';
import { FontScaleState } from '../util/fontScaleState';
import DotUtil from '../util/Dot/DotUtils';
import { PolicyDialogUsersOperation } from '../util/Dot/DotCommon';

let TAG = '[DeviceManagerUI:NetAccessPolicyDiagPage]==>';

@Extend(Button)
function wifiOnlyButtonStyle() {
  .fontSize($r('sys.float.ohos_id_text_size_button1'))
  .fontWeight(FontWeight.Medium)
  .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
  .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
}

@CustomDialog
struct CustomDialogExample {
  @Link textValue: string
  @Link inputValue: string
  @Link appValue: Resource
  @Link appUid: number
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;
  controller: CustomDialogController
  storage = LocalStorage.getShared();

  @Builder
  wifiOnlyPart() {
    if (FontScaleState.isSmallerThirdGear(this.fontSizeScale)) {
      this.wifiOnlyButtonPart();
    } else {
      this.wifiOnlySeniorButtonPart();
    }
  }

  @Builder
  wifiOnlyButtonPart() {
    Row() {
      RelativeContainer() {
        Row() {
          Divider()
            .vertical(true)
            .height(24)
            .width('0.5px')
            .color($r('sys.color.comp_divider'))
        }
        .height('100%')
        .width(20)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .alignRules({
          top: { anchor: '__container__', align: VerticalAlign.Top },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .id('dividerCenter')

        Button($r('app.string.not_allow'))
          .onClick(() => {
            this.wifiOnlyNotAllowAction();
          })
          .wifiOnlyButtonStyle()
          .alignRules({
            top: { anchor: '__container__', align: VerticalAlign.Top },
            left: { anchor: '__container__', align: HorizontalAlign.Start },
            right: { anchor: 'dividerCenter', align: HorizontalAlign.Start }
          })
          .id('notAllow')

        Button($r('app.string.allow'))
          .onClick(() => {
            this.wifiOnlyAllowAction();
          })
          .wifiOnlyButtonStyle()
          .alignRules({
            top: { anchor: '__container__', align: VerticalAlign.Top },
            left: { anchor: 'dividerCenter', align: HorizontalAlign.End },
            right: { anchor: '__container__', align: HorizontalAlign.End }
          })
          .id('allow')
      }
      .width('100%')
    }
    .height(40)
    .margin({ top: 8, bottom: 16 })
  }

  @Builder
  wifiOnlySeniorButtonPart() {
    Column() {
      Button($r('app.string.not_allow'))
        .onClick(() => {
          this.wifiOnlyNotAllowAction();
        })
        .margin({ bottom: 4 })
        .width('100%')
        .wifiOnlyButtonStyle()
        .fontSize(FontScaleState.isSmallerSixGear(this.fontSizeScale) ? $r('sys.float.ohos_id_text_size_button1') :
          '32vp')

      Button($r('app.string.allow'))
        .onClick(() => {
          this.wifiOnlyAllowAction();
        })
        .width('100%')
        .wifiOnlyButtonStyle()
        .fontSize(FontScaleState.isSmallerSixGear(this.fontSizeScale) ? $r('sys.float.ohos_id_text_size_button1') :
          '32vp')
    }
    .margin({ top: 8, bottom: 16 })
  }

  @Builder
  normalButtonPart() {
    Column() {
      Button($r('app.string.mobile_data_and_WLAN'))
        .onClick(() => {
          let accessPolicy: policy.NetworkAccessPolicy = {
            allowWiFi: true,
            allowCellular: true,
          }
          LogUtil.info(TAG,`set wifi-mobile wifi: ${accessPolicy.allowWiFi}, cellular: ${accessPolicy.allowCellular}`);
          policy.setNetworkAccessPolicy(this.appUid, accessPolicy, true)
          DotUtil.getInstance().reportAllowWirelessDataDialog(PolicyDialogUsersOperation.MOBILE_DATA_AND_WLAN);
          this.controller.close()
          this.cancel()
        })
        .fontSize($r('app.float.dialog_menu_font_size'))
        .fontWeight(FontWeight.Medium)
        .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
        .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
        .margin({ bottom: 4 })

      Button($r('app.string.only_wlan'))
        .onClick(() => {
          let accessPolicy: policy.NetworkAccessPolicy = {
            allowWiFi: true,
            allowCellular: false,
          }
          LogUtil.info(TAG,`set only-wlan wifi: ${accessPolicy.allowWiFi}, cellular: ${accessPolicy.allowCellular}`);
          policy.setNetworkAccessPolicy(this.appUid, accessPolicy, true)
          DotUtil.getInstance().reportAllowWirelessDataDialog(PolicyDialogUsersOperation.WLAN_ONLY);
          this.controller.close()
          this.cancel()
        })
        .fontSize($r('app.float.dialog_menu_font_size'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
        .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
        .margin({ bottom: 4 })

      Button($r('app.string.not_allow'))
        .onClick(() => {
          let accessPolicy: policy.NetworkAccessPolicy = {
            allowWiFi: false,
            allowCellular: false,
          }
          LogUtil.info(TAG,`set deny wifi: ${accessPolicy.allowWiFi}, cellular: ${accessPolicy.allowCellular}`);
          policy.setNetworkAccessPolicy(this.appUid, accessPolicy, true)
          DotUtil.getInstance().reportAllowWirelessDataDialog(PolicyDialogUsersOperation.DENY);
          this.controller.close()
          this.cancel()
        })
        .fontSize($r('app.float.dialog_menu_font_size'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
        .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
        .margin({ bottom: 8 })
    }
    .margin({ top: 8, bottom: 8 })
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  ImagePart() {
    Stack({ alignContent: Alignment.Center }) {
      Image($r('app.media.ic_public_worldclock_filled'))
        .objectFit(ImageFit.Fill)
        .width(20)
        .height(20)
        .fillColor($r('sys.color.ohos_id_color_primary_contrary'))
        .draggable(false)
    }
    .borderRadius(32)
    .width(32)
    .height(32)
    .align(Alignment.Center)
    .backgroundColor($r('sys.color.ohos_id_color_activated'))
    .margin({
      top: 24,
    })
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        this.ImagePart()
        Text(this.appValue)
          .fontFamily('HarmonyHeiTi')
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .textAlign(TextAlign.Center)
          .margin({
            top: 16,
            bottom: 16
          })
        Scroll() {
          Text($r('app.string.body_network_access_policy'))
            .fontFamily('HarmonyHeiTi')
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontWeight(FontWeight.Regular)
            .fontColor($r('sys.color.font_primary'))
        }
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
        .width('100%')
        .constraintSize({
          maxHeight: (isTablet() && !FontScaleState.isSmallerSixGear(this.fontSizeScale)) ? '50%' : '55%'
        })

        if (IsWiFiOnly()) {
          this.wifiOnlyPart();
        } else {
          this.normalButtonPart();
        }
      }
      .justifyContent(FlexAlign.Center)
    }
    .padding({
      left: 24,
      right: 24
    })
    .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
  }

  cancel() {
    let session = this.storage.get<UIExtensionContentSession>('session');
    if (session) {
      session.terminateSelf();
    }
  }

  confirm() {
  }

  wifiOnlyAllowAction() {
    let accessPolicy: policy.NetworkAccessPolicy = {
      allowWiFi: true,
      allowCellular: true
    }
    LogUtil.info(TAG,`set wifi-only allow wifi: ${accessPolicy.allowWiFi}, cellular: ${accessPolicy.allowCellular}`);
    policy.setNetworkAccessPolicy(this.appUid, accessPolicy, true)
    DotUtil.getInstance().reportAllowWirelessDataDialog(PolicyDialogUsersOperation.WLAN_ONLY);
    this.controller.close()
    this.cancel()
  }

  wifiOnlyNotAllowAction() {
    let accessPolicy: policy.NetworkAccessPolicy = {
      allowWiFi: false,
      allowCellular: false,
    }
    LogUtil.info(TAG,`set wifi-only notallow wifi: ${accessPolicy.allowWiFi}, cellular: ${accessPolicy.allowCellular}`);
    policy.setNetworkAccessPolicy(this.appUid, accessPolicy, true)
    DotUtil.getInstance().reportAllowWirelessDataDialog(PolicyDialogUsersOperation.DENY);
    this.controller.close()
    this.cancel()
  }
}

@Entry
@Component
struct CustomDialogUser {
  @State textValue: string = ''
  @State inputValue: string = 'click me'
  @State appValue: Resource = IsWiFiOnly() ? $r('app.string.title_wifi_only_network_access_policy') :
  $r('app.string.title_network_access_policy');
  @State appUid: number = 0
  storage = LocalStorage.getShared();
  dialogController: CustomDialogController = new CustomDialogController({
    builder: CustomDialogExample({
      textValue: $textValue,
      inputValue: $inputValue,
      appValue: $appValue,
      appUid: $appUid,
    }),
    cancel: this.existApp,
    autoCancel: false,
    alignment: DialogAlignment.Center,
    maskColor: $r('sys.color.ohos_id_color_mask_thin'),
    backgroundColor: $r('sys.color.ohos_id_color_dialog_bg')
  })

  onPageShow() {
    this.appUid = this.storage.get<number>('appUid') as number;
    try {
      let bundleName: string = bundleManager.getBundleNameByUidSync(this.appUid);
      let bundleFlags = bundleResourceManager.ResourceFlag.GET_RESOURCE_INFO_ALL;
      try {
        let resourceInfo = bundleResourceManager.getBundleResourceInfo(bundleName, bundleFlags);
        if (IsWiFiOnly()) {
          this.appValue = $r('app.string.title_wifi_only_network_access_policy', resourceInfo.label);
        } else {
          this.appValue = $r('app.string.title_network_access_policy', resourceInfo.label);
        }
      } catch (err) {
        LogUtil.error(TAG, 'Get bundle label info failed')
      }
    } catch (err) {
      LogUtil.error(TAG, 'Get bundle name failed')
    }
  }

  aboutToDisappear() {
  }

  onCancel() {
    LogUtil.info(TAG, 'onCancel')
  }

  onAccept() {
    LogUtil.info(TAG, 'onAccept')
  }

  existApp() {
    LogUtil.info(TAG, 'existApp')
  }

  build() {
    Column(this.dialogController.open())
  }
}
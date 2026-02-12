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

import { MAX_FONT_SCALE, SYS_STATUS_SEARCH_SATELLITE_SUCC } from '../../common/constant/SatelliteSearchConst';
import SatelliteSearchManager from '../../manager/SatelliteSearchManager';
import { curves } from '@kit.ArkUI';
import { LogUtils, ReportUtil } from '@ohos/common/CommonIndex';
import { bundleResourceManager } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AlertDialog } from '@ohos.arkui.advanced.Dialog';
import { isTablet } from '../../common/utils/Utils';
import { DisplayUtil } from '../../common/utils/DisplayUtil';
import ScreenAdapterUtils from '../../common/utils/ScreenAdapterUtils';
import { TrifoldManager } from '../../manager/TrifoldManager';

const TAG = 'HyacinthSearchBottom';

@Entry
@Component
export struct HyacinthSearchBottom {
  @Link showReConnect: boolean;
  @Link showReCalibrate: boolean;
  @Link showReSearch: boolean;
  @Link currentStatus: Number;
  @Link scaleSize: number;
  @Link isSkipCalibrate: boolean;
  @State text: Resource = $r('app.string.voicemail');
  @State reconnectScale: number = 0.85;
  @State reconnectOP: number = 0;
  @State icLauncherPhone: string | undefined = undefined;
  @State icLauncherMessage: string | undefined = undefined;
  private isNewFoldPhone = ScreenAdapterUtils.isNewFormFoldPhone();
  private outOrInButtonEffect = TransitionEffect.asymmetric(
    TransitionEffect.OPACITY.animation({ duration: 150, curve: Curve.Sharp }).combine(
      TransitionEffect.scale({ x: 0.85, y: 0.85 })
        .animation({ duration: 200, curve: curves.cubicBezierCurve(0.38, 1.33, 0.6, 1) }),
    ),
    TransitionEffect.OPACITY.animation({ duration: 150, curve: Curve.Sharp }).combine(
      TransitionEffect.scale({ x: 0.85, y: 0.85 })
        .animation({ duration: 200, curve: Curve.Friction }),
    )
  )

  skipCalibrateDialog: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      primaryTitle: $r('app.string.contact_str_copysim_notification'),
      content: $r('app.string.im_smc_note_content'),
      primaryButton: {
        value: $r('app.string.mobile_data_cancel'),
        action: () => {
          this.skipCalibrateDialog.close();
        }
      },
      secondaryButton: {
        value: $r('app.string.confim_space'),
        action: () => {
          this.isSkipCalibrate = false;
          this.showReCalibrate = false;
          SatelliteSearchManager.getInstance().setShowReCalibrate(this.showReCalibrate);
        }
      },
    }),
    autoCancel: false,
    showInSubWindow: true
  })

  aboutToAppear(): void {
    this.getPhoneIcon();
    this.getMessageIcon();
  }

  getButtonAnimation() {
    LogUtils.i('SatelliteSearchBottom', ' getButtonAnimation in');
    this.reconnectScale = 0.85;
    animateTo({ duration: 250, curve: Curve.Sharp }, () => {
      this.reconnectScale = 1;
    })
  }

  getButtonAnimationOut() {
    LogUtils.i('SatelliteSearchBottom', ' getButtonAnimation out');
    animateTo({ duration: 250, curve: Curve.Sharp }, () => {
      this.reconnectScale = 0.85;
    })
  }

  getPhoneIcon() {
    let bundleName = 'com.ohos.contacts';
    let abilityName = 'com.ohos.contacts.MainAbility';
    let bundleFlag = bundleResourceManager.ResourceFlag.GET_RESOURCE_INFO_ALL;
    try {
      let resourceInfos = bundleResourceManager.getLauncherAbilityResourceInfo(bundleName, bundleFlag);
      if (resourceInfos == undefined) {
        return;
      }
      while (resourceInfos.length > 0) {
        let resourceInfo = resourceInfos.pop();
        if (resourceInfo?.abilityName == abilityName) {
          this.icLauncherPhone = resourceInfo?.icon;
          LogUtils.i(TAG, 'getPhoneIcon success');
          return
        }
      }
    } catch (err) {
      let e: BusinessError = err as BusinessError;
      LogUtils.e(TAG, 'getPhoneIcon fail, errCode: ' + e.code + ' ,msg: ' + e.message);
    }
  }

  getMessageIcon() {
    let bundleName = 'com.ohos.mms';
    let abilityName = 'com.ohos.mms.MainAbility';
    let bundleFlag = bundleResourceManager.ResourceFlag.GET_RESOURCE_INFO_ALL;
    try {
      let resourceInfos = bundleResourceManager.getLauncherAbilityResourceInfo(bundleName, bundleFlag);
      if (resourceInfos == undefined) {
        return;
      }
      while (resourceInfos.length > 0) {
        let resourceInfo = resourceInfos.pop();
        if (resourceInfo?.abilityName == abilityName) {
          this.icLauncherMessage = resourceInfo?.icon;
          LogUtils.i(TAG, 'getMessageIcon success');
          return;
        }
      }
    } catch (err) {
      let e: BusinessError = err as BusinessError;
      LogUtils.e(TAG, 'getMessageIcon fail, errCode: ' + e.code + ' ,msg: ' + e.message);
    }
  }

  getMarginBasedOnCondition(): Margin {
    if (this.isNewFoldPhone || this.scaleSize === 1) {
      return { bottom: 64 };
    } else if (isTablet()) {
      return { bottom: 64 * this.scaleSize * 1.4 };
    } else {
      return { bottom: 60 };
    }
  }

  openExpandDialog: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      primaryTitle: $r('app.string.contact_str_copysim_notification'),
      content: $r('app.string.fold_remind_tips_message'),
      primaryButton: {
        value: $r('app.string.gotIt'),
        fontColor: $r('sys.color.font_emphasize'),
        action: () => {
          this.openExpandDialog.close();
          if (this.showReSearch) {
            this.goReSearch();
          } else if (this.showReConnect) {
            this.goReConnect();
          }
        }
      },
    }),
    autoCancel: false,
    showInSubWindow: true
  })

  goReSearch() {
    this.showReSearch = false;
    SatelliteSearchManager.getInstance().setShowReSearch(this.showReSearch);
    ReportUtil.getInstance().reportSatelliteClickReSearchBtn();
  }

  goReConnect() {
    this.showReConnect = false;
    SatelliteSearchManager.getInstance().setShowReconnect(false);
    ReportUtil.getInstance().reportSatelliteClickReConnectingBtn();
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 电话&短信按钮
      if (!SatelliteSearchManager.getInstance().getIsFromMeetime() &&
        this.currentStatus === SYS_STATUS_SEARCH_SATELLITE_SUCC) {
        Row() {
          Stack({ alignContent: Alignment.TopStart }) {
            Column() {
              Image(this.icLauncherPhone == undefined ? $r('app.media.ic_launcher_phone') : this.icLauncherPhone)
                .width(56)
                .height(56)
                .margin({left:6})
                .draggable(false)
              Text($r('app.string.satellite_phone'))
                .fontSize(12)
                .margin({ top: 6 })
                .fontColor(Color.White)
                .maxFontScale(MAX_FONT_SCALE)
            }.onClick(() => {
              SatelliteSearchManager.getInstance().jumpToDialCall();
              ReportUtil.getInstance().reportSatelliteConnectedClickPhone();
            })

            Image($r('app.media.ic_hyacinth_satellite_icon'))
              .width(18)
              .height(18)
              .margin({ left: 50, top: 40 })
              .draggable(false)
          }

          Stack({ alignContent: Alignment.TopStart }) {
            Column() {
              Image(this.icLauncherMessage == undefined ? $r('app.media.ic_launcher_message') : this.icLauncherMessage)
                .width(56)
                .height(56)
                .draggable(false)
              Text($r('app.string.satellite_message'))
                .fontSize(12)
                .margin({ top: 6 })
                .fontColor(Color.White)
                .maxFontScale(MAX_FONT_SCALE)
            }.onClick(() => {
              SatelliteSearchManager.getInstance().jumpToMms();
              ReportUtil.getInstance().reportSatelliteConnectedClickMessage();
            })

            Image($r('app.media.ic_hyacinth_satellite_icon'))
              .width(18)
              .height(18)
              .margin({ left: 44, top: 40 })
              .draggable(false)
          }
        }
        .width(238)
        .height(76)
        .margin(this.getMarginBasedOnCondition())
        .justifyContent(FlexAlign.SpaceBetween)
        .transition(
          TransitionEffect.asymmetric(
            TransitionEffect.OPACITY.animation({ delay: 100, duration: 150, curve: Curve.Sharp }).combine(
              TransitionEffect.translate({ y: '200px' })
                .animation({ delay: 60, curve: curves.interpolatingSpring(0, 1, 228, 30) }),
            ),
            TransitionEffect.IDENTITY
          )
        )
      }

      Column() {
        // 重新校准按钮
        if (this.showReCalibrate) {
          if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
            this.showSmcReCalibrateLayout();
          } else {
            Column() {
              Button($r('app.string.re_calibrate'))
                .retryTextStyle()
                .onClick(() => {
                  this.showReCalibrate = false;
                  SatelliteSearchManager.getInstance().setShowReCalibrate(this.showReCalibrate);
                  ReportUtil.getInstance().reportClickSatelliteRecalibrateBtn();
                })
            }
            .width('100%')
            .height(40)
            .margin({ bottom: 58 })
            .transition(this.outOrInButtonEffect)
          }
        }

        // 重新连接按钮
        if (this.showReConnect) {
          Column() {
            Button($r('app.string.re_connecting_satellite'))
              .retryTextStyle()
              .onClick(() => {
                if (ScreenAdapterUtils.isTrifoldPhone() && !TrifoldManager.getInstance().isTrifold()) {
                  this.openExpandDialog.open();
                } else {
                  this.goReConnect();
                }
              })
          }
          .width('100%')
          .height(40)
          .margin({ bottom: 58 })
          .transition(this.outOrInButtonEffect)
        }

        // 重新搜寻按钮
        if (this.showReSearch) {
          Column() {
            Button($r('app.string.re_wait_loading'))
              .retryTextStyle()
              .onClick(() => {
                if (ScreenAdapterUtils.isTrifoldPhone() && !TrifoldManager.getInstance().isTrifold()) {
                  this.openExpandDialog.open();
                } else {
                  this.goReSearch();
                }
              })
          }
          .width('100%')
          .height(40)
          .margin({ bottom: 58 })
          .transition(this.outOrInButtonEffect)
        }
      }
      .width('100%')
      .height(100)
      .padding({ left: 16, right: 16 })
      .justifyContent(FlexAlign.End)
    }
  }

  isFoldOrTablet(): boolean {
    return isTablet() || DisplayUtil.isExpandedStatus() || TrifoldManager.getInstance().isTrifold();
  }

  @Builder
  showSmcReCalibrateLayout() {
    Column() {
      Column() {
        Button($r('app.string.re_calibrate'))
          .retryTextStyle()
          .onClick(() => {
            this.showReCalibrate = false;
            SatelliteSearchManager.getInstance().setShowReCalibrate(this.showReCalibrate);
            ReportUtil.getInstance().reportClickSatelliteRecalibrateBtn();
          })
      }
      .width('100%')
      .height(40)
      .margin({
        top: this.isSkipCalibrate ? (this.isFoldOrTablet() ? -16 : -52) :
          (this.isFoldOrTablet() ? 36 : 0),
        bottom: this.isSkipCalibrate ? 12 : (this.isFoldOrTablet() ? 8 : 44)
      })
      .transition(this.outOrInButtonEffect)

      if (this.isSkipCalibrate) {
        Column() {
          Button($r('app.string.hicall_user_info_skip'))
            .retryTextStyle()
            .onClick(() => {
              this.skipCalibrateDialog.open();
            })
        }
        .width('100%')
        .height(40)
        .margin({ bottom: this.isFoldOrTablet() ? 8 : 44 })
        .transition(this.outOrInButtonEffect)
      }
    }
    .width('100%')
    .height('100%')
  }
}

@Extend(Button)
function retryTextStyle() {
  .fontColor('#5291FF')
  .backgroundColor(SatelliteSearchManager.getInstance().getIsFromMeetime() ?
  $r('sys.color.ohos_id_color_button_normal') : $r('sys.color.ohos_id_color_button_normal_dark'))
  .width('100%')
  .height(40)
  .fontSize($r('sys.float.Body_L'))
  .fontWeight(FontWeight.Medium)
}

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

import { LogUtils, ReportUtil, TitleBarLayout, TitleParams } from '@ohos/common/CommonIndex';
import * as CallSettingsConstant from '../common/constant/CallSettingsConstant';
import { StringUtil } from '../common/utils/StringUtil';
import queryAddData from '../common/utils/queryAddData';
import { BusinessError } from '@ohos.base';
import { promptAction } from '@kit.ArkUI';
import display from '@ohos.display';
import CallColumnUtils from '../common/utils/CallColumnUtils';
import { isPhone, isTablet } from '../common/utils/Utils';
import { SystemMode } from '../model/SystemMode';
import CallSettingVM from '../viewModel/CallSettingVM';
// import { NavDestination,  HdsNavDestinationAttribute, HdsNavDestinationTitleMode } from '@kit.UIDesignKit';

const TAG = 'CallBannerCallNotifies';
const commons: queryAddData = new queryAddData();
const cardAspectRatio: number = (252 / 378);
const cardImgViewHeight: string = 'calc(80% + 24vp)';

@Component
export default struct CallNotifies {
  @Consume('pathInfos') pathInfos: NavPathStack;
  @StorageProp('curBp') curBp: string = '';
  @State message: string = 'Hello World';
  @State slotId: number = 1;
  @State isPenglai: boolean = false;
  @State bannerIsSelect: boolean = false;
  @State fullIsSelect: boolean = false;
  @State callNotifiesTextValue: string = CallSettingsConstant.BANNER;
  @State callNotifiersTitle: string = StringUtil.formatResourceToString($r('app.string.unlock_after_call_notification'));
  @LocalStorageLink('CallNotifiesText') getCallNotifiesText: Resource = $r('app.string.banner');
  @StorageProp('foldStatus') @Watch('setDeviceCurBp') foldStatus: display.FoldStatus = 0;
  // 判断是否使用模态窗口拉起
  @State isFromExternal: boolean = CallSettingVM.getInstance().getIsFromExternal();
  // 判断半模态是否有叉号
  @State isCrossMarkExists: boolean = CallSettingVM.getInstance().getIsFromExternal();
  @State deviceCurBp: string = '';
  aboutToAppear() {
    this.isPenglai = SystemMode.getInstance().isModePenglai();
    this.getCallNotifiesTextValue();
    this.setDeviceCurBp();
  }

  async getCallNotifiesTextValue() {
    if (this.isPenglai) {
      this.bannerIsSelect = false
      this.fullIsSelect = true
      this.callNotifiesTextValue = CallSettingsConstant.FULL_SCREEN;
      return;
    }
    commons.queryCallNotifiesType((data: string) => {
      this.callNotifiesTextValue = data;
      this.bannerIsSelect = this.callNotifiesTextValue === CallSettingsConstant.BANNER;
      this.fullIsSelect = this.callNotifiesTextValue === CallSettingsConstant.FULL_SCREEN;
    })
  }

  async changeToWay(params: string) {
    if (this.isPenglai) {
      this.bannerIsSelect = false
      this.fullIsSelect = true
      this.callNotifiesTextValue = CallSettingsConstant.FULL_SCREEN;
      try {
        promptAction.showToast({
          message: $r('app.string.not_support_toast'),
          duration: 2000
        });
      } catch (e) {
        LogUtils.e(TAG, `showToast error ${e.message}`);
      }
      return
    }
    this.bannerIsSelect = params === CallSettingsConstant.BANNER;
    this.fullIsSelect = params === CallSettingsConstant.FULL_SCREEN;
    commons.setCallCallNotifiesType(params).then((data: boolean | BusinessError) => {
      LogUtils.i(TAG, 'setCallCallNotifiesType success, data: ' + data);
      this.callNotifiesTextValue = params + '';
      this.getCallNotifiesText = (params === CallSettingsConstant.BANNER ? $r('app.string.banner') :
      $r('app.string.full_screen'));
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, 'setCallCallNotifiesType error' + JSON.stringify(err));
    });
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          GridRow({ columns: { xs: 4, sm: 4, md: 8, lg: 12 }, gutter: 24 }) {
            GridCol({ span: this.isFromExternal ? { xs: 2, sm: 2, md: 4, lg: 6 } : { xs: 2, sm: 2, md: 3, lg: 3 },
              offset: this.isFromExternal ? 0 : { md: 1, lg: 3 } }) {
              Stack() {
                Column() {
                  this.CardLeftImage()
                }
                .height('100%')
                .width('100%')
                .alignItems(HorizontalAlign.Center)
                .justifyContent(FlexAlign.SpaceBetween)

                Column() {
                  Radio({ value: '', group: 'radioMessageInfo' })
                    .checked(this.bannerIsSelect)
                    .padding($r('sys.float.padding_level1'))
                    .margin({
                      right: $r('sys.float.padding_level6'),
                      bottom: $r('sys.float.padding_level6'),
                      top: this.curBp === 'sm' ? $r('sys.float.padding_level12') : 0
                    })
                    .width(24)
                    .height(24)
                    .onClick(() => {
                      this.bannerIsSelect = !this.bannerIsSelect;
                      this.changeToWay(CallSettingsConstant.BANNER);
                    })
                }
                .height('100%')
                .width('100%')
                .alignItems(HorizontalAlign.End)
                .justifyContent(FlexAlign.End)

                Column() {
                }
                .height('100%')
                .width('100%')
                .alignItems(HorizontalAlign.End)
                .justifyContent(FlexAlign.Center)
                .border({
                  width: this.callNotifiesTextValue === CallSettingsConstant.BANNER ? 2 : 0,
                  color: $r('sys.color.brand')
                })
                .borderRadius($r('sys.float.corner_radius_level8'))
              }
              .aspectRatio(cardAspectRatio)
            }
            .onClick(() => {
              this.changeToWay(CallSettingsConstant.BANNER);
              ReportUtil.getInstance().reportNotifyTypeAction(0);
            })
            .aspectRatio(cardAspectRatio)
            .backgroundColor(this.isFromExternal ? $r('sys.color.comp_background_list_card') :
              $r('sys.color.comp_background_primary'))
            .borderRadius($r('sys.float.corner_radius_level10'))
            .margin({
              right: this.curBp === 'md' ? -6 : -4
            })

            GridCol({ span: this.isFromExternal ? { xs: 2, sm: 2, md: 4, lg: 6 } : { xs: 2, sm: 2, md: 3, lg: 3 }}) {
              Stack() {
                Column() {
                  this.CardRightImage()
                }
                .height('100%')
                .width('100%')
                .alignItems(HorizontalAlign.Center)
                .justifyContent(FlexAlign.SpaceBetween)

                Column() {
                  Radio({ value: '', group: 'radioMessageInfo' })
                    .checked(this.fullIsSelect)
                    .padding($r('sys.float.padding_level1'))
                    .margin({
                      right: $r('sys.float.padding_level6'),
                      bottom: $r('sys.float.padding_level6'),
                      top: this.curBp === 'sm' ? $r('sys.float.padding_level12') : 0
                    })
                    .width(24)
                    .height(24)
                    .onClick(() => {
                      this.fullIsSelect = !this.fullIsSelect;
                      this.changeToWay(CallSettingsConstant.FULL_SCREEN);
                    })
                }
                .height('100%')
                .width('100%')
                .alignItems(HorizontalAlign.End)
                .justifyContent(FlexAlign.End)

                Column() {
                }
                .height('100%')
                .width('100%')
                .alignItems(HorizontalAlign.End)
                .justifyContent(FlexAlign.Center)
                .border({
                  width: this.callNotifiesTextValue === CallSettingsConstant.FULL_SCREEN ? 2 : 0,
                  color: $r('sys.color.brand')
                })
                .borderRadius($r('sys.float.corner_radius_level8'))
              }
              .aspectRatio(cardAspectRatio)
            }
            .onClick(() => {
              this.changeToWay(CallSettingsConstant.FULL_SCREEN);
              ReportUtil.getInstance().reportNotifyTypeAction(1);
            })
            .aspectRatio(cardAspectRatio)
            .backgroundColor(this.isFromExternal ? $r('sys.color.comp_background_list_card') :
              $r('sys.color.comp_background_primary'))
            .borderRadius($r('sys.float.corner_radius_level10'))
            .margin({
              left: this.curBp === 'md' ? -6 : -4
            })
          }
          .margin({
            top: this.isFromExternal ? $r('sys.float.padding_level4') : $r('sys.float.padding_level8'),
            left: this.getPaddingSpace(),
            right: this.getPaddingSpace()
          })

          GridRow({ columns: { xs: 2, sm: 2, md: 8, lg: 12 }, gutter: 24 }) {
            GridCol({ span: this.isFromExternal ? { xs: 2, sm: 2, md: 8, lg: 12 } : { xs: 2, sm: 2, md: 6, lg: 8 },
              offset: this.isFromExternal ? 0 : { md: 1, lg: 2 } }) {
              Column() {
                Text(this.isPenglai ? $r('app.string.unlock_after_call_notification_descriptions') :
                $r('app.string.unlock_after_call_notification_descriptions_normal'))
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.Body_M'))
                  .fontWeight(FontWeight.Regular)
                  .constraintSize({ minHeight: $r('app.float.line_height_16') })
                  .margin({
                    top: $r('sys.float.padding_level12')
                  })
                  .width('100%')
                  .textAlign(this.curBp === 'lg' ? TextAlign.Center : TextAlign.Start)
              }
            }
          }
          .margin({
            left: this.getPaddingSpace(),
            right: this.getPaddingSpace()
          })
        }
        .width('100%')
        .backgroundColor(this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
          $r('sys.color.background_secondary'))
      }
      .clip(false)
      .edgeEffect(EdgeEffect.Spring)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
      .height('100%')
    }
    // .titleBar(TitleParams.MiniTitleParams($r('app.string.unlock_after_call_notification'),
    //     this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
    //     $r('sys.color.background_secondary'), this.isCrossMarkExists))
    // .titleMode(this.isFromExternal ? HdsHdsNavDestinationTitleMode.MODAL : HdsHdsNavDestinationTitleMode.MINI)
    .title(this.myTitleBar)
    .backgroundColor(this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
      $r('sys.color.background_secondary'))
  }
  @Builder
  myTitleBar(){
    TitleBarLayout($r('app.string.unlock_after_call_notification'),
     this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
       $r('sys.color.background_secondary'), this.isCrossMarkExists)
  }

  @Builder
  CardRightImage() {
    Column() {
      Image(this.getRightImgResource())
        .objectFit(ImageFit.Contain)
        .margin({
          left: this.getImgMargin(),
          right: this.getImgMargin(),
        })
        .aspectRatio(1)
        .draggable(false)
      Column(){
        Text($r('app.string.full_screen'))
          .width('100%')
          .maxFontScale(1.75)
          .fontColor($r('sys.color.font_primary'))
          .fontSize($r('sys.float.Body_S'))
          .fontWeight(FontWeight.Regular)
          .textAlign(TextAlign.Center)
          .margin({
            top: $r('sys.float.padding_level4')
          })
      }
      .width('100%')
      .padding({
        left: 12,
        right: 12
      })
    }
    .justifyContent(FlexAlign.Center)
    .height(cardImgViewHeight)
  }

  @Builder
  CardLeftImage() {
    Column() {
      Image(this.getLeftImgResource())
        .objectFit(ImageFit.Contain)
        .margin({
          left: this.getImgMargin(),
          right: this.getImgMargin(),
        })
        .aspectRatio(1)
        .draggable(false)
      Column(){
        Text($r('app.string.banner'))
          .width('100%')
          .maxFontScale(1.75)
          .fontColor($r('sys.color.font_primary'))
          .fontSize($r('sys.float.Body_S'))
          .fontWeight(FontWeight.Regular)
          .textAlign(TextAlign.Center)
          .margin({
            top: $r('sys.float.padding_level4')
          })
      }
      .width('100%')
      .padding({
        left: 12,
        right: 12
      })
    }
    .justifyContent(FlexAlign.Center)
    .height(cardImgViewHeight)
  }

  private getPaddingSpace(): Resource {
    if (this.curBp === 'sm' && isTablet()) {
      return $r('sys.float.padding_level12');
    }
    if (this.isFromExternal) {
      return $r('sys.float.padding_level8');
    }
    return CallColumnUtils.getInstance().getPaddingSpace(this.curBp);
  }

  private getImgMargin(): Resource | string {
    if (this.curBp === 'sm') {
      return $r('sys.float.padding_level9');
    }
    if (this.curBp === 'md' || this.curBp === 'lg') {
      if (CallColumnUtils.getInstance().isFoldableExpand()) {
        if (this.isFromExternal) {
          return '36vp';
        }
        return $r('sys.float.padding_level24');
      }
      return $r('sys.float.padding_level12');
    }
    return $r('sys.float.padding_level9');
  }

  private getLeftImgResource(): Resource {
    if (this.deviceCurBp === 'sm') {
      return $r('app.media.ic_banner_config');
    }
    if (this.deviceCurBp === 'md') {
      return $r('app.media.ic_banner_config_md_light');
    }
    if (this.deviceCurBp === 'lg') {
      return $r('app.media.ic_banner_config_lg_light');
    }
    return $r('app.media.ic_banner_config');
  }

  private getRightImgResource(): Resource {
    if (this.deviceCurBp === 'sm') {
      return $r('app.media.ic_full_config');
    }
    if (this.deviceCurBp === 'md') {
      return $r('app.media.ic_full_config_md_light');
    }
    if (this.deviceCurBp === 'lg') {
      return $r('app.media.ic_full_config_lg_light');
    }
    return $r('app.media.ic_full_config');
  }

  private setDeviceCurBp() {
    if (isPhone()) {
      if (CallColumnUtils.getInstance().isFoldableExpand()) {
        this.deviceCurBp = 'md';
      } else {
        this.deviceCurBp = 'sm';
      }
    } else if (isTablet()) {
      this.deviceCurBp = 'lg';
    } else {
      this.deviceCurBp = this.curBp;
    }
  }
}

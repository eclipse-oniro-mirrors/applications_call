/**
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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

import AnimationUtil from './AnimationUtil';
import { fontScaleManager } from './FontScaleManager';
import { IconWantType, IconUtil } from './IconUtil';
import { FakeAppIconModel } from '././model/FakeAppIconModel';
import { FakeAppIcon } from './FakeAppIcon';
import { FontScaleState } from '../../common/utils/FontScaleState';
import { i18n } from '@kit.LocalizationKit';
import { LogUtils } from '@ohos/common';

const TAG: string = 'GalleryButton';
const BTN_ID: string = 'SelectFromGalleryButton';
const GALLERY_ICON_SIZE: number = 48;

@Component
export default struct GalleryButton {
  @State shouldPerformTransition: boolean = false;
  @State alpha: number = 0;
  @State galleryIconModel?: FakeAppIconModel = undefined;
  @Prop isFullScreen: boolean = false;
  @Prop isFromContact: boolean;
  @State fontScaleState: FontScaleState = fontScaleManager.getSysFontScaleState();
  @StorageProp('colorMode') @Watch('getBgColor') colorMode: ColorMode = ColorMode.LIGHT;
  @State layerBgColor: ResourceColor = Color.Transparent;
  @State bgColor: ResourceColor = $r('sys.color.comp_background_list_card');
  onButtonClick?: () => void;

  aboutToAppear(): void {
    this.getBgColor();
    this.createGalleryIconModel();
    if (this.shouldPerformTransition) {
      animateTo({
        curve: AnimationUtil.alphaInterpolator,
        duration: 200,
      }, () => {
        this.alpha = 1;
      })
    } else {
      this.alpha = 1;
    }
  }

  private async createGalleryIconModel(): Promise<void> {
    try {
      const iconData: string | string[] | undefined = await IconUtil.getIconData({
        appName: 'gallery',
        type: IconWantType.CURRENT,
      });
      if (!iconData) {
        LogUtils.e(TAG, 'gallery layer is undefined');
        return;
      }
      this.galleryIconModel = new FakeAppIconModel({
        appName: 'gallery',
        iconData: iconData,
      });
    } catch (error) {
      LogUtils.w(TAG, 'error in getIconLayered, will show mockImage');
    }
  }

  private getBgColor(): void {
    this.bgColor = $r('sys.color.comp_background_list_card');
  }

  @Builder
  TouchLayer() {
    Flex()
      .borderRadius(12.5)
      .backgroundColor(this.layerBgColor)
      .height('calc(100% - 8vp)')
      .width('calc(100% - 8vp)')
  }

  @Builder
  TargetItem() {
    Stack({ alignContent: Alignment.Center }) {
      this.TouchLayer()

      Row() {
        Image($r('app.media.ohos_gallery_foreground'))
          .height(GALLERY_ICON_SIZE)
          .width(GALLERY_ICON_SIZE)
          .draggable(false)
          .border({
            width: 1,
            color: $r('app.color.gallery_button_border_color'),
            radius: $r('sys.float.corner_radius_level6'),
          })
          .id(`mockImage_gallery`)

        Column() {
          Text($r('app.string.video_ringtone_from_photo_picker'))
            .draggable(false)
            .fontWeight(FontWeight.Medium)
            .fontSize($r('sys.float.ohos_id_text_size_button1'))
            .maxFontScale(FontScaleState.buttonMaxScale)
            .width('70%')
            .direction(i18n.isRTL(i18n.System.getSystemLanguage()) ? Direction.Rtl : Direction.Ltr)
        }
        .margin({
          left: i18n.isRTL(i18n.System.getSystemLanguage()) ? 8 : 16,
          right: i18n.isRTL(i18n.System.getSystemLanguage()) ? 16 : 8,
        })

        Blank()

        Image($r('app.media.ic_public_arrow_right'))
          .height('24vp')
          .width('12vp')
          .fillColor($r('sys.color.icon_fourth'))
          .matchTextDirection(true)
      }
      .padding({
        left: 12,
        right: 12,
      })
      .width('100%')
    }
    .id(BTN_ID)
    .onHover((isHover: boolean) => {
      if (isHover) {
        this.layerBgColor = $r('sys.color.ohos_id_color_click_effect');
      } else {
        this.layerBgColor = Color.Transparent;
      }
    })
    .onTouch((event?: TouchEvent) => {
      if (event?.type === TouchType.Down) {
        this.layerBgColor = $r('sys.color.ohos_id_color_click_effect');
      }
      if (event?.type === TouchType.Up || event?.type === TouchType.Cancel) {
        this.layerBgColor = Color.Transparent;
      }
    })
    .onClick(() => {
      this.onButtonClick && this.onButtonClick();
    })
    .onAppear(() => {
      if (!this.isFullScreen) {
        focusControl.requestFocus(BTN_ID);
      }
    })
    .backgroundColor(this.bgColor)
    .width('100%')
    .height(72)
    .borderRadius(16)
    .focusable(true)
    .defaultFocus(true)
  }

  build() {
    Column() {
      this.TargetItem()
    }
    .margin({
      top: this.isFromContact ? 8 : 16,
    })
    .width('100%')
    .padding({
      left: 16,
      right: 16,
    })
    .opacity(this.alpha)
    .justifyContent(FlexAlign.Center)
  }
}
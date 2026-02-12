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

import { SettingItemProperty } from '../insightintents/model/SettingItemProperty';
import { LogUtils } from '@ohos/common/CommonIndex';
import { IntentSwitchAdaptor } from '../insightintents/adapter/IntentSwitchAdaptor';

const TAG: string = 'DefaultIntentComponent';

@Entry
@Component
struct DefaultIntentComponent {
  @StorageLink('intentItem') intentItem: SettingItemProperty | undefined = undefined;
  summary?: string;
  switchState: boolean = false;
  itemName: string = '';

  build() {
    Column() {
      this.intentTitleBuilder()
      this.MenuItemBuilder()
    }
    .alignSelf(ItemAlign.Start)
    .clip(true)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.color_00000000_transparent'))
    .padding({
      top: '10vp',
      bottom: '12vp',
      left: '12vp',
      right: '12vp'
    })
  }

  @Builder
  MenuItemBuilder() {
    Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
      Column() {
        Column() {
          Text($r('app.string.mobile_data'))
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontWeight(FontWeight.Medium)
            .fontFamily('HarmonyHeiTi')
            .lineHeight(21)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .flexGrow(1)
      .alignItems(HorizontalAlign.Start);
      Toggle({ type: ToggleType.Switch, isOn: this.switchState })
        .switchStyle({
          unselectedColor: $r('sys.color.ohos_id_color_component_normal')
        })
        .onChange((isOn: boolean) => {
          if (isOn) {
            IntentSwitchAdaptor.setSwitchOn(this.itemName)
          } else {
            IntentSwitchAdaptor.setSwitchOff(this.itemName);
          }
        })
        .hoverEffect(HoverEffect.None)
        .responseRegion({ width: 48, height: 48 })
        .width(36)
        .height(20)
        .flexShrink(0)
        .defaultFocus(true)
    }.layoutWeight(1)
    .margin({
      top: '12vp'
    })
  }

  @Builder
  intentTitleBuilder() {
    Row() {
      Image($r('app.media.ic_app_icon_settings'))
        .flexGrow(0)
        .flexShrink(0)
        .align(Alignment.Start)
        .size({ width: '20vp', height: '20vp' })
        .autoResize(false)
        .interpolation(ImageInterpolation.Medium)
        .syncLoad(true)
        .draggable(false);

      Text($r('app.string.mobile_setting'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.ohos_fa_text_primary'))
        .fontSize($r('sys.float.ohos_id_text_size_body3'))
        .fontFamily('HarmonyHeiTi')
        .lineHeight(16)
        .margin({
          left: '8vp',
        });
    }
    .width('100%')
  }

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    this.itemName = String(this.intentItem?.itemName ?? '').toLowerCase();
    this.switchState = AppStorage.get<boolean>(this.itemName) ?? false
    LogUtils.i(TAG, `aboutToAppear ${this.itemName} state is : ${this.switchState}`);
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear');
  }

  onPageShow(): void {
    LogUtils.i(TAG, 'onPageShow');
  }

  onPageHide(): void {
    LogUtils.i(TAG, 'onPageHide');
  }
}


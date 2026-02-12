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

import CallColumnUtils from '../utils/CallColumnUtils';
import { LengthMetrics } from '@kit.ArkUI';
import SplitScreenManager, { SplitScreenType } from '../../model/SplitScreenManager';

@Component
export default struct ConferenceTitle {
  @Link showConferenceDetail: boolean;
  @StorageProp('curBp') curBp: string = '';
  @StorageLink('SplitScreenType') splitScreenType: SplitScreenType = SplitScreenType.DEFAULT;
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  @Prop isShowKeyboard: boolean = false;

  getConferenceTitleFontSize(isNewFoldPhoneExternalScreen: boolean): string {
    if (isNewFoldPhoneExternalScreen) {
      if (this.isShowKeyboard) {
        return '20vp';
      }
      return '30vp';
    }
    let splitFontSize = SplitScreenManager.getInstance().getDisplayNameFontSize(this.splitScreenType);
    if (splitFontSize.length > 0) {
      return splitFontSize
    }
    return CallColumnUtils.getInstance().getDisplayNameForAutoSize($r('app.string.telephone_Conference'), this.curBp, false,);
  }

  build() {
    Row() {
      Text($r('app.string.telephone_Conference'))
        .fontColor($r('sys.color.font_on_primary'))
        .fontSize(this.getConferenceTitleFontSize(this.isNewFoldPhoneExternalScreen))
        .fontWeight(600)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize('24vp')
        .fontColor([$r('sys.color.icon_on_primary')])
        .draggable(false)
        .margin({ start: LengthMetrics.vp(6) })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .margin({ bottom: $r('sys.float.padding_level1')})
    .accessibilityLevel('yes')
    .accessibilityRole(AccessibilityRoleType.BUTTON)
    .onClick(() => {
      this.showConferenceDetail = true;
    })
  }
}
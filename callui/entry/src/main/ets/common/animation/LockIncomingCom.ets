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

import IncomingComVM from '../../viewmodel/IncomingComVM';
import ParticleLayout from './ParticleLayout';
import CallColumnUtils from '../utils/CallColumnUtils';
import { StringUtil } from '../utils/StringUtil';
import { LengthMetrics } from '@kit.ArkUI';
import ScreenAdapterUtils from '../utils/ScreenAdapterUtils';
import { AppFuncBtnStyleData } from '../struct/TypeUtils';

const ICON_OFFSET = 18;
const MAX_OFFSET = 18;

@Component
export default struct LockIncomingCom {
  @Link mIncomingVM: IncomingComVM;
  @State incomingIcon: Resource = $r('sys.symbol.phone_fill');
  @State incomingVideoIcon: Resource = $r(`sys.symbol.video_fill`);
  @State scrollX: number = 0;
  @State scrollXLockCon: number = 0;
  @Link isVideoCall: boolean;
  @StorageProp('curBp') curBp: string = '';
  @StorageLink('isRTL') isRTL: boolean = false;
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  @StorageLink('isApplyNewStyle') isApplyNewStyle: boolean = false;
  @StorageLink('funcBtnStyle') funcBtnStyle: AppFuncBtnStyleData = new AppFuncBtnStyleData();

  getBottomBtnWidth() {
    if (this.isApplyNewStyle) {
      return this.funcBtnStyle.btnWidth;
    }
    return ScreenAdapterUtils.getInstance().getParticleLayoutBottomBtnWidth(this.isNewFoldPhoneExternalScreen);
  }

  getBottomBtnSymbolWidth() {
    return ScreenAdapterUtils.getInstance().getParticleLayoutBottomBtnSymbolWidth(this.isNewFoldPhoneExternalScreen);
  }

  build() {
    if (this.curBp !== 'sm' && this.curBp !== 'xs') {
      Stack() {
        Row({ space: CallColumnUtils.getInstance().getRowSpace(this.curBp) }) {
          Column() {
            this.hungUpBtn();
          }
          .justifyContent(FlexAlign.Center)
          .layoutWeight(1)

          Column() {
            this.anwserBtn();
          }
          .justifyContent(FlexAlign.Center)
          .layoutWeight(1)
        }.width('100%')

        ParticleLayout({
          scrollXLockCon: $scrollXLockCon,
          scrollX: $scrollX,
          mIncomingVM: $mIncomingVM,
          isVideoCall: $isVideoCall
        })
          .alignSelf(ItemAlign.Center)
      }
      .width('100%')
      .height(80)
    } else {
      Row() {
        this.hungUpBtn();

        ParticleLayout({
          scrollXLockCon: $scrollXLockCon,
          scrollX: $scrollX,
          mIncomingVM: $mIncomingVM,
          isVideoCall: $isVideoCall
        })
          .zIndex(10)
          .alignSelf(ItemAlign.Center)

        this.anwserBtn();
      }
      .height(this.isNewFoldPhoneExternalScreen ? 64 : 80) // Missed Call Latest Altitude
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
  }

  private hungUpTranslate(): number {
    if (this.isRTL) {
      return this.scrollX > 0 ? -this.scrollX * 0.2 < -MAX_OFFSET ? -MAX_OFFSET : -this.scrollX * 0.2 : 0;
    }
    return this.scrollX < 0 ? -this.scrollX * 0.2 > MAX_OFFSET ? MAX_OFFSET : -this.scrollX * 0.2 : 0;
  }

  @Builder
  hungUpBtn() {
    Column() {
      SymbolGlyph($r('sys.symbol.phone_down_fill'))
        .fontSize(this.getBottomBtnSymbolWidth())
        .fontColor(['#e84826'])
        .width(this.getBottomBtnSymbolWidth())
        .height(this.getBottomBtnSymbolWidth())
        .draggable(false)
        .translate({
          x: this.hungUpTranslate()
        });
    }
    .id('callui_LockIncomingCom_hungUpBtn_Column')
    .width(this.getBottomBtnWidth())
    .height(this.getBottomBtnWidth())
    .alignSelf(ItemAlign.Center)
    .justifyContent(FlexAlign.Center)
    .margin({ end: this.curBp === 'sm' ? LengthMetrics.vp(10) : null })
    .accessibilityLevel('yes')
    .accessibilityText(StringUtil.formatResourceToString(
      $r('app.string.hangUp')))
  }

  private anwserTranslate(): number {
    if (this.isRTL) {
      return this.scrollX < 0 ? -this.scrollX * 0.2 > MAX_OFFSET ? MAX_OFFSET : -this.scrollX * 0.2 : 0;
    }
    return this.scrollX > 0 ? -this.scrollX * 0.2 < -MAX_OFFSET ? -MAX_OFFSET : -this.scrollX * 0.2 : 0;
  }

  @Builder
  anwserBtn() {
    Column() {
      Stack() {
        SymbolGlyph(this.isVideoCall ? this.incomingVideoIcon : this.incomingIcon)
          .fontSize(this.getBottomBtnSymbolWidth())
          .fontColor(['#64BB5C'])
          .width(this.getBottomBtnSymbolWidth())
          .height(this.getBottomBtnSymbolWidth())
          .draggable(false);
      }
      .translate({
        x: this.anwserTranslate()
      })
      .onAreaChange((oldValue: Area, newValue: Area) => {
        let startPoint: number = Number(newValue.globalPosition.x) + ICON_OFFSET;
        AppStorage.setOrCreate<number>('LockIncomingCenterPoint', startPoint);
      });
    }
    .width(this.getBottomBtnWidth())
    .height(this.getBottomBtnWidth())
    .alignSelf(ItemAlign.Center)
    .justifyContent(FlexAlign.Center)
    .margin({ start: this.curBp === 'sm' ? LengthMetrics.vp(10) : null })
    .accessibilityLevel('yes')
    .accessibilityText(StringUtil.formatResourceToString($r('app.string.answer')))
    .id('callUI_LockIncomingCom_answerBtn_Column')
  }
}

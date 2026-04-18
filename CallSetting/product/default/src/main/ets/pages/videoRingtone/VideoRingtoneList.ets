/**
 * Copyright (c) 2025-2025 Huawei Device Co., Ltd.
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

import { VideoRingtoneCard } from './VideoRingtoneCard';
import { Card } from './model/Card';
import { CardSection } from './model/CardSection';
import { LogUtils } from '@ohos/common';
import { DisplayUtil } from '../../common/utils/DisplayUtil';
import { isTablet } from '../../common/utils/DeviceTypeUtils';
import ScreenAdapterUtils from '../../common/utils/ScreenAdapterUtils';
import { TrifoldManager } from '../../manager/TrifoldManager';
import { isPhone } from '../../common/utils/Utils';
import { display } from '@kit.ArkUI';

const TAG = 'VideoRingtoneList';
const IN_USE_OUTLINE_SIZE_DELTA: number = 7;

@Component
export default struct VideoRingtoneList {
  section: number = 0;
  @ObjectLink @Watch('refreshGridHeight') model?: CardSection;
  onCardSelected?: (selectedCard: Card, index: number) => void;
  parentWidth?: number;
  @StorageProp('statusBottomHeight') statusBottomHeight: number = 0;
  @Provide('inUseOuterLineSize') inUseOuterLineSize: SizeOptions = { width: 0, height: 0 };
  @Provide('roundedPlainCardSize') roundedPlainCardSize: SizeOptions = {};
  @State gridHeight: string = '100%';

  aboutToAppear() {
    this.registerDisplayListener();
    if (this.parentWidth && this.parentWidth > 0) {
      this.refreshCardSize(this.parentWidth);
      this.refreshGridHeight();
    }
    LogUtils.i(TAG, 'aboutToAppear');
  }

  private refreshGridHeight() {
    if (this.model?.getDataArray() && this.model?.getDataArray().length > 3) {
      this.gridHeight = (this.roundedPlainCardSize.height as number * 2 + 8) + 'vp';
    } else {
      this.gridHeight = (this.roundedPlainCardSize.height as number) + 'vp';
    }
  }

  refreshCardSize(width: number): void {
    const displayWidth = this.getUIContext().px2vp(width);
    const padding = (isTablet() || TrifoldManager.getInstance().isTripleFoldG()) ? 24 : 16;
    const space = 8;
    const result = Math.floor((displayWidth - padding * 2 - space * 2) / 3 * 100) / 100;
    LogUtils.i(TAG,
      `refreshCardSize displayWidth: ${displayWidth}, padding: ${padding}, space: ${space}, result: ${result}`);
    const cardSizeRadio = this.getCardSizeRadio();
    LogUtils.i(TAG, `refreshCardSize, cardSizeRadio: ${cardSizeRadio}`);
    this.roundedPlainCardSize = {
      width: result,
      height: result * cardSizeRadio
    }
    this.inUseOuterLineSize = {
      width: (this.roundedPlainCardSize.width as number) + IN_USE_OUTLINE_SIZE_DELTA,
      height: (this.roundedPlainCardSize.height as number) + IN_USE_OUTLINE_SIZE_DELTA,
    };
  }

  private getCardSizeRadio(): number {
    if (ScreenAdapterUtils.getInstance().isNewFoldPhoneInnerScreen()) {
      return 13.8 / 9;
    }
    if (isTablet() ||
      (DisplayUtil.isFoldable() && !ScreenAdapterUtils.isSmallFoldPhone() && !DisplayUtil.isFoldedStatus())) {
      try {
        let displayWidth = display.getDefaultDisplaySync().width;
        let displayHeight = display.getDefaultDisplaySync().height;
        return displayWidth === 0 ? 0 : (displayHeight / displayWidth);
      } catch (err) {
        LogUtils.e(TAG, `getCardSizeRadio error: ${err?.code} ${err?.message}`);
      }
    }
    return 2;
  }

  private registerDisplayListener() {
    try {
      display.on('change', (id: number) => {
        if (isTablet() || DisplayUtil.isFoldable() && !DisplayUtil.isFoldedStatus()) {
          let componentWidth: number = this.getUIContext()
            .getComponentUtils()
            .getRectangleById('gridId')
            .size
            .width;
          LogUtils.i(TAG, 'Grids onSizeChange, componentWidth = ' + componentWidth);
          this.refreshCardSize(componentWidth);
          this.refreshGridHeight();
        }
      })
    } catch (error) {
      LogUtils.e(TAG, 'An exception occurs in the on method of display.');
    }
  }
  
  onPageShow(): void {
    LogUtils.i(TAG, 'onPageShow');
  }

  onPageHide(): void {
    LogUtils.i(TAG, 'onPageHide');
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear');
    try {
      display.off('change');
    } catch (exception) {
      LogUtils.e(TAG, `Failed to unregister display change. Code: ${exception.code}`);
    }
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.interactive_click'))
    .padding({
      left: $r('sys.float.padding_level0'),
      right: $r('sys.float.padding_level0')
    })
    .borderRadius($r('sys.float.corner_radius_level8'))
  }

  @Styles
  normalStyles() {
    .backgroundColor($r('sys.color.ohos_id_color_background_transparent'))
  }

  build() {
    Grid() {
      ForEach(this.model?.getDataArray(), (item: Card, index: number) => {
        GridItem() {
          VideoRingtoneCard({
            model: item,
            index: item.historyIndex,
            geometryId: (index + 1).toString(),
            onCardClick: (index: number) => {
              LogUtils.i(TAG, 'VideoRingtoneList onClick historyIndex:' + item.historyIndex +
                ' selectedCard:' + item.inSelect);
              this.onCardSelected && this.onCardSelected(item, index);
            }
          })
        }
      }, (card: Card) => {
        return card.getId();
      })
    }
    .columnsTemplate('1fr 1fr 1fr')
    .columnsGap(8)
    .rowsGap(8)
    .width('100%')
    .height(this.gridHeight)
    .padding({ left: '16vp', right: '16vp' })
    .clip(false)
    .id('gridId')
    .nestedScroll({
      scrollForward: NestedScrollMode.PARENT_FIRST,
      scrollBackward: NestedScrollMode.SELF_FIRST
    })
    .onSizeChange(() => {
      let componentWidth: number = this.getUIContext()
        .getComponentUtils()
        .getRectangleById('gridId')
        .size
        .width;
      LogUtils.i(TAG, 'Grid onSizeChange, componentWidth = ' + componentWidth);
      this.refreshCardSize(componentWidth);
      this.refreshGridHeight();
    })
    .margin({ bottom: (this.statusBottomHeight === 0 ? 16 : this.statusBottomHeight) + 'vp' })
  }
}
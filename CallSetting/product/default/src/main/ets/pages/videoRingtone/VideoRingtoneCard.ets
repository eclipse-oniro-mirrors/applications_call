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

import { Card } from './model/Card';
import { LengthMetrics, promptAction } from '@kit.ArkUI';
import { LogUtils } from '@ohos/common';
import { accessibility } from '@kit.AccessibilityKit';

const TAG: string = 'VideoRingtoneCard';
const CARD_TOUCH_SCALE: number = 0.90;
const IN_USE_OUTLINE_SIZE_DELTA: number = 7;
const INDEX_DIFFERENT_BETWEEN: number = 2;

@Component
export struct VideoRingtoneCard {
  @ObjectLink model: Card;
  @State fileFd: number = -1;
  @State timeDuration: string = '00:00'
  @Prop overLayOpacity: number = 1;
  @Prop imagePixelMap: PixelMap | undefined = undefined;
  @Consume('roundedPlainCardSize') cardSize: SizeOptions;
  @Consume('inUseOuterLineSize') inUseOuterLineSize: SizeOptions;
  onCardClick?: (index: number) => void;
  @Prop index: number = 0;
  geometryId: string = '';
  @StorageLink('isManage') isManage: boolean = false;
  @StorageLink('isManagePage') isManagePage: boolean = false;

  async aboutToAppear(): Promise<void> {
    this.handleImagePath();
    this.handleDuration();
    this.imagePixelMap = this.model.thumbnail;
  }

  onPageShow(): void {
  }

  private handleImagePath() {
    this.fileFd = this.model.fileFd;
  }

  private handleDuration() {
    try {
      let duration = this.model.videoDuration;
      // 将字符串转换为数字
      let milliseconds = parseInt(duration, 10);
      // 检查转换是否成功
      if (isNaN(milliseconds)) {
        throw new Error('无效的毫秒时间戳');
      }
      this.timeDuration = this.formatMillisecondsToMinSec(milliseconds);
      LogUtils.i(TAG, 'handleDuration timeDuration: ' + this.timeDuration + ' duration:' + duration);
    } catch (e) {
      LogUtils.e(TAG, 'handleDuration fail error:' + JSON.stringify(e));
    }
  }

  formatMillisecondsToMinSec(milliseconds: number): string {
    // 将毫秒转换为秒
    let totalSeconds = Math.floor(milliseconds / 1000);
    // 计算小时、分钟和秒
    let hours = Math.floor(totalSeconds / 3600);
    let minutes = Math.floor((totalSeconds % 3600) / 60);
    let seconds = totalSeconds % 60;
    let hoursStr = '';
    if (hours != 0) {
      hoursStr = hours.toString().padStart(2, '0') + ':';
    }
    return `${hoursStr}${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  }

  public getAccessibilityTextOfTime(time: string) {
    if (time === undefined) {
      return '';
    }
    let timeTmpList = time.split(':');
    let accessibilityText = '';
    if (timeTmpList.length < 3) {
      let sec = Number(timeTmpList[1]);
      let min = Number(timeTmpList[0]);
      if (sec >= 1) {
        accessibilityText = this.formatPluralResourceToString($r('app.plural.call_time_sec'), sec)
      }
      if (min >= 1) {
        accessibilityText = this.formatPluralResourceToString($r('app.plural.call_time_min'), min) + accessibilityText;
      }
    } else {
      let sec = Number(timeTmpList[2]);
      let min = Number(timeTmpList[1]);
      let hour = Number(timeTmpList[0]);
      if (sec >= 1) {
        accessibilityText = this.formatPluralResourceToString($r('app.plural.call_time_sec'), sec)
      }
      if (min >= 1) {
        accessibilityText = this.formatPluralResourceToString($r('app.plural.call_time_min'), min) + accessibilityText;
      }
      if (hour >= 1) {
        accessibilityText = this.formatPluralResourceToString($r('app.plural.call_time_hour'), hour) + accessibilityText;
      }
    }
    accessibilityText = getContext(this)?.resourceManager.getStringSync($r('app.string.video_type').id,
      this.index + INDEX_DIFFERENT_BETWEEN) + ' ' + accessibilityText;
    if (this.isManage && !this.model.isInUse) {
      accessibilityText = accessibilityText + ' ' +
        (this.model.inSelect ? getContext(this)?.resourceManager.getStringSync($r('app.string.talkback_selected').id) :
        getContext(this)?.resourceManager.getStringSync($r('app.string.talkback_not_selected').id));
    }
    return accessibilityText;
  }

  formatPluralResourceToString(resource: Resource, param: number) {
    try {
      return getContext(this)?.resourceManager.getPluralStringValueSync(resource.id, param);
    } catch (err) {
      LogUtils.e(TAG, `formatPluralResourceToString err. Code is ${err.code}, message is ${err.message}`);
      return '';
    }
  }

  private sendAccessibilityEventAnnounce(text: string): void {
    if (!accessibility.isOpenAccessibilitySync()) {
      return;
    }
    let eventInfo: accessibility.EventInfo = ({
      type: 'announceForAccessibility',
      bundleName: 'com.ohos.callsetting',
      triggerAction: 'common',
      textAnnouncedForAccessibility: text
    });
    accessibility.sendAccessibilityEvent(eventInfo);
  }

  @Builder
  inUseOuterLine() {
    Column()
      .border({
        width: this.model.isInUse ? 2.0 : 0,
        radius: 19,
        color: $r('sys.color.interactive_focus'),
      })
      .size(this.inUseOuterLineSize)
      .opacity(this.overLayOpacity)
  }

  @Builder
  inUseCheckBox(isSelect: boolean) {
    Checkbox()
      .focusable(false)
      .width('24vp')
      .height('24vp')
      .hitTestBehavior(HitTestMode.None)
      .margin(0)
      .select(isSelect)
      .selectedColor($r('sys.color.comp_background_emphasize'))
      .padding('2vp')
      .opacity(this.model.isInUse && this.isManagePage ? 0.4 : 1)
      .alignRules({
        bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
        right: { anchor: '__container__', align: HorizontalAlign.End }
      })
      .margin({ bottom: LengthMetrics.vp(8), end: LengthMetrics.vp(8) })
  }

  @Builder
  timeDurationText() {
    Column() {
      Text(this.timeDuration)
        .fontColor($r('sys.color.font_on_primary'))
        .fontSize(10)
        .maxFontScale(1.45)
        .textAlign(TextAlign.Center)
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .padding({ top: '2vp', bottom: '2vp' })
    }
    .alignRules({
      bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
    })
    .padding({ right: '8vp', bottom: '8vp', left: '8vp' })
  }

  @Builder
  cardImage() {
    Image(this.imagePixelMap)
      .width('100%')
      .height('100%')
      .autoResize(true)
      .interpolation(ImageInterpolation.Medium)
      .draggable(false)
      .objectFit(ImageFit.Cover)
      .borderRadius($r('sys.float.corner_radius_level8'))
      .id(`Card_${this.geometryId}`)
      .geometryTransition(this.geometryId, { follow: true })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      this.cardImage();
      RelativeContainer() {
        this.timeDurationText();
        if (this.model.isInUse) {
          this.inUseCheckBox(true);
        } else {
          if (this.isManage) {
            Checkbox()
              .focusable(false)
              .width('24vp')
              .height('24vp')
              .hitTestBehavior(HitTestMode.None)
              .margin(0)
              .select(this.model?.inSelect)
              .selectedColor($r('sys.color.comp_background_emphasize'))
              .onChange((isOn: boolean) => {
                this.sendAccessibilityEventAnnounce(isOn ?
                getContext(this)?.resourceManager.getStringSync($r('app.string.talkback_selected').id) :
                getContext(this)?.resourceManager.getStringSync($r('app.string.talkback_not_selected').id))
              })
              .padding('2vp')
              .alignRules({
                bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
                right: { anchor: '__container__', align: HorizontalAlign.End }
              })
              .margin({ bottom: LengthMetrics.vp(8), end: LengthMetrics.vp(8) })
          }
        }
      }
      .height('56vp')
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: [['#00000000', 0.0], ['#66000000', 1.0]]
      })
      .borderRadius({ bottomStart: LengthMetrics.vp(16), bottomEnd: LengthMetrics.vp(16) })
    }
    .clickEffect({ level: ClickEffectLevel.MIDDLE, scale: CARD_TOUCH_SCALE })
    .hoverEffect(HoverEffect.Scale)
    .size(this.cardSize)
    .borderRadius($r('sys.float.corner_radius_level8'))
    .id(this.geometryId)
    .overlay(this.inUseOuterLine(), {
      offset: {
        x: -(IN_USE_OUTLINE_SIZE_DELTA / 2),
        y: -(IN_USE_OUTLINE_SIZE_DELTA / 2),
      }
    })
    .onClick(() => {
      LogUtils.i(TAG, 'VideoRingtoneCard onClick selectedCard isInUse:' + this.model.isInUse + ' inSelect:' +
      this.model.inSelect + ' index:' + this.index + ' isManage:' + this.isManage);
      if (this.isManage && this.model.isInUse) {
        LogUtils.i(TAG, 'VideoRingtoneCard onClick isInUse : ' + this.model.isInUse);
        promptAction.showToast({
          message: $r('app.string.video_ringtone_no_delete'),
          duration: 2000
        });
      } else {
        this.onCardClick && this.onCardClick(this.index);
      }
    })
    .accessibilityGroup(true)
    .accessibilityDescription((this.isManagePage && !this.isManage) ? ' ' : '')
    .accessibilitySelected(!this.isManagePage && this.model.isInUse)
    .accessibilityText(this.getAccessibilityTextOfTime(this.timeDuration))
  }
}

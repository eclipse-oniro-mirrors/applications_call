/*
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
import { Keys, NavEntryKey, SlotId } from '../constants/CommonConstants';
import PageViewModel from '../viewmodel/PageViewModel';
import { isTablet } from '../util/DeviceUtil';
import { LogUtil } from '../util/LogUtil';
import { LengthMetrics, OperationType, SubHeader, SegmentButtonItemOptionsArray } from '@kit.ArkUI';
import { SearchInfo } from '../data/SearchData';
import { UIExtensionContentSession } from '@kit.AbilityKit';
import { ArrowStructureComponent } from '../view/ArrowStructureComponent';
import DotUtil from '../util/Dot/DotUtils';
import { data } from '@kit.TelephonyKit';
import TrafficController from '../Controller/TrafficController';
// import { HdsNavDestination, HdsNavDestinationAttribute } from '@kit.UIDesignKit';
import { TitleParams } from '../view/TitleParams';

const TAG: string = 'MoreSettingsPage';

@Component
export struct MoreSettingsPageComponent {
  scroller: Scroller = new Scroller;
  trafficController: TrafficController = new TrafficController();
  @Consume('pageInfos') pageInfos: NavPathStack;
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;
  @State showDataInPanel: boolean = true;
  @State isHover: boolean = false;
  @Consume hasTwoSimCard: boolean;
  @Consume existSimCard: boolean;
  @Prop cardName: ResourceStr[];
  @StorageProp('reminder1')@Watch('reminderChange') reminder1: boolean = false;
  @StorageProp('reminder2')@Watch('reminderChange') reminder2: boolean = false;
  @State defaultSlotId: number = data.getDefaultCellularDataSlotIdSync();
  @State showDefaultReminder: boolean =
    this.defaultSlotId === SlotId.SLOT_1 ? this.reminder1 : this.reminder2;
  private storage = LocalStorage.getShared();
  private naviHeight: number = 0;

  aboutToAppear(): void {
    LogUtil.info(TAG, 'aboutToAppear');
    this.existSimCard = PageViewModel.existSimCard();
    this.hasTwoSimCard = PageViewModel.hasTwoSimCard();
    if (AppStorage.get<number>('naviIndicatorHeight')) {
      this.naviHeight = AppStorage.get<number>('naviIndicatorHeight') as number;
    }
  }

  reminderChange(): void {
    this.showDefaultReminder = this.defaultSlotId === SlotId.SLOT_1 ? this.reminder1 : this.reminder2;
  }


  build() {
    NavDestination() {
      // HdsNavDestination() {
      Scroll() {
        Stack({ alignContent: Alignment.End }) {
          this.normalPagePart()

          ScrollBar({ scroller: this.scroller, direction: ScrollBarDirection.Vertical, state: BarState.Auto })
            .margin({ top: 20, bottom: 16 + this.naviHeight });
        }
        .height('100%')
      }
    }
    .title(TitleParams.MiniTitleParams($r('app.string.more_data_usage_settings_title'),
      $r('sys.color.ohos_id_color_sub_background')))
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    .onBackPressed(() => {
      if (this.storage?.get<SearchInfo>(Keys.SEARCH_INFO)?.isMoreSettings()) {
        let session: UIExtensionContentSession =
          this.storage?.get<UIExtensionContentSession>('session') as UIExtensionContentSession
        session?.sendData({ 'action': 'pop' })
      } else {
        const popDestinationInfo = this.pageInfos.pop() // 弹出路由栈栈顶元素
        LogUtil.log(TAG, 'pop' + JSON.stringify(popDestinationInfo))
      }
      return true
    })
  }

  @Builder
  normalPagePart() {
    Column() {
      List({ scroller: this.scroller }) {
        if (this.hasTwoSimCard) {
          this.subHeader(SlotId.SLOT_1)
          PlanAndReminderItem({ slotId: SlotId.SLOT_1, showReminder: this.reminder1 })
          this.subHeader(SlotId.SLOT_2)
          PlanAndReminderItem({ slotId: SlotId.SLOT_2, showReminder: this.reminder2 })
        } else if (this.existSimCard) {
          PlanAndReminderItem({
            slotId: this.defaultSlotId,
            showReminder: this.showDefaultReminder
          })
        }
      }
      .clip(false)
      .borderRadius(20)
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .padding({ left: isTablet() ? 24 : 16, right: isTablet() ? 24 : 16, top: this.hasTwoSimCard ? 0 : 16 })
    .height('100%')
    .width('100%')
  }

  @Builder
  subHeader(slotId: SlotId) {
    SubHeader({
      secondaryTitle: this.cardName[slotId],
      operationType: OperationType.TEXT_ARROW,
      contentMargin: { start: LengthMetrics.vp(0), end: LengthMetrics.vp(0) }
    })
  }
}

@Component
export struct PlanAndReminderItem {
  slotId: number = SlotId.DEFAULT;
  @Prop showReminder: boolean;
  @Consume('pageInfos') pageInfos: NavPathStack;

  build() {
    ListItemGroup() {
      ListItem() {
        ArrowStructureComponent({
          value: $r('app.string.data_plan_settings'),
          onClickCallBack: () => {
            this.pageInfos.pushPath({ name: NavEntryKey.DATA_PLAN_PAGE, param: this.slotId })
            DotUtil.getInstance().reportClickPackageSettings(this.slotId);
          }
        })
      }

      if (this.showReminder) {
        ListItem() {
          ArrowStructureComponent({
            value: $r('app.string.usage_reminders'),
            onClickCallBack: () => {
              this.pageInfos.pushPath({ name: NavEntryKey.USAGE_REMINDERS_PAGE, param: this.slotId })
              DotUtil.getInstance().reportClickQuotaNotification(this.slotId);
            }
          })
        }
      }
    }
    .width('100%')
    .padding({
      top: 4,
      bottom: 4,
      left: 4,
      right: 4
    })
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .borderRadius($r('sys.float.corner_radius_level10'))
    .divider({
      strokeWidth: '1px',
      color: $r('sys.color.comp_divider'),
      startMargin: 8,
      endMargin: 8
    })
  }
}
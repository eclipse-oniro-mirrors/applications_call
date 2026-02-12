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
import { isTablet } from '../util/DeviceUtil';

import { CustomContentDialog, LengthMetrics } from '@kit.ArkUI';
import { LogUtil } from '../util/LogUtil';
import {
  ActionWhenTrafficOut,
  fetchFullKeyWord,
  getFlowText,
  isRTL,
  ONE_GB,
  ONE_KB,
  ONE_MB,
  ONE_TB,
  QueryName,
  ResultCode,
  TAG_NAME,
  UNDERLINE
} from '../constants/CommonConstants';
import { ArrowStructureComponent } from '../view/ArrowStructureComponent';
import { TextSelectItem } from '../view/TextSelectItem';
import { AccessibilityUtils } from '../util/AccessibilityUtils';
import StringUtil from '../util/StringUtil';
import myCommon from '@ohos.app.ability.common';
import { FontScaleState } from '../util/fontScaleState';
import { data, sim } from '@kit.TelephonyKit';
import SettingsDataService, { resType } from '../service/SettingsDataService';
import { ValuesBucket } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { settingsDataParam } from '../model/SettingsDataModel';
import { ResultCodeParamType } from '../model/BaseModel';
import PageViewModel from '../viewmodel/PageViewModel';
import DotUtil from '../util/Dot/DotUtils';
import { DialogOperationState } from '../util/Dot/DotCommon';
import SimServiceProxy from '../model/simServiceProxy';
import { cardInfo, SimCradNameListener as SimCradListener } from '../util/SimCradNameListener';
// import { HdsNavDestination, HdsNavDestinationAttribute } from '@kit.UIDesignKit';
import { TitleParams } from '../view/TitleParams';
import I18n from '@ohos.i18n';

const TAG: string = 'UsageRemindersPage';

interface FlowUnit {
  unit: string,
  maxValue: number,
  ratio: number
}

function getFlowReminderText(flow: number): string {
  let flowUnitArray: FlowUnit[] = [
    { unit: 'byte', maxValue: ONE_KB, ratio: 1 },
    { unit: 'kilobyte', maxValue: ONE_MB, ratio: ONE_KB },
    { unit: 'megabyte', maxValue: ONE_GB, ratio: ONE_MB },
    { unit: 'gigabyte', maxValue: ONE_TB, ratio: ONE_GB },
    { unit: 'terabyte', maxValue: Number.MAX_VALUE, ratio: ONE_TB }
  ];
  let unit = 'byte';
  for (const flowUnit of flowUnitArray) {
    if (flow < flowUnit.maxValue) {
      unit = flowUnit.unit;
      flow = flow / flowUnit.ratio;
      break;
    }
  }
  let locale = new Intl.Locale(I18n.System.getSystemLanguage());
  let ntf =
    new Intl.NumberFormat(locale.toString(), { style: 'unit', unit: unit, unitDisplay: 'short' });
  let flowString = ntf.format(flow);
  return flowString;
}

function getPercentageText(percentage: number): string {
  let locale = new Intl.Locale(I18n.System.getSystemLanguage());
  let ntf = new Intl.NumberFormat(locale.toString(), { style: 'percent' });
  let percentageText = ntf.format((percentage / 100));
  return percentageText;
}

@Component
export struct UsageRemindersPageComponent {
  scroller: Scroller = new Scroller;
  @Consume('pageInfos') pageInfos: NavPathStack;
  @State monthLimitPercentage: number = 80;
  @State dailyLimitPercentage: number = 10;
  @State slotId: number = data.getDefaultCellularDataSlotIdSync();
  @State simId: number = 0;
  @State actionWhenTrafficOut: number = 1;
  @State totalValue: number = 100 * 1024 * 1024;
  private simCardListener: SimCradListener = new SimCradListener();
  whenMonthlyTrafficOutDialog: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.over_monthly_limit'),
      contentBuilder: () => {
        this.whenMonthlyTrafficOutDialogContent()
      },
      contentAreaPadding: { left: $r('sys.float.padding_level6'), right: $r('sys.float.padding_level6') },
      buttons: [
        {
          value: $r('app.string.cancel'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            DotUtil.getInstance()
              .reportWhenTrafficExceedDialog(this.simId, DialogOperationState.CANCEL);
          }
        }
      ]
    }),
    autoCancel: false,
    showInSubWindow: true
  });
  private naviHeight: number = 0;
  private readTimeoutId: number = 0;

  aboutToAppear(): void {
    LogUtil.info(TAG, 'aboutToAppear');
    if (AppStorage.get<number>('naviIndicatorHeight')) {
      this.naviHeight = AppStorage.get<number>('naviIndicatorHeight') as number;
    }
  }

  aboutToDisappear(): void {
    clearTimeout(this.readTimeoutId);
  }

  build() {
    NavDestination() {
      // HdsNavDestination() {
      Stack({ alignContent: Alignment.End }) {
        this.normalPagePart()

        ScrollBar({ scroller: this.scroller, direction: ScrollBarDirection.Vertical, state: BarState.Auto })
          .margin({ top: 20, bottom: 16 + this.naviHeight });
      }
      .height('100%')
    }
    .title(TitleParams.MiniTitleParams(this.setReminderTitle(), $r('sys.color.ohos_id_color_sub_background')))
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    .onBackPressed(() => {
      const popDestinationInfo = this.pageInfos.pop() // 弹出路由栈栈顶元素
      LogUtil.log(TAG, 'pop' + JSON.stringify(popDestinationInfo))
      return true;
    })
    .onReady((ctx: NavDestinationContext) => {
      let tmp = ctx.pathInfo.param as number;
      if (tmp !== undefined) {
        this.slotId = tmp;
      } else {
        LogUtil.warn(TAG, 'get slot id param problem');
      }
      this.getUsageRemindersValues();
    })
  }

  @Builder
  normalPagePart() {
    Column() {
      List({ scroller: this.scroller }) {
        ListItem() {
          ArrowStructureComponent({
            value: $r('app.string.over_monthly_limit'),
            subValue: this.actionWhenTrafficOut === 0 ? $r('app.string.reminder') : $r('app.string.disconnect'),
            onClickCallBack:() => {
              this.whenMonthlyTrafficOutDialog.open();
              DotUtil.getInstance().reportClickMonthlyTrafficExceed(this.simId);
            }
          });
        }
        .constraintSize({ minHeight: 56 })
        .padding({
          top: 4,
          bottom: 4,
          left: 4,
          right: 4
        })
        .backgroundColor($r('sys.color.comp_background_list_card'))
        .borderRadius($r('sys.float.corner_radius_level10'))
        .margin({ bottom: 12 })

        ListItem() {
          reminderComponent({
            title: $r('app.string.monthly_data_reminder'),
            secondTitle: 'app.string.monthly_limit_data_reminder',
            sliderValue: this.monthLimitPercentage,
            simID: this.simId,
            totalValue: this.totalValue,
            flowValue: getFlowReminderText(this.totalValue * this.monthLimitPercentage / 100),
            limitPercentage: getPercentageText(this.monthLimitPercentage),
            contentPercentage: getPercentageText(this.monthLimitPercentage)
          });
        }
        .margin({ bottom: 24 });

        ListItem() {
          reminderComponent({
            title: $r('app.string.daily_data_reminder'),
            secondTitle: 'app.string.daily_limit_data_reminder',
            sliderValue: this.dailyLimitPercentage,
            simID: this.simId,
            isMonthlyReminder: false,
            totalValue: this.totalValue,
            flowValue: getFlowReminderText(this.totalValue * this.dailyLimitPercentage / 100),
            limitPercentage: getPercentageText(this.dailyLimitPercentage),
            contentPercentage: getPercentageText(this.dailyLimitPercentage)
          });
        }
        .margin({ bottom: 16 + this.naviHeight });
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .clip(false)
    }
    .padding({ left: isTablet() ? 24 : 16, right: isTablet() ? 24 : 16, top: 16 })
    .height('100%')
    .width('100%')
  }

  setReminderTitle() {
    if (PageViewModel.hasTwoSimCard()) {
      this.simCardListener.refreshSimList();
      if (cardInfo[this.slotId].isSimCard) {
        return $r('app.string.usage_reminders_index', cardInfo[this.slotId].slotIndex);
      } else{
        return $r('app.string.esim_usage_reminders_index', cardInfo[this.slotId].slotIndex);
      }
    }
    return $r('app.string.usage_reminders');
  }

  @Builder
  normalTitle() {
    Row() {
      Text(this.setReminderTitle())
        .fontWeight(FontWeight.Bold)
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontFamily('HarmonyHeiTi')
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .margin({ start: LengthMetrics.vp(8) })
    }
    .height('100%')
  }

  setData(name: QueryName, value: string) {
    let actionData: settingsDataParam = {};
    let keyWord: string = fetchFullKeyWord(this.simId, name);
    actionData.KEYWORD = keyWord;
    let valueBucket: ValuesBucket = {
      'KEYWORD': keyWord,
      'VALUE': value
    };
    SettingsDataService.getInstance().insertOrUpdate(actionData, valueBucket, (res: ResultCodeParamType) => {
      if (res?.code === ResultCode.FAILURE) {
        LogUtil.error(TAG, `insert ${name} failed`);
      }
    }, getContext(this))

  }

  @Builder
  whenMonthlyTrafficOutDialogContent() {
    List() {
      ListItem() {
        TextSelectItem({
          itemId: 0,
          text: $r('app.string.reminder'),
          selectedId: this.actionWhenTrafficOut
        })
          .onClick(() => {
            this.onMonthlyTrafficOutActionSelected(0, $r('app.string.reminder'));
            this.actionWhenTrafficOut = ActionWhenTrafficOut.REMINDER;
            this.setData(QueryName.monthly_notify_type, this.actionWhenTrafficOut.toString());
            this.whenMonthlyTrafficOutDialog.close();
            DotUtil.getInstance()
              .reportWhenTrafficExceedDialog(this.simId, ActionWhenTrafficOut.REMINDER + 1);
          })
      }

      ListItem() {
        TextSelectItem({
          itemId: 1,
          text: $r('app.string.disconnect'),
          selectedId: this.actionWhenTrafficOut
        })
          .onClick(() => {
            this.onMonthlyTrafficOutActionSelected(1, $r('app.string.disconnect'));
            this.actionWhenTrafficOut = ActionWhenTrafficOut.DISABLE;
            this.setData(QueryName.monthly_notify_type, this.actionWhenTrafficOut.toString());
            this.whenMonthlyTrafficOutDialog.close();
            DotUtil.getInstance()
              .reportWhenTrafficExceedDialog(this.simId, ActionWhenTrafficOut.DISABLE + 1);
          })
      }
    }
    .divider({
      strokeWidth: '1px',
      color: $r('sys.color.comp_divider'),
      startMargin: $r('sys.float.padding_level6'),
      endMargin: $r('sys.float.padding_level6')
    })
  }

  private getUsageRemindersValues() {
    sim.getSimAccountInfo(this.slotId).then(accountInfo => {
      this.simId = accountInfo?.simId ?? 0;
      let actionData: settingsDataParam = {};
      actionData.KEYWORD = TAG_NAME + this.simId;
      SettingsDataService.getInstance().querySettingsInfoByBeginningCondition(actionData, (res: resType) => {
        this.getUsageRemindersSettingsFromDB(res);
        // 限额提醒页面静态打点
        DotUtil.getInstance()
          .reportQuotaNotificationPageStatus(this.simId, this.actionWhenTrafficOut, this.monthLimitPercentage,
            this.dailyLimitPercentage);
      }, getContext(this));
    }).catch((err: BusinessError) => {
      LogUtil.error(TAG, `simdId failed, err.code: ${err.code}, err.msg: ${err.message}`);
    })
  }

  private getUsageRemindersSettingsFromDB(res: resType) {
    if (res?.code === ResultCode.SUCCESS && res?.abilityResult?.length > 0) {
      res?.abilityResult.forEach((resultObj: settingsDataParam) => {
        if (!resultObj.KEYWORD) {
          LogUtil.error(TAG, 'getUsageRemindersSettingsFromDB error')
          return;
        }
        if (resultObj.KEYWORD === fetchFullKeyWord(this.simId, QueryName.monthly_notify_type)) {
          this.actionWhenTrafficOut = Number(resultObj.VALUE);
          LogUtil.info(TAG, `get action when trafficOut: ${this.actionWhenTrafficOut}`);
          return;
        }
        if (resultObj.KEYWORD === fetchFullKeyWord(this.simId, QueryName.monthly_limited_traffic)) {
          this.totalValue = Number(resultObj.VALUE);
          LogUtil.info(TAG, `get monthly limited traffic: ${this.totalValue}`);
          return;
        }
        if (resultObj.KEYWORD === fetchFullKeyWord(this.simId, QueryName.over_monthly_mark)) {
          this.monthLimitPercentage = Number(resultObj.VALUE);
          LogUtil.info(TAG, `get month limit percentage: ${this.monthLimitPercentage}`);
          return;
        }
        if (resultObj.KEYWORD === fetchFullKeyWord(this.simId, QueryName.over_daily_mark)) {
          this.dailyLimitPercentage = Number(resultObj.VALUE);
          LogUtil.info(TAG, `get daily limit percentage: ${this.dailyLimitPercentage}`);
        }
      });
    }
  }

  /**
   * 月度流量超限时弹窗中选则处理方式，如果屏幕朗读开启，需要进行播报再关闭弹窗。
   *
   * @param itemId - 选项id
   * @param readText - 选项标题
   */
  private onMonthlyTrafficOutActionSelected(itemId: number, readText: Resource) {
    clearTimeout(this.readTimeoutId);
    this.actionWhenTrafficOut = itemId;
    if (AccessibilityUtils.isNeedScreenRead()) {
      const context = getContext(this) as myCommon.UIAbilityContext;
      if (context === null || typeof context === 'undefined') {
        this.whenMonthlyTrafficOutDialog.close();
      }
      const title = StringUtil.convertResourceToString(readText, context);
      const selectState = StringUtil.convertResourceToString($r('app.string.accessibility_selected'), context);
      AccessibilityUtils.readInfo(title + ' ' + selectState).then(() => {
        this.readTimeoutId = setTimeout(() => {
          this.whenMonthlyTrafficOutDialog.close();
        }, 1500);
      });
    } else {
      this.whenMonthlyTrafficOutDialog.close();
    }
  }
}

@Component
struct reminderComponent {
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;
  title: string | Resource = '';
  secondTitle: string = '';
  isMonthlyReminder: boolean = true;
  @Prop totalValue: number;
  @Prop simID: number;
  @Prop sliderValue: number;
  @Prop limitPercentage: string;
  @Prop contentPercentage: string;
  @Prop flowValue: string;

  setData(name: QueryName, value: string) {
    let actionData: settingsDataParam = {};
    let keyWord: string = fetchFullKeyWord(this.simID, name);
    actionData.KEYWORD = keyWord;
    let valueBucket: ValuesBucket = {
      'KEYWORD': keyWord,
      'VALUE': value
    };
    SettingsDataService.getInstance().insertOrUpdate(actionData, valueBucket, (res: ResultCodeParamType) => {
      if (res?.code === ResultCode.FAILURE) {
        LogUtil.error(TAG, `insert ${name} failed`);
      }
    }, getContext(this))
  }

  build() {
    Column() {
      Column() {
        this.reminderText()

        Slider({ value: this.sliderValue, style: SliderStyle.InSet })
          .onChange((percentage, mode) => {
            this.limitPercentage =
              this.contentPercentage = getPercentageText(percentage);
            this.flowValue = getFlowReminderText(this.totalValue * percentage / 100);
            if (mode === SliderChangeMode.End) {
              this.setData(this.isMonthlyReminder ? QueryName.over_monthly_mark : QueryName.over_daily_mark,
                percentage.toString());
              if (this.isMonthlyReminder) {
                DotUtil.getInstance()
                  .reportClickMonthlyTrafficRemind(this.simID, percentage);
              } else {
                DotUtil.getInstance()
                  .reportClickDailyUsedTrafficRemind(this.simID, percentage);
              }
            }
          })
          .width('100%')
          .padding({
            left: 6,
            right: 6
          })
      }
      .width('100%')
      .padding({ top: 4, bottom: 8 })
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .borderRadius($r('sys.float.corner_radius_level10'))

      Row() {
        Text($r(this.secondTitle, this.contentPercentage, this.flowValue))
          .fontColor($r('sys.color.font_secondary'))
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Regular)
          .width('100%')
          .maxFontScale(2)
          .accessibilityText($r(this.secondTitle, this.contentPercentage, this.flowValue))
      }
      .margin({ start: LengthMetrics.vp(12), end: LengthMetrics.vp(12), top: LengthMetrics.vp(8) })
    }
    .width('100%')
  }

  @Builder
  reminderText() {
    Row() {
      if (FontScaleState.isStandardGear(this.fontSizeScale)) {
        Row() {
          Text(this.title)
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Medium)
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
        }
        .margin({ end: LengthMetrics.vp(8) })
        .layoutWeight(1)
        Text(this.limitPercentage)
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Regular)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      } else {
        Column() {
          Text(this.title)
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Medium)
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor($r('sys.color.ohos_id_color_text_primary'));
          Text(this.limitPercentage)
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Regular)
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor($r('sys.color.ohos_id_color_text_secondary'));
        }
        .alignItems(HorizontalAlign.Start);
      }
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
    .constraintSize({ minHeight: 48 })
    .padding({
      top: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, '13vp'),
      bottom: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, '14vp'),
      left: 12,
      right: 12,
    })
  }
}
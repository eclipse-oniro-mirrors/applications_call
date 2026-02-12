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
import { FontScaleState } from '../util/fontScaleState';
import { ArrowStructureComponent } from '../view/ArrowStructureComponent';
import {
  DataUnit,
  EMITTER_NOTICE_EVENT_ID,
  EMITTER_RESET_MONTH_LIMIT_NOTICE_EVENT_ID,
  fetchFullKeyWord,
  ONE_GB,
  ONE_MB,
  QueryName,
  ResultCode,
  SlotIdMapSimIdInterface,
  TAG_NAME,
  UNDERLINE,
  UnlimitedEnable
} from '../constants/CommonConstants';
import { cardInfo, SimCradNameListener as SimCradListener } from '../util/SimCradNameListener';
import SettingsDataService, { resType } from '../service/SettingsDataService';
import { ValuesBucket } from '@kit.ArkData';
import { data, sim } from '@kit.TelephonyKit';
import { BusinessError, emitter } from '@kit.BasicServicesKit';
import { settingsDataParam } from '../model/SettingsDataModel';
import PageViewModel from '../viewmodel/PageViewModel';
import TrafficController from '../Controller/TrafficController';
import DotUtil from '../util/Dot/DotUtils';
import { DialogOperationState, NewToggleState } from '../util/Dot/DotCommon';
import StringUtil from '../util/StringUtil';
import myCommon from '@ohos.app.ability.common';
import SettingsSearchUtils from '../util/SettingsSearchUtils';
import { common } from '@kit.AbilityKit';
import { LIMIT_TRAFFIC_NOSET } from '../util/TrafficPackageUtil';
// import { HdsNavDestination, HdsNavDestinationAttribute} from '@kit.UIDesignKit';
import { TitleParams } from '../view/TitleParams';

const TAG: string = 'DataPlanPage';

@Entry
@Component
export struct DataPlanPageComponent {
  @Consume('pageInfos') pageInfos: NavPathStack;
  @State dataLimitUnitSelected: DataUnit = DataUnit.GB;
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;
  @State slotId: number = data.getDefaultCellularDataSlotIdSync();
  @State simId: number = 0;
  @State dataLimitInput: string = '';
  @State dataLimitValue: string = '';
  @State dataLimitText: string | Resource = $r('app.string.not_set');
  @State selectedDayIndex: number = 0;
  @State isOpenUnlimit: boolean = false;
  @State inputFocused: boolean = false;
  private simCardListener: SimCradListener = new SimCradListener();
  private days: string[] =
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20',
      '21', '22', '23', '24', '25', '26', '27', '28', '29', '30', '31'];
  private indexWhenSelecting: number = 0;

  dataLimitDialog: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.data_limit'),
      contentBuilder: () => {
        this.buildContent();
      },
      buttons: [{
        value: $r('app.string.cancel'), buttonStyle: ButtonStyleMode.TEXTUAL, action: () => {
          console.info('Callback when the button is clicked')
          DotUtil.getInstance()
            .reportPackageQuotaDialog(this.simId, DialogOperationState.CANCEL, this.dataLimitInput,
              this.dataLimitUnitSelected);
        }
      }, {
        value: $r('app.string.confirm'), buttonStyle: ButtonStyleMode.TEXTUAL, action: () => {
          this.setMonthlyLimitedTraffic();
        }
      }],
    }),
    autoCancel: false,
    // showInSubWindow: true
  })
  selectStartDayDialog: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.start_date'),
      contentBuilder: () => {
        this.selectStartDayDialogContent();
      },
      buttons: [
        {
          value: $r('app.string.cancel'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            DotUtil.getInstance()
              .reportStartDataDialog(this.simId, DialogOperationState.CANCEL, this.selectedDayIndex + 1);
          }
        },
        {
          value: $r('app.string.confirm'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            this.setStartDayOfMonth();
            DotUtil.getInstance()
              .reportStartDataDialog(this.simId, DialogOperationState.OK, this.selectedDayIndex + 1);
          }
        }
      ]
    }),
    autoCancel: false,
    // showInSubWindow: true
  });

  @Builder
  selectStartDayDialogContent() {
    Column() {
      TextPicker({ range: this.days, selected: this.selectedDayIndex })
        .constraintSize({ minHeight: 129, minWidth: 102 })
        .disappearTextStyle({
          color: $r('sys.color.font_primary'),
          font: { size: $r('sys.float.Body_M'), weight: FontWeight.Regular }
        })
        .textStyle({
          color: $r('sys.color.font_primary'),
          font: { size: $r('sys.float.Body_L'), weight: FontWeight.Regular }
        })
        .selectedTextStyle({
          color: $r('sys.color.font_emphasize'),
          font: { size: $r('sys.float.Title_S'), weight: FontWeight.Medium }
        })
        .divider({
          strokeWidth: '1px',
          color: $r('sys.color.comp_divider')
        } as DividerOptions)
        .onChange((value, index) => {
          if (typeof index === 'number') {
            this.indexWhenSelecting = index;
          }
        })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding({
      top: $r('sys.float.padding_level4')
    })
  }

  @Builder
  dataLimitUnitMenu() {
    Menu() {
      MenuItem({
        content: DataUnit.MB,
        endIcon: this.dataLimitUnitSelected === DataUnit.MB ? $r('app.media.check_mark') : ''
      })
        .selected(this.dataLimitUnitSelected === DataUnit.MB)
        .onClick(() => {
          this.dataLimitUnitSelected = DataUnit.MB;
        })
      MenuItem({
        content: DataUnit.GB,
        endIcon: this.dataLimitUnitSelected === DataUnit.GB ? $r('app.media.check_mark') : ''
      })
        .selected(this.dataLimitUnitSelected === DataUnit.GB)
        .onClick(() => {
          this.dataLimitUnitSelected = DataUnit.GB;
        })
    }
    .focusable(false)
    .menuItemDivider({
      strokeWidth: LengthMetrics.px(1),
      startMargin: LengthMetrics.px(16),
      endMargin: LengthMetrics.px(16),
      color: $r('sys.color.comp_divider')
    })
    .radius('20vp')
    .width('224vp')
    .font({
      size: FontScaleState.isStandardGear(this.fontSizeScale) ? $r('sys.float.ohos_id_text_size_body1') : '32vp',
      weight: FontWeight.Medium, family: 'HarmonyHeiTi'
    })
    .fontColor($r('sys.color.ohos_id_color_text_primary'))
  }

  @Builder
  itemEnd() {
    Select([])
      .value(this.dataLimitUnitSelected)
      .font({ size: $r('sys.float.Body_M'), weight: FontWeight.Medium })
      .fontColor($r('sys.color.font_primary'))
      .arrowPosition(ArrowPosition.END)
      .backgroundColor($r('sys.color.comp_background_tertiary'))
      .bindMenu(this.dataLimitUnitMenu, { placement: Placement.Top })
  }

  @Builder
  buildContent(): void {
    Column() {
      Row() {
        TextInput({ text: this.dataLimitValue })
          .inputFilter('^\\d{0,6}(\\.\\d{0,2})?$', (val) => {
            LogUtil.error(TAG, 'input error');
          })
          .onChange((value: string) => {
            this.dataLimitInput = value;
          })
          .caretColor($r('sys.color.font_emphasize'))
          .backgroundColor(Color.Transparent)
          .direction(Direction.Ltr)
          .defaultFocus(true)
          .width('100%')
          .layoutWeight(1)
          .constraintSize({ minHeight: 48 })
          .padding({ start: LengthMetrics.vp(0) })
          .type(InputType.NUMBER_DECIMAL)
          .onBlur(() => {
            this.inputFocused = false;
          })
          .onFocus(() => {
            this.inputFocused = true;
          })
          .borderRadius(0)

        this.itemEnd()
      }.alignItems(VerticalAlign.Center)

      Divider()
        .vertical(false)
        .height(1)
        .strokeWidth(0.5)
        .color(this.inputFocused ? $r('sys.color.icon_primary') : $r('sys.color.comp_divider'))
        .opacity(this.inputFocused ? $r('sys.float.alpha_secondary') : 1)
    }
    .width('100%')
    .constraintSize({ minHeight: 56 })
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  listItemWithToggle(name: Resource | string) {
    Row() {
      Text(name)
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Medium)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .margin({ end: LengthMetrics.vp(8) })
      Row() {
        Toggle({
          type: ToggleType.Switch,
          isOn: this.isOpenUnlimit
        })
          .onChange((isOn) => {
            this.isOpenUnlimit = isOn;
            let actionData: settingsDataParam = {};
            let keyWord: string = fetchFullKeyWord(this.simId, QueryName.unlimited_traffic_enable);
            actionData.KEYWORD = keyWord;
            let valueBucket: ValuesBucket = {
              'KEYWORD': keyWord,
              'VALUE': isOn
            };
            SettingsDataService.getInstance().insertOrUpdate(actionData, valueBucket, (res: resType) => {
              if (res?.code === ResultCode.FAILURE) {
                LogUtil.error(TAG, 'insert unlimited traffic enable failed');
              }
              this.postMessage();
              let showReminder = false;
              if (isOn === false && this.dataLimitInput.trim() !== '') {
                showReminder = true;
              }
              AppStorage.setOrCreate<boolean>(TrafficController.getReminderName(this.slotId), showReminder);
            }, getContext(this))
            DotUtil.getInstance()
              .reportClickUnlimitedTrafficToggle(this.simId, isOn ? NewToggleState.OK : NewToggleState.OFF);
          })
          .accessibilityLevel('yes')
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.End)
    }
    .padding({
      top: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, '13vp'),
      bottom: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, '14vp'),
      left: 8,
      right: 8
    })
    .constraintSize({ minHeight: 48 })
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .accessibilityGroup(true)
  }

  getDataLimitInputFromDB(value: number) {
    if (value === LIMIT_TRAFFIC_NOSET) {
      return;
    }
    if (value < ONE_GB) {
      this.dataLimitUnitSelected = DataUnit.MB;
      let mbValue = value / ONE_MB;
      this.dataLimitValue = this.dataLimitInput = mbValue.toFixed(Number.isInteger(mbValue) ? 0 : 2);
      this.dataLimitText = this.dataLimitInput + ' ' + this.dataLimitUnitSelected;
      return;
    }
    this.dataLimitUnitSelected = DataUnit.GB;
    let gbValue = value / ONE_GB;
    this.dataLimitValue = this.dataLimitInput = gbValue.toFixed(Number.isInteger(gbValue) ? 0 : 2);
    this.dataLimitText = this.dataLimitInput + ' ' + this.dataLimitUnitSelected;
    return;
  }

  setMonthlyLimitedTraffic() {
    this.dataLimitText = this.dataLimitInput + ' ' + this.dataLimitUnitSelected;
    let isSet: boolean = this.dataLimitInput.trim() !== '';
    let value = Number(this.dataLimitInput);
    let actionData: settingsDataParam = {};
    if (isSet) {
      if (this.dataLimitUnitSelected === DataUnit.MB) {
        value = value * ONE_MB;
      } else {
        value = value * ONE_GB;
      }
      this.getDataLimitInputFromDB(value);
    } else {
      this.dataLimitValue = this.dataLimitInput = '';
      this.dataLimitText = $r('app.string.not_set');
      this.postResetMonthLimitMessage();
    }
    let keyWord: string = fetchFullKeyWord(this.simId, QueryName.monthly_limited_traffic);
    actionData.KEYWORD = keyWord;
    let valueBucket: ValuesBucket = {
      'KEYWORD': keyWord,
      'VALUE': isSet ?  value.toString() : LIMIT_TRAFFIC_NOSET.toString()
    };
    SettingsDataService.getInstance().insertOrUpdate(actionData, valueBucket, (res: resType) => {
      if (res?.code === ResultCode.FAILURE) {
        LogUtil.error(TAG, 'insert monthly limited traffic failed');
        return;
      }
      if (res) {
        this.handleMonthlyLimitedTrafficData(isSet);
      }
    }, getContext(this))
    DotUtil.getInstance()
      .reportPackageQuotaDialog(this.simId, DialogOperationState.OK,
        isSet ? this.dataLimitInput : LIMIT_TRAFFIC_NOSET.toString(), this.dataLimitUnitSelected);
  }

  handleMonthlyLimitedTrafficData(isSet: boolean) {
    AppStorage.setOrCreate<boolean>(TrafficController.getReminderName(this.slotId), isSet && !this.isOpenUnlimit);
    this.postMessage();
    SettingsSearchUtils.enableLimitReminder(getContext(this) as common.UIExtensionContext,
      isSet && !this.isOpenUnlimit);
  }

  build() {
    NavDestination() {
      // HdsNavDestination() {
        Scroll() {
        List() {
          ListItemGroup() {
            ListItem() {
              this.listItemWithToggle($r('app.string.unlimited_data'))
            }

            ListItem() {
              ArrowStructureComponent({
                value: $r('app.string.data_limit'),
                subValue: this.dataLimitText,
                onClickCallBack: () => {
                  this.dataLimitDialog.open();
                  DotUtil.getInstance().reportClickPackageQuota(this.simId);
                }
              })
            }

            ListItem() {
              ArrowStructureComponent({
                value: $r('app.string.start_date'),
                subValue: this.days[this.selectedDayIndex],
                onClickCallBack: () => {
                  this.selectStartDayDialog.open();
                  DotUtil.getInstance().reportClickStartDateOfMonth(this.simId);
                }
              })
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
            startMargin: 8,
            endMargin: 8,
            strokeWidth: '1px',
            color: $r('sys.color.ohos_id_color_list_separator')
          })
        }
        .margin({
          left: isTablet() ? 24 : 16,
          right: isTablet() ? 24 : 16,
          top: $r('sys.float.padding_level8')
        })
        .clip(false)
      }
      .align(Alignment.Top)
      .height('100%')
      .edgeEffect(EdgeEffect.Spring)
      .scrollBar(BarState.Off)
    }
    .title(TitleParams.MiniTitleParams(this.setDataPlanTitle(), $r('sys.color.ohos_id_color_sub_background')))
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    .onReady((ctx: NavDestinationContext) => {
      let tmp = ctx.pathInfo.param as number;
      if (tmp !== undefined) {
        this.slotId = tmp;
      } else {
        LogUtil.warn(TAG, 'get slot id param problem');
      }
      this.getDataPlanValues();
    })
    .onBackPressed(() => {
      const popDestinationInfo = this.pageInfos.pop() // 弹出路由栈栈顶元素
      LogUtil.log(TAG, 'pop' + JSON.stringify(popDestinationInfo))
      return true;
    })
  }

  setDataPlanTitle() {
    if (PageViewModel.hasTwoSimCard()) {
      this.simCardListener.refreshSimList();
      if (cardInfo[this.slotId].isSimCard) {
        // 实体卡，使用旧逻辑
        return $r('app.string.data_plan_settings_index', cardInfo[this.slotId].slotIndex);
      } else{
        // eSIM卡，使用新逻辑
        return $r('app.string.data_plan_esim_settings_index', cardInfo[this.slotId].slotIndex);
      }
    }
    return $r('app.string.data_plan_settings');
  }

  postMessage() {
    let event: emitter.InnerEvent = {
      eventId: EMITTER_NOTICE_EVENT_ID,
      priority: emitter.EventPriority.HIGH
    };
    let exportData: emitter.EventData = {
      data: {
        'params': { slotId: this.slotId, simId: this.simId } as SlotIdMapSimIdInterface
      }
    }
    emitter.emit(event, exportData);
  }

  private postResetMonthLimitMessage() {
    let event: emitter.InnerEvent = {
      eventId: EMITTER_RESET_MONTH_LIMIT_NOTICE_EVENT_ID,
    };
    let emitData: emitter.EventData = {
      data: {
        'params': { slotId: this.slotId, simId: this.simId } as SlotIdMapSimIdInterface
      }
    }
    LogUtil.info(TAG, `postResetMonthLimitMessage: ${this.slotId}`);
    emitter.emit(event, emitData);
  }

  private getDataPlanValues() {
    sim.getSimAccountInfo(this.slotId).then(accountInfo => {
      this.simId = accountInfo?.simId ?? 0;
      let actionData: settingsDataParam = {};
      actionData.KEYWORD = TAG_NAME + this.simId;
      SettingsDataService.getInstance().querySettingsInfoByBeginningCondition(actionData, (res: resType) => {
        this.getDataPlanSettingsFromDB(res);
        // 套餐设置页面静态打点
        this.dataPlanPageStatisticDot();
      }, getContext(this));
    }).catch((err: BusinessError) => {
      LogUtil.error(TAG, `get sim id failed, err.code: ${err.code}, err.msg: ${err.message}`);
    })
  }

  private dataPlanPageStatisticDot() {
    let tempDataLimitText: string = '';
    if (typeof this.dataLimitText === 'string') {
      tempDataLimitText = this.dataLimitText;
    } else {
      tempDataLimitText = StringUtil.convertResourceToString(this.dataLimitText,
        getContext(this) as myCommon.UIAbilityContext);
    }
    DotUtil.getInstance()
      .reportPackageSettingsPageStatus(this.simId, this.isOpenUnlimit ? NewToggleState.OK : NewToggleState.OFF,
        tempDataLimitText, this.selectedDayIndex + 1);
  }

  private getDataPlanSettingsFromDB(res: resType) {
    if (res?.code === ResultCode.SUCCESS && res?.abilityResult?.length > 0) {
      res?.abilityResult.forEach((resultObj: settingsDataParam) => {
        if (!resultObj.KEYWORD) {
          LogUtil.error(TAG, 'getDataPlanSettingsFromDB error')
          return;
        }
        if (resultObj.KEYWORD === fetchFullKeyWord(this.simId, QueryName.unlimited_traffic_enable)) {
          if (resultObj.VALUE === UnlimitedEnable.UNLIMITED_OPEN) {
            this.isOpenUnlimit = true;
          }
          return;
        }
        if (resultObj.KEYWORD === fetchFullKeyWord(this.simId, QueryName.monthly_limited_traffic)) {
          this.getDataLimitInputFromDB(Number(resultObj.VALUE));
          return;
        }
        if (resultObj.KEYWORD === fetchFullKeyWord(this.simId, QueryName.monthly_start_date)) {
          this.selectedDayIndex = Math.floor(Number(resultObj.VALUE)) - 1; // selectedDayIndex 比日期数少一
        }
      });
    }
  }

  /**
   * 设置每月的起始日
   */
  private setStartDayOfMonth() {

    this.selectedDayIndex = this.indexWhenSelecting;
    let actionData: settingsDataParam = {};
    let keyWord: string = fetchFullKeyWord(this.simId, QueryName.monthly_start_date);
    actionData.KEYWORD = keyWord;
    let valueBucket: ValuesBucket = {
      'KEYWORD': keyWord,
      'VALUE': this.days[this.selectedDayIndex]
    };
    SettingsDataService.getInstance().insertOrUpdate(actionData, valueBucket, (res: resType) => {
      if (res?.code === ResultCode.FAILURE) {
        LogUtil.error(TAG, 'insert monthly start date failed');
      }
      if (res) {
        this.postMessage()
      }
    }, getContext(this))
  }
}
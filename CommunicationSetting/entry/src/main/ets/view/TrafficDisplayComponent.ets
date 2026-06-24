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
import { CustomContentDialog, LengthMetrics, promptAction, SymbolGlyphModifier } from '@kit.ArkUI';
import { DataUnit, DEFAULT_USERID, SearchMode } from '../constants/CommonConstants';
import { FontScaleState } from '../util/fontScaleState';
import { TrafficDispalyStatus, TrafficDisplayViewModel } from '../viewmodel/TrafficDisplayViewModel';
import { LogUtil } from '../util/LogUtil';
import CustomButtons from './CustomButtons';

const TAG: string = 'TrafficDisplayComponent'

@Component
export struct TrafficDisplayComponent {
  @State dataLimitInput: string = '';
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;
  @Link trafficDisplayViewModel: TrafficDisplayViewModel;
  @State inputFocused: boolean = false;
  @State dataLimitUnitSelected: DataUnit = DataUnit.GB;
  @Consume @Watch('exitTrafficEvent') isExitTraffic: boolean;
  @State confirmButtonEnabled: boolean = false;
  @StorageProp('userID') userID: number = DEFAULT_USERID;
  private menuList: DataUnit[] = [DataUnit.MB, DataUnit.GB];
  @Consume searchMode: number;
  dataLimitDialog: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: this.trafficDisplayViewModel.getDialogTitle(),
      contentBuilder: () => {
        this.buildContent();
      },
      contentAreaPadding: {
        left: $r('sys.float.padding_level0'),
        right: $r('sys.float.padding_level0'),
        bottom: $r('sys.float.padding_level8')
      }
    }),
    autoCancel: false,
    showInSubWindow: true,
    onWillDismiss: () => {
    }
  })

  aboutToAppear(): void {
    LogUtil.info(TAG, `aboutToAppear`)
    this.trafficDisplayViewModel.addTrafficPackageOberser();
    this.trafficDisplayViewModel.fetchTrafficDisplayStatus();
  }

  exitTrafficEvent() {
    LogUtil.info(TAG, `exitTrafficEvent`);
    if (this.isExitTraffic) {
      this.trafficDisplayViewModel.removeTrafficPackageOberser();
    }
  }

  @Builder
  dataLimitUnitMenu() {
    Menu() {
      ForEach(this.menuList, (item: DataUnit) => {
        MenuItem({
          content: item,
          symbolEndIcon: this.dataLimitUnitSelected === item ? new SymbolGlyphModifier($r('sys.symbol.checkmark')) :
            undefined
        })
          .selected(this.dataLimitUnitSelected === item)
          .onClick(() => {
            this.dataLimitUnitSelected = item;
          })
      })
    }
    .focusable(false)
    .menuItemDivider({
      strokeWidth: LengthMetrics.px(1),
      startMargin: LengthMetrics.px(16),
      endMargin: LengthMetrics.px(16),
      color: $r('sys.color.comp_divider')
    })
    .radius($r('sys.float.corner_radius_level10'))
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
        TextInput({ text: '' })
          .inputFilter('^\\d{0,6}(\\.\\d{0,2})?$', (val) => {
            LogUtil.error(TAG, 'input error');
          })
          .onChange((value: string) => {
            this.dataLimitInput = value;
            this.confirmButtonEnabled = this.dataLimitInput.trim().length > 0;
          })
          .caretColor($r('sys.color.font_emphasize'))
          .backgroundColor(Color.Transparent)
          .direction(Direction.Ltr)
          .defaultFocus(true)
          .width('100%')
          .layoutWeight(1)
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
      }
      .alignItems(VerticalAlign.Center)
      .constraintSize({ minHeight: 47 })

      Divider()
        .vertical(false)
        .height(1)
        .color(this.inputFocused ? $r('sys.color.icon_primary') : $r('sys.color.comp_divider'))
        .opacity(this.inputFocused ? $r('sys.float.alpha_secondary') : 1)
    }
    .constraintSize({ minHeight: 48 })
    .justifyContent(FlexAlign.Center)
    .margin({
      start: LengthMetrics.resource($r('sys.float.padding_level12')),
      end: LengthMetrics.resource($r('sys.float.padding_level12')),
    })

    CustomButtons({
      confirmButtonEnabled: this.confirmButtonEnabled,
      cancelButtonText: $r('app.string.cancel'),
      confirmButtonText: $r('app.string.confirm'),
      onCancel: () => {
        this.dataLimitDialog.close();
        this.trafficDisplayViewModel.handleMonthlyLimitCancelEvent(this.dataLimitInput, this.dataLimitUnitSelected);
      },
      onConfirm: () => {
        this.dataLimitDialog.close();
        this.trafficDisplayViewModel.handleMonthlyLimitConfirmEvent(this.dataLimitInput, this.dataLimitUnitSelected);
      }
    })
      .margin({
        start: LengthMetrics.resource($r('sys.float.padding_level8')),
        end: LengthMetrics.resource($r('sys.float.padding_level8')),
      })
  }

  build() {
    Row() {
      Column() {
        Text($r('app.string.flow_display_title'))
          .fontFamily('HarmonyHeiTi')
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .constraintSize({ minHeight: 22 })
          .textAlign(TextAlign.Start)
          .margin({
            bottom: $r('sys.float.padding_level1')
          })
        Text($r('app.string.usage_display_summary'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Regular)
          .fontSize($r('sys.float.Body_M'))
          .fontColor($r('sys.color.font_secondary'))
          .constraintSize({ minHeight: 19 })
      }
      .justifyContent(FlexAlign.Center)
      .padding({
        top: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, '11vp'),
        bottom: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, '11vp'),
      })
      .layoutWeight(1)
      .constraintSize({ minHeight: 64 })
      .alignItems(HorizontalAlign.Start)
      .margin({ end: LengthMetrics.vp(8) })

      Row() {
        Toggle({
          type: ToggleType.Switch,
          isOn: this.trafficDisplayViewModel.trafficDisplayStatus === TrafficDispalyStatus.OPEN ? true : false
        })
          .onChange((isOn) => {
            if (!this.trafficDisplayViewModel.checkNeedHandleChangeEvent(isOn)) {
              LogUtil.info(TAG, 'jump change event');
              return;
            }
            if (isOn) {
              this.trafficDisplayViewModel.haveSetMonthlyLimited((haveCheck: boolean) => {
                this.trafficDisplayViewModel.trafficDisplayStatus = TrafficDispalyStatus.OPEN;
                if (haveCheck) {
                  LogUtil.info(TAG, `save traffic display status true after limit value`);
                  this.trafficDisplayViewModel.saveTrafficDisplayStatus(isOn);
                } else {
                  LogUtil.info(TAG, `show input data limit`);
                  this.dataLimitInput = '';
                  this.confirmButtonEnabled = false;
                  this.dataLimitUnitSelected = DataUnit.GB;
                  this.dataLimitDialog.open();
                }
              })
            } else {
              this.trafficDisplayViewModel.trafficDisplayStatus = TrafficDispalyStatus.CLOSE;
              LogUtil.info(TAG, `save traffic displayStatus false`);
              // 点击开启显示流量显示套餐限额又取消的情况无需存储数据
              this.trafficDisplayViewModel.saveTrafficDisplayStatus(isOn);
            }
          })
          .accessibilityLevel(this.searchMode === SearchMode.NOT_SEARCHING ? 'yes' : 'no')
          .enabled(this.userID === DEFAULT_USERID)
      }
      .onClick(() => {
        if (this.userID !== DEFAULT_USERID) {
          promptAction.showToast({
            message: $r('app.string.forbid_operation'),
            duration: 2000
          });
        }
      })
      .visibility(this.trafficDisplayViewModel.trafficDisplayStatus === TrafficDispalyStatus.DEFAULT ? Visibility.None :
      Visibility.Visible)
      .justifyContent(FlexAlign.End)
    }
    .accessibilityGroup(true)
    .width('100%')
    .padding({
      top: 0,
      bottom: 0,
      left: 12,
      right: 12
    })
    .justifyContent(FlexAlign.Center)
    .borderRadius($r('sys.float.corner_radius_level10'))
  }
}
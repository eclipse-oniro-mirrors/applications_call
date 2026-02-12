/*
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

import {
  LogUtils,
  ReportUtil,
  disableCellularDataRoamingCardOne,
  disableCellularDataRoamingCardTwo,
  setNetworkCapabilityLTEOn,
  setNetworkCapabilityLTEOff,
  setNetworkCapabilityNROn,
  setNetworkCapabilityNROff,
  enableCellularDataRoamingCardOne,
  enableCellularDataRoamingCardTwo,
  disableImsSwitchCardOne,
  disableImsSwitchCardTwo,
  enableImsSwitchCardOne,
  enableImsSwitchCardTwo,
  ToastUtil
} from '@ohos/common/CommonIndex';
import lazy { AlertDialog } from '@ohos.arkui.advanced.Dialog';
import { DynamicLoader } from '../../control/DynamicLoader';
import { LengthMetrics } from '@kit.ArkUI';
import { FontScale } from '../../utils/FontScaleState';
import CallSettingVM from '../../../viewModel/CallSettingVM';

const TAG = 'ListItem';

interface apnParamType {
  cardType: number;
}

interface pathParams {
  slotId: number;
}

@Component
export default struct listItem {
  @Prop isCard: boolean = false;
  @Prop isBtn: boolean = false;
  @Prop isEnabled: boolean = false;
  @Prop describeDisabled: boolean = false;
  @Prop iconBtn: boolean = false;
  @Prop cardType: number = -1;
  @Link controlSwitch: boolean;
  @Prop title: Resource = $r('app.string.mobile_data_dataRoaming');
  @State describe: Resource = $r('app.string.mobile_data_enableDataWhileRoaming');
  @State titleopacity: boolean = false;
  @Prop isDisableByEdm: boolean = false;
  @Prop isCon: number = -1;
  @Consume('pathInfos') pathInfos: NavPathStack;
  @StorageProp('foldStatus') foldStatus: number = -1;
  @Prop isEFL: boolean = true;
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('fontSizeScaleMargin') fontSizeScaleMargin: string = '';
  @Prop isFiveG: boolean = true;
  @BuilderParam dialogBuildParams: object;
  @StorageProp('topMarginOnScal') topMarginOnScal: string = '10vp';
  @StorageProp('bottomMarginOnScal') bottomMarginOnScal: string = '11vp';
  @Prop isShowSwitchStateText: boolean = false;

  dialogTitle: string = '';
  radio_state_enable5g = 'RADIO_STATE_ENABLE5G';
  recordTypeDialog?: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      primaryTitle: $r('app.string.mobile_data_tips'),
      content: $r('app.string.mobile_data_turn_on_data_roaming'),
      primaryButton:
      {
        value: $r('app.string.cancel_space'),
        action: () => {
          this.recordTypeDialog?.close();
          this.controlSwitch = false;
        }
      },
      secondaryButton: {
        value: $r('app.string.confim_space'),
        action: () => {
          this.recordTypeDialog?.close();
          this.controlSwitch = true;
          this.cardType === 0 ? enableCellularDataRoamingCardOne() : enableCellularDataRoamingCardTwo();
        }
      }
    }),
    autoCancel: false,
    // showInSubWindow: true
  })

  build() {
    Column() {
      if (this.fontSizeScale >= FontScale.FourthGear && this.title.id === $r('app.string.wifi_calling').id) {
        this.fontSizeScaleBig();
      } else {
        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
          this.listColumnBuilder()
          this.statusToggleBuilder()
        }
        .enabled(this.isEnabled)
        .accessibilityGroup(true)
        .onClick(() => {
          LogUtils.i(TAG, 'onclick clickHandle')
          if (this.isCon === 33) {
            this.onApnItemClicked();
          } else if (this.isCon === 55) {
            DynamicLoader.getInstance().callFunction('WifiCallingSettings').then(() => {
              let param: pathParams = { slotId: this.cardType };
              this.pathInfos.pushPathByName('WifiCallingSettings', param);
              CallSettingVM.getInstance().setIsFromExternal(false);
            });
          }
        })
        // 覆盖数据漫游的单只双击朗读无障碍文本，且可以读出不可用的状态
        .accessibilityDescription(this.isCon != 33 && this.isEnabled ? ' ' : '')
      }
    }
  }

  @Builder
  listColumnBuilder() {
    Column() {
      Text(this.title)
        .fontFamily('HarmonyHeiTi')
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .constraintSize({ minHeight: 22 })
        .textAlign(TextAlign.Start)
        .margin({
          top: this.describeDisabled || this.describe == $r('app.string.mobile_empty_string') ?
          this.fontSizeScaleMargin : this.topMarginOnScal,
          bottom: this.describeDisabled || this.describe == $r('app.string.mobile_empty_string') ?
          this.fontSizeScaleMargin : $r('sys.float.padding_level1')
        })
      Text(this.describe)
        .margin({ bottom: this.bottomMarginOnScal })
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.font_secondary'))
        .constraintSize({ minHeight: 19 })
        .visibility(this.describeDisabled || this.describe == $r('app.string.mobile_empty_string') ?
        Visibility.None : Visibility.Visible)
    }
    .constraintSize({ minHeight: this.describeDisabled ? 48 : 64 })
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .margin({
      right: this.isShowSwitchStateText ? $r('sys.float.padding_level8') :
      $r('sys.float.ohos_id_text_margin_horizontal')
    })
    .enabled(this.isEnabled)
    .opacity(this.getOpacity())
  }

  @Builder
  statusToggleBuilder() {
    Text(this.controlSwitch ? $r('app.string.opened') : $r('app.string.closed'))
      .fontSize($r('sys.float.Subtitle_S'))
      .fontColor($r('sys.color.font_secondary'))
      .fontFamily('HarmonyHeiTi')
      .fontWeight(FontWeight.Regular)
      .textAlign(TextAlign.Start)
      .margin({ end: LengthMetrics.vp(4) })
      .visibility(this.isShowSwitchStateText ? Visibility.Visible : Visibility.None)
      .enabled(this.isEnabled)
      .opacity(this.isEnabled ? 1 : $r('sys.float.alpha_tertiary'))

    SymbolGlyph($r('sys.symbol.chevron_right'))
      .fontSize('24vp')
      .fontColor([$r('sys.color.icon_fourth')])
      .onClick(() => {
        LogUtils.i(TAG, 'onclick clickImage')
        if (this.isCon === 33) {
          DynamicLoader.getInstance().callFunction('apnIndex').then(() => {
            let param: apnParamType = { cardType: this.cardType };
            this.pathInfos.pushPathByName('apnIndex', param);
            ReportUtil.getInstance().reportCheckApnList(this.cardType + 1);
          })
        } else if (this.isCon === 55) {
          DynamicLoader.getInstance().callFunction('WifiCallingSettings').then(() => {
            let param: pathParams = { slotId: this.cardType };
            this.pathInfos.pushPathByName('WifiCallingSettings', param);
            CallSettingVM.getInstance().setIsFromExternal(false);
          });
        }
      })
      .enabled(this.isEnabled && !this.isDisableByEdm)
      .visibility(this.iconBtn ? Visibility.Visible : Visibility.None)
      .opacity(this.getOpacity())
      .draggable(false)

    Toggle({ type: ToggleType.Switch, isOn: this.controlSwitch ? true : false })
      .width('36vp')
      .height('20vp')
      .enabled(this.isEnabled)
      .selectedColor($r('sys.color.comp_background_emphasize'))
      .switchPointColor($r('sys.color.comp_background_primary_contrary'))
      .margin($r('sys.float.padding_level0'))
      .onChange((isOn) => {
        if (isOn === this.controlSwitch) {
          return;
        }
        this.controlSwitch = !this.controlSwitch;
        LogUtils.i(TAG, 'onclick cardType is :' + JSON.stringify(this.cardType) + 'switcher is:' +
        JSON.stringify(this.isCon) + 'Switch status:' + this.controlSwitch);
        if (this.controlSwitch && this.isCon === 0) {
          this.recordTypeDialog?.open();
        } else if (this.controlSwitch == false && this.isCon === 0) {
          this.cardType === 0 ? disableCellularDataRoamingCardOne() : disableCellularDataRoamingCardTwo();
        }
        if (this.isCon === 22 && this.controlSwitch) {
          this.cardType === 0 ? enableImsSwitchCardOne() : enableImsSwitchCardTwo();
        } else if (this.isCon === 22 && this.controlSwitch === false) {
          this.cardType === 0 ? disableImsSwitchCardOne() : disableImsSwitchCardTwo();
        }
        this.lteNrSwitchMethod();
      })
      .hoverEffect(HoverEffect.None)
      .visibility(this.isBtn ? Visibility.Visible : Visibility.None)
      .accessibilityLevel('yes')
  }

  @Builder
  fontSizeScaleBig() {
    Column() {
      Column() {
        Text(this.title)
          .fontFamily('HarmonyHeiTi')
          .fontSize($r('sys.float.Subtitle_M'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .constraintSize({ minHeight: 22 })
          .textAlign(TextAlign.Start)
          .margin({
            top: this.describeDisabled || this.describe == $r('app.string.mobile_empty_string') ?
            this.fontSizeScaleMargin : $r('sys.float.padding_level5'),
          })
          .id(`callSetting_common_components_listItem_bigFontSize_${this.title.id}`)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: 2 })

      Column() {
        Row() {
          this.statusToggleBuilder()
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({
        bottom: this.fontSizeScaleMargin
      })
    }
    .enabled(this.isEnabled)
    .onClick(() => {
      LogUtils.i(TAG, 'onclick clickHandle')
      if (this.isCon === 33) {
        let param: apnParamType = { cardType: this.cardType };
        this.pathInfos.pushPathByName('apnIndex', param);
        ReportUtil.getInstance().reportCheckApnList(this.cardType + 1);
      } else if (this.isCon === 55) {
        DynamicLoader.getInstance().callFunction('WifiCallingSettings').then(() => {
          let param: pathParams = { slotId: this.cardType };
          this.pathInfos.pushPathByName('WifiCallingSettings', param);
          CallSettingVM.getInstance().setIsFromExternal(false);
        });
      }
    })
    .accessibilityGroup(true)
  }

  private lteNrSwitchMethod() {
    if (this.isCon === 44 && this.controlSwitch) {
      this.isEFL ? setNetworkCapabilityNROn(this.cardType) : setNetworkCapabilityLTEOn(this.cardType);
    } else if (this.isCon === 44 && this.controlSwitch === false) {
      this.isEFL ? setNetworkCapabilityNROff(this.cardType) : setNetworkCapabilityLTEOff(this.cardType);
    }
  }

  private onApnItemClicked() {
    if (this.isDisableByEdm) {
      ToastUtil.handleMultiToast($r('app.string.edm_operate_prohibit_tip'));
    } else {
      DynamicLoader.getInstance().callFunction('apnIndex').then(() => {
        let param: apnParamType = { cardType: this.cardType };
        this.pathInfos.pushPathByName('apnIndex', param);
        ReportUtil.getInstance().reportCheckApnList(this.cardType + 1);
      })
    }
  }

  private getOpacity(): number | Resource {
    return (this.isEnabled && !this.isDisableByEdm) ? 1 : $r('sys.float.alpha_tertiary');
  }
}
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

import { LengthMetrics, SelectDialog } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BusinessError, settings } from '@kit.BasicServicesKit';
import { LogUtils, ReportUtil, TitleBarLayout, TitleParams } from '@ohos/common/CommonIndex';
import { getPaddingByDevice } from '../common/utils/Utils';
import * as CallSettingsConstant from '../common/constant/CallSettingsConstant';
import { StringUtil } from '../common/utils/StringUtil';
import queryAddData from '../common/utils/queryAddData';
import { FontScale } from '../common/utils/FontScaleState';
import CallSettingVM from '../viewModel/CallSettingVM';
// import { NavDestination,  HdsNavDestinationAttribute, HdsNavDestinationTitleMode } from '@kit.UIDesignKit';

export enum VoWifiPreferSettings {
  PREFER_WIFI = '0', // WiFi优先
  PREFER_CELLULAR = '1' // 移动网络优先
}

interface pathParams {
  slotId: number;
}

const TAG = 'WifiCallingSettings';

export const WIFI_CALLING_SETTINGS_PATH_NAME = 'WifiCallingSettings';
const commons: queryAddData = new queryAddData();

@Component
export default struct WifiCallingSettings {
  scroller: Scroller = new Scroller();
  @Consume('pathInfos') pathInfos: NavPathStack;
  @State slotId: number = -1;
  @State selectedRadioId: number = -1;
  @State context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State navTitle: string = StringUtil.formatResourceToString($r('app.string.wifi_calling'));
  @State wifiCallingSwitchState: boolean = false;
  @StorageLink('wifiCallingSwitchStateCard1') @Watch('wifiCallingSwitchStateChange') wifiCallingSwitchStateCard1: boolean =
    false;
  @StorageLink('wifiCallingSwitchStateCard2') @Watch('wifiCallingSwitchStateChange') wifiCallingSwitchStateCard2: boolean =
    false;
  @StorageLink('wifiCallingImsModeCard1') @Watch('wifiCallingImsModeChange') wifiCallingImsModeCard1: string =
    CallSettingsConstant.WIFI_CALLING_IMS_MODE_WIFI;
  @StorageLink('wifiCallingImsModeCard2') @Watch('wifiCallingImsModeChange') wifiCallingImsModeCard2: string =
    CallSettingsConstant.WIFI_CALLING_IMS_MODE_WIFI;
  // 判断是否使用模态窗口拉起
  @State isFromExternal: boolean = CallSettingVM.getInstance().getIsFromExternal();
  // 判断半模态是否有叉号
  @State isCrossMarkExists: boolean = CallSettingVM.getInstance().getIsFromExternal();
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('fontSizeScaleMargin') fontSizeScaleMargin: string = '0vp';

  preferSettingsSelectDialog: CustomDialogController = new CustomDialogController({
    builder: this.SelectDialogBuilder
  });
  voWifiPreferSettingsMap: Record<string, string> = {
    [VoWifiPreferSettings.PREFER_WIFI]: '2',
    [VoWifiPreferSettings.PREFER_CELLULAR]: '3'
  }
  voWifiPreferDomainMap: Record<string, string> = {
    '2': VoWifiPreferSettings.PREFER_WIFI,
    '3': VoWifiPreferSettings.PREFER_CELLULAR
  }

  aboutToAppear(): void {
    LogUtils.i(TAG, `aboutToAppear, isFromExternal: ${this.isFromExternal}`);
    const pathParamsLen = this.pathInfos.getParamByName('WifiCallingSettings').length;
    if (pathParamsLen) {
      let params: pathParams = this.pathInfos.getParamByName('WifiCallingSettings')[pathParamsLen - 1] as pathParams;
      LogUtils.i(TAG, `params: ${JSON.stringify(params)}`);
      this.slotId = params.slotId;
      this.getWifiCallingSwitchState();
      this.getWifiCallingImsMode();
    }
  }

  wifiCallingSwitchStateChange() {
    this.wifiCallingSwitchState =
      this.slotId === 0 ? this.wifiCallingSwitchStateCard1 : this.wifiCallingSwitchStateCard2;
    LogUtils.i(TAG, `wifiCallingSwitchState: ${this.wifiCallingSwitchState}`);
  }

  wifiCallingImsModeChange() {
    this.selectedRadioId = this.slotId === 0 ? Number(this.voWifiPreferDomainMap[this.wifiCallingImsModeCard1]) :
    Number(this.voWifiPreferDomainMap[this.wifiCallingImsModeCard2]);
    LogUtils.i(TAG, `wifiCallingImsModeChange selectedRadioId: ${this.selectedRadioId}`);
  }

  getWifiCallingSwitchState() {
    const key = `${CallSettingsConstant.WIFI_CALLING_ENABLED}_${this.slotId}`;
    const defValue = CallSettingsConstant.WIFI_CALLING_SWITCH_OFF;
    try {
      const result: string = settings.getValueSync(this.context, key, defValue, settings.domainName.USER_PROPERTY);
      LogUtils.i(TAG, `getWifiCallingSwitchState ${key}: ${result}`);
      this.wifiCallingSwitchState = result === CallSettingsConstant.WIFI_CALLING_SWITCH_ON;
    } catch (err) {
      LogUtils.e(TAG, `getWifiCallingSwitchState failed, err: ${JSON.stringify(err)}`);
    }
  }

  getWifiCallingImsMode() {
    const key = `${CallSettingsConstant.WIFI_CALLING_IMS_MODE}_${this.slotId}`;
    let result: string = commons.getWifiCallingImsMode(this.context, key);
    LogUtils.i(TAG, `getWifiCallingImsMode ${key}: ${result}`);
    if (result) {
      this.selectedRadioId = Number(this.voWifiPreferDomainMap[result]);
    }
  }

  setSettingsValue(key: string, value: string) {
    LogUtils.i(TAG, `setSettingsValue ${key}: ${value}`);
    try {
      const result = settings.setValueSync(this.context, key, value, settings.domainName.USER_PROPERTY);
      LogUtils.i(TAG, `setSettingsValue result: ${result}`);
    } catch (err) {
      LogUtils.e(TAG, `setSettingsValue failed, err: ${JSON.stringify(err)}`);
    }
  }

  onWifiCallingSwitchChange(isOn: boolean) {
    const key = `${CallSettingsConstant.WIFI_CALLING_ENABLED}_${this.slotId}`;
    const value = isOn ? CallSettingsConstant.WIFI_CALLING_SWITCH_ON : CallSettingsConstant.WIFI_CALLING_SWITCH_OFF;
    this.setSettingsValue(key, value);
  }

  saveTo(selectedRadioId: number) {
    const key = `${CallSettingsConstant.WIFI_CALLING_IMS_MODE}_${this.slotId}`;
    const value = this.voWifiPreferSettingsMap[selectedRadioId.toString()];
    this.setSettingsValue(key, value);
    if (this.slotId === 0) {
      this.wifiCallingImsModeCard1 = value;
    } else {
      this.wifiCallingImsModeCard2 = value;
    }
  }

  build() {
    NavDestination() {
      Scroll(this.scroller) {
        GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: { x: 24 } }) {
          GridCol({ span: { xs: 2, sm: 4, md: 8, lg: 12 } }) {
            Column() {
              Row() {
                Text($r('app.string.wifi_calling_tips'))
                  .fontSize($r('sys.float.Body_M'))
                  .fontColor($r('sys.color.font_secondary'))
                  .fontFamily('HarmonyHeiTi')
                  .fontWeight(FontWeight.Regular)
                  .margin({
                    left: 28,
                    right: 28,
                    top: $r('sys.float.padding_level8'),
                    bottom: $r('sys.float.padding_level8')
                  })
              }

              List() {
                ListItemGroup() {
                  ListItem() {
                    this.wifiCallingToggleItemBuilder();
                  }

                  ListItem() {
                    Column() {
                      this.preferenceSettingsItemBuilder();
                    }
                    .constraintSize({ minHeight: 48 })
                    .padding({
                      top: this.fontSizeScaleMargin,
                      bottom: this.fontSizeScaleMargin
                    })
                  }
                }
                .borderRadius($r('sys.float.corner_radius_level10'))
                .backgroundColor(this.isFromExternal ? $r('sys.color.comp_background_list_card') :
                $r('sys.color.comp_background_primary'))
                .divider({
                  strokeWidth: '1px',
                  color: $r('sys.color.comp_divider'),
                })
                .padding({
                  left: $r('sys.float.padding_level6'),
                  right: $r('sys.float.padding_level6'),
                  top: $r('sys.float.padding_level2'),
                  bottom: $r('sys.float.padding_level2'),
                })
              }
              .padding({
                left: getPaddingByDevice(),
                right: getPaddingByDevice()
              })
              .scrollBar(BarState.Off)
              .edgeEffect(EdgeEffect.None)
            }
          }
        }
      }
      .align(Alignment.Top)
      .height('100%')
      .margin({ top: this.isFromExternal ? '8vp' : '0' })
      .edgeEffect(EdgeEffect.Spring)
      .scrollBar(BarState.Off)
      .clip(false)
    }
    // .titleMode(this.isFromExternal ? HdsHdsNavDestinationTitleMode.MODAL : HdsHdsNavDestinationTitleMode.MINI)
    // .titleBar(TitleParams.MiniTitleParams($r('app.string.wifi_calling'),
    //     this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
    //     $r('sys.color.background_secondary'), this.isCrossMarkExists))
    .title(this.myTitleBar)
    .backgroundColor(this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
    $r('sys.color.background_secondary'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
    .onBackPressed(() => {
      this.pathInfos.pop();
      return true;
    })
  }
  @Builder
  myTitleBar(){
    TitleBarLayout($r('app.string.wifi_calling') ,this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
      $r('sys.color.background_secondary'), this.isCrossMarkExists)
  }

  @Builder
  wifiCallingToggleItemBuilder() {
    Column() {
      Flex({
        direction: FlexDirection.Row,
        justifyContent: FlexAlign.SpaceBetween,
        alignItems: ItemAlign.Center
      }) {
        Row() {
          Text($r('app.string.wifi_calling'))
            .fontSize($r('sys.float.Subtitle_M'))
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Medium)
        }
        .layoutWeight(1)

        Row() {
          Toggle({
            type: ToggleType.Switch,
            isOn: this.wifiCallingSwitchState
          })
            .size({ width: 36, height: 20 })
            .selectedColor($r('sys.color.comp_background_emphasize'))
            .switchPointColor($r('sys.color.comp_background_primary_contrary'))
            .margin(0)
            .hoverEffect(HoverEffect.None)
            .accessibilityLevel('yes')
            .onChange((isOn: boolean) => {
              if (this.slotId === 0) {
                if (isOn !== this.wifiCallingSwitchStateCard1) {
                  this.wifiCallingSwitchStateCard1 = isOn;
                }
              } else {
                if (isOn !== this.wifiCallingSwitchStateCard2) {
                  this.wifiCallingSwitchStateCard2 = isOn;
                }
              }
              this.onWifiCallingSwitchChange(isOn);
              ReportUtil.getInstance().reportWifiCallingSwitchState(isOn);
            })
        }
        .margin({ left: $r('sys.float.padding_level7') })
      }
    }
    .constraintSize({ minHeight: 48 })
    .padding({
      top: this.fontSizeScaleMargin,
      bottom: this.fontSizeScaleMargin
    })
  }

  @Builder
  preferenceSettingsItemBuilder() {
    if (this.fontSizeScale >= FontScale.FourthGear) {
      this.fontSizeScaleBigBuilder();
    } else {
      Flex({
        direction: FlexDirection.Row,
        justifyContent: FlexAlign.SpaceBetween,
        alignItems: ItemAlign.Center
      }) {
        Row() {
          Text($r('app.string.preference_settings'))
            .fontSize($r('sys.float.Subtitle_M'))
            .fontColor(this.wifiCallingSwitchState ? $r('sys.color.ohos_id_color_text_primary') :
            $r('sys.color.ohos_id_color_text_tertiary'))
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Medium)
        }
        .layoutWeight(1)

        Row() {
          Text(this.selectedRadioId === Number(VoWifiPreferSettings.PREFER_WIFI) ? $r('app.string.WiFi_first') :
          $r('app.string.vowifi_mobile_network_preferred'))
            .fontSize($r('sys.float.Subtitle_S'))
            .fontColor(this.wifiCallingSwitchState ? $r('sys.color.font_secondary') : $r('sys.color.font_tertiary'))
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Regular)
            .textAlign(TextAlign.Start)
            .margin({ end: LengthMetrics.vp(4) })

          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize('24vp')
            .fontColor([$r('sys.color.icon_fourth')])
            .draggable(false)
        }
        .margin({ left: $r('sys.float.padding_level8') })
      }
      .enabled(this.wifiCallingSwitchState)
      .onClick(() => {
        if (this.wifiCallingSwitchState) {
          this.preferSettingsSelectDialog.open();
        }
      })
    }
  }

  @Builder
  SelectDialogBuilder() {
    SelectDialog({
      title: $r('app.string.preference_settings'),
      selectedIndex: this.selectedRadioId,
      confirm: {
        value: $r('app.string.cancel'),
        action: () => {
          this.preferSettingsSelectDialog?.close();
        },
      },
      radioContent: [
        {
          title: $r('app.string.WiFi_first'),
          action: () => {
            this.selectedRadioId = Number(VoWifiPreferSettings.PREFER_WIFI);
            this.preferSettingsSelectDialog?.close();
            this.saveTo(this.selectedRadioId);
          }
        },
        {
          title: $r('app.string.vowifi_mobile_network_preferred'),
          action: () => {
            this.selectedRadioId = Number(VoWifiPreferSettings.PREFER_CELLULAR);
            this.preferSettingsSelectDialog?.close();
            this.saveTo(this.selectedRadioId);
          }
        },
      ]
    })
  }

  @Builder
  fontSizeScaleBigBuilder() {
    Column() {
      Row() {
        Text($r('app.string.preference_settings'))
          .fontSize($r('sys.float.Subtitle_M'))
          .fontColor(this.wifiCallingSwitchState ? $r('sys.color.ohos_id_color_text_primary') :
          $r('sys.color.ohos_id_color_text_tertiary'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .margin({ bottom: 2 })

      Column() {
        Row() {
          Text(this.selectedRadioId === Number(VoWifiPreferSettings.PREFER_WIFI) ? $r('app.string.WiFi_first') :
          $r('app.string.vowifi_mobile_network_preferred'))
            .fontSize($r('sys.float.Subtitle_S'))
            .fontColor(this.wifiCallingSwitchState ? $r('sys.color.font_secondary') : $r('sys.color.font_tertiary'))
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Regular)
            .textAlign(TextAlign.Start)
            .margin({ end: LengthMetrics.vp(4) })

          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize('24vp')
            .fontColor([$r('sys.color.icon_fourth')])
            .draggable(false)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .enabled(this.wifiCallingSwitchState)
    .onClick(() => {
      if (this.wifiCallingSwitchState) {
        this.preferSettingsSelectDialog.open();
      }
    })
  }
}
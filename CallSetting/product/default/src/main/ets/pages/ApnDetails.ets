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

import {
  LogUtils,
  DetailsCommon,
  ApnParamClass,
  OptionClass,
  SubDataType,
  updateObjectValue,
  TitleBarLayout
} from '@ohos/common/CommonIndex';
import { EditableTitleBar, EditableLeftIconType } from '@ohos.arkui.advanced.EditableTitleBar'
import { formatResourceToString } from '../common/utils/formatResourceToString';
import systemParameterEnhance from '@ohos.systemParameterEnhance';
import { ApnDetailDialogContent } from '../common/components/ApnDetailDialogContent';
import { CustomContentDialog, AlertDialog } from '@ohos.arkui.advanced.Dialog';
import { getPaddingByDevice, isTablet } from '../common/utils/Utils';
import { phoneFormat } from '../common/utils/SimIdFormat';
import { FontScale } from '../common/utils/FontScaleState';
// import { NavDestination,  HdsNavDestinationAttribute } from '@kit.UIDesignKit';
import { LengthMetrics } from '@kit.ArkUI';


const TAG = 'ApnDetails ';
const FOLD_STATUS_EXPANDED = 1;
const FOLD_STATUS_HALF_FOLDED = 3;
const LAYOUT_WEIGHT_MAX = 1;
const LAYOUT_WEIGHT_DEFAULT = 0;

@Builder
export function apnDetailsLoader(): void {
  CallAPN();
}

@Component
export default struct CallAPN {
  @State common: DetailsCommon = new DetailsCommon();
  @State detailsList: SubDataType[] = [];
  @State index: number = -1;
  @State init: boolean = true;
  addAPN: Resource = $r('app.string.APN_ADD_APN');
  editAPN: Resource = $r('app.string.APN_EDIT_APN');
  @State showText: Resource = this.addAPN;
  @State dialogData: SubDataType = new SubDataType('', '');
  @Consume('pathInfos') pathInfos: NavPathStack;
  @StorageProp('foldStatus') foldStatus: number = -1;
  @State inputText: string | number = '';
  @State inputCheck: number[] = [];
  @State inputShowCounter: boolean = false;
  @State msg: ResourceStr = ''
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('fontSizeScaleMargin') fontSizeScaleMargin: string = '';
  private scroller: Scroller = new Scroller();
  private naviIndicatorHeight: number =  28;

  @Builder
  apnContentDialogContent() {
    ApnDetailDialogContent({
      inputText: this.inputText,
      inputCheck: this.inputCheck,
      inputShowCounter: this.inputShowCounter,
      common: this.common,
      dialogData: this.dialogData,
      controller: this.dialogController,
      update: () => {
        this.detailsList = this.common.getArray();
      },
    })
  }

  cancel() {
    this.inputText = '';
    this.inputCheck = [];
    this.inputShowCounter = false;
  }

  onUpdate(controller: CustomDialogController) {
    let data = this.dialogData;
    if (this.dialogData.type === 'Checkbox') {
      if (this.inputCheck.length === 0) {
        data.description = [0];
      } else {
        data.description = this.inputCheck;
      }
    } else {
      data.description = this.inputText;
    }
    this.common = updateObjectValue(data.key, data, this.common);
    this.detailsList = this.common.getArray();
    controller?.close();
  }

  dialogController: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: this.dialogData.displayName,
      contentBuilder: () => {
        this.apnContentDialogContent();
      },
      buttons: this.dialogData.type === 'Radio' ?
        [
          {
            value: $r('app.string.Apn_cancel'),
            action: () => {
              this.cancel();
              this.dialogController.close();
            }
          }
        ] : [
          {
            value: $r('app.string.Apn_cancel'),
            action: () => {
              this.cancel();
              this.dialogController.close();
            }
          },
          {
            value: $r('app.string.Apn_OK'),
            action: () => {
              this.onUpdate(this.dialogController);
            }
          }
        ]
    }),
    customStyle: false,
    autoCancel: false
  });

  async aboutToAppear() {
    LogUtils.i(TAG, '[aboutToAppear]');
    let obj: ApnParamClass | undefined = this.pathInfos.getParamByName('apnDetails')[this.pathInfos.getParamByName('apnDetails')
      .length - 1] as (ApnParamClass | undefined);
    LogUtils.i(TAG, '[obj]' + JSON.stringify(obj));
    if (obj && (obj.cardType === 0 || obj.cardType === 1)) {
      this.common.cardType = obj.cardType;
      this.common.mccmnc = obj.mccmnc;
      this.common.simId = obj.simId;
      this.common.opkey = systemParameterEnhance.getSync('telephony.sim.opkey' + obj.cardType, obj.mccmnc)
      this.common.isDefault = obj.isDefault;
      this.common.profileID = obj.profileID;
      if (obj.profileID === -1) {
        this.showText = this.addAPN;
        this.common.initData();
        this.detailsList = this.common.getArray();
      } else {
        this.showText = this.editAPN;
        await this.common.editData(obj.profileID);
        this.isSupportEditForPreAPN();
        this.detailsList = this.common.getArray();
      }
    } else {
      this.pathInfos.pop()
      LogUtils.e(TAG, 'aboutToAppear getParams null');
    }
  }

  private isSupportEditForPreAPN() {
    if (this.common.isDefault === 0) {
      let isSupportEdit = this.common.checkPreMadeAPNIsEdit(this.common.mccmnc);
      LogUtils.i(TAG, `isSupportEditForPreMadeAPN: ${isSupportEdit}`);
      if (isSupportEdit) {
        this.common.isDefault = 1;
      }
    }
  }

  @Styles
  normalStyles() {
    .backgroundColor(Color.Transparent)
  }


  onDialogButton(item: SubDataType) {
    if (item.type === 'Checkbox') {
      if ((item.description as number[]).length === 0) {
        item.description = [0];
      }
    }
    this.dialogData = item;
    if (this.dialogData.type === 'Checkbox') {
      this.inputCheck = this.dialogData.description as number[];
    } else {
      this.inputText = this.dialogData.description as string | number;
    }
    this.dialogController.open();
  }

  getShowText(item: SubDataType) {
    LogUtils.i(TAG, '[getShowText]' + JSON.stringify(item))
    let text: string = formatResourceToString($r('app.string.APN_Not_set'));
    if (item.type === 'TextInput') {
      if (item.description !== '') {
        text = item.description as string;
      }
    } else if (item.type === 'Number') {
      if (item.description !== '') {
        text = item.description as string;
      }
    } else if (item.type === 'Radio') {
      let index = item.option.findIndex((val: OptionClass) => val.value === item.description);
      text = index !== -1 ? formatResourceToString(item.option[index].title as Resource) :
      formatResourceToString($r('app.string.APN_Not_set'));
    } else if (item.type === 'Checkbox') {
      text = '';
      (item.description as number[]).forEach((num: number) => {
        let index = item.option.findIndex((val: OptionClass) => val.value === num);
        if (index !== -1) {
          if (text === '') {
            text = text + formatResourceToString(item.option[index].title as Resource);
          } else {
            text = text + ',' + formatResourceToString(item.option[index].title as Resource);
          }
        }
      })
    }
    if (text === '') {
      text = formatResourceToString($r('app.string.APN_Not_set'));
    }
    text = phoneFormat(text);
    return text.replace(new RegExp(' ', 'g'), '\t');
  }

  getPassWord(item: SubDataType) {
    let password = '';
    for (let i = 0; i < (item.description as string).length; i++) {
      password += '*';
    }
    return password === '' ? $r('app.string.APN_Not_set') : password;
  }

  async deleteData() {
    await this.common.deleteData();
  }

  routerBack() {
    if (this.common.isDefault === 0) {
      this.pathInfos.pop();
    } else {
      this.dialogRouterBackController.open();
    }
  }

  dialogRouterBackController: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.Apn_give_up_the_modification'),
      primaryButton: {
        value: $r('app.string.Apn_cancel'),
        action: () => {
          this.dialogRouterBackController.close();
        }
      },
      secondaryButton: {
        value: $r('app.string.Apn_OK'),
        action: () => {
          this.pathInfos.pop();
        }
      }
    }),
    autoCancel: false,
    showInSubWindow: true
  })

  async saveData() {
    if (this.common.name.description === '') {
      this.dialogMsg($r('app.string.Apn_The_name_cannot_be_empty'));
    } else if (this.common.apn.description === '') {
      this.dialogMsg($r('app.string.Apn_The_APN_cannot_be_empty'));
    } else if (this.common.mcc.description.toString()
      .length !== 3) {
      this.dialogMsg($r('app.string.Apn_The_MCC_must_be_a_3_digit_number'));
    } else if (this.common.mnc.description.toString()
      .length !== 3 && this.common.mnc.description.toString()
      .length !== 2) {
      this.dialogMsg($r('app.string.Apn_MNC_must_be_2_or_3_digits'));
    } else if (this.common.mnc.description.toString() !== this.common.simMnc) {
      await this.deleteData();
      this.pathInfos.pop();
    } else {
      if (this.common.apnType.description === '') {
        this.common.apnType.description = 'default';
      }
      await this.common.saveData();
      this.pathInfos.pop();
    }
  }

  dialogMsgController: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: this.msg,
      primaryButton: {
        value: $r('app.string.Apn_OK'),
        action: () => {
          this.dialogController.close();
        }
      }
    }),
    showInSubWindow: true
  })

  dialogMsg(msg: Resource) {
    this.msg = msg;
    this.dialogMsgController.open();
  }

  build() {
    NavDestination() {
      EditableTitleBar({
        title:this.showText,
        onCancel:()=>{
          this.routerBack()
        },
        onSave:async ()=>{
          await this.saveData();
        }
      })
        //.margin({end:LengthMetrics.vp(24)})

      GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: { x: 24 } }) {
        GridCol({ span: { xs: 2, sm: 4, md: 8, lg: 12 }, offset: { sm: 0, md: 1, lg: 2 } }) {
          Column() {
            this.listBuilder()

            Flex({
              direction: FlexDirection.Column,
              justifyContent: FlexAlign.SpaceBetween,
              alignItems: ItemAlign.Center
            }) {
              this.bottomDelectContentbuilder()
            }
            .enabled(this.common.isDefault === 0 ? false : true)
            .onClick(async () => {
              await this.deleteData();
              this.pathInfos.pop()
            })
            .visibility(this.common.profileID !== -1 && this.common.isDefault === 1 ?
            Visibility.Visible : Visibility.None)
            .width('100%')
            .height(52)
            .margin({ bottom : this.naviIndicatorHeight })
          }
          .height('100%')
          .width('100%')
          .backgroundColor($r('sys.color.background_secondary'))
        }
      }
    }
    // .titleBar({
    //   style: {
    //     scrollEffectOpts: {
    //       enableScrollEffect: false
    //     },
    //     originalStyle: {
    //       backgroundStyle: {
    //         backgroundColor: $r('sys.color.background_secondary')
    //       }
    //     }
    //   },
    //   avoidLayoutSafeArea: true,
    //   enableComponentSafeArea: true,
    //   content: {
    //     backIcon: {
    //       icon: this.common.isDefault === 0 ? $r('sys.symbol.chevron_left') : $r('sys.symbol.xmark'),
    //       label: this.common.isDefault === 0 ? $r('app.string.InfoEdit_back') : $r('app.string.close_button'),
    //       action: () => {
    //         this.routerBack()
    //       }
    //     },
    //     title: {
    //       mainTitle: this.showText
    //     },
    //     menu: this.common.isDefault === 0 ? undefined : {
    //       value: [
    //         {
    //           content: {
    //             icon: $r('sys.symbol.checkmark'),
    //             label: $r('app.string.save'),
    //             action: async () => {
    //               await this.saveData();
    //             }
    //           }
    //         }
    //       ]
    //     }
    //   }
    // })
    .hideTitleBar(true)
    //.title(this.myTitleBar)
    .padding({ top: 40  })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
    .backgroundColor($r('sys.color.background_secondary'))
  }
  @Builder
  myTitleBar(){
    TitleBarLayout(
      this.showText,
      $r('sys.color.background_secondary'),
      this.common.isDefault !== 0,
      0,
      {
        icon: this.common.isDefault === 0 ? $r('sys.symbol.chevron_left') : $r('sys.symbol.xmark'),
        label: this.common.isDefault === 0 ? $r('app.string.InfoEdit_back') : $r('app.string.close_button'),
        pathInfos: this.pathInfos
      },
      this.common.isDefault === 0 ? undefined : {
        value: [
          {
            value: $r('app.string.save'),
            icon: $r('sys.symbol.checkmark'),
            action: async () => {
              await this.saveData();
            }
          }
        ]
      }
    )
  }

  @Builder
  bottomDelectContentbuilder() {
    Column() {
      SymbolGlyph($r('sys.symbol.trash'))
        .fontSize($r('app.float.wh_value_24'))
        .fontColor([$r('sys.color.icon_primary')])
        .draggable(false)
    }
    .width(24)
    .height(24)
    .margin({ top: 5 })

    Column() {
      Text($r('app.string.Apn_Deleting_an_APN'))
        .fontSize('10vp')
        .fontWeight(FontWeight.Medium)
        .height('14vp')
        .height(14)
        .fontColor($r('sys.color.font_primary'))
    }
    .height(14)
    .margin({ bottom: 5 })
  }

  @Builder
  itemFoot(item: SubDataType) {
    if (item.type === 'Toggle') {
      Text($r('app.string.Apn_APN_enabled'))
        .width('100%')
        .textAlign(TextAlign.Start)
        .padding({ left: $r('sys.float.padding_level6') })
        .fontSize($r('sys.float.Subtitle_S'))
        .fontColor($r('sys.color.font_secondary'))
        .fontWeight(FontWeight.Regular)
        .constraintSize({ minHeight: 19 })
        .opacity(1)
        .margin({
          top: $r('sys.float.padding_level4'),
          bottom: $r('sys.float.padding_level4'),
        })
    }
  }

  @Builder
  listBuilder() {
    List({ scroller: this.scroller }) {
      ForEach(this.detailsList, (item: SubDataType, index?: number) => {
        ListItemGroup({ footer: this.itemFoot(item) }) {
          ListItem() {
            Column() {
              Column() {
                if (item.type === 'Toggle') {
                  this.TypeToggleContent(item, index)
                } else {
                  this.listSubBiulder(item, index)
                }
              }
              .padding({
                left: $r('sys.float.padding_level2'),
                right: $r('sys.float.padding_level2'),
                top: $r('sys.float.padding_level2')
              })
              .borderRadius($r('sys.float.corner_radius_level10'))
              .backgroundColor($r('sys.color.comp_background_primary'))
              .constraintSize({ minHeight: 56 });
            };
          }.margin({
            top: index === 0 ? $r('sys.float.padding_level8') : $r('sys.float.padding_level0'),
            bottom: this.getBottpmSpace(item, index),
          })
          .enabled((this.common.isDefault === 0 ||
            (item.key === 'mvnoValue' && this.common.mvnoType.description === '0')) ? false : true);
        }
        .margin({
          left: getPaddingByDevice(),
          right: getPaddingByDevice()
        })
      }, (item: SubDataType, index: number) => {
        return `listContentBuider_${index}`;
      });
    }
    .scrollBar(BarState.Off)
    .width('100%')
    .layoutWeight(1)

    ScrollBar({
      scroller: this.scroller,
      direction: ScrollBarDirection.Vertical,
      state: BarState.Auto
    })
      .position({ top: 0, right: 0 })
      // 卡片距离标题栏 16 + 滑动条距离 4
      .margin({ top: 20, bottom: this.naviIndicatorHeight })
      .layoutWeight(1)
  }

  getBottpmSpace(item: SubDataType, index?: number): Resource {
    if (this.common.profileID !== -1 && this.common.isDefault === 1) {
      return item.type === 'Toggle' ? $r('sys.float.padding_level0') : $r('sys.float.padding_level6');
    } else {
      return this.detailsList.length - 1 === index ? $r('sys.float.padding_level16') :
        item.type === 'Toggle' ? $r('sys.float.padding_level0') : $r('sys.float.padding_level6');
    }
  }

  @Builder
  listSubBiulder(item: SubDataType, index: number | undefined) {
    Column() {
      Flex({
        direction: this.fontSizeScale < 1.75 ? FlexDirection.Row : FlexDirection.Column,
        justifyContent: this.fontSizeScale < 1.75 ? FlexAlign.SpaceBetween : FlexAlign.Start,
        alignItems: this.fontSizeScale < 1.75 ? ItemAlign.Center : ItemAlign.Start
      }) {
        Text(item.displayName)
          .fontSize($r('sys.float.Subtitle_M'))
          .fontColor($r('sys.color.font_primary'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Medium)
          .constraintSize({ minHeight: 22 })
          .textAlign(TextAlign.Start)
          .flexShrink(0)
          .margin({
            top: this.fontSizeScaleMargin,
            bottom: this.fontSizeScale < 1.75 ? this.fontSizeScaleMargin :
            $r('sys.float.padding_level1'),
            end: LengthMetrics.vp(8)
          })
          .opacity(this.common.isDefault === 0 ||
            (item.key === 'mvnoValue' && this.common.mvnoType.description === '0') ? 0.4 : 1)
          .id(`callSetting_pages_apnDetails_flexText_${index}`);

        this.listSubPasswordBuilder(item, index)
      }
      .width('100%')
      .padding({ left: $r('sys.float.padding_level4'), right: $r('sys.float.padding_level4') })
      .onClick(() => {
        if (item.type === 'Toggle') {
          return;
        }
        this.onDialogButton(item);
      });
    }
  }

  @Builder
  listSubPasswordBuilder(item: SubDataType, index: number | undefined) {
    if (item.key === 'passWord') {
      Text(this.getPassWord(item))
        .fontColor($r('sys.color.font_secondary'))
        .fontSize($r('sys.float.Subtitle_S'))
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .constraintSize({ minHeight: 22 })
        .textAlign(this.fontSizeScale < 1.75 ? TextAlign.End : TextAlign.Start)
        .opacity(this.common.isDefault === 0 ? $r('sys.float.alpha_disable') : 1)
        .margin({
          top: this.fontSizeScale < 1.75 ? this.fontSizeScaleMargin :
          $r('sys.float.padding_level0'),
          bottom: this.fontSizeScaleMargin
        })
        .id(`callSetting_pages_apnDetails_flexText_passWord_${index}`);
    } else {
      Text(this.getShowText(item))
        .fontColor($r('sys.color.font_secondary'))
        .fontSize($r('sys.float.Subtitle_S'))
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .constraintSize({ minHeight: 22 })
        .textAlign(this.fontSizeScale < 1.75 ? TextAlign.End : TextAlign.Start)
        .margin({
          top: this.fontSizeScale < 1.75 ? this.fontSizeScaleMargin :
          $r('sys.float.padding_level0'),
          bottom: this.fontSizeScaleMargin
        })
        .opacity(this.common.isDefault === 0 ||
          (item.key === 'mvnoValue' && this.common.mvnoType.description === '0') ? 0.4 : 1)
        .width('auto')
        .id(`callSetting_pages_apnDetails_flexText_getShowText_${index}`);
    }
  }

  @Builder
  TypeToggleContent(item: SubDataType, index: number | undefined) {
    Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
      Text(item.displayName)
        .fontSize($r('sys.float.Subtitle_M'))
        .fontColor($r('sys.color.font_primary'))
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Medium)
        .constraintSize({ minHeight: 22 })
        .textAlign(TextAlign.Start)
        .margin({
          right: $r('sys.float.padding_level2'),
          top: this.fontSizeScaleMargin,
          bottom: this.fontSizeScaleMargin
        })
        .opacity(this.common.isDefault === 0 || item.type === 'Toggle' ||
          (item.key === 'mvnoValue' && this.common.mvnoType.description === '0') ? 0.4 : 1)
        .id(`callSetting_pages_apnDetails_flexText_${index}`);

      Toggle({ type: ToggleType.Switch, isOn: true })
        .selectedColor($r('sys.color.comp_background_emphasize'))
        .switchPointColor($r('sys.color.comp_background_primary_contrary'))
        .enabled(false)
        .height(20)
        .id(`callSetting_pages_apnDetails_flexToggle_Toggle_${index}`);
    }
    .stateStyles({
      normal: this.normalStyles
    })
    .constraintSize({ minHeight: 48 })
    .width('100%')
    .padding({
      left: $r('sys.float.padding_level4'),
      right: $r('sys.float.padding_level4'),
    })
    .enabled(item.key !== 'apnState' ? true : false)
    .onClick(() => {
      if (item.type === 'Toggle') {
        return;
      }
      this.onDialogButton(item);
    })
  }
}

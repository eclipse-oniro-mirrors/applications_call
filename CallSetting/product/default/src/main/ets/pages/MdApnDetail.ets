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
import { display, promptAction, uiExtensionHost } from '@kit.ArkUI'
import {
  LogUtils,
  DetailsCommon,
  ApnParamClass,
  OptionClass,
  SubDataType,
  updateObjectValue
} from '@ohos/common/CommonIndex';
import { EditableTitleBar, EditableLeftIconType } from '@ohos.arkui.advanced.EditableTitleBar'
import { formatResourceToString } from '../common/utils/formatResourceToString';
import systemParameterEnhance from '@ohos.systemParameterEnhance';
import { ApnDetailDialogContent } from '../common/components/ApnDetailDialogContent';
import { CustomContentDialog, AlertDialog } from '@ohos.arkui.advanced.Dialog';
import { UIExtensionContentSession } from '@kit.AbilityKit';
import { emitter } from '@kit.BasicServicesKit';
import mediaquery from '@ohos.mediaquery'
import { phoneFormat } from '../common/utils/SimIdFormat';

let storage = LocalStorage.getShared()
const TAG = 'MdApnDetails ';
@Entry
@Component
export default struct MdApnDetail{
  public storage = LocalStorage.getShared();
  private session: UIExtensionContentSession = this.storage?.
  get<UIExtensionContentSession>('session') as UIExtensionContentSession;
  extensionWindow: uiExtensionHost.UIExtensionHostWindowProxy | undefined = this.session?.
  getUIExtensionHostWindowProxy();
  @State common: DetailsCommon = new DetailsCommon();
  @State detailsList: SubDataType[] = [];
  @State index: number = -1;
  @State init: boolean = true;
  addAPN: Resource = $r('app.string.APN_ADD_APN');
  editAPN: Resource = $r('app.string.APN_EDIT_APN');
  @State showText: Resource = this.addAPN;
  @State dialogData: SubDataType = new SubDataType('', '');
  @State inputText: string | number = '';
  @State inputCheck: number[] = [];
  @State inputShowCounter: boolean = false;
  @State msg: ResourceStr = ''
  @StorageProp('curBp') curBp: string = '';
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;
  @State isLandscape: boolean = false;
  listener: mediaquery.MediaQueryListener = mediaquery.matchMediaSync('(orientation: landscape)');

  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('fontSizeScaleMargin') fontSizeScaleMargin: string = '';
  @Link isShowBind: boolean;
  @StorageProp('foldStatus') foldStatus: number = -1;

  @Builder apnContentDialogContent() {
    ApnDetailDialogContent({
      inputText: this.inputText,
      inputCheck: this.inputCheck,
      inputShowCounter: this. inputShowCounter,
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
    this.detailsList = this.common.getArray()
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

  emitterCallback(eventData: emitter.EventData) {
    promptAction.showToast({message:'emitterCallback'})
  }

  async aboutToAppear() {
    try {
      this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
      this.screenHeight = px2vp(display.getDefaultDisplaySync().height)
    } catch (err) {
      LogUtils.e(TAG, `aboutToAppear: getDefaultDisplaySync error: ${err?.code} ${err?.message}`);
    }
    LogUtils.i(TAG, '[aboutToAppear]');

    let obj: ApnParamClass | undefined = AppStorage.get('apnDetail') as (ApnParamClass | undefined)
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
      this.destroyWindow();
      LogUtils.e(TAG, 'aboutToAppear getParams null');
    }

    let portraitFunc = (mediaQueryResult: mediaquery.MediaQueryResult) : void => this.onPortrait(mediaQueryResult);
    this.listener.on('change', portraitFunc);
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

  onPortrait(mediaQueryResult: mediaquery.MediaQueryResult) {
    if (mediaQueryResult.matches) {
      this.isLandscape = true;
    } else {
      this.isLandscape = false;
    }
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.interactive_click'))
    .borderRadius($r('sys.float.corner_radius_level9'))
    .constraintSize({ minHeight: 48 })
    .opacity(1)
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

  getShowText(item: SubDataType): string {
    LogUtils.i(TAG, '[getShowText]' + JSON.stringify(item))
    let text: string = formatResourceToString($r('app.string.APN_Not_set'));
    if (item.type === 'TextInput' && item.description !== '') {
      text = item.description as string;
    } else if (item.type === 'Number' && item.description !== '') {
      text = item.description as string;
    } else if (item.type === 'Radio') {
      let index = item.option.findIndex((val: OptionClass) => val.value === item.description);
      text = index !== -1 ? formatResourceToString(item.option[index].title as Resource) :
      formatResourceToString($r('app.string.APN_Not_set'));
    } else if (item.type === 'Checkbox') {
      text = this.showTextCheckBox(text, item);
    }
    if (text === '') {
      text = formatResourceToString($r('app.string.APN_Not_set'));
    }
    text = phoneFormat(text);
    return text.replace(new RegExp(' ', 'g'), '\t');
  }

  private showTextCheckBox(text: string, item: SubDataType): string {
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
    });
    return text;
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
    AppStorage.setOrCreate('apnList', Number(AppStorage.get('apnList')) + 1)
    AppStorage.delete('apnDetail')
    AppStorage.delete('apnList')
  }

  routerBack() {
    if (this.common.isDefault === 0) {
      this.destroyWindow();
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
         this.destroyWindow();
        }
      }
    }),
    autoCancel: false
  })

  destroyWindow() {
    AppStorage.setOrCreate('apnList', Number(AppStorage.get('apnList')) + 1)
    this.isShowBind = false
  }

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
    } else {
      if (this.common.apnType.description === '') {
        this.common.apnType.description = 'default';
      }
      await this.common.saveData();
      this.destroyWindow();
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
    })
  })
  dialogMsg(msg: Resource) {
    this.msg = msg;
    this.dialogMsgController.open();
  }

  build() {
    Stack({ alignContent: Alignment.Center} ){
      GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: { x: 24 } }) {
        GridCol({ span: { xs: 2, sm: 4, md: 8, lg: 12 }, offset: { sm: 0, md: 1, lg: 2 } }) {
          Column() {
            Column() {
              EditableTitleBar({
                leftIconStyle: this.common.isDefault === 0 ? EditableLeftIconType.Back : EditableLeftIconType.Cancel,
                title: this.showText,
                onCancel: () => {
                  this.routerBack();
                },
                onSave: async () => {
                  await this.saveData();
                },
              })
                .backgroundColor($r('sys.color.background_secondary'))
                .margin({ top: $r('sys.float.padding_level4'), bottom: $r('sys.float.padding_level4') })
                .borderRadius($r('sys.float.corner_radius_level16'))

              Flex({
                direction: FlexDirection.Column,
                justifyContent: FlexAlign.SpaceBetween,
                alignItems: ItemAlign.Center
              }) {
                this.listContentBuider()

                this.bottomDeleteBuilder()
              }
              .height('calc(100% - 72vp)')
            }
            .width('100%')
            .height('100%')
            .backgroundColor($r('sys.color.background_secondary'))
            .borderRadius($r('sys.float.corner_radius_level16'))
          }
        }
      }
    }
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
          top: $r('sys.float.padding_level4'), bottom: $r('sys.float.padding_level4')
        })
    }
  }

  @Builder
  listContentBuider() {
    List() {
      ForEach(this.detailsList, (item: SubDataType, index?: number) => {
        ListItemGroup({ footer: this.itemFoot(item) }) {
          ListItem() {
            this.listContentSubBilder(item, index)
          }.margin({
            bottom: this.getBottpmSpace(item, index),
          })
          .enabled((this.common.isDefault === 0 ||
            (item.key === 'mvnoValue' && this.common.mvnoType.description === '0')) ? false : true)
        }
        .margin({
          left: $r('sys.float.padding_level8'),
          right: $r('sys.float.padding_level8')
        })
      }, (item: SubDataType, index: number) => {
        return `listContentBuider_${index}`;
      });
    }
    .width('100%')
  }

  getBottpmSpace(item: SubDataType, index?: number): Resource {
    if (this.common.profileID !== -1 && this.common.isDefault === 1) {
      return (item.type === 'Toggle' || index === this.detailsList.length - 1) ? $r('sys.float.padding_level0') :
      $r('sys.float.padding_level6');
    } else {
      return (this.foldStatus === 2 && index === this.detailsList.length - 1) ? $r('sys.float.padding_level16') :
        item.type === 'Toggle' ? $r('sys.float.padding_level0') : $r('sys.float.padding_level6')
    }
  }

  @Builder
  listContentSubBilder(item: SubDataType, index: number | undefined) {
    Column() {
      Column() {
        this.listToggleBuilder(item, index)
      }
      .padding({
        left: $r('sys.float.padding_level2'),
        right: $r('sys.float.padding_level2'),
        top: $r('sys.float.padding_level2')
      })
      .borderRadius($r('sys.float.corner_radius_level10'))
      .backgroundColor($r('sys.color.comp_background_primary'))
      .constraintSize({ minHeight: 56 });
    }
  }

  @Builder
  listToggleBuilder(item: SubDataType, index: number | undefined) {
    if (item.type === 'Toggle') {
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        this.typeToggleBuilder(item, index);
      }
      .stateStyles({
        pressed: this.pressedStyles,
        normal: this.normalStyles
      })
      .constraintSize({ minHeight: 48 })
      .width('100%')
      .padding({ left: $r('sys.float.padding_level4'), right: $r('sys.float.padding_level4') })
      .enabled(item.key !== 'apnState' ? true : false)
      .onClick(() => {
        if (item.type === 'Toggle') {
          return;
        }
        this.onDialogButton(item);
      });
    } else {
      this.listContentTypeNototoggleBuilder(item, index);
    }
  }

  @Builder
  listContentTypeNototoggleBuilder(item: SubDataType, index: number | undefined) {
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
          .padding({ right: $r('sys.float.padding_level4') })
          .textAlign(TextAlign.Start)
          .flexShrink(0)
          .margin({
            top: this.fontSizeScaleMargin,
            bottom: this.fontSizeScale < 1.75 ? this.fontSizeScaleMargin : $r('sys.float.padding_level1')
          })
          .opacity(this.common.isDefault === 0 ||
            (item.key === 'mvnoValue' && this.common.mvnoType.description === '0') ? 0.4 : 1)
          .width('auto')
          .id(`callSetting_pages_mdApnDetails_flexText_${index}`);

        this.listContentTypeNototogglSubBuilde(item, index)
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
  listContentTypeNototogglSubBuilde(item: SubDataType, index: number | undefined) {
    if (item.key === 'passWord') {
      Text(this.getPassWord(item))
        .fontColor($r('sys.color.font_secondary'))
        .fontSize($r('sys.float.Subtitle_S'))
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .constraintSize({ minHeight: 22 })
        .textAlign(this.fontSizeScale < 1.75 ? TextAlign.End : TextAlign.Start)
        .margin({
          top: this.fontSizeScale < 1.75 ? this.fontSizeScaleMargin : $r('sys.float.padding_level0'),
          bottom: this.fontSizeScaleMargin
        })
        .opacity(this.common.isDefault === 0 ? $r('sys.float.alpha_disable') : 1)
        .id(`callSetting_pages_mdApnDetails_flexText_passWord_${index}`);
    } else {
      Text(this.getShowText(item))
        .fontColor($r('sys.color.font_secondary'))
        .fontSize($r('sys.float.Subtitle_S'))
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .constraintSize({ minHeight: 22 })
        .textAlign(this.fontSizeScale < 1.75 ? TextAlign.End : TextAlign.Start)
        .margin({
          top: this.fontSizeScale < 1.75 ? this.fontSizeScaleMargin : $r('sys.float.padding_level0'),
          bottom: this.fontSizeScaleMargin
        })
        .opacity(this.common.isDefault === 0 ||
          (item.key === 'mvnoValue' && this.common.mvnoType.description === '0') ? 0.4 : 1)
        .id(`callSetting_pages_mdApnDetails_flexText_getShowText_${index}`);
    }
  }

  @Builder
  typeToggleBuilder(item: SubDataType, index: number | undefined) {
    Text(item.displayName)
      .fontSize($r('sys.float.Subtitle_M'))
      .fontColor($r('sys.color.font_primary'))
      .fontFamily('HarmonyHeiTi')
      .fontWeight(FontWeight.Medium)
      .constraintSize({ minHeight: 22 })
      .margin({
        right: $r('sys.float.padding_level2'),
        top: this.fontSizeScaleMargin,
        bottom: this.fontSizeScaleMargin
      })
      .textAlign(TextAlign.Start)
      .opacity(this.common.isDefault === 0 || item.type === 'Toggle' ||
        (item.key === 'mvnoValue' && this.common.mvnoType.description === '0') ? 0.4 : 1)
      .id(`callSetting_pages_mdApnDetails_flexText_${index}`)
    Toggle({ type: ToggleType.Switch, isOn: true })
      .selectedColor($r('sys.color.comp_background_emphasize'))
      .switchPointColor($r('sys.color.comp_background_primary_contrary'))
      .enabled(false)
      .height(20)
      .id(`callSetting_pages_apnDetails_flexToggle_Toggle_${index}`)
  }

  @Builder
  listItemBuilder(item: SubDataType, index: number | undefined) {
    ListItem() {
      Column() {
        Column() {
          this.listContentFlexBuilder(item);
        }
        .padding({
          left: $r('sys.float.padding_level2'),
          right: $r('sys.float.padding_level2'),
          top: $r('sys.float.padding_level2')
        })
        .borderRadius($r('sys.float.corner_radius_level10'))
        .backgroundColor($r('sys.color.comp_background_primary'))
        .constraintSize({ minHeight: 56 });

        if (item.type === 'Toggle') {
          Text($r('app.string.Apn_APN_enabled'))
            .width('100%')
            .margin({ top: $r('sys.float.padding_level4') })
            .textAlign(TextAlign.Start)
            .padding({ left: $r('sys.float.padding_level6') })
            .fontSize($r('sys.float.Subtitle_S'))
            .fontColor($r('sys.color.font_secondary'))
            .fontWeight(FontWeight.Regular)
            .lineHeight(19)
            .opacity(1)
            .margin({
              top: $r('sys.float.padding_level4'),
              bottom: $r('sys.float.padding_level4')
            });
        }
      };
    }.margin({
      top: index === 0 ? $r('sys.float.padding_level4') : 0,
      bottom: index === this.detailsList.length - 1 ? 0 :
        item.type === 'Toggle' ? 0 : $r('sys.float.padding_level6'),
      left: $r('sys.float.padding_level8'),
      right: $r('sys.float.padding_level8')
    })
    .enabled((this.common.isDefault === 0 ||
      (item.key === 'mvnoValue' && this.common.mvnoType.description === '0')) ? false : true)
  }

  @Builder
  listContentFlexBuilder(item: SubDataType) {
    Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
      Text(item.displayName)
        .fontSize($r('sys.float.Subtitle_M'))
        .fontColor($r('sys.color.font_primary'))
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Medium)
        .constraintSize({ minHeight: 22 })
        .padding({ right: $r('sys.float.padding_level2') })
        .textAlign(TextAlign.Start)
        .maxLines(1)
        .displayPriority(1)
        .opacity(this.common.isDefault === 0 || item.type === 'Toggle' ||
          (item.key === 'mvnoValue' && this.common.mvnoType.description === '0') ? 0.4 : 1);

      this.judgmentBuilder(item);
    }
    .stateStyles({
      pressed: this.pressedStyles,
      normal: this.normalStyles
    })
    .constraintSize({ minHeight: 48 })
    .width('100%')
    .padding({ left: $r('sys.float.padding_level4'), right: $r('sys.float.padding_level4') })
    .onClick(() => {
      if (item.type === 'Toggle') {
        return;
      }
      this.onDialogButton(item);
    })
  }

  @Builder
  judgmentBuilder(item: SubDataType) {
    if (item.type === 'Toggle') {
      Toggle({ type: ToggleType.Switch, isOn: true })
        .selectedColor($r('sys.color.comp_background_emphasize'))
        .switchPointColor($r('sys.color.comp_background_primary_contrary'))
        .enabled(false)
        .height(20);
    } else if (item.key === 'passWord') {
      Text(this.getPassWord(item))
        .fontColor($r('sys.color.font_secondary'))
        .fontSize($r('sys.float.Subtitle_S'))
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .lineHeight(22)
        .textAlign(TextAlign.End)
        .opacity(this.common.isDefault === 0 ? $r('sys.float.alpha_disable') : 1);
    } else {
      Text(this.getShowText(item))
        .fontColor($r('sys.color.font_secondary'))
        .fontSize($r('sys.float.Subtitle_S'))
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .lineHeight(22)
        .textAlign(TextAlign.End)
        .opacity(this.common.isDefault === 0 ||
          (item.key === 'mvnoValue' && this.common.mvnoType.description === '0') ? 0.4 : 1);
    }
  }

  @Builder
  bottomDeleteBuilder() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.SpaceBetween,
      alignItems: ItemAlign.Center
    }) {
      Column() {
        SymbolGlyph($r('sys.symbol.trash'))
          .fontSize($r('app.float.wh_value_24'))
          .fontColor([$r('sys.color.icon_primary')])
          .draggable(false);
      }.width(24)
      .margin({ top: 5 });

      Column() {
        Text($r('app.string.Apn_Deleting_an_APN'))
          .fontSize('10vp')
          .fontWeight(FontWeight.Medium)
          .height('14vp')
          .height(14)
          .fontColor($r('sys.color.font_primary'));
      }
      .margin({ top: 4, bottom: 5 });
      Column() {}
      .height(16)
      .visibility(this.foldStatus === 2 ? Visibility.Visible : Visibility.None)
    }
    .enabled(this.common.isDefault === 0 ? false : true)
    .onClick(async () => {
      await this.deleteData();
      this.destroyWindow();
    })
    .visibility(this.common.profileID !== -1 && this.common.isDefault === 1 ?
    Visibility.Visible : Visibility.None)
    .width('100%')
    .height( this.foldStatus === 2 ? 68 : 52)
  }
}
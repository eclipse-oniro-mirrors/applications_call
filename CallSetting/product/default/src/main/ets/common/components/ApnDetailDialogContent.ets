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

import { LogUtils, OptionClass, SubDataType, DetailsCommon, updateObjectValue } from '@ohos/common/CommonIndex';
import sim from '@ohos.telephony.sim';

const TAG = 'ApnDetailDialogContent';

@Component
export struct ApnDetailDialogContent {
  textController: TextAreaController = new TextAreaController();
  @Link dialogData: SubDataType;
  @Link inputText: string | number;
  @Link inputShowCounter: boolean;
  @Link inputCheck: number[];
  @Link common: DetailsCommon;
  update: () => void = () => {
  };
  controller?: CustomDialogController;
  @State inputFocus: boolean = true;
  @StorageProp('curBp') curBp: string = '';
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('fontSizeScaleMargin') fontSizeScaleMargin: string = '0vp';

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
    .borderRadius($r('sys.float.corner_radius_level9'))
    .padding({
      left: $r('sys.float.padding_level0'),
      right: $r('sys.float.padding_level0')
    })
    .constraintSize({ minHeight: 40 })
    .opacity(1)
  }

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear dialogData option count ' + this.dialogData.option.length);
  }

  onTextInput(val: string) {
    this.inputText = val;
    this.inputShowCounter = val.toString().length > (this.dialogData.key === 'apn' ? 91 : 1000) * 0.9;
  }

  async onRadio(item: OptionClass, controller: CustomDialogController) {
    if (this.dialogData.key === 'mvnoType') {
      if (item.value === '0') {
        this.common.mvnoValue.description = '';
      } else if (item.value === '1') {
        this.common.mvnoValue.description = await sim.getSimSpn(this.common.cardType);
      } else if (item.value === '2') {
        this.common.mvnoValue.description = await sim.getSimOperatorNumeric(this.common.cardType) + 'x';
      } else if (item.value === '3') {
        this.common.mvnoValue.description = await sim.getSimGid1(this.common.cardType);
      }
      this.inputText = item.value;
      this.onUpdate(controller);
    } else {
      this.inputText = item.value;
      this.onUpdate(controller);
    }
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
    this.update();
    controller?.close();
  }

  onCheckbox(item: OptionClass) {
    let data = this.inputCheck;
    let index = data.findIndex((num: number) => num === item.value);
    LogUtils.i(TAG, '[mvnoValue]' + JSON.stringify(index));
    if (index !== -1) {
      data.splice(index, 1);
    } else {
      data.push(item.value as number);
    }
    data = Array.from(new Set(this.inputCheck));
    data.sort((a, b) => a - b);
    this.inputCheck = data;
  }

  build() {
    Column() {
      if (this.dialogData.type === 'Number') {
        TextInput({
          text: this.inputText as string,
          controller: this.textController
        })
          .backgroundColor(Color.Transparent)
          .type(InputType.Number)
          .width('100%')
          .constraintSize({ minHeight: 48, maxHeight: 100 })
          .onChange((val: string) => {
            this.onTextInput(val);
          })
          .onTouch(() => {
            this.inputFocus = true;
          })
          .onBlur(() => {
            this.inputFocus = false;
          })
          .align(Alignment.Center)
          .fontSize($r('sys.float.Subtitle_M'))
          .fontWeight(FontWeight.Regular)
          .fontColor($r('sys.color.font_primary'))
          .borderRadius($r('sys.float.corner_radius_none'))
          .borderWidth(0)
          .maxLength(this.dialogData.key === 'apn' ? 91 : 1000)
          .draggable(false)
          .focusable(this.inputFocus)
          .defaultFocus(true)
          .enableKeyboardOnFocus(true)
          .copyOption(this.dialogData?.key === 'passWord' ? CopyOptions.None : CopyOptions.LocalDevice)
          .selectionMenuHidden(this.dialogData?.key === 'passWord' ? true : false)
          .borderWidth(1)
          .borderColor(Color.Transparent)
          .padding({
            left: $r('sys.float.padding_level0'),
            right: $r('sys.float.padding_level0'),
          })
          .margin({ top: $r('sys.float.padding_level2') })
        Divider()
          .width('100%')
          .strokeWidth(this.inputFocus ? '2px' : '1px')
          .color(this.inputFocus ? $r('sys.color.icon_primary') : $r('sys.color.comp_divider'))
          .opacity(this.inputFocus ? 0.6 : 1)
          .visibility(this.inputText.toString().length === (this.dialogData.key === 'apn' ? 91 : 1000) ?
          Visibility.Hidden : Visibility.Visible)
          .margin({ top: -1, bottom: $r('sys.float.padding_level2') })
      } else if (this.dialogData.type === 'TextInput') {
        TextArea({
          text: this.inputText as string,
          controller: this.textController
        })
          .backgroundColor(Color.Transparent)
          .borderRadius($r('sys.float.corner_radius_none'))
          .width('100%')
          .constraintSize({ minHeight: 48, maxHeight: 100 })
          .onChange((val: string) => {
            this.onTextInput(val);
          })
          .onTouch(() => {
            this.inputFocus = true;
          })
          .onBlur(() => {
            this.inputFocus = false;
          })
          .align(Alignment.Center)
          .fontSize($r('sys.float.Subtitle_M'))
          .fontWeight(FontWeight.Regular)
          .fontColor($r('sys.color.font_primary'))
          .maxLength(this.dialogData.key === 'apn' ? 91 : 1000)
          .draggable(false)
          .focusable(this.inputFocus)
          .defaultFocus(true)
          .copyOption(this.dialogData?.key === 'passWord' ? CopyOptions.None : CopyOptions.LocalDevice)
          .selectionMenuHidden(this.dialogData?.key === 'passWord' ? true : false)
          .showCounter(this.inputShowCounter)
          .borderWidth(1)
          .borderColor(Color.Transparent)
          .onTextSelectionChange(() => {
            if (this.dialogData?.key === 'passWord') {
              this.textController.setTextSelection(this.inputText.toString().length, this.inputText.toString()
                .length)
            }
          })
          .padding({ left: $r('sys.float.padding_level0'), right: $r('sys.float.padding_level0') })
          .margin({ top: $r('sys.float.padding_level2') })
        Divider()
          .width('100%')
          .strokeWidth(this.inputFocus ? '2px' : '1px')
          .color(this.inputFocus ? $r('sys.color.icon_primary') : $r('sys.color.comp_divider'))
          .lineCap(LineCapStyle.Round)
          .opacity(this.inputFocus ? 0.6 : 1)
          .visibility(this.inputText.toString().length === (this.dialogData.key === 'apn' ? 91 : 1000) ?
          Visibility.Hidden : Visibility.Visible)
          .margin({ top: -1, bottom: $r('sys.float.padding_level2') })
      } else if (this.dialogData.type === 'Radio') {
        List() {
          ForEach(this.dialogData.option, (item: OptionClass, index?: number) => {
            ListItem() {
              Column() {
                Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
                  Text(item.title)
                    .fontSize($r('sys.float.Body_L'))
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('sys.color.font_primary'))
                    .padding({
                      top: this.fontSizeScaleMargin,
                      bottom: this.fontSizeScaleMargin
                    })
                    .id(`callSetting_components_apnDetailDialogContent_Radio_flexText_${this.dialogData.type}`)
                  Radio({ value: JSON.stringify(item.value), group: 'radioGroup' })
                    .checked(this.inputText === item.value)
                    .hoverEffect(HoverEffect.None)
                    .height(20)
                    .width(20)
                    .margin($r('sys.float.padding_level1'))
                    .onClick(() => {
                      this.onRadio(item, this.controller!);
                    })
                }
                .onClick(() => {
                  this.onRadio(item, this.controller!);
                })
                .padding({
                  left: $r('sys.float.padding_level4'),
                  right: $r('sys.float.padding_level4')
                })
                .accessibilityText(item.title as string)
                .accessibilityGroup(true)
                .constraintSize({ minHeight: 48 })
                if (index !== this.dialogData.option.length - 1) {
                  Divider()
                    .width('100%')
                    .color($r('sys.color.comp_divider'))
                    .lineCap(LineCapStyle.Round)
                    .padding({
                      left: $r('sys.float.padding_level4'),
                      right: $r('sys.float.padding_level4')
                    })
                }
              }
              .stateStyles({
                pressed: this.pressedStyles,
                normal: {
                  .backgroundColor(Color.Transparent)
                }
              })
            }
          })
        }
        .scrollBar(BarState.Off)
      } else if (this.dialogData.type === 'Checkbox') {
        List() {
          ForEach(this.dialogData.option, (item: OptionClass, index?: number) => {
            ListItem() {
              Column() {
                Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
                  Text(item.title)
                    .fontSize($r('sys.float.Body_L'))
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('sys.color.font_primary'))
                    .padding({
                      top: this.fontSizeScaleMargin,
                      bottom: this.fontSizeScaleMargin
                    })
                    .id(`callSetting_components_apnDetailDialogContent_Checkbox_flexText_${this.dialogData.type}`)
                  Checkbox({ name: JSON.stringify(item.value), group: 'checkboxGroup' })
                    .select((this.inputCheck).findIndex((val) => {
                      return val === item.value
                    }) !== -1 ? true : false)
                    .selectedColor($r('sys.color.comp_background_emphasize'))
                    .width(20)
                    .height(20)
                    .margin($r('sys.float.padding_level1'))
                    .onClick(() => {
                      this.onCheckbox(item)
                    })
                }
                .onClick(() => {
                  this.onCheckbox(item);
                })
                .padding({
                  left: $r('sys.float.padding_level4'),
                  right: $r('sys.float.padding_level4')
                })
                .constraintSize({ minHeight: 48 })
                .width('100%')

                if (index !== this.dialogData.option.length - 1) {
                  Divider()
                    .width('100%')
                    .color($r('sys.color.comp_divider'))
                    .padding({
                      left: $r('sys.float.padding_level4'),
                      right: $r('sys.float.padding_level4')
                    })
                }
              }
              .stateStyles({
                pressed: this.pressedStyles,
                normal: {
                  .backgroundColor(Color.Transparent)
                }
              })
            }
            .padding({ right: 24 })
          })
        }
        .scrollBar(BarState.Off)
        .margin({ right: -24 })
      }
    }.width('100%')
  }
}
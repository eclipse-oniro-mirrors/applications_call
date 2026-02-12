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

import commonData from '../data/CommonData';
import ContactService from '../service/ContactService';
import { LogUtils, ReportUtil, CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import prompt from '@system.prompt';
import { setCallForward } from '../model/CallServiceProxy';
import { StringUtil } from '../common/utils/StringUtil';
import SubCallForwardData from '../common/struct/SubCallForwardData';
import common from '@ohos.app.ability.common';
import * as CallSettingsConstant from '../common/constant/CallSettingsConstant';
import call from '@ohos.telephony.call';
import { BusinessError } from '@ohos.base';
import CallColumnUtils from '../common/utils/CallColumnUtils';
import { CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import { UIExtensionContentSession } from '@kit.AbilityKit';
import { emitter } from '@kit.BasicServicesKit';
import { BehaviorDotting } from '../common/utils/presenter/BehaviorDotting';
import CallSettingVM from '../viewModel/CallSettingVM';

const OPACITY_ENABLE = 1;
const OPACITY_DISABLE_ITEM_CHILD = 0.4;
const TAG = 'SubCallForward';

@Component
export struct SubCallForward {
  @Link number: string;
  @Link status: number;
  @Link activeType: number;
  @Link isCellularDataEnabled: boolean;
  subData?: SubCallForwardData;
  @Link slotId: number;
  @Link isUnconditionalClicked: boolean;
  @StorageProp('curBp') curBp: string = '';
  @StorageProp('ratio') ratio: number = 0;
  @StorageLink('isGoHome') @Watch('closeDialog') keepDialog: boolean = true;
  private mCallColumnUtils: CallColumnUtils = CallColumnUtils.getInstance();
  controller?: CustomDialogController;
  @State forwardInputText: string = '';
  @State textFocusable: boolean = true;
  @State builder: ForwardDialogBuilder = {
    title: '',
    slotId: 1,
    number: '',
    twoBtn: true,
    callForwardType: -1
  };
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('fontSizeScaleMargin') fontSizeScaleMargin: string = '0vp';
  // 判断是否使用模态窗口拉起
  @State isFromExternal: boolean = CallSettingVM.getInstance().getIsFromExternal();
  private session: UIExtensionContentSession = AppStorage.get('extensionSession') as UIExtensionContentSession;

  clickToContacts() {
    let actionData: Record<string, string> = {};
    actionData.pageFlag = commonData.contactPage.PAGE_FLAG_SINGLE_CHOOSE;
    this.jumpToContactForResult(actionData);
  }

  async jumpToContactForResult(actionData: Record<string, string>) {
    if (this.isFromExternal) {
      this.session?.sendData({ 'getPickerData': 'getSinglePickerData' });
      await new Promise<void>((resolve, reject) => {
        emitter.on({ eventId: CallSettingsConstant.EMIT_SINGLE_PICKER_EVENT_ID }, (data) => {
          if (data?.data?.pickerData) {
            this.dealContactParams(data?.data?.pickerData.toString());
            resolve();
            emitter.off(CallSettingsConstant.EMIT_SINGLE_PICKER_EVENT_ID);
          } else {
            reject();
            emitter.off(CallSettingsConstant.EMIT_SINGLE_PICKER_EVENT_ID);
          }
        })
      })
    } else {
      let str = ContactService.getPhoneNumberParam(actionData);
      let data = await CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT)?.
      startAbilityForResult(str);
      if (data.resultCode == 0) {
        if (data.want && data.want.parameters) {
          let parameters = data.want.parameters as Record<string, Object>;
          let objectStr: string = parameters.contactObjects as string;
          this.dealContactParams(objectStr);
        }
      }
    }
  }

  private dealContactParams(contactObjects: string): void {
    let params: Record<string, string>[] = [];
    try {
      params = JSON.parse(contactObjects);
      let element: Record<string, string> = params[0];
      this.forwardInputText = element.telephone;
    } catch (e) {
      LogUtils.e(TAG, 'dealContactParams failed, return!');
      return;
    }
  }

  confirm() {
    if (this.builder.clickCallback) {
      this.builder.clickCallback();
    }
    this.forwardInputText = this.stripSeparators(this.forwardInputText);
    this.controller?.close();
    let callTransferInfo: call.CallTransferInfo = {
      type: this.builder.callForwardType,
      transferNum: this.forwardInputText,
      settingType: 3
    }
    LogUtils.i(TAG, 'confirm callTransferInfo set start callForwardType: ' + this.builder.callForwardType +
      ', slotId: ' + this.builder.slotId);
    setCallForward(this.builder.slotId, callTransferInfo).then((res) => {
      if (res) {
        LogUtils.i(TAG, 'confirm setCallTransfer end then err: ' + JSON.stringify(res));
        this.showToast();
        this.forwardInputText = '';
        if (this.builder.resultCallback) {
          this.builder.resultCallback(this.forwardInputText, 0);
        }
        return;
      }
      LogUtils.i(TAG, 'confirm setCallTransfer end success');
      BehaviorDotting.getInstance().setCallForwardDotting('1');
      if (this.builder.resultCallback) {
        this.builder.resultCallback(this.forwardInputText, 1);
      }
    }).catch((error: BusinessError) => {
      LogUtils.e(TAG, 'confirm setCallTransfer end error: ' + JSON.stringify(error));
      this.showToast(error.code.toString());
      this.forwardInputText = '';
      if (this.builder.resultCallback) {
        this.builder.resultCallback(this.forwardInputText, 0);
      }
    });
    ReportUtil.getInstance().reportCallForwardingSetAction(this.builder.callForwardType, 1);
  }

  cancel() {
    this.controller?.close();
    ReportUtil.getInstance().reportCallForwardingSetAction(this.builder.callForwardType, 0);
  }

  deactivation() {
    if (this.builder.clickCallback) {
      this.builder.clickCallback();
    }
    this.forwardInputText = this.stripSeparators(this.forwardInputText);
    this.controller?.close();
    let callForwardInfo: call.CallTransferInfo = {
      type: this.builder.callForwardType,
      transferNum: this.forwardInputText,
      settingType: 0
    }
    LogUtils.i(TAG, 'deactivation setCallForward slotId: ' + this.builder.slotId);
    setCallForward(this.builder.slotId, callForwardInfo).then((res) => {
      if (res) {
        LogUtils.i(TAG, 'deactivation setCallForward：then: ' + JSON.stringify(res));
        this.showToast();
        if (this.builder.resultCallback) {
          this.builder.resultCallback('', 0);
        }
        return;
      }
      LogUtils.i(TAG, 'deactivation setCallForward success');
      BehaviorDotting.getInstance().setCallForwardDotting('0');
      if (this.builder.resultCallback) {
        this.builder.resultCallback(this.forwardInputText, 0);
      }
    }).catch((error: BusinessError) => {
      LogUtils.e(TAG, 'deactivation setCallForward error: ' + JSON.stringify(error));
      this.showToast(error.code.toString());
      if (this.builder.resultCallback) {
        this.builder.resultCallback('', 0);
      }
    });
  }

  showToast(msg?: string) {
    if (msg && msg === commonData.string.ERROR_CODE) {
      AppStorage.SetOrCreate('showTipsDialog', true);
    } else {
      let showMsg = StringUtil.getErrorMsg(msg);
      prompt.showToast({
        message: (msg && !StringUtil.isEmpty(msg)) ?
        StringUtil.formatResourceToString(showMsg) :
        StringUtil.formatResourceToString($r('app.string.networkAnomaly'))
      });
    }
  }

  stripSeparators(phoneNumber: string): string {
    let str: string = '';
    if (StringUtil.isEmpty(phoneNumber)) {
      return str;
    }
    let len: number = phoneNumber.length;
    for (let i = 0; i < len; i++) {
      let char: string = phoneNumber.charAt(i);
      if ((char >= '0' && char <= '9') || char == '*' || char == '#' || char == '+') {
        str = str.concat(char);
      }
    }
    return str;
  }

  @Builder
  dialogContent() {
    Row() {
      Text($r('app.string.To'))
        .fontSize($r('sys.float.Body_L'))
        .constraintSize({ minHeight: 21 })
        .fontColor($r('sys.color.font_secondary'))
        .fontWeight(FontWeight.Regular)
        .width('100%')
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }

    Row() {
      this.SubCallForwardInputText()

      Button() {
        SymbolGlyph($r('sys.symbol.person'))
          .fontSize($r('app.float.wh_value_24'))
          .flexShrink(0)
          .opacity(0.86)
          .fontColor([$r('sys.color.ohos_fa_icon_primary')])
      }
      .margin({ left: $r('sys.float.padding_level4') })
      .backgroundColor(Color.Transparent)
      .accessibilityText($r('app.string.selectContacts'))
      .onClick(() => {
        this.clickToContacts();
      })
    }
    .width('100%')
    .constraintSize({ minHeight: 56 })
    Divider()
      .strokeWidth(this.textFocusable ? '2px' : '1px')
      .color(this.textFocusable ? $r('sys.color.icon_primary') :
      $r('sys.color.comp_divider'))
      .opacity(this.textFocusable ? 0.6 : 1)
      .margin({ top: -4, bottom: $r('sys.float.padding_level2') })
  }

  forwardDialogController1: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: this.builder.title,
      contentBuilder: () => {
        this.dialogContent();
      },
      buttons: [
        {
          value: $r('app.string.cancel'),
          action: () => {
            this.cancel();
          }
        },
        {
          value: $r('app.string.Turn_on'),
          action: () => {
            this.confirm();
          }
        }
      ]
    })
  })
  forwardDialogController2: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: this.builder.title,
      contentBuilder: () => {
        this.dialogContent();
      },
      buttons: [
        {
          value: $r('app.string.cancel'),
          action: () => {
            this.cancel();
          }
        },
        {
          value: $r('app.string.Deactivation'),
          action: () => {
            this.deactivation();
          }
        },
        {
          value: $r('app.string.Change_the'),
          action: () => {
            this.confirm();
          }
        },
      ]
    })
  })

  @Builder
  SubCallForwardInputText() {
    TextInput({ text: this.forwardInputText })
      .fontColor($r('sys.color.font_primary'))
      .fontSize($r('sys.float.Body_L'))
      .type(InputType.PhoneNumber)
      .fontWeight(FontWeight.Regular)
      .borderRadius($r('sys.float.corner_radius_none'))
      .backgroundColor(Color.Transparent)
      .caretColor($r('sys.color.font_emphasize'))
      .flexShrink(1)
      .focusable(this.textFocusable)
      .defaultFocus(true)
      .padding({ left: $r('sys.float.padding_level0') })
      .constraintSize({ minHeight: 48 })
      .onChange((value: string) => {
        this.forwardInputText = value;
      })
      .onFocus(() => {
        this.textFocusable = true;
      })
      .onBlur(() => {
        this.textFocusable = false;
      })
      .onTouch(() => {
        this.textFocusable = true;
      })
  }

  closeDialog() {
    if (!this.keepDialog) {
      if (this.builder.twoBtn) {
        this.forwardDialogController1.close();
      } else {
        this.forwardDialogController2.close();
      }
    }
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.interactive_click'))
  }

  @Styles
  normalStyles() {
    .backgroundColor(this.isFromExternal ? Color.Transparent : $r('sys.color.comp_background_primary'))
  }

  aboutToAppear() {
  }

  subCallForwardEnabled() {
    let enabled: boolean = true;
    if (!this.isCellularDataEnabled) {
      enabled = false;
    } else if (this.isUnconditionalClicked) {
      enabled = false;
    } else if (this.activeType === 0 && this.subData?.callForwardType === 0) {
      enabled = true;
    } else if (this.activeType === 0 && this.subData?.callForwardType !== 0) {
      enabled = false;
    } else if (this.status === 0 || this.status === 1) {
      enabled = true;
    } else {
      enabled = false;
    }
    return enabled;
  }

  build() {
    Column() {
      Flex({
        direction: this.fontSizeScale >= 1.75 ? FlexDirection.Column : FlexDirection.Row,
        justifyContent: FlexAlign.SpaceBetween,
        alignItems: this.fontSizeScale >= 1.75 ? ItemAlign.Start : ItemAlign.Center
      }) {
        Row() {
          Text(this.subData?.displayName)
            .fontSize($r('sys.float.Subtitle_M'))
            .fontColor($r('sys.color.font_primary'))
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Medium)
            .constraintSize({ minHeight: 22 })
            .flexShrink(0)
            .id(`callSetting_components_subCallForward_flexText_${this.subData?.displayName.id}`)
            .width(this.fontSizeScale >= 1.75 ? '100%' : '')
        }
        .padding({
          left: $r('sys.float.padding_level4'), right: $r('sys.float.padding_level4'),
          top: this.fontSizeScaleMargin, bottom: this.fontSizeScaleMargin
        })
        this.rowContentBuilder()
      }
      .callForwardStatusStyle()
    }
    .padding({
      left: $r('sys.float.padding_level2'), right: $r('sys.float.padding_level2')
    })
    .constraintSize({ minHeight: 47.5 })
    .borderRadius($r('sys.float.corner_radius_level8'))
  }

  @Builder
  rowContentBuilder() {
    Row() {
      if (this.status !== 0 && this.status !== 1) {
        LoadingProgress()
          .width('24vp')
          .height('24vp')
          .margin({ left: $r('sys.float.padding_level6') })
      } else {
        Text(this.status === 0 ? $r('app.string.Call_forward_deactivated') : this.status === 1 ?
        this.number : $r('app.string.unknown'))
          .fontSize($r('sys.float.Subtitle_S'))
          .fontColor($r('sys.color.font_secondary'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Regular)
          .textAlign(TextAlign.End)
          .flexShrink(1)
          .margin({ right: $r('sys.float.padding_level2') })
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .id(this.status === 0 ? 'callSetting_components_subCallForward_status0' : this.status === 1 ?
            'callSetting_components_subCallForward_status1' : 'callSetting_components_subCallForward_status2');

        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize($r('app.float.wh_value_24'))
          .flexShrink(0)
          .fontColor([$r('sys.color.icon_fourth')])
          .draggable(false)
      }
    }
    .justifyContent(this.fontSizeScale >= 1.75 ? FlexAlign.SpaceBetween : FlexAlign.End)
    .width(this.fontSizeScale >= 1.75 ? '100%' : '')
    .margin({ top: this.fontSizeScale >= 1.75 ? 2 : 0 })
    .padding({
      left: $r('sys.float.padding_level4'), right: $r('sys.float.padding_level4'),
    })
  }

  @Styles
  callForwardStatusStyle() {
    .opacity(this.subCallForwardEnabled() ? OPACITY_ENABLE : OPACITY_DISABLE_ITEM_CHILD)
    .enabled(this.subCallForwardEnabled())
    .onClick(() => {
      this.builder.title = this.subData ? this.subData.displayName : '';
      this.builder.slotId = this.slotId;
      this.builder.number = (this.subData && this.subData.forwardResult) ? this.subData.forwardResult?.number : '';
      this.builder.callForwardType = this.subData ? this.subData.callForwardType : -1;
      this.builder.twoBtn = this.status === 0;
      this.builder.clickCallback = () => {
        if (this.subData && this.subData.callForwardType === 0) {
          this.isUnconditionalClicked = true;
        }
        this.status = -1;
      };
      this.builder.resultCallback = (number, status) => {
        this.isUnconditionalClicked = false;
        this.status = status;
        this.number = number;
        if (this.subData && this.subData.forwardResult) {
          this.subData.forwardResult.number = this.number;
        }
        if (status === 1 && this.subData) {
          this.activeType = this.subData.callForwardType;
        } else {
          this.activeType = -1;
        }
      };
      this.forwardInputText = this.number;
      this.textFocusable = true;
      if (this.builder.twoBtn) {
        this.forwardDialogController1.open();
      } else {
        this.forwardDialogController2.open();
      }
    })
    .width('100%')
    .backgroundColor($r('sys.color.comp_background_primary'))
    .stateStyles({
      pressed: this.pressedStyles,
      normal: this.normalStyles
    })
    .borderRadius($r('sys.float.corner_radius_level8'))
  }
}

export class ForwardDialogBuilder {
  public title: string | Resource = '';
  public slotId: number = 0;
  public number: string = '';
  public callForwardType: number = -1;
  public resultCallback?: (forwardInputText: string, status: number) => void;
  public clickCallback?: () => void;
  public twoBtn: boolean = true;
}

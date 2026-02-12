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

import { DialogDataStruct } from '../common/struct/RejectMsgStruct';
import LogUtils from '../common/utils/LogUtils';
import * as storageUtil from '../common/utils/DataStorageUtil';
import common from '@ohos.app.ability.common';
import { GlobalContextHelper } from '../common/utils/GlobalContextHelper';
import * as Constants from '../common/utils/Constants';
import CallColumnUtils from '../common/utils/CallColumnUtils';
import { BusinessError } from '@ohos.base';
import commonEventManager from '@ohos.commonEventManager';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import ability from '@ohos.ability.ability';
import { CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import { ReportUtil } from '../common/utils/ReportUtils/ReportUtil';
import display from '@ohos.display';
import CustomButtons from '../common/components/CustomButtons';
import { StringUtil } from '../common/utils/StringUtil';
import { LengthMetrics } from '@kit.ArkUI';
import { isTwoInOne } from '../common/utils/DeviceTypeUtils';

let subscriber: commonEventManager.CommonEventSubscriber;
const TAG: string = 'IncomingCallRejectionSms';

interface FontSizeScale {
  top?: string,
  bottom?: string
}

@Entry
@Component
export default struct IncomingCallRejectionSms {
  @State confirmButtonEnabled: boolean = false;
  @State customTextInputFocus: boolean = false;
  isFromPhoneNumberMarkAs: boolean = false;
  cancelButtonText: ResourceStr = $r('app.string.cancel');
  confirmButtonText: ResourceStr = $r('app.string.ok');
  onCancel: () => void = () => {
  };
  onConfirm: (value: string) => void = (value: string) => {
  };
  @Provide('pathInfos') pathInfos: NavPathStack = new NavPathStack();
  @StorageProp('curBp') curBp: string = '';
  @State dialogData: DialogDataStruct = {
    textValue: '',
    confirm: (data: string) => {}
  };
  @State rejectMsgTemp: Array<string> = [];
  @State textFocusable: boolean = false;
  @StorageProp('foldStatus') foldStatus: number = -1;
  @State inputValue: string = '';
  @State statusBarHeight: number = -1;
  confirm: (data: string) => void = (data: string) => {};
  private curLanguage: string = '';
  private mCallColumnUtils: CallColumnUtils = CallColumnUtils.getInstance();
  private curLocale: string = '';
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('fontSizeScaleMargin') fontSizeScaleMargin: string = '0vp';
  private isFromExternal: boolean = AppStorage.get('isFromExternal') as boolean;
  @StorageProp('language') language: string = '';

  @Builder
  dialogContent() {
    Scroll() {
      Column() {
        Row() {
          this.IncomingTextArea()
        }
        .width('100%')
        .constraintSize({ minHeight: 48 })
        .padding({
          top: $r('sys.float.padding_level2'),
          bottom: $r('sys.float.padding_level2')
        })

        CustomButtons({
          confirmButtonEnabled: this.confirmButtonEnabled,
          cancelButtonText: this.cancelButtonText,
          confirmButtonText: this.confirmButtonText,
          onCancel: () => {
            this.rejectMsgDialog?.close();
          },
          onConfirm: () => {
            this.dialogData.confirm(this.inputValue);
            this.rejectMsgDialog?.close();
            if (this.inputValue !== this.dialogData.textValue) {
              ReportUtil.getInstance().reportRejectSmsChange();
            }
          }
        })
          .margin({ bottom: $r('sys.float.padding_level8') })
      }
    }
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })
  }
  rejectMsgDialog?: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.quickReply'),
      contentBuilder: () => {
        this.dialogContent();
      },
      contentAreaPadding: { left: $r('sys.float.padding_level0'), right: $r('sys.float.padding_level0') },
    }),
    autoCancel: true,
    showInSubWindow: isTwoInOne()
  })

  @Builder
  IncomingTextArea() {
    TextInput({ text: this.inputValue })
      .width('100%')
      .constraintSize({ minHeight: 48 })
      .align(Alignment.Center)
      .fontColor($r('sys.color.font_primary'))
      .fontSize($r('sys.float.Body_L'))
      .backgroundColor(Color.Transparent)
      .caretColor($r('sys.color.font_emphasize'))
      .borderRadius($r('sys.float.corner_radius_none'))
      .fontWeight(FontWeight.Regular)
      .draggable(false)
      .focusable(true)
      .defaultFocus(true)
      .showUnderline(true)
      .padding({
        left: $r('sys.float.padding_level12'),
        right: $r('sys.float.padding_level12')
      })
      .onChange((value) => {
        this.inputValue = value;
        if (!StringUtil.isEmpty(this.inputValue)) {
          this.confirmButtonEnabled = true;
        } else {
          this.confirmButtonEnabled = false;
        }
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

  @Builder
  myRouter(name: string, params: Record<string, number>) {
  }

  aboutToAppear() {
    this.initRejectMsgTemp();
    this.subscribeLocaleChanged();
    try {
      CallColumnUtils.getInstance().updateBreakpoint(display.getDefaultDisplaySync().width);
    } catch (error) {
      LogUtils.e(TAG, 'Error updating breakpoint');
    }
    this.statusBarHeight = AppStorage.get<number>('statusBarHeight') as number;
  }

  aboutToDisappear() {
    this.unsubscribeLocaleChanged();
    this.rejectMsgDialog = undefined;
  }

  onPageShow(): void {
    LogUtils.i(TAG, `onPageShow curLanguage: ${this.curLanguage} language: ${this.language}`);
    if (this.curLanguage !== this.language) {
      this.initRejectMsgTemp();
    }
    this.curLanguage = this.language;
  }

  initRejectMsgTemp() {
    this.rejectMsgTemp = [];
    try {
      import('@ohos.i18n').then((i18n) => {
        let latestLocale = i18n.default.System.getSystemLocale();
        this.curLocale = latestLocale;
        LogUtils.i(TAG, 'call setting curLocale: ' + this.curLocale);
        storageUtil.getRejectMsgData(GlobalContextHelper.getContext()
          .getValue<common.UIAbilityContext>(Constants.CALL_SETTING_ABILITY_CONTEXT),
          this.curLocale).then((data: string[]) => {
          this.rejectMsgTemp = data;
        });
      });
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtils.e(TAG, `call System.getSystemLanguage failed, error code: ${err.code}, message: ${err.message}.`);
    }
  }

  subscribeLocaleChanged() {
    let subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: [commonEventManager.Support.COMMON_EVENT_LOCALE_CHANGED]
    };
    commonEventManager.createSubscriber(subscribeInfo)
      .then((commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
        LogUtils.i(TAG, 'createSubscriber');
        subscriber = commonEventSubscriber;
        commonEventManager.subscribe(subscriber, (err, data) => {
          if (err) {
            LogUtils.e(TAG, `Failed to subscribe common event. error code: ${err.code}, message: ${err.message}.`);
            return;
          }
          this.initRejectMsgTemp();
          LogUtils.i(TAG, 'the subscribed event has occurred, data');
        })
      })
      .catch((err: BusinessError) => {
        LogUtils.e(TAG, `createSubscriber failed, code is ${err.code}, message is ${err.message}`);
      });
  }

  unsubscribeLocaleChanged() {
    commonEventManager.unsubscribe(subscriber, (err) => {
      if (err) {
        LogUtils.i(TAG, 'unsubscribe commonEvent.unsubscribe err:' + JSON.stringify(err));
      }
    });
  }

showEditDialog(textValue: string, index: number) {
  ReportUtil.getInstance();
    this.dialogData.textValue = textValue;
    this.dialogData.confirm = (value: string) => {
      if (value.trim() && this.rejectMsgTemp[index]) {
        this.rejectMsgTemp.splice(index, 1, value);
        storageUtil.updateRejectMsg(GlobalContextHelper.getContext()
          .getValue<common.UIAbilityContext>(Constants.CALL_SETTING_ABILITY_CONTEXT),
          this.curLocale, this.rejectMsgTemp);
      }
    }
  this.inputValue = this.dialogData.textValue;
  this.rejectMsgDialog?.open();
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.interactive_click'))
    .padding({
      left: $r('sys.float.padding_level6'),
      right: $r('sys.float.padding_level6')
    })
    .borderRadius($r('sys.float.corner_radius_level7'))
    .constraintSize({ minHeight: $r('app.float.wh_value_48') })
    .opacity(1)
  }

  build() {
    Navigation(this.pathInfos) {
      GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: 24 }) {
        GridCol({ span: { xs: 2, sm: 4, md: 6, lg: 8 }, offset: { md: 1, lg: 2 } }) {
          List() {
            ListItemGroup() {
              ForEach(this.rejectMsgTemp, (item: string, index?: number) => {
                this.RejectionSmsListItem(item, index)
              }, (item: string) => item)
            }
            .divider({ strokeWidth: '1px', color: $r('sys.color.comp_divider'), endMargin: 2 })
            .padding({ left: $r('app.float.padding_12'), right: $r('app.float.padding_12'),
              top: $r('sys.float.padding_level2'), bottom: $r('sys.float.padding_level2') })
            .borderRadius($r('sys.float.corner_radius_level8'))
            .backgroundColor(this.isFromExternal ? $r('sys.color.comp_background_list_card') :
            $r('sys.color.comp_background_primary'))
            .margin({ top: $r('sys.float.padding_level4') })
          }
          .height('100%')
          .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
        }
      }
      .AdaptationMargin()
    }
    .mode(NavigationMode.Stack)
    .title($r('app.string.incoming_call_rejection_sms'), {
      paddingEnd: LengthMetrics.vp(58)
    })
    .navDestination(this.myRouter)
    .titleMode(NavigationTitleMode.Mini)
    .padding({ top: this.isFromExternal ? 8 : this.statusBarHeight })
    .backgroundColor(this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
      $r('sys.color.background_secondary'))
    .expandSafeArea([SafeAreaType.KEYBOARD])
  }

  @Builder
  RejectionSmsListItem(item: string, index: number | undefined) {
    ListItem() {
      Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Text(item)
          .fontSize($r('sys.float.Subtitle_M'))
          .fontColor($r('sys.color.font_primary'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Medium)
          .constraintSize({ minHeight: $r('app.float.line_height_22') })
        Row() {
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontColor([$r('sys.color.icon_fourth')])
            .fontSize($r('app.float.wh_value_24'))
            .draggable(false);
        }
      }
      .onClick(() => {
        let curIndex: number = index ? index : 0;
        this.showEditDialog(item, curIndex);
      });
    }
    .width('100%')
    .constraintSize({ minHeight: 48 })
    .backgroundColor(this.isFromExternal ? Color.Transparent : $r('sys.color.comp_background_primary'))
    .padding(this.fontSizeScaleUtil('padding'))
  }

  fontSizeScaleUtil(type: string): FontSizeScale {
    LogUtils.i(TAG, 'fontSizeScaleUtil:' + this.fontSizeScaleMargin + ' fontSizeScale:' + this.fontSizeScale);
    if (type === 'padding' && this.fontSizeScale > 1) {
      return {
        top: this.fontSizeScaleMargin, bottom: this.fontSizeScaleMargin
      }
    } else {
      return {};
    }
  }

  public getPaddingSpace(curBp: string): Resource {
    if (isTwoInOne()) {
      return $r('sys.float.padding_level12');
    }
    if (curBp === 'sm') {
      return $r('sys.float.padding_level8');
    }
    if (curBp === 'md') {
      return $r('sys.float.padding_level12');
    }
    return $r('sys.float.padding_level16');
  }

  @Styles
  AdaptationMargin() {
    .margin({
      left: this.getPaddingSpace(this.curBp),
      right: this.getPaddingSpace(this.curBp)
    })
  }
  onBackPress() {
    let session: UIExtensionContentSession = LocalStorage.getShared()
      .get<UIExtensionContentSession>('session') as UIExtensionContentSession;
    session.sendData({ 'action': 'pop' });
  }
}

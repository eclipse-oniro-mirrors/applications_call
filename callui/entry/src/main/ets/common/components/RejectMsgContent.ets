/**
 * Copyright (c) 2024-2024 Huawei Device Co., Ltd.
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

import * as storageUtil from '../utils/DataStorageUtil';
import { GlobalContextHelper } from '../utils/GlobalContextHelper';
import LogUtils from '../utils/LogUtils';
import { StringUtil } from '../utils/StringUtil';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import * as Constants from '../utils/Constants';
import IncomingComVM from '../../viewmodel/IncomingComVM';
import I18n from '@ohos.i18n';

const TAG = 'RejectMsgContent';
const CUSTOM_MSG_ID: number = 4;

@Component
export struct RejectMsgContent {
  dialogController?: CustomDialogController;
  @State msgList: string[] = [];
  private curLocale: string = '';
  @Link mIncomingVM: IncomingComVM;
  clickCustomMsg: Function = () => {
  };

  aboutToAppear(): void {
    LogUtils.i(TAG, 'RejectMsgContent aboutToAppear');
    try {
      this.curLocale = I18n.System.getSystemLocale();
      storageUtil.getRejectMsgData(GlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(Constants.CALL_ABILITY_CONTEXT), this.curLocale).then((data: string[]) => {
        data.push(StringUtil.formatResourceToString($r('app.string.customSMS')));
        this.msgList = data;
      })
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtils.e(TAG, `call System.getSystemLanguage failed, error code: ${err.code}, message: ${err.message}.`);
    }
  }

  /**
   * Call rejection interface
   *
   * @param {string} msg - Send SMS content
   */
  private msgItemClick(msg: string, index: number) {
    LogUtils.i(TAG, 'msgItemClick rejectCall');
    if (index === CUSTOM_MSG_ID) {
      this.clickCustomMsg()
    } else {
      this.mIncomingVM.sendMessageAndRejectCall(msg);
    }
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.interactive_click'))
    .borderRadius($r('sys.float.corner_radius_level7'))
    .opacity(1)
  }

  build() {
    Column() {
      List() {
        ForEach(this.msgList, (item: string, index: number) => {
          ListItem() {
            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
              Row() {
                Text(item)
                  .fontSize($r('sys.float.Body_L'))
                  .fontColor($r('sys.color.font_primary'))
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    top: $r('app.float.call_dtmf_text_video_line_height'),
                    bottom: $r('app.float.call_dtmf_text_video_height')
                  })
              }
            }
            .padding({ left: $r('sys.float.padding_level6'), right: $r('sys.float.padding_level6') })
          }
          .constraintSize({ minHeight: $r('app.float.wh_value_48') })
          .stateStyles({ pressed: this.pressedStyles, normal: {
            .backgroundColor(Color.Transparent)
          }})
          .onClick(() => {
            this.dialogController?.close();
            this.msgItemClick(item, index);
          })
        })
      }
      .padding({ left: $r('sys.float.padding_level6'), right: $r('sys.float.padding_level6') })
      .divider({ strokeWidth: '1px', color: $r('sys.color.comp_divider'), startMargin: '12vp', endMargin: '12vp' })
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .backgroundColor(Color.Transparent)
    }
  }
}
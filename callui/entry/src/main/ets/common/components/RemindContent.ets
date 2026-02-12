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

import IncomingComVM from '../../viewmodel/IncomingComVM';
import { remindObj } from '../dialog/RemindObj';
import LogUtils from '../utils/LogUtils';
import { ReportUtil } from '../utils/ReportUtils/ReportUtil';

const TAG = 'RemindContent';

@Component
export struct RemindContent {
  dialogController?: CustomDialogController;
  @Link mIncomingVM: IncomingComVM;

  /**
   * recall remind
   *
   * @param {number} value -  set remind time
   */
  private remindItemClick(obj: remindObj) {
    LogUtils.i(TAG, 'remindItemClick rejectCall');
    this.mIncomingVM.sendRemind(obj);
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.interactive_click'))
    .borderRadius($r('sys.float.corner_radius_level7'))
    .opacity(1)
  }

  aboutToAppear(): void {
    LogUtils.i(TAG, 'RemindContent aboutToAppear');
  }

  build() {
    Column() {
      List() {
        ForEach(this.mIncomingVM.remindList, (item: remindObj) => {
          ListItem() {
            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
              Row() {
                Text(item.msg)
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
            this.remindItemClick(item);
            LogUtils.i(TAG, 'onClick and confirm');
            ReportUtil.getInstance().reportCallBackRemindAction(item.id + 1);
            this.dialogController?.close();
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
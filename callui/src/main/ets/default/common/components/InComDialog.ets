/**
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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

import HiLog from '../utils/Hilog.ets';

const TAG = "InComDialog";

@CustomDialog
export default struct InComDialog {
  controller: CustomDialogController;
  cancel: () => void;
  confirm: (msg) => void;
  cancelHandle: () => void;
  List: [];

  build() {
    GridContainer({ gutter: 12, margin: 12 }) {
      Row() {
        Flex({ justifyContent: FlexAlign.Start }) {
          Column() {
            Flex({justifyContent: FlexAlign.Start, alignItems: ItemAlign.Start}) {
              Text($r("app.string.hangUpReply"))
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
                .fontColor('#182431')
                .height(56)
            }

            Column() {
              ForEach(this.List, (item) => {
                Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
                  Text(item.msg)
                    .width('100%')
                    .fontSize(16)
                    .height(48)
                    .fontColor('#182431')
                    .fontWeight(FontWeight.Medium)
                }
                .onClick(() => {
                  this.controller.close();
                  this.confirm(item)
                  HiLog.i(TAG, "onClick and confirm : %s",JSON.stringify(item));
                })
                if(item.id !== 4){
                  Image($r("app.media.divider"))
                    .height(0.5)
                }
              })
            }

            Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
              Text($r("app.string.cancel"))
                .fontColor('#00CB87')
                .fontSize(16)
                .height(40)
                .fontWeight(FontWeight.Medium)
            }
            .margin({ top: 8, bottom: 16 })
            .onClick(() => {
              HiLog.i(TAG, "onClick %s");
              this.controller.close();
            })
          }
        }
        .padding({ left: 24, right: 24 })
      }.backgroundColor(Color.White)
      .useSizeType({
        xs: { span: 1, offset: 0 },
        sm: { span: 4, offset: 0 },
        md: { span: 4, offset: 2 },
        lg: { span: 4, offset: 4 }
      })
      .borderRadius(32)
    }
    .onClick(() => {
      this.controller.close();
    })
  }
}
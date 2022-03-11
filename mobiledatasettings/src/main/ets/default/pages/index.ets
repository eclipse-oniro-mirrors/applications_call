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

/**
 * @file: Mobile Network Home page
 */

import router from '@system.router';
import telephonyData from '@ohos.telephony.data';

@Entry
@Component
struct Index {
  @State isDataEnable: boolean = false;

  private onPageShow(): void {
    telephonyData.isCellularDataEnabled().then((dataEnable) => {
      this.isDataEnable = dataEnable
    }).catch((error) => {
    });
  }

  build() {
    Column() {
      Row() {
        Image($r("app.media.ic_back"))
          .height(24)
          .width(24)
          .margin({ top:2, bottom: 2, right: 16 })
          .onClick(() => {
            router.back()
          })

        Text($r("app.string.mobile_data"))
          .height(28)
          .lineHeight(28)
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor('#182431')
      }
      .width("100%")
      .height(56)
      .padding({ left: 24, top: 14, bottom: 14 })
      .margin({ bottom: 8 })

      GridContainer({ gutter: 12, margin: 12 }) {
        List() {
          ListItem() {
            Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
              Column() {
                Row() {
                  Text($r("app.string.mobile_data"))
                    .height(22)
                    .lineHeight(22)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#182431')
                }
                .margin({ left: 12, top: 14, bottom: 2 })

                Row() {
                  Text($r("app.string.mobile_data_charges"))
                    .height(19)
                    .lineHeight(19)
                    .fontSize(14)
                    .fontWeight(FontWeight.Regular)
                    .fontColor('#182431')
                    .opacity(0.6)
                }
                .margin({ left: 12, bottom: 15 })
              }
              .alignItems(HorizontalAlign.Start)
              .height(64)

              Toggle({ type: ToggleType.Switch, isOn: this.isDataEnable })
                .onChange((isOn: boolean) => {
                  if (isOn) {
                    telephonyData.enableCellularData().then((data) => {
                    }).catch((error) => {
                    });
                  } else {
                    telephonyData.disableCellularData().then((data) => {
                    }).catch((error) => {
                    });
                  }
                })
                .height(20)
                .width(36)
                .margin({ top: 26, bottom: 26, right: 12 })
            }
            .height(72)
            .width('100%')
            .backgroundColor('#FFFFFF')
            .borderRadius(25)
          }
        }
        .useSizeType({
          sm: { span: 4, offset: 0 },
          md: { span: 6, offset: 1 },
          lg: { span: 8, offset: 2 }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }
}
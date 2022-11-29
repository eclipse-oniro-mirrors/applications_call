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
import telephonyData from '@ohos.telephony.data';
import telephonyObserver from '@ohos.telephony.observer';
import telephonySim from '@ohos.telephony.sim';
import LogUtils from '../common/utils/LogUtils'

const TAG = "MobileDataSettings:";

@Entry
@Component
struct Index {
  @State isDataOn: boolean = false;
  @State isDataEnable: boolean = false;

  aboutToAppear(): void {
    LogUtils.i(TAG, "aboutToAppear");
    telephonyObserver.on("simStateChange", (simStateData) => {
      if (!simStateData) {
        return;
      }
      LogUtils.i(TAG, "simStateChange simState: " + simStateData.state);
      this.updateDataEnableState(simStateData.state);
    });
  }

  onPageShow(): void {
    LogUtils.i(TAG, "onPageShow  3333");
    telephonySim.getSimState(0).then((simState) => {
      LogUtils.i(TAG, "onPageShow simState: " + simState);
      this.updateDataEnableState(simState);
    }).catch((error) => {
      LogUtils.i(TAG, "onPageShow getSimState error: " + error);
    });
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, "aboutToDisappear");
    telephonyObserver.off("simStateChange");
  }

  terminateAbility(): void {
    LogUtils.i(TAG, "onclick back")
    globalThis.settingsAbilityContext?.terminateSelf().then((data) => {
      LogUtils.i(TAG, "mobiledatasettings terminateSelfCallBack");
    });
  }

  private updateDataEnableState(simState) {
    if (simState == telephonySim.SimState.SIM_STATE_NOT_PRESENT) {
      this.isDataEnable = false;
      this.isDataOn = false;
    } else {
      this.isDataEnable = true;
      telephonyData.isCellularDataEnabled().then((dataEnable) => {
        LogUtils.i(TAG, "updateDataEnableState isCellularDataEnabled: " + dataEnable);
        this.isDataOn = dataEnable;
      }).catch((error) => {
        LogUtils.i(TAG, "updateDataEnableState isCellularDataEnabled error: " + error);
      });
    }
  }

  build() {
    GridRow({ columns: { sm: 4, md: 8, lg: 12 }, gutter: { x: 12 } }) {
      GridCol({ span: { sm: 4, md: 8, lg: 8 }, offset: { sm: 0, md: 1, lg: 2 } }) {
        Row() {
          Image($r("app.media.ic_back"))
            .height(24)
            .width(24)
            .margin({ top: 2, bottom: 2, right: 16 })
            .onClick(() => {
              this.terminateAbility();
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
        .padding({
          left: 12,
          top: 14,
          bottom: 14
        })
        .margin({ bottom: 8 })
      }

      GridCol({ span: { sm: 4, md: 6, lg: 8 }, offset: { sm: 0, md: 1, lg: 4 } }) {
        Flex({
          direction: FlexDirection.Row,
          alignItems: ItemAlign.Center,
          justifyContent: FlexAlign.SpaceBetween
        }) {
          Column() {
            Text($r("app.string.mobile_data"))
              .height(22)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#182431')
              .margin({ bottom: 2 })

            Text($r("app.string.mobile_data_charges"))
              .height(19)
              .fontSize(14)
              .fontWeight(FontWeight.Regular)
              .fontColor('#182431')
              .opacity(0.6)
          }
          .margin({ left: 12 })
          .alignItems(HorizontalAlign.Start)

          Toggle({ type: ToggleType.Switch, isOn: this.isDataOn })
            .onChange((isOn: boolean) => {
              if (isOn) {
                telephonyData.enableCellularData()
                  .then((data) => {
                  })
                  .catch((error) => {
                  });
              } else {
                telephonyData.disableCellularData()
                  .then((data) => {
                  })
                  .catch((error) => {
                  });
              }
            })
            .height(20)
            .width(36)
            .margin({ right: 12 })
            .enabled(this.isDataEnable)
        }
        .height(72)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(25)
      }
    }
    .padding({ left: 12, right: 12 })
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }
}
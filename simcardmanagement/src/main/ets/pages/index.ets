/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
/**
 SIM_CARD_INFO */
import HeadComponent from '../common/components/headComponent'
import CardInfomation from '../common/components/cardInfomation'
import CardSetData from '../common/config/cardSetData';
import SetFlowLimit from '../common/components/dialog/setFlowLimit'
import DefaultDialCard from '../common/components/dialog/defalutDialing'
import cardInfoData from '../common/config/cardInfoData';
import { setCache, getCache } from '../common/utils/KvManager'
import dataServiceProxy from '../model/dataServiceProxy';
import simServiceProxy from '../model/simServiceProxy'
import DefaultCard from '../common/components/defaultCard'
import LogUtils from '../common/utils/LogUtils'

export const CARD_HOT_PULL_PLUG = {
  HOT_PULL: 1,
  HOT_PLUG: 4
};

const TAG = "Index"

@Entry
@Component
struct Index {
  scroller: Scroller = new Scroller();
  @State simId: string = '';
  @State isShow: boolean = false;
  @State isShow2: boolean = false;
  private number1: string = '';
  private number2: string = '';
  @State phoneNumber: boolean = false;
  @State cardData: any = JSON.parse(JSON.stringify(CardSetData));
  @State isRegisterObserver: boolean = false;
  @State defaultDataChange: boolean = true;
  @State isStop: boolean = true;
  @State defaultset: any = '';
  @State closeTransfer: boolean = false;
  @State list: any = [
    JSON.parse(JSON.stringify(cardInfoData)),
    JSON.parse(JSON.stringify(cardInfoData))
  ];
  SIM_CARD_STOP = 'sim_card_management_card_stop_boolean';
  SIM_CARD_Change = 'sim_card_management_card_change_boolean';
  SIM_CARD_DEFAULT = 'sim_card_management_card_default_call';
  SIM_CARD_TRANSFER = 'sim_card_management_transfer';
  SIM_CARD_TRANSFER2 = 'sim_card_management_transfer2';
  SHOW_CHANGE = 'sim_change_data'
  setFlowLimit: CustomDialogController = new CustomDialogController({
    builder: SetFlowLimit({ change: this.defaultDataChange }),
    alignment: DialogAlignment.Bottom,
    autoCancel: false,
    offset: { dx: 0, dy: -30 }
  })
  defaultDialCard: CustomDialogController = new CustomDialogController({
    builder: DefaultDialCard({ action: (v) => {
      this.defaultset = v;
    }}),
    alignment: DialogAlignment.Bottom,
    autoCancel: false,
    offset: { dx: 0, dy: -30 }
  })

 /* set(item) {
    this.setFlowLimit.open();
  };*/

  defaultCard() {
    LogUtils.i(TAG, "onclick defaultDialCard open")
    this.defaultDialCard.open();
  };

  /**
   * Get the customized mobile phone number set by the user
   */
  getShowNumber(slotId) {
    simServiceProxy.getShowNumber(slotId).then((res: string) => {
      if (res !== 'null') {
        if (!slotId) {
          this.number1 = res;
        } else {
          this.number2 = res;
        }
      } else {
        this.getPhoneNumber(slotId);
      }
    })
  }

  /**
   * Get the phone number of sim card
   */
  getPhoneNumber(slotId) {
    simServiceProxy.getSimTelephoneNumber(slotId).then((res: string) => {
      if (!slotId) {
        this.number1 = res;
      } else {
        this.number2 = res;
      }
    })
  }

  /**
   * Get the default voice sim card
   */
  getDefaultVoiceSlotld() {
    simServiceProxy.getDefaultVoiceSlotId().then((res: string) => {
      if (res == '0') {
        this.defaultset = $r('app.string.sim_card_one_no_space');
      } else if (res == '1') {
        this.defaultset = $r('app.string.sim_card_two_no_space');
      } else {
        this.defaultset = $r('app.string.not_set');
      }
    })
  }

  setDefaultDataSlotId(slotId) {
    dataServiceProxy.setDefaultDataSlotId(slotId)
  }

  aboutToAppear() {
    LogUtils.i(TAG, "aboutToAppear")
    getCache(this.SHOW_CHANGE, (data) => {
      if (data == 0) {
        this.isShow = false;
      } else {
        this.isShow = true;
      };
    });
  }

  getDefaultDataSlotId() {
    dataServiceProxy.getDefaultDataSlotId().then((res) => {
      if (res === 1) {
        this.defaultDataChange = false;
      } else {
        this.defaultDataChange = true;
      }
    })
  }

  onPageShow() {
    LogUtils.i(TAG, "onPageShow start ")
    this.getShowNumber(0);
    this.getShowNumber(1);
    this.getDefaultVoiceSlotld();
    this.getDefaultDataSlotId();
    getCache(this.SIM_CARD_Change, (data) => {
      if (data == null) {
        setCache(this.SIM_CARD_Change, 0);
      } else {
        if (data == 0) {
          this.defaultDataChange = true;
        } else {
          this.defaultDataChange = false;
        };
      };
    });

    getCache(this.SIM_CARD_STOP, (data) => {
      if (data != null) {
        this.isStop = data;
      }
      ;
    });

    getCache(this.SIM_CARD_DEFAULT, (data) => {
      this.defaultset = data.replace('\'', '').replace('\'', '');
    });

    LogUtils.i(TAG, "onPageShow end ")
  }

  build() {
    GridRow({ columns: { sm: 4, md: 8, lg: 12 }, gutter: { x: 12 } }) {
      GridCol({ span: { sm: 4, md: 8, lg: 8 }, offset: { sm: 0, md: 1, lg: 2 } }) {
        Column() {
          Column() {
            HeadComponent({ headName: $r('app.string.sim_headName') })

            Column() {
            }
            .height(12)
            .width("100%")

            CardInfomation({
              simCardStop: $isStop,
              changeCard: $defaultDataChange,
              phone1Number: this.number1,
              phone2Number: this.number2,
              isCardChange: $defaultDataChange,
              isCardChange2: $isShow,
              defaultSetString: $defaultset,
            })

            Column() {
            }
            .height(16)
            .width("100%")

            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
              Column() {
                Text($r('app.string.default_mobile_data')).fontSize('16vp').fontFamily("HarmonyHeiTi").fontWeight(FontWeight.Medium).maxLines(1)
              }
              .opacity(this.isStop ? 1 : 0.4)
              .align(Alignment.Center)

              Row() {
                DefaultCard({ cardName: $r('app.string.card_1'),
                  cardTextBackgrounColor: this.defaultDataChange ? "#0A59F7" : "#FFFFFF",
                  cardTextColor: this.defaultDataChange ? "#FFFFFF" : "#0A59F7" })
                  .opacity(this.isStop ? 1 : 0.4)
                  .onClick(() => {
                    LogUtils.i(TAG, "onclick defaultcard card one")
                    setCache(this.SIM_CARD_Change, 0);
                    this.setDefaultDataSlotId(0)
                    this.defaultDataChange = !this.defaultDataChange;
                  })
                  .margin({ right: 6 })

                DefaultCard({ cardName: $r('app.string.card_2'),
                  cardTextBackgrounColor: this.defaultDataChange ? "#FFFFFF" : "#0A59F7",
                  cardTextColor: this.defaultDataChange ? "#0A59F7" : "#FFFFFF" })
                  .opacity(this.isStop ? 1 : 0.4)
                  .onClick(() => {
                    LogUtils.i(TAG, "onclick defaultcard card two")
                    this.setDefaultDataSlotId(1)
                    this.defaultDataChange = !this.defaultDataChange;
                  })
              }
              .enabled(this.isStop)
              .margin({ right: 1 })
              .width(148)
              .height(40)
              .borderRadius(50)
              .backgroundColor($r("sys.color.ohos_id_color_sub_background"))
              .padding({
                top: 6,
                bottom: 6,
                right: 6,
                left: 6
              })
            }
            .padding({
              left: 12,
              right: 12,
              top: 12,
              bottom: 12
            })
            .width("100%")
            .backgroundColor($r("sys.color.ohos_id_color_foreground_contrary"))
            .borderRadius($r('app.float.radius_24'))

            Column() {
            }
            .height(16)
            .width("100%")

            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
              Text($r('app.string.default_dial_card')).fontSize('16vp').fontFamily("HarmonyHeiTi").fontWeight(FontWeight.Medium).maxLines(1)
                .lineHeight(21)
              Row() {
                Text(this.defaultset ? this.defaultset : $r('app.string.not_set')).fontSize(14).fontColor('#555').margin({
                  right: 5
                }).lineHeight(19)
                  .fontFamily("HarmonyHeiTi").fontWeight(FontWeight.Regular)
                Image($r('app.media.next_icon')).height(20).width(12)
              }
            }
            .opacity(this.isStop ? 1 : 0.4)
            .enabled(this.isStop)
            .onClick(() => {
              this.defaultCard();
            })
            .height(60)
            .backgroundColor('rgba(255, 255, 255, 1)')
            .padding({
              left: 12,
              right: 12,
              top: 2,
              bottom: 2
            })
            .width("100%")
            .backgroundColor($r("sys.color.ohos_id_color_foreground_contrary"))
            .borderRadius($r('app.float.radius_24'))
          }
          .useSizeType({
            sm: { span: 4, offset: 0 },
            md: { span: 6, offset: 1 },
            lg: { span: 8, offset: 2 }
          })
        }
      }
    }
    .padding({ left: 12, right: 12 })
    .width('100%')
    .height('100%')
    .backgroundColor($r("sys.color.ohos_id_color_sub_background"))
  }
}
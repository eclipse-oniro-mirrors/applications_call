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
import SetFlowLimit from '../common/components/dialog/setFlowLimit'
import DefaultDialCard from '../common/components/dialog/defalutDialing'
import dataServiceProxy from '../model/dataServiceProxy';
import simServiceProxy from '../model/simServiceProxy'
import DefaultCard from '../common/components/defaultCard'
import LogUtils from '../common/utils/LogUtils'
import { registerSimStateChange, getMaxSimCount } from '../model/registerSimStateApi'
import SubscriberManager from '../common/utils/SubscriberManager'
import { getPrimarySlotId } from '../model/radioServiceProxy'
import OperaNameStruct from '../common/struct/operaNameStruct';

export const CARD_HOT_PULL_PLUG = {
  HOT_PULL: 1,
  HOT_PLUG: 4
};

const TAG = "Index"
class CardInfoStruct {
  id
  title
  isOpened
  disabled
  name
  info
  isSimCardClosed
}

@Entry
@Component
struct Index {
  scroller: Scroller = new Scroller();
  @State list: Array<CardInfoStruct> = [
    {
      id: 0,
      title: $r('app.string.sim_card_one_no_space'),
      isOpened: false,
      disabled: true,
      name: $r('app.string.sim_null_character'),
      info: '',
      isSimCardClosed: false
    },
    {
      id: 1,
      title: $r('app.string.sim_card_two_no_space'),
      isOpened: false,
      disabled: true,
      name: $r('app.string.sim_null_character'),
      info: '',
      isSimCardClosed: false
    }
  ];
  @State isShow: boolean = false;
  @State isShow2: boolean = false;
  private number1: string = '';
  private number2: string = '';
  @State defaultDataChange: boolean = true;
  @State isStop: boolean = true;
  @State defaultSet: Resource = $r('app.string.not_set');
  @State simActive: boolean = false;
  @StorageLink("operatorName") @Watch('updateInfo') operatorInfo: OperaNameStruct = new OperaNameStruct();
  SIM_CARD_STOP = 'sim_card_management_card_stop_boolean';
  SIM_CARD_Change = 'sim_card_management_card_change_boolean';
  SIM_CARD_DEFAULT = 'sim_card_management_card_default_call';
  SIM_CARD_TRANSFER = 'sim_card_management_transfer';
  SIM_CARD_TRANSFER2 = 'sim_card_management_transfer2';
  SHOW_CHANGE = 'sim_change_data';
  setFlowLimit: CustomDialogController = new CustomDialogController({
    builder: SetFlowLimit({ change: this.defaultDataChange }),
    alignment: DialogAlignment.Bottom,
    autoCancel: false,
    offset: { dx: 0, dy: -30 }
  })
  defaultDialCard: CustomDialogController = new CustomDialogController({
    builder: DefaultDialCard({ defaultSet: $defaultSet,
      action: (v) => {
        this.defaultSet = v;
      } }),
    alignment: DialogAlignment.Bottom,
    autoCancel: false,
    offset: { dx: 0, dy: -16 }
  })

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
    });
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
    simServiceProxy.getDefaultVoiceSlotId().then((res: number) => {
      LogUtils.i(TAG, "isSimActive getDefaultVoiceSlotId:" + "  " + JSON.stringify(res));
      if (res === 0 || res === 1) {
        this.isSimActive(res);
      } else {
        this.defaultSet = $r('app.string.not_set');
      }
    }).catch((err) => {
      this.defaultSet = $r('app.string.not_set');
    })
  }

  isSimActive(slotId) {
    simServiceProxy.isSimActive(slotId).then((res: boolean) => {
      LogUtils.i(TAG, "isSimActive simServiceProxy.isSimActive:" + JSON.stringify(slotId) + "  " + JSON.stringify(res));
      this.simActive = res;
      if (res) {
        if (slotId === 0) {
          this.defaultSet = $r('app.string.sim_card_one_no_space');
        }
        else if (slotId === 1) {
          this.defaultSet = $r('app.string.sim_card_two_no_space');
        } else {
          this.defaultSet = $r('app.string.not_set');
        }
      } else {
        this.defaultSet = $r('app.string.not_set');
      }
    }).catch((err) => {
      this.defaultSet = $r('app.string.not_set');
    })
  }

  updateInfo() {
    this.getShowNumber(0);
    this.getShowNumber(1);
    this.getDefaultVoiceSlotld();
    this.getDefaultDataSlotId();
  }

  setDefaultDataSlotId(slotId) {
    dataServiceProxy.setDefaultDataSlotId(slotId)
  }

  aboutToAppear() {
    LogUtils.i(TAG, "aboutToAppear:");
    SubscriberManager.registerSubscriber();

    if (getMaxSimCount() >= 2) {
      this.addRegisterSimStateChange(1);
    }
    this.addRegisterSimStateChange(0);
  }

  getDefaultDataSlotId() {
    if (this.list[0].isSimCardClosed && this.list[1].isSimCardClosed) {
      dataServiceProxy.getDefaultDataSlotId().then((res) => {
        this.setDefaultDataChange(res);
      })
    } else {
      getPrimarySlotId().then((res) => {
        LogUtils.i(TAG, "getPrimarySlotId: then: " + JSON.stringify(res));
        this.setDefaultDataChange(res);
      });
    }
  }

  setDefaultDataChange(res) {
    if (res === 1) {
      this.defaultDataChange = false;
    } else {
      this.defaultDataChange = true;
    }
  }

  onPageShow() {
    LogUtils.i(TAG, "onPageShow start ");
    this.updateInfo();
    LogUtils.i(TAG, "onPageShow end ")
  }

  addRegisterSimStateChange(slotId) {
    registerSimStateChange(slotId, async (callStateInfo) => {
      LogUtils.i(TAG, "registerSimStateChange:" + JSON.stringify(callStateInfo));
      this.updateInfo();
      this.defaultDialCard.close();
    })
  }

  aboutToDisappear() {
    SubscriberManager.unsubscribe();
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
              list: $list,
              changeCard: $defaultDataChange,
              phone1Number: this.number1,
              phone2Number: this.number2,
              isCardChange: $defaultDataChange,
              isCardChange2: $isShow,
              defaultSetString: $defaultSet,
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
              .opacity((this.list[0].isOpened && this.list[1].isOpened) ? 1 : 0.4)
              .align(Alignment.Center)

              Row() {
                DefaultCard({ cardName: $r('app.string.card_1'),
                  cardTextBackgrounColor: this.defaultDataChange ? "#0A59F7" : "#FFFFFF",
                  cardTextColor: this.defaultDataChange ? "#FFFFFF" : "#0A59F7" })
                  .opacity((this.list[0].isOpened && this.list[1].isOpened) ? 1 : 0.4)
                  .onClick(() => {
                    LogUtils.i(TAG, "onclick defaultcard card one")
                    this.setDefaultDataSlotId(0);
                    this.defaultDataChange = !this.defaultDataChange;
                  })
                  .margin({ right: 6 })

                DefaultCard({ cardName: $r('app.string.card_2'),
                  cardTextBackgrounColor: this.defaultDataChange ? "#FFFFFF" : "#0A59F7",
                  cardTextColor: this.defaultDataChange ? "#0A59F7" : "#FFFFFF" })
                  .opacity((this.list[0].isOpened && this.list[1].isOpened) ? 1 : 0.4)
                  .onClick(() => {
                    LogUtils.i(TAG, "onclick defaultcard card two")
                    this.setDefaultDataSlotId(1);
                    this.defaultDataChange = !this.defaultDataChange;
                  })
              }
              .enabled((this.list[0].isOpened && this.list[1].isOpened))
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
            .opacity((this.list[0].isOpened && this.list[1].isOpened) ? 1 : 0.6)
            .borderRadius($r('app.float.radius_16'))

            Column() {
            }
            .height(16)
            .width("100%")

            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
              Text($r('app.string.default_dial_card')).fontSize('16vp').fontFamily("HarmonyHeiTi").fontWeight(FontWeight.Medium).maxLines(1)
                .lineHeight(21)
                .opacity((this.list[0].isOpened && this.list[1].isOpened) ? 1 : 0.4)

              Row() {
                Text(this.defaultSet ? this.defaultSet : $r('app.string.not_set')).fontSize(14).fontColor('#555').margin({
                  right: 5
                }).lineHeight(19)
                  .fontFamily("HarmonyHeiTi").fontWeight(FontWeight.Regular)
                Image($r('app.media.next_icon')).height(20).width(12)
              }
              .opacity((this.list[0].isOpened && this.list[1].isOpened) ? 1 : 0.4)
            }
            .opacity((this.list[0].isOpened && this.list[1].isOpened) ? 1 : 0.6)
            .enabled((this.list[0].isOpened && this.list[1].isOpened))
            .onClick(() => {
              this.defaultCard();
            })
            .height(60)
            .padding({
              left: 12,
              right: 12,
              top: 2,
              bottom: 2
            })
            .width("100%")
            .backgroundColor($r("sys.color.ohos_id_color_foreground_contrary"))
            .borderRadius($r('app.float.radius_16'))
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
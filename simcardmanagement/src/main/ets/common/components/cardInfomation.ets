/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the Licensef at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import { setCache, getCache, deleteCache } from '../utils/KvManager'
import UpdataInfo from './dialog/upDataInfo'
import StopSim from './dialog/stopSim'
import EditSimInfo from './dialog/editSimInfo'
import simServiceProxy from '../../model/simServiceProxy'
import radioServiceProxy from '../../model/radioServiceProxy'
import { registerSimStateChange, getMaxSimCount } from '../../model/registerSimStateApi'
import dataServiceProxy from '../../model/dataServiceProxy';
import LogUtils from '../../common/utils/LogUtils'

const TAG = "cardInformation"

@Component
export default struct eSimSet {
  @State list: any = [
    {
      id: 0,
      title: $r('app.string.sim_card_one_no_space'),
      isOpened: true,
      disabled: true,
      name: $r('app.string.sim_null_character'),
      info: ''
    },
    {
      id: 1,
      title: $r('app.string.sim_card_two_no_space'),
      isOpened: true,
      disabled: true,
      name: $r('app.string.sim_null_character'),
      info: ''
    }
  ];
/*  @State eSimCard: any =
    {
      title: '卡2',
      subTitle: 'eSIM',
      name: '添加eSIM',
      info: '2G/3G/4G/5G'
    };*/
  @State flowCardId: number = 1;
  @State phone1Number: string = '';
  @State phone2Number: string = '';
  @State title: any = '';
  @State curEditList : any = [];
  @State isSimCardClosed: boolean = true;
  @State simName: string = '';
  @State phoneNumber: string = '';
  @State simId: string = '';
  @State index: number = 0;
  @State storage: any = [];
  @State isChange: boolean = true;
  @State diaLing: number = 0;
  @State upisChange: boolean = true;
  @State isCancel: boolean = false;
  @State isCard: boolean = true;
  @Link  isCardChange: boolean;
  @State listIndex: number = 0;
  @State upDataTitle: any = '';
  @State card1: boolean = true;
  @State card2: boolean = true;
  @State isStop1: boolean = true;
  @State isStop2: boolean = true;
  @Link simCardStop: boolean;
  @Link changeCard: boolean;
  @Link isCardChange2: boolean;
  @Link defaultSetString: any;
  timer = null;
  SIM_CARD_DEFAULT = 'sim_card_management_card_default_call';
  SIM_CARD_INFO = 'sim_card_management_storage_card_info';
  SIM_CARD_KEYWORD = 'sim_card_keyword';
  SIM_CARD_INFO2 = 'sim_card_management_storage_card_info2';
  SIM_CARD_Change = 'sim_card_management_card_change_boolean';
  SIM_CARD_STOP = 'sim_card_management_card_stop_boolean';
  SIM_CARD_DATA = 'sim_card_management_storage_card_data';
  SIM_LIST_DISABLED = 'sim_card_management_list_disabled';
  SIM_LIST_DISABLED2 = 'sim_card_management_list_disabled2';
  SIM_NAME1 = 'sim_card_name1';
  SIM_NAME2 = 'sim_card_name2';
  SIM_phoneNumber1 = 'sim_card_phoneNumber1';
  SIM_phoneNumber2 = 'sim_card_phoneNumber2';
  editSimInfo: CustomDialogController = new CustomDialogController({
    builder: EditSimInfo({ curEditList: this.curEditList, phoneNumber: $phoneNumber,
      action: (simName, curEditList, phoneNumber) => {
        if (curEditList.id === 0) {
          if (simName !== 'null') {
            this.list[0].name = simName;
          } else {
            this.getNetName(0);
          };
          if (phoneNumber !== 'null') {
            this.phone1Number = phoneNumber;
          } else {
            this.getPhoneNumber(0);
          };
        } else {
          if (simName !== 'null') {
            this.list[1].name = simName;
          } else {
            this.getNetName(1);
          };
          if (phoneNumber !== null) {
            this.phone2Number = phoneNumber;
          } else {
            this.getPhoneNumber(1);
          };
        }
        this.isChange = !this.isChange;
      } }),
    alignment: DialogAlignment.Bottom,
    autoCancel: false,
    offset: { dx: 0, dy: -30 }
  })
  stopSim: CustomDialogController = new CustomDialogController({
    builder: StopSim({ curEditList: this.curEditList, title: this.title, isChange: $isChange, cancel: (isChange) => {
      this.isCancel = true;
      if (this.curEditList.id === 0) {
        this.list[0].isOpened = true;
      } else {
        this.list[1].isOpened = true;
      };
      this.simCardStop = isChange
    },
      action: (stop) => {
        this.defaultSetString = $r('app.string.sim_null_character');
        if (this.curEditList.id === 0) {
          setCache(this.SIM_CARD_Change, 1);
          this.setSimActive(0, false)
          this.list[0].name = $r('app.string.sim_not_enabled');
          this.isStop1 = false;
          this.isStop2 = true;
          this.changeCard = false;
          this.isCardChange = false
        } else {
          this.changeCard = true;
          this.setSimActive(1, false)
          this.list[1].name = $r('app.string.sim_not_enabled');
          this.isStop1 = true;
          this.isStop2 = false;
          this.isCardChange = true;
        };
      }
    }),
    alignment: DialogAlignment.Bottom,
    autoCancel: false,
    offset: { dx: 0, dy: -30 }
  })
  updataInfo: CustomDialogController = new CustomDialogController({
    builder: UpdataInfo({ title: this.upDataTitle, isChange: this.upisChange }),
    alignment: DialogAlignment.Bottom,
    autoCancel: false,
    offset: { dx: 0, dy: -30 }
  })

  edit(item) {
    LogUtils.i(TAG, "onclick edit this.title:" + JSON.stringify(item.title))
    this.title = item.title;
    this.curEditList = item;
    if (item.id === 0) {
      if (this.phone1Number) {
        this.phoneNumber = this.phone1Number;
      } else {
        this.getNetName(0);
      }
    } else {
      if (this.phone2Number) {
        this.phoneNumber = this.phone2Number;
      } else {
        this.getNetName(1)
      }
    };
    this.editSimInfo.open();
  }

  stopCard(item, boolean) {
    this.simCardStop = boolean;
    if (!boolean) {
    };
    this.upisChange = boolean;
  };

  UpdataInfo(v) {
    clearTimeout(this.timer);
    this.upisChange = v;
    this.updataInfo.open();
    this.timer = setTimeout(() => {
      this.updataInfo.close();
    }, 15000)
  };

  /**
   * Get the customized mobile phone number set by the user
   */
  getShowNumber(slotId) {
    simServiceProxy.getShowNumber(slotId).then((res: any) => {
      if (!slotId) {
        if (res === 'null') {
          this.getPhoneNumber(0)
        } else {
          if (slotId) {
            this.phone2Number = res;
          } else {
            this.phone1Number = res;
          }
        }
      } else {
        if (res === 'null') {
          this.getPhoneNumber(1)
        } else {
          if (slotId) {
            this.phone2Number = res;
          } else {
            this.phone1Number = res;
          }
        }
      };
    }).catch((err) => {
      this.getPhoneNumber(slotId);
    })
  }

  /**
   * Get the custom operator name set by the user -- success
   */
  getShowName(slotId) {
    simServiceProxy.getShowName(slotId).then((res) => {
      if (!slotId) {
        if (res === 'null') {
          this.getNetName(0)
        } else {
          this.list[slotId].name = res;
        }
      } else {
        if (res === 'null') {
          this.getNetName(1)
        } else {
          this.list[slotId].name = res;
        }
      };
      this.isChange = !this.isChange;
    }).catch((err) => {
      this.getNetName(slotId)
    })
  }

  /**
   * Get card slot operator name
   */
  getNetName(slotId) {
    radioServiceProxy.getOperatorName(slotId).then((res: string) => {
      if (!slotId) {
        this.list[slotId].name = res;
      } else {
        this.list[slotId].name = res;
      }
      this.isChange = !this.isChange
    }).catch((err) => {
    })
  }

  /**
   * Whether there is a card
   */
  hasSimCard(slotId) {
    simServiceProxy.hasSimCard(slotId).then((res: boolean) => {
      this.isSimCardClosed = res;
      this.isChange = !this.isChange;
    }).catch((err) => {
    })
  }

  /**
   * Get card status
   */
  async getSimState(slotId) {
    this.getSupportNetwork(slotId);
    this.hasSimCard(slotId);
    this.isSimActive(slotId);
    simServiceProxy.getSimState(slotId).then((res: number) => {
      if (![4, 5].indexOf(res)) {
        this.list[slotId].disabled = true;
        this.list[slotId].isOpened = true;
        this.getShowName(slotId);
        this.getShowNumber(slotId);
      } else if (![2, 3].indexOf(res)) {
        this.list[slotId].name = $r('app.string.sim_no_service');
        this.list[slotId].isOpened = false;
        this.getShowNumber(slotId);
      } else if (![1].indexOf(res) && !this.isSimCardClosed) {
        this.list[slotId].name = $r('app.string.sim_no_card_inserted');
        this.list[slotId].isOpened = false;
        if (slotId) {
          this.phone2Number = '';
        } else {
          this.phone1Number = '';
        }
        this.list[slotId].disabled = false;
        this.list[slotId].info = '4G/3G/2G';
      } else if (![-1].indexOf(res)) {
        this.list[slotId].info = '4G/3G/2G';
        this.list[slotId].disabled = false;
        this.list[slotId].isOpened = false;
        this.list[slotId].isOpened = false;
        if (slotId) {
          this.phone2Number = '';
        } else {
          this.phone1Number = '';
        }
        this.list[slotId].name = $r('app.string.sim_no_card_inserted');
      }
      this.isChange = !this.isChange;
      this.updataInfo.close();
      clearTimeout(this.timer)
    }).catch((err) => {
      this.list[slotId].name = $r('app.string.sim_no_card_inserted');
      if (slotId) {
        this.phone2Number = '';
      } else {
        this.phone1Number = '';
      }
      this.list[slotId].disabled = false;
      this.list[slotId].isOpened = false;
      this.list[slotId].info = '4G/3G/2G';
      this.simCardStop = false;
    });
    this.isChange = !this.isChange;
  }

  onInit() {
    this.getSimState(0);
    this.getSimState(1);
  }

  /**
   * Get the phone number of sim card
   */
  getPhoneNumber(slotId) {
    simServiceProxy.getSimTelephoneNumber(slotId).then((res: string) => {
      if (!slotId) {
        this.phone1Number = res;
      } else {
        this.phone2Number = res;
      }
    }).catch((err) => {
      this.phone2Number = '';
    })
  }

  setSimActive(slotId, bool) {
    simServiceProxy.setSimActive(slotId, bool).then((res) => {
      if (bool) {
        this.getShowName(slotId);
      } else {
        this.list[slotId].name = $r('app.string.sim_not_enabled');
        this.list[slotId].info = '4G/3G/2G';
      }
      this.updataInfo.close();
      clearTimeout(this.timer);
    }).catch((err) => {
    })
  }

  /**
   * Whether the sim card is activated
   */
  isSimActive(slotId) {
    simServiceProxy.isSimActive(slotId).then((res) => {
      if (!res && this.isSimCardClosed) {
        this.list[slotId].isOpened = false;
        this.list[slotId].name = $r('app.string.sim_not_enabled');
        this.list[slotId].info = '4G/3G/2G';
      }
    }).catch((err) => {
      this.list[slotId].isOpened = false;
    })
  }

  getSupportNetwork(slotId) {
    radioServiceProxy.getSupportNetwork(slotId).then((res) => {
      if (res) {
        this.list[slotId].info = '5G/4G/3G/2G';
      } else {
        this.list[slotId].info = '4G/3G/2G';
      }
    }).catch((err) => {
    })
  }

  /**
   * Get default voice
   */
  getDefaultVoiceSlotId() {
    simServiceProxy.getDefaultVoiceSlotId().then((res: number) => {
      this.diaLing = res;
    }).catch((err) => {
    })
  }

  /**
   * Set default voice
   */
  setDefaultVoiceSlotId(slotId) {
    simServiceProxy.setDefaultVoiceSlotId(slotId).catch((err) => {
    })
  }

  addRegisterSimStateChange(slotId) {
    registerSimStateChange(slotId, async () => {
      this.getSimState(slotId);
      this.isChange = !this.isChange
    })
  }

  setDefaultDataSlotId(slotId) {
    dataServiceProxy.setDefaultDataSlotId(slotId)
  }

  aboutToAppear() {
    this.onInit();
    if (getMaxSimCount() === 2) {
      this.addRegisterSimStateChange(1);
    }
    this.addRegisterSimStateChange(0);
    this.isChange = !this.isChange;
  }

  build() {
    Column() {
      Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
        Row() {
          Stack() {
            Image($r('app.media.phone')).width(62).height(42)
            Text(this.list[0].title).fontSize('12vp').fontColor('#333333')
              .align(Alignment.Start)
              .lineHeight(21)
              .fontWeight(FontWeight.Regular)
              .fontFamily("HarmonyHeiTi")
          }

          Column() {
            Text(this.list[0].name).fontSize('16vp').margin({
              bottom: 2
            }).fontFamily("HarmonyHeiTi").fontWeight(FontWeight.Medium)
              .lineHeight(22)
            Text(this.phone1Number).fontColor('#555').fontSize('14vp').margin({ bottom: this.phone2Number ? 0 : 2 })
              .lineHeight(19).fontFamily("HarmonyHeiTi").fontWeight(FontWeight.Regular)
            Text(this.list[0].info).fontColor(this.isChange ? '#555' : '#555').fontSize('14vp')
              .lineHeight(19).fontFamily("HarmonyHeiTi").fontWeight(FontWeight.Regular)
          }
          .margin({ left: 16 })

          Image($r('app.media.redact')).width('15vp').height('15vp')
            .onClick(() => {
              this.edit(this.list[0])
            }).margin({ left: 20 }).enabled(this.list[0].isOpened)
        }

        Row() {
          Toggle({ type: ToggleType.Switch, isOn: this.list[0].isOpened })
            .width(36)
            .height(20)
            .onChange((isOn: boolean) => {
              LogUtils.i(TAG, "onclick toggle card one")
              this.getDefaultVoiceSlotId();
              this.list[0].isOpened = !this.list[0].isOpened;
              this.upDataTitle = this.list[0].title;
              if (!this.list[0].isOpened) {
                if (this.diaLing == 0) {
                  this.setDefaultVoiceSlotId(-1)
                  this.setDefaultDataSlotId(1)
                  this.defaultSetString = $r('app.string.not_set');
                }
              }
              if (this.list[1].isOpened) {
                if (!this.list[0].isOpened) {
                  if (this.isCardChange) {
                    this.title = $r('app.string.sim_card_one_no_space');
                    this.curEditList = this.list[0];
                    this.setDefaultDataSlotId(1);
                    this.stopSim.open();
                    this.stopCard(this.list[0], false);
                  };
                };
              };
              if (this.list[0].isOpened && this.list[1].isOpened) {
                this.UpdataInfo(true);
                this.setSimActive(0, true)
                this.stopCard(this.list[0], true);
              }
              if (!this.list[0].isOpened && this.list[1].isOpened && !this.isCardChange) {
                this.setDefaultDataSlotId(1)
                this.UpdataInfo(false);
                this.setSimActive(0, false)
                this.stopCard(this.list[0], false);
              }
              if (this.list[0].isOpened && !this.list[1].isOpened) {
                this.UpdataInfo(true);
                this.setSimActive(0, true)
                this.changeCard = true;
              } else if (!this.list[0].isOpened && !this.list[1].isOpened) {
                this.UpdataInfo(false);
                this.isCardChange = false;
                this.setDefaultDataSlotId(1)
                this.setSimActive(0, false)
                this.list[0].name = $r('app.string.sim_not_enabled');
                this.stopCard(this.list[0], false);
              } else if (!this.list[0].isOpened || !this.list[1].isOpened) {
                this.stopCard(this.list[0], false);
              }
              this.isChange = !this.isChange;
            })
        }
      }
      .opacity(this.list[0].isOpened ? 1 : 0.4)
      .enabled(this.list[0].disabled)
      .padding({
        left: 12,
        right: 12,
        top: 12,
        bottom: 12
      })
      .height(104)
      .width("100%")
      .borderRadius($r('app.float.radius_24'))
      .backgroundColor($r("sys.color.ohos_id_color_foreground_contrary"))


      Column() {
      }
      .height(16)
      .width("100%")

      Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
        Row() {
          Stack() {
            Image($r('app.media.phone')).width(62).height(42)
            Text(this.list[1].title).fontSize('12vp').fontColor('#333333')
              .align(Alignment.Start)
              .lineHeight(21)
              .fontWeight(FontWeight.Regular)
              .fontFamily("HarmonyHeiTi")
          }

          Column() {
            Text(this.list[1].name).fontSize('16vp').margin({ bottom: 2 })
              .fontFamily("HarmonyHeiTi").fontWeight(FontWeight.Medium)
              .lineHeight(22)
            Text(this.phone2Number).fontColor('#555').fontSize('14vp').margin({ bottom: this.phone2Number ? 0 : 2 })
              .lineHeight(19).fontFamily("HarmonyHeiTi").fontWeight(FontWeight.Regular)
            Text(this.list[1].info).fontColor(this.isChange ? '#555' : '#555').fontSize('14vp')
              .lineHeight(19).fontFamily("HarmonyHeiTi").fontWeight(FontWeight.Regular)
          }
          .margin({ left: 16 })

          Image($r('app.media.redact')).width('15vp').height('15vp')
            .onClick(() => {
              this.edit(this.list[1]);
            }).margin({ left: 20 }).enabled(this.list[1].isOpened)
        }

        Row() {
          Toggle({ type: ToggleType.Switch, isOn: this.list[1].isOpened })
            .width(36)
            .height(20)
            .onChange((isOn: boolean) => {
              LogUtils.i(TAG, "onclick toggle card two")
              this.getDefaultVoiceSlotId();
              this.list[1].isOpened = !this.list[1].isOpened;
              this.upDataTitle = this.list[1].title;
              if (!this.list[1].isOpened) {
                if (this.diaLing == 0) {
                  this.setDefaultDataSlotId(0)
                  this.setDefaultVoiceSlotId(-1)
                  this.defaultSetString = $r('app.string.not_set');
                }
              }
              if (this.list[0].isOpened) {
                if (!this.list[1].isOpened) {
                  if (!this.isCardChange) {
                    this.setDefaultDataSlotId(0)
                    this.title = $r('app.string.sim_card_two_no_space');
                    this.curEditList = this.list[1];
                    this.stopSim.open();
                    this.stopCard(this.list[1], false);
                  };
                };
              };
              if (this.list[0].isOpened && this.list[1].isOpened) {
                this.UpdataInfo(true);
                this.setSimActive(1, true);
                this.stopCard(this.list[1], true);
              }
              if (this.list[0].isOpened && !this.list[1].isOpened && this.isCardChange) {
                this.setDefaultDataSlotId(0)
                this.UpdataInfo(false);
                this.setSimActive(1, false);
                this.stopCard(this.list[1], false);
              }
              if (!this.list[0].isOpened && this.list[1].isOpened) {
                this.UpdataInfo(true);
                this.setSimActive(1, true);
                this.changeCard = true;
              } else if (!this.list[0].isOpened && !this.list[1].isOpened) {
                this.setDefaultDataSlotId(0)
                this.UpdataInfo(false);
                this.isCardChange = false;
                this.setSimActive(1, false);
                this.list[1].name = $r('app.string.sim_not_enabled');
                this.stopCard(this.list[1], false);
              } else if (!this.list[0].isOpened || !this.list[1].isOpened) {
                this.stopCard(this.list[1], false);
              }
              this.isChange = !this.isChange;
            })
        }
      }
      .opacity(this.list[1].isOpened ? 1 : 0.4)
      .enabled(this.list[1].disabled)
      .padding({
        left: 12,
        right: 12,
        top: 12,
        bottom: 12
      })
      .width("100%")
      .backgroundColor($r("sys.color.ohos_id_color_foreground_contrary"))
      .borderRadius($r('app.float.radius_24'))
    }
    .width('100%')
  }
}

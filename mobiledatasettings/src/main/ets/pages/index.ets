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
import publiccontent from '../common/components/publiccontent';
import item from '../common/components/listItem/listItem';
import call from '@ohos.telephony.call';
import { registerSimStateChange } from '../model/registerSimStateApi'
import { getSimStateCardOne, getSimStateCardTwo } from '../common/model/getSimStateApi';
import { getSimCardOnePhoneNumber, getSimCardTwoPhoneNumber } from '../common/model/getSimTelephoneNumberApi';
import {
  isCellularDataRoamingEnabled,
  enableCellularDataRoaming,
  disableCellularDataRoaming,
  getSupportNetwork
} from '../common/model/getCellularDataRoamingEnabledApi';
import { setPreferredNetwork } from '../common/model/setPreferredNetworkApi';
import { getPreferredNetwork } from '../common/model/getPreferredNetworkModeApi';
import {
  getCellularDataState,
  enableCellularData,
  disableCellularData,
  getOperatorName
} from '../model/mobileDataStatus';
import { MOBILE_DATA_STATUS } from '../common/constant/moblieDataConst';
import HeadComponent from '../common/components/headComponent'
import { SubHeader } from '../common/components/subHeader'
import LogUtils from '../common/utils/LogUtils'

const TAG = "Index"

@Entry
@Component
struct Index {
  scroller: Scroller = new Scroller();
  @State byValueWLMS: any = publiccontent.strings.fourAuto;
  @State publicheader: any = publiccontent.strings.mobileData;
  @State isLoading: boolean = true;
  @State simState: string = '';
  @State moisBtn: boolean = true;
  @State isBtn: boolean = true;
  @State gqBtn: boolean = true;
  @State moislastone: boolean = true;
  @State isSupport: boolean = true;
  @State mobileDataDisabled: boolean = false;
  @State mobileDataDisabled2: boolean = false;
  // Mobile data switch
  @State isDataEnable: boolean = true;
  // Data roaming switch
  @State DataRoamSwitch: boolean = false;
  // HD call switch
  @State volteSwitch: boolean = false;
  // Card I status
  @State simStateStatusCardOne: boolean = true;
  // Card 2 status
  @State simStateStatusCardTwo: boolean = false;
  @State ControlswitchWLMS: boolean = false;
  @State slotId: number = 0;
  @State dialogTitle: any = publiccontent.strings.preferredNetworkMode;
  setCache_cun_name = 'DISTRIBUTEDDATA_CUN_NAME';
  setCache_wl_name = 'SETCACHE_WL_NAME';
  @State enable5g: boolean = false;
  @State enableISM: boolean = false;
  @State enableISM2: boolean = false;
  @State TelephoneNumber: string = '';
  @State TelephoneNumber2?: string = '';
  @State ceshi: boolean = false;

  /**
   * Get network mode
   *
   * @param {Object} slotId - call slotId
   */
  async getPreferredNetwork(slotId) {
    const res = await getPreferredNetwork(this.slotId);
    if (res == 0) {
      this.byValueWLMS = $r('app.string.mobile_data_5g');
    } else if (res == 5) {
      this.byValueWLMS = $r("app.string.mobile_data_4g");
    } else if (res == 6) {
      this.byValueWLMS = $r("app.string.mobile_data_3g");
    } else if (res == 1) {
      this.byValueWLMS = $r("app.string.mobile_data_2g");
    }
  }

  /**
   * This interface is used to obtain sim cardOne status
   */
  getSimStateDataCardOne() {
    getSimStateCardOne().then((res: any) => {
      LogUtils.i(TAG, "getSimStateData Card1 :success " + JSON.stringify(res))
      const simState = {
        SIM_STATE_UNKNOWN: 0,
        SIM_STATE_NOT_PRESENT: 1,
        SIM_STATE_LOCKED: 2,
        SIM_STATE_NOT_READY: 3,
        SIM_STATE_READY: 4,
        SIM_STATE_LOADED: 5
      };
      this.simState = res;
      if (res == simState.SIM_STATE_LOADED || res == simState.SIM_STATE_READY) {
        this.simStateStatusCardOne = true;
      } else {
        this.simStateStatusCardOne = false;
      }
    }).catch((err) => {
      LogUtils.i(TAG, 'getSimStateData Card1 :console.error() ' + JSON.stringify(err.message));
    });
  }

  /**
   * This interface is used to obtain sim cardTwo status
   */
  getSimStateDataCardTwo() {
    getSimStateCardTwo().then((res: any) => {
      LogUtils.i(TAG, "getSimState Card2 :success " + JSON.stringify(res));
      const simState = {
        SIM_STATE_UNKNOWN: 0,
        SIM_STATE_NOT_PRESENT: 1,
        SIM_STATE_LOCKED: 2,
        SIM_STATE_NOT_READY: 3,
        SIM_STATE_READY: 4,
        SIM_STATE_LOADED: 5
      };
      if (res == simState.SIM_STATE_LOADED || res == simState.SIM_STATE_READY) {
        this.simStateStatusCardTwo = true;
      } else {
        this.simStateStatusCardTwo = false;
      }
    }).catch((err) => {
      LogUtils.i(TAG, 'getSimState Card2 :console.error() ' + JSON.stringify(err.message));
    });
  }

  getSupportNetwork(slotId) {
    getSupportNetwork(slotId).then((res) => {
      if (res) {
        this.isSupport = true;
      } else {
        this.isSupport = false;
      }
    }).catch((err) => {
    })
  }

  /**
   * Get mobile phone number
   */
  getSimCardOnePhoneNumber() {
    getSimCardOnePhoneNumber().then((res) => {
      LogUtils.i(TAG, "getSimTelephoneNumber card1 other success" + JSON.stringify(res));
      this.TelephoneNumber = res
    }).catch((err) => {
      LogUtils.i(TAG, "getSimTelephoneNumber card1 other catch" + JSON.stringify(err));
    });
  }

  /**
   * Get mobile phone number
   */
  getSimCardTwoPhoneNumber() {
    getSimCardTwoPhoneNumber().then((res) => {
      LogUtils.i(TAG, "getSimTelephoneNumber card2 other success" + JSON.stringify(res));
      this.TelephoneNumber2 = res;
    }).catch((err) => {
      LogUtils.i(TAG, "getSimTelephoneNumber card2 other catch" + JSON.stringify(err));
    });
  }

  /**
   * Get mobile data on or off
   */
  getCellularDataState() {
    getCellularDataState().then((data) => {
      if (data == MOBILE_DATA_STATUS.DATA_STATE_CONNECTED) {
        /**
         * Gets the status of the mobile data
         */
        enableCellularData().then((data) => {
          LogUtils.i(TAG, "enableCellularData success" + JSON.stringify(data));
        }).catch((error) => {
          LogUtils.i(TAG, "enableCellularData catch" + JSON.stringify(error));
        });
        this.isDataEnable = true;
      } else if (data == MOBILE_DATA_STATUS.DATA_STATE_DISCONNECTED || data == MOBILE_DATA_STATUS.DATA_STATE_UNKNOWN) {
        this.isDataEnable = false;
        /**
         * Gets the status of the disableCellularData
         */
        disableCellularData().then((data) => {
          LogUtils.i(TAG, "disableCellularData success" + JSON.stringify(data));
        }).catch((error) => {
          LogUtils.i(TAG, "disableCellularData error" + JSON.stringify(error));
        });
      }
    }).catch((error) => {
      LogUtils.i(TAG, "disableCellularData catch" + JSON.stringify(error));
    });
  }

  addRegisterSimStateChange(slotId) {
    registerSimStateChange(slotId, async () => {
      this.getCellularDataRoamingEnabled();
      this.getSimStateDataCardOne();
      this.getSimStateDataCardTwo();
      this.getPreferredNetwork(slotId);
      this.getSupportNetwork(slotId);
      this.getSimCardOnePhoneNumber();
      this.getSimCardTwoPhoneNumber();
      this.getCellularDataState();
    })
  }

  isImsSwitchEnabled(slotId) {
    call.isImsSwitchEnabled(slotId).then((res: any) => {
      if (slotId) {
        this.enableISM2 = res;
      } else {
        this.enableISM = res;
      }
    })
  }

  aboutToAppear() {
    LogUtils.i(TAG, "aboutToAppear")
    this.addRegisterSimStateChange(0);
    this.addRegisterSimStateChange(1);
    //Get data roaming status
    this.getCellularDataRoamingEnabled();
    //Get HD call status
    this.isImsSwitchEnabled(0);
    this.isImsSwitchEnabled(1);
    this.getSimStateDataCardOne();
    this.getSimStateDataCardTwo();
    //Get network mode
    this.getPreferredNetwork(this.slotId);
    getOperatorName().then((res) => {
    })
    this.getSupportNetwork(this.slotId);
    //card number acquire
    this.getSimCardOnePhoneNumber();
    this.getSimCardTwoPhoneNumber();
    this.getCellularDataState();
  }

  /**
   * Set network mode
   */
  radioChange(slotId, v) {
    const res = setPreferredNetwork(slotId, v);
    LogUtils.i(TAG, "radioChange res:" + JSON.stringify(res));
  }

  getCellularDataRoamingEnabled() {
    isCellularDataRoamingEnabled().then((res) => {
      if (!res) {
        this.DataRoamSwitch = false;
        disableCellularDataRoaming().then((data) => {
          LogUtils.i(TAG, "disableCellularDataRoaming success: then" + JSON.stringify(data));
        }).catch((error) => {
          LogUtils.i(TAG, "disableCellularDataRoaming error" + JSON.stringify(error));
        });
      } else {
        this.DataRoamSwitch = true;
        enableCellularDataRoaming().then((data) => {
          LogUtils.i(TAG, "enableCellularDataRoaming success: then" + JSON.stringify(data));
        }).catch((error) => {
          LogUtils.i(TAG, "enableCellularDataRoaming error" + JSON.stringify(error));
        });
      }
    }).catch((err) => {
      LogUtils.i(TAG, "enableCellularDataRoaming catch:" + JSON.stringify(err));
    });
  }

  build() {
    Column() {
      Column() {

        HeadComponent();

        Stack({ alignContent: Alignment.TopStart }) {
          Scroll(this.scroller) {
            Column() {
              SubHeader({ titleContent: $r('app.string.mobile_data_general'), subTitleContent: '' });

              Flex({
                direction: FlexDirection.Row,
                justifyContent: FlexAlign.SpaceBetween,
                alignItems: ItemAlign.Center
              }) {
                Column() {
                  Row() {
                    Text($r('app.string.mobile_data'))
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontFamily('HarmonyHeiTi')
                      .lineHeight(22)
                      .fontColor($r('app.color.font_color_182431'))
                      .opacity(this.isDataEnable ? 0.9 : 0.6)
                  }

                  Row() {
                    Text($r('app.string.mobile_data_charges'))
                      .fontSize(14)
                      .fontWeight(FontWeight.Regular)
                      .fontFamily('HarmonyHeiTi')
                      .fontColor('#555')
                      .opacity(0.6)
                      .lineHeight(19)
                      .maxLines(2)
                  }
                  .margin({ top: 2, right: 26 })
                }
                .opacity(this.simStateStatusCardOne ? 1 : 0.4)
                .alignItems(HorizontalAlign.Start)

                Toggle({ type: ToggleType.Switch, isOn: this.isDataEnable })
                  .width(36)
                  .height(20)
                  .enabled(this.simStateStatusCardOne)
                  .opacity(this.simStateStatusCardOne ? 1 : 0.4)
                  .onChange((isOn: boolean) => {
                    this.isDataEnable = !this.isDataEnable
                    if (this.isDataEnable == false) {
                      disableCellularData().then((data) => {
                        LogUtils.i(TAG, "disableCellularData: then" + JSON.stringify(data))
                      }).catch((error) => {
                        LogUtils.i(TAG, "disableCellularData: catch" + JSON.stringify(error))
                      });
                    } else {
                      enableCellularData().then((data) => {
                        LogUtils.i(TAG, "enableCellularData: then" + JSON.stringify(data))
                      }).catch((error) => {
                        LogUtils.i(TAG, "enableCellularData: catch" + JSON.stringify(error))
                      });
                    }
                  })
              }
              .padding({
                left: 12,
                right: 12,
                top: 4,
                bottom: 4
              })
              .height(90)
              .width("100%")
              .borderRadius(24)
              .backgroundColor($r("sys.color.ohos_id_color_foreground_contrary"))

              SubHeader({ titleContent: $r('app.string.mobile_data_card1'), subTitleContent: this.TelephoneNumber });

              Column() {
                item({
                  isBtn: this.moisBtn,
                  LastOne: this.moislastone,
                  Controlswitch: this.DataRoamSwitch,
                  title: $r('app.string.mobile_data_dataRoaming'),
                  describe: $r('app.string.mobile_data_enableDataWhileRoaming'),
                  isDisabled: this.simStateStatusCardOne,
                  isCard: true,
                  isSupport: false,
                  isCon: 0,
                })
                Divider()
                  .strokeWidth(0.5)
                  .color("#E3E3E3")
                  .lineCap(LineCapStyle.Round)
                  .margin({ right: '2%' })

                item({
                  isBtn: this.gqBtn,
                  LastOne: this.moislastone,
                  Controlswitch: this.enableISM,
                  title: $r('app.string.mobile_data_volte'),
                  describe: $r('app.string.mobile_data_confirmation_function'),
                  isDisabled: this.simStateStatusCardOne,
                  isSupport: false,
                  isCard: true,
                  isCon: 22,
                })
              }
              .padding({
                left: 12,
                right: 12,
                top: 4,
                bottom: 4
              })
              .width("100%")
              .borderRadius(24)
              .backgroundColor($r("sys.color.ohos_id_color_foreground_contrary"))

              SubHeader({ titleContent: $r('app.string.mobile_data_card2'), subTitleContent: this.TelephoneNumber2 });

              Column() {
                item({
                  isBtn: this.moisBtn,
                  LastOne: this.moislastone,
                  Controlswitch: this.mobileDataDisabled2,
                  title: $r('app.string.mobile_data_dataRoaming'),
                  describe: $r('app.string.mobile_data_enableDataWhileRoaming'),
                  isDisabled: this.simStateStatusCardTwo,
                  isSupport: false,
                  isCard: true,
                  isCon: 0,
                })
                Divider()
                  .strokeWidth(0.5)
                  .color("#E3E3E3")
                  .lineCap(LineCapStyle.Round)
                  .margin({ right: '2%' })
                item({
                  isBtn: this.gqBtn,
                  LastOne: this.moislastone,
                  Controlswitch: this.enableISM2,
                  title: $r('app.string.mobile_data_volte'),
                  describe: $r('app.string.mobile_data_confirmation_function'),
                  isDisabled: this.simStateStatusCardTwo,
                  isSupport: false,
                  isCard: true,
                  isCon: 22,
                })
              }
              .padding({
                left: 12,
                right: 12,
                top: 4,
                bottom: 4
              })
              .padding({
                left: 12,
                right: 12,
                top: 4,
                bottom: 4
              })
              .width("100%")
              .borderRadius(24)
              .backgroundColor($r("sys.color.ohos_id_color_foreground_contrary"))
            }
            .alignItems(HorizontalAlign.Start)
          }
        }
      }
      .useSizeType({
        sm: { span: 4, offset: 0 },
        md: { span: 6, offset: 1 },
        lg: { span: 8, offset: 2 }
      })
    }
    .visibility(this.isLoading ? Visibility.Visible : Visibility.Hidden)
    .padding({
      left: 12,
      right: 12 })
    .backgroundColor($r("sys.color.ohos_id_color_sub_background"))
    .width("100%")
    .height("100%")
  }
}
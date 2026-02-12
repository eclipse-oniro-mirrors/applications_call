/**
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

/**
 * @file: Mobile Network Home page
 */
import {
  LogUtils,
  MobileDataGlobalContextHelper,
  Constants,
  removeAirPlaneModeListener,
  EdmConstants,
  ToastUtil,
  getSystemParam,
  ReportUtil,
  TitleParams,
  TitleBarLayout
} from '@ohos/common/CommonIndex';
import lazy { SubHeader } from '@ohos.arkui.advanced.SubHeader';
import { formatResourceToString, formatResourceToStringWithArgs  } from '../common/utils/formatResourceToString';
import item from '../common/components/listItem/listItem';
import {
  registerSimStateChangeForSlotId,
  registerAccountInfoChange,
  registerCellularDataSettingChange,
  getMaxSimCount,
  unRegisterSimStateChange,
  unRegisterAccountInfoChange,
  registerCellularDataRoamingSettingChange,
  removeCellularDataRoamingSettingListener
} from '../model/RegisterSimStateApi';
import lazy {
  setPreferredNetwork,
  getPreferredNetwork
} from '../common/model/setPreferredNetworkApi';
import { BusinessError } from '@ohos.base';
import sim from '@ohos.telephony.sim';
import radio from '@ohos.telephony.radio';
import common from '@ohos.app.ability.common';
import { display, LengthMetrics, TextModifier, curves, EditableTitleBar } from '@kit.ArkUI';
import { isSplit, isTablet } from '../common/utils/DeviceTypeUtils';
import { getPaddingByDevice, needFilterEflInfo } from '../common/utils/MobileDataUtils';
import lazy { SelectDialog } from '@ohos.arkui.advanced.Dialog';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';
import { DynamicLoader } from '../common/control/DynamicLoader';
import { NetworkOperatorsParams } from '../model/MobileLoaderParams';
import { SimCardOneViewData } from '../viewModel/MobileDataViewModel/SimCardOneViewData';
import { SimCardTwoViewData } from '../viewModel/MobileDataViewModel/SimCardTwoViewData';
import { GeneralViewEvent } from '../viewModel/MobileDataViewModel/GeneralViewEvent';
import { MobileViewData } from '../viewModel/MobileDataViewModel/MobileViewData';
import telephonyData from '@ohos.telephony.data';
import displaySync from '@ohos.graphics.displaySync';
import {
  addRegisterDistributedStateListener,
  queryDistributedState,
  removeRegisterDistributedStateListener
} from '../common/utils/DistributeUtils';
import { CustPhoneNetworkStruct, OperatorConfigUtils } from '@ohos/cust/src/main/CustIndex';
import { createSubscriber,
  subscribeConfigChange,
  unSubscribeConfigChange } from '@ohos/common/src/main/ets/utils/CommonUtil';
import { commonEventManager } from '@kit.BasicServicesKit';
import * as CallSettingsConstant from '../common/constant/CallSettingsConstant';
import queryAddData from '../common/utils/queryAddData';
import WifiCallingSettings from './WifiCallingSettings';
// import { Navigation, HdsNavigationTitleMode, HdsNavigationAttribute } from '@hms.hds.hdsBaseComponent';
import CallColumnUtils from '../common/utils/CallColumnUtils';
import { getSimLabelSync } from '../common/model/getSimStateApi';

class ObjInterface {
  public sonSlotId: number = 0;
}

class NetworkComponentParam {
  public card: number = 0;
  public enabled: boolean = true;
}

const MAX_SIM_COUNTS = 2;
const MOBILE_INDEX_APPEAR_TASK_ID = 1002;
const TAG = 'MobileDataSettingsIndex';
const commons: queryAddData = new queryAddData();
const ANIM_DURATION: number = 150;
const CIRCLE_ANIM_DURATION: number = 30;

@Entry
@Component
struct MobileDataIndex {
  @Provide('pathInfos') pathInfos: NavPathStack = new NavPathStack();
  public storage = LocalStorage.getShared();
  private session: UIExtensionContentSession =
    this.storage?.get<UIExtensionContentSession>('session') as UIExtensionContentSession;
  scroller: Scroller = new Scroller();
  @State @Watch('updateCustParamCardOne') mCustNetworkCardOne: CustPhoneNetworkStruct = new CustPhoneNetworkStruct();
  @State @Watch('updateCustParamCardTwo') mCustNetworkCardTwo: CustPhoneNetworkStruct = new CustPhoneNetworkStruct();
  @State @Watch('updateCardOneSwitch') byValueWlms: Resource = $r('app.string.emptyStr');
  @State @Watch('updateCardTwoSwitch') byValueWlmsTwo: Resource = $r('app.string.emptyStr');
  @State publicheader: Resource = $r('app.string.mobile_data');
  @State isLoading: boolean = true;
  @State moisBtn: boolean = true;
  @State isBtn: boolean = true;
  @State gqBtn: boolean = true;
  @State apnBtn: boolean = false;
  @State moislastone: boolean = true;
  @State mobileDataDisabled: boolean = false;
  @State mobileDataDisabled2: boolean = false;
  // Mobile data switch
  @State isDataEnable: boolean = true;
  // Mobile AirPlane Mode
  @State isAirPlaneMode: boolean = false;
  // Is Satellite mode
  @State isSatelliteMode: boolean = false;
  // Is Distribute Sink
  @State isDistributeSink: boolean = false;
  // Data roaming switch
  @State dataRoamSwitchCardOne: boolean = false;
  @State dataRoamSwitchCardTwo: boolean = false;
  // Volte
  @State cardOneVolteIsHide: boolean = true;
  @State cardTwoVolteIsHide: boolean = true;
  private subscriber?: commonEventManager.CommonEventSubscriber;
  @State lteOrNrTitleCardOne: Resource = $r('app.string.emptyStr');
  @State lteOrNrTitleCardTwo: Resource = $r('app.string.emptyStr');
  @State @Watch('changeNetModeValueTextCardOne') lteOrNrSwitchCardOne: boolean = true;
  @State @Watch('changeNetModeValueTextCardTwo') lteOrNrSwitchCardTwo: boolean = true;
  @State slotId: number = 0;
  @State enable5g: boolean = false;
  @StorageLink('imsOne') enableISM: boolean = false;
  @State enableISM2: boolean = false;
  @State telephoneNumber: string = '';
  @State telephoneNumber2?: string = '';
  @State cardOne: number = 0;
  @State cardTwo: number = 1;
  @State modeList: SheetInfo[] = [];
  @State storageOne: number = 0;
  @State storageTwo: number = 0;
  @State hasSimCard1: boolean = false;
  @State hasSimCard2: boolean = false;
  @State networkModeStatus: boolean = true;
  @State apnControlSwitch: boolean = true;
  @State byValueWlmsList: Record<number, Resource> = {
    34: $r('app.string.emptyStr'),
    5: $r('app.string.emptyStr'),
    6: $r('app.string.emptyStr'),
    1: $r('app.string.emptyStr'),
  }
  @State radioId: number = -1;
  @StorageProp('foldStatus') @Watch('refreshFlodStatus') foldStatus: number = -1;
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('fontSizeScaleMargin') fontSizeScaleMargin: string = '';
  @StorageProp('topMarginOnScal') topMarginOnScal: string = '10vp';
  @StorageProp('bottomMarginOnScal') bottomMarginOnScal: string = '11vp';
  private startReason: string | undefined = AppStorage.get('startReason');
  @State isHideBackButton: boolean = false;
  @State secondaryModifier: TextModifier = new TextModifier().maxLines(3)
  @BuilderParam apnIndexLoader: () => void;
  @BuilderParam apnDetailsLoader: () => void;
  @BuilderParam NetworkOperatorsLoader: ($$: NetworkOperatorsParams) => void;
  @State @Watch('result') mSimCardOneViewData: SimCardOneViewData = new SimCardOneViewData();
  @State @Watch('result') mSimCardTwoViewData: SimCardTwoViewData = new SimCardTwoViewData();
  @State mMobileViewData: MobileViewData = new MobileViewData();
  @State @Watch('onVsyncChange') stages: number = 0;
  @State wifiCallingSwitchState: boolean = false;
  @State isShowSwitchStateText: boolean = false;
  @State cardOneWifiCallingIsShow: boolean = false;
  @State cardTwoWifiCallingIsShow: boolean = false;
  @StorageLink('wifiCallingSwitchStateCard1') wifiCallingSwitchStateCard1: boolean = false;
  @StorageLink('wifiCallingSwitchStateCard2') wifiCallingSwitchStateCard2: boolean = false;
  @StorageLink('wifiCallingImsModeCard1') wifiCallingImsModeCard1: string =
    CallSettingsConstant.WIFI_CALLING_IMS_MODE_WIFI;
  @StorageLink('wifiCallingImsModeCard2') wifiCallingImsModeCard2: string =
    CallSettingsConstant.WIFI_CALLING_IMS_MODE_WIFI;
  @State isShowWifiCallingSwitchCard1: boolean = false;
  @State isShowWifiCallingSwitchCard2: boolean = false;
  @State isDisableApnByEdm: boolean = false;
  @State isDisableMobileDataByEdm: boolean = false;
  @State titleX: number | string = '40%';
  @State opacityVal: number = 0;
  @State circleOpacityVal: number = 0;
  @State simCardInfo: [boolean, string][] = [
    [true, '1'],
    [true, '2']
  ];

  myDisplaySync:displaySync.DisplaySync = displaySync.create();
  private mGeneralViewEvent: GeneralViewEvent = new GeneralViewEvent();
  modeDialogController: CustomDialogController = new CustomDialogController({
    builder: SelectDialog({
      title: $r('app.string.emptyStr'),
      radioContent: this.modeList,
      selectedIndex: this.radioId,
      confirm: {
        value: $r('app.string.mobile_data_cancel'),
        action: () => {
          this.modeDialogController.close();
        }
      }
    }),
    showInSubWindow: true,
    gridCount: 4
  })

  async loadPage(key: string): Promise<void> {
    try {
      if (key === 'apnIndex') {
        let pageObj = await import('./ApnList');
        this.apnIndexLoader = pageObj.apnLoader;
      } else if (key === 'apnDetails') {
        let pageObj = await import('./ApnDetails');
        this.apnDetailsLoader = pageObj.apnDetailsLoader;
      } else if (key === 'NetworkOperators') {
        let pageObj = await import('../pages/NetworkOperators');
        this.NetworkOperatorsLoader = pageObj.NetworkOperatorsLoader;
      }
    } catch (err) {
      LogUtils.e(TAG, 'loadPage import error');
    }
  }

  @Builder
  myRouter(name: string, pageInfos: Object) {
    if (name === 'apnIndex') {
      this.apnIndexLoader();
    } else if (name === 'apnDetails') {
      this.apnDetailsLoader();
    } else if (name === 'NetworkOperators') {
      this.NetworkOperatorsLoader({
        isCellularDataEnable: this.mMobileViewData
      });
    } else if (name === 'WifiCallingSettings') {
      WifiCallingSettings({ slotId: (Object.entries(pageInfos))['cardType'] });
    }
  }

  setPreferredNetWordView(title: Resource) {
    if (this.slotId === 0) {
      this.byValueWlms = title;
    } else {
      this.byValueWlmsTwo = title;
    }
  }

  getNaviPadding(direction: string): LengthMetrics {
    let margin = CallColumnUtils.getInstance().getNaviPaddingSpace(direction);
    return LengthMetrics.resource(margin);
  }

  updateCustParamCardOne() {
    let isSimActive = sim.isSimActiveSync(0);
    let isSupportVowifi = this.mCustNetworkCardOne.isSupportVowifi;
    LogUtils.i(TAG, 'updateCustParamCardOne isSimActive:' + isSimActive +
      ', isSupportVolte:' + this.mCustNetworkCardOne.isSupportVolte +
      ', isHideVolte:' + this.mCustNetworkCardOne.isHideVolte + `, isSupportVowifi: ${isSupportVowifi}`);
    this.cardOneVolteIsHide = (this.mCustNetworkCardOne.isSupportVolte === true &&
      this.mCustNetworkCardOne.isHideVolte === false && isSimActive) ? false : true;
    this.lteOrNrTitleCardOne = this.mCustNetworkCardOne.isShowNr ? $r('app.string.mobile_data_enabled5G') :
    $r('app.string.mobile_data_enabled4G');
    if (this.mCustNetworkCardOne.isShowLte || this.mCustNetworkCardOne.isShowNr) {
      this.getNetworkCapability(Constants.SLOT_ID_ONE);
    }
    if (!this.cardOneVolteIsHide) {
      this.isImsSwitchEnabledSync(Constants.SLOT_ID_ONE);
    }
    this.isShowWifiCallingSwitchCard1 = isSupportVowifi && isSimActive;
    this.getWifiCallingSwitchState(0);
  }

  updateCustParamCardTwo() {
    let isSimActive = sim.isSimActiveSync(1);
    let isSupportVowifi = this.mCustNetworkCardTwo.isSupportVowifi;
    LogUtils.i(TAG, 'updateCustParamCardTwo isSimActive:' + isSimActive +
      ', isSupportVolte:' + this.mCustNetworkCardTwo.isSupportVolte +
      ', isHideVolte:' + this.mCustNetworkCardTwo.isHideVolte + `, isSupportVowifi: ${isSupportVowifi}`);
    this.cardTwoVolteIsHide = (this.mCustNetworkCardTwo.isSupportVolte === true &&
      this.mCustNetworkCardTwo.isHideVolte === false && isSimActive) ? false : true;
    this.lteOrNrTitleCardTwo = this.mCustNetworkCardTwo.isShowNr ? $r('app.string.mobile_data_enabled5G') :
    $r('app.string.mobile_data_enabled4G');
    if (this.mCustNetworkCardTwo.isShowLte || this.mCustNetworkCardTwo.isShowNr) {
      this.getNetworkCapability(Constants.SLOT_ID_TWO);
    }
    if (!this.cardTwoVolteIsHide) {
      this.isImsSwitchEnabledSync(Constants.SLOT_ID_TWO);
    }
    this.isShowWifiCallingSwitchCard2 = isSupportVowifi && isSimActive;
    this.getWifiCallingSwitchState(1);
  }

  getRadioContent(isOpen: boolean, isSupportNR: boolean): SheetInfo[] {
    let radioContent: SheetInfo[] = [];
    let currentRadioId: number = 0;
    if (isOpen) {
      if (isSupportNR) {
        radioContent.push({
          title: $r('app.string.emptyStr'),
          action: async () => {
            this.radioId = currentRadioId;
            await setPreferredNetwork(this.slotId, radio.PreferredNetworkMode.PREFERRED_NETWORK_MODE_NR_LTE_WCDMA_GSM);
            this.setPreferredNetWordView($r('app.string.emptyStr'));
          }
        })
        currentRadioId += 1;
      }
      radioContent.push({
        title: $r('app.string.emptyStr'),
        action: async () => {
          this.radioId = currentRadioId;
          await setPreferredNetwork(this.slotId, radio.PreferredNetworkMode.PREFERRED_NETWORK_MODE_LTE_WCDMA_GSM);
          this.setPreferredNetWordView($r('app.string.emptyStr'));
        }
      })
      currentRadioId += 1;
    } else {
      if (isSupportNR) {
        radioContent.push({
          title: $r('app.string.emptyStr'),
          action: async () => {
            this.radioId = currentRadioId;
            await setPreferredNetwork(this.slotId, radio.PreferredNetworkMode.PREFERRED_NETWORK_MODE_LTE_WCDMA_GSM);
            this.setPreferredNetWordView($r('app.string.emptyStr'));
          }
        })
        currentRadioId += 1;
      }
    }
    this.addMobileData3And2G(radioContent, currentRadioId);
    return radioContent;
  }

  private addMobileData3And2G(radioContent: SheetInfo[], currentRadioId: number) {
    radioContent.push({
      title: $r('app.string.emptyStr'),
      action: async () => {
        this.radioId = currentRadioId;
        await setPreferredNetwork(this.slotId, radio.PreferredNetworkMode.PREFERRED_NETWORK_MODE_WCDMA_GSM);
        this.setPreferredNetWordView($r('app.string.emptyStr'));
      }
    });
    currentRadioId += 1;
    radioContent.push({
      title: $r('app.string.emptyStr'),
      action: async () => {
        this.radioId = currentRadioId;
        await setPreferredNetwork(this.slotId, radio.PreferredNetworkMode.PREFERRED_NETWORK_MODE_GSM);
        this.setPreferredNetWordView($r('app.string.emptyStr'));
      }
    });
  }

  selectRadioId(valueWlms: Resource, isOpen: boolean, isSupportNR: boolean) {
    switch (JSON.stringify(valueWlms)) {
      case JSON.stringify($r('app.string.emptyStr')):
        this.radioId = 0;
        break;
      case JSON.stringify($r('app.string.emptyStr')):
        this.radioId = (isOpen && isSupportNR) ? 1 : 0;
        break
      case JSON.stringify($r('app.string.emptyStr')):
        if (isOpen) {
          this.radioId = isSupportNR ? 2 : 1;
        } else {
          this.radioId = isSupportNR ? 1 : 0;
        }
        break;
      case JSON.stringify($r('app.string.emptyStr')):
        if (isOpen) {
          this.radioId = isSupportNR ? 3 : 2;
        } else {
          this.radioId = isSupportNR ? 2 : 1;
        }
        break;
      default:
        break;
    }
  }

  async determineDialogContent(slotId: number) {
    let result = await radio.isNRSupported(slotId);
    if (slotId === 0) {
      this.modeList = this.getRadioContent(this.lteOrNrSwitchCardOne, result);
      this.selectRadioId(this.byValueWlms, this.lteOrNrSwitchCardOne, result);
    } else {
      this.modeList = this.getRadioContent(this.lteOrNrSwitchCardTwo, result);
      this.selectRadioId(this.byValueWlmsTwo, this.lteOrNrSwitchCardTwo, result);
    }
  }

  @Builder
  networkProviderBuilder($$: NetworkComponentParam) {
    Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Center }) {
      Text($r('app.string.mobile_data_networkProvider'))
        .fontSize($r('sys.float.Body_L'))
        .fontWeight(FontWeight.Medium)
        .fontFamily('HarmonyHeiTi')
        .constraintSize({ minHeight: 22 })
        .fontColor($r('sys.color.font_primary'))
        .margin({ top: this.topMarginOnScal, bottom: $r('sys.float.padding_level1') })
      Text($r('app.string.mobile_data_chooseNetworkProvider'))
        .fontSize($r('sys.float.Body_M'))
        .fontWeight(FontWeight.Regular)
        .fontFamily('HarmonyHeiTi')
        .fontColor($r('sys.color.font_secondary'))
        .constraintSize({ minHeight: 19 })
        .margin({ bottom: this.bottomMarginOnScal })
        .maxLines(2)
    }
    .width(300)
    .opacity(($$.enabled && !this.isDistributeSink) ? 1 : $r('sys.float.alpha_disable'))
  }

  @Builder
  flexNetworkComponentParam($$: NetworkComponentParam) {
    if (!needFilterEflInfo()) {
      Column() {
        this.dividerBuilder($$)
        this.flexNetworkComponentParamSubBiilder($$)
      }
      .stateStyles({
        pressed: this.pressedStyles,
        normal: this.normalStyles
      })
    }
  }

  /**
   * Get network mode
   *
   * @param {Object} slotId - call slotId
   */
  async getPreferredNetwork(slotId: number) {
    const res = await getPreferredNetwork(slotId);
    if (this.byValueWlmsList[res]) {
      if (slotId === 0) {
        this.storageOne = res;
        this.byValueWlms = this.byValueWlmsList[res];
      } else if (slotId === 1) {
        this.storageTwo = res;
        this.byValueWlmsTwo = this.byValueWlmsList[res];
      }
    }
  }

  updateCardOneSwitch() {
    if (this.mCustNetworkCardOne.isShowNr) {
      this.lteOrNrSwitchCardOne = JSON.stringify(this.byValueWlms) === JSON.stringify($r('app.string.emptyStr'));
    } else {
      this.lteOrNrSwitchCardOne = JSON.stringify(this.byValueWlms) === JSON.stringify($r('app.string.emptyStr'));
    }
  }

  updateCardTwoSwitch() {
    if (this.mCustNetworkCardTwo.isShowNr) {
      this.lteOrNrSwitchCardTwo =
        JSON.stringify(this.byValueWlmsTwo) === JSON.stringify($r('app.string.emptyStr'));
    } else {
      this.lteOrNrSwitchCardTwo =
        JSON.stringify(this.byValueWlmsTwo) === JSON.stringify($r('app.string.emptyStr'));
    }
  }

  changeNetModeValueTextCardOne() {
    if (!this.mCustNetworkCardOne.isHideNetworkMode && (this.mCustNetworkCardOne.isShowNr ||
    this.mCustNetworkCardOne.isShowLte)) {
      if (this.lteOrNrSwitchCardOne) {
        this.updateByValueWlms();
      } else {
        this.newUpdateByValueWlms();
      }
    }
  }

  private newUpdateByValueWlms() {
    if (this.mCustNetworkCardOne.isShowNr) {
      if (JSON.stringify(this.byValueWlms) === JSON.stringify($r('app.string.emptyStr'))) {
        this.byValueWlms = $r('app.string.emptyStr');
      }
    } else {
      if (JSON.stringify(this.byValueWlms) === JSON.stringify($r('app.string.emptyStr'))) {
        this.byValueWlms = $r('app.string.emptyStr');
      }
    }
  }

  private updateByValueWlms() {
    if (this.mCustNetworkCardOne.isShowNr) {
      if (this.byValueWlms !== $r('app.string.emptyStr')) {
        this.byValueWlms = $r('app.string.emptyStr');
      }
    } else {
      if (this.byValueWlms !== $r('app.string.emptyStr')) {
        this.byValueWlms = $r('app.string.emptyStr');
      }
    }
  }

  changeNetModeValueTextCardTwo() {
    if (!this.mCustNetworkCardTwo.isHideNetworkMode && (this.mCustNetworkCardTwo.isShowNr ||
    this.mCustNetworkCardTwo.isShowLte)) {
      if (this.lteOrNrSwitchCardTwo) {
        this.updateByValueWlmsTwo();
      } else {
        this.newUpdateByValueWlmsTwo();
      }
    }
  }

  private newUpdateByValueWlmsTwo() {
    if (this.mCustNetworkCardTwo.isShowNr) {
      if (JSON.stringify(this.byValueWlmsTwo) === JSON.stringify($r('app.string.emptyStr'))) {
        this.byValueWlmsTwo = $r('app.string.emptyStr');
      }
    } else {
      if (JSON.stringify(this.byValueWlmsTwo) === JSON.stringify($r('app.string.emptyStr'))) {
        this.byValueWlmsTwo = $r('app.string.emptyStr');
      }
    }
  }

  private updateByValueWlmsTwo() {
    if (this.mCustNetworkCardTwo.isShowNr) {
      if (this.byValueWlmsTwo !== $r('app.string.emptyStr')) {
        this.byValueWlmsTwo = $r('app.string.emptyStr');
      }
    } else {
      if (this.byValueWlmsTwo !== $r('app.string.emptyStr')) {
        this.byValueWlmsTwo = $r('app.string.emptyStr');
      }
    }
  }

  async subscribeConfigChange() {
    this.subscriber = await createSubscriber();
    subscribeConfigChange(() => {
      OperatorConfigUtils.getInstance().initOperatorConfig();
    }, this.subscriber);
  }

  addRegisterSimStateChange(slotId: number) {
    registerSimStateChangeForSlotId(slotId, async () => {
      this.getSettingSim();
      this.getSettingMobileData(slotId);
    })
  }

  addRegisterAccountInfoChange() {
    registerAccountInfoChange(async () => {
      this.getSettingSim();
      if (getMaxSimCount() === MAX_SIM_COUNTS) {
        this.getSettingMobileData(1);
      }
      this.getSettingMobileData(0);
    })
  }

  addRegisterCellularDataSettingChange() {
    registerCellularDataSettingChange(async () => {
      if (getMaxSimCount() === MAX_SIM_COUNTS) {
        this.getSettingMobileData(1);
      }
      this.getSettingMobileData(0);
    })
  }

  addRegisterCellularDataRoamingSettingChange() {
    registerCellularDataRoamingSettingChange(0, async () => {
      this.getIsCellularDataRoamingEnabled(0);
    })
    if (getMaxSimCount() === MAX_SIM_COUNTS) {
      registerCellularDataRoamingSettingChange(1, async () => {
        this.getIsCellularDataRoamingEnabled(1);
      })
    }
  }

  getSettingSim() {
    this.mSimCardOneViewData.getSimStateDataCardOne();
    this.mSimCardTwoViewData.getSimStateDataCardTwo();
    this.mSimCardOneViewData.getSimCardOnePhoneNumber();
    this.mSimCardTwoViewData.getSimCardTwoPhoneNumber();
    this.updateCustParamCardOne();
    this.updateCustParamCardTwo();
    this.getSimNameWithSlotId(0);
    this.getSimNameWithSlotId(1);
  }

  getSettingMobileData(slotId: number) {
    this.getCellularDataRoamingEnabled();
    this.getPreferredNetwork(slotId);
    this.mMobileViewData.getCellularDataState();
    this.isImsSwitchEnabled(0);
    if (getMaxSimCount() === MAX_SIM_COUNTS) {
      this.isImsSwitchEnabled(1);
    }
    this.mMobileViewData.getVSimStatus();
  }

  isImsSwitchEnabled(slotId: number) {
    import('@ohos.telephony.call').then((call) => {
      call.default.isImsSwitchEnabled(slotId).then((res: boolean) => {
        if (slotId) {
          this.enableISM2 = res;
          LogUtils.i(TAG, 'isImsSwitchEnable enable 1:' + JSON.stringify(this.enableISM2));
        } else {
          this.enableISM = res;
          LogUtils.i(TAG, 'isImsSwitchEnable enable 0:' + JSON.stringify(this.enableISM));
        }
      }).catch((err: BusinessError) => {
        if (slotId) {
          this.enableISM2 = true;
          LogUtils.i(TAG, 'isImsSwitchEnable err 1:' + JSON.stringify(this.enableISM2));
        } else {
          this.enableISM = true;
          LogUtils.i(TAG, 'isImsSwitchEnable err 0:' + JSON.stringify(this.enableISM));
        }
        LogUtils.i(TAG, 'isImsSwitchEnabled card catch:' + JSON.stringify(err));
      });
    })
  }

  async isImsSwitchEnabledSync(slotId: number) {
    try {
      let call = await import('@ohos.telephony.call');
      if (slotId) {
        this.enableISM2 = call.default.isImsSwitchEnabledSync(slotId);
        LogUtils.i(TAG, 'isImsSwitchEnable enable 1:' + JSON.stringify(this.enableISM2));
      } else {
        this.enableISM = call.default.isImsSwitchEnabledSync(slotId);
        LogUtils.i(TAG, 'isImsSwitchEnable enable 0:' + JSON.stringify(this.enableISM));
      }
    } catch (err) {
      LogUtils.i(TAG, 'isImsSwitchEnabled card catch:' + JSON.stringify(err));
    }
  }

  async result() {
    if (needFilterEflInfo()) {
      return;
    }
    if (this.mSimCardOneViewData.simStateStatusCardOne) {
      this.getPreferredNetwork(0);
    }
    if (this.mSimCardTwoViewData.simStateStatusCardTwo) {
      this.getPreferredNetwork(1);
    }
  }

  getWifiCallingSwitchState(slotId: number) {
    let context = MobileDataGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT);
    const key = `${CallSettingsConstant.WIFI_CALLING_ENABLED}_${slotId}`;
    let result: string = commons.getWifiCallingSwitchState(context, key);
    LogUtils.i(TAG, `getWifiCallingSwitchState ${key}:${result}`);
    if (slotId === 0) {
      this.wifiCallingSwitchStateCard1 = result === CallSettingsConstant.WIFI_CALLING_SWITCH_ON;
    } else {
      this.wifiCallingSwitchStateCard2 = result === CallSettingsConstant.WIFI_CALLING_SWITCH_ON;
    }
  }

  getWifiCallingImsMode(slotId: number) {
    let context = MobileDataGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT);
    const key = `${CallSettingsConstant.WIFI_CALLING_IMS_MODE}_${slotId}`;
    let result: string = commons.getWifiCallingImsMode(context, key);
    LogUtils.i(TAG, `getWifiCallingImsMode ${key}: ${result}`);
    if (slotId === 0) {
      this.wifiCallingImsModeCard1 = result;
    } else {
      this.wifiCallingImsModeCard2 = result;
    }
  }

  getStorage(storageUtil: typeof import('../common/utils/DataStorageUtil'), card: number) {
    let promise = sim.hasSimCard(card);
    promise.then(res => {
      LogUtils.i(TAG, 'hasSimCard success, promise: data ' + JSON.stringify(res))
      if (!res) {
        storageUtil.getStorageData(MobileDataGlobalContextHelper.getContext()
          .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT), (data) => {
          if (card === 0) {
            this.storageOne = data[card];
            if (this.byValueWlmsList[data[card]]) {
              this.byValueWlms = this.byValueWlmsList[data[card]];
            } else {
              this.byValueWlms = $r('app.string.emptyStr');
            }
          } else if (card === 1) {
            this.storageTwo = data[card];
            if (this.byValueWlmsList[data[card]]) {
              this.byValueWlmsTwo = this.byValueWlmsList[data[card]];
            } else {
              this.byValueWlmsTwo = $r('app.string.emptyStr');
            }
          }
        })
      }
    }, (err: BusinessError) => {
      LogUtils.i(TAG, 'hasSimCard failed, promise: data ' + JSON.stringify(err));
    })
  }

  updateStage() {
    if (this.stages == 0) {
      this.myDisplaySync.start();
      this.myDisplaySync.on("frame", (frameInfo: displaySync.IntervalInfo) => {
        LogUtils.i(TAG, 'updateStage ' + JSON.stringify(this.stages));
        this.updateStage();
      });
    }
    this.stages += 1;
    if (this.stages === 4) {
      this.myDisplaySync.stop();
    }
  }

  onVsyncChange() {
    LogUtils.i(TAG, `onVsyncChange current stage: ${this.stages}`);
    if (this.stages === 1) {
      //移动数据开关
      this.mMobileViewData.getCellularDataStateSync();
      this.mMobileViewData.getVSimStatus();
    } else if (this.stages === 2) {
      this.mSimCardOneViewData.getSimCardOnePhoneNumber();
      this.getCellularDataRoamingEnabled();
      OperatorConfigUtils.getInstance().setCustParam(this.mCustNetworkCardOne, Constants.SLOT_ID_ONE);
      OperatorConfigUtils.getInstance().initOperatorConfig();
      this.mSimCardOneViewData.getSimStateDataCardOne();
      setTimeout(() => {
        this.mMobileViewData.initAirPlaneMode();
      }, 0);
    } else if (this.stages === 3) {
      if (getMaxSimCount() === MAX_SIM_COUNTS) {
        this.mSimCardTwoViewData.getSimStateDataCardTwo();
        this.mSimCardTwoViewData.getSimCardTwoPhoneNumber();
        OperatorConfigUtils.getInstance().setCustParam(this.mCustNetworkCardTwo, Constants.SLOT_ID_TWO);
        OperatorConfigUtils.getInstance().initOperatorConfig();
        this.addRegisterSimStateChange(1);
      }
    }
  }

  aboutToAppear() {
    hiTraceMeter.startTrace('aboutToAppear', MOBILE_INDEX_APPEAR_TASK_ID);
    LogUtils.i(TAG, 'aboutToAppear')
    addRegisterDistributedStateListener(MobileDataGlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(Constants.SETTINGS_ABILITY_CONTEXT),
      (data: string) => {
        LogUtils.i(TAG, 'addRegisterDistributedStateListener:' + JSON.stringify(data));
        this.isDistributeSink = data === Constants.DISTRIBUTE_SINK_CALL;
      });
    queryDistributedState(MobileDataGlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(Constants.SETTINGS_ABILITY_CONTEXT),
      (data: string) => {
        LogUtils.i(TAG, 'querySatellite:' + JSON.stringify(data));
        this.isDistributeSink = data === Constants.DISTRIBUTE_SINK_CALL;
      })
    this.getSimNameWithSlotId(0);
    this.getSimNameWithSlotId(1);
    this.updateStage();
    this.checkIsShowBack();
    this.addRegisterSimStateChange(0);
    this.subscribeConfigChange();
    this.addRegisterAccountInfoChange();
    //Get HD call status
    setTimeout(() => {
      this.addRegisterCellularDataSettingChange();
    }, 0);
    this.addRegisterCellularDataRoamingSettingChange();
    DynamicLoader.getInstance().register(async (str: string): Promise<void> => {
      this.loadPage(str);
    });
    hiTraceMeter.finishTrace('aboutToAppear', MOBILE_INDEX_APPEAR_TASK_ID);
  }

  onPageShow(): void {
    LogUtils.i(TAG, 'onPageShow');
    this.mMobileViewData.updateSatelliteMode();
    if (this.isShowWifiCallingSwitchCard1) {
      this.getWifiCallingSwitchState(0);
      this.getWifiCallingImsMode(0);
    }
    if (getMaxSimCount() === MAX_SIM_COUNTS) {
      if (this.isShowWifiCallingSwitchCard2) {
        this.getWifiCallingSwitchState(1);
        this.getWifiCallingImsMode(1);
      }
    }
    this.updateEdmParameter();
    this.backToMobileDataWhenApnDisabledByEdm();
  }

  private backToMobileDataWhenApnDisabledByEdm(): void {
    if (!this.isDisableApnByEdm) {
      return;
    }
    // 当前页面为APN或APN详情页面时，退出到根页面
    let latestIndex = this.pathInfos.size() - 1;
    if (this.pathInfos.getIndexByName('apnIndex')[0] === latestIndex ||
      this.pathInfos.getIndexByName('apnDetails')[0] === latestIndex) {
      this.pathInfos.clear();
    }
  }

  private updateEdmParameter(): void {
    this.isDisableApnByEdm = getSystemParam(EdmConstants.EDM_DISALLOW_MODIFY_APN, 'false') === 'true';
    let edmMobileDataPolicy: string = getSystemParam(EdmConstants.EDM_MOBILE_DATA_POLICY, '');
    this.isDisableMobileDataByEdm = edmMobileDataPolicy === EdmConstants.EDM_MOBILE_DATA_POLICY_DISALLOW ||
      edmMobileDataPolicy === EdmConstants.EDM_MOBILE_DATA_POLICY_FORCE_OPEN;
  }

  onPageHide(): void {
    LogUtils.i(TAG, 'onPageHide');
  }

  aboutToDisappear(): void {
    removeAirPlaneModeListener();
    unRegisterSimStateChange();
    unRegisterAccountInfoChange();
    unSubscribeConfigChange(this.subscriber);
    removeRegisterDistributedStateListener();
    removeCellularDataRoamingSettingListener(0);
    if (getMaxSimCount() === MAX_SIM_COUNTS) {
      removeCellularDataRoamingSettingListener(1);
    }
    this.myDisplaySync.off('frame');
    LogUtils.i(TAG, 'aboutToDisappear');
  }

  private refreshFlodStatus() {
    // if (this.foldStatus == display.FoldStatus.FOLD_STATUS_EXPANDED ||
    //   this.foldStatus == display.FoldStatus.FOLD_STATUS_FOLDED) {
    //   this.checkIsShowBack();
    // }
  }

  private checkIsShowBack() {
    LogUtils.i(TAG, 'startReason: ' + this.startReason);
    let isisSplit: boolean = isSplit(getContext());
    this.isHideBackButton = (this.startReason === 'from_search') && isisSplit;
  }

  /**
   * Set network mode
   */
  radioChange(slotId: number, v: radio.PreferredNetworkMode) {
    const res = setPreferredNetwork(slotId, v);
    LogUtils.i(TAG, 'radioChange res:' + JSON.stringify(res));
  }

  getNetworkCapability(slotId: number) {
    let type: radio.NetworkCapabilityType;
    if (slotId === 0) {
      type = this.mCustNetworkCardOne.isShowNr ? radio.NetworkCapabilityType.SERVICE_TYPE_NR :
      radio.NetworkCapabilityType.SERVICE_TYPE_LTE;
    } else {
      type = this.mCustNetworkCardTwo.isShowNr ? radio.NetworkCapabilityType.SERVICE_TYPE_NR :
      radio.NetworkCapabilityType.SERVICE_TYPE_LTE;
    }
    radio.getNetworkCapability(slotId, type).then((data: radio.NetworkCapabilityState) => {
      LogUtils.i(TAG, 'getNetworkCapability success, promise: data card' + slotId + JSON.stringify(data));
      if (slotId === 0) {
        this.lteOrNrSwitchCardOne = data === 1;
      } else {
        this.lteOrNrSwitchCardTwo = data === 1;
      }
    }).catch((err: BusinessError) => {
      LogUtils.i(TAG, 'getNetworkCapability failed, promise: err' + slotId + JSON.stringify(err.code));
    });
  }

  getCellularDataRoamingEnabled() {
    this.getIsCellularDataRoamingEnabled(0);
    this.getIsCellularDataRoamingEnabled(1);
  }

  private getIsCellularDataRoamingEnabled(slotId: number) {
    if (slotId === 0) {
      telephonyData.isCellularDataRoamingEnabled(0).then((res) => {
        LogUtils.i(TAG, 'getCellularDataRoamingEnabled card one success then:' + JSON.stringify(res));
        this.dataRoamSwitchCardOne = res;
      }).catch((err: BusinessError) => {
        this.dataRoamSwitchCardOne = false;
        LogUtils.i(TAG, 'enableCellularDataRoaming card one catch:' + JSON.stringify(err));
      });
    }
    if (slotId === 1 && getMaxSimCount() === MAX_SIM_COUNTS) {
      telephonyData.isCellularDataRoamingEnabled(1).then((res) => {
        LogUtils.i(TAG, 'getCellularDataRoamingEnabled card two success then:' + JSON.stringify(res));
        this.dataRoamSwitchCardTwo = res;
      }).catch((err: BusinessError) => {
        this.dataRoamSwitchCardTwo = false;
        LogUtils.e(TAG, 'enableCellularDataRoaming card two catch:' + JSON.stringify(err));
      });
    }
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.interactive_click'))
    .padding({
      left: $r('sys.float.padding_level0'),
      right: $r('sys.float.padding_level0')
    })
    .borderRadius($r('sys.float.corner_radius_level9'))
  }

  @Styles
  pressedApnStyles() {
    .backgroundColor(this.isDisableApnByEdm ? Color.Transparent : $r('sys.color.interactive_click'))
    .borderRadius($r('sys.float.corner_radius_level9'))
  }

  @Styles
  normalStyles() {
    .backgroundColor($r('sys.color.ohos_id_color_background_transparent'))
  }

  @Styles
  titleStyle() {
    .size({ height: '100%', width: '100%' })
    .padding({
      start: isTablet() ? LengthMetrics.vp(24) : LengthMetrics.vp(16),
    })
  }

  @Builder
  CustomSettingsNavBar() {
    Row() {
      Text($r('app.string.mobile_data'))
        .fontWeight(FontWeight.Bold)
        .fontFamily('HarmonyHeiTi')
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .margin({ start: LengthMetrics.vp(8) })
        .maxLines(2)
        .maxFontSize($r('sys.float.ohos_id_text_size_headline8'))
        .minFontSize($r('app.float.font_14'))
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .opacity(this.opacityVal)
        .constraintSize({
          maxWidth: 'calc(100% - 48vp - 48vp)',
          maxHeight: `100%`
        })
    }
    .titleStyle()
    .alignItems(VerticalAlign.Center)
    .translate({ x: this.titleX })
  }

  onBackPress(): boolean | void {
    this.backAnimate();
    if (this.pathInfos.size() === 0) {
      this.session.sendData({ 'action': 'pop' });
    } else {
      this.pathInfos.pop()
    }
    return true;
  }

  private backAnimate(): void {
    // title退场动画
    animateTo({ duration: 150, curve: Curve.Sharp }, () => {
      this.titleX = '40%';
      this.opacityVal = 0;
    });
    animateTo({ duration: CIRCLE_ANIM_DURATION, delay: 30, curve: Curve.Sharp }, () => {
      this.circleOpacityVal = 0;
    });
  }

  async getSimNameWithSlotId(slotId: number) {
    let simLabel = await getSimLabelSync(slotId);
    if (simLabel) {
      let simType: sim.SimType = simLabel.simType;
      let index: number = simLabel.index;
      if (simType === sim.SimType.ESIM) {
        this.simCardInfo[slotId] = [false, `${index}`];
      } else {
        this.simCardInfo[slotId][1] = `${index}`;
      }
      LogUtils.i(TAG, `getSimNameWithSlotId slotId: ${slotId} isPsimCard: ${this.simCardInfo[slotId][0]};
      simCardName: ${this.simCardInfo[slotId][1]}`);
    }
  }

  build() {
    Navigation(this.pathInfos) {
      EditableTitleBar({
        title:$r('app.string.mobile_able'),
        contentMargin:{top:LengthMetrics.px(100)},
        isSaveIconRequired: false,
        onCancel:()=>{
          this.onBackPress()
        }
      })
        .margin({start:LengthMetrics.vp(24)})
      Column(){
          GridRow({
            columns: {
              xs: 2,
              sm: 4,
              md: 8,
              lg: 12
            },
            gutter: { x: 24 }
          }) {
            GridCol({
              span: {
                xs: 2,
                sm: 4,
                md: 8,
                lg: 12
              },
              offset: { sm: 0, md: 1, lg: 2 }
            }) {
              List() {
                if (this.stages > 1) {
                  SubHeader({ secondaryTitle: $r('app.string.mobile_data_general') })
                    .margin({ start: LengthMetrics.vp(-16) })
                  this.dataGeneralBuilder()
                }
                this.mobileDataCardBuilder()
              }
              .height('100%')
              .padding({
                left: getPaddingByDevice(),
                right: getPaddingByDevice(),
                bottom: $r('sys.float.padding_level8')
              })
              .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
              .scrollBar(BarState.Off)
              .clip(false)
            }
        }
      }.layoutWeight(1)
      .onVisibleAreaChange([0, 1], (isVisible: boolean) => {
        if (!needFilterEflInfo()) {
          import('../common/utils/DataStorageUtil').then((storageUtil) => {
            if (isVisible) {
              this.getStorage(storageUtil, 0)
              this.getStorage(storageUtil, 1)
            } else {
              storageUtil.updateStorage(MobileDataGlobalContextHelper.getContext()
                .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT),
                [this.storageOne, this.storageTwo])
            }
          })
        }
      })
    }
    .hideTitleBar(true)
    //.title(this.myTitleBar)
    // .titleBar(TitleParams.MiniTitleParams($r('app.string.mobile_data'),
    //   $r('sys.color.background_secondary'), false, true))
    .hideBackButton(this.isHideBackButton)
    // .titleMode(HdsHdsNavigationTitleMode.MINI)
    .navDestination(this.myRouter)
    .expandSafeArea([SafeAreaType.SYSTEM])
    .mode(NavigationMode.Stack)
    .onAppear(() => {
      // title入场动画
      animateTo({ duration: ANIM_DURATION, curve: curves.interpolatingSpring(0.0, 1.0, 342.0, 37.0) }, () => {
        this.opacityVal = 1;
        this.titleX = 0;
      });
      animateTo({ duration: CIRCLE_ANIM_DURATION, delay: 120, curve: Curve.Sharp }, () => {
        this.circleOpacityVal = 1;
      });
    })
    .backgroundColor($r('sys.color.background_secondary'))
  }
  @Builder
  myTitleBar(){
    TitleBarLayout($r('app.string.mobile_data'),
      $r('sys.color.background_secondary'), false)
  }

  @Builder
  mobileDataCardBuilder() {
    if (this.stages > 3) {
      if (getMaxSimCount() === MAX_SIM_COUNTS) {
        SubHeader({
          secondaryTitle: this.simCardInfo[0][0] ?
            `${this.simCardInfo[0][1] === '1' ? formatResourceToString($r('app.string.mobile_data_card1')) :
              formatResourceToString($r('app.string.mobile_data_card2'))}${this.mSimCardOneViewData.telephoneNumberOne}` :
            `${formatResourceToStringWithArgs($r('app.string.mobile_data_esim_card'),
              this.simCardInfo[0][1])}${this.mSimCardOneViewData.telephoneNumberOne}`,
          secondaryTitleModifier: this.secondaryModifier,
        }).margin({ start: LengthMetrics.vp(-16) })
      }
      this.cardOneBuilder()
    }

    if (getMaxSimCount() === MAX_SIM_COUNTS && this.stages > 3) {
      SubHeader({
        secondaryTitle: this.simCardInfo[1][0] ?
          `${this.simCardInfo[1][1] === '1' ? formatResourceToString($r('app.string.mobile_data_card1')) :
            formatResourceToString($r('app.string.mobile_data_card2'))}${this.mSimCardTwoViewData.telephoneNumberTwo}` :
          `${formatResourceToStringWithArgs($r('app.string.mobile_data_esim_card'),
            this.simCardInfo[1][1])}${this.mSimCardTwoViewData.telephoneNumberTwo}`,
        secondaryTitleModifier: this.secondaryModifier,
      })
        .margin({ start: LengthMetrics.vp(-16) })

      ListItemGroup() {
        this.cardTwoBuilder();
      }
      .padding({
        left: $r('sys.float.padding_level2'),
        right: $r('sys.float.padding_level2'),
        top: $r('sys.float.padding_level2'),
        bottom: $r('sys.float.padding_level2')
      })
      .width('100%')
      .borderRadius($r('sys.float.corner_radius_level10'))
      .backgroundColor($r('sys.color.comp_background_primary'))
    }
  }

  @Builder
  cardTwoBuilder() {
    this.cardTwoDataRoamingBuilder()

    if (this.mCustNetworkCardTwo.isShowNr || this.mCustNetworkCardTwo.isShowLte) {
      this.cardTwoLteOrNrBuilder()
    }

    if (!this.cardTwoVolteIsHide) {
      this.cardTwoVolteBuilder()
    }

    if (this.isShowWifiCallingSwitchCard2) {
      this.cardTwoWifiCallingBuilder();
    }

    ListItem() {
      item({
        isBtn: this.apnBtn,
        cardType: this.cardTwo,
        controlSwitch: $apnControlSwitch,
        title: $r('app.string.APN_NAME'),
        describeDisabled: true,
        iconBtn: true,
        isEnabled: this.mSimCardTwoViewData.simStateStatusCardTwo && !this.mMobileViewData.isAirPlaneMode &&
          !this.mMobileViewData.isSatelliteMode && !this.isDistributeSink,
        isCard: true,
        isCon: 33,
        isDisableByEdm: this.isDisableApnByEdm
      })
    }
    .enabled(this.mSimCardTwoViewData.simStateStatusCardTwo && !this.mMobileViewData.isAirPlaneMode &&
      !this.mMobileViewData.isSatelliteMode && !this.isDistributeSink )
    .padding({
      left: $r('sys.float.padding_level4'),
      right: $r('sys.float.padding_level4')
    })
    .stateStyles({
      pressed: this.pressedApnStyles,
      normal: this.normalStyles
    })

    ListItem() {
      this.NetworkComponent({
        card: 1,
        enabled: this.mSimCardTwoViewData.simStateStatusCardTwo && !this.mMobileViewData.isAirPlaneMode &&
          !this.mMobileViewData.isSatelliteMode
      });
    }
  }

  @Builder
  cardTwoVolteBuilder() {
    ListItem() {
      Column() {
        item({
          isBtn: this.gqBtn,
          cardType: this.cardTwo,
          controlSwitch: $enableISM2,
          title: $r('app.string.mobile_data_volte'),
          describe: $r('app.string.mobile_data_confirmation_function'),
          isEnabled: this.mSimCardTwoViewData.simStateStatusCardTwo && !this.mMobileViewData.isAirPlaneMode &&
            !this.mMobileViewData.isSatelliteMode,
          isCard: true,
          isCon: 22,
        })
          .constraintSize({ minHeight: '64vp' })
          .padding({
            left: $r('sys.float.padding_level4'),
            right: $r('sys.float.padding_level4')
          })
          .visibility(this.cardTwoVolteIsHide ? Visibility.None : Visibility.Visible)

        Divider()
          .color($r('sys.color.comp_divider'))
          .lineCap(LineCapStyle.Round)
          .visibility(this.cardTwoVolteIsHide ? Visibility.None : Visibility.Visible)
          .padding({
            left: $r('sys.float.padding_level4'),
            right: $r('sys.float.padding_level4')
          })
      }
    }
  }

  @Builder
  cardTwoLteOrNrBuilder() {
    ListItem() {
      Column() {
        item({
          isBtn: true,
          cardType: this.cardTwo,
          controlSwitch: $lteOrNrSwitchCardTwo,
          title: this.lteOrNrTitleCardTwo,
          describeDisabled: true,
          isEnabled: this.mSimCardTwoViewData.simStateStatusCardTwo && !this.mMobileViewData.isAirPlaneMode &&
            !this.mMobileViewData.isSatelliteMode,
          isCard: true,
          isCon: 44,
          isEFL: this.mCustNetworkCardTwo.isShowNr,
        })
          .padding({
            left: $r('sys.float.padding_level4'),
            right: $r('sys.float.padding_level4')
          })
          .visibility(this.mCustNetworkCardTwo.isShowNr ? Visibility.Visible : this.mCustNetworkCardTwo.isShowLte ?
          Visibility.Visible : Visibility.None);

        Divider()
          .color($r('sys.color.comp_divider'))
          .visibility(this.mCustNetworkCardTwo.isShowNr ? Visibility.Visible : this.mCustNetworkCardTwo.isShowLte ?
          Visibility.Visible : Visibility.None)
          .lineCap(LineCapStyle.Round)
          .padding({
            left: $r('sys.float.padding_level4'),
            right: $r('sys.float.padding_level4')
          })
      }
    }
  }

  @Builder
  cardTwoDataRoamingBuilder() {
    ListItem() {
      Column() {
        item({
          isBtn: this.moisBtn,
          cardType: this.cardTwo,
          controlSwitch: $dataRoamSwitchCardTwo,
          title: $r('app.string.mobile_data_dataRoaming'),
          describe: $r('app.string.mobile_data_enableDataWhileRoaming'),
          isEnabled: this.mSimCardTwoViewData.simStateStatusCardTwo && !this.mMobileViewData.isAirPlaneMode &&
            !this.mMobileViewData.isSatelliteMode && !this.isDistributeSink,
          isCard: true,
          isCon: 0,
        })
          .padding({
            left: $r('sys.float.padding_level4'),
            right: $r('sys.float.padding_level4')
          })

        Divider()
          .color($r('sys.color.comp_divider'))
          .padding({
            left: $r('sys.float.padding_level4'),
            right: $r('sys.float.padding_level4')
          });
      }
    }
  }

  @Builder
  cardOneBuilder() {
    ListItemGroup() {
      if (getMaxSimCount() === MAX_SIM_COUNTS) {
        this.cardOneDataRoamingBuilder()
      }
      ListItem() {
        Column() {
          item({
            isBtn: true,
            cardType: this.cardOne,
            controlSwitch: $lteOrNrSwitchCardOne,
            title: this.lteOrNrTitleCardOne,
            describeDisabled: true,
            isEnabled: this.mSimCardOneViewData.simStateStatusCardOne && !this.mMobileViewData.isAirPlaneMode &&
              !this.mMobileViewData.isSatelliteMode,
            isCard: true,
            isCon: 44,
            isEFL: this.mCustNetworkCardOne.isShowNr,
          })
            .padding({
              left: $r('sys.float.padding_level4'),
              right: $r('sys.float.padding_level4')
            })
            .visibility(this.mCustNetworkCardOne.isShowNr ? Visibility.Visible : this.mCustNetworkCardOne.isShowLte ?
            Visibility.Visible : Visibility.None)
          Divider()
            .color($r('sys.color.comp_divider'))
            .visibility(this.mCustNetworkCardOne.isShowNr ? Visibility.Visible : this.mCustNetworkCardOne.isShowLte ?
            Visibility.Visible : Visibility.None)
            .lineCap(LineCapStyle.Round)
            .padding({
              left: $r('sys.float.padding_level4'),
              right: $r('sys.float.padding_level4')
            })
        }
      }

      if (!this.cardOneVolteIsHide) {
        this.cardOneVolteBuilder()
      }
      if (this.isShowWifiCallingSwitchCard1) {
        this.cardOneWifiCallingBuilder();
      }
      this.cardOneAPNBuilder()
      ListItem() {
        this.NetworkComponent({
          card: 0,
          enabled: this.mSimCardOneViewData.simStateStatusCardOne && !this.mMobileViewData.isAirPlaneMode &&
            !this.mMobileViewData.isSatelliteMode
        });
      }
    }
    .padding({
      left: $r('sys.float.padding_level2'),
      right: $r('sys.float.padding_level2'),
      top: $r('sys.float.padding_level2'),
      bottom: $r('sys.float.padding_level2')
    })
    .margin({
      top: getMaxSimCount() === MAX_SIM_COUNTS ?
      $r('sys.float.padding_level0') : $r('sys.float.padding_level6')
    })
    .width('100%')
    .borderRadius($r('sys.float.corner_radius_level10'))
    .backgroundColor($r('sys.color.comp_background_primary'))
  }

  @Builder
  cardOneAPNBuilder() {
    ListItem() {
      item({
        cardType: this.cardOne,
        controlSwitch: $apnControlSwitch,
        title: $r('app.string.APN_NAME'),
        describeDisabled: true,
        describe: $r('app.string.mobile_empty_string'),
        iconBtn: true,
        isEnabled: this.mSimCardOneViewData.simStateStatusCardOne && !this.mMobileViewData.isAirPlaneMode &&
          !this.mMobileViewData.isSatelliteMode && !this.isDistributeSink,
        isCard: true,
        isCon: 33,
        isDisableByEdm: this.isDisableApnByEdm
      })
        .padding({
          left: $r('sys.float.padding_level4'),
          right: $r('sys.float.padding_level4')
        })
    }
    .enabled(this.mSimCardOneViewData.simStateStatusCardOne && !this.mMobileViewData.isAirPlaneMode &&
      !this.mMobileViewData.isSatelliteMode && !this.isDistributeSink)
    .stateStyles({
      pressed: this.pressedApnStyles,
      normal: this.normalStyles
    })
  }

  @Builder
  cardOneVolteBuilder() {
    ListItem() {
      Column() {
        item({
          isBtn: this.gqBtn,
          cardType: this.cardOne,
          controlSwitch: $enableISM,
          title: $r('app.string.mobile_data_volte'),
          describe: $r('app.string.mobile_data_confirmation_function'),
          isEnabled: this.mSimCardOneViewData.simStateStatusCardOne && !this.mMobileViewData.isAirPlaneMode &&
            !this.mMobileViewData.isSatelliteMode,
          isCard: true,
          isCon: 22,
        })
          .constraintSize({ minHeight: '80vp' })
          .padding({
            left: $r('sys.float.padding_level4'),
            right: $r('sys.float.padding_level4')
          })
          .visibility(this.cardOneVolteIsHide ? Visibility.None : Visibility.Visible)

        Divider()
          .color($r('sys.color.comp_divider'))
          .visibility(this.cardOneVolteIsHide ? Visibility.None : Visibility.Visible)
          .lineCap(LineCapStyle.Round)
          .padding({
            left: $r('sys.float.padding_level4'),
            right: $r('sys.float.padding_level4')
          })
      }
    }
    .stateStyles({
      normal: this.normalStyles
    })
  }

  @Builder
  cardOneDataRoamingBuilder() {
    ListItem() {
      Column() {
        Divider()
          .color($r('sys.color.comp_divider'))
          .padding({
            left: $r('sys.float.padding_level4'),
            right: $r('sys.float.padding_level4')
          })
          .visibility(getMaxSimCount() === MAX_SIM_COUNTS ? Visibility.None : Visibility.Visible)

        item({
          isBtn: this.moisBtn,
          cardType: this.cardOne,
          controlSwitch: $dataRoamSwitchCardOne,
          title: $r('app.string.mobile_data_dataRoaming'),
          describe: $r('app.string.mobile_data_enableDataWhileRoaming'),
          isEnabled: this.mSimCardOneViewData.simStateStatusCardOne && !this.mMobileViewData.isAirPlaneMode &&
            !this.mMobileViewData.isSatelliteMode && !this.isDistributeSink,
          isCard: true,
          isCon: 0,
        })
          .borderRadius($r('sys.float.corner_radius_level10'))
          .backgroundColor($r('sys.color.comp_background_primary'))
          .padding({
            left: $r('sys.float.padding_level4'),
            right: $r('sys.float.padding_level4'),
            bottom: getMaxSimCount() === MAX_SIM_COUNTS ?
            $r('sys.float.padding_level0') : $r('sys.float.padding_level2')
          })
        Divider()
          .color($r('sys.color.comp_divider'))
          .padding({
            left: $r('sys.float.padding_level4'),
            right: $r('sys.float.padding_level4')
          })
          .visibility(getMaxSimCount() === MAX_SIM_COUNTS ? Visibility.Visible : Visibility.None)
      }
    }
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius($r('sys.float.corner_radius_level10'))
    .padding({
      left: getMaxSimCount() === MAX_SIM_COUNTS ? $r('sys.float.padding_level0') : $r('sys.float.padding_level2'),
      right: getMaxSimCount() === MAX_SIM_COUNTS ? $r('sys.float.padding_level0') : $r('sys.float.padding_level2')
    })

  }

  @Builder
  dataGeneralBuilder() {
    ListItem() {
      this.dataGeneralListItemBuilder()
    }
    .padding({
      left: $r('sys.float.padding_level2'),
      right: $r('sys.float.padding_level2'),
      top: $r('sys.float.padding_level2'),
      bottom: getMaxSimCount() === MAX_SIM_COUNTS ?
      $r('sys.float.padding_level2') : $r('sys.float.padding_level0')
    })
    .enabled(((this.mSimCardOneViewData.simStateStatusCardOne || this.mSimCardTwoViewData.simStateStatusCardTwo) &&
      !this.mMobileViewData.isAirPlaneMode && !this.mMobileViewData.isSatelliteMode &&
      !this.mMobileViewData.isVSimMode))
    .accessibilityGroup(true)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius($r('sys.float.corner_radius_level10'))
  }

  @Builder
  dataGeneralListItemBuilder() {
    Column() {
      Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        this.dataGeneralTextBuilder()
        this.dataGeneralToggleBuilder()
      }
      .stateStyles({
        pressed: this.pressedStyles, normal: this.normalStyles
      })
      .borderRadius($r('sys.float.corner_radius_level10'))
      .width('100%')
      .backgroundColor($r('sys.color.comp_background_primary'))
      .onClick(() => {
        if (this.isDisableMobileDataByEdm) {
          ToastUtil.handleMultiToast($r('app.string.edm_operate_prohibit_tip'));
        }
      })

      if (getMaxSimCount() !== MAX_SIM_COUNTS) {
        this.dataGeneralContentBuilder()
      }
    }
  }

  @Builder
  dataGeneralContentBuilder() {
    Column() {
      Divider()
        .color($r('sys.color.comp_divider'))
        .padding({
          left: $r('sys.float.padding_level4'),
          right: $r('sys.float.padding_level4')
        })
        .visibility(getMaxSimCount() === MAX_SIM_COUNTS ? Visibility.None : Visibility.Visible);
      item({
        isBtn: this.moisBtn,
        cardType: this.cardOne,
        controlSwitch: $dataRoamSwitchCardOne,
        title: $r('app.string.mobile_data_dataRoaming'),
        describe: $r('app.string.mobile_data_enableDataWhileRoaming'),
        isEnabled: this.mSimCardOneViewData.simStateStatusCardOne && !this.mMobileViewData.isAirPlaneMode &&
          !this.mMobileViewData.isSatelliteMode && !this.isDistributeSink,
        isCard: true,
        isCon: 0,
      })
        .borderRadius($r('sys.float.corner_radius_level10'))
        .backgroundColor($r('sys.color.comp_background_primary'))
        .padding({
          left: $r('sys.float.padding_level4'),
          right: $r('sys.float.padding_level4'),
          bottom: getMaxSimCount() === MAX_SIM_COUNTS ?
          $r('sys.float.padding_level0') : $r('sys.float.padding_level2')
        });
      Divider()
        .color($r('sys.color.comp_divider'))
        .padding({
          left: $r('sys.float.padding_level4'),
          right: $r('sys.float.padding_level4')
        })
        .visibility(getMaxSimCount() === MAX_SIM_COUNTS ? Visibility.Visible : Visibility.None);
    }.backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius($r('sys.float.corner_radius_level10'))
    .padding({
      left: getMaxSimCount() === MAX_SIM_COUNTS ? $r('sys.float.padding_level0') : $r('sys.float.padding_level2'),
      right: getMaxSimCount() === MAX_SIM_COUNTS ? $r('sys.float.padding_level0') : $r('sys.float.padding_level2')
    })
  }

  @Builder
  dataGeneralToggleBuilder() {
    Column() {
      Toggle({ type: ToggleType.Switch, isOn: this.mMobileViewData.isDataEnable ? true : false })
        .width('36vp')
        .height('20vp')
        .enabled(this.isMobileDataToggleEnable())
        .selectedColor($r('sys.color.comp_background_emphasize'))
        .switchPointColor($r('sys.color.comp_background_primary_contrary'))
        .onChange((isOn) => {
          this.mGeneralViewEvent.onToggleClickEvent(isOn, this.mMobileViewData);
        })
        .hoverEffect(HoverEffect.None)
        .accessibilityLevel('yes')
    }
    .padding({
      right: $r('sys.float.padding_level2'),
      left: $r('sys.float.padding_level2')
    })
  }

  @Builder
  dataGeneralTextBuilder() {
    Column() {
      Text($r('app.string.mobile_data'))
        .fontSize($r('sys.float.Body_L'))
        .fontWeight(FontWeight.Medium)
        .fontFamily('HarmonyHeiTi')
        .constraintSize({ minHeight: 22 })
        .fontColor($r('sys.color.font_primary'))
        .margin({ top: this.topMarginOnScal });

      Text($r('app.string.mobile_data_charges'))
        .fontWeight(FontWeight.Regular)
        .fontFamily('HarmonyHeiTi')
        .fontSize($r('sys.float.Body_M'))
        .fontColor($r('sys.color.font_secondary'))
        .constraintSize({ minHeight: 19 })
        .margin({ top: $r('sys.float.padding_level1'), bottom: this.bottomMarginOnScal });
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .padding({ left: $r('sys.float.padding_level4'), right: $r('sys.float.padding_level4') })
    .opacity(this.isMobileDataToggleEnable() ? 1 : $r('sys.float.alpha_tertiary'))
  }

  @Builder
  NetworkComponent($$: NetworkComponentParam) {
    if (!needFilterEflInfo()) {
      this.networkComponentBuilder($$)
    }

    if ($$.card === 0) {
      this.cardOneNetworkNameBuilder($$)
    } else {
      this.cardTwoNetworkNameBuilder($$)
    }
  }

  @Builder
  cardTwoNetworkNameBuilder($$: NetworkComponentParam) {
    Column() {
      this.dividerBuilder($$)
      this.networkProviderSubBuilder($$)
    }
    .enabled(this.mSimCardTwoViewData.simStateStatusCardTwo && !this.mMobileViewData.isAirPlaneMode &&
      !this.mMobileViewData.isSatelliteMode && !this.isDistributeSink)
    .stateStyles({
      pressed: this.pressedStyles,
      normal: this.normalStyles
    });
  }

  @Builder
  cardOneNetworkNameBuilder($$: NetworkComponentParam) {
    Column() {
      this.dividerBuilder($$)
      this.networkProviderSubBuilder($$)
    }
    .enabled(this.mSimCardOneViewData.simStateStatusCardOne && !this.mMobileViewData.isAirPlaneMode &&
      !this.mMobileViewData.isSatelliteMode && !this.isDistributeSink)
    .stateStyles({
      pressed: this.pressedStyles,
      normal: this.normalStyles
    });
  }

  @Builder
  dividerBuilder($$: NetworkComponentParam) {
    Divider()
      .color($r('sys.color.comp_divider'))
      .lineCap(LineCapStyle.Round)
      .padding({
        left: $r('sys.float.padding_level4'),
        right: $r('sys.float.padding_level4')
      });
  }

  @Builder
  networkComponentBuilder($$: NetworkComponentParam) {
    if ($$.card === 0) {
      if (!this.mCustNetworkCardOne.isHideNetworkMode) {
        this.flexNetworkComponentParam($$);
      }
    } else {
      if (!this.mCustNetworkCardTwo.isHideNetworkMode) {
        this.flexNetworkComponentParam($$);
      }
    }
  }

  @Builder
  networkProviderSubBuilder($$: NetworkComponentParam) {
    Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
      this.networkProviderBuilder($$);

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize('24vp')
        .fontColor([$r('sys.color.icon_fourth')])
        .draggable(false)
        .opacity(($$.enabled && !this.isDistributeSink) ? 1 : $r('sys.float.alpha_disable'))
    }
    .width('100%')
    .padding({
      left: $r('sys.float.padding_level4'),
      right: $r('sys.float.padding_level4')
    })
    .constraintSize({ minHeight: 64 })
    .enabled($$.enabled)
    .onClick(() => {
      if (this.networkModeStatus && !this.mMobileViewData.isAirPlaneMode && !this.mMobileViewData.isSatelliteMode) {
        DynamicLoader.getInstance().callFunction('NetworkOperators').then(() => {
          let param: ObjInterface = { sonSlotId: $$.card };
          this.pathInfos.pushPathByName('NetworkOperators', param);
        });
      }
    })
  }

  @Builder
  flexNetworkComponentParamSubBiilder($$: NetworkComponentParam) {
    Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
      this.networkModeBuilder($$);

      Image($r('app.media.ic_public_arrow_right'))
        .fillColor($r('sys.color.icon_fourth'))
        .width(12)
        .height(24)
        .matchTextDirection(true)
        .draggable(false)
        .opacity($$.enabled ? 1 : $r('sys.float.alpha_disable'))
    }
    .constraintSize({ minHeight: 64 })
    .width('100%')
    .enabled($$.enabled)
    .onClick(() => {
      this.slotId = $$.card;
      if ($$.card === 0) {
        this.networkModeStatus = this.mSimCardOneViewData.simStateStatusCardOne;
      } else if ($$.card === 1) {
        this.networkModeStatus = this.mSimCardTwoViewData.simStateStatusCardTwo;
      }
      if (this.networkModeStatus && !this.mMobileViewData.isAirPlaneMode) {
        this.getPreferredNetwork($$.card);
        this.determineDialogContent($$.card);
        this.modeDialogController.open();
      }
    })
    .padding({
      left: $r('sys.float.padding_level4'),
      right: $r('sys.float.padding_level4')
    })
  }

  @Builder
  networkModeBuilder($$: NetworkComponentParam) {
    Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Center }) {
      Text($r('app.string.emptyStr'))
        .fontSize($r('sys.float.Body_L'))
        .fontWeight(FontWeight.Medium)
        .fontFamily('HarmonyHeiTi')
        .constraintSize({
          minHeight: 22
        })
        .fontColor($r('sys.color.font_primary'))
        .margin({ top: this.topMarginOnScal, bottom: $r('sys.float.padding_level1') })

      Text($$.card === 0 ? this.byValueWlms : this.byValueWlmsTwo)
        .fontSize($r('sys.float.Body_M'))
        .fontWeight(FontWeight.Regular)
        .fontFamily('HarmonyHeiTi')
        .fontColor($r('sys.color.font_secondary'))
        .constraintSize({
          minHeight: 19
        })
        .margin({ top: $r('sys.float.padding_level1'), bottom: this.bottomMarginOnScal })
        .maxLines(2)
    }
    .width(300)
    .opacity($$.enabled ? 1 : $r('sys.float.alpha_disable'))
  }

  @Builder
  cardOneWifiCallingBuilder() {
    ListItem() {
      Column() {
        item({
          isBtn: false,
          cardType: this.cardOne,
          controlSwitch: $wifiCallingSwitchStateCard1,
          title: $r('app.string.wifi_calling'),
          describeDisabled: true,
          iconBtn: true,
          isEnabled: this.mSimCardOneViewData.simStateStatusCardOne && !this.mMobileViewData.isSatelliteMode &&
            !this.isDistributeSink,
          isCard: true,
          isCon: 55,
          isShowSwitchStateText: true
        })
          .padding({
            left: $r('sys.float.padding_level4'),
            right: $r('sys.float.padding_level4')
          })
          .id('callSetting_pages_mobileDataIndex_item_cardOne_wifi_Calling');
        Divider()
          .color($r('sys.color.comp_divider'))
          .padding({
            left: $r('sys.float.padding_level4'),
            right: $r('sys.float.padding_level4')
          })
      }
      .enabled(this.mSimCardOneViewData.simStateStatusCardOne && !this.mMobileViewData.isSatelliteMode &&
        !this.isDistributeSink)
      .stateStyles({
        pressed: this.pressedStyles,
        normal: this.normalStyles
      })
    }
  }

  @Builder
  cardTwoWifiCallingBuilder() {
    ListItem() {
      Column() {
        item({
          isBtn: false,
          cardType: this.cardTwo,
          controlSwitch: $wifiCallingSwitchStateCard2,
          title: $r('app.string.wifi_calling'),
          describeDisabled: true,
          iconBtn: true,
          isEnabled: this.mSimCardTwoViewData.simStateStatusCardTwo && !this.mMobileViewData.isSatelliteMode &&
            !this.isDistributeSink,
          isCard: true,
          isCon: 55,
          isShowSwitchStateText: true,
        })
          .padding({
            left: $r('sys.float.padding_level4'),
            right: $r('sys.float.padding_level4')
          })
          .id('callSetting_pages_mobileDataIndex_item_cardTwo_wifi_Calling');
        Divider()
          .color($r('sys.color.comp_divider'))
          .padding({
            left: $r('sys.float.padding_level4'),
            right: $r('sys.float.padding_level4')
          })
      }
      .enabled(this.mSimCardTwoViewData.simStateStatusCardTwo && !this.mMobileViewData.isSatelliteMode &&
        !this.isDistributeSink)
      .stateStyles({
        pressed: this.pressedStyles,
        normal: this.normalStyles
      })
    }
  }

  private isMobileDataToggleEnable(): boolean {
    return (this.mSimCardOneViewData.simStateStatusCardOne || this.mSimCardTwoViewData.simStateStatusCardTwo) &&
      !this.mMobileViewData.isAirPlaneMode && !this.mMobileViewData.isSatelliteMode &&
      !this.mMobileViewData.isVSimMode && !this.isDisableMobileDataByEdm;
  }
}
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

import radio from '@ohos.telephony.radio';
import { LoadingDialog } from '@ohos.arkui.advanced.Dialog';
import promptAction from '@ohos.promptAction';
import { BusinessError } from '@ohos.base';
import {
  LogUtils,
  disableCellularData,
  enableCellularData,
  addAirPlaneModeListener,
  removeAirPlaneModeListener,
  ReportUtil,
  TitleParams,
  TitleBarLayout
} from '@ohos/common/CommonIndex';
import { getPaddingByDevice, needFilterEflInfo } from '../common/utils/MobileDataUtils';
import { registerNetworkStateChange, unRegisterNetworkStateChange } from '../model/RegisterSimStateApi';
import { getRadioTechnologyFromStr } from '../common/utils/NetworkModeUtils';
import sim from '@ohos.telephony.sim';
import { AlertDialog } from '@ohos.arkui.advanced.Dialog';
import { formatResourceToString } from '../common/utils/formatResourceToString';
import { NetworkOperatorsParams } from '../model/MobileLoaderParams';
import { MobileViewData } from '../viewModel/MobileDataViewModel/MobileViewData';
import { EditableTitleBar, LengthMetrics } from '@kit.ArkUI';

// import { NavDestination,  HdsNavDestinationAttribute } from '@hms.hds.hdsBaseComponent';

class NetworkInformation {
  public operatorName: string = '';
  public operatorNumeric: string = '';
  public state: radio.NetworkInformationState = radio.NetworkInformationState.NETWORK_AVAILABLE;
  public radioTech: string = '';
}

class NetworkSelectionModeOptions {
  public slotId: number = 0;
  public selectMode: radio.NetworkSelectionMode = radio.NetworkSelectionMode.NETWORK_SELECTION_MANUAL;
  public networkInformation: NetworkInformation = new NetworkInformation();
  public resumeSelection: boolean = true;
}

class ObjInterface {
  public sonSlotId: number = 0;
}

const TAG = 'NetworkOperators';

@Builder
export function NetworkOperatorsLoader($$: NetworkOperatorsParams): void {
  NetworkOperators({isCellularDataEnable: $$.isCellularDataEnable});
}

@Component
export default struct NetworkOperators {
  public storage = LocalStorage.getShared();
  @Link @Watch('watchCellularData') isCellularDataEnable: MobileViewData; // Cellular Data on or off.
  @State needCellularDataOn: boolean = false; // Whether need to turn on Cellular Data.
  @Consume('pathInfos') pathInfos: NavPathStack;
  @State needCellularDataOff: boolean = false; // Whether need to turn off Cellular Data.
  @State sysOpFlagBool: boolean = false; // Indicate Cellular Data is operated by system.
  @State isDataEnable: boolean = true; // Toggle's status.
  @State display: boolean = false;
  @State isShow: boolean = true;
  @State isAppear: boolean = true;
  @State operateShowContent: string = '';
  @State operators: string = '';
  @State listOperators: Object[] = [];
  @State listOperatorsCache: Object[] = []; // Local search cache.
  @State isable: boolean = true; // Whether can click.
  @State isTogEnabel: boolean = true;
  @State isTogClose: boolean = false;
  @State isNoSimToggleOn: boolean = true; // Toggle status when no sim.
  @State setModeFlagBool: boolean = false; // Indicate setNetworkSelectionMode is going on.
  @State searchFlagBool: boolean = false; // Indicate getNetworkSearchInformation is going on.
  @State showColor: boolean = true;
  @State blackColor: boolean = true;
  @State itemOperatorName: string = '';
  @State disOperatorName: boolean = true;
  @State slotId: number = 0;
  @State isTouch: boolean = false;
  @StorageProp('foldStatus') foldStatus: number = -1;
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('fontSizeScaleMargin') fontSizeScaleMargin: string = '';
  @State isListHidden: boolean = true;
  private isInitDataEnableChange: boolean = false;

  private watchCellularData() {
    LogUtils.i(TAG, 'Current Cellular Data status:' + this.isCellularDataEnable.isDataEnable +
      '; this.searchFlagBool:' + this.searchFlagBool);
    // searchFlagBool indicates network search is going on(true).
    // When searchFlagBool is true, we should ignore any users OP.
    // Besides, we need to consider between users click and system set.
    if (this.searchFlagBool && !this.sysOpFlagBool) {
      LogUtils.i(TAG, 'Users OP during search...');
      this.needCellularDataOn = false;
      this.needCellularDataOff = false;
      return;
    }
    if (this.isCellularDataEnable.isDataEnable && !this.searchFlagBool) {
      // Disable Cellular Data before manual NW search and enable it again after the NW search.
      LogUtils.i(TAG, 'CellularData is on before search, need off.');
      this.needCellularDataOff = true;
      this.needCellularDataOn = false;
    } else if (!this.isCellularDataEnable.isDataEnable && this.sysOpFlagBool) {
      // Current Cellular Data is off, no OP when users select to manual NW search.
      LogUtils.i(TAG, 'CellularData is off by sys before search, need on.');
      this.needCellularDataOn = true;
      this.needCellularDataOff = false;
      this.sysOpFlagBool = false;
    }
  }

  async reQuery(slotId: number) {
    let data = await radio.getOperatorName(slotId);
    if (data) {
      this.operateShowContent = data;
      promptAction.showToast({
        message: $r('app.string.mobile_register'),
        duration: 2000
      })
    } else {
      this.operateShowContent = formatResourceToString($r('app.string.mobile_not_serve'));
      promptAction.showToast({
        message: $r('app.string.mobile_Search'),
        duration: 2000
      })
      this.isGetOperatorName(slotId);
    }
  }

  async isGetOperatorName(slotId: number) {
    let data = await radio.getOperatorName(slotId);
    if (data) {
      this.operateShowContent = formatResourceToString($r('app.string.mobile_empty_string'));
    } else {
      this.operateShowContent = formatResourceToString($r('app.string.mobile_not_serve'));
      this.isGetOperatorName(slotId);
    }
  }

  dialogControllerTow: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: $r('app.string.automatic_enrollment')
    }),
    autoCancel: false,
    // showInSubWindow: true
  })
  dialogController: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: this.disOperatorName ? $r('app.string.mobile_Registering', this.itemOperatorName) :
      $r('app.string.mobile_Registering_disable', this.itemOperatorName)
    }),
    autoCancel: false,
    // showInSubWindow: true
  })

  aboutToAppear() {
    let obj: ObjInterface | undefined = this.pathInfos.getParamByName(
      'NetworkOperators')[this.pathInfos.getParamByName('NetworkOperators').length - 1] as (ObjInterface | undefined);
    if (obj) {
      this.slotId = obj.sonSlotId;
    } else {
      LogUtils.e(TAG, 'aboutToAppear slotId is null');
    }
    this.isable = true;
    this.listOperators = [];
    this.listOperatorsCache = this.listOperators;
    let promise = radio.getNetworkSelectionMode(this.slotId);
    promise.then(data => {
      LogUtils.i(TAG, 'getNetworkSelectionMode success, promise: data' + JSON.stringify(data));
      if (data === 1) {
        this.isDataEnable = true;
        let promise = radio.getOperatorName(this.slotId);
        promise.then(data => {
          LogUtils.i(TAG, 'getOperatorName success, promise: data' + JSON.stringify(data));
          if (data) {
            this.operateShowContent = data;
          } else {
            this.operateShowContent = formatResourceToString($r('app.string.mobile_not_serve'));
          }
        }, (err: BusinessError) => {
          LogUtils.i(TAG, 'getOperatorName failed, promise: err' + JSON.stringify(err));
        })
      } else {
        this.operateShowContent = formatResourceToString($r('app.string.shut_down'));
        this.isDataEnable = false;
        this.isInitDataEnableChange = true;
      }
    }, (err: BusinessError) => {
      LogUtils.i(TAG, 'getNetworkSelectionMode failed, promise: err' + JSON.stringify(err));
    })

    registerNetworkStateChange(this.slotId,
      async (data: radio.NetworkState): Promise<void> => this.onNetworkStateChange(data));
    addAirPlaneModeListener((data: number): void => this.onAirplaneModeChanged(data == 1));

    // Call function to update variables.
    this.watchCellularData();
  }

  aboutToDisappear() {
    this.restoreCellularData();
    unRegisterNetworkStateChange();
    removeAirPlaneModeListener();
  }

  private async onNetworkStateChange(newState: radio.NetworkState) {
    LogUtils.i(TAG, 'on NW state change, regState: ' + newState?.regState);

    if (newState.regState == radio.RegState.REG_STATE_IN_SERVICE) {
      this.operateShowContent =
        !this.isDataEnable ? formatResourceToString($r('app.string.shut_down')) : newState.longOperatorName;
    } else {
      if (sim.hasSimCardSync(this.slotId)) {
        if (newState.regState == radio.RegState.REG_STATE_POWER_OFF) {
          this.pathInfos.pop(); // We should back to previous page if airplane mode is on
        }
        this.operateShowContent = formatResourceToString($r('app.string.shut_down'));
      } else {
        // Preferred Network need to display 'No Service' with no SIM.
        this.operateShowContent = formatResourceToString($r('app.string.mobile_not_serve'));
      }
    }

    this.listOperators.forEach(i => {
      let item = i as NetworkInformation;
      if (item.state != radio.NetworkInformationState.NETWORK_FORBIDDEN &&
        item.state != radio.NetworkInformationState.NETWORK_UNKNOWN) {
        // We should only update the valid networks

        if (item.operatorNumeric == newState.plmnNumeric &&
          getRadioTechnologyFromStr(item.radioTech) == newState.cfgTech) {
          // Match!
          item.state = newState.regState == radio.RegState.REG_STATE_IN_SERVICE ?
          radio.NetworkInformationState.NETWORK_CURRENT :
          radio.NetworkInformationState.NETWORK_AVAILABLE;
        } else {
          item.state = radio.NetworkInformationState.NETWORK_AVAILABLE;
        }
      }
    })

    // Force update the list
    this.listOperators = JSON.parse(JSON.stringify(this.listOperators));
    this.listOperatorsCache = this.listOperators;
  }

  private onAirplaneModeChanged(isOn: boolean) {
    LogUtils.i(TAG, 'on airplane mode state change: isOn = ' + isOn);
    this.sysOpFlagBool = true;
    this.restoreCellularData();
    if (isOn) {
      this.pathInfos.pop(); // We should back to previous page if airplane mode is on
    }
  }

  private whenSimCardAbsent(scene?: number): boolean {
    // For sim card exist, no action.
    if (sim.hasSimCardSync(this.slotId)) {
      return false;
    }
    // 1. For no sim card, toggle from off to on.
    if (!this.isDataEnable && !this.isNoSimToggleOn) {
      promptAction.showToast({
        message: $r('app.string.mobile_Search'),
        duration: 2000
      })
      this.isAppear = true; // No Divider.
      this.isDataEnable = true; // Toggle is on
      this.operateShowContent = formatResourceToString($r('app.string.mobile_not_serve'));
      this.listOperators = []; // Clear Operators list.
      this.listOperatorsCache = this.listOperators;
      return true;
    } else {
      // 2. For no sim card, toggle from on to off.
      if (scene === 2) {
        this.isable = true; // Allow to click
        this.isNoSimToggleOn = false;
        this.isDataEnable = false;
        this.operateShowContent = formatResourceToString($r('app.string.shut_down'));
        promptAction.showToast({
          message: $r('app.string.mobile_Search'),
          duration: 2000
        })
        return true;
      }
      // For no sim card and toggle is on, we don't need to deal in onClick method, so return false.
      return false;
    }
  }

  closeAutoSelectDialog: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      primaryTitle: $r('app.string.mobile_data_closeAutoSelect'),
      content: this.isCellularDataEnable.isDataEnable || !sim.hasSimCardSync(this.slotId) ? $r('app.string.text_paragraphs') :
      $r('app.string.text_paragraphs_no_data'),
      primaryButton: {
        value: $r('app.string.mobile_data_cancel'),
        action: () => {
          LogUtils.i(TAG, 'Callback when the first button(cancel) is clicked.');
          this.isable = true;
          this.isDataEnable = false;
          this.isDataEnable = true;
          this.isTogEnabel = true;
        }
      },
      secondaryButton: {
        value: $r('app.string.confim_space'),
        action: () => {
          this.isTogEnabel = true;
          this.isNoSimToggleOn = false;
          if (this.needCellularDataOff && this.isCellularDataEnable.isDataEnable) {
            // Turn off Cellular Data.
            disableCellularData()?.then(() => {
              LogUtils.i(TAG, 'disableCellularData: success');
              this.sysOpFlagBool = true;
            }).catch((error: BusinessError) => {
              LogUtils.e(TAG, 'disableCellularData: error catch-' + JSON.stringify(error));
            });
          }
          if (this.whenSimCardAbsent(2)) {
            return;
          }
          LogUtils.i(TAG, 'Callback when the second button(confirm) is clicked.');
          this.blackColor = false;
          this.display = true;
          this.isShow = false;
          this.isDataEnable = false;
          this.operateShowContent = formatResourceToString($r('app.string.shut_down'));
          // After the automatic selection is disabled, the network search starts.
          if (!this.searchFlagBool) {
            this.toggleOnToOffExt();
          }
        }
      },
    }),
    autoCancel: false,
    // showInSubWindow: true
  })

  private toggleOnToOff() {
    this.closeAutoSelectDialog.open();
  }

  restoreCellularData() {
    if (this.needCellularDataOn && !this.isCellularDataEnable.isDataEnable) {
      enableCellularData()?.then(() => {
        LogUtils.i(TAG, 'enableCellularData: success');
      }).catch((error: BusinessError) => {
        LogUtils.e(TAG, 'enableCellularData: error catch-' + JSON.stringify(error));
      });
    }
  }

  private toggleOnToOffExt() {
    if (this.listOperators.length > 0) {
      this.isListHidden = false;
      this.isAppear = false;
      this.isable = true;
      this.searchFlagBool = false;
      this.blackColor = false;
      this.display = false;
      this.isShow = true;
      this.isDataEnable = false;
      this.operateShowContent = formatResourceToString($r('app.string.shut_down'));
    } else {
      this.searchFlagBool = true;
      let promise = radio.getNetworkSearchInformation(this.slotId);
      promise.then(data => {
        LogUtils.i(TAG, 'getNetworkSearchInformation success, searchResult length: ' + data.networkSearchResult.length);
        if (needFilterEflInfo()) {
          data.networkSearchResult = data.networkSearchResult.filter((item) => item.radioTech !== '');
        }
        this.listOperators = this.processOperatorsList(JSON.parse(JSON.stringify(data.networkSearchResult)))
        this.listOperatorsCache = this.listOperators;
        this.blackColor = true;
        this.isAppear = false;
        this.display = false;
        this.isShow = true;
        this.isable = true;
        this.searchFlagBool = false; // Only previous search finish can search next.
        // After the network search completed, need to open the mobile data if necessary.
        LogUtils.i(TAG, 'this.needCellularDataOn:' + this.needCellularDataOn);
        this.restoreCellularData();
        this.isListHidden = false;
      }, (err: BusinessError) => {
        this.searchFlagBool = false;
        LogUtils.e(TAG, 'getNetworkSearchInformation failed, promise: err' + JSON.stringify(err));
        this.restoreCellularData();

        promptAction.showToast({
          message: $r('app.string.mobile_fail'),
          duration: 2000
        })
        this.blackColor = true;
        this.display = false;
        this.isShow = true;
        this.isable = true;
      })
    }
  }

  /**
   * 处理运营商信息，包括名称转换和技术映射
   * @param operatorInfo 原始运营商信息
   * @returns 处理后的运营商信息
   */
  private processOperatorInfo(operatorInfo: NetworkInformation): NetworkInformation {
    // 运营商名称映射表
    const OPERATOR_NAME_MAP: Record<string, string> = {
      'CHN-TELECOM': '中国电信',
      'CHN-UNICOM': '中国联通',
      'CHINA BROADNET': '中国广电',
      'CHA_UNION': '中国联通',
      'CHINA_UNICOM': '中国联通',
      'CHINA_MOBILE': '中国移动',
      'CHINA_TELECOM': '中国电信',
      'CHINA_BROADNET': '中国广电',
    };

    const ACT_TO_NETWORK_GEN_MAP: Record<number, string> = {
      0: '2G', // GSM
      1: '2G', // GSM Compact
      2: '3G', // UTRAN
      3: '2G', // GSM w/EGPRS
      4: '3G', // UTRAN w/HSDPA
      5: '3G', // UTRAN w/HSUPA
      6: '3G', // UTRAN w/HSDPA and HSUPA
      7: '4G', // E-UTRAN
      8: '4G', // EC-GSM-IOT(A/Gb mode)
      9: '4G', // E-UTRAN (NB-S1 mode)
      10: '5G', // E-UTRA connected to a 5GCN
      11: '5G', // NR connected to a 5GCN
      12: '5G', // NG-RAN
      13: '5G'  // E-UTRA-NR dual connectivity
    };


    const processedInfo = JSON.parse(JSON.stringify(operatorInfo)) as radio.NetworkInformation

    let operatorName = processedInfo.operatorName

    //处理运营商名称
    if (OPERATOR_NAME_MAP[operatorName]) {
      processedInfo.operatorName = OPERATOR_NAME_MAP[operatorName];
    }

    const radioTechArcIndex = processedInfo.operatorNumeric.split(" ").length
    // 处理网络技术
    processedInfo.radioTech = ACT_TO_NETWORK_GEN_MAP[processedInfo.operatorNumeric.split(" ")[radioTechArcIndex-1]]

    return processedInfo;
  }

  /**
   * 批量处理运营商信息列表
   * @param operatorsList 原始运营商信息列表
   * @returns 处理后的运营商信息列表
   */
  private processOperatorsList(operatorsList: NetworkInformation[]): NetworkInformation[] {
    return operatorsList.map(item => this.processOperatorInfo(item));
  }

  private toggleOffToOnChange() {
    let promise = radio.getNetworkSelectionMode(this.slotId);
    promise.then(data => {
      LogUtils.i(TAG, 'getNetworkSelectionMode off to on, promise: ' + JSON.stringify(data));
      if (data === 1 && this.listOperators.length > 0) {
        this.toggleOffToOn(false);
      } else {
        this.toggleOffToOn(true);
      }
    }, (err: BusinessError) => {
      LogUtils.e(TAG, 'getNetworkSelectionMode failed, promise: err' + JSON.stringify(err));
      this.toggleOffToOn(true);
    })
  }

  private toggleOffToOn(isSetAuto: boolean) {
    if (!isSetAuto) {
      this.isListHidden = true;
      this.isable = true;
      this.isAppear = true;
      this.isDataEnable = true;
      this.setModeFlagBool = false;
      this.reQuery(this.slotId);
    } else {
      this.isNoSimToggleOn = true;
      let networkInformation: NetworkInformation = {
        operatorName: '',
        operatorNumeric: '',
        state: radio.NetworkInformationState.NETWORK_AVAILABLE,
        radioTech: ''
      }
      let networkSelectionModeOptions: NetworkSelectionModeOptions = {
        slotId: this.slotId,
        selectMode: radio.NetworkSelectionMode.NETWORK_SELECTION_AUTOMATIC,
        networkInformation: networkInformation,
        resumeSelection: true
      }
      // Automatic selection changes from off to on to start automatic network search.
      if (!this.setModeFlagBool) {
        this.setModeFlagBool = true;
        let promise = radio.setNetworkSelectionMode(networkSelectionModeOptions);
        promise.then(() => {
          this.dialogControllerTow.close();
          LogUtils.i(TAG, 'setNetworkSelectionMode success.');
          this.isable = true;
          this.listOperators = [];
          this.listOperatorsCache = this.listOperators;
          this.isAppear = true;
          this.isDataEnable = true;
          this.reQuery(this.slotId);
          this.setModeFlagBool = false;
        }, (err: BusinessError) => {
          this.setModeFlagBool = false;
          LogUtils.e(TAG, 'setNetworkSelectionMode failed, promise: err' + JSON.stringify(err));
        })
      }
    }
  }

  private clickToManualReg(networkSelectionModeOptions: NetworkSelectionModeOptions) {
    // Before network registration, obtain current network search mode.
    let promise = radio.getNetworkSelectionMode(this.slotId);
    promise.then(data => {
      // 1-auto 2-manual
      LogUtils.i(TAG, 'Current network search mode:' + JSON.stringify(data));
    }, (err: BusinessError) => {
      LogUtils.i(TAG, 'getNetworkSelectionMode failed, promise: err' + JSON.stringify(err));
    })

    // List displayed, click to network register.
    if (!this.setModeFlagBool) {
      this.setModeFlagBool = true;
      LogUtils.i(TAG, 'click item to register:set&get.');
      let setModePromise = radio.setNetworkSelectionMode(networkSelectionModeOptions);
      setModePromise.then(() => {
        LogUtils.i(TAG, 'setNetworkSelectionMode success.');
        this.showColor = true;
        this.dialogController.close(); // Close register dialog
        promptAction.showToast({
          message: $r('app.string.mobile_register'),
          duration: 2000
        })
        this.setModeFlagBool = false;
      }, (err: BusinessError) => {
        LogUtils.e(TAG, 'clickToManualReg-setNetworkSelectionMode failed, promise: err' + JSON.stringify(err));
        this.whenManualRegFailed();
      })
    }
  }

  regFailDialog: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      primaryTitle: $r('app.string.registration_failed'),
      content: $r('app.string.automatic_carrier_selection'),
      primaryButton: {
        value: $r('app.string.mobile_data_cancel'),
        action: () => {
          LogUtils.i(TAG, 'Callback when the first button(cancel) is clicked');
        }
      },
      secondaryButton: {
        value: $r('app.string.confim_space'),
        action: () => {
          this.dialogControllerTow.open();
          this.backToAutomaticReg();
        }
      },
    }),
    cancel: () => {
      LogUtils.i(TAG, 'Closed callbacks');
    },
    // showInSubWindow: true
  })

  private whenManualRegFailed() {
    this.dialogController.close();
    // If click fast(No wait for Modem's manual search result, etc) to set auto mode here,
    // previous manual mode's setNetworkSelectionMode promise will not react.
    // But it still return err and block next auto mode.
    this.setModeFlagBool = false; // setNetworkSelectionMode fails, no need to get info again.
    this.searchFlagBool = false;

    // If network register fails, local cache can be used because the interval is short.
    this.listOperators = this.listOperatorsCache;
    this.showColor = true;
    this.regFailDialog.open();
  }

  private async backToAutomaticReg() {
    LogUtils.i(TAG, 'Callback when the second button(ok) is clicked');
    let networkInformation: NetworkInformation = {
      operatorName: '',
      operatorNumeric: '',
      state: radio.NetworkInformationState.NETWORK_AVAILABLE,
      radioTech: ''
    }
    let networkSelectionModeOptions: NetworkSelectionModeOptions = {
      slotId: this.slotId,
      selectMode: radio.NetworkSelectionMode.NETWORK_SELECTION_AUTOMATIC,
      networkInformation: networkInformation,
      resumeSelection: true
    }

    // After network register fails, click OK to select automatic network search.
    if (!this.setModeFlagBool) {
      this.setModeFlagBool = true;
      await radio.setNetworkSelectionMode(networkSelectionModeOptions).then(() => {
        LogUtils.i(TAG, 'setNetworkSelectionMode success');
        this.dialogControllerTow.close();
        this.listOperators = [];
        this.listOperatorsCache = this.listOperators;
        this.isAppear = true;
        this.isDataEnable = true;
        this.reQuery(this.slotId);
        this.setModeFlagBool = false;
      }, (err: BusinessError) => {
        this.setModeFlagBool = false;
        LogUtils.e(TAG, 'setNetworkSelectionMode failed, promise: err' + JSON.stringify(err));
      })
    }
  }

  @Styles
  normalStyles() {
    .backgroundColor(Color.Transparent)
  }

  @Builder statusToggle() {
    Toggle({ type: ToggleType.Switch, isOn: this.isDataEnable })
      .width(36)
      .height(20)
      .margin(0)
      .visibility(this.isShow ? Visibility.Visible : Visibility.None)
      .selectedColor($r('sys.color.comp_background_emphasize'))
      .switchPointColor($r('sys.color.comp_background_primary_contrary'))
      .hoverEffect(HoverEffect.None)
      .id('callSetting_pages_NetWorkOperators_stackToggle_Switch')
      .onChange((isOn: boolean) => {
        this.isTogClose = !isOn;
        if (this.whenSimCardAbsent()) {
          return;
        }
        if (!this.isTogEnabel) {
          return;
        }
        this.isable = false;
        if (this.isDataEnable === true && this.isTogClose) {
          this.toggleOnToOff();
          this.isTogEnabel = false;

          ReportUtil.getInstance().reportClickAvailableNetSwitch(0);
        } else if (this.isDataEnable === false && !this.isInitDataEnableChange) {
          this.toggleOffToOnChange();
          ReportUtil.getInstance().reportClickAvailableNetSwitch(1);
        }
        this.isInitDataEnableChange = false;
      })
      .accessibilityLevel('yes')
  }

  @Builder
  itemHeadToggleContentBuilder() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.display) {
        LoadingProgress()
          .width(32)
          .height(32)
          .enableLoading(this.display)
      } else {
        this.statusToggle();
      }
    }
  }

  @Builder
  itemHead() {
    Column() {
      Column() {
        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
          Column() {
            Text($r('app.string.mobile_Automatic_selection'))
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontFamily('HarmonyHeiTi')
              .constraintSize({ minHeight: 22 })
              .margin({ top: this.fontSizeScale < 1.75 ? $r('sys.float.padding_level5') :
              this.fontSizeScaleMargin, bottom: $r('sys.float.padding_level1') })
              .fontColor(this.blackColor ? $r('sys.color.font_primary') :
              $r('sys.color.font_secondary'))
              .id('callSetting_pages_NetWorkOperators_flexText_selection')

            Text($r('app.string.mobile_data_preferredNetwork', this.operateShowContent))
              .fontSize(14)
              .fontWeight(FontWeight.Regular)
              .fontFamily('HarmonyHeiTi')
              .fontColor($r('sys.color.font_secondary'))
              .constraintSize({ minHeight: 20 })
              .margin({ bottom: this.fontSizeScale < 1.75 ? $r('sys.float.padding_level5') :
              this.fontSizeScaleMargin })
              .id(`callSetting_pages_NetWorkOperators_flexText_${$r('app.string.mobile_data_preferredNetwork')
                .id}`)
          }
          .alignItems(HorizontalAlign.Start)
          this.itemHeadToggleContentBuilder()
        }
      }
      .padding({
        left: $r('sys.float.padding_level6'), right: $r('sys.float.padding_level6'),
        top: $r('sys.float.padding_level2'),
        bottom: this.getListStatus() ? $r('sys.float.padding_level2') : $r('sys.float.padding_level0')
      })
      Divider()
        .color($r('sys.color.comp_divider'))
        .lineCap(LineCapStyle.Round)
        .visibility(this.isAppear ? Visibility.None : Visibility.Visible)
        .padding({ left: $r('sys.float.padding_level6'), right: $r('sys.float.padding_level6') })
    }
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius({
      topLeft: $r('sys.float.corner_radius_level10'), topRight: $r('sys.float.corner_radius_level10'),
      bottomLeft: this.getListStatus() ? $r('sys.float.corner_radius_level10') : 0,
      bottomRight: this.getListStatus() ? $r('sys.float.corner_radius_level10') : 0
    })
    .accessibilityGroup(true)
  }

  @Builder
  itemFooter() {
    Column() {
    }
    .height($r('sys.float.corner_radius_level16'))
    .width('100%')
    .backgroundColor($r('sys.color.background_secondary'))
  }

  build() {
    NavDestination() {
      EditableTitleBar({
        title:$r('app.string.mobile_able'),
        contentMargin:{top:LengthMetrics.px(100)},
        isSaveIconRequired: false,
        onCancel:()=>{
          this.pathInfos.pop()
        }
      })
        .margin({start:LengthMetrics.vp(24)})
      Column(){
        GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: { x: 24 } }) {
          GridCol({ span: { xs: 2, sm: 4, md: 8, lg: 12 } }) {
            List() {
              ListItemGroup({ header: this.itemHead, footer: this.itemFooter }) {
                ForEach(this.listOperators, (item: NetworkInformation, index?: number) => {
                  ListItem() {
                    Column() {
                      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
                        Row() {
                          Text(item.state === 3 ? $r('app.string.mobile_disable', item.operatorName+' '+item.radioTech) :
                            item.operatorName+' '+item.radioTech)
                            .fontSize(16)
                            .fontWeight(FontWeight.Medium)
                            .fontFamily('HarmonyHeiTi')
                            .constraintSize({ minHeight: 22 })
                            .fontColor(item.state === 2 && this.showColor ?
                              $r('sys.color.font_emphasize') :
                              $r('sys.color.font_primary'))
                            .padding({
                              top: this.fontSizeScale < 1.75 ? $r('sys.float.padding_level5') :
                                this.fontSizeScaleMargin,
                              bottom: this.fontSizeScale < 1.75 ? $r('sys.float.padding_level5') :
                                this.fontSizeScaleMargin,
                            })
                            .id(item.state === 3 ? 'callSetting_pages_NetWorkOperators_rowText_disable' :
                              'callSetting_pages_NetWorkOperators_rowText_disableElse')
                        }

                        Image($r('app.media.ic_signal'))
                          .fillColor($r('sys.color.ohos_fa_icon_primary'))
                          .width(24)
                          .height(19)
                          .draggable(false)
                      }
                      .padding({
                        left: $r('sys.float.padding_level4'),
                        right: $r('sys.float.padding_level4')
                      })
                      .stateStyles({
                        pressed: {
                          .backgroundColor($r('sys.color.interactive_click'))
                          .borderRadius($r('sys.float.corner_radius_level9'))
                        },
                        normal: this.normalStyles
                      })

                      Divider()
                        .color($r('sys.color.comp_divider'))
                        .visibility(this.listOperators.length - 1 === index ? Visibility.None : Visibility.Visible)
                        .padding({ left: $r('sys.float.padding_level4'), right: $r('sys.float.padding_level4') })
                    }
                    .margin({
                      left: $r('sys.float.padding_level2'),
                      right: $r('sys.float.padding_level2'),
                    })
                  }
                  .borderRadius({
                    bottomRight: index === this.listOperators.length - 1 ?
                      $r('sys.float.corner_radius_level10') : 0,
                    bottomLeft: index === this.listOperators.length - 1 ?
                      $r('sys.float.corner_radius_level10') : 0
                  })
                  .backgroundColor($r('sys.color.comp_background_primary'))
                  .onClick(() => {
                    this.itemOperatorName = item.operatorName;
                    if (item.state === 3) {
                      this.disOperatorName = false;
                    } else {
                      this.disOperatorName = true;
                    }
                    if (item.state === 2) {
                      promptAction.showToast({
                        message: $r('app.string.mobile_register'),
                        duration: 2000
                      })
                    } else {
                      this.showColor = false;
                      this.dialogController.open();
                      let networkInformation: NetworkInformation = {
                        operatorName: item.operatorName,
                        operatorNumeric: item.operatorNumeric,
                        state: radio.NetworkInformationState.NETWORK_CURRENT,
                        radioTech: item.radioTech
                      }
                      let networkSelectionModeOptions: NetworkSelectionModeOptions = {
                        slotId: this.slotId,
                        selectMode: radio.NetworkSelectionMode.NETWORK_SELECTION_MANUAL,
                        networkInformation: networkInformation,
                        resumeSelection: true
                      }
                      this.clickToManualReg(networkSelectionModeOptions);
                    }
                  })
                  .constraintSize({ minHeight: 48 })
                  .visibility(this.getListStatus() ? Visibility.None : Visibility.Visible)
                })
              }
              .borderRadius({
                bottomRight: $r('sys.float.corner_radius_level10'),
                bottomLeft: $r('sys.float.corner_radius_level10')
              })
              .backgroundColor($r('sys.color.background_secondary'))
            }
            .clip(false)
            .backgroundColor($r('sys.color.background_secondary'))
            .padding({
              left: getPaddingByDevice(),
              right: getPaddingByDevice(),
              top: $r('sys.float.padding_level8')
            })
            .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
            .height('100%')
          }
        }
      }.layoutWeight(1)
    }
    .hideTitleBar(true)
    // .titleBar(TitleParams.MiniTitleParams($r('app.string.mobile_able'), $r('sys.color.background_secondary'), false, true))
    //.title(this.myTitleBar)
    .backgroundColor($r('sys.color.background_secondary'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .onBackPressed(() => {
      this.pathInfos.pop();
      return true;
    })
  }
  @Builder
  myTitleBar(){
    TitleBarLayout($r('app.string.mobile_able'), $r('sys.color.background_secondary'), false)
  }

  getListStatus(): boolean {
    if (this.listOperators.length > 0) {
      return this.isListHidden;
    } else {
      return true;
    }
  }
}

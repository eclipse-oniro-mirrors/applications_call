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

import account_osAccount from '@ohos.account.osAccount';
import {
  getMaxSimCount,
  registerAccountInfoChange,
  registerSimStateChangeForSlotId,
  unRegisterAccountInfoChange,
  unRegisterSimStateChange
} from '../model/RegisterSimStateApi';
import { SubHeader } from '@ohos.arkui.advanced.SubHeader';
import { LogUtils, CallSettingGlobalContextHelper, Constants, ReportUtil, TitleParams,
  ToastUtil,
  TitleBarLayout} from '@ohos/common/CommonIndex';
import { RouterOptions, SubSettings } from '../components/SubSettings';
import SubSettingsData from '../common/struct/SubSettingsData';
import CallForward from './CallForward';
import { StringUtil } from '../common/utils/StringUtil';
import More from './More';
import { SubRecordConfig } from '../components/SubRecordConfig';
import CallAbout from './CallAbout';
import CallNotifies from './CallNotifies';
import { SubSettingRingtone } from '../components/SubSettingRingtone';
import RecorderConfig from './RecorderConfig';
import IncomingCallRejectionSms from './IncomingCallRejectionSms';
import * as CallSettingsConstant from '../common/constant/CallSettingsConstant';
import common from '@ohos.app.ability.common';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';
import SatelliteNetworkExtensionAbility from './SatelliteNetworkExtensionAbility';
import HyacinthExtensionAbility from  './hyacinth/HyacinthExtensionAbility'
import CallColumnUtils from '../common/utils/CallColumnUtils';
import { SubSwitch } from '../components/SubSwitch';
import {
  getExpandAutoAnswer,
  setExpandAutoAnswer,
  isTwoInOne,
} from '../common/utils/Utils';
import {
  getSimCardDefaultPhoneNumber,
  getSimCardOnePhoneNumber,
  getSimCardTwoPhoneNumber,
  getSimStateCardOne
} from '../common/model/getSimInfoApi';
import { BusinessError, commonEventManager, settings } from '@kit.BasicServicesKit';
import { getSimStateCardTwo, isSimActive, getSimLabelSync } from '../common/model/getSimStateApi';
import { call, observer, sim } from '@kit.TelephonyKit';
import { phoneFormat } from '../common/utils/SimIdFormat';
import AdvanceOptions from './AdvanceOptions';
import OnLineFusionCallPrivacy from '../components/FusionCallPrivacy';
import { EditableTitleBar, LengthMetrics, promptAction, TextModifier } from '@kit.ArkUI';
import queryAddData from '../common/utils/queryAddData';
import commonController from '../common/control/CommonCtrol';
import { dataShare, dataSharePredicates } from '@kit.ArkData';
import {
  addRegisterDistributedStateListener,
  queryDistributedState,
  removeRegisterDistributedStateListener
} from '../common/utils/DistributeUtils';
import { MAIN_ACCOUNT_ID } from '../common/constant/SatelliteSearchConst';
import { DisplayUtil } from '../common/utils/DisplayUtil';
import ScreenAdapterUtils from '../common/utils/ScreenAdapterUtils';
import WifiCallingSettings from './WifiCallingSettings';
import { CustPhoneNetworkStruct, OperatorConfigUtils } from '@ohos/cust';
import { createSubscriber, subscribeConfigChange } from '@ohos/common/src/main/ets/utils/CommonUtil';
import { SystemMode } from '../model/SystemMode';
import CallSettingVM from '../viewModel/CallSettingVM';
import { bundleManager } from '@kit.AbilityKit';
// import { Navigation, HdsNavigationAttribute, HdsNavigationTitleMode } from '@kit.UIDesignKit';
import SystemModeUtils from '@ohos/common/src/main/ets/utils/SystemModeUtils';

const TAG = 'CallSettingIndex';
const PAGE_UPDATE_FLAG: string = 'pageUpdateFlag';
const MAX_SIM_COUNTS = 2;
const commons: queryAddData = new queryAddData();

interface RouterParams {
  slotId?: number,
  isPrivacyNote?: boolean;
  fromOtherApp?: boolean;
  phoneNumber?: string;
}

@Entry
@Component
export default struct Index {
  scroller: Scroller = new Scroller();
  @State slotId0: number = 0;
  @State slotId1: number = 1;
  // Card 1 status
  @State simStateStatusCardOne: boolean = false;
  // Card 2 status
  @State simStateStatusCardTwo: boolean = false;
  @State showRejectMessageData: boolean = true;
  @State showCallNotifies: boolean = true;
  // Card 1 number
  @State TelephoneNumber0: string = '';
  // Card 2 number
  @State TelephoneNumber1: string = '';
  @State callForwardSubData0: SubSettingsData =
    new SubSettingsData($r('app.string.Call_forward'), this.simStateStatusCardOne, false);
  @State callForwardSubData1: SubSettingsData =
    new SubSettingsData($r('app.string.Call_forward'), this.simStateStatusCardTwo, false);
  @State callForwardSubData2: SubSettingsData = new SubSettingsData($r('app.string.call_history_merging'), true, false);
  @State callNotifies: SubSettingsData =
    new SubSettingsData($r('app.string.unlock_after_call_notification'), true, false);
  @State voiceControlCallAble : boolean = false;
  @State callRingTone: SubSettingsData = new SubSettingsData($r('app.string.phone_ring_tone'), true, false);
  @State callRejectMessageData: SubSettingsData =
    new SubSettingsData($r('app.string.incoming_call_rejection_sms'), true, false);
  @State speedDialData: SubSettingsData =
    new SubSettingsData($r('app.string.speedDial'), true, false);
  @State advanceOptions: SubSettingsData = new SubSettingsData($r('app.string.advance_options_title'), true, false);
  @State callAbout: SubSettingsData = new SubSettingsData($r('app.string.call_about'), true, false);
  @State moreCard0: SubSettingsData = new SubSettingsData($r('app.string.more'), this.simStateStatusCardOne, false);
  @State moreCard1: SubSettingsData = new SubSettingsData($r('app.string.more'), this.simStateStatusCardTwo, false);
  @State wifiCallingSubData0: SubSettingsData =
    new SubSettingsData($r('app.string.wifi_calling'), this.simStateStatusCardOne, false);
  @State wifiCallingSubData1: SubSettingsData =
    new SubSettingsData($r('app.string.wifi_calling'), this.simStateStatusCardTwo, false);
  @StorageProp('airPlaneOn') airPlaneOn: boolean = false;
  @Provide('pathInfos') pathInfos: NavPathStack = new NavPathStack();
  @StorageLink('isGoHome') @Watch('pagesChanged') isGoHome: boolean = false;
  @StorageProp('curBp') curBp: string = '';
  @State controlSwitch: boolean = getExpandAutoAnswer();
  @State secondaryModifier: TextModifier = new TextModifier().maxLines(3)
  @LocalStorageLink('numberIdentityStatus') numberIdentityStatus: boolean = true;
  @LocalStorageLink('CallNotifiesText') getCallNotifiesText: Resource = $r('app.string.banner');
  @LocalStorageLink('FusionCallSwitchStatus') fusionCallSwitchStatus: boolean = false;
  @LocalStorageLink('VideoRingToneSwitchStatus') videoRingToneSwitchStatus: boolean = true;
  @LocalStorageLink('EndCallSwitchStatus') endCallSwitchStatus: boolean = false;
  @State commonController: commonController = commonController.getInstance();
  @LocalStorageLink('CallRecorderStatusText') getCallRecorderStatusText: Resource = $r('app.string.closed');
  @State callText: ResourceStr = $r('app.string.by_time');
  @State radioId: number = 0;
  // Is Distribute Sink
  @State isDistributeSink: boolean = false;
  // 判断是否使用模态窗口拉起
  @State isFromExternal: boolean = CallSettingVM.getInstance().getIsFromExternal();
  // 判断半模态是否有叉号
  @State isCrossMarkExists: boolean = CallSettingVM.getInstance().getIsFromExternal();
  @StorageLink('isShowBorder') isShowBorder: boolean = false;
  private dataShareHelper: dataShare.DataShareHelper | undefined = undefined;
  @StorageLink('wifiCallingSwitchStateCard1') wifiCallingSwitchStateCard1: boolean = false;
  @StorageLink('wifiCallingSwitchStateCard2') wifiCallingSwitchStateCard2: boolean = false;
  @StorageLink('wifiCallingImsModeCard1') wifiCallingImsModeCard1: string =
    CallSettingsConstant.WIFI_CALLING_IMS_MODE_WIFI;
  @StorageLink('wifiCallingImsModeCard2') wifiCallingImsModeCard2: string =
    CallSettingsConstant.WIFI_CALLING_IMS_MODE_WIFI;
  @State @Watch('updateCustParamCardOne') mCustNetworkCardOne: CustPhoneNetworkStruct = new CustPhoneNetworkStruct();
  @State @Watch('updateCustParamCardTwo') mCustNetworkCardTwo: CustPhoneNetworkStruct = new CustPhoneNetworkStruct();
  @State isShowWifiCallingSwitchCard1: boolean = false;
  @State isShowWifiCallingSwitchCard2: boolean = false;
  @State simCardInfo: [boolean, string][] = [
    [true, '1'],
    [true, '2']
  ];
  @State newCallEnabled: boolean = !SystemMode.getInstance().isModePenglai();
  @State newCallEnabledOne: boolean = false;
  @State newCallEnabledTwo: boolean = false;
  private operatorConfigSubscriber?: commonEventManager.CommonEventSubscriber;
  private powerSaveEvent?: commonEventManager.CommonEventSubscriber;

  @Builder
  myRouter(name: string, params: RouterParams) {
    if (name === 'CallForward') {
      CallForward({ slotId: params.slotId });
    } else if (name === 'More') {
      More({ slotId: params.slotId });
    } else if (name === 'CallAbout') {
      CallAbout();
    } else if (name === 'RecorderConfig') {
      RecorderConfig();
    } else if (name === 'CallNotifies') {
      CallNotifies({ slotId: params.slotId });
    } else if (name === 'IncomingCallRejectionSms') {
      IncomingCallRejectionSms();
    } else if (name == 'SatelliteNetworkExtensionAbility') {
      SatelliteNetworkExtensionAbility();
    } else if (name == 'HyacinthExtensionAbility') {
      HyacinthExtensionAbility();
    } else if (name === 'AdvanceOptions') {
      AdvanceOptions();
    } else if (name === 'FusionCallAgreement') {
      OnLineFusionCallPrivacy();
    } else if (name === 'WifiCallingSettings') {
      WifiCallingSettings({ slotId: params.slotId });
    }
  }

  pagesChanged() {
    if (this.isGoHome) {
      let size = this.pathInfos.size();
      LogUtils.i(TAG, 'pagesChanged size: ' + size);
      if (size !== 0) {
        this.pathInfos.popToIndex(0);
        this.pathInfos.pop();
      }
      AppStorage.setOrCreate('isGoHome', false);
    }
  }

  onBackPress(): boolean | void {
    CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT)
      .terminateSelf();
    return true;
  }

  registerCallLogMergeTypeStatusObserver() {
    try {
      settings.registerKeyObserver(CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT),
        Constants.CALL_LOG_MERGE_TYPE, settings.domainName.DEVICE_SHARED, () => {
          commons.getValue(undefined, (data: string) => {
            data === 'contacts' ? this.radioId = 1 : this.radioId = 0;
            this.callText = data === 'contacts' ? $r('app.string.by_contact') : $r('app.string.by_time');
          })
        });
    } catch (err) {
      LogUtils.e(TAG, 'registerCallLogMergeTypeStatusObserver error: code: ' + err.code + ', message: ' + err.message);
    }

  }

  registerCallNotifyTypeStatusObserver() {
    try {
      settings.registerKeyObserver(CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT),
        Constants.CALL_NOTIFY_TYPE, settings.domainName.DEVICE_SHARED, () => {
          commons.queryCallNotifiesType((data: string) => {
            this.getCallNotifiesText =
              data === CallSettingsConstant.FULL_SCREEN ? $r('app.string.full_screen') : $r('app.string.banner');
          })
        });
    } catch (err) {
      LogUtils.e(TAG, 'registerCallNotifyTypeStatusObserver error: code: ' + err.code + ', message: ' + err.message);
    }
  }

  registerFusionCallSwitchStatusObserver() {
    try {
      settings.registerKeyObserver(CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT),
        Constants.FUSION_CALL_KEY, settings.domainName.USER_PROPERTY, () => {
          let fusionCallSwitch: string = settings.getValueSync(CallSettingGlobalContextHelper.getContext()
            .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT),
            Constants.FUSION_CALL_KEY, '0', settings.domainName.USER_PROPERTY);
          this.fusionCallSwitchStatus = (fusionCallSwitch === '1');
        });
    } catch (err) {
      LogUtils.e(TAG, 'registerFusionCallSwitchStatusObserver error: code: ' + err.code + ', message: ' + err.message);
    }
  }

  registerIncallPowerButtonBehaviorStatusObserver() {
    try {
      settings.registerKeyObserver(CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT),
        Constants.INCALL_POWER_KEY, settings.domainName.USER_PROPERTY, () => {
          let endCallSwitch: string = settings.getValueSync(CallSettingGlobalContextHelper.getContext()
            .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT),
            Constants.INCALL_POWER_KEY, '0', settings.domainName.USER_PROPERTY);
          this.endCallSwitchStatus = (endCallSwitch == '1');
        });
    } catch (err) {
      LogUtils.e(TAG, 'registerIncallPowerButtonBehaviorStatusObserver error: code: ' + err.code + ', message: ' + err.message);
    }
  }

  async queryForConfigAndListenChange(context: common.Context) {
    LogUtils.i(TAG, 'queryForConfig-self');
    let uri: string = `${CallSettingsConstant.DATA_SHARE_ABILITY_NAME}${CallSettingsConstant.RECORDER_CONFIG_TABLE}`;
    let condition = new dataSharePredicates.DataSharePredicates();
    const columns = ['is_open', 'object'];
    try {
      this.dataShareHelper = await dataShare.createDataShareHelper(context, uri);
      this.dataShareHelper.query(uri, condition, columns, (err, resultSet) => {
        if (resultSet?.goToNextRow()) {
          const isOpen = resultSet.getLong(resultSet.getColumnIndex('is_open'));
          LogUtils.i(TAG, `isOpen-self: ${isOpen}`);
          this.getCallRecorderStatusText =
            (isOpen === 1 ? $r('app.string.opened') : $r('app.string.closed'));
        }
        resultSet?.close();
      });
      this.dataShareHelper.on('dataChange', dataShare.SubscriptionType.SUBSCRIPTION_TYPE_EXACT_URI, uri,
        (err, resultSettwo) => {
          if (resultSettwo?.type == dataShare.ChangeType.UPDATE) {
            this.getCallRecorderStatusText =
              (resultSettwo?.values[0]?.is_open === 1 ? $r('app.string.opened') : $r('app.string.closed'));
          }
        })
      LogUtils.i(TAG, 'queryForConfig-dataHelperTwo-datachage-end');
    } catch (err) {
      LogUtils.e(TAG, `queryForConfig query failed, error code: ${err.code}`);
    }
  }

  aboutToAppear() {
    hiTraceMeter.startTrace('aboutToAppear', 1200);
    LogUtils.i(TAG, 'aboutToAppear');
    let context = CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT);
    addRegisterDistributedStateListener(context, (data: string) => {
      LogUtils.i(TAG, `addRegisterDistributedStateListener: ${data}`);
      this.isDistributeSink = data === Constants.DISTRIBUTE_SINK_CALL;
    });
    queryDistributedState(context, (data: string) => {
      LogUtils.i(TAG, `queryDistributedState: ${data}`);
      this.isDistributeSink = data === Constants.DISTRIBUTE_SINK_CALL;
    });
    this.queryForConfigAndListenChange(context);
    this.registerCallLogMergeTypeStatusObserver();
    this.registerCallNotifyTypeStatusObserver();
    this.registerFusionCallSwitchStatusObserver();
    this.registerIncallPowerButtonBehaviorStatusObserver();
    this.getSimStateDataCardOne();
    this.getSimCardOnePhoneNumber();
    this.registerSimStateChangeForCardOne();
    this.addRegisterAccountInfoChange();
    this.registerWifiCallingSwitchStateObserver(0);
    this.registerWifiCallingImsModeObserver(0);
    this.getSimNameWithSlotId(0);
    this.newCallEnabledOne = SystemMode.getInstance().getSimStateDataCard(Constants.SLOT_ID_ONE);
    OperatorConfigUtils.getInstance().setCustParam(this.mCustNetworkCardOne, Constants.SLOT_ID_ONE);
    if (getMaxSimCount() === MAX_SIM_COUNTS) {
      this.getSimStateDataCardTwo();
      this.getSimCardTwoPhoneNumber();
      this.registerSimStateChangeForCardTwo();
      this.registerWifiCallingSwitchStateObserver(1);
      this.registerWifiCallingImsModeObserver(1);
      this.getSimNameWithSlotId(1);
      this.newCallEnabledTwo = SystemMode.getInstance().getSimStateDataCard(Constants.SLOT_ID_TWO);
      OperatorConfigUtils.getInstance().setCustParam(this.mCustNetworkCardTwo, Constants.SLOT_ID_TWO);
    }
    OperatorConfigUtils.getInstance().initOperatorConfig();
    this.subscribeOperatorConfigChange();
    let callSettingsUri = AppStorage.get<string>('callSettingsUri');
    LogUtils.i(TAG, 'aboutToAppear, callSettingsUri = ' + callSettingsUri);
    if (callSettingsUri === 'CallNotifies') {
      let routerOptions: RouterOptions = { url: '', params: {} };
      routerOptions.url = 'CallNotifies';
      routerOptions.params = { 'slotId': this.slotId0 };
      LogUtils.i(TAG, ' onClick pushUrl');
      this.pathInfos.pushPathByName(routerOptions.url, routerOptions.params);
    } else if (callSettingsUri === 'SatelliteNetworkExtensionAbility') {
      this.pathInfos.pushPathByName('SatelliteNetworkExtensionAbility', '');
    } else if (callSettingsUri === 'HyacinthExtensionAbility') {
      this.pathInfos.pushPathByName('HyacinthExtensionAbility', '');
    } else if (callSettingsUri === 'NumberIdentity') {
      let routerOptions: RouterOptions = { url: '', params: {} };
      routerOptions.url = 'NumberIdentity';
      routerOptions.params = { 'fromOtherApp': true };
      this.pathInfos.pushPathByName(routerOptions.url, routerOptions.params, false);
    } else if (callSettingsUri === 'AdvanceOptions') {
      this.pathInfos.pushPathByName('AdvanceOptions', '');
    }
    AppStorage.delete('callSettingsUri');
    LogUtils.i(TAG, 'aboutToAppear end');
    hiTraceMeter.finishTrace('aboutToAppear', 1200);
    this.checkPenglaiMode();
  }

  private checkPenglaiMode() {
    if (SystemModeUtils.getInstance().isEnablePenglai() || SystemModeUtils.getInstance().isOutdoorTravel()) {
      this.voiceControlCallAble = false;
    } else {
      this.voiceControlCallAble = this.showCallNotifies;
    }
  }

  updatePageShow() {
    let pageUpdateFlag: boolean = !AppStorage.get<boolean | undefined>(PAGE_UPDATE_FLAG);
    AppStorage.setOrCreate<boolean>(PAGE_UPDATE_FLAG, pageUpdateFlag);
  }

  async subscribeOperatorConfigChange() {
    this.operatorConfigSubscriber = await createSubscriber();
    subscribeConfigChange(() => {
      OperatorConfigUtils.getInstance().initOperatorConfig();
    }, this.operatorConfigSubscriber);
  }

  @Builder
  ExpandAutoAnswerSwitch() {
    SubSwitch({
      controlSwitch: this.controlSwitch,
      airPlaneOn: this.airPlaneOn,
      onChange: (isOn: boolean) => {
        if (isOn === this.controlSwitch) {
          return;
        }
        this.controlSwitch = !this.controlSwitch;
        LogUtils.i(TAG, 'Switch status:' + this.controlSwitch);
        setExpandAutoAnswer(this.controlSwitch);
      }
    })
  }

  onPageShow() {
    LogUtils.i(TAG, 'onPageShow');
    hiTraceMeter.startTrace('onPageShow', 1201);
    this.getSimCardOnePhoneNumber();
    this.getSimCardTwoPhoneNumber();
    this.updatePageShow();
    AppStorage.setOrCreate('currentColorMode', CallSettingGlobalContextHelper?.getContext()
    ?.getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT)?.config?.colorMode);
    AppStorage.setOrCreate('currentLanguage', getContext()?.resourceManager?.getConfigurationSync()?.locale);
    // onNewWant
    let callSettingsUri = AppStorage.get<string>('callSettingsUri');
    LogUtils.i(TAG, 'onPageShow, callSettingsUri = ' + callSettingsUri);
    if (callSettingsUri === 'NumberIdentity') {
      let routerOptions: RouterOptions = { url: '', params: {} };
      routerOptions.url = 'NumberIdentity';
      routerOptions.params = { 'fromOtherApp': true };
      this.pathInfos.pushPathByName(routerOptions.url, routerOptions.params, false);
    }
    AppStorage.delete('callSettingsUri');
    hiTraceMeter.finishTrace('onPageShow', 1201);
  }

  onPageHide(): void {
    LogUtils.i(TAG, 'onPageHide');
  }

  getSimStateDataCardOne() {
    getSimStateCardOne()?.then((res: number) => {
      LogUtils.i(TAG, 'getSimStateData Card1 :success ' + JSON.stringify(res))
      if (res == sim.SimState.SIM_STATE_LOADED || res == sim.SimState.SIM_STATE_READY) {
        this.isSimActiveWithSlotId(0);
        this.getSimNameWithSlotId(0);
      } else {
        this.simStateStatusCardOne = false;
        this.TelephoneNumber0 = '';
      }
    }).catch((err: BusinessError) => {
      this.simStateStatusCardOne = false;
      this.TelephoneNumber0 = '';
      LogUtils.i(TAG, 'getSimStateData Card1 err: ' + JSON.stringify(err.message));
    });
    this.updateCustParamCardOne();
  }

  getSimStateDataCardTwo() {
    getSimStateCardTwo()?.then((res: number) => {
      LogUtils.i(TAG, 'getSimState Card2 :success then' + JSON.stringify(res));
      if (res == sim.SimState.SIM_STATE_LOADED || res == sim.SimState.SIM_STATE_READY) {
        this.isSimActiveWithSlotId(1);
        this.getSimNameWithSlotId(1);
      } else {
        this.simStateStatusCardTwo = false;
        this.TelephoneNumber1 = '';
      }
    }).catch((err: BusinessError) => {
      this.simStateStatusCardTwo = false;
      this.TelephoneNumber1 = '';
      LogUtils.i(TAG, 'getSimState Card2 err: ' + JSON.stringify(err.message));
    });
    this.updateCustParamCardTwo();
  }

  isSimActiveWithSlotId(slotId: number) {
    isSimActive(slotId).then((res) => {
      LogUtils.i(TAG, 'isSimActive: ' + JSON.stringify(res) + ' slotId : ' + slotId);
      if (res) {
        if (slotId === 1) {
          this.simStateStatusCardTwo = true;
        } else {
          this.simStateStatusCardOne = true;
        }
      } else {
        if (slotId === 1) {
          this.simStateStatusCardTwo = false;
          this.TelephoneNumber1 = '';
        } else {
          this.simStateStatusCardOne = false;
          this.TelephoneNumber0 = '';
        }
      }
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, `isSimActive error: code: ${err?.code}, message: ${err?.message} `);
      if (slotId === 1) {
        this.simStateStatusCardTwo = false;
        this.TelephoneNumber1 = '';
      } else {
        this.simStateStatusCardOne = false;
        this.TelephoneNumber0 = '';
      }
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
      LogUtils.i(TAG, `getSimNameWithSlotId slotId: ${slotId} isPsimCard: ${this.simCardInfo[slotId][0]}
      simCardName: ${this.simCardInfo[slotId][1]}`);
    }
    // 获取SIM卡和eSIM卡打点
    ReportUtil.getInstance().reportGetSimNameWithSlotId(slotId, this.simCardInfo)
  }

  getSimCardOnePhoneNumber() {
    getSimCardOnePhoneNumber().then((res) => {
      if (res === 'null') {
        getSimCardDefaultPhoneNumber(0).then((resDefault: string) => {
          LogUtils.i(TAG, 'getSimTelephoneNumber card1 success.');
          this.TelephoneNumber0 = StringUtil.formatPhoneNumberInMultiLanguage(phoneFormat(resDefault));
        }).catch((err: BusinessError) => {
          LogUtils.i(TAG, 'getSimTelephoneNumber card1 other catch' + JSON.stringify(err));
        })
      } else {
        this.TelephoneNumber0 = StringUtil.formatPhoneNumberInMultiLanguage(phoneFormat(res));
      }
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, 'getSimCardOnePhoneNumber card1 other catch' + JSON.stringify(err));
    });
  }

  getSimCardTwoPhoneNumber() {
    getSimCardTwoPhoneNumber().then((res) => {
      if (res === 'null') {
        getSimCardDefaultPhoneNumber(1).then((resDefault: string) => {
          LogUtils.i(TAG, 'getSimCardDefaultPhoneNumber card2 success.');
          this.TelephoneNumber1 = StringUtil.formatPhoneNumberInMultiLanguage(phoneFormat(resDefault));
        }).catch((err: BusinessError) => {
          LogUtils.i(TAG, 'getSimCardDefaultPhoneNumber card2 other catch' + JSON.stringify(err));
        })
      } else {
        this.TelephoneNumber1 = StringUtil.formatPhoneNumberInMultiLanguage(phoneFormat(res));
      }
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, 'getSimCardTwoPhoneNumber card2 other catch' + JSON.stringify(err));
    });
  }

  registerSimStateChangeForCardOne() {
    registerSimStateChangeForSlotId(0, async (callStateInfo: observer.SimStateData) => {
      this.simStateStatusCardOne = callStateInfo.state === sim.SimState.SIM_STATE_READY || callStateInfo.state ===
      sim.SimState.SIM_STATE_LOADED ? true : false;
      this.getSimStateChange();
    });
  }

  registerSimStateChangeForCardTwo() {
    registerSimStateChangeForSlotId(1, async (callStateInfo: observer.SimStateData) => {
      this.simStateStatusCardTwo = callStateInfo.state === sim.SimState.SIM_STATE_READY || callStateInfo.state ===
      sim.SimState.SIM_STATE_LOADED ? true : false;
      this.getSimStateChange();
    });
  }

  registerWifiCallingSwitchStateObserver(slotId: number) {
    try {
      let context = CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT);
      const key = `${CallSettingsConstant.WIFI_CALLING_ENABLED}_${slotId}`;
      this.getWifiCallingSwitchState(context, key, slotId);
      settings.registerKeyObserver(context, key, settings.domainName.USER_PROPERTY, () => {
        this.getWifiCallingSwitchState(context, key, slotId);
      });
    } catch (err) {
      LogUtils.e(TAG, 'registerWifiCallingSwitchStateObserver error: code: ' + err.code + ', message: ' + err.message);
    }
  }

  registerWifiCallingImsModeObserver(slotId: number) {
    try {
      let context = CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT);
      const key = `${CallSettingsConstant.WIFI_CALLING_IMS_MODE}_${slotId}`;
      this.getWifiCallingImsMode(context, key, slotId);
      settings.registerKeyObserver(context, key, settings.domainName.USER_PROPERTY, () => {
        this.getWifiCallingImsMode(context, key, slotId);
      });
    } catch (err) {
      LogUtils.e(TAG, 'registerWifiCallingImsModeObserver error: code: ' + err.code + ', message: ' + err.message);
    }
  }

  getWifiCallingSwitchState(context: Context, key: string, slotId: number) {
    let result: string = commons.getWifiCallingSwitchState(context, key);
    const wifiCallingSwitchState: boolean = result === CallSettingsConstant.WIFI_CALLING_SWITCH_ON;
    if (slotId === Constants.SLOT_ID_ONE) {
      this.wifiCallingSwitchStateCard1 = wifiCallingSwitchState;
      LogUtils.i(TAG, `getWifiCallingSwitchState, wifiCallingSwitchStateCard1: ${this.wifiCallingSwitchStateCard1}`);
      return;
    }
    if (slotId === Constants.SLOT_ID_TWO) {
      this.wifiCallingSwitchStateCard2 = wifiCallingSwitchState;
      LogUtils.i(TAG, `getWifiCallingSwitchState, wifiCallingSwitchStateCard2: ${this.wifiCallingSwitchStateCard2}`);
      return;
    }
  }

  getWifiCallingImsMode(context: Context, key: string, slotId: number) {
    let result: string = commons.getWifiCallingImsMode(context, key);
    if (slotId === Constants.SLOT_ID_ONE) {
      this.wifiCallingImsModeCard1 = result;
      LogUtils.i(TAG, `getWifiCallingImsMode, wifiCallingImsModeCard1: ${this.wifiCallingImsModeCard1}`);
      return;
    }

    if (slotId === Constants.SLOT_ID_TWO) {
      this.wifiCallingImsModeCard2 = result;
      LogUtils.i(TAG, `getWifiCallingImsMode, wifiCallingImsModeCard2: ${this.wifiCallingImsModeCard2}`);
      return;
    }
  }

  addRegisterAccountInfoChange() {
    try {
      registerAccountInfoChange(async () => {
        this.getSimStateDataCardOne();
        this.getSimStateDataCardTwo();
        this.getSimStateChange();
      })
    } catch (err) {
      LogUtils.e(TAG, `addRegisterAccountInfoChange err = ${JSON.stringify(err)}`);
    }
  }

  getSimStateChange() {
    LogUtils.i(TAG,
      `getSimStateChange isSim1Active: ${this.simStateStatusCardOne}, isSim2Active: ${this.simStateStatusCardTwo}`);
    if (this.simStateStatusCardOne) {
      this.getSimCardOnePhoneNumber();
      this.getSimStateDataCardOne();
      this.newCallEnabledOne = SystemMode.getInstance().getSimStateDataCard(Constants.SLOT_ID_ONE);
    } else {
      this.TelephoneNumber0 = '';
    }
    if (this.simStateStatusCardTwo) {
      this.getSimCardTwoPhoneNumber();
      this.getSimStateDataCardTwo();
      this.newCallEnabledTwo = SystemMode.getInstance().getSimStateDataCard(Constants.SLOT_ID_TWO);
    } else {
      this.TelephoneNumber1 = '';
    }
  }

  updateCustParamCardOne() {
    let isSimActive = sim.isSimActiveSync(0);
    let isSupportVowifi = this.mCustNetworkCardOne.isSupportVowifi;
    LogUtils.i(TAG, `updateCustParamCardOne isSimActive:${isSimActive}, isSupportVowifi:${isSupportVowifi}`);
    this.isShowWifiCallingSwitchCard1 = isSupportVowifi && isSimActive;
  }

  updateCustParamCardTwo() {
    let isSimActive = sim.isSimActiveSync(1);
    let isSupportVowifi = this.mCustNetworkCardTwo.isSupportVowifi;
    LogUtils.i(TAG, `updateCustParamCardTwo isSimActive:${isSimActive}, isSupportVowifi:${isSupportVowifi}`);
    this.isShowWifiCallingSwitchCard2 = isSupportVowifi && isSimActive;
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear');
    try {
      unRegisterSimStateChange();
      unRegisterAccountInfoChange();
      removeRegisterDistributedStateListener();
      let context = CallSettingGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT);
      settings.unregisterKeyObserver(context, Constants.NUMBER_IDENTITY_KEY, settings.domainName.DEVICE_SHARED);
      settings.unregisterKeyObserver(context, Constants.CALL_LOG_MERGE_TYPE, settings.domainName.DEVICE_SHARED);
      settings.unregisterKeyObserver(context, Constants.CALL_NOTIFY_TYPE, settings.domainName.DEVICE_SHARED);
      settings.unregisterKeyObserver(context, Constants.FUSION_CALL_KEY, settings.domainName.USER_PROPERTY);
      settings.unregisterKeyObserver(context, Constants.INCALL_POWER_KEY, settings.domainName.USER_PROPERTY);
      this.dataShareHelper?.off('dataChange', dataShare.SubscriptionType.SUBSCRIPTION_TYPE_EXACT_URI,
        `${CallSettingsConstant.DATA_SHARE_ABILITY_NAME}${CallSettingsConstant.RECORDER_CONFIG_TABLE}`);
    } catch (err) {
      LogUtils.e(TAG, `aboutToDisappear err = ${JSON.stringify(err)}`);
    }
  }

  private getListMargin(): Resource {
    if (this.isFromExternal) {
      if (isTwoInOne()) {
        return $r('sys.float.padding_level12');
      }
      return $r('sys.float.padding_level8');
    }
    return CallColumnUtils.getInstance().getPaddingSpace(this.curBp);
  }

  private getNavigationTop(): string {
    if ((this.isFromExternal && this.isShowBorder) ||
    isTwoInOne()) {
      return '8vp';
    }
    return '0vp';
  }

  async build() {
    Navigation(this.pathInfos) {
      // EditableTitleBar(
      //   {
      //     title:$r('app.string.mobile_setting'),
      //     isSaveIconRequired:false
      //   }
      // )
      Column(){
        GridRow({
          columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: this.isFromExternal ? 0 : 24 }) {
          GridCol({
            span: this.isFromExternal ? { xs: 2, sm: 4, md: 8, lg: 12 } : { xs: 2, sm: 4, md: 6, lg: 8 },
            offset: this.isFromExternal ? 0 : { md: 1, lg: 2 }
          }) {
            List({ scroller: this.scroller }) {
              if (!isTwoInOne() || ScreenAdapterUtils.isSmallFoldPhone()) {
                SubHeader({
                  secondaryTitle: $r('app.string.call_setting_incoming'),
                  contentMargin: { start: LengthMetrics.vp(0), end: LengthMetrics.vp(0) }
                })
                ListItemGroup() {
                  if (!isTwoInOne()) {
                    ListItem() {
                      SubSettings({
                        slotId: $slotId0,
                        subData: $callNotifies,
                        isEnable: $showCallNotifies,
                        airPlaneOn: $airPlaneOn,
                        callText: $callText,
                        radioId: $radioId
                      })
                    }
                  }

                  if (!isTwoInOne()) {
                    ListItem() {
                      if (getMaxSimCount() === MAX_SIM_COUNTS) {
                        SubSettingRingtone({
                          airPlaneOn: $airPlaneOn,
                          simCardInfo: this.simCardInfo
                        })
                      } else {
                        SubSettings({
                          slotId: $slotId0,
                          subData: $callRingTone,
                          isEnable: $showCallNotifies,
                          airPlaneOn: $airPlaneOn,
                          callText: $callText,
                          radioId: $radioId
                        })
                      }
                    }
                  }

                  if (ScreenAdapterUtils.isSmallFoldPhone()) {
                    ListItem() {
                      this.ExpandAutoAnswerSwitch();
                    }
                    .id('callSetting_pages_index_listItem_SubCheckBox_controlSwitch_airPlaneOn_onChange')
                  }
                }
                .listItemGroupExtend(this.isFromExternal)
              }


              SubHeader({
                secondaryTitle: $r('app.string.call_setting_call'),
                contentMargin: { start: LengthMetrics.vp(0), end: LengthMetrics.vp(0) }
              })
              ListItemGroup() {
                if (!isTwoInOne()) {
                  ListItem() {
                    SubRecordConfig({ airPlaneOn: $airPlaneOn, isDistributeSink: $isDistributeSink })
                  }
                }
                ListItem() {
                  SubSettings({
                    slotId: $slotId0,
                    subData: $callForwardSubData2,
                    isEnable: $showRejectMessageData,
                    airPlaneOn: $airPlaneOn,
                    callText: $callText,
                    radioId: $radioId
                  })
                }
              }
              .listItemGroupExtend(this.isFromExternal)

              if (getMaxSimCount() === MAX_SIM_COUNTS) {
                SubHeader({
                  secondaryTitle: this.simCardInfo[0][0] ?
                    `${StringUtil.formatResourceWithParamToString($r('app.string.sim_card_num_no_space'),
                      this.simCardInfo[0][1])}${this.TelephoneNumber0}` :
                    `${StringUtil.formatResourceWithParamToString($r('app.string.esim_card_num_no_space'),
                      this.simCardInfo[0][1])}${this.TelephoneNumber0}`,
                  secondaryTitleModifier: this.secondaryModifier,
                  contentMargin: { start: LengthMetrics.vp(0), end: LengthMetrics.vp(0) }
                })
              } else {
                if (!isTwoInOne()) {
                  SubHeader({
                    secondaryTitle: StringUtil.formatResourceToString($r('app.string.call_setting_incoming')),
                    contentMargin: { start: LengthMetrics.vp(0), end: LengthMetrics.vp(0) }
                  })
                }
              }
              if (!isTwoInOne()) {
                ListItemGroup() {
                  ListItem() {
                    SubSettings({
                      slotId: $slotId0,
                      subData: $callForwardSubData0,
                      isEnable: $simStateStatusCardOne,
                      airPlaneOn: $airPlaneOn,
                      callText: $callText,
                      radioId: $radioId
                    })
                  }

                  ListItem() {
                    SubSettings({
                      slotId: $slotId0,
                      subData: $wifiCallingSubData0,
                      isEnable: $simStateStatusCardOne,
                      airPlaneOn: $airPlaneOn,
                      callText: $callText,
                      radioId: $radioId
                    })
                  }
                  .id('callSetting_pages_index_listItem_subSetting_wifiCalling0')
                  .visibility(this.mCustNetworkCardOne.isSupportVowifi ? Visibility.Visible : Visibility.None)

                  ListItem() {
                    SubSettings({
                      slotId: $slotId0,
                      subData: $moreCard0,
                      isEnable: $simStateStatusCardOne,
                      airPlaneOn: $airPlaneOn,
                      callText: $callText,
                      radioId: $radioId
                    })
                  }
                }.onAppear(() => {
                  if (!AppStorage.get('scrollToCardOne')) {
                    return;
                  }
                  AppStorage.delete('scrollToCardOne');
                  try {
                    const rect = this.scroller.getItemRect(2);
                    this.scroller.scrollTo({ xOffset: 0, yOffset: rect.y });
                  } catch (err) {
                    LogUtils.e(TAG, `scroll failed, code: ${err?.code}, message: ${err?.message}`);
                  }
                })
                .listItemGroupExtend(this.isFromExternal)
              }
              if (getMaxSimCount() === MAX_SIM_COUNTS) {
                SubHeader({
                  secondaryTitle: this.simCardInfo[1][0] ?
                    `${StringUtil.formatResourceWithParamToString($r('app.string.sim_card_num_no_space'),
                      this.simCardInfo[1][1])}${this.TelephoneNumber1}` :
                    `${StringUtil.formatResourceWithParamToString($r('app.string.esim_card_num_no_space'),
                      this.simCardInfo[1][1])}${this.TelephoneNumber1}`,
                  secondaryTitleModifier: this.secondaryModifier,
                  contentMargin: { start: LengthMetrics.vp(0), end: LengthMetrics.vp(0) }
                })

                ListItemGroup() {
                  ListItem() {
                    SubSettings({
                      slotId: $slotId1,
                      subData: $callForwardSubData1,
                      isEnable: $simStateStatusCardTwo,
                      airPlaneOn: $airPlaneOn,
                      callText: $callText,
                      radioId: $radioId
                    })
                  }

                  ListItem() {
                    SubSettings({
                      slotId: $slotId1,
                      subData: $wifiCallingSubData1,
                      isEnable: $simStateStatusCardTwo,
                      airPlaneOn: $airPlaneOn,
                      callText: $callText,
                      radioId: $radioId,
                    })
                  }
                  .id('callSetting_pages_index_listItem_subSetting_wifiCalling1')
                  .visibility(this.mCustNetworkCardTwo.isSupportVowifi ? Visibility.Visible : Visibility.None)

                  ListItem() {
                    SubSettings({
                      slotId: $slotId1,
                      subData: $moreCard1,
                      isEnable: $simStateStatusCardTwo,
                      airPlaneOn: $airPlaneOn,
                      callText: $callText,
                      radioId: $radioId
                    })
                  }
                }
                .listItemGroupExtend(this.isFromExternal)
              }

              SubHeader({
                secondaryTitle: StringUtil.formatResourceToString($r('app.string.others')),
                contentMargin: { start: LengthMetrics.vp(0), end: LengthMetrics.vp(0) }
              })

              ListItemGroup() {
                ListItem() {
                  SubSettings({
                    slotId: $slotId1,
                    subData: $callRejectMessageData,
                    isEnable: $showRejectMessageData,
                    airPlaneOn: $airPlaneOn,
                    callText: $callText,
                    radioId: $radioId
                  })
                }

                ListItem() {
                  SubSettings({
                    slotId: $slotId1,
                    subData: $speedDialData,
                    isEnable: $showRejectMessageData,
                    airPlaneOn: $airPlaneOn,
                    callText: $callText,
                    radioId: $radioId
                  })
                }

                if (sim.getMaxSimCount() !== 0) {
                  ListItem() {
                    SubSettings({
                      slotId: $slotId1,
                      subData: $advanceOptions,
                      isEnable: $showRejectMessageData,
                      airPlaneOn: $airPlaneOn,
                      callText: $callText,
                      radioId: $radioId
                    })
                  }
                }
              }
              .listItemGroupExtend(this.isFromExternal)

              ListItemGroup() {
                ListItem() {
                  SubSettings({
                    slotId: $slotId1,
                    subData: $callAbout,
                    isEnable: $showRejectMessageData,
                    airPlaneOn: $airPlaneOn,
                    callText: $callText,
                    radioId: $radioId
                  })
                }
              }
              .listItemGroupExtend(this.isFromExternal)
              .margin({ top: $r('sys.float.padding_level6') });
            }
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
            .scrollBar(BarState.Off)
            .contentEndOffset(44)
            .clip(false)
          }
          .height('100%')
        }
        .margin({
          left: this.getListMargin(),
          right: this.getListMargin()
        })
      }
      .layoutWeight(1)
    }
    //.bindSheet()
    .mode(NavigationMode.Stack)
    .titleMode(NavigationTitleMode.Mini)
    .title($r('app.string.mobile_setting'))
    // .titleBar(TitleParams.MiniTitleParams($r('app.string.mobile_setting'),
    //     this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
    //     $r('sys.color.background_secondary'), this.isCrossMarkExists, false))
    // .titleMode(this.isFromExternal? HdsHdsNavigationTitleMode.MODAL: HdsHdsNavigationTitleMode.MINI)
    //.title(this.myTitleBar)
    //.hideTitleBar(true)
    .hideBackButton(this.isFromExternal)
    .backgroundColor(this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
      $r('sys.color.background_secondary'))
    .navDestination(this.myRouter)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
    .onAppear(() => {
      this.subscribePowerSaveEvent();
    })
    .onDisAppear(()=>{
      SystemMode.getInstance().unSubscribeEvent(this.powerSaveEvent);
    })
  }
  @Builder
  myTitleBar() {
    TitleBarLayout($r('app.string.mobile_setting'), this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
      $r('sys.color.background_secondary'), this.isCrossMarkExists)
  }

  private async subscribePowerSaveEvent() {
    this.powerSaveEvent = await SystemMode.getInstance().subscribePowerSaveEvent(() => {
      this.checkPenglaiMode();
    });
  }

  private notSupportModeToast() {
    if (!this.voiceControlCallAble) {
      ToastUtil.handleMultiToast($r('app.string.not_support_toast'), 2000);
      LogUtils.i(TAG, `mode is penglai show prmptAction then return`);
    }
  }
}

@Extend(ListItemGroup)
function listItemGroupExtend(isFromExternal = false) {
  .backgroundColor(isFromExternal ? $r('sys.color.comp_background_list_card') : $r('sys.color.comp_background_primary'))
  .borderRadius($r('sys.float.corner_radius_level10'))
  .padding({ top: 4, bottom: 4})
  .divider({
    strokeWidth: '1px',
    color: $r('sys.color.comp_divider'),
    startMargin: $r('sys.float.padding_level6'),
    endMargin: $r('sys.float.padding_level6')
  })
}
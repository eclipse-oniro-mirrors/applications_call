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
import {
  DISPLAY_CALL_PAGE_VALUE_OF_EXTRA_PARAMS,
  SosEmergencyCallController } from '../control/SosEmergencyCallController';
import CallColumnUtils from '../utils/CallColumnUtils';
import {
  ContactListStruct,
  EccsCountryStruct,
  EccsStruct,
  EmergencyNumListStruct,
  TimeOutStruct
} from '../utils/ClassStruct';
import LogUtils from '../utils/HiLog';
import { Utils } from '../utils/Utils';
import EmergencyInfoUIExtension from './EmergencyInfoUIExtension';
import { componentUtils, LengthMetrics } from '@kit.ArkUI';
import { call, observer } from '@kit.TelephonyKit';
import { BusinessError, commonEventManager, settings } from '@kit.BasicServicesKit';
import { SosCountdown } from '../components/sos/SosCountdown';
import { AudioPlayerService } from '../service/AudioPlayerService';
import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { SosEmergencyNumberListItem } from '../components/sos/SosEmergencyNumberListItem';
import { AlertDialog } from '@kit.ArkUI'
import { I18nPhoneNumberFormat, TelephoneUtil } from '../utils/TelephoneUtil';
import EmergencyCallController from '../control/EmergencyCallControl';
import { ReportUtil } from '../utils/ReportUtil';
import { getEmptyEmergencyListData } from '../utils/InitDataUtil';
import { IS_RUNNING_OF_AUTO_SEND_SOS_MSG, SosEmergencySmsController} from '../control/SosEmergencySmsController';
import { AudioUtil } from '../utils/AudioUtil';
import EmergencyNumber from '../utils/EmergencyNumber';
import { getCountryCode } from '../EmergencyEarthquackLocationService/Geo';
import SOSEmergencyCallAbility, { ABILITY_STATE_KEY,
  ABILITY_STATE_ON_BACKGROUND,
  IS_LOCK_SUCCESS_IN_PENG_LAI,
  releaseCpuResourcesFromSosEmergencyAbility} from '../sosemergencycallability/SOSEmergencyCallAbility';
import { DefaultListItem, LLIST_SEL_TIMEOUT } from './Index';
import { addAirPlaneModeListener, removeAirPlaneModeListener } from '../data/AirplaneMode';
import { ContactsService } from '../service/ContactsService';
import CommonData, {
  AutoDialCallResult,
  AutoSendSosMessageResult,
  CommunicationNetworkType,
  PersonalSafetyReportSosType
} from '../data/CommonData';
import { PersonalSafetyCountdown } from '../components/PersonalSafetyCountdown';
import { CAR_ACCIDENT, FALL_DOWN, PERSONAL_SAFETY_ACCIDENT_TYPE, SOS_EXIT_IN_SOS_PAGE } from '../utils/Constants'
import { PersonalSafetyAccidentType } from '../utils/ClassStruct'
import { CommonEventUtils } from '../utils/CommonEventUtils';
import { SystemModeController } from '../control/SystemModeController';
import {
  SatelliteUtil,
  TIAN_TONG_CONNECT_STATE_KEY,
  TIAN_TONG_SLOT_KEY
} from '../utils/SatelliteUtil';
import { addTianTongConnectStateListener, queryTianTongSatelliteConnectState } from '../model/SatelliteModel';
//import { HdsNavigation, HdsNavigationAttribute, HdsNavigationTitleMode } from '@kit.UIDesignKit';
import { geoLocationManager } from '@kit.LocationKit';

const TAG = 'SosEmergencyCall';
const AIRPLANE_MODE = 1;
export const QUERY_SATELLITE_MODE_TIANTONG_KEY = 'satellite_mode_switch_tiantong';
export const QUERY_SATELLITE_MODE_HYACINTH_KEY = 'satellite_mode_switch_hyacinth';

interface SosConfig {
  waitTimeForDialing: number;
}

/**
 * 蜂窝通信网络下的SOS求助功能配置
 */
const SOS_CONFIG_ON_CELLAR: SosConfig = {
  waitTimeForDialing: 30000
}
/**
 * 天通卫星通信网络下的SOS求助功能配置
 */
const SOS_CONFIG_ON_TIAN_TONG: SosConfig = {
  waitTimeForDialing: 60000
}

const CALL_COUNT_EXCEED_LIMIT_CODE = 8300008;

export const COMMUNICATION_NETWORK_TYPE = 'communicationNetworkType';

export const ABNORMAL_TIP_OF_TIAN_TONG = 'abnormalTipOfTianTong';

export const SATELLITE_DISABLE_VALUE = 0;

export const SATELLITE_ENABLED_VALUE = 1;

export enum SatelliteType {
  OTHER_SATELLITE = -1,
  NO_SATELLITE = 0,
  TIANTONG_SATELLITE = 1,
  HYACINTH_SATELLITE = 2
}

/** 蓬莱模式一的SOS求助功能的初始化重试参数  */
interface RetryInitParam {
  /** 是否有重试过初始化逻辑 */
  isRetriedInitInPengLai: boolean;

  /** 是否在下次页面显示时重试初始化逻辑 */
  isRetryInNextPageShow: boolean;
}

@Entry({ storage: LocalStorage.getShared() })
@Component
export struct SosEmergencyCall {
  mSosEmergencyCallController: SosEmergencyCallController = SosEmergencyCallController.getInstance();
  mSosEmergencySmsController: SosEmergencySmsController = SosEmergencySmsController.getInstance();
  @Provide('pathInfos') pathInfos: NavPathStack = new NavPathStack();
  @State autoSendSOSMessageSwitchState: boolean = Utils.isAutoSendSosSmsSwitchOn();
  @State autoAutoDialSOSNumberSwitchState: boolean = Utils.isAutoDialSosNumberSwitchOn();
  @State mEmergencyCallController: EmergencyCallController = EmergencyCallController.getInstance();
  @State clickActiveContactItemIds: string[] = [];
  @State activeOffsetX: number = 0;
  @State movingId: string = '';
  @StorageLink(SosEmergencyCallController.EMERGENCY_CONTACTS_KEY) emergencyContacts:
    ContactListStruct[] = [];
  /**
   * 在当前界面发起的正在进行的sos通话对应的联系人在紧急联系人列表的index
   */
  @StorageLink(SosEmergencyCallController.CURRENT_EMERGENCY_CONTACTS_INDEX_KEY) @Watch('outputContactIndex') currentEmergencyContactsIndex:
  number | null = null;
  @State currentEmergencyContactsIndex1: number | null = null;
  @State isDeviceHasSim: boolean = false;
  @StorageLink(SosEmergencySmsController.SOS_CAN_AUTO_SEND_SOS_MESSAGE_KEY) canAutoSendSosMessage: boolean =
    false;
  @State isDisplayCountdown: boolean = true;
  @StorageProp('curBp') curBp: string = '';
  @StorageProp('ratio') ratio: number = 0;
  @State isEnableAirPlaneMode: boolean = false;
  @StorageLink(SosEmergencyCallController.SOS_IS_HAS_NORMAL_WORK_SIM_CARD) isHasNormalWorkSimCard: boolean = true;
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;
  isCompletedAutoSendMessage: boolean = false;
  hasVoiceCapability: boolean = false;
  scroller: Scroller = new Scroller()
  @StorageLink(SosEmergencyCallController.IS_BEE_BUZZ_ALARM_ACTIVE_KEY) isBeeBuzzAlarmActive: boolean = false;
  exitButtonDialogContent: string | Resource = '';
  sosCallStatusDialingNum: number = 0;
  @State emergencyNumberLisHeight: number = 0;
  @State emergencyNumberScrollAreaHeight: number = 0;
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0;
  @StorageLink(SOSEmergencyCallAbility.KEY_TOP_STATUS_BAR_HEIGHT) topStatusBarHeight: number = 0;
  @State emergencyNumberList: EmergencyNumListStruct[] = [];
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  i18nPhoneNumberFormat = I18nPhoneNumberFormat.getInstance();
  simStateChangeEventSubscriber: commonEventManager.CommonEventSubscriber | null = null;
  /**
   * 在当前界面发起的正在进行的非sos通话对应的联系人在紧急联系人列表的index
   */
  @State @Watch('outputContactIndex') contactsIndexOfCommonCall: number | null = null;
  currentCallState: call.DetailedCallState = call.DetailedCallState.CALL_STATUS_IDLE;
  /** 天通卫星开关状态 */
  @State satelliteModeSwitchStatus: boolean = false;
  public eccEmerNumList: EccsCountryStruct[] = [];
  public isoCode: string = '';
  @LocalStorageLink(PERSONAL_SAFETY_ACCIDENT_TYPE) personalSafetyAccidentType: PersonalSafetyAccidentType = 'none';
  /**
   * SOS求助功能的通信网络类型，初始化赋值后不会再变更
   */
  @StorageProp(COMMUNICATION_NETWORK_TYPE) communicationNetworkType: CommunicationNetworkType =
    CommunicationNetworkType.NONE;
  @StorageProp(ABNORMAL_TIP_OF_TIAN_TONG) abnormalTipOfTianTong: string = '';
  private isHasBeenStartedSosOnTianTongNet: boolean = false;
  private isHasBeenStartedAutoSosCallOnTianTong: boolean = false;
  private mSystemModeController: SystemModeController = SystemModeController.getInstance();
  @StorageLink(TIAN_TONG_CONNECT_STATE_KEY) isTianTongSatelliteConnected: boolean = false;
  @StorageProp('currentColorMode') currentColorMode: ConfigurationConstant.ColorMode | undefined = undefined;
  @StorageLink(IS_RUNNING_OF_AUTO_SEND_SOS_MSG) isRunningOfAutoSendSosMsg: boolean = false;
  /** 当前是否是页面在组件创建后的第一次显示 */
  private isFirstPageShowAfterPageCreate: boolean = false;
  // 紧急联系人通话列表
  private commonCalls: number[] = [];
  // 当前卫星类型
  @State currentSatelliteType: SatelliteType = SatelliteType.NO_SATELLITE;
  /** 蓬莱模式一的SOS求助功能的初始化重试参数  */
  private retryInitParam: RetryInitParam = {
    isRetriedInitInPengLai: false,
    isRetryInNextPageShow: false
  }
  /**
   * 获取是否可以自动拨打求助电话
   * @returns
   */
  getCanAutoDialSosCall = (): boolean => {
    if (this.mSystemModeController.getIsEnableSosOnSatelliteNet()) {
      switch (this.communicationNetworkType) {
        case CommunicationNetworkType.CELLULAR:
          return this.getCanAutoDialSosCallOnCellarNet();
        case CommunicationNetworkType.TIAN_TONG:
          return this.getCanAutoDialSosCallOnTianTongSatelliteNet();
        default:
          return false;
      }
    } else {
      return this.getCanAutoDialSosCallOnCellarNet();
    }
  }
  private getCanAutoDialSosCallOnCellarNet = (): boolean => {
    let canAutoDialSosCall = this.autoAutoDialSOSNumberSwitchState && this.emergencyContacts &&
      this.emergencyContacts.length > 0 && this.isDeviceHasSim && !this.isEnableAirPlaneMode &&
      !this.mSosEmergencyCallController.isCompletedAutoDialCall && this.hasVoiceCapability;
    LogUtils.i(TAG, 'autoDialSwitchState：' + this.autoAutoDialSOSNumberSwitchState +
      ', hasEmergencyContact：' + (this.emergencyContacts.length > 0) + ', hasSim：' + this.isDeviceHasSim +
      ', enableAirPlaneMode：' + this.isEnableAirPlaneMode + ', completedAutoDialCall：' +
    this.mSosEmergencyCallController.isCompletedAutoDialCall + ', hasVoiceCapability：' + this.hasVoiceCapability);
    if (canAutoDialSosCall) {
      let isCheckCallStatePass = false;
      if (this.currentCallState === call.DetailedCallState.CALL_STATUS_IDLE ||
        this.currentCallState === call.DetailedCallState.CALL_STATUS_DISCONNECTED) {
        isCheckCallStatePass = true;
      }
      canAutoDialSosCall = canAutoDialSosCall && isCheckCallStatePass;
    }
    return canAutoDialSosCall;
  }
  private getCanAutoDialSosCallOnTianTongSatelliteNet = () => {
    let canAutoDialSosCall = this.autoAutoDialSOSNumberSwitchState && this.emergencyContacts &&
      this.emergencyContacts.length > 0 && !this.mSosEmergencyCallController.isCompletedAutoDialCall &&
    this.hasVoiceCapability;
    LogUtils.i(TAG, `autoDialSwitchState: ${this.autoAutoDialSOSNumberSwitchState} | contactsLength: ${
    this.emergencyContacts.length} | completedAutoDialCall: ${
    this.mSosEmergencyCallController.isCompletedAutoDialCall} hasVoiceCapability: ${this.hasVoiceCapability}`);
    if (canAutoDialSosCall) {
      let isCheckCallStatePass = false;
      if (this.currentCallState === call.DetailedCallState.CALL_STATUS_IDLE ||
        this.currentCallState === call.DetailedCallState.CALL_STATUS_DISCONNECTED) {
        isCheckCallStatePass = true;
      }
      canAutoDialSosCall = canAutoDialSosCall && isCheckCallStatePass;
    }
    return canAutoDialSosCall;
  }
  /**
   * @returns
   */
  getCanAutoSendSosMessage = () => {
    return this.autoSendSOSMessageSwitchState && this.emergencyContacts &&
      this.emergencyContacts.length > 0 && this.isDeviceHasSim && !this.isEnableAirPlaneMode;
  }
  private getCanAutoSendSosMessageOnTianTongSatelliteNet = () => {
    return this.autoSendSOSMessageSwitchState && this.emergencyContacts &&
      this.emergencyContacts.length > 0 && !this.isEnableAirPlaneMode;
  }
  private dialSosCallToContact = async (i: number, slotId: number) => {
    const item = this.emergencyContacts[i];
    if (!item?.value) {
      this.continueDialSosCall(() => {
        this.iterateBodyOfDialSosCall();
      });
      return;
    }
    try {
      this.sosCallStatusDialingNum = 0;
      this.mSosEmergencyCallController.isHangUpSosCallActively = false;
      await this.mSosEmergencyCallController.muteAudio();

      // 在非车祸或跌倒场景即主动拉起SOS求助界面场景下, 当前界面处于后台时不执行功能
      const isCheckPass = SosEmergencyCallController.checkSosEmergencyCallAbilityState(this.getUIContext());
      if (!isCheckPass) {
        LogUtils.w(TAG, 'dialSosCallToContact: current page on background, return');
        this.mSosEmergencyCallController.endDialSosCall();
        return;
      }

      if (this.personalSafetyAccidentType !== 'none') {
        item.callType = this.personalSafetyAccidentType;
      } else {
        item.callType = 'sosCall';
      }
      item.callState = call.DetailedCallState.CALL_STATUS_DIALING;
      SosEmergencyCallController.resetEmergencyContactsItem(i, item);

      const isError = await call.dialCall(item.value, {
        accountId: slotId,
        extraParams: { 'sosWithOutCallUiAbility': '1' },
        dialScene: call.DialScene.CALL_EMERGENCY
      }).then(() => {
        return false;
      }).catch((err: BusinessError) => {
        LogUtils.e(TAG, `dialSosCallToContact: dial call err->${JSON.stringify(err)}`);
        return true;
      })
      if (isError) {
        this.mSosEmergencyCallController.endDialSosCall();
        return;
      }
    } catch (e) {
      LogUtils.e(TAG, `dialSosCallToContact: dial call err->${JSON.stringify(e)}`);
      this.mSosEmergencyCallController.endDialSosCall();
      return;
    }
  }
  onSosCallDetailsChangeCallBack = async (data: call.CallAttributeOptions, type: string) => {
    if (this.currentEmergencyContactsIndex == null ||
      !this.emergencyContacts?.[this.currentEmergencyContactsIndex]?.value) {
      return;
    }

    const item = this.emergencyContacts[this.currentEmergencyContactsIndex];
    if (TelephoneUtil.formatDisplayPhoneNum(data.accountNumber) !== TelephoneUtil.formatDisplayPhoneNum(item.value)) {
      this.mSosEmergencyCallController.hangUpCallByCallId(data.callId);
      return;
    }

    let abilityState = AppStorage.get<string>(ABILITY_STATE_KEY);
    if (abilityState === ABILITY_STATE_ON_BACKGROUND && !SosEmergencyCallController.getInstance().isDisplayCallUi &&
      typeof item.callId !== 'number' && typeof data.callId === 'number') {
      // 若不因拉起通话界面而退到后台, 此时“自动拨打求助电话功能”刚调用接口给某个紧急联系人打电话但还未获取callId,
      // 在该时机接收到该紧急联系人号码的通话状态变更回调, 挂断该通话
      LogUtils.i(TAG, 'onSosCallDetailsChangeCallBack: UIAbility is on background, hang up this sos call.');
      this.mSosEmergencyCallController.hangUpCallByCallId(data.callId);
      this.mSosEmergencyCallController.resetEmergencyContactsCallPropertyByIndex(this.emergencyContacts,
        this.currentEmergencyContactsIndex);
      this.currentEmergencyContactsIndex = null;
      releaseCpuResourcesFromSosEmergencyAbility();
      return;
    }

    const callId = data.callId;
    if (data.callState === call.DetailedCallState.CALL_STATUS_DIALING && this.sosCallStatusDialingNum === 0) {
      LogUtils.i(TAG, `on sos callDetailsChange CALL_STATUS_DIALING`);
      this.sosCallStatusDialingNum++;
      item.callId = callId;
      item.callState = data.callState;
      if (type === CAR_ACCIDENT) {
        item.callType = CAR_ACCIDENT;
      } else if (type === FALL_DOWN) {
        item.callType = FALL_DOWN;
      } else {
        item.callType = 'sosCall';
      }
      SosEmergencyCallController.resetEmergencyContactsItem(this.currentEmergencyContactsIndex, item);
      this.mSosEmergencyCallController.clearTimerIdOfSosCallWaitTime();
      // When the phone is not connected, each waits for 30 seconds, hangs up after 30 seconds,
      this.mSosEmergencyCallController.timerIdOfSosCallWaitTime = setTimeout(async () => {
        LogUtils.i(TAG, `on sos callDetailsChange CALL_STATUS_DIALING: current call time out`);
        this.mSosEmergencyCallController.isHangUpSosCallActively = true;
        this.mSosEmergencyCallController.hangUpCallByCallId(callId);
        this.mSosEmergencyCallController.resetEmergencyContactsCallPropertyByIndex(this.emergencyContacts,
          this.currentEmergencyContactsIndex);
        this.continueDialSosCall(() => {
          this.mSosEmergencyCallController.isContinueDialCallNextContact = true;
        });
      }, this.mSystemModeController.getIsEnableSosOnSatelliteNet() &&
        this.communicationNetworkType === CommunicationNetworkType.TIAN_TONG ?
      SOS_CONFIG_ON_TIAN_TONG.waitTimeForDialing : SOS_CONFIG_ON_CELLAR.waitTimeForDialing);
    } else if (item.callId === callId && data.callState === call.DetailedCallState.CALL_STATUS_ACTIVE) {
      LogUtils.i(TAG, `on sos callDetailsChange CALL_STATUS_ACTIVE`);
      item.callState = data.callState;
      SosEmergencyCallController.resetEmergencyContactsItem(this.currentEmergencyContactsIndex, item);
      this.mSosEmergencyCallController.isCompletedAutoDialCall = true;
      this.mSosEmergencyCallController.clearTimerIdOfSosCallWaitTime();
      const failCallback = async () => {
        this.mSosEmergencyCallController.isHangUpSosCallActively = true;
        await this.mSosEmergencyCallController.hangUpCallByCallId(callId);
        this.mSosEmergencyCallController.resetEmergencyContactsCallPropertyByIndex(this.emergencyContacts,
          this.currentEmergencyContactsIndex);
        this.mSosEmergencyCallController.endDialSosCall();
      }
      if (type === 'sosCall') {
        AudioPlayerService.getInstance().startPlaySosAudioOnCall(callId, failCallback, 'sosCall');
      } else if (type === CAR_ACCIDENT) {
        AudioPlayerService.getInstance().startPlaySosAudioOnCall(callId, failCallback, CAR_ACCIDENT);
      } else if (type === FALL_DOWN) {
        AudioPlayerService.getInstance().startPlaySosAudioOnCall(callId, failCallback, FALL_DOWN);
      }
    } else if (item.callId === callId &&
      data.callState === call.DetailedCallState.CALL_STATUS_DISCONNECTED) {
      LogUtils.i(TAG, `on sos callDetailsChange CALL_STATUS_DISCONNECTED`);
      item.callState = data.callState;
      item.callId = null;
      SosEmergencyCallController.resetEmergencyContactsItem(this.currentEmergencyContactsIndex, item);
      await AudioPlayerService.getInstance().destroyAvPlayerOfSos();
      this.mSosEmergencyCallController.recoveryAudioNormal();
      if (!this.mSosEmergencyCallController.isHangUpSosCallActively) {
        this.mSosEmergencyCallController.clearTimerIdOfSosCallWaitTime();
        this.continueDialSosCall(() => {
          this.iterateBodyOfDialSosCall();
        });
      }
    }
  }
  iterateBodyOfDialSosCall = async () => {
    const length = this.emergencyContacts?.length;
    if (this.currentEmergencyContactsIndex == null || this.currentEmergencyContactsIndex >= length) {
      LogUtils.i(TAG, `iterateBodyOfDialSosCall: currentEmergencyContactsIndex is invalid, endDialSosCall`);
      this.mSosEmergencyCallController.endDialSosCall();
      return;
    }

    if (this.mSosEmergencyCallController.isCompletedAutoDialCall) {
      LogUtils.i(TAG, `iterateBodyOfDialSosCall: The auto dial call function is in completion state`);
      this.mSosEmergencyCallController.endDialSosCall();
      return;
    }

    let canAutoDialSosCall = false;
    if (this.personalSafetyAccidentType === CAR_ACCIDENT && this.checkCarAccidentAutoAskForHelp()) {
      canAutoDialSosCall = true;
    } else if (this.personalSafetyAccidentType === FALL_DOWN && this.checkFallDownAutoAskForHelp()) {
      canAutoDialSosCall = true;
    } else {
      canAutoDialSosCall = this.getCanAutoDialSosCall();
    }
    this.mSosEmergencyCallController.canAutoDialSosCall = canAutoDialSosCall;
    LogUtils.i(TAG, `startDialSosCall canAutoDialSosCall ${canAutoDialSosCall}`);
    if (!canAutoDialSosCall) {
      this.mSosEmergencyCallController.endDialSosCall();
      return;
    }
    let slotId: null | number = null;
    if (this.mSystemModeController.getIsEnableSosOnSatelliteNet() &&
      this.communicationNetworkType === CommunicationNetworkType.TIAN_TONG) {
      // 网络连接类型是天通，检查天通卫星网络连接状态，断连中止自动拨打求助电话流程
      let isTianTongSatelliteConnected = AppStorage.get<boolean>(TIAN_TONG_CONNECT_STATE_KEY) ?? false;
      if (!isTianTongSatelliteConnected) {
        LogUtils.w(TAG, 'iterateBodyOfDialSosCall: TianTong satellite network disconnected');
        this.mSosEmergencyCallController.endDialSosCall();
        return;
      }

      //获取slotId 卫星网络：使用卫星设置里的SIM卡
      slotId = Number(settings.getValueSync(getContext(this), TIAN_TONG_SLOT_KEY, '0'));
    } else {
      slotId = await SosEmergencyCallController.getNormalWorkSimCard();
    }
    if (slotId === null) {
      LogUtils.w(TAG, 'iterateBodyOfDialSosCall: The device does not have a working normally SIM card.');
      this.mSosEmergencyCallController.endDialSosCall();
      return;
    }
    this.dialSosCallToContact(this.currentEmergencyContactsIndex, slotId);
  }
  continueDialSosCall = (continueCallBack: () => void) => {
    LogUtils.i(TAG, `continueDialSosCall`);
    if (this.currentEmergencyContactsIndex == null) {
      this.mSosEmergencyCallController.endDialSosCall();
    } else {
      this.currentEmergencyContactsIndex++;
      continueCallBack();
    }
  }

  async startDialSosCall() {
    LogUtils.i(TAG, 'startDialSosCall');
    this.currentEmergencyContactsIndex = 0;
    const length = this.emergencyContacts?.length;
    if (!length) {
      LogUtils.i(TAG, `startDialSosCall: emergencyContacts is empty`);
      return;
    }

    this.iterateBodyOfDialSosCall();
  }

  private startDialSosCallOnTianTongNet = () => {
    LogUtils.i(TAG, 'startDialSosCallOnTianTongNet');
    this.currentEmergencyContactsIndex = 0;
    const length = this.emergencyContacts?.length;
    if (!length) {
      LogUtils.i(TAG, `startDialSosCallOnTianTongNet: emergencyContacts is empty`);
      return;
    }

    this.iterateBodyOfDialSosCall();
  }
  public listenAirPlaneModeChange = (context: Context) => {
    LogUtils.i(TAG, 'listenAirPlaneModeChange');
    try {
      addAirPlaneModeListener((res: Record<string, number | boolean>) => {
        LogUtils.i(TAG, 'listenAirPlaneModeChange callback');
        const newIsEnableAirPlaneMode = res?.data === AIRPLANE_MODE;
        if (!this.isEnableAirPlaneMode && newIsEnableAirPlaneMode) {
          this.mSosEmergencyCallController.canAutoDialSosCall = false;
          this.canAutoSendSosMessage = false;
          this.mSosEmergencyCallController.resetAutoDialSosCall();
          SosEmergencySmsController.getInstance().stopAutoSendSosMessage();
        }
        this.isEnableAirPlaneMode = newIsEnableAirPlaneMode;
      }, context);
    } catch (err) {
      LogUtils.e(TAG, `listenAirPlaneModeChange err = ${JSON.stringify(err)}`);
    }
  }
  onCommonCallDetailsChangeCallBack = (data: call.CallAttributeOptions) => {
    const index = this.contactsIndexOfCommonCall;
    if (index === null || !this.emergencyContacts?.[index]?.value) {
      return;
    }
    const item = this.emergencyContacts[index];
    if (TelephoneUtil.formatDisplayPhoneNum(data.accountNumber) !== TelephoneUtil.formatDisplayPhoneNum(item.value)) {
      return;
    }
    const callId = data.callId;
    if ((!item?.callId || item.callId === callId) &&
      data.callState === call.DetailedCallState.CALL_STATUS_DIALING) {
      LogUtils.i(TAG, `dialCommonCall: on sos callDetailsChange CALL_STATUS_DIALING`);
      item.callId = callId;
      item.callState = data.callState;
      SosEmergencyCallController.resetEmergencyContactsItem(index, item);
    } else if (item.callId === callId && data.callState === call.DetailedCallState.CALL_STATUS_ACTIVE) {
      LogUtils.i(TAG, `dialCommonCall: on sos callDetailsChange CALL_STATUS_ACTIVE`);
      item.callState = data.callState;
      SosEmergencyCallController.resetEmergencyContactsItem(index, item);
    } else if (item.callId === callId && data.callState === call.DetailedCallState.CALL_STATUS_DISCONNECTED) {
      LogUtils.i(TAG, `dialCommonCall: on sos callDetailsChange CALL_STATUS_DISCONNECTED`);
      item.callState = data.callState;
      item.callId = null;
      this.handleContactsIndexOfCommonCall(index);
      SosEmergencyCallController.resetEmergencyContactsItem(index, item);
    }
  };
  private setIsDisplayCallUi = (callId: number, callState: call.DetailedCallState,
    extraParams?: Record<string, Object>) => {
    if (callId == null) {
      LogUtils.e(TAG, `setIsDisplayCallUi: callId empty`);
      return;
    }
    LogUtils.i(TAG, `setIsDisplayCallUi: callState ${callState}`);
    if (extraParams?.sosWithOutCallUiAbility === DISPLAY_CALL_PAGE_VALUE_OF_EXTRA_PARAMS ||
      callState === call.DetailedCallState.CALL_STATUS_INCOMING ||
      (callState === call.DetailedCallState.CALL_STATUS_DIALING && this.currentEmergencyContactsIndex === null)) {
      this.mSosEmergencyCallController.isDisplayCallUi = true;
    }
  }
  observerCallDetailStateChange = () => {
    LogUtils.i(TAG, 'observerCallDetailStateChange');
    try {
      call.on('callDetailsChange', (data) => {
        this.currentCallState = data.callState;
        LogUtils.i(TAG, `on sos callDetailsChange`);
        this.setIsDisplayCallUi(data.callId, data.callState, data.extraParams);

        const isBeeBuzzAlarmActive = AppStorage.get<boolean>(SosEmergencyCallController.IS_BEE_BUZZ_ALARM_ACTIVE_KEY);
        if (isBeeBuzzAlarmActive &&
          ![call.DetailedCallState.CALL_STATUS_IDLE].includes(data.callState)) {
          this.mSosEmergencyCallController.stopBeeBuzzAlarm();
        }

        let index = this.emergencyContacts.find(item => item.callId === data.callId)?.index as number;
        if (this.commonCalls.includes(index)) {
          this.contactsIndexOfCommonCall = index;
        }

        if (this.contactsIndexOfCommonCall !== null &&
          this.emergencyContacts?.[this.contactsIndexOfCommonCall]?.callType === 'commonCall') {
          LogUtils.i(TAG, 'observerCallDetailStateChange commonCall');
          this.onCommonCallDetailsChangeCallBack(data);
        } else if (this.mSosEmergencyCallController.isContinueDialCallNextContact &&
          this.currentEmergencyContactsIndex !== null &&
          this.currentCallState === call.DetailedCallState.CALL_STATUS_DISCONNECTED) {
          LogUtils.i(TAG, `observerCallDetailStateChange sosCall continueDialCallNextContact`);
          this.mSosEmergencyCallController.isContinueDialCallNextContact = false;
          this.iterateBodyOfDialSosCall();
        } else if (this.currentEmergencyContactsIndex !== null &&
          this.emergencyContacts?.[this.currentEmergencyContactsIndex]?.callType === 'sosCall') {
          this.onSosCallDetailsChangeCallBack(data, 'sosCall');
          LogUtils.i(TAG, 'observerCallDetailStateChange sosCall');
        } else if (this.currentEmergencyContactsIndex !== null &&
          this.emergencyContacts?.[this.currentEmergencyContactsIndex]?.callType === CAR_ACCIDENT) {
          this.onSosCallDetailsChangeCallBack(data, CAR_ACCIDENT);
          LogUtils.i(TAG, 'observerCallDetailStateChange sosCarAccident');
        } else if (this.currentEmergencyContactsIndex !== null &&
          this.emergencyContacts?.[this.currentEmergencyContactsIndex]?.callType === FALL_DOWN) {
          this.onSosCallDetailsChangeCallBack(data, FALL_DOWN);
          LogUtils.i(TAG, 'observerCallDetailStateChange fallDown');
        } else if (this.currentEmergencyContactsIndex !== null &&
          this.emergencyContacts?.[this.currentEmergencyContactsIndex]?.callType === 'commonCallFromSosCall' &&
          this.emergencyContacts?.[this.currentEmergencyContactsIndex].callId === data.callId &&
          this.currentCallState === call.DetailedCallState.CALL_STATUS_DISCONNECTED) {
          LogUtils.i(TAG, 'observerCallDetailStateChange commonCallFromSosCall CALL_STATUS_DISCONNECTED');
          this.mSosEmergencyCallController.resetEmergencyContactsCallPropertyByIndex(this.emergencyContacts,
            this.currentEmergencyContactsIndex);
          this.currentEmergencyContactsIndex = null;
        }
      });
    } catch (e) {
      LogUtils.e(TAG, 'observerCallDetailStateChange error:' + JSON.stringify(e));
    }
  }

  private getCurrentSatelliteType = (context: Context): SatelliteType => {
    let res = SatelliteType.NO_SATELLITE;
    try {
      // 查询是否有在卫星状态,0-没有卫星状态,1-有卫星
      const satelliteStatus = settings.getValueSync(context, 'satellite_mode_switch', '0');
      if (!satelliteStatus || Number(satelliteStatus) === SATELLITE_DISABLE_VALUE) {
        LogUtils.i(TAG, `getCurrentSatelliteType result: ${SatelliteType.NO_SATELLITE}`);
        return SatelliteType.NO_SATELLITE;
      }
      // 查询是否是天通卫星,0-没有卫星状态,1-有当前卫星
      const tianTongType = settings.getValueSync(context, 'satellite_mode_switch_tiantong', '0');
      if (tianTongType && Number(tianTongType) === SATELLITE_ENABLED_VALUE) {
        LogUtils.i(TAG, `getCurrentSatelliteType result: ${SatelliteType.TIANTONG_SATELLITE}`);
        return SatelliteType.TIANTONG_SATELLITE;
      }
      // 查询是否风信子卫星,0-没有卫星状态,1-有当前卫星
      const hyacinthType = settings.getValueSync(context, 'satellite_mode_switch_hyacinth', '0');
      if (hyacinthType && Number(hyacinthType) === SATELLITE_ENABLED_VALUE) {
        LogUtils.i(TAG, `getCurrentSatelliteType result: ${SatelliteType.HYACINTH_SATELLITE}`);
        return SatelliteType.HYACINTH_SATELLITE;
      }
      res = SatelliteType.OTHER_SATELLITE;
    } catch (e) {
      LogUtils.e(TAG, `getCurrentSatelliteType error: ${e?.code}`);
    }
    return res;
  }

  private initDataByNetType = async (context: Context, netType: CommunicationNetworkType) => {
    try {
      this.emergencyContacts = await ContactsService.getInstance().syncAndGetEmergencyContactsFromDatabase(context);
      this.isEnableAirPlaneMode = SosEmergencyCallController.getIsEnableAirPlaneModeSync(context);
      this.hasVoiceCapability = call.hasVoiceCapability();
      this.getEmergencyNumberList();
      this.listenAirPlaneModeChange(context);
      this.subscribeSimStateChange();
      this.observerCallDetailStateChange();
    } catch (e) {
      LogUtils.e(TAG, `initDataByNetType error: ${e?.code} ${e?.message}`);
    }
  }
  /**
   * 在蓬莱模式下初始化数据
   * （支持卫星SOS功能）
   * @param context
   */
  private initWithSupportSosOnSatellite = async (context: Context) => {
    LogUtils.w(TAG, 'initWithSupportSosOnSatellite');
    //1.判断当前通信网络连接类型
    this.isDeviceHasSim = SosEmergencyCallController.isDeviceHasSimSync(true);
    LogUtils.w(TAG, `initWithSupportSosOnSatellite: isDeviceHasSim ${this.isDeviceHasSim}`);
    this.satelliteModeSwitchStatus = SatelliteUtil.getTianTongSatelliteSwitchState(context);
    CommonEventUtils.getInstance().showSatelliteWindow(this.satelliteModeSwitchStatus);

    let netType: CommunicationNetworkType = await this.mSosEmergencyCallController.getCommunicationNetworkType(context,
      this.isDeviceHasSim, this.satelliteModeSwitchStatus, () => { // 错误处理
        const isLockSuccessInPengLai = AppStorage.get<boolean>(IS_LOCK_SUCCESS_IN_PENG_LAI);
        LogUtils.w(TAG, `initWithSupportSosOnSatellite: retryInitFunction isLockInPengLai ${
        isLockSuccessInPengLai}, isRetriedInitInPengLai: ${this.retryInitParam?.isRetriedInitInPengLai}`);
        //若此时为解锁状态下拉起SOS紧急求助页面锁屏成功但首次初始化失败场景，并且没有重试过初始化逻辑，则在下次页面显示时重试初始化逻辑一次
        if (isLockSuccessInPengLai && !this.retryInitParam.isRetriedInitInPengLai) {
          this.retryInitParam.isRetryInNextPageShow = true;
        }
      });
    AppStorage.setOrCreate(COMMUNICATION_NETWORK_TYPE, netType);
    LogUtils.w(TAG, `initWithSupportSosOnSatellite: communicationNetworkType ${this.communicationNetworkType}`);
    if (this.retryInitParam.isRetryInNextPageShow) { //中止初始化逻辑的继续执行, 在下次页面显示时重试执行初始化逻辑
      LogUtils.w(TAG, 'initWithSupportSosOnSatellite: abort function and retry in next onPageShow');
      return;
    }

    //2.根据网络类型获取和监听SOS自动拨打电话和发送求助短信的条件。
    this.initDataByNetType(context, netType);
  }

  onPageShow() {
    if (this.mSystemModeController.getIsEnableSosOnSatelliteNet()) {
      const isLockSuccessInPengLai = AppStorage.get<boolean>(IS_LOCK_SUCCESS_IN_PENG_LAI);
      //蓬莱模式一中, 此时为解锁状态下拉起SOS紧急求助页面锁屏成功但首次初始化失败场景, 重试页面初始化逻辑一次
      if (isLockSuccessInPengLai && this.retryInitParam.isRetryInNextPageShow) {
        this.retryInitParam.isRetryInNextPageShow = false;
        this.retryInitParam.isRetriedInitInPengLai = true;
        LogUtils.i(TAG, 'onPageShow: retry init function in PengLai');
        this.initWithSupportSosOnSatellite(getContext());
      }
    }

    if (this.mSystemModeController.getIsEnableSosOnSatelliteNet() && this.isFirstPageShowAfterPageCreate) {
      LogUtils.i(TAG, 'onPageShow: fist page show after page create');
      this.isFirstPageShowAfterPageCreate = false;
      // 因锁屏后应用没有声明相应的权限不能从后台连接ServiceExtAbility
      // 所以在第一次页面显示的时候初始化支持卫星的SOS紧急求助功能(初始化中有场景会拉起天通卫星寻星窗口)
      this.initWithSupportSosOnSatellite(getContext());
    } else {
      LogUtils.i(TAG, 'onPageShow: not fist page show after page create');
      this.satelliteModeSwitchStatus = SatelliteUtil.getTianTongSatelliteSwitchState(getContext(this));
      CommonEventUtils.getInstance().showSatelliteWindow(this.satelliteModeSwitchStatus);
    }
  }

  async aboutToAppear() {
    LogUtils.w(TAG, 'aboutToAppear');
    const context = getContext();
    this.mSosEmergencySmsController.setAbilityContextAndUiContext(context, this.getUIContext());
    if (this.mSystemModeController.getIsEnableSosOnSatelliteNet()) {
      this.isFirstPageShowAfterPageCreate = true;
      this.initUILayoutListener();
    } else {
      this.initDataOnCommonMode(context);
    }
  }

  /**
   * 在普通模式下初始化数据
   * @param context
   */
  private async initDataOnCommonMode(context: Context) {
    LogUtils.w(TAG, 'initDataOnCommonMode');
    if (this.personalSafetyAccidentType === 'none') {
      ReportUtil.getInstance().reportSosClick5Power();
    }
    // 获取当前卫星状态及类型
    const curSatellite = this.getCurrentSatelliteType(context);
    if (curSatellite === SatelliteType.TIANTONG_SATELLITE || curSatellite === SatelliteType.HYACINTH_SATELLITE) {
      // 设置当前卫星类型,并打开弹窗
      this.currentSatelliteType = curSatellite;
      this.dialogControllerOfSatelliteModeSwitch.open();
      return;
    }

    await this.initDataOnCellularNet(context);
    this.initUILayoutListener();

    if (!this.emergencyContacts || !this.emergencyContacts.length) {
      ReportUtil.getInstance().reportSosMmsSuccessOrFail(AutoSendSosMessageResult.FAIL_WITH_NO_CONTACTS);
      ReportUtil.getInstance().reportSosCallSuccessOrFail(AutoDialCallResult.FAIL_WITH_NO_CONTACTS);
    }
    if (!this.isDeviceHasSim && this.emergencyContacts && this.emergencyContacts.length > 0 &&
      (this.autoSendSOSMessageSwitchState || this.autoAutoDialSOSNumberSwitchState)) {
      ReportUtil.getInstance().reportSosMmsSuccessOrFail(AutoSendSosMessageResult.FAIL_WITH_NO_SIM_CARD);
      ReportUtil.getInstance().reportSosCallSuccessOrFail(AutoDialCallResult.FAIL_WITH_NO_SIM_CARD);
    } else if ((this.isEnableAirPlaneMode || !this.isHasNormalWorkSimCard) &&
    this.emergencyContacts && this.emergencyContacts.length > 0 &&
      (this.autoSendSOSMessageSwitchState || this.autoAutoDialSOSNumberSwitchState)) {
      ReportUtil.getInstance().reportSosMmsSuccessOrFail(AutoSendSosMessageResult.FAIL_WITH_FLIGHT_MODE);
      ReportUtil.getInstance().reportSosCallSuccessOrFail(AutoDialCallResult.FAIL_WITH_FLIGHT_MODE);
    }
  }

  private async initDataOnCellularNet(context: Context) {
    this.emergencyContacts = await ContactsService.getInstance().syncAndGetEmergencyContactsFromDatabase(context);
    this.isDeviceHasSim = SosEmergencyCallController.isDeviceHasSimSync(true);
    this.isEnableAirPlaneMode = SosEmergencyCallController.getIsEnableAirPlaneModeSync(context);
    this.hasVoiceCapability = call.hasVoiceCapability();
    this.getEmergencyNumberList();
    this.listenAirPlaneModeChange(context);
    this.subscribeSimStateChange();
    this.observerCallDetailStateChange();
  }

  private initUILayoutListener = () => {
    this.mSosEmergencyCallController.listenerOfEmergencyNumberList.on('layout', () => {
      LogUtils.i(TAG, `listenerOfEmergencyNumberList layout`);
      try {
        const modePosition: componentUtils.ComponentInfo =
          componentUtils.getRectangleById(SosEmergencyCallController.EMERGENCY_NUMBER_LIST_ID);
        this.emergencyNumberLisHeight = modePosition?.size?.height || 0;
      } catch (e) {
        LogUtils.e(TAG, `listenerOfEmergencyNumberList layout error: ${JSON.stringify(e)}`);
      }
    });

    this.mSosEmergencyCallController.listenerOfEmergencyNumberScrollArea.on('layout', () => {
      LogUtils.i(TAG, `listenerOfEmergencyNumberScrollArea layout`);
      try {
        const modePosition: componentUtils.ComponentInfo =
          componentUtils.getRectangleById(SosEmergencyCallController.EMERGENCY_NUMBER_SCROLL_AREA_ID);
        this.emergencyNumberScrollAreaHeight = modePosition?.size?.height || 0;
      } catch (e) {
        LogUtils.e(TAG, `listenerOfEmergencyNumberScrollArea layout error: ${JSON.stringify(e)}`);
      }
    });
  }

  private async getEmergencyNumberList() {
    try {
      const value: Uint8Array = await getContext(this).resourceManager.getRawFileContent('eccdata.json')
        .catch((e: BusinessError) => {
          LogUtils.e(TAG, `getEmergencyNumberList error: ${e?.code} ${e?.message}`);
          return new Uint8Array();
        });

      this.eccEmerNumList = value ? JSON.parse(String.fromCharCode(...Array.from(value))).countries :
        [];
      let eccsCountryStructOfCN = this.eccEmerNumList.find(v => (v.iso_code === EmergencyNumber.ISO_GEO_CODE_CN));
      if (eccsCountryStructOfCN?.eccs) {
        let tempEmergencyNumber = eccsCountryStructOfCN.eccs.find(v => (v.phone_number ===
        EmergencyNumber.TRAFFIC_ACCIDENT_ALARM_NUMBER_CN));
        if (!tempEmergencyNumber) {
          eccsCountryStructOfCN.eccs.push({
            'phone_number': EmergencyNumber.TRAFFIC_ACCIDENT_ALARM_NUMBER_CN,
            'types': 'TRAFFIC'
          })
        }
      }

      const getCountriesByISOCode = (callback: Function, currentIsoCode: string) => {
        const target: EccsCountryStruct | undefined =
          this.eccEmerNumList.find((item: EccsCountryStruct) => item.iso_code ===
            currentIsoCode);
        callback(target ? target.eccs : []);
      }
      const countryCode: geoLocationManager.CountryCode | null = await getCountryCode();
      this.isoCode = countryCode?.country?.toUpperCase() || EmergencyNumber.ISO_GEO_CODE_CN;
      getCountriesByISOCode(async (eccs: Array<EccsStruct>) => {
        //获取拨打紧急号码的sim卡的slotId时，不校验sim卡的驻网状态，因为该状态不影响拨打紧急号码
        const slotId = await SosEmergencyCallController.getNormalWorkSimCard(false);
        LogUtils.w(TAG, `getEmergencyNumberList slotId: ${slotId}`);

        if (this.personalSafetyAccidentType !== 'none') {
          this.emergencyNumberList = []
          eccs.map((item: EccsStruct, index) => {
            if (item.types === 'POLICE' || item.types === 'AMBULANCE') {
              let listItem: EmergencyNumListStruct =
                EmergencyNumber.getInstance().retrunEmerNumListItem(item.phone_number, item.types, index, slotId ?? 0);
              this.emergencyNumberList.push(listItem)
            }
          })
        } else {
          const formatList: EmergencyNumListStruct[] = eccs.map((item: EccsStruct, index) => {
            let listItem: EmergencyNumListStruct =
              EmergencyNumber.getInstance().retrunEmerNumListItem(item.phone_number, item.types, index, slotId ?? 0);
            return listItem;
          })
          this.emergencyNumberList = formatList;
        }
      }, this.isoCode);
    } catch (e) {
      LogUtils.e(TAG, 'getEmergencyNumberList error: ' + JSON.stringify(e));
      this.eccEmerNumList = [];
      this.emergencyNumberList = [];
    }
  }

  public unsubscribeSimStateChange = () => {
    LogUtils.i(TAG, 'unsubscribeSimStateChange');
    if (!this.simStateChangeEventSubscriber) {
      return;
    }
    try {
      commonEventManager.unsubscribe(this.simStateChangeEventSubscriber, (err: BusinessError) => {
        if (err) {
          LogUtils.e(TAG,
            `unsubscribeSimStateChange failed, code is ${err.code}, message is ${err.message}`);
        } else {
          LogUtils.i(TAG, 'unsubscribeSimStateChange success');
          this.simStateChangeEventSubscriber = null;
        }
      });
    } catch (error) {
      LogUtils.e(TAG, `unsubscribeSimStateChange failed, error: ${JSON.stringify(error)}`);
    }
  }
  onSimStateChange = async (err: BusinessError, data: commonEventManager.CommonEventData) => {
    LogUtils.i(TAG, 'simStateChange');
    if (err) {
      LogUtils.e(TAG, `onSimStateChange failed, code is ${err.code}, message is ${err.message}`);
      return;
    }
    const isDeviceHasSimNew = SosEmergencyCallController.isDeviceHasSimSync(false);
    if (this.mSystemModeController.getIsEnableSosOnSatelliteNet()) {
      switch (this.communicationNetworkType) {
        case CommunicationNetworkType.CELLULAR:
          this.handleSimChange(isDeviceHasSimNew);
          break;
        case CommunicationNetworkType.TIAN_TONG:
          this.handleSimChangeOnSimRemove(isDeviceHasSimNew);
          break;
      }
    } else {
      this.handleSimChange(isDeviceHasSimNew);
    }

    SosEmergencyCallController.getNormalWorkSimCard();
    this.isDeviceHasSim = isDeviceHasSimNew;
  }
  private handleSimChange = (isDeviceHasSimNew: boolean) => {
    this.handleSimChangeOnSimRemove(isDeviceHasSimNew);
    if (this.isDeviceHasSim === false && isDeviceHasSimNew === true) {
      LogUtils.i(TAG, 'handleSimChangeOnCellarNet: Insert SIM card.');
      this.isDeviceHasSim = isDeviceHasSimNew;
      this.canAutoSendSosMessage = this.getCanAutoSendSosMessage();
      if (this.canAutoSendSosMessage && this.mSosEmergencySmsController.firstSendSuccess === false) {
        this.mSosEmergencySmsController.startAutoSendSosMessage('sos', this.getUIContext());
      }
    }
  }
  private handleSimChangeOnSimRemove = (isDeviceHasSimNew: boolean) => {
    if (this.isDeviceHasSim === true && isDeviceHasSimNew === false) {
      LogUtils.i(TAG, 'handleSimChangeOnSimRemove: Remove all SIM card.');
      this.mSosEmergencyCallController.isCompletedAutoDialCall = true;
      this.mSosEmergencyCallController.canAutoDialSosCall = false;
      this.canAutoSendSosMessage = false;
      this.mSosEmergencyCallController.resetAutoDialSosCall();
      SosEmergencySmsController.getInstance().stopAutoSendSosMessage();
    }
  }

  private subscribeSimStateChange() {
    if (!canIUse('SystemCapability.Telephony.StateRegistry')) {
      return;
    }
    LogUtils.i(TAG, 'subscribeSimStateChange');
    let commonEventSubscribeInfoData: commonEventManager.CommonEventSubscribeInfo = {
      events: [commonEventManager.Support.COMMON_EVENT_SIM_STATE_CHANGED]
    };

    let subscriber: commonEventManager.CommonEventSubscriber;
    try {
      subscriber = commonEventManager.createSubscriberSync(commonEventSubscribeInfoData);
      this.simStateChangeEventSubscriber = subscriber;
      commonEventManager.subscribe(this.simStateChangeEventSubscriber, this.onSimStateChange)
    } catch (error) {
      LogUtils.e(TAG, `subscribeSimStateChange createSubscriberSync failed, error: ${JSON.stringify(error)}`);
    }
  }

  onPageHide() {
    LogUtils.i(TAG, 'onPageHide')
    this.satelliteModeSwitchStatus = SatelliteUtil.getTianTongSatelliteSwitchState(getContext(this));
    CommonEventUtils.getInstance().hideSatelliteWindow(this.satelliteModeSwitchStatus);
  }

  async aboutToDisappear(): Promise<void> {
    LogUtils.i(TAG, 'aboutToDisappear');
    if (canIUse('SystemCapability.Telephony.StateRegistry')) {
      observer.off('simStateChange');
    }
    this.mSosEmergencyCallController.recoveryAudioNormal();
    AudioUtil.getInstance().recoverMediaVolume();
    this.mSosEmergencySmsController.stopAutoSendSosMessage();
    this.mSosEmergencyCallController.cancelSubscribeCallDetailsChange();
    this.mSosEmergencyCallController.listenerOfEmergencyNumberList.off('layout', () => {
    });
    this.mSosEmergencyCallController.listenerOfEmergencyNumberScrollArea.off('layout', () => {
    });
    removeAirPlaneModeListener();
    this.unsubscribeSimStateChange();
    this.satelliteModeSwitchStatus = SatelliteUtil.getTianTongSatelliteSwitchState(getContext(this));
    CommonEventUtils.getInstance().hideSatelliteWindow(this.satelliteModeSwitchStatus);
    if (this.mSystemModeController.getIsEnableSosOnSatelliteNet()) {
      SosEmergencyCallController.releaseSatelliteNetDataOfSosEmergencyCall(getContext(this));
    }
  }

  @Builder
  myRouter(name: string) {
    if (name === 'EmergencyInfoView') {
      EmergencyInfoUIExtension();
    }
  }

  onBackPress() {
    return true;
  }

  setTimeOutIdOfCountdown = (v: number) => {
    this.mSosEmergencyCallController.timeOutIdOfCountdown = v;
  }
  private startSosHelpOnTianTongNet = async () => {
    const context = getContext(this);
    const startAutoDialSosCall = () => {
      LogUtils.i(TAG, 'startSosHelpOnTianTongNet: startAutoDialSosCall');
      this.mSosEmergencyCallController.canAutoDialSosCall = this.getCanAutoDialSosCall();
      if (this.mSosEmergencyCallController.canAutoDialSosCall && !this.isHasBeenStartedAutoSosCallOnTianTong) {
        this.isHasBeenStartedAutoSosCallOnTianTong = true;
        this.startDialSosCallOnTianTongNet();
      }
    }

    const startSos = () => {
      //当前天通卫星连接状态为true时，开始发送求助信息 自动拨打求助电话和发送求助信息
      this.canAutoSendSosMessage = this.getCanAutoSendSosMessageOnTianTongSatelliteNet();
      if (this.canAutoSendSosMessage) {
        this.mSosEmergencySmsController.startAutoSendSosMessageOnTianTongNet(context, this.getUIContext(), () => {
          //第一次求助短信发送完成后（不论成功或者失败），紧接着进行自动拨打求助电话流程
          startAutoDialSosCall();
        });
      } else {
        startAutoDialSosCall();
      }
    }

    const startSosEmergencyHelpAfterSatelliteConnected = async () => {
      //获取天通卫星连接状态
      this.isTianTongSatelliteConnected = await queryTianTongSatelliteConnectState(context);
      LogUtils.i(TAG, 'startSosHelpOnTianTongNet: isTianTongSatelliteConnected: ' + this.isTianTongSatelliteConnected );

      if (this.isTianTongSatelliteConnected && !this.isHasBeenStartedSosOnTianTongNet) {
        this.isHasBeenStartedSosOnTianTongNet = true;
        startSos();
      }
    }
    //监听天通卫星连接状态
    addTianTongConnectStateListener(context, async () => {
      //等连接上后，开始自动拨打求助电话和发送求助信息
      startSosEmergencyHelpAfterSatelliteConnected();
    });
    startSosEmergencyHelpAfterSatelliteConnected();
  }
  /**
   *
   * 开始支持卫星网络的SOS紧急求助功能
   */
  private startSosHelpWithSupportSatellite = async () => {
    switch (this.communicationNetworkType) {
      case CommunicationNetworkType.CELLULAR:
        this.startSosHelpOnCellularNet();
        break;
      case CommunicationNetworkType.TIAN_TONG:
        this.startSosHelpOnTianTongNet();
        break;
    }
  }
  onCountdownComplete = () => {
    LogUtils.i(TAG, 'onCountdownComplete');
    this.mSosEmergencyCallController.publishEventToTellPageName('SosEmergencyCall');
    this.isDisplayCountdown = false;

    // 在非车祸或跌倒场景即主动拉起SOS求助界面场景下, 当前界面处于后台时不执行自动发送求助信息功能和自动拨打求助电话功能
    const isCheckPass = SosEmergencyCallController.checkSosEmergencyCallAbilityState(this.getUIContext());
    if (!isCheckPass) {
      LogUtils.w(TAG, 'onCountdownComplete: current page on background, return');
      return;
    }

    if (SystemModeController.getInstance().getIsEnableSosOnSatelliteNet()) {
      this.startSosHelpWithSupportSatellite();
    } else {
      this.startSosHelpOnCellularNet();
    }
  }

  checkCarAccidentAutoAskForHelp = () => {
    return Utils.isCarAccidentAutoCallSwitchOn() && this.emergencyContacts &&
      this.emergencyContacts.length > 0 && this.isDeviceHasSim && !this.isEnableAirPlaneMode;
  }

  checkFallDownAutoAskForHelp = () => {
    return Utils.isFallDownAutoCallSwitchOn() && this.emergencyContacts &&
      this.emergencyContacts.length > 0 && this.isDeviceHasSim && !this.isEnableAirPlaneMode;
  }

  onPersonalSafetyCountdownComplete = (autoTrigger: boolean, type: string) => {
    this.mSosEmergencyCallController.publishEventToTellPageName('SosEmergencyCall');
    this.isDisplayCountdown = false;

    if (autoTrigger === false) {
      if (type === CAR_ACCIDENT) {
        ReportUtil.getInstance().reportCrashTrigger(PersonalSafetyReportSosType.MANUALLY);
      } else if (type === FALL_DOWN) {
        ReportUtil.getInstance().reportFallTrigger(PersonalSafetyReportSosType.MANUALLY);
      }
      return;
    }

    if (type === CAR_ACCIDENT) {
      if (this.checkCarAccidentAutoAskForHelp()) {
        this.canAutoSendSosMessage = true;
        this.mSosEmergencySmsController.startAutoSendSosMessage(CAR_ACCIDENT, this.getUIContext());
        this.startDialSosCall();
      }
      ReportUtil.getInstance().reportCrashTrigger(PersonalSafetyReportSosType.AUTO);
    }

    if (type === FALL_DOWN) {
      if (this.checkFallDownAutoAskForHelp()) {
        this.canAutoSendSosMessage = true;
        this.mSosEmergencySmsController.startAutoSendSosMessage(FALL_DOWN, this.getUIContext());
        this.startDialSosCall();
      }
      ReportUtil.getInstance().reportFallTrigger(PersonalSafetyReportSosType.AUTO);
    }
  }

  exitSosEmergencyCall = async (isDialogRemind: boolean) => {
    LogUtils.i(TAG, 'exitSosEmergencyCall');
    if (isDialogRemind) {
      this.exitButtonDialogContent = $r('app.string.stop_share_location_prompt_content');
      this.dialogControllerOfExitButton.open();
    } else {
      this.mSosEmergencyCallController.terminateEmergencyCall(getContext() as common.UIAbilityContext);
    }

    if (this.personalSafetyAccidentType === CAR_ACCIDENT) {
      ReportUtil.getInstance().reportCrashTrigger(PersonalSafetyReportSosType.CANCEL);
    } else if (this.personalSafetyAccidentType === FALL_DOWN) {
      ReportUtil.getInstance().reportFallTrigger(PersonalSafetyReportSosType.CANCEL);
    }
  }
  public dialCommonCall = async (phoneNumber: string, slotId: number | null, index: number) => {
    if (!phoneNumber) {
      return;
    }
    //当前支持天通卫星SOS功能，并且开启了天通卫星开关，但是没有天通卫星连接时不去拨打phoneNumber的电话，而是拉起天通卫星寻星弹窗
    if (this.mSystemModeController.getIsEnableSosOnSatelliteNet() && !this.checkTianTongSatelliteState()) {
      return;
    }
    LogUtils.i(TAG, 'start dial Common Call');
    const item = this.emergencyContacts[index];

    const failFunction = () => {
      item.callType = undefined;
      item.callState = null;
      item.callId = null;
      this.contactsIndexOfCommonCall = null;
    }
    try {
      const isError = await call.dialCall(phoneNumber, {
        accountId: slotId || undefined,
        dialScene: call.DialScene.CALL_EMERGENCY
      }).then(() => {
        this.setSuccessCallInfo(item, index);
        return false;
      }).catch((err: BusinessError) => {
        LogUtils.e(TAG, `dialCommonCall: err: ${err.code}`);
        // 前一通未打通，不处理其他界面拨号操作
        if (err.code === CALL_COUNT_EXCEED_LIMIT_CODE) {
          return false;
        }
        return true;
      })
      if (isError) {
        failFunction();
        SosEmergencyCallController.resetEmergencyContactsItem(index, item);
      }
    } catch (e) {
      failFunction();
      SosEmergencyCallController.resetEmergencyContactsItem(index, item);
    }
  }

  private setSuccessCallInfo(item: ContactListStruct, index: number): void {
    this.contactsIndexOfCommonCall = index;
    this.commonCalls.push(index);
    item.callType = 'commonCall';
    item.callState = call.DetailedCallState.CALL_STATUS_DIALING;
    item.index = index;
    SosEmergencyCallController.resetEmergencyContactsItem(index, item);
  }

  // 处理紧急联系人通话列表：1、通话挂断后从列表中删除当前通话index；2、当当前通话列表长度为0时说明没有正在进行的通话，将当前通话index恢复默认
  private handleContactsIndexOfCommonCall(index: number): void {
    this.commonCalls = this.commonCalls.filter(item => item !== index);
    if (this.commonCalls.length === 0) {
      this.contactsIndexOfCommonCall = null;
    }
  }

  onSosEmergencyNumberListItemClick = async (item: ContactListStruct, index: number) => {
    LogUtils.i(TAG, 'onSosEmergencyNumberListItemClick');
    const slotId = await SosEmergencyCallController.getNormalWorkSimCard(!this.isEnableAirPlaneMode);
    LogUtils.i(TAG, `onSosEmergencyNumberListItemClick: slotId ${slotId}`);

    const callState = this.currentCallState;

    const isHasCall = this.getIsHasCall(callState);
    if (isHasCall) {
      if (this.currentEmergencyContactsIndex !== null) {
        LogUtils.i(TAG, 'onSosEmergencyNumberListItemClick: current has sosCall');
        const sosItem = this.emergencyContacts[this.currentEmergencyContactsIndex];
        if (this.currentEmergencyContactsIndex === index && sosItem?.callId != null &&
          (sosItem.callType === 'sosCall' || sosItem.callType === CAR_ACCIDENT || sosItem.callType === FALL_DOWN)) {
          LogUtils.i(TAG, 'onSosEmergencyNumberListItemClick: display sos call page');
          sosItem.callType = 'commonCallFromSosCall';
          SosEmergencyCallController.resetEmergencyContactsItem(index, sosItem);
          this.mSosEmergencyCallController.isCompletedAutoDialCall = true;
          this.mSosEmergencyCallController.canAutoDialSosCall = false;
          this.mSosEmergencyCallController.isContinueDialCallNextContact = false;
          this.mSosEmergencyCallController.clearTimerIdOfSosCallWaitTime();
          await AudioPlayerService.getInstance().destroyAvPlayerOfSos();
          await this.mSosEmergencyCallController.recoveryAudioNormal();
          this.mSosEmergencyCallController.displaySpecifiedCallPageByCallId(sosItem.callId);
        } else if (this.currentEmergencyContactsIndex === index && sosItem?.callId != null &&
          sosItem.callType === 'commonCallFromSosCall') {
          LogUtils.i(TAG, 'onSosEmergencyNumberListItemClick: display commonCallFromSosCall page');
          this.mSosEmergencyCallController.displaySpecifiedCallPageByCallId(sosItem.callId);
        } else {
          LogUtils.i(TAG, 'onSosEmergencyNumberListItemClick: sosCall switch to commonCall');
          this.mSosEmergencyCallController.isCompletedAutoDialCall = true;
          this.mSosEmergencyCallController.canAutoDialSosCall = false;
          await this.mSosEmergencyCallController.resetAutoDialSosCall();
          this.dialCommonCall(item.value, slotId, index);
        }
      } else if (item?.callId != null && item.callType === 'commonCall') {
        LogUtils.i(TAG, 'onSosEmergencyNumberListItemClick: display common page');
        this.mSosEmergencyCallController.displaySpecifiedCallPageByCallId(item.callId);
      } else {
        LogUtils.i(TAG, 'onSosEmergencyNumberListItemClick: dial other common call');
        this.dialCommonCall(item.value, slotId, index);
      }
    } else {
      LogUtils.i(TAG, 'onSosEmergencyNumberListItemClick: current not has call');
      if (this.personalSafetyAccidentType !== 'none') {
        item.callType = this.personalSafetyAccidentType;
      }
      if (this.personalSafetyAccidentType === CAR_ACCIDENT) {
        if (!this.isDeviceHasSim) {
          ReportUtil.getInstance().reportCrashDialResult('Contact_' + index, PersonalSafetyReportSosType.MANUALLY,
            AutoDialCallResult.FAIL_WITH_NO_SIM_CARD);
        } else if (this.isEnableAirPlaneMode) {
          ReportUtil.getInstance().reportCrashDialResult('Contact_' + index, PersonalSafetyReportSosType.MANUALLY,
            AutoDialCallResult.FAIL_WITH_FLIGHT_MODE);
        }
      } else if (this.personalSafetyAccidentType === FALL_DOWN) {
        if (!this.isDeviceHasSim) {
          ReportUtil.getInstance().reportFallDialResult('Contact_' + index, PersonalSafetyReportSosType.MANUALLY,
            AutoDialCallResult.FAIL_WITH_NO_SIM_CARD);
        } else if (this.isEnableAirPlaneMode) {
          ReportUtil.getInstance().reportFallDialResult('Contact_' + index, PersonalSafetyReportSosType.MANUALLY,
            AutoDialCallResult.FAIL_WITH_FLIGHT_MODE);
        }
      }
      this.dialCommonCall(item.value, slotId, index);
    }
  }

  private startSosHelpOnCellularNet() {
    this.canAutoSendSosMessage = this.getCanAutoSendSosMessage();
    if (this.canAutoSendSosMessage) {
      this.mSosEmergencySmsController.startAutoSendSosMessage('sos', this.getUIContext());
    }

    this.mSosEmergencyCallController.canAutoDialSosCall = this.getCanAutoDialSosCall();
    if (this.mSosEmergencyCallController.canAutoDialSosCall) {
      this.startDialSosCall();
    }
  }

  resetEmergencyContactsItem(index: number, item: ContactListStruct) {
    const newItem: ContactListStruct = ContactListStruct.getDeepCopy(item);
    this.emergencyContacts[index] = newItem as ContactListStruct;
  }

  outputContactIndex() {
    LogUtils.i(TAG, 'updateButtonStatus currentEmergencyContactsIndex：' + this.currentEmergencyContactsIndex +
      ', contactsIndexOfCommonCall：' + this.contactsIndexOfCommonCall);
  }

  @Builder
  renderSosEmergencyContactList() {
    List({ space: 12, initialIndex: 0 }) {
      ForEach(this.emergencyContacts, (item: ContactListStruct, index: number) => {
        ListItem() {
          SosEmergencyNumberListItem({
            item: item,
            index: index,
            icon: this.communicationNetworkType === CommunicationNetworkType.TIAN_TONG ?
            $r('sys.symbol.phone_badge_satellite_fill') : (
                (this.currentEmergencyContactsIndex === index || this.commonCalls.includes(index)) ?
                $r('sys.symbol.phone_arrow_up_right_fill') : $r('sys.symbol.phone_fill')
              ),
            title: item?.label,
            itemId: item?.id
          })
            .onClick(() => {
              this.onSosEmergencyNumberListItemClick(item, index);
            });
        }
        .width('100%')
        .constraintSize({ minHeight: 64 })
        .backgroundColor((this.currentEmergencyContactsIndex === index || this.commonCalls.includes(index)) ?
          'rgba(91, 168, 84, 1)' : (this.currentColorMode !== ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
          $r('app.color.comp_background_list_card_dark') : $r('sys.color.comp_background_list_card')))
        .borderRadius($r('sys.float.corner_radius_level10'));
      }, (item: ContactListStruct) => JSON.stringify(item));
    }
    .width('100%')
    .listDirection(Axis.Vertical)
    .flexShrink(0)
    .contentEndOffset(this.isNewFoldPhoneExternalScreen ? 112 : 0)
  }

  getBarrierFree = (label: ResourceStr): string => {
    if (label instanceof String) {
      return label as string;
    } else {
      let r = label as Resource;
      let value = getContext(this).resourceManager.getStringSync(r.id);
      return value;
    }
  }
  /**
   * 获取当前是否有通话
   */
  getIsHasCall = (callState: call.DetailedCallState) => {
    const isHasCall = ![call.DetailedCallState.CALL_STATUS_IDLE,
      call.DetailedCallState.CALL_STATUS_DISCONNECTED].includes(callState) ||
      this.currentEmergencyContactsIndex !== null || this.contactsIndexOfCommonCall !== null;
    LogUtils.i(TAG, `getIsHasCall: callState ${callState}, currentEmergencyContactsIndex ${
    this.currentEmergencyContactsIndex}, contactsIndexOfCommonCall ${this.contactsIndexOfCommonCall}`);
    return isHasCall;
  }

  reportPersonalSafetySmsDialContact(value: string, index: number | string): string {
    if (value === '110' || value === '120') {
      return value;
    }
    return 'Contact_' + index;
  }

  onSlideEmergencyNumberListItemHorizontallyActionEnd = async (event: GestureEvent, item: EmergencyNumListStruct) => {
    if (event.offsetX > 0) {
      this.activeOffsetX = 0;
    }
    if (event.offsetX > 150) {
      //当前支持天通卫星SOS功能，并且开启了天通卫星开关，但是没有天通卫星连接时不去拨打item的电话，而是拉起天通卫星寻星弹窗
      if (this.mSystemModeController.getIsEnableSosOnSatelliteNet() && !this.checkTianTongSatelliteState()) {
        return;
      }
      if (this.personalSafetyAccidentType === CAR_ACCIDENT) {
        ReportUtil.getInstance().reportCrashDialResult(this.reportPersonalSafetySmsDialContact(item.value, item.id),
          PersonalSafetyReportSosType.MANUALLY, AutoDialCallResult.SUCCESS);
      } else if (this.personalSafetyAccidentType === FALL_DOWN) {
        ReportUtil.getInstance().reportFallDialResult(this.reportPersonalSafetySmsDialContact(item.value, item.id),
          PersonalSafetyReportSosType.MANUALLY, AutoDialCallResult.SUCCESS);
      }
      this.mEmergencyCallController.emergencyCallDial(item.value, item.slotId, true);
      this.mEmergencyCallController.setTimeOutIdList.forEach(value => {
        if (value.timerId) {
          clearTimeout(value.timerId);
        }
      })
      this.mEmergencyCallController.setTimeOutIdList = [];
      this.clickActiveContactItemIds = [];
      this.movingId = ''
      ReportUtil.getInstance().reportEmergencyDial(item.value.length);
    }
  }

  @Builder
  renderEmergencyNumberList() {
    List({ space: 12, initialIndex: 0 }) {
      ForEach(this.emergencyNumberList, (item: EmergencyNumListStruct, index: number) => {
        ListItem() {
          if (this.clickActiveContactItemIds.includes(item.id)) {
            ActiveListItem({
              listItem: item,
              communicationNetworkType: this.communicationNetworkType
            })
              .id(`EmergencyCommunication_pages_index_ActiveListItem_item_${item.id}`)
              .translate({ x: this.movingId === item.id ? this.activeOffsetX : 0 })
              .gesture(
                PanGesture({ direction: PanDirection.Horizontal })
                  .onActionEnd((event: GestureEvent) => {
                    this.onSlideEmergencyNumberListItemHorizontallyActionEnd(event, item);
                  })
                  .onActionUpdate((event: GestureEvent) => {
                    this.mEmergencyCallController.clearIdOfList(item.id, (data: string) => {
                      this.clickActiveContactItemIds =
                        this.clickActiveContactItemIds.filter(value => value !== data);
                    });
                    this.movingId = item.id;
                    if (event.offsetX > 0) {
                      this.activeOffsetX = event.offsetX;
                    }
                  })
              )
          } else {
            DefaultListItem({
              listItem: item,
              communicationNetworkType: this.communicationNetworkType
            })
              .id(`EmergencyCommunication_pages_index_DefaultListItem_item_${item.id}`)
              .onClick(async () => {
                SosEmergencyCallController.getInstance().resetAutoDialSosCall();
                this.clickActiveContactItemIds.push(item.id);
                let timer = setTimeout(() => {
                  this.clickActiveContactItemIds =
                    this.clickActiveContactItemIds.filter(val => val !== item.id);
                  this.mEmergencyCallController.setTimeOutIdList =
                    this.mEmergencyCallController.setTimeOutIdList.filter(value =>
                    value.itemId !== item.id);
                }, LLIST_SEL_TIMEOUT)
                let timerItem: TimeOutStruct = {
                  itemId: item.id,
                  timerId: timer
                }
                this.mEmergencyCallController.pushIdToList(timerItem);
              })
              .accessibilityText(item.value + this.getBarrierFree(item.label))
          }
        }
        .width('100%')
        .constraintSize({ minHeight: this.personalSafetyAccidentType !== 'none' ? 66 : 64 })
        .backgroundColor(this.clickActiveContactItemIds.includes(item.id) ?
        $r('app.color.emc_warning') : (this.currentColorMode !== ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
          $r('app.color.comp_background_list_card_dark') : $r('sys.color.comp_background_list_card')))
        .borderRadius($r('sys.float.corner_radius_level10'));
      }, (item: EmergencyNumListStruct) => JSON.stringify(item));
    }
    .width('100%')
    .listDirection(Axis.Vertical)
    .flexShrink(0)
    .contentEndOffset(this.isNewFoldPhoneExternalScreen && !this.emergencyContacts?.length ? 112 : 0)
  }

  dialogControllerOfExitButton: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: this.exitButtonDialogContent,
      primaryButton: {
        value: $r('app.string.CANCEL'),
        action: () => {
          this.dialogControllerOfExitButton.close();
        },
      },
      secondaryButton: {
        value: $r('app.string.exit'),
        role: ButtonRole.ERROR,
        action: () => {
          this.mSosEmergencyCallController.terminateEmergencyCall(getContext() as common.UIAbilityContext);
        }
      },
    }),
    backgroundColor: $r('sys.color.ohos_id_blur_style_component_ultra_thick_color_dark'),
    backgroundBlurStyle: BlurStyle.COMPONENT_ULTRA_THICK,
    autoCancel: true,
    showInSubWindow: true,
    cancel: () => {
      this.dialogControllerOfExitButton.close();
    }
  })
  dialogControllerOfSatelliteModeSwitch: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: this.currentSatelliteType === SatelliteType.HYACINTH_SATELLITE ?
        $r('app.string.hyacinth_satellite_not_support') : $r('app.string.satellite_not_support'),
      primaryButton: {
        value: $r('app.string.determine'),
        action: () => {
          this.dialogControllerOfSatelliteModeSwitch.close();
          this.exitSosEmergencyCall(false);
        }
      }
    }),
    autoCancel: false,
    isModal: true,
    showInSubWindow: true,
    backgroundColor: $r('sys.color.ohos_id_blur_style_component_ultra_thick_color_dark'),
    backgroundBlurStyle: BlurStyle.COMPONENT_ULTRA_THICK,
    onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
      LogUtils.i(TAG, 'satellite_not_support dialog onWillDismiss');
    }
  })

  /**
   * 检查天通状态
   * 开关打开但没有连接上天通卫星网络返回false
   * 否则返回true
   *
   * @returns
   */
  private checkTianTongSatelliteState() {
    let tianTongSatelliteSwitchState = SatelliteUtil.getTianTongSatelliteSwitchState(
      getContext(this));
    if (tianTongSatelliteSwitchState && !this.isTianTongSatelliteConnected) {
      SosEmergencyCallController.publishActionSatelliteConnectEventOfTianTong();
      LogUtils.w(TAG, 'checkTianTongSatelliteState: not connect TianTong satellite');
      return false;
    }
    return true;
  }

  @Builder
  renderPerosonalSafetyBottomButtons() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontColor([$r('sys.color.icon_on_primary')])
          .fontSize($r('app.float.emc_widthLevel14'))
          .fontWeight(FontWeight.Medium)
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .width('64vp')
      .height('64vp')
      .margin({
        left: 148,
        right: 148,
      })
      .borderRadius(40)
      .backgroundEffect({
        radius: 81.55,
        saturation: 1.1,
        brightness: 1.0,
        color: '#33ffffff'
      })
      .onClick((e) => {
        LogUtils.i('SosButton', 'onIconClick')
        this.exitSosEmergencyCall(this.canAutoSendSosMessage);
      })

      Column() {
        Text($r('app.string.exit'))
          .textAlign(TextAlign.Center)
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Regular)
          .fontSize(14)
          .lineHeight(16)
          .fontColor('#99ffffff')
          .maxFontScale(1)
      }
      .height('19vp')
      .margin({
        top: '4vp',
        left: '16vp',
        right: '16vp',
      })
    }.margin({
      top: '24vp',
      left: '16vp',
      right: '16vp',
      bottom: '41vp'
    })
  }

  @Builder
  renderBottomButtons() {
    GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: { x: 8 } }) {
      GridCol({ span: { xs: 1, sm: 2, md:4, lg: 6 } }) {
        SosButton({
          onButtonClick: (event: ClickEvent) => {
            LogUtils.i(TAG, 'onBeeBuzzAlarmButtonClick');
            const isHasCall = this.getIsHasCall(this.currentCallState);
            if (isHasCall) {
              LogUtils.w(TAG, 'onBeeBuzzAlarmButtonClick: there has a call, and bee buzz alarm is disabled');
              return;
            }
            this.isBeeBuzzAlarmActive = !this.isBeeBuzzAlarmActive;
            if (this.isBeeBuzzAlarmActive) {
              this.mSosEmergencyCallController.playBeeBuzzAlarm();
            } else {
              this.mSosEmergencyCallController.stopBeeBuzzAlarm();
            }
            // sos 点击蜂鸣警报打点
            ReportUtil.getInstance().reportSosBeeBuzzAlarmBtn(this.isBeeBuzzAlarmActive);
          },
          buttonImage: $r('sys.symbol.warning'),
          isSymbol: true,
          buttonText: $r('app.string.emergency_number_alarm'),
          buttonBackgroundColor: this.isBeeBuzzAlarmActive ? $r('app.color.emc_warning') : undefined
        });
      }
      GridCol({ span: { xs: 1, sm: 2, md:4, lg: 6 } }) {
        SosButton({
          onButtonClick: (event: ClickEvent) => {
            LogUtils.i(TAG, 'on exit button click');
            this.exitSosEmergencyCall(this.canAutoSendSosMessage && this.isRunningOfAutoSendSosMsg);
            // sos 点击关闭打点
            ReportUtil.getInstance().reportSosClickCancelBtn(SOS_EXIT_IN_SOS_PAGE);
          },
          buttonImage: $r('sys.symbol.xmark'),
          isSymbol: true,
          buttonText: $r('app.string.exit'),
        });
      }
    }
    .width('100%')
    .padding({
      top: 24,
      left: 16,
      right: 16
    })
  }

  @Builder
  renderSubtitle(subtitleText: Resource | string, isShowIcon: boolean) {
    Row() {
      if (isShowIcon) {
        SymbolGlyph($r('sys.symbol.local'))
          .fontSize($r('app.float.emc_paddding_level9'))
          .fontColor([$r('sys.color.font_on_secondary')])
          .margin({
            top: 3.5, bottom: 2.5, end: LengthMetrics.vp(4)
          })
          .align(Alignment.Center)
      }

      Text(subtitleText)
        .margin({
          top: 1,
        })
        .fontColor($r('sys.color.font_on_secondary'))
        .fontSize($r('sys.float.Body_L'))
        .maxFontScale(1)
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(2)
        .textAlign(TextAlign.Center)
        .wordBreak(WordBreak.BREAK_WORD)
    }
    .height(24)
    .margin({ top: this.personalSafetyAccidentType !== 'none' ? 9.5 : 8, bottom: 1.5 })
    .width('100%')
    .padding({
      left: $r('sys.float.padding_level8'),
      right: $r('sys.float.padding_level8')
    })
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .flexShrink(0)
  }

  @Builder
  renderPersonalSafetyTitle() {
    Column() {
      Text($r('app.string.emergencyCall'))
        .maxLines(1)
        .fontSize(this.isNewFoldPhoneExternalScreen ? $r('sys.float.Title_M') : $r('sys.float.Title_L'))
        .maxFontScale(1)
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_on_primary'))
        .lineHeight(35)
        .flexShrink(0)
        .textAlign(TextAlign.Center)
        .width('100%')
        .height('100%')
    }
    .height(64)
    .padding({ top: 12, bottom: 12})
    .margin({left: 16, right: 16, top: 8})
  }

  @Builder
  renderTitle() {
    Text($r('app.string.emergencyCall'))
      .maxLines(1)
      .fontSize(this.isNewFoldPhoneExternalScreen ? $r('sys.float.Title_M') : $r('sys.float.Title_L'))
      .maxFontScale(1)
      .fontFamily('HarmonyHeiTi')
      .fontWeight(FontWeight.Bold)
      .fontColor($r('sys.color.font_on_primary'))
      .lineHeight(this.personalSafetyAccidentType !== 'none' ? 35 : (this.isNewFoldPhoneExternalScreen ? 32 : 40))
      .margin({ top: 8, bottom: this.isNewFoldPhoneExternalScreen ? 12 : 0 })
      .flexShrink(0)
      .padding({
        top: this.isNewFoldPhoneExternalScreen ? 0 : 12,
        bottom: this.isNewFoldPhoneExternalScreen ? 0 : 12
      })
  }

  @Builder
  renderEmergencyInfoButton() {
    Button() {
      Text($r('app.string.personalEmergencyInfo'))
        .fontColor($r('sys.color.font_on_primary'))
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Medium)
        .fontSize(16)
        .maxLines(1)
        .maxFontScale(1)
        .lineHeight(21);
    }
    .padding({ left: $r('app.float.emc_padding_level6'), right: $r('app.float.emc_padding_level6') })
    .height(40)
    .backgroundColor($r('app.color.emc_comp_background_tertiary'))
    .labelStyle({ maxFontSize: '16vp', minFontSize: this.fontSizeScale !== 0 ? '16vp' : '9vp' })
    .constraintSize({
      minWidth: $r('app.float.emc_padding_level100'),
      maxWidth: '100%'
    })
    .flexShrink(0)
    .onClick(() => {
      this.pathInfos.pushPathByName('EmergencyInfoView', '');
    })
    .margin({ top: this.personalSafetyAccidentType !== 'none' ? 44 : 0 })
  }

  @Builder
  renderSosEmergencyCall() {
    GridRow({ columns: { sm: 4, md: 8, lg: 12 }, gutter: { x: 24 } }) {
      GridCol({ span: { sm: 4, md: 6, lg: 8 }, offset: { md: 1, lg: 2 } }) {
        Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center }) {
          if (!this.isNewFoldPhoneExternalScreen || this.personalSafetyAccidentType !== 'none') {
            this.renderEmergencyInfoButton();
          }

          if (this.personalSafetyAccidentType !== 'none') {
            this.renderPersonalSafetyTitle();
          } else {
            this.renderTitle();
          }

          if (this.communicationNetworkType === CommunicationNetworkType.TIAN_TONG) {
            if (this.canAutoSendSosMessage && this.isRunningOfAutoSendSosMsg) {
              this.renderSubtitle($r('app.string.share_location_background_tips'), true);
            }
          } else if (this.abnormalTipOfTianTong && this.communicationNetworkType === CommunicationNetworkType.NONE) {
            this.renderSubtitle(this.abnormalTipOfTianTong, false);
          } else { //蜂窝通信网络提示
            this.renderSubTitleCommon()
          }

          this.renderSosEmergencyCallBody();

          if (this.personalSafetyAccidentType !== 'none') {
            this.renderPerosonalSafetyBottomButtons();
          } else if (!this.isNewFoldPhoneExternalScreen) {
            this.renderSosEmergencyCallBottom();
          }
        }
        .padding(this.personalSafetyAccidentType !== 'none' ? {} : {
          top: this.isNewFoldPhoneExternalScreen ? 0 : 8 + this.topStatusBarHeight,
          bottom: this.isNewFoldPhoneExternalScreen ? 0 : 13 + this.bottomRectHeight
        });
      };
    }
  }

  @Builder
  renderSubTitleCommon() {
    if (!this.isDeviceHasSim && this.emergencyContacts && this.emergencyContacts.length > 0 &&
      (this.autoSendSOSMessageSwitchState || this.autoAutoDialSOSNumberSwitchState)) {
      this.renderSubtitle($r('app.string.no_sim_message_and_call_unavailable'), false);
    } else if ((this.isEnableAirPlaneMode || !this.isHasNormalWorkSimCard) &&
    this.emergencyContacts && this.emergencyContacts.length > 0 &&
      (this.autoSendSOSMessageSwitchState || this.autoAutoDialSOSNumberSwitchState)) {
      this.renderSubtitle($r('app.string.no_service_message_and_call_unavailable'), false);
    } else if (this.canAutoSendSosMessage && this.isRunningOfAutoSendSosMsg) {
      this.renderSubtitle($r('app.string.share_location_background_tips'), true);
    }
  }

  @Builder
  renderSosEmergencyCallBottom() {
    Row() {
      if (this.emergencyNumberLisHeight > this.emergencyNumberScrollAreaHeight) {
        Row()
          .position({ top: -20 })
          .width('100%')
          .height(24)
          .linearGradient({
            angle: 180,
            colors: [['rgba(0, 0, 0, 0.00)', 0], ['rgba(0, 0, 0, 1)', 1]]
          })
          .responseRegion({
            x: 0,
            y: 0,
            width: '0%',
            height: '0%'
          });
      }

      this.renderBottomButtons();
    }
    .width('100%')
    .flexShrink(0)
  }

  @Builder
  renderNewFoldPhoneSosEmergencyCallBottom() {
    Stack() {
      Row() {
        Row()
          .position({ top: 0 })
          .width('100%')
          .height(112)
          .linearGradient({
            angle: 180,
            colors: [['rgba(0, 0, 0, 0)', 0], ['rgba(0, 0, 0, 0.6)', 1]]
          })
          .responseRegion({
            x: 0,
            y: 0,
            width: '0%',
            height: '0%'
          });

        this.renderBottomButtons();
      }
      .width('100%')
      .flexShrink(0)
    }
    .height(112)
    .padding({ bottom: 11 })
    .position({ bottom: 0 })
  }

  @Builder
  renderSosEmergencyCallBody() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: this.isNewFoldPhoneExternalScreen ? FlexAlign.Start : FlexAlign.End
    }) {
      Scroll(this.scroller) {
        Flex({ direction: FlexDirection.Column,
          justifyContent: this.personalSafetyAccidentType !== 'none' ? FlexAlign.End : FlexAlign.Center }) {
          this.renderEmergencyNumberList();

          if (this.emergencyContacts && this.emergencyContacts.length > 0) {
            Text($r('app.string.emergencyContact'))
              .margin({ top: 28, bottom: 8 })
              .fontSize($r('sys.float.Body_M'))
              .maxLines(1)
              .maxFontScale(1)
              .fontFamily('HarmonyHeiTi')
              .fontColor($r('sys.color.font_on_secondary'))
              .fontWeight(FontWeight.Medium)
              .width('100%')
              .lineHeight(19)
              .padding({ left: 12, right: 12 })
              .flexShrink(0);

            this.renderSosEmergencyContactList();
          }
        }
        .id(SosEmergencyCallController.EMERGENCY_NUMBER_LIST_ID)
      }
      .id(SosEmergencyCallController.EMERGENCY_NUMBER_SCROLL_AREA_ID)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .height('100%')

      if (this.isNewFoldPhoneExternalScreen) {
        this.renderNewFoldPhoneSosEmergencyCallBottom();
      }
    }
    .height(this.isNewFoldPhoneExternalScreen ? 'calc(100% - 40vp)' : '100%')
    .layoutWeight(1)
    .margin(this.personalSafetyAccidentType !== 'none' ? {
      top: '8vp',
      left: '16vp',
      right: '16vp'
    } :
      {
      top: this.isNewFoldPhoneExternalScreen ? 0 : 8,
      left: CallColumnUtils.getInstance().getPaddingSpace(this.curBp, false),
      right: CallColumnUtils.getInstance().getPaddingSpace(this.curBp, false)
    })
  }

  build() {
    Stack() {
      Column()
        .height('100%')
        .width('100%')
        .backgroundColor('#000000')
        .id('SosEmergencyCall_StackImage_background');

      Navigation(this.pathInfos) {
        if (this.mSystemModeController.getIsEnableSosOnSatelliteNet() || !this.satelliteModeSwitchStatus) {
          if (this.isDisplayCountdown) {
            if (this.personalSafetyAccidentType !== 'none') {
              PersonalSafetyCountdown({
                accidentType: this.personalSafetyAccidentType,
                setTimeOutIdOfCountdown: this.setTimeOutIdOfCountdown,
                onCountdownComplete: this.onPersonalSafetyCountdownComplete,
                exitSos: this.exitSosEmergencyCall,
              })
            } else {
              SosCountdown({
                autoSendSOSMessageSwitchState: this.autoSendSOSMessageSwitchState,
                emergencyContacts: this.emergencyContacts,
                setTimeOutIdOfCountdown: this.setTimeOutIdOfCountdown,
                onCountdownComplete: this.onCountdownComplete,
                exitSos: this.exitSosEmergencyCall
              })
            }
          } else {
            this.renderSosEmergencyCall();
          }
        }
      }
      .navDestination(this.myRouter)
      .mode(NavigationMode.Stack)
      .hideNavBar(false)
      //.titleMode(HdsNavigationTitleMode.MINI)
      //.titleMode(NavigationTitleMode.Mini)
      .hideTitleBar(true)
      .height('100%')
      .width('100%')
    }
    .height('100%')
    .width('100%')
  }
}

@Component
export struct ActiveListItem {
  listItem: EmergencyNumListStruct = getEmptyEmergencyListData();
  @Prop communicationNetworkType: CommunicationNetworkType = CommunicationNetworkType.NONE;

  aboutToAppear() {
    LogUtils.e(TAG, 'ActiveListItem aboutToAppear');
  }

  build() {
    Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
      SymbolGlyph(this.communicationNetworkType === CommunicationNetworkType.TIAN_TONG ?
      $r('sys.symbol.phone_badge_satellite_fill') : $r('sys.symbol.chevron_right'))
        .fontSize('32vp')
        .fontColor([$r('sys.color.icon_on_primary')])
        .margin({ end: LengthMetrics.resource($r('sys.float.padding_level2')) })
        .id(`EmergencyCommunication_pages_index_ActiveListItem_rowImage_next_white_${this.listItem.id}`)

      Text($r('app.string.rightCall', this.listItem.value))
        .fontSize('24vp')
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_on_primary'))
        .lineHeight('32vp')
        .id(`EmergencyCommunication_pages_index_ActiveListItem_rowText_rightCall_${this.listItem.id}`)
    }
    .padding({
      top: $r('sys.float.padding_level8'),
      bottom: $r('sys.float.padding_level8'),
      left: $r('sys.float.padding_level6'),
      right: $r('sys.float.padding_level6')
    })
  }
}

@Component
export struct SosButton {
  @Prop buttonImage: Resource;
  buttonText: Resource | string = '';
  @Prop buttonBackgroundColor: string | Resource | null = null;
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  isSymbol: boolean = false;
  @StorageProp('currentColorMode') currentColorMode: ConfigurationConstant.ColorMode | undefined = undefined;

  onButtonClick = () => {
  }

  aboutToAppear(): void {
    LogUtils.i('SosButton', 'aboutToAppear')
  }

  build() {
    Column() {
      Row() {
        if (this.isSymbol) {
          SymbolGlyph(this.buttonImage)
            .fontColor([$r('sys.color.icon_on_primary')])
            .fontSize($r('app.float.emc_widthLevel14'))
            .fontWeight(FontWeight.Medium)
        } else {
          Image(this.buttonImage)
            .fillColor($r('sys.color.icon_on_primary'))
            .width(28)
            .height(28)
        }
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .width(this.isNewFoldPhoneExternalScreen ? 56 : 64)
      .height(this.isNewFoldPhoneExternalScreen ? 56 : 64)
      .borderRadius(this.isNewFoldPhoneExternalScreen ? 28 : 32)
      .backgroundColor(this.buttonBackgroundColor ? this.buttonBackgroundColor :
        (this.currentColorMode !== ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
        $r('app.color.icon_tertiary_dark') : $r('sys.color.icon_tertiary')))
      .backgroundEffect(this.buttonBackgroundColor ? null : {
        radius: 120,
        saturation: 1.1,
        brightness: 1.0,
        color: '#0CFFFFFF'
      })
      .onTouch(e => {
        e.stopPropagation();
      })

      Text(this.buttonText)
        .fontSize($r('sys.float.Body_M'))
        .maxFontScale(1)
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .fontColor($r('sys.color.font_on_secondary'))
        .lineHeight(19)
        .margin({ top: this.isNewFoldPhoneExternalScreen ? 2 : 4 });
    }
    .accessibilityRole(AccessibilityRoleType.BUTTON)
    .onClick((e) => {
      LogUtils.i('SosButton', 'onIconClick')
      this.onButtonClick();
    });
  }
}
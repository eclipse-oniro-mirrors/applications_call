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
import commonEvent from '@ohos.commonEventManager';
import { ContactListStruct } from '../utils/ClassStruct';
import LogUtils from '../utils/HiLog';
import { BusinessError, commonEventManager, settings } from '@kit.BasicServicesKit';
import { call, observer, sim } from '@kit.TelephonyKit';
import { AudioParams, AudioUtil } from '../utils/AudioUtil';
import { VibratorUtil } from '../utils/VibratorUtil';
import { common } from '@kit.AbilityKit';
import { inspector } from '@kit.ArkUI';
import { AudioPlayerService } from '../service/AudioPlayerService';
import { SosEmergencySmsController } from './SosEmergencySmsController';
import { radio } from '@kit.TelephonyKit';
import { SatelliteUtil, START_TIAN_TONG_SWITCH, } from '../utils/SatelliteUtil';
import CommonData, { CommonEvent, CommunicationNetworkType } from '../data/CommonData';
import { SystemModeController } from './SystemModeController';
import { removeTianTongConnectStateListener } from '../model/SatelliteModel';
import { ABNORMAL_TIP_OF_TIAN_TONG } from '../pages/SosEmergencyCall';
import { JSON } from '@kit.ArkTS';
import { isObjectJSONString } from '../utils/StringUtil';
import { ABILITY_STATE_KEY, ABILITY_STATE_ON_BACKGROUND } from '../sosemergencycallability/SOSEmergencyCallAbility';
import { PERSONAL_SAFETY_ACCIDENT_TYPE } from '../utils/Constants';

/**
 * 向CallSetting请求打开天通卫星开关的返回结果
 */
interface OpenTianTongSwitchResult {
  /** 开关是否成功打开 */
  result: boolean;

  /** 异常提示 */
  message: string;

  /** 错误信息 */
  errorMessage: string;
}

/**
 * 若当前有从SOS界面给紧急联系人拨出的通话，点击该紧急联系人，在拉起通话界面后，
 * 通话状态的extraParams.sosWithOutCallUiAbility为'2'
 */
export const DISPLAY_CALL_PAGE_VALUE_OF_EXTRA_PARAMS = '2'

const TAG = 'SosEmergencyCallController';

export class SosEmergencyCallController {
  private static sInstance: SosEmergencyCallController | null;
  private static readonly SOS_EMERGENCY_CALL_ABILITY_PAGE_CHANGE_EVENT =
    'emergencycommunication.event.SOS_EMERGENCY_CALL_ABILITY_PAGE_CHANGE';
  public static readonly SOS_IS_HAS_NORMAL_WORK_SIM_CARD = 'sosEmergencyCall_isHasNormalWorkSimCard';
  public static readonly CURRENT_EMERGENCY_CONTACTS_INDEX_KEY = 'SosEmergencyCall_currentEmergencyContactsIndex';
  public static readonly IS_BEE_BUZZ_ALARM_ACTIVE_KEY = 'SosEmergencyCall_isBeeBuzzAlarmActive';
  public static readonly EMERGENCY_CONTACTS_KEY = 'SosEmergencyCall_emergencyContacts';
  /**
   * 自动拨打电话过程中给紧急联系人拨号后设置的定时器的id,
   * 定时器超时后挂断当前的SOS通话，给下一个紧急联系人拨号
   */
  public timerIdOfSosCallWaitTime: number | null = null;
  public timeOutIdOfCountdown: number | null = null;
  public static readonly EMERGENCY_NUMBER_LIST_ID = 'SosEmergencyCall_emergencyNumberListId';
  public static readonly EMERGENCY_NUMBER_SCROLL_AREA_ID = 'SosEmergencyCall_emergencyNumberScrollArea';
  public listenerOfEmergencyNumberList: inspector.ComponentObserver =
    inspector.createComponentObserver(SosEmergencyCallController.EMERGENCY_NUMBER_LIST_ID);
  public listenerOfEmergencyNumberScrollArea: inspector.ComponentObserver =
    inspector.createComponentObserver(SosEmergencyCallController.EMERGENCY_NUMBER_SCROLL_AREA_ID);
  public isCompletedAutoDialCall: boolean = false;
  public canAutoDialSosCall: boolean = false;
  public isHangUpSosCallActively: boolean = false;
  private observerCallStateChangeReference: ((data: observer.CallStateInfo) => void) | null = null;
  public isContinueDialCallNextContact = false;
  /** 紧急通信应用是否打开过天通卫星开关 */
  public isTurnedOnTianTongSwitch = false;
  /** SOS紧急求助界面是否因显示通话界面而退到后台 */
  public isDisplayCallUi: boolean | null = null;

  constructor() {
  }


  public static getInstance() {
    if (SosEmergencyCallController.sInstance == null) {
      SosEmergencyCallController.sInstance = new SosEmergencyCallController();
    }
    return SosEmergencyCallController.sInstance;
  }

  public static resetInstance() {
    SosEmergencyCallController.sInstance = new SosEmergencyCallController();
  }

  public static destroyInstance() {
    SosEmergencyCallController.sInstance = null;
  }

  /**
   * 取消 自动拨打电话过程中给紧急联系人拨号后设置的等待定时器
   */
  public clearTimerIdOfSosCallWaitTime = () => {
    LogUtils.i(TAG, 'clearTimerIdOfSosCallWaitTime');
    if (!this.timerIdOfSosCallWaitTime) {
      return;
    }
    try {
      clearTimeout(this.timerIdOfSosCallWaitTime);
      this.timerIdOfSosCallWaitTime = null;
    } catch (e) {
      LogUtils.e(TAG, `clearTimerIdOfSosCallWaitTime error: ${e?.code} ${e?.message}`);
    }
  }

  public static isDeviceHasSimSync(isRequestEmergencyNumber: boolean): boolean {
    if (!canIUse('SystemCapability.Telephony.CoreService')) {
      return false;
    }
    try {
      const hasSimCardOne = sim.hasSimCardSync(0);
      const hasSimCardTwo = sim.hasSimCardSync(1);

      if (isRequestEmergencyNumber) {
        AppStorage.setOrCreate('simOperatorNameFirst', hasSimCardOne);
        AppStorage.setOrCreate('simOperatorNameSecond', hasSimCardTwo);
      }
      return hasSimCardOne || hasSimCardTwo;
    } catch (e) {
      LogUtils.e(TAG, `isDeviceHasSimSync error: ${e?.code} ${e?.message}`);
      return false;
    }
  }

  /**
   * 查找正常工作的SIM卡
   * @param excludedSlotId 排除查找的卡槽id
   * @param isCheckSimRegStatue 是否检查SIM卡的网络注册状态
   */
  private static findNormalWorkSimCard = async (excludedSlotId?: number, isCheckSimRegStatue = true) => {
    LogUtils.i(TAG, `findNormalWorkSimCard: isCheckSimRegStatue ${isCheckSimRegStatue}`);
    try {
      const simCardNum = sim.getMaxSimCount();
      if (!simCardNum || simCardNum <= 0) {
        return null;
      }
      // 遍历卡槽中SIM卡状态，如果为SIM_STATE_READY或者SIM_STATE_LOADED则返回slotid并且能正常拨打电话
      for (let i = 0; i < simCardNum; i++) {
        if (excludedSlotId === i) {
          continue;
        }
        const simState = sim.getSimStateSync(i);
        LogUtils.i(TAG, `simState ${simState.valueOf()}, soltID is ${i}}`);
        if (isCheckSimRegStatue) {
          let simRegstatue = await SosEmergencyCallController.checkSimRegstatue(i);
          if ((simState === sim.SimState.SIM_STATE_READY || simState === sim.SimState.SIM_STATE_LOADED) &&
            simRegstatue) {
            return i;
          }
        } else if (simState === sim.SimState.SIM_STATE_READY || simState === sim.SimState.SIM_STATE_LOADED) {
          return i;
        }
      }
      return null;
    } catch (e) {
      LogUtils.e(TAG, `findNormalWorkSimCard error: ${JSON.stringify(e)}`);
      return null;
    }
  }

  private static async checkSimRegstatue(slotId: number): Promise<boolean> {
    try {
      let networkStatus = await radio.getNetworkState(slotId);
      LogUtils.i(TAG, `checkSimRegstatue: slotId ${slotId}, simRegstatue is ${networkStatus.regState.valueOf()}`);
      return networkStatus.regState === radio.RegState.REG_STATE_IN_SERVICE;
    } catch (err) {
      LogUtils.i(TAG, `getNetworkState error ${err.code}`)
      return true;
    }
  }

  private static setIsHasNormalWorkSimCard = (value: boolean) => {
    AppStorage.setOrCreate<boolean>(SosEmergencyCallController.SOS_IS_HAS_NORMAL_WORK_SIM_CARD, value);
  }
  /**
   * 获取当前设备中正常工作的sim卡
   * 双卡场景下优先使用默认拨号卡，没有的话按卡1->卡2的顺序
   * 校验sim状态和sim卡是否激活
   * @param isCheckSimRegStatue 是否检查SIM卡的网络注册状态
   * @returns SimCard slotId
   */
  public static getNormalWorkSimCard = async (isCheckSimRegStatue = true): Promise<number | null> => {
    LogUtils.i(TAG, `getNormalWorkSimCard start, isCheckSimRegStatue ${isCheckSimRegStatue}`);

    if (!canIUse('SystemCapability.Telephony.CoreService')) {
      SosEmergencyCallController.setIsHasNormalWorkSimCard(false);
      return null;
    }

    let defaultSlotId: number | null = null;
    try {
      // 获取默认拨号卡
      defaultSlotId = await sim.getDefaultVoiceSlotId()
        .catch((err: BusinessError) => {
          LogUtils.e(TAG, `getDefaultVoiceSlotId failed, promise: err->${JSON.stringify(err)}`);
          return null;
        });
    } catch (e) {
      LogUtils.e(TAG, `getNormalWorkSimCard: getDefaultVoiceSlotId error: ${JSON.stringify(e)}`);
      defaultSlotId = null;
    }
    LogUtils.i(TAG, `getNormalWorkSimCard defaultSlotId: ${defaultSlotId}`);

    let simCardSlotId: null | number = null;
    if (defaultSlotId !== null && defaultSlotId >= 0) {
      // 获取默认拨号的SIM卡状态
      const simState = sim.getSimStateSync(defaultSlotId);
      if (isCheckSimRegStatue) {
        let simRegstatue = await SosEmergencyCallController.checkSimRegstatue(defaultSlotId);
        if ((simState === sim.SimState.SIM_STATE_READY || simState === sim.SimState.SIM_STATE_LOADED) && simRegstatue) {
          simCardSlotId = defaultSlotId;
        } else {
          simCardSlotId = await SosEmergencyCallController.findNormalWorkSimCard(defaultSlotId, isCheckSimRegStatue);
        }
      } else if (simState === sim.SimState.SIM_STATE_READY || simState === sim.SimState.SIM_STATE_LOADED) {
        simCardSlotId = defaultSlotId;
      } else {
        simCardSlotId = await SosEmergencyCallController.findNormalWorkSimCard(defaultSlotId, isCheckSimRegStatue);
      }
    } else {
      simCardSlotId = await SosEmergencyCallController.findNormalWorkSimCard(undefined, isCheckSimRegStatue);
    }
    SosEmergencyCallController.setIsHasNormalWorkSimCard((simCardSlotId == null) ? false : true);
    return simCardSlotId;
  }

  public static async shakeDeviceOnce() {
    await VibratorUtil.startVibration(250);
  }

  public static async shakeDeviceContinuous(time: number) {
    await VibratorUtil.startVibration(time);
  }

  public static async terminateSelfUIAbility(context: common.UIAbilityContext) {
    if (!context) {
      return;
    }

    try {
      context.terminateSelf()
        .then(() => {
          LogUtils.i(TAG, 'terminateSelf succeed');
        })
        .catch((err: BusinessError) => {
          LogUtils.e(TAG, `terminateSelf failed, code is ${err.code}, message is ${err.message}`);
        });
    } catch (err) {
      let code = (err as BusinessError).code;
      let message = (err as BusinessError).message;
      LogUtils.e(TAG, `terminateSelf failed, code is ${code}, message is ${message}`);
    }
  }

  public static getIsEnableAirPlaneModeSync(context: Context): boolean {
    LogUtils.i(TAG, `getIsEnableAirPlaneModeSync`);
    try {
      const value =
        settings.getValueSync(context, 'settings.telephony.airplanemode', '0');
      const isEnableAirPlaneMode = value === '1';
      return isEnableAirPlaneMode;
    } catch (e) {
      LogUtils.e(TAG, `get isAirPlaneMode failed, error: ${JSON.stringify(e)}`);
      return false;
    }
  }

  /**
   * After invoking this API, must invoke 'recoveryAudioNormal'.
   */
  public async muteAudio() {
    LogUtils.i(TAG, 'muteAudio');
    try {
      // So that that recording can only be played to the opposite end of the call
      await AudioUtil.setCallAudioParameters({
        [AudioParams.AUDIO2VOICE]: 'true'
      });
      await AudioUtil.setCallAudioParameters({
        [AudioParams.INPUT_MUTE]: 'true',
        [AudioParams.OUTPUT_MUTE]: 'true'
      });
    } catch (e) {
      LogUtils.e(TAG, `muteAudio error: ${JSON.stringify(e)}`)
    }
  }

  public async recoveryAudioNormal() {
    LogUtils.i(TAG, 'recoveryAudioNormal');
    try {
      await AudioUtil.setCallAudioParameters({
        [AudioParams.AUDIO2VOICE]: 'false'
      });
      await AudioUtil.setCallAudioParameters({
        [AudioParams.INPUT_MUTE]: 'false',
        [AudioParams.OUTPUT_MUTE]: 'false'
      });
    } catch (e) {
      LogUtils.e(TAG, `muteAudio error: ${JSON.stringify(e)}`)
    }
  }

  public cancelSubscribeCallDetailsChange() {
    LogUtils.i(TAG, `cancelSubscribeCallDetailsChange`);
    try {
      call.off('callDetailsChange');
    } catch (e) {
      LogUtils.e(TAG, `cancelSubscribeCallDetailsChange error: ${JSON.stringify(e)}`);
    }
  }

  /**
   * Notify "multiModalInput" SosEmergency page change.
   * @param pageName
   */
  public publishEventToTellPageName(pageName: 'SosCountdown' | 'SosEmergencyCall' | 'PersonalSafetyCountdown' | 'None') {
    LogUtils.i(TAG, `publishEventToTellPageName: pageName ${pageName}`);
    const options: commonEventManager.CommonEventPublishData = {
      code: 100,
      isOrdered: false,
      isSticky: false,
      parameters: {
        pageName: pageName
      },
      subscriberPermissions: ['ohos.permission.GET_TELEPHONY_STATE']
    };
    const event = SosEmergencyCallController.SOS_EMERGENCY_CALL_ABILITY_PAGE_CHANGE_EVENT;
    try {
      commonEventManager.publish(event, options, err => {
        if (err) {
          LogUtils.e(TAG, `publishEventToTellPageName publish event error: ${err.code}, message is ${err.message}`);
        } else {
          LogUtils.i(TAG, 'publishEventToTellPageName publish CommonEvent' + options.code);
        }
      });
    } catch (err) {
      LogUtils.e(TAG, `publishEventToTellPageName publish event error: ${err.code}, message is ${err.message}`);
    }
  }

  /**
   * 重置SOS紧急求助功能
   * 会中断倒计时3秒的震动、自动拨打求助电话功能、蜂鸣警报、自动发送求助信息功能
   * 重置以上场景的变量和监听函数
   * @param context
   * @param isClearCurrentEmergencyContactsIndex 是否清除currentEmergencyContactsIndex
   * (即在正在进行的sos通话对应的联系人在紧急联系人列表的索引值)
   */
  public resetEmergencyCall = async (context: Context, isClearCurrentEmergencyContactsIndex = true) => {
    try {
      const promise1 = this.resetAutoDialSosCall(isClearCurrentEmergencyContactsIndex);
      const promise2 = VibratorUtil.stopAllVibration();
      const promise3 = this.stopBeeBuzzAlarm();
      await Promise.allSettled([promise1, promise2, promise3]);
      SosEmergencySmsController.getInstance().stopAutoSendSosMessage();
      if (SystemModeController.getInstance().getIsEnableSosOnSatelliteNet()) {
        SosEmergencyCallController.releaseSatelliteNetDataOfSosEmergencyCall(context);
      }
      this.isCompletedAutoDialCall = false;
    } catch (e) {
      LogUtils.e(TAG, `resetEmergencyCall error: ${e?.code} ${e?.message}`);
    }
  }
  /**
   * 销毁SOS求助界面所在的UIAbility
   */
  public terminateEmergencyCall = async (context: common.UIAbilityContext) => {
    await this.resetEmergencyCall(context);
    SosEmergencyCallController.terminateSelfUIAbility(context as common.UIAbilityContext);
  }
  public playBeeBuzzAlarm = async () => {
    LogUtils.i(TAG, 'playBeeBuzzAlarm');
    await AudioUtil.getInstance().setMaxVolumeOfMedia();
    AudioPlayerService.getInstance().startPlayBeeBuzzAlarm();
  }
  public stopBeeBuzzAlarm = async () => {
    LogUtils.i(TAG, 'stopBeeBuzzAlarm');
    AppStorage.setOrCreate<boolean>(SosEmergencyCallController.IS_BEE_BUZZ_ALARM_ACTIVE_KEY, false);
    await AudioPlayerService.getInstance().destroyAvPlayerOfBeeBuzz();
    await AudioUtil.getInstance().recoverMediaVolume();
  }

  /**
   * 根据item重置紧急联系人列表项数据
   * @param index
   * @param item
   */
  public static resetEmergencyContactsItem(index: number, item: ContactListStruct) {
    const newItem: ContactListStruct = ContactListStruct.getDeepCopy(item);
    const emergencyContacts =
      AppStorage.get<ContactListStruct[]>(SosEmergencyCallController.EMERGENCY_CONTACTS_KEY);
    if (emergencyContacts) {
      emergencyContacts[index] = newItem as ContactListStruct;
      AppStorage.setOrCreate<ContactListStruct[]>(SosEmergencyCallController.EMERGENCY_CONTACTS_KEY, emergencyContacts);
    }
  }

  /**
   * 重置自动拨打求助电话功能
   * @param isClearCurrentEmergencyContactsIndex 是否清除currentEmergencyContactsIndex
   * (即在正在进行的sos通话的联系人在紧急联系人列表的index)
   */
  public async resetAutoDialSosCall(isClearCurrentEmergencyContactsIndex = true) {
    LogUtils.i(TAG, `resetAutoDialSosCall`);
    try {
      const emergencyContacts = AppStorage.get<ContactListStruct[]>(SosEmergencyCallController.EMERGENCY_CONTACTS_KEY);
      if (emergencyContacts && emergencyContacts.length > 0) {
        for (let i = 0; i < emergencyContacts.length; i++) {
          let item = ContactListStruct.getDeepCopy(emergencyContacts[i]);
          if (item?.callType === 'sosCall' && (typeof item.callId === 'number')) {
            LogUtils.i(TAG, `resetAutoDialSosCall: hangUpCallByCallId`);
            this.hangUpCallByCallId(item.callId);
            item.callId = null;
            item.callType = undefined;
            item.callState = null;
          }
          emergencyContacts[i] = item;
        }
        AppStorage.setOrCreate<ContactListStruct[]>(SosEmergencyCallController.EMERGENCY_CONTACTS_KEY,
          emergencyContacts);
      }
      if (isClearCurrentEmergencyContactsIndex) {
        AppStorage.setOrCreate<number | null>(SosEmergencyCallController.CURRENT_EMERGENCY_CONTACTS_INDEX_KEY, null);
      }
      this.clearTimerIdOfSosCallWaitTime();
      await AudioPlayerService.getInstance().destroyAvPlayerOfSos();
      await this.recoveryAudioNormal();
    } catch (e) {
      LogUtils.e(TAG, `resetAutoDialSosCall error: ${e?.code} ${e?.message}`);
    }
  }

  public async hangUpCallByCallId(callId: number) {
    LogUtils.i(TAG, `hangUpCallByCallId`);
    if (typeof callId !== 'number') {
      return;
    }

    try {
      await call.hangUpCall(callId).catch((e: BusinessError) => {
        LogUtils.e(TAG, `hangUpCallByCallId error ${JSON.stringify(e)}`);
      });
    } catch (e) {
      LogUtils.e(TAG, `hangUpCallByCallId error: ${JSON.stringify(e)}`);
    }
  }

  public async endAutoDialSosCallByCallId(callId: number) {
    LogUtils.i(TAG, 'endAutoDialSosCallByCallId');
    this.isHangUpSosCallActively = true;
    await this.endDialSosCall();
    this.hangUpCallByCallId(callId);
  }

  public async endDialSosCall() {
    this.isCompletedAutoDialCall = true;
    this.isContinueDialCallNextContact = false;
    const emergencyContacts = AppStorage.get<ContactListStruct[]>(SosEmergencyCallController.EMERGENCY_CONTACTS_KEY);
    this.resetEmergencyContactsCallProperty(emergencyContacts);
    AppStorage.setOrCreate<number | null>(SosEmergencyCallController.CURRENT_EMERGENCY_CONTACTS_INDEX_KEY, null);
    await AudioPlayerService.getInstance().destroyAvPlayerOfSos();
    this.recoveryAudioNormal();
  }

  public displaySpecifiedCallPageByCallId = async (callId: number) => {
    LogUtils.i(TAG, `displaySpecifiedCallPageByCallId`);
    try {
      call.sendCallUiEvent(callId, 'DISPLAY_SPECIFIED_CALL_PAGE_BY_CALL_ID');
    } catch (e) {
      LogUtils.e(TAG, `displaySpecifiedCallPageByCallId: err: ${JSON.stringify(e)}`);
    }
  }

  private resetEmergencyContactsCallProperty(emergencyContacts: ContactListStruct[] | undefined) {
    if (emergencyContacts && emergencyContacts.length > 0) {
      for (let i = 0; i < emergencyContacts.length; i++) {
        let item = ContactListStruct.getDeepCopy(emergencyContacts[i]);
        if (item?.callType === 'sosCall' && (typeof item.callId === 'number')) {
          item.callId = null;
          item.callType = undefined;
          item.callState = null;
        }
        emergencyContacts[i] = item;
      }
      AppStorage.setOrCreate<ContactListStruct[]>(SosEmergencyCallController.EMERGENCY_CONTACTS_KEY, emergencyContacts);
    }
  }

  /**
   * 在紧急联系人列表中重置指定索引的联系人的SOS通话状态
   * @param emergencyContacts
   * @param index
   */
  public resetEmergencyContactsCallPropertyByIndex(emergencyContacts: ContactListStruct[] | undefined,
    index: number | null) {
    if (emergencyContacts && emergencyContacts.length > 0 && index !== null) {
      let item: ContactListStruct = emergencyContacts[index];
      item.callId = null;
      item.callType = undefined;
      item.callState = null;
      SosEmergencyCallController.resetEmergencyContactsItem(index, item);
    }
  }

  /**
   * 判断当前是否连接上蜂窝网络
   * @param isDeviceHasSim
   * @returns
   */
  private static async getIsConnectedCellularNetwork(isDeviceHasSim: boolean) {
    if (!isDeviceHasSim) {
      return false;
    }
    let simCardSlotId = await SosEmergencyCallController.findNormalWorkSimCard();
    if (simCardSlotId === null) {
      return false;
    }
    return true;
  }

  /**
   * 获取当前设备是否支持天通卫星特性
   */
  public static getIsSupportTianTongSatellite = (): boolean => {
    return SatelliteUtil.getIsDeviceSupportTianTongSatellite();
  }
  /**
   * 向CallSetting请求打开天通卫星开关
   * @param context Context
   * @param retryInitFunction 连接ServiceExtAbility时权限校验失败的失败重试函数
   */
  public static requestToOpenTianTongSwitch = (context: Context, retryInitFunction: () => void): Promise<boolean> => {
    return new Promise((resolve, reject) => {
      //先连接CallSetting应用的SatelliteServiceExtAbility
      SatelliteUtil.getInstance().connectCallSettingSatelliteServiceExtAbility(context, (errorCode) => {
        if (['201', '2097177'].includes(String(errorCode))) { //权限校验失败错误码
          // 此时可能由于页面处于后台导致没有权限连上ServiceExtAbility, 在下次onPageShow的时候重试一次
          retryInitFunction();
        }
        resolve(false);
      }, async (proxy) => {
        if (!proxy) {
          LogUtils.e(TAG, `requestToOpenTianTongSwitch: SatelliteServiceExtAbility proxy empty`);
          resolve(false);
          return;
        }
        let res = await SatelliteUtil.requestToCallSettingService(proxy, START_TIAN_TONG_SWITCH, '');
        if (!res || res.code !== CommonData.int['SUCCESS']) {
          LogUtils.e(TAG, `requestToOpenTianTongSwitch: request START_TIAN_TONG_SWITCH failed`);
          resolve(false);
          return;
        }
        let resultString: string = res.result ?? '';
        if (!isObjectJSONString(resultString)) {
          LogUtils.e(TAG, `requestToOpenTianTongSwitch: resultString is not normal`);
          resolve(false);
          return;
        }
        let result = JSON.parse(resultString) as OpenTianTongSwitchResult;
        if (result.result === true) {
          resolve(true);
        } else {
          //若打开天通卫星失败，保存返回的失败原因
          AppStorage.setOrCreate(ABNORMAL_TIP_OF_TIAN_TONG, result.message ?? '');
          LogUtils.e(TAG, `requestToOpenTianTongSwitch failed, errorMessage: ${result.errorMessage}`);
          resolve(false);
        }
      });
    })
  }
  private delay = (ms: number): Promise<void> => {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
  /**
   * 获取当前通信网络连接类型
   * @param context
   * @param isDeviceHasSim 设备是否有sim卡
   * @param tianTongSatelliteSwitchState 天通卫星开关是否开启
   * @param retryInitFunction 连接ServiceExtAbility时报错的失败重试函数
   */
  public getCommunicationNetworkType = async (context: Context, isDeviceHasSim: boolean,
    tianTongSatelliteSwitchState: boolean, retryInitFunction: () => void) => {
    //1）当天通卫星开关打开时，此时天通卫星已经连接或者正在寻星，使用天通卫星通信网络；
    if (tianTongSatelliteSwitchState) {
      return CommunicationNetworkType.TIAN_TONG;
    }
    // 2）天通卫星开关关闭，蜂窝通信网络有信号时，使用蜂窝通信网络；
    //判断sim状态，有正常工作的sim卡则为蜂窝网络类型
    let isConnectedCellular = await SosEmergencyCallController.getIsConnectedCellularNetwork(isDeviceHasSim);
    if (isConnectedCellular) {
      return CommunicationNetworkType.CELLULAR;
    }

    // 3）天通卫星开关关闭，蜂窝通信网络没有信号时，SOS紧急求助界面，如果当前设备支持天通卫星特性，
    // SOS与callSetting通信（通过IPC通信），去打开天通卫星开关。成功打开天通卫星开关后，使用天通卫星通信网络；
    let isSupportTianTongSatellite: boolean = SosEmergencyCallController.getIsSupportTianTongSatellite();
    LogUtils.w(TAG, `getCommunicationNetworkType: isSupportTianTongSatellite ${isSupportTianTongSatellite}`);
    try {
      if (isSupportTianTongSatellite) {
        let res = await SosEmergencyCallController.requestToOpenTianTongSwitch(context, retryInitFunction);
        if (res) {
          this.isTurnedOnTianTongSwitch = true;
          return CommunicationNetworkType.TIAN_TONG;
        }
      }
    } catch (e) {
      LogUtils.e(TAG, `getCommunicationNetworkType requestToOpenTianTongSwitch error: ${e?.code} ${e?.message}`);
    }

    //否则没有通信网络
    return CommunicationNetworkType.NONE;
  }
  /**
   * 发布公共事件通知CallSetting拉起天通卫星寻星弹窗
   */
  public static publishActionSatelliteConnectEventOfTianTong = () => {
    LogUtils.i(TAG, 'publishActionSatelliteConnectEventOfTianTong, start');
    try {
      commonEvent.publish(CommonEvent.SATELLITE_SUBSCRIBER_CONNECT_EVENT, {
        subscriberPermissions: ['ohos.permission.SET_TELEPHONY_STATE'],
        isOrdered: false,
      }, () => {
      });
    } catch (e) {
      LogUtils.e(TAG, `publishActionSatelliteConnectEventOfTianTong error: ${e?.code} ${e?.message}`);
    }
  }
  /**
   * 获取slotId对应的sim卡的注册网络所在国家的ISO国家码。
   */
  private static getISOCountryCodeForNetwork = (slotId: number) => {
    try {
      let countryISO: string = radio.getISOCountryCodeForNetworkSync(slotId);
      return countryISO ? countryISO.toUpperCase() : null;
    } catch (e) {
      LogUtils.e(TAG, `getISOCountryCodeForNetwork error: ${e?.code} ${e?.message}`);
      return null;
    }
  }
  /**
   * 获取卡1和卡2的注册网络所在国家的ISO国家码列表
   */
  public static getIsoCodeListFromSim = () => {
    let cardOne: string | undefined = AppStorage.get('simOperatorNameFirst');
    let cardTwo: string | undefined = AppStorage.get('simOperatorNameSecond');
    LogUtils.i(TAG, `getIsoCodeListFromSim cardOne：${cardOne},cardTwo：${cardTwo}`);
    let isoOfSimOne = cardOne ? this.getISOCountryCodeForNetwork(0) : null;
    let isoOfSimTwo = cardTwo ? this.getISOCountryCodeForNetwork(1) : null;

    let tempList: string[] = []
    if (isoOfSimOne && isoOfSimTwo && isoOfSimOne === isoOfSimTwo) {
      LogUtils.i(TAG, 'getIsoCodeListFromSim: isoCodes same');
      tempList.push(isoOfSimOne);
    } else {
      if (isoOfSimOne) {
        tempList.push(isoOfSimOne);
      }
      if (isoOfSimTwo) {
        tempList.push(isoOfSimTwo);
      }
    }
    return tempList
  }
  /**
   * 获取设备当前是否有已激活的sim卡
   */
  public static isHasSimActive = () => {
    try {
      const simCardNum = sim.getMaxSimCount();

      if (!simCardNum || simCardNum <= 0) {
        return false;
      }
      for (let i = 0; i < simCardNum; i++) {
        if (sim.isSimActiveSync(i)) {
          return true;
        }
      }
    } catch (e) {
      LogUtils.e(TAG, `isHasSimActive error: ${e?.code} ${e?.message}`);
    }
    return false;
  }
  /**
   * 释放天通卫星网络下SOS紧急求助功能的相关数据
   * 主要是一些状态监听函数
   */
  public static releaseSatelliteNetDataOfSosEmergencyCall = (context: Context) => {
    try {
      removeTianTongConnectStateListener();
    } catch (e) {
      LogUtils.e(TAG, `releaseSatelliteNetDataOfSosEmergencyCall error: ${e?.code} ${e?.message}`);
    }
  }

  /**
   * 检查SosEmergencyCallAbility的前后台状态, 在非车祸或跌倒场景即主动拉起SOS求助界面场景下;
   * @returns true 检查成功; false 检查失败
   */
  public static checkSosEmergencyCallAbilityState(uiContext: UIContext | null): boolean {
    if (!uiContext) {
      LogUtils.e(TAG, 'checkSosEmergencyCallAbilityState: uiContext empty, unable to check');
      return true;
    }
    try {
      const localStorage = uiContext?.getSharedLocalStorage();
      let personalSafetyAccidentType = localStorage?.get<string>(PERSONAL_SAFETY_ACCIDENT_TYPE);
      LogUtils.i(TAG, `checkSosEmergencyCallAbilityState: personalSafetyAccidentType ${personalSafetyAccidentType}`);
      if (!personalSafetyAccidentType || personalSafetyAccidentType === 'none') { //非车祸或跌倒场景即主动拉起SOS界面的场景
        let abilityState = AppStorage.get<string>(ABILITY_STATE_KEY);
        LogUtils.i(TAG, `checkSosEmergencyCallAbilityState: abilityState ${abilityState}`);
        if (abilityState === ABILITY_STATE_ON_BACKGROUND) {
          return false;
        }
      }
    } catch (e) {
      LogUtils.e(TAG, `checkSosEmergencyCallAbilityState error: ${e?.code} ${e?.message}`);
    }
    return true;
  }
}

/**
 * 判断是否存在通话
 * @returns boolean 返回判断是否存在通话。返回true表示当前存在通话，false表示当前不存在通话。
 */
export const hasCallSync = (): boolean => {
  try {
    return call.hasCallSync();
  } catch (e) {
    LogUtils.e(TAG, `hasCallSync error: ${e?.code} ${e?.message}`);
    return false;
  }
}
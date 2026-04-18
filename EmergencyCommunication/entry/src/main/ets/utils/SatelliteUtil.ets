/**
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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
import { BusinessError, settings } from '@kit.BasicServicesKit';
import SystemParameterEnhance from '@ohos.systemParameterEnhance';
import LogUtils from './HiLog';
import { common } from '@kit.AbilityKit';
import { rpc } from '@kit.IPCKit';
import CommonData, { ReturnResult } from '../data/CommonData';
import { getSatelliteHardwareSupportInfo } from './SatelliteServiceApi';

/**
 * 天通卫星开关是否启用
 */
export const TIAN_TONG_SATELLITE_MODE_KEY = 'satellite_mode_switch';

const TIAN_TONG_SATELLITE_SWITCH_ON = '1.0';
const TIAN_TONG_SATELLITE_SWITCH_OFF = '0.0';

export const TIAN_TONG_CONNECT_STATE_KEY = 'isTianTongSatelliteConnected';

/**  天通卫星注册sim卡的卡槽Id保存在settingsData的key */
export const TIAN_TONG_SLOT_KEY = 'satellite_slot_id';

const SATELLITE_KEY = 'const.telephony.satellite.support_type';
const DANDELION = 0b00000100;
const CACTUS = 0b00001000;
const TYPE_CACTUS: number = 3;
/** 打开天通卫星开关 */
export const START_TIAN_TONG_SWITCH = 1;
/** 恢复天通卫星开关 */
export const RESTORE_TIAN_TONG_SWITCH = 0;

/** 接口描述符，CallSetting的SatelliteServiceExtAbility的远端对象可使用该信息校验本次通信 */
const TOKEN_OF_CALL_SETTING_SATELLITE_SERVICE = 'com.ohos.emergencycommunication.SOSEmergencyCallAbility';

export function encapsulateReturnResult(code: number, message?: string) {
  let result: ReturnResult = {
    code: code,
    result: message
  };
  return result;
}

const TAG = 'SatelliteUtil';

/**
 * 天通卫星工具类
 */
export class SatelliteUtil {
  private static sInstance: SatelliteUtil | null;
  private proxyOfCallSettingServiceExtAbility: rpc.IRemoteObject | null = null;
  private connectIdOfCallSettingServiceExtAbility: number | null = null;

  constructor() {
  }

  public static getInstance() {
    if (!SatelliteUtil.sInstance) {
      SatelliteUtil.sInstance = new SatelliteUtil();
    }
    return SatelliteUtil.sInstance;
  }

  public getConnectIdOfCallSettingServiceExtAbility = () => {
    return this.connectIdOfCallSettingServiceExtAbility;
  }
  public getProxyOfCallSettingServiceExtAbility = () => {
    return this.proxyOfCallSettingServiceExtAbility;
  }
  /**
   * 连接callSetting的SatelliteServiceExtAbility，尝试去打开天通卫星开关并拉起天通卫星半模态连接窗口
   * @param context Context
   * @param connectFailCallBack 失败处理函数
   * @param connectSuccessCallback 成功处理函数
   */
  public connectCallSettingSatelliteServiceExtAbility = async (context: Context,
    connectFailCallBack: (errorCode: number | undefined) => void,
    connectSuccessCallback: (proxy: rpc.IRemoteObject | null) => void): Promise<void> => {
    try {
      let want: Want = {
        bundleName: 'com.ohos.callsetting',
        abilityName: 'SatelliteServiceExtAbility'
      };
      let connect: common.ConnectOptions = {
        onConnect: (elementName, remoteProxy) => {
          LogUtils.i(TAG, 'connectCallSettingSatelliteServiceExtAbility: js onConnect called');
          this.proxyOfCallSettingServiceExtAbility = remoteProxy;
          connectSuccessCallback(this.proxyOfCallSettingServiceExtAbility);
        },
        onDisconnect: (elementName) => {
          LogUtils.i(TAG, 'connectCallSettingSatelliteServiceExtAbility: onDisconnect');
          this.proxyOfCallSettingServiceExtAbility = null;
        },
        onFailed: (code) => {
          LogUtils.e(TAG, `connectCallSettingSatelliteServiceExtAbility: onFailed, code: ${code}`);
          connectFailCallBack(code);
        }
      };
      LogUtils.w(TAG, 'connectCallSettingSatelliteServiceExtAbility start');
      this.connectIdOfCallSettingServiceExtAbility =
        (context as common.UIAbilityContext).connectServiceExtensionAbility(want, connect);
    } catch (e) {
      LogUtils.e(TAG, `connectCallSettingSatelliteServiceExtAbility error: ${e?.code} ${e?.message}`);
      connectFailCallBack(e?.code);
    }
  }
  public disConnectCallSettingSatelliteServiceExtAbility = (context: common.UIAbilityContext) => {
    LogUtils.i(TAG, 'disConnectCallSettingSatelliteServiceExtAbility');
    try {
      if (this.connectIdOfCallSettingServiceExtAbility !== null) {
        (context as common.UIAbilityContext).disconnectServiceExtensionAbility(
          this.connectIdOfCallSettingServiceExtAbility).then(() => {
          this.proxyOfCallSettingServiceExtAbility = null;
          this.connectIdOfCallSettingServiceExtAbility = null;
          LogUtils.e(TAG, 'disConnectCallSettingSatelliteServiceExtAbility succeed');
        }).catch((err: BusinessError) => {
          LogUtils.e(TAG, `disConnectCallSettingSatelliteServiceExtAbility failed, error: ${err.code} ${err.message}`);
        });
      }
    } catch (e) {
      LogUtils.e(TAG, `disConnectCallSettingSatelliteServiceExtAbility error: ${e?.code} ${e?.message}`);
    }
  }

  /**
   * 向callSetting的SatelliteServiceExtAbility发送请求
   * @param proxy SatelliteServiceExtAbility的代理对象，
   * 可用于查询或获取接口描述符、添加或删除死亡通知、转储对象状态到特定文件、发送消息。
   * @param code 请求调用的消息码，由客户端和服务端共同决定，相当于接口名
   * @param inputParam 请求参数
   * @returns ReturnResult
   */
  public static async requestToCallSettingService(proxy: rpc.IRemoteObject | null, code: number,
    inputParam: string): Promise<ReturnResult> {
    if (!proxy) {
      LogUtils.w(TAG, `requestToCallSettingService proxy empty`);
      return encapsulateReturnResult(CommonData.int['FAILURE']);
    }
    try {
      let option = new rpc.MessageOption();
      let data = rpc.MessageSequence.create();
      let reply = rpc.MessageSequence.create();
      data.writeInterfaceToken(TOKEN_OF_CALL_SETTING_SATELLITE_SERVICE);
      data.writeString(inputParam);
      let res = await proxy.sendMessageRequest(code, data, reply, option)
        .then((result: rpc.RequestResult): ReturnResult => {
          if (result.errCode !== 0) {
            LogUtils.e(TAG, 'requestToCallSettingService: sendMessageRequest failed, errCode: ' + result.errCode);
            return encapsulateReturnResult(CommonData.int['FAILURE']);
          }
          LogUtils.i(TAG, 'requestToCallSettingService: sendMessageRequest success');
          let resultString: string = result.reply.readString();
          return encapsulateReturnResult(CommonData.int['SUCCESS'], resultString);
        }).catch((e: BusinessError): ReturnResult => {
          LogUtils.e(TAG, `requestToCallSettingService: sendMessageRequest error: ${e?.code} ${e?.message}`);
          return encapsulateReturnResult(CommonData.int['FAILURE']);
        });
      data.reclaim();
      reply.reclaim();
      return res;
    } catch (e) {
      LogUtils.e(TAG, `requestToCallSettingService error: ${e?.code} ${e?.message}`);
      return encapsulateReturnResult(CommonData.int['FAILURE']);
    }
  }

  private static isSupportCactus(): boolean {
    try {
      let cactus = SystemParameterEnhance.getSync(SATELLITE_KEY, '0');
      let isSupport = (Number(cactus) & CACTUS) === CACTUS;
      if (isSupport) {
        isSupport = getSatelliteHardwareSupportInfo(TYPE_CACTUS);
      }
      LogUtils.i(TAG, 'isSupportCactus isSupport:' + isSupport);
      return isSupport;
    } catch (e) {
      LogUtils.e(TAG, `isSupportCactus error: ${e?.code} ${e?.message}`);
      return false;
    }
  }

  private static isSupportDandelion(): boolean {
    try {
      let cactus = SystemParameterEnhance.getSync(SATELLITE_KEY, '0');
      let isSupport = (Number(cactus) & DANDELION) === DANDELION;
      LogUtils.i(TAG, 'isSupportDandelion isSupport:' + isSupport);
      return isSupport;
    } catch (e) {
      LogUtils.e(TAG, `isSupportDandelion error: ${e?.code} ${e?.message}`);
      return false;
    }
  }

  public static getIsDeviceSupportTianTongSatellite = () => {
    return SatelliteUtil.isSupportCactus() || SatelliteUtil.isSupportDandelion();
  }

  /**
   * Obtaining the Status of the TianTong Satellite Switch
   *
   * @returns satellite switch state 0.0 is off, 1.0 is on
   */
  public static getTianTongSatelliteSwitchState(context: Context): boolean {
    if (!context) {
      LogUtils.e(TAG, 'getTianTongSatelliteSwitchState context empty');
      return false;
    }
    try {
      let settingsValue = settings.getValueSync(context, TIAN_TONG_SATELLITE_MODE_KEY, TIAN_TONG_SATELLITE_SWITCH_OFF);
      if (settingsValue && Number(settingsValue) === 1) {
        LogUtils.i(TAG, 'getTianTongSatelliteSwitchState switch on');
        return true;
      } else {
        LogUtils.i(TAG, 'getTianTongSatelliteSwitchState switch off');
        return false;
      }
    } catch (e) {
      LogUtils.e(TAG, `getTianTongSatelliteSwitchState error: ${e?.code} ${e?.message}`);
      return false;
    }
  }
}
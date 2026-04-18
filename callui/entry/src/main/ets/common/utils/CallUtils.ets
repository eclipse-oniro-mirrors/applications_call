/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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
 * Call Util
 *
 * standard:
 * 1. define TAG, recommend class name.
 * 2. switch IS_DEBUG_ON as true, when debugging.
 * 3. msg should be short and valuable.
 * 4. choose appropriate function.
 * 5. the function execute many times can not print.
 * 6. uniqueness.
 */
import LogUtils from './LogUtils';
import radio from '@ohos.telephony.radio';
import CallServiceProxy from '../../model/CallServiceProxy';
import { BusinessError } from '@ohos.base';
import sim from '@ohos.telephony.sim';
import account_osAccount from '@ohos.account.osAccount';
import DefaultCallData, { VoipCallAttribute } from '../struct/TypeUtils';
import CallStateConst from '../constant/CallStateConst';
import systemParameterEnhance from '@ohos.systemParameterEnhance';
import { UE_CALL_TYPE } from '../utils/Constants';
import { ReportUtil } from './ReportUtils/ReportUtil';
import { DisplayMode } from './ReportUtils/DisplayMode';
import BannerNotificationManager from '../../model/BannerNotificationManager';

const TAG = 'CallUtils';
const SYS_USER_ID: number = 100;

/**
 *  calllog package tool class
 */
export class CallUtils {
  private static sLastClickTime = 0;
  private static sTimeSpace = 1000;
  private static sLastBtnName = '';
  private region = 'CN';
  public static readonly HIDE_CALL_PAGE_WHEN_SOS_CALL = 1;
  public static readonly DISPLAY_CURRENT_CALL_PAGE = 2;
  public static sosAbility = new Map<string, number>([
    ['1', CallUtils.HIDE_CALL_PAGE_WHEN_SOS_CALL],
    ['2', CallUtils.DISPLAY_CURRENT_CALL_PAGE]
  ]);

  constructor() {
    try {
      this.region = systemParameterEnhance.getSync('const.global.region', 'CN');
      LogUtils.i(TAG, 'get system parameter region: ' + this.region);
    } catch (err) {
      LogUtils.e(TAG, 'get system parameter region failed ' + JSON.stringify(err));
    }
  }

  public getCallISRoaming(slotId: number, callback: Function) {
    try {
      radio.getNetworkState(slotId).then((data: radio.NetworkState) => {
        LogUtils.i(TAG, 'getCallISRoaming success, slotId: ' + JSON.stringify(slotId) + ' isRoaming: ' +
          JSON.stringify(data.isRoaming));
        callback(data.isRoaming);
      }).catch((err: BusinessError) => {
        LogUtils.e(TAG, 'getCallISRoaming failed, slotId: ' + JSON.stringify(slotId) + ' err->' + JSON.stringify(err));
        callback(false);
      });
    } catch (error) {
      LogUtils.e(TAG, 'getCallISRoaming error, slotId : ' + JSON.stringify(slotId) + '  ' + JSON.stringify(error));
      callback(false);
    }
  }

  public getNetworkOperatorName(slotId: number): string {
    return radio.getOperatorNameSync(slotId);
  }

  public muteRinger(isIncoming: boolean) {
    if (isIncoming) {
      CallServiceProxy.getInstance().muteRinger();
    }
  }
  /**
   * Is call belonging to CMCC operator.
   * @param accountId  is slot id.
   * @returns
   */
  public isCmccCall(accountId: number): boolean {
    let mccmnc = sim.getSimOperatorNumericSync(accountId);
    LogUtils.i(TAG, `isOperatorChinaMobile:${mccmnc}`);
    let cmArr: string[] = ['46000', '46002', '46007', '46008', '46020'];
    let res = cmArr.some(item => {
      return item === mccmnc;
    })
    return res;
  }

  public isFastClick(btn : string) {
    if (btn !== CallUtils.sLastBtnName) {
      CallUtils.sLastBtnName = btn;
      return false;
    }
    const currentClickTime = new Date().getTime();
    let isFastClick: boolean = false;
    if (currentClickTime - CallUtils.sLastClickTime > CallUtils.sTimeSpace) {
      isFastClick = false;
      CallUtils.sLastClickTime = currentClickTime;
    } else {
      isFastClick = true;
    }
    CallUtils.sLastBtnName = btn;
    return isFastClick;
  }

  public isInvalidNumber(number: string): boolean {
    if (number.length === 0) {
      LogUtils.i(TAG, 'isInvalidNumber: number length is 0');
      return true;
    }
    if (number === 'Anonymous') {
      LogUtils.i(TAG, 'isInvalidNumber: number is Anonymous');
      return true;
    }
    return false;
  }

  /**
   * Is multi active sim.
   *
   * @returns true have multi active sim; false don't have multi active sim
   */
  public isMultiSimActive(): boolean {
    let simNumber = (sim.isSimActiveSync(0) ? 1 : 0) + (sim.isSimActiveSync(1) ? 1 : 0);
    return simNumber === 2;
  }

  public async getSysUserId(): Promise<number> {
    let accountManager = account_osAccount.getAccountManager();
    try {
      let spaceNum = await accountManager.getOsAccountLocalId();
      LogUtils.i(TAG, `getOsAccountLocalId, spaceNum: ${spaceNum}`);
      return spaceNum;
    } catch (e) {
      LogUtils.e(TAG, 'getOsAccountLocalId err: ' + JSON.stringify(e));
    }
    return SYS_USER_ID;
  }

  public getOsAccountLocalIdForUid(uid: number): number {
    let accountManager = account_osAccount.getAccountManager();
    try {
      // 获取空间id
      let spaceNum = accountManager.getOsAccountLocalIdForUidSync(uid);
      LogUtils.i(TAG, `getOsAccountLocalIdForUid, spaceNum: ${spaceNum}`);
      return spaceNum;
    } catch (e) {
      LogUtils.e(TAG, 'getOsAccountLocalIdForUid err: ' + JSON.stringify(e));
    }
    return SYS_USER_ID;
  }

  public isVoipCall(callData: DefaultCallData): boolean {
    return callData?.callType === CallStateConst.TYPE_VOIP;
  }

  public isMainProcessMode(attribute: VoipCallAttribute): boolean {
    return attribute?.extensionId === '';
  }

  public isSubProcessMode(attribute: VoipCallAttribute): boolean {
    return attribute?.extensionId !== '';
  }

  public isSosWithOutCallUiAbility(callData: DefaultCallData): number {
    if (!callData.extraParams?.sosWithOutCallUiAbility) {
      LogUtils.e(TAG, 'extraParams is null');
      return 0;
    }

    const value = callData.extraParams?.sosWithOutCallUiAbility as string;
    let tmpValue = CallUtils.sosAbility?.get(value);
    if (tmpValue === undefined) {
      LogUtils.e(TAG, 'tmpValue is undefined');
      return 0;
    }
    return tmpValue;
  }

  public isDoNotDisturb(callData: DefaultCallData): boolean {
    if (!callData || !callData.extraParams) {
      LogUtils.e(TAG, `isDoNotDisturb error`)
      return false;
    }
    const isDoNotDisturb = callData.extraParams['IsNeedSilentInDoNotDisturbMode'];
    LogUtils.i(TAG, `isDoNotDisturb ${isDoNotDisturb}`);
    if (!isDoNotDisturb) {
      return false;
    }
    if (typeof isDoNotDisturb === 'number') {
      return isDoNotDisturb === 1;
    }
    LogUtils.e(TAG, `isDoNotDisturb type not is number`);
    return false;
  }

  public getDisconnectedReason(callData: DefaultCallData): number {
    if (!callData || !callData.extraParams) {
      LogUtils.e(TAG, `getDisconnectedReason error`);
      return -1;
    }
    const reason = callData.extraParams['disconnectedReason'];
    LogUtils.i(TAG, `disconnectedReason: ${reason}`);
    if (typeof reason === 'number') {
      return reason;
    }
    return -1;
  }

  public isOversea(): boolean {
    return this.region !== 'CN';
  }

  public getImsDomain(callData: DefaultCallData): number {
    if (!callData || !callData.extraParams) {
      LogUtils.e(TAG, `getImsDomain error`);
      return -1;
    }
    const imsDomain = callData.extraParams['imsDomain'];
    LogUtils.i(TAG, `imsDomain: ${imsDomain}`);
    if (typeof imsDomain === 'number') {
      return imsDomain;
    }
    return -1;
  }

  public getUECallType(callData: DefaultCallData): number {
    return this.isVoipCall(callData) ? UE_CALL_TYPE.VOIP_CALL : UE_CALL_TYPE.CARRIER_CALL
  }

  public reportHangupCount() {
    if (BannerNotificationManager.getIsHeadsUpEnabled()) {
      ReportUtil.getInstance().reportHangupCallCount(DisplayMode.BANNER);
    } else if (AppStorage.get('hasBeenToFrontOrBackend') || AppStorage.get('onIndexPage')) {
      ReportUtil.getInstance().reportHangupCallCount(DisplayMode.FULLSCREEN);
    } else if (AppStorage.get('hasBeenToFrontOrBackend') == undefined && AppStorage.get('onIndexPage') == false) {
      ReportUtil.getInstance().reportHangupCallCount(DisplayMode.CAPSULE);
    }
  }
}

let mCallUtil = new CallUtils();

export default mCallUtil as CallUtils;


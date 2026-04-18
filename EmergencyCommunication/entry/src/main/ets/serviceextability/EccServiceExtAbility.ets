/*
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
import ServiceExtensionAbility from '@ohos.app.ability.ServiceExtensionAbility';
import ServiceExtImpl from '../idlServiceExt/idl_service_ext_impl';
import Want from '@ohos.app.ability.Want';
import rpc from '@ohos.rpc';
import LogUtils from '../utils/HiLog';
import EmergencyWarningPreferencesUtils from '../utils/EmergencyWarningPreferencesUtils';
import EmergencyWarningController from '../control/EmergencyWarningControl';
import { BusinessError, systemDateTime, systemTimer } from '@kit.BasicServicesKit';
import { Utils } from '../utils/Utils';
import { call, sim } from '@kit.TelephonyKit';
import SosLocationService, { SosLocationBody } from '../soslocationservice/SosLocationService';
import deviceinfo from '@ohos.deviceInfo';
import I18n from '@ohos.i18n';
import { SosHttpsUtils } from '../soslocationservice/SosHttpUtils';


const TAG: string = 'EccServiceExtAbility';

export interface SosInfoBody {
  caller: string
  called: string
  device: string
  address: string
  lng: number
  lat: number
  alt: number
  source: string
  time: number
  firstTime: number
  count: number
  tranceEnd: string
}

export default class EccServiceExtAbility extends ServiceExtensionAbility {
  private serviceExtImpl: ServiceExtImpl = new ServiceExtImpl('ExtImpl');
  public static readonly CALL_STATE_CALLING = 2
  public static readonly CALL_STATE_HANGUP = 0
  public callState = EccServiceExtAbility.CALL_STATE_HANGUP
  public called = ''
  public caller = 0
  public telephoneNumber = ''
  private sosLocationBody: SosLocationService = new SosLocationService()
  private sosLocation: SosLocationBody = {
    lng: 0,
    lat: 0,
    time: 0,
    alt: 0,
    address: ''
  }
  private emergencyWarningController: EmergencyWarningController = EmergencyWarningController.getInstance();
  private firstTime: number = 0
  public timeoutID = -1
  public epsTimeoutID = -1;
  private phoneNumberWithCountryCode: string = '';

  onCreate(want: Want) {
    LogUtils.i(TAG, `onCreate`);
  }

  async onRequest(want: Want, startId: number) {
    LogUtils.i(TAG, `onRequest`);
  }

  async onConnect(want: Want) {
    LogUtils.i(TAG, `onConnect`);
    if (want?.parameters && (want.parameters?.callerName === 'call_status_manager') && Utils
      .isSosLocationUpdateSwitchOn(this.context)) {
      this.called = want.parameters.phoneNumber + ''
      this.caller = parseInt(want.parameters.slotId + '')
      call.isEmergencyPhoneNumber(this.called, {
        slotId: this.caller === -1 ? 0 : this.caller
      }, async (err: BusinessError, data: boolean) => {
        if (err) {
          this.callState = EccServiceExtAbility.CALL_STATE_HANGUP
          LogUtils.e(TAG, 'answer err:' + JSON.stringify(err))
        } else {
          if (data) {
            this.firstTime = systemDateTime.getTime()
            this.getSimCardPhoneNumber(this.caller)
            this.callState = EccServiceExtAbility.CALL_STATE_CALLING
            await this.sendLocationInfo()
          } else {
            this.callState = EccServiceExtAbility.CALL_STATE_HANGUP
          }
        }
      });
    }
    return this.serviceExtImpl as rpc.RemoteObject;
  }

  onDisconnect() {
    this.callState = EccServiceExtAbility.CALL_STATE_HANGUP
    clearInterval(this.timeoutID);
    LogUtils.i(TAG, `onDisconnect`);
  }

  onDestroy() {
    LogUtils.i(TAG, `onDestroy`);
  }

  async sendLocationInfo() {
    LogUtils.i(TAG, 'sendLocationInfo start')
    await EmergencyWarningController.getInstance().readValueFromConfigJSON(this.context);
    this.sosLocation = await this.sosLocationBody.getLocationInfo(this.context)
    let deviceName: string = deviceinfo.marketName;
    if (Utils.isProductHide()) {
      deviceName = 'XX DEVICE';
    }
    let brandInfo: string = deviceinfo.brand;
    let phoneNumberFormat = new I18n.PhoneNumberFormat('CN', {
      type: 'NATIONAL'
    });
    let formattedNumber = phoneNumberFormat.format(this.telephoneNumber);
    formattedNumber = formattedNumber.replace(/\s+/g, '')
    let sosInfo: SosInfoBody = {
      caller: formattedNumber,
      called: this.called,
      device: deviceName,
      address: this.sosLocation.address,
      lng: this.sosLocation.lng,
      lat: this.sosLocation.lat,
      alt: this.sosLocation.alt,
      source: brandInfo,
      time: this.sosLocation.time,
      firstTime: this.firstTime,
      count: 0,
      tranceEnd: 'false'
    }
    sosInfo.count += 1
    await this.retryOperation(0, sosInfo)
    await this.retryEpsOperation(0, sosInfo);
    this.sosLocation = await this.sosLocationBody.getLocationInfo(this.context)
    sosInfo.address = this.sosLocation.address
    sosInfo.lng = this.sosLocation.lng
    sosInfo.alt = this.sosLocation.alt
    sosInfo.lat = this.sosLocation.lat
    sosInfo.time = this.sosLocation.time
    this.timeoutID = setInterval(async () => {
      sosInfo.count += 1
      if (this.callState !== EccServiceExtAbility.CALL_STATE_CALLING) {
        sosInfo.tranceEnd = 'true'
        await this.retryOperation(0, sosInfo)
        LogUtils.i(TAG, 'sendLocationInfo end')
        clearInterval(this.timeoutID);
        return
      }
      await this.retryOperation(0, sosInfo)
      this.sosLocation = await this.sosLocationBody.getLocationInfo(this.context)
      sosInfo.address = this.sosLocation.address
      sosInfo.lng = this.sosLocation.lng
      sosInfo.alt = this.sosLocation.alt
      sosInfo.lat = this.sosLocation.lat
      sosInfo.time = this.sosLocation.time
    }, 20000)
    this.epsTimeoutID = setInterval(async () => {
      if (this.callState !== EccServiceExtAbility.CALL_STATE_CALLING) {
        sosInfo.tranceEnd = 'true';
        await this.retryEpsOperation(0, sosInfo);
        LogUtils.i(TAG, 'EPS sendLocationInfo end');
        clearInterval(this.epsTimeoutID);
        return;
      }
      await this.retryEpsOperation(0, sosInfo);
      this.sosLocation = await this.sosLocationBody.getLocationInfo(this.context);
      sosInfo.address = this.sosLocation.address;
      sosInfo.lng = this.sosLocation.lng;
      sosInfo.alt = this.sosLocation.alt;
      sosInfo.lat = this.sosLocation.lat;
      sosInfo.time = this.sosLocation.time;
    }, 20000);
  }

  async retryEpsOperation(attempt: number, sosInfo: SosInfoBody): Promise<void> {
    LogUtils.i(TAG, `retryEpsOperation Start!`);
    let onError = () => {
      LogUtils.e(TAG, 'report EPS Info error');
    }
    let onSuccess = () => {
      LogUtils.i(TAG, 'report EPS Info Success');
    }
    let maxAttempts = 3;
    let delay = 3000;
    if (attempt >= maxAttempts) {
      onError();
      return;
    }
    let callback = (success: boolean) => {
      if (success) {
        onSuccess();
      } else {
        LogUtils.i(TAG, 'report EPS Info try again');
        setTimeout(() => {
          this.retryEpsOperation(attempt + 1, sosInfo);
        }, delay);
      }
    }
    await SosHttpsUtils.reportEpsInfo(sosInfo, this.phoneNumberWithCountryCode, callback);
  }

  async retryOperation(attempt: number, sosInfo: SosInfoBody): Promise<void> {
    LogUtils.i(TAG, `retryOperation Start!`);
    let onError = () => {
      LogUtils.e(TAG, 'report SosInfo error')
    }
    let onSuccess = () => {
      LogUtils.i(TAG, 'report SosInfo Success')
    }
    let maxAttempts = 3
    let delay = 3000
    if (attempt >= maxAttempts) {
      onError();
      return;
    }
    let callback = (success: boolean) => {
      if (success) {
        onSuccess();
      } else {
        LogUtils.i(TAG, 'report SosInfo try again')
        setTimeout(() => {
          this.retryOperation(attempt + 1, sosInfo);
        }, delay);
      }
    }
    // await SosHttpsUtils.reportSosInfo(sosInfo, callback);
  }

  getSimCardPhoneNumber(slotId: number) {
    LogUtils.i(TAG, `getSimCardPhoneNumber Start!`);
    sim.getShowNumber(slotId).then((res) => {
      if (res === '') {
        sim.getSimTelephoneNumber(slotId).then((resDefault: string) => {
          this.phoneNumberWithCountryCode = resDefault;
          this.telephoneNumber = Utils.formatPhoneNumberInMultiLanguage(resDefault);
        }).catch((err: BusinessError) => {
          LogUtils.i(TAG, 'getSimTelephoneNumber card1 other catch' + JSON.stringify(err));
        })
      } else {
        this.phoneNumberWithCountryCode = res;
        this.telephoneNumber = Utils.formatPhoneNumberInMultiLanguage(res);
      }
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, 'getSimCardOnePhoneNumber card1 other catch' + JSON.stringify(err));
    });
  }
}
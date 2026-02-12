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

import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import geoLocationManager from '@ohos.geoLocationManager';
import call from '@ohos.telephony.call';
import radio from '@ohos.telephony.radio';
import commonData from '../data/CommonData';
import sms from '@ohos.telephony.sms';
import promptAction from '@ohos.promptAction';
import LogUtils from '../utils/HiLog';
import sim from '@ohos.telephony.sim';
import common from '@ohos.app.ability.common';
import { EmergencyGlobalContextHelper } from '../utils/EmergencyGlobalContextHelper';
import * as Constants from '../utils/Constants';
import window from '@ohos.window';
import { BusinessError } from '@ohos.base';
import { LocationInfoStruct, ContactDataStruct, TimeOutStruct } from '../utils/ClassStruct';
import EmergencyNumber from '../utils/EmergencyNumber';
import { EccsCountryStruct } from '../utils/ClassStruct';
import { checkLocationPermission } from '../data/LocationData';
import { contact } from '@kit.ContactsKit';
import { TelephoneUtil } from '../utils/TelephoneUtil';
import LocationUtils, { AdaptedReverseGeocodeResult } from '../utils/LocationUtils';
//import { site } from '@kit.MapKit';

const TAG = 'EmergencyCallController';
const ESIM_PHONE_SYMBOL_RESOURCE_ID = 125836164;

export default class EmergencyCallController {
  private static sInstance: EmergencyCallController;
  public eccEmerNumList: EccsCountryStruct[] = [];
  public setTimeOutIdList: Array<TimeOutStruct> = [];

  static getInstance() {
    if (EmergencyCallController.sInstance == null) {
      EmergencyCallController.sInstance = new EmergencyCallController();
    }
    return EmergencyCallController.sInstance;
  }

  /**
   * get location info
   *
   * @param {function} callback - callback of location info
   */
  public getLocationInfo(callback: (data: LocationInfoStruct) => void) {
    LocationUtils.getInstance().setLocationSwitchIgnoredCallback(true, () => {
      try {
        this.getPermissionOfLocation(callback);
      } catch (err) {
        LogUtils.i(TAG, 'getLocationInfo catch errCode:' + (err as BusinessError).code +
          ',errMessage:' + (err as BusinessError).message);
        callback({
          isSuccess: false,
          data: ''
        })
      }
    })
  }

  getPermissionOfLocation(callback: (data: LocationInfoStruct) => void) {
    let atManager = abilityAccessCtrl.createAtManager();
    try {
      checkLocationPermission((grantStatus) => {
        LogUtils.i(TAG, 'grantStatus:' + grantStatus);
        if (grantStatus) {
          this.getBlurredLocationInfo(callback);
        } else {
          atManager.requestPermissionsFromUser(EmergencyGlobalContextHelper.getContext()
            .getValue<common.UIAbilityContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT),
            ['ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION']).then((data) => {
            LogUtils.i(TAG, 'requestPermissionsFromUser data authResults:' + JSON.stringify(data.authResults));
            if (data.authResults[0] === 0) {
              this.getBlurredLocationInfo(callback);
            } else {
              callback({
                isSuccess: false,
                data: '',
                hasPermission: false
              })
            }
          }).catch((err: BusinessError) => {
            LogUtils.e(TAG, 'getPermissionOfLocation failed errCode:' + err.code + ',errMessage:' + err.message);
            callback({
              isSuccess: false,
              data: ''
            })
          })
        }
      });
    } catch (err) {
      LogUtils.e(TAG, 'getPermissionOfLocation catch errCode:' +
      (err as BusinessError).code + ',errMessage:' + (err as BusinessError).message);
      callback({
        isSuccess: false,
        data: ''
      })
    }
  }

  /**
   * get blurred location info
   *
   * @param {function} callback - callback of location info
   */
  getBlurredLocationInfo(callback: (data: LocationInfoStruct) => void) {
    let requestInfo: geoLocationManager.CurrentLocationRequest = {
      'priority': geoLocationManager.LocationRequestPriority.FIRST_FIX,
      'scenario': geoLocationManager.LocationRequestScenario.UNSET
    };
    let locationChange = (err: BusinessError, location: geoLocationManager.Location) => {
      if (err || !location) {
        LogUtils.i(TAG, 'getBlurredLocationInfo: err=' + JSON.stringify(err));
        callback({
          isSuccess: false,
          data: ''
        })
        return;
      }
      LogUtils.i(TAG, 'getBlurredLocationInfo: location');
      this.formatLocationInfo(callback, location);
    };
    try {
      geoLocationManager.getCurrentLocation(requestInfo, locationChange);
    } catch (err) {
      LogUtils.i(TAG, 'getBlurredLocationInfo catch errCode:' +
      (err as BusinessError).code + ',errMessage:' + (err as BusinessError).message);
      callback({
        isSuccess: false,
        data: ''
      })
    }
  }

  /**
   * format location info
   *
   * @param {function} callback - callback of location info
   * @param {object} location - location info
   */
  async formatLocationInfo(callback: (data: LocationInfoStruct) => void, location: geoLocationManager.Location) {
    let currentLanguage = EmergencyGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT)?.config?.language || '';
    try {
      // let data: site.ReverseGeocodeResult | undefined =
      //   await LocationUtils.getInstance().reverseGeocode(currentLanguage, location.latitude, location.longitude);

      let data: AdaptedReverseGeocodeResult | undefined =
        await LocationUtils.getInstance().reverseGeocode(currentLanguage, location.latitude, location.longitude);
      if (!data) {
        LogUtils.e(TAG, `reverseGeocode is empty`);
        callback({
          isSuccess: false,
          data: ''
        })
        return;
      }
      LogUtils.i(TAG, 'reverseGeocode');
      /*if (data.addressDescription) {
        callback({
          isSuccess: true,
          data: data.addressDescription
        })
      } else {
        callback({
          isSuccess: false,
          data: ''
        })
      }*/
      if (data.formatAddress) {
        callback({
          isSuccess: true,
          data: data.formatAddress
        })
      } else {
        callback({
          isSuccess: false,
          data: ''
        })
      }
    } catch (err) {
      LogUtils.e(TAG, `reverseGeocode catch errCode: ${err?.code}, errMessage: ${err?.message}`);
      callback({
        isSuccess: false,
        data: ''
      })
    }
  }

  /**
   * check is emergency number
   *
   * @param {string} phoneNumber - input number
   * @param {function} callback - callback of result
   */
  public checkIsEmergencyPhoneNumber(phoneNumber: string, slotId: number, callback: (result: boolean) => void): void {
    call.isEmergencyPhoneNumber(phoneNumber, {
      slotId: slotId === -1 ? 0 : slotId
    }, (err: BusinessError, data: boolean) => {
      LogUtils.i(TAG, `answer callback: err->${JSON.stringify(err)}, data->${data},slotId->${slotId}`)
      if (err) {
        callback(false);
      } else {
        callback(data);
      }
    });
  }

  /**
   * dial
   *
   * @param {string} phoneNumber - dial number
   * @param {number} string - slot id of sim
   * @param {boolean} isEmergency - is emergency number
   */
  public emergencyCallDial(phoneNumber: string, slotId: number, isEmergency?: boolean) {
    LogUtils.i(TAG, `emergencyCallDial, slotId:${slotId}, isEmergency: ${isEmergency}`);
    const options: call.DialCallOptions = {
      dialScene: call.DialScene.CALL_EMERGENCY
    };
    if (isEmergency) {
      options.dialScene = call.DialScene.CALL_EMERGENCY;
    }
    if (slotId !== commonData.int.SIM_SLOT_ID_EMPTY) {
      options['accountId'] = slotId;
    }
    let promise = call.dial(phoneNumber.toString(), options);
    promise.then(() => {
      LogUtils.i(TAG, `dialCall success.`);
    }).catch((err: BusinessError) => {
      LogUtils.i(TAG, `dialCall fail, promise: err->${JSON.stringify(err)}`);
    });
  }

  /**
   * get sim operator name
   *
   * @param {number} string - slot id of sim
   *
   */
  public getSimOperatorName(slotId: number, isGetEmergencyNum = true): void {
    let promise = radio.getOperatorName(slotId);
    promise.then(data => {
      LogUtils.i(TAG, `getOperatorName success, promise: data->${data}`);
      if (slotId) {
        AppStorage.SetOrCreate('simOperatorNameSecond', data);
      } else {
        AppStorage.SetOrCreate('simOperatorNameFirst', data);
      }
      if (data && isGetEmergencyNum) {
        this.getEccdataEmergencyNum();
      }
    }, (err: BusinessError) => {
      LogUtils.i(TAG, `getOperatorName failed, promise: err->${JSON.stringify(err)}`);
    })
  }

  public getDefaultVoiceSlotId() {
    sim.getDefaultVoiceSlotId().then((data) => {
      AppStorage.setOrCreate('defaultVoiceId', data);
    })
  }

  /**
   * get sim operator names
   *
   */
  public getSimOperatorNames(isGetEmergencyNum = true): void {
    this.getSimOperatorName(commonData.int.SIM_SLOT_ID_FIRST, isGetEmergencyNum);
    let simNumber = sim.getMaxSimCount();
    if (simNumber > 1) {
      this.getSimOperatorName(commonData.int.SIM_SLOT_ID_SECOND, isGetEmergencyNum);
    }
  }

  /**
   * get PhoneBadgeIcon
   * @param slotId
   * @returns Phone symbol Resource
   */
  public getPhoneBadgeIcon(slotId: number): Resource {
    let sim1PhoneBadge = $r('sys.symbol.phone_badge_1_fill');
    let sim2PhoneBadge = $r('sys.symbol.phone_badge_2_fill');
    let eSimPhoneBadge = $r('sys.symbol.phone_badge_1_fill');
    eSimPhoneBadge.id = ESIM_PHONE_SYMBOL_RESOURCE_ID;
    let simLabel:ESObject = sim.getSimLabelSync(slotId);
    let curSimType:ESObject = simLabel.simType ?? null;
    let curSimIndex:ESObject = simLabel.index ?? null;
    if (curSimType !== null && curSimIndex !== null) {
      return curSimType === sim.SimType.ESIM ? eSimPhoneBadge : (curSimIndex === 1 ? sim1PhoneBadge : sim2PhoneBadge);
    }
    return slotId === 0 ? sim1PhoneBadge : sim2PhoneBadge;
  }

  /**
   * select in contacts picker
   *
   * @param {function} callback - callback with the selected contact data
   */
  async selectInContactsPicker(callback: (data: ContactDataStruct | null) => void) {
    try {
      const data: contact.Contact[] | void = await contact.selectContacts({
        isMultiSelect: false
      }).catch((err: BusinessError) => {
        LogUtils.e(TAG, `jumpToContactForResult Failed to select Contacts. Code: ${err.code}, message: ${err.message}`);
        return [];
      });
      if (!data || data.length === 0) {
        callback(null);
        return;
      }
      let contactsList: ContactDataStruct[] = [];
      for (let contact of data) {
        const contactPhoneNumber = contact.phoneNumbers?.find(v => Boolean(v.phoneNumber));
        if (contactPhoneNumber) {
          const telephone = contactPhoneNumber.phoneNumber;
          contactsList.push({
            telephone: telephone,
            contactName: contact.name?.fullName || telephone,
            nameRawContactId: contact.id
          });
        }
      }
      if (contactsList && contactsList.length > 0) {
        callback(contactsList[0]);
      } else {
        callback(null);
      }
    } catch (e) {
      LogUtils.e(TAG, `jumpToContactForResult callback: err->${JSON.stringify(e)}`);
      callback(null);
    }
  }

  /**
   * get string from resource
   *
   * @param {Resource} resource - resource
   * @param {string} accountNumber - the phone number send to
   * @param {ResourceStr} contentResource - content of message
   *
   * @return { string } - return resource string
   */
  formatResourceToString(resource: Resource) {
    return EmergencyGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT)?.
    resourceManager.getStringSync(resource.id);
  }

  /**
   * get string from resource
   *
   * @param {Resource} resource - resource
   * @param {string} accountNumber - the phone number send to
   *
   * @return { string } - return resource string
   */
  formatResourceToStringWithParams(resource: Resource, ...args: Array<string | number>) {
    return EmergencyGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT)?.
    resourceManager.getStringSync(resource.id, ...args);
  }

  /**
   * send message
   *
   * @param {number} accountId - slot id of sim
   * @param {string} accountNumber - the phone number send to
   * @param {ResourceStr} contentResource - content of message
   */
  public sendMessage(accountId: number, accountNumber: string, contentResource: Resource) {
    EmergencyGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT)?.
    resourceManager.getStringValue(contentResource.id, (err, typeName) => {
      if (accountId === commonData.int.SIM_SLOT_ID_EMPTY) {
        promptAction.showToast({
          message: $r('app.string.no_sim_message_and_call_unavailable'),
          duration: 2000
        });
        return
      }
      sms.sendShortMessage({
        slotId: accountId,
        destinationHost: TelephoneUtil.formatDisplayPhoneNum(accountNumber),
        content: typeName,
        sendCallback: (err, sendResult) => {
          LogUtils.i(TAG, 'sendCallback result:' + sendResult?.result);
          if (err) {
            return;
          }
          if (sendResult.result === commonData.int.SEND_SMS_SUCCESS) {
            promptAction.showToast({
              message: $r('app.string.sendSmsSuccess'),
              duration: 2000
            });
          } else {
            promptAction.showToast({
              message: $r('app.string.sendSmsFail'),
              duration: 2000
            });
          }
        }
      });
    })
  }

  /**
   * exit application
   *
   */
  public exitingApplication() {
    try {
      EmergencyGlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT)?.
      terminateSelf().then(() => {
        LogUtils.i(TAG, 'terminateSelf success');
      }, (err: BusinessError) => {
        LogUtils.i(TAG, `terminateSelf failed, code is ${err.code}, message is ${err.message}`);
      });
    } catch (error) {
      LogUtils.i(TAG, `terminateSelf failed, code is ${(error as BusinessError).code}` +
        `, message is ${(error as BusinessError).message}`);
    }
  }

  /**
   * set systemBar style
   *
   * @param {string} color value of color
   *
   */
  public setWindowBackgroundColor(color: string) {
    if (!color) {
      LogUtils.i(TAG, `color empty`);
      return;
    }
    LogUtils.i(TAG, 'setWindowBackgroundColor: 1');
    EmergencyGlobalContextHelper.getContext().getValue<window.WindowStage>(Constants.EMERGENCY_CALL_WINDOW_STAGE)?.
    getMainWindow((err, data) => {
      if (err.code) {
        LogUtils.i(TAG, 'Failed to obtain the main window. Cause: ' + JSON.stringify(err));
        return;
      }
      LogUtils.i(TAG, 'setWindowBackgroundColor: 3');
      let windowClass: window.Window = data;
      LogUtils.i(TAG, 'Succeeded in obtaining the main window. ');
      try {
        LogUtils.i(TAG, 'setWindowBackgroundColor: 4');
        windowClass.setWindowBackgroundColor(color);
      } catch (exception) {
        LogUtils.i(TAG, 'Failed to set the background color. Cause: ' + JSON.stringify(exception));
      }
    });
  }

  getEccdataEmergencyNum() {
    EmergencyGlobalContextHelper.getContext().
      getValue<common.UIAbilityContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT)?.resourceManager.
      getRawFileContent('eccdata.json', (error, value) => {
      if (error != null) {
        LogUtils.i(TAG, 'error is ' + error);
      } else {
        this.eccEmerNumList = value ? JSON.parse(String.fromCharCode(...Array.from(value))).countries : [];
        LogUtils.i(TAG, 'Length of getRawFileContentRes : ' + this.eccEmerNumList.length);
        EmergencyNumber.getInstance().initEmergencyNumData();
      }
    });
  }

  pushIdToList(item: TimeOutStruct) {
    this.setTimeOutIdList.push(item)
  }

  clearIdOfList(id: string, callBack: (data: string) => void) {
    this.setTimeOutIdList.forEach(item => {
      if (item.itemId === id) {
        clearTimeout(item.timerId);
        item.timerId = setTimeout(() => {
          callBack(id);
        }, 3000)
      }
    })
  }

  dialerSpecialCode(number: string) {
    let phoneNumber: string = number;
    call.inputDialerSpecialCode(phoneNumber, (err: BusinessError) => {
      if (err) {
        LogUtils.e(TAG, 'inputDialerSpecialCode error: ' + JSON.stringify(err));
      } else {
        LogUtils.i(TAG, 'inputDialerSpecialCode success');
      }
    });
  }
}
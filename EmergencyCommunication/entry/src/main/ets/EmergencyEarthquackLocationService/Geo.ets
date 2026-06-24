/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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
import geoLocationManager from '@ohos.geoLocationManager';
import checkAccess from './Detector'
import { HashMap } from '@kit.ArkTS';
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import LogUtils from '../utils/HiLog';
import { BusinessError } from '@kit.BasicServicesKit';
import { PermissionsUtils } from '../utils/PermissionsUtils';
import { Utils } from '../utils/Utils';
import EmergencyWarningController from '../control/EmergencyWarningControl';
import { DeviceLocation } from '../utils/ClassStruct';
import LocationUtils, { AdaptedReverseGeocodeResult } from '../utils/LocationUtils';
import deviceInfo from '@ohos.deviceInfo';

//import { site } from '@kit.MapKit';
import DeviceInfoManager from '../utils/DeviceInfoManager';

const TAG_NODE0 = 'Geo-Node0';
const TAG_NODE1 = 'Geo-Node1';
const TAG_NODE2 = 'Geo-Node2';
const TAG = 'Geo';
const DEVICE_MODEL = deviceInfo.productModel;

export class OUT {
  public latitude: number = 0;
  public longitude: number = 0;
  public altitude: number = 0;
  public cityName: string = '';
  public speed: number = 0;
  public isFinished: boolean = false;
  public error: string = '';
  public switchStatus? : string = ''
}

export async function nodeGetGeographicalPosition1() {
  let output: OUT = {
    latitude: 0,
    longitude: 0,
    altitude: 0,
    cityName: '',
    speed: 0,
    isFinished: false,
    error: 'null'
  }
  if (!LocationUtils.getInstance().getLocationEnable()) {
    LogUtils.i(TAG_NODE1, 'Location module loads fail')
    output.error = EmergencyWarningController.IGNORE_LOCATION_SWITCH_KEY
    output.switchStatus = EmergencyWarningController.IGNORE_LOCATION_SWITCH_KEY
    LocationUtils.getInstance().setLocationSwitchIgnored(true);
  }
  let requestInfo: geoLocationManager.CurrentLocationRequest = {
    'priority': 0x203,
    'scenario': 0x300,
    'maxAccuracy': 0
  }
  await geoLocationManager.getCurrentLocation(requestInfo).then((result) => {
    output.latitude = result.latitude
    output.longitude = result.longitude
    output.altitude = result.altitude
    output.speed = result.speed
    output.isFinished = true
    output.error = 'null'
  }).catch(async (error: Error) => {
    output.error = 'getCurrentLocation failed'
    await retryGetLocation(error, output, requestInfo);
  });
  LogUtils.i(TAG, 'out put');
  return output
}

async function retryGetLocation(error: Error, output: OUT, requestInfo: geoLocationManager.CurrentLocationRequest) {
  LogUtils.e(TAG, 'getCurrentLocation failed 0: error=' + JSON.stringify(error));
  await delay(3000);
  await geoLocationManager.getCurrentLocation(requestInfo).then((result) => {
    output.latitude = result.latitude;
    output.longitude = result.longitude;
    output.altitude = result.altitude;
    output.speed = result.speed;
    output.isFinished = true;
    output.error = 'null'
  }).catch(async (error: Error) => {
    output.error = 'getCurrentLocation failed'
    LogUtils.e(TAG, 'getCurrentLocation failed 1 : error=' + JSON.stringify(error));
    await delay(3000);
    await geoLocationManager.getCurrentLocation(requestInfo).then((result) => {
      output.latitude = result.latitude;
      output.longitude = result.longitude;
      output.altitude = result.altitude;
      output.speed = result.speed;
      output.isFinished = true;
      output.error = 'null'
    }).catch(async (error: Error) => {
      output.error = 'getCurrentLocation failed'
      LogUtils.e(TAG, 'getCurrentLocation failed 2 : error=' + JSON.stringify(error));
    });
  });
}

function delay(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

export async function nodeGetCityName2(input: OUT, context: Context) {
  let output: OUT = {
    cityName: '',
    latitude: input.latitude,
    longitude: input.longitude,
    altitude: input.altitude,
    speed: input.speed,
    isFinished: false,
    error: input.error,
    switchStatus: input.switchStatus,
  }
  if (!geoLocationManager.isGeocoderAvailable()) {
    LogUtils.e(TAG_NODE2, 'Geocoder module loads fail')
    output.error = 'Geocoding conversion is not available, please check your device or server'
    return output
  }
  if (!LocationUtils.getInstance().getLocationEnable()) {
    LogUtils.i(TAG_NODE1, 'Location module loads fail')
    output.error = EmergencyWarningController.IGNORE_LOCATION_SWITCH_KEY
    output.switchStatus = EmergencyWarningController.IGNORE_LOCATION_SWITCH_KEY
    LocationUtils.getInstance().setLocationSwitchIgnored(true)
  }
  await LocationUtils.getInstance().reverseGeocodeByContext(context, 'zh', input.latitude, input.longitude)
    /*.then((result: site.ReverseGeocodeResult | undefined) => {
      let cityName:ESObject = result?.addressComponent.city?.cityName;
      if (cityName !== undefined) {
        let address:ESObject = result?.addressComponent;
        output.cityName = getCityName(cityName, address, result);
        output.isFinished = true
        output.error = 'null'
      }
    })*/
    .then((result: AdaptedReverseGeocodeResult  | undefined) => {
      if(result){
        let cityName:string | undefined = result.countryName
        if (cityName !== undefined) {
          let address:string | undefined = result.locality;
          output.cityName = getCityName(cityName, result);
          output.isFinished = true
          output.error = 'null'
        }
      }
    })
    .catch((error: Error) => {
      LogUtils.e(TAG_NODE2, `Get addresses from location: ${error?.name}, errMessage: ${error?.message}`);
      output.error = 'Reverse geocoding conversion failed'
    });
  return output
}

/*function getCityName(cityName: string, address: site.AddressComponent | undefined,
  result: site.ReverseGeocodeResult | undefined): string {
  return `${cityName}|${address?.postalCode || ''}|${address?.city?.cityCode || ''},${address?.adminCode || ''}|` +
    `${address?.adminLevel1 || ''}|${address?.adminLevel2 || ''}|${result?.addressDescription || ''}` +
    `|${address?.countryCode || ''}`;
}*/
/**
 * 适配后的 getCityName 方法
 * @param cityName 外部传入的城市名称
 * @param geoAddress OpenHarmony 返回的地址对象 (取 result[0])
 */
function getCityName(cityName: string, geoAddress: geoLocationManager.GeoAddress | undefined): string {
  if (!geoAddress) {
    // 如果对象为空，返回仅包含分隔符的空字符串，防止崩溃
    return `${cityName}||,|||||`;
  }

  // 1. 邮编
  const postalCode = geoAddress.postalCode || '';

  // 2. 城市代码/行政区代码 (OpenHarmony 不提供，留空)
  const cityCode = '';
  const adminCode = '';

  // 3. 行政区划
  // adminLevel1 -> 省/州
  const adminLevel1 = geoAddress.administrativeArea || '';
  // adminLevel2 -> 通常对应 subAdministrativeArea，但在国内可能为空，视系统实现而定
  const adminLevel2 = geoAddress.subAdministrativeArea || '';

  // 4. 详细地址描述
  // GeoAddress 的 descriptions 是一个数组，通常取第一个作为完整描述
  let addressDescription = '';
  if (geoAddress.descriptions && geoAddress.descriptions.length > 0) {
    addressDescription = geoAddress.descriptions[0];
  }

  // 5. 国家码
  const countryCode = geoAddress.countryCode || '';

  // 6. 拼接返回 (保持原有的管道符格式)
  return `${cityName}|${postalCode}|${cityCode},${adminCode}|` +
    `${adminLevel1}|${adminLevel2}|${addressDescription}` +
    `|${countryCode}`;
}

export async function getGeoData(context: Context) {
  let reOut: OUT = {
    latitude: 0,
    longitude: 0,
    altitude: 0,
    cityName: '',
    speed: 0,
    isFinished: false,
    error: 'The device has not obtained relevant permissions'
  }
  if (!checkAccess()) {
    return reOut;
  }
  let output = await nodeGetGeographicalPosition1()
  if (output !== undefined && !output.isFinished) {
    LogUtils.e(TAG, 'output isFinished');
    if (output.switchStatus === EmergencyWarningController.IGNORE_LOCATION_SWITCH_KEY) {
      try {
        LocationUtils.getInstance().setLocationSwitchIgnored(false);
      } catch (error) {
        LogUtils.e(TAG, 'disableLocation failed: error=' + JSON.stringify(error));
      }
    }
    return output
  }
  if (output === undefined) {
    return reOut;
  }
  output = await nodeGetCityName2(output, context)
  if (output.switchStatus === EmergencyWarningController.IGNORE_LOCATION_SWITCH_KEY) {
    try {
      LocationUtils.getInstance().setLocationSwitchIgnored(false);
    } catch (error) {
      LogUtils.e(TAG, 'disableLocation failed: error=' + JSON.stringify(error));
    }
  }
  return output
}

export const getCountryCode = async (): Promise<null | geoLocationManager.CountryCode> => {
  try {
    let countryCode = await geoLocationManager.getCountryCode()
      .catch((error: number) => {
        LogUtils.e(TAG, 'promise, getCountryCode: error:' + JSON.stringify(error));
        return null;
      });
    return countryCode;
  } catch (err) {
    let error = err as BusinessError;
    LogUtils.e(TAG, 'getCountryCode failed, errCode:' + error?.code + ',errMessage:' + err?.message);
    return null;
  }
}

/**
 * get DeviceLocation By Latitude And Longitude
 */
export const getDeviceLocationByLatitudeAndLongitude =
  async (latitude: string, longitude: string, context: Context): Promise<DeviceLocation | undefined> => {
    LogUtils.i(TAG, 'getGeocodeByLatitudeAndLongitude start');

    if (!geoLocationManager.isGeocoderAvailable()) {
      LogUtils.e(TAG, 'geoLocationManager is not Available');
      return;
    }

    // let data: site.ReverseGeocodeResult | undefined =
    //   await LocationUtils.getInstance().reverseGeocodeByContext(context, 'en', Number(latitude), Number(longitude));
    let data:  AdaptedReverseGeocodeResult | undefined =
      await LocationUtils.getInstance().reverseGeocodeByContext(context, 'en', Number(latitude), Number(longitude));
    if (!data) {
      LogUtils.e(TAG, 'getAddressesFromLocation failed');
      return;
    }
    //const geocode:ESObject = data.addressComponent.adminCode || '';
    const geocode:ESObject = data.formatAddress || '';
    //const countryCode:ESObject = data.addressComponent.countryCode || '';
    const countryCode:ESObject = data.countryName || '';
    return {
      geocode: geocode,
      countryCode: countryCode,
      longitude: Number(longitude),
      latitude: Number(latitude),
      deviceModel: DEVICE_MODEL,
      romVersion: DeviceInfoManager.getInstance().romVersion
    };
  }

/**
 * get DeviceLocation
 * @param isChecked Check whether the location permission and location information switch have been verified.
 * @returns Promise<DeviceLocation | undefined>
 */
export const getDeviceLocation = async (isChecked: boolean, context: Context): Promise<DeviceLocation | undefined> => {
  if (!isChecked) {
    let mapPermissionsToGrantStatus: HashMap<Permissions, abilityAccessCtrl.GrantStatus> =
      await PermissionsUtils.checkPermissions(PermissionsUtils.permissionsOfEmergencyWarning);
    let listOfNeedPermission: Permissions[] = [];
    if (!mapPermissionsToGrantStatus.isEmpty()) {
      mapPermissionsToGrantStatus.forEach((value, key) => {
        if (key && value === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
          listOfNeedPermission.push(key);
        }
      })
      if (listOfNeedPermission.length > 0) {
        LogUtils.w(TAG, `check PERMISSION_DENIED ${JSON.stringify(listOfNeedPermission)}`);
      }
    }
    LogUtils.i(TAG, 'getDeviceLocation enableLocationSwitchOfEmergencyWarning start');
    await Utils.enableLocationSwitchOfEmergencyWarning();
  }

  let outputOfPosition: OUT;
  try {
    outputOfPosition = await nodeGetGeographicalPosition1();
  } catch (e) {
    LogUtils.e(TAG, 'Node1_Get_Geographical_Position failed');
    return;
  }
  if (!outputOfPosition || outputOfPosition.isFinished === false) {
    LogUtils.e(TAG, 'outputOfPosition is not Available');
    return;
  }

  if (!geoLocationManager.isGeocoderAvailable()) {
    LogUtils.e(TAG, 'geoLocationManager is not Available');
    return;
  }

/*  let data: site.ReverseGeocodeResult | undefined =
    await LocationUtils.getInstance()
      .reverseGeocodeByContext(context, 'en', outputOfPosition.latitude, outputOfPosition.longitude);*/
  let data: AdaptedReverseGeocodeResult | undefined =
    await LocationUtils.getInstance()
      .reverseGeocodeByContext(context, 'en', outputOfPosition.latitude, outputOfPosition.longitude);
  LogUtils.w(TAG, 'getDeviceLocation reverseGeocodeByContext');
  if (!data) {
    LogUtils.e(TAG, 'getAddressesFromLocation failed');
  }
  //const geocode:ESObject = data?.addressComponent.adminCode || '';
  let geocode:ESObject =  '';
  //const countryCode:ESObject = data?.addressComponent.countryCode || '';
  let  countryCode:ESObject =  '';
  if(data){
    geocode = data.countryName
    countryCode = data.countryName
  }
  return {
    geocode: geocode,
    countryCode: countryCode,
    longitude: outputOfPosition.longitude,
    latitude: outputOfPosition.latitude,
    deviceModel: DEVICE_MODEL,
    romVersion: DeviceInfoManager.getInstance().romVersion
  };
}
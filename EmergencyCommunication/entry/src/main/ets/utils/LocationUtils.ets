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

import geoLocationManager from '@ohos.geoLocationManager';
import LogUtils from '../utils/HiLog';
import { BusinessError } from '@ohos.base';
//import { map, mapCommon, site } from '@kit.MapKit';
const TAG = 'LocationUtils';


export interface AdaptedReverseGeocodeResult {
  formatAddress: string; // 完整地址
  countryName?: string;
  administrativeArea?: string; // 省/州
  locality?: string; // 市
  subLocality?: string; // 区/县
  roadName?: string; // 路名
}

export interface LatLng {
  latitude: number;
  longitude: number;
}

export default class LocationUtils {
  private static sInstance: LocationUtils;
  public ignoreLocationSwitch: boolean = true;

  static getInstance() {
    if (LocationUtils.sInstance == null) {
      LocationUtils.sInstance = new LocationUtils();
    }
    return LocationUtils.sInstance;
  }

  /**
   * Set the Get Location Ignore Position switch
   */
  public setLocationSwitchIgnored(isIgnored: boolean): boolean {
    LogUtils.i(TAG, `setLocationSwitchIgnored start param: ${isIgnored}`);
    this.ignoreLocationSwitch = isIgnored;
    try {
      geoLocationManager.setLocationSwitchIgnored(isIgnored);
      LogUtils.i(TAG, 'promise, setLocationSwitchIgnored succeed');
      return true;
    } catch (err) {
      LogUtils.e(TAG, `promise, setLocationSwitchIgnored failed: code:${err?.code}, message:${err?.message}`);
      return false;
    }
  }

  /**
   * Set the Get Position, ignore the position switch, and callback
   */
  public setLocationSwitchIgnoredCallback(isIgnored: boolean, callback: () => void) {
    if (this.setLocationSwitchIgnored(isIgnored)) {
      callback();
    }
  }

  /**
   * Get the position switch status
   */
  public getLocationEnable(): boolean {
    try {
      return geoLocationManager.isLocationEnabled();
    } catch (err) {
      LogUtils.e(TAG, `getLocationEnable catch errCode: ${err?.code}, errMessage: ${err?.message}`);
      return false;
    }
  }

  // 简化语言区域标识
  simplifyLocale(locale: string): string {
    return locale.startsWith('en') ? 'en' : 'zh';
  }

  // 暂不支持地图坐标转换，可能需要适配
  /*  // 转换地图坐标
  convertMapCoordinate(latitude: number, longitude: number): mapCommon.LatLng {
    return map.convertCoordinateSync(
      mapCommon.CoordinateType.WGS84,
      mapCommon.CoordinateType.GCJ02,
      { latitude, longitude }
    );
  }*/
  convertMapCoordinate(latitude: number, longitude: number): LatLng {
    // 适配：直接透传 WGS84 坐标给系统服务
    // 如果必须 GCJ02，需要引入纯算法转换库
    return { latitude, longitude };
  }

  /**
   * reverseGeocode
   */
  /*public async reverseGeocode(locale: string, latitude: number,
    longitude: number): Promise<site.ReverseGeocodeResult | undefined> {
    try {
      let params: site.ReverseGeocodeParams = this.getReverseGeocode(latitude, longitude, locale);
      return await site.reverseGeocode(params);
    } catch (err) {
      LogUtils.e(TAG, `reverseGeocode catch errCode: ${err?.code}, errMessage: ${err?.message}`);
    }
    return undefined;
  }*/

  public async reverseGeocode(locale: string, latitude: number,
    longitude: number): Promise<AdaptedReverseGeocodeResult | undefined> {
    try {
      // 1. 获取适配后的请求参数 (OpenHarmony 标准)
      let request = this.getReverseGeocodeRequest(latitude, longitude, locale);

      // 2. 调用 OpenHarmony 标准能力
      const geoAddresses: Array<geoLocationManager.GeoAddress> = await geoLocationManager.getAddressesFromLocation(request);

      // 3. 结果适配转换 (Adaptee -> Target)
      if (geoAddresses && geoAddresses.length > 0) {
        return this.mapGeoAddressToResult(geoAddresses[0]);
      }
    } catch (err) {
      let error = err as BusinessError;
      LogUtils.e(TAG, `reverseGeocode catch errCode: ${error.code}, errMessage: ${error.message}`);
    }
    return undefined;
  }

  /**
   * reverseGeocodeByContext
   */
  /* public async reverseGeocodeByContext(context: Context, locale: string, latitude: number,
    longitude: number): Promise<site.ReverseGeocodeResult | undefined> {
    try {
      let params: site.ReverseGeocodeParams = this.getReverseGeocode(latitude, longitude, locale);
      return await site.reverseGeocode(context, params);
    } catch (err) {
      LogUtils.e(TAG, `reverseGeocodeByContext catch errCode: ${err?.code}, errMessage: ${err?.message}`);
    }
    return undefined;
  }*/
  public async reverseGeocodeByContext(context: Context, locale: string, latitude: number,
    longitude: number): Promise<AdaptedReverseGeocodeResult | undefined> {
    // 逻辑同上，OpenHarmony API 不需要 Context 即可调用系统服务
    return this.reverseGeocode(locale, latitude, longitude);
  }

  /*private getReverseGeocode(latitude: number, longitude: number, locale: string) {
    let locationData = this.convertMapCoordinate(latitude, longitude);
    let params: site.ReverseGeocodeParams = {
      location: {
        latitude: locationData.latitude,
        longitude: locationData.longitude
      },
      language: this.simplifyLocale(locale),
      radius: 200
    };
    return params;
  }*/
  private getReverseGeocodeRequest(latitude: number, longitude: number, locale: string): geoLocationManager.ReverseGeoCodeRequest {
    // 注意：这里不再进行 WGS84 -> GCJ02 转换，直接使用原始坐标
    // 因为系统 Geocoder 期望的是真实 GPS 坐标
    let request: geoLocationManager.ReverseGeoCodeRequest = {
      latitude: latitude,
      longitude: longitude,
      maxItems: 1, // 我们只需要最匹配的那一个
      locale: this.simplifyLocale(locale)
    };
    return request;
  }

  private mapGeoAddressToResult(addr: geoLocationManager.GeoAddress): AdaptedReverseGeocodeResult {
    // 拼接一个大致的格式化地址，OpenHarmony 可能直接提供 placeName
    let fullAddress = '';

    // 如果系统没有直接提供格式化好的地址，手动拼接 (根据实际需求调整顺序)
    if (addr.placeName) {
      fullAddress = addr.placeName;
    } else {
      fullAddress = `${addr.administrativeArea || ''}${addr.locality || ''}${addr.roadName || ''}`;
    }

    return {
      formatAddress: fullAddress,
      countryName: addr.countryName,
      administrativeArea: addr.administrativeArea,
      locality: addr.locality,
      subLocality: addr.subLocality,
      roadName: addr.roadName
    };
  }
}
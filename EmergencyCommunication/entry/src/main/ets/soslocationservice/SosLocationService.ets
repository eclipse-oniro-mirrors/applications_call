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
import { getGeoData, OUT } from '../EmergencyEarthquackLocationService/Geo'
import systemDateTime from '@ohos.systemDateTime'
import LogUtils from '../utils/HiLog'
import { ReportUtil } from '../utils/ReportUtil'
import { LocationReportResultOfSos } from '../data/CommonData'

const TAG = 'SosLocationService'

export interface SosLocationBody {
  lng: number
  lat: number
  time: number
  address: string
  alt: number
}

export default class SosLocationService {
  public lng: number = 0;
  public lat: number = 0;
  public time: number = 0;
  public alt: number = 0;
  public address: string = '';
  public sosLocationIndo: SosLocationBody = {
    lng: this.lng,
    lat: this.lat,
    time: this.time,
    address: this.address,
    alt: this.alt
  }
  public locationInfo: OUT = new OUT()

  getAddress(inputString: string, defaultValue: string): string {
    const fields = inputString.split('|');
    if (fields.length > 5) {
      return fields[5];
    } else {
      return defaultValue;
    }
  }

  async getLocationInfo(context: Context) {
    LogUtils.i(TAG, 'getLocationInfo start');
    this.locationInfo = await getGeoData(context)
    this.lat = this.locationInfo.latitude
    this.lng = this.locationInfo.longitude
    this.alt = this.locationInfo.altitude
    this.time = systemDateTime.getTime()
    this.address = this.getAddress(this.locationInfo.cityName, 'unknown')
    if (this.locationInfo.cityName === 'unknown') {
      ReportUtil.getInstance().reportSosMakeCallTriggerLocation(LocationReportResultOfSos.FAIL_TO_GET_LOCATION);
    }
    this.sosLocationIndo = {
      lng: this.lng,
      lat: this.lat,
      time: this.time,
      address: this.address,
      alt: this.alt
    }
    return this.sosLocationIndo
  }
}
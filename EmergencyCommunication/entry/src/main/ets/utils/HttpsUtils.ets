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
import http from '@ohos.net.http';
import { BusinessError } from '@ohos.base';
import deviceinfo from '@ohos.deviceInfo';
import { getRandomIntInRange, parseHex } from './Utils';
import { systemDateTime } from '@kit.BasicServicesKit';
import LogUtils from './HiLog';

const TAG = 'HttpsUtils';

export class HttpsUtils {
  private static sInstance: HttpsUtils;
  private static CONNECT_OVERTIME_THRESHOLD: number = 2000;
  private static CHARSET_UTF_8 = 'UTF-8';

  constructor() {
  }

  static getInstance() {
    if (!HttpsUtils.sInstance) {
      HttpsUtils.sInstance = new HttpsUtils();
    }
    return HttpsUtils.sInstance;
  }

  private static getPhoneUserAgent(): string {
    let tempStr = '';
    if ('Release' === deviceinfo.osReleaseType) {
      let model = deviceinfo.marketName;
      if (model.length > 0) {
        tempStr += ' ';
        tempStr += model;
      }
    }
    let fullName = deviceinfo.osFullName;
    if (fullName.length > 0) {
      tempStr += ' Build/';
      tempStr += fullName;
    }
    tempStr += '; ';
    let version = deviceinfo.distributionOSVersion;
    if (version.length > 0) {
      let tempRegExp = new RegExp('^\\d{1}$');
      if (tempRegExp.test(version[0])) {
        tempStr += version;
      } else {
        tempStr += '5.0.0';
      }
    } else {
      tempStr += '1.0';
    }
    return tempStr;
  }

  static getTraceId(): string {
    let seconds: number = systemDateTime.getTime(false) / 1000;
    let random: number = getRandomIntInRange();
    let traceId = (seconds & 0xFFFFFFFF) << 32 | (random & 0xFFFFFFFF);
    return (traceId >= 0) ? traceId.toString(16) : parseHex(traceId, 8);
  }

  /**
   * report by https Post and get response result
   *
   * @param data
   * @param path Report URL
   * @param sign Report sign data in header
   * @param traceId trace id
   */
  public static reportAndGetResponseResult(
    data: Object, path: string, sign: string, traceId: string): Promise<http.HttpResponse> {
    let optionsHeader: Record<string, string> = {
      'content-Type': 'application/json',
      'user-Agent': HttpsUtils.getPhoneUserAgent(),
      'charset': HttpsUtils.CHARSET_UTF_8,
      'packageName': 'com.ohos.emergencycommunication'
    }
    if (sign) {
      optionsHeader.Authorization = sign;
    }
    if (traceId) {
      optionsHeader.traceId = traceId;
    }

    let headerObj = optionsHeader;
    let options: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,
      usingCache: false,
      connectTimeout: HttpsUtils.CONNECT_OVERTIME_THRESHOLD,
      readTimeout: HttpsUtils.CONNECT_OVERTIME_THRESHOLD,
      header: headerObj,
      extraData: data
    };
    try {
      let httpRequest = http.createHttp();
      return new Promise<http.HttpResponse>(
        (resolve: (res: http.HttpResponse) => void, reject: (error: BusinessError) => void) => {
          httpRequest.request(path, options).then((requestRes: http.HttpResponse) => {
            resolve(requestRes);
            httpRequest.destroy();
          }).catch((e: BusinessError) => {
            LogUtils.i(TAG, `BusinessError ${e?.code}`);
            reject(e);
            httpRequest.destroy();
          });
        });
    } catch (e) {
      return Promise.reject(e);
    }
  }
}
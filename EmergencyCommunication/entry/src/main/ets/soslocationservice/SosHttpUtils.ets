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
import LogUtils from '../utils/HiLog';
import { SosInfoBody } from '../serviceextability/EccServiceExtAbility';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { concatUint8Arrays, Encrypted } from './SosEncrypted';
import { util } from '@kit.ArkTS';
import { ReportUtil } from '../utils/ReportUtil';
import { LocationReportResultOfEps, LocationReportResultOfSos } from '../data/CommonData';
import { Sm3Util } from '../utils/Sm3Util';
import EmergencyWarningController from '../control/EmergencyWarningControl';
import { EARTHQUAKE_SHA256_KEY } from '../utils/Constants';


interface NetLocation {
  'macs': string;
}

interface Location {
  'locationStartTime': string;
  'locationEndTime': string;
  'altitude': string;
  'longtitude': string;
  'latitude': string;
}

interface MyJsonObject {
  'channelName': string;
  'channelNo': string;
  'mobile': string;
  'emergencyNum': string;
  'areaCode': string;
  'deviceId': string;
  'device': string;
  'type': string;
  'triggerType': string;
  'callMillisTime': string;
  'traceSessionId': string;
  'traceCount': string;
  'traceEnd': string;
  'netLocation'?: NetLocation;
  'locationList': Location[];
}

interface EpsJsonObject {
  'source': string;
  'caller': string;
  'called': string;
  'device': string;
  'method': string;
  'type': string;
  'lng': number;
  'lat': number;
  'hAccuracy': number;
  'vAccuracy': number;
  'altitude': number;
  'address': string;
  'time': string;
  'extra': string;
  'sign': string;
  'key': string;
}

interface EpsExtraObject {
  'callTime': string
}

interface EpsResponseData {
  'status': number;
  'info': string;
}

const TAG = 'SosHttpsUtils';

export class SosHttpsUtils {
  public isReportSuccess: boolean = false

  // public static async reportSosInfo(sosInfo: SosInfoBody, reportSosInfoCallback: (isSuccess: boolean) => void) {
  //   LogUtils.i(TAG, 'reportSosInfo Start!');
  //   let httpRequest = http.createHttp();
  //   httpRequest.on('headersReceive', (header) => {
  //     LogUtils.i(TAG, 'header: ' + JSON.stringify(header));
  //   });
  //   let data: MyJsonObject = {
  //     'channelName': 'XX',
  //     'channelNo': '3010',
  //     'mobile': sosInfo?.caller,
  //     'emergencyNum': sosInfo?.called,
  //     'areaCode': '0755',
  //     'deviceId': '0000000000000000000000000000000',
  //     'device': sosInfo.device,
  //     'type': 'gps',
  //     'triggerType': 'phone',
  //     'callMillisTime': sosInfo?.firstTime + '',
  //     'traceSessionId': '0000000000000000000000000000000' + sosInfo?.firstTime,
  //     'traceCount': sosInfo?.count + '',
  //     'traceEnd': sosInfo?.tranceEnd,
  //     'netLocation': {
  //       'macs': ''
  //     },
  //     'locationList': [
  //       {
  //         'locationStartTime': sosInfo.time + '',
  //         'locationEndTime': sosInfo.time + '',
  //         'altitude': sosInfo.alt + '',
  //         'longtitude': sosInfo.lng + '',
  //         'latitude': sosInfo.lat + '',
  //       }
  //     ]
  //   }
  //   let md5Sum: cryptoFramework.DataBlob = await Encrypted.sha256Summary(EmergencyWarningController.getInstance()
  //       .getValueFromConfigMap(EARTHQUAKE_SHA256_KEY));
  //   let decrypResult = await Encrypted.aesEcbEncode256(md5Sum, JSON.stringify(data));
  //   let callback = (isSuccess: boolean) => {
  //     reportSosInfoCallback(isSuccess)
  //   }
  //   SosHttpsUtils.httpPost(httpRequest, decrypResult, callback);
  // }

  private static httpPost(httpRequest: http.HttpRequest, aesValue: string, callback: (isSuccess: boolean) => void) {
    LogUtils.i(TAG, 'httpPost Start!');
    let isSuccess = true;
    httpRequest.request(
      EmergencyWarningController.getInstance().mapName2Value.get('location_net_report_url'),
      {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: {
          'channelNo': '3010',
          'data': aesValue,
        },
        expectDataType: http.HttpDataType.OBJECT,
        usingCache: true,
        priority: 1,
        connectTimeout: 60000,
        readTimeout: 60000,
        usingProtocol: http.HttpProtocol.HTTP1_1,
        usingProxy: false,
      }, (err: BusinessError, data: http.HttpResponse) => {
      if (!err) {
        LogUtils.i(TAG, 'Result:' + JSON.stringify(data.result) + 'code:' + JSON.stringify(data.responseCode));
        if (data.responseCode !== 200) {
          LogUtils.i(TAG, 'report false!');
          isSuccess = false
          callback(isSuccess);
        }
        if (data.responseCode === 200) {
          ReportUtil.getInstance().reportSosMakeCallTriggerLocation(LocationReportResultOfSos.SUCCESS);
        } else if (data.responseCode === 504) {
          ReportUtil.getInstance().reportSosMakeCallTriggerLocation(LocationReportResultOfSos.SERVER_RETURN_FAILURE);
        }
        httpRequest.off('headersReceive');
        httpRequest.destroy();
        callback(isSuccess);
      } else {
        ReportUtil.getInstance().reportSosMakeCallTriggerLocation(LocationReportResultOfSos.FAIL_WITH_NO_NETWORK);
        isSuccess = false
        LogUtils.e(TAG, 'error:' + JSON.stringify(err));
        httpRequest.off('headersReceive');
        httpRequest.destroy();
        callback(isSuccess);
      }
    }
    );
  }

  public static async reportEpsInfo(sosInfo: SosInfoBody, phoneNumberWithCountryCode: string,
    reportEpsInfoCallback: (isSuccess: boolean) => void) {
    LogUtils.i(TAG, 'reportEpsInfo Start!');
    let epsKey = EmergencyWarningController.getInstance().mapName2Value.get('eps_key');
    // let httpRequest = http.createHttp();
    // httpRequest.on('headersReceive', (header) => {
    //   LogUtils.i(TAG, 'EpsHeader: ' + JSON.stringify(header));
    // });
    const callerStr = await Sm3Util.doMdByPromise(phoneNumberWithCountryCode);
    let extraData: EpsExtraObject = {
      callTime: sosInfo?.firstTime + '',
    }
    const extra = JSON.stringify(extraData);
    const stringA: string = 'address=' + sosInfo.address + '&altitude=' + sosInfo.alt + '&called=' +
      sosInfo?.called + '&caller=' + callerStr + '&device=' + sosInfo.device + '&extra=' + extra +
      '&hAccuracy=0&lat=' + sosInfo.lat + '&lng=' + sosInfo.lng + '&method=1&source=02&time=' +
      sosInfo?.time + '&type=1&vAccuracy=0&key=' + epsKey;
    const signValue: string = await Sm3Util.doMdByPromise(stringA);
    let newData: EpsJsonObject = {
      address: sosInfo.address,
      altitude: sosInfo.alt,
      called: sosInfo?.called,
      caller: callerStr,
      device: sosInfo.device,
      extra: extra,
      hAccuracy: 0,
      lat: sosInfo.lat,
      lng: sosInfo.lng,
      method: '1',
      sign: signValue,
      source: '02',
      time: sosInfo?.time + '',
      type: '1',
      vAccuracy: 0,
      key: epsKey,
    }
    let callback = (isSuccess: boolean) => {
      reportEpsInfoCallback(isSuccess);
    }
    // SosHttpsUtils.epsHttpPost(httpRequest, newData, callback);
  }

  private static epsHttpPost(httpRequest: http.HttpRequest, aesValue: EpsJsonObject,
    callback: (isSuccess: boolean) => void) {
    LogUtils.i(TAG, 'EPS httpPost Start!');
    let isSuccess = true;
    httpRequest.request(
      EmergencyWarningController.getInstance().mapName2Value.get('eps_report_url'),
      {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: aesValue,
        expectDataType: http.HttpDataType.OBJECT,
        usingCache: true,
        priority: 1,
        connectTimeout: 60000,
        readTimeout: 60000,
        usingProtocol: http.HttpProtocol.HTTP1_1,
        usingProxy: false,
      }, (err: BusinessError, data: http.HttpResponse) => {
      if (!err) {
        LogUtils.i(TAG,
          'EPS Response Result:' + JSON.stringify(data.result) + 'code:' + JSON.stringify(data.responseCode));
        if (data.responseCode !== 200) {
          LogUtils.i(TAG, 'EPS report failed!' + data.responseCode);
          isSuccess = false;
          callback(isSuccess);
        }
        let resultJson: EpsResponseData = {
          status: 0,
          info: ''
        }
        try {
          let result = JSON.stringify(data.result);
          resultJson = JSON.parse(result);
        } catch (error) {
          LogUtils.e(TAG, `JSON parsing failed, code is ${error.code},message is ${error.message}`);
        }
        switch (resultJson.status) {
          case 200:
            LogUtils.e(TAG, 'EPS report success.');
            ReportUtil.getInstance().reportEpsMakeCallTriggerLocation(LocationReportResultOfEps.SUCCESS);
            break;
          case 201:
            LogUtils.e(TAG, 'The supplier not exist.');
            ReportUtil.getInstance()
              .reportEpsMakeCallTriggerLocation(LocationReportResultOfEps.FAIL_WITH_SUPPLIER_NOT_EXIST);
            isSuccess = false;
            break;
          case 202:
            LogUtils.e(TAG, 'Signature verification failed.');
            ReportUtil.getInstance()
              .reportEpsMakeCallTriggerLocation(LocationReportResultOfEps.FAIL_TO_VERIFY_SIGNATURE);
            isSuccess = false;
            break;
          case 203:
            LogUtils.e(TAG, 'Data verification failed.');
            ReportUtil.getInstance().reportEpsMakeCallTriggerLocation(LocationReportResultOfEps.FAIL_TO_VERIFY_DATA);
            isSuccess = false;
            break;
          case 204:
            LogUtils.e(TAG, 'Internal server error.');
            ReportUtil.getInstance().reportEpsMakeCallTriggerLocation(LocationReportResultOfEps.INTERNAL_SERVER_ERROR);
            isSuccess = false;
            break;
          default:
            LogUtils.e(TAG, 'EPS report failed');
            isSuccess = false;
            break;
        }
        httpRequest.off('headersReceive');
        httpRequest.destroy();
        callback(isSuccess);
      } else {
        ReportUtil.getInstance().reportSosMakeCallTriggerLocation(LocationReportResultOfEps.FAIL_WITH_NO_NETWORK);
        isSuccess = false;
        LogUtils.e(TAG, `EPS report error: Code is ${err.code}, message is ${err.message}`);
        httpRequest.off('headersReceive');
        httpRequest.destroy();
        callback(isSuccess);
      }
    }
    );
  }
}

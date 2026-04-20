/**
 * Copyright (c) 2024-2024 Huawei Device Co., Ltd.
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
import { BusinessError } from '@kit.BasicServicesKit';
import LogUtils from './LogUtils';
// import { smartMobilityCommon } from '@kit.CarKit';

const TAG = 'HiCarUtils';

export class HiCarUtils {
  // public static async getHiCarDeviceInfo(): Promise<HiCarDeviceInfo | undefined> {
  //   try {
  //     const awareness: smartMobilityCommon.SmartMobilityAwareness = smartMobilityCommon.getSmartMobilityAwareness();
  //     const info:ESObject = awareness.getSmartMobilityStatus(smartMobilityCommon.SmartMobilityType.HICAR);
  //     const connectStatus = info.status === smartMobilityCommon.SmartMobilityStatus.RUNNING ? true : false;
  //     const displayId: string = info.data?.['DISPLAY_ID'] as string;
  //     const deviceType: string = info.data?.['DEVICE_TYPE'] as string;
  //     return new HiCarDeviceInfo(connectStatus, deviceType, displayId);
  //   } catch (err) {
  //     LogUtils.e(TAG, `getHiCarDeviceInfo fail, err: ${(err as BusinessError).message}`);
  //     return undefined;
  //   }
  // }
}

export class HiCarDeviceInfo {
  public connectStatus: boolean = false;
  public deviceType: string = '';
  public displayId: string = '';

  constructor(connectStatus: boolean, deviceType: string, displayId: string) {
    this.connectStatus = connectStatus;
    this.deviceType = deviceType;
    this.displayId = displayId;
  }
}
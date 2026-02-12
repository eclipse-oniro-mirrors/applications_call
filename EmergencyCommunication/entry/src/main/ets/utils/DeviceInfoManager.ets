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
import { deviceInfo } from '@kit.BasicServicesKit';
import LogUtils from './HiLog';

const TAG = 'DeviceInfoManager';

export default class DeviceInfoManager {
  private static sInstance: DeviceInfoManager;
  private _romVersion: string = '';

  constructor() {
    this.romVersion = DeviceInfoManager.getRomVersion();
  }

  static getInstance() {
    if (DeviceInfoManager.sInstance === undefined) {
      DeviceInfoManager.sInstance = new DeviceInfoManager();
    }
    return DeviceInfoManager.sInstance;
  }

  public get romVersion(): string {
    return this._romVersion;
  }

  private set romVersion(value: string) {
    this._romVersion = value;
  }

  /**
   * 获取系统版本号
   * @returns romVersion, eg: 6.0.0.110
   * */
  private static getRomVersion(): string {
    return `${deviceInfo.majorVersion}.${deviceInfo.seniorVersion}.${deviceInfo.featureVersion}.${deviceInfo.buildVersion}`;
  }
}
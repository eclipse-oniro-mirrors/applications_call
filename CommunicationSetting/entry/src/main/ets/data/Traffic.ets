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
import { NetworkType } from '../constants/CommonConstants';

@Observed
export class SystemAndServiceTraffic {
  public networkType: NetworkType = -1;
  public sysTraffic: number = 0;
  public svcTraffic: number = 0;

  constructor(networkType: NetworkType) {
    this.networkType = networkType;
  }

  public isMobile(): boolean {
    return this.networkType === NetworkType.MOBILE;
  }

  public isWlan(): boolean {
    return this.networkType === NetworkType.WLAN;
  }
}

export class TrafficInfo {
  public name: Resource | undefined = undefined;
  public totalTraffic: string = '';
}
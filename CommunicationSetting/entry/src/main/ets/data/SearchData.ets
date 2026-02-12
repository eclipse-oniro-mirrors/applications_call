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
import { NetworkType, PageIndex } from '../constants/CommonConstants';

export class SearchInfo {
  public slotId: number = -1;
  public pageIndex: number = -1;
  public networkType: number = 0;

  constructor(pageIndex: number, slotId: number, networkType: number) {
    this.slotId = slotId;
    this.pageIndex = pageIndex;
    this.networkType = networkType;
  }

  public isSlotIdDefault() {
    return this.slotId === -1;
  }

  public isTrafficManager(): boolean {
    return this.pageIndex === PageIndex.TRAFFIC_MANAGER;
  }

  public isNetworkAccess(): boolean {
    return this.pageIndex === PageIndex.NETWORK_ACCESS;
  }

  public isDataRankings(): boolean {
    return this.pageIndex === PageIndex.DATA_RANKINGS;
  }

  public isSystemAndServices(): boolean {
    return this.pageIndex === PageIndex.SYSTEM_AND_SERVICES
  }

  public isModeMobile(): boolean {
    return this.networkType === NetworkType.MOBILE;
  }

  public isModeWlan(): boolean {
    return this.networkType === NetworkType.WLAN;
  }

  public isNetworkTypeValueAble(): boolean {
    return this.networkType === NetworkType.MOBILE || this.networkType === NetworkType.WLAN;
  }

  public getNetworkType(): number {
    if (this.networkType) {
      return this.networkType;
    } else {
      return NetworkType.DEFAULT;
    }
  }

  public isMoreSettings(): boolean {
    return this.pageIndex === PageIndex.MORE_SETTINGS
  }
}
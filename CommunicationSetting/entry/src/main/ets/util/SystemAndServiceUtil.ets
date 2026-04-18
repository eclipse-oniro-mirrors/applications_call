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
import { resourceManager } from '@kit.LocalizationKit';
import { LogUtil } from './LogUtil';
import { BusinessError } from '@kit.BasicServicesKit';
import BasicDataSource from '../viewmodel/BasicDataSource';
import { ArrayUtil } from './ArrayUtil';
import { getFlowText } from '../constants/CommonConstants';

const TAG = 'SystemAndServiceUtil';

export interface sysServiceInterface {
  sysServiceInfo: SysAndServiceInfo,
  index: number,
}

export default class SysServiceListDataSource extends BasicDataSource {
  private sysServiceInfos: Array<SysAndServiceInfo> = [];

  public getData(index: number): sysServiceInterface | undefined {
    if (ArrayUtil.isEmpty(this.sysServiceInfos) || index >= this.sysServiceInfos.length || index < 0) {
      LogUtil.info(TAG, 'getData empty or index err');
      return;
    } else {
      return {
        index: index, sysServiceInfo: this.sysServiceInfos[index]
      };
    }
  }

  public totalCount(): number {
    return this.sysServiceInfos.length;
  }

  public refresh(sysAndServicesTemp: Array<SysAndServiceInfo>) {
    LogUtil.info(TAG, ' refresh!');
    this.sysServiceInfos = sysAndServicesTemp;
    this.notifyDataReload();
  }

  public getAllData(): Array<SysAndServiceInfo> {
    return this.sysServiceInfos;
  }
}

export class SysAndServiceInfo {
  public flow: number = 0;
  public category: Resource = $r('app.string.category_system');
  private categoryIndex?: number;

  constructor(flow: number, categoryIndex: number, category: Resource) {
    this.flow = flow;
    this.categoryIndex = categoryIndex;
    this.category = category;
  }

  public static compare(infoA: SysAndServiceInfo, infoB: SysAndServiceInfo) {
    return infoB.flow - infoA.flow;
  }

  public getFlowText() {
    let list = getFlowText(this.flow);
    return list[0] + ' ' + list[1];
  }

  public addFlow(flow: number) {
    this.flow += flow;
  }

  public getCategoryIndex() {
    return this.categoryIndex;
  }
}

export class SysServiceCategoryManager {
  public sysAndServiceArray: SysAndServiceInfo[] = [];
  private categoryMap: Map<number, Resource> = new Map<number, Resource>();

  constructor(sysServiceList: Map<number, number>) {
    this.initCategoryMap();
    this.initSysAndServiceArray(sysServiceList);
  }

  public addCategoryFlows(uid: number, flow: number) {
    let categoryIndex = this.getIndexByUid(uid);
    let i = -1;
    this.sysAndServiceArray.forEach((value, index) => {
      if (categoryIndex === value.getCategoryIndex()) {
        i = index;
      }
    })
    if (i === -1) {
      let info = new SysAndServiceInfo(flow, categoryIndex, this.categoryMap.get(categoryIndex) as Resource);
      this.sysAndServiceArray.push(info);
      return;
    }
    this.sysAndServiceArray[i].addFlow(flow);
  }

  private initCategoryMap() {
    this.categoryMap.set(SysServiceCategory.CATEGORY_SYSTEM, $r('app.string.category_system'));
    this.categoryMap.set(SysServiceCategory.CATEGORY_GENERAL_SERVICE, $r('app.string.category_general_service'));
    this.categoryMap.set(SysServiceCategory.CATEGORY_DEBUG_SYSTEM, $r('app.string.category_debug_system'));
    this.categoryMap.set(SysServiceCategory.CATEGORY_LOCATION_SERVICE, $r('app.string.category_location_service'));
    this.categoryMap.set(SysServiceCategory.CATEGORY_SECURITY_SERVICE, $r('app.string.category_security_service'));
    this.categoryMap.set(SysServiceCategory.CATEGORY_MEDIA_SERVICE, $r('app.string.category_media_service'));
    this.categoryMap.set(SysServiceCategory.CATEGORY_UPDATE, $r('app.string.category_update'));
    this.categoryMap.set(SysServiceCategory.CATEGORY_RTC_SERVICE, $r('app.string.category_rtc_service'));
    this.categoryMap.set(SysServiceCategory.CATEGORY_WLAN_SERVICE, $r('app.string.category_WLAN_service'));
    this.categoryMap.set(SysServiceCategory.CATEGORY_CALL_SERVICE, $r('app.string.category_call_service'));
    this.categoryMap.set(SysServiceCategory.CATEGORY_NFC_SERVICE, $r('app.string.category_nfc_service'));
  }

  private initSysAndServiceArray(sysServiceList: Map<number, number>) {
    this.sysAndServiceArray = [];
    sysServiceList.forEach((flow, uid) => {
      this.addCategoryFlows(uid, flow);
    });
    this.sysAndServiceArray.sort(SysAndServiceInfo.compare);
  }

  private getIndexByUid(uid: number): number {
    let categoryIndex = 0;
    try {
      let resourceManager: resourceManager.ResourceManager = getContext(this).resourceManager;
      categoryIndex = resourceManager.getNumberByName(uid.toString());
    } catch (error) {
      let code = (error as BusinessError).code;
      let message = (error as BusinessError).message;
      LogUtil.error(TAG, `${uid}, categoryIndex failed, error code: ${code}, message: ${message}.`);
    }
    return categoryIndex;
  }
}

/**
 * 0：系统 System
 * 1：通用 General
 * 2：调试系统 Debugging service
 * 3：位置信息服务 Location services
 * 4：安全服务 Security service
 * 5：多媒体服务 Media service
 * 6：软件更新 Update
 * 7：实时通信服务 RTC services
 * 8: WLAN 服务 WLAN service
 * 9: 通话服务 Call service
 * 10: NFC 服务 NFC service
 **/
export enum SysServiceCategory {
  CATEGORY_SYSTEM = 0,
  CATEGORY_GENERAL_SERVICE = 1,
  CATEGORY_DEBUG_SYSTEM = 2,
  CATEGORY_LOCATION_SERVICE = 3,
  CATEGORY_SECURITY_SERVICE = 4,
  CATEGORY_MEDIA_SERVICE = 5,
  CATEGORY_UPDATE = 6,
  CATEGORY_RTC_SERVICE = 7,
  CATEGORY_WLAN_SERVICE = 8,
  CATEGORY_CALL_SERVICE = 9,
  CATEGORY_NFC_SERVICE = 10
}
/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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
import { ArrayUtil } from '../util/ArrayUtil';

import { AppInfo } from './AppInfo';
import BasicDataSource from './BasicDataSource';
import { AppInfoInterface } from './type';
import { LogUtil } from '../util/LogUtil';


const TAG = 'AppInfoListDataSource';

export default class AppInfoListDataSource extends BasicDataSource {
  private appInfos: Array<AppInfo> = [];

  public getData(index: number): AppInfoInterface | undefined {
    if (ArrayUtil.isEmpty(this.appInfos) || index >= this.appInfos.length || index < 0) {
      LogUtil.info(TAG, 'getData empty or index err');
      return;
    } else {
      return {
        index: index, appInfo: this.appInfos[index]
      };
    }
  }

  public totalCount(): number {
    return this.appInfos.length;
  }

  public refresh(appInfoTemp: Array<AppInfo>) {
    LogUtil.info(TAG, ' refresh!');
    this.appInfos = appInfoTemp;
    this.notifyDataReload();
  }

  public getAllData(): Array<AppInfo> {
    return this.appInfos;
  }

  public refreshAccessByUid(uid: number, wifiAccess: boolean, mobileAccess: boolean) {
    for (let i = 0; i < this.appInfos.length; i++) {
      if (this.appInfos[i].uid === uid) {
        this.appInfos[i].wifiAccess = wifiAccess;
        this.appInfos[i].mobileAccess = mobileAccess;
        this.notifyDataChange(i);
        break;
      }
    }
  }

  public changeAccessByUid(uid: number, wifiAccess: boolean, mobileAccess: boolean) {
    for (let i = 0; i < this.appInfos.length; i++) {
      if (this.appInfos[i].uid === uid) {
        this.appInfos[i].wifiAccess = wifiAccess;
        this.appInfos[i].mobileAccess = mobileAccess;
        break;
      }
    }
  }
}
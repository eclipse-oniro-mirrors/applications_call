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
import connection from '@ohos.net.connection';
import { BusinessError } from '@ohos.base';
import LogUtils from './HiLog';

const TAG = 'NetUtils';

export class NetUtils {
  constructor() {
  }

  static async hasValidatedNet() {
    try {
      let data = await connection.getAllNets()
        .catch((err: BusinessError) => {
          LogUtils.e(TAG, 'hasValidatedNet getAllNets failed errCode:' + err.code + ',errMessage:' + err.message);
        });
      if (!data || data.length === 0) {
        return false;
      }
      let itemNumber: Set<connection.NetHandle> = new Set(data);
      let dataNumber: connection.NetHandle[] = Array.from(itemNumber.values());
      for (let i = 0; i < dataNumber.length; i++) {
        let netCapabilities = connection.getNetCapabilitiesSync(dataNumber[i]);
        if (netCapabilities?.networkCap &&
          netCapabilities.networkCap.indexOf(connection.NetCap.NET_CAPABILITY_VALIDATED) > -1) {
          return true;
        }
      }
      return false;
    } catch (e) {
      LogUtils.e(TAG, `hasValidatedNet failed error:${JSON.stringify(e)}`);
      return false;
    }
  }
}

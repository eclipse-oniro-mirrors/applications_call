/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import data from '@ohos.telephony.data';
import { BusinessError } from '@ohos.base';
import { LogUtils } from '@ohos/common/CommonIndex';

const TAG = 'CellularDataServiceProxy';

export async function checkCellularDataEnabled(): Promise<boolean | BusinessError> {
  return new Promise((resolve, reject) => {
    try {
      data.isCellularDataEnabled().then((data) => {
        LogUtils.i(TAG, `isCellularDataEnabled success, promise: data->${JSON.stringify(data)}`);
        resolve(data);
      }).catch((error: BusinessError) => {
        LogUtils.e(TAG, `isCellularDataEnabled fail, promise: err->${JSON.stringify(error)}`);
        reject(error);
      });
    } catch (error) {
      LogUtils.e(TAG, `isCellularDataEnabled fail, promise: err->${JSON.stringify(error)}`);
      reject(error);
    }
  });
}
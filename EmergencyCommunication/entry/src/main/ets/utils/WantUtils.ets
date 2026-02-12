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
import WantAgent, { WantAgent as _WantAgent } from '@ohos.app.ability.wantAgent';
import LogUtils from './HiLog';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'WantUtils';

export class WantUtils {
  public static async getWantAgent(wantAgentInfo: WantAgent.WantAgentInfo) {
    let wantAgent: _WantAgent | void;
    try {
      wantAgent = await WantAgent.getWantAgent(wantAgentInfo).catch((err: BusinessError) => {
        LogUtils.e(TAG,
          `getWantAgent failed, code: ${err?.code}, message: ${err?.message}`);
      });
      return wantAgent;
    } catch (err) {
      LogUtils.e(TAG, `getWantAgent failed! ${err?.code} ${err?.message}`);
      return wantAgent;
    }
  }
}
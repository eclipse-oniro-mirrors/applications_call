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
import { securityGuard } from '@kit.SecurityGuardKit';
import { LogUtils } from '@ohos/common/CommonIndex';

const TAG = 'BehaviorDotting';

export class BehaviorDotting {
  private static behaviorDotting: BehaviorDotting;
  public version = '1.0';
  public eventId = 0x009000002;

  public static getInstance(): BehaviorDotting {
    if (!BehaviorDotting.behaviorDotting) {
      BehaviorDotting.behaviorDotting = new BehaviorDotting();
    }
    return BehaviorDotting.behaviorDotting;
  }

  dottingTimeData(): string {
    let dateStr = new Date().getTime().toString();
    return dateStr;
  }

  setCallForwardDotting(transferState: string) {
    let occurTime = this.dottingTimeData();
    try {
      securityGuard.reportSecurityEvent({
        eventId: this.eventId,
        version: '1.0',
        content: JSON.stringify({
          'occurTime': occurTime,
          'transferState': transferState,
          'setting': 'mail'
        })
      })
    } catch (error) {
      LogUtils.e(TAG, 'reportSecurityEvent error: ' + JSON.stringify(error));
    }

  }
}
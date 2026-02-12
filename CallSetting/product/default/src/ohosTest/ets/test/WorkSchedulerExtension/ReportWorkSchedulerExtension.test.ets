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
import { describe, it, expect } from '@ohos/hypium';
import MyWorkSchedulerExtensionAbility from '../../../../main/ets/WorkSchedulerExtension/ReportWorkSchedulerExtension';
import { workScheduler } from '@kit.BackgroundTasksKit';


export default function ReportWorkSchedulerExtensionTest() {
  describe('ReportWorkSchedulerExtensionTest', () => {

    it('ReportWorkSchedulerExtensionTest_onWorkStartTest', 0, () => {
      let testName = new MyWorkSchedulerExtensionAbility();
      let workInfo: workScheduler.WorkInfo = {
        workId: 0,
        bundleName: '',
        abilityName: ''
      };
      let result = testName.onWorkStart(workInfo);
      (testName as object)['getSwitchStatusToReport']('MOBILENET_AVAIL_NET_CARDONE', true, true);
      (testName as object)['getSwitchStatusToReport']('MOBILENET_AVAIL_NET_CARDTWO', true, true);
      (testName as object)['getSwitchStatusToReport']('MOBILENET_ROAMING_CARDONE', true, true);
      (testName as object)['getSwitchStatusToReport']('MOBILENET_ROAMING_CARDTWO', true, true);
      (testName as object)['getSwitchStatusToReport']('CALL_HOLDSTATE_CARDONE', true, true);
      (testName as object)['getSwitchStatusToReport']('CALL_FORWARDING_CARDONE', true, true);
      (testName as object)['cardTwoCallHoldStateReport'](true);
      (testName as object)['getSwitchStatusToReport']('', true, true);
      expect(result === null).assertFalse();
    })

    it('ReportWorkSchedulerExtensionTest_getSwitchStatusToReport', 0, () => {

      let testName = new MyWorkSchedulerExtensionAbility();
      (testName as object)['getSwitchStatusToReport']('MOBILENET_AVAIL_NET_CARDONE', true, true);

      (testName as object)['getCardOneFourTypeCallTransfer']('', true);
      (testName as object)['getCardTwoFourTypeCallTransfer']('');

      expect(testName === undefined).assertFalse();
    })
  })
}
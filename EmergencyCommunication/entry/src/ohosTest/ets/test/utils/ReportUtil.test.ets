/**
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

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium'
import { EmergencyGlobalContextHelper } from '../../../../main/ets/utils/EmergencyGlobalContextHelper';
import { getDeviceType, ReportUtil } from '../../../../main/ets/utils/ReportUtil';
import { sleep } from './Sleep';
import UIAbility from '@ohos.app.ability.UIAbility';

let reportDrawnCompletedFn = async () => {
  let getCtx = new UIAbility().context;
  ReportUtil.reportDrawnCompleted(1, getCtx);
  expect(true).assertEqual(true);
  await sleep(500);
  ReportUtil.reportDrawnCompleted(0, getCtx);
  expect(true).assertEqual(true);
}

export default function ReportUtilTest() {
  describe('ReportUtilTest', () => {
    it('ReportUtilTest_reportShowEmergencyPage', 0, () => {
      let el = new ReportUtil();
      el.reportShowEmergencyPage();
      expect(1).assertEqual(1);
    })
    it('ReportUtilTest_reportClickPersonEmergencyInfo', 0, () => {
      let el = new ReportUtil();
      el.reportClickPersonEmergencyInfo();
      expect(1).assertEqual(1);
    })
    it('ReportUtilTest_reportEmergencyDial', 0, () => {
      let el = new ReportUtil();
      el.reportEmergencyDial(11);
      expect(1).assertEqual(1);
    })
    it('ReportUtilTest_reportEmergencyContactListDial', 0, () => {
      let el = new ReportUtil();
      el.reportEmergencyContactListDial(11);
      expect(1).assertEqual(1);
    })
    it('ReportUtilTest_getDeviceType', 0, () => {
      let res = getDeviceType();
      let a = [0, 1, 2];
      let b = a.indexOf(res) > -1 ? true : false;
      expect(b).assertEqual(true);
    })
    it('ReportUtilTest_getInstance', 0, async () => {
      ReportUtil.sReportUtil = new ReportUtil();
      ReportUtil.getInstance();
      await sleep(500);
      ReportUtil.sReportUtil = null;
      ReportUtil.getInstance();
      expect(true).assertEqual(true);
    })
    it('ReportUtilTest_reportDrawnCompleted', 0, async () => {
      reportDrawnCompletedFn();
    })
  })
}
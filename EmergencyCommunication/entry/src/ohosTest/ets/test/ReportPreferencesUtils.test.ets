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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium'
import { EmergencyGlobalContextHelper } from '../../../main/ets/utils/EmergencyGlobalContextHelper';
import { common } from '@kit.AbilityKit';
import ReportPreferencesUtils from '../../../main/ets/utils/ReportPreferencesUtils';
import { preferences } from '@kit.ArkData';
import { EMERGENCY_CALL_ABILITY_CONTEXT } from '../../../main/ets/utils/Constants';

let report = ReportPreferencesUtils.getInstance();
let context = EmergencyGlobalContextHelper.getContext()
  .getValue<common.UIAbilityContext>(EMERGENCY_CALL_ABILITY_CONTEXT);
let emptyContext: Context;

export default function ReportPreferencesUtilsTest() {
  beforeAll(() => {
    context = EmergencyGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(EMERGENCY_CALL_ABILITY_CONTEXT);
  })
  describe('ReportPreferencesUtilsTest', () => {

    it('ReportPreferencesUtils_loadReportPreferences', 0, async () => {
      ReportPreferencesUtils.getInstance();
      await report.loadReportPreferences(context);
      await report.loadReportPreferences(context, () => {
      });
      let value: preferences.ValueType = 'test';
      report.getSyncByPreferences('test', value);
      report.putAndFlushInPreferences('test', value);
      report.deleteAndFlushInPreferences('test');
      await report.loadReportPreferences(emptyContext, () => {
      });
      let result = await report.loadReportPreferences(emptyContext);
      report.putAndFlushInPreferences('test', value);
      report.getSyncByPreferences('test', value);
      report.deleteAndFlushInPreferences('test');
      (report as object)['flushReportPreferences']();
      expect(result === null).assertFalse();
    })
  })
}
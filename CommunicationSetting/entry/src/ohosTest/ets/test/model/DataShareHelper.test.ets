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
import { describe, expect, it } from '@ohos/hypium'
import { SlotId, TAG_NAME, Uri } from '../../../../main/ets/constants/CommonConstants'
import DataShareHelper from '../../../../main/ets/model/DataShareHelper'
import { DTGlobalContext } from '../../testability/TestAbility'
import { dataShare } from '@kit.ArkData'
import { settingsDataParam } from '../../../../main/ets/model/SettingsDataModel'
import { SLOT_1 } from '../../../../main/ets/util/TrafficPackageUtil'
import SettingsDataService from '../../../../main/ets/service/SettingsDataService'

export default function DataShareHelperTest() {
  describe('DataShareHelperTest', () => {
    it('DataShareHelperBasicTest', 0, async () => {
      DataShareHelper.release();
      let result =
        await DataShareHelper.getInstance().initSettingDB(DTGlobalContext.getContext().getObject('test') as Context);
      expect(result).assertUndefined();
      DataShareHelper.release();
      let settingDbHelper =
        await dataShare.createDataShareHelper(DTGlobalContext.getContext().getObject('TestContext') as Context,
          Uri.SETTINGS_DATA_URI);

      let result1 = await DataShareHelper.getInstance()
        .initSettingDB(DTGlobalContext.getContext().getObject('TestContext') as Context);
      expect(result1).assertDeepEquals(settingDbHelper);

      let result2 = await DataShareHelper.getInstance()
        .initSettingDB(DTGlobalContext.getContext().getObject('TestContext') as Context);
      expect(result2).assertDeepEquals(settingDbHelper);

    })
  })
}
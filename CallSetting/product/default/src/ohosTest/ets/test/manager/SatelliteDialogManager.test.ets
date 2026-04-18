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
import { window } from '@kit.ArkUI';
import SatelliteDialogManager from '../../../../main/ets/manager/SatelliteDialogManager';

export default function SatelliteDialogManagerTest() {
  let window1 :window.Window;
  describe('SatelliteDialogManagerTest', () => {

    it('SatelliteDialogManagerTest_createSatelliteDialog', 0, async () => {
      let r = await SatelliteDialogManager.getInstance().createSatelliteDialog()
      expect(r == null).assertEqual(true)
    })
    it('SatelliteDialogManagerTest_resizeDisplaySize', 0, async () => {
      let r = await SatelliteDialogManager.getInstance().resizeDisplaySize()
      expect(r == null).assertEqual(true)
    })
    it('SatelliteDialogManagerTest_closeSatelliteDialog', 0, async () => {
      let r = await SatelliteDialogManager.getInstance().closeSatelliteDialog()
      expect(r == null).assertEqual(true)
    })
    it('SatelliteDialogManagerTest_setSatelliteDialogWindowKeepScreenOn', 0, async () => {
      let r :object = (SatelliteDialogManager.getInstance() as object)['setSatelliteDialogWindowKeepScreenOn'](window1);
      expect(r == null).assertTrue();
    })
  })
}
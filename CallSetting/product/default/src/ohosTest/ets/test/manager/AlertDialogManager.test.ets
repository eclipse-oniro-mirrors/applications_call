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
import { SATELLITE_SERVICE_CONTEXT } from '../../../../main/ets/common/constant/CallSettingsConstant';
import { CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import AlertDialogManager from '../../../../main/ets/manager/AlertDialogManager';
import { common } from '@kit.AbilityKit';

export default function AlertDialogManagerTest() {
  describe('AlertDialogManagerTest', () => {

    let manager = AlertDialogManager.getInstance();
    it('AlertDialogManagerTest_removeDialogCallback', 0, () => {
      let testfn = () => {
      };
      let testfn1 = () => {
      };
      let testfn2 = () => {
      };
      (manager as object)['dialogCallbacks'] = [testfn, testfn1]
      manager.removeDialogCallback(testfn);
      manager.removeDialogCallback(testfn2);
      manager.showDialogByDialogType(99);
      manager.dialogType = 1;
      manager.createDialogByType();
      manager.dialogType = 3;
      manager.createDialogByType();
      manager.dialogType = 4;
      manager.createDialogByType();
      manager.dialogType = 2;
      let result = manager.createDialogByType();
      expect(result===null).assertFalse();
    })
    it('AlertDialogManagerTest_private', 0, async () => {
      let context: Context = CallSettingGlobalContextHelper.getContext()
        .getValue<common.ServiceExtensionContext>(SATELLITE_SERVICE_CONTEXT);
      await (manager as object)['createNotifyLeftIcon'](context);
    })
    it('showDialogWindow_test', 0, async () => {
      let result = AlertDialogManager.getInstance().showDialogWindow();
      expect(result === null).assertFalse();
    })
  })
}
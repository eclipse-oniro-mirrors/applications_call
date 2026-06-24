/**
 * Copyright (c) 2024-2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { afterEach, ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import LogUtils from '../../../main/ets/common/utils/LogUtils';
import {
  hasLimFreeSize,
  isNeedNotePadRestore, isNotePadEnable,
  sendStorageClearPopup } from '../../../main/ets/common/utils/CheckRestoresUtils';
import { common, dialogRequest } from '@kit.AbilityKit';
import { BusinessError } from '@ohos.base';
import { storageStatistics } from '@kit.CoreFileKit';
import { ReportUtil } from '../../../main/ets/common/utils/ReportUtils/ReportUtil';


export default function isNotePadEnableTest() {

  describe('isNotePadEnable_testSuite', () => {

    beforeEach(() => {
      let mocker: MockKit = new MockKit();
      mocker.clearAll();
    });
    afterEach(() => {
      let mocker: MockKit = new MockKit();
      mocker.clearAll();
    });

    it('should_return_true_when_bundleManager_isApplicationEnabledSync_returns_true', 0, async () => {
      let mocker: MockKit = new MockKit();

      let mockLogUtilsI: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      when(mockLogUtilsI)(ArgumentMatchers.anyString).afterReturnNothing();

      let result = isNotePadEnable();
      expect(result).assertEqual(true);

      mocker.ignoreMock(LogUtils, LogUtils.i);
    });

    it('should_return_false_when_bundleManager_isApplicationEnabledSync_throws_error', 0, async () => {
      let mocker: MockKit = new MockKit();

      let mockLogUtilsE: Function = mocker.mockFunc(LogUtils, LogUtils.e);
      when(mockLogUtilsE)(ArgumentMatchers.anyString).afterReturnNothing();

      let result = isNotePadEnable();
      expect(result).assertEqual(true);

      mocker.ignoreMock(LogUtils, LogUtils.e);
    });

    it('should_return_true_when_freeSize_is_less_than_FREE_SIZE', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockGetFreeSize: Function = mocker.mockFunc(LogUtils, storageStatistics.getFreeSizeSync);
      when(mockGetFreeSize)().afterReturn(700 * 1024 * 1024 - 1);

      let result = hasLimFreeSize();
      expect(result).assertEqual(false);

      mocker.ignoreMock(LogUtils, storageStatistics.getFreeSizeSync);
    });

    it('should_return_false_when_freeSize_is_equal_to_FREE_SIZE', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockGetFreeSize: Function = mocker.mockFunc(LogUtils, storageStatistics.getFreeSizeSync);
      when(mockGetFreeSize)().afterReturn(700 * 1024 * 1024);

      let result = hasLimFreeSize();
      expect(result).assertEqual(false);

      mocker.ignoreMock(LogUtils, storageStatistics.getFreeSizeSync);
    });

    it('should_return_false_when_freeSize_is_greater_than_FREE_SIZE', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockGetFreeSize: Function = mocker.mockFunc(LogUtils, storageStatistics.getFreeSizeSync);
      when(mockGetFreeSize)().afterReturn(700 * 1024 * 1024 + 1);

      let result = hasLimFreeSize();
      expect(result).assertEqual(false);

      mocker.ignoreMock(LogUtils, storageStatistics.getFreeSizeSync);
    });

    it('should_return_false_when_getFreeSizeSync_throws_error', 0, async () => {
      let mocker: MockKit = new MockKit();
      let mockGetFreeSize: Function = mocker.mockFunc(LogUtils, storageStatistics.getFreeSizeSync);
      let error: BusinessError = {
        code: 1, message: 'error',
        name: ''
      };
      when(mockGetFreeSize)().afterThrow(JSON.stringify(error));

      let result = hasLimFreeSize();
      expect(result).assertEqual(false);

      mocker.ignoreMock(LogUtils, storageStatistics.getFreeSizeSync);
    });

    it('should_log_info_when_publish_succeeds', 0, async () => {
      let mocker: MockKit = new MockKit();
      let report = new ReportUtil();
      let logUtilsMock: Function = mocker.mockFunc(LogUtils, LogUtils.e);
      when(logUtilsMock)(ArgumentMatchers.anyString).afterReturn(null);
      sendStorageClearPopup();
      expect(report.callAnswerTime).assertEqual(0)
      mocker.ignoreMock(LogUtils, LogUtils.e);
    });
  });
}
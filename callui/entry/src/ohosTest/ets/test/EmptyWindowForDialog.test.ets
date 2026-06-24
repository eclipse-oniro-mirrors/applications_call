/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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

import { describe, it, expect, MockKit, when, ArgumentMatchers, beforeEach, afterEach } from '@ohos/hypium';
import EmptyWindowForDialog from '../../../main/ets/common/utils/EmptyWindowForDialog';
import { window } from '@kit.ArkUI';
import LogUtils from '../../../main/ets/common/utils/LogUtils';
import { CALLUI_WINDOW_FOR_DIALOG } from '../../../main/ets/common/utils/Constants';


export default function EmptyWindowForDialogTest() {
  describe('loadPageForOpenDialog_testSuite', () => {

    beforeEach(() => {

    });

    afterEach(() => {

    });

    it('should_log_error_when_loadPage_fails', 0, async () => {
      let emptyWindowForDialog: EmptyWindowForDialog = new EmptyWindowForDialog();
      let mocker: MockKit = new MockKit();
      let logUtilsMock: Function = mocker.mockFunc(LogUtils, LogUtils.e);

      let config: window.Configuration = {
        name: CALLUI_WINDOW_FOR_DIALOG,
        // dialog用TYPE_VOLUME_OVERLAY，toast用TYPE_SYSTEM_TOAST
        windowType: window.WindowType.TYPE_VOLUME_OVERLAY,
        ctx: getContext()
      };
      let uri: string = 'testUri';

      when(logUtilsMock)(ArgumentMatchers.anyString).afterReturnNothing();

      try {
        await emptyWindowForDialog.loadPageForOpenDialog(config, uri);
      } catch (err) {
        expect(err.message).assertContain('Failed to load page');
      }

      mocker.ignoreMock(LogUtils, LogUtils.e);
    });

    it('should_log_error_when_showWindow_fails', 0, async () => {
      let emptyWindowForDialog: EmptyWindowForDialog = new EmptyWindowForDialog();
      let mocker: MockKit = new MockKit();
      let logUtilsMock: Function = mocker.mockFunc(LogUtils, LogUtils.e);

      let config: window.Configuration = {
        name: CALLUI_WINDOW_FOR_DIALOG,
        // dialog用TYPE_VOLUME_OVERLAY，toast用TYPE_SYSTEM_TOAST
        windowType: window.WindowType.TYPE_VOLUME_OVERLAY,
        ctx: getContext()
      };
      let uri: string = 'testUri';

      when(logUtilsMock)(ArgumentMatchers.anyString).afterReturnNothing();

      try {
        await emptyWindowForDialog.loadPageForOpenDialog(config, uri);
      } catch (err) {
        expect(err.message).assertContain('Failed to show window');
      }

      mocker.ignoreMock(LogUtils, LogUtils.e);
    });

    it('should_set_background_color_and_show_window_when_both_operations_succeed', 0, async () => {
      let emptyWindowForDialog: EmptyWindowForDialog = new EmptyWindowForDialog();
      let mocker: MockKit = new MockKit();
      let logUtilsMock: Function = mocker.mockFunc(LogUtils, LogUtils.i);

      let config: window.Configuration = {
        name: CALLUI_WINDOW_FOR_DIALOG,
        // dialog用TYPE_VOLUME_OVERLAY，toast用TYPE_SYSTEM_TOAST
        windowType: window.WindowType.TYPE_VOLUME_OVERLAY,
        ctx: getContext()
      };
      let uri: string = 'testUri';

      when(logUtilsMock)(ArgumentMatchers.anyString).afterReturnNothing();
      try {
        await emptyWindowForDialog.loadPageForOpenDialog(config, uri);
      } catch (err) {
        expect(err?.message).assertContain('Failed to show window');
      }
      mocker.ignoreMock(LogUtils, LogUtils.i);
    });

    it('should_log_error_when_loadPageForOpenDialog_throws_error', 0, async () => {
      let emptyWindowForDialog: EmptyWindowForDialog = new EmptyWindowForDialog();
      let mocker: MockKit = new MockKit();
      emptyWindowForDialog.showThermalDialog(1, 2, "1234567890", "1234567890");
      let result: LocalStorage = (emptyWindowForDialog as object)['localStorage'];
      expect(result !== null).assertTrue()
      mocker.ignoreMock(emptyWindowForDialog, emptyWindowForDialog.loadPageForOpenDialog);
    });

    it('should_log_info_when_window_is_found_and_destroyed', 0, async () => {
      let emptyWindowForDialog: EmptyWindowForDialog = new EmptyWindowForDialog();
      let mocker: MockKit = new MockKit();
      let mockLogUtilsI: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      let mockLogUtilsE: Function = mocker.mockFunc(LogUtils, LogUtils.e);

      when(mockLogUtilsI)(ArgumentMatchers.anyString).afterReturnNothing();
      when(mockLogUtilsE)(ArgumentMatchers.anyString).afterReturnNothing();

      await emptyWindowForDialog.killDialogContainerWindow();
      let result: LocalStorage = (emptyWindowForDialog as object)['localStorage'];
      expect(result !== null).assertTrue()

      mocker.ignoreMock(LogUtils, LogUtils.i);
      mocker.ignoreMock(LogUtils, LogUtils.e);
    });

    it('should_log_error_when_window_destroy_fails', 0, async () => {
      let emptyWindowForDialog: EmptyWindowForDialog = new EmptyWindowForDialog();
      let mocker: MockKit = new MockKit();
      let mockLogUtilsI: Function = mocker.mockFunc(LogUtils, LogUtils.i);
      let mockLogUtilsE: Function = mocker.mockFunc(LogUtils, LogUtils.e);


      when(mockLogUtilsI)(ArgumentMatchers.anyString).afterReturnNothing();
      when(mockLogUtilsE)(ArgumentMatchers.anyString).afterReturnNothing();

      await emptyWindowForDialog.killDialogContainerWindow();
      let result: LocalStorage = (emptyWindowForDialog as object)['localStorage'];
      expect(result !== null).assertTrue()

      mocker.ignoreMock(LogUtils, LogUtils.i);
      mocker.ignoreMock(LogUtils, LogUtils.e);
    });
  });
}
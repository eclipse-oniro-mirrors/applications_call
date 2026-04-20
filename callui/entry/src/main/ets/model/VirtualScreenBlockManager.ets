/**
 * Copyright (c) 2023-2025 Huawei Device Co., Ltd.
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

import { display, window } from '@kit.ArkUI';
import LogUtils from '../common/utils/LogUtils';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = 'VirtualScreenBlockService';

export class VirtualScreenBlockManager {
  private static virtualScreenBlockService: VirtualScreenBlockManager;

  public static getInstance(): VirtualScreenBlockManager {
    if (!VirtualScreenBlockManager.virtualScreenBlockService) {
      VirtualScreenBlockManager.virtualScreenBlockService = new VirtualScreenBlockManager();
    }
    return VirtualScreenBlockManager.virtualScreenBlockService;
  }

  public constructor() {
  }

  /**
   * 将窗口添加到禁止投屏显示的名单中，被添加的窗口无法在投屏时显示。
   * @param windowObj 窗口对象
   */
  public addVirtualScreenBlocklist(windowObj: window.Window) {
    if (!windowObj) {
      LogUtils.e(TAG, `addVirtualScreenBlocklist windowObj is null`);
      return;
    }
    try {
      const windowIds = [windowObj.getWindowProperties().id];
      display.addVirtualScreenBlocklist(windowIds).then(() => {
        LogUtils.i(TAG, 'Succeeded in adding virtual screen blocklist.');
      }).catch((err: BusinessError) => {
        LogUtils.e(TAG, `Failed to add virtual screen blocklist. Code: ${err?.code}, msg: ${err?.message}`);
      })
    } catch (err) {
      LogUtils.e(TAG, `getWindowProperties failde, err code: ${err?.code}, msg: ${err?.message}`);
    }
  }

  /**
   * 将窗口从禁止投屏显示的名单中移除
   * @param windowObj 窗口对象
   */
  public removeVirtualScreenBlocklist(windowObj: window.Window) {
    if (!windowObj) {
      LogUtils.e(TAG, `addVirtualScreenBlocklist windowObj is null`);
      return;
    }
    try {
      const windowIds = [windowObj.getWindowProperties().id];
      display.removeVirtualScreenBlocklist(windowIds).then(() => {
        LogUtils.i(TAG, 'removeVirtualScreenBlocklist success.');
      }).catch((err: BusinessError) => {
        LogUtils.e(TAG, `Failed to remove virtual screen blocklist. Code:${err?.code}, message:${err?.message}`);
      });
    } catch (err) {
      LogUtils.e(TAG, `removeVirtualScreenBlocklist failed. Code:${err?.code}, message:${err?.message}`);
    }
  }
}
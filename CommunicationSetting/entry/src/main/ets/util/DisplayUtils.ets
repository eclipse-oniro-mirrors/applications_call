/*
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
import { display } from '@kit.ArkUI';
import { settings } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { isDevicePortrait, isTablet } from './DeviceUtil';
import { LogUtil } from './LogUtil';
import StringUtil from './StringUtil';
import ScreenAdapterUtils from './ScreenAdapterUtils';

const TAG = 'DisplayUtils';

export class DisplayUtils {
  /**
   * 是否处于设置分栏
   *
   * @param context 上下文
   * @return boolean true: 设置分栏, false: 全屏显示
   */
  public static isSplit(context: common.Context): boolean {
    let foldable: boolean = false;
    let status: number = display.FoldStatus.FOLD_STATUS_UNKNOWN;
    try {
      foldable = display.isFoldable();
      status = display.getFoldStatus();
    } catch (exception) {
      console.error('Failed to check display status. Code: ' + JSON.stringify(exception));
    }
    LogUtil.info(TAG, `foldable: ${foldable}, status: ${status}`);
    if (foldable && ScreenAdapterUtils.isNewFormFoldPhone()) {
      return false;
    }
    if (foldable && (status === display.FoldStatus.FOLD_STATUS_EXPANDED ||
      status === display.FoldStatus.FOLD_STATUS_HALF_FOLDED)) {
      LogUtil.info(TAG, `isSplit,fold expanded or half folded.`);
      return true;
    }
    if (isTablet()) {
      let currentDpiStr = settings.getValueSync(context, 'user_set_dpi_value', '');
      let currentDpi = StringUtil.isEmpty(currentDpiStr) ? 0 : Number(currentDpiStr);
      const PORTRAIT_NO_SPLIT_DPI = 480;
      const isSplit = !isDevicePortrait() || currentDpi < PORTRAIT_NO_SPLIT_DPI;
      LogUtil.info(TAG, `isSplit = ${JSON.stringify(isSplit)}`);
      return isSplit;
    }
    return false;
  }

  /**
   * 注册折叠屏展开状态监听
   */
  public static registerFoldStatusChanged() {
    let foldable: boolean = false;
    try {
      foldable = display.isFoldable();
    } catch (exception) {
      console.error('Failed to check is foldable or not. Code: ' + JSON.stringify(exception));
    }
    if (!foldable) {
      LogUtil.info(TAG, 'registerFoldStatusChanged is not a folded phone');
      return;
    }
    try {
      display.on('foldStatusChange', (foldStatus: display.FoldStatus) => {
        LogUtil.info(TAG, `onFoldStatusChanged foldStatus=${foldStatus}`);
        AppStorage.setOrCreate('foldStatus', foldStatus);
      });
    } catch (exception) {
      LogUtil.error(TAG, 'registerFoldStatusChanged failed error=' + JSON.stringify(exception));
    }
  }

  /**
   * 解除注册折叠屏展开状态监听
   */
  public static unregisterFoldStatusChanged() {
    let foldable: boolean = false;
    try {
      foldable = display.isFoldable();
    } catch (exception) {
      console.error('Failed to check is foldable or not. Code: ' + JSON.stringify(exception));
    }
    if (!foldable) {
      LogUtil.info(TAG, 'unregisterFoldStatusChanged is not a folded phone');
      return;
    }
    try {
      display.off('foldStatusChange');
    } catch (exception) {
      LogUtil.error(TAG, 'registerFoldStatusChanged fFailed error=' + JSON.stringify(exception));
    }
    AppStorage.delete('foldStatus');
  }
}
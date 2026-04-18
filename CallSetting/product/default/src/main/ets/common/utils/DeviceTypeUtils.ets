/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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
import { LogUtils } from '@ohos/common/CommonIndex';
import deviceInfo from '@ohos.deviceInfo'
import SystemParameterEnhance from '@ohos.systemParameterEnhance';
import { display } from '@kit.ArkUI';
import { StringUtil } from './StringUtil';
import { settings } from '@kit.BasicServicesKit';
import { screenLock } from '@kit.BasicServicesKit';
import ScreenAdapterUtils from './ScreenAdapterUtils';

const TAG = 'DeviceTypeUtils';
const DEVICE_MODE = 'ALN';
/**
 * 用户调节显示大小时设置的DPI
 */
const USER_SET_DPI_VALUE: string = 'user_set_dpi_value';

/**
 * Get deviceType info
 *
 * @return { String } deviceTypeInfo
 */
export function getDeviceTypeInfo() {
  const deviceTypeInfo = deviceInfo.deviceType;
  LogUtils.i(TAG, 'the value of the deviceType is :' + deviceTypeInfo);
  return deviceTypeInfo;
}

/**
 * Get isTablet
 *
 * @return { Boolean } isTablet
 */
export function isTablet() {
  const deviceTypeInfo = getDeviceTypeInfo();
  const isTablet = deviceTypeInfo === 'tablet';
  LogUtils.i(TAG, 'the value of the isTablet is :' + isTablet);
  return isTablet;
}

/**
 * Get device mode
 *
 * @return { boolean } is aln device
 */
export function isALNDevice(): boolean {
  let ret: string = SystemParameterEnhance.getSync('const.build.product', '0');
  LogUtils.i(TAG, 'the value of isALNDevice is :' + JSON.stringify(ret === DEVICE_MODE));
  return ret === DEVICE_MODE;
}

export function isPC(): boolean {
  return getDeviceTypeInfo() === '2in1';
}

/**
 * 获取settings表配置项
 *
 * @param context 环境上下文
 * @param key 配置项键值
 * @param defaultValue 默认值
 * @return 配置项值
 */
export function getDataShareValue(context: Context, key: string, defaultValue?: string): string {
  let defVal: string = defaultValue ?? '';
  if (context === undefined || StringUtil.isEmpty(key)) {
    return defVal;
  }
  try {
    return settings.getValueSync(context, key, defVal);
  } catch (err) {
    LogUtils.e(TAG, `getDataShareValue error: ${err?.code} ${err?.message}`);
    return defVal;
  }
}

/**
 * 当前设备是否为竖屏
 *
 * @return true: 竖屏  false: 横屏
 */
export function isDevicePortrait(): boolean {
  try {
    const orientation: display.Orientation = display.getDefaultDisplaySync().orientation;
    if (orientation === display.Orientation.LANDSCAPE || orientation === display.Orientation.LANDSCAPE_INVERTED) {
      return false;
    }
  } catch (err) {
    LogUtils.e(TAG, `isDevicePortrait failed. error: ${err?.code} ${err?.message}`);
  }
  return true;
}

/**
 * 是否处于设置分栏
 *
 * @param context 上下文
 * @return boolean true: 设置分栏, false: 全屏显示
 */
export function isSplit(context: Context): boolean {
  if (isPC()) {
    return true;
  }
  try {
    if (ScreenAdapterUtils.isNewFormFoldPhone()) {
      return false;
    }
    if (display.isFoldable() && (display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_EXPANDED ||
      display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_HALF_FOLDED )) {
      return true;
    }
    if (isTablet()) {
      let currentDpiStr = getDataShareValue(context, USER_SET_DPI_VALUE);
      let currentDpi = StringUtil.isEmpty(currentDpiStr) ? 0 : Number(currentDpiStr);
      const PORTRAIT_NO_SPLIT_DPI = 480;
      return !isDevicePortrait() || currentDpi < PORTRAIT_NO_SPLIT_DPI;
    }
  } catch (err) {
    LogUtils.e(TAG, `isSplit error: ${err?.code} ${err?.message}`);
  }
  return false;
}

export function isScreenLocked(): boolean {
  try {
    return screenLock.isLocked();
  } catch (err) {
    LogUtils.e(TAG, 'isScreenLocked failed, error code: ' + err.code);
    return false;
  }
}
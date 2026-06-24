/**
 * Copyright (c) 2025-2025 Huawei Device Co., Ltd.
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

import common from '@ohos.app.ability.common';
import Utils from '../common/utils/utils';
import settings from '@ohos.settings';
import * as Constants from '../common/utils/Constants';
import * as DeviceTypeConst from '../common/constant/DeviceTypeConst';
import LogUtils from '../common/utils/LogUtils';
import { AudioDevice } from './audio/AudioDeviceType';

const TAG = 'PrivacyEnhancedManager';

const VALID_DEVICE_TYPES = [
  DeviceTypeConst.DEVICE_BLUETOOTH_SCO,
  DeviceTypeConst.DEVICE_DISTRIBUTED_XINGSHAN,
];

export class PrivacyEnhancedCallManager {
  private static instance: PrivacyEnhancedCallManager | null = null;

  private isRegistered: boolean = false;

  private constructor() {
  }

  public static getInstance(): PrivacyEnhancedCallManager {
    if (!PrivacyEnhancedCallManager.instance) {
      PrivacyEnhancedCallManager.instance = new PrivacyEnhancedCallManager();
    }
    return PrivacyEnhancedCallManager.instance;
  }

  public updateCurrentAudioDevice(device: AudioDevice): void {
    LogUtils.i(TAG, `updateCurrentAudioDevice: [${device.deviceType}]`);
    this.updateState(device);
    if (this.isValidDevice(device)) {
      this.addTwoWayStateChangeListener();
    } else {
      this.removeTwoWayStateChangeListener();
    }
  }

  public getTwoWayState(): boolean {
    const context = Utils.getInstance().getContext() as common.UIAbilityContext;
    if (!context) {
      LogUtils.e(TAG, `getTwoWayStateFailed: [context invalid]`);
      return false;
    }
    try {
      const result = settings.getValueSync(context, Constants.TOW_WAY_PRIVACY_ENHANCED_CALL, '0');
      LogUtils.i(TAG, `getTwoWayState: [${result}]`);
      return result === '1';
    } catch (error) {
      LogUtils.e(TAG, `getTwoWayStateFailed: [${error.code}][${error.message}]`);
    }
    return false;
  }

  private isValidDevice(device: AudioDevice) {
    return VALID_DEVICE_TYPES.includes(device.deviceType);
  }

  private updateState(device?: AudioDevice): void {
    if (device && !this.isValidDevice(device)) {
      AppStorage.setOrCreate<boolean>('TwoWayPrivacyEnhancedCall', false);
      return;
    }
    const state = this.getTwoWayState();
    AppStorage.setOrCreate<boolean>('TwoWayPrivacyEnhancedCall', state);
  }

  private addTwoWayStateChangeListener(): void {
    if (this.isRegistered) {
      return;
    }
    const context = Utils.getInstance().getContext() as common.UIAbilityContext;
    if (!context) {
      LogUtils.e(TAG, `addTwoWayStateChangeListenerFailed: [context invalid]`);
      return;
    }
    try {
      this.isRegistered = settings.registerKeyObserver(context, Constants.TOW_WAY_PRIVACY_ENHANCED_CALL,
        settings.domainName.DEVICE_SHARED, () => {
          this.updateState();
        });
      LogUtils.i(TAG, `addTwoWayStateChangeListener: [${this.isRegistered}]`);
    } catch (error) {
      LogUtils.e(TAG, `addTwoWayStateChangeListenerFailed: [${error.code}][${error.message}]`);
    }
  }

  private removeTwoWayStateChangeListener(): void {
    if (!this.isRegistered) {
      return;
    }
    const context = Utils.getInstance().getContext() as common.UIAbilityContext;
    if (!context) {
      LogUtils.e(TAG, `removeTwoWayStateChangeListenerFailed: [context invalid]`);
      return;
    }
    try {
      const result = settings.unregisterKeyObserver(context, Constants.TOW_WAY_PRIVACY_ENHANCED_CALL,
        settings.domainName.DEVICE_SHARED);
      LogUtils.i(TAG, `removeTwoWayStateChangeListener: [${result}]`);
      this.isRegistered = !result;
    } catch (error) {
      LogUtils.e(TAG, `removeTwoWayStateChangeListenerFailed: [${error.code}][${error.message}]`);
    }
  }
}
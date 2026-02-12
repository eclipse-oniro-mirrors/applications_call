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

import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import { LogUtils, MobileDataGlobalContextHelper, Constants } from '@ohos/common/CommonIndex';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import SatelliteSearchManager from '../manager/SatelliteSearchManager';
import display from '@ohos.display';
import { DisplayUtil } from '../common/utils/DisplayUtil';
import { BusinessError } from '@kit.BasicServicesKit';
import { PermissionVerifyManager } from '../manager/PermissionVerifyManager';
import { Configuration } from '@kit.AbilityKit';

const TAG = 'SatelliteUiExtentionAbility';

/**
 * 畅连北斗卫星消息拉起天通寻星页面对应的UIExtensionAbility
 *
 * @since 2024-05-09
 */
export default class SatelliteUiExtentionAbility extends UIExtensionAbility {
  private isNeedUpdate: boolean = true;
  // private preFoldStatus: number = display.FoldStatus.FOLD_STATUS_UNKNOWN;

  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    LogUtils.i(TAG, 'onSessionCreate.');
    if (!want || !session) {
      LogUtils.e(TAG, 'onSessionCreate param is invalid.');
      return;
    }
    const callerBundleName: string | undefined = want.parameters?.['ohos.aafwk.param.callerBundleName'] as string;
    LogUtils.i(TAG, `onSessionCreate callerBundleName: ${callerBundleName}`);
    const isVerify: boolean =
      PermissionVerifyManager.getInstance().checkCallerWantParams('SatelliteUiExtentionAbility', callerBundleName);
    if (!isVerify) {
      LogUtils.w(TAG, 'the caller bundle name is not verify');
      return;
    }
    if (DisplayUtil.isFoldable()) {
      try {
        // this.preFoldStatus = display.getFoldStatus();
      } catch {
        LogUtils.e(TAG, 'failed to get fold status');
      }
    }
    this.addFoldStatusChangeListener();
    MobileDataGlobalContextHelper.getContext()
      .set<common.UIExtensionContext>(Constants.SETTINGS_ABILITY_CONTEXT, this.context);
    let storage: LocalStorage = new LocalStorage({
      'session': session,
      'parameters': want.parameters
    } as Record<string, UIExtensionContentSession | Object>);
    session.loadContent('pages/SatelliteDialog', storage);
    AppStorage.setOrCreate('currentColorMode', this.context.config.colorMode);
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    LogUtils.i(TAG, `onConfigurationUpdate.`);
    AppStorage.setOrCreate('currentColorMode', newConfig?.colorMode);
  }

  onSessionDestroy() {
    LogUtils.i(TAG, 'onSessionDestroy.');
    this.removeFoldStatusChangeListener();
  }

  onBackground(): void {
    LogUtils.i(TAG, 'onBackground.');
    this.updateSatelliteNeedEndCallback();
  }

  /**
   * Add fold status change listener
   */
  private addFoldStatusChangeListener(): void {
    if (!DisplayUtil.isFoldable()) {
      return;
    }
    LogUtils.i(TAG, 'addFoldStatusChangeListener.');
    try {
      // display.on('foldStatusChange', (foldStatus: display.FoldStatus) => {
      //   LogUtils.i(TAG, `addFoldStatusChangeListener preFoldStatus: ${this.preFoldStatus}, foldStatus: ${foldStatus}`);
      //   if (this.isAbnormalInterruption(foldStatus)) {
      //     this.updateSatelliteNeedEndCallback();
      //   }
      // })
    } catch (error) {
      const err = error as BusinessError
      LogUtils.e(TAG, `addFoldStatusChangeListener fail, code: ${err?.code}, msg: ${err?.message}`);
    }
  }

  /**
   * Is abnormal interruption
   *
   * @param foldStatus
   */
  private isAbnormalInterruption(foldStatus: display.FoldStatus): boolean {
    // if ((this.preFoldStatus === display.FoldStatus.FOLD_STATUS_FOLDED &&
    //   foldStatus === display.FoldStatus.FOLD_STATUS_HALF_FOLDED) ||
    //   (this.preFoldStatus === display.FoldStatus.FOLD_STATUS_EXPANDED &&
    //     foldStatus === display.FoldStatus.FOLD_STATUS_FOLDED) ||
    //   (this.preFoldStatus === display.FoldStatus.FOLD_STATUS_HALF_FOLDED &&
    //     foldStatus === display.FoldStatus.FOLD_STATUS_FOLDED)) {
    //   return true;
    // }
    return false;
  }

  /**
   * Remove fold status change listener
   */
  private removeFoldStatusChangeListener(): void {
    if (!DisplayUtil.isFoldable()) {
      return;
    }
    LogUtils.i(TAG, 'removeFoldStatusChangeListener.');
    try {
      // display.off('foldStatusChange');
    } catch (error) {
      const err = error as BusinessError
      LogUtils.e(TAG, `removeFoldStatusChangeListener fail, code: ${err?.code}, msg: ${err?.message}`);
    }
  }

  /**
   * Update satellite need end callback
   */
  private updateSatelliteNeedEndCallback(): void {
    if (!this.isNeedUpdate) {
      return;
    }
    SatelliteSearchManager.getInstance().updateSatelliteNeedEndCallback(true);
    this.isNeedUpdate = false;
  }
}

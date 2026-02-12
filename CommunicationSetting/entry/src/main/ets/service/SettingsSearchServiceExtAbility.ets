/**
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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
import ServiceExtensionAbility from '@ohos.app.ability.ServiceExtensionAbility';
import Want from '@ohos.app.ability.Want';
import { LogUtil } from '../util/LogUtil';
import { sim } from '@kit.TelephonyKit';
import { QueryName, TAG_NAME, UNDERLINE } from '../constants/CommonConstants';
import { settings } from '@kit.BasicServicesKit';
import SettingsSearchUtils from '../util/SettingsSearchUtils';
import { JSON } from '@kit.ArkTS';

const TAG = 'SettingsSearchServiceExtAbility';

export default class SettingsSearchServiceExtAbility extends ServiceExtensionAbility {
  private callback = () => {
    this.context.terminateSelf();
  };

  onRequest(want: Want, startId: number): void {
    this.checkItems();
  }

  private async checkItems(): Promise<void> {
    try {
      const maxSimCount = sim.getMaxSimCount();
      let isMoreSettingsEnabled = false;
      let isLimitReminderEnabled = false;
      for (let index = 0; index < maxSimCount; index++) {
        if (sim.hasSimCardSync(index)) {
          isMoreSettingsEnabled = true;
          if (await this.isShowLimitReminder(index)) {
            isLimitReminderEnabled = true;
          }
        }
      }
      if (isMoreSettingsEnabled) {
        if (isLimitReminderEnabled) {
          SettingsSearchUtils.enableAllItemsInMoreSettings(this.context, true, this.callback);
        } else {
          SettingsSearchUtils.enableMoreAndPackageSettings(this.context, true, this.callback);
          SettingsSearchUtils.enableLimitReminder(this.context, false, this.callback);
        }
      } else {
        SettingsSearchUtils.enableAllItemsInMoreSettings(this.context, false, this.callback);
      }
    } catch (err) {
      LogUtil.error(TAG, `checkItems err=${JSON.stringify(err)}`);
    }
  }

  public async isShowLimitReminder(slotId: number): Promise<boolean> {
    try {
      let accountInfo = await sim.getSimAccountInfo(slotId);
      let simId = accountInfo?.simId ?? 0;
      let key = TAG_NAME + simId + UNDERLINE + QueryName.monthly_limited_traffic;
      let value = settings.getValueSync(this.context, key, '');
      return value !== null && value !== '';
    } catch (err) {
      LogUtil.error(TAG, `isShowLimitReminder err=${JSON.stringify(err)}`)
      return false;
    }
  }
}
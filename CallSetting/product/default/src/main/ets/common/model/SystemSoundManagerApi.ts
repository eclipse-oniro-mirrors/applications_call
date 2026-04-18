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

// @ts-ignore
import SystemSoundManager from '@ohos.multimedia.systemSoundManager';

// @ts-ignore
const type1: SystemSoundManager.RingtoneType = SystemSoundManager?.RingtoneType?.RINGTONE_TYPE_SIM_CARD_0;
// @ts-ignore
const type2: SystemSoundManager.RingtoneType = SystemSoundManager?.RingtoneType?.RINGTONE_TYPE_SIM_CARD_1;

export function getSystemRingtoneApi(context, slotId, callBack: (ringName: string) => void): void {
  // @ts-ignore
  let systemSoundManagerInstance: SystemSoundManager.SystemSoundManager | undefined =
  SystemSoundManager?.getSystemSoundManager();
  try {
    // @ts-ignore
    systemSoundManagerInstance?.getDefaultRingtoneAttrs(context, slotId ? type2 : type1,).then((data: ToneAttrs) => {
      callBack(data.getTitle().replace(new RegExp('_', 'g'), ' '));
    }, () => {
      callBack('');
    });
  } catch (jsonError) {
    callBack('');
  }
}
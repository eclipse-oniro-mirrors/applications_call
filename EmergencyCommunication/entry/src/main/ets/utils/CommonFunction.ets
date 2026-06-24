/*
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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
import { EmergencyInfoStruct } from './ClassStruct'
import Intl from '@ohos.intl';
import I18n from '@ohos.i18n';
import LogUtils from './HiLog';

const TAG = 'CommonFunction'
export function updateObjectValue(key: string, value: string | number | undefined, obj: EmergencyInfoStruct) {
  if ((obj as Record<string, string | number | undefined>)[key] !== undefined) {
    (obj as Record<string, string | number | undefined>)[key] = value;
  }
  return obj
}

export function formatNumberByLanguage(formatNumber: number | string) {
  const systemLanguage = I18n.System.getAppPreferredLanguage();
  LogUtils.i(TAG, `systemLanguage: ${systemLanguage}`);
  const options: Intl.NumberOptions = { locale: 'Locale' };
  const numberFormat: Intl.NumberFormat = new Intl.NumberFormat(systemLanguage, options);
  return numberFormat.format(Number(formatNumber));
}
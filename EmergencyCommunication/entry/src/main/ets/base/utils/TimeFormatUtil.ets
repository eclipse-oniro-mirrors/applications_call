/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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

export function formatToHHmmSS(time: number): string {
  if (time < 0) {
    return 'invalid time'
  }
  let seconds = time % 60
  time = Math.floor(time / 60)
  let minutes = time % 60
  let hours = Math.floor(time / 60)
  let hourStr = hours > 0 ? `${hours}:` : ''
  let minuteStr = `${minutes.toString().padStart(2, '0')}:`
  let secondStr = seconds.toString().padStart(2, '0')
  return `${hourStr}${minuteStr}${secondStr}`
}

export function getHHmmByTimeStamp(timestamp: number): string {
  const date = new Date(timestamp);

  // 提取并格式化
  const hours = date.getHours().toString().padStart(2, '0');
  const minutes = date.getMinutes().toString().padStart(2, '0');

  return `${hours}:${minutes}`;
}
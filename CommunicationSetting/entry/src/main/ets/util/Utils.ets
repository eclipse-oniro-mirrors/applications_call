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
export class Utils {
  /**
   * 获取正常状态下背景色
   *
   * @param isHover - 是否悬浮状态
   * @returns - 背景色
   */
  public static getNormalStyleBgColor(isHover: boolean): ResourceColor | string {
    if (isHover) {
      return $r('sys.color.ohos_id_color_hover');
    }
    return '#00000000';
  }

  /**
   * 判断是否存在应用分身

   * @param appIndex - 应用编号
   * @returns  - 是否存在应用分身
   */
  public static checkAppIndexExists(appIndex: number): boolean {
    // 当前仅支持最多5个应用分身
    return appIndex === 1 || appIndex === 2 || appIndex === 3 || appIndex === 4 || appIndex === 5;
  }
}
/**
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
import { SimInfo } from '../data/SimInfo';

export class AppStorageUtils {
  public static SIM_INFO = 'sim_info'
  public static SIM_COUNT = 'sim_count'

  private constructor() {
  }

  /**
   * 刷新卡信息
   *
   * @param slotId - 卡槽id
   * @param simInfo - 卡信息
   */
  public static updateSimInfo(slotId: number, simInfo: SimInfo) {
    AppStorage.setOrCreate<SimInfo>(`${AppStorageUtils.SIM_INFO}${slotId}`, simInfo);
  }

  /**
   * 刷新SIM卡数量
   *
   * @param simCount SIM卡数量.
   */
  public static updateSimCount(simCount: number) {
    AppStorage.setOrCreate<number>(AppStorageUtils.SIM_COUNT, simCount);
  }

  /**
   * 获取SIM卡数量
   *
   * @returns - SIM卡数量
   */
  public static getSimCount(): number {
    const simCount = AppStorage.get<number>(AppStorageUtils.SIM_COUNT);
    return simCount ? simCount : 0;
  }
}
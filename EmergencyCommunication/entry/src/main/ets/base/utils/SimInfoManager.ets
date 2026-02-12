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

import { radio, sim } from '@kit.TelephonyKit'
import LogUtils from '../../utils/HiLog'

const INVALID_SLOT_ID = -1
export const INVALID_PHONE_NUMBER_STR = '-1'
const INVALID_IMEI_STR = '-1'
const TAG = 'SimInfoManager'

export class SimInfoManager {
  private static sInstance: SimInfoManager

  private activeSlotId = INVALID_SLOT_ID
  private isGetSlotIdFinish = false
  private isGetPhoneFinish = false
  private isGetIMEIFinish = false
  private activePhoneNumber: string = INVALID_PHONE_NUMBER_STR
  private activeIMEI: string = INVALID_IMEI_STR

  private constructor() {}

  public static getInstance(): SimInfoManager {
    if (SimInfoManager.sInstance === null || SimInfoManager.sInstance === undefined) {
      SimInfoManager.sInstance = new SimInfoManager()
    }
    return SimInfoManager.sInstance
  }

  public init() {
    this.initPhoneNumber()
    this.initImei()
  }

  public getActiveSlotId(): number {
    if (this.isGetSlotIdFinish) {
      return this.activeSlotId
    }
    this.initActiveSlotIdSync()
    return this.activeSlotId
  }

  public getPhoneNumber(): string {
    if (this.isGetPhoneFinish) {
      return this.activePhoneNumber
    }
    this.initPhoneNumber()
    return INVALID_PHONE_NUMBER_STR
  }

  public getActiveImei(): string {
    if (this.isGetIMEIFinish) {
      return this.activeIMEI
    }
    this.initImei()
    return INVALID_IMEI_STR
  }

  private async initImei() {
    try {
      this.activeIMEI = await radio.getIMEI(0)
      LogUtils.i(TAG, `imei is ${this.activeIMEI}`)
      this.isGetIMEIFinish = true
    } catch (err) {
      LogUtils.e(TAG, `call sim.getSimTelephoneNumber failed, err: ${JSON.stringify(err)}`)
    }
  }

  private async initPhoneNumber() {
    await this.initActiveSlotId()
    let activeSlotId = this.getActiveSlotId()
    if (activeSlotId === INVALID_SLOT_ID) {
      LogUtils.e(TAG, 'init phone number failed cause active slotId is not exist')
      return
    }

    try {
      this.activePhoneNumber = await sim.getSimTelephoneNumber(activeSlotId)
      this.isGetPhoneFinish = true
    } catch (err) {
      LogUtils.e(TAG, `call sim.getSimTelephoneNumber failed, slotID is: ${activeSlotId}, err: ${JSON.stringify(err)}`)
    }
  }

  private async initActiveSlotId(): Promise<void> {
    LogUtils.i(TAG, 'initActiveSlotId')
    let slotIdArr: number[] = [0, 1]
    for (let i = 0; i < slotIdArr.length; i++) {
      try {
        let isSimActive: boolean = await sim.isSimActive(slotIdArr[i])
        LogUtils.i(TAG, `sim${i} isActive: ${isSimActive}`)
        if (isSimActive) {
          this.activeSlotId = slotIdArr[i]
          this.isGetSlotIdFinish = true
          return
        }
      } catch (err) {
        LogUtils.e(TAG, `call sim.isSimActive failed, slotID is: ${slotIdArr[i]}, err: ${JSON.stringify(err)}`)
      }
    }
  }

  private initActiveSlotIdSync() {
    let slotIdArr: number[] = [0, 1]
    for (let i = 0; i < slotIdArr.length; i++) {
      try {
        let isSimActive: boolean = sim.isSimActiveSync(slotIdArr[i])
        if (isSimActive) {
          this.activeSlotId = slotIdArr[i]
          this.isGetSlotIdFinish = true
          return
        }
      } catch (err) {
        LogUtils.e(TAG, `call sim.initActiveSlotIdSync failed, slotID is: ${slotIdArr[i]}, err: ${JSON.stringify(err)}`)
      }
    }
  }
}
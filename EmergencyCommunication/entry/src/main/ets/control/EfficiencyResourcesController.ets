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
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import LogUtils from '../utils/HiLog';

const TAG = 'EfficiencyResourcesController';

/**
 * 应用目前已申请的CPU能效资源数量
 */
const APPLIED_CPU_RESOURCE_NUMBER = 'appliedCpuResourceNumberInApplication';

export class EfficiencyResourcesController {
  private static sInstance: EfficiencyResourcesController | null;
  /**
   * 记录每个CPU能效资源申请. key为申请者+理由,value为是否申请能效资源
   */
  private mapKey2IsApplyCPU: Map<string, boolean> = new Map<string, boolean>();

  constructor() {
  }

  public static getInstance() {
    if (!EfficiencyResourcesController.sInstance) {
      EfficiencyResourcesController.sInstance = new EfficiencyResourcesController();
    }
    return EfficiencyResourcesController.sInstance;
  }

  private static setMapKey2IsApplyCPU(reason: string, applicant: string, value: boolean) {
    try {
      EfficiencyResourcesController.getInstance().mapKey2IsApplyCPU.set(String(applicant + reason), value);
    } catch (e) {
      LogUtils.e(TAG, `setMapKey2IsApplyCPU error: ${e?.code} ${e?.message}`);
    }
  }

  public getIsApplyCPU = (reason: string, applicant: string) => {
    try {
      return this.mapKey2IsApplyCPU?.get(String(applicant + reason));
    } catch (e) {
      LogUtils.e(TAG, `setMapKey2IsApplyCPU error: ${e?.code} ${e?.message}`);
    }
    return null;
  }

  /**
   * 增加一个已申请的CPU能效资源数
   */
  private static addOneAppliedCpuResourceNumber() {
    try {
      let appliedCpuResourceNumber = AppStorage.get<number>(APPLIED_CPU_RESOURCE_NUMBER) ?? 0;
      LogUtils.i(TAG, `addOneAppliedCpuResourceNumber appliedCpuResourceNumber: ${appliedCpuResourceNumber}`);
      appliedCpuResourceNumber++;
      AppStorage.setOrCreate(APPLIED_CPU_RESOURCE_NUMBER, appliedCpuResourceNumber);
    } catch (e) {
      LogUtils.e(TAG, `addOneAppliedCpuResourceNumber error: ${e?.code} ${e?.message}`);
    }
  }

  /**
   * 减少一个已申请的CPU能效资源数
   */
  private static reduceOneAppliedCpuResourceNumber() {
    try {
      let appliedCpuResourceNumber = AppStorage.get<number>(APPLIED_CPU_RESOURCE_NUMBER) ?? 0;
      LogUtils.i(TAG, `reduceOneAppliedCpuResourceNumber appliedCpuResourceNumber: ${appliedCpuResourceNumber}`);
      appliedCpuResourceNumber--;
      AppStorage.setOrCreate(APPLIED_CPU_RESOURCE_NUMBER, appliedCpuResourceNumber);
    } catch (e) {
      LogUtils.e(TAG, `reduceOneAppliedCpuResourceNumber error: ${e?.code} ${e?.message}`);
    }
  }

  /**
   * 按照应用维度申请CPU能效资源，申请后应用进程不被挂起
   * @param duration 资源使用时间（ms）
   * @param reason 申请资源原因
   * @param applicant 申请者
   */
  public static applyCpuEfficiencyResources(duration: number, reason: string, applicant: string): void {
    try {
      let request: backgroundTaskManager.EfficiencyResourcesRequest = {
        resourceTypes: backgroundTaskManager.ResourceType.CPU,
        isApply: true,
        timeOut: duration,
        reason: reason,
        isPersist: false,
        isProcess: false,
      };
      backgroundTaskManager.applyEfficiencyResources(request);
      LogUtils.i(TAG, 'applyCpuEfficiencyResources success');
      EfficiencyResourcesController.addOneAppliedCpuResourceNumber();
      EfficiencyResourcesController.setMapKey2IsApplyCPU(reason, applicant, true);
    } catch (e) {
      LogUtils.e(TAG, `applyCpuEfficiencyResources error: ${e?.code} ${e?.message}`);
    }
  }

  /**
   * 减少应用目前已申请的CPU能效资源数量
   * 当数量小于等于0时，释放CPU能效资源
   * @param reason 申请资源原因
   * @param applicant 申请者
   */
  public static reduceCpuEfficiencyResources(reason: string, applicant: string): void {
    EfficiencyResourcesController.setMapKey2IsApplyCPU(reason, applicant, false);
    EfficiencyResourcesController.reduceOneAppliedCpuResourceNumber();
    let appliedCpuResourceNumber = AppStorage.get<number>(APPLIED_CPU_RESOURCE_NUMBER) ?? 0;
    LogUtils.i(TAG, 'reduceCpuEfficiencyResources appliedCpuResourceNumber: ' + appliedCpuResourceNumber);
    if (appliedCpuResourceNumber <= 0) {
      AppStorage.setOrCreate(APPLIED_CPU_RESOURCE_NUMBER, 0);
      EfficiencyResourcesController.releaseCpuEfficiencyResources(reason);
    }
  }

  /**
   * 按照应用维度释放CPU能效资源
   * @param reason 申请资源原因
   */
  private static releaseCpuEfficiencyResources(reason: string): void {
    try {
      let request: backgroundTaskManager.EfficiencyResourcesRequest = {
        resourceTypes: backgroundTaskManager.ResourceType.CPU,
        isApply: false,
        timeOut: 0,
        reason: reason,
        isPersist: false,
        isProcess: false,
      };
      backgroundTaskManager.applyEfficiencyResources(request);
      LogUtils.i(TAG, 'releaseCpuEfficiencyResources success');
    } catch (e) {
      LogUtils.e(TAG, `releaseCpuEfficiencyResources error: ${e?.code} ${e?.message}`);
    }
  }
}
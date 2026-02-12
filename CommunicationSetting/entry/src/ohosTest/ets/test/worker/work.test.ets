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
import { describe, it, expect } from '@ohos/hypium';
import DataWorkerWrapper from '../../../../main/ets/workers/DataWorkerWrapper';
import WorkerWrapper from '../../../../main/ets/workers/WorkerWrapper';
import WorkFactory, { WorkerType } from '../../../../main/ets/workers/WorkFactory';

export default function WorkFactoryTest() {
  describe('getWorker_testSuite', () => {
    it('WorkFactoryTest_BasicTest', 0, () => {
      let result: WorkerWrapper | null = WorkFactory.getWorker(WorkerType.DataWorker);
      let instance = DataWorkerWrapper.getInstance();
      WorkFactory.getWorker(WorkerType.DataWorker)?.close();
      expect(result).assertDeepEquals(instance);
    });
  });
}
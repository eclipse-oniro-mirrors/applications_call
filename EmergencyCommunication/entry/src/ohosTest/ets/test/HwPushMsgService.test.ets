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

const test: HwPushMsg = {
  type: '1',
  users: '001',
  eventId: 1,
  update: 1,
  magnitude: 8.0,
  epicenter: '四川青川',
  longitude: 105.00,
  latitude: 32.29,
  depth: 9,
  startAt: 1603951800000,
  updateAt: 1506122112000,
  signature: ['成都高新减灾研究所', '大陆地震预警中心'],
  source: 0,
  sWaveVelocity: 0,
  beta: false,
  epiIntensity: 0,
  provinceCodes: '',
};

export default function HwPushMsgServiceTest() {
  describe('HwPushMsgServiceTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    })
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: preset action function.
    })
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: clear action function.
    })
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end.
      // This API supports only one parameter: clear action function.
    })
    it('assertEqual', 0, () => {
      let a = 'test'
      saveMessageReceived(test)
      expect(a).assertEqual('test')
    })
  })
}
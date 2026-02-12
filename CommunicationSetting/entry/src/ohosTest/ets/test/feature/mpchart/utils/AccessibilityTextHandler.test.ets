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
import { describe, beforeAll, it, expect, MockKit, ArgumentMatchers, when } from '@ohos/hypium'
import myCommon from '@ohos.app.ability.common';
import { DTGlobalContext } from '../../../../testability/TestAbility';
import { AccessibilityTextHandler, Matrix } from '../../../../../../main/ets/feature/mpchart';
import { AccessibilityData } from '../../../../../../main/ets/feature/mpchart/utils/AccessibilityTextHandler';
import CanvasUtil from '../../../../../../main/ets/feature/mpchart/utils/CanvasUtil';

export default function AccessibilityTextHandlerTest() {
  describe('AccessibilityTextHandlerTest', () => {
    let context: myCommon.UIAbilityContext;
    let bundleName = 'com.ohos.communicationsetting';
    let uid: number;

    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
      context = DTGlobalContext.getContext().getObject('TestContext') as myCommon.UIAbilityContext;
      uid = context.applicationInfo.uid;
    })
    it('updateAccessibilityTextTest01', 0, () => {
      let param: AccessibilityData = {
        visibleIndex: -1,
        chartStr: ['a'],
        chartDate: [],
        dataValues: [],
        isHourDuration: false
      };
      AccessibilityTextHandler.updateAccessibilityText(param);
      expect(param.chartStr.length).assertEqual(1);
      expect(param.chartStr[0]).assertEqual('');
    });
    it('updateAccessibilityTextTest02', 0, () => {
      let param: AccessibilityData = {
        visibleIndex: -1,
        chartStr: ['a', 'b'],
        chartDate: [],
        dataValues: [],
        isHourDuration: false
      };
      AccessibilityTextHandler.updateAccessibilityText(param);
      expect(param.chartStr.length).assertEqual(2);
      expect(param.chartStr[0]).assertEqual('');
      expect(param.chartStr[1]).assertEqual('');
    })
    it('updateAccessibilityTextTest03', 0, () => {
      let param: AccessibilityData = {
        visibleIndex: 1,
        chartStr: ['a', 'b'],
        chartDate: [],
        dataValues: [],
        isHourDuration: false
      };
      AccessibilityTextHandler.updateAccessibilityText(param);
      expect(param.chartStr.length).assertEqual(2);
      expect(param.chartStr[0]).assertEqual('');
      expect(param.chartStr[1]).assertEqual('b');
    })
    it('updateAccessibilityTextTest04', 0, () => {
      let param: AccessibilityData = {
        visibleIndex: 1,
        chartStr: ['a', 'c'],
        chartDate: [],
        dataValues: [],
        isHourDuration: true
      };
      AccessibilityTextHandler.updateAccessibilityText(param);
      expect(param.chartStr.length).assertEqual(2);
      expect(param.chartStr[0]).assertEqual('');
      expect(param.chartStr[1]).assertEqual('c');
    })
    it('updateAccessibilityTextTest05', 0, () => {
      let param: AccessibilityData = {
        visibleIndex: 1,
        chartStr: ['a', 'b'],
        chartDate: [],
        dataValues: [],
        isHourDuration: true
      };
      AccessibilityTextHandler.updateAccessibilityText(param);
      expect(param.chartStr.length).assertEqual(2);
      expect(param.chartStr[0]).assertEqual('');
      expect(param.chartStr[1]).assertEqual('b');
    })
    it('isSameDayTest01', 0, () => {
      let param: AccessibilityData = {
        visibleIndex: 1,
        chartStr: [''],
        chartDate: [],
        dataValues: [],
        isHourDuration: true
      };
      let currentDate = new Date();
      let date = new Date(param.chartDate[0]);
      let result = AccessibilityTextHandler.isSameDay(currentDate, date);
      expect(result).assertFalse();
    })
    it('isSameDayTest02', 0, () => {
      let param: AccessibilityData = {
        visibleIndex: 1,
        chartStr: [bundleName],
        chartDate: [],
        dataValues: [],
        isHourDuration: true
      };
      let currentDate = new Date();
      currentDate.setHours(0, 0, 0);
      param.chartDate.push(currentDate.getTime());
      let date = new Date(param.chartDate[0]);
      let result = AccessibilityTextHandler.isSameDay(currentDate, date);
      expect(result).assertTrue();
    })
    it('getPopTextTest01', 0, () => {
      let param: AccessibilityData = {
        visibleIndex: 1,
        chartStr: [''],
        chartDate: [1, 2, 3],
        dataValues: [[0, 1]],
        isHourDuration: true
      };
      let result = AccessibilityTextHandler.getPopText(-1, param.dataValues);
      expect(result).assertEqual('');
    })
    it('getPopTextTest02', 0, () => {
      let param: AccessibilityData = {
        visibleIndex: 1,
        chartStr: [''],
        chartDate: [],
        dataValues: [[0, 1]],
        isHourDuration: true
      };
      let result = AccessibilityTextHandler.getPopText(2, param.dataValues);
      expect(result).assertEqual('');
    })
    it('getPopTextTest03', 0, () => {
      let param: AccessibilityData = {
        visibleIndex: 1,
        chartStr: [''],
        chartDate: [],
        dataValues: [[0, 1]],
        isHourDuration: true
      };
      let result = AccessibilityTextHandler.getPopText(0, param.dataValues);
      expect(result).assertEqual('1.00 B');
    })
    it('getPopTextTest04', 0, () => {
      let param: AccessibilityData = {
        visibleIndex: 1,
        chartStr: [''],
        chartDate: [],
        dataValues: [[0, 1024]],
        isHourDuration: true
      };
      let result = AccessibilityTextHandler.getPopText(0, param.dataValues);
      expect(result).assertEqual('1.00 KB');
    })
    it('getPopTextTest05', 0, () => {
      let param: AccessibilityData = {
        visibleIndex: 1,
        chartStr: [''],
        chartDate: [],
        dataValues: [[0, 1024 * 1024]],
        isHourDuration: true
      };
      let result = AccessibilityTextHandler.getPopText(0, param.dataValues);
      expect(result).assertEqual('1.00 MB');
    })
    it('getPopTextTest06', 0, () => {
      let param: AccessibilityData = {
        visibleIndex: 1,
        chartStr: [''],
        chartDate: [],
        dataValues: [[0, 1024 * 1024 * 1024]],
        isHourDuration: true
      };
      let result = AccessibilityTextHandler.getPopText(0, param.dataValues);
      expect(result).assertEqual('1.00 GB');
    })
    it('getPopTextTest07', 0, () => {
      let param: AccessibilityData = {
        visibleIndex: 1,
        chartStr: [''],
        chartDate: [],
        dataValues: [[0, 1024 * 1024 * 1024 * 1024]],
        isHourDuration: true
      };
      let c: Matrix = new Matrix();
      ;
      CanvasUtil.clearCanvas(c);
      let result = AccessibilityTextHandler.getPopText(0, param.dataValues);
      expect(result).assertEqual('1.00 TB');
    })
    it('getPopTextTest08', 0, () => {
      let param: AccessibilityData = {
        visibleIndex: 1,
        chartStr: [''],
        chartDate: [],
        dataValues: [[0, 1024 * 1024 * 1024 * 1024 * 1024]],
        isHourDuration: true
      };
      let c = null;
      CanvasUtil.clearCanvas(c);
      let result = AccessibilityTextHandler.getPopText(0, param.dataValues);
      expect(result).assertEqual('1024.00 TB');
    })
    it('getPopTextTest09', 0, () => {
      let param: AccessibilityData = {
        visibleIndex: 0,
        chartStr: [''],
        chartDate: [],
        dataValues: [[0, 1024 * 1024]],
        isHourDuration: true
      };
      AccessibilityTextHandler.getHourDurationAccessibilityText(param.visibleIndex, param);
      let result = AccessibilityTextHandler.getPopText(param.visibleIndex, param.dataValues);
      expect(result).assertEqual('1.00 MB');
    })
    it('getPopTextTest10', 0, () => {
      let param: AccessibilityData = {
        visibleIndex: 1,
        chartStr: [''],
        chartDate: [],
        dataValues: [[0, 1024 * 1024 * 1024]],
        isHourDuration: true
      };
      AccessibilityTextHandler.getHourDurationAccessibilityText(param.visibleIndex, param);
      let result = AccessibilityTextHandler.getPopText(0, param.dataValues);
      expect(result).assertEqual('1.00 GB');
    })
    it('getPopTextTest11', 0, () => {
      let param: AccessibilityData = {
        visibleIndex: -1,
        chartStr: [''],
        chartDate: [],
        dataValues: [[0, 1024]],
        isHourDuration: true
      };
      AccessibilityTextHandler.getDayDurationAccessibilityText(param.visibleIndex, param);
      let result = AccessibilityTextHandler.getPopText(0, param.dataValues);
      expect(result).assertEqual('1.00 KB');
    })
    it('getPopTextTest12', 0, () => {
      let param: AccessibilityData = {
        visibleIndex: 0,
        chartStr: [''],
        chartDate: [],
        dataValues: [[0, 1024 * 1024]],
        isHourDuration: true
      };
      let date = new Date();
      param.chartDate.push(date.getTime());
      AccessibilityTextHandler.getDayDurationAccessibilityText(param.visibleIndex, param);
      let result = AccessibilityTextHandler.getPopText(0, param.dataValues);
      expect(result).assertEqual('1.00 MB');
    })
    it('getPopTextTest13', 0, () => {
      let param: AccessibilityData = {
        visibleIndex: 0,
        chartStr: [''],
        chartDate: [],
        dataValues: [[0, 1024 * 1024]],
        isHourDuration: true
      };
      let date = new Date('2024-01-01');
      param.chartDate.push(date.getTime());
      AccessibilityTextHandler.getDayDurationAccessibilityText(param.visibleIndex, param);
      let result = AccessibilityTextHandler.getPopText(0, param.dataValues);
      expect(result).assertEqual('1.00 MB');
    })
    it('getPopTextTest14', 0, () => {
      let param: AccessibilityData = {
        visibleIndex: 0,
        chartStr: [''],
        chartDate: [],
        dataValues: [[0, 1024 * 1024 * 1024 * 1024]],
        isHourDuration: true
      };
      let date = new Date('2025-01-01');
      param.chartDate.push(date.getTime());
      AccessibilityTextHandler.getDayDurationAccessibilityText(param.visibleIndex, param);
      let result = AccessibilityTextHandler.getPopText(0, param.dataValues);
      expect(result).assertEqual('1.00 TB');
    })
  })
}
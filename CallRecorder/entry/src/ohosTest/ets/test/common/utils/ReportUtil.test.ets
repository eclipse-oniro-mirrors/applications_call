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

import {
  describe,
  beforeAll,
  beforeEach,
  afterEach,
  afterAll,
  it,
  expect,
  MockKit,
  when,
  ArgumentMatchers
} from '@ohos/hypium';
import { ReportUtil } from '../../../../../main/ets/common/utils/ReportUtil';

let sReportUtil = ReportUtil.getInstance();
const errCode = 401;
const OPERATE = 1;

let ReportUtilTest_reportCallAutoRecord_Func01 = () => {
  sReportUtil.reportCallAutoRecord(OPERATE);
}

let ReportUtilTest_reportRecordOperate_Func01 = () => {
  sReportUtil.reportRecordOperate(OPERATE);
}

let ReportUtilTest_reportFault_Func01 = () => {
  ReportUtil.getInstance().reportRecordStartError(errCode);
}

let ReportUtilTest_reportFault_Func02 = () => {
  ReportUtil.getInstance().reportRecordStopError(errCode);
}

export function ReportUtilTest01() {
  describe('ReportUtilTest01', () => {
    it('ReportUtilTest_reportCallAutoRecord_Func01', 0, () => {
      ReportUtilTest_reportCallAutoRecord_Func01();
    })
    it('ReportUtilTest_reportRecordOperate_Func01', 0, () => {
      ReportUtilTest_reportRecordOperate_Func01();
    })
    it('ReportUtilTest_reportFault_Func01', 0, () => {
      ReportUtilTest_reportFault_Func01();
    })
    it('ReportUtilTest_reportFault_Func02', 0, () => {
      ReportUtilTest_reportFault_Func02();
    })
  })
}
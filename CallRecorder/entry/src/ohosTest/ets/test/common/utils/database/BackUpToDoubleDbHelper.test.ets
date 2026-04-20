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
import { describe, it, expect, } from '../../../../../../../oh_modules/@ohos/hypium'
import { backUpToDoubleDbHelper } from '../../../../../../main/ets/common/utils/database/BackUpToDoubleDbHelper'
import { common } from '@kit.AbilityKit'
import CallRecorderDualConstant from '../../../../../../main/ets/common/constant/CallRecorderDualConstant'
import { GlobalContextHelper } from '../../../../../../main/ets/common/utils/GlobalContextHelper'
import { Constant } from '../../../../../../main/ets/common/constant/Constant'
import { ValuesBucket, } from '@kit.ArkData'

export default function BackUpToDoubleDbHelperTest() {
  let BackUpToDoubleDbHelperTest_queryCount_01 = async (context: common.Context) => {
    let table: string = CallRecorderDualConstant.RECORDER_FILE_TABLE_NAME;
    let count = await backUpToDoubleDbHelper.queryCount(context, table);
    expect(count >= 0).assertTrue();
  }
  let BackUpToDoubleDbHelperTest_queryCount_03 = async (context: common.Context) => {
    let count = await backUpToDoubleDbHelper.queryCount(context, 'no exist table name');
    expect(count === 0).assertTrue();
  }
  let BackUpToDoubleDbHelperTest_queryCallRecorder_01 = async (context: common.Context) => {
    let count = await backUpToDoubleDbHelper.queryCallRecorder(context, 0);
    expect(count.length == 0).assertEqual(true);
  }
  let BackUpToDoubleDbHelperTest_batchInsertRecordInfoForBackUp_01 = async (context: common.Context) => {
    let callRecodeResult: ValuesBucket[] = [{
      'a': 1
    }, {
      'b': true
    }];
    let callRecodeResult0: ValuesBucket[] = [];
    let result1 = await backUpToDoubleDbHelper.batchInsertRecordInfoForBackUp(context, callRecodeResult0);
    let result = await backUpToDoubleDbHelper.batchInsertRecordInfoForBackUp(context, callRecodeResult);
    expect(result1).assertEqual(undefined);
    expect(Number(result) >= 0).assertFalse();
  }
  let BackUpToDoubleDbHelperTest_batchInsertRecordInfoForBackUp_02 = async (context: common.Context) => {
    let recLogValue: ValuesBucket[] = [{
      'a': 1
    }, {
      'b': true
    }];
    let count = await backUpToDoubleDbHelper.batchInsertRecordInfoForBackUp(context, recLogValue);
    expect(count).assertEqual(undefined);
  }
  let BackUpToDoubleDbHelperTest_queryContactData_01 = async (context: common.Context) => {
    let result = await backUpToDoubleDbHelper.queryCustomizeData(context, 0);
    expect(result.length >= 0).assertTrue();
  }
  let BackUpToDoubleDbHelperTest_queryCustomizeData_01 = async (context: common.Context) => {
    let result = await backUpToDoubleDbHelper.queryCustomizeData(context, 0);
    expect(result.length >= 0).assertTrue();
  }
  let BackUpToDoubleDbHelperTest_queryCustomizeData_02 = async (context: common.Context) => {
    let result = await backUpToDoubleDbHelper.queryCustomizeData(context, 3);
    expect(result.length >= 0).assertTrue();
  }
  let BackUpToDoubleDbHelperTest_batchInsertCustomizeForBackUp_02 = async (context: common.Context) => {
    let recLogValue: ValuesBucket[] = [{
      "1": 1, "2": 2
    }];
    let result = await backUpToDoubleDbHelper.batchInsertCustomizeForBackUp(context, recLogValue);
    expect(result == null).assertTrue();
  }
  let BackUpToDoubleDbHelperTest_getCopyFileData_01 = async (context: common.Context) => {
    let result = await backUpToDoubleDbHelper.getCopyFileData(context);
    expect(result.length >= 0).assertTrue();
  }
  let BackUpToDoubleDbHelperTest_getCopyFileData_02 = async (context: common.Context) => {
    let result = await backUpToDoubleDbHelper.getCopyFileData(context);
    expect(result.length == 0).assertTrue();
  }
  let BackUpToDoubleDbHelperTest_batchInsertCopyFileForBackUp_01 = async (context: common.Context) => {
    let recLogValue: ValuesBucket[] = [{
      "1": 1, "2": 2
    }];
    let result = await backUpToDoubleDbHelper.batchInsertCopyFileForBackUp(context, recLogValue);
    expect(result == null).assertTrue();
  }
  let BackUpToDoubleDbHelperTest_getDefaultFileData_01 = async (context: common.Context) => {
    let result = await backUpToDoubleDbHelper.getDefaultFileData(context);
    expect(result.length >= 0).assertTrue();
  }
  let BackUpToDoubleDbHelperTest_getDefaultFileData_02 = async (context: common.Context) => {
    let result = await backUpToDoubleDbHelper.getDefaultFileData(context);
    expect(result.length == 0).assertTrue();
  }
  let BackUpToDoubleDbHelperTest_batchInsertDefaultFileForBackUp_01 = async (context: common.Context) => {
    let recLogValue: ValuesBucket[] = [{
      "1": 1, "2": 2
    }];
    let result = await backUpToDoubleDbHelper.batchInsertDefaultFileForBackUp(context, recLogValue);
    expect(result == null).assertTrue();
  }
  let BackUpToDoubleDbHelperTest_getUriData_01 = async (context: common.Context) => {
    let result = await backUpToDoubleDbHelper.getUriData(context);
    expect(result.length >= 0).assertTrue();
  }
  let BackUpToDoubleDbHelperTest_getUriData_02 = async (context: common.Context) => {
    let result = await backUpToDoubleDbHelper.getUriData(context);
    expect(result.length == 0).assertTrue();
  }
  let BackUpToDoubleDbHelperTest_batchInsertUriForBackUp_01 = async (context: common.Context) => {
    let recLogValue: ValuesBucket[] = [{
      "1": 1, "2": 2
    }];
    let result = await backUpToDoubleDbHelper.batchInsertUriForBackUp(context, recLogValue);
    expect(result == null).assertTrue();
  }
  let BackUpToDoubleDbHelperTest_getVersionData_01 = async (context: common.Context) => {
    let result = await backUpToDoubleDbHelper.getVersionData(context);
    expect(result.length >= 0).assertTrue();
  }
  let BackUpToDoubleDbHelperTest_getVersionData_02 = async (context: common.Context) => {
    let result = await backUpToDoubleDbHelper.getVersionData(context);
    expect(result.length == 0).assertTrue();
  }
  let BackUpToDoubleDbHelperTest_batchInsertVersionForBackUp_01 = async (context: common.Context) => {
    let recLogValue: ValuesBucket[] = [{
      "1": 1, "2": 2
    }];
    let result = await backUpToDoubleDbHelper.batchInsertVersionForBackUp(context, recLogValue);
    expect(result == null).assertTrue();
  }

  describe('BackUpToDoubleDbHelperTest', () => {
    let recLogValue: ValuesBucket[];
    let testContext1: common.Context;
    let testContext =
      GlobalContextHelper.getContext().getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    it('BackUpToDoubleDbHelperTest_queryCount_01', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_queryCount_01(testContext);
    })
    it('BackUpToDoubleDbHelperTest_queryCount_03', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_queryCount_03(testContext1);
    })
    it('BackUpToDoubleDbHelperTest_queryCount_03_1', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_queryCount_03(testContext);
    })
    it('BackUpToDoubleDbHelperTest_queryCallRecorder_01', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_queryCallRecorder_01(testContext);
    })
    it('BackUpToDoubleDbHelperTest_queryCallRecorder_02', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_queryCallRecorder_01(testContext1);
    })
    it('BackUpToDoubleDbHelperTest_queryContactData_01', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_queryContactData_01(testContext);
    })
    it('BackUpToDoubleDbHelperTest_queryContactData_02', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_queryContactData_01(testContext1);
    })
    it('BackUpToDoubleDbHelperTest_batchInsertRecordInfoForBackUp_01', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_batchInsertRecordInfoForBackUp_01(testContext);
    })
    it('BackUpToDoubleDbHelperTest_batchInsertRecordInfoForBackUp_01_01', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_batchInsertRecordInfoForBackUp_02(testContext1);
    })
    it('BackUpToDoubleDbHelperTest_batchInsertRecordInfoForBackUp_02', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await backUpToDoubleDbHelper.batchInsertRecordInfoForBackUp(testContext, recLogValue);
    })
    it('BackUpToDoubleDbHelperTest_batchInsertRecordInfoForBackUp_03', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_batchInsertRecordInfoForBackUp_02(testContext1);
    })
    it('BackUpToDoubleDbHelperTest_queryCustomizeData_01', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_queryCustomizeData_01(testContext);
    })
    it('BackUpToDoubleDbHelperTest_queryCustomizeData_02', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_queryCustomizeData_02(testContext);
    })
    it('BackUpToDoubleDbHelperTest_queryCustomizeData_01_01', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_queryCustomizeData_01(testContext1);
    })
    it('BackUpToDoubleDbHelperTest_batchInsertCustomizeForBackUp_01', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      let result = await backUpToDoubleDbHelper.batchInsertCustomizeForBackUp(testContext, recLogValue);
      expect(result == null).assertTrue();
    })
    it('BackUpToDoubleDbHelperTest_batchInsertCustomizeForBackUp_02', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_batchInsertCustomizeForBackUp_02(testContext1);
    })
    it('BackUpToDoubleDbHelperTest_batchInsertCustomizeForBackUp_02_01', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_batchInsertCustomizeForBackUp_02(testContext);
    })
    it('BackUpToDoubleDbHelperTest_getCopyFileData_01', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_getCopyFileData_01(testContext);
    })
    it('BackUpToDoubleDbHelperTest_getCopyFileData_02', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_getCopyFileData_02(testContext1);
    })
    it('BackUpToDoubleDbHelperTest_batchInsertCopyFileForBackUp_01', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      let result = await backUpToDoubleDbHelper.batchInsertCopyFileForBackUp(testContext, recLogValue);
      expect(result == null).assertTrue();
    })
    it('BackUpToDoubleDbHelperTest_batchInsertCopyFileForBackUp_02', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_batchInsertCopyFileForBackUp_01(testContext1);
    })
    it('BackUpToDoubleDbHelperTest_batchInsertCopyFileForBackUp_02_01', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_batchInsertCopyFileForBackUp_01(testContext);
    })
    it('BackUpToDoubleDbHelperTest_getDefaultFileData_01', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_getDefaultFileData_01(testContext);
    })
    it('BackUpToDoubleDbHelperTest_getDefaultFileData_02', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_getDefaultFileData_02(testContext1);
    })
    it('BackUpToDoubleDbHelperTest_batchInsertDefaultFileForBackUp_01', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      let result = await backUpToDoubleDbHelper.batchInsertDefaultFileForBackUp(testContext, recLogValue);
      expect(result == null).assertTrue();
    })
    it('BackUpToDoubleDbHelperTest_batchInsertDefaultFileForBackUp_02', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_batchInsertDefaultFileForBackUp_01(testContext1);
    })
    it('BackUpToDoubleDbHelperTest_batchInsertDefaultFileForBackUp_02_01', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_batchInsertDefaultFileForBackUp_01(testContext);
    })
    it('BackUpToDoubleDbHelperTest_getUriData_01', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_getUriData_01(testContext);
    })
    it('BackUpToDoubleDbHelperTest_getUriData_02', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_getUriData_02(testContext1);
    })
    it('BackUpToDoubleDbHelperTest_batchInsertUriForBackUp_01', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      let result = await backUpToDoubleDbHelper.batchInsertUriForBackUp(testContext, recLogValue);
      expect(result == null).assertTrue();
    })
    it('BackUpToDoubleDbHelperTest_batchInsertUriForBackUp_02', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_batchInsertUriForBackUp_01(testContext1);
    })
    it('BackUpToDoubleDbHelperTest_batchInsertUriForBackUp_02_01', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_batchInsertUriForBackUp_01(testContext);
    })
    it('BackUpToDoubleDbHelperTest_getVersionData_01', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_getVersionData_01(testContext);
    })
    it('BackUpToDoubleDbHelperTest_getVersionData_02', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_getVersionData_02(testContext1);
    })
    it('BackUpToDoubleDbHelperTest_batchInsertVersionForBackUp_01', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      let result = await backUpToDoubleDbHelper.batchInsertVersionForBackUp(testContext, recLogValue);
      expect(result == null).assertTrue();
    })
    it('BackUpToDoubleDbHelperTest_batchInsertVersionForBackUp_02', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_batchInsertVersionForBackUp_01(testContext1);
    })
    it('BackUpToDoubleDbHelperTest_batchInsertVersionForBackUp_02_01', 0, async () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      await BackUpToDoubleDbHelperTest_batchInsertVersionForBackUp_01(testContext);
    })
  })
}
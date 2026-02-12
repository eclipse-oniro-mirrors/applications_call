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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium'
import { callSettingDbHelper } from '../../../../../main/ets/backup/presenter/CallSettingDbHelper'
import CallSettingSingleConstant from '../../../../../main/ets/backup/presenter/CallSettingSingleConstant';
import Utils from '../../../../../main/ets/common/utils/utils'
import { common } from '@kit.AbilityKit';

export default function CallSettingDbHelperTest() {
  let context = Utils.getInstance().getContext();
  let emptyContext: common.Context;
  describe('CallSettingDbHelperTest', () => {
    let queryCountTest = async () => {
      let table = CallSettingSingleConstant.CLONE_PUBLIC_BACKUP_FIRST + CallSettingSingleConstant.LOCALE +
      CallSettingSingleConstant.CLONE_PUBLIC_BACKUP_LAST;
      await callSettingDbHelper.queryCount(context, table).then((num) => {
        expect(num >= 0).assertTrue()
      });
    }
    let queryCountTest_01 = async () => {
      let table = "";
      await callSettingDbHelper.queryCount(emptyContext, table).then((num) => {
        expect(num >= 0).assertTrue()
      });
    }
    let queryCloneSubDataTest = async () => {
      let table = CallSettingSingleConstant.LOCALE;
      await callSettingDbHelper.queryCloneSubData(context, table).then((arr) => {
        expect(arr.length >= 0).assertTrue()
      });
    }
    let queryCloneSubDataTest_01 = async () => {
      let table = CallSettingSingleConstant.LOCALE;
      await callSettingDbHelper.queryCloneSubData(emptyContext, table).then((arr) => {
        expect(arr.length >= 0).assertTrue()
      });
    }

    let formatResourceToString_test = () => {
      let result = callSettingDbHelper.formatResourceToString(emptyContext, $r('app.string.TestAbility_label'));
      expect(result).assertEqual('');
    }

    let updateRejectMsg_test_01 = async () => {
      let result = await callSettingDbHelper.updateRejectMsg(true, context);
      expect(result === undefined).assertTrue();
    }
    let updateRejectMsg_test_02 = async () => {
      let result = await callSettingDbHelper.updateRejectMsg(false, context);
      expect(result === undefined).assertTrue();
    }

    it('queryCountTest', 0, async () => {
      await queryCountTest()
    })
    it('queryCountTest_01', 0, async () => {
      await queryCountTest_01()
    })
    it('queryCloneSubDataTest', 0, async () => {
      await queryCloneSubDataTest()
    })
    it('queryCloneSubDataTest_01', 0, async () => {
      await queryCloneSubDataTest_01()
    })

    it('formatResourceToString', 0, () => {
      formatResourceToString_test();
    })
    it('should_return_empty_string_when_backUpLocale_is_empty', 0, () => {
      let result = callSettingDbHelper.getConvertLocale('');
      expect(result).assertEqual('');
    });

    it('should_return_empty_string_when_backUpLocale_is_invalid_format', 0, () => {
      let result = callSettingDbHelper.getConvertLocale('invalid_format');
      expect(result).assertEqual('invalid-format');
    });

    it('should_return_correct_locale_when_backUpLocale_is_valid', 0, () => {
      let result = callSettingDbHelper.getConvertLocale('en_US');
      expect(result).assertEqual('en-US');
    });

    it('should_return_correct_locale_when_backUpLocale_has_script', 0, () => {
      let result = callSettingDbHelper.getConvertLocale('en_US_POSIX');
      expect(result).assertEqual('en-US');
    });
    it('updateRejectMsg_test_01', 0, async () => {
      await updateRejectMsg_test_01();
    })
    it('updateRejectMsg_test_02', 0, async () => {
      await updateRejectMsg_test_02();
    })
  });
}
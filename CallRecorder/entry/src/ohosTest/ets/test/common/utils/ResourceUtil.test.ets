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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { GlobalContextHelper } from '../../../../../main/ets/common/utils/GlobalContextHelper';
import { ResourceUtil } from '../../../../../main/ets/common/utils/ResourceUtil';
import { Constant } from '../../../../../main/ets/common/constant/Constant';
import common from '@ohos.app.ability.common';

let ResourceUtilTestIt = () => {
  let value: Resource = $r('app.string.unknown');
  let titleString: string = ResourceUtil.resourceToString(value, GlobalContextHelper.getContext()
    .getValue(Constant.CALL_RECORDER_ABILITY_CONTEXT));
  let res = GlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT)
    .resourceManager.getStringSync(value);
  expect(titleString).assertEqual(res);
}

let formatPluralResourceToStringTestIt = (context: common.Context) => {
  let value: Resource = $r('app.plural.call_numbers_finish');
  let titleString: string = ResourceUtil.formatPluralResourceToString(value, context, 10);
  expect(titleString).assertContain('10');
}

export default function ResourceUtilTest() {
  let context = GlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT).getApplicationContext();
  describe('ResourceUtilTest', () => {
    it('ResourceUtilTest', 0, () => {
      ResourceUtilTestIt();
    })
    it('formatPluralResourceToStringTestIt', 0, () => {
      formatPluralResourceToStringTestIt(context);
    })
  })
}
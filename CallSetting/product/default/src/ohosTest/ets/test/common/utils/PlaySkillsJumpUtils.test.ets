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

import { describe, it, expect } from '@ohos/hypium';
import { util } from '@kit.ArkTS';
import TipsJumpUtils from '../../../../../main/ets/common/utils/PlaySkillsJumpUtils';
import common from '@ohos.app.ability.common';
import { MobileDataGlobalContextHelper, Constants } from '@ohos/common/CommonIndex';

const FUN_NUM_HOME = 'SF-10056664_f101';
const URI_FORMATTER = 'hwtips://com.ohos.tips.app?funNum=%s&type=%s'
let type = '2';
let uri = util.format(URI_FORMATTER, FUN_NUM_HOME, type);

export default function PlaySkillsJumpUtilsTest() {
  const FUN_NAME_SATELLITE = 'satellite';
  const FUN_NAME_DISTRIBUTED = 'distributed';
  let context = MobileDataGlobalContextHelper.getContext()
    .getValue<common.UIAbilityContext>(Constants.SETTINGS_ABILITY_CONTEXT);
  describe('PlaySkillsJumpUtilsTest', () => {
    it('PlaySkillsJumpUtilsTest_jumpTipsByUri', 0, () => {
      let result = TipsJumpUtils.jumpTipsByUri(context, uri, 'test');
      expect(result === null).assertFalse();
    });
    it('PlaySkillsJumpUtilsTest_jumpHome', 0, () => {
      TipsJumpUtils.jumpHome(context, '100', FUN_NAME_SATELLITE, 'phone_widget');
      TipsJumpUtils.jumpHome(context, undefined, FUN_NAME_SATELLITE, '');
      TipsJumpUtils.jumpHome(context, undefined, FUN_NAME_SATELLITE);
      TipsJumpUtils.jumpHome(context, undefined, 'test');
      TipsJumpUtils.jumpTips(context, 'test', 'type');
      let r = TipsJumpUtils.jumpHome(context, '100', FUN_NAME_DISTRIBUTED, 'phone_widget');
      expect(r == null).assertTrue()
    });
    it('PlaySkillsJumpUtilsTest_jumpTipsByUri_01', 0, () => {
      let r: object = (TipsJumpUtils as object)['jumpAppByUri'](context, uri);
      expect(r == null).assertTrue()
    });
    it('PlaySkillsJumpUtilsTest_jumpAppGallery', 0, () => {
      let r: object = (TipsJumpUtils as object)['jumpAppGallery'](context);
      expect(r == null).assertTrue()
    });
  });
}
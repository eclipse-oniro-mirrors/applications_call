/**
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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

import { Constant } from '../constant/Constant';

class ContactService {
  getPhoneNumberParam(actionData: Object) {
    let str: Record<string, Object> = {
      'bundleName': Constant.CONTACT_BUNDLE_NAME,
      'abilityName': Constant.CONTACT_ABILITY_NAME,
      'parameters': actionData,
      'entities': [Constant.COMMON_ENTITIES]
    };
    return str;
  }

  getRecorderSqlParam(actionData: Object) {
    let str: Record<string, Object> = {
      'bundleName': Constant.RECORDER_BUNDLE_NAME,
      'abilityName': Constant.RECORDER_ABILITY_NAME,
      'parameters': actionData
    };
    return str;
  }
}

export default new ContactService();
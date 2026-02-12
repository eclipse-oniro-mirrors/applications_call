/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

class CommonData {
  public string: Record<string, string> = {};
  public contactPage: Record<string, string> = {};

  constructor() {
    this.string = {
      // BundleName of a contact.
      'CONTACT_BUNDLE_NAME': 'com.ohos.contacts',
      // contact AbilityName
      'CONTACT_ABILITY_NAME': 'com.ohos.contacts.MainAbility',
      // Public entity
      'COMMON_ENTITIES': 'entity.system.home',
      'MOBILE_SETTING_BUNDLE_NAME': 'com.ohos.callui',
      'MOBILE_SETTING_ABILITY_NAME': 'com.ohos.mobiledatasettings.MainAbility',
      'ERROR_CODE': '8300003',
      'REJECT_MESSAGE_PAGE_FLAG': 'rejectMessagePage',
      'CALL_UI_BUNDLE_NAME': 'com.ohos.callui',
      'CALL_UI_CALL_SETTING_ABILITU_NAME': 'com.ohos.callui.IncomingCallRejectionSmsAbility',
      'CONTACT_SPEED_DIAL_ABILITY_NAME': 'com.ohos.contacts.SpeedDialAbility',
      'VOICE_MAIL_PAGE': 'voicemailPage',
      'CALL_SETTING_BUNDLE_NAME': 'com.ohos.callsetting',
      'NUMBER_IDENTITY_EXT_ABILITY_NAME': 'NumberIdentityPrivacyStatementUIExtAbility',
    };
    this.contactPage = {
      // The page for selecting multi contact
      'PAGE_FLAG_SINGLE_CHOOSE': 'page_flag_single_choose',
      // The page for tel'xxx'
      'PAGE_FLAG_EDIT_BEFORE_CALLING': 'page_flag_edit_before_calling',
    }
  }
}

export default new CommonData();
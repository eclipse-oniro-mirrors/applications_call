/*
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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

export enum IntentType {
  GET_SETTING_SWITCH = 'GetSettingSwitch',
  SET_SETTING_SWITCH = 'SetSettingSwitch',
  CHECK_SETTING_ITEM = 'CheckSettingItem',
  CHECK_SETTING_PAGE = 'CheckSettingPage',
  CHECK_DATA_ROAMING_SWITCH = 'CheckDataRoamingSwitch',
  GET_DATA_ROAMING_SWITCH = 'GetDataRoamingSwitch',
  SET_DATA_ROAMING_SWITCH = 'SetDataRoamingSwitch',
  CHECK_IMS_SWITCH = 'CheckImsSwitch',
  GET_IMS_SWITCH = 'GetImsSwitch',
  SET_IMS_SWITCH = 'SetImsSwitch'
}

export enum IntentItemName {
  MOBILE_DATA = 'mobile_data',
  SKYCOM_SATELLITE_COMMUNICATIONS = 'skycom_satellite_communications',
  MEETIME_BEIDOU_SATELLITE_NEWS = 'changlian_beidou_satellite_news',
}

export enum IntentEntryKeyName {
  MOBILE_DATA = 'mobile_data_settings_entry',
  SATELLITE_NETWORK = 'satellite_network_entry'
}

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

interface RejectMessage {
  id: string,
  textValue: Resource
}

export const DIALOG_TIPS: Record<string, string> = {
  'TRAFFIC_USAGE_TIPS': 'trafficUsageTips'
}

export const SATELLITE_DIALOG_TIPS: Record<string, string> = {
  'SATELLITE_DIALOG_TIPS': 'satelliteServiceSim'
}

export const HYACINTH_DIALOG_TIPS: Record<string, string> = {
  'HYACINTH_DIALOG_TIPS': 'hyacinthServiceSim'
}

export const SATELLITE_SLOT_ID_TIPS: Record<string, string> = {
  'SATELLITE_SLOT_ID_TIPS': 'satelliteSlotId'
}

export const MAX_TIME_COUNT: number = 2;

export const BANNER = 'banner';
export const FULL_SCREEN = 'fullScreen';
export const DEFAULT_CONFIG = FULL_SCREEN; // target is BANNER, FULL_SCREEN for temp
export const PREFERENCE_KEY = 'callNotifies';
export const PREFERENCE_NOTIFIES_FILE = 'callNotifiesPreferences';

export const CALL_SETTING_ABILITY_CONTEXT = 'callSettingsAbilityContext';
export const PRIVACY_STATEMENT_ABILITY_CONTEXT = 'privacyStatementAbilityContext';
export const CALL_SETTING_SATELLITE_ABILITY_CONTEXT = 'callSettingsSatelliteAbilityContext';
export const SATELLITE_SERVICE_CONTEXT = 'SatelliteServiceContext';
export const DISTRIBUTED_SETTING_CONTEXT = 'DistributedSettingContext';
export const GESTURE_MUTE_CALL_SETTING_CONTEXT = 'GestureMuteCallSettingContext';
export const GESTURE_QUICK_CALL_SETTING_CONTEXT = 'GestureQuickCallSettingContext';
export const CALL_BANNER_ABILITY_SESSION = 'callBannerAbilitySession';
export const NUMBER_IDENTITY_EXT_ABILITY_SESSION = 'numberIdentityPrivacyStatementUIExtAbilitySession';
export const PAGE_UPDATE_FLAG = 'pageUpdateFlag';
export const IS_START_SERVICE = 'isStartService';
export const IS_SMC_ENABLED = 'is_smc_enabled';
export const BEIDOU_SIM_SLOTID = 'beidou_sim_slotid';
export const NUMBER_IDENTITY_SERVICE_KEY = 'numberIdentityService';

export const CALL_RECORDER_BUNDLE_NAME = 'com.ohos.callrecorder';

export const CALL_RECORDER_ABILITY_NAME = 'com.ohos.callrecorder.CallRecorderAbility';

export const DATA_SHARE_ABILITY_NAME = 'datashare:///com.ohos.callrecorder.datashareAbility';
export const SETTINGS_DATA_SHARE_ABILITY_NAME = 'datashare:///com.ohos.settingsdata';

export const VOICE_CONTROL_BUNDLE_NAME = 'com.ohos.vassistant';
export const VOICE_CONTROL_ABILITY_NAME = 'CallVoiceControlUIExtensionAbility';
export const INTELLIGENT_CALL_SWITCH = 'const.call.intelligent_callui_enable'; // 机型特性隔离
export const AI_FEATURE_CELIA_CALL = 'const.ai.feature_celia_call';

export const WANT_START_REASON_SEARCH = 'from_search';
export const WANT_START_REASON_EXTERNAL = 'from_external';
export const CLOSE_SATELLITE_NETWORK_BUTTON = 'close_satellite_network_button';
export const IGNORE_NOTIFY_BUTTON = 'ignore_notify_button';
export const CELLULAR_NETWORK_NOTIFY_ID = 2;

export const RECORDER_CONFIG_TABLE = '/call_record/record_config';
export const NUMBER_IDENTITY_OPEN = '1';
export const NUMBER_IDENTITY_CLOSE = '0';
export const OOBE_BUNDLE_NAME = 'com.ohos.hwstartupguide';
export const PRIVACY_CENTER_BUNDLE_NAME = 'com.ohos.security.privacycenter';

export const EMIT_GET_RINGTONE_EVENT_ID = 1001;
export const EMIT_LANGUAGE_CHANGE_EVENT_ID = 1003;
export const EMIT_SINGLE_PICKER_EVENT_ID = 1004;
export const EMIT_NEW_FOLD_PHONE_EXTERNAL_EVENT_ID = 1005;
export const EMIT_GESTURE_CALL_PAGE_FOREGROUND = 1006;

export const WIFI_CALLING_ENABLED = 'wfc_ims_enabled';
export const WIFI_CALLING_SWITCH_OFF = '0';
export const WIFI_CALLING_SWITCH_ON = '1';
export const WIFI_CALLING_IMS_MODE = 'wfc_ims_mode';
export const WIFI_CALLING_IMS_MODE_WIFI = '2';
export const WIFI_CALLING_IMS_MODE_MOBILE_NETWORK = '1';
export const CARD_PAGE_MODE = 'card';

export const NAVIGATION_URL: string = 'navigationUrl';
export const NAVIGATION_MODE: string = 'navigationMode';
export const START_REASON: string = 'startReason';

/**
 * 滑动到底部默认距离导航条高度
 */
export const BOTTOM_MARGIN: number = 16;
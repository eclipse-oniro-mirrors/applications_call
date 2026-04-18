/**
 * Copyright (c) 2022-2024 Huawei Device Co., Ltd.
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
import call from '@ohos.telephony.call';
import emitter from '@ohos.events.emitter';
/**
 *  constants package tool class
 */
export const CALL_BUNDLE_NAME = 'com.ohos.callui';
export const CALL_ABILITY_NAME = 'com.ohos.callui.MainAbility';
export const HICAR_CALL_ABILITY_NAME = 'com.ohos.callui.HiCarMainAbility';
export const CALL_ABILITY_NAME_VOIP = 'com.ohos.callui.VoipAbility';
export const PETAL_MAP_BUNDLE_NAME = 'com.ohos.maps.app';
export const BAIDU_MAP_BUNDLE_NAME = 'com.baidu.hmmap';
export const A_MAP_BUNDLE_NAME = 'com.amap.hmapp';
// @ts-ignore
export const EVENT_HOLD_CALL_FAILED = Number(call.CallAbilityEventId.EVENT_HOLD_CALL_FAILED);
// @ts-ignore
export const EVENT_SWAP_CALL_FAILED = Number(call.CallAbilityEventId.EVENT_SWAP_CALL_FAILED);
export const EVENT_DEFAULT_CALL_FAILED = -1;
export const OP_EMPTY = 0;
export const OP_FULL = 1;
export const MIN_ANGLE = 45;
export const MAX_ANGLE = 75;
export const ANGLE_DIVIDE = 2;
export const LEFT_ANGLE = 270;
export const RIGHT_ANGLE = 90;
export const BOTTOM_ANGLE = 180;
export const FULL_SCALE = 1;
export const CALL_ABILITY_CONTEXT = 'calluiAbilityContext';
export const HICAR_CALL_ABILITY_CONTEXT = 'calluiHiCarAbilityContext';
export const EXTERNAL_CALL_ABILITY_CONTEXT = 'externalCallAbilityContext';
export const CALL_SERVICE_CONTEXT = 'calluiServiceContext';
export const ABILITY_WANT = 'abilityWant';
export const VOIP_ABILITY_CONTEXT = 'voipAbilityContext';
export const VOIP_ABILITY_WANT = 'voipAbilityWant';
export const WINDOW = 'window';
export const HICAR_WINDOW = 'hicarWindow';
export const CALL_SETTING_ABILITY_CONTEXT = 'callSettingAbilityContext';
export const CALL_DATA = 'callData';
export const CALL_LIST = 'callList';
export const INVALID_NUM = -1;
export const LEFT_DIRECTION = 0;
export const RIGHT_DIRECTION = 1;
export const BOTTOM_DIRECTION = 2;
export const IS_MULTI_DEVICE = 'isMultiDevice';
export const STRANGE_NUMBER_CALL_DATA = 'strangeNumberCallData';
export const CALL_SETTING_PAGE_WINDOW = 'CallSettingPageWindow';

export const BANNER = 'banner';
export const FULL_SCREEN = 'fullScreen';
export const DEFAULT_CONFIG = FULL_SCREEN; // target is BANNER, FULL_SCREEN for temp
export const PREFERENCE_KEY = 'callNotifies';
export const PREFERENCE_NOTIFIES_FILE = 'callNotifiesPreferences';
export const BANNER_TAG = 'bannerNotification';
export const EXTERNAL_LEFT_ICON = 'externalLeftIcon';
export const EXTERNAL_RIGHT_ICON = 'externalRightIcon';
export const EXTERNAL_BOTTOM_ICON = 'externalBottomIcon';
export const FOLD_PRODUCT_TYPE_KEY = 'const.window.foldscreen.type';
export const SMALL_EXTERNAL_DISPLAY_ID = 5;
export const DEFAULT_FOLD_CONFIGURATION = '0,0,0,0';

export const ANSWERED_TYPE_VIDEO = 'ANSWERED_TYPE_VIDEO';
export const ANSWERED_TYPE_VOICE = 'ANSWERED_TYPE_VOICE';

export const EVENT_SUPER_PRIVACY_MODE_ON = 20;
export const EVENT_SUPER_PRIVACY_MODE_OFF = 21;
export const EVENT_MUTE_RING = 22;
export const EVENT_LOCAL_ALERTING = 23;

export const SCREEN_CAST_PRIVACY_PROJECTION_STATE = 'huaweicast.data.privacy_projection_state';

export const SETTINGS_DEVICE_PROVISIONED = 'device_provisioned';
export const SETTINGS_USER_SETUP_COMPLETE = 'user_setup_complete';
export const SETTINGS_IS_OTA_FINISHED = 'is_ota_finished';

export const PERSIST_HIVIEWCARE_MAINTENANCEMODE = 'persist.hiviewcare.maintenancemode';

export const STRING_TRUE = 'true';

export const ACCESSIBILITY_SCREEN_READER = 'accessibility_screenreader_enabled';

export const DISTRIBUTE_MODEM_STATE = 'distributed_modem_state';

export const DISTRIBUTE_MODEM_DEVICE_NAME = 'distributed_modem_device_name';

export const DISTRIBUTE_CALL_SOURCE_SMS = 'distributed_call_source_sms';

export const DISTRIBUTED_CALL_SMS_SHARING_SINK = 'distributed_call_sms_sharing_sink';

export const DISTRIBUTE_SOURCE_CALL = '1_source';

export const DISTRIBUTE_SINK_CALL = '1_sink';

export const MUTE_BUTTON_DISABLED = -1;

export const VOICE_CONTROL_SWITCH = 'voiceControlSwitch';
export const VOICE_BROADCAST_SWITCH = 'voiceBroadcastSwitch';

export const EVENT_SPEAKER_OFF = 'EVENT_SPEAKER_OFF';
export const EVENT_REQUEST_FOCUS_FOR_ACCESSIBILITY = 'requestFocusForAccessibility';
export const EVENT_TRIGGER_ACTION = 'common';

export const WALLPAPER_EVENT_ID = 100;
export const WALLPAPER_EVENT = { eventId: WALLPAPER_EVENT_ID, priority: emitter.EventPriority.HIGH };

export const UPDATE_VIDEO_RINGTONE_EVENT_ID = 102;

export const UPDATE_VIDEO_RINGTONE_EVENT =
  { eventId: UPDATE_VIDEO_RINGTONE_EVENT_ID, priority: emitter.EventPriority.HIGH };

export const OPEN_VIDEO_CAMERA = 'OPEN_VIDEO_CAMERA';

export const COVER_WINDOW_SHOWING = 'cover_window_showing';

export const ANTIFRAUD_CENTER_SWITCH = 'settings.telephony.antifraud_center_switch';

export const BEST_MIND_SETTING_KEY = 'settings.telephony.antifraud_bestmind_switch';

export const NUMBER_IDENTITY_KEY = 'settings.telephony.number_identity_switch';

export const ALPHA_NO = 1.0;
export const ALPHA_HAVE = 0.4;

export const CALL_DISCONNECTED_BY_REMOTE = 8;

export const START_CHECK_CALL_RISK = 1;
export const CALL_RISK_DETECTED = 2;
export const DIALOG_HANG_UP = 3;
export const DIALOG_HANG_UP_AND_BLOCKLIST = 4;
export const DIALOG_CONTINUE_CALL = 5;

export const PRODUCT_TYPE_KEY = 'const.build.product';

export const ACCESSIBILITY_LEVEL_YES = 'yes';

export const PROJECTION_DEVICE = ['HuaweiCast-Dual', 'HuaweiCast', 'Miracast', 'HuaweiShare-Dual'];
export const COLLABORATION_MOTION_SERVICE = 'MotionFramework'; // 协同框架中标识动效完成的serviceName，hicar、流转都有用到

export enum IMS_DOMAIN {
  IMS_DOMAIN_VOLTE = 0,
  IMS_DOMAIN_VOWIFI,
  IMS_DOMAIN_VONR
}

export const TOW_WAY_PRIVACY_ENHANCED_CALL = 'tow_way_privacy_enhanced_call';

export enum UE_CALL_TYPE {
  CARRIER_CALL = 0,
  VOIP_CALL = 1
}

export enum UE_MUTE_STATE {
  MUTE = 0,
  UNMUTE = 1
}

export enum ROTATION_ANGLE {
  LEFT = 0,
  TOP = 1,
  RIGHT = 2,
  BOTTOM = 3
}

export const EVENT_CELIA_AUTO_ANSWER_CALL_ON = 'EVENT_CELIA_AUTO_ANSWER_CALL_ON';

export enum AntiFraudState {
  /**
   * Indicates the default anti fraud state
   */
  ANTI_FRAUD_STATE_DEFAULT = 0,
  /**
   * Indicates the anti fraud is started
   */
  ANTI_FRAUD_STATE_STARTED,
  /**
   * Indicates the call is fraud risk call
   */
  ANTI_FRAUD_STATE_RISK,
  /**
   * Indicates the anti fraud is finished and the call is not fraud call
   */
  ANTI_FRAUD_STATE_FINISHED,
};

/**
 * 视频铃声
 */
export const FLAG_PATH_A: string = '/data/themes/a/app/flag';
export const ICONS = 'icons';
/**
 * 预置图标相对路径
 */
export const ICON_RESOURCE_SRC = 'resource/themes/icon';
/**
 * foreground图标路径
 */
export const ICON_FORE_PATH: string = '/entry/foreground';
/**
 * 图标资源png后缀名
 */
export const FORMAT_PNG: string = '.png';
/**
 * 图标资源webp后缀名
 */
export const FORMAT_WEBP: string = '.webp';
/**
 * background图标路径
 */
export const ICON_BACK_PATH: string = '/entry/background';
/**
 * 文件分隔符
 */
export const FILE_SEPARATOR = '/';
/**
 * A目录app路径
 */
export const APP_SANDBOX_PATH_A: string = '/data/themes/a/app/';
/**
 * B目录flag路径
 */
export const FLAG_PATH_B: string = '/data/themes/b/app/flag';
/**
 * B目录app路径
 */
export const APP_SANDBOX_PATH_B: string = '/data/themes/b/app/';
/**
 * B目录app路径
 */
export const VIDEO_RINGTONE_DATA: string = 'video_ringtone_data';

export const DEFAULT_FONT_SIZE_SCALE: number = 1;

export const MAX_FONT_SCALE: number = 3.2;

export const VIDEO_RINGTONE_HISTORY_DATA_SP: string = 'videoRingtoneHistoryData';

export const VIDEO_RINGTONE_DATA_SP: string = 'videoRingtoneData';

export const VIDEO_RINGTONE_SOURCE_SETTING: number = 0;

export const VIDEO_RINGTONE_SOURCE_CONTACT: number = 1;

export const NO_RING_SOUND: string = 'no_ring_sound';

export const VIDEO_RINGTONE_CONTACTS_FLAG = 'VideoRingtoneContactsFlag';

export const VIDEO_RINGTONE_THUMB_SUFFIX = '.jpg';

export const VIDEO_RINGTONE_SUFFIX = '.mp4';

export const CARD1_VALUE = '0';

export const CARD2_VALUE = '1';

export const VIDEO_RINGTONE_MAX_SIZE: number = 1048576000;

export const VIDEO_RINGTONE_MAX_SIZE_STR: string = '1000 MB';

export const VIDEO_RINGTONE_SETTINGS_DATA_KEY_CARD1: string = 'videoRingtoneNameCard1';

export const VIDEO_RINGTONE_SETTINGS_DATA_KEY_CARD2: string = 'videoRingtoneNameCard2';

export const RINGTONE_SETTINGS_FLAG_CARD1: string = 'ringtoneFlagCard1';

export const RINGTONE_SETTINGS_FLAG_CARD2: string = 'ringtoneFlagCard2';

export const RINGTONE_SETTINGS_FLAG_VIDEO: string = '1';

/**
 * 用于承载高风险来电提醒dialog的空的窗口的name
 */
export const CALLUI_WINDOW_FOR_DIALOG: string = 'window_for_toast_when_callui_onBackground';

/**
 * 用于传递高风险来电参数的localstorage的key值
 */
export const KEY_FOR_DIALOG_CALLID: string = 'dl_callId';

export const KEY_FOR_DIALOG_CALLLISTCOUNT: string = 'dl_callListCount';

export const KEY_FOR_DIALOG_ACCOUNTNUMBER: string = 'dl_accountNumber';

export const KEY_FOR_DIALOG_FORMATNUMBER: string = 'dl_formatNumber';

export const SUCCESS = 'SUCCESS';

export const FAILURE = 'FAILURE';

export const ALL_SWITCH_ENABLE = 63;
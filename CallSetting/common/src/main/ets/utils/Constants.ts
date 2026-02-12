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

/**
 *  constants package tool class
 */

export class Constants {
  public static readonly CALL_SETTING_ABILITY_CONTEXT = 'callSettingsAbilityContext';
  public static readonly SETTINGS_ABILITY_CONTEXT = 'settingsAbilityContext';
  public static readonly MOBILE_DATA: string = 'mobile_data';
  public static readonly MOBILE_DATA_DEFAULT: number = -1;
  public static readonly MOBILE_DATA_ENABLE_VALUE: number = 1;
  public static readonly DATA_ROAMING = 'data_roaming';
  public static readonly DATA_ROAMING1 = 'data_roaming';
  public static readonly DATA_ROAMING2 = 'data_roaming_sim2';
  public static readonly DATA_ROAMING_ENABLE_VALUE: number = 1;
  public static readonly DATA_ROAMING_DEFAULT: number = -1;
  public static readonly MAX_SIM_COUNTS = 2;
  public static readonly VERSION = '0.0.0.0';
  public static readonly SETTINGS_DATA_GLOBAL_URI = 'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true';
  public static readonly SETTINGS_DATA_SYSTEM_URI = 'datashare:///com.ohos.settingsdata/entry/settingsdata/USER_SETTINGSDATA_100?Proxy=true&key=incall_power_button_behavior';
  public static readonly CALL_LOG_MERGE_TYPE = 'settings.telephony.calllogmergetype';
  public static readonly CALL_LOG_DEFAULT: number = -1;
  public static readonly IN_CALL_HANG_UP = 'incall_power_button_behavior';
  public static readonly IN_CALL_HANG_UP_DEFAULT: number = 0;
  public static readonly NUMBER_IDENTITY_OPTION: string = 'hw_numbermark_option';
  public static readonly NUMBER_IDENTITY_KEY: string = 'settings.telephony.number_identity_switch';
  public static readonly OLD_NUMBER_IDENTITY_VALUE_ON: string = 'hw_numbermark_usenetworks';
  public static readonly NEW_NUMBER_IDENTITY_VALUE_ON: string = '1';
  public static readonly NEW_NUMBER_IDENTITY_VALUE_OFF: string = '0';
  public static readonly CALL_NOTIFY_TYPE: string = 'settings.telephony.callnotifytype';
  public static readonly CALL_NOTIFY_TYPE_DEFAULT: string = '-1';
  public static readonly CALL_NOTIFY_TYPE_FULLSCREEN: string = 'fullScreen';
  public static readonly CALL_NOTIFY_TYPE_BANNER: string = 'banner';
  public static readonly CALL_NOTIFY_TYPE_BANNER_NUMBER: string = '1';
  public static readonly OPEN_PHONE_TO_ANSWER: string = 'open_phone_to_answer';
  public static readonly OPEN_PHONE_TO_ANSWER_ON: number = 1;
  public static readonly OPEN_PHONE_TO_ANSWER_OFF: number = 0;
  public static readonly VOLTE_USER_SWITCH_DEFAULT: string = '-1';
  public static readonly VOLTE_USER_SWITCH_ON: string = '1';
  public static readonly VOLTE_USER_SWITCH_OFF: string = '0';
  public static readonly VOLTE_USER_SWITCH_0: string = 'hw_volte_user_switch_0';
  public static readonly VOLTE_USER_SWITCH_1: string = 'hw_volte_user_switch_1';
  public static readonly VOLTE_USER_SWITCH_SLOT_0: number = 0;
  public static readonly VOLTE_USER_SWITCH_SLOT_1: number = 1;
  public static readonly FUSION_CALL_KEY: string = 'fusion_call_switch';
  public static readonly INCALL_POWER_KEY: string = 'incall_power_button_behavior';
  public static readonly DISTRIBUTE_MODEM_STATE = 'distributed_modem_state';
  public static readonly DISTRIBUTE_SINK_CALL = '1_sink';
  public static readonly BLUE_CONNECT_STATE: string = 'Blue_Connect_State';
  public static readonly DEFAULT_FOLD_CONFIGURATION = '0,0,0,0';
  public static readonly FOLD_PRODUCT_TYPE_KEY = 'const.window.foldscreen.type';

  public static readonly UE_SELECT_SIM1 = 1;
  public static readonly UE_SELECT_SIM2 = 2;
  public static readonly UE_CLICK_ALERT_CANCEL = 3;
  public static readonly UE_CLICK_STOP_BTN = 1;
  public static readonly UE_CLICK_CANCEL_BTN = 2;
  public static readonly UE_IS_NOT_CTCARD = 1;
  public static readonly UE_IN_AIRPLANE = 3;
  public static readonly UE_TIANJITONG_OPEND = 4;
  public static readonly UE_INCALL = 6;
  public static readonly UE_INITIATIVE_QUIT = 1;
  public static readonly UE_AIRPLAN_QUIT = 3;
  public static readonly UE_PLUG_AND_UNPLUG = 5;
  public static readonly UE_SATELLITE_FIVE_MINUTE = 24;
  /**
   * 没有网络
   */
  public static readonly UE_NO_NET = 7;
  public static readonly PRIVACY_STATEMENT_VERSION = '1.0.0';

  public static readonly SLOT_ID_ONE: number = 0;
  public static readonly SLOT_ID_TWO: number = 1;
  /**
   * 视频铃声
   */
  public static readonly FLAG_PATH_A: string = '/data/themes/a/app/flag';
  public static readonly ICONS = 'icons';
  /**
   * 预置图标相对路径
   */
  public static readonly ICON_RESOURCE_SRC = 'resource/themes/icon';
  /**
   * foreground图标路径
   */
  public static readonly ICON_FORE_PATH: string = '/entry/foreground';
  /**
   * 图标资源png后缀名
   */
  public static readonly FORMAT_PNG: string = '.png';
  /**
   * 图标资源webp后缀名
   */
  public static readonly FORMAT_WEBP: string = '.webp';
  /**
   * background图标路径
   */
  public static readonly ICON_BACK_PATH: string = '/entry/background';
  /**
   * 文件分隔符
   */
  public static readonly FILE_SEPARATOR = '/';
  /**
   * A目录app路径
   */
  public static readonly APP_SANDBOX_PATH_A: string = '/data/themes/a/app/';
  /**
   * B目录flag路径
   */
  public static readonly FLAG_PATH_B: string = '/data/themes/b/app/flag';
  /**
   * B目录app路径
   */
  public static readonly APP_SANDBOX_PATH_B: string = '/data/themes/b/app/';
  /**
   * B目录app路径
   */
  public static readonly VIDEO_RINGTONE_DATA: string = 'video_ringtone_data';

  public static readonly DEFAULT_FONT_SIZE_SCALE: number = 1;

  public static readonly MAX_FONT_SCALE: number = 3.2;

  public static readonly VIDEO_RINGTONE_HISTORY_DATA_SP: string = 'videoRingtoneHistoryData';

  public static readonly VIDEO_RINGTONE_DATA_SP: string = 'videoRingtoneData';

  public static readonly VIDEO_RINGTONE_SOURCE_SETTING: number = 0;

  public static readonly VIDEO_RINGTONE_SOURCE_CONTACT: number = 1;

  public static readonly NO_RING_SOUND: string = 'no_ring_sound';

  public static readonly VIDEO_RINGTONE_CONTACTS_FLAG = 'VideoRingtoneContactsFlag';

  public static readonly VIDEO_RINGTONE_THUMB_SUFFIX = '.jpg';

  public static readonly VIDEO_RINGTONE_SUFFIX = '.mp4';

  public static readonly CARD1_VALUE = '0';

  public static readonly CARD2_VALUE = '1';

  public static readonly VIDEO_RINGTONE_MAX_SIZE: number = 524288000;

  public static readonly VIDEO_RINGTONE_MAX_SIZE_STR: string = '200 MB';

  public static readonly RINGTONE_SETTINGS_FLAG_VIDEO: string = '1';

  public static readonly TIAN_TONG_SATELLITE_CLOSE_EVENT: string = 'tian_tong_satellite_close';

  public static readonly TIAN_TONG_SATELLITE_OPEN_EVENT: string = 'tian_tong_satellite_open';

  public static readonly TIAN_TONG_SATELLITE_STATE_CLOSE: string = '0';

  public static readonly TIAN_TONG_SATELLITE_STATE_OPEN: string = '1';

  // 北斗卫星sim卡变化时通知应用北斗页面刷新
  public static readonly BEI_DOU_SIM_SLOTID_UPDATE: string = 'bei_sou_sim_slotId_update';
}
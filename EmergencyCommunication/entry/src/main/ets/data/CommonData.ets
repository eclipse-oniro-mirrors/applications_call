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

import { ContactListStruct } from '../utils/ClassStruct';

export default class CommonData {
  public static bool: Record<string, string> = {
    'TRUE': '1',
    'FALSE': '0',
  };
  public static int: Record<string, number> = {
    // status code
    'SUCCESS': 0,
    'FAILURE': -1,
    'INVALID': -1,
    'UN_KNOW': 2,

    'DEFAULT_CONTACT_TYPE': 0,
    'COMMON_CONTACT_TYPE': 1,
    'TITLE_TYPE': 2,
    'LOCATION_STATE_DOING': 0,
    'LOCATION_STATE_FAILED': 1,
    'LOCATION_STATE_DONE': 2,
    'SIM_SLOT_ID_EMPTY': -1,
    'SIM_SLOT_ID_FIRST': 0,
    'SIM_SLOT_ID_SECOND': 1,

    'CONTACT_UPPER_LIMIT': 3,
    'SEND_SMS_SUCCESS': 0,
    //tablet screen orientation
    'DEVICE_DISPLAY_ROW': 1,
    'DEVICE_DISPLAY_ROW_REVERSE': 3,
    //contacts type
    'CONTACTS_PHONENUMBER': 5,
    'CONTACTS_NAME': 6
  };
  public static string: Record<string, string> = {
    // BundleName of a contact.
    'CONTACT_BUNDLE_NAME': 'com.ohos.contacts',
    // contact AbilityName
    'CONTACT_ABILITY_NAME': 'com.ohos.contacts.MainAbility',
    // Public entity
    'COMMON_ENTITIES': 'entity.system.home',
    // SMS database
    'URI_MESSAGE_LOG': 'datashare:///com.ohos.smsmmsability',
    // sms_mms_info table
    'URI_MESSAGE_INFO_TABLE': '/sms_mms/sms_mms_info',
    // session table
    'URI_MESSAGE_SESSION_TABLE': '/sms_mms/session',
  };
  public static defaultContactsList: ContactListStruct[] =
    [
      {
        value: '110',
        label: $r('app.string.POLICE'),
        id: 'default0',
        type: 0
      }, {
      value: '119',
      label: $r('app.string.FIRE'),
      id: 'default1',
      type: 0
    }, {
      value: '120',
      label: $r('app.string.AMBULANCE'),
      id: 'default2',
      type: 0
    }
    ];
  public static contactPage: Record<string, string> = {
    // The page for selecting a contact is displayed after an SMS message is sent.
    'PAGE_FLAG_SINGLE_CHOOSE': 'page_flag_single_choose',
  };
  public static backgroundColor: Record<string, string> = {
    'index': '#000000',
    'common': '#F1F3F5',
    'commonDark': '#000000'
  }
  public static readonly PRIVACY_STATEMENT_VERSION_OF_EARTHQUAKE_WARNING = '1.0.0';
  public static readonly PRIVACY_STATEMENT_VERSION_OF_AUTO_SEND_SOS_MESSAGE = '1.0.0';
  public static readonly PRIVACY_STATEMENT_VERSION_OF_AUTO_CAR_ACCIDENT_SEND_SOS_MESSAGE = '1.0.0';
  public static readonly PRIVACY_STATEMENT_VERSION_OF_AUTO_FALL_DOWN_SEND_SOS_MESSAGE = '1.0.0';

  /**
   * 收到中国地震局的地震消息是，保存收到的时间
   */
  public static readonly EARTHQUAKE_PUSH_UTC_TIMESTAMP = 'earthquake_push_utc_timestamp';
  /**
   * 收到中国地震局的地震消息时，保存提醒时间
   */
  public static readonly EARTHQUAKE_REMINDER_UTC_TIMESTAMP = 'earthquake_reminder_utc_timestamp'

  public static readonly EARTHQUAKE_REMINDER_LEVEL = 'reminder_type';
  public static readonly EARTHQUAKE_INTENSITY = 'earthquake_intensity';
  public static readonly EARTHQUAKE_EVENT_ID = 'earthquake_event_id';
}

export class AVPlayerState {
  public static readonly IDLE: string = 'idle';
  public static readonly INITIALIZED: string = 'initialized';
  public static readonly PREPARED: string = 'prepared';
  public static readonly PLAYING: string = 'playing';
  public static readonly PAUSED: string = 'paused';
  public static readonly COMPLETED: string = 'completed';
  public static readonly STOPPED: string = 'stopped';
  public static readonly RELEASED: string = 'released';
  public static readonly STARTED: string = 'started';
  public static readonly ERROR: string = 'error';
}

export class DatabaseUri {
  public static readonly URI_ROW_CONTACTS: string = 'datashare:///com.ohos.contactsdataability';
  public static readonly RAW_CONTACT_URI: string = '/contacts/raw_contact';
  public static readonly CONTACT_DATA_URI: string = '/contacts/contact_data';
  public static readonly SETTING_SATELLITE_URI: string =
    'datashare:///com.ohos.callsetting.satellitedatashareAbility';
  public static readonly SETTING_SATELLITE_LOCATION_URI: string =
    'datashare:///com.ohos.callsetting.satellitedatashareStatus.location';
  public static readonly SETTING_SATELLITE_STATUS_URI: string =
    'datashare:///com.ohos.callsetting.satellitedatashareStatus.status';
}

export enum AutoDialCallResult {
  SUCCESS = 1,
  FAIL_WITH_NO_CONTACTS = 2,
  FAIL_WITH_NO_SIM_CARD = 3,
  FAIL_WITH_FLIGHT_MODE = 4,
  FAIL_TO_GET_LOCATION = 5
}

export enum AutoSendSosMessageResult {
  SUCCESS = 1,
  FAIL_WITH_NO_CONTACTS = 2,
  FAIL_WITH_NO_SIM_CARD = 3,
  FAIL_WITH_FLIGHT_MODE = 4,
  FAIL_TO_GET_LOCATION = 5
}

export enum LocationReportResultOfEarthquake {
  SUCCESS = 1,
  FAILURE = 2
}

export enum LocationReportResultOfSos {
  SUCCESS = 1,
  FAIL_WITH_NO_NETWORK = 2,
  FAIL_TO_GET_LOCATION = 3,
  SERVER_RETURN_FAILURE = 4
}

export enum LocationReportResultOfEps {
  SUCCESS = 1,
  FAIL_WITH_SUPPLIER_NOT_EXIST = 2,
  FAIL_TO_VERIFY_SIGNATURE = 3,
  FAIL_TO_VERIFY_DATA = 4,
  INTERNAL_SERVER_ERROR = 5,
  FAIL_WITH_NO_NETWORK = 6
}

export enum PersonalSafetyReportTriggerType {
  CRASH = 1,
  FALL = 2
}

export enum PersonalSafetyReportSwitch {
  CLICK = -1,
  CLOSE = 0,
  OPEN = 1,
  CANNOT_OPEN_WITHOUT_LOCATION = 2,
  ADD_CONTACT = 3,
}

export enum PersonalSafetyReportSosType {
  CANCEL = 0,
  MANUALLY = 1,
  AUTO = 2
}

export enum CommunicationNetworkType {
  NONE = 'None_Communication_Network',
  CELLULAR = 'Cellular_Network',
  TIAN_TONG = 'TianTong_Satellite_Network'
}

export enum DeviceLocationSaveKey {
  GEOCODE_KEY = 'geocode_key',
  LONGITUDE_KEY = 'longitude_key',
  LATITUDE_KEY = 'latitude_key',
  SAVE_TIME_KEY = 'save_time_key'
}

export enum EarthquakeSource {
  EARTHQUAKE_NORMAL_SOURCE = 1, // 1中国地震局的push地震消息
}

export enum EarthquakeType {
  EARTHQUAKE_NORMAL_TYPE = '0', // 正式地震报文
  EARTHQUAKE_TEST_TYPE = '1', // 测试地震报文
  EARTHQUAKE_CANCEL_TYPE = '10000', // 取消的正式的地震报文
  EARTHQUAKE_CANCEL_TEST_TYPE = '10001' // 取消的测试的地震报文
}

export enum EarthquakeReminderLevel {
  STRONG_REMINDER = 0, // 强提醒
  NORMAL_REMINDER = 1, // 普通提醒
  NO_REMINDER = 2 // 无提醒
}

export class CommonEvent {
  public static readonly SATELLITE_SUBSCRIBER_CONNECT_EVENT: string = 'event.custom.satellite.ACTION_SATELLITE_CONNECT';
}

export interface ReturnResult {
  code: number
  result?: string
}

export interface ReportEarthquakeInfoParams {
  deviceId: string,
  deviceType: number,
  deviceModel: string,
  romVersion: string,
  levelTotal: number,
  receivingTime: number,
  reminderType: number,
  eewId: string,
  geoCode: string
}
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
// float window name
export const SATELLITE_FLOAT_WINDOW: string = 'floatWindow';

// satellite dialog window name
export const SATELLITE_DIALOG: string = 'satelliteDialog';

// satellite strong notify window name
export const STRONG_NOTIFY: string = 'strongNotify';

// alert dialog window name
export const ALERT_DIALOG: string = 'alertDialog';

// new fold device alert dialog window name
export const NEW_FOLD_ALERT_DIALOG: string = 'newFoldAlertDialog';

// SYS_STATUS_DEFAULT
export const SYS_STATUS_DEFAULT: number = 0;

// CALIBRATING
export const SYS_STATUS_WAIT_CALIBRATING: number = 1;

// LOADING
export const SYS_STATUS_WAIT_LOADING: number = 2;

// SEARCHING SATELLITE
export const SYS_STATUS_SEARCHING_SATELLITE: number = 3;

// SEARCH SATELLITE SUCCEED
export const SYS_STATUS_SEARCH_SATELLITE_SUCC: number = 4;

// SEARCH SATELLITE FAIL
export const SYS_STATUS_SEARCH_SATELLITE_FAIL: number = 5;

// CALIBRATING
export const SYS_STATUS_SATELLITE_CONNECTING: number = 7;

// 连接中断
export const SYS_DISCONNECT: number = -1;

// BLOCKING
export const SYS_STATUS_WAIT_BLOCKING: number = 12;

// CONNECTING
export const DEFAULT_CAUSE_CODE: number = 0;

// max calibrate accuracy (0, 1, 2, 3)
export const ACCURACY_CANUSE: number = 2;

// max calibrate accuracy (0, 1, 2, 3)
export const ACCURACY_FINISH: number = 3;

// SERVICE_CB_SYSTEM_STATUS
export const SERVICE_CB_SYSTEM_STATUS: number = 1;

// SEARCH SATELLITE INFOMATION
export const SERVICE_CB_SATE_INFO: number = 3;

// SEND_STATUS_FAIL
export const SEND_STATUS_FAIL: number = 64;

// SEND_STATUS_SENT
export const SEND_STATUS_SENT: number = 128;

// SEND_STATUS_SUCC
export const SEND_STATUS_SUCC: number = 8;

// SYS_STATUS_RESOURCE_READY
export const SYS_STATUS_RESOURCE_READY: number = 1;

// SYS_STATUS_NWREJ
export const SYS_STATUS_NWREJ: number = 2;

// SYS_STATUS_ENHANCES_CONNECT
export const SYS_STATUS_ENHANCES_CONNECT: number = 3;

// SYS_STATUS_CP_TIMEOUT
export const SYS_STATUS_CP_TIMEOUT: number = 4;

// SYS_STATUS_HOT_PLUG
export const SYS_STATUS_HOT_PLUG: number = 5;

// SYS_STATUS_SIMST_OFF
export const SYS_STATUS_SIMST_OFF: number = 7;

// SYS_STATUS_NETWORK_REGED
export const SYS_STATUS_NETWORK_REGED: number = 8;

// SYS_STATUS_NETWORK_UNREGED
export const SYS_STATUS_NETWORK_UNREGED: number = 9;

// SYS_STATUS_SERVICE_DIED
export const SYS_STATUS_SERVICE_DIED: number = 10;

// SYS_STATUS_UPDATE_DELTA
export const SYS_STATUS_UPDATE_DELTA: number = 11;

// SYS_STATUS_CELLULAR_NETWORK
export const SYS_STATUS_CELLULAR_NETWORK: number = 12;

// The sensor delay time
export const SENSOR_DELAY_TIME: number = 50000;

// The wait loading time (seconds)
export const WAIT_LOADING_TIME: number = 30;

// Type of TYPE_AZIMUTH_DELTA
export const TYPE_AZIMUTH_DELTA: String = 'azimuthDelta';

// Type of TYPE_PITCHANGLE_DELTA
export const TYPE_PITCHANGLE_DELTA: String = 'pitchAngleDelta';

// Type of TYPE_SIGNAL
export const TYPE_SIGNAL: String = 'signal';

// ANIMDURATION
export const ANIMDURATION: number = 1500;

// ANIMSPEED
export const ANIMSPEED: number = 400;

// ANIMRADIUS
export const ANIMRADIUS: number = 40;

// ANIMPICTHANGLE
export const ANIMPICTHANGLE: number = 60;

// START_DAIL_ACTIVITY
export const START_DAIL_ACTIVITY: number = 1001;

// START_MESSAGE_ACTIVITY
export const START_MESSAGE_ACTIVITY: number = 1002;

// MOVE_ACTIVITY_DELAY_MESSAGE
export const MOVE_ACTIVITY_DELAY_MESSAGE: number = 1003;

// MOVE_ACTIVITY_DELAY_TIME
export const MOVE_ACTIVITY_DELAY_TIME: number = 300;

// CURRENT_CAILBRATE_PITCH
export const CURRENT_CAILBRATE_PITCH: number = 1;

// CURRENT_CAILBRATE_AZIMUTH
export const CURRENT_CAILBRATE_AZIMUTH: number = 0;

// Enter the activity transition animation
export const TYPE_FADE_IN: number = 1;

// Space string
export const SPACE: String = ' ';

// sound when connecting fail
export const CONNECT_SUCC_SOUND: number = 0;

// search satellite direction
export const CONNECT_FAIL_SOUND: number = 1;

// The maximum connection time is 60s. If the connection is not successful, it will fail.
export const WAIT_STATE_TIME: number = 60;

// The maximum connection time for cactus is 15 + 15 = 30s. If the connection is not successful, it will fail.
export const WAIT_STATE_TIME_CACTUS: number = 30;

export const HALF_WAIT_STATE_TIME_CACTUS: number = WAIT_STATE_TIME_CACTUS / 2;

// Satellite switch is on
export const SATELLITE_SWITCH_ON: number = 1;

// Satellite switch is off
export const SATELLITE_SWITCH_OFF: number = 0;

// Satellite slotid key
export const SATELLITE_KEY_SLOT_ID: string = 'satellite_slot_id';

// Satellite carrier type key
export const SATELLITE_KEY_CARRIER_TYPE: string = 'satellite_carrier_type';

// hyacinth location permission key
export const HYACINTH_LOCATION_ALLOWED: string = 'isLocationAllowed';

// Satellite connecting state on
export const SATELLITE_CONNECTING_ON: number = 1;

export const SATELLITE_CONNECTING_DEFAULT_PAGING: number = 0;

export const SATELLITE_CONNECTING_STRONG_PAGING: number = 1;

export const SATELLITE_CONNECTING_STRONG_N0TIFY: number = 2;

// Satellite connecting state off
export const SATELLITE_CONNECTING_OFF: number = 0;

export const SATELLITE_TOAST_AIRPLANE_CODE: number = 2;

export const SATELLITE_TOAST_OFF_CODE: number = 1;

export const SATELLITE_CLOSE_DIALOG_CODE: number = 3;

export const SATELLITE_TOAST_DURATION: number = 2000;

export const SATELLITE_TOAST_DURATION_NEW_FOLD: number = 5000;

export const ERROR_CODE_NOT_ACTIVATED_SIM: number = 0;

export const ERROR_CODE_NOT_OPENED_ROAMING: number = 4;

export const ERROR_CODE_NOT_OPENED_TIANDIWINGCARD: number = 2;

export const ERROR_CODE_NOT_SUPPORT_CARD: number = 256;

export const ERROR_CODE_OTHERS: number = 5;

// Receive status is receiving
export const RECEIVER_STATUS_RECEIVING: number = 9;

// Receive status is success
export const RECEIVER_STATUS_SUCCESS: number = 10;

// SYS_STATUS_SATELLITE_KEEPING
export const SYS_STATUS_SATELLITE_KEEPING: number = 11;

// Receive status is fail
export const RECEIVER_STATUS_FAIL: number = 27;

// Receive status is null
export const RECEIVER_STATUS_NULL: number = 36;

// Sending time
export const SENDING_TIME: number = 15;

// Close dialog delay
export const CLOSE_DIALOG_DELAY: number = 3000;

// Send Receipt Countdown timer
export const SEND_RECEIPT_COUNTDOWN_TIMER: number = 1500;

// Maximum number of remaining received messages
export const MAX_QUANTITY_TO_RECEIVE = 50;

export const MAIN_ACCOUNT_ID: number = 100;

// Maximum font scaling
export const MAX_FONT_SCALE: number = 1;

export const SHOW_TIME_FIFTEEN: number = 15 * 60;

export const EVENT_SATELLITE_WINDOW_SHOW = ['usual.event.SCREEN_UNLOCKED', 'usual.event.satellite.window.show'];

export const EVENT_SATELLITE_WINDOW_HIDE = ['usual.event.SCREEN_LOCKED', 'usual.event.satellite.window.hide'];

export const HYACINTH_SIM_SHOW_NAME: string = 'showNameForHyacinth';

// 半模态切星发生时间
export const HYACINTH_DIALOG_SWITCH_SATELLITE_START_TIMES = 'hyacinthDialogSwitchSatelliteStartTimes';
// 半模态切星老卫星闪烁执行时间
export const HYACINTH_DIALOG_OLD_SATELLITE_WINKED_TIMES = 'hyacinthDialogOldSatelliteWinkedTimes';
// 半模态切星老卫星方位角
export const HYACINTH_DIALOG_OLD_SATELLITE_AZIMUTH = 'hyacinthDialogOldSatelliteAzimuth';
// 悬浮窗切星发生时间
export const HYACINTH_FLOAT_SWITCH_SATELLITE_START_TIMES = 'hyacinthFloatSwitchSatelliteStartTimes';
// 悬浮窗切星老卫星闪烁执行时间
export const HYACINTH_FLOAT_OLD_SATELLITE_WINKED_TIMES = 'hyacinthFloatOldSatelliteWinkedTimes';
// 悬浮窗切星老卫星方位角
export const HYACINTH_FLOAT_OLD_SATELLITE_AZIMUTH = 'hyacinthFloatOldSatelliteAzimuth';

export enum EnterSatelliteNetwork {
  DESKTOP = 'desktop',
  SETTINGS = 'settings',
}

export enum SatelliteDirection {
  NONE = 0,
  LEFT,
  RIGHT,
  UP,
  DOWN
}

/**
 * Satellite level
 */
export enum SatelliteLevel {
  /**
   * low
   */
  SATELLITE_LEVEL_LOW = 59,

  /**
   * medium
   */
  SATELLITE_LEVEL_MEDIUM = 60,

  /**
   * high
   */
  SATELLITE_LEVEL_HIGH = 61,
}

/**
 * Satellite operation type
 */
export enum SatelliteOperationType {
  /**
   * send
   */
  OPERATION_TYPE_SEND = 'send',

  /**
   * receive
   */
  OPERATION_TYPE_RECEIVE = 'receive',

  /**
   * sendSuccess
   */
  OPERATION_TYPE_SEND_SUCCESS = 'sendSuccess',

  /**
   * sent
   */
  OPERATION_TYPE_SENT = 'sent',

  /**
   * sendFail
   */
  OPERATION_TYPE_SEND_FAIL = 'sendFail',

  /**
   * receiveSuccess
   */
  OPERATION_TYPE_RECEIVE_SUCCESS = 'receiveSuccess',

  /**
   * receiveFail
   */
  OPERATION_TYPE_RECEIVE_FAIL = 'receiveFail',

  /**
   * receiveNull
   */
  OPERATION_TYPE_RECEIVE_NULL = 'receiveNull',

  /**
   * sysStatusSearching
   */
  OPERATION_TYPE_SYS_STATUS_SEARCHING = 'sysStatusSearching',

  /**
   * sysStatusSending
   */
  OPERATION_TYPE_SYS_STATUS_SENDING = 'sysStatusSending',

  /**
   * sysStatusReceiving
   */
  OPERATION_TYPE_SYS_STATUS_RECEIVING = 'sysStatusReceiving',

  /**
   * sysStatusBlocking
   */
  OPERATION_TYPE_SYS_STATUS_BLOCKING = 'sysStatusBlocking',

  /**
   * hideSmcSatellitePage
   */
  OPERATION_TYPE_HIDE_SMC_SATELLITE_PAGE = 'hideSmcSatellitePage',

  /**
   * sysStatusAngle
   */
  OPERATION_TYPE_SYS_STATUS_ANGLE = 'sysStatusAngle',
}

/**
 * Satellite event
 */
export enum SatelliteEvent {
  /**
   * finishCalibrate
   */
  EVENT_FINISH_CALIBRATE = 'finishCalibrate',

  /**
   * clickCancelSatellite
   */
  EVENT_CLICK_CANCEL_SATELLITE = 'clickCancelSatellite',

  /**
   * sendingCompleted
   */
  EVENT_SENDING_COMPLETED = 'sendingCompleted',

  /**
   * sendingTimedOut
   */
  EVENT_SENDING_TIME_OUT = 'sendingTimeOut',

  /**
   * receivingCompleted
   */
  EVENT_RECEIVING_COMPLETED = 'receivingCompleted',

  /**
   * closeSatelliteDialog
   */
  EVENT_CLOSE_SATELLITE_DIALOG = 'closeSatelliteDialog',

  /**
   * abnormalInterruption
   */
  EVENT_ABNORMAL_INTERRUPTION = 'abnormalInterruption'
}

/**
 * Satellite state
 */
export enum SatelliteState {
  /**
   * calibrating
   */
  STATE_CALIBRATING = 'calibrating',

  /**
   * loading
   */
  STATE_LOADING = 'loading',

  /**
   * searching
   */
  STATE_SEARCHING = 'searching',

  /**
   * connection
   */
  STATE_CONNECTION = 'connection',

  /**
   * change
   */
  STATE_CHANGE = 'change',

  /**
   * sending
   */
  STATE_SENDING = 'sending',

  /**
   * receiving
   */
  STATE_RECEIVING = 'receiving'
}


/**
 * Satellite level
 */
export enum CarrierType {
  /**
   * China Telecom 中国电信
   */
  CARRIER_CT = '0',

  /**
   * China Unicom  中国联通
   */
  CARRIER_UNICOM = '1',

  /**
   * Other carrier  其他运营商
   */
  CARRIER_OTHER = '2',

  /**
   * CHINA_MOBILE  中国移动
   */
  CARRIER_CMCC = '3',
}

//不显示卫星图标 1
export const SATE_SHOW: number = 1;

export enum SatelliteType {
  /**
   * 北斗
   */
  BEI_DOU = 0,

  /**
   * 天通
   */
  TIAN_TONG = 1,


  /**
   * 风信子
   */
  HYACINTH = 2
}

export enum BatteryCapacityLevel {
  /**
   * 表示电池电量等级为满电量
   */
  LEVEL_FULL = 1,

  /**
   * 表示电池电量等级为高电量
   */
  LEVEL_HIGH = 2,

  /**
   * 表示电池电量等级为正常电量
   */
  LEVEL_NORMAL = 3,

  /**
   * 表示电池电量等级为低电量
   */
  LEVEL_LOW = 4,

  /**
   * 表示电池电量等级为告警电量
   */
  LEVEL_WARNING = 5,

  /**
   * 表示电池电量等级为极低电量
   */
  LEVEL_CRITICAL = 6,

  /**
   * 表示电池电量等级为关机电量
   */
  LEVEL_SHUTDOWN = 7
}

/**
 * Satellite from type
 */
export enum SatelliteFromType {
  SATELLITE_FROM_TYPE_MEETIME = 'meetime',
  SATELLITE_FROM_TYPE_MMS = 'mms'
}
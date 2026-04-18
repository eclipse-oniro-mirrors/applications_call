/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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

export interface ConsumerBehaviorParams {
  PNAMEID?: string,
  PVERSIONID?: string,
  BUNDLENAME?: string,
  STATE?: number,
}

export interface ConsumerStatisticParams {
  PNAMEID?: string,
  PVERSIONID?: string,
  BUNDLENAMES?: string,
  STATES?: string,
}

export let toggleParams: ConsumerBehaviorParams = {
  BUNDLENAME: '',
  STATE: 0,
}

export enum ToggleState {
  OPEN = 1,
  CLOSE = 2,
}

export enum DialogOperationState {
  CANCEL = 0,
  OK = 1,
}

export enum NewToggleState {
  OFF = 0,
  OK = 1,
}

export enum PolicyDialogUsersOperation {
  DENY = 0,
  WLAN_ONLY = 1,
  MOBILE_DATA_AND_WLAN = 2,
}

export enum DisableMobileUsersOperation {
  OK = 0,
  RESTART = 1,
  SWITCH_TO_ANOTHER_CARD = 2,
}

class EventName {
  public readonly TOGGLE_MOBILEDATA = 'TOGGLE_MOBILEDATA';
  public readonly TOGGLE_WLAN = 'TOGGLE_WLAN';
  public readonly MOBILE_TOGGLE_STATE = 'MOBILE_TOGGLE_STATE';
  public readonly WLAN_TOGGLE_STATE = 'WLAN_TOGGLE_STATE';

  public readonly CLICK_DAILY_USED_TRAFFIC_REMIND = 'CLICK_DAILY_USED_TRAFFIC_REMIND';
  public readonly CLICK_MONTHLY_TRAFFIC_REMIND = 'CLICK_MONTHLY_TRAFFIC_REMIND';
  public readonly WHEN_TRAFFIC_EXCEEDS_DIALOG = 'WHEN_TRAFFIC_EXCEEDS_DIALOG';
  public readonly CLICK_MONTHLY_TRAFFIC_EXCEED = 'CLICK_MONTHLY_TRAFFIC_EXCEED';
  public readonly START_DATE_DIALOG = 'START_DATE_DIALOG';
  public readonly CLICK_START_DATA_OF_MONTH = 'CLICK_START_DATA_OF_MONTH';
  public readonly PACKAGE_QUOTA_DIALOG = 'PACKAGE_QUOTA_DIALOG';
  public readonly CLICK_PACKAGE_QUOTA = 'CLICK_PACKAGE_QUOTA';
  public readonly CLICK_UNLIMITED_TRAFFIC_TOGGLE = 'CLICK_UNLIMITED_TRAFFIC_TOGGLE';
  public readonly CLICK_QUOTA_NOTIFICATION = 'CLICK_QUOTA_NOTIFICATION';
  public readonly CLICK_PACKAGE_SETTINGS = 'CLICK_PACKAGE_SETTINGS';
  public readonly CLICK_MORE_TRAFFIC_SETTINGS = 'CLICK_MORE_TRAFFIC_SETTINGS';
  public readonly DISABLE_MOBILE_DATA_DIALOG = 'DISABLE_MOBILE_DATA_DIALOG';
  public readonly ALLOW_WIRELESS_DATA_DIALOG = 'ALLOW_WIRELESS_DATA_DIALOG';
  public readonly PACKAGE_SETTINGS_PAGE_STATUS = 'PACKAGE_SETTINGS_PAGE_STATUS';
  public readonly QUOTA_NOTIFICATION_PAGE_STATUS = 'QUOTA_NOTIFICATION_PAGE_STATUS';
  public readonly SYS_SERVICE_WLAN_FLOW_RANK = 'SYS_SERVICE_WLAN_FLOW_RANK';
  public readonly SYS_SERVICE_MOBILEDATA_FLOW_RANK = 'SYS_SERVICE_MOBILEDATA_FLOW_RANK';
  public readonly DATA_USAGE_WLAN_FLOW_RANK = 'DATA_USAGE_WLAN_FLOW_RANK';
  public readonly DATA_USAGE_MOBILEDATA_FLOW_RANK = 'DATA_USAGE_MOBILEDATA_FLOW_RANK';
  public readonly DATA_USAGE_BARCHART = 'DATA_USAGE_BARCHART';
  public readonly GET_SIMLABEL_AND_INDEX = 'GET_SIMLABEL_AND_INDEX';
  public readonly CLICK_TRAFFIC_DISPLAY = 'CLICK_TRAFFIC_DISPLAY';
}

class AllBundleNames {
  public readonly TOGGLE_MOBILEDATA_ALL: string = 'TOGGLE_MOBILEDATA_ALL';
  public readonly TOGGLE_WLAN_ALL: string = 'TOGGLE_WLAN_ALL';
}

class CommonData {
  public eventName = new EventName();
  public allBundleNames = new AllBundleNames();
}

export default new CommonData();
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
import bundleManager from '@ohos.bundle.bundleManager';
import { LogUtil } from '../util/LogUtil';
import { i18n } from '@kit.LocalizationKit';

export const ATOMIC_SERVICE: number = 1;
export const DELAY: number = 5;
export const DROI_UID: number = 4294967295;
export const UNINSTALLED_APPS_UID: number = 4294967294;
export const ABROAD_TOTAL_UID: number = 4294967293;
export const ORI_APP_INDEX: number = 0;
export const UNKNOWN_BUNDLE_TYPE: number = -1;
export const DROI_BUNDLE_NAME: string = 'com.droi.tong';
export const DROI_OLD_BUNDLE_NAME: string = 'com.droi.iapps';
export const ABROAD_BUNDLE_NAME: string = 'com.easy.hmos.abroad';
export const ABROAD_OLD_BUNDLE_NAME: string = 'com.easy.abroadHarmony.temp';
export const INNER_DROI_BUNDLE_NAME: string = 'com.zhuoyi.appstore.lite';
export const INNER_ABROAD_BUNDLE_NAME: string = 'com.easy.abroad';
export const INNER_BROWSER_BUNDLE_NAME: string = 'com.zhuoyi.browser';
export const UNDERLINE: string = '_';
export const TAG_NAME: string = 'net_stats_';
export const DEFAULT_USERID: number = 100;
export const TRAFFIC_CONTROL_PAGE_VISIBLE_STATUS: string = 'visible_status';
export const DEFAULT_FOLD_CONFIGURATION = '0,0,0,0';
export const FOLD_PRODUCT_TYPE_KEY = 'const.window.foldscreen.type';
export const COMPATIBLE_APP_CODE_PATH = '1';
export const BAR_COUNT: number = 7;
export const DUARTION_DAY_30: number = 30;
export const DUARTION_HOUR_24: number = 24;
export const DAYS_29 = 29;
export const HOURS_23 = 23;
export const MILLISECOND_1000 = 1000;

/**
 * 隐私空间包名
 */
export const PRIVATE_SPACE_BUNDLE_NAME = 'com.ohos.privatespacemanager';

/**
 * 主空间UID
 */
export const MAIN_SPACE_UID = 4294967291;

/**
 * 隐私空间UID
 */
export const PRIVATE_SPACE_UID = 4294967290;

/**
 * 套餐通知刷新使用
 */
export const EMITTER_NOTICE_EVENT_ID = 10000;
/**
 * 应用进入前台通知
 */
export const EMITTER_ON_FORGROUND_EVENT_ID = 10001;

/**
 * 预请求套餐使用数据结果回调通知
 */
export const EMITTER_PRELOAD_CALLBACK_EVENT_ID = 10002;

/**
 * 预请求套餐使用数据结果回调通知
 */
export const EMITTER_PRELOAD_TOTAL_CALLBACK_EVENT_ID = 10003;

/**
 * 重置套餐通知刷新使用
 */
export const EMITTER_RESET_MONTH_LIMIT_NOTICE_EVENT_ID = 10004;

/**
 * 热点数据服务uid, value = unint32.max - 3
 */
export const ABROAD_HOTSPOT_UID: number = 4294967292;

/**
 * 手机设备搜索页搜索组件左边避让宽度: 返回键 24vp 边距 + 40vp + 8vp 搜索组件与返回键间距
 */
export const SEARCH_TITLE_START_MARGIN: number = 64;

/**
 * 平板设备搜索页搜索组件左边避让宽度：返回键 16vp 边距 + 40vp + 8vp 搜索组件与返回键间距
 */
export const SEARCH_TITLE_START_MARGIN_PAD: number = 72;

export interface SlotIdMapSimIdInterface {
  slotId: number,
  simId: number
}
/**
 * want参数中的startReason值的一种，表示从设置搜索进入的界面
 */
export const START_REASON_FROM_SEARCH = 'from_search';

/**
 * 次数：0
 */
export const TIMES_0 = 0;

/**
 * 次数：1
 */
export const TIMES_1 = 1;

/**
 * Maximum number of SIM cards.
 */
export const MAX_SIM_COUNT = 2;

/**
 * 应用安装来源是否为兼容应用
 */
export const EASY_ZHUOYI_INSTALL_SOURCE: string = '1';

export class WhiteListData {
  public bundleName?: string;
  public appIdentifier?: string;
};

export const whiteListMap = new Map<string, WhiteListData[]>([
  ['CommunicationSettingAbility', [
    {
      bundleName: 'com.ohos.settings',
      appIdentifier: '5765880207852919475'
    }]
  ],
]);

/**
 * 检查调用方want参数
 *
 * @param {string} abilityName - 调用方的 Ability 名
 * @returns {boolean} 表示拉起方包名是否在白名单之内
 */
export function checkCallerWantParams(tag: string, want: Want): boolean {
  let abilityName = want?.abilityName as string;
  let callerBundleName = want?.parameters?.['ohos.aafwk.param.callerBundleName'] as string;
  if (!abilityName || !callerBundleName) {
    LogUtil.error(tag, 'The caller bundle name is invalid, reject.');
    return false;
  }

  // 根据 abilityName 获取对应的白名单列表
  const whiteList: WhiteListData[] = whiteListMap.get(abilityName) as WhiteListData[];
  const bundleInfo =
    bundleManager.getBundleInfoSync(callerBundleName, bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_SIGNATURE_INFO);
  if (whiteList && whiteList.length && bundleInfo && bundleInfo.signatureInfo) {
    return whiteList.some(item => item.bundleName === callerBundleName &&
      item.appIdentifier === bundleInfo.signatureInfo.appIdentifier)
  } else {
    LogUtil.info(tag, 'The caller bundle is not in the whitelist, reject.');
    return false;
  }
}

export enum SearchMode {
  NOT_SEARCHING = 0,
  IN_SEARCHING = 1,
  SearchingResult = 2,
}
export enum NavEntryKey {
  TRAFFIC_PAGE = 'TRAFFIC_PAGE',
  CONNECTION_PAGE = 'CONNECTION_PAGE',
  RANK_PAGE = 'RANK_PAGE',
  SEARCH_PAGE = 'SEARCH_PAGE',
  SINGLE_APP_PAGE = 'SINGLE_APP_PAGE',
  SYS_SERVICE_PAGE = 'SYS_SERVICE_PAGE',
  MORE_SETTINGS_PAGE = 'MORE_SETTINGS_PAGE',
  DATA_PLAN_PAGE = 'DATA_PLAN_PAGE',
  USAGE_REMINDERS_PAGE = 'USAGE_REMINDERS_PAGE'
}

export class PushParam {
  public bundleName?: string;
  public pageName?: string;
  public uid?: number;
}
export function getFlowText(flow: number): string [] {
  let unit = ['B', 'KB', 'MB', 'GB', 'TB'];
  let i = 0;
  while (flow >= 1024 && i < 4) {
    flow = flow / 1024;
    i++;
  }
  return [flow.toFixed(2), unit[i]];
}

export function isRTL(): boolean {
  return i18n.isRTL(i18n.System.getSystemLocale());
}

export enum PageIndex {
  TRAFFIC_MANAGER = 0,
  NETWORK_ACCESS = 1,
  DATA_RANKINGS = 2,
  SYSTEM_AND_SERVICES = 3,
  MORE_SETTINGS = 4,
}

export enum NetworkType {
  DEFAULT = -1,
  MOBILE = 0,
  WLAN = 1,
}

export enum Keys {
  SEARCH_INFO = 'searchInfo',
  PAGE_INFOS = 'pageInfos'
}

export enum LoadingFinished {
  NONE = -1,
  HIDDEN = 0,
  FINISHED = 1
}

export enum SlotId {
  DEFAULT = -1,
  /**
   * 卡槽1
   */
  SLOT_1 = 0,
  /**
   * 卡槽2
   */
  SLOT_2 = 1
}

export enum Uri {
  SETTINGS_DATA_URI = 'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true&key='
}

export enum ResultCode {
  SUCCESS = 0,
  FAILURE = -1
}

export enum RunInWorkerMethod {
  insertSettingsInfoByCondition = 'insertSettingsInfoByCondition',
  deleteSettingsInfoByCondition = 'deleteSettingsInfoByCondition',
  updateSettingsInfoByCondition = 'updateSettingsInfoByCondition',
  querySettingsInfoByCondition = 'querySettingsInfoByCondition',
  querySettingsInfoByBeginningCondition = 'querySettingsInfoByBeginningCondition',
  querySettingsInfoByEndCondition = 'querySettingsInfoByEndCondition',
}

export enum QueryName {
  unlimited_traffic_enable = 'unlimited_traffic_enable',
  monthly_limited_traffic = 'monthly_limited_traffic',
  monthly_start_date = 'monthly_start_date',
  monthly_notify_type = 'monthly_notify_type',
  over_monthly_mark = 'over_monthly_mark',
  over_daily_mark = 'over_daily_mark',
  show_traffic = 'traffic_switch'
}

export enum UnlimitedEnable {
  UNLIMITED_OFF = '0',
  UNLIMITED_OPEN = '1'
}

export enum ActionWhenTrafficOut {
  REMINDER = 0,
  DISABLE = 1
}

export enum ShowReminder {
  REMINDER1 = 'reminder1',
  REMINDER2 = 'reminder2'
}

export enum DataUnit {
  MB = 'MB',
  GB = 'GB',
}

export const ONE_TB = 1024 * 1024 * 1024 * 1024;
export const ONE_GB = 1024 * 1024 * 1024;
export const ONE_MB = 1024 * 1024;
export const ONE_KB = 1024;

export function fetchFullKeyWord(simId: number, key: string): string {
  let fullKeyWord = TAG_NAME + simId + UNDERLINE + key;
  return fullKeyWord;
}
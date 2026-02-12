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

import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import { LogUtil } from '../util/LogUtil';
import { FontScaleState } from '../util/fontScaleState';
import { Configuration } from '@ohos.app.ability.Configuration';
import Window from '@ohos.window';
import {
  checkCallerWantParams,
  EMITTER_ON_FORGROUND_EVENT_ID,
  Keys,
  NavEntryKey,
  TIMES_0,
  TIMES_1
} from '../constants/CommonConstants';
import { SearchInfo } from '../data/SearchData';
import { DisplayUtils } from '../util/DisplayUtils';
import WorkFactory, { WorkerType } from '../workers/WorkFactory';
import WorkerWrapper from '../workers/WorkerWrapper';
import DataShareHelper from '../model/DataShareHelper';
import { getActivatedAccountLocalId } from '../util/DeviceUtil';
import { emitter } from '@kit.BasicServicesKit';
import { TrafficDataStroageUtil, TrafficPackagePreloadUtil } from '../util/TrafficPackagePreloadUtil';
import { SimManager } from '../util/SimManager';
import { AccessibilityUtils } from '../util/AccessibilityUtils';
import { TrafficDataCacheUtil } from '../util/TrafficPackageUtil';

const TAG: string = 'CommunicationSettingAbility';

export default class CommunicationSettingAbility extends UIExtensionAbility {
  private static createdTimes = 0;

  onCreate() {
    LogUtil.log(TAG, `onCreate`);
    GlobalContext.getContext().setObject('rankPageContext', this.context);
    GlobalContext.getContext().setObject('DataWorker', WorkFactory.getWorker(WorkerType.DataWorker));
    DataShareHelper.getInstance().initSettingDB(this.context);
    AccessibilityUtils.addAccessibilityStateChangeListener();
  }

  onForeground() {
    LogUtil.log(TAG, `onForeground`);
    let event: emitter.InnerEvent = {
      eventId: EMITTER_ON_FORGROUND_EVENT_ID,
      priority: emitter.EventPriority.HIGH
    };
    emitter.emit(event);
    AccessibilityUtils.getAccessibilitySwitchState();
  }

  onBackground() {
    LogUtil.log(TAG, `onBackground`);
  }

  onDestroy() {
    LogUtil.log(TAG, `onDestroy`);
    (GlobalContext.getContext().getObject('DataWorker') as WorkerWrapper)?.close();
    GlobalContext.getContext().setObject('DataWorker', null);
    SimManager.getInstance().destroy();
    TrafficDataCacheUtil.getInstance().clearAllCachedData();
    AccessibilityUtils.releaseAccessibility();
  }

  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    LogUtil.log(TAG, `onSessionCreate`);
    TrafficDataStroageUtil.getInstance().isNeedPreload = true;
    if (!checkCallerWantParams(TAG, want)) {
      LogUtil.error(TAG, 'Only the settings mainAbility can invoke this interface.');
      return;
    }
    SimManager.getInstance().init();
    TrafficPackagePreloadUtil.preQueryTrafficUseDetail(this.context);
    this.fetchSystemFontSizeScale();
    this.setColorModeProps(this.context.config);
    let storage: LocalStorage = new LocalStorage();
    storage.setOrCreate('session', session);
    this.setSafeAreaInfo(session);
    this.handleSearchInfo(want, storage);
    this.handleWantParams(want, storage);
    this.registerFoldStatusChanged();
    this.getUserId();
    session.loadContent('pages/TrafficControlPage', storage);
    CommunicationSettingAbility.createdTimes++;
  }

  private getUserId() {
    getActivatedAccountLocalId().then((res) => {
      AppStorage.setOrCreate<number>('userID', res);
    }).catch((err: Error) => {
      LogUtil.error(TAG, `getActivatedAccountLocalId error, err->${JSON.stringify(err)}`);
    })
  }

  onSessionDestroy(session: UIExtensionContentSession) {
    try {
      let extensionWindow = session.getUIExtensionHostWindowProxy();
      if (extensionWindow) {
        extensionWindow.off('avoidAreaChange');
      }
    } catch (err) {
      LogUtil.error(TAG, `off avoidAreaChange err -> ${JSON.stringify(err)}`);
    }
    LogUtil.log(TAG, `onSessionDestroy`);
    this.unregisterFoldStatusChanged();
    CommunicationSettingAbility.createdTimes--;
  }

  private areaChangeCallBack = (): void => {
    let storage = LocalStorage.getShared();
    let session: UIExtensionContentSession | undefined = storage.get('session');
    if (session) {
      try {
        let extensionWindow = session.getUIExtensionHostWindowProxy();
        // 状态栏高度
        let statusBarHeight = extensionWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height;
        AppStorage.setOrCreate<number>('statusBarHeight', px2vp(statusBarHeight));
        LogUtil.info(TAG, 'areaChangeCallBack statusBarHeight: ' + px2vp(statusBarHeight));
      } catch (err) {
        LogUtil.error(TAG, 'areaChangeCallBack errCode: ' + err?.code + ' ,msg: ' + err?.message);
      }
    }
  }

  setSafeAreaInfo(session: UIExtensionContentSession): void {
    LogUtil.info(TAG, `setSafeAreaInfo`);
    let extensionWindow = session.getUIExtensionHostWindowProxy();
    // 状态栏高度
    let statusBarHeight = extensionWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height;

    // 导航条高度
    let naviIndicatorHeight = extensionWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)
      .bottomRect.height;
    AppStorage.setOrCreate<number>('statusBarHeight', px2vp(statusBarHeight));
    AppStorage.setOrCreate<number>('naviIndicatorHeight', px2vp(naviIndicatorHeight));
    LogUtil.info(TAG, 'statusBarHeight: ' + px2vp(statusBarHeight));
    try {
      extensionWindow.on('avoidAreaChange', this.areaChangeCallBack);
    } catch (err) {
      LogUtil.error(TAG, 'on avoidAreaChange errCode: ' + err?.code + ' ,msg: ' + err?.message);
    }
  }

  handleSearchInfo(want: Want, storage: LocalStorage) {
    try {
      //str格式"0,1,-1",-1表示默认
      //第一位：页码 - 0：流量管理；1：应用联网；2：流量排行；3：系统与服务；4：更多流量设置
      //第二位：卡槽 - 0：卡1；1：卡2
      //第三位：网络类型 - 0：移动数据；1：wlan
      const str = want?.parameters?.['pushParams'] as string
      if (!str) {
        LogUtil.error(TAG, 'pushParams is invalid');
        return;
      }
      const params = str.split(',');
      if (!params || params.length < 3) {
        LogUtil.error(TAG, 'search params is invalid');
        return;
      }
      const searchInfo = new SearchInfo(Number.parseInt(params[0]),
        Number.parseInt(params[1]), Number.parseInt(params[2]));
      if (!searchInfo.isTrafficManager()) {
        storage.setOrCreate<SearchInfo>(Keys.SEARCH_INFO, searchInfo);
        let pageInfos: NavPathStack = new NavPathStack();
        let info: NavPathInfo = new NavPathInfo('', undefined, undefined, true);
        if (searchInfo.isNetworkAccess()) {
          info.name = NavEntryKey.CONNECTION_PAGE;
        } else if (searchInfo.isDataRankings()) {
          info.name = NavEntryKey.RANK_PAGE;
        } else if (searchInfo.isSystemAndServices()) {
          info.name = NavEntryKey.SYS_SERVICE_PAGE;
          info.param = [0, 1];
        } else if (searchInfo.isMoreSettings()) {
          info.name = NavEntryKey.MORE_SETTINGS_PAGE;
        }
        pageInfos.pushPath(info, false);
        storage.setOrCreate<NavPathStack>(Keys.PAGE_INFOS, pageInfos);
      }
    } catch (err) {
      LogUtil.error(TAG, `handleSearchInfo err: ${JSON.stringify(err)}`);
    }
  }

  onConfigurationUpdate(newConfig: Configuration) {
    FontScaleState.updateAppFontGearSize(newConfig.fontSizeScale);
    this.setColorModeProps(newConfig);
  }

  /**
   * 打开页面
   * @param windowStage
   */
  onWindowStageCreate(windowStage: Window.WindowStage) {
    windowStage.setDefaultDensityEnabled(true);
  }

  fetchSystemFontSizeScale(): void {
    let fontSizeScale = this.context.config?.fontSizeScale;
    FontScaleState.updateAppFontGearSize(fontSizeScale);
  }

  private handleWantParams(want: Want, localStorage: LocalStorage) {
    let startReason = want?.parameters?.['startReason'] as string;
    localStorage.setOrCreate<string>('startReason', startReason);
  }

  registerFoldStatusChanged() {
    if (CommunicationSettingAbility.createdTimes === TIMES_0) {
      DisplayUtils.registerFoldStatusChanged();
    }
  }

 unregisterFoldStatusChanged() {
    if (CommunicationSettingAbility.createdTimes === TIMES_1) {
      DisplayUtils.unregisterFoldStatusChanged();
    }
  }

  setColorModeProps(config?: Configuration) {
    let newColorMode = config?.colorMode !== undefined ? config?.colorMode : AppStorage.get<number>('currentColorMode');
    let currentColorMode = AppStorage.get<number>('currentColorMode');
    if (newColorMode === currentColorMode) {
      LogUtil.info(TAG, 'ColorMode has not changed.');
      return;
    }
    AppStorage.setOrCreate('currentColorMode', newColorMode);
  }
};

export class GlobalContext {
  private constructor() {
  }

  private static instance: GlobalContext;
  private _objects = new Map<string, Object>();

  public static getContext(): GlobalContext {
    if (!GlobalContext.instance) {
      GlobalContext.instance = new GlobalContext();
    }
    return GlobalContext.instance;
  }

  getObject(value: string): Object | window.WindowStage {
    return this._objects.get(value) as Object;
  }

  setObject(key: string, objectClass: Object | null | window.WindowStage): void {
    if (objectClass === null || objectClass === undefined) {
      this._objects.delete(key);
    } else {
      this._objects.set(key, objectClass as Object);
    }
  }
};
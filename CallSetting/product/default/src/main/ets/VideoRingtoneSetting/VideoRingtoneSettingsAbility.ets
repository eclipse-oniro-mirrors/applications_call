/**
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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
import Want from '@ohos.app.ability.Want';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import { uiExtensionHost, window } from '@kit.ArkUI';
import CallColumnUtils from '../common/utils/CallColumnUtils';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';
import { StringUtil } from '../common/utils/StringUtil';
import { LogUtils, Constants } from '@ohos/common/CommonIndex';
import { pathParams } from '../pages/videoRingtone/VideoRingtonePage';
import SplitScreenManager from '../model/SplitScreenManager';
import { display } from '@kit.ArkUI';

const TAG = 'VideoRingtoneSettingsAbility';

export interface extensionProperties {
  session?: UIExtensionContentSession;
  simCard: string;
  videoRingtoneSource: number;
  contactsPath: string;
  pathParams?: pathParams;
  isFullScreen: boolean;
}

export interface RingtoneParam {
  'card': string;
  'pageType': string;
  'ringtonePath'?: string;
  'selectRingtoneContentId'?: string;
  'selectedLibraryRingtonePath'?: string;
  'selectedRingtoneName'?: string;
  'selectedRingtonePath': string;
  'showTitle'?: boolean;
  'toneType'?: string;
  'uiStyle'?: string;
}

const SESSION_CREATE_TASK_ID = 1001;

export default class VideoRingtoneSettingsAbility extends UIExtensionAbility {
  public storage?: LocalStorage;
  private mCallColumnUtils: CallColumnUtils = CallColumnUtils.getInstance();
  private extensionWindow: uiExtensionHost.UIExtensionHostWindowProxy | null = null;

  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    let localStorage: LocalStorage | undefined = this.handleWant(want, session);
    LogUtils.i(TAG, 'onSessionCreate localStorage : ' + JSON.stringify(localStorage));
    let videoRingtoneSource: number = localStorage?.get<number>('videoRingtoneSource') as number;
    LogUtils.i(TAG, 'onSessionCreate videoRingtoneSource : ' + videoRingtoneSource);
    if (videoRingtoneSource == Constants.VIDEO_RINGTONE_SOURCE_CONTACT) {
      session.loadContent('pages/videoRingtone/VideoRingtonePage', localStorage);
    } else {
      session.loadContent('pages/videoRingtone/VideoRingtoneSettings', localStorage);
    }
    let extensionWindow = session?.getUIExtensionHostWindowProxy();
    this.extensionWindow = extensionWindow;
    this.addAvoidAreaChangeLister();
    this.setSystemBar();
    try {
      this.mCallColumnUtils.updateBreakpoint(-1);
      SplitScreenManager.getInstance()
        .updateScreenSize(display.getDefaultDisplaySync().width, display.getDefaultDisplaySync().height);
      extensionWindow.on('windowSizeChange', (windowSize) => {
        try {
          SplitScreenManager.getInstance()
            .updateScreenSize(display.getDefaultDisplaySync().width, display.getDefaultDisplaySync().height);
          this.mCallColumnUtils.updateBreakpoint(-1);
        } catch (err) {
          LogUtils.e(TAG, `onWindowStageCreate err = ${JSON.stringify(err)}`);
        }
      });
      hiTraceMeter.finishTrace('onSessionCreate', SESSION_CREATE_TASK_ID);
    } catch (err) {
      LogUtils.e(TAG, `onSessionCreate err = ${JSON.stringify(err)}`);
    }
  }

  private handleWant(want: Want, session: UIExtensionContentSession) {
    let ringtoneParam: RingtoneParam = want?.parameters?.['ringtoneParam'] as RingtoneParam;
    if (ringtoneParam == null) {
      LogUtils.e(TAG, 'handleWant ringtoneParam is null');
      return undefined;
    }
    let simCard: string = ringtoneParam.card;
    let pageType: string = ringtoneParam.pageType;
    let videoRingtoneSource: number = Constants.VIDEO_RINGTONE_SOURCE_SETTING;
    if (!StringUtil.isEmpty(pageType) && pageType == 'videoRingtone') {
      videoRingtoneSource = Constants.VIDEO_RINGTONE_SOURCE_SETTING;
    } else {
      videoRingtoneSource = Constants.VIDEO_RINGTONE_SOURCE_CONTACT;
    }
    let contactsPath: string = ringtoneParam.selectedRingtonePath;
    LogUtils.i(TAG,
      'handleWant pageType:' + pageType + ' simCard:' + simCard + ' videoRingtoneSource:' + videoRingtoneSource);
    let localStorage: LocalStorage = new LocalStorage({
      session: session,
      simCard: simCard,
      videoRingtoneSource: videoRingtoneSource,
      contactsPath: contactsPath,
      isFullScreen: false
    } as extensionProperties);
    this.setWantParams(want);
    return localStorage;
  }

  async setSystemBar() {
    let windowClass: window.Window = await window.getLastWindow(getContext(this))
    windowClass.setWindowLayoutFullScreen(true);
  }

  private setWantParams(want: Want) {
    let startReason: string = (want?.parameters?.['startReason'] ?? '') as string;
    AppStorage.setOrCreate('startReason', startReason);

    let navigationMode = (want?.parameters?.['navigationMode'] ?? 0) as number;
    AppStorage.setOrCreate('navigationMode', navigationMode);
  }

  onForeground(): void {
    LogUtils.i(TAG, 'onForeground');
  }

  onSessionDestroy() {
    LogUtils.i(TAG, 'onSessionDestroy');
    AppStorage.delete('foldStatus');
    this.removeAvoidAreaChangeLister();
    AppStorage.delete('statusBarHeight');
  }

  private addAvoidAreaChangeLister() {
    try {
      if (this.extensionWindow !== null) {
        let area = this.extensionWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        let navigationArea = this.extensionWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
        this.setWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM, area);
        this.setNavigationWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR, navigationArea);
        this.extensionWindow?.on('avoidAreaChange', (data: window.AvoidAreaOptions) => {
          LogUtils.i(TAG, `avoidAreaChange type: ${data.type}`);
          this.setWindowAvoidArea(data.type, data.area);
          this.setNavigationWindowAvoidArea(data.type, data.area);
        });
      }
    } catch (err) {
      LogUtils.e(TAG, `add avoidAreaChange callback failed, err: ${JSON.stringify(err)}`);
    }
  }

  private setWindowAvoidArea(type: window.AvoidAreaType, area: window.AvoidArea) {
    if (type === window.AvoidAreaType.TYPE_SYSTEM) {
      let statusBarHeight = area.topRect.height;
      LogUtils.i(TAG, `avoidAreaChange statusBarHeight: ${px2vp(statusBarHeight)}`);
      AppStorage.setOrCreate<number>('statusBarHeight', px2vp(statusBarHeight));
    }
  }

  private setNavigationWindowAvoidArea(type: window.AvoidAreaType, area: window.AvoidArea) {
    if (type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
      let statusBottomHeight = area.bottomRect.height;
      LogUtils.i(TAG, `setNavigationWindowAvoidArea statusBottomHeight: ${px2vp(statusBottomHeight)}`);
      AppStorage.setOrCreate<number>('statusBottomHeight', px2vp(statusBottomHeight));
    }
  }

  private removeAvoidAreaChangeLister() {
    try {
      if (this.extensionWindow !== null) {
        this.extensionWindow?.off('avoidAreaChange');
      }
    } catch (err) {
      LogUtils.e(TAG, `remove avoidAreaChange callback failed, err: ${JSON.stringify(err)}`);
    }
  }
}
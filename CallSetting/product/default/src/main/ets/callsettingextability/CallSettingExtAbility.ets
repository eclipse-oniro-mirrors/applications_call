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

import { LogUtils, ReportUtil, CallSettingGlobalContextHelper } from '@ohos/common/CommonIndex';
import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import Want from '@ohos.app.ability.Want';
import common from '@ohos.app.ability.common';
import * as CallSettingsConstant from '../common/constant/CallSettingsConstant';
import CallSettingVM from '../viewModel/CallSettingVM';
import { Configuration, UIExtensionContentSession } from '@kit.AbilityKit';
import { FontScaleState } from '../common/utils/FontScaleState';
import { BusinessError, emitter } from '@kit.BasicServicesKit';
import { display, uiExtensionHost, window } from '@kit.ArkUI';
import CallColumnUtils from '../common/utils/CallColumnUtils';
import { ReportWorkSchedulerUtil } from '../WorkSchedulerExtension/ReportWorkSchedulerUtil';
import { DisplayUtil } from '../common/utils/DisplayUtil';
import { pafInitForUIExtension } from '../common/utils/PafEngineUtils';

const TAG = 'CallSettingUIExtAbility';

export default class CallSettingUIExtAbility extends UIExtensionAbility {
  public storage?: LocalStorage;
  private mCallColumnUtils: CallColumnUtils = CallColumnUtils.getInstance();
  private hostWindowProxy: uiExtensionHost.UIExtensionHostWindowProxy | undefined = undefined;

  onSessionCreate(want: Want, session: UIExtensionContentSession): void {
    LogUtils.i(TAG, 'CallSettingUIExtAbility onSessionCreate, ' + JSON.stringify(want?.parameters));
    session.setReceiveDataCallback((data: Record<string, Object>) => {
      LogUtils.i(TAG, 'CallSettingUIExtAbility setReceiveDataCallback enter');
      if (data?.pickerData) {
        if (data?.isContactMultiSelect && AppStorage.get('callRecorderProxy')) {
          const callRecorderProxy: UIExtensionProxy = AppStorage.get('callRecorderProxy') as UIExtensionProxy;
          callRecorderProxy?.send({ 'pickerData': data?.pickerData })
        } else if (!data?.isContactMultiSelect) {
          emitter.emit({ eventId: CallSettingsConstant.EMIT_SINGLE_PICKER_EVENT_ID },
            { data: { 'pickerData': data?.pickerData } });
        }
      }
      if (data?.windowStatus) {
        const windowStatus: window.WindowStatusType = data?.windowStatus as window.WindowStatusType;
        LogUtils.i(TAG, `onWindowStatusChange windowStatus: ${windowStatus}`);
        AppStorage.setOrCreate<window.WindowStatusType>('windowStatus', windowStatus);
      }
    })
    try {
      let displayWidth = display.getDefaultDisplaySync().width;
      this.mCallColumnUtils.updateBreakpoint(displayWidth);
    } catch (err) {
      LogUtils.e(TAG, `updateBreakpoint fail, code: ${err?.code}, message: ${err?.message}`);
    }
    // 使用模态窗口拉起
    CallSettingVM.getInstance().setIsFromExternal(true);
    pafInitForUIExtension(session, this.context);
    AppStorage.setOrCreate('currentColorMode', this.context.config?.colorMode);
    AppStorage.setOrCreate('currentLanguage', this.context.config?.language);
    AppStorage.setOrCreate('scrollToCardOne', want.parameters?.['scrollToCardOne']);
    AppStorage.setOrCreate<window.WindowStatusType>('windowStatus',
      want.parameters?.['windowStatus'] as window.WindowStatusType);
    CallSettingGlobalContextHelper.getContext()
      .set<common.UIExtensionContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT, this.context);
    AppStorage.setOrCreate<UIExtensionContentSession>('extensionSession', session);
    let proxy: uiExtensionHost.UIExtensionHostWindowProxy = session.getUIExtensionHostWindowProxy();
    if (proxy) {
      proxy.on('windowSizeChange', (size: window.Size) => {
        LogUtils.i(TAG, 'proxy windowSizeChange, size: ' + JSON.stringify(size));
        this.mCallColumnUtils.updateBreakpoint(size.width);
      })
      this.hostWindowProxy = proxy;
      this.addFoldStatusListener();
      this.addAvoidAreaChangeLister();
      this.addFoldDisplayModeChangeListener();
    }
    this.storage = new LocalStorage();
    CallSettingVM.getInstance().initData();
    ReportUtil.getInstance();
    this.adaptiveAging();
    session.loadContent('pages/EntryPage', this.storage)
    ReportWorkSchedulerUtil.tryStartButtonStateReportWorkScheduler();
    try {
      const extensionHostWindow = session.getUIExtensionWindowProxy();
      // 添加安全水印标志
      extensionHostWindow.setWaterMarkFlag(true);
    } catch (err) {
      LogUtils.e(TAG, `onSessionCreate Failed to setting water mark flag. Cause: ${err?.code}, ${err?.message}`);
    }
  }

  onSessionDestroy(session: UIExtensionContentSession) {
    try {
      const extensionHostWindow = session.getUIExtensionWindowProxy();
      // 删除安全水印标志
      extensionHostWindow.setWaterMarkFlag(false);
    } catch (err) {
      LogUtils.e(TAG, `onSessionDestroy Failed to setting water mark flag. Cause: ${err?.code}, ${err?.message}`);
    }
  }

  onDestroy(): void {
    AppStorage.delete('callSettingsUri');
    LogUtils.i(TAG, 'Ability onDestroy');
    CallSettingVM.getInstance().unregister();
    this.removeAvoidAreaChangeLister();
    this.removeFoldStatusListener();
    this.removeFoldDisplayModeChangeListener();
  }

  onForeground(): void {
    // Ability has brought to foreground
    LogUtils.i(TAG, 'Ability onForeground');
    // 发送前台事件
    emitter.emit({ eventId: CallSettingsConstant.EMIT_GET_RINGTONE_EVENT_ID });
  }

  onBackground(): void {
    // Ability has back to background
    LogUtils.i(TAG, 'Ability onBackground');
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    LogUtils.i(TAG, 'Ability onConfigurationUpdate, config: ' + JSON.stringify(newConfig));
    AppStorage.setOrCreate('currentColorMode', newConfig?.colorMode);
    let language: string | undefined = AppStorage.get('currentLanguage');
    if (language != undefined && language !== newConfig?.language) {
      emitter.emit({ eventId: CallSettingsConstant.EMIT_LANGUAGE_CHANGE_EVENT_ID });
    }
    AppStorage.setOrCreate('currentLanguage', newConfig?.language);
    let fontSizeScale = newConfig?.fontSizeScale ?? 1;
    LogUtils.i(TAG, 'onConfigurationUpdate' + fontSizeScale);
    FontScaleState.updateAppFontGearSize(fontSizeScale);
  }

  private adaptiveAging() {
    LogUtils.i(JSON.stringify(this.context.config?.fontSizeScale), 'Ability onWindowStageCreate  fontSizeScale2');
    let fontSizeScale = this.context.config?.fontSizeScale ?? 1;
    FontScaleState.updateAppFontGearSize(fontSizeScale);
  }

  private addAvoidAreaChangeLister(): void {
    let avoidArea = this.hostWindowProxy?.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
    let areaHeight = avoidArea?.bottomRect.height ?? 0;
    AppStorage.setOrCreate('navigationHeight', px2vp(areaHeight));
    try {
      this.hostWindowProxy?.on('avoidAreaChange', (data: window.AvoidAreaOptions) => {
        LogUtils.i(TAG, `avoidAreaChange type: ${data.type}`);
        if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
          let height = data.area.bottomRect.height;
          AppStorage.setOrCreate('navigationHeight', px2vp(height));
        }
      });
    } catch (err) {
      LogUtils.e(TAG, `add avoidAreaChange callback failed, err: ${JSON.stringify(err)}`);
    }
  }

  addFoldStatusListener(): void {
    if (DisplayUtil.isFoldable()) {
      // try {
      //   display.on('foldStatusChange', (foldStatus: display.FoldStatus) => {
      //     LogUtils.i(TAG, 'foldStatusChange foldStatus=' + foldStatus);
      //     AppStorage.setOrCreate('foldStatus', foldStatus);
      //   })
      // } catch (exception) {
      //   LogUtils.e(TAG, 'foldStatusChange exp=' + JSON.stringify(exception));
      // }
    }
  }

  removeFoldStatusListener(): void {
    if (DisplayUtil.isFoldable()) {
      try {
        // display.off('foldStatusChange');
      } catch (exception) {
        LogUtils.e(TAG, 'Failed to unregister callback. Code: ' + JSON.stringify(exception));
      }
    }
  }

  private removeAvoidAreaChangeLister() {
    try {
      if (this.hostWindowProxy) {
        this.hostWindowProxy?.off('avoidAreaChange');
      }
    } catch (err) {
      LogUtils.e(TAG, `off avoidAreaChange callback failed, err: ${JSON.stringify(err)}`);
    }
  }

  private addFoldDisplayModeChangeListener(): void {
    if (!DisplayUtil.isFoldable()) {
      return;
    }
    try {
      // AppStorage.setOrCreate<display.FoldDisplayMode>('foldDisplayMode', display.getFoldDisplayMode());
      // display.on('foldDisplayModeChange', this.onFoldDisplayModeChange);
    } catch (e) {
      const err = e as BusinessError;
      LogUtils.e(TAG, `addFoldDisplayModeChangeListener error: ${err?.code}, ${err?.message}`);
    }
  }

  private removeFoldDisplayModeChangeListener(): void {
    if (!DisplayUtil.isFoldable()) {
      return;
    }
    try {
      AppStorage.delete('foldDisplayMode');
      // display.off('foldDisplayModeChange', this.onFoldDisplayModeChange);
    } catch (e) {
      const err = e as BusinessError;
      LogUtils.e(TAG, `addFoldDisplayModeChangeListener error: ${err?.code}, ${err?.message}`);
    }
  }

  private onFoldDisplayModeChange = (foldDisplayMode: display.FoldDisplayMode) => {
    LogUtils.i(TAG, `foldDisplayModeChange FoldDisplayMode: ${foldDisplayMode}`);
    AppStorage.setOrCreate<display.FoldDisplayMode>('foldDisplayMode', foldDisplayMode);
  }
}

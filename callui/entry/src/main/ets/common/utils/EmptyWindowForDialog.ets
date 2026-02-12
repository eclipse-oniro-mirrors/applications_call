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

import LogUtils from './LogUtils';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { GlobalContextHelper } from './GlobalContextHelper';
import { common } from '@kit.AbilityKit';
import { CALL_ABILITY_CONTEXT, CALLUI_WINDOW_FOR_DIALOG, KEY_FOR_DIALOG_CALLID,
  KEY_FOR_DIALOG_CALLLISTCOUNT,
  KEY_FOR_DIALOG_ACCOUNTNUMBER,
  KEY_FOR_DIALOG_FORMATNUMBER} from './Constants';

const TAG = 'EmptyWindowForDialog';
const activeStorage: Record<string, number> = {};

export default class EmptyWindowForDialog {
  private static EmptyWindowForDialogInstance: EmptyWindowForDialog;
  private localStorage: LocalStorage = new LocalStorage(activeStorage);

  public static getInstance(): EmptyWindowForDialog {
    if (!EmptyWindowForDialog.EmptyWindowForDialogInstance) {
      EmptyWindowForDialog.EmptyWindowForDialogInstance = new EmptyWindowForDialog();
    }
    return EmptyWindowForDialog.EmptyWindowForDialogInstance;
  }

  public async loadPageForOpenDialog(config: window.Configuration, uri: string): Promise<void> {
    LogUtils.i(TAG, 'showDialog called');
    let dialogContainer: window.Window;
    try {
      dialogContainer = await window.createWindow(config);
      dialogContainer.loadContent(uri, this.localStorage, (err: BusinessError) => {
        if (err.code) {
          LogUtils.e(TAG, `Failed to load page: ${uri} code: ${err.code} msg: ${err.message}.`);
          return;
        }
        dialogContainer.setWindowBackgroundColor('#00ffffff');
        dialogContainer.showWindow((err: BusinessError) => {
          if (err.code) {
            LogUtils.e(TAG, `Failed to show window code: ${err.code} msg: ${err.message}.`);
            return;
          }
        })
      })
    } catch (err) {
      LogUtils.e(TAG, `loadContent and showWindow failed. msg: ${err?.message} code:${err?.code}`);
      return;
    }
  }


  public showThermalDialog(callId: number, callListCount: number, accountNumber: string, formatNumber: string) {
    this.localStorage.setOrCreate(KEY_FOR_DIALOG_CALLID, callId);
    this.localStorage.setOrCreate(KEY_FOR_DIALOG_CALLLISTCOUNT, callListCount);
    this.localStorage.setOrCreate(KEY_FOR_DIALOG_ACCOUNTNUMBER, accountNumber);
    this.localStorage.setOrCreate(KEY_FOR_DIALOG_FORMATNUMBER, formatNumber);
    let ctx = GlobalContextHelper.getContext().getValue(CALL_ABILITY_CONTEXT) as common.UIAbilityContext;

    let config: window.Configuration = {
      name: CALLUI_WINDOW_FOR_DIALOG,
      // dialog用TYPE_VOLUME_OVERLAY，toast用TYPE_SYSTEM_TOAST
      windowType: window.WindowType.TYPE_VOLUME_OVERLAY,
      ctx: ctx
    };
    this.loadPageForOpenDialog(config, 'pages/PageForDialog');
  }

  public async killDialogContainerWindow(): Promise<void> {
    try {
      const win = await window.findWindow(CALLUI_WINDOW_FOR_DIALOG);
      if (win) {
        LogUtils.i(TAG, 'kill DialogContainerWindow');
        win.destroyWindow();
      }
    } catch (err) {
      LogUtils.e(TAG, `Failed to destroyWindow. Cause: ${err?.message}`);
    }
  }
}
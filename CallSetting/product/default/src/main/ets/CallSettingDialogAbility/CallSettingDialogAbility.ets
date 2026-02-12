/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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

import { CustomMmiCodeResult, LogUtils, MmiCodeUtils } from '@ohos/common/CommonIndex';
import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import Want from '@ohos.app.ability.Want';
import { application, StartOptions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import SubscriberManagement from '../common/utils/SubscriberManagement';

const TAG = 'CallSettingDialogAbility';

export default class CallSettingDialogAbility extends UIExtensionAbility {
  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    LogUtils.i(TAG, 'onSessionCreate.');
    AppStorage.setOrCreate('session', session);
    AppStorage.setOrCreate('want', want);
    if (want?.parameters?.dialogReason.toString().startsWith('SUPER_PRIVACY_MODE')) {
      if (want?.parameters?.isFold as boolean) {
        this.startExternalAbility(want);
        return;
      }
      session.loadContent('pages/SuperPrivacyCallDialog');
    } else if (want?.parameters?.dialogReason?.toString().startsWith('PROCESS_MMI_CODE')) {
      const mmiFeatureDebug: boolean = want?.parameters?.mmiFeatureDebug as boolean
      if (mmiFeatureDebug) {
        const result: CustomMmiCodeResult = want?.parameters?.mmiCodeResult as CustomMmiCodeResult
        LogUtils.i(TAG, `load MmiCodeDialog mmiFeatureDebug = ${mmiFeatureDebug}`);
        MmiCodeUtils.mmiFeatureDebug = mmiFeatureDebug
        MmiCodeUtils.result = result
      }
      try {
        application.createModuleContext(this.context.getApplicationContext(), 'common').then((data: Context)=>{
          MmiCodeUtils.context = data
        }).catch((error : BusinessError)=>{
          LogUtils.e(TAG, `createModuleContext failed, error.code: ${(error as BusinessError).code}, error.message: ${(error as BusinessError).message}`);
        })
      } catch (error) {
        LogUtils.e(TAG, `createModuleContext failed, error.code: ${(error as BusinessError).code}, error.message: ${(error as BusinessError).message}`);
      }
      session.loadContent('pages/MmiCodeDialog');
    } else {
      session.loadContent('pages/SatelliteCallDialog');
    }
    session.setWindowBackgroundColor('#33000000');
    SubscriberManagement.registerSubscriber();
  }

  startExternalAbility(want: Want) {
    let exWant: Want = {
      bundleName: 'com.ohos.callsetting',
      abilityName: 'ExternalCallSettingDialogAbility',
      parameters: want.parameters
    };
    let options: StartOptions = {
      displayId: 5
    };
    this.context.startAbility(exWant, options).then(() => {
      this.context.terminateSelf();
      LogUtils.i(TAG, 'startExternalAbility done');
    }).catch((err: BusinessError) => {
      LogUtils.i(TAG, 'startExternalAbility err :' + JSON.stringify(err));
    });
  }

  onSessionDestroy() {
    let want: Want | undefined = AppStorage.get('want');
    if (!(want?.parameters?.isFold as boolean)) {
      SubscriberManagement.unsubscribe();
    }
    LogUtils.i(TAG, 'onSessionDestroy.');
  }

  onCreate(): void {
    LogUtils.i(TAG, 'onCreate.');
  }

  onDestroy(): void {
    LogUtils.i(TAG, 'onDestroy.');
  }
}
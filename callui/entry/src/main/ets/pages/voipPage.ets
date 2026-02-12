/**
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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

import Want from '@ohos.app.ability.Want';
import CallStateConst from '../common/constant/CallStateConst';
import CallTimeListStruct from '../common/struct/CallTimeListStruct';
import DefaultCallData, { callDataToSafeString } from '../common/struct/TypeUtils';
import LogUtils from '../common/utils/LogUtils';
import CommonEventManager from '@ohos.commonEventManager';
import BannerNotificationManager from '../model/BannerNotificationManager';
import * as Constants from '../common/utils/Constants';
import { GlobalContextHelper } from '../common/utils/GlobalContextHelper';
import common from '@ohos.app.ability.common';
import { CallEventUtil } from '../common/utils/CallEventUtil';
import CallUtils from '../common/utils/CallUtils';

const TAG = 'VoipPage';

@Entry
@Component
struct VoipPage {
  @State message: string = 'Hello World'
  callData: DefaultCallData = new DefaultCallData();
  callList: Array<DefaultCallData> = [];
  callTimeList: CallTimeListStruct[] = [];
  private myProxy: UIExtensionProxy | null = null;
  private bundleName = '';
  private uid = 0;
  private callId? = '';
  @State want: Want = {
    bundleName: this.bundleName,
    abilityName: '',
    parameters: {
      'ability.want.params.uiExtensionType': 'voip',
      'ability.want.params.uiExtensionAbilityId':''
    }
  }
  @StorageProp('callData') @Watch('onVoipCallDataChange') voipCallData: DefaultCallData = new DefaultCallData();

  onVoipCallDataChange() {
    if (this.voipCallData !== undefined && CallUtils.isVoipCall(this.voipCallData)) {
      let attribute = this.voipCallData.voipCallAttribute;
      if (attribute !== undefined && CallUtils.isSubProcessMode(attribute)) {
        this.want = {
          bundleName: attribute?.voipBundleName,
          abilityName: attribute?.abilityName,
          parameters: {
            'ability.want.params.uiExtensionType': 'voip',
            'ability.want.params.uiExtensionAbilityId': attribute?.extensionId
          }
        }
        if (this.want.parameters !== undefined) {
          this.want.parameters.callData = this.voipCallData;
        }
        GlobalContextHelper.getContext().set<Want>(Constants.VOIP_ABILITY_WANT, this.want);
      }
    }
  }

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    this.updateVoipCallData();
    LogUtils.i(TAG, 'aboutToAppear after init: ' + callDataToSafeString(this.callData));
    if (this.callData !== undefined && this.callData.voipCallAttribute !== undefined) {
      this.callId = this.callData.voipCallAttribute.voipCallId;
      if (this.callData.voipCallAttribute.voipBundleName != null) {
        this.bundleName = this.callData.voipCallAttribute.voipBundleName;
        this.uid = this.callData.voipCallAttribute.uid;
      }
      let abilityName = '';
      if (this.callData.voipCallAttribute.abilityName != null) {
        abilityName = this.callData.voipCallAttribute.abilityName;
      }
      this.want = {
        bundleName: this.bundleName,
        abilityName: abilityName,
        parameters: {
          'ability.want.params.uiExtensionType': 'voip',
          'ability.want.params.uiExtensionAbilityId':this.callData.voipCallAttribute.extensionId
        }
      }
    }
  }

  private updateVoipCallData() {
    if (GlobalContextHelper.getContext().getValue<Want>(Constants.VOIP_ABILITY_WANT)?.parameters &&
      (GlobalContextHelper.getContext()
        .getValue<Want>(Constants.VOIP_ABILITY_WANT)?.parameters?.callData !== undefined)) {
      let callData = GlobalContextHelper?.getContext().getValue<Want>(Constants.VOIP_ABILITY_WANT).parameters?.callData;
      this.callData = (callData as DefaultCallData);
      LogUtils.i(TAG, 'aboutToAppear featureAbility.getWant :');
    }
  }

  build() {
    Row() {
      Column() {
        UIExtensionComponent(this.want)
          .size({ width: '100%', height: '100%' })
          .onRemoteReady((proxy: UIExtensionProxy) => {
            LogUtils.i(TAG, 'onRemoteReady');
            this.message = 'remote ready'
            this.myProxy = proxy
            CallEventUtil.sendCommonEvent(this.getEventOptions(CallEventUtil.EVENT_SUCCESS));
          })
          .onReceive((data: Object) => {
            this.message = JSON.stringify(data)
            LogUtils.i(TAG, 'onReceive ' + (this.message));
          })
          .onRelease((releaseCode: number) => {
            this.message = 'Release: ' + releaseCode;
            this.updateVoipCallData();
            if (this.callData.callState !== CallStateConst.CALL_STATUS_DISCONNECTED) {
              CallEventUtil.sendCommonEvent(this.getEventOptions(CallEventUtil.UI_ABILITY_DESTROY_ABNORMAL));
            }
            GlobalContextHelper.getContext().getValue<common.UIAbilityContext>(Constants.VOIP_ABILITY_CONTEXT)?.
            terminateSelf().then(() => {
              LogUtils.i(TAG, 'voipAbility terminateSelf');
            });
          })
          .onResult((data: Object) => {
            this.message = JSON.stringify(data)
            LogUtils.i(TAG, 'onResult ' + (this.message));
          })
          .onError((error: ErrorObject) => {
            this.message = 'onError: ' + error.code;
            CallEventUtil.sendCommonEvent(this.getEventOptions(CallEventUtil.EVENT_FAIL));
          })

      }
      .width('100%')
    }
    .height('100%')
  }

  private getEventOptions(eventId: number): CommonEventManager.CommonEventPublishData {
    return CallEventUtil.getEventOptions(eventId, this.bundleName, this.callId, this.uid);
  }
}

interface ErrorObject {
  code: number;
  name: string;
  message: string;
}

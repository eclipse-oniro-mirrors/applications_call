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

import { LogUtils } from '@ohos/common/CommonIndex';
import Want from '@ohos.app.ability.Want';
import commonData from '../data/CommonData';
import { getLoadingComponent } from '../common/components/LoadingComponent'
import CallSettingVM from '../viewModel/CallSettingVM';

const TAG = 'IncomingCallRejectionSms';

@Component
export default struct IncomingCallRejectionSms {
  @Consume('pathInfos') pathInfos: NavPathStack;
  private proxyComponent: UIExtensionProxy | null = null;
  // 判断是否使用模态窗口拉起
  @State isFromExternal: boolean = CallSettingVM.getInstance().getIsFromExternal();
  @StorageLink('isShowBorder') isShowBorder: boolean = false;
  private want: Want = {
    'bundleName': commonData.string.MOBILE_SETTING_BUNDLE_NAME,
    'abilityName': commonData.string.CALL_UI_CALL_SETTING_ABILITU_NAME,
    'parameters': {
      'ability.want.params.uiExtensionType': 'sys/commonUI',
      'ability.want.params.IsNotifyOccupiedAreaChange': true,
      'isFromExternal': this.isFromExternal
    }
  }
  private contentNode = getLoadingComponent(this.getUIContext());
  private options: UIExtensionOptions = {
    'placeholder': this.contentNode
  }

  aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear');
  }

  build() {
    NavDestination() {
      Column() {
        UIExtensionComponent(this.want, this.options)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
          .size({ width: '100%', height: '100%' })
          .onRemoteReady((proxy: UIExtensionProxy) => {
            LogUtils.i(TAG, 'UIExtensionComponent onRemoteReady');
            this.isShowBorder = false;
            this.proxyComponent = proxy;
          })
          .onReceive((data: Record<string, Object>) => {
            LogUtils.i(TAG, 'UIExtensionComponent onReceive');
            if (data?.action === 'pop') {
              this.isShowBorder = true;
              this.pathInfos?.pop();
              return;
            }
          })
          .onRelease((releaseCode: number) => {
            LogUtils.i(TAG, 'UIExtensionComponent onRelease');
          })
          .onResult((data: Object) => {
            LogUtils.i(TAG, 'UIExtensionComponent onResult');
            this.isShowBorder = true;
            this.pathInfos.pop();
          })
          .gesture(
            PanGesture().onActionStart(() => {
              LogUtils.i(TAG, 'PanGesture onActionStart')
            })
          )
          .onError((error: ErrorObject) => {
            LogUtils.i(TAG, 'UIExtensionComponent ' + 'onError: ' + error.code + ', name: ' + error.name +
              ', message: ' + error.message);
          })
      }
      .width('100%')
    }
    .backgroundColor($r('sys.color.background_secondary'))
    .hideTitleBar(true)
  }
}

interface ErrorObject {
  code: number;
  name: string;
  message: string;
}
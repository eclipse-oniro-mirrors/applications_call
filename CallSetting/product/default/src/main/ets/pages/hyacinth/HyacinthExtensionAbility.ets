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

const TAG = 'HyacinthExtensionAbility';

@Component
export default struct HyacinthExtensionAbility {
  @Consume('pathInfos') pathInfos: NavPathStack;
  private proxyComponent: UIExtensionProxy | null = null;

  want: Want = {
    'bundleName': 'com.ohos.callsetting',
    'abilityName': 'com.ohos.callsetting.SatelliteServiceNetworkAbility',
    'uri': 'HyacinthExtensionAbility',
    'parameters': {
      'ability.want.params.uiExtensionType': 'sys/commonUI',
      'ability.want.params.IsNotifyOccupiedAreaChange': true
    }
  }

  aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear');
  }

  build() {
    NavDestination() {
      Column() {
        UIExtensionComponent(this.want)
          .size({ width: '100%', height: '100%'})
          .onRemoteReady((proxy: UIExtensionProxy) => {
            LogUtils.i(TAG, 'UIExtensionComponent onRemoteReady');
            this.proxyComponent = proxy;
          })
          .onReceive((data: Object) => {
            LogUtils.i(TAG, 'UIExtensionComponent onReceive');
            this.pathInfos.pop();
          })
          .onRelease((releaseCode: number) => {
            LogUtils.i(TAG, 'UIExtensionComponent onRelease');
          })
          .onResult((data: Object) => {
            LogUtils.i(TAG, 'UIExtensionComponent onResult');
            this.pathInfos.pop();
          })
          .onError((error: ErrorObject) => {
            LogUtils.i(TAG, 'UIExtensionComponent ' + 'onError: ' + error.code + ', name: ' + error.name +
              ', message: ' + error.message);
          })
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      }
      .width('100%')
    }
    .hideTitleBar(true)
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }
}

interface ErrorObject {
  code: number;
  name: string;
  message: string;
}
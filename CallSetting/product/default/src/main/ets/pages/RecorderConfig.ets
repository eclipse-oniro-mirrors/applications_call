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
import * as CallSettingsConstant from '../common/constant/CallSettingsConstant';
import { LogUtils } from '@ohos/common/CommonIndex';
import ability from '@ohos.ability.ability';
import { getLoadingComponent } from '../common/components/LoadingComponent'
import { UIExtensionContentSession } from '@kit.AbilityKit';
import CallSettingVM from '../viewModel/CallSettingVM';

const TAG = 'CallSettingRecorderConfig';

interface ErrorObject {
  code: number;
  name: string;
  message: string;
}

@Component
export default struct RecordingSettingIndex {
  @Consume('pathInfos') pathInfos: NavPathStack;
  @LocalStorageLink('CallRecorderStatusText') getCallRecorderStatusText: Resource = $r('app.string.closed');
  // 判断是否使用模态窗口拉起
  @State isFromExternal: boolean = CallSettingVM.getInstance().getIsFromExternal();
  private extensionSession: UIExtensionContentSession =
    AppStorage.get<UIExtensionContentSession>('extensionSession') as UIExtensionContentSession;
  @StorageLink('isShowBorder') isShowBorder: boolean = false;
  private want: Want = {
    'bundleName': CallSettingsConstant.CALL_RECORDER_BUNDLE_NAME,
    'abilityName': CallSettingsConstant.CALL_RECORDER_ABILITY_NAME,
    'parameters': {
      'ability.want.params.uiExtensionType': 'sys/commonUI',
      'isFromExternal': this.isFromExternal
    }
  }
  private contentNode = getLoadingComponent(this.getUIContext());
  private options: UIExtensionOptions = {
    'placeholder': this.contentNode
  }

  aboutToAppear() {
    LogUtils.i(TAG, 'RecordConfig Appear');
  }

  aboutToDisappear() {
    LogUtils.i(TAG, 'RecordConfig aboutToDisappear');
  }

  onReceivePop(data: Object) {
    this.isShowBorder = true;
    AppStorage.delete('callRecorderProxy');
    let dataInfo: Record<string, boolean> = (data as Record<string, boolean>);
    this.getCallRecorderStatusText = dataInfo['recordingState'] ? $r('app.string.opened') : $r('app.string.closed');
    this.pathInfos.pop();
  }

  build() {
    NavDestination() {
      Column() {
        UIExtensionComponent(this.want, this.options)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
          .size({ width: '100%', height: '100%' })
          .onRemoteReady((proxy: UIExtensionProxy) => {
            LogUtils.i(TAG, 'UIExtensionComponent onRemoteReady');
            AppStorage.setOrCreate('callRecorderProxy', proxy);
            this.isShowBorder = false;
          })
          .onReceive((data: Object) => {
            LogUtils.i(TAG, 'onReceive ' + JSON.stringify(data));
            let dataMap: Record<string, boolean> = (data as Record<string, boolean>);
            this.getCallRecorderStatusText =
              dataMap['recordingState'] ? $r('app.string.opened') : $r('app.string.closed');
            let pickerData: Record<string, string> = (data as Record<string, string>);
            if (pickerData.getPickerData === 'getMultiPickerData') {
              this.extensionSession?.sendData({ 'getPickerData': 'getMultiPickerData' });
              return;
            }
            if (pickerData?.action === 'pop') {
              this.onReceivePop(data);
              return;
            }
          })
          .onRelease((releaseCode: number) => {
            LogUtils.i(TAG, 'UIExtensionComponent onRelease');
          })
          .onResult((data: Object) => {
            LogUtils.i(TAG, 'UIExtensionComponent onResult');
            this.isShowBorder = true;
            AppStorage.delete('callRecorderProxy');
            let dataResult = data as ability.AbilityResult;
            this.getCallRecorderStatusText =
              dataResult?.want?.parameters?.contactObjects === 'true' ? $r('app.string.opened') :
              $r('app.string.closed');
            this.pathInfos.pop();
          })
          .gesture(
            PanGesture().onActionStart(() => {
              LogUtils.i(TAG, 'PanGesture onActionStart');
            })
          )
          .onError((error: ErrorObject) => {
            LogUtils.e(TAG,
              'UIExtensionComponent onError: ' + error.code + ', name: ' + error.name + ', message: ' + error.message);
          })
      }
      .width('100%')
    }
    .backgroundColor($r('sys.color.background_secondary'))
    .hideTitleBar(true);
  }
}
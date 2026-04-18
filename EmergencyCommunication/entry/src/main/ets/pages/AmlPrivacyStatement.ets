/**
 * Copyright (c) 2024-2024 Huawei Device Co., Ltd.
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
import LogUtils from '../utils/HiLog';
//import { HdsNavDestination, HdsNavDestinationAttribute } from '@kit.UIDesignKit';
import { TITLE_BAR_HEIGHT_MINI } from '../base/constant/HdsNavigationConstant';
import { TitleBarLayout, TitleParams } from '../base/view/TitleParams';
import { EditableTitleBar, LengthMetrics } from '@kit.ArkUI';

const TAG = 'AmlPrivacyStatement';

@Component
export default struct AmlPrivacyStatement {
  @StorageProp('statusBarHeight') statusBarHeight: number = 38;
  @Consume('pathInfos') pathInfos: NavPathStack;
  loadHwAmlWnt: Want = {
    'bundleName': 'com.ohos.aml',
    'abilityName': 'OobeStatementAbility',
    'parameters': {
      'ability.want.params.uiExtensionType': 'sys/commonUI',
      'type': 'sos'
    }
  }
  @Builder
  MyCustomTitle() {
    // 在这里调用你的全局 Builder，并传入参数
    TitleBarLayout('',$r('sys.color.background_secondary'),{value: []})
  }

  aboutToAppear() {
    LogUtils.i(TAG, 'AmlPrivacyStatement aboutToAppear');
  }

  aboutToDisappear() {
    LogUtils.i(TAG, 'AmlPrivacyStatement aboutToDisappear');
  }

  build() {
/*    HdsNavDestination() {
      Column() {
        UIExtensionComponent(this.loadHwAmlWnt, {
          windowModeFollowStrategy: WindowModeFollowStrategy.FOLLOW_UI_EXTENSION_ABILITY_WINDOW_MODE
        })
          .size({ width: '100%', height: '100%' })
          .onRemoteReady((proxy: UIExtensionProxy) => {
            LogUtils.i(TAG, 'UIExtensionComponent onRemoteReady');
          })
          .onReceive((data: Object) => {
            LogUtils.i(TAG, 'UIExtensionComponent onReceive');
          })
          .onTerminated((data: TerminationInfo) => {
            LogUtils.i(TAG, 'UIExtensionComponent onTerminated');
          })
          .onError((error) => {
            LogUtils.e(TAG, 'UIExtensionComponent err:' + error.code + ', ' + error.name + ', ' + error.message);
          })
      }
      .margin({ top: TITLE_BAR_HEIGHT_MINI + this.statusBarHeight })
    }*/
    NavDestination() {
      EditableTitleBar({
        title:"",
        isSaveIconRequired:false,
        contentMargin:{top:LengthMetrics.px(100)},
        onCancel:()=>{
          this.pathInfos.pop()
        }
      })
      Column() {
        UIExtensionComponent(this.loadHwAmlWnt, {
          windowModeFollowStrategy: WindowModeFollowStrategy.FOLLOW_UI_EXTENSION_ABILITY_WINDOW_MODE
        })
          .size({ width: '100%', height: '100%' })
          .onRemoteReady((proxy: UIExtensionProxy) => {
            LogUtils.i(TAG, 'UIExtensionComponent onRemoteReady');
          })
          .onReceive((data: Object) => {
            LogUtils.i(TAG, 'UIExtensionComponent onReceive');
          })
          .onTerminated((data: TerminationInfo) => {
            LogUtils.i(TAG, 'UIExtensionComponent onTerminated');
          })
          .onError((error) => {
            LogUtils.e(TAG, 'UIExtensionComponent err:' + error.code + ', ' + error.name + ', ' + error.message);
          })
      }
      .margin({ top: TITLE_BAR_HEIGHT_MINI + this.statusBarHeight })
    }
 /*   .titleBar({
      style: {
        scrollEffectOpts: {
          enableScrollEffect: false
        },
        originalStyle: {
          backgroundStyle: {
            backgroundColor: $r('sys.color.ohos_id_color_sub_background')
          }
        }
      },
      avoidLayoutSafeArea: true
    })*/
    //.title(this.MyCustomTitle)
    .hideTitleBar(true)
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }
}
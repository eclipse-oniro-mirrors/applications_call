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
// import { Navigation, HdsNavigationAttribute, } from '@kit.UIDesignKit';
import { LogUtils } from '@ohos/common';
import { UIExtensionContentSession } from '@kit.AbilityKit';
import { SatelliteNetworkIndex } from '../pages/SatelliteNetworkIndex';
import { CARD_PAGE_MODE, NAVIGATION_MODE, START_REASON } from '../common/constant/CallSettingsConstant';
import { SatelliteCommunication } from '../components/SatelliteNetworkCompent/SatelliteCommunication';
import { OnLineSatelliteServicePrivacy } from '../components/SatelliteNetworkCompent/OnLineSatelliteServicePrivacy';
import { BeiDouSatelliteMessage } from '../components/SatelliteNetworkCompent/BeiDouSatelliteMessage';
import { BeiDouSatelliteMessagePrivacy } from '../components/SatelliteNetworkCompent/BeiDouSatelliteMessagePrivacy';
import { HyacinthActivate } from '../components/SatelliteNetworkCompent/HyacinthActivate';
import { HyacinthCommunication } from '../components/SatelliteNetworkCompent/HyacinthCommunication';
import { HyacinthPrivacy } from '../components/SatelliteNetworkCompent/HyacinthPrivacy';
import { PageStartReason } from '../common/data/commonData';

const TAG: string = 'SatelliteNetworkBlankPage';

@Entry
@Component
export default struct SatelliteNetworkBlankPage {
  @Provide('pathInfos') pathInfos: NavPathStack = new NavPathStack();
  @StorageLink(NAVIGATION_MODE) navMode: NavigationMode = AppStorage.get(NAVIGATION_MODE) ?? NavigationMode.Stack;
  @StorageLink('startReason') startReason: string = AppStorage.get(START_REASON) ?? PageStartReason.DEFAULT;
  @StorageProp('pageMode') pageMode: string = '';
  public storage = LocalStorage.getShared();
  @Provide('session') session: UIExtensionContentSession = this.storage?.
  get<UIExtensionContentSession>('session') as UIExtensionContentSession;
  @BuilderParam satelliteCommunicationLoaderLoader: () => void;

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    this.pathInfos.pushPath({ name: 'SatelliteNetworkIndex' }, true);
  }

  onPageShow(): void {
    // 兼容蓬莱模式
    LogUtils.i(TAG, 'onPageShow');
    this.pageMode === CARD_PAGE_MODE && this.pathInfos.pushPath({ name: 'SatelliteNetworkIndex' }, true);
  }

  build() {
    Navigation(this.pathInfos) {
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .navDestination(this.myRouter)
    .hideNavBar(this.navMode === NavigationMode.Split || this.startReason === PageStartReason.FROM_STABILITY)
  }

  @Builder
  myRouter(name: string) {
    if (name === 'SatelliteNetworkIndex') {
      SatelliteNetworkIndex();
    } else  if (name === 'SatelliteCommunication') {
      SatelliteCommunication();
    } else if (name === 'SatelliteServiceUserAgreement') {
      OnLineSatelliteServicePrivacy({isPrivacyNote: true});
    } else if (name === 'SatelliteServicePrivacyStatement') {
      OnLineSatelliteServicePrivacy({isPrivacyNote: false});
    } else if (name === 'BeiDouSatelliteMessage') {
      BeiDouSatelliteMessage();
    } else if (name === 'BeiDouSatelliteMessagePrivacyStatement') {
      BeiDouSatelliteMessagePrivacy({ isPrivacyNote: false });
    } else if (name === 'BeiDouSatelliteMessageUserAgreement') {
      BeiDouSatelliteMessagePrivacy({ isPrivacyNote: true });
    } else if (name === 'HyacinthActivate') {
      HyacinthActivate();
    } else if (name === 'HyacinthCommunication') {
      HyacinthCommunication();
    } else if (name === 'HyacinthPrivacyStatement') {
      HyacinthPrivacy({ isPrivacyNote: false });
    } else if (name === 'HyacinthUserAgreement') {
      HyacinthPrivacy({ isPrivacyNote: true });
    }
  }
}

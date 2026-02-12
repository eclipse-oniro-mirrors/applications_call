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
import SatelliteSearchManager from '../../manager/SatelliteSearchManager';
import { geoLocationManager } from '@kit.LocationKit';

const TAG = 'SatelliteSearchProgress';

@Entry
@Component
export struct SatelliteSearchProgress {
  @Link @Watch('startLoadingAnimation') showReSearch: boolean;
  @Link scaleSize: number;
  @State ringScale: number = 0.2;
  @State directionAngle: number = 0;

  uiContext: UIContext = this.getUIContext();
  private timerId: number = -1;

  aboutToDisappear(): void {
    this.stopLoadingAnimation();
    if (!SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      clearTimeout(this.timerId);
    }
  }

  startTimer() {
    this.timerId = setTimeout(() => {
      clearTimeout(this.timerId);
      LogUtils.i(TAG, ' startTimer stopLoadingAnimation is called');
      this.stopLoadingAnimation();
      // 搜寻失败，解除绑定
      SatelliteSearchManager.getInstance().unbindSatelliteService();
      this.showReSearch = true;
      SatelliteSearchManager.getInstance().setShowReSearch(this.showReSearch);
    }, 30 * 1000);
  }


  startLoadingAnimation() {
    console.info('startLoadingAnimation is called 1');
    if (!this.showReSearch) {
      console.info('startLoadingAnimation is called 2');
      animateTo({
        duration: 3000, curve: Curve.Linear, iterations: -1}, () => {
        this.directionAngle = 360;
      })
      if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
        // 开始搜寻，打开寻星监听
        SatelliteSearchManager.getInstance().openMeetimeSatelliteListener()
      } else {
        let locationMode: boolean = geoLocationManager.isLocationEnabled();
        if (!locationMode) {
          SatelliteSearchManager.getInstance().enableLocation(true);
        } else {
          SatelliteSearchManager.getInstance().bindSatelliteService();
        }
        this.startTimer();
      }
    }
  }

  stopLoadingAnimation() {
    this.directionAngle = 0.12;
    animateTo({duration: 0}, () => {
      this.directionAngle = 0;
    })
  }

  build() {
    Stack() {
      Stack() {
        Image(SatelliteSearchManager.getInstance().getIsFromMeetime() ? $r('app.media.meetime_dialog_center_blue') :
        $r('app.media.dialog_center_blue'))
          .width(60)
          .height(60)
          .align(Alignment.Center)
          .draggable(false)
        Image(SatelliteSearchManager.getInstance().getIsFromMeetime() ? $r('app.media.meetime_prograss_light') :
        $r('app.media.prograss_light'))
          .width(260 * this.scaleSize)
          .height(260 * this.scaleSize)
          .align(Alignment.Center)
          .draggable(false)
          .transition(TransitionEffect.OPACITY.animation({ duration: 250, curve: Curve.Sharp }))
          .rotate({ angle: this.directionAngle })
      }
    }
    .width('100%')
    .height('100%')
    .onAppear(() => {
      this.startLoadingAnimation();
    })
  }
}
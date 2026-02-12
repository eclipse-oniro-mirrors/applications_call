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
import SatelliteUtils from '../../common/utils/SatelliteUtils';
import SatelliteSearchManager, { SatelliteData } from '../../manager/SatelliteSearchManager';
import { TrifoldManager } from '../../manager/TrifoldManager'
import { isTablet } from '../../common/utils/DeviceTypeUtils'

@Entry
@Component
export struct SatelliteLandscapeRemind {

  @Link @Watch('changeSatelliteData') mSatelliteData: SatelliteData;
  @Link @Watch('updateRemind') isShowOrientationRemind: boolean;

  //卫星角度信息发生变化
  changeSatelliteData() {
    if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      return;
    }
    if (SatelliteUtils.checkAzimuthOk(this.mSatelliteData?.azimuthDelta) &&
      SatelliteUtils.checkPitchOk(this.mSatelliteData?.pitchAngleDelta)) {
      this.updateRemind();
    }
  }

  updateRemind() {
    if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      return;
    }
    this.isShowOrientationRemind = SatelliteSearchManager.getInstance().isShowOrientationRemind();
  }

  build() {
      Stack() {
        Stack() {
          Image((isTablet() || TrifoldManager.getInstance().isTrifold()) ?
          $r('app.media.portrait_remind') : $r('app.media.landscape_remind'))
            .width(260)
            .height(260)
            .align(Alignment.Center)
            .draggable(false)
        }
      }
  }
}
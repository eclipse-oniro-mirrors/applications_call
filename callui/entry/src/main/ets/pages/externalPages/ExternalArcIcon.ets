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

import LogUtils from '../../common/utils/LogUtils';
import DefaultCallData from '../../common/struct/TypeUtils';
import * as Constants from '../../common/utils/Constants';
import { isIncomingCall, isIncomingVoiceSilencedCall } from '../../common/utils/CallListHelper';

const TAG = 'ExternalArcIcon';
const DIRECTION_ARR: number[] = [Constants.LEFT_DIRECTION, Constants.RIGHT_DIRECTION,
  Constants.BOTTOM_DIRECTION];

@Component
export default struct ExternalArcIcon {
  @StorageProp(Constants.CALL_DATA) @Watch('refreshingData') callData: DefaultCallData = new DefaultCallData();
  @State callState: number = -1;
  @Consume('leftValue') leftValue: number;
  @Consume('rightValue') rightValue: number;
  @Consume('bottomValue') bottomValue: number;
  @Consume('leftAngle') leftAngle: number;
  @Consume('rightAngle') rightAngle: number;
  @Consume('bottomAngle') bottomAngle: number;

  aboutToAppear(): void {
    this.refreshingData();
    LogUtils.i(TAG, 'aboutToAppear');
  }

  refreshingData(): void {
    this.callState = this.callData.callState;
  }

  private getValue(arcDirection: number): number {
    let value = this.leftValue;
    switch (arcDirection) {
      case Constants.LEFT_DIRECTION:
        value = this.leftValue;
        break;
      case Constants.RIGHT_DIRECTION:
        value = this.rightValue;
        break;
      case Constants.BOTTOM_DIRECTION:
        value = this.bottomValue;
        break;
      default:
        LogUtils.e(TAG, 'getValue invalid direction');
    }
    return value;
  }

  private getAngle(arcDirection: number): number {
    let angle = this.leftAngle;
    switch (arcDirection) {
      case Constants.LEFT_DIRECTION:
        angle = this.leftAngle;
        break;
      case Constants.RIGHT_DIRECTION:
        angle = this.rightAngle;
        break;
      case Constants.BOTTOM_DIRECTION:
        angle = this.bottomAngle;
        break;
      default:
        LogUtils.e(TAG, 'getAngle invalid direction');
    }
    return angle;
  }

  private getColor(arcDirection: number): ResourceColor | LinearGradient {
    if (arcDirection === Constants.LEFT_DIRECTION) {
      return $r('sys.color.ohos_id_color_handup');
    }
    if (arcDirection === Constants.RIGHT_DIRECTION) {
      return $r('sys.color.ohos_id_color_connected');
    }
    return isIncomingCall(this.callState) ? $r('sys.color.ohos_id_color_connected')
      : $r('sys.color.ohos_id_color_handup');
  }

  private getVisibility(arcDirection: number): Visibility {
    if (arcDirection === Constants.LEFT_DIRECTION || arcDirection === Constants.RIGHT_DIRECTION) {
      return isIncomingCall(this.callState) ? Visibility.Visible : Visibility.None;
    }
    return isIncomingVoiceSilencedCall(this.callData) ? Visibility.None : Visibility.Visible;
  }

  build() {
    Stack() {
      ForEach(DIRECTION_ARR, (arcDirection: number) => {
        Progress({ value: this.getValue(arcDirection), total: 360, type: ProgressType.Ring })
          .color(this.getColor(arcDirection))
          .rotate({ angle: this.getAngle(arcDirection) })
          .style({ strokeWidth: '4vp' })
          .visibility(this.getVisibility(arcDirection))
          .width('100%')
          .height('100%')
      })
    }
  }
}
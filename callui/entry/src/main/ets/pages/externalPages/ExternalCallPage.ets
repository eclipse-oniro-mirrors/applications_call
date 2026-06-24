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
import * as Constants from '../../common/utils/Constants';
import CallDataManager from '../../model/CallDataManager';
import DefaultCallData from '../../common/struct/TypeUtils'
import CallTimeListStruct from '../../common/struct/CallTimeListStruct';
import ExternalCallCard from './ExternalCallCard';
import ExternalCallButton from './ExternalCallButton';
import { ExternalCallModel } from '../../model/ExternalCallModel';
import ExternalResourceManager, { getContactImage } from '../../model/ExternalResourceManager';
import ExternalArcIcon from './ExternalArcIcon';
import { image } from '@kit.ImageKit';

const TAG = 'ExternalCallPage';

@Entry
@Component
struct ExternalCallPage {
  @StorageProp(Constants.CALL_DATA) @Watch('commonUpdate') callData: DefaultCallData = new DefaultCallData();
  @StorageProp('isMute') @Watch('updateExternalIcon') isMute: boolean = false;
  @StorageProp('currentAudioDeviceIcon') @Watch('updateAudioDeviceIcon') currentAudio: Resource =
    $r('app.media.answer_icon_green');
  @State callTimeList: Array<CallTimeListStruct> = [];
  @Provide('contactImage') contactImage: Resource | null | image.PixelMap | undefined =
    $r('app.media.ic_user_40_40dark');
  @Provide('leftValue') leftValue: number = Constants.MIN_ANGLE;
  @Provide('rightValue') rightValue: number = Constants.MIN_ANGLE;
  @Provide('bottomValue') bottomValue: number = Constants.MIN_ANGLE;
  @Provide('leftAngle') leftAngle: number = Constants.LEFT_ANGLE - Constants.MIN_ANGLE / Constants.ANGLE_DIVIDE;
  @Provide('rightAngle') rightAngle: number = Constants.RIGHT_ANGLE - Constants.MIN_ANGLE / Constants.ANGLE_DIVIDE;
  @Provide('bottomAngle') bottomAngle: number = Constants.BOTTOM_ANGLE - Constants.MIN_ANGLE / Constants.ANGLE_DIVIDE;
  @Provide('isConferenceMode') isConferenceMode: boolean = false;
  private mCallDataManager?: CallDataManager;
  private isPsd: boolean = ExternalCallModel.sIsPsd;

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    this.addTimeUpdateCallback();
    this.commonUpdate();
  }

  aboutToDisappear() {
    LogUtils.i(TAG, 'aboutToDisappear');
  }

  onPageShow() {
    LogUtils.i(TAG, 'onPageShow');
    AppStorage.setOrCreate<boolean>('onExternalPageShow', true);
  }

  onPageHide() {
    LogUtils.i(TAG, 'onPageHide');
    AppStorage.setOrCreate<boolean>('onExternalPageShow', false);
  }

  private addTimeUpdateCallback() {
    this.callTimeList = [];
    this.mCallDataManager = CallDataManager.getInstance();
    this.mCallDataManager.addTimeUpdateCallback((callTimeList: CallTimeListStruct[]) => {
      this.callTimeList = callTimeList;
    });
  }

  private commonUpdate() {
    this.updateExternalIcon();
    this.isConferenceMode = ExternalCallModel.checkConferenceCall();
    this.contactImage = getContactImage(this.isConferenceMode);
  }

  private updateExternalIcon() {
    ExternalResourceManager.getInstance().updateExternalIcon();
  }

  private updateAudioDeviceIcon() {
    ExternalResourceManager.getInstance().updateAudioDeviceIcon();
  }

  build() {
    Stack() {
      ExternalArcIcon()
        .visibility(this.isPsd ? Visibility.None : Visibility.Visible)
      Column() {
        ExternalCallCard({
          callTimeList: this.callTimeList
        })
        ExternalCallButton()
      }
      .alignItems(HorizontalAlign.Center)
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Color.Black)
    .onAppear(() => {
      ExternalCallModel.getInstance().showVideoTipsDialog();
    })
  }
}

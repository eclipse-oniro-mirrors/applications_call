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

import CallStateConst from '../constant/CallStateConst';
import LogUtils from '../utils/LogUtils';
import { setDisplayWindowApi, VideoStateType } from '../../common/utils/VideoCallApi';
import { getCallById, isActiveCall, isVideoCall } from '../utils/CallListHelper';
import VideoCallManager from '../../model/VideoCallManager';
import { ReportUtil } from '../utils/ReportUtils/ReportUtil';
import { ScreenInfo } from '../struct/CallUiDataStruct';
import { display } from '@kit.ArkUI';
import ScreenAdapterUtils from '../utils/ScreenAdapterUtils';
import CallDataManager from '../../model/CallDataManager';

const TAG = 'RbtRingToneXComponent';

@Component
export default struct RbtRingToneXComponent {
  private surfaceId: string = ''
  @Link @Watch('onCallDataChanged') callId: number;
  @Link @Watch('onCallDataChanged') videoState: number;
  @Link @Watch('onCallDataChanged') callState: number;
  xComponentController: XComponentController = new XComponentController()
  @State hasSetDisplayWindow: boolean = false;
  @StorageLink('peerScreenAspectRatio') @Watch('updateRbtRingSize') peerScreenAspectRatio: number = -1;
  @State rbtRingWidth: number | string = '100%';
  @State rbtRingHeight: number | string = '100%';
  @StorageLink('FoldStatus') @Watch('updateRbtRingSize') foldStatus: number = 0;
  @StorageProp('windowSizeChangeMd') @Watch('updateRbtRingSize') windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  }
  @StorageLink('CurrentOrientation') @Watch('updateRbtRingSize') orientation: display.Orientation = -1;
  @State screenSize: ScreenInfo = {
    width: 0,
    height: 0
  };
  @StorageLink('Density') @Watch('updateRbtRingSize') density: number = 1;

  private xComponentOnLoad() {
    this.surfaceId = this.xComponentController.getXComponentSurfaceId();
    LogUtils.i(TAG, `xComponentOnLoad surfaceId: ${this.surfaceId}`);
    //set CRBT surfaceId.
    setDisplayWindowApi(this.callId, this.surfaceId);
    // Video and incmoing.
    this.hasSetDisplayWindow = (!isVideoCall(this.videoState) &&
      this.callState === CallStateConst.CALL_STATUS_ALERTING);
    ReportUtil.getInstance().reportPlayVoiveColor();
  }

  private onCallDataChanged(value?: string) {
    LogUtils.i(TAG, `onCallDataChanged: watch: ${value}, callState: ${this.callState}, videoState: ${this.videoState}`);
    const callData = getCallById(CallDataManager.getInstance().callList, this.callId);

    if (!callData) {
      LogUtils.w(TAG, 'call data is null');
      return;
    }
    LogUtils.i(TAG, `onCallDataChanged: w: ${value}, c: ${callData.callState}, v: ${callData.videoState}`);
    if (isActiveCall(callData.callState) && this.hasSetDisplayWindow &&
      callData.videoState !== VideoStateType.TYPE_VIDEO_RECEIVE_ONLY) {

      VideoCallManager.getInstance().controlCamera(this.callId, '');
      setDisplayWindowApi(this.callId, '');
      this.hasSetDisplayWindow = false;
    }
  }

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    this.updateRbtRingSize();
    this.onCallDataChanged();
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear');
  }

  getScreenInfo() {
    let width: number = px2vp(this.windowSizeChangeMd.width);
    let height: number = px2vp(this.windowSizeChangeMd.height);
    if (width === 0) {
      try {
        const size: display.Display = display.getDefaultDisplaySync();
        width = px2vp(size.width);
        height = px2vp(size.height);
      } catch (error) {
        LogUtils.e(TAG, `getScreenInfo error :${JSON.stringify(error)}`);
      }
    }
    this.screenSize = {
      width,
      height
    }
  }

  updateRbtRingSize() {
    this.getScreenInfo();
    if (this.peerScreenAspectRatio === -1 || this.peerScreenAspectRatio === 0) {
      return;
    }
    let isNewFoldInnerExpandFlag =
      ScreenAdapterUtils.isNeedExpandXComponentToFullScreen(this.peerScreenAspectRatio, true);
    LogUtils.i(TAG, `updateRbtRingSize isNewFoldInnerExpandFlag:${isNewFoldInnerExpandFlag}`);
    this.rbtRingWidth = this.screenSize.width;
    this.rbtRingHeight = this.screenSize.width / this.peerScreenAspectRatio;
    if (this.rbtRingHeight > this.screenSize.height && !isNewFoldInnerExpandFlag) {
      this.rbtRingHeight = this.screenSize.height;
      this.rbtRingWidth = this.rbtRingHeight * this.peerScreenAspectRatio;
    }
  }

  build() {
    Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Row() {
        XComponent({ id: 'xComponent', type: XComponentType.SURFACE, controller: this.xComponentController })
          .onLoad(() => this.xComponentOnLoad())
          .width('100%')
          .height('100%')
          .backgroundColor(Color.Transparent)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      }
      .width(this.rbtRingWidth)
      .height(this.rbtRingHeight)
    }
    .width('100%')
    .height('100%')
  }
}
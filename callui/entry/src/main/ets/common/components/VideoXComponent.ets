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
import LogUtils from '../utils/LogUtils';
import CallStateConst from '../constant/CallStateConst';
import callStateConst from '../constant/CallStateConst';
import DefaultCallData from '../struct/TypeUtils';
import curves from '@ohos.curves';
import display from '@ohos.display';
import VideoCallPanel from './VideoCallPanel';
import CallTimeListStruct from '../struct/CallTimeListStruct';
import {
  ImsCallMode,
  offCameraCapabilitiesChange,
  onCameraCapabilitiesChange,
  PeerDimensionsDetail,
  setDeviceDirection,
  setDisplayWindowApi,
  setPreviewWindowApi,
} from '../utils/VideoCallApi';
import {
  isActiveCall,
  isIncomingCall,
  isOutgoingCall,
  isUpgradingToVideo,
  isVoiceCall,
  setWindowLayoutFullScreenApi
} from '../utils/CallListHelper';
import VideoCameraHelper from '../struct/VideoCameraHelper';
import VideoCallManager from '../../model/VideoCallManager';
import CallColumnUtils from '../utils/CallColumnUtils';
import BottomViewModel from '../../viewmodel/BottomViewModel';
import { AudioListItem } from '../../model/audio/AudioListItem';
import { getCallLabelPrimary, getCallLabelSecondary } from '../utils/CallLabelUtils';
import { isTablet } from '../utils/DeviceTypeUtils';
import { SmallScreenOffset } from '../struct/CallUiDataStruct';
import { ReportUtil } from '../utils/ReportUtils/ReportUtil';
import { ScreenInfo } from '../struct/CallUiDataStruct';
import { BusinessError, emitter } from '@kit.BasicServicesKit';
import json from '@ohos.util.json';
import VideoCameraStatus from '../struct/VideoCameraStatus';
import ScreenAdapterUtils from '../utils/ScreenAdapterUtils';
import { DisplayUtil } from '../utils/DisplayUtil';
import { TrifoldManager } from '../utils/TrifoldManager';
import call from '@ohos.telephony.call';
import ThrFoldRemindContent from './ThrFoldRemindContent';
import { CustomContentDialog } from '@kit.ArkUI';
import { ProximityUtils } from '../utils/ProximityUtils';
import { ExternalCallModel } from '../../model/ExternalCallModel';
import systemParameterEnhance from '@ohos.systemParameterEnhance';
import { StringUtil } from '../utils/StringUtil';
import { OPEN_VIDEO_CAMERA, ROTATION_ANGLE } from '../utils/Constants';

const TAG = 'VideoXComponent';
const FLOATDEVICEOFFSETY = 8;

@Component
export struct VideoXComponent {
  @Link @Watch('initData') callData: DefaultCallData;
  @Link callList: Array<DefaultCallData>;
  @Link callTimeList: Array<CallTimeListStruct>;
  @Link hasMultiDevice: boolean;
  @Link callState: number;
  @Link callId: number;
  @Link videoState: number;
  @State accountId: number = -1;
  @State callLabelPrimary: Resource | string = '';
  @State callLabelSecondary: string = '';
  @State emitterId: number = 101;
  @State isShowVideoPanel: boolean = true;
  @State videoShowMode: boolean = false;
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @State positionX: number = 0;
  @State positionY: number = 0;
  @State screenSize: ScreenInfo = {
    width: 0,
    height: 0
  };
  @StorageProp('curBp') curBp: string = '';
  @State smallScreenWidth: number = 0;
  @State smallScreenWidthCur: number | string = '100%';
  @State smallScreenHeightCur: number | string = '100%';
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  @StorageProp('navigationHeight') @Watch('navigationHeightChange') navigationHeight: number = 0;
  @StorageLink('isShowSmartWindow') isShowSmartWindow: boolean = false;
  @StorageLink('surfaceId') surfaceId: string = '';
  @StorageProp('windowSizeChangeMd') @Watch('windowSizeChangeMdChange') windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  }
  @State bigScreenWidthCur: number | string = '100%';
  @State bigScreenHeightCur: number | string = '100%';
  @StorageLink('peerScreenAspectRatio') @Watch('updatePeerScreenSize') peerScreenAspectRatio: number = -1;
  @StorageLink('currentScreenAspectRatio') @Watch('updateCurrentScreenAspectRatio')
  currentScreenAspectRatio: number = -1;
  @State currentRotateZ: number = 0;
  @StorageProp('cameraState') @Watch('updateCameraState') cameraState: number = VideoCameraHelper.CAMERA_STATE_OPEN;
  @State isCameraClosed: boolean = false;
  private localSurfaceId: string = '';
  @State videoPanelTimer: number = -1;
  @StorageLink('isShowVideoKeyBoard') @Watch('updateVideoKeyBoardMode') isShowVideoKeyBoard: boolean = false;
  @State shouldShowPreviewZoomAnimation: boolean = false;
  @StorageLink('hidePeerVideoScreen') hidePeerVideoScreen: boolean = true;
  @Prop contactAppear: boolean = false;
  @Prop callListCount: number = 0;
  @StorageLink('clearPanelTimer') @Watch('showPanel') clearPanelTimer: boolean | null = null;
  @State bigZIndex: number = 0;
  @State smallZIndex: number = 1;
  @State oldShowByImsCallMode: boolean | null = null;
  @State callVoiceToVideo: boolean = false;
  localXComponentController: XComponentController = new XComponentController();
  peerXComponentController: XComponentController = new XComponentController();
  @State showVideoRbt: boolean = false;
  @State timer: number = 0;
  @State mBottomViewModel: BottomViewModel = BottomViewModel.getInstance();
  @StorageLink('audioDeviceList') audioDeviceList: AudioListItem[] = [];
  @StorageLink('FoldStatus') @Watch('foldStatusChange') foldStatus: number = 0;
  @State nickFontSize: string = '40vp';
  @State stackOpacity: number = 0;
  @Provide frontCameraId: string = '';
  @Provide backCameraId: string = '';
  @Provide currentCameraId: string = '';
  private currentVideoAngle: number = 0;
  @State videoAngle: string = '0deg';
  private lastOrientation: display.Orientation = -1;
  @StorageLink('CurrentOrientation') @Watch('currentOrientationChange') orientation: display.Orientation = -1;
  private angle_90: number = 90;
  private angle_180: number = 180;
  private angle_270: number = 270;
  private offsetYSpace: number = 5;
  private screenHalf_2: number = 2;
  @StorageLink('Density') @Watch('densityDidChange') density: number = 1;
  @StorageLink('isNewFoldPhoneExternalScreen') @Watch('setNewFoldDeviceDirection') isNewFoldPhoneExternalScreen: boolean =
    false;
  @State isComponentTran: boolean = true;
  @State isCameraFullScreen: boolean = false;
  @StorageProp('foldDisplayMode') @Watch('foldDisplayModeChange') foldDisplayMode: number = -1;
  private lastFoldDisplayMode: number = -1;
  @StorageProp('rotation') @Watch('rotationChange') rotation: number = -1;
  @State triVideoAngle: number = 0;
  private callDirection: call.DeviceDirection = -1;
  private backCameraValue: string = '0';
  thrFoldRemindController?: CustomDialogController;
  // MLR是平板，但是横屏时获取的Orientation值和其他平板不一样，这里做特殊处理
  private isMLR: boolean = systemParameterEnhance.getSync('const.build.product', '') === 'MLR';

  aboutToAppear() {
    LogUtils.i(TAG, `aboutToAppear`);
    this.addCallEventListener();
    this.updateOrientationAndDensityPixels();
    this.rotationChange();
    this.addCurrentDimensionsChangeListener();
    this.getScreenInfo();
    this.updateSmallScreenWidth();
    this.updatePeerScreenSize();
    this.showPanel();
    setTimeout(() => {
      this.isCameraFullScreen = true
      setWindowLayoutFullScreenApi(true);
    }, 300);
    this.updateUnActiveSmallScreenSize();
    this.initData();
    if (isActiveCall(this.callState)) {
      AppStorage.setOrCreate('hidePeerVideoScreen', false);
      if (!this.callVoiceToVideo) {
        this.initCurrentScreenSize();
        this.initSmallScreenOffset(true);
      }
    }
    ProximityUtils.keepScreenOn(true);
    this.initSmallScreenAngle();
    this.getCameraList();
    this.alertThrFoldRemind();
    this.afterCameraRotation();
  }

  afterCameraRotation(){
    emitter.on(OPEN_VIDEO_CAMERA, () => {
      this.rotationChange()
    })
  }

  setNewFoldDeviceDirection() {
    if (!ScreenAdapterUtils.isNewFormFoldPhone()) {
      return;
    }
    LogUtils.i(TAG, `setNewFoldDeviceDirection ${this.isNewFoldPhoneExternalScreen}_${this.rotation}`);
    let currentCallDirection = -1;
    if (this.isNewFoldPhoneExternalScreen) {
      switch (this.rotation) {
        case 0:
          currentCallDirection = call.DeviceDirection.DEVICE_DIRECTION_270;
          break;
        case 1:
          currentCallDirection = call.DeviceDirection.DEVICE_DIRECTION_180;
          break;
        case 2:
          currentCallDirection = call.DeviceDirection.DEVICE_DIRECTION_90;
          break;
        case 3:
          currentCallDirection = call.DeviceDirection.DEVICE_DIRECTION_0;
          break;
        default:
          break;
      }
    } else {
      currentCallDirection = call.DeviceDirection.DEVICE_DIRECTION_270;
    }
    if (this.callDirection !== currentCallDirection) {
      LogUtils.i(TAG, `setNewFoldDeviceDirection start ${currentCallDirection}`);
      this.callDirection = currentCallDirection;
      setDeviceDirection(this.callId, this.callDirection);
    }
  }

  /**
   * list the video foreground and background status.
   */
  addCallEventListener() {
    let innerEvent: emitter.InnerEvent = {
      eventId: this.emitterId,
      priority: emitter.EventPriority.HIGH
    };
    emitter.on(innerEvent, (data: emitter.EventData) => {
      if (!isVoiceCall(this.callData)) {
        LogUtils.i(TAG, 'event data =' + json.stringify(data.data));
        LogUtils.i(TAG, 'event data cameraState =' + this.cameraState);
        if (data.data!['type'] === 'background') {
          VideoCallManager.getInstance().modifyImsCallMode(this.callData, ImsCallMode.CALL_MODE_VIDEO_PAUSED);
          setPreviewWindowApi(this.callId, '');
        } else if (data.data!['type'] === 'foreground' && this.cameraState === VideoCameraHelper.CAMERA_STATE_OPEN) {
          VideoCallManager.getInstance().modifyImsCallMode(this.callData, ImsCallMode.CALL_MODE_SEND_RECEIVE);
          LogUtils.i(TAG, 'addCallEventListener_setPreviewWindowApi');
          setPreviewWindowApi(this.callId, this.surfaceId);
        } else if (data.data!['type'] === 'foreground' &&
          this.cameraState === VideoCameraHelper.CAMERA_STATE_MANUAL_CLOSED) {
          VideoCallManager.getInstance().modifyImsCallMode(this.callData, ImsCallMode.CALL_MODE_SEND_RECEIVE);
          LogUtils.i(TAG, 'modifyImsCallMode Success, ImsCallMode.CALL_MODE_RECEIVE_ONLY');
        }
      }
    })
  }

  setNewThreeFoldDeviceDirection() {
    const currentCamera = AppStorage.get('currentCameraState') || '1';
    // 左：0， 下：3， 上：1， 右：2
    switch (this.rotation) {
      case ROTATION_ANGLE.LEFT:
        this.callDirection = call.DeviceDirection.DEVICE_DIRECTION_270;
        break;
      case ROTATION_ANGLE.TOP:
        this.callDirection =
          currentCamera === this.backCameraValue ? call.DeviceDirection.DEVICE_DIRECTION_180 :
          call.DeviceDirection.DEVICE_DIRECTION_0;
        break;
      case ROTATION_ANGLE.RIGHT:
        this.callDirection = call.DeviceDirection.DEVICE_DIRECTION_90;
        break;
      case ROTATION_ANGLE.BOTTOM:
        this.callDirection =
          currentCamera === this.backCameraValue ? call.DeviceDirection.DEVICE_DIRECTION_0 :
          call.DeviceDirection.DEVICE_DIRECTION_180;
        break;
      default:
        break;
    }
    setDeviceDirection(this.callId, this.callDirection);
  }

  updateOrientationAndDensityPixels() {
    try {
      const defaultDisplay: display.Display = display.getDefaultDisplaySync();
      // lastOrientation只在第一次初始化的时候获取一次，后面每次旋转屏幕，lastOrientation都是前一次的orientation值。
      if (this.lastOrientation.valueOf() === -1) {
        this.lastOrientation = defaultDisplay.orientation;
      }
      this.orientation = defaultDisplay.orientation;
      this.lastFoldDisplayMode = display.getFoldDisplayMode().valueOf();
      this.rotation = defaultDisplay.rotation;
      LogUtils.i(TAG, `foldStatusChange lastOrientation ${this.lastOrientation} orientation ${this.orientation}`);
    } catch (error) {
      LogUtils.e(TAG, `updateOrientationAndDensityPixels error :${JSON.stringify(error)}`);
    }
  }

  addCurrentDimensionsChangeListener(): void {
    try {
      onCameraCapabilitiesChange((value: PeerDimensionsDetail) => {
        VideoCallManager.getInstance().handleCurrentDimensionsChange(value);
      });
    } catch (error) {
      LogUtils.e(TAG, `addPeerDimensionsChangeListener error :${JSON.stringify(error)}`);
    }
  }

  private densityDidChange() {
    this.updateLayoutWithScreenChange(true);
  }

  private foldStatusChange() {
    this.updatefoldCamera();
  }

  private currentOrientationChange() {
    if (this.lastFoldDisplayMode !== this.foldDisplayMode) {
      this.updateOrientationAndDensityPixels();
    }
    this.updateSmallScreenAngle();
    this.lastOrientation = this.orientation;
  }

  private foldDisplayModeChange() {
    LogUtils.i(TAG, `foldDisplayModeChange value is ${this.foldDisplayMode}`);
    this.lastFoldDisplayMode = this.lastFoldDisplayMode;
  }

  private windowSizeChangeMdChange() {
    LogUtils.i(TAG, `windowSizeChangeMdChange`);
    this.updateLayoutWithScreenChange(true);
  }

  private rotationChange() {
    if (this.isNewFoldPhoneExternalScreen && this.surfaceId !== '') {
      this.setNewFoldDeviceDirection();
      this.initSmallScreenOffset(!this.videoShowMode);
    }
    if (ScreenAdapterUtils.isTrifoldPhone()) {
      if (ScreenAdapterUtils.isNewThreeFoldPhone()) {
        this.setNewThreeFoldDeviceDirection();
        return;
      }
      if (this.rotation === 0) {
        this.triVideoAngle = 0;
      } else if (this.rotation === 1) {
        this.triVideoAngle = this.angle_90;
      } else if (this.rotation === 2) {
        this.triVideoAngle = this.angle_180;
      } else {
        this.triVideoAngle = this.angle_270;
      }
    }
  }

  updateLayoutWithScreenChange(needUpdateSmallScreenWidth: boolean) {
    this.getScreenInfo();
    if (needUpdateSmallScreenWidth) {
      this.updateSmallScreenWidth();
    }
    this.updateFontSize();
    this.updatePeerScreenSize();
    if (this.callData.callState === CallStateConst.CALL_STATUS_ACTIVE) {
      AppStorage.setOrCreate('hidePeerVideoScreen', false);
      if (!this.callVoiceToVideo) {
        this.initCurrentScreenSize();
        this.initSmallScreenOffset(true);
      } else {
        this.updateUnActiveSmallScreenSize();
      }
    } else {
      LogUtils.i(TAG, 'updateUnActiveSmallScreenSize');
      this.updateUnActiveSmallScreenSize();
    }
  }

  private updatefoldCamera() {
    if (this.foldStatus === display.FoldStatus.FOLD_STATUS_HALF_FOLDED) {
      return;
    }
    VideoCameraHelper.getInstance().getCameraIds();
    if (!ScreenAdapterUtils.isNewFormFoldPhone() && !ExternalCallModel.isSmallExternalDevice() &&
      VideoCameraHelper.getInstance().backCameraId === VideoCameraHelper.getInstance().getCurrentCameraId()) {
      return;
    }
    this.frontCameraId = VideoCameraHelper.getInstance().frontCameraId;
    this.currentCameraId = this.frontCameraId;
    VideoCallManager.getInstance().controlCamera(this.callId, this.frontCameraId);
    VideoCameraHelper.getInstance().saveVideoCameraInfo(this.callId, this.currentCameraId, false);
    this.alertThrFoldRemind();
  }

  // Updates the video angle of the local video call.
  updateUnActiveSmallScreenSize() {
    if (ScreenAdapterUtils.isTrifoldPhone()) {
      this.smallScreenWidthCur = this.screenSize.width;
      this.smallScreenHeightCur = this.screenSize.height;
    } else {
      if (this.orientation === display.Orientation.LANDSCAPE ||
        this.orientation === display.Orientation.LANDSCAPE_INVERTED) {
        this.smallScreenWidthCur = this.screenSize.height;
        this.smallScreenHeightCur = this.screenSize.width;
      } else {
        this.smallScreenWidthCur = this.screenSize.width;
        this.smallScreenHeightCur = this.screenSize.height;
      }
    }
  }

  // Update the local video angle during a video call.
  updateActiveSmallScreenSize() {
    LogUtils.i(TAG, `updateActiveSmallScreenSize`);
    if (TrifoldManager.getInstance().rection(this.orientation) === display.Orientation.LANDSCAPE ||
      TrifoldManager.getInstance().rection(this.orientation) === display.Orientation.LANDSCAPE_INVERTED) {
      this.smallScreenWidthCur = this.videoShowMode ? this.screenSize.height : this.smallScreenWidth;
      if (this.currentScreenAspectRatio !== 0) {
        this.smallScreenHeightCur = (this.videoShowMode ? this.screenSize.height : this.smallScreenWidth) /
        this.currentScreenAspectRatio;
      }
      if (this.smallScreenHeightCur > this.screenSize.width) {
        this.smallScreenHeightCur = this.screenSize.width;
        this.smallScreenWidthCur = this.smallScreenHeightCur * this.currentScreenAspectRatio;
      }
      // 新三折叠，屏幕宽高要对倒
      if(ScreenAdapterUtils.isNewThreeFoldPhone()){
        let temp = this.smallScreenHeightCur;
        this.smallScreenHeightCur = this.smallScreenWidthCur;
        this.smallScreenWidthCur = temp;
      }
      LogUtils.i(TAG, `LANDSCAPEorINVERTED smallSH: ${this.smallScreenHeightCur} smallSW: ${this.smallScreenWidthCur}`);
    } else {
      this.smallScreenWidthCur = this.videoShowMode ? this.screenSize.width : this.smallScreenWidth;
      if (this.currentScreenAspectRatio !== 0) {
        this.smallScreenHeightCur = (this.videoShowMode ? this.screenSize.width : this.smallScreenWidth) /
        this.currentScreenAspectRatio;
      }
      if (this.smallScreenHeightCur > this.screenSize.height) {
        this.smallScreenHeightCur = this.screenSize.height;
        this.smallScreenWidthCur = this.smallScreenHeightCur * this.currentScreenAspectRatio;
      }
      LogUtils.i(TAG, `smallSH: ${this.smallScreenHeightCur} smallSW: ${this.smallScreenWidthCur}`);
    }
  }

  // Initialize the local screen angle.
  initSmallScreenAngle() {
    switch (this.orientation) {
      case display.Orientation.PORTRAIT:
        this.currentVideoAngle = 0;
        break;
      case display.Orientation.PORTRAIT_INVERTED:
        this.currentVideoAngle = this.angle_180;
        break;
      case display.Orientation.LANDSCAPE:
        if (isTablet() && !this.isMLR) {
          this.currentVideoAngle = -this.angle_90;
        } else {
          this.currentVideoAngle = this.angle_90;
        }
        break;
      case display.Orientation.LANDSCAPE_INVERTED:
        if (isTablet() && !this.isMLR) {
          this.currentVideoAngle = this.angle_90;
        } else {
          this.currentVideoAngle = -this.angle_90;
        }
        break;
    }
    this.videoAngle = this.currentVideoAngle + 'deg';
    LogUtils.i(TAG, `initSmallScreenAngle, videoAngle: ${this.videoAngle}`)
  }

  updateSmallScreenAngle() {
    switch (this.lastOrientation) {
      case display.Orientation.PORTRAIT:
        this.updateSmallScreenPortraitAngle();
        break;
      case display.Orientation.PORTRAIT_INVERTED:
        this.updateSmallScreenPortraitInvertedAngle();
        break;
      case display.Orientation.LANDSCAPE:
        this.updateSmallScreenLandscapeAngle();
        break;
      case display.Orientation.LANDSCAPE_INVERTED:
        this.updateSmallScreenLandscapeInvertedAngle();
        break;
    }
    this.videoAngle = this.currentVideoAngle + 'deg';
    LogUtils.i(TAG, `updateSmallScreenAngle, videoAngle: ${this.videoAngle}`)
  }

  private updateSmallScreenLandscapeInvertedAngle() {
    switch (this.orientation) {
      case display.Orientation.PORTRAIT:
        this.currentVideoAngle = isTablet() && !this.isMLR ? this.currentVideoAngle - this.angle_90 :
          (ScreenAdapterUtils.isNewFormFoldPhone() &&
            DisplayUtil.getScreenFoldStatus() !== display.FoldStatus.FOLD_STATUS_FOLDED) ?
            0 : this.currentVideoAngle + this.angle_90;
        break;
      case display.Orientation.PORTRAIT_INVERTED:
        this.currentVideoAngle = isTablet() && !this.isMLR ? this.currentVideoAngle + this.angle_90 :
          this.currentVideoAngle - this.angle_90;
        break;
      case display.Orientation.LANDSCAPE:
        this.currentVideoAngle += this.angle_180;
        break;
      default:
        break;
    }
  }

  private updateSmallScreenLandscapeAngle() {
    switch (this.orientation) {
      case display.Orientation.PORTRAIT:
        this.currentVideoAngle = isTablet() && !this.isMLR ? this.currentVideoAngle + this.angle_90 :
          (ScreenAdapterUtils.isNewFormFoldPhone() &&
            DisplayUtil.getScreenFoldStatus() !== display.FoldStatus.FOLD_STATUS_FOLDED) ? 0 :
            this.currentVideoAngle - this.angle_90;
        break;
      case display.Orientation.PORTRAIT_INVERTED:
        this.currentVideoAngle = isTablet() && !this.isMLR ? this.currentVideoAngle - this.angle_90 :
          this.currentVideoAngle + this.angle_90;
        break;
      case display.Orientation.LANDSCAPE_INVERTED:
        this.currentVideoAngle -= this.angle_180;
        break;
      default:
        break;
    }
  }

  private updateSmallScreenPortraitInvertedAngle() {
    switch (this.orientation) {
      case display.Orientation.PORTRAIT:
        this.currentVideoAngle = (ScreenAdapterUtils.isNewFormFoldPhone() &&
          DisplayUtil.getScreenFoldStatus() !== display.FoldStatus.FOLD_STATUS_FOLDED) ? 0 :
          this.currentVideoAngle + this.angle_180;
        break;
      case display.Orientation.LANDSCAPE:
        this.currentVideoAngle = isTablet() && !this.isMLR ? this.currentVideoAngle + this.angle_90 :
          this.currentVideoAngle - this.angle_90;
        break;
      case display.Orientation.LANDSCAPE_INVERTED:
        this.currentVideoAngle = isTablet() && !this.isMLR ? this.currentVideoAngle - this.angle_90 :
          this.currentVideoAngle + this.angle_90;
        break;
      default:
        break;
    }
  }

  private updateSmallScreenPortraitAngle() {
    LogUtils.i(TAG,
      `updateSmallScreenPortraitAngle, orientation: ${this.orientation},currentVideoAngle: ${this.currentVideoAngle}`);
    switch (this.orientation) {
      case display.Orientation.PORTRAIT:
        this.currentVideoAngle = 0;
        break;
      case display.Orientation.PORTRAIT_INVERTED:
        this.currentVideoAngle -= this.angle_180;
        break;
      case display.Orientation.LANDSCAPE:
        this.currentVideoAngle = isTablet() && !this.isMLR ? this.currentVideoAngle - this.angle_90 :
          this.currentVideoAngle + this.angle_90;
        break;
      case display.Orientation.LANDSCAPE_INVERTED:
        this.currentVideoAngle = isTablet() && !this.isMLR ? this.currentVideoAngle + this.angle_90 :
          this.currentVideoAngle - this.angle_90;
        break;
      default:
        break;
    }
  }

  private getCameraList() {
    VideoCameraHelper.getInstance().getCameraIds();
    this.frontCameraId = VideoCameraHelper.getInstance().frontCameraId;
    this.backCameraId = VideoCameraHelper.getInstance().backCameraId;
    this.openCamera();
  }

  private async openCamera() {
    try {
      //get camerainfo data from storage.
      let videoCameraInfo: VideoCameraStatus | undefined = VideoCameraHelper.getInstance().getVideCameraInfo();
      LogUtils.i(TAG, 'getCameraList videoCamera: ' + JSON.stringify(videoCameraInfo));
      if (videoCameraInfo === undefined || videoCameraInfo?.currentCameraId === '') {
        this.currentCameraId = this.frontCameraId;
      } else if (videoCameraInfo.isCameraClose) {
        this.currentCameraId = videoCameraInfo.currentCameraId;
        LogUtils.i(TAG, ' getCameraList camera is closed no need open it.');
        return;
      } else {
        this.currentCameraId = this.frontCameraId;
      }
      await VideoCallManager.getInstance().controlCamera(this.callId, this.currentCameraId);
      AppStorage.setOrCreate('currentCameraState', this.currentCameraId);
      LogUtils.i(TAG, `getCameraList currentCameraId: ${this.currentCameraId}` +
        `, backCameraId: ${VideoCameraHelper.getInstance().backCameraId}`);
      VideoCameraHelper.getInstance().saveVideoCameraInfo(this.callId, this.currentCameraId, false);
    } catch (error) {
      LogUtils.e(TAG, `The getSupportedCameras call failed. error code: ${error?.code}`);
    }
  }

  aboutToDisappear() {
    LogUtils.i(TAG, `aboutToDisappear`);
    this.callDirection = -1;
    offCameraCapabilitiesChange();
    setWindowLayoutFullScreenApi(this.isNewFoldPhoneExternalScreen);
    ProximityUtils.keepScreenOn(isIncomingCall(this.callState));
    emitter.off(this.emitterId);
    emitter.off(OPEN_VIDEO_CAMERA);
    AppStorage.delete('surfaceId');
  }

  updateVideoKeyBoardMode() {
    if (this.isShowVideoKeyBoard && this.videoPanelTimer !== -1) {
      clearTimeout(this.videoPanelTimer);
      this.videoPanelTimer = -1;
    } else {
      this.videoPanelTimer = setTimeout(() => {
        this.isShowVideoPanel = false;
      }, 5000);
    }
  }

  updateCameraState() {
    LogUtils.i(TAG, 'updateCameraState cameraState: ' + this.cameraState);
    switch (this.cameraState) {
      case VideoCameraHelper.CAMERA_STATE_OPEN:
        LogUtils.i(TAG, 'updateCameraState_setPreviewWindowApi');
        setPreviewWindowApi(this.callId, this.localSurfaceId);
        VideoCameraHelper.getInstance().saveVideoCameraInfo(this.callId, this.currentCameraId, false);
        break;
      case VideoCameraHelper.CAMERA_STATE_MANUAL_CLOSED:
      case VideoCameraHelper.CAMERA_STATE_CLOSED:
        setPreviewWindowApi(this.callId, '');
        if (this.videoShowMode) {
          this.changePositionAndSize();
        }
        VideoCameraHelper.getInstance().saveVideoCameraInfo(this.callId, this.currentCameraId, true);
        break;
      default:
        break;
    }
  }

  setTimeOutHidePeerVideoScreen() {
    const timer = setTimeout(() => {
      AppStorage.setOrCreate('hidePeerVideoScreen', false);
      clearTimeout(timer);
    }, 1500);
  }

  navigationHeightChange() {
    this.initSmallScreenOffset(true);
  }

  // Updating the Peer Video Size
  updatePeerScreenSize() {
    if (this.peerScreenAspectRatio === -1) {
      return;
    }
    this.isComponentTran = false;
    let smallScreenWidthTemp = this.smallScreenWidth
    if (this.peerScreenAspectRatio > 1) {
      smallScreenWidthTemp = this.smallScreenWidth * this.peerScreenAspectRatio;
    }
    this.bigScreenWidthCur = !this.videoShowMode ? this.screenSize.width : smallScreenWidthTemp;
    this.bigScreenHeightCur = (!this.videoShowMode ? this.screenSize.width : smallScreenWidthTemp) /
    this.peerScreenAspectRatio;
    let isNewFoldInnerExpandFlag =
      ScreenAdapterUtils.isNeedExpandXComponentToFullScreen(this.peerScreenAspectRatio, this.showVideoRbt);
    LogUtils.i(TAG, `updatePeerScreenSize isNewFoldInnerExpandFlag:${isNewFoldInnerExpandFlag}`);
    if (this.bigScreenHeightCur > this.screenSize.height && !isNewFoldInnerExpandFlag) {
      this.bigScreenHeightCur = this.screenSize.height;
      this.bigScreenWidthCur = this.bigScreenHeightCur * this.peerScreenAspectRatio;
    }
  }

  // Updates the current screen aspect ratio.
  updateCurrentScreenAspectRatio() {
    LogUtils.i(TAG, 'updateCurrentScreenAspectRatio:' + this.currentScreenAspectRatio);
    if (this.currentScreenAspectRatio === -1) {
      return;
    }
    if (isActiveCall(this.callState) && !this.callVoiceToVideo) {
      if (this.offsetX === 0 && this.offsetY === 0) {
        LogUtils.i(TAG, 'offsetX is 0 and offsetY is 0');
        this.initSmallScreenOffset(true);
      }
      this.initCurrentScreenSize();
    } else {
      LogUtils.i(TAG, 'isActiveCall');
    }
  }

  initCurrentScreenSize() {
    if (this.currentScreenAspectRatio === -1) {
      return;
    }
    this.updateActiveSmallScreenSize();
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

  updateSmallScreenWidth() {
    this.smallScreenWidth = CallColumnUtils.getInstance().getVideoSmall(this.curBp,
      this.screenSize.width, this.screenSize.height);
  }

  initData() {
    this.accountId = this.callData.accountId;
    this.callLabelPrimary = getCallLabelPrimary(this.callData);
    this.callLabelSecondary = getCallLabelSecondary(this.callData);
    let isCallOutgoing = isOutgoingCall(this.callData.callState);
    let isCallActive = isActiveCall(this.callData.callState);
    this.callVoiceToVideo = isUpgradingToVideo(this.callData);
    if (isCallOutgoing || isCallActive) {
      this.showPanel();
    }
    if (isCallActive && this.shouldShowPreviewZoomAnimation) {
      animateTo({ curve: curves.springMotion(), duration: 500 }, () => {
        this.smallScreenWidthCur = this.smallScreenWidth;
        this.smallScreenHeightCur = this.smallScreenWidthCur / this.currentScreenAspectRatio;
      });
      this.updateSmallWindowSize();
      this.setTimeOutHidePeerVideoScreen();
    }

    if (isCallOutgoing && this.callData.imsCallMode && this.callData.imsCallMode !== ImsCallMode.CALL_MODE_AUDIO_ONLY) {
      this.showVideoRbt = true;
      AppStorage.setOrCreate('hidePeerVideoScreen', false);
      this.smallZIndex = -1;
    } else {
      this.showVideoRbt = false;
      this.smallZIndex = 1;
    }
    this.shouldShowPreviewZoomAnimation = isCallOutgoing || this.callVoiceToVideo;
    this.updateFontSize();
    if (this.callVoiceToVideo) {
      animateTo({ duration: 200, delay: 200, curve: curves.interpolatingSpring(0, 1, 342, 37) }, () => {
        this.stackOpacity = 1;
      });
    }
  }

  // Update the xy coordinates of the small screen.
  updateSmallWindowSize() {
    setTimeout(() => {
      animateTo({ curve: curves.springMotion(), duration: 500 }, () => {
        let curBp = TrifoldManager.getInstance().isTrifold() ? 'lg' : this.curBp;
        let paddingResoure: Resource = CallColumnUtils.getInstance().getPaddingSpace(curBp);
        if (this.isShowSmartWindow) {
          paddingResoure = $r('sys.float.padding_level8');
        }
        let paddingSize: number = px2vp(getContext(this).resourceManager.getNumber(paddingResoure.id));
        let offSetX: number = (this.screenSize.width - this.smallScreenWidth) / this.screenHalf_2 - paddingSize;
        let offSetY: number = -((this.screenSize.height - this.smallScreenWidth / this.currentScreenAspectRatio) /
        this.screenHalf_2 - this.deviceOffSetY());
        if (TrifoldManager.getInstance().rection(this.orientation) === display.Orientation.LANDSCAPE ||
          TrifoldManager.getInstance().rection(this.orientation) === display.Orientation.LANDSCAPE_INVERTED) {
          offSetX = (this.screenSize.width - this.smallScreenWidth / this.currentScreenAspectRatio) /
          this.screenHalf_2 - paddingSize;
          offSetY = -((this.screenSize.height - this.smallScreenWidth) /
          this.screenHalf_2 - this.deviceOffSetY());
        }
        this.offsetX = offSetX;
        this.offsetY = offSetY;
        this.positionX = offSetX;
        this.positionY = offSetY;
      });
    }, 1000);
  }

  // Drag the small screen to update the xy coordinate
  moveActionUpdate(event: GestureEvent | undefined) {
    if (this.callState !== CallStateConst.CALL_STATUS_ACTIVE) {
      return
    }
    if (event) {
      const aspectRatio = (!this.videoShowMode ? this.currentScreenAspectRatio : this.peerScreenAspectRatio);
      this.offsetX = this.positionX + event.offsetX;
      this.offsetY = this.positionY + event.offsetY;
      let smallScreenOffset: SmallScreenOffset = this.getSmallScreenAreaOffset(aspectRatio);
      if (!this.videoShowMode) {
        this.updateSmallScreenOffset(event);
      }
      if (this.offsetY < smallScreenOffset.minOffsetY) {
        this.offsetY = smallScreenOffset.minOffsetY;
      }
      if (this.offsetY > smallScreenOffset.maxOffSetY) {
        this.offsetY = smallScreenOffset.maxOffSetY;
      }
      if (this.offsetX < smallScreenOffset.minOffSetX) {
        this.offsetX = smallScreenOffset.minOffSetX;
      }
      if (this.offsetX > smallScreenOffset.maxOffSetX) {
        this.offsetX = smallScreenOffset.maxOffSetX;
      }
    }
  }

  private updateSmallScreenOffset(event: GestureEvent) {
    if (this.isNewFoldPhoneExternalScreen) {
      return;
    }
    switch (TrifoldManager.getInstance().rection(this.orientation)) {
      case display.Orientation.PORTRAIT_INVERTED:
        this.offsetX =
          this.isNewFoldPhoneExternalScreen ? this.positionX + event.offsetX : this.positionX - event.offsetX;
        this.offsetY =
          this.isNewFoldPhoneExternalScreen ? this.positionY + event.offsetY : this.positionY - event.offsetY;
        break;
      case display.Orientation.LANDSCAPE:
        this.offsetX =
          (this.isNewFoldPhoneExternalScreen || isTablet()) ? this.positionX + event.offsetY :
            this.positionX - event.offsetY;
        this.offsetY =
          (this.isNewFoldPhoneExternalScreen || isTablet()) ? this.positionY - event.offsetX :
            this.positionY + event.offsetX;
        break;
      case display.Orientation.LANDSCAPE_INVERTED:
        this.offsetX =
          (this.isNewFoldPhoneExternalScreen || isTablet()) ? this.positionX - event.offsetY :
            this.positionX + event.offsetY;
        this.offsetY =
          (this.isNewFoldPhoneExternalScreen || isTablet()) ? this.positionY + event.offsetX :
            this.positionY - event.offsetX;
        break;
      case display.Orientation.PORTRAIT:
        this.offsetX =
          this.isNewFoldPhoneExternalScreen ? this.positionX - event.offsetX : this.positionX + event.offsetX;
        this.offsetY =
          this.isNewFoldPhoneExternalScreen ? this.positionY - event.offsetY : this.positionY + event.offsetY;
        break;
      default:
        break;
    }
  }

  private getSmallScreenAreaOffset(aspectRatio: number): SmallScreenOffset {
    if (aspectRatio === 0) {
      let smallScreenOffset: SmallScreenOffset = {
        minOffsetY: 0,
        maxOffSetY: 0,
        minOffSetX: 0,
        maxOffSetX: 0
      }
      return smallScreenOffset;
    }
    let smallScreenWidthTemp = this.smallScreenWidth;
    if (this.videoShowMode && aspectRatio > 1) {
      smallScreenWidthTemp = this.smallScreenWidth * aspectRatio;
    }
    let minOffsetY: number = -(this.screenSize.height - smallScreenWidthTemp / aspectRatio) / this.screenHalf_2;
    let maxOffSetY: number = (this.screenSize.height - smallScreenWidthTemp / aspectRatio) / this.screenHalf_2;
    let minOffSetX: number = -(this.screenSize.width - smallScreenWidthTemp) / this.screenHalf_2;
    let maxOffSetX: number = (this.screenSize.width - smallScreenWidthTemp) / this.screenHalf_2;
    let isNewFoldPeerScreen = this.isNewFoldPhoneExternalScreen && this.videoShowMode;
    if (TrifoldManager.getInstance().rection(this.orientation) === display.Orientation.LANDSCAPE ||
      TrifoldManager.getInstance().rection(this.orientation) === display.Orientation.LANDSCAPE_INVERTED) {
      if (!isNewFoldPeerScreen) {
        minOffsetY = -(this.screenSize.height - smallScreenWidthTemp) / this.screenHalf_2;
        maxOffSetY = (this.screenSize.height - smallScreenWidthTemp) / this.screenHalf_2;
        minOffSetX = -(this.screenSize.width - smallScreenWidthTemp / aspectRatio) / this.screenHalf_2;
        maxOffSetX = (this.screenSize.width - smallScreenWidthTemp / aspectRatio) / this.screenHalf_2;
      }
    }
    let paddingResoure: Resource = CallColumnUtils.getInstance().getPaddingSpace(this.curBp);
    let paddingSize: number = px2vp(getContext(this).resourceManager.getNumber(paddingResoure.id));
    let smallScreenOffset: SmallScreenOffset = {
      minOffsetY: minOffsetY + this.statusBarHeight,
      maxOffSetY: maxOffSetY - this.navigationHeight,
      minOffSetX: minOffSetX + paddingSize,
      maxOffSetX: maxOffSetX - paddingSize
    }
    return smallScreenOffset;
  }

  moveActionEnd() {
    if (this.callState !== CallStateConst.CALL_STATUS_ACTIVE) {
      return
    }
    this.positionX = this.offsetX;
    this.positionY = this.offsetY;
  }

  deviceOffSetY(): number {
    if (this.isShowSmartWindow) {
      return FLOATDEVICEOFFSETY;
    }
    return this.statusBarHeight + this.offsetYSpace;
  }

  // Initialize the xy coordinates of the small screen in a call.
  initSmallScreenOffset(isCurrentScreenAspectRatio: boolean) {
    if ((this.currentScreenAspectRatio === -1 && isCurrentScreenAspectRatio) ||
      (!isCurrentScreenAspectRatio && this.peerScreenAspectRatio === -1)) {
      LogUtils.i(TAG, 'initSmallScreenOffset return');
      return;
    }
    let paddingResoure: Resource = CallColumnUtils.getInstance().getPaddingSpace(this.curBp);
    if (this.isShowSmartWindow) {
      paddingResoure = $r('sys.float.padding_level8');
    }
    let smallScreenWidthTemp = this.smallScreenWidth;
    if (!isCurrentScreenAspectRatio && this.peerScreenAspectRatio > 1) {
      smallScreenWidthTemp = this.smallScreenWidth * this.peerScreenAspectRatio;
    }
    let paddingSize: number = px2vp(getContext(this).resourceManager.getNumber(paddingResoure.id));
    let aspectRatio: number = !isCurrentScreenAspectRatio ? this.peerScreenAspectRatio : this.currentScreenAspectRatio;
    let offSetX: number = (this.screenSize.width - smallScreenWidthTemp) / this.screenHalf_2 - paddingSize;
    let offSetY: number = 0;
    if (aspectRatio !== 0) {
      offSetY = -((this.screenSize.height - smallScreenWidthTemp / aspectRatio) / this.screenHalf_2 -
      this.deviceOffSetY());
    }
    if (!this.videoShowMode) {
      if (TrifoldManager.getInstance().rection(this.orientation) === display.Orientation.LANDSCAPE ||
        TrifoldManager.getInstance().rection(this.orientation) === display.Orientation.LANDSCAPE_INVERTED) {
        if (aspectRatio !== 0) {
          offSetX = (this.screenSize.width - this.smallScreenWidth / aspectRatio) / this.screenHalf_2 - paddingSize;
        }
        offSetY = -((this.screenSize.height - this.smallScreenWidth) / this.screenHalf_2 - this.deviceOffSetY());
      }
    }
    this.offsetX = offSetX;
    this.offsetY = offSetY;
    this.positionX = offSetX;
    this.positionY = offSetY;
    LogUtils.i(TAG, `offsetX is ${this.offsetX} and offsetY is ${this.offsetY}`);
  }

  showPanel() {
    this.isShowVideoPanel = true;
    if (this.videoPanelTimer !== -1) {
      clearTimeout(this.videoPanelTimer);
    }
    if (!this.isShowVideoKeyBoard) {
      this.videoPanelTimer = setTimeout(() => {
        this.isShowVideoPanel = false;
        this.videoPanelTimer = -1;
      }, 5000)
    }
  }

  changePositionAndSize() {
    if (this.callState !== CallStateConst.CALL_STATUS_ACTIVE) {
      return
    }
    this.videoShowMode = !this.videoShowMode;
    let smallScreenWidthTemp = this.smallScreenWidth;
    if (this.peerScreenAspectRatio > 1) {
      smallScreenWidthTemp = this.smallScreenWidth * this.peerScreenAspectRatio;
    }
    this.bigScreenWidthCur = this.videoShowMode ? smallScreenWidthTemp : this.screenSize.width;
    this.bigScreenHeightCur = this.videoShowMode ? smallScreenWidthTemp / this.peerScreenAspectRatio
      : this.screenSize.width / this.peerScreenAspectRatio;
    if (this.bigScreenHeightCur > this.screenSize.height) {
      this.bigScreenHeightCur = this.screenSize.height;
      this.bigScreenWidthCur = this.bigScreenHeightCur * this.peerScreenAspectRatio;
    }
    this.updateActiveSmallScreenSize();
    this.smallZIndex = this.videoShowMode ? 0 : 1;
    this.bigZIndex = this.videoShowMode ? 1 : 0;
    this.initSmallScreenOffset(!this.videoShowMode);
  }

  clearPanelTimerFunc(isChange: boolean = true) {
    if (isChange) {
      this.isShowVideoPanel = !this.isShowVideoPanel;
    }
    if (this.isShowVideoPanel) {
      if (this.videoPanelTimer !== -1) {
        clearTimeout(this.videoPanelTimer);
      }
      if (this.isShowVideoKeyBoard) {
        return;
      }
      this.videoPanelTimer = setTimeout(() => {
        this.isShowVideoPanel = false;
        this.videoPanelTimer = -1;
      }, 5000)
    }
  }

  clearTimeOut() {
    clearTimeout(this.videoPanelTimer);
  }

  updateFontSize() {
    this.nickFontSize =
      CallColumnUtils.getInstance().getDisplayNameForAutoSize(this.callLabelPrimary, this.curBp, true);
  }

  canShowContactCard(): boolean {
    return this.callState === callStateConst.CALL_STATUS_DIALING ||
      this.callState === callStateConst.CALL_STATUS_ALERTING || this.callVoiceToVideo;
  }

  isXComponentBig(): boolean {
    return (isActiveCall(this.callState) || this.showVideoRbt) && !this.callVoiceToVideo;
  }

  getXComponentSmallTranslate(): TranslateOptions {
    if (!this.isXComponentBig() && isOutgoingCall(this.callState)) {
      return { x: 0, y: 0, z: 0 };
    }
    return !this.videoShowMode ? { x: this.offsetX, y: this.offsetY, z: 0 } : { x: 0, y: 0, z: 0 };
  }

  alertThrFoldRemind() {
    if (ScreenAdapterUtils.isTrifoldPhone() && this.foldStatus === 1 && this.frontCameraId === this.currentCameraId) {
      this.creatThrFoldRemindController()
      this.thrFoldRemindController?.open();
    } else {
      this.thrFoldRemindController?.close();
    }
  }

  @Builder
  creatThrFoldRemindContent() {
    ThrFoldRemindContent({
      remindString: $r('app.string.flip_phone_for_front_camera'),
      clickClose: () => {
        this.thrFoldRemindController?.close();
      }
    })
  }

  creatThrFoldRemindController() {
    if (this.thrFoldRemindController === null || this.thrFoldRemindController === undefined) {
      this.thrFoldRemindController = new CustomDialogController({
        builder: CustomContentDialog({
          contentBuilder: () => {
            this.creatThrFoldRemindContent();
          },
          contentAreaPadding: { left: $r('sys.float.padding_level0'), right: $r('sys.float.padding_level0') },
          themeColorMode: ThemeColorMode.DARK
        }),
        autoCancel: true,
        customStyle: false,
        width: 320,
        backgroundBlurStyle: BlurStyle.BACKGROUND_THICK
      })
    }
  }

  getRotationAngle() {
    if (this.isNewFoldPhoneExternalScreen || ScreenAdapterUtils.isNewThreeFoldPhone()) {
      return 0;
    }
    if (ScreenAdapterUtils.isTrifoldPhone()) {
      return this.triVideoAngle;
    }
    return this.videoAngle;
  }

  build() {
    RelativeContainer() {
      Stack() {
        Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
          Row() {
            XComponent({
              id: 'xComponent',
              type: XComponentType.SURFACE,
              controller: this.peerXComponentController
            })
              .onAppear(() => {
                LogUtils.i(TAG, 'onAppear Peer DisplayWindow');
              })
              .accessibilityText($r('app.string.peer_video'))
              .onLoad(() => {
                LogUtils.i(TAG, 'onLoad Peer DisplayWindow');
                AppStorage.setOrCreate('peerSurfaceId', this.peerXComponentController.getXComponentSurfaceId());
                setDisplayWindowApi(this.callId, this.peerXComponentController.getXComponentSurfaceId());
                ReportUtil.getInstance().reportPlayVideoColor();
              })
              .width('100%')
              .height('100%')
              .borderRadius(this.videoShowMode ? 12 : 0)
              .backgroundColor(this.isComponentTran ? Color.Transparent : null)
          }
          .width(this.bigScreenWidthCur)
          .height(this.bigScreenHeightCur)
          .visibility(this.hidePeerVideoScreen ? Visibility.Hidden : Visibility.Visible)
          .translate(this.videoShowMode ? { x: this.offsetX, y: this.offsetY, z: 0 } : { x: 0, y: 0, z: 0 })
          .accessibilityDescription(this.bigZIndex === 1 ?
            StringUtil.formatResourceToString($r('app.string.one_finger_double_click')) : ' ')
          .gesture(
            PanGesture()
              .onActionUpdate((event: GestureEvent | undefined) => {
                if (this.videoShowMode) {
                  this.moveActionUpdate(event);
                }
              })
              .onActionEnd(() => {
                if (this.videoShowMode) {
                  this.moveActionEnd();
                }
              }))
          .onClick(() => {
            if (this.videoShowMode) {
              this.changePositionAndSize();
            }
            if (this.showVideoRbt) {
              this.clearPanelTimerFunc();
            }
          })
        }
        .width('100%')
        .height('100%')
        .visibility(this.isXComponentBig() ? Visibility.Visible : Visibility.None)
        .zIndex(this.bigZIndex)

        Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
          Row() {
            XComponent({
              id: 'xComponent',
              type: XComponentType.SURFACE,
              controller: this.localXComponentController
            })
              .accessibilityText($r('app.string.my_video'))
              .onLoad(() => {
                this.setNewFoldDeviceDirection();
                this.localSurfaceId = this.localXComponentController.getXComponentSurfaceId();
                LogUtils.i(TAG, 'setPreviewWindowApi_XComponent_onLoad');
                AppStorage.setOrCreate('surfaceId', this.localSurfaceId);
                LogUtils.i(TAG, `onLoad local DisplayWindow`);
              })
              .width('100%')
              .height('100%')
              .backgroundColor(this.isComponentTran ? Color.Transparent : null)
              .borderRadius((!this.videoShowMode && this.smallScreenHeightCur !== '100%') ?
              $r('sys.float.corner_radius_level4') : 0)
          }
          .rotate({
            centerX: '50%',
            centerY: '50%',
            angle: this.getRotationAngle()
          })
          .visibility(this.cameraState !== VideoCameraHelper.CAMERA_STATE_OPEN || this.showVideoRbt ?
          Visibility.Hidden : Visibility.Visible)
          .translate(this.getXComponentSmallTranslate())
          .accessibilityDescription(this.smallZIndex === 1 ?
            StringUtil.formatResourceToString($r('app.string.one_finger_double_click')) : ' ')
          .gesture(
            PanGesture()
              .onActionUpdate((event: GestureEvent | undefined) => {
                if (!this.videoShowMode && !this.callVoiceToVideo) {
                  this.moveActionUpdate(event);
                }
              })
              .onActionEnd(() => {
                if (!this.videoShowMode) {
                  this.moveActionEnd();
                }
              }))
          .width(this.getSmallWidth())
          .height(this.getSmallHeight())
          .onClick(() => {
            if (!this.videoShowMode) {
              if (!this.callVoiceToVideo) {
                this.changePositionAndSize();
              }
              if (this.callVoiceToVideo || isOutgoingCall(this.callState)) {
                this.clearPanelTimerFunc();
              }
            }
          })
        }
        .width('100%')
        .height('100%')
        .zIndex(this.smallZIndex)

        if (this.canShowContactCard()) {
          Column()
            .backgroundColor('#33000000')
            .height('100%')
            .width('100%')
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
            .zIndex(2)
        }
      }
      .width('100%')
      .height('100%')
      .opacity(!this.callVoiceToVideo ? 1 : this.stackOpacity)
      .alignRules({
        top: { anchor: '__container__', align: VerticalAlign.Top },
        middle: { anchor: '__container__', align: HorizontalAlign.Center }
      })
      .id('video')
      .onClick(() => {
        this.clearPanelTimerFunc();
      })

      if (this.canShowContactCard()) {
        Column() {
          Text(this.callLabelPrimary)
            .fontColor('#FFFFFF')
            .fontWeight(600)
            .fontSize(this.isNewFoldPhoneExternalScreen ? '30vp' : this.nickFontSize)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.callLabelSecondary)
            .fontSize($r('app.float.call_video_card_body_m_font'))
            .height($r('app.float.call_video_card_body_m_height'))
            .lineHeight($r('app.float.call_video_card_body_m_height'))
            .fontColor('#FFFFFF')
            .visibility(this.callLabelSecondary ? Visibility.Visible : Visibility.None)
            .margin({ bottom: $r('sys.float.padding_level1') })
            .accessibilityText('"' + getCallLabelSecondary(this.callData) + '"')
          Text($r('app.string.waitingInvitation'))
            .fontColor('#FFFFFF')
            .height($r('app.float.call_video_card_body_m_height'))
            .lineHeight($r('app.float.call_video_card_body_m_height'))
            .fontSize($r('app.float.call_video_card_body_m_font'))
        }
        .alignItems(HorizontalAlign.Start)
        .margin({
          left: CallColumnUtils.getInstance().getPaddingSpace(this.curBp),
          top: this.isCameraFullScreen ? 24 + this.statusBarHeight : 24,
          right: CallColumnUtils.getInstance().getPaddingSpace(this.curBp)
        })
        .opacity(!this.callVoiceToVideo ? 1 : this.stackOpacity)
      }

      Row() {
        VideoCallPanel({
          callData: $callData,
          callList: $callList,
          callState: $callState,
          callId: $callId,
          videoState: $videoState,
          accountId: $accountId,
          callTimeList: $callTimeList,
          hasMultiDevice: $hasMultiDevice,
          contactAppear: this.contactAppear,
          callListCount: this.callListCount,
          showVideoRbt: this.showVideoRbt,
          isShowVideoPanel: $isShowVideoPanel,
          touchStatusCallBack: (isTouchDown) => {
            isTouchDown ? this.clearTimeOut() : this.clearPanelTimerFunc(false);
          },
          touchCameraCallBack: () => {
            this.alertThrFoldRemind();
          }
        })
      }
      .alignRules({
        bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
        middle: { anchor: '__container__', align: HorizontalAlign.Center }
      })
      .id('row')
    }
    .height('100%')
    .width('100%')
  }

  private getSmallHeight(): Length {
    if (this.isNewFoldPhoneExternalScreen && this.smallScreenWidthCur !== '100%') {
      if (this.rotation === 1 || this.rotation === 3) {
        // 横屏 宽>高
        return this.smallScreenWidthCur > this.smallScreenHeightCur ? this.smallScreenHeightCur :
        this.smallScreenWidthCur;
      } else {
        // 竖屏 宽<高
        return this.smallScreenWidthCur > this.smallScreenHeightCur ? this.smallScreenWidthCur :
        this.smallScreenHeightCur;
      }
    }
    return this.smallScreenHeightCur;
  }

  private getSmallWidth(): Length {
    if (this.isNewFoldPhoneExternalScreen && this.smallScreenWidthCur !== '100%') {
      if (this.rotation === 1 || this.rotation === 3) {
        // 横屏 宽>高
        return this.smallScreenWidthCur > this.smallScreenHeightCur ? this.smallScreenWidthCur :
        this.smallScreenHeightCur;
      } else {
        // 竖屏 宽<高
        return this.smallScreenWidthCur > this.smallScreenHeightCur ? this.smallScreenHeightCur :
        this.smallScreenWidthCur;
      }
    }
    return this.smallScreenWidthCur;
  }
}

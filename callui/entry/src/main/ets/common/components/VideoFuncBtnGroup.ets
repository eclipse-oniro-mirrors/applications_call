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
import call from '@ohos.telephony.call';
import CallServiceProxy from '../../model/CallServiceProxy';
import BtnGroupConfig from '../../model/configs/BtnGroupConfig';
import LogUtils from '../utils/LogUtils';
import Clone from '../utils/Clone';
import DefaultCallData from '../struct/TypeUtils';
import VideoFuncBtn from './VideoFuncBtn';
import callStateConst from '../constant/CallStateConst';
import BottomViewModel from '../../viewmodel/BottomViewModel';
import Method from '../utils/Method';
import {
  setPreviewWindowApi,
  setDisplayWindowApi,
  ImsCallMode,
  cancelCallUpgradeApi,
  VideoStateType,
} from '../../common/utils/VideoCallApi';
import { AudioListItem } from '../../model/audio/AudioListItem';
import AudioDeviceManager from '../../model/audio/AudioDeviceManager';
import VideoCameraHelper from '../struct/VideoCameraHelper';
import VideoCameraStatus from '../struct/VideoCameraStatus';
import { isUpgradingToVideo } from '../utils/CallListHelper';
import CallUtils from '../utils/CallUtils';
import VideoCallManager from '../../model/VideoCallManager';
import { CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import { SelectDeviceContent } from './SelectDeviceContent';
import { ReportUtil } from '../utils/ReportUtils/ReportUtil';
import { audioDeviceToString } from '../../model/audio/AudioDeviceType';
import SplitScreenManager, { SplitScreenType } from '../../model/SplitScreenManager';
import { screenLock } from '@kit.BasicServicesKit';
import { display, window } from '@kit.ArkUI';
import Utils from '../utils/utils';

const TAG = 'VideoFuncBtnGroup';

interface BtnStruct {
  type: string
  iconDisableUrl: string
  iconDefaultUrl: string
  iconActiveUrl: string
  iconTouchUrl: string
  iconDisableFontColor?: string
  iconDefaultFontColor?: string
  iconActiveFontColor?: string
  iconTouchFontColor?: string
  isDisable: boolean
  isActive: boolean
  iconText: Resource
  isShowKeyboard: boolean
}

const textMap: Record<string, Resource> = {
  'keyBoard': $r('app.string.keyBoard'),
  'hangUp': $r('app.string.hangUp'),
  'videoMute': $r('app.string.mute'),
  'speaker': $r('app.string.speaker'),
  'switchCamera': $r('app.string.switchCamera'),
  'switchToVoice': $r('app.string.switchToVoice'),
  'tureOffMyVideo': $r('app.string.turn_off_camera'),
};

@Component
export default struct VideoFuncBtnGroup {
  @State btnList: Array<BtnStruct> = [];
  @Link callData: DefaultCallData;
  @Link @Watch('updateBtnList') callList: Array<DefaultCallData>;
  @Link @Watch('updateBtnList') callListCount: number;
  @Link @Watch('updateBtnList') callId: number;
  @Link @Watch('updateBtnList') accountId: number;
  @Link @Watch('updateBtnList') callState: number;
  @Link @Watch('updateBtnList') videoState: number;
  @Link @Watch('cancel') hasMultiDevice: boolean;
  @StorageLink('isMute') @Watch('updateVideoMuteState') isMute: boolean = false;
  @StorageLink('speakerSelected') @Watch('updateAudioDeviceStatus') speakerSelected: boolean = false;
  @Link isShowKeyboard: boolean;
  private mCallServiceProxy?: CallServiceProxy;
  private mBtnGroupConfig = BtnGroupConfig;
  private mClone?: Clone;
  @Consume frontCameraId: string;
  @Consume backCameraId: string;
  @Consume currentCameraId: string;
  @Link isHidePanel: boolean;
  @State mBottomViewModel: BottomViewModel = BottomViewModel.getInstance();
  @Link @Watch('updateBtnList') showVideoRbt: boolean;
  @StorageProp('curBp') curBp: string = '';
  //audioDeviceList length maybe be 0 with bt and without bt.
  @StorageLink('audioDeviceList') audioDeviceList: AudioListItem[] = [];
  @StorageLink('SplitScreenType') @Watch('changeSpliteScreenType') splitScreenType: SplitScreenType =
    SplitScreenType.DEFAULT
  @Consume enableLight: boolean;
  @StorageLink('isNewFoldPhoneExternalScreen') @Watch('updateBtnList') isNewFoldPhoneExternalScreen: boolean = false;
  btnVideoClick: () => void = () => {
  };
  btnCameraClick: Function = () => {
  };
  @State deviceSwitchCount: number = 0;
  @StorageLink('windowStatus') windowStatus: window.WindowStatusType = window.WindowStatusType.UNDEFINED;
  @StorageLink('foldDisplayMode') foldDisplayMode: display.FoldDisplayMode =
    display.FoldDisplayMode.FOLD_DISPLAY_MODE_UNKNOWN;
  @StorageLink('isDistributeSink') isDistributeSink: boolean = false;

  @Builder
  selectDevice() {
    SelectDeviceContent({ dialogController: this.dialogController, switchCount : this.deviceSwitchCount });
  }

  dialogController?: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.select_device'),
      contentBuilder: () => {
        this.selectDevice();
      },
      contentAreaPadding: { left: $r('sys.float.padding_level0'), right: $r('sys.float.padding_level0') },
      buttons: [
        {
          value: $r('app.string.cancel'),
          action: () => {
            this.dialogController?.close();
            this.cancel();
          }
        }
      ]
    }),
    autoCancel: true,
    customStyle: false,
  })

  onAccept(itemDeviceType: call.AudioDeviceType, address: string) {
    let audioDevice: call.AudioDevice = {
      deviceType: 0, address: ' '
    };
    audioDevice.deviceType = itemDeviceType;
    audioDevice.address = address;
    LogUtils.i(TAG, 'onAccept device: ' + audioDeviceToString(audioDevice));
    AudioDeviceManager.getInstance().setAudioDevice(audioDevice);
  }

  cancel() {
    LogUtils.i(TAG, `cancel dialog:${!this.mBottomViewModel.isHaveMultiDevice}`);
    if (!this.mBottomViewModel.isHaveMultiDevice) {
      this.dialogController?.close();
    }
  }

  aboutToAppear() {
    this.mClone = Clone.getInstance();
    this.mCallServiceProxy = CallServiceProxy.getInstance();
    this.mBtnGroupConfig.videoBtnGroupList.forEach((v) => {
      v.iconText = textMap[v.type as string];
    });
    this.btnList = this.mClone.clone(this.mBtnGroupConfig.videoBtnGroupList);
    this.updateBtnList();
    this.changeSpliteScreenType();
  }

  aboutToDisappear() {
    LogUtils.i(TAG, 'aboutToDisappear');
    this.dialogController?.close();
    this.dialogController = undefined;
  }

  downgradeToVoice() {
    VideoCallManager.getInstance().modifyImsCallMode(this.callData, ImsCallMode.CALL_MODE_AUDIO_ONLY, updatedCall => {
      LogUtils.i(TAG, 'downgradeToVoice for callId ' + updatedCall.callId);
      updatedCall.videoState = VideoStateType.TYPE_VOICE;
      VideoCallManager.getInstance().controlCamera(updatedCall.callId, '');
      setPreviewWindowApi(updatedCall.callId, '');
      setDisplayWindowApi(updatedCall.callId, '');
    });
  }

  /**
   * Display the buttons of the button group
   *
   * @param {Object} obj - object
   */
  btnClick(obj: BtnStruct) {
    LogUtils.i(TAG, 'btnClick get icon type : ' + JSON.stringify(obj));
    this.btnVideoClick();
    const btnName = ['keyBoard', 'speaker', 'switchCamera', 'tureOffMyVideo'];
    const type = obj.type;

    switch (type) {
      case 'keyBoard':
        this.handelVideCallClickKeyBoard();
        break;
      case 'videoMute':
        this.muteHandle('videoMute');
        break;
      case 'tureOffMyVideo':
        this.tureOffMyVideo(obj);
        break;
      case 'switchToVoice':
        this.switchToVoice();
        break;
      case 'switchCamera':
        this.switchCamera(obj);
        this.btnCameraClick();
        break;
      case 'hangUp':
        this.handleVideoCallClickHangUp();
        break;
      case 'speaker':
        // open dialog if other audio device exist.
        if (this.mBottomViewModel.isHaveMultiDevice) {
          LogUtils.i(TAG, 'onSpeakerButtonClicked dialogController.open');
          this.dialogController?.open();
          return;
        } else {
          this.mBottomViewModel.setButtonAudioDevice(this.callId);
          this.dialogController?.close();
          ReportUtil.getInstance().reportVideoCallClickSpeaker(obj.isActive ? 0 : 1);
        }
      default:
        break;
    }
    if (Method.includes(btnName, type)) {
      this.btnList.forEach((item: BtnStruct) => {
        if (item.type === type && item.type !== 'speaker' && item.type !== 'keyBoard') {
          item.isActive = !item.isActive;
        }
      });
      this.btnList = JSON.parse(JSON.stringify(this.btnList));
    }
    if (type !== 'keyBoard' && !this.isShowKeyboard) {
      const clearPanelTimer = AppStorage.get('clearPanelTimer') as boolean;
      AppStorage.setOrCreate('clearPanelTimer', !clearPanelTimer);
    }
  }

  private handelVideCallClickKeyBoard() {
    this.isShowKeyboard = !this.isShowKeyboard;
    this.enableLight = false;
    this.isHidePanel = true;
    AppStorage.setOrCreate('isShowVideoKeyBoard', this.isShowKeyboard);
    ReportUtil.getInstance().reportVideoCallClickDTMF(this.isShowKeyboard ? 1 : 0);
  }

  private handleVideoCallClickHangUp() {
    CallServiceProxy.getInstance()?.hangUpCall(this.callId);
    if (this.callList.length === 1) {
      AppStorage.setOrCreate('hasBeenToFrontOrBackend', AppStorage.get('onPageShow'));
      AppStorage.setOrCreate('hangUp', true);
      ReportUtil.getInstance().reportVideoIncomingPageClickHangUp();
    }
  }

  private switchCamera(obj: BtnStruct) {
    this.frontCameraId = VideoCameraHelper.getInstance().frontCameraId;
    this.currentCameraId = !obj.isActive ? this.backCameraId : this.frontCameraId;
    AppStorage.setOrCreate('currentCameraState', this.currentCameraId);
    LogUtils.i(TAG, `btnClick currentCameraId: ${JSON.stringify(this.currentCameraId)}`);
    VideoCameraHelper.getInstance().saveVideoCameraInfo(this.callId, this.currentCameraId, false);
    VideoCallManager.getInstance().controlCamera(this.callId, this.currentCameraId);
    ReportUtil.getInstance().reportVideoCallSwitchCamera();
  }

  private switchToVoice() {
    if (isUpgradingToVideo(this.callData) && CallUtils.isCmccCall(this.accountId)) {
      LogUtils.i(TAG, 'switchToVoice cancel voiceToVideo.');
      cancelCallUpgradeApi(this.callId);
    }
    //switch to audio call mode.
    this.downgradeToVoice();
    // reset camera data when videoToVoice.
    LogUtils.i(TAG, 'btnClick switchToVoice clearCameraInfo data.');
    VideoCameraHelper.getInstance().clearVideoCameraInfo();
    VideoCameraHelper.getInstance().updateCameraStatus(VideoCameraHelper.CAMERA_STATE_INVALID);
    AppStorage.setOrCreate('peerScreenAspectRatio', -1);
    ReportUtil.getInstance().reportVideoToVoice();
  }

  private tureOffMyVideo(obj: BtnStruct) {
    let cameraStatus = obj.isActive ?
    VideoCameraHelper.CAMERA_STATE_OPEN :
    VideoCameraHelper.CAMERA_STATE_MANUAL_CLOSED;
    VideoCameraHelper.getInstance().updateCameraStatus(cameraStatus);
    VideoCameraHelper.getInstance().saveVideoCameraInfo(this.callId, this.currentCameraId, !obj.isActive);
    LogUtils.i(TAG, `btnClick tureOffMyVideo isCameraOpen: ${obj.isActive}`);

    const switchCamera = this.btnList.find((val) => val.type === 'switchCamera');
    if (switchCamera) {
      switchCamera.isDisable = !obj.isActive;
      const iconDisableUrl = `${switchCamera.isActive ? switchCamera.iconActiveUrl : switchCamera.iconDefaultUrl}`;
      switchCamera.iconDisableUrl = iconDisableUrl;
    }
    ReportUtil.getInstance().reportVideoCallClickLocalCamera(obj.isActive ? 0 : 1);
  }

  private updateAudioDeviceStatus() {
    this.btnList[3].isActive = this.speakerSelected;
    this.btnList = JSON.parse(JSON.stringify(this.btnList));
  }

  private updateVideoMuteState() {
    this.btnList[2].isActive = this.isMute;
    this.btnList = JSON.parse(JSON.stringify(this.btnList));
  }

  private changeSpliteScreenType() {
    LogUtils.i(TAG, 'changeSpliteScreenType ' + this.btnList[0].type)
    if (!SplitScreenManager.getInstance().callBottomKeyboardBtnEnable(this.splitScreenType)) {
      this.btnList[0].isDisable = true;
      if (this.isShowKeyboard) {
        this.handelVideCallClickKeyBoard();
      }
    } else {
      this.btnList[0].isDisable = false;
    }
    this.btnList = JSON.parse(JSON.stringify(this.btnList));
  }

  updateBtnList() {
    const btnName = ['videoMute', 'switchToVoice', 'tureOffMyVideo'];
    let videoCameraInfo: VideoCameraStatus | undefined = VideoCameraHelper.getInstance().getVideCameraInfo();
    if (this.isNewFoldPhoneExternalScreen) {
      this.btnList =
        this.mClone?.clone(this.mBtnGroupConfig.videoBtnGroupList.filter(item => item.type !== 'switchCamera'));
    } else {
      this.btnList = this.mClone?.clone(this.mBtnGroupConfig.videoBtnGroupList);
    }
    this.btnList.forEach((item: BtnStruct) => {
      if (Method.includes(btnName, item.type)) {
        item.isDisable = !(this.callState === callStateConst.CALL_STATUS_ACTIVE) ||
          (isUpgradingToVideo(this.callData) && !CallUtils.isCmccCall(this.accountId));
        if (item.type == 'videoMute') {
          LogUtils.i(TAG, 'updateBtnList mute = ' + this.isMute);
          item.isDisable = this.callState === callStateConst.CALL_STATUS_HOLDING;
          item.isActive = this.isMute;
        }
      }
      if (item.type === 'speaker') {
        item.isActive = this.speakerSelected;
      }
      if (item.type === 'keyBoard' &&
        !SplitScreenManager.getInstance().callBottomKeyboardBtnEnable(this.splitScreenType)) {
        // 分屏状态时,DTMF键盘需要禁用
        item.isDisable = true;
      }
      // init speaker state and listen audio change and update audio.
      if (this.callId === videoCameraInfo?.callId) {
        switch (item.type) {
          case 'tureOffMyVideo':
            if (this.videoState === VideoStateType.TYPE_VIDEO_RECEIVE_ONLY) {
              item.isActive = false;
            } else {
              item.isActive = videoCameraInfo.isCameraClose;
            }
            item.isDisable = item.isDisable || this.videoState === VideoStateType.TYPE_VIDEO_RECEIVE_ONLY;
            break;
          case 'switchCamera':
            if (videoCameraInfo.isCameraClose || this.showVideoRbt) {
              item.isDisable = true;
            } else {
              // crs will disable switchcamera, we need enable it.
              if (item.isDisable) {
                item.isDisable = false;
              }
            }
            if (videoCameraInfo.currentCameraId == this.frontCameraId) {
              item.isActive = false;
              this.currentCameraId = this.frontCameraId;
            } else if (videoCameraInfo.currentCameraId == this.backCameraId) {
              item.isActive = true;
              this.currentCameraId = this.backCameraId;
            } else {
              item.isActive = false;
              this.currentCameraId = this.frontCameraId;
            }
            item.isDisable = item.isDisable || this.videoState === VideoStateType.TYPE_VIDEO_RECEIVE_ONLY;
          default:
            break;
        }
      }
    });
    this.btnList = JSON.parse(JSON.stringify(this.btnList));
  }

  /**
   * Call hold mute
   *
   * @param {string} type - Click the hold button
   */
  muteHandle(type: string) {
    const awaitIsActive = this.btnList.find((v: BtnStruct) => v.type === type)?.isActive;
    LogUtils.i(TAG, 'mute Handle awaitIsActive : ' + awaitIsActive);
    !awaitIsActive ? this.mCallServiceProxy?.setMuted() : this.mCallServiceProxy?.cancelMuted();
    ReportUtil.getInstance().reportVideoCallClickMute(!awaitIsActive ? 1 : 0);
  }

  /**
   * Clear timer
   */
  onDestroy() {
    LogUtils.i(TAG, 'onDestroy');
  }

  getVideoFuncBtnRowsGap(isNewFoldPhoneExternalScreen: boolean): number {
    if (isNewFoldPhoneExternalScreen) {
      return this.isShowKeyboard || this.isHidePanel ? 0 : 16;
    }
    let splitRowsGap = SplitScreenManager.getInstance().getVideoFuncBtnRowsGap(this.splitScreenType);
    if (splitRowsGap > 0) {
      return splitRowsGap;
    }
    return this.isShowKeyboard || this.isHidePanel ? 0 : 24;
  }

  checkNewCallValid() {
    const foldModeValid = this.foldDisplayMode !== display.FoldDisplayMode.FOLD_DISPLAY_MODE_SUB;
    const windowStatusValid = this.windowStatus !== window.WindowStatusType.FLOATING &&
      this.windowStatus !== window.WindowStatusType.SPLIT_SCREEN;
    return foldModeValid && windowStatusValid && !this.isDistributeSink;
  }

  build() {
    GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 } }) {
      GridCol({ span: { xs: 2, sm: 4, md: 8, lg: 12 }, offset: { md: 0, lg: 0 } }) {
        Grid() {
          ForEach(this.btnList, (item: BtnStruct, index: number) => {
            GridItem() {
              VideoFuncBtn({
                btnType: item.type,
                isDisable: item.isDisable,
                isActive: item.isActive,
                iconText: item.iconText,
                iconDisableUrl: item.iconDisableUrl,
                iconDefaultUrl: item.iconDefaultUrl,
                iconActiveUrl: item.iconActiveUrl,
                iconTouchUrl: item.iconTouchUrl,
                iconDisableFontColor: item.iconDisableFontColor,
                iconDefaultFontColor: item.iconDefaultFontColor,
                iconActiveFontColor: item.iconActiveFontColor,
                iconTouchFontColor: item.iconTouchFontColor,
                isShowKeyboard: this.isShowKeyboard,
                hasMultiDevice: $hasMultiDevice,
                btnClick: () => {
                  this.btnClick(item);
                }
              })
            }
            .visibility((((this.isShowKeyboard || this.isHidePanel) && index > 3)) ?
            Visibility.None : Visibility.Visible)
          })
        }
        .clip(false)
        .height((this.isShowKeyboard || this.isHidePanel) ? (this.isNewFoldPhoneExternalScreen ? 68 : 76) : 176)
        .columnsGap(this.isNewFoldPhoneExternalScreen ? 8 : 4)
        .rowsGap(this.getVideoFuncBtnRowsGap(this.isNewFoldPhoneExternalScreen))
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .scrollBar(BarState.Off)
      }
    }
    .margin({ left: $r('sys.float.padding_level8'), right: $r('sys.float.padding_level8') })
  }
}
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

import LogUtils from '../../common/utils/LogUtils';
import call from '@ohos.telephony.call';
import AudioDeviceType, { audioDeviceInfoToString, audioDeviceToString } from './AudioDeviceType';
import BottomViewModel from '../../viewmodel/BottomViewModel';
import FunctionBtnVM from '../../viewmodel/FunctonBtnVIewModel';
import * as DeviceTypeConst from '../../common/constant/DeviceTypeConst';
import Method from '../../common/utils/Method';
import hiTraceMeter from '@ohos.hiTraceMeter';
import { BusinessError } from '@ohos.base';
import { audioObj } from './AudioDeviceType';
import CallDataManager from '../CallDataManager';
import CallStateConst from '../../common/constant/CallStateConst';
import CallManagerService from '../../ServiceAbility/CallManagerService';
import { ExternalCallModel } from '../ExternalCallModel';
import { ReportUtil } from '../../common/utils/ReportUtils/ReportUtil';
import CallTypeConst from '../../common/constant/CallTypeConst';
import DefaultCallData from '../../common/struct/TypeUtils';
import { isVideoCall, getForegroundCall } from '../../common/utils/CallListHelper';
import data from '@ohos.telephony.data';
import Clone from '../../common/utils/Clone';
import { ProximityUtils } from '../../common/utils/ProximityUtils';
import { PrivacyEnhancedCallManager } from '../PrivacyEnhancedCallManager';

const TAG = 'AudioDeviceManager';

export default class AudioDeviceManager {
  public audioDevice: call.AudioDevice = {
    deviceType: DeviceTypeConst.DEVICE_EARPIECE,
    address: ''
  };
  public audioDeviceInfo: audioObj = AudioDeviceType.audioDeviceType;
  public mBottomViewModel: BottomViewModel = BottomViewModel.getInstance();
  public mFunctionBtnVM: FunctionBtnVM = FunctionBtnVM.getInstance();
  private static sAudioDeviceManager: AudioDeviceManager;

  public static getInstance(): AudioDeviceManager {
    if (!AudioDeviceManager.sAudioDeviceManager) {
      AudioDeviceManager.sAudioDeviceManager = new AudioDeviceManager()
    }
    return AudioDeviceManager.sAudioDeviceManager;
  }

  /**
   * audio channel switch
   *
   * @param {number} device - device type
   *
   * @return {Promise} promise object
   */
  public setAudioDevice = (audioList: call.AudioDevice = this.audioDevice) =>
    new Promise((resolve: (value: void) => void, reject: (reason?: BusinessError) => void) => {
    hiTraceMeter.startTrace('onSpeakerButtonClicked', 1005);
    LogUtils.i(TAG, `setAudio, audio: ${audioDeviceToString(audioList)}`);
    call.setAudioDevice(audioList).then((res: void) => {
      LogUtils.i(TAG, 'then:setAudio : ' + audioDeviceToString(audioList));
      resolve(res);
    }).catch((err: BusinessError) => {
      reject(err);
      LogUtils.e(TAG, `catch:setAudio ${err?.code}`);
    });
  });

  /**
   * register call audioDeviceChange callback
   *
   * @param { Function } callBack - inject an Function
   */
  public registerAudioDeviceChange(callBack: Function) {
    LogUtils.i(TAG, 'registerAudioDeviceChange')
    try {
      call.on('audioDeviceChange', (data: call.AudioDeviceCallbackInfo) => {
        if (!data) {
          LogUtils.i(TAG, 'audioDeviceChange AudioDeviceCallbackInfo is null')
          return;
        }
        LogUtils.i(TAG, 'audioDeviceChange AudioDeviceCallbackInfo: ' + audioDeviceInfoToString(data));
        hiTraceMeter.finishTrace('registerAudioDeviceChange', 1005);
        callBack(data);
      });
    } catch (err) {
      LogUtils.e(TAG, 'registerAudioDeviceChange err: ' + JSON.stringify(err));
    }
  }

  /**
   * onRegister call audioDeviceChange callback
   */
  public unRegisterAudioChange() {
    try {
      call.off('audioDeviceChange', (data: call.AudioDeviceCallbackInfo) => {
        if (!data) {
          LogUtils.i(TAG, 'call.off unRegisterAudioChange failed');
          return;
        }
        LogUtils.i(TAG, 'call.off unRegisterAudioChange success');
      });
    } catch (err) {
      LogUtils.e(TAG, 'call.off unRegisterAudioChange err: ' + JSON.stringify(err));
    }
  }

  public updateAudioDevice(audioDeviceInfo: audioObj) {
    this.changeAudioDeviceInfo(audioDeviceInfo);
  }

  public updateAudioDeviceInfo(audioDeviceInfo: audioObj) {
    if (JSON.stringify(audioDeviceInfo) === JSON.stringify(this.audioDeviceInfo)) {
      LogUtils.w(TAG, 'Audio status not changed')
      return;
    }

    let callData = this.getVoipCallForAudioChanged(audioDeviceInfo);

    if (callData) {
      AppStorage.setOrCreate('isVoipMute', audioDeviceInfo.isMuted);
    } else {
      AppStorage.setOrCreate('isMute', audioDeviceInfo.isMuted);
      callData = CallDataManager.getInstance().getForegroundLiveCall();
      audioDeviceInfo.isMuted ? ReportUtil.getInstance().stopPrivacyPermission() :
        ReportUtil.getInstance().reportPrivacyIndicator();
    }
    const btnName = [
      DeviceTypeConst.DEVICE_BLUETOOTH_SCO,
      DeviceTypeConst.DEVICE_DISTRIBUTED_AUTOMOTIVE,
      DeviceTypeConst.DEVICE_DISTRIBUTED_PHONE,
      DeviceTypeConst.DEVICE_DISTRIBUTED_PAD,
      DeviceTypeConst.DEVICE_DISTRIBUTED_XINGSHAN,
      DeviceTypeConst.DEVICE_BLUETOOTH_HEARINGAID
    ];
    let isHaveMultiDevice = false;
    audioDeviceInfo.audioDeviceList.forEach((item: call.AudioDevice) => {
      if (Method.includes(btnName, (item.deviceType))) {
        isHaveMultiDevice = true;
        return;
      }
    });
    LogUtils.i(TAG, 'updateAudioDeviceInfo isHaveMultiDevice = ' + isHaveMultiDevice);
    PrivacyEnhancedCallManager.getInstance().updateCurrentAudioDevice(audioDeviceInfo.currentAudioDevice);
    BottomViewModel.getInstance().initCurrentAudioDevice(audioDeviceInfo.currentAudioDevice, isHaveMultiDevice);
    BottomViewModel.getInstance().initDataList(audioDeviceInfo.audioDeviceList, isHaveMultiDevice);
    this.audioDeviceInfo = audioDeviceInfo;
    ExternalCallModel.getInstance().checkAndOpenSpeaker();
    ProximityUtils.updateProximityLock()
    
    if (callData && ((callData.callState === CallStateConst.CALL_STATUS_DIALING) ||
      (callData.callState === CallStateConst.CALL_STATUS_ALERTING) ||
      (callData.callState === CallStateConst.CALL_STATUS_ACTIVE))) {
      if (callData.callType === CallStateConst.TYPE_VOIP) {
        CallManagerService.getInstance().updateAudioForVoipCall(callData);
      } else {
        CallDataManager.getInstance().sendNotification(callData);
      }
    }
  }

  private changeAudioDeviceInfo(audioDeviceInfo:audioObj) {
    const audioDeviceChangeInfo: audioObj = Clone.getInstance().clone(audioDeviceInfo);
    LogUtils.i(TAG, `audioDeviceListLen:${audioDeviceChangeInfo.audioDeviceList.length}`);
    this.updateAudioDeviceInfo(audioDeviceChangeInfo);
  }

  private getVoipCallForAudioChanged(audioDeviceInfo: audioObj): DefaultCallData | undefined {
    if (audioDeviceInfo.callId && audioDeviceInfo.callId > 0) {
      let callData = CallManagerService.getInstance().getCallDataByCallId(audioDeviceInfo.callId);
      if (callData && callData.callType === CallStateConst.TYPE_VOIP) {
        return callData;
      }
    }
    return undefined;
  }

  public isCurEarpiece(): boolean {
    return this.audioDeviceInfo.currentAudioDevice.deviceType === DeviceTypeConst.DEVICE_EARPIECE;
  }

  public isCurSpeaker(): boolean {
    LogUtils.i(TAG, 'ExternalCallModel isCurSpeaker cur:' + audioDeviceToString(this.audioDeviceInfo.currentAudioDevice));
    return this.audioDeviceInfo.currentAudioDevice.deviceType === DeviceTypeConst.DEVICE_SPEAKER;
  }

  public isExternalAudioDeviceSupport(): boolean {
    const btnName = [
      DeviceTypeConst.DEVICE_WIRED_HEADSET,
      DeviceTypeConst.DEVICE_BLUETOOTH_SCO,
      DeviceTypeConst.DEVICE_DISTRIBUTED_AUTOMOTIVE,
      DeviceTypeConst.DEVICE_DISTRIBUTED_PHONE,
      DeviceTypeConst.DEVICE_DISTRIBUTED_PAD
    ];
    let isHaveExternalDevice: boolean = false;
    this.audioDeviceInfo.audioDeviceList.forEach((item: call.AudioDevice) => {
      if (Method.includes(btnName, (item.deviceType))) {
        LogUtils.i(TAG, `have ExternalDevice:${JSON.stringify(item)}`);
        isHaveExternalDevice = true;
        return;
      }
    });
    return isHaveExternalDevice;
  }

  /**
   * Wired headset or sco type
   *
   * @param deviceType
   * @returns true Wired headset or sco type
   */
  public isHeadsetOrSco(deviceType: number): boolean {
    return deviceType === DeviceTypeConst.DEVICE_WIRED_HEADSET || deviceType === DeviceTypeConst.DEVICE_BLUETOOTH_SCO;
  }

  release() {
    this.audioDeviceInfo = AudioDeviceType.audioDeviceType;
  }
}
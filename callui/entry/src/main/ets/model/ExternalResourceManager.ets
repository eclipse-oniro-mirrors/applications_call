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

import DefaultCallData from '../common/struct/TypeUtils';
import LogUtils from '../common/utils/LogUtils';
import * as Constants from '../common/utils/Constants';
import {
  isIncomingCall,
  isVideoCall,
  isActiveCall
} from '../common/utils/CallListHelper';
import { HashMap } from '@kit.ArkTS';
import ImagePathConst from '../common/constant/ImagePathConst';
import BottomViewModel from '../viewmodel/BottomViewModel';
import CallDataManager from './CallDataManager';
import { image } from '@kit.ImageKit';

const TAG = 'ExternalResourceManager';

export interface ExternalIconResource {
  iconRes: Resource,
  iconColor: string,
  isClickable: boolean,
  opacity: number,
  id: number
}

export enum IconTypes {
  MUTE_RINGER,
  REJECT,
  HANGUP,
  CS_ANSWER,
  VIDEO_ANSWER,
  SET_MUTE_GREY,
  CANCEL_MUTE_GREY,
  SET_MUTE_WHITE,
  CANCEL_MUTE_WHITE,
  AUDIO_DEVICE_GREY,
  AUDIO_DEVICE_WHITE
}

export default class ExternalResourceManager {
  private static sInstance: ExternalResourceManager;
  private mExternalIconResourceMap: HashMap<number, ExternalIconResource> = new HashMap();

  constructor() {
    this.initLeftResource();
    this.initRightResource();
    this.initBottomResource();
    this.updateMultiDeviceStatus();
  }

  private updateMultiDeviceStatus() {
    let bottomVM: BottomViewModel = BottomViewModel.getInstance();
    AppStorage.setOrCreate(Constants.IS_MULTI_DEVICE, bottomVM.getMultiDeviceState());
    bottomVM.addMultiDeviceListener((bol: boolean) => {
      AppStorage.setOrCreate(Constants.IS_MULTI_DEVICE, bol);
    });
  }

  private initLeftResource() {
    this.mExternalIconResourceMap.set(IconTypes.REJECT, {
      iconRes: $r('sys.symbol.phone_down_fill'),
      iconColor: '#E84026',
      isClickable: false,
      opacity: 1,
      id: IconTypes.REJECT
    });
    this.mExternalIconResourceMap.set(IconTypes.SET_MUTE_GREY, {
      iconRes: $r('sys.symbol.mic_fill'),
      iconColor: '#FFFFFF',
      isClickable: false,
      opacity: 0.4,
      id: IconTypes.SET_MUTE_GREY
    });
    this.mExternalIconResourceMap.set(IconTypes.CANCEL_MUTE_GREY, {
      iconRes: $r('sys.symbol.mic_slash_fill'),
      iconColor: '#FFFFFF',
      isClickable: false,
      opacity: 0.4,
      id: IconTypes.CANCEL_MUTE_GREY
    });
    this.mExternalIconResourceMap.set(IconTypes.SET_MUTE_WHITE, {
      iconRes: $r('sys.symbol.mic_fill'),
      iconColor: '#FFFFFF',
      isClickable: true,
      opacity: 1,
      id: IconTypes.SET_MUTE_WHITE
    });
    this.mExternalIconResourceMap.set(IconTypes.CANCEL_MUTE_WHITE, {
      iconRes: $r('sys.symbol.mic_slash_fill'),
      iconColor: '#FFFFFF',
      isClickable: true,
      opacity: 1,
      id: IconTypes.CANCEL_MUTE_WHITE
    });
  }

  private initRightResource() {
    this.mExternalIconResourceMap.set(IconTypes.CS_ANSWER, {
      iconRes: $r('sys.symbol.phone_fill'),
      iconColor: '#64BB5C',
      isClickable: false,
      opacity: 1,
      id: IconTypes.CS_ANSWER
    });
    this.mExternalIconResourceMap.set(IconTypes.VIDEO_ANSWER, {
      iconRes: $r('sys.symbol.video_fill'),
      iconColor: '#64BB5C',
      isClickable: false,
      opacity: 1,
      id: IconTypes.VIDEO_ANSWER
    });
    this.mExternalIconResourceMap.set(IconTypes.AUDIO_DEVICE_GREY, {
      iconRes: this.getCurrentAudioRes(),
      iconColor: '#FFFFFF',
      isClickable: false,
      opacity: 0.4,
      id: IconTypes.AUDIO_DEVICE_GREY
    });
    this.mExternalIconResourceMap.set(IconTypes.AUDIO_DEVICE_WHITE, {
      iconRes: this.getCurrentAudioRes(),
      iconColor: '#FFFFFF',
      isClickable: true,
      opacity: 1,
      id: IconTypes.AUDIO_DEVICE_WHITE
    });
  }

  private initBottomResource() {
    this.mExternalIconResourceMap.set(IconTypes.MUTE_RINGER, {
      iconRes: $r('sys.symbol.speaker_slash_fill'),
      iconColor: '#FFFFFF',
      isClickable: false,
      opacity: 1,
      id: IconTypes.MUTE_RINGER
    });
    this.mExternalIconResourceMap.set(IconTypes.HANGUP, {
      iconRes: $r('sys.symbol.phone_down_fill'),
      iconColor: '#E84026',
      isClickable: false,
      opacity: 1,
      id: IconTypes.HANGUP
    });
  }

  /**
   * Get ExternalResourceManager object
   *
   * @return { Object } ExternalResourceManager
   */
  public static getInstance(): ExternalResourceManager {
    if (ExternalResourceManager.sInstance == null) {
      ExternalResourceManager.sInstance = new ExternalResourceManager();
    }
    return ExternalResourceManager.sInstance;
  }

  /**
   * Update external audio icon when audio device change
   */
  public updateAudioDeviceIcon() {
    let oldResId = this.mExternalIconResourceMap.get(IconTypes.AUDIO_DEVICE_GREY)?.id;
    let curResId = this.getCurrentAudioRes()?.id;
    if (oldResId === curResId) {
      LogUtils.i(TAG, 'updateAudioDeviceIcon id not change');
      return;
    }
    this.mExternalIconResourceMap.set(IconTypes.AUDIO_DEVICE_GREY, {
      iconRes: this.getCurrentAudioRes(),
      iconColor: '#FFFFFF',
      isClickable: false,
      opacity: 0.4,
      id: IconTypes.AUDIO_DEVICE_GREY
    });
    this.mExternalIconResourceMap.set(IconTypes.AUDIO_DEVICE_WHITE, {
      iconRes: this.getCurrentAudioRes(),
      iconColor: '#FFFFFF',
      isClickable: true,
      opacity: 1,
      id: IconTypes.AUDIO_DEVICE_WHITE
    });
    this.updateExternalRightIcon();
  }

  private getCurrentAudioRes(): Resource {
    let curAudioIconRes = AppStorage.get('currentAudioDeviceIcon') as Resource;
    if (curAudioIconRes.id === $r('sys.symbol.ear').id) {
      LogUtils.i(TAG, 'getCurrentAudioRes is ear, change to speaker');
      return $r('sys.symbol.speaker_wave_3_fill');
    } else {
      return curAudioIconRes;
    }
  }

  /**
   * Update external icons
   */
  public updateExternalIcon(): void {
    this.updateExternalLeftIcon();
    this.updateExternalRightIcon();
    this.updateExternalBottomIcon();
  }

  private updateExternalLeftIcon(): void {
    let callData: DefaultCallData = AppStorage.get(Constants.CALL_DATA) as DefaultCallData;
    let isMute: boolean = AppStorage.get('isMute') as boolean;
    let isIncoming: boolean = isIncomingCall(callData.callState);
    let isActive: boolean = isActiveCall(callData.callState);
    let leftIconRes: ExternalIconResource;
    if (isIncoming) {
      leftIconRes = this.mExternalIconResourceMap.get(IconTypes.REJECT);
    } else if (isActive && isMute) {
      leftIconRes = this.mExternalIconResourceMap.get(IconTypes.CANCEL_MUTE_WHITE);
    } else if (isActive && !isMute) {
      leftIconRes = this.mExternalIconResourceMap.get(IconTypes.SET_MUTE_WHITE);
    } else if (!isActive && isMute) {
      leftIconRes = this.mExternalIconResourceMap.get(IconTypes.CANCEL_MUTE_GREY);
    } else {
      leftIconRes = this.mExternalIconResourceMap.get(IconTypes.SET_MUTE_GREY);
    }
    AppStorage.setOrCreate(Constants.EXTERNAL_LEFT_ICON, leftIconRes);
  }

  private updateExternalRightIcon(): void {
    let callData: DefaultCallData = AppStorage.get(Constants.CALL_DATA) as DefaultCallData;
    let rightIconRes: ExternalIconResource;
    let isIncoming: boolean = isIncomingCall(callData.callState);
    let isActive: boolean = isActiveCall(callData.callState);
    let isVideo: boolean = isVideoCall(callData.videoState);
    if (isIncoming && isVideo) {
      rightIconRes = this.mExternalIconResourceMap.get(IconTypes.VIDEO_ANSWER);
    } else if (isIncoming && !isVideo) {
      rightIconRes = this.mExternalIconResourceMap.get(IconTypes.CS_ANSWER);
    } else if (isActive) {
      rightIconRes = this.mExternalIconResourceMap.get(IconTypes.AUDIO_DEVICE_WHITE);
    } else {
      rightIconRes = this.mExternalIconResourceMap.get(IconTypes.AUDIO_DEVICE_GREY);
    }
    AppStorage.setOrCreate(Constants.EXTERNAL_RIGHT_ICON, rightIconRes);
  }

  private updateExternalBottomIcon(): void {
    let callData: DefaultCallData = AppStorage.get(Constants.CALL_DATA) as DefaultCallData;
    let bottomIconRes: ExternalIconResource;
    let isIncoming: boolean = isIncomingCall(callData.callState);
    let isVideo: boolean = isVideoCall(callData.videoState);
    if (isIncoming && isVideo) {
      bottomIconRes = this.mExternalIconResourceMap.get(IconTypes.CS_ANSWER);
    } else if (isIncoming && !isVideo) {
      bottomIconRes = this.mExternalIconResourceMap.get(IconTypes.MUTE_RINGER);
    } else {
      bottomIconRes = this.mExternalIconResourceMap.get(IconTypes.HANGUP);
    }
    AppStorage.setOrCreate(Constants.EXTERNAL_BOTTOM_ICON, bottomIconRes);
  }
}

/**
 * Get contact image
 *
 * @param isConferenceMode
 * @returns contact image resource
 */
export function getContactImage(isConferenceMode: boolean): Resource | null | image.PixelMap | undefined {
  let contactImage: Resource | null | image.PixelMap | undefined = $r('app.media.ic_user_40_40dark');
  if (isConferenceMode) {
    return contactImage;
  }
  let callData: DefaultCallData = AppStorage.get(Constants.CALL_DATA) as DefaultCallData;
  let callList = CallDataManager.getInstance().callList;
  let index = callList.findIndex((v: DefaultCallData) =>
  v.callId === callData.callId);
  if (index >= 0 && index < callList.length && callList[index].contactAvatar) {
    contactImage = callList[index].contactAvatar;
  }
  return contactImage;
}
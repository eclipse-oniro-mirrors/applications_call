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

import LogUtils from '../common/utils/LogUtils';
import { AudioListItem, DeviceItemStyle, initDeviceItemStyleMap } from '../model/audio/AudioListItem';
import * as DeviceTypeConst from '../common/constant/DeviceTypeConst';
import AudioDeviceManager from '../model/audio/AudioDeviceManager';
import Method from '../common/utils/Method';
import BaseViewModel from './base/BaseViewModel';
import call from '@ohos.telephony.call';
import CallServiceProxy from '../model/CallServiceProxy';
import * as Constants from '../common/utils/Constants';
import { DefaultDistributeDeviceAddressData } from '../common/struct/TypeUtils';
import HashMap from '@ohos.util.HashMap';
import BannerNotificationManager from '../model/BannerNotificationManager';
import CallStateConst from '../common/constant/CallStateConst';
import { ReportUtil } from '../common/utils/ReportUtils/ReportUtil';
import { NumberMarkManager } from '../model/NumberMarkService';
import CallDataManager from '../model/CallDataManager';
import Utils from '../common/utils/utils';
import { SymbolIconUtil } from '../common/utils/SymbolIconUtil';
import { AudioDevice } from '../model/audio/AudioDeviceType';
import { removeWindowListener, terminateSelf } from '../model/TerminateManager';
import { BusinessError } from '@kit.BasicServicesKit';
import { ProximityUtils } from '../common/utils/ProximityUtils';
import { AccessibilityUtil } from '../common/utils/AccessiblityUtil';
import { StringUtil } from '../common/utils/StringUtil';

const TAG = 'BottomViewModel';

export default class BottomViewModel extends BaseViewModel<BottomViewModel> {
  public dataList: AudioListItem[] = [];
  public audioDeviceList: Array<AudioDevice> = [];
  public currentAudioDevice: AudioDevice = new AudioDevice();
  public isHaveMultiDevice: boolean = false;
  public currentAudioIcon: Resource = $r('sys.symbol.ear');
  public audioIconStyle: Resource = $r('app.color.white');
  public speakerSelected: boolean = false;
  private static sBottomViewModel: BottomViewModel;
  private currentHeadset = DeviceTypeConst.DEVICE_EARPIECE;
  private callbacks: Function[] = [];
  private mAudioDevice: call.AudioDevice = {
    deviceType: 0, address: ' '
  };
  public multiDeviceState: ((arg: boolean) => void)[] = [];
  public isCurEarpieceState: ((arg: boolean) => void)[] = [];
  public deviceItemStyleMap: HashMap<number, DeviceItemStyle> = new HashMap();

  public static getInstance(): BottomViewModel {
    if (!BottomViewModel.sBottomViewModel) {
      BottomViewModel.sBottomViewModel = new BottomViewModel();
    }
    return BottomViewModel.sBottomViewModel;
  }

  initDataList(audioDeviceList: AudioDevice[], isHaveMultiDevice: boolean): void {
    this.audioDeviceList = audioDeviceList;
    AppStorage.setOrCreate('audioDeviceList', audioDeviceList);
    if (this.multiDeviceState.length > 0) {
      this.multiDeviceState.forEach((func: (arg: boolean) => void) => {
        func(isHaveMultiDevice);
      });
    }
    this.isHaveMultiDevice = isHaveMultiDevice;
    const btnNameHeadSet = [DeviceTypeConst.DEVICE_WIRED_HEADSET];
    let deviceheadset = DeviceTypeConst.DEVICE_EARPIECE;

    this.audioDeviceList.forEach((item) => {
      if (Method.includes(btnNameHeadSet, (item.deviceType))) {
        deviceheadset = DeviceTypeConst.DEVICE_WIRED_HEADSET;
        return;
      }
    });

    this.currentHeadset = deviceheadset;

    if (isHaveMultiDevice) {
      this.updateMultiDevice();
      this.updateImageAudio(isHaveMultiDevice);
    }
  }

  initCurrentAudioDevice(currentAudioDevice: AudioDevice, isHaveMultiDevice: boolean): void {
    this.currentAudioDevice = currentAudioDevice;
    Method.assign(this.currentAudioDevice, currentAudioDevice);
    LogUtils.i(TAG, `initCurrentAudioDevice: {name:${currentAudioDevice.deviceName} type:${currentAudioDevice.deviceType}}`);
    this.updateImageAudio(isHaveMultiDevice);
    if (this.isCurEarpieceState.length > 0) {
      this.isCurEarpieceState.forEach((func: (arg: boolean) => void) => {
        func(currentAudioDevice.deviceType === DeviceTypeConst.DEVICE_EARPIECE);
      });
    }
  }

  addMultiDeviceListener(fn: (arg: boolean) => void): void {
    this.multiDeviceState.push(fn);
  }

  addIsCurEarpieceListener(fn: (arg: boolean) => void): void {
    this.isCurEarpieceState.push(fn);
  }

  removeIsCurEarpieceListener(fn: (arg: boolean) => void): void {
    const index = this.isCurEarpieceState.indexOf(fn);
    if (index !== -1) {
      this.isCurEarpieceState.splice(index, 1);
    }
  }

  removeMultiDeviceListener(): void {
    this.multiDeviceState = [];
    this.dataList = [];
    this.audioDeviceList = [];
    this.callbacks = [];
    this.deviceItemStyleMap.clear();
  }

  getMultiDeviceState(): boolean {
    return this.isHaveMultiDevice;
  }

  updateImageAudio(isHaveMultiDevice: boolean): void {
    this.isHaveMultiDevice = isHaveMultiDevice;
    if (isHaveMultiDevice) {
      LogUtils.i(TAG, 'updateImageAudio dataList length:' + this.dataList?.length);
      this.dataList.forEach((item) => {
        let deviceType: number = item.deviceType;
        if (deviceType === this.currentAudioDevice.deviceType) {
          if ((this.isDistributeDevice(deviceType) || deviceType === DeviceTypeConst.DEVICE_BLUETOOTH_SCO) &&
            item.address !== this.currentAudioDevice.address) {
            LogUtils.i(TAG, 'is Not Distributed Device or address not same, return');
            return;
          }
          // 星闪设备deviceType相同，address不同
          if (deviceType === DeviceTypeConst.DEVICE_DISTRIBUTED_XINGSHAN &&
            item.address !== this.currentAudioDevice.address) {
            LogUtils.i(TAG, 'is XINGSHAN Device or address not same, return');
            return;
          }
          this.currentAudioIcon = item.selectedIcon;
          item.isCheck = true;
        }
      });
      this.speakerSelected = true;
      this.audioIconStyle = $r('sys.color.icon_primary');
    } else {
      this.updateButtonIcon();
    }
    AppStorage.setOrCreate('currentAudioDeviceIcon', this.currentAudioIcon);
    LogUtils.i(TAG, `speakerSelected: ${this.speakerSelected}`);
    AppStorage.setOrCreate('speakerSelected', this.speakerSelected);
    this.callbacks.forEach((fn) => {
      fn(this.currentAudioIcon, this.audioIconStyle);
    });
    LogUtils.i(TAG, `updateImageAudio update currentAudioIcon: {id:${this.currentAudioIcon.id} type:${this.currentAudioIcon.type}}`);
  }

  setAudioListItemData(item: AudioDevice, earIcon: Resource, audioListItem: AudioListItem): void {
    audioListItem.audioIcon = earIcon;
    audioListItem.selectedIcon = earIcon;
    audioListItem.audioTitle = item.deviceName;
    audioListItem.isCheck = this.currentAudioDevice.deviceType === item.deviceType &&
      this.currentAudioDevice.address === item.address;
  }

  updateMultiDevice(): void {
    let deviceItemStyleMap: HashMap<number, DeviceItemStyle> = initDeviceItemStyleMap();
    this.dataList.splice(0, this.dataList.length);
    this.audioDeviceList.forEach((item) => {
      let audioListItem: AudioListItem = new AudioListItem();
      let deviceType: number = item.deviceType;
      let address = item.address;
      let deviceName = item.deviceName;
      let itemStyle: DeviceItemStyle = deviceItemStyleMap.get(deviceType);
      if (itemStyle) {
        audioListItem.audioIcon = itemStyle.audioIcon;
        audioListItem.selectedIcon = itemStyle.selectedIcon;
        if (this.isDistributeDevice(deviceType)) {
          let data: DefaultDistributeDeviceAddressData = JSON.parse(address);
          audioListItem.audioTitle = data.devName;
          audioListItem.isCheck = this.currentAudioDevice.deviceType === deviceType &&
            this.currentAudioDevice.address === data.devId;
        } else if (deviceType === DeviceTypeConst.DEVICE_BLUETOOTH_SCO ||
          deviceType === DeviceTypeConst.DEVICE_DISTRIBUTED_XINGSHAN) {
          // const earIcon: Resource = deviceType === DeviceTypeConst.DEVICE_DISTRIBUTED_XINGSHAN ?
          // $r(`${SymbolIconUtil.getInstance().getXingshanEarphoneFillIcon(address)}`) :
          // $r(`${SymbolIconUtil.getInstance().getEarphoneFillIcon(address)}`);
          // this.setAudioListItemData(item, earIcon, audioListItem);
        } else if (deviceType === DeviceTypeConst.DEVICE_BLUETOOTH_HEARINGAID) {
          const earIcon: Resource = $r(`sys.symbol.audiphonen`)
          this.setAudioListItemData(item, earIcon, audioListItem);
        } else {
          audioListItem.audioTitle = itemStyle.audioTitle;
          audioListItem.isCheck = this.currentAudioDevice.deviceType === deviceType;
        }
        audioListItem.deviceType = deviceType;
        audioListItem.address = address;
        this.dataList.push(audioListItem);
      }
    });
    AppStorage.setOrCreate('dataList', this.dataList);
  }

  isDistributeDevice(deviceType: number): boolean {
    return deviceType === DeviceTypeConst.DEVICE_DISTRIBUTED_AUTOMOTIVE ||
      deviceType === DeviceTypeConst.DEVICE_DISTRIBUTED_PHONE ||
      deviceType === DeviceTypeConst.DEVICE_DISTRIBUTED_PAD
  }

  updateButtonIcon(): void {
    this.speakerSelected = false;
    if (this.currentAudioDevice.deviceType === DeviceTypeConst.DEVICE_SPEAKER) {
      this.currentAudioIcon = $r('sys.symbol.speaker_wave_3_fill');
      this.speakerSelected = true;
    } else if (this.currentAudioDevice.deviceType === DeviceTypeConst.DEVICE_EARPIECE) {
      this.currentAudioIcon = $r('sys.symbol.speaker_wave_3_fill');
    } else if (this.currentAudioDevice.deviceType === DeviceTypeConst.DEVICE_WIRED_HEADSET) {
      this.currentAudioIcon = $r('sys.symbol.earphone_16640_fill');
      this.speakerSelected = true;
    }
    this.audioIconStyle = $r('sys.color.icon_primary');
  }

  setMapNavigationAudioDevice(): void {
    if (this.currentAudioDevice.deviceType !== DeviceTypeConst.DEVICE_EARPIECE &&
      this.currentAudioDevice.deviceType !== DeviceTypeConst.DEVICE_SPEAKER) {
      LogUtils.i(TAG, 'map navigation is not a earpiece answer, AudioDeviceType: ' + this.currentAudioDevice.deviceType);
      return;
    }
    let audioDevice: AudioDevice = new AudioDevice();
    audioDevice.deviceType = DeviceTypeConst.DEVICE_SPEAKER;
    LogUtils.i(TAG, 'setMapNavigationAudioDevice AudioDeviceType: ' + JSON.stringify(audioDevice.deviceType));
    AudioDeviceManager.getInstance().setAudioDevice(audioDevice);
    ReportUtil.getInstance().reportMapNavigationBarAnswerAudioRute(audioDevice.deviceType);
  }

  setButtonAudioDevice(callId: number, callType?: number, isFromNotify?: boolean): void {
    let itemDeviceType = this.currentAudioDevice.deviceType;
    if (callType === CallStateConst.TYPE_SATELLITE && this.currentHeadset === DeviceTypeConst.DEVICE_EARPIECE &&
      itemDeviceType === DeviceTypeConst.DEVICE_SPEAKER) {
      Utils.getInstance().showToast($r('app.string.disableChangedToEarpiece'), 2000);
      return;
    }
    if (itemDeviceType === DeviceTypeConst.DEVICE_SPEAKER) {
      if (this.isHaveMultiDevice) {
        call.sendCallUiEvent(callId, Constants.EVENT_SPEAKER_OFF).then(() => {
          LogUtils.i(TAG, 'sendCallUiEvent EVENT_SPEAKER_OFF success');
        }).catch((err: BusinessError) => {
          LogUtils.e(TAG, 'sendCallUiEvent EVENT_SPEAKER_OFF failed, err: ' + JSON.stringify(err));
        });
        return;
      } else {
        itemDeviceType = this.currentHeadset;
      }
    } else {
      itemDeviceType = DeviceTypeConst.DEVICE_SPEAKER;
      AppStorage.setOrCreate('isAutoOpenSpeaker', false);
    }
    this.mAudioDevice.deviceType = itemDeviceType;
    this.mAudioDevice.address = this.getAudioDeviceAddress(itemDeviceType);
    LogUtils.i(TAG, 'setButtonAudioDevice deviceType:' + JSON.stringify(itemDeviceType) +
      ', address: ' + LogUtils.toSafeAddressString(this.mAudioDevice.address));
    AudioDeviceManager.getInstance().setAudioDevice(this.mAudioDevice);
    AccessibilityUtil.announceForAccessibilityNotInterrupt(this.postExecutionBroadcastInfo(itemDeviceType));
    if (isFromNotify) {
      ReportUtil.getInstance().reportNotifyBarAnswerAudioRute(itemDeviceType,
        callType === CallStateConst.TYPE_VOIP ? 1 : 0);
    } else {
      ReportUtil.getInstance().reportSwitchAudioRuteInCall(itemDeviceType);
    }
  }

  private postExecutionBroadcastInfo(itemDeviceType: number): string {
    switch (itemDeviceType) {
      case DeviceTypeConst.DEVICE_SPEAKER:
        return StringUtil.formatResourceToString($r('app.string.selected_device'),
          StringUtil.formatResourceToString($r('app.string.speaker')));
      case DeviceTypeConst.DEVICE_EARPIECE:
        return StringUtil.formatResourceToString($r('app.string.selected_device'),
          StringUtil.formatResourceToString($r('app.string.phoneHandset')));
      case DeviceTypeConst.DEVICE_WIRED_HEADSET:
        return StringUtil.formatResourceToString($r('app.string.wired_headset_selected'));
      case DeviceTypeConst.DEVICE_BLUETOOTH_SCO:
        return StringUtil.formatResourceToString($r('app.string.blueetooth_device_selected'));
      default:
        return '';
    }
  }

  private getAudioDeviceAddress(itemDeviceType: number) {
    let audioDeviceAddress = this.mAudioDevice.address;
    for (let i = 0; i < this.dataList.length; i++) {
      let audioListItem = this.dataList[i];
      if (itemDeviceType === audioListItem.deviceType) {
        audioDeviceAddress = audioListItem.address;
        break;
      }
    }
    return audioDeviceAddress;
  }

  public getCurrentAudioDeviceType(): number {
    return this.currentAudioDevice.deviceType;
  }

  public getCurrentAudioDeviceAddress(): string {
    return this.currentAudioDevice.address;
  }

  public setAudioDeviceSpeaker(audioDevice: number): void {
    this.mAudioDevice.deviceType = audioDevice;
    LogUtils.i(TAG, 'setAudioDeviceSpeaker ' + audioDevice);
    AudioDeviceManager.getInstance().setAudioDevice(this.mAudioDevice);
  }

  async hangUpCall(callId: number, callCount: number): Promise<void> {
    CallServiceProxy.getInstance()?.hangUpCall(callId);
    if (callCount <= 1) {
      const callData = CallDataManager.getInstance().callList.find(callData => callData.callId == callId);
      if (callData && callData.callState !== CallStateConst.CALL_STATUS_DISCONNECTED) {
        AppStorage.setOrCreate('hasBeenToFrontOrBackend', AppStorage.get('onPageShow'));
        AppStorage.setOrCreate('hangUp', true);
        AppStorage.setOrCreate('nativeHangUp', true);
        animateToImmediately({}, () => {});
      }
      LogUtils.i(TAG, 'hangUpCall callCount length is 1');

      if (callData != null) {
        await NumberMarkManager.getInstance().beginNumberMarkSteps(callData);
      }
      removeWindowListener();
      BannerNotificationManager.getInstance().cancelNotification(callId);
      ProximityUtils.unHoldProximityLock();

      setTimeout(() => {
        LogUtils.e(TAG, `delay to releaseUiAbility`);
        terminateSelf(Constants.CALL_ABILITY_CONTEXT);
        // destroy page small folding screen
        terminateSelf(Constants.EXTERNAL_CALL_ABILITY_CONTEXT);
        terminateSelf(Constants.HICAR_CALL_ABILITY_CONTEXT);
      }, 180);
    }
  }
}
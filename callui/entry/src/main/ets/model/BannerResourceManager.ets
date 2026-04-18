/**
 * Copyright (c) 2022-2024 Huawei Device Co., Ltd.
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

import image from '@ohos.multimedia.image';
import ConfigurationConstant from '@ohos.app.ability.ConfigurationConstant';
import CallStateConst from '../common/constant/CallStateConst';
import LogUtils from '../common/utils/LogUtils';
import Utils from '../common/utils/utils';
import ServiceExtensionContext from '@ohos.app.ability.common';
import { MUTE_BUTTON_DISABLED } from '../common/utils/Constants';
import notificationManager from '@ohos.notificationManager';
import { SystemMode } from '../common/utils/SystemMode';

const DEFAULT_CONTACT_ICON = 'ic_public_avatar.svg';
const DEFAULT_CONTACT_ICON_DARK = 'ic_public_avatar_dark.svg';
const DEFAULT_CAPSULE_ICON = 'default_incoming.svg';
const VIDEO_CAPSULE_ICON = 'default_video.svg';
const SIM1_INCOMING_ICON = 'sim1_incoming.svg';
const SIM1_VIDEO_INCOMING_ICON = 'sim1_video_incoming.svg';
const SIM2_INCOMING_ICON = 'sim2_incoming.svg';
const SIM2_VIDEO_INCOMING_ICON = 'sim2_video_incoming.svg';
const CELIA_CALL_ICON = 'AI_phone_fill.svg';
const CELIA_CALL_ICON_NEWASSTANT = 'AI_phone_fill_newassistant.svg';
const DEFAULT_CAPSULE_ICON_LIVE_TWO = 'default_incoming_live_two.svg';
const VIDEO_CAPSULE_ICON_LIVE_TWO = 'default_video_live_two.svg';
const SIM1_INCOMING_ICON_LIVE_TWO = 'sim1_incoming_live_two.svg';
const SIM1_VIDEO_INCOMING_ICON_LIVE_TWO = 'sim1_video_incoming_live_two.svg';
const SIM2_INCOMING_ICON_LIVE_TWO = 'sim2_incoming_live_two.svg';
const SIM2_VIDEO_INCOMING_ICON_LIVE_TWO = 'sim2_video_incoming_live_two.svg';

const APP_ICON = 'callui_icon.svg';

export const MUTE_DISABLED = 2;

const TAG = 'BannerResourceManager';
const ICON_SIZE = 1;
const ICON_SIZE_CONTACTS = 2;
const ICON_SIZE_CAPSULE = 3;
const CAPSULE_ICON_SIZE = 63; // 18 * 3.5
const MEDIUM_ICON_SIZE = 112; // 32 * 3.5
const BANNER_ICON_SIZE = 140; // 40 * 3.5

export enum CallStateType {
  // normal incoming call
  InComingCallNormal = 0,
  // in active call
  InCallNormal,
  // holding
  HoldOnCall,
  // out going call
  OutGoingCall
}

export interface DarkResIcon {
  resId: number,
  res?: image.PixelMap,
  hasDark: boolean;
  dark?: string,
  light: string,
  size: number
}

export enum DarkResIcons {
  DEFAULT_CONTACTS = 0,
  // below is no dark res icons
  APP_ICONS,
  CAPSULE_VOICE,
  CAPSULE_VIDEO,
  SIM1_VOICE,
  SIM2_VOICE,
  SIM1_VIDEO,
  SIM2_VIDEO,
  CELIA_CALL,
  CElIA_CALL_NEWASSTANT
}

export class BannerResourceManager {
  private isDark: boolean = false;
  private lastMode?: boolean = undefined;
  private isNeedUpdateRes: boolean = false;
  private context?: Context;
  private darkResMap: DarkResIcon[];
  private celiaPixelMap?: PixelMap;
  private appPixelMap?: PixelMap;

  createDarkResIcon(resIdParam: number, lightParam: string, darkParam: string | undefined,
    sizeParam: number, hasDark: boolean): DarkResIcon {
    return {
      resId: resIdParam,
      light: lightParam,
      dark: darkParam,
      size: sizeParam,
      hasDark: hasDark
    };
  }

  constructor(context: Context) {
    this.context = context;
    this.initDarkMode();

    let defaultCapsuleIcon = DEFAULT_CAPSULE_ICON;
    let videoCapsuleIcon = VIDEO_CAPSULE_ICON;
    let sim1Incoming = SIM1_INCOMING_ICON;
    let sim1VideoIncoming = SIM1_VIDEO_INCOMING_ICON;
    let sim2Incoming = SIM2_INCOMING_ICON;
    let sim2VideoIncoming = SIM2_VIDEO_INCOMING_ICON;

    if (Utils.getInstance().isEnabledSystemUiLive2()) {
      defaultCapsuleIcon = DEFAULT_CAPSULE_ICON_LIVE_TWO;
      videoCapsuleIcon = VIDEO_CAPSULE_ICON_LIVE_TWO;
      sim1Incoming = SIM1_INCOMING_ICON_LIVE_TWO;
      sim1VideoIncoming = SIM1_VIDEO_INCOMING_ICON_LIVE_TWO;
      sim2Incoming = SIM2_INCOMING_ICON_LIVE_TWO;
      sim2VideoIncoming = SIM2_VIDEO_INCOMING_ICON_LIVE_TWO;
    }

    this.darkResMap = [
      this.createDarkResIcon(DarkResIcons.DEFAULT_CONTACTS, DEFAULT_CONTACT_ICON, DEFAULT_CONTACT_ICON_DARK,
        ICON_SIZE_CONTACTS, true),
      this.createDarkResIcon(DarkResIcons.APP_ICONS, APP_ICON, undefined, ICON_SIZE, false),
      this.createDarkResIcon(DarkResIcons.CAPSULE_VOICE, defaultCapsuleIcon, undefined, ICON_SIZE_CAPSULE, false),
      this.createDarkResIcon(DarkResIcons.CAPSULE_VIDEO, videoCapsuleIcon, undefined, ICON_SIZE_CAPSULE, false),
      this.createDarkResIcon(DarkResIcons.SIM1_VOICE, sim1Incoming, undefined, ICON_SIZE_CAPSULE, false),
      this.createDarkResIcon(DarkResIcons.SIM2_VOICE, sim2Incoming, undefined, ICON_SIZE_CAPSULE, false),
      this.createDarkResIcon(DarkResIcons.SIM1_VIDEO, sim1VideoIncoming, undefined, ICON_SIZE_CAPSULE, false),
      this.createDarkResIcon(DarkResIcons.SIM2_VIDEO, sim2VideoIncoming, undefined, ICON_SIZE_CAPSULE, false),
      this.createDarkResIcon(DarkResIcons.CELIA_CALL, CELIA_CALL_ICON, undefined, ICON_SIZE_CAPSULE, false),
      this.createDarkResIcon(DarkResIcons.CElIA_CALL_NEWASSTANT, CELIA_CALL_ICON_NEWASSTANT, undefined,
        ICON_SIZE_CAPSULE, false)
    ];
  }

  refreshResource(isDark: boolean) {
    LogUtils.i(TAG, 'start to refresh with dark resource ' + isDark);
    this.updateDarkModeStatus(isDark);
    this.darkResMap.forEach((item) => {
      if (item !== undefined && item.hasDark) {
        LogUtils.i(TAG, 'start to refresh with dark resource ' + item.resId);
        this.getCorrespondingPixMap(item.resId);
      }
    });
  }

  async getPixMap(context: Context, imageName: string, size?: number) {
    let resourceMgr = context?.resourceManager;
    let decodeOption: image.DecodingOptions;
    // use number size instead of vp2px
    let desiredWidth: number = 0;
    if (size === ICON_SIZE_CAPSULE) {
      desiredWidth = CAPSULE_ICON_SIZE;
    }
    if (size === ICON_SIZE_CONTACTS) {
      desiredWidth = MEDIUM_ICON_SIZE;
    } else {
      desiredWidth = BANNER_ICON_SIZE;
    }
    decodeOption = {
      desiredSize: {
        height: desiredWidth,
        width: desiredWidth
      }
    }

    let data = await resourceMgr.getRawFileContent(imageName);
    let buffer = data.buffer;
    let imageSource = image.createImageSource(buffer);
    let pixelMap: image.PixelMap = await imageSource.createPixelMap(decodeOption);
    imageSource.release();
    return pixelMap;
  }

  async getSmallIcon(): Promise<PixelMap | undefined> {
    let resource = $r('app.media.app_icon');
    if (this.celiaPixelMap) {
      return this.celiaPixelMap;
    } else if (this.appPixelMap) {
      return this.appPixelMap;
    } else {
      try {
        let context = Utils.getInstance().getContext(false);
        let imageArray = await context.resourceManager.getMediaContent(resource);
        let imageSource = image.createImageSource(imageArray.buffer.slice(0));
        let pixMap = await imageSource.createPixelMap();
        imageSource.release();
        this.appPixelMap = pixMap;
        return pixMap;
      } catch (e) {
        LogUtils.e(TAG, 'getSmallIcon error');
        return undefined;
      }
    }
  }

  release() {
    LogUtils.i(TAG, 'start to release resource.');
    let iconArray = this.darkResMap;
    iconArray.forEach((item) => {
      if (item !== undefined && item.res !== undefined) {
        item.res.release();
        item.res = undefined;
      }
    });
    this.celiaPixelMap?.release();
    this.appPixelMap?.release();
    this.celiaPixelMap = undefined;
    this.appPixelMap = undefined;
  }

  private async handleMuteCase(isMute: number, nameResult: string[], iconsResource: Array<Resource | undefined>) {
    if (isMute === MUTE_BUTTON_DISABLED) {
      nameResult.splice(0, 0, CallStateConst.TEXT_IN_CALL_AUDIO_MUTE_OFF_DISABLED);
      iconsResource.splice(0, 0, $r('app.media.mic_off_disabled'));
    } else if (isMute === 1) {
      nameResult.splice(0, 0, CallStateConst.TEXT_IN_CALL_UN_MUTE);
      iconsResource.splice(0, 0, $r('app.media.mic_slash_on'));
    } else if (isMute === 0) {
      nameResult.splice(0, 0, CallStateConst.TEXT_IN_CALL_MUTE);
      iconsResource.splice(0, 0, $r('app.media.mic_off'));
    } else { // isMute === MUTE_DISABLED
      nameResult.splice(0, 0, CallStateConst.TEXT_IN_CALL_DISABLED_MUTE);
      iconsResource.splice(0, 0, $r('app.media.mic_off_disabled'));
    }
  }

  private showVoiceAnswer(videoState: number, isVoiceAnswerSupported?: boolean): boolean {
    if (videoState !== CallStateConst.VIDEO_STATE_VIDEO) {
      return true;
    }
    if (isVoiceAnswerSupported == undefined) {
      return true;
    }
    if (isVoiceAnswerSupported) {
      return true;
    }
    return false;
  }

  public async getIconNamesByState(state: number, videoState: number, isMute?: number, isSpeakerOn?: boolean,
    isVoiceAnswerSupported?: boolean): Promise<notificationManager.NotificationButton> {
    let nameResult: string[] = [];
    let iconsResource: Resource[] = [];
    const isRTL = AppStorage.get<boolean>('isRTL');
    LogUtils.i(TAG, 'getIconNamesByState start state:' + state + ',videoState:' + videoState +
      ',isMute:' + isMute + ',isSpeakerOn:' + isSpeakerOn);
    if (isMute !== undefined) {
      await this.handleMuteCase(isMute, nameResult, iconsResource);
    }
    switch (state) {
      case CallStateType.InComingCallNormal:
        nameResult.push(CallStateConst.TEXT_INCOMING_CALL_REJECT);
        iconsResource.push($r('app.media.phone_down'));
        if (this.showVoiceAnswer(videoState, isVoiceAnswerSupported)) {
          const currentResource = isRTL ? $r('app.media.rtl_phone') : $r('app.media.phone');
          nameResult.push(CallStateConst.TEXT_INCOMING_CALL_ANSWER);
          iconsResource.push(currentResource);
        }

        if (videoState === CallStateConst.VIDEO_STATE_VIDEO && !SystemMode.getInstance().isModePenglai()) {
          nameResult.push(CallStateConst.TEXT_INCOMING_CALL_ANSWER_VIDEO);
          iconsResource.push($r('app.media.video'));
        }
        break;
      case CallStateType.InCallNormal:
      case CallStateType.OutGoingCall:
        nameResult.push(CallStateConst.TEXT_IN_CALL_HANG_UP);
        iconsResource.push($r('app.media.phone_down'));
        if (isSpeakerOn !== undefined) {
          if (isSpeakerOn) {
            iconsResource.push($r('app.media.sound_filled_on'));
          } else {
            iconsResource.push($r('app.media.sound_off'));
          }
          nameResult.push(CallStateConst.TEXT_IN_CALL_AUDIO_SPEAKER);
        }
        break;
      case CallStateType.HoldOnCall:
        nameResult.push(CallStateConst.TEXT_IN_CALL_HANG_UP);
        iconsResource.push($r('app.media.phone_down'));

        nameResult.push(CallStateConst.TEXT_IN_CALL_UN_HOLD_ON);
        iconsResource.push($r('app.media.pause_on'));
        break;
      default:
        break;
    }
    let result: notificationManager.NotificationButton = {
      names: nameResult,
      iconsResource: iconsResource
    }
    LogUtils.i(TAG, 'getIconNamesByState end ' + nameResult.length);
    return result;
  }

  public getCallState(callData: number): CallStateType {
    let result: CallStateType = CallStateType.OutGoingCall;
    switch (callData) {
      case CallStateConst.CALL_STATUS_INCOMING:
      case CallStateConst.CALL_STATUS_ANSWER:
      case CallStateConst.CALL_STATUS_WAITING:
        result = CallStateType.InComingCallNormal;
        break
      case CallStateConst.CALL_STATUS_DIALING:
      case CallStateConst.CALL_STATUS_ALERTING:
        result = CallStateType.OutGoingCall;
        break
      case CallStateConst.CALL_STATUS_ACTIVE:
        result = CallStateType.InCallNormal;
        break
      case CallStateConst.CALL_STATUS_HOLDING:
        result = CallStateType.HoldOnCall;
        break
      default:
        break;
    }
    LogUtils.i(TAG, 'getCallState is ' + callData + ' to ' + result);
    return result;
  }

  public async getCorrespondingPixMap(resType: number) {
    let withDarkRes: DarkResIcon;
    if (resType < DarkResIcons.DEFAULT_CONTACTS || resType > (this.darkResMap.length - 1)) {
      LogUtils.e(TAG, `resType is invalid, resType: ${resType}`);
      return undefined;
    }
    withDarkRes = this.darkResMap[resType];

    if (withDarkRes.res !== undefined) {
      if (!withDarkRes.hasDark || !this.isNeedUpdateRes) {
        return withDarkRes.res;
      }
    }
    if (this.context === undefined) {
      this.context = Utils.getInstance().getContext(true);
    }
    if (withDarkRes.res !== undefined) {
      withDarkRes.res.release();
      withDarkRes.res = undefined;
    }
    try {
      if (this.isDark && withDarkRes.hasDark && withDarkRes.dark !== undefined) {
        withDarkRes.res = await this.getPixMap(this.context, withDarkRes.dark, withDarkRes.size);
      } else {
        withDarkRes.res = await this.getPixMap(this.context, withDarkRes.light, withDarkRes.size);
      }
    } catch (error) {
      LogUtils.e(TAG, 'Failed to get PixMap');
    }
    return withDarkRes.res;
  }

  private initDarkMode() {
    let serviceContext = this.context as ServiceExtensionContext.ServiceExtensionContext;
    if (serviceContext !== undefined) {
      this.isDark = serviceContext.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
      LogUtils.i(TAG, 'serviceContext isDarkMode ' + this.isDark);
    }
  }

  updateDarkModeStatus(isDark: boolean) {
    LogUtils.i(TAG, 'updateDarkModeStatus isDark: ' + isDark);
    this.isDark = isDark;
    this.isNeedUpdateRes = this.lastMode !== this.isDark;
    this.lastMode = this.isDark;
  }

  public isDarkMode() {
    return this.isDark;
  }
}
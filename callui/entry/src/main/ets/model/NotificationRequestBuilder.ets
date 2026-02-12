/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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

import notificationManager from '@ohos.notificationManager';
import { WantAgent } from '@ohos.app.ability.wantAgent';

export default class NotificationRequestBuilder {
  private request: notificationManager.NotificationRequest;

  constructor(notificationId: number) {
    this.request = {
      id: notificationId,
      isRemoveAllowed: false,
      content: {
        contentType: 1,
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_SYSTEM_LIVE_VIEW,
        systemLiveView: {
          title: '',
          text: '',
          typeCode: 0,
          capsule: {
            backgroundColor: '#64BB5C'
          }
        }
      },
      notificationSlotType: notificationManager.SlotType.LIVE_VIEW,
      extraInfo: {
        'hw_capsule_sticky': false,
        'hw_capsule_hidden_when_terminate': true
      }
    };
  }

  setbackgrouncolor(): void {
    if (this.request.content.systemLiveView?.capsule) {
      this.request.content.systemLiveView.capsule.backgroundColor = '#64BB5C';
    }
  }

  setWantAgent(wantAgent: WantAgent) {
    this.request.wantAgent = wantAgent;
  }

  setOverlayIcon(overlayIcon?: PixelMap) {
    if (overlayIcon) {
      this.request.overlayIcon = overlayIcon;
    }
  }

  setSmallIcon(smallIcon?: PixelMap) {
    if (smallIcon) {
      this.request.smallIcon = smallIcon;
    }
  }

  setTitle(title: string) {
    let systemLiveView = this.request.content.systemLiveView;
    if (systemLiveView) {
      systemLiveView.title = title;
    }
  }

  setText(text: string) {
    let systemLiveView = this.request.content.systemLiveView;
    if (systemLiveView) {
      systemLiveView.text = text;
    }
  }

  setButton(button: notificationManager.NotificationButton) {
    let systemLiveView = this.request.content.systemLiveView;
    if (systemLiveView) {
      systemLiveView.button = button;
    }
  }

  setCapsuleTitle(title: string) {
    let systemLiveView = this.request.content.systemLiveView;
    if (systemLiveView && systemLiveView.capsule) {
      systemLiveView.capsule.title = title;
    }
  }

  setCapsuleIcon(icon: PixelMap) {
    let systemLiveView = this.request.content.systemLiveView;
    if (systemLiveView && systemLiveView.capsule) {
      systemLiveView.capsule.icon = icon;
    }
  }

  setHeadsUpEnable(hwHeadsUpEnable: boolean) {
    if (this.request.extraInfo) {
      this.request.extraInfo['hw_heads_up_enable'] = hwHeadsUpEnable;
    }
  }

  setKeepHeadsUpSticky(hwKeepHeadsUpSticky: boolean) {
    if (this.request.extraInfo) {
      this.request.extraInfo['hw_keep_headsup_sticky'] = hwKeepHeadsUpSticky;
    }
  }

  setSimIconStatus(hwSimIconStatus: number) {
    if (this.request.extraInfo) {
      this.request.extraInfo['hw_sim_icon_status'] = hwSimIconStatus;
    }
  }

  setCapsuleSticky(hwCapsuleSticky?: boolean) {
    if (hwCapsuleSticky === undefined) {
      hwCapsuleSticky = false;
    }
    if (this.request.extraInfo) {
      this.request.extraInfo['hw_capsule_sticky'] = hwCapsuleSticky;
    }
  }

  setCapsuleHiddenWhenTerminate(hwCapsuleHiddenWhenTerminate: boolean) {
    if (this.request.extraInfo) {
      this.request.extraInfo['hw_capsule_hidden_when_terminate'] = hwCapsuleHiddenWhenTerminate;
    }
  }

  setButtonAccessibilityText(hwButtonAccessibilityText: string[]) {
    if (this.request.extraInfo) {
      this.request.extraInfo['hw_button_accessibility_text'] = hwButtonAccessibilityText;
    }
  }

  setSysVoipState(sysVoipState: number) {
    if (this.request.extraInfo) {
      this.request.extraInfo['SYS_VOIP_STATUS'] = sysVoipState;
    }
  }

  setNotificationTime(time: notificationManager.NotificationTime) {
    let systemLiveView = this.request.content.systemLiveView;
    if (systemLiveView) {
      systemLiveView.time = time;
    }
  }

  build() {
    return this.request;
  }
}
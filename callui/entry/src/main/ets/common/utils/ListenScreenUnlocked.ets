/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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
import LogUtils from './LogUtils';
import { BusinessError, commonEventManager, osAccount } from '@kit.BasicServicesKit';
import { isScreenLocked } from './DeviceTypeUtils';
import { ProximityUtils } from './ProximityUtils';

const TAG = 'ListenScreenUnlocked';
const SCREEN_ON_LOCKED = 'usual.event.SCREEN_UNLOCKED';
const events = [SCREEN_ON_LOCKED];
const STK_LOCK_NOTIFICATION_EVENT = 'usual.event.STK_LOCK_NOTIFICATION';
const STK_LOCK_NOTIFICATION_EVENT_SUBSCRIBEINFO: commonEventManager.CommonEventSubscribeInfo = {
  events: [STK_LOCK_NOTIFICATION_EVENT],
  publisherPermission: 'ohos.permission.SET_TELEPHONY_STATE'};

export class ListenScreenUnlocked {
  private static listenScreenUnlocked: ListenScreenUnlocked;
  private isEventSubscribed: boolean = false;
  private subscriber?: commonEventManager.CommonEventSubscriber;
  private isStkEventSubscribed: boolean = false;
  private stkSubscriber?: commonEventManager.CommonEventSubscriber;

  public static getInstance(): ListenScreenUnlocked {
    if (!ListenScreenUnlocked.listenScreenUnlocked) {
      ListenScreenUnlocked.listenScreenUnlocked = new ListenScreenUnlocked();
    }
    return ListenScreenUnlocked.listenScreenUnlocked;
  }

  /**
   * add callui app subscriber
   */
  async addSubscriber(): Promise<void> {
    LogUtils.i(TAG, 'addSubscriber');
    if (this.isEventSubscribed) {
      return;
    }
    const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: events,
      publisherPermission: 'ohos.permission.GET_TELEPHONY_STATE'
    };
    commonEventManager.createSubscriber(subscribeInfo).then((res) => {
      this.subscriber = res;
      try {
        LogUtils.i(TAG, 'screenUnlocked subscribe');
        commonEventManager.subscribe(this.subscriber, (err, data) => {
          if ((err && err.code !== 0) || data === undefined) {
            LogUtils.i(TAG, 'addSubscriber commonEvent.subscribe failed err :' + JSON.stringify(err));
            return;
          }
          let event = data.event;
          LogUtils.i(TAG, 'subscribe event:' + JSON.stringify(event));
          switch (event) {
            case SCREEN_ON_LOCKED:
              LogUtils.i(TAG, 'screenUnLoked');
              AppStorage.setOrCreate('isOsAccountUnlocked', true);
              this.unsubscribe();
              break;
            default:
              break;
          }
        });
        this.isEventSubscribed = true;
      } catch (err) {
        LogUtils.e(TAG, 'subscribe err:' + err);
      }
    });
  }

  unsubscribe() {
    commonEventManager.unsubscribe(this.subscriber, (err, data) => {
      LogUtils.i(TAG, 'unsubscribe SCREEN_UNLOCKED event');
    })
  }

  async addStkLockNotiSubscriber(): Promise<void> {
    if (this.isStkEventSubscribed) {
      return;
    }
    try {
      this.stkSubscriber = await commonEventManager.createSubscriber(STK_LOCK_NOTIFICATION_EVENT_SUBSCRIBEINFO);
      commonEventManager.subscribe(this.stkSubscriber, (err, data) => {
        if (data?.event === STK_LOCK_NOTIFICATION_EVENT && isScreenLocked()) {
          ProximityUtils.minimize();
        }
      });
      this.isStkEventSubscribed = true;
    } catch (err) {
      LogUtils.e(TAG, `subscribe stk lock notification err:${err?.message} ${err?.code}`);
    }
  }

  unsubscribeStkLockNoti(): void {
    if (this.isStkEventSubscribed) {
      try {
        commonEventManager.unsubscribe(this.stkSubscriber);
        this.isStkEventSubscribed = false;
      } catch (err) {
        LogUtils.e(TAG, `unsubscribe stk lock notification err:${err?.message} ${err?.code}`);
      }
    }
  }

  /**
   * Checks whether the current OS account is unlocked.
   */
  isUserUnlocked() {
    let accountManager: osAccount.AccountManager = osAccount.getAccountManager();
    try {
      accountManager.getActivatedOsAccountLocalIds().then((idArray: number[]) => {
        LogUtils.i(TAG, `getActivatedOsAccountLocalIds idArray:${JSON.stringify(idArray)}`)
        accountManager.isOsAccountUnlocked(idArray[0]).then((isVerified: boolean) => {
          AppStorage.setOrCreate('isOsAccountUnlocked', isVerified);
          LogUtils.i(TAG, 'isOsAccountUnlocked successfully, isVerified: ' + isVerified);
          if (!isVerified) {
            this.addSubscriber();
          }
        }).catch((err: BusinessError) => {
          LogUtils.i(TAG, 'isOsAccountUnlocked failed, error: ' + JSON.stringify(err));
        });
      }).catch((e: BusinessError) => {
        LogUtils.e(TAG, `queryCurrentOsAccount is error,code:${e.code},message:${e.message}`)
      })
    } catch (err) {
      LogUtils.i(TAG, 'isOsAccountUnlocked exception: ' + JSON.stringify(err));
    }
  }
}
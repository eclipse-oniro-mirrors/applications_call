/**
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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

/**
 * @file: Call management
 */
import CallDataManager from './CallDataManager';
import Utils from '../common/utils/utils';
import commonEvent from '@ohos.commonEvent';
import featureAbility from '@ohos.ability.featureAbility';
import CallServiceProxy from './CallServiceProxy';
import ContactManager from './ContactManager';
import HiLog from '../common/utils/Hilog';
import call from '@ohos.telephony.call';
import CallStateConst from '../common/constant/CallStateConst';

const TAG = "CallManager";
let subscriber;
const TIMING = 1000;
const events = ['callui.event.callDetailsChange'];

/**
 * class CallManager
 */
export default class CallManager {
  private callData: any = {};
  private timer = null ;
  callTimeList = [];
  private ctx = [];
  private sendNotificationHandle: any;
  private mCallDataManager: CallDataManager;
  private mCallServiceProxy: CallServiceProxy ;
  private mUtils: Utils;
  private contactManager;
  private diffSeconds
  private mTimeMeter

  constructor(ctx) {
    this.contactManager = new ContactManager();
    this.mCallServiceProxy = CallServiceProxy.getInstance();
    this.mUtils = Utils.getInstance();
    this.callData = ctx.callData;
    this.timer = null;
    this.ctx = ctx;
    this.callTimeList = ctx.callTimeList;
    this.mCallDataManager = new CallDataManager(ctx.callData, ctx.callList, ctx.callTimeList);
    this.openTimer();
    this.sendNotificationHandle = (arg) => arg;
    this.registerSubscriber();
    this.initCallData();
  }

  /*
   * init CallData
   */
  private initCallData() {
    featureAbility.getWant().then((want) => {
      if (want && want.parameters && ('callState' in want.parameters)) {
        this.update(want.parameters);
        HiLog.i(TAG, "initCallData featureAbility.getWant :  %s")
      } else {
        this.mCallServiceProxy.publish({
          key: 'getInitCallData',
          params: []
        });
      }
    })
      .catch((error) => {
        HiLog.i(TAG, "initCallData catch error :  %s" + JSON.stringify(error))
      });
  }

  /*
   * Registered subscribers
   */
  private async registerSubscriber() {
    subscriber = await new Promise((resolve) => {
      commonEvent.createSubscriber({
        events
      },
        (err, data) => {
          resolve(data);
        }
      );
    });

    commonEvent.subscribe(subscriber, (err, res) => {
      if (err.code === 0) {
        const callData = JSON.parse(res.data);
        this.callData = callData
        HiLog.i(TAG, "commonEvent subscribe : %s")
        if (callData) {
          this.update(callData);
        }
        HiLog.i(TAG, "commonEvent subscribe : %s")
      } else {
        HiLog.i(TAG, "commonEvent.subscribe err: %s" + JSON.stringify(err))
      }
    });
  }

  /**
   * unsubscribe
   */
  private unsubscribe() {
    commonEvent.unsubscribe(subscriber, (err) => {
      if (err.code !== 0) {
        HiLog.i(TAG, "commonEvent.unsubscribe err: %s" + JSON.stringify(err))
      }
    });
  }

  /**
   * update callData callBack
   *
   * @param { Object } callData -Object
   */
  async update(callData) {
    await this.contactManager.getContactInfo(callData)
    this.mCallDataManager.update(callData);
    call.formatPhoneNumber(callData.accountNumber, (err, data) => {
      if (data === undefined) {
        AppStorage.SetOrCreate("AccountNumber", callData.accountNumber)
      } else {
        AppStorage.SetOrCreate("AccountNumber", data)
      }
    });
    HiLog.i(TAG, "update : ")
  }

  /**
   * update call time list
   */
  updateCallTimeList() {
    if (this.callData.callState != CallStateConst.CALL_STATUS_ACTIVE && this.callData.callState != CallStateConst.CALL_STATUS_HOLDING) {
      return;
    }
    this.callTimeList = AppStorage.Get("CallTimeList")
    this.callTimeList.forEach((item, i) => {
      item.endTimestamp = new Date().valueOf();
      const diffSeconds = item.endTimestamp - item.startTimestamp;
      this.diffSeconds = diffSeconds
      item.callTime = this.mUtils.formatTime(diffSeconds);
      this.callTimeList.splice(i, 1, {
        ...item,
      });
      AppStorage.SetOrCreate("CallTimeList", this.callTimeList)
    });
    this.mTimeMeter = setTimeout(() => {
      this.updateCallTimeList();
    }, 1000 - this.diffSeconds % 1000);

  }

  /**
   * open timer
   *
   * @param { Function } callBack - add updateCallTimeList callBack
   */
  openTimer() {
    this.timer = setInterval(() => {
      this.updateCallTimeList();
      if (this.callData.callState === CallStateConst.CALL_STATUS_ACTIVE) {
        clearInterval(this.timer);
      }
    }, TIMING);
  }

  /**
   * clear timer
   */
  clearTimer() {
    clearInterval(this.timer);
  }
}

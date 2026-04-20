/*
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

import { MarkType } from './NumberMark';
import { common } from '@kit.AbilityKit';
import LogUtils from '../common/utils/LogUtils';
import { noop } from '../common/utils/Misc';
import DefaultCallData, { CallDataPatch, callDataPatcher } from '../common/struct/TypeUtils';
// import numberLookup from '@ohos.telephony.numberLookup';
import * as Constants from '../common/utils/Constants';
import { dataShare, dataSharePredicates } from '@kit.ArkData';
import { GlobalContextHelper } from '../common/utils/GlobalContextHelper';
import CallStateConst from '../common/constant/CallStateConst';
import { taskpool } from '@kit.ArkTS';
import { TaskUtil } from '../common/utils/TaskUtil';
import CallDataManager from './CallDataManager';
import { STRANGE_NUMBER_CALL_DATA } from '../common/utils/Constants';
import { isTwoInOne } from '../common/utils/DeviceTypeUtils';
import { BusinessError } from '@kit.BasicServicesKit';
import { DisplayUtil } from '../common/utils/DisplayUtil';
import * as BannerNotificationProxy from '../common/utils/BannerNotificationProxy';

export interface MarkNumberParams {
  markType: MarkType;
  accountNumber: string;
  formatNumber: string;
  customMark?: string;
}
type Complete = () => void;
type Abort = (reason?: string) => void;
interface NumberMarkStep {
  complete: Complete;
  abort: Abort;
  workingPromise: Promise<void>;
  callData: DefaultCallData;
}

const CONTACTS_URI = 'datashare:///com.ohos.contactsdataability';
const CONTACTS_BLOCK_LIST_URI = 'datashare:///com.ohos.contactsdataability/contacts/contact_blocklist';


/** Empty class for default implementation. */
export class NumberMarkService {
  async createNewContact(accountNumber: string): Promise<void> {
    this.info('createNewContact');
    const context = this.getUIAbilityContext();
    try {
      await context.startAbility({
        bundleName: 'com.ohos.contacts',
        abilityName: 'com.ohos.contacts.MainAbility',
        parameters: {
          'pageFlag': 'page_flag_save_contact',
          'phoneNumber': accountNumber,
        },
      });
    } catch (e) {
      this.error(`startAbility error: ${JSON.stringify(e)}`);
    }
  }

  async addToExistingContact(accountNumber: string): Promise<void> {
    this.info(`addToExistingContact`);
    const context = this.getUIAbilityContext();
    try {
      await context.startAbility({
        bundleName: 'com.ohos.contacts',
        abilityName: 'com.ohos.contacts.MainAbility',
        parameters: {
          'pageFlag': 'page_flag_save_exist_contact',
          'phoneNumber': accountNumber,
        },
      });
    } catch (e) {
      this.error(`startAbility error: ${JSON.stringify(e)}`);
    }
  }

  async addToBlockList(accountNumber: string, formatNumber: string): Promise<void> {
    this.info('addToBlockList');
    const context = this.getUIAbilityContext();
    try {
      const helper = await dataShare.createDataShareHelper(context, CONTACTS_URI);
      this.info(`contact block list datashare created`);
      await helper.insert(CONTACTS_BLOCK_LIST_URI, {
        'types': 0,
        'phone_number': accountNumber,
        'content': formatNumber,
        'time_stamp': Date.now(),
      });
      this.info('addToBlockList done');
    } catch (e) {
      this.error(`error ${JSON.stringify(e)}`);
    }
  }

  async removeFromBlockList(accountNumber: string): Promise<void> {
    this.info('removeFromBlockList');
    const context = this.getUIAbilityContext();
    try {
      const helper = await dataShare.createDataShareHelper(context, CONTACTS_URI);
      this.info(`contact block list datashare created`);
      const predicates = new dataSharePredicates.DataSharePredicates()
        .equalTo('phone_number', accountNumber)
        .and()
        .equalTo('types', 0);
      await helper.delete(CONTACTS_BLOCK_LIST_URI, predicates);
      this.info('removeFromBlockList done');
      helper.close();
    } catch (e) {
      this.error(`error ${JSON.stringify(e)}`);
    }
  }

  async setNumberMark(params: MarkNumberParams): Promise<void> {
    this.info('setNumberMark');
    const blockMarkTypes = [MarkType.MARK_TYPE_CRANK, MarkType.MARK_TYPE_FRAUD];
    if (blockMarkTypes.includes(params.markType)) {
      await Promise.all([
        this.setNumberMarkInfo(params),
        this.addToBlockList(params.accountNumber, params.formatNumber),
      ]);
    } else {
      await Promise.all([
        this.setNumberMarkInfo(params),
        this.removeFromBlockList(params.accountNumber),
      ]);
    }
    this.info('setNumberMark done.');
  }

  async setNumberMarkInfo(params: MarkNumberParams): Promise<void> {
    const context = this.getUIAbilityContext();
    // await numberLookup.setNumberMarkInfo(context, params.accountNumber, params.markType, params.customMark);
  }

  completeSetNumberMarkSteps(reason: string) {
    NumberMarkManager.getInstance().completeNumberMark(reason);
  }

  abortSetNumberMarkSteps(reason: string) {
    NumberMarkManager.getInstance().abortNumberMark(reason);
  }

  private getUIAbilityContext() {
    return GlobalContextHelper.getContext().getValue<common.UIAbilityContext>(Constants.CALL_ABILITY_CONTEXT);
  }

  private info(msg: string) {
    LogUtils.i('NumberMarkService', msg);
  }

  private error(msg: string) {
    LogUtils.e('NumberMarkService', msg);
  }
}

export class NumberMarkManager {
  private static instance: NumberMarkManager | null = null;

  static getInstance(): NumberMarkManager {
    return NumberMarkManager.instance ??= new NumberMarkManager();
  }

  private markSteps: NumberMarkStep | null = null;

  resetStatus() {
    this.markSteps = null;
    AppStorage.set(Constants.STRANGE_NUMBER_CALL_DATA, null);
  }

  completeNumberMark(reason: string) {
    const steps = this.markSteps;
    if (!steps) {
      this.info(`Cannot complete, currently is not showing set number mark. Requested reason: ${reason}`);
      return;
    }
    this.info(`Mark number completed: ${reason}.`);
    steps.complete();
    this.resetStatus();
  }

  abortNumberMark(reason: string) {
    const steps = this.markSteps;
    if (!steps) {
      this.info(`Cannot abort, currently is not showing set number mark. Requested reason: ${reason}`);
      return;
    }
    this.info(`Mark number aborted: ${reason}.`);
    CallDataManager.getInstance().removeCallById(steps.callData.callId);
    steps.abort(reason);
    this.resetStatus();
  }

  async beginNumberMarkSteps(callData: DefaultCallData): Promise<void> {
    if (!this.isOsAccountUnlocked()) {
      return this.info(`OS account locked, skipped number mark popup.`);
    }
    if (!callData.accountNumber) {
      return this.info(`Unknown number, skipped number mark popup.`);
    }
    if (callData.isVoiceMailNumber) {
      return this.info(`Voice mail number, skipped number mark popup.`);
    }
    if (callData.isEcc) {
      return this.info(`Emergency number, skipped number mark popup.`);
    }
    if (callData.callDirection !== CallStateConst.CALL_DIRECTION_INCOMING) {
      return this.info(`Direction is not incoming, skipped number mark popup.`);
    }
    if (!callData.isAnswered) {
      return this.info(`Current call is not answered.`);
    }
    if (this.isContactYellowPageNumberMark(callData)) {
      return this.info('not stranger number, is contact or yellow page or has number mark');
    }
    if (callData.hasAnsweredIncomingCallLog) {
      return this.info('not stranger number, hasAnsweredIncomingCallLog');
    }
    if (this.markSteps !== null) {
      this.error(`number mark steps already working!`);
      return this.markSteps.workingPromise;
    }
    if (isTwoInOne()) {
      return this.info('isTwoInOneDevice');
    }
    if (DisplayUtil.isWifiOnlyDevice()) {
      return this.info('isWifiOnlyDevice');
    }
    if (callData.isMarkPanelShown) {
      return this.info('isMarkPanelShown');
    }
    if (await BannerNotificationProxy.hasImmersiveWindow()) {
      return this.info('hasImmersiveWindow');
    }
    this.info(`Current call is strange number without accepted calls.`);
    this.markSteps = this.createMarkStepContext(callData);
    AppStorage.setOrCreate(Constants.STRANGE_NUMBER_CALL_DATA, callData);
    this.showNumberMarkPanel(callData);
    return this.markSteps.workingPromise;
  }

  showNumberMarkPanel(callData: DefaultCallData) {
    this.info(`showNumberMarkPanel`);

    const patch: CallDataPatch = callDataPatcher.createPatch({
      callId: callData.callId,
      isMarkPanelShown: true,
    });
    callDataPatcher.apply(callData, patch, 'showNumberMarkPanel isMarkPanelShown');
    CallDataManager.getInstance().updateCallerInfo(patch);

    const context = GlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext | null>(Constants.CALL_SERVICE_CONTEXT);
    const parameters: Record<string, Object> = {};
    parameters[STRANGE_NUMBER_CALL_DATA] = callData;
    if (context == null) {
      this.error(`showNumberMarkPanel: No context registered!`);
      return;
    }
    context.startAbility({
      bundleName: 'com.ohos.callui',
      abilityName: 'com.ohos.callui.MainAbility',
      parameters,
    }).then(() => {
      this.info(`showNumberMarkPanel startAbility done`);
    }).catch((err: BusinessError) => {
      this.error(`showNumberMarkPanel startAbility err: ${JSON.stringify(err)}`);
    });
  }

  addCallLogCheckTask(callData: DefaultCallData): void {
    if (this.isContactYellowPageNumberMark(callData)) {
      return this.info(`Skipped to add call log check.`);
    }
    this.info(`add call log check task`);
    const context =
      GlobalContextHelper.getContext().getValue<common.UIAbilityContext | null>(Constants.CALL_SERVICE_CONTEXT);
    if (context == null) {
      this.error('CALL_SERVICE_CONTEXT is null!');
      return;
    }
    const task = new taskpool.Task('queryCallLogTask', queryCallLogTask, callData, context);
    TaskUtil.getInstance().executeTask(task, (value) => {
      this.info(`checkHasAnsweredIncomingCallLog = ${value}`);
      const patch: CallDataPatch = callDataPatcher.createPatch({
        callId: callData.callId,
        hasAnsweredIncomingCallLog: !!value,
      })
      callDataPatcher.apply(callData, patch, 'call log check task result callback');
      CallDataManager.getInstance().updateCallerInfo(patch);
    });
  }

  createMarkStepContext(callData: DefaultCallData): NumberMarkStep {
    // Use callback variable to avoid temporal dead zone (TDZ).
    let complete: Complete = noop;
    let abort: Abort = noop;
    const context: NumberMarkStep = {
      complete: noop,
      abort: noop,
      workingPromise: new Promise<void>((resolve, reject) => {
        this.info(`create mark step promise`);
        complete = resolve;
        abort = reject;
      }),
      callData,
    }
    this.info(`after created mark step context`);
    context.complete = complete;
    context.abort = abort;
    return context;
  }

  private isContactYellowPageNumberMark(callData: DefaultCallData) {
    if ((callData.contactId ?? -1) > 0) {
      this.info('not strange number, type = contact');
      return true;
    }
    const numberMarkInfo = callData.numberMarkInfo;
    if (numberMarkInfo.markType == MarkType.MARK_TYPE_YELLOW_PAGE) {
      this.info('not strange number, type = yellow page');
      return true;
    }
    if (numberMarkInfo.markType > MarkType.MARK_TYPE_NONE) {
      this.info('not strange number, type = number mark');
      return true;
    }
    return false;
  }

  private isOsAccountUnlocked(): boolean {
    const isOsAccountUnlocked = AppStorage.get<boolean>('isOsAccountUnlocked');
    this.info(`isOsAccountUnlocked value = ${isOsAccountUnlocked}`);
    return !!isOsAccountUnlocked;
  }

  private info(msg: string) {
    LogUtils.i('NumberMarkManager', msg);
  }

  private error(msg: string) {
    LogUtils.e('NumberMarkManager', msg);
  }
}


@Concurrent
async function queryCallLogTask(callData: DefaultCallData, context: Context) {
  const TAG = 'CallLogTask';
  LogUtils.i(TAG, `query call log begin`);
  let helper: dataShare.DataShareHelper | undefined;
  try {
    const CALL_LOG_URI = 'datashare:///com.ohos.calllogability';
    const CALL_SUBSECTION = 'datashare:///com.ohos.calllogability/calls/calllog';
    const CALL_PHONE_NUMBER = 'phone_number';
    const CALL_ANSWER_STATE = 'answer_state';
    const CALL_DIRECTION = 'call_direction';
    const phoneNumber = callData.accountNumber;
    helper = await dataShare.createDataShareHelper(context, CALL_LOG_URI);
    LogUtils.i(TAG, `after call log datashare helper created`);
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(CALL_PHONE_NUMBER, phoneNumber);
    predicates.equalTo(CALL_DIRECTION, 0); // incoming call
    predicates.equalTo(CALL_ANSWER_STATE, 1); // accepted calls
    const resultSet = await helper.query(CALL_SUBSECTION, predicates, [CALL_ANSWER_STATE, CALL_DIRECTION]);
    const rowCount = resultSet.rowCount;
    const hasCallLog = rowCount > 0;
    LogUtils.i(TAG, `got ${rowCount} row(s) of call log, is${hasCallLog ? ' not ' : ' '}strange number`);
    resultSet.close();
    return hasCallLog;
  } catch (e) {
    LogUtils.e(TAG, `error when checking call log: ${JSON.stringify(e)}`);
    return false;
  } finally {
    await helper?.close();
  }
}
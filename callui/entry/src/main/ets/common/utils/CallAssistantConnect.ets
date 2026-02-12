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
import common from '@ohos.app.ability.common';
import { rpc } from '@kit.IPCKit';
import { BusinessError } from '@kit.BasicServicesKit';
import Utils from './utils';
import CallStateConst from '../constant/CallStateConst';
import { processSummaryFail } from './CallSummaryUtils';
import { ReportUtil } from './ReportUtils/ReportUtil';
import hiSysEvent from '@ohos.hiSysEvent';

const TAG = 'CallAssistantConnect';
const FAIL_NUMBER: number = -1
const MAX_RETRY: number = 1;
const MODE_BRIEF_TYPE = 11;

export class ConnectionManager {
  private static connectionManager: ConnectionManager
  private summaryConnectionID: number = -1;
  private startTime: number = 0;
  private remoteProxy : rpc.RemoteObject | undefined = undefined;
  private isAutoSummary: boolean = false;

  private constructor() {
  }

  public static getInstance(): ConnectionManager {
    if (ConnectionManager.connectionManager == null) {
      ConnectionManager.connectionManager = new ConnectionManager();
    }
    return ConnectionManager.connectionManager;
  }

  public openCallSummaryByCeliaService(context: common.ServiceExtensionContext | common.UIAbilityContext, want: Want,
    isEnabled: boolean, isAutoSummary: boolean = false) {
    if (isEnabled) {
      let initialRetryCount: number = 0;
      this.isAutoSummary = isAutoSummary;
      // 初始化连接
      this.connectWithRetry(context, want, initialRetryCount);
    }
    let requestSummaryParam: Record<string, boolean> = {
      'isSummaryOn': isEnabled
    }
    this.sendMessage(requestSummaryParam);
    if (isEnabled) {
      this.startTime = Date.now();
    } else {
      const endTime = Date.now();
      const duration = endTime - this.startTime;
      LogUtils.i(TAG, `openCallSummaryByCeliaService duration : ${duration} ms`);
    }
  }

  private connectWithRetry(context: common.ServiceExtensionContext | common.UIAbilityContext, want: Want,
    retryCount: number): void {
    if (this.summaryConnectionID === -1) {
      try {
        this.summaryConnectionID = context.connectServiceExtensionAbility(want, {
          onConnect: (elementName, remote: rpc.RemoteObject) => {
            LogUtils.i(TAG, `connectCeliaSumService onConnect ${this.summaryConnectionID}`);
            this.startTime = Date.now();
            this.remoteProxy = remote;
            let requestSummaryParam: Record<string, boolean> = {
              'isSummaryOn': true
            }
            this.sendMessage(requestSummaryParam);
            // 注册客户端Stub, 实现双向通信
            this.sendServiceStub();
          },
          onDisconnect: (elementName) => {
            LogUtils.i(TAG, 'connectCeliaSumService onDisconnect');
            this.summaryConnectionID = FAIL_NUMBER;
            this.remoteProxy = undefined;
            const endTime = Date.now();
            const duration = endTime - this.startTime;
            LogUtils.i(TAG, `connectCeliaSumService duration : ${duration} ms`);
            ReportUtil.getInstance().reportIntelligentDuration('ABSTRACT_DURATION', duration);
            ReportUtil.getInstance().reportIsAutoSummary('INTELLIGENT_IS_AUTO_SUMMARY',
              hiSysEvent.EventType.STATISTIC, this.isAutoSummary);
          },
          onFailed: (code: number) => {
            LogUtils.e(TAG, `connectCeliaSumService onFailed callback code: ${code}`);
            this.handleRetry(context, want, retryCount);
            this.showToastFailed(retryCount);
          }
        });
      } catch (err) {
        LogUtils.e(TAG, `connectCeliaSumService err code: ${err?.code}, err reason: ${err?.message}`);
        this.handleRetry(context, want, retryCount);
        this.showToastFailed(retryCount);
      }
    }
  }

  private showToastFailed(retryCount: number) {
    if (retryCount >= MAX_RETRY) {
      Utils.getInstance().showToast($r('app.string.summary_failed_turned_on'), 2000);
      ReportUtil.getInstance().reportOpenSummaryFail('summary failed turn on', this.isAutoSummary);
    }
  }

  private handleRetry(context: common.ServiceExtensionContext | common.UIAbilityContext, want: Want,
    retryCount: number): void {
    this.summaryConnectionID = FAIL_NUMBER;
    if (retryCount < MAX_RETRY) {
      retryCount++;
      LogUtils.i(TAG, `connectCeliaSumService retry`);
      this.connectWithRetry(context, want, retryCount);
    }
  }

  private sendMessage(requestParam: Record<string, boolean>) {
    if (!this.remoteProxy) {
      LogUtils.w(TAG, 'Remote proxy is not available');
      return;
    }
    let option = new rpc.MessageOption();
    let dataSequence = rpc.MessageSequence.create();
    let replySequence = rpc.MessageSequence.create();
    try {
      let modeTypeString = JSON.stringify(requestParam);
      dataSequence.writeInterfaceToken(this.remoteProxy.getDescriptor());
      dataSequence.writeString(modeTypeString);
      this.remoteProxy.sendMessageRequest(MODE_BRIEF_TYPE, dataSequence, replySequence, option)
        .then((result: rpc.RequestResult) => {
          resolve(result);
        })
        .catch((err: BusinessError) => {
          reject(err);
        });
    } catch (err) {
      LogUtils.e(TAG, `sendMessageRequest fail, code: ${err?.code}, messeage: ${err?.message}`);
    } finally {
      dataSequence.reclaim();
      replySequence.reclaim();
    }
  }

  private sendServiceStub() {
    if (!this.remoteProxy) {
      return;
    }
    let option = new rpc.MessageOption();
    let dataSequence = rpc.MessageSequence.create();
    let replySequence = rpc.MessageSequence.create();
    try {
      dataSequence.writeInterfaceToken(this.remoteProxy.getDescriptor());
      dataSequence.writeRemoteObject(new CeliaAssistantServiceStub(this.remoteProxy.getDescriptor()));
      // 获取初始化数据
      this.remoteProxy.sendMessageRequest(CallUIRequestType.REGISTRY_CALL_UI_PROXY,
        dataSequence, replySequence, option).then((result: rpc.RequestResult) => {
        if (result.errCode !== 0) {
          LogUtils.e(TAG, `result.errCode is ${result.errCode}`);
          return;
        }
      }).catch((err: BusinessError) => {
        LogUtils.e(TAG, `sendMessageRequest err, code: ${err?.code}, err reason: ${err?.message}`);
      });
    } catch (err) {
      LogUtils.e(TAG, `sendMessageRequest err, code: ${err?.code}, err reason: ${err?.message}`);
    } finally {
      dataSequence.reclaim();
      replySequence.reclaim();
    }
  }
}

function resolve(result: rpc.RequestResult) {
  LogUtils.i(TAG, `Rpc RequestResult, code: ${result.code}`);
}

function reject(err: BusinessError) {
  LogUtils.e(TAG, `Rpc reject, code: ${err?.code}, messeage: ${err?.message}`);
}

export class CeliaAssistantServiceStub extends rpc.RemoteObject {
  constructor(des: string) {
    super(des);
  }

  async onRemoteMessageRequest(
    code: number,
    data: rpc.MessageSequence,
    reply: rpc.MessageSequence,
    options: rpc.MessageOption
  ): Promise<boolean> {
    let token: string = data.readInterfaceToken();
    if (this.checkPermissions(token)) {
      LogUtils.w(TAG, `Check permissions is no permissions`);
      return false;
    }
    if (code === CallUIRemoteType.ON_AUTO_SERVICE_ERROR) {
      let result = data.readString();
      if (!result) {
        LogUtils.w(TAG, `result is empty`);
        return false;
      }
      try {
        const exResult = JSON.parse(result) as CeliaExceptionResult;
        if (exResult.code !== undefined) {
          LogUtils.w(TAG, `Celia exception termination code: ${exResult.code}, message: ${exResult.message}`);
          processSummaryFail();
          return false;
        }
      } catch (err) {
        LogUtils.e(TAG, `onRemoteMessageRequest error: ${err?.code}`);
      }
    }
    LogUtils.i(TAG, `onRemoteMessageRequest is success, not expection`);
    return true;
  }

  private checkPermissions(token: string): boolean {
    return this.getDescriptor() !== token;
  }
}

/**
 * 监听小艺返回的结果
 */
interface CeliaExceptionResult {
  /** 异常标志 */
  code: number;

  /** 错误信息 */
  message: string;
}

export enum CeliaCode {
  /** 摘要执行异常终止，或小艺服务进程异常终止 */
  ExceptionTermination = 0,

  /** 音频流获取失败 */
  AudioStreamFailed = 1
}

// 来自CallUI的请求
export enum CallUIRemoteType {
  // 抛出摘要运行时异常
  ON_AUTO_SERVICE_ERROR = 0,
}

// 来自CallUI的请求
export enum CallUIRequestType {
  // 打开/关闭通话摘要
  CLICK_MODE_BRIEF = 11,

  // 注册CallUI伪服务
  REGISTRY_CALL_UI_PROXY = 12,
}
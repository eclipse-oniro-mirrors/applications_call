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

/**
 * @file: Voice call API interface call
 */

import call from '@ohos.telephony.call';
import LogUtils from '../common/utils/LogUtils';
import { ReportUtil } from '../common/utils/ReportUtils/ReportUtil';
import CallStateConst from '../common/constant/CallStateConst';
import { MarkType } from '../common/struct/TypeUtils';
import hiTraceChain from '@ohos.hiTraceChain';

const prefixLog = 'callui service:@ohos.telephony.call:';
const TAG = 'TelephonyApi';

export default class TelephonyApi {
  /**
   * register call state callback
   *
   * @param { Function } callBack - inject an Function
   */
  public registerCallStateCallback(callBack: Function) {
    try {
      call.on('callDetailsChange', (data: call.CallAttributeOptions) => {
        if (!data) {
          LogUtils.i(TAG, prefixLog + 'call.on registerCallStateCallback');
          return;
        }
        let dataStr: string = 'id: ' + data.callId + ', callState: ' + data.callState +
          ', conferenceState: ' + data.conferenceState + `,isEcc: ${data.isEcc}`;
        LogUtils.i(TAG, prefixLog + 'callDetailsChange ' + dataStr);
        if (!data.numberMarkInfo) {
          data.numberMarkInfo = {
            markType: MarkType.MARK_TYPE_NONE, markContent: ''
          };
        }
        if (data.extraParams && data.extraParams['traceChainId'] && data.extraParams['traceFlags']) {
          let newTraceId = hiTraceChain.getId()
          if(newTraceId != undefined) {
            newTraceId.chainId = BigInt(data.extraParams['traceChainId'] as string)
            newTraceId.flags = Number(data.extraParams['traceFlags'] as string)
            hiTraceChain.setId(newTraceId)
          }
        }
        //callBack(data);
        //TODO 临时方案，强制显示“HD“图标
        /*
         * 来去电页面的“HD”高清通话图标是否显示由callType的值决定，为TYPE_IMS时显示；
         * 目前callType的取值来自call.on('callDetailsChange')通话时通话详情的变化的监听回调；
         * callType的值一直为TYPE_CS。也就是现在的通话模式是CS模式；
         * 而且通话模式由系统自动选择最优路线，应用层没办法手动修改为IMS模式。
         * 【处理方案】目前使用临时处理方案，修改callType属性强制显示通话界面的“HD"图标。
         * */
        let newData = data
        newData.callType = 1 //将callType赋值为TYPE_IMS（临时方案）
        callBack(newData);//执行回调（临时方案）

        if (data.callState === CallStateConst.CALL_STATUS_ACTIVE && ReportUtil.getInstance().callAnswerTime > 0) {
          ReportUtil.getInstance().isCallAnswerResponseTimeout(data.callType);
        }
      });
    } catch (err) {
      LogUtils.e(TAG, `Subscribe to the callDetailsChange event failed, err: ${JSON.stringify(err)}`);
    }
  }

  /**
   * onRegister call state callback
   */
  public unRegisterCallStateCallback() {
    try {
      call.off('callDetailsChange', (data: call.CallAttributeOptions) => {
        if (!data) {
          LogUtils.i(TAG, prefixLog + 'call.off unRegisterCallStateCallback error');
          return;
        }
        LogUtils.i(TAG, prefixLog + 'call.off unRegisterCallStateCallback');
      });
    } catch (err) {
      LogUtils.e(TAG, `Unsubscribe from the callDetailsChange event failed, err: ${JSON.stringify(err)}`);
    }
  }
}
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

import FuncBtn from './FuncBtn.ets';
import InComDialog from './InComDialog.ets';
import ImagePathConst from '../constant/ImagePathConst.ets';
import CallStateConst from '../constant/callStateConst.ets';
import CallServiceProxy from '../../model/CallServiceProxy.ets';
import sms from '@ohos.telephony.sms';
import resourceManager from '@ohos.resourceManager';
import prompt from '@system.prompt';
import HiLog from '../utils/Hilog.ets';

const TAG = "IncomingCom";
const SMS_REJECTION = `${ImagePathConst.BASE_URL}ic_public_message.svg`;
const SMS_REMINDER = `${ImagePathConst.BASE_URL}remindDisabled.png`;

/**
 * SMS sent successfully
 */
const SEND_SMS_SUCCESS = 0;

/**
 * Failed to send SMS for unknown reason
 */
const SEND_SMS_FAILURE_UNKNOWN = 1;

/**
 * The wireless module for sending text messages is turned off
 */
const SEND_SMS_FAILURE_RADIO_OFF = 2;

/**
 * The network sending the text message is unavailable
 */
const SEND_SMS_FAILURE_SERVICE_UNAVAILABLE = 3;

@Component
export default struct IncomingCom {
  @State SendResult: any = {};
  @Link callData: any;
  private btnList= [];
  private msgList = [];
  private remindList= [];
  mCallServiceProxy: CallServiceProxy= null;

  msgDialogController: CustomDialogController = new CustomDialogController
  ({
    builder: InComDialog({
      cancel: () => {
      },
      confirm: (item) => {
        HiLog.i(TAG, "confirm : %s");
        this.msgItemClick(item);
      },
      cancelHandle: () => {
      },
      List: this.msgList
    }),
    cancel: () => {
    },
    customStyle: true
  });

  private aboutToAppear(): void {
    this.mCallServiceProxy = CallServiceProxy.getInstance();
    this.getMsgList();
    this.getBtnList();
  }

  /**
   * send Message   slotId : card slot, destinationHost : accountNumber ,content: content
   *
   * @param obj
   */
  private sendMessage(obj) {
    let slotId = 0
    let destinationHost = this.callData.accountNumber
    let content: string = "";
    resourceManager.getResourceManager().then(result => {
      result.getString(obj.msg.id, (err, typeName) => {
        content = typeName
        HiLog.i(TAG, "sendMessage  resourceManager.getResourceManager : " );
        return new Promise(function (resolve, reject) {
          if(globalThis.sendPermissionFlag){
            sms.sendMessage({
              slotId: slotId,
              destinationHost: destinationHost,
              content: content,
              sendCallback: (err, sendResult) => {
                this.SendResult = sendResult
                if (err) {
                  reject(err);
                } else {
                  if (sendResult.result === SEND_SMS_SUCCESS) {
                    resolve(true);
                  } else {
                    resolve(false);
                  }
                }
              }
            });
          }
        }
        );
      })
    })
  }

  private getMsgList() {
    this.msgList = [
      {
        id: 1,
        msg: $r("app.string.backLater")
      },
      {
        id: 2,
        msg: $r("app.string.answerThePhone")
      },
      {
        id: 3,
        msg: $r("app.string.contactMeLater")
      },
      {
        id: 4,
        msg: $r("app.string.beThereSoon")
      },
    ];
  }

  private getBtnList() {
    this.btnList = [
      {
        type: 'msg',
        iconText: $r("app.string.sms"),
        iconDefaultUrl: SMS_REJECTION,
        iconDisableUrl: SMS_REJECTION,
        isDisable:false
      },
    
    ];
  }

  /**
   * Call rejection interface
   *
   * @param {string} msg - Send SMS content
   */
  private msgItemClick(obj) {
    let Content: string = "";
    let Err: string = "";
    this.sendMessage(obj)
    if (this.SendResult) {
      resourceManager.getResourceManager().then(result => {
        result.getString($r("app.string.SMS_Sent").id, (err, typeName) => {
          Content = typeName
          prompt.showToast({
            message: this.callData.contactName ? Content + `${this.callData.contactName}` : Content + `${this.callData.accountNumber}`,
            duration: 2000,
          });
          this.mCallServiceProxy.rejectCall(this.callData.callId, obj.msg);
          HiLog.i(TAG, "msgItemClick : " );
        })
      })
    } else {
      resourceManager.getResourceManager().then(result => {
        result.getString($r("app.string.message_Failed").id, (err, typeName) => {
          Err = typeName
          prompt.showToast({
            message: Err ,
            duration: 2000,
          });
        })
      })
    }
  }

  /**
   * Handling interface call hangup and rejection
   */
  private async onReject() {
    const {callId, callState} = this.callData;
    if (callState !== CallStateConst.CALL_STATUS_WAITING) {
      this.mCallServiceProxy.rejectCall(callId);
      HiLog.i(TAG, "onReject this.mCallServiceProxy.rejectCall : ");
    } else {
      this.mCallServiceProxy.hangUpCall(callId);
      HiLog.i(TAG, "onReject this.mCallServiceProxy.hangUpCall : ");
    }
  }

  /**
   * Enable the SMS reply pop-up
   */
  private btnClick(type){
    HiLog.i(TAG, "btnClick : %s");
    if (type === 'msg') {
      this.msgDialogController.open();
    }
  }

  /**
   * Answer the phone interface
   */
  private onAnswer() {
    HiLog.i(TAG, "onAnswer : ");
    this.mCallServiceProxy.acceptCall(this.callData.callId);
  }

  build() {
    GridContainer({  gutter: 24, margin: 24 } ) {
      Row() {
        GridContainer({ gutter:24, margin:0 }) {
          Row() {
            ForEach(this.btnList, (item) => {
              Column() {
                FuncBtn({
                  btnType: item.type,
                  iconDisableUrl: item.iconDefaultUrl,
                  iconDefaultUrl:item.iconDefaultUrl,
                  iconText: item.iconText,
                  isDisable:item.isDisable,
                  btnClick: (type) => {
                    this.btnClick(type)
                  }
                })
              }
            })
          }
          .height(51)
          .useSizeType({
            sm: { span: 4, offset: 0 },
            md: { span: 8, offset: 0 },
            lg: { span: 12, offset: 0 }
          })

          Row() {
            Column() {
              Image($r("app.media.ic_public_ring_off"))
                .width(56)
                .height(56)
                .onClick(() => {
                  this.onReject()
                })
            }
            .useSizeType({
              sm: { span: 2, offset: 0 },
              md: { span: 4, offset: 0 },
              lg: { span: 6, offset: 0 }
            })

            Column() {
              Image($r("app.media.ic_public_answer"))
                .width(56)
                .height(56)
                .onClick(() => {
                  this.onAnswer()
                })
            }
            .useSizeType({
              sm: { span: 2, offset: 2 },
              md: { span: 4, offset: 4 },
              lg: { span: 6, offset: 6 }
            })
          }
          .margin({ top: 30 })
        }
      }
      .useSizeType({
        sm: { span: 4, offset: 0 },
        md: { span: 6, offset: 1 },
        lg: { span: 6, offset: 3 }
      })
    }
  }
}

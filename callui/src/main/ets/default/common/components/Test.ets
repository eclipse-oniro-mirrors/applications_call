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

import  callStateConst from '../constant/CallStateConst.ets';
import router from '@system.router';
import callManger from '../../model/CallManager.ets'
import HiLog from '../utils/Hilog.ets';

const TAG = "Test";

@Component
export default struct Test {
  private numValue: Number = 0;
  @State showList:boolean =false;
  public btnList = [
    {
      id: 1,
      type: 'active',
      txt: '正在通话',
      callState: 0,
      videoState: 0,
      conferenceState: 0
    },
    {
      id: 2,
      type: 'holding',
      txt: '通话挂起保持',
      callState: 1,
      videoState: 0,
      conferenceState: 0
    },
    {
      id: 3,
      type: 'dialing',
      txt: '拨号开始',
      callState: 2,
      videoState: 0,
      conferenceState: 0
    },
    {
      id: 4,
      type: 'alerting',
      txt: '正在呼出',
      callState: 3,
      videoState: 0,
      conferenceState: 0
    },
    {
      id: 5,
      type: 'incoming',
      txt: '对方来电',
      callState: 4,
      videoState: 0,
      conferenceState: 0
    },
    {
      id: 6,
      type: 'waiting',
      txt: '第三方来电等待',
      callState: 5,
      videoState: 0,
      conferenceState: 0
    },
    {
      id: 7,
      type: 'disconnected',
      txt: '挂断完成',
      callState: 6,
      videoState: 0,
      conferenceState: 0
    },
  ];
  private firstCallData = {
    callId: 1001,
    callState: 8,
    accountNumber: '13888888888',
    videoState: 0,
    callType: 0,
    startTime: 0,
    contactName: '幸运虾',
    conferenceState: 0
  };
  private secondCallData = {
    callId: 1002,
    callState: 8,
    accountNumber: '13666666666',
    videoState: 0,
    callType: 0,
    startTime: 0,
    contactName: '倒霉虾',
    conferenceState: 0
  };
  private mCallManger: callManger;
  @State test: boolean = false;
  @Link callData : any;
  @Link callList:Array<any>;

  private aboutToAppear(): void {
    this.mCallManger =new callManger(this)
  }

  onDialClick() {
    router.push({
      uri: 'pages/dial/dial',
    });
  }

  onMenuSelected(item) {
    let id = parseInt(item.id);
    const targetObj = this.btnList.find((v) => v.id === id);
    HiLog.i(TAG, "onMenuSelected : %s" + JSON.stringify(targetObj));
    const { callState, videoState, conferenceState } = targetObj;
    let obj = {};
    let len = this.callList.length;
    if ((targetObj.callState === 5 && len === 1) || len > 1) {
      if (targetObj.callState === 0) {
        this.mCallManger.update({ ...this.firstCallData, callState: 1 });
      }
      Object.assign(obj, {
        ...this.secondCallData,
        callState,
        videoState,
        conferenceState
      });
    } else {
      Object.assign(obj, {
        ...this.firstCallData,
        callState,
        videoState,
        conferenceState
      });
    }
    this.mCallManger.update(obj);
    HiLog.i(TAG, "onMenuSelected end : " );
  }
  
  build() {
    Column(){
      Button('测试')
        .onClick(() => {
          this.showList = !this.showList
        })
      Column() {
        ForEach(this.btnList, (item) => {
          Column() {
            Text(item.txt)
            .padding(5)
            .fontSize(25)
          }
          .onClick(() => {
            this.showList =! this.showList
            this.onMenuSelected(item)
          })
        })
      }
      .borderWidth(1)
      .borderRadius(5)
      .visibility(this.showList ? Visibility.Visible:Visibility.Hidden)
      .backgroundColor(Color.White)
    }
  }
}


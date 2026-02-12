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

import { describe, it, expect, MockKit, when, ArgumentMatchers } from '@ohos/hypium';
import { RECORDING_WAY_ALL_NUMBER } from '../../../../../main/ets/common/constant/CallRecorderConst';
import CallStateConst from '../../../../../main/ets/common/constant/CallStateConst';
import { RecordConfigDataStruct, RecordInputData } from '../../../../../main/ets/common/struct/RecordingStruct';
import DefaultCallData from '../../../../../main/ets/common/struct/TypeUtils';
import Recording from '../../../../../main/ets/common/utils/Recording';
import { VideoStateType } from '../../../../../main/ets/common/utils/VideoCallApi';
import { sleep } from '../../Utils';
import { GlobalContextHelper } from '../../../../../main/ets/common/utils/GlobalContextHelper';
import * as Constants from '../../../../../main/ets/common/utils/Constants';
import common from '@ohos.app.ability.common';

let callData: DefaultCallData[] = [
  {
    videoState: VideoStateType.TYPE_VOICE,
    callState: CallStateConst.CALL_STATUS_ANSWER,
    accountId: 0,
    accountNumber: '',
    callId: 0,
    callType: CallStateConst.TYPE_IMS,
    conferenceState: 0,
    contactName: '',
    formatNumber: '123456789',
    isEcc: false,
    startTime: 0,
    numberLocation: '',
    contactCompany: '',
    contactCompanyPosition: '',
    numberMarkInfo: { markContent: '', markType: -1, markCount: -1 },
  }
]

let recordData: RecordInputData = {
  callId: 1,
  accountNumber: '1234567',
  mode: 0,
  startTime: 110011,
  callList: callData,
  fileNameStr: '1234567'
}

let recordingStart_test = () => {
  Recording.getInstance().recordingStart(recordData);
  expect(recordData.callId).assertEqual(1);
}

let recordingGetIsError_test = () => {
  let ret = Recording.getInstance().recordingGetIsError();
  expect(ret != undefined).assertTrue();
}

let addRPCErrorListener_test = () => {
  Recording.getInstance().addRPCErrorListener();
  sleep(1000);
  expect(recordData.accountNumber).assertEqual('1234567');
}

let removeRPCErrorListener_test = () => {
  Recording.getInstance().removeRPCErrorListener();
  sleep(1000);
  expect(recordData.startTime).assertEqual(110011);
}

let recordingStartRpc_test = () => {
  Recording.getInstance().recordingStartRpc(recordData);
  expect(true).assertTrue();
}

let autoStartAnotherRecord_test = () => {
  Recording.getInstance().autoStartAnotherRecord(callData[0]);
  expect(true).assertTrue();
}

let autoStopById_test = () => {
  Recording.getInstance().autoStopById(1);
  expect(true).assertTrue();
  Recording.getInstance().autoStopById(-1);
  expect(true).assertTrue();
}

let onRecordDisconnected_test = () => {
  let mocker: MockKit = new MockKit();
  let mockFunc: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc)('recorderStatus').afterReturn('stop');
  Recording.getInstance().onRecordDisconnected('string', true);
  expect(true).assertTrue();
  Recording.getInstance().onRecordDisconnected('string', false);
  expect(true).assertTrue();
  mocker.clear(AppStorage);
}

let isDesignateNumber_test = async () => {
  let mocker: MockKit = new MockKit();
  let mockFunc: Function = mocker.mockFunc(Recording, Recording.getInstance().getIsDesignateNumber);
  when(mockFunc)('1234567').afterReturn(new Promise<string>((res: Function, rej: Function) => {
    res(0);
  }));
  await Recording.getInstance().isDesignateNumber(recordData);
  sleep(1000);
  expect(true).assertTrue();
  when(mockFunc)('1234567').afterReturn(new Promise<string>((res: Function, rej: Function) => {
    res(true);
  }));
  let textContext = AppStorage.get<common.UIAbilityContext>('testAbility');
  if (!textContext) {
    return;
  }
  GlobalContextHelper.getContext().set(Constants.CALL_SERVICE_CONTEXT, textContext);
  await Recording.getInstance().isDesignateNumber(recordData);
  sleep(1000);
  expect(true).assertTrue();
  mocker.clear(Recording);
}

let getIsDesignateNumber_test = async () => {
  let textContext = AppStorage.get<common.UIAbilityContext>('testAbility');
  if (!textContext) {
    return;
  }
  GlobalContextHelper.getContext().set(Constants.CALL_SERVICE_CONTEXT, textContext);
  let result = await Recording.getInstance().getIsDesignateNumber('1234567');
  expect(result).assertFalse();
}
let getIsDesignateNumber_test_01 = async () => {
  let recording = Recording.getInstance();
  let mocker: MockKit = new MockKit();
  let mockFunc = mocker.mockFunc(recording, recording.queryRecorderConfig);
  let testResult: RecordConfigDataStruct = {
    isOpen: 0, object: RECORDING_WAY_ALL_NUMBER
  };
  when(mockFunc)(ArgumentMatchers.any).afterReturn(testResult);
  let result = await Recording.getInstance().getIsDesignateNumber('1234567');
  expect(result).assertFalse();
  mocker.ignoreMock(Recording, recording.queryRecorderConfig);
  mocker.clearAll();
}
let getIsDesignateNumber_test_02 = async () => {
  let recording = Recording.getInstance();
  let mocker: MockKit = new MockKit();
  let mockFunc = mocker.mockFunc(recording, recording.queryRecorderConfig);
  let testResult: RecordConfigDataStruct = {
    isOpen: 1, object: RECORDING_WAY_ALL_NUMBER
  };
  when(mockFunc)(ArgumentMatchers.any)
    .afterReturn(new Promise<RecordConfigDataStruct>((resolve: Function, reject: Function) => {
      resolve(testResult);
    }));
  let result = await Recording.getInstance().getIsDesignateNumber('1234567');
  expect(result).assertTrue();
  mocker.ignoreMock(Recording, recording.queryRecorderConfig);
  mocker.clearAll();
}
let getIsDesignateNumber_test_03 = async () => {
  let recording = Recording.getInstance();
  let mocker: MockKit = new MockKit();
  let mockFunc = mocker.mockFunc(recording, recording.queryRecorderConfig);
  let testResult: RecordConfigDataStruct = {
    isOpen: 1, object: ""
  };
  when(mockFunc)(ArgumentMatchers.any)
    .afterReturn(new Promise<RecordConfigDataStruct>((resolve: Function, reject: Function) => {
      resolve(testResult);
    }));
  let result = await Recording.getInstance().getIsDesignateNumber('1234567');
  expect(result).assertFalse();
  let result1 = await Recording.getInstance().getIsDesignateNumber('');
  expect(result1).assertFalse();
  mocker.ignoreMock(Recording, recording.queryRecorderConfig);
  mocker.clearAll();
}

let changeRecorderStatus_test = () => {
  let mocker: MockKit = new MockKit();
  let mockFunc: Function = mocker.mockFunc(AppStorage, AppStorage.get);
  when(mockFunc)('recorderStatus').afterReturn('start');
  Recording.getInstance().changeRecorderStatus();
  expect(true).assertTrue();
  when(mockFunc)('recorderStatus').afterReturn('disabled');
  Recording.getInstance().changeRecorderStatus();
  expect(true).assertTrue();
  mocker.clear(AppStorage);
  mocker.clearAll();
}
let getRecordCallId_test = () => {
  let recording = Recording.getInstance();
  recording.onRecordDisconnected('test', false);
  let result = recording.getRecordCallId();
  expect(result).assertEqual(-1);
}

let compareNum_test = () => {
  let ret = Recording.getInstance().compareNum('12345678901', '02987668100');
  expect(ret).assertFalse();
}

export default function RecordingTest() {
  describe('RecordingTest', () => {
    it('RecordingTest_recordingStart', 0, () => {
      recordingStart_test();
    });
    it('RecordingTest_recordingGetIsError', 0, () => {
      recordingGetIsError_test();
    });
    it('RecordingTest_addRPCErrorListener', 0, () => {
      addRPCErrorListener_test();
    });
    it('RecordingTest_removeRPCErrorListener', 0, () => {
      removeRPCErrorListener_test();
    });
    it('RecordingTest_recordingStartRpc', 0, () => {
      recordingStartRpc_test();
    });
    it('RecordingTest_autoStartAnotherRecord', 0, () => {
      autoStartAnotherRecord_test();
    });
    it('RecordingTest_autoStopById', 0, () => {
      autoStopById_test();
    });
    it('RecordingTest_onRecordDisconnected', 0, () => {
      onRecordDisconnected_test();
    });
    it('RecordingTest_isDesignateNumber', 0, async () => {
      await isDesignateNumber_test();
    });
    it('RecordingTest_getIsDesignateNumber', 0, async () => {
      await getIsDesignateNumber_test();
    });
    it('RecordingTest_changeRecorderStatus', 0, () => {
      changeRecorderStatus_test();
    });
    it('RecordingTest_getIsDesignateNumber_01', 0, async () => {
      await getIsDesignateNumber_test_01();
      await getIsDesignateNumber_test_02();
      await getIsDesignateNumber_test_03();
    });
    it('RecordingTest_getRecordCallId_test', 0, () => {
      getRecordCallId_test();
    });
    it('RecordingTest_compareNum_test', 0, () => {
      compareNum_test();
    });
  })
}

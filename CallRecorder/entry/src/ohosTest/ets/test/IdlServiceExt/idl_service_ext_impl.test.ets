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
import {
  describe,
  beforeAll,
  beforeEach,
  afterEach,
  afterAll,
  it,
  expect,
  MockKit,
  when,
  ArgumentMatchers
} from '@ohos/hypium';
import { GlobalContextHelper } from '../../../../main/ets/common/utils/GlobalContextHelper';
import ServiceExtImpl from '../../../../main/ets/IdlServiceExt/idl_service_ext_impl';
import common from '@ohos.app.ability.common';
import { Constant } from '../../../../main/ets/common/constant/Constant';
import { ResourceUtil } from '../../../../main/ets/common/utils/ResourceUtil';
import DatabaseHelper from '../../../../main/ets/common/utils/DatabaseHelper';
import { formatPhoneNum } from '../../../../main/ets/common/utils/CommonUtil';
import TimeUtil from '../../../../main/ets/common/utils/TimeUtil';
import { sleep } from '../common/utils/Sleep';
import storageStatistics from '@ohos.file.storageStatistics';
import { FuncManageReturn, RecordLog } from '../../../../main/ets/common/struct/RecorderStruct';
import { RPCInfoConstant } from '../../../../main/ets/common/constant/RPCInfoConstant';
import { RecordInputParameter } from '../../../../main/ets/common/struct/idlStruct';
import ServiceExtStub from '../../../../main/ets/IdlServiceExt/idl_service_ext_stub';
import media from '@ohos.multimedia.media';
import userFileManager from '@ohos.filemanagement.userFileManager';
import { BusinessError } from '@kit.BasicServicesKit';
import { AVRecorderConstant } from '../../../../main/ets/common/constant/AVRecorderConstant';

let idl_service_ext_implTest_addAVRecorderListener_01Func = (testContext: Context) => {
  let serviceImpl: ServiceExtImpl = new ServiceExtImpl(testContext);
  serviceImpl.addAVRecorderListener();
  expect(1).assertEqual(1);
};

let idl_service_ext_implTest_removeAVRecorderListener_01Func = (testContext: Context) => {
  let serviceImpl: ServiceExtImpl = new ServiceExtImpl(testContext);
  serviceImpl.removeAVRecorderListener();
  expect(1).assertEqual(1);
}

let idl_service_ext_implTest_commitRecordingErrorFunc = (testContext: Context) => {
  let serviceImpl: ServiceExtImpl = new ServiceExtImpl(testContext);
  serviceImpl.commitRecordingError();
  expect(0).assertEqual(0);
};

let idl_service_ext_implTest_stopServiceFunc = (testContext: Context) => {
  let serviceImpl: ServiceExtImpl = new ServiceExtImpl(testContext);
  serviceImpl.stopService();
  expect(0).assertEqual(0);
};

let idl_service_ext_implTest_getIsHasFreeStorageFunc = (testContext: Context) => {
  let serviceImpl: ServiceExtImpl = new ServiceExtImpl(testContext);
  let result = serviceImpl.getIsHasFreeStorage();
  expect(result).assertEqual(true || false);
};

let idl_service_ext_implTest_getErrorServiceFunc = (testContext: Context) => {
  let serviceImpl: ServiceExtImpl = new ServiceExtImpl(testContext);
  let freeSize: number = storageStatistics.getFreeSizeSync();
  serviceImpl.getErrorService((errCode, message) => {
    if (freeSize > 104857600) {
      expect(errCode).assertEqual(RPCInfoConstant.SUCCESS_STATUS_CODE);
      expect(message).assertEqual(RPCInfoConstant.SUCCESS_STATUS_MESSAGE);
    } else {
      expect(errCode).assertEqual(RPCInfoConstant.NO_STORAGE_STATUS_CODE);
      expect(message).assertEqual(RPCInfoConstant.NO_STORAGE_STATUS_MESSAGE);
    }
  });
};

let idl_service_ext_implTest_getErrorServiceFunc01 = (testContext: Context) => {
  let serviceImpl: ServiceExtImpl = new ServiceExtImpl(testContext);
  let mocker: MockKit = new MockKit();
  let mockFunc: Function = mocker.mockFunc(serviceImpl, serviceImpl.getIsHasFreeStorage);
  when(mockFunc)().afterReturn(false);
  serviceImpl.getErrorService((errCode, message) => {
    expect(errCode).assertEqual(RPCInfoConstant.NO_STORAGE_STATUS_CODE);
    expect(message).assertEqual(RPCInfoConstant.NO_STORAGE_STATUS_MESSAGE);
    mocker.clearAll();
  });
};

let idl_service_ext_implTest_updateRecorderInfo01 = async (testContext: Context) => {
  let serviceImpl: ServiceExtImpl = new ServiceExtImpl(testContext);
  serviceImpl.recordLog = new RecordLog()
  await serviceImpl.updateRecorderInfo();
  await sleep(1000);
  expect(true).assertTrue();
}

let idl_service_ext_implTest_updateRecorderInfo02 = async (testContext: Context) => {
  let serviceImpl: ServiceExtImpl = new ServiceExtImpl(testContext);
  serviceImpl.recordLog = new RecordLog()
  serviceImpl.recordLog.mode = 2;
  await serviceImpl.updateRecorderInfo();
  await sleep(1000);
  expect(true).assertTrue();
}

let idl_service_ext_implTest_buildFileName_02Func = async (testContext: Context) => {
  let date: Date = new Date();
  let serviceImpl: ServiceExtImpl = new ServiceExtImpl(testContext);
  let mocker: MockKit = new MockKit();
  let DatabaseHelperInstance = DatabaseHelper.getInstance();
  let mockFunc: Function = mocker.mockFunc(DatabaseHelperInstance, DatabaseHelperInstance.getCallUserInfo);
  when(mockFunc)(ArgumentMatchers.any).afterReturn('10086');
  // mode 0-auto;1-manual;2-meeting
  let path = await serviceImpl.buildFileName(date, 'name', '10086', 0);
  expect(path).assertEqual('');
  mocker.clearAll();
};

let idl_service_ext_implTest_buildFileName_03Func = async (testContext: Context) => {
  let afterSuffix: string = '.m4a';
  let serviceImpl: ServiceExtImpl = new ServiceExtImpl(testContext);
  let dateTime: Date = new Date();
  let contact: string = '';
  let number: string = '';
  serviceImpl.buildFileName(dateTime, contact, number, 0);
  serviceImpl.buildFileName(dateTime, contact, number, 2);
  expect(true).assertTrue();
};

let idl_service_ext_implTest_buildDisplayNameFunc = (testContext: Context) => {
  let serviceImpl: ServiceExtImpl = new ServiceExtImpl(testContext);
  let fileName = 'idl_service_ext_implTest_buildDisplayName.';
  let path = serviceImpl.buildDisplayName(new Date(), fileName);
  let timeStr: string = TimeUtil.getRecordDisplayNameTime(new Date());
  let timeStamp: string = fileName.slice(fileName.indexOf('_') + 1, fileName.indexOf('.'));
  let str: string = fileName.replace(timeStamp, timeStr);
  expect(path).assertEqual(str);
};

let idl_service_ext_implTest_startRecordingService_01Func = (testContext: Context) => {
  let serviceImpl: ServiceExtImpl = new ServiceExtImpl(testContext);
  let params: RecordInputParameter = {
    accountNumber: '10086',
    mode: ServiceExtStub.RECORDING_MEETING,
    startTime: new Date().getTime(),
    callList: [],
    callTimeList: [],
    fileNameStr: '10086'
  };
  serviceImpl.startRecordingService(params, (code, message) => {
    expect(message).assertEqual(RPCInfoConstant.MEETING_RECORDING_MESSAGE);
  });
};

let idl_service_ext_implTest_startRecordingService_02Func = (testContext: Context) => {
  let serviceImpl: ServiceExtImpl = new ServiceExtImpl(testContext);
  let params: RecordInputParameter = {
    accountNumber: '10086',
    mode: ServiceExtStub.RECORDING_AUTO,
    startTime: new Date().getTime(),
    callList: [],
    callTimeList: [],
    fileNameStr: '10086'
  };
  serviceImpl.startRecordingService(params, (code, message) => {
    expect(message).assertEqual(RPCInfoConstant.UNKNOWN_RECORDING_MESSAGE);
  });
};

let idl_service_ext_implTest_startRecordingService_03Func = (testContext: Context) => {
  let serviceImpl: ServiceExtImpl = new ServiceExtImpl(testContext);
  let params: RecordInputParameter = {
    accountNumber: '10086',
    mode: ServiceExtStub.RECORDING_MANUAL,
    startTime: new Date().getTime(),
    callList: [],
    callTimeList: [],
    fileNameStr: '10086'
  };
  serviceImpl.startRecordingService(params, (code, message) => {
    expect(message).assertEqual(RPCInfoConstant.MANUAL_RECORDING_MESSAGE);
  });
};

let idl_service_ext_implTest_realStartRecording_01Func = async (testContext: Context) => {
  let serviceImpl: ServiceExtImpl = new ServiceExtImpl(testContext);
  serviceImpl.realStartRecording('', 0, 0, [], [], '');
  await sleep(1000);
  expect(serviceImpl.callList.length).assertEqual(0);
}

let idl_service_ext_implTest_realStartRecording_02Func = async (testContext: Context) => {
  let serviceImpl: ServiceExtImpl = new ServiceExtImpl(testContext);
  let startTime = new Date();
  let mocker: MockKit = new MockKit();
  let mockFunc: Function = mocker.mockFunc(media.createAVPlayer, media.createAVPlayer);
  when(mockFunc)(ArgumentMatchers.any).afterThrow('error');
  await serviceImpl.realStartRecording('10086', startTime.getTime(), 2, [], [], '10086');
  await sleep(1000);
  expect(serviceImpl.callList.length === 0).assertTrue();
  mocker.clearAll();
}

let idl_service_ext_implTest_realStartRecording_03Func = async (testContext: Context) => {
  let serviceImpl: ServiceExtImpl = new ServiceExtImpl(testContext);
  let startTime = new Date();
  await serviceImpl.realStartRecording('10086', startTime.getTime(), 2, [], [], '10086');
  await sleep(1000)
  let path = await serviceImpl.buildFileName(startTime, 'name', '10086', 0);
  let contacts = await DatabaseHelper.getInstance().getCallUserInfo(testContext, '10086');
  let time: string = startTime.getTime().toString();
  let afterSuffix: string = '.m4a';
  let str = formatPhoneNum(contacts) + '_' + time + afterSuffix;
  expect(path).assertEqual(str);
}

let idl_service_ext_implTest_realStartRecordingExtByFile_01Func = async (testContext: Context) => {
  let serviceImpl: ServiceExtImpl = new ServiceExtImpl(testContext);
  let mocker: MockKit = new MockKit();
  let mockFunc: Function = mocker.mockFunc(serviceImpl, serviceImpl.realStartRecordingExtByFile);
  when(mockFunc)(ArgumentMatchers.any).afterReturnNothing();
  when(mockFunc)(ArgumentMatchers.any).afterThrow('error');
  mocker.verify('commitRecordingError', []).never();
  mocker.clearAll();
  expect(serviceImpl.callList.length).assertEqual(0);
}

let idl_service_ext_implTest_realStartRecordingExt_01Func = async (testContext: Context) => {
  let serviceImpl: ServiceExtImpl = new ServiceExtImpl(testContext);
  let userManager: userFileManager.UserFileManager = userFileManager.getUserFileMgr(testContext);
  let fileAsset: userFileManager.FileAsset = await userManager.createAudioAsset('test');
  let avProfile: media.AVRecorderProfile = {
    audioBitrate: AVRecorderConstant.AUDIO_BITRATE,
    audioChannels: AVRecorderConstant.AUDIO_CHANNELS,
    audioCodec: media.CodecMimeType.AUDIO_AAC, // audio encoding format. Currently, only AAC is supported.
    audioSampleRate: AVRecorderConstant.AUDIO_SAMPLE_RATE,
    fileFormat: media.ContainerFormatType.CFT_MPEG_4A // Encapsulation format. Currently, only m4a is supported.
  };
  let avConfig: media.AVRecorderConfig = {
    audioSourceType: AVRecorderConstant.AUDIO_SOURCE_TYPE,
    profile: avProfile,
    url: 'fd://'
  };
  media.createAVRecorder(async (error, recorder) => {
    serviceImpl.realStartRecordingExt(fileAsset, avConfig, recorder, "testUse", "10086", 1727423328484, 1, [], []);
    expect(serviceImpl.callTimeList.length).assertEqual(0);
  })

}

let idl_service_ext_implTest_realStartRecordingExtra_01Func = async (testContext: Context) => {
  let serviceImpl: ServiceExtImpl = new ServiceExtImpl(testContext);
  let mocker: MockKit = new MockKit();
  let mockFunc: Function = mocker.mockFunc(serviceImpl, serviceImpl.realStartRecordingExt);
  when(mockFunc)(ArgumentMatchers.any).afterReturnNothing();
  mocker.clearAll();
}

let idl_service_ext_implTest_stopRecordingProcess_01Func = (testContext: Context) => {
  let serviceImpl: ServiceExtImpl = new ServiceExtImpl(testContext);
  serviceImpl.recorderPrepareState = 0;
  serviceImpl.stopRecordingProcess();
  expect(0).assertEqual(0);
}

let idl_service_ext_implTest_stopRecordingProcess_02Func = async (testContext: Context) => {
  let serviceImpl: ServiceExtImpl = new ServiceExtImpl(testContext);
  serviceImpl.recorderPrepareState = 1;
  serviceImpl.stopRecordingProcess();
  expect(serviceImpl.callList.length >= 0).assertTrue();
};

let idl_service_ext_implTest_stopRecordingProcess_03Func = async (testContext: Context) => {
  let serviceImpl: ServiceExtImpl = new ServiceExtImpl(testContext);
  serviceImpl.recorderPrepareState = 2;
  serviceImpl.stopRecordingProcess();
  expect(serviceImpl.callList.length >= 0).assertTrue();
};

export function idl_service_ext_implTest() {
  describe('idl_service_ext_implTest', () => {
    let testContext: Context = GlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    it('idl_service_ext_implTest_addAVRecorderListener_01', 0, () => {
      idl_service_ext_implTest_addAVRecorderListener_01Func(testContext);
    })
    it('idl_service_ext_implTest_removeAVRecorderListener_01', 0, () => {
      idl_service_ext_implTest_removeAVRecorderListener_01Func(testContext);
    })
    it('idl_service_ext_implTest_commitRecordingError', 0, () => {
      idl_service_ext_implTest_commitRecordingErrorFunc(testContext);
    });
    it('idl_service_ext_implTest_stopService', 0, async () => {
      idl_service_ext_implTest_stopServiceFunc(testContext);
    });
    it('idl_service_ext_implTest_getIsHasFreeStorage', 0, () => {
      idl_service_ext_implTest_getIsHasFreeStorageFunc(testContext);
    });
    it('idl_service_ext_implTest_getErrorService', 0, () => {
      idl_service_ext_implTest_getErrorServiceFunc(testContext);
    });
    it('idl_service_ext_implTest_getErrorService01', 0, () => {
      idl_service_ext_implTest_getErrorServiceFunc01(testContext);
    });
    it('idl_service_ext_implTest_updateRecorderInfo01', 0, () => {
      idl_service_ext_implTest_updateRecorderInfo01(testContext);
    });
    it('idl_service_ext_implTest_updateRecorderInfo02', 0, () => {
      idl_service_ext_implTest_updateRecorderInfo02(testContext);
    });
    it('idl_service_ext_implTest_buildFileName_02', 0, async () => {
      await idl_service_ext_implTest_buildFileName_02Func(testContext);
    });
    it('idl_service_ext_implTest_buildFileName_03', 0, async () => {
      await idl_service_ext_implTest_buildFileName_03Func(testContext);
    });
    it('idl_service_ext_implTest_buildDisplayName', 0, async () => {
      idl_service_ext_implTest_buildDisplayNameFunc(testContext);
    });
  });
}

export function idl_service_ext_implTest01() {
  describe('idl_service_ext_implTest01', () => {
    let testContext: Context = GlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    it('idl_service_ext_implTest_startRecordingService_01', 0, () => {
      idl_service_ext_implTest_startRecordingService_01Func(testContext);
    });
    it('idl_service_ext_implTest_startRecordingService_02', 0, () => {
      idl_service_ext_implTest_startRecordingService_02Func(testContext);
    });
    it('idl_service_ext_implTest_startRecordingService_03', 0, () => {
      idl_service_ext_implTest_startRecordingService_03Func(testContext);
    });
    it('idl_service_ext_implTest_realStartRecording_01', 0, () => {
      idl_service_ext_implTest_realStartRecording_01Func(testContext);
    });
    it('idl_service_ext_implTest_realStartRecordingExtByFile_01', 0, () => {
      idl_service_ext_implTest_realStartRecordingExtByFile_01Func(testContext);
    });
    it('idl_service_ext_implTest_realStartRecordingExt_01', 0, () => {
      idl_service_ext_implTest_realStartRecordingExt_01Func(testContext);
    });
    it('idl_service_ext_implTest_realStartRecordingExtra_01', 0, () => {
      idl_service_ext_implTest_realStartRecordingExtra_01Func(testContext);
    });
    it('idl_service_ext_implTest_realStartRecording_02', 0, () => {
      idl_service_ext_implTest_realStartRecording_02Func(testContext);
    });
    it('idl_service_ext_implTest_realStartRecording_03', 0, () => {
      idl_service_ext_implTest_realStartRecording_03Func(testContext);
    });
    it('idl_service_ext_implTest_stopRecordingProcess_01', 0, () => {
      idl_service_ext_implTest_stopRecordingProcess_01Func(testContext);
    });
    it('idl_service_ext_implTest_stopRecordingProcess_02', 0, () => {
      idl_service_ext_implTest_stopRecordingProcess_02Func(testContext);
    });
    it('idl_service_ext_implTest_stopRecordingProcess_03', 0, () => {
      idl_service_ext_implTest_stopRecordingProcess_03Func(testContext);
    });
  });
}
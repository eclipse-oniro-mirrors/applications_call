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
import { StartRecordingCallBack } from './i_idl_service_ext';
import IdlServiceExtStub from './idl_service_ext_stub';
import FuncManager from '../serviceextability/FuncManager';
import common from '@ohos.app.ability.common';
import LogUtils from '../common/utils/LogUtils';
import { FuncManageReturn, RecordLog } from '../common/struct/RecorderStruct';
import media from '@ohos.multimedia.media';
import fs from '@ohos.file.fs';
import { BusinessError } from '@ohos.base';
import ServiceExtStub from './idl_service_ext_stub';
import { ResourceUtil } from '../common/utils/ResourceUtil';
import { RecordInputParameter } from '../common/struct/idlStruct';
import userFileManager from '@ohos.filemanagement.userFileManager';
import commonController from '../common/control/CommonCtrol';
import { AVRecorderConstant } from '../common/constant/AVRecorderConstant';
import TimeUtil from '../common/utils/TimeUtil';
import { formatPhoneNum } from '../common/utils/CommonUtil';
import { RPCInfoConstant } from '../common/constant/RPCInfoConstant';
import storageStatistics from '@ohos.file.storageStatistics';
import { FileUtils } from '../common/utils/FileUtils';
import { ReportUtil } from '../common/utils/ReportUtil';
import { SampleUtil } from '../common/utils/SampleUtil';
import { MigrationConstant } from '../common/constant/MigrationConstant';
import { Constant } from '../common/constant/Constant';

const TAG: string = 'CallRecorderIdlServiceExtImpl';

export default class ServiceExtImpl extends IdlServiceExtStub {
  public funcManager: FuncManager;
  public useContext: Context;
  private avRecorder: media.AVRecorder | undefined = undefined;
  public file?: fs.File;
  public fileAsset?: userFileManager.FileAsset;
  public fd?: number;
  private avProfile: media.AVRecorderProfile = {
    audioBitrate: AVRecorderConstant.AUDIO_BITRATE,
    audioChannels: AVRecorderConstant.AUDIO_CHANNELS,
    audioCodec: media.CodecMimeType.AUDIO_AAC, // audio encoding format. Currently, only AAC is supported.
    audioSampleRate: AVRecorderConstant.AUDIO_SAMPLE_RATE,
    fileFormat: media.ContainerFormatType.CFT_MPEG_4A // Encapsulation format. Currently, only m4a is supported.
  };
  private avConfig: media.AVRecorderConfig = {
    audioSourceType: AVRecorderConstant.AUDIO_SOURCE_TYPE,
    profile: this.avProfile,
    url: 'fd://'
  };
  public recorderPrepareState: number = 0;
  public recordLog: RecordLog = new RecordLog();
  public callTimeList: number[] = [];
  public callList: string[] = [];
  //100M space size
  private FREE_SIZE = 104857600;
  private RECORDER_RELEASE = 0;
  private RECORDER_PREPARING = 1;
  private RECORDER_RECORDING = 2;
  private groupDir: string = '';
  private isGroupDirInvalid: boolean = true;
  private curFile?: fs.File;
  private sampleUtil: SampleUtil = new SampleUtil();

  constructor(context: common.Context) {
    super('ServiceExtImpl');
    this.useContext = context;
    this.funcManager = new FuncManager(context);
    this.getGroupDir();
  }

  private async getGroupDir() {
    this.groupDir = await FileUtils.getCallRecordGroupDir(this.useContext);
    this.isGroupDirInvalid = (this.groupDir === '');
    LogUtils.i(TAG, 'getGroupDir isGroupDirInvalid:' + this.isGroupDirInvalid);
  }

  addAVRecorderListener() {
    LogUtils.i(TAG, 'addAVRecorderListener start');
    if (!this.avRecorder) {
      LogUtils.w(TAG, 'add avRecorder listener fail');
    }
    this.avRecorder?.on('error', (err: BusinessError) => {
      this.commitRecordingError();
    });
  }

  removeAVRecorderListener() {
    if (!this.avRecorder) {
      LogUtils.w(TAG, 'remove avRecorder listener fail');
    }
    this.avRecorder?.off('error');
    LogUtils.i(TAG, 'removeAVRecorderListener');
  }

  commitRecordingError() {
    commonController.getInstance().updateErrorTime(this.useContext);
  }

  realStartRecording(accountNumber: string, startTime: number, mode: number, callList: string[],
    callTimeList: number[], contactName: string) {
    let context: Context = this.useContext;
    try {
      LogUtils.i(TAG, 'startRecordingProcess');
      media.createAVRecorder(async (error, recorder) => {
        LogUtils.i(TAG, 'createAVRecorder success');
        if (recorder != null) {
          this.avRecorder = recorder;
          let avConfigUse: media.AVRecorderConfig = this.avConfig;
          let date: Date = new Date();
          let fileName = await this.buildFileName(date, contactName, accountNumber, mode);
          let displayName = this.buildDisplayName(date, fileName);
          if (!this.isGroupDirInvalid) {
            this.realStartRecordingExtByFile(`${this.groupDir}/${fileName}`, avConfigUse, recorder, displayName,
              accountNumber, startTime, mode, callTimeList, callList);
            return;
          }
          let userManager: userFileManager.UserFileManager = userFileManager.getUserFileMgr(context);
          LogUtils.i(TAG, 'getUserFileMgr success');
          if (!userManager) {
            LogUtils.w(TAG, 'getUserFileMgr error');
            return;
          }
          let fileAsset: userFileManager.FileAsset = await userManager.createAudioAsset(fileName);
          LogUtils.i(TAG, 'createAudioAsset success');
          this.fileAsset = fileAsset;
          this.realStartRecordingExt(fileAsset, avConfigUse, recorder, displayName, accountNumber,
            startTime, mode, callTimeList, callList);
        } else {
          LogUtils.e(TAG, `openFile fail, code is ${error.code}`);
          this.commitRecordingError();
        }
      });
    } catch (err) {
      let error = err as BusinessError;
      LogUtils.e(TAG, 'startRecordingProcess err: code: ' + error.code);
      this.commitRecordingError();
    }
  }

  realStartRecordingExtByFile(filePathInput: string, avConfigUse: media.AVRecorderConfig,
    recorder: media.AVRecorder, displayName: string, accountNumber: string, startTime: number, mode: number,
    callTimeList: number[], callList: string[]) {
    let filePath: string = filePathInput;
    if (!this.curFile) {
      LogUtils.e(TAG, 'file not exist');
      this.commitRecordingError();
      return;
    }
    try {
      let fd = this.curFile?.fd
      LogUtils.i(TAG, `realStartRecordingExtByFile fd: ${fd}`);
      this.recorderPrepareState = this.RECORDER_PREPARING;
      avConfigUse.url = 'fd://' + fd;
      recorder.prepare(avConfigUse, (err) => {
        this.realStartRecordingExtra(err, recorder, filePath, displayName, accountNumber, startTime, mode,
          callTimeList, callList);
      });
    } catch (err) {
      LogUtils.e(TAG, `realStartRecordingExtByFile err:${JSON.stringify(err)}`);
      this.commitRecordingError();
      if (err && err.code) {
        ReportUtil.getInstance().reportRecordStartError(err.code);
      }
    }
  }

  /* instrument ignore next */
  realStartRecordingExt(fileAsset: userFileManager.FileAsset, avConfigUse: media.AVRecorderConfig,
    recorder: media.AVRecorder, displayName: string, accountNumber: string, startTime: number, mode: number,
    callTimeList: number[], callList: string[]) {
    // For CodeCheck.
    let filePath: string = fileAsset.uri;
    fileAsset.open('w', (err, fd) => {
      if (err) {
        LogUtils.e(TAG, 'createAudioAsset open failed' + err);
        return;
      }
      this.fd = fd;
      LogUtils.i(TAG, 'createAudioAsset open success' + fd);
      try {
        avConfigUse.url = 'fd://' + fd;
        this.recorderPrepareState = this.RECORDER_PREPARING;
        recorder.prepare(avConfigUse, (err) => {
          this.realStartRecordingExtra(err, recorder, filePath, displayName, accountNumber, startTime, mode,
            callTimeList, callList);
        });
      } catch (err) {
        let error = err as BusinessError;
        LogUtils.e(TAG, 'prepareRecordingProcess err: code: ' + error.code);
        this.commitRecordingError();
        if (err && err.code) {
          ReportUtil.getInstance().reportRecordStartError(err.code);
        }
      }
    });
  }

  /* instrument ignore next */
  realStartRecordingExtra(err: BusinessError<void>, recorder: media.AVRecorder, filePath: string, displayName: string,
    accountNumber: string, startTime: number, mode: number, callTimeList: number[], callList: string[]) {
    if (this.recorderPrepareState != this.RECORDER_PREPARING) {
      return;
    }
    // For CodeCheck.
    if (err === null || err === undefined) {
      LogUtils.i(TAG, 'prepare success');
      recorder.start((err) => {
        if (err === null || err === undefined) {
          this.recorderPrepareState = this.RECORDER_RECORDING;
          let reLog: RecordLog = new RecordLog();
          reLog.filePath = filePath;
          reLog.displayName = displayName;
          reLog.phoneNumber = accountNumber;
          reLog.dateAdded = startTime;
          reLog.recorderAdded = new Date().getTime();
          reLog.mode = mode;
          this.recordLog = reLog;
          this.callTimeList = callTimeList;
          this.callList = callList;
          LogUtils.i(TAG, 'start AVRecorder success');
          // 开启振幅定时器
          this.sampleUtil.startAmplitudeTimer(recorder);
          this.addAVRecorderListener();
        } else {
          LogUtils.e(TAG, `start AVRecorder failed, errCode: ${err.code}`);
          this.commitRecordingError();
          if (err.code) {
            ReportUtil.getInstance().reportRecordStartError(err.code);
          }
        }
      });
    } else {
      LogUtils.e(TAG, `Invoke prepare failed, code is ${err.code}`);
      this.commitRecordingError();
      if (err.code) {
        ReportUtil.getInstance().reportRecordStartError(err.code);
      }
    }
  }

  async stopService() {
    await this.stopRecordingProcess();
  }

  getIsHasFreeStorage() {
    let freeSize: number = storageStatistics.getFreeSizeSync();
    LogUtils.i(TAG, 'freeSize:' + freeSize);
    return freeSize > this.FREE_SIZE;
  }

  getErrorService(callback: StartRecordingCallBack): void {
    LogUtils.i(TAG, `getErrorService start`);
    let _info: FuncManageReturn = {};
    _info.errCode = RPCInfoConstant.SUCCESS_STATUS_CODE;
    _info.message = RPCInfoConstant.SUCCESS_STATUS_MESSAGE;
    let isHasFreeStorage: boolean = this.getIsHasFreeStorage();
    if (!isHasFreeStorage) {
      _info.errCode = RPCInfoConstant.NO_STORAGE_STATUS_CODE;
      _info.message = RPCInfoConstant.NO_STORAGE_STATUS_MESSAGE;
    }
    callback(_info.errCode, _info.message);
  }

  startRecordingService(params: RecordInputParameter, callback: StartRecordingCallBack): void {
    LogUtils.i(TAG, `startRecordingService start`);
    let _info: FuncManageReturn = {};
    _info.errCode = RPCInfoConstant.SUCCESS_STATUS_CODE;
    let accountNumber: string = params.accountNumber;
    let startTime: number = params.startTime;
    let mode: number = params.mode;
    let callList: string[] = params.callList ? params.callList : [];
    let callTimeList: number[] = params.callTimeList ? params.callTimeList : [];
    let fileNameStr: string = params.fileNameStr;
    LogUtils.i(TAG, `startRecordingService, val: ${mode} `);
    switch (mode) {
      case ServiceExtStub.RECORDING_MANUAL:
        LogUtils.i(TAG, `startRecordingService, RECORDING_MANUAL`);
        _info.message = RPCInfoConstant.MANUAL_RECORDING_MESSAGE;
        this.realStartRecording(accountNumber, startTime, mode, callList, callTimeList, fileNameStr);
        break;
      case ServiceExtStub.RECORDING_MEETING:
        LogUtils.i(TAG, `startRecordingService, RECORDING_MEETING`);
        _info.message = RPCInfoConstant.MEETING_RECORDING_MESSAGE;
        this.realStartRecording(accountNumber, startTime, mode, callList, callTimeList, fileNameStr);
        break;
      default:
        _info.errCode = RPCInfoConstant.UNKNOWN_STATUS_CODE;
        _info.message = RPCInfoConstant.UNKNOWN_RECORDING_MESSAGE;
        LogUtils.i(TAG, 'startRecordingService unknown');
        break;
    }
    callback(_info.errCode, _info.message);
  }

  async stopRecordingProcess() {
    LogUtils.i(TAG, 'stopRecordingProcess');
    if (this.recorderPrepareState === this.RECORDER_RELEASE) {
      LogUtils.w(TAG, 'stopRecordingProcess not started');
      return;
    } else if (this.recorderPrepareState === this.RECORDER_RECORDING) {
      this.funcManager.sendNotification();
      await this.updateRecorderInfo();
    }
    this.recorderPrepareState = this.RECORDER_RELEASE;
    if (this.avRecorder !== undefined) {
      if (this.avRecorder.state === 'started' || this.avRecorder.state === 'paused') {
        await this.avRecorder.stop().catch((err: BusinessError) => {
          LogUtils.e(TAG, 'avRecorder stop err: ' + JSON.stringify(err));
          if (err && err.code) {
            ReportUtil.getInstance().reportRecordStopError(err.code);
          }
        });
      }
      await this.avRecorder.release();
      // AVRecorder销毁后保存采样数据到录音文件中
      await this.sampleUtil.trySaveSamples(this.recordLog.filePath);
      this.removeAVRecorderListener();
      this.avRecorder = undefined;
    } else {
      LogUtils.w(TAG, `stopRecordingProcess avRecorder unkonwn`);
    }
    if (this.curFile) {
      try {
        await fs.close(this.curFile);
        await this.moveFileToMigrationDir();
      } catch (err) {
        LogUtils.e(TAG, `stopRecordingProcess close fs error code:${err?.code}, msg: ${err?.message}`);
      }
    }
    if (this.fileAsset) {
      await this.fileAsset.close(this.fd);
    } else {
      LogUtils.w(TAG, `stopRecordingProcess fileAsset unkonwn`);
    }
    LogUtils.i(TAG, 'stopRecordingProcess over');
  }

  async updateRecorderInfo() {
    let recordLog = this.recordLog;
    let duration: number = new Date().getTime() - recordLog.recorderAdded;
    recordLog.duration = duration;
    if (recordLog.mode === ServiceExtStub.RECORDING_MEETING) {
      await commonController.getInstance()
        .batchInsertRecordInfo(this.useContext, recordLog, this.callList, this.callTimeList);
    } else {
      await commonController.getInstance().insertRecorderLog(this.useContext, recordLog);
    }
  }

  /* instrument ignore next */
  private async moveFileToMigrationDir() {
    LogUtils.w(TAG, `start moveFileToMigrationDir`);
    let migrationDir = FileUtils.getCallRecordMigrationDir();
    if (migrationDir === '') {
      LogUtils.e(TAG, 'migration dir is invalid, can not move record file');
      return;
    }
    let timeStr = this.recordLog.displayName.substring(
      this.recordLog.displayName.lastIndexOf(MigrationConstant.FILE_NAME_UNDERLINE_SEPARATOR) + 1)
      .replace(MigrationConstant.FILE_NAME_M4A_SUFFIX, MigrationConstant.EMPTY_STRING);
    let fileName = this.recordLog.displayName.replace(MigrationConstant.FILE_NAME_UNDERLINE_SEPARATOR + timeStr,
      MigrationConstant.EMPTY_STRING);
    let date = TimeUtil.getDateFromRecordDisplayNameTime(timeStr);
    let localizedStr = TimeUtil.getLocalizedMonthDateString(date);
    fileName = localizedStr + MigrationConstant.FILE_NAME_SPACE_SEPARATOR + fileName;
    let finalName = FileUtils.getDistinctRecordFileNameFromDir(fileName, migrationDir);
    LogUtils.i(TAG, `finalName is equal to fileName: ${finalName.length === fileName.length}`);
    let targetFilePath = `${migrationDir}/${finalName}`;
    try {
      fs.moveFileSync(this.recordLog.filePath, targetFilePath);
      LogUtils.w(TAG, 'move file success');
    } catch (err) {
      LogUtils.w(TAG, `move file failed, code:${err?.code}, msg: ${err?.message}`);
      return;
    }
    await commonController.getInstance().updateRecordLog(this.useContext, this.recordLog, finalName, targetFilePath);
  }

  async buildFileName(date: Date, contactName: string, accountNumber: string, mode: number): Promise<string> {
    let fileName = '';
    let startName = '';
    const time: string = date.getTime().toString();
    const afterSuffix: string = '.m4a';
    const endName = '_' + time + afterSuffix;
    if (mode === ServiceExtStub.RECORDING_MEETING) {
      startName = ResourceUtil.resourceToString($r('app.string.call_meeting'), this.useContext);
    } else if (!accountNumber) {
      startName = ResourceUtil.resourceToString($r('app.string.unknown'), this.useContext);
    } else if (contactName && !Constant.UNSUPPORTED_FILENAME_REGEXP.test(contactName)) {
      LogUtils.i(TAG, 'use contactName');
      startName = contactName;
    } else {
      startName = formatPhoneNum(accountNumber);
    }
    fileName = startName + endName;
    try {
      this.initFile(fileName);
    } catch (err) {
      fileName = '';
      LogUtils.e(TAG, `initFile err:${JSON.stringify(err)}`);
    }
    if (fileName) {
      return fileName;
    }
    if (contactName) {
      LogUtils.e(TAG, 'contact name error len: ' + contactName.length);
    } else {
      return '';
    }
    fileName = formatPhoneNum(accountNumber) + endName;
    try {
      this.initFile(fileName);
    } catch (err) {
      fileName = '';
      LogUtils.e(TAG, `reset initFile err:${JSON.stringify(err)}`);
    }
    return fileName;
  }

  buildDisplayName(date: Date, fileName: string): string {
    let timeStr: string = TimeUtil.getRecordDisplayNameTime(date);
    let timeStamp: string = fileName.slice(fileName.indexOf('_') + 1, fileName.indexOf('.'));
    return fileName.replace(timeStamp, timeStr);
  }

  initFile(fileName: string) {
    let path = `${this.groupDir}/${fileName}`;
    this.curFile = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    LogUtils.i(TAG, 'file open success');
  }
}
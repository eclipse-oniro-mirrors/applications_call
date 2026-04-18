/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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

import common from '@ohos.app.ability.common';
import LogUtils from '../common/utils/LogUtils';
import { RPCInfoConstant } from '../common/constant/RPCInfoConstant';
import IdlFilePermissionExtStub from './idl_file_permission_ext_stub';
import { CallBack } from './i_idl_file_permission';
import { FileUtils } from '../common/utils/FileUtils';
import fs from '@ohos.file.fs';
import callRecorder from 'libcallrecorder.so';
import deviceInfo from '@ohos.deviceInfo';

const TAG: string = 'IdlFilePermissionExtImpl';

const DIR_NAME_CALL_RECORD = 'CallRecord';
const GROUP_ID = 'group.1435681907172981696';
const PHONE_CALL_RECORDER_DIR_NAME = '/storage/Users/currentUser/Sounds';
const TABLET_CALL_RECORDER_DIR_NAME = '/storage/Users/currentUser/Music/SoundRecorder';

enum Device {
  PHONE = 'phone',
  TABLET = 'tablet',
  PC = '2in1'
}

export default class IdlFilePermissionExtImpl extends IdlFilePermissionExtStub {

  public useContext: Context;

  constructor(context: common.Context) {
    super('IdlFilePermissionExtImpl');
    this.useContext = context;
  }


  async allCallRecorderFilePermissionChange(callback: CallBack): Promise<void> {
    let allCallRecorder: string;
    let groupDir = await this.getCallRecordGroupDir(this.useContext);
    let dir = this.getCallRecordDir();
    // instrument ignore else
    if (dir !== '') {
      allCallRecorder = dir;
    } else if (groupDir !== '') {
      allCallRecorder = groupDir;
    } else {
      LogUtils.e(TAG, 'call recorder dir is not exist');
      callback(RPCInfoConstant.DIR_ERROR_CODE, RPCInfoConstant.DIR_ERROR_MESSAGE);
      return;
    }
    let listFileName = this.getDirListFile(allCallRecorder);
    if (listFileName === undefined || listFileName === null || listFileName.length === 0) {
      LogUtils.e(TAG, 'call recorder file is not exist');
      callback(RPCInfoConstant.FILE_ERROR_CODE, RPCInfoConstant.FILE_ERROR_MESSAGE);
      return;
    }
    // instrument ignore next
    for (const value of listFileName) {
      let callRecorderPath = `${allCallRecorder}/${value}`;
      if (value.endsWith('m4a')) {
        let filePermsResult: boolean = callRecorder.handleFilePermsNapi(callRecorderPath);
        LogUtils.i(TAG, `change dest path file permission result is ${filePermsResult}`);
      }
    }
    callback(RPCInfoConstant.SUCCESS_STATUS_CODE, RPCInfoConstant.SUCCESS_STATUS_MESSAGE);
  }

  // 获取沙箱通话录音目录
  private async getCallRecordGroupDir(context?: common.Context): Promise<string> {
    let dirInPref = FileUtils.getGroupDirFromPref(context);
    if (dirInPref !== '') {
      return dirInPref;
    }
    let groupDir: string = '';
    // instrument ignore next
    try {
      groupDir = await context?.getGroupDir(GROUP_ID) ?? '';
    } catch (err) {
      LogUtils.e(TAG, `getGroupDir err code:${err?.code}, msg: ${err?.message}`);
    }
    // instrument ignore if
    if (!groupDir || groupDir === '') {
      LogUtils.e(TAG, 'getGroupDir is empty');
      return '';
    } else {
      let callRecordGroupDir = `${groupDir}/${DIR_NAME_CALL_RECORD}`;
      return callRecordGroupDir;
    }
  }

  // 获取文管通话录音目录
  private getCallRecordDir():string {
    let baseDir = this.isPhone() ? PHONE_CALL_RECORDER_DIR_NAME : TABLET_CALL_RECORDER_DIR_NAME;
    let callRecordDir = `${baseDir}/${DIR_NAME_CALL_RECORD}`;
    return FileUtils.isFileExist(callRecordDir) ? callRecordDir : '';
  }

  private getDirListFile(dir: string): string[] {
    let listFile: string[] = [];
    try {
      const isDirFileExists = fs.accessSync(dir);
      if (!isDirFileExists) {
        return listFile;
      }
      listFile = fs.listFileSync(dir);
      return listFile;
    } catch (error) {
      LogUtils.e(TAG, `getSrcDirListFile catch error code:${error?.code},msg:${error?.message}`);
    }
    return listFile;
  }

  private isPhone() {
    return deviceInfo.deviceType === Device.PHONE;
  }
}

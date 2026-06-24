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
import { BusinessError } from '@ohos.base';
import fs, { ConflictFiles } from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { DIR_NAME_CALLRECORD, FileUtils } from './FileUtils';
import { ReportUtil } from './ReportUtil';
import callRecorder from 'libcallrecorder.so';
import { isPhone } from './CommonUtil';

const TAG = 'CopyDbDataHelper';

class CopyDbDataHelper {
  private groupDir: string = '';
  private fileDir: string = '';
  public failedCopyAudioFileList: string[] = [];
  public successCopyAudioFileList: string[] = [];
  public copyFileTotalCount: number = 0;
  public copyFileFailedCount: number = 0;

  public audioTotalCountInDb: number = 0;
  public sucAudioCountInDb: number = 0;
  public repeatAudioCountInDb: number = 0;
  public exAudioPathCountInDb: number = 0;
  public isBackup: boolean = false;
  public fileListCount: number = 0;
  private callRecordSoundsDir: string = '';

  async initDirs(context: common.Context) {
    LogUtils.i(TAG, 'initDirs');
    this.fileDir = context.filesDir;
    this.groupDir = await FileUtils.getCallRecordGroupDir(context);
    if (this.groupDir === '') {
      this.groupDir = this.fileDir;
    }
    this.callRecordSoundsDir = await FileUtils.getCallRecordSoundsDir();
    if (this.callRecordSoundsDir === '') {
      this.callRecordSoundsDir = this.groupDir;
    }
  }

  getSrcDirListFile(srcDir: string): string[] {
    let listFile: string[] = [];
    try {
      const isSrcDirExists = fs.accessSync(srcDir);
      if (!isSrcDirExists) {
        return listFile;
      }
      listFile = fs.listFileSync(srcDir);
      return listFile;
    } catch (error) {
      LogUtils.e(TAG, `getSrcDirListFile catch error code:${error?.code},msg:${error?.message}`);
    }
    return listFile;
  }

  async copyDbListFileForClone(clonePath: string, readClonePath: string, isCopyDir: boolean = true): Promise<boolean> {
    try {
      const isClonePathExists = fs.accessSync(clonePath);
      if (!isClonePathExists) {
        LogUtils.e(TAG, 'clonePath is not exists');
        return false;
      }

      const isReadClonePathExists = fs.accessSync(readClonePath);
      if (!isReadClonePathExists) {
        try {
          fs.mkdirSync(readClonePath, true);
        } catch (error) {
          LogUtils.i(TAG, `readClonePath: ${error.code}`);
        }
      }

      let listFileName = this.getSrcDirListFile(clonePath);
      if (listFileName === undefined || listFileName === null || listFileName.length === 0) {
        LogUtils.i(TAG, 'copyDbListFileForClone clonePath is not file');
        return false;
      }
      this.fileListCount = this.fileListCount + listFileName.length;
      ReportUtil.getInstance().reportRestoreStatus(0, this.fileListCount);
      let isCopyAudioFile: boolean =
        isPhone() ? readClonePath.includes('Sounds/CallRecord') : readClonePath.includes('SoundRecorder/CallRecord');
      LogUtils.i(TAG, `copylist listFile len:${listFileName.length} isCopyAudioFile:${isCopyAudioFile}`);
      for (const value of listFileName) {
        let srcPath = `${clonePath}/${value}`;
        let destPath = `${readClonePath}/${FileUtils.modifyDbFileNameForNext2Next(value)}`;
        if (fs.statSync(srcPath).isFile()) {
          await this.copySingleFileSync(srcPath, destPath, isCopyAudioFile);
        } else if (isCopyDir) {
          LogUtils.i(TAG, `copyDbListFileForClone foreach is dir`);
          await this.copyAudioFiles(srcPath);
        }
        if (value.endsWith('m4a')) {
          let filePermsResult: boolean = callRecorder.handleFilePermsNapi(destPath);
          LogUtils.i(TAG, `change dest path file permission result is ${filePermsResult}`);
        }
      }
      LogUtils.i(TAG, 'copyFile end');
      return true;
    } catch (error) {
      LogUtils.e(TAG, `copyDbListFileForClone error code: ${error?.code}, msg: ${error?.message}`);
    }
    return false;
  }

  async copySingleFileSync(srcPath: string, destPath: string, isCopyAudioFile: boolean = false) {
    this.copyFileTotalCount++;
    try {
      if (this.isBackup) {
        await fs.copyFile(srcPath, destPath);
      } else {
        await fs.moveFile(srcPath, destPath);
      }
      if (isCopyAudioFile) {
        this.successCopyAudioFileList.push(destPath);
      }
    } catch (err) {
      LogUtils.e(TAG, `copySingleFileSync err code: ${err?.code}, msg: ${err?.message}`);
      this.copyFileFailedCount++;
      if (isCopyAudioFile) {
        this.failedCopyAudioFileList.push(destPath);
      }
    }
  }

  setAudioTotalCountInDb(count: number) {
    this.audioTotalCountInDb = count;
  }

  addExAudioPathCountInDb() {
    this.exAudioPathCountInDb++;
  }

  addRepeatAudioCountInDb() {
    this.repeatAudioCountInDb++;
  }

  addSuccessAudioCountInDb(addCount: number) {
    this.sucAudioCountInDb = this.sucAudioCountInDb + addCount;
  }

  isCopySuccessRecord(filePath: string): boolean {
    return (this.successCopyAudioFileList.indexOf(filePath) >= 0);
  }

  getCopyFileProgressInfo(): string {
    let processInfo: Record<string, ESObject> = {
      'name': 'callRecorder',
      'processed': this.copyFileTotalCount + this.sucAudioCountInDb,
      'total': this.fileListCount + (this.audioTotalCountInDb == 0 ? this.fileListCount : this.audioTotalCountInDb),
      'isPercentage': true
    };
    let process: string = `{"progressInfo":[${JSON.stringify(processInfo)}]}`;
    LogUtils.i(TAG, `onProcess current is:${process}`);
    return process;
  }

  getCopyFileResultInfo(): string {
    let failCountInDb = this.audioTotalCountInDb - this.sucAudioCountInDb - this.repeatAudioCountInDb -
    this.exAudioPathCountInDb;
    LogUtils.i(TAG, `Db t:${this.audioTotalCountInDb} s:${this.sucAudioCountInDb} r:${this.repeatAudioCountInDb}` +
      ` ex:${this.exAudioPathCountInDb}`);

    let sucCopyCount = this.successCopyAudioFileList.length;
    let failCopyCount = this.failedCopyAudioFileList.length;
    let totalCopyCount = sucCopyCount + failCopyCount;
    LogUtils.i(TAG, `File t:${totalCopyCount} s:${sucCopyCount} f:${failCopyCount} tc:${this.copyFileTotalCount}`);

    return this.makeResultInfo(this.sucAudioCountInDb, failCountInDb, this.repeatAudioCountInDb,
      `${failCountInDb > 0 ? 'Insert Database fail ' + failCountInDb : ''}` +
        `${failCopyCount > 0 ? 'Copy audio fail ' + failCopyCount : ''}`);
  }

  makeResultInfo(sucCount: number, failCount: number, repeatedCount: number, errorInfo: string = ''): string {
    LogUtils.i(TAG, `makeResultInfo suc:${sucCount} fail:${failCount} repeat:${repeatedCount} err:${errorInfo}`);
    let errorInfoRecord: Record<string, ESObject> = {
      'type': 'ErrorInfo',
      'errorCode': (failCount > 0) ? '13500099' : '0',
      'errorInfo': errorInfo
    };
    let countInfoRecord: Record<string, ESObject> = {
      'backupInfo': 'callRecorder',
      'successCount': sucCount,
      'duplicateCount': repeatedCount,
      'failedCount': failCount
    };
    let countInfo = `{"type": "CountInfo","infos":[${JSON.stringify(countInfoRecord)}]}`;
    let resultInfo = `{"resultInfo":[${JSON.stringify(errorInfoRecord)},${countInfo}]}`;
    return resultInfo;
  }

  async copyAudioFiles(oldAudioPath: string, newPath: string = this.callRecordSoundsDir): Promise<boolean> {
    let oldPath = FileUtils.findCallRecordInSubDir(oldAudioPath);
    LogUtils.i(TAG, 'copyAudioFile');
    return await this.copyDbListFileForClone(oldPath, newPath, false);
  }

  delFiles(oldDir: string) {
    try {
      let delCount: number = 0;
      this.getSrcDirListFile(oldDir)?.forEach((fileName: string) => {
        fs.unlinkSync(`${oldDir}/${fileName}`);
        delCount++;
      });
      LogUtils.i(TAG, `delTempAudioFiles delSize:${delCount}`);
    } catch (err) {
      LogUtils.e(TAG, `delTempAudioFiles err code: ${err?.code}, msg: ${err?.message}`);
    }
  }

  async delOldAndCopyNewAudioFiles(context: common.Context) {
    LogUtils.i(TAG, `delOldAndCopyNewAudioFiles start`);
    this.delFiles('/data/storage/el2/base/haps/entry/files/CallRecord');
    let groupDir = FileUtils.getGroupDirFromPref(context);
    let callRecordSoundsDir = await FileUtils.getCallRecordSoundsDir();
    LogUtils.i(TAG, `groupDir: ${groupDir}, callRecordSoundsDir: ${callRecordSoundsDir}`);
    try {
      if (fs.accessSync(callRecordSoundsDir)) {
        await this.copyDbListFileForClone(callRecordSoundsDir, '/data/storage/el2/base/.backup/restore/CallRecord',
          false);
      }
    } catch (err) {
      LogUtils.e(TAG, `Failed to accessSync callRecordSoundsDir, err code: ${err?.code},msg:${err?.message}`);
    }
    LogUtils.i(TAG, `delTempAudioFiles has groupDir:${groupDir !== ''}`);
    await this.copyDbListFileForClone(groupDir, '/data/storage/el2/base/.backup/restore/CallRecord', false);
  }
}

export const copyDbDataHelper: CopyDbDataHelper = new CopyDbDataHelper();

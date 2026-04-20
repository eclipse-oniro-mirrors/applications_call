/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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
import { common } from '@kit.AbilityKit';
import LogUtils from './LogUtils';
import preferences from '@ohos.data.preferences';
import fileIo from '@ohos.file.fs';
import { isPhone } from './CommonUtil';
import { MigrationConstant } from '../constant/MigrationConstant';
import { BusinessError } from '@kit.BasicServicesKit';
import { media } from '@kit.MediaKit';

const TAG = 'FileUtils';
export const GROUP_ID = 'group.1435681907172981696';
export const RECORD_DIR_ON_DUAL = '/storage/emulated/0/Sounds/CallRecord';
export const DIR_NAME_CALLRECORD = 'CallRecord';
export const TYPE_DUAL2NEXT = 1;
export const TYPE_NEXT2NEXT = 2;
export const TYPE_DUAL2NEXT2NEXT = 3;
export const TYPE_NEXT2DUAL = 4;
export const GROUP_PREF = 'group_info';
export const GROUP_PREF_DIR = 'group_dir';
export const PHONE_MIGRATION_DIR_NAME = '/storage/Users/currentUser/Sounds';
export const TABLET_MIGRATION_DIR_NAME = '/storage/Users/currentUser/Music/SoundRecorder';

const NUMBER_AMR_REGEX = /^[0-9]+\.amr$/;
const NUMBER_M4A_REGEX = /^[0-9]+\.m4a$/;

export class FileUtils {
  public static groupDir: string = '';
  public static callRecordMigrationDir: string = '';
  public static callRecordSoundsDir: string = '';

  static getGroupDirFromPref(context?: common.Context): string {
    if (!context) {
      LogUtils.e(TAG, 'getGroupDirFromPref invalid context');
      return '';
    }
    try {
      let pref = preferences.getPreferencesSync(context, { name: GROUP_PREF });
      let dir = pref.getSync(GROUP_PREF_DIR, '') as string;
      return dir;
    } catch (err) {
      LogUtils.e(TAG, `getGroupDirFromPref error code:${err?.code}, msg: ${err?.message}`);
      return '';
    }
  }

  static setGroupDirToPref(dirPath: string, context?: common.Context): void {
    if (!context) {
      LogUtils.e(TAG, 'setGroupDirToPref invalid context');
      return;
    }
    try {
      let pref = preferences.getPreferencesSync(context, { name: GROUP_PREF });
      pref.putSync(GROUP_PREF_DIR, dirPath);
      pref.flush();
    } catch (err) {
      LogUtils.e(TAG, `setGroupDirToPref error code:${err?.code}, msg: ${err?.message}`);
    }
  }

  // 获取通话录音文管目录
  static async getCallRecordSoundsDir(): Promise<string> {
    if (FileUtils.callRecordSoundsDir !== '') {
      return FileUtils.callRecordSoundsDir;
    }
    const callRecordSoundsDir = await FileUtils.getCallRecordMigrationDir();
    try {
      if (fileIo.accessSync(callRecordSoundsDir)) {
        FileUtils.callRecordSoundsDir = callRecordSoundsDir;
        return callRecordSoundsDir;
      }
    } catch (err) {
      LogUtils.e(TAG, `getCallRecordSoundsDir failed, err code: ${err?.code}, message: ${err?.message}`);
    }
    return '';
  }

  static async getCallRecordGroupDir(context?: common.Context): Promise<string> {
    if (FileUtils.groupDir !== '' && FileUtils.isFileExist(FileUtils.groupDir)) {
      return FileUtils.groupDir;
    }
    let dirInPref = FileUtils.getGroupDirFromPref(context);
    if (dirInPref !== '' && FileUtils.isFileExist(dirInPref)) {
      FileUtils.groupDir = dirInPref;
      return dirInPref;
    }
    let groupDir: string = '';
    try {
      groupDir = await context?.getGroupDir(GROUP_ID) ?? '';
    } catch (err) {
      LogUtils.e(TAG, `getGroupDir err code:${err?.code}, msg: ${err?.message}`);
    }
    LogUtils.i(TAG, `getCallRecordGroupDir groupDir length:${groupDir.length}`);
    if (!groupDir || groupDir === '') {
      LogUtils.e(TAG, 'getGroupDir is empty');
      return '';
    } else {
      let callRecordGroupDir = `${groupDir}/${DIR_NAME_CALLRECORD}`;
      FileUtils.mkDirSync(`${groupDir}/${DIR_NAME_CALLRECORD}`);
      FileUtils.groupDir = callRecordGroupDir;
      FileUtils.setGroupDirToPref(callRecordGroupDir, context);
      return FileUtils.groupDir;
    }
  }

  static getCallRecordMigrationDir(): string {
    let baseDir = isPhone() ? PHONE_MIGRATION_DIR_NAME : TABLET_MIGRATION_DIR_NAME;
    let callRecordMigrationDir = baseDir + '/' + DIR_NAME_CALLRECORD;
    if (FileUtils.checkAndMakeDirSync(baseDir)) {
      let ret = FileUtils.checkAndMakeDirSync(callRecordMigrationDir);
      return ret ? callRecordMigrationDir : '';
    } else {
      return '';
    }
  }

  static checkAndMakeDirSync(dirPath: string): boolean {
    if (!FileUtils.isFileExist(dirPath)) {
      let result = FileUtils.mkDirSync(dirPath);
      LogUtils.i(TAG, 'migrationDir create:' + result);
      return result;
    }
    return true;
  }

  static mkDirSync(dir: string): boolean {
    try {
      fileIo.mkdirSync(dir, true);
      return true;
    } catch (error) {
      LogUtils.e(TAG, `mkDirSync error code:${error?.code}, msg: ${error?.message}`);
      return false;
    }
  }

  static getDualDir(oriFullPath: string): string {
    if (oriFullPath.startsWith(RECORD_DIR_ON_DUAL)) {
      return RECORD_DIR_ON_DUAL;
    }
    let index = oriFullPath.indexOf('Sounds/CallRecord');
    if (index >= 0) {
      return oriFullPath.substring(0, index + 'Sounds/CallRecord'.length);
    } else {
      return RECORD_DIR_ON_DUAL;
    }
  }

  static replaceAudioFileDir(replaceType: number, oldPath: string): string {
    if (!oldPath || oldPath === '') {
      return oldPath;
    }
    switch (replaceType) {
      case TYPE_DUAL2NEXT:
        if (FileUtils.callRecordSoundsDir) {
          return oldPath.replace(FileUtils.getDualDir(oldPath), FileUtils.callRecordSoundsDir);
        }
        break;
      case TYPE_NEXT2NEXT:
        if (FileUtils.callRecordSoundsDir) {
          let oldPathSplitList = oldPath.split('/');
          let oldPathSize = oldPathSplitList?.length ?? 0;
          if (oldPathSize > 1) {
            let fileName = oldPathSplitList[oldPathSize - 1];
            return oldPath.replace(oldPath.replace(fileName, ''), `${FileUtils.callRecordSoundsDir}/`);
          }
        }
        break;
      case TYPE_NEXT2DUAL:
        let oldPathSplitList = oldPath.split('/');
        let oldPathSize = oldPathSplitList?.length ?? 0;
        if (oldPathSize > 1) {
          let fileName = oldPathSplitList[oldPathSize - 1];
          return RECORD_DIR_ON_DUAL + '/' + fileName;
        }
        break;
      default:
        break;
    }
    return oldPath;
  }

  static modifyDbFileNameForNext2Next(oldDbFilePath: string): string {
    // trans call_record.db to old_call_record.db for Next Clone To Next
    if (oldDbFilePath.endsWith('.db') || oldDbFilePath.endsWith('.db-shm') || oldDbFilePath.endsWith('.db-wal')) {
      let newPath = oldDbFilePath.replace('call_record', 'old_call_record');
      LogUtils.i(TAG,
        `transDbFileNameForNext2Next oldDbFilePath length:${oldDbFilePath.length} newPath length:${newPath.length}`);
      return newPath;
    }
    return oldDbFilePath;
  }

  static findCallRecordInSubDir(oriPath: string) {
    let recordDirPath = oriPath;
    LogUtils.i(TAG, `findCallRecordInSubDir start, oriPath length:${oriPath.length}`);
    try {
      while (fileIo.statSync(recordDirPath).isDirectory()) {
        if (recordDirPath.endsWith(DIR_NAME_CALLRECORD) || recordDirPath.endsWith(`${DIR_NAME_CALLRECORD}/`)) {
          break;
        }
        let subDirName: string = fileIo.listFileSync(recordDirPath)[0] ?? '';
        LogUtils.i(TAG, `continue findCallRecordDir subDirName length:${subDirName.length}`);
        if (!subDirName || subDirName === '') {
          break;
        }
        recordDirPath = `${recordDirPath}/${subDirName}`;
      }
    } catch (error) {
      LogUtils.e(TAG, `getCallRecordDir error: code:${error?.code}, msg: ${error?.message}`);
    }
    LogUtils.i(TAG, `findCallRecordInSubDir get, recordDirPath length:${recordDirPath.length}`);
    return recordDirPath;
  }

  /**
   * Check if the file exists.
   *
   * @param {string} filePath - filePath as the absolute path to the target file.
   * @return {boolean} - boolean true(Exist)
   */
  static isFileExist(filePath: string): boolean {
    try {
      return fileIo.accessSync(filePath);
    } catch (error) {
      LogUtils.e(TAG, `isFileExist error code:${error?.code}, msg: ${error?.message}`);
      return false;
    }
  }

  /**
   * delete file.
   *
   * @param {string} filePath - filePath as the absolute path to the target file.
   * @return {boolean} - boolean true(deleted)
   */
  static deleteFileSync(path: string): boolean {
    try {
      fileIo.unlinkSync(path);
      return true;
    } catch (error) {
      LogUtils.e(TAG, `isFileExist error: ` + error);
      return false;
    }
  }

  static getFileListSync(filePath: string): string[] {
    try {
      return fileIo.listFileSync(filePath);
    } catch (error) {
      LogUtils.e(TAG, `listFileSync error code:${error?.code}, msg: ${error?.message}`);
      return [];
    }
  }

  static moveFileSync(src: string, dest: string): boolean {
    try {
      fileIo.moveFileSync(src, dest);
      return true;
    } catch (error) {
      LogUtils.e(TAG, `moveFileSync error code:${error?.code}, msg: ${error?.message}`);
      return false;
    }
  }

  static copyFileSync(src: string, dest: string): boolean {
    try {
      fileIo.copyFileSync(src, dest);
      return true;
    } catch (error) {
      LogUtils.e(TAG, `copyFileSync error code:${error?.code}, msg: ${error?.message}`);
      return false;
    }
  }

  static getFileStatSync(path: string): fileIo.Stat | null {
    try {
      return fileIo.statSync(path);
    } catch (error) {
      LogUtils.e(TAG, `getFileStatSync error code:${error?.code}, msg: ${error?.message}`);
      return null;
    }
  }

  static getDistinctRecordFileNameFromDir(oriFileName: string, dir: string) {
    let dirFiles = FileUtils.getFileListSync(dir);
    let suffix = oriFileName.endsWith(MigrationConstant.FILE_NAME_M4A_SUFFIX) ?
      MigrationConstant.FILE_NAME_M4A_SUFFIX : MigrationConstant.FILE_NAME_AMR_SUFFIX;
    let suffixRegex = oriFileName.endsWith(MigrationConstant.FILE_NAME_M4A_SUFFIX) ? NUMBER_M4A_REGEX :
      NUMBER_AMR_REGEX;
    if (dirFiles.findIndex((element) => oriFileName == element) != -1) {
      LogUtils.i(TAG, `current fileName is already contained in dirFiles`);
      let oriFileNamePrefix = oriFileName.replace(suffix, MigrationConstant.FILE_NAME_SPACE_SEPARATOR);
      let displayNames = dirFiles.filter(name => name.startsWith(oriFileNamePrefix) &&
        suffixRegex.test(name.replace(oriFileNamePrefix, MigrationConstant.EMPTY_STRING))).sort((a, b) => {
        let aIndex = a.replace(suffix, MigrationConstant.EMPTY_STRING)
          .substring(a.lastIndexOf(MigrationConstant.FILE_NAME_SPACE_SEPARATOR) + 1);
        let bIndex = b.replace(suffix, MigrationConstant.EMPTY_STRING)
          .substring(b.lastIndexOf(MigrationConstant.FILE_NAME_SPACE_SEPARATOR) + 1);
        return Number.parseInt(aIndex) - Number.parseInt(bIndex);
      });
      if (displayNames.length === 0) {
        LogUtils.i(TAG, `index is 2`);
        oriFileName = oriFileName.replace(suffix, MigrationConstant.FILE_NAME_SPACE_SEPARATOR + '2' + suffix);
      } else {
        // 索引优先补位
        let indexStr = displayNames[0].replace(suffix, MigrationConstant.EMPTY_STRING)
          .substring(displayNames[0].lastIndexOf(MigrationConstant.FILE_NAME_SPACE_SEPARATOR) + 1);
        let index = Number.parseInt(indexStr);
        LogUtils.i(TAG, `index: ${index}`);
        let finalIndex = index;
        if (index >= 2) {
          for (let i = 1; i < displayNames.length; i++) {
            let currentIndexStr = displayNames[i].replace(suffix, MigrationConstant.EMPTY_STRING)
              .substring(displayNames[i].lastIndexOf(MigrationConstant.FILE_NAME_SPACE_SEPARATOR) + 1);
            let currentIndex = Number.parseInt(currentIndexStr);
            if (currentIndex !== index + i) {
              LogUtils.i(TAG, `currentIndex: ${currentIndex}, index + i: ${index + i}`);
              finalIndex = index + i;
              break;
            }
          }
          if (finalIndex === index) {
            finalIndex = index + displayNames.length;
          }
        }
        LogUtils.i(TAG, `finalIndex: ${finalIndex}`);
        oriFileName = oriFileNamePrefix + finalIndex + suffix;
      }
    }
    return oriFileName;
  }
}

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
import fs from '@ohos.file.fs';
import LogUtils from './LogUtils';
import * as Constants from './Constants';
import preferences from '@ohos.data.preferences';
import fileIo from '@ohos.file.fs';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { dataSharePredicates } from '@kit.ArkData';

const TAG = 'FileUtils';
const GROUP_ID = 'group.1435681907172981696';
export const MANAGER_DIR_ON_DUAL = '/storage/emulated/0/Sounds/CallSetting';
export const DIR_NAME_CALLMANAGER = 'CallSetting';
export const TYPE_DUAL2NEXT = 1;
export const TYPE_NEXT2NEXT = 2;
export const TYPE_DUAL2NEXT2NEXT = 3;
export const GROUP_PREF = 'group_info';
export const GROUP_PREF_DIR = 'group_dir';
export const FILE_SEPARATOR: string = '/';
export const JPG_FILE: string = '.jpg';

export class FileUtils {
  public static groupDir: string = '';

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
      LogUtils.e(TAG, `getGroupDirFromPref error:${JSON.stringify(err)}`);
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
      LogUtils.e(TAG, `setGroupDirToPref error:${JSON.stringify(err)}`);
    }
  }

  static async getCallSettingGroupDir(context?: common.Context): Promise<string> {
    if (context == null || context == undefined) {
      LogUtils.i(TAG, 'current context is null or undefined');
      return '';
    }
    if (FileUtils.groupDir !== '') {
      return FileUtils.groupDir;
    }
    let dirInPref = FileUtils.getGroupDirFromPref(context);
    if (dirInPref !== '') {
      FileUtils.groupDir = dirInPref;
      return dirInPref;
    }
    let groupDir: string = '';
    try {
      groupDir = await context?.getGroupDir(GROUP_ID) ?? '';
    } catch (err) {
      LogUtils.e(TAG, `getGroupDir err:${JSON.stringify(err)}`);
    }
    if (!groupDir || groupDir === '') {
      LogUtils.e(TAG, 'getGroupDir is empty');
      return '';
    } else {
      let callSettingGroupDir = `${groupDir}/${DIR_NAME_CALLMANAGER}`;
      FileUtils.mkDirSync(`${groupDir}/${DIR_NAME_CALLMANAGER}`);
      FileUtils.groupDir = callSettingGroupDir;
      FileUtils.setGroupDirToPref(callSettingGroupDir, context);
      return FileUtils.groupDir;
    }
  }

  static mkDirSync(dir: string): boolean {
    try {
      fs.mkdirSync(dir);
      return true;
    } catch (error) {
      LogUtils.w(TAG, `mkDirSync error:${JSON.stringify(error)}`);
      return false;
    }
  }

  static replaceAudioFileDir(replaceType: number, oldPath: string): string {
    if (!oldPath || oldPath === '') {
      return oldPath;
    }
    switch (replaceType) {
      case TYPE_DUAL2NEXT:
        if (FileUtils.groupDir) {
          return oldPath.replace(MANAGER_DIR_ON_DUAL, FileUtils.groupDir);
        }
        break;
      case TYPE_NEXT2NEXT:
        if (FileUtils.groupDir) {
          let oldPathSplitList = oldPath.split('/');
          let oldPathSize = oldPathSplitList?.length ?? 0;
          if (oldPathSize > 1) {
            let fileName = oldPathSplitList[oldPathSize - 1];
            return oldPath.replace(oldPath.replace(fileName, ''), `${FileUtils.groupDir}/`);
          }
        }
        break;
      default:
        break;
    }
    return oldPath;
  }

  static modifyDbFileNameForNext2Next(oldDbFilePath: string): string {
    // trans call_manager.db to old_call_manager.db for Next Clone To Next
    if (oldDbFilePath.endsWith('.db') || oldDbFilePath.endsWith('.db-shm') || oldDbFilePath.endsWith('.db-wal')) {
      let newPath = oldDbFilePath.replace('call_manager', 'old_call_manager');
      return newPath;
    }
    return oldDbFilePath;
  }

  static findCallSettingInSubDir(oriPath: string) {
    let managerDirPath = oriPath;
    try {
      while (fs.statSync(managerDirPath).isDirectory()) {
        if (managerDirPath.endsWith(DIR_NAME_CALLMANAGER) || managerDirPath.endsWith(`${DIR_NAME_CALLMANAGER}/`)) {
          break;
        }
        let subDirName: string = fs.listFileSync(managerDirPath)[0] ?? '';
        if (!subDirName || subDirName === '') {
          break;
        }
        managerDirPath = `${managerDirPath}/${subDirName}`;
      }
    } catch (error) {
      LogUtils.e(TAG, `getCallSettingDir error: ${JSON.stringify(error)}`);
    }
    return managerDirPath;
  }

  /**
   * 获取A/B目录下的App文件夹路径
   *
   * @returns App文件夹路径
   */
  public static getSandboxAppPath(): string {
    let rootPath: string = '';
    try {
      if (fs.accessSync(Constants.FLAG_PATH_A)) {
        rootPath = Constants.APP_SANDBOX_PATH_A;
      } else if (fs.accessSync(Constants.FLAG_PATH_B)) {
        rootPath = Constants.APP_SANDBOX_PATH_B;
      } else {
        LogUtils.e(TAG, 'getSandboxAppPath, there is no FLAG in A/B path.');
      }
    } catch (error) {
      LogUtils.e(TAG, `error in getSandboxAppPath: ${error}`);
    }
    return rootPath;
  }

  // 创建视频缩略图
  public static async createThumbnailFromVideo(asset: photoAccessHelper.PhotoAsset, path: string) {
    LogUtils.w(TAG, 'createThumbnailFromVideo start' );
    try {
      let imagePackerApi = image.createImagePacker();
      let packOpts: image.PackingOption = { format: 'image/jpeg', quality: 98 };
      let pixelMap = await asset.getThumbnail();
      let data: ArrayBuffer = await imagePackerApi.packToData(pixelMap, packOpts);
      if (data.byteLength == 0) {
        LogUtils.e(TAG, 'data.byteLength is 0');
        return;
      }
      let filePath = FileUtils.getNoFileNamePath(path);
      if (!fs.accessSync(filePath, 0)) {
        LogUtils.i(TAG, 'uriToDir no have path');
        fs.mkdirSync(filePath, true);
      }
      let thumbnailPath = path + Constants.VIDEO_RINGTONE_THUMB_SUFFIX;
      let file = fs.openSync(thumbnailPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      fileIo.writeSync(file.fd, data);
      fileIo.closeSync(file);
      pixelMap.release();
      imagePackerApi.release();
      LogUtils.i(TAG, 'createThumbnailFromVideo thumbnailPath');
    } catch (error) {
      LogUtils.e(TAG, 'createThumbnailFromVideo failed with err: ' + JSON.stringify(error));
    }
  }

  public static async getVideoAssets(videoUri: string, callback: Function) {
    LogUtils.i(TAG, 'getVideoAssets start');
    try {
      let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(getContext());
      let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
      predicates.equalTo('uri', videoUri);
      let fetchOption: photoAccessHelper.FetchOptions = {
        fetchColumns: ['duration', 'size'],
        predicates: predicates
      };
      phAccessHelper.getAssets(fetchOption).then((fetchResult: photoAccessHelper
        .FetchResult<photoAccessHelper.PhotoAsset>) => {
        fetchResult.getFirstObject().then((asset: photoAccessHelper.PhotoAsset) => {
          LogUtils.i(TAG, 'getVideoAssets getFirstObject success');
          callback(asset);
        });
        fetchResult.close();
      });
    } catch (error) {
      LogUtils.e(TAG, 'getVideoAssets failed with err: ' + JSON.stringify(error));
    }
  }

  public static getFileName(path: string): string {
    // 找到最后一个斜杠的位置
    let lastSlashIndex = path.lastIndexOf('/');
    let fileName = '';
    if (lastSlashIndex !== -1) {
      // 提取文件名部分
      fileName = path.substring(lastSlashIndex + 1);
    }
    return fileName;
  }

  // 保存uri视频文件到沙箱目录
  public static uriToDir(uri: string, path: string) {
    LogUtils.i(TAG, 'uriToDir start');
    let videoRingtonePath: string = path;
    try {
      let file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      let filePath = FileUtils.getNoFileNamePath(path);
      if (!fs.accessSync(filePath, 0)) {
        LogUtils.i(TAG, 'uriToDir no have path');
        fs.mkdirSync(filePath, true)
      }
      videoRingtonePath = path + Constants.VIDEO_RINGTONE_SUFFIX;
      let file2 = fs.openSync(videoRingtonePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      fs.copyFileSync(file.fd, file2.fd);
      fs.closeSync(file);
      fs.closeSync(file2);
      LogUtils.i(TAG, 'uriToDir videoRingtonePath done');
    } catch (e) {
      LogUtils.e(TAG, 'uriToDir fail e :' + JSON.stringify(e));
    }
    return videoRingtonePath;
  }

  public static getFileNameNoSuffix(fileName: string): string {
    // 找到最后一个点的位置
    let lastDotIndex = fileName.lastIndexOf('.');
    let baseName = '';
    if (lastDotIndex !== -1) {
      // 提取文件名的主部分
      baseName = fileName.substring(0, lastDotIndex);
    }
    return baseName;
  }

  // 去除掉后缀后的路径
  public static getNoFileSuffixPath(path: string): string {
    const regex = /(?:\.[^.]*)$/;
    return path.replace(regex, '');
  }

  public static deleteDir(dirPath: string) {
    fs.rmdir(dirPath).then(() => {
      LogUtils.i(TAG, 'deleteVideoRingtoneFromDir rmdir' );
    }).catch((err: BusinessError) => {
      LogUtils.e(TAG, 'deleteVideoRingtoneFromDir rmdir failed with error message: ' + err.message +
        ', error code: ' + err.code);
    });
  }

  // 去除掉文件名后的路径
  public static getNoFileNamePath(path: string): string {
    // 找到最后一个斜杠的位置
    let lastSlashIndex = path.lastIndexOf('/');
    let directory = '';
    if (lastSlashIndex !== -1) {
      // 提取目录部分
      directory = path.substring(0, lastSlashIndex + 1);
    }
    return directory;
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
      LogUtils.e(TAG, `isFileExist error ${JSON.stringify(error)}`);
      return false;
    }
  }

  static delFiles(path: string) {
    try {
      let delCount: number = 0;
      FileUtils.getSrcDirListFile(path)?.forEach((fileName: string) => {
        fs.unlinkSync(`${path}/${fileName}`);
        delCount++;
      });
      LogUtils.i(TAG, `delTempAudioFiles delSize:${delCount}`);
    } catch (err) {
      LogUtils.e(TAG, `delTempAudioFiles err:${JSON.stringify(err)}`);
    }
  }

  static getSrcDirListFile(srcDir: string): string[] {
    let listFile: string[] = [];
    try {
      const isSrcDirExists = fs.accessSync(srcDir);
      if (!isSrcDirExists) {
        return listFile;
      }
      listFile = fs.listFileSync(srcDir);
      return listFile;
    } catch (error) {
      LogUtils.i(TAG, 'getSrcDirListFile catch error');
    }
    return listFile;
  }
}
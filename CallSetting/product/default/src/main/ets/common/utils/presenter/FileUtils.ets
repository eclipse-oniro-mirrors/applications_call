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
import { Constants, LogUtils } from '@ohos/common/CommonIndex';
import preferences from '@ohos.data.preferences';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { dataSharePredicates } from '@kit.ArkData';

const TAG = 'FileUtils';
const GROUP_ID = 'group.1435681907172981696';

export const SETTING_DIR_ON_DUAL = '/storage/emulated/0/Sounds/CallSetting';

export const DIR_NAME_CALLSETTING = 'CallSetting';

export const TYPE_DUAL2NEXT = 1;

export const TYPE_NEXT2NEXT = 2;

export const TYPE_DUAL2NEXT2NEXT = 3;

export const GROUP_PREF = 'group_info';

export const GROUP_PREF_DIR = 'group_dir';

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
    if (context === null || context === undefined) {
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
      let callSettingGroupDir = `${groupDir}/${DIR_NAME_CALLSETTING}`;
      FileUtils.mkDirSync(`${groupDir}/${DIR_NAME_CALLSETTING}`);
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
          return oldPath.replace(SETTING_DIR_ON_DUAL, FileUtils.groupDir);
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
    if (oldDbFilePath.endsWith('.db') || oldDbFilePath.endsWith('.db-shm') || oldDbFilePath.endsWith('.db-wal')) {
      let newPath = oldDbFilePath.replace('call_setting', 'old_call_setting');
      newPath = newPath.replace('CallSetting', 'CallSettingClone');
      return newPath;
    }
    return oldDbFilePath;
  }

  static findCallSettingInSubDir(oriPath: string) {
    let settingDirPath = oriPath;
    try {
      while (fs.statSync(settingDirPath).isDirectory()) {
        if (settingDirPath.endsWith(DIR_NAME_CALLSETTING) || settingDirPath.endsWith(`${DIR_NAME_CALLSETTING}/`)) {
          break;
        }
        let subDirName: string = fs.listFileSync(settingDirPath)[0] ?? '';
        if (!subDirName || subDirName === '') {
          break;
        }
        settingDirPath = `${settingDirPath}/${subDirName}`;
      }
    } catch (error) {
      LogUtils.e(TAG, `getCallSettingDir error: ${JSON.stringify(error)}`);
    }
    return settingDirPath;
  }

  /**
   * ��ȡA/BĿ¼�µ�App�ļ���·��
   *
   * @returns App�ļ���·��
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

  public static async getVideoAssets(videoUri: string, callback: Function) {
    LogUtils.i(TAG, 'getVideoAssets start');
    try {
      let phAccessHelper: photoAccessHelper.PhotoAccessHelper = photoAccessHelper.getPhotoAccessHelper(getContext());
      let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
      predicates.equalTo('uri', videoUri);
      let fetchOption: photoAccessHelper.FetchOptions = {
        fetchColumns: ['duration', 'size', 'title', 'display_name', 'media_type'],
        predicates: predicates
      };
      phAccessHelper.getAssets(fetchOption)
        .then((fetchResult: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset>) => {
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
}
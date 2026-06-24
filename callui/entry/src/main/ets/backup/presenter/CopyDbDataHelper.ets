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

import LogUtils from '../../common/utils/LogUtils';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { FileUtils } from '../../common/utils/FileUtils';

const TAG = 'CopyDbDataHelper';

class CopyDbDataHelper {
  private groupDir: string = '';
  private fileDir: string = '';
  public failedCopyManagerFileList: string[] = [];
  public successCopyManagerFileList: string[] = [];
  public copyFileTotalCount: number = 0;
  public copyFileFailedCount: number = 0;

  async initDirs(context: common.Context) {
    LogUtils.i(TAG, 'initDirs');
    if (context == null || context == undefined) {
      LogUtils.i(TAG, 'current context is null or undefined');
      return;
    }
    this.fileDir = context.filesDir;
    this.groupDir = await FileUtils.getCallSettingGroupDir(context);
    if (this.groupDir === '') {
      this.groupDir = this.fileDir;
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
      LogUtils.i(TAG, 'getSrcDirListFile catch error');
    }
    return listFile;
  }

  public copyDbListFileForClone(clonePath: string, readClonePath: string, isCopyDir: boolean = true): boolean {
    try {
      const isClonePathExists = fs.accessSync(clonePath);
      if (!isClonePathExists) {
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
      let isCopyManagerFile: boolean = readClonePath.includes('group');
      listFileName.forEach((value: string) => {
        let srcPath = `${clonePath}/${value}`;
        let destPath = `${readClonePath}/${FileUtils.modifyDbFileNameForNext2Next(value)}`;
        if (fs.statSync(srcPath).isFile()) {
          this.copySingleFileSync(srcPath, destPath, isCopyManagerFile);
        } else if (isCopyDir) {
          LogUtils.i(TAG, `copyDbListFileForClone foreach is dir`);
          this.copyManagerFiles(srcPath);
        }
      });
      LogUtils.i(TAG, 'copyFile end');
      return true;
    } catch (error) {
      LogUtils.i(TAG, `copyDbListFileForClone error: ${JSON.stringify(error)}`);
    }
    return false;
  }

  copySingleFileSync(srcPath: string, destPath: string, isCopyManagerFile: boolean = false) {
    this.copyFileTotalCount++;
    try {
      fs.copyFileSync(srcPath, destPath);
      if (isCopyManagerFile) {
        this.successCopyManagerFileList.push(destPath);
      }
    } catch (err) {
      this.copyFileFailedCount++;
      if (isCopyManagerFile) {
        this.failedCopyManagerFileList.push(destPath);
      }
    }
  }

  copyManagerFiles(oldManagerPath: string, newPath: string = this.groupDir): boolean {
    let oldPath = FileUtils.findCallSettingInSubDir(oldManagerPath);
    LogUtils.i(TAG, 'copyManagerFile');
    return this.copyDbListFileForClone(oldPath, newPath, false);
  }
}

export const copyDbDataHelper: CopyDbDataHelper = new CopyDbDataHelper();

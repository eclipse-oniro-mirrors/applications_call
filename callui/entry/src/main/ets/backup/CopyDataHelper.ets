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

import LogUtils from '../common/utils/LogUtils';
import { BusinessError } from '@ohos.base';
import fs, { ConflictFiles } from '@ohos.file.fs';

const TAG = 'CopyDataHelper';

class CopyDataHelper {
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
      LogUtils.e(TAG, 'getSrcDirListFile catch error');
    }
    return listFile;
  }

  public copyListFile(clonePath: string, newPath: string): boolean {
    try {
      const isClonePathExists = fs.accessSync(clonePath);
      if (!isClonePathExists) {
        LogUtils.e(TAG, 'clonePath is not exists');
        return false;
      }

      const isReadClonePathExists = fs.accessSync(newPath);
      if (!isReadClonePathExists) {
        try {
          fs.mkdirSync(newPath);
        } catch (error) {
          LogUtils.e(TAG, `readClonePath: ${error.code}`);
        }
      }

      return this.copyFiles(clonePath, newPath);
    } catch (error) {
      LogUtils.e(TAG, `copyListFile error: ${JSON.stringify(error)}`);
    }
    return false;
  }

  public copyListFilePre(clonePath: string, newPath: string): boolean {
    try {
      const isClonePathExists = fs.accessSync(clonePath);
      if (!isClonePathExists) {
        LogUtils.e(TAG, 'clonePath is not exists');
        return false;
      }

      const isReadClonePathExists = fs.accessSync(newPath);
      if (!isReadClonePathExists) {
        try {
          fs.mkdirSync(newPath, true);
        } catch (error) {
          LogUtils.e(TAG, `readClonePath: ${error.code}`);
        }
      }

      return this.copyFilesPre(clonePath, newPath);
    } catch (error) {
      LogUtils.e(TAG, `copyListFile error: ${JSON.stringify(error)}`);
    }
    return false;
  }

  copyFilesPre(clonePath: string, newPath: string): boolean {
    let listFileName = this.getSrcDirListFile(clonePath);
    if (listFileName === undefined || listFileName === null || listFileName.length === 0) {
      LogUtils.i(TAG, 'copyListFile clonePath is not file');
      return false;
    }
    listFileName.forEach((value: string) => {
      let srcPath = `${clonePath}/${value}`;
      let destPath = `${newPath}/${value}_copy`;
      if (fs.statSync(srcPath).isFile()) {
        fs.copyFileSync(srcPath, destPath);
      } else {
        fs.copyDir(srcPath, newPath, (err: BusinessError<ConflictFiles[]> | undefined) => {
          LogUtils.i(TAG, 'copy directory : ' + JSON.stringify(err));
        });
      }
    });
    LogUtils.i(TAG, 'copyFile success');
    return true;
  }

  copyFiles(clonePath: string, newPath: string): boolean {
    let listFileName = this.getSrcDirListFile(clonePath);
    if (listFileName === undefined || listFileName === null || listFileName.length === 0) {
      LogUtils.i(TAG, 'copyListFile clonePath is not file');
      return false;
    }
    listFileName.forEach((value: string) => {
      let srcPath = `${clonePath}/${value}`;
      let destPath = `${newPath}/${value}`;
      if (fs.statSync(srcPath).isFile()) {
        fs.copyFileSync(srcPath, destPath);
      } else {
        fs.copyDir(srcPath, newPath, (err: BusinessError<ConflictFiles[]> | undefined) => {
          LogUtils.i(TAG, 'copy directory : ' + JSON.stringify(err));
        });
      }
    });
    LogUtils.i(TAG, 'copyFile success');
    return true;
  }
}

export const copyDataHelper: CopyDataHelper = new CopyDataHelper();

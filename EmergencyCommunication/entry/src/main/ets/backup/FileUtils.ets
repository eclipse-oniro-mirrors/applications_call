/**
 * Copyright (c) 2024-2024 Huawei Device Co., Ltd.
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

import fs from '@ohos.file.fs';
import LogUtils from '../utils/HiLog';
import xmlConvertUtils from '@ohos.convertxml';
import util from '@ohos.util';
import * as Constants from './RestoreConstants';
import { EmergencyContactConvertOptions, XmlNode } from './ResotreClassStructs';
import { prefUtils } from './PrefUtils';
import RestoreUtils from './RestoreUtils';

const TAG = 'FileUtils'
const DATABASE_DIR = '/rdb';

class FileUtils {
  /**
   * Copy files from src dir to new dir
   */
  public copyFilesByDir(oldDir: string, newDir: string, isCopyDb?: boolean, skipFile?: string[]): boolean {
    /**
     * when get dir from context, pref path is:/data/storage/el2/base/haps/entry/preferences
     * db path is:/data/storage/el2/database/entry, for db need add /rdb path
     */
    let newFinalDir: string = isCopyDb ? `${newDir}${DATABASE_DIR}` : newDir;
    try {
      if (!this.isAllDirAccessible(oldDir, newDir, newFinalDir, isCopyDb)) {
        return false;
      }

      let oldFileLists: string[] = fs.listFileSync(oldDir);
      let fileCount = oldFileLists.length;
      LogUtils.i(TAG, `copy files old file count:${fileCount}`);
      if (fileCount === 0) {
        LogUtils.w(TAG, 'get empty file list, means no need continue copy files');
        return true;
      }

      let copyCount: number = 0;
      oldFileLists.forEach((value: string) => {
        if (!skipFile?.includes(value)) {
          fs.copyFileSync(`${oldDir}/${value}`, `${newFinalDir}/${value}`);
          LogUtils.i(TAG, `copy file:${value}`);
          copyCount++;
        } else {
          LogUtils.i(TAG, `copy sikp File: ${value}`);
        }
      });
      LogUtils.i(TAG, `end copy copyCount:${copyCount}`);
      return copyCount === fileCount;
    } catch (error) {
      LogUtils.e(TAG, `copy file list occurs error:${error?.code}`);
      return false;
    }
  }

  private isAllDirAccessible(oldDir: string, newDir: string, newFinalDir: string, isCopyDb?: boolean): boolean {
    if (!this.isFileAccessibleSync(newDir)) {
      LogUtils.e(TAG, `newDir:${newDir} not accessible`);
      return false;
    }

    if (isCopyDb) {
      this.mkRdbDir(newFinalDir);
      if (!this.isFileAccessibleSync(newFinalDir)) {
        LogUtils.e(TAG, `newFinalDir:${oldDir} not access`);
        return false;
      }
    }

    if (!this.isFileAccessibleSync(oldDir)) {
      LogUtils.i(TAG, `oldDir: ${oldDir} not accessible`);
      return false;
    };
    LogUtils.i(TAG, 'isAllPathAccessible all check success');
    return true;
  }

  public isFileAccessibleSync(filePath: string): boolean {
    try {
      return fs.accessSync(filePath);
    } catch (error) {
      return false;
    }
  }

  private mkRdbDir(rdbDir: string): void {
    try {
      fs.mkdirSync(rdbDir);
    } catch (error) {
      LogUtils.e(TAG, `mkRdbDir:${rdbDir} error:${error?.code}`);
    }
  }

  public async parseXmlToPref(filePath: string): Promise<boolean> {
    let fileContent: string | undefined = this.readFileContent(filePath);
    LogUtils.i(TAG, `parse xml content len:${fileContent?.length}`);
    if (!fileContent || '' === fileContent) {
      LogUtils.e(TAG, 'parse xml get empty content');
      return false;
    }

    try {
      let options: xmlConvertUtils.ConvertOptions = new EmergencyContactConvertOptions()
      let convertUtils: xmlConvertUtils.ConvertXML = new xmlConvertUtils.ConvertXML();
      let xmlNodeList = convertUtils.convertToJSObject(fileContent, options) as XmlNode;

      let rootNode = this.getRootNodeByTag(Constants.XML_ROOT_NODE_MAP, xmlNodeList);
      if (rootNode) {
        rootNode._elements?.forEach(async (node: XmlNode) => {
          await this.saveNodeToPref(node);
        });
        return true;
      } else {
        LogUtils.i(TAG, 'convertToJSObject rootNode invalid');
        return false;
      }
    } catch (err) {
      LogUtils.e(TAG, `parseXmlToPref err:${JSON.stringify(err)}`);
      RestoreUtils.getInstance().appendErrorInfo(`parseXmlToPref err:${err?.code}-${err?.message};`);
      return false;
    }
  }

  private getRootNodeByTag(rootTag: string, xmlNodeList?: XmlNode): XmlNode | undefined {
    let rootNode: XmlNode | undefined = undefined;
    if (!xmlNodeList) {
      LogUtils.i(TAG, 'get invalid nodeList');
      return xmlNodeList;
    }

    if (xmlNodeList._elements && xmlNodeList._elements.length > 0) {
      rootNode = xmlNodeList._elements[0];
      if (!rootNode) {
        LogUtils.i(TAG, 'getRootNodeByTag has no root node');
        return rootNode;
      }
      let rootNodeName = rootNode._name ?? '';
      LogUtils.i(TAG, `get root node:${rootNodeName} subSize:${rootNode._elements?.length ?? 0}`);
      if ('' !== rootNodeName && rootTag === rootNodeName) {
        return rootNode;
      }
    }
    return rootNode;
  }

  private async saveNodeToPref(node: XmlNode): Promise<void> {
    LogUtils.i(TAG, `save node type:${node?._name} size:${JSON.stringify(node)?.length}`);
    if (node && 'string' === node?._name) {
      let prefKey: string | undefined = node._attributes?.name;
      if (!prefKey) {
        LogUtils.e(TAG, 'can not save node info without key');
        return;
      }

      let transKey: string = Constants.OLD_TO_NEW_TRANS_MAP.get(prefKey) ?? '';
      if ('' !== transKey && prefKey !== transKey) {
        LogUtils.i(TAG, `saveNodeToPref trans key from ${prefKey} to ${transKey}`);
        prefKey = transKey;
      }

      let prefVal: string = '';
      if (node._elements && node._elements.length > 0) {
        prefVal = node._elements[0]?._text ?? '';
      }
      await prefUtils.saveParsedOldInfoToPref(prefKey, prefVal);
    }
  }

  private readFileContent(filePath: string): string | undefined {
    if (!this.isFileAccessibleSync(filePath)) {
      return undefined;
    }

    let buf = new ArrayBuffer(Constants.READ_DATA_SIZE_4096);
    let totalLength = 0;
    let bufArray: ArrayBuffer[] = [];
    try {
      let stream: fs.Stream = fs.createStreamSync(filePath, 'r');
      let len = stream.readSync(buf);
      LogUtils.i(TAG, `getContent FileIO start reading ${len}`);
      while (len > 0) {
        totalLength = totalLength + len;
        bufArray.push(buf.slice(0, len));
        buf = new ArrayBuffer(Constants.READ_DATA_SIZE_4096);
        len = stream.readSync(buf);
        LogUtils.i(TAG, `getContent FileIO foreach reading ${len}`);
      }
      stream.closeSync();
      LogUtils.i(TAG, `getContent read finished: ${totalLength}`);

      const contentBuf = new Uint8Array(totalLength);
      let offset = 0;
      for (let arr of bufArray) {
        const uInt8Arr = new Uint8Array(arr);
        contentBuf.set(uInt8Arr, offset);
        offset = offset + uInt8Arr.byteLength;
        LogUtils.i(TAG, `getContent collecting: ${offset}`);
      }
      let textDecoder = util.TextDecoder.create(Constants.XML_ENCODE_UTF_8, {ignoreBOM: true});
      return textDecoder.decodeWithStream(contentBuf, {stream: false});
    } catch (error) {
      LogUtils.e(TAG, `getFileContent error: ${error?.code}`);
      RestoreUtils.getInstance().appendErrorInfo(`getFileContent err:${error?.code}-${error?.message};`);
      return undefined;
    }
  }

}

export const fileUtils: FileUtils = new FileUtils();
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
import { buffer } from '@kit.ArkTS';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import LogUtils from './HiLog';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'Sm3Util';

export class Sm3Util {
  public static async doMdByPromise(message: string): Promise<string> {
    let result: string = '';
    let mdAlgName = 'SM3';
    let md = cryptoFramework.createMd(mdAlgName);
    let promiseMdUpdate = md.update({ data: Sm3Util.stringToUint8Array(message) });
    await promiseMdUpdate.then(() => {
      let promiseMdDigest = md.digest();
      return promiseMdDigest;
    }).then(digestOutput => {
      let mdOutput = digestOutput.data;
      let str = Sm3Util.uint8ArrayToHexStr(mdOutput);
      result = str;
    }).catch((error: BusinessError) => {
      LogUtils.e(TAG, '[Promise]: error: ' + error.message);
    });
    return Promise.resolve(result);
  }

  private static stringToUint8Array(str: string) {
    return new Uint8Array(buffer.from(str, 'utf-8').buffer);
  }

  private static uint8ArrayToHexStr(data: Uint8Array): string {
    let hexString = '';
    let i: number;
    for (i = 0; i < data.length; i++) {
      let char = ('00' + data[i].toString(16)).slice(-2);
      hexString += char;
    }
    return hexString;
  }
}

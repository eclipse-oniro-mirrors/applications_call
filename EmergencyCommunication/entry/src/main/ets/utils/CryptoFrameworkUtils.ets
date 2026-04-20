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
import cryptoFramework from '@ohos.security.cryptoFramework';
import buffer from '@ohos.buffer';
import LogUtils from './HiLog';
import { parseHex } from './Utils';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { StringUtil } from './StringUtil';

const TAG = 'CryptoFrameworkUtils';

export class CryptoFrameworkUtils {
  private static CHNAGE_BYTE_TO_CORRECT_INT = 0xFF;
  private static VALIDE_LENGTH_LOWER_LIMITE = 2;

  constructor() {
  }

  private static getSHA256String(b: Uint8Array): string {
    let sb = '';
    let hex: string;
    b.forEach((bt) => {
      let tempNum = (bt & CryptoFrameworkUtils.CHNAGE_BYTE_TO_CORRECT_INT);
      hex = (tempNum >= 0) ? tempNum.toString(16) : parseHex(tempNum, 4);
      if (hex.length < CryptoFrameworkUtils.VALIDE_LENGTH_LOWER_LIMITE) {
        sb += 0;
      }
      sb += hex;
    })
    return sb;
  }

  /**
   * Encrypt String use SHA-256
   * @param strSrc string need to encrypt.
   * @return encrypted string.
   */
  public static async getSHA256DigestString(strSrc: string): Promise<string> {
    if (!strSrc) {
      LogUtils.i(TAG, 'encrypt sha empty');
      return '';
    }
    let mdAlgName = 'SHA256';
    let md = cryptoFramework.createMd(mdAlgName);
    await md.update({ data: new Uint8Array(buffer.from(strSrc, 'utf-8').buffer) });

    let mdResult = await md.digest();
    return CryptoFrameworkUtils.getSHA256String(mdResult.data);
  }


  private static uint8ToHex(uint8arr: Uint8Array): string {
    let hexStr = '';
    for (let i = 0; i < uint8arr.length; i++) {
      let hex = uint8arr[i].toString(16);
      hex = hex.length === 1 ? '0' + hex : hex;
      hexStr += hex;
    }
    return hexStr;
  }

  public static async stringToSha256(plainText: string): Promise<string> {
    let str = '';
    if (StringUtil.isEmpty(plainText)) {
      LogUtils.e(TAG, 'stringToSha256: plainText empty');
      return str;
    }
    try {
      let md = cryptoFramework.createMd('SHA256');
      let buff = new util.TextEncoder().encodeInto(plainText);
      let blob: cryptoFramework.DataBlob = {
        data: buff
      }

      let promiseMdUpdate = md.update(blob);
      await promiseMdUpdate.then(() => {
        let promiseMdDigest = md.digest();
        return promiseMdDigest;
      }).then(mdOutput => {
        let newBuff = CryptoFrameworkUtils.uint8ToHex(mdOutput.data) as string;
        str = newBuff.toString();
      }).catch((e: BusinessError) => {
        LogUtils.e(TAG, `stringToSha256: promiseMdUpdate error: ${e?.code} ${e?.message}`);
      });
      return str;
    } catch (e) {
      LogUtils.e(TAG, `stringToSha256 error: ${e?.code} ${e?.message}`);
      return str;
    }
  }
}
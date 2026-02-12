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
import cryptoFramework from '@ohos.security.cryptoFramework';
import util from '@ohos.util';
import { buffer } from '@kit.ArkTS';
import LogUtils from '../utils/HiLog';
import { constant } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';

function doRandBySync() {
  let rand = cryptoFramework.createRandom();
  let len = 16; // Generate a 24-byte random number.
  let iv = new Uint8Array
  try {
    let randData = rand.generateRandomSync(len);
    if (randData != null) {
      LogUtils.i(TAG, '[Sync]: rand success!');
      iv = randData.data
    } else {
      LogUtils.e(TAG, '[Sync]: get rand result fail!');
    }
  } catch (error) {
    LogUtils.e(TAG, `do rand failed, error :${JSON.stringify(error)}`);
  }
  return iv
}

export function concatUint8Arrays(array1: Uint8Array, array2: Uint8Array): Uint8Array {
  const result = new Uint8Array(array1.length + array2.length);
  result.set(array1, 0);
  result.set(array2, array1.length);
  return result;
}

function genIvParamsSpec(iv: Uint8Array) {
  let ivBlob: cryptoFramework.DataBlob = { data: iv };
  let ivParamsSpec: cryptoFramework.IvParamsSpec = {
    algName: 'IvParamsSpec',
    iv: ivBlob
  };
  return ivParamsSpec;
}

const TAG = 'Encrypted'

class Encrypted {
  constructor() {
  }

  // Comprehensible Strings Converted to Byte Streams
  public static stringToUint8Array(str: string): Uint8Array {
    return new Uint8Array(buffer.from(str, 'utf-8').buffer);
  }

  // Convert the byte stream into an understandable string.
  public static uint8ArrayToString(array: Uint8Array) {
    let out: string = '';
    let index: number = 0;
    let len: number = array.length;
    while (index < len) {
      let character = array[index++];
      switch (character >> 4) {
        case 0:
        case 1:
        case 2:
        case 3:
        case 4:
        case 5:
        case 6:
        case 7:
          out += String.fromCharCode(character);
          break;
        case 12:
        case 13:
          out += String.fromCharCode(((character & 0x1F) << 6) | (array[index++] & 0x3F));
          break;
        case 14:
          out += String.fromCharCode(((character & 0x0F) << 12) | ((array[index++] & 0x3F) << 6) |
            ((array[index++] & 0x3F) << 0));
          break;
        default:
          break;
      }
    }
    return out;
  }

  // SHA256 Summary
  public static sha256Summary = async (message: string) => {
    LogUtils.i(TAG, 'sha256Summary Start!');
    let md = cryptoFramework.createMd('SHA256');
    await md.update({ data: Encrypted.stringToUint8Array(message) });
    let mdOutput = await md.digest();
    return mdOutput;
  }

  public static aesEcbEncode256 = async (md5Sum: cryptoFramework.DataBlob, message: string) => {
    LogUtils.i(TAG, 'aesEcbEncode256 Start!');
    // 如果传入的不是有效的DataBlob，可能会导致后续操作失败。应该在使用md5Sum之前进行有效性检查。
    if (!md5Sum || !md5Sum.data) {
      LogUtils.e(TAG, 'Invalid md5Sum parameter');
      return '';
    }
    let result = ''
    try {
      let globalCipher1 = cryptoFramework.createCipher('AES256|CBC|PKCS5');
      let globalKey1 = await cryptoFramework.createSymKeyGenerator('AES256').convertKey(md5Sum);
      let encodedKey = globalKey1.getEncoded();
      let ivTemp = doRandBySync()
      let iv = genIvParamsSpec(ivTemp);
      let mode1 = cryptoFramework.CryptoMode.ENCRYPT_MODE;
      let promiseInit1 = globalCipher1.init(mode1, globalKey1, iv);
      await promiseInit1;
      let plainText: cryptoFramework.DataBlob = { data: Encrypted.stringToUint8Array(message) };
      let updateOutput1 = await globalCipher1.doFinal(plainText);
      result = new util.Base64Helper().encodeToStringSync(concatUint8Arrays(ivTemp, updateOutput1.data));
    } catch (e) {
      LogUtils.e(TAG, 'aesEcbEncode256 error: ' + e.message);
    }
    return result;
  }
}

export { Encrypted };

/*
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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
import { BusinessError } from '@ohos.base';
import LogUtils from './HiLog';
import { stringToUint8Array } from './Utils';
import huks from '@ohos.security.huks';

export class GenKeyPropertyType {
  public tag: huks.HuksTag = huks.HuksTag.HUKS_TAG_ALGORITHM;
  public value: huks.HuksKeyAlg | huks.HuksKeySize | huks.HuksKeyPurpose | huks.HuksKeyDigest |
  huks.HuksKeyPadding | huks.HuksAuthStorageLevel | Uint8Array | huks.HuksKeyGenerateType =
    huks.HuksKeyAlg.HUKS_ALG_RSA;
}

class AttestKeypropertyType {
  public tag: huks.HuksTag = huks.HuksTag.HUKS_TAG_ALGORITHM;
  public value: huks.HuksKeyAlg | huks.HuksKeySize | huks.HuksKeyPurpose | huks.HuksKeyDigest |
  huks.HuksKeyStorageType | huks.HuksKeyPadding | huks.HuksKeyGenerateType |
  huks.HuksCipherMode | huks.HuksAuthStorageLevel | Uint8Array = huks.HuksKeyAlg.HUKS_ALG_RSA;
}

const TAG = 'HuksUtils';

export class HuksUtils {
  private static readonly CERTIFICATE_CHAIN_LEN = 3;
  private static readonly CERTIFICATE_CHAIN_INDEX_DEVICE = 1;
  private static readonly CERTIFICATE_CHAIN_INDEX_ATTESTATION = 0;
  private static readonly beginString = '-----BEGIN CERTIFICATE-----';
  private static readonly endString = '-----END CERTIFICATE-----';

  constructor() {
  }

  public static getDeviceCertificate(certificateChain: string[]): string {
    let deviceCertificateBase64 = '';
    if (certificateChain && certificateChain.length === HuksUtils.CERTIFICATE_CHAIN_LEN) {
      try {
        let tempString = certificateChain[HuksUtils.CERTIFICATE_CHAIN_INDEX_DEVICE];

        deviceCertificateBase64 = tempString
          .replace(new RegExp('(\n)', 'g'), '')
          .replace(new RegExp('^' + HuksUtils.beginString), '')
          .replace(new RegExp(HuksUtils.endString + '$'), '');
      } catch (e) {
        LogUtils.e(TAG, 'get device certificate encode error');
      }
      return deviceCertificateBase64;
    } else {
      LogUtils.e(TAG, 'get device certificate error, chain is not right');
      return deviceCertificateBase64;
    }
  }

  public static getAttestationCertificate(certificateChain: string[]): string {
    let attestationBase64 = '';
    if (certificateChain && certificateChain.length === HuksUtils.CERTIFICATE_CHAIN_LEN) {
      try {
        let tempString = certificateChain[HuksUtils.CERTIFICATE_CHAIN_INDEX_ATTESTATION];

        attestationBase64 = tempString
          .replace(new RegExp('(\n)', 'g'), '')
          .replace(new RegExp('^' + HuksUtils.beginString), '')
          .replace(new RegExp(HuksUtils.endString + '$'), '');
      } catch (e) {
        LogUtils.e(TAG, 'get attestation certificate encode error');
      }
      return attestationBase64;
    } else {
      LogUtils.e(TAG, 'get attestation certificate error, chain is not right');
      return attestationBase64;
    }
  }

  /**
   * Get certificate chain
   * @param aliasString
   * @param challengeStr
   * @returns
   */
  public static async anonAttestKeyItem(aliasString: string, challengeStr: string) {
    let aliasUint8 = stringToUint8Array(aliasString);
    let securityLevel = stringToUint8Array('');
    let keyChallenge = stringToUint8Array(challengeStr ? challengeStr : '');

    let properties: AttestKeypropertyType[] = [
      {
        tag: huks.HuksTag.HUKS_TAG_ATTESTATION_ID_SEC_LEVEL_INFO,
        value: securityLevel
      },
      {
        tag: huks.HuksTag.HUKS_TAG_ATTESTATION_CHALLENGE,
        value: keyChallenge
      },
      {
        tag: huks.HuksTag.HUKS_TAG_ATTESTATION_ID_ALIAS,
        value: aliasUint8
      },
      {
        tag: huks.HuksTag.HUKS_TAG_AUTH_STORAGE_LEVEL,
        value: huks.HuksAuthStorageLevel.HUKS_AUTH_STORAGE_LEVEL_DE
      }
    ];
    let options: huks.HuksOptions = {
      properties: properties
    };
    try {
      let data = await huks.anonAttestKeyItem(aliasString, options)
        .catch((error: BusinessError) => {
          LogUtils.e(TAG, `anonAttestKeyItem failed, errorCode:` + error.code + ' errorMessage:' + error.message);
        });
      return data;
    } catch (error) {
      LogUtils.e(TAG, `anonAttestKeyItem input arg invalid, error:${JSON.stringify(error)}`);
    }
  }

  private static async isDEKeyItemExist(keyAlias: string) {
    let emptyOptions: huks.HuksOptions = {
      properties: [
        {
          tag: huks.HuksTag.HUKS_TAG_AUTH_STORAGE_LEVEL,
          value: huks.HuksAuthStorageLevel.HUKS_AUTH_STORAGE_LEVEL_DE
        }
      ]
    };
    try {
      let res = await huks.hasKeyItem(keyAlias, emptyOptions)
        .catch((error: BusinessError) => {
          LogUtils.e(TAG, `find key failed, errorCode:` + error.code + ' errorMessage:' + error.message);
          return false;
        });
      if (res) {
        LogUtils.i(TAG, 'find key success');
      } else {
        LogUtils.e(TAG, `find key failed`);
      }
      return res;
    } catch (e) {
      LogUtils.e(TAG, `find key failed, error:` + JSON.stringify(e));
      return false;
    }
  }

  public static async importPublicKeyToHUKS(keyAlias: string, properties: GenKeyPropertyType[], publicKey: Uint8Array) {
    let options: huks.HuksOptions = {
      properties: properties,
      inData: publicKey
    };
    try {
      await huks.importKeyItem(keyAlias, options)
        .then((data) => {
          LogUtils.i(TAG, `promise: importKeyItem success`);
        })
        .catch((error: BusinessError) => {
          LogUtils.e(TAG, `importPublicKeyToHUKS failed, errorCode:` + error.code + ' errorMessage:' + error.message);
          return false;
        });
      let res = await HuksUtils.isDEKeyItemExist(keyAlias);
      if (res) {
        LogUtils.i(TAG, `importPublicKeyToHUKS success`);
        return res;
      } else {
        LogUtils.e(TAG, `importPublicKeyToHUKS failed`);
        return res;
      }
    } catch (error) {
      LogUtils.e(TAG, `importPublicKeyToHUKS failed, error:` + error);
      return false;
    }
  }

  /**
   * 生成RSA非对称秘钥对
   *
   * @param alias   别名
   * @param purpose 用途
   * @param digest  摘要算法
   */
  public static async generateRSAKeyPair(alias: string, purpose: huks.HuksKeyPurpose, digest: huks.HuksKeyDigest) {
    LogUtils.i(TAG, `start generateKeyItem`);

    let keyAlias = alias ? alias : '';
    let keyDigest: huks.HuksKeyDigest = digest ? digest : huks.HuksKeyDigest.HUKS_DIGEST_NONE;
    let properties: GenKeyPropertyType[] = [
      {
        tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
        value: huks.HuksKeyAlg.HUKS_ALG_RSA
      },
      {
        tag: huks.HuksTag.HUKS_TAG_PURPOSE,
        value: purpose
      },
      {
        tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
        value: huks.HuksKeySize.HUKS_RSA_KEY_SIZE_2048
      },
      {
        tag: huks.HuksTag.HUKS_TAG_DIGEST,
        value: keyDigest
      },
      {
        tag: huks.HuksTag.HUKS_TAG_PADDING,
        value: huks.HuksKeyPadding.HUKS_PADDING_PSS
      },
      {
        tag: huks.HuksTag.HUKS_TAG_AUTH_STORAGE_LEVEL,
        value: huks.HuksAuthStorageLevel.HUKS_AUTH_STORAGE_LEVEL_DE
      },
      {
        tag: huks.HuksTag.HUKS_TAG_KEY_GENERATE_TYPE,
        value: huks.HuksKeyGenerateType.HUKS_KEY_GENERATE_TYPE_DEFAULT
      }
    ];
    let huksOptions: huks.HuksOptions = {
      properties: properties,
      inData: new Uint8Array([])
    };

    try {
      await huks.generateKeyItem(keyAlias, huksOptions).then(() => {
        LogUtils.i(TAG, `generateKeyItem success`);
      }).catch((error: BusinessError) => {
        LogUtils.e(TAG, `generateKeyItem failed, errorCode:${error.code} errorMessage:${error.message}`);
      });
    } catch (e) {
      LogUtils.e(TAG, `generateKeyItem input arg invalid, error:${JSON.stringify(e)}`);
    }
  }

  /**
   * 使用alias指定的秘钥进行签名
   *
   * @param alias   别名
   * @param inData  输入数据
   */
  public static async signData(alias: string, inData: Uint8Array): Promise<Uint8Array | void> {
    if (!alias || !inData) {
      LogUtils.e(TAG, 'signData failed, alias or inData is null');
      return;
    }

    let signProperties: huks.HuksParam[] = [];
    let index = 0;
    signProperties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
      value: huks.HuksKeyAlg.HUKS_ALG_RSA
    };
    signProperties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
      value: huks.HuksKeySize.HUKS_RSA_KEY_SIZE_2048
    };
    signProperties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_PURPOSE,
      value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_SIGN
    };
    signProperties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_DIGEST,
      value: huks.HuksKeyDigest.HUKS_DIGEST_SHA256
    };
    signProperties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_PADDING,
      value: huks.HuksKeyPadding.HUKS_PADDING_PSS
    };
    signProperties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_AUTH_STORAGE_LEVEL,
      value: huks.HuksAuthStorageLevel.HUKS_AUTH_STORAGE_LEVEL_DE
    };
    signProperties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_RSA_PSS_SALT_LEN_TYPE,
      value: huks.HuksRsaPssSaltLenType.HUKS_RSA_PSS_SALT_LEN_DIGEST
    };
    let options: huks.HuksOptions = {
      properties: signProperties,
      inData: inData
    };

    let data: huks.HuksSessionHandle | void = await huks.initSession(alias, options)
      .catch((err: BusinessError) => {
        LogUtils.e(TAG, `signData initSession failed, error: ` + JSON.stringify(err));
      });
    if (!data) {
      LogUtils.e(TAG, `signData initSession result is empty`);
      return;
    }

    try {
      let res = await huks.finishSession(data.handle, options);
      if (res) {
        return res.outData;
      } else {
        LogUtils.e(TAG, `signData failed, error: huks.finishSession.result is null`);
      }
    } catch (e) {
      LogUtils.e(TAG, `signData failed error: ${JSON.stringify(e)}`);
    }
  }
}
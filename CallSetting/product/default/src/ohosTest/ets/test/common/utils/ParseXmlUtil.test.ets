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
import { describe, it, expect } from '@ohos/hypium'
import { ParseXmlUtil, SpanNodeInfo } from '../../../../../main/ets/common/utils/ParseXmlUtil';
import { xml } from '@kit.ArkTS';

export default function ParseXmlUtilTest() {
  let currentNode: SpanNodeInfo;
  describe('ParseXmlUtilTest', () => {

    it('ParseXmlUtilTest_parseXml', 0, () => {
      let numberIdentityNotification: string =
        "<body><span style='normal'>This service requires </span><span style='bold'>Internet</span><span style='normal'> and </span><span style='bold'>Contacts</span><span style='normal'> access, and needs to read your contacts, read and modify the call log, and read and upload/transfer SMS message content. By turning this on, you agree to these terms. For more details about how your personal information is processed, refer to the </span><span style='privacyStatement'>Statement About Call &amp; Message Identification and Privacy</span><span style='normal'> and </span><span style='permissionStatement'>Permissions Notice</span><span style='normal'>.</span></body>";
      let spanNodeArray = [];
      let r = ParseXmlUtil.getInstance().parseXml(numberIdentityNotification, spanNodeArray);
      expect(r == null).assertTrue()
    })
    it('ParseXmlUtilTest_test', 0, () => {
      let parse = ParseXmlUtil.getInstance();
      let info: xml.ParseInfo = {
        getColumnNumber: (): number => {
          throw new Error('Function not implemented.');
        },
        getDepth: (): number => {
          return 2
        },
        getLineNumber: (): number => {
          throw new Error('Function not implemented.');
        },
        getName: (): string => {
          throw new Error('Function not implemented.');
        },
        getNamespace: (): string => {
          throw new Error('Function not implemented.');
        },
        getPrefix: (): string => {
          throw new Error('Function not implemented.');
        },
        getText: (): string => {
          throw new Error('Function not implemented.');
        },
        isEmptyElementTag: (): boolean => {
          throw new Error('Function not implemented.');
        },
        isWhitespace: (): boolean => {
          throw new Error('Function not implemented.');
        },
        getAttributeCount: (): number => {
          throw new Error('Function not implemented.');
        }
      };
      (parse as object)['currentNode'] = currentNode;
      (parse as object)['onTokenValue'](xml.EventType.TEXT, info);
      (parse as object)['onTokenValue'](xml.EventType.END_TAG, info);
      (parse as object)['onTokenValue'](xml.EventType.END_DOCUMENT, info);
      let result: boolean = (parse as object)['onAttributeValue']('test', 'test');
      expect(result).assertTrue();
    })
  })
}
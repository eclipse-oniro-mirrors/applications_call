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

import util from '@ohos.util';
import xml from '@ohos.xml';
import { LogUtils } from '@ohos/common/CommonIndex';

const TAG = 'ParseXmlUtil';
const CONTENT_DEPTH = 2;

export class SpanNodeInfo {
  public content: string = '';
  public textStyle: string = '';
}

export class ParseXmlUtil {
  private static sParseXmlUtil: ParseXmlUtil;
  private spanNodeArray: SpanNodeInfo[] = [];
  private currentNode?: SpanNodeInfo;

  public static getInstance(): ParseXmlUtil {
    if (ParseXmlUtil.sParseXmlUtil == null) {
      ParseXmlUtil.sParseXmlUtil = new ParseXmlUtil();
    }
    return ParseXmlUtil.sParseXmlUtil;
  }

  parseXml(src: string, spanNodeArray: SpanNodeInfo[]) {
    LogUtils.i(TAG, 'parseXml');
    this.spanNodeArray = spanNodeArray;
    let textEncoder = new util.TextEncoder();
    let arrbuffer = textEncoder.encodeInto(src);
    let that = new xml.XmlPullParser(arrbuffer.buffer.slice(0), 'UTF-8');
    let options: xml.ParseOptions = {
      supportDoctype: true,
      ignoreNameSpace: true,
      attributeValueCallbackFunction: this.onAttributeValue,
      tokenValueCallbackFunction: this.onTokenValue
    }
    that.parse(options);
  }

  private onAttributeValue = (name: string, value: string) => {
    if (name === 'style' && this.currentNode !== undefined) {
      this.currentNode.textStyle = value;
    }
    return true;
  }

  private onTokenValue = (eventType: xml.EventType, value: xml.ParseInfo) => {
    if (value.getDepth() !== CONTENT_DEPTH) {
      return true;
    }
    switch (eventType) {
      case xml.EventType.START_TAG:
        this.currentNode = new SpanNodeInfo();
        break;
      case xml.EventType.TEXT:
        if (this.currentNode !== undefined) {
          this.currentNode.content = value.getText();
        }
        break;
      case xml.EventType.END_TAG:
        if (this.currentNode !== undefined) {
          this.spanNodeArray.push(this.currentNode);
        }
        break;
      default:
    }
    return true;
  }
}
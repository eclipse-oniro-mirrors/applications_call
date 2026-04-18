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

import xmlConvertUtils from '@ohos.convertxml';

export class EmergencyContactConvertOptions implements xmlConvertUtils.ConvertOptions {
  public trim = false;
  public declarationKey = '_declaration';
  public instructionKey = '_instruction';
  public attributesKey = '_attributes';
  public textKey = '_text';
  public cdataKey = '_cdata';
  public doctypeKey = '_doctype';
  public commentKey = '_comment';
  public parentKey = '_parent';
  public typeKey = '_type';
  public nameKey = '_name';
  public elementsKey = '_elements';
}

export class XmlNode {
  public _type: string = '';
  public _name?: string;
  public _elements?: XmlNode[];
  public _attributes?: Record<string, string>;
  public _text?: string;
}

export class OldContactInfo {
  public id: number = -1;
  public rawContactId: number = -1;
  public phoneNumber: string = '';
  public phoneName: string = '';
}

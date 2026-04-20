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

export type typeText = 'TextInput' | 'Toggle' | 'Radio' | 'Checkbox' | 'Number';

export class SubDataType {
  public key: string = '';
  public type: typeText;
  public displayName: Resource | string;
  public description: string | number | number[];
  public option: OptionClass[];

  constructor(key: string, displayName: Resource | string, type: typeText = 'TextInput', option: OptionClass[] = [],
    description: string | number | number[] = '') {
    this.key = key;
    this.displayName = displayName;
    this.type = type;
    this.option = option;
    this.description = description;
  }
}

export class ApnParamClass {
  public cardType: number;
  public simId: number = -1;
  public mccmnc: string = '';
  public profileID: number = -1;
  public isDefault: number = 0;

  constructor() {
    this.cardType = -1;
  }
}

export class DataListClass {
  public title: string = '';
  public msg: string = '';
  public id: number = -1;
  public isDefault: number = 0;
  public apnTypes: string = '';
}

export class ParamsType {
  public cardType: number = -1;
  public simId: number = -1;
  public mccmnc: string = '';
  public profileID: number = -1;
  public isDefault: number = 0;
}

export class OptionClass {
  public title: Resource | string = '';
  public value: string | number = '';
}

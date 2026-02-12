/**
 * Copyright (c) 2022-2024 Huawei Device Co., Ltd.
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

export class Method {
  includes(array: Array<any>, num: any): boolean {
    let bool = array.find((item) => {
      return item === num;
    });
    return num === bool;
  }

  assign(target: any, source1: any, source2?: any) {
    return Object.assign(target, {
      ...source1,
      ...source2
    });
  }
}

let mMethod = new Method();

export default mMethod as Method;
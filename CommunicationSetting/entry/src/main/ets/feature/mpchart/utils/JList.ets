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
export class JList<T> {
  public dataSource: Array<T>;
  // 列表的大小
  public listSize: number;
  // 列表中当前的位置
  public pos: number;

  constructor() {
    this.dataSource = [];
    this.listSize = 0;
    this.pos = 0;
  }

  get(pos: number): T {
    return this.dataSource[pos];
  }

  length(): number {
    return this.listSize;
  }
}
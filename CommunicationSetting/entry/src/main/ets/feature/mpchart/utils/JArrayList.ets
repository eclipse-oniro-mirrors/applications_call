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
import { JList } from './JList';

export class JArrayList<T> {
  public dataSource: Array<T>;
  // 列表的大小
  public listSize: number = 0;
  // 列表中当前的位置
  public pos: number = 0;

  constructor() {
    this.dataSource = [];
    this.listSize = 0;
    this.pos = 0;
  }

  append(element: T) {
    this.dataSource[this.listSize++] = element;
  }

  add(element: T) {
    this.append(element)
    return this
  }

  addAll(newArray: JList<T>) {
    let len = newArray.length()
    for (let i = 0; i < len; i++) {
      this.append(newArray.get(i))
    }
  }

  indexOf(element: T): number {
    return this.dataSource.indexOf(element);
  }

  get(pos: number): T {
    return this.dataSource[pos];
  }

  clear() {
    this.dataSource = [];
    this.listSize = 0;
    this.pos = 0;
  }

  length(): number {
    return this.listSize;
  }

  size(): number {
    return this.listSize;
  }

  isEmpty(): boolean {
    return this.listSize == 0;
  }
}


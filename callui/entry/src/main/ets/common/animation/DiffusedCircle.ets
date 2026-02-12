/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

@Component
export struct DiffusedCircle {
  @State tailCount: number = 50;
  @State arr: number[] = [];
  mSize: number = 10;

  aboutToAppear() {
    let op = 1;
    for (let index = 0; index < this.tailCount; index++) {
      this.arr[index] = op
      op = op * 0.88;
    }
  }

  build() {
    Stack() {
      ForEach(this.arr, (item: number, index: number) => {
        Circle()
          .width(this.mSize)
          .height(this.mSize)
          .fill('#ffc4c2c2')
          .opacity(item)
          .offset({ x: 0.5 * index })
          .scale({ x: 1 - 0.01 * index, y: 1 - 0.01 * index })
      })
    }
    .width('100%')
    .height('100%')
  }
}
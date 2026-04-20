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

export default class MyRect {
  public left: number = 0;
  public top: number = 0;
  public right: number = 0;
  public bottom: number = 0;

  constructor(left?: number, top?: number, right?: number, bottom?: number, r?: MyRect) {
    this.left = left == undefined ? 0 : left
    this.top = top == undefined ? 0 : top;
    this.right = right == undefined ? 0 : right;
    this.bottom = bottom == undefined ? 0 : bottom;
    if (r != null || r != undefined) {
      this.left = r.left;
      this.top = r.top;
      this.right = r.right;
      this.bottom = r.bottom;
    }
  }

  public width(): number {
    return this.right - this.left;
  }

  public height(): number {
    return this.bottom - this.top;
  }

  public centerX(): number {
    return (this.left + this.right) >> 1;
  }

  public set(left: number, top: number, right: number, bottom: number) {
    this.left = left;
    this.top = top;
    this.right = right;
    this.bottom = bottom;
  }

  public inset(left: number, top: number, right: number, bottom: number) {
    this.left += left;
    this.top += top;
    this.right -= right;
    this.bottom -= bottom;
  }
}
/**
 * Copyright (c) 2025-2025 Huawei Device Co., Ltd.
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

export interface CardContents {
  displayImagePath: string;
  applyData: string;
  fileFd: number;
  thumbnail?: PixelMap | undefined;
  ignoreTimeStamp?: boolean;
  label?: ResourceStr;
  isInUse?: boolean;
  noInUse?: boolean;
  inSelect?: boolean;
  historyIndex?: number;
  isBlur?: boolean;
  videoDuration?: string
};

const OBJECT_PREFIX = 'Card#';
let objectCount: number = 0;

@Observed
export class Card {
  public displayImagePath: string; // 裁剪图路径
  public applyData: string; // 原图路径
  public thumbnail: PixelMap | undefined = undefined; // 缩略图路径
  public fileFd: number = -1;
  public ignoreTimeStamp: boolean = false; //
  public label: ResourceStr = '';

  public isInUse: boolean = false;
  public noInUse: boolean = false;
  public inSelect: boolean = false;
  public historyIndex: number = -1;
  public isLoading: boolean = false;
  public isPc: boolean = false;
  public videoDuration: string = '';
  public isBlur: boolean = false;
  private objectId: string;

  constructor(contents: CardContents) {
    this.displayImagePath = contents.displayImagePath;
    this.applyData = contents.applyData;
    this.fileFd = contents.fileFd;
    if (contents.thumbnail) {
      this.thumbnail = contents.thumbnail;
    }
    if (contents.label) {
      this.label = contents.label;
    }
    if (contents.isInUse) {
      this.isInUse = contents.isInUse;
    }
    if (contents.noInUse) {
      this.noInUse = contents.noInUse;
    }
    if (contents.inSelect) {
      this.inSelect = contents.inSelect;
    }
    if (contents.historyIndex != null) {
      this.historyIndex = contents.historyIndex;
    }
    if (contents.ignoreTimeStamp) {
      this.ignoreTimeStamp = contents.ignoreTimeStamp;
    }
    if (contents.isBlur) {
      this.isBlur = contents.isBlur;
    }
    if (contents.videoDuration) {
      this.videoDuration = contents.videoDuration;
    }
    this.objectId = `${OBJECT_PREFIX}${objectCount.toString()}`;
    objectCount++;
  }

  public getId(): string {
    return this.objectId;
  }
}
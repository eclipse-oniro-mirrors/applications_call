/**
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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
import { LogUtils } from '@ohos/common';

import { FakeAppIconModel } from '././model/FakeAppIconModel';

const TAG: string = 'FakeAppIcon';
const LAYER_ADAPTIVE_SCALE: number = 1.0;

@Component
export struct FakeAppIcon {
  @Watch('loadFakeAppIconModel') @ObjectLink data: FakeAppIconModel;
  @State iconImage?: string = '';
  @State backgroundPath?: string = undefined;
  @State foregroundPath?: string = undefined;
  @State targetWidth: Length = 0;
  @State targetHeight: Length = 0;
  @State iconRadius: Resource | number = 0;
  @State borderOptions: BorderOptions = {
    width: 0,
  };

  aboutToAppear(): void {
    this.loadFakeAppIconModel();
  }

  aboutToDisappear(): void {
  }

  private loadFakeAppIconModel(): void {
    if (!this.data) {
      LogUtils.e(TAG, 'data is undefined');
      return;
    }
    if (Array.isArray(this.data.iconData)) {
      LogUtils.i(TAG, `loadFakeAppIconModel, iconData is array`);
      this.backgroundPath = this.data.iconData[0];
      this.foregroundPath = this.data.iconData[1];
    } else {
      this.iconImage = this.data.iconData;
    }
  }

  @Builder
  layerIcon() {
    Stack({ alignContent: Alignment.Center }) {
      Image(this.backgroundPath)
        .draggable(false)
        .height(this.targetHeight)
        .width(this.targetWidth)
        .scale({
          x: LAYER_ADAPTIVE_SCALE,
          y: LAYER_ADAPTIVE_SCALE,
        })
        .interpolation(ImageInterpolation.High)
        .id(`background_${this.data?.appName}`)
    }
    .clip(true)
    .height(this.targetWidth)
    .width(this.targetHeight)
    .borderRadius(this.iconRadius)

    Image(this.foregroundPath)
      .draggable(false)
      .height(this.targetHeight)
      .width(this.targetWidth)
      .scale({
        x: LAYER_ADAPTIVE_SCALE,
        y: LAYER_ADAPTIVE_SCALE,
      })
      .objectFit(ImageFit.Contain)
      .interpolation(ImageInterpolation.Low)
      .autoResize(false)
      .id(`foreground_${this.data?.appName}`)
  }

  @Builder
  pixelMapIcon() {
    Image(this.iconImage)
      .draggable(false)
      .height(this.targetHeight)
      .width(this.targetWidth)
      .objectFit(ImageFit.Contain)
      .interpolation(ImageInterpolation.Low)
      .autoResize(false)
      .id(`pixelmap_${this.data?.appName}`)
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.backgroundPath && this.foregroundPath) {
        this.layerIcon()
      } else {
        this.pixelMapIcon()
      }
    }
    .focusable(true)
    .border(this.borderOptions)
    .clip(true)
    .height(this.targetWidth)
    .width(this.targetHeight)
    .borderRadius(this.iconRadius)
  }
}
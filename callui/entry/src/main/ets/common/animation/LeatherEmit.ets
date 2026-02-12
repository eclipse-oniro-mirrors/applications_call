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
import { displaySync } from '@kit.ArkGraphics2D';
import Curves from '@ohos.curves'
import { DiffusedCircle } from './DiffusedCircle';

export const EMIT_INTERVAL: number = 500;

const CIRCLE_SIZE_WIDE: number = 80;
const CIRCLE_SIZE: number = 42;
const COMET_TOTAL_HEIGHT = 25;
const COMET_TOTAL_WIDTH = 10;

const TAG: string = 'LeatherEmit';

const DEFAULT_SCALE: number = 0.7;
const DEFAULT_OPACITY: number = 0;
const DEFAULT_BLUR: number = 0;
const DEFAULT_OFFSET: number = 15;

const EMITS_NUMBER: number = 2;
const EMITS_NUMBER_REJECT: number = 3;
const COMET_OFFSET_DURATION: number = 700;
const COMET_OPACITY_DURATION1: number = 350;
const COMET_OPACITY_DURATION2: number = 350;
const COMET_MAX_OFFSET: number = -95;
const COMET_MAX_OFFSET_REJECT: number = -450;
const COMET_SCALE_DURATION: number = 450;
const COMET_SCALE_DELAY: number = 250;

@Component
export struct LeatherEmit {
  private isIncoming: boolean = true
  @State scale1: number = DEFAULT_SCALE;
  @State opacity1: number = DEFAULT_OPACITY;
  @State blur1: number = DEFAULT_BLUR;
  @State offset1: string = DEFAULT_OFFSET + 'px';
  @State scale2: number = DEFAULT_SCALE;
  @State opacity2: number = DEFAULT_OPACITY;
  @State blur2: number = DEFAULT_BLUR;
  @State offset2: string = DEFAULT_OFFSET + 'px';
  @Prop @Watch('updateAnimation') touchDown: boolean;
  @Prop isWideMode: boolean = true;
  private animationFps: ExpectedFrameRateRange = { min: 47, max: 57, expected: 47 };
  private displaySyncInfo: displaySync.DisplaySync = displaySync.create();
  private currentTime: number = 0;
  private totalTime: number = 3500;
  private singleFpsTime: number = 1000 / this.animationFps.expected;
  private frictionCurve: ICurve = Curves.cubicBezierCurve(0.2, 0.0, 0.2, 1.0);
  private isStartAnimation: boolean = true;
  private startTimerId: number = -1;

  initDisplaySync(): void {
    this.displaySyncInfo.setExpectedFrameRateRange(this.animationFps);
    this.displaySyncInfo.on('frame', (data) => {
      if (!this.isStartAnimation) {
        return;
      }
      try {
        this.currentTime = (this.currentTime + this.singleFpsTime) % this.totalTime;
        this.updateFirstComet();
        this.updateSecondComet();
      } catch (error) {
      }
    });
    this.displaySyncInfo.start();
  }

  updateFirstComet(): void {
    if ((0 <= this.currentTime && this.currentTime <= COMET_OFFSET_DURATION) ||
      (EMIT_INTERVAL * 2 <= this.currentTime && this.currentTime <= EMIT_INTERVAL * 2 + COMET_OFFSET_DURATION)) {
      let animationTime1 = this.currentTime % 1000;
      let currentOpacity1: number = DEFAULT_OPACITY;
      let currentOffset1: string = '0';
      let currentScale1: number = DEFAULT_SCALE;
      if (animationTime1 <= COMET_OPACITY_DURATION1) {
        currentOpacity1 = animationTime1 / COMET_OPACITY_DURATION1;
      } else {
        currentOpacity1 = (COMET_OFFSET_DURATION - animationTime1) / COMET_OPACITY_DURATION2;
      }
      let offsetRatio: number = animationTime1 / COMET_OFFSET_DURATION;
      let offsetData = this.frictionCurve.interpolate(offsetRatio);
      currentOffset1 = (DEFAULT_OFFSET -
        (DEFAULT_OFFSET - (this.isIncoming ? COMET_MAX_OFFSET : COMET_MAX_OFFSET_REJECT)) * offsetData) + 'px';
      if (animationTime1 >= COMET_SCALE_DELAY) {
        let scaleRatio: number = (animationTime1 - COMET_SCALE_DELAY) / COMET_SCALE_DURATION;
        let scaleData = this.frictionCurve.interpolate(scaleRatio);
        currentScale1 = DEFAULT_SCALE - 0.5 * scaleData;
      }
      this.setOpacity(0, currentOpacity1);
      this.setOffset(0, currentOffset1);
      this.setScale(0, currentScale1);
    } else {
      this.resetParam(0);
    }
  }

  updateSecondComet(): void {
    if ((EMIT_INTERVAL <= this.currentTime && this.currentTime <= COMET_OFFSET_DURATION + EMIT_INTERVAL) ||
      (EMIT_INTERVAL * 3 <= this.currentTime && this.currentTime <= EMIT_INTERVAL * 3 + COMET_OFFSET_DURATION)) {
      let animationTime2 = (this.currentTime - EMIT_INTERVAL) % 1000;
      let currentOpacity2: number = DEFAULT_OPACITY;
      let currentOffset2: string = '0';
      let currentScale2: number = DEFAULT_SCALE;
      if (animationTime2 <= COMET_OPACITY_DURATION1) {
        currentOpacity2 = animationTime2 / COMET_OPACITY_DURATION1;
      } else {
        currentOpacity2 = (COMET_OFFSET_DURATION - animationTime2) / COMET_OPACITY_DURATION2;
      }
      let offsetRatio: number = animationTime2 / COMET_OFFSET_DURATION;
      let offsetData = this.frictionCurve.interpolate(offsetRatio);
      currentOffset2 = (DEFAULT_OFFSET -
        (DEFAULT_OFFSET - (this.isIncoming ? COMET_MAX_OFFSET : COMET_MAX_OFFSET_REJECT)) * offsetData) + 'px';
      if (animationTime2 >= COMET_SCALE_DELAY) {
        let scaleRatio: number = (animationTime2 - COMET_SCALE_DELAY) / COMET_SCALE_DURATION;
        let scaleData = this.frictionCurve.interpolate(scaleRatio);
        currentScale2 = DEFAULT_SCALE - 0.5 * scaleData;
      }
      this.setOpacity(1, currentOpacity2);
      this.setOffset(1, currentOffset2);
      this.setScale(1, currentScale2);
    } else {
      this.resetParam(1);
    }
  }

  aboutToAppear(): void {
    this.initDisplaySync();
  }

  aboutToDisappear() {
    try {
      this.displaySyncInfo.off('frame', () => {
      });
      this.displaySyncInfo.stop();
    } catch (error) {
    }
  }

  updateAnimation() {
    if (this.startTimerId > 0) {
      clearTimeout(this.startTimerId);
    }
    if (!this.touchDown) {
      this.startTimerId = setTimeout(() => {
        this.isStartAnimation = true;
      }, EMIT_INTERVAL);
    } else {
      this.isStartAnimation = false;
      this.stopAnimation();
    }
  }

  stopAnimation() {
    for (let index = 0; index < (this.isIncoming ? EMITS_NUMBER : EMITS_NUMBER_REJECT); index++) {
      this.setOpacity(index, 0);
      this.setOffset(index, '0');
      this.setScale(index, 0.5);
      this.setBlur(index, 1);
    }
    animateTo({ duration: 0 }, () => {
      for (let index = 0; index < (this.isIncoming ? EMITS_NUMBER : EMITS_NUMBER_REJECT); index++) {
        this.resetParam(index);
      }
    })
    this.currentTime = 0;
  }

  setOpacity(index: number, value: number) {
    if (index === 0) {
      this.opacity1 = value;
    } else {
      this.opacity2 = value;
    }
  }

  setScale(index: number, value: number) {
    if (index === 0) {
      this.scale1 = value;
    } else {
      this.scale2 = value;
    }
  }

  setOffset(index: number, value: string) {
    if (index === 0) {
      this.offset1 = value;
    } else {
      this.offset2 = value;
    }
  }

  setBlur(index: number, value: number) {
    if (index === 0) {
      this.blur1 = value;
    } else {
      this.blur2 = value;
    }
  }

  resetParam(index: number) {
    this.setOpacity(index, DEFAULT_OPACITY);
    this.setScale(index, DEFAULT_SCALE);
    this.setOffset(index, DEFAULT_OFFSET + 'px');
    this.setBlur(index, DEFAULT_BLUR)
  }

  @Builder
  buildComets(isUp: boolean): void {
    Stack({ alignContent: Alignment.Center }) {
      DiffusedCircle()
        .translate({ x: this.offset1 })
        .scale({ x: this.scale1, y: this.scale1 })
        .opacity(this.opacity1)
        .blur(this.blur1, undefined, { disableSystemAdaptation: true })
      DiffusedCircle()
        .translate({ x: this.offset2 })
        .scale({ x: this.scale2, y: this.scale2 })
        .opacity(this.opacity2)
        .blur(this.blur2, undefined, { disableSystemAdaptation: true })
    }
    .height(COMET_TOTAL_HEIGHT)
    .width(COMET_TOTAL_WIDTH)
    .rotate({ angle: isUp ? 90 : 270 })
  }

  build() {
    Column() {
      if (this.isIncoming) {
        this.buildComets(true);
      }
      Stack()
        .width(this.isWideMode ? CIRCLE_SIZE_WIDE : CIRCLE_SIZE)
        .height(this.isWideMode ? CIRCLE_SIZE_WIDE : CIRCLE_SIZE)
        .visibility(Visibility.Hidden)
        .backgroundColor(Color.White)
      this.buildComets(false);
    }
    .justifyContent(this.isIncoming ? FlexAlign.Center : FlexAlign.Start)
    .width(this.isWideMode ? CIRCLE_SIZE_WIDE : CIRCLE_SIZE)
    .height('100%')
  }
}
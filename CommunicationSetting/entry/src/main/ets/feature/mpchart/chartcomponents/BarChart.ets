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

import BarChartModel from '../charts/BarChartModel';
import { CustomUiInfo } from '../data/customUiData';
import { EventType } from '../listener/EventControl';

@Component
export struct BarChart {
  model: BarChartModel | null = null;
  private setRender: RenderingContextSettings | null = null;
  private context2D: CanvasRenderingContext2D | null = null;
  @Prop customInfo: CustomUiInfo | null = null;
  @Prop customTriggerEvent: EventType = EventType.SingleTap;

  aboutToAppear() {
    this.setRender = new RenderingContextSettings(true);
    this.context2D = new CanvasRenderingContext2D(this.setRender);
  }

  aboutToDisappear(): void {
    this.model?.clearJobs();
    this.setRender = null;
    this.context2D = null;
  }

  invalidate() {
    this.model?.invalidate();
  }

  @Builder
  emptyBuilder() {
  };

  @BuilderParam customUiBuilder: () => void = this.emptyBuilder;

  @Builder
  chartBuilder() {
    Canvas(this.context2D)
      .onReady(() => {
        if (this.model && this.context2D) {
          this.model.setContext2D(this.context2D);
          this.model.onDraw(this.context2D);
        }
      })
      .onAreaChange((oldArea: Area, newArea: Area) => {
        if (this.model && ((newArea.width !== oldArea.width) || (newArea.height !== oldArea.height))) {
          this.model.onChartSizeChanged(Number(newArea.width), Number(newArea.height));
        }
      })
      .onTouch((event) => {
        this.model?.onTouchEvent(event);
      })
      .hitTestBehavior(HitTestMode.Default)
      .priorityGesture(
        TapGesture({ count: 1 })
        .onAction((event?: GestureEvent) => {
          if (event && this.model) {
            this.model.onSingleTapUp(false, event);
            if (this.customTriggerEvent === EventType.SingleTap &&
            this.model.eventControl.eventIsEnable(EventType.SingleTap)) {
              this.calcCustomUiInfo(event);
            }
          }
        })
      )
      .scale({
        x: this.model?.getHorizontalFlip() ? -1 : 1
      })
  };

  public calcCustomUiInfo(ev: GestureEvent | TouchEvent) {
    if (!this.customInfo) {
      return;
    }
    if (!this.model) {
      return;
    }
    const pos = this.model.calcPos(false, ev);
    if (!pos) {
      return;
    }
    const entryData = this.model.getEntryByTouchPoint(pos[0], pos[1]);
    if (entryData) {
      const vph = this.model.getViewPortHandler();
      const isInbounds = vph.isInBounds(pos[0], pos[1]);
      // 距离左侧距离
      const offsetLeft = pos[0] - vph.offsetLeft();
      // 距离右侧
      const offsetRight = vph.getChartWidth() - pos[0] - vph.offsetRight();
      this.customInfo.isInbounds = isInbounds;
      this.customInfo.x = pos[0];
      this.customInfo.y = pos[1];
      this.customInfo.offsetLeft = offsetLeft;
      this.customInfo.offsetRight = offsetRight;
      this.customInfo.data = entryData;
      this.customInfo.showUi = true;
    }
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.TopStart }) {
        this.chartBuilder();
        if (this.customInfo && this.customInfo.showUi) {
          this.customUiBuilder()
        }
      }
    }
  }
}


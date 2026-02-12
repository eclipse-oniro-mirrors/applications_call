/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { formatToHHmmSS } from '../utils/TimeFormatUtil'

@Component
export struct TimingTextView {

  // 后续如果需要复用此组件的定时计数功能，但样式不同时，可把样式通过@State传递进来
  @State txtBeforeTiming: string = ''
  @State txtAfterTiming: string = ''
  @State fontColor: ResourceColor = Color.White
  @State fontSize: number | string | Resource = $r('sys.float.Body_M')
  @State createTime: number = Date.now()

  @State timeCount: number = 0

  private intervalId: number = -1

  private getTimeFormatText(): string {
    return formatToHHmmSS(this.timeCount)
  }

  aboutToAppear(): void {
    this.intervalId = setInterval(() => {
      this.timeCount = Math.floor((Date.now() - this.createTime) / 1000)
    }, 1000)
  }

  build() {
    Text(`${this.txtBeforeTiming}${this.getTimeFormatText()}${this.txtAfterTiming}`)
      .id('txtTimingView')
      .fontColor(this.fontColor)
      .fontSize(this.fontSize)
      .maxFontScale(1)
      .margin({
        top: 4
      })
  }

  aboutToDisappear(): void {
    clearInterval(this.intervalId)
  }
}
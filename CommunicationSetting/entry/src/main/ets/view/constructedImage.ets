/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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
import { LengthMetrics } from '@ohos.arkui.node';
import { Utils } from '../util/Utils';
import { AppInfo } from '../viewmodel/AppInfo';

@Component
export struct constructedImage {
  public appInfo?: AppInfo;

  build() {
    RelativeContainer() {
      Image(this.appInfo?.img)
        .width('48vp')
        .height('48vp')
        .draggable(false)
      // 分身应用的角标
      if (this.appInfo?.appIndex && Utils.checkAppIndexExists(this.appInfo.appIndex)) {
        Image($r(`app.media.app_icon_clone_index_${this.appInfo.appIndex}`))
          .height('18vp')
          .width('18vp')
          .offset({ start: LengthMetrics.vp(6), top: LengthMetrics.vp(2) })
          .alignRules({
            right: { anchor: '__container__', align: HorizontalAlign.End },
            bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
          })
          .draggable(false)
      }
      if (this.appInfo?.isShowDroidBadge()) {
        Image($r('app.media.droi_corner_mark'))
          .height('14vp')
          .width('18vp')
          .offset({ end: LengthMetrics.vp(3), bottom: LengthMetrics.vp(3) })
          .alignRules({
            right: { anchor: '__container__', align: HorizontalAlign.End },
            bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
          })
          .draggable(false)
      }
    }
    .width('48vp')
    .height('48vp')
  }
}
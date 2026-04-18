/**
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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
import CallColumnUtils from '../../utils/CallColumnUtils';

@Component
export default struct HiCarConferenceTitle {
  @StorageProp('curBp') curBp: string = '';

  build() {
    Row() {
      Text($r('app.string.telephone_Conference'))
        .fontColor($r('sys.color.font_on_primary'))
        .fontSize(CallColumnUtils.getInstance()
          .getDisplayNameForAutoSize($r('app.string.telephone_Conference'), this.curBp, false, true))
        .fontWeight(600)
        .id('callUI_components_ConferenceTitle_rowText_Conference')
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .margin({ bottom: $r('sys.float.padding_level1') })
  }
}
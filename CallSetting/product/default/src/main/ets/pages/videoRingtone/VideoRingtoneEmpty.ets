// import { PafEmptyPage } from '@hms-paf/ui-widget-emptypage';

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

@Component
export default struct VideoRingtoneEmpty {
  @StorageProp('statusBottomHeight') statusBottomHeight: number = 0;
  @Prop isFromContact: boolean;

  build() {
    Stack() {
      // PafEmptyPage({
      //   icon: $rawfile('empty_page_no_video.svg'),
      //   emptyDescription: $r('app.string.no_video_ringtone'),
      //   customBackgroundColor: this.isFromContact ? $r('app.color.color_bind_sheet_background') :
      //   $r('sys.color.ohos_id_color_sub_background'),
      //   fullPage: true,
      // })
      Column(){
        Image($rawfile('empty_page_no_video.svg'))
          .width(120)
          .height(120)
        Text($r('app.string.no_video_ringtone'))
          .fontColor(Color.Gray)
      } .width(`100%`)
        .height(`100%`)
        .padding({bottom:20})
        .backgroundColor(this.isFromContact ? $r('app.color.color_bind_sheet_background') :
          $r('sys.color.ohos_id_color_sub_background'))
        .justifyContent(FlexAlign.Center)
    }
    .layoutWeight(1)
    .constraintSize({ minHeight: 250 })
    .margin({ bottom: this.statusBottomHeight + 'vp' })
  }
}
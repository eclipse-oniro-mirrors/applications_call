/*
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

@Component
export struct ConfirmDialogContent {
  @Prop contentText: Resource = $r('app.string.emptyStr');

  build() {
    Scroll() {
      Row() {
        Text(this.contentText)
          .width('100%')
          .fontColor($r('sys.color.font_primary'))
          .fontSize($r('sys.float.Body_L'))
          .fontWeight(FontWeight.Regular)
          .lineHeight(21)
      }
      .width('100%')
    }
    .nestedScroll({scrollForward: NestedScrollMode.PARALLEL, scrollBackward: NestedScrollMode.PARALLEL})
  }
}
/*
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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

@CustomDialog
export default struct deleteNumberUseDialog {
  controller?: CustomDialogController;
  cancel: () => void = () => {};
  confirm: () => void = () => {};
  dialogTitle: Resource = $r('app.string.is_delete_number');

  build() {
    Column() {
      Row() {
        Text(this.dialogTitle)
          .width('100%')
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontWeight(FontWeight.Regular)
          .lineHeight(21)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .margin({ bottom: 8 })
      .justifyContent(FlexAlign.Center)

      Flex({
        direction: FlexDirection.Row,
        justifyContent: FlexAlign.SpaceBetween,
        alignItems: ItemAlign.Start
      }) {
        Button($r('app.string.cancel'), { type: ButtonType.Capsule })
          .constraintSize({ minHeight: 40 })
          .backgroundColor($r('sys.color.ohos_id_color_background_transparent'))
          .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
          .fontSize($r('sys.float.ohos_id_text_size_sub_title2'))
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            this.controller?.close();
            this.cancel();
          })
          .margin({ right: '4vp' })
          .flexGrow(1)
        Divider()
          .margin({ top: 8 })
          .flexShrink(0)
          .vertical(true)
          .height(24)
          .color($r('sys.color.ohos_id_color_list_separator'))
        Button($r('app.string.delete'), { type: ButtonType.Capsule })
          .flexGrow(1)
          .constraintSize({ minHeight: 40 })
          .backgroundColor($r('sys.color.ohos_id_color_background_transparent'))
          .fontSize($r('sys.float.ohos_id_text_size_sub_title2'))
          .fontColor($r('sys.color.ohos_id_color_warning'))
          .fontWeight(FontWeight.Medium)
          .margin({ left: '4vp' })
          .onClick(() => {
            this.controller?.close();
            this.confirm();
          })
      }
      .width('100%')
      .constraintSize({ minHeight: 56 })
    }
    .padding({ left: 16, right: 16, top: 24 })
    .width('100%')
  }
}
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

import { ComponentContent, display, promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import LogUtils from '../../utils/HiLog';
import { common } from '@kit.AbilityKit';

const fourthGearFont = 1.75

@Builder
function buildDialog(params: Confirm2ButtonParams) {
  Column() {
    RelativeContainer() {
      Text(params.mainTitle)
        .id('txtDialogMainTitle')
        .fontSize($r('sys.float.Title_S'))
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Bold)
        .maxFontScale(2)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .alignRules({
          middle: {anchor: '__container__', align: HorizontalAlign.Center}
        })
        .textAlign(TextAlign.Center)
        .padding({left: 8, right: 8})

      Scroll() {
        Text(params.content)
          .fontSize($r('sys.float.Body_L'))
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .width('100%')
      }
      .id('txtDialogContent')
      .width('100%')
      .margin({ top: 12 })
      .padding({left: 8, right: 8})
      .alignRules({
        top: { anchor: 'txtDialogMainTitle', align: VerticalAlign.Bottom },
        middle: { anchor: '__container__', align: HorizontalAlign.Center }
      })
      .constraintSize({ maxHeight: 'calc(100% - 384vp)' })

      Row() {
        Button(params.cancelText)
          .id('btnDialogCancel')
          .btnStyle()
          .onClick(params.cancelClickCallback)
          .alignRules({
            left: { anchor: '__container__', align: HorizontalAlign.Start },
          })

        Row() {
          Divider()
            .vertical(true)
            .width(0.5)
            .height(24)
            .color($r('sys.color.comp_background_tertiary'))
        }
        .width(16)
        .alignRules({
          top: { anchor: 'btnDialogCancel', align: VerticalAlign.Top },
          bottom: { anchor: 'btnDialogCancel', align: VerticalAlign.Bottom },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .justifyContent(FlexAlign.Center)

        Button(params.confirmText)
          .id('btnDialogConfirm')
          .btnStyle()
          .fontColor(params.confirmTextColor)
          .onClick(params.confirmClickCallback)
          .alignRules({
            top: { anchor: 'btnDialogCancel', align: VerticalAlign.Top },
          })
      }
      .alignRules({
        top: { anchor: 'txtDialogContent', align: VerticalAlign.Bottom },
        left: { anchor: '__container__', align: HorizontalAlign.Start },
        right: { anchor: '__container__', align: HorizontalAlign.End },
      })
      .margin({ top: 8 })
    }
    .width('100%')
    .backgroundColor($r('sys.color.comp_background_primary'))
    .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THICK)
    .height('auto')
    .constraintSize({ maxHeight: params.dialogMaxHeight, maxWidth: params.dialogMaxWidth})
    .borderRadius(32)
    .padding({ left: 16, right:16, bottom: 16, top: 12 })
  }
  .width('100%')
  .padding({
    left: 16, right: 16
  })
}

@Extend(Button)
function btnStyle() {
  .width('calc((100% - 16vp) * 0.5)')
  .height('auto')
  .fontColor($r('sys.color.font_emphasize'))
  .fontSize($r('sys.float.Body_L'))
  .backgroundColor(Color.Transparent)
  .borderRadius($r('sys.float.corner_radius_level10'))
  .maxFontScale(2)
  .padding({top: 8, bottom: 8})
}

export class Confirm2ButtonParams {
  private _mainTitle: ResourceStr = '';

  public get mainTitle(): ResourceStr {
    return this._mainTitle;
  }

  public set mainTitle(value: ResourceStr) {
    this._mainTitle = value;
  }

  private _content: ResourceStr = '';

  public set content(value: ResourceStr) {
    this._content = value;
  }

  public get content(): ResourceStr {
    return this._content;
  }

  private _confirmText: ResourceStr = $r('app.string.determine');

  public get confirmText(): ResourceStr {
    return this._confirmText;
  }

  public set confirmText(value: ResourceStr) {
    this._confirmText = value;
  }

  private _confirmTextColor: Resource = $r('sys.color.font_emphasize');

  public set confirmTextColor(value: Resource) {
    this._confirmTextColor = value;
  }

  public get confirmTextColor(): Resource {
    return this._confirmTextColor;
  }

  private _cancelText: ResourceStr = $r('app.string.CANCEL')

  public get cancelText(): ResourceStr {
    return this._cancelText;
  }

  public set cancelText(value: ResourceStr) {
    this._cancelText = value;
  }

  private _confirmClickCallback: () => void = () => {
  };

  public get confirmClickCallback(): () => void {
    return this._confirmClickCallback;
  }

  public set confirmClickCallback(value: () => void) {
    this._confirmClickCallback = value;
  }

  private _cancelClickCallback: () => void = () => {
  };

  public get cancelClickCallback(): () => void {
    return this._cancelClickCallback;
  }

  public set cancelClickCallback(value: () => void) {
    this._cancelClickCallback = value;
  }

  private _onDidDisAppear: () => void = () => {};

  public set onDidDisAppear(value: () => void) {
    this._onDidDisAppear = value;
  }

  public get onDidDisAppear(): () => void {
    return this._onDidDisAppear;
  }

  private _screenHeight: number = 0;

  public get screenHeight() {
    return this._screenHeight;
  }

  public set screenHeight(value: number) {
    this._screenHeight = value;
  }

  private _statusBarHeight: number = 0;

  public get statusBarHeight() {
    return this._statusBarHeight;
  }

  public set statusBarHeight(value: number) {
    this._statusBarHeight = value;
  }

  private _navigationBarHeight: number = 0;

  public get navigationBarHeight() {
    return this._navigationBarHeight;
  }

  public set navigationBarHeight(value: number) {
    this._navigationBarHeight = value;
  }

  private _dialogMaxHeight: number = 0;

  public get dialogMaxHeight() {
    return this._dialogMaxHeight;
  }

  public set dialogMaxHeight(value: number) {
    this._dialogMaxHeight = value;
  }

  private _dialogMaxWidth: number = 400;

  public get dialogMaxWidth() {
    return this._dialogMaxWidth;
  }

  public set dialogMaxWidth(value: number) {
    this._dialogMaxWidth = value;
  }
}

const TAG = 'ConfirmDialogWith2Buttons'

export class ConfirmDialogWith2Buttons {
  private ctx: UIContext

  private contentNode: ComponentContent<Object>
  private options: promptAction.BaseDialogOptions;
  private params: Confirm2ButtonParams;
  private currentScreenStatus: display.Orientation = display.Orientation.PORTRAIT;

  constructor(ctx: UIContext, params: Confirm2ButtonParams = new Confirm2ButtonParams(),
    isShowInSubWindow: boolean = false) {
    this.ctx = ctx;
    this.contentNode = new ComponentContent(this.ctx, wrapBuilder(buildDialog), params);
    this.options = { autoCancel: false, onDidDisappear: params.onDidDisAppear, showInSubWindow: isShowInSubWindow }
    this.params = params;
    display.on('change', () => {
      this.handleScreenStatusChange();
    })
  }

  private handleScreenStatusChange() {
    let displayInfo = display.getDefaultDisplaySync();
    let orientation = displayInfo.orientation;
    if (orientation === this.currentScreenStatus) {
      return;
    }
    let curFontScale: number =
      (this.ctx.getHostContext() as common.UIAbilityContext).config.fontSizeScale ?? 1;
    if (curFontScale < fourthGearFont ||
      orientation === display.Orientation.PORTRAIT ||
      orientation === display.Orientation.PORTRAIT_INVERTED) {
      this.params.dialogMaxWidth = 400;
    } else if (orientation === display.Orientation.LANDSCAPE ||
      orientation === display.Orientation.LANDSCAPE_INVERTED) {
      this.params.dialogMaxWidth = 0.75 * px2vp(displayInfo.width);
    }
    this.currentScreenStatus = orientation;
    this.contentNode.update(this.params);
  }


  openDialog() {
    this.ctx.getPromptAction().openCustomDialog(this.contentNode, this.options)
      .then(() => {
      })
      .catch((error: BusinessError) => {
        let message = (error as BusinessError).message;
        let code = (error as BusinessError).code;
        LogUtils.e(TAG, `CloseCustomDialog open failed, error code is ${code}, message is ${message}`);
      })
  }

  closeDialog() {
    if (this.contentNode !== null) {
      this.ctx.getPromptAction().closeCustomDialog(this.contentNode)
        .then(() => {

        })
        .catch((error: BusinessError) => {
          let message = (error as BusinessError).message;
          let code = (error as BusinessError).code;
          LogUtils.e(TAG, `CloseCustomDialog close failed, error code is ${code}, message is ${message}`);
        })
    }
  }
}
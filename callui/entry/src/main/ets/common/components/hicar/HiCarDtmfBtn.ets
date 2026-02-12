/**
 * Copyright (c) 2024-2024 Huawei Device Co., Ltd.
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
import CallServiceProxy from '../../../model/CallServiceProxy';
import DefaultCallData from '../../struct/TypeUtils';
import LogUtils from '../../utils/LogUtils';

const TAG = 'HiCarDtmfBtn';

class DataListStruct {
  public value: string = '';
  public sign: string = '';
}

@Component
export default struct HiCarDtmfBtn {
  private item?: DataListStruct;
  private mCallServiceProxy: CallServiceProxy = CallServiceProxy.getInstance();
  private callId?: number;
  @State subStr: string = '';
  @State isPressed: boolean = false;
  @Link textInput: string;
  @Link textInputValue: string;
  @Link btnRadius: number;

  private onClickFunction(): void {
    LogUtils.i(TAG, 'onClickFunction');
    this.textInput = this.textInput + this.item?.value;
    if (this.textInput.length > 19) {
      this.subStr = this.textInput.substr(this.textInput.length - 19, this.textInput.length - 1);
      this.textInputValue = this.subStr;
    } else {
      this.textInputValue = this.textInput;
    }
    AppStorage.setOrCreate('TextInputValue', this.textInputValue);
    AppStorage.setOrCreate('TextInput', this.textInput);
    if (this.item !== undefined) {
      this.onBtnTouchStart(this.item);
    }
  }

  private onBtnTouchStart(obj: DataListStruct): void {
    LogUtils.i(TAG, `onBtnTouchStart, value: ${obj?.value}, sign: ${obj?.sign}`);
    this.mCallServiceProxy?.startDTMF(this.callId, String(obj?.value));
  }

  @Builder
  buildActiveLayer() {
    Column()
      .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
      .visibility(this.isPressed ? Visibility.Visible : Visibility.Hidden)
      .size({
        width: '100%',
        height: '100%'
      })
      .borderRadius(this.btnRadius)
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.item?.value == '*') {
        Image($r('app.media.ic_star'))
          .height(24)
          .draggable(false)
      } else if (this.item?.value == '#') {
        Image($r('app.media.ic_pound'))
          .height(24)
          .draggable(false)
      } else {
        Text(this.item?.value)
          .fontSize(24)
          .height(32)
          .lineHeight(32)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .draggable(false)
      }
      this.buildActiveLayer()
    }
    .size({
      width: '100%',
      height: '100%'
    })
    .borderRadius(this.btnRadius)
    .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
    .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THIN, { colorMode: ThemeColorMode.LIGHT },
      { disableSystemAdaptation: true })
    .onTouch((event?: TouchEvent) => {
      switch (event?.type) {
        case TouchType.Down:
        case TouchType.Move:
          this.isPressed = true;
          break;
        case TouchType.Up:
        case TouchType.Cancel:
          this.isPressed = false;
          break;
        default:
          break;
      }
    })
    .onClick((event: ClickEvent) => {
      this.onClickFunction();
    })
  }
}
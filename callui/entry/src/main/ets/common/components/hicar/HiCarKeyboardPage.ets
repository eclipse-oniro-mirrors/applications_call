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

import DefaultCallData from '../../struct/TypeUtils';
import HiCarKeyboard from './HiCarKeyboard';
import ConferenceConst from '../../constant/ConferenceConst';
import BottomViewModel from '../../../viewmodel/BottomViewModel';
import LogUtils from '../../utils/LogUtils';
import { ReportUtil } from '../../utils/ReportUtils/ReportUtil';
import CallServiceProxy from '../../../model/CallServiceProxy';
import CallStateConst from '../../constant/CallStateConst';
import { ReportDeviceType } from '../../utils/ReportUtils/ReportService';
import Utils from '../../utils/utils';
import { StringUtil } from '../../utils/StringUtil';

const TAG: string = 'HiCarKeyboardPage';
const BUTTON_TYPE_RETURN: string = 'return';
const BUTTON_TYPE_HANGUP: string = 'hangUp';

@Component
export default struct HiCarKeyboardPage {
  private mBottomViewModel: BottomViewModel = BottomViewModel.getInstance();
  @Link @Watch('getCallCount') callList: Array<DefaultCallData>;
  @Link @Watch('refreshingData') callData: DefaultCallData;
  @Link callListCount: number;
  @Link hangup: boolean;
  @Link isShowKeyboardPage: boolean;
  @StorageLink('TextInput') textInput: string = '';
  @StorageLink('TextInputValue') textInputValue: string = '';
  @State pressItemType: string = '';
  @State callState: number = -1;
  @State callId: number = -1;
  @State conferenceState: number = -1;
  @State accountId: number = -1;

  aboutToAppear(): void {
    this.refreshingData();
  }

  refreshingData(): void {
    this.callId = this.callData.callId;
    this.callState = this.callData.callState;
    this.conferenceState = this.callData.conferenceState;
    this.accountId = this.callData.accountId;
  }

  private getCallCount(): void {
    let callCount = 0;
    let hasConference: boolean = false;
    for (let i = 0; i < this.callList.length; i++) {
      let curCallData = this.callList[i];
      if (Utils.getInstance().isConferenceCall(curCallData)) {
        if (!hasConference) {
          hasConference = true;
          callCount++;
        }
      } else {
        callCount++;
      }
    }
    this.callListCount = callCount;
  }

  private onHangUp(): void {
    LogUtils.i(TAG, `onHangUp this.callId : ${this.callId}`);
  ReportUtil.getInstance()
      .reportIsDualCardOneInCallAndAnotherDialCancel(this.callList.length, this.accountId,
        this.callState, ReportDeviceType.HICAR);

    this.callState = CallStateConst.CALL_STATUS_DISCONNECTING;
    if (Utils.getInstance().isConferenceCall(this.callData)) {
      CallServiceProxy.getInstance()?.getMainCallId(this.callId, (mainId: number) => {
        this.mBottomViewModel.hangUpCall(mainId, this.callListCount);
        this.hangup = true;
      });
    } else {
      this.mBottomViewModel.hangUpCall(this.callId, this.callList.length);
      this.hangup = true;
    }
  }

  private onBack(): void {
    this.isShowKeyboardPage = false;
  }

  @Builder
  buildBackBtn() {
    Button() {
      SymbolGlyph($r('sys.symbol.chevron_left'))
        .fontColor([Color.White])
        .fontSize(32)
    }
    .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
    .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THIN, { colorMode: ThemeColorMode.LIGHT },
      { disableSystemAdaptation: true })
    .size({
      width: 48,
      height: 48
    })
    .onClick(() => {
      this.onBack();
    })
    .accessibilityText(StringUtil.formatResourceToString($r('app.string.hide_dialpad')))
  }

  @Builder
  buildHangUpBtn() {
    Button() {
      Image($r('app.media.ic_hangup_bottom_btn'))
        .size({
          width: 29,
          height: 29
        })
    }
    .backgroundColor($r('sys.color.ohos_id_color_handup'))
    .size({
      width: 48,
      height: 48
    })
    .onClick(() => {
      this.onHangUp();
    })
  }

  @Builder
  buildBtn(btnType: string) {
    Stack() {
      if (btnType === BUTTON_TYPE_RETURN) {
        this.buildBackBtn()
      } else if (btnType === BUTTON_TYPE_HANGUP) {
        this.buildHangUpBtn()
      }
      this.buildActiveLayer(btnType)
    }
    .onTouch((event?: TouchEvent) => {
      switch (event?.type) {
        case TouchType.Down:
        case TouchType.Move:
          this.pressItemType = btnType;
          break;
        case TouchType.Up:
        case TouchType.Cancel:
          this.pressItemType = '';
          break;
        default:
          break;
      }
    })
  }

  @Builder
  buildActiveLayer(btnType: string) {
    Column()
      .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
      .visibility(this.pressItemType === btnType ? Visibility.Visible : Visibility.Hidden)
      .size({
        width: 48,
        height: 48
      })
      .borderRadius(24)
  }

  @Builder
  buildInputText() {
    Scroll() {
      Text(this.textInputValue)
        .fontColor($r('sys.color.ohos_id_color_text_primary_contrary'))
        .fontSize($r('sys.float.ohos_id_text_size_headline6'))
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .lineHeight(40)
        .constraintSize({ minWidth: '100%' })
        .onTouch((event?: TouchEvent) => {
          if (event?.type === TouchType.Move) {
            this.textInputValue = this.textInput;
          }
        })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }

  @Builder
  buildButtonArea() {
    Flex({
      direction: FlexDirection.Row,
      alignItems: ItemAlign.Center
    }) {
      this.buildBtn(BUTTON_TYPE_RETURN)

      Column() {
        this.buildInputText()
      }
      .layoutWeight(1)
      .margin({
        left: 12,
        right: 12
      })

      this.buildBtn(BUTTON_TYPE_HANGUP)
    }.size({
      width: '100%',
      height: 48
    })
  }

  build() {
    GridRow({ columns: { xs: 4, sm: 8, md: 16, lg: 24 }, gutter: 2 }) {
      GridCol({ span: { xs: 4, sm: 6, md: 10, lg: 14 }, offset: { sm: 1, md: 3, lg: 5 } }) {
        Column() {
          Column() {
            this.buildButtonArea()
          }
          .size({
            width: '100%',
            height: '30%'
          })
          .justifyContent(FlexAlign.End)

          Column() {
            HiCarKeyboard({ callId: $callId })
          }
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .size({
            width: '100%',
            height: '70%'
          })
        }
        .size({
          width: '100%',
          height: '100%'
        })
      }
    }
    .backgroundColor('#000000')
    .size({
      width: '100%',
      height: '100%'
    })
  }
}
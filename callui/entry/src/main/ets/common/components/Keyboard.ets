/**
 * Copyright (c) 2022-2024 Huawei Device Co., Ltd.
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

import DtmfBtn from '../components/DtmfBtn';
import { AppBtnStyleData, AppWindowStyleData } from '../struct/TypeUtils';
import CallColumnUtils from '../utils/CallColumnUtils';
import { ScreenInfo } from '../struct/CallUiDataStruct';
import LogUtils from '../utils/LogUtils';

class DataListStruct {
  public value: string = '';
  public sign: string = '';
}
const TAG = 'Keyboard';

@Component
export default struct Keyboard {
  @State isVideoKeyBoard: boolean = false;
  @Link callId: number;
  @StorageLink('TextInput') textInput: string = '';
  @StorageLink('TextInputValue') textInputValue: string = '';
  @StorageLink('isShowSmartWindow') isShowSmartWindow: boolean = false;
  @StorageLink('isSmartWindowSplitScreen') isSmartWindowSplitScreen: boolean = false;
  @StorageProp('curBp') curBp: string = '';
  @StorageLink('windowSizeChangeMd') windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  }
  @StorageLink('statusBarHeight') statusBarHeight: number = 0;
  @StorageLink('navigationHeight') airbarHeight: number = 0;
  @StorageLink('LandscapeOrPortrait') landscapeOrPortrait: number = 1;
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  @StorageLink('isNewFoldPhoneInnerFullScreen') isNewFoldPhoneInnerFullScreen: boolean = false;
  @StorageLink('isApplyNewStyle') isApplyNewStyle: boolean = false;
  @StorageLink('appWindow') appWindow: AppWindowStyleData = {
    maxWidth: undefined,
    maxHeight: undefined
  };
  @StorageLink('appBtnStyle') appBtnStyle: AppBtnStyleData = {
    btnWidth: 64,
    rowsGap: 20
  };
  @StorageLink('btnBottomGap') btnBottomGap: number = 0;
  @StorageLink('btnLeftGap') btnLeftGap: number = 0;
  @State dataList: Array<DataListStruct> =
    [
      {
        value: '1',
        sign: 'o_o'
      },
      {
        value: '2',
        sign: 'ABC'
      },
      {
        value: '3',
        sign: 'DEF'
      },
      {
        value: '4',
        sign: 'GHI'
      },
      {
        value: '5',
        sign: 'JKL'
      },
      {
        value: '6',
        sign: 'MNO'
      },
      {
        value: '7',
        sign: 'PQRS'
      },
      {
        value: '8',
        sign: 'TUV'
      },
      {
        value: '9',
        sign: 'WXYZ'
      },
      {
        value: '*',
        sign: '(P)'
      },
      {
        value: '0',
        sign: '+'
      },
      {
        value: '#',
        sign: '(W)'
      },
    ];
  @Prop celiaAssistantShow: boolean;

  public aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
  }

  rowsGap(): number | Resource {
    if (this.isApplyNewStyle && this.appBtnStyle.rowsGap) {
      let rowsGap: number = this.appBtnStyle.rowsGap;
      return rowsGap;
    }
    if (this.isNewFoldPhoneExternalScreen || this.isVideoKeyBoard) {
      return 0;
    }
    if (this.isNewFoldPhoneInnerFullScreen) {
      return 12;
    }
    let rowsGapNum = CallColumnUtils.getInstance().rowsGap(this.windowSizeChangeMd, this.isShowSmartWindow,
      this.statusBarHeight, this.airbarHeight, this.curBp,
      this.isSmartWindowSplitScreen);
    return rowsGapNum;
  }

  getGridHeight(isNewFoldPhoneExternalScreen: boolean): number {
    if (this.isApplyNewStyle && this.appBtnStyle.btnWidth) {
      let funcButtonAndKeyboardHeight: number = (this.appBtnStyle.btnWidth * 4) + (this.appBtnStyle.rowsGap * 3);
      return funcButtonAndKeyboardHeight;
    }
    if (isNewFoldPhoneExternalScreen) {
      return 176;
    }
    if (this.isVideoKeyBoard) {
      return 240;
    }
    if (this.isNewFoldPhoneInnerFullScreen) {
      return 292;
    }
    let height = CallColumnUtils.getInstance().gridHeight(this.windowSizeChangeMd, this.isShowSmartWindow,
      this.statusBarHeight, this.airbarHeight, this.curBp,
      this.isSmartWindowSplitScreen);
    LogUtils.i(TAG, `gridHeight: ${height}`);
    return height;
  }

  getColumnsGap() {
    if (this.isApplyNewStyle) {
      return this.btnLeftGap;
    }
    if (this.isVideoKeyBoard) {
      return CallColumnUtils.getInstance().getVideoKeyBoardRowSpace(this.curBp);
    }
    if (this.isNewFoldPhoneInnerFullScreen) {
      return 20;
    }
    return CallColumnUtils.getInstance()
      .getItemSpace(this.curBp, this.isNewFoldPhoneExternalScreen);
  }

  getGridRowMarginLeft() {
    if (this.isVideoKeyBoard || this.isApplyNewStyle) {
      return 0;
    }
    if (this.isNewFoldPhoneExternalScreen) {
      return $r('sys.float.padding_level11');
    }
    if (this.isNewFoldPhoneInnerFullScreen) {
      return $r('app.float.new_form_foldphone_func_btn_margin_space');
    }
    return CallColumnUtils.getInstance()
      .getKeyBordMarginSpace(this.curBp);
  }

  build() {
    GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 },
      gutter: this.isVideoKeyBoard ? 0 : 24
    }) {
      GridCol({
        span: {
          xs: 2,
          sm: 4,
          md: this.isVideoKeyBoard || this.isApplyNewStyle ? 8 : 6,
          lg: this.isVideoKeyBoard || this.isApplyNewStyle ? 12 : 8
        },
        offset: {
          md: this.isVideoKeyBoard || this.isApplyNewStyle ? 0 : 1,
          lg: this.isVideoKeyBoard || this.isApplyNewStyle ? 0 : 2
        }
      }) {
        Grid() {
          ForEach(this.dataList, (item: DataListStruct) => {
            GridItem() {
              DtmfBtn({
                isVideoKeyBoard: this.isVideoKeyBoard,
                item: item,
                textInput: $textInput,
                textInputValue: $textInputValue,
                callId: this.callId
              })
            }
            .height(this.isApplyNewStyle ? this.appBtnStyle.btnWidth : 'auto')
            .align(Alignment.Center)
          })
        }
        .clip(false)
        .width(this.isApplyNewStyle ? (this.appBtnStyle.btnWidth * 3 + this.btnLeftGap * 2) : 'auto')
        .rowsGap(this.rowsGap())
        .columnsGap(this.getColumnsGap())
        .columnsTemplate('1fr 1fr 1fr')
        .rowsTemplate('1fr 1fr 1fr 1fr')
        .direction(Direction.Ltr)
      }
      .height(this.getGridHeight(this.isNewFoldPhoneExternalScreen))
    }
    .id('callui_keyboard_GridRow')
    .margin({
      left: this.getGridRowMarginLeft(),
      right: this.getGridRowMarginLeft()
    })
  }
}
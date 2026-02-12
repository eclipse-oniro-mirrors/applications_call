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

import DefaultCallData from '../struct/TypeUtils';
import CallTimeListStruct from '../struct/CallTimeListStruct';
import VideoContactCard from './VideoContactCard';
import VideoFunBtnGroup from './VideoFuncBtnGroup';
import LogUtils from '../utils/LogUtils';

const TAG = 'VideoCallPanel';
const FLOATPANELHEIGHT = 28;

@Component
export default struct VideoCallPanel {
  @StorageProp('navigationHeight') navigationHeight: number = 0;
  @State callStateText: string = '';
  @State dialing: string = '.';
  @StorageLink('isShowVideoKeyBoard') isShowKeyboard: boolean = false;
  @StorageLink('isShowSmartWindow') isShowSmartWindow: boolean = false;
  @Link callList: Array<DefaultCallData>;
  @Link callData: DefaultCallData;
  @Link callState: number;
  @Link callId: number;
  @Link accountId: number;
  @Link videoState: number;
  @Link callTimeList: Array<CallTimeListStruct>;
  @Link hasMultiDevice: boolean;
  @Prop surfaceId: string = '';
  @Prop callListCount: number = 0;
  @State translateName: string = '';
  @State translateTime: string = '';
  @Prop contactAppear: boolean = false;
  @State multiContactName: string = '';
  @State multiContactNumber: string = '';
  @State isShowSim: boolean = false;
  @State isHidePanel: boolean = true;
  @Link showVideoRbt: boolean;
  @Link isShowVideoPanel: boolean;
  @StorageProp('curBp') curBp: string = '';
  @Provide enableLight: boolean = false;
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  private willHiddenPanel: boolean = false;
  private bindSheetHeight: number = 0;
  touchStatusCallBack: (item: boolean) => void = () => {
  };
  touchCameraCallBack: Function = () => {
  };

  private panelHeigth(): number {
    if (this.isShowSmartWindow) {
      return FLOATPANELHEIGHT;
    }
    return this.navigationHeight;
  }

  private bindSheetWidth(): Dimension {
    if (this.curBp === 'sm' || this.curBp === 'xs') {
      return '100%';
    }
    return 480;
  }

  private updatePanel(height: number) {
    LogUtils.i(TAG, `pannel height: ${height} navigation height: ${this.navigationHeight}`);
    if (this.willHiddenPanel) {
      return;
    }
    let bindSheetOneHeight: number = 40 + 76 + this.panelHeigth() + 12;
    let bindSheetTwoHeight: number = 40 + 176 + this.panelHeigth() + 12;
    let changeHeight: number = 0;
    if (Math.abs(this.bindSheetHeight - bindSheetTwoHeight) < 1) {
      changeHeight = bindSheetTwoHeight - 60;
    } else {
      changeHeight = bindSheetOneHeight;
    }
    if (!this.isShowKeyboard) {
      if (px2vp(height) > changeHeight) {
        if (this.isHidePanel) {
          this.isHidePanel = false;
        }
      } else {
        if (!this.isHidePanel) {
          this.isHidePanel = true;
        }
      }
    } else {
      if (this.isHidePanel) {
        this.isHidePanel = false;
      }
    }
  }

  build() {
    Column() {
    }
    .bindSheet($$this.isShowVideoPanel, this.PanelBuilder, {
      detents: this.isShowKeyboard ?
        [400 + this.panelHeigth()] : this.isNewFoldPhoneExternalScreen ? [124, 208] :
          [40 + 76 + this.panelHeigth() + 12, 40 + 176 + this.panelHeigth() + 12],
      backgroundColor: 'rgba(48, 48, 48, 0.6)',
      blurStyle: BlurStyle.BACKGROUND_REGULAR,
      showClose: false,
      dragBar: false,
      width: this.bindSheetWidth(),
      maskColor: Color.Transparent,
      preferType: SheetType.BOTTOM,
      enableOutsideInteractive: true,
      onHeightDidChange: (height: number) => {
        this.updatePanel(height);
      },
      onDetentsDidChange: (height: number) => {
        this.bindSheetHeight = px2vp(height);
      },
      onAppear: () => {
        this.enableLight = true;
      },
      onWillDisappear: () => {
        this.isShowVideoPanel = false;
        this.willHiddenPanel = true;
        this.isHidePanel = true;
        this.bindSheetHeight = 0;
      },
      onDisappear: () => {
        this.enableLight = false;
        this.willHiddenPanel = false;
      },
      scrollSizeMode: ScrollSizeMode.CONTINUOUS
    })
  }

  @Builder
  CardDragBar() {
    Row() {
      Row() {
        Row() {
        }
        .width(48)
        .height(4)
        .borderRadius($r('sys.float.corner_radius_level2'))
        .margin({ top: $r('sys.float.padding_level4'), bottom: $r('sys.float.padding_level2') })
        .backgroundColor('#33FFFFFF')
      }
      .height(16)
      .width(64)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .visibility(this.isShowKeyboard ? Visibility.None : Visibility.Visible)
  }

  @Builder
  PanelBuilder() {
    Column() {
      this.CardDragBar()
      VideoContactCard({
        callState: $callState,
        callId: $callId,
        isShowKeyboard: $isShowKeyboard,
        callList: $callList,
        callTimeList: $callTimeList,
        isShowSim: $isShowSim,
        translateName: this.translateName,
        translateTime: this.translateTime,
        contactAppear: this.contactAppear,
        isHidePanel: this.isHidePanel,
      })
      VideoFunBtnGroup({
        callData: $callData,
        callId: $callId,
        callState: $callState,
        accountId: $accountId,
        videoState: $videoState,
        callList: $callList,
        callListCount: $callListCount,
        isShowKeyboard: $isShowKeyboard,
        hasMultiDevice: $hasMultiDevice,
        isHidePanel: this.isHidePanel,
        showVideoRbt: this.showVideoRbt,
        btnVideoClick: () => {
          this.touchStatusCallBack(false);
        },
        btnCameraClick: () => {
          this.touchCameraCallBack();
        }
      })
    }
    .onTouch((event) => {
      switch (event.type) {
        case TouchType.Down:
          this.touchStatusCallBack(true);
          break;
        case TouchType.Up:
          this.enableLight = false;
          this.touchStatusCallBack(false);
          break;
      }
    })
    .height('100%')
  }
}
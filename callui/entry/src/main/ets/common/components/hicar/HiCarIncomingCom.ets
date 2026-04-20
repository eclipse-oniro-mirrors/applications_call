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

import LogUtils from '../../utils/LogUtils';
import DefaultCallData from '../../struct/TypeUtils';
import IncomingComVM from '../../../viewmodel/IncomingComVM';
import { getFirstCallByStateExcludeCall } from '../../utils/CallListHelper';
import CallStateConst from '../../constant/CallStateConst';

const TAG = 'HiCarIncomingCom';
const BUTTON_TYPE_ANSWER: string = 'answer';
const BUTTON_TYPE_REJECT: string = 'reject';

@Component
export default struct HiCarIncomingCom {
  private imageList: ImageList[] = [];
  @Link @Watch('initData') callList: Array<DefaultCallData>;
  @Link @Watch('initData') callData: DefaultCallData;
  @State mIncomingVM: IncomingComVM = IncomingComVM.getInstance();
  @State pressItemType: string = '';

  private initData(): void {
    this.mIncomingVM.initData(this.callData, this.callList);
    this.initImageList();
  }

  private initImageList(): void {
    const answer: ImageList = {
      type: BUTTON_TYPE_ANSWER,
      img: $r('app.media.ic_public_answer')
    }
    const reject: ImageList = {
      type: BUTTON_TYPE_REJECT,
      img: $r('app.media.ic_public_ring_off')
    }
    this.imageList = [
      answer,
      reject
    ];
  }

  private onImgClick(type: string): void {
    LogUtils.i(TAG, `onImgClick, type: ${type}`);
    switch (type) {
      case BUTTON_TYPE_REJECT:
        this.onReject();
        break;
      case BUTTON_TYPE_ANSWER:
        this.onAnswer();
        break;
      default:
        LogUtils.i(TAG, 'onImgClick, type error');
        break;
    }
  }

  private onReject(): void {
    this.mIncomingVM.onReject();
  }

  private onAnswer(): void {
    LogUtils.i(TAG, 'onAnswer :');
    let primaryIncomingCall = this.mIncomingVM.primaryIncomingCall;
    // The answer button on the vehicle is set to voice answer by default.
    this.mIncomingVM.onAnswer(false);
    // don't stop the animation state when other incoming call exists
    if (this.mIncomingVM.callList.length > 1) {
      const callData = getFirstCallByStateExcludeCall(this.mIncomingVM.callList, CallStateConst.CALL_STATUS_INCOMING,
        primaryIncomingCall);
      if (callData) {
        return;
      }
    }
  }

  @Builder
  buildActiveLayer(item: ImageList) {
    Column()
      .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
      .visibility(this.pressItemType === item.type ? Visibility.Visible : Visibility.Hidden)
      .size({
        width: 64,
        height: 64
      })
      .borderRadius(32)
  }

  @Builder
  buildImageList() {
    ForEach(this.imageList, (item: ImageList,) => {
      GridItem() {
        Stack() {
          Button() {
            Image(item.img)
              .size({
                width: '100%',
                height: '100%'
              })
              .draggable(false)
          }
          .size({
            width: 64,
            height: 64
          })
          .borderRadius(32)

          this.buildActiveLayer(item)
        }
      }
      .onTouch((event?: TouchEvent) => {
        switch (event?.type) {
          case TouchType.Down:
          case TouchType.Move:
            this.pressItemType = item.type;
            break;
          case TouchType.Up:
          case TouchType.Cancel:
            this.pressItemType = '';
            break;
          default:
            break;
        }
      })
      .onClick(() => {
        this.onImgClick(item.type)
      })
    })
  }

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    this.mIncomingVM.aboutToAppear();
    this.initData();
  }

  build() {
    GridRow({ columns: { xs: 4, sm: 4, md: 8, lg: 12 }, gutter: 2 }) {
      GridCol({ span: { xs: 4, sm: 4, md: 6, lg: 8 }, offset: { md: 1, lg: 2 } }) {
        Grid() {
          this.buildImageList()
        }
        .columnsTemplate('1fr 1fr')
        .rowsTemplate('1fr')
        .size({
          width: '100%',
          height: '100%'
        })
      }
    }
  }
}

interface ImageList {
  type: string,
  img: Resource,
  backgroundColor?: ResourceColor
}

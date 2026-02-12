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
import { display, window } from '@kit.ArkUI';
import DefaultCallData from '../../struct/TypeUtils';
import { GlobalContextHelper } from '../../utils/GlobalContextHelper';
import HiCarDtmfBtn from './HiCarDtmfBtn';
import * as Constants from '../../../common/utils/Constants';
import LogUtils from '../../utils/LogUtils';
import { BusinessError } from '@kit.BasicServicesKit';
import { HiCarUtils } from '../../utils/HiCarUtils';

class DataListStruct {
  public value: string = '';
  public sign: string = '';
}

const TAG = 'HiCarKeyboard';

@Component
export default struct HiCarKeyboard {
  private itemGap: number = 4;
  private dataList: Array<DataListStruct> =
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
  @StorageLink('TextInput') textInput: string = '';
  @StorageLink('TextInputValue') textInputValue: string = '';
  @StorageProp('curBp') curBp: string = '';
  @Link callId: number;
  @State btnRadius: number = 16;
  @State totalHeight: number = 140;

  private async updateLayout(): Promise<void> {
    const windowClass = GlobalContextHelper.getContext().getValue<window.Window>(Constants.HICAR_WINDOW);
    if (!windowClass) {
      this.btnRadius = 16;
      this.totalHeight = 140;
      return;
    }
    try {
      const windowHeight = windowClass.getWindowProperties().windowRect.height;
      // const deviceInfo = await HiCarUtils.getHiCarDeviceInfo();
      // if (deviceInfo === undefined) {
      //   return;
      // }
      // const densityPixels = display.getDisplayByIdSync(Number(deviceInfo.displayId)).densityPixels;
      // if (densityPixels === 0) {
      //   return;
      // }
      // const windowHeightVp = windowHeight / densityPixels;
      // let height: number = 32;
      // if (windowHeightVp > 360) {
      //   height = 48;
      // } else if (windowHeightVp > 280) {
      //   height = 40;
      // }
      // LogUtils.i(TAG, `windowHeight: ${windowHeightVp}, height: ${height}`);
      // this.btnRadius = height / 2;
      // this.totalHeight = height * 4 + this.itemGap * 3;
    } catch (err) {
      const error = err as BusinessError;
      LogUtils.e(TAG, `updateLayout error: ${error.code}`);
    }
  }

  aboutToAppear(): void {
    this.updateLayout();
  }

  build() {
    Grid() {
      ForEach(this.dataList, (item: DataListStruct) => {
        GridItem() {
          HiCarDtmfBtn({
            item: item,
            textInput: $textInput,
            textInputValue: $textInputValue,
            callId: this.callId,
            btnRadius: $btnRadius
          })
        }
        .borderRadius(this.btnRadius)
      })
    }
    .rowsGap(this.itemGap)
    .columnsGap(this.itemGap)
    .columnsTemplate('1fr 1fr 1fr')
    .rowsTemplate('1fr 1fr 1fr 1fr')
    .size({
      width: '100%',
      height: this.totalHeight
    })
  }
}
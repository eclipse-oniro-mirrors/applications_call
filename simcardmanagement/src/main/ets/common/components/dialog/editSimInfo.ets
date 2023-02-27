/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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
import { REGULAR } from '../../../common/utils/constant'
import simServiceProxy from '../../../model/simServiceProxy'
import radioServiceProxy from '../../../model/radioServiceProxy'
import LogUtils from '../../utils/LogUtils'
import { getString } from '../../utils/Utils'

const TAG = "EditSimInfo"

@CustomDialog
export default struct EditSimInfo {
  controller: CustomDialogController;
  action: (simName, curEditList, phoneNumber) => void;
  disabledState: true;
  inputVal: '';
  isShow: true;
  curEditList: any = [];
  MinLength: number = 0;
  MaxLength: number = 17;
  @State simName: string = '';
  @State isChange: boolean = true;
  @State phoneNumber: string = '';
  SIM_NAME1 = 'sim_card_name1';
  SIM_NAME2 = 'sim_card_name2';
  SIM_phoneNumber1 = 'sim_card_phoneNumber1';
  SIM_phoneNumber2 = 'sim_card_phoneNumber2';

  /**
   * Set user's custom operator name
   */
  setShowName(slotId, name) {
    simServiceProxy.setShowName(slotId, name).then((res) => {
      if (res) {
        this.getShowName(slotId);
      }
    }).catch(() => {
    })
  }

  /**
   * Get the custom operator name set by the user -- success
   */
  getShowName(slotId) {
    simServiceProxy.getShowName(slotId).then((res: string) => {
      if (res !== 'null') {
        this.simName = res;
      }
      ;
    }).catch(() => {
    })
  }

  /**
   * Get the customized mobile phone number set by the user
   */
  getShowNumber(slotId) {
    simServiceProxy.getShowNumber(slotId).then((res: string) => {
      if (res !== 'null') {
        this.phoneNumber = res;
      } else {
        this.getPhoneNumber(slotId);
      }
    }).catch(() => {
    })
  }

  /**
   * Set user's customized mobile phone number
   */
  setShowNumber(slotId, phoneNumber) {
    simServiceProxy.setShowNumber(slotId, phoneNumber).then(() => {
    }).catch((err) => {
    })
  }

  /**
   * Get card slot operator name
   */
  getNetName(slotId) {
    radioServiceProxy.getOperatorName(slotId).then((res: string) => {
      if (!slotId) {
        this.simName = res;
      } else {
        this.simName = res;
      }
    }).catch((err) => {
    })
  }

  getPhoneNumber(slotId) {
    simServiceProxy.getSimTelephoneNumber(slotId).then((res: string) => {
      this.phoneNumber = res;
    }).catch((err) => {
    })
  }

  aboutToAppear() {
    LogUtils.i(TAG, "this.curentList:" + JSON.stringify(this.curEditList));
    if (this.curEditList.id === 0) {
      LogUtils.i(TAG, "this.curentList id:" + JSON.stringify(this.curEditList.id));
      this.getShowName(0);
      this.getShowNumber(0);
    } else {
      this.getShowName(1);
      this.getShowNumber(1);
    }
    this.isChange = !this.isChange;
  }

  build() {
    Column() {
      Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Start }) {
        Text($r('app.string.sim_edit', `${getString(this.curEditList.title)}`))
          .fontWeight(FontWeight.Medium)
          .fontFamily('HarmonyHeiTi')
          .fontSize('20vp')
          .fontColor('rgba(0, 0, 0, 0.9)')
          .lineHeight(56)
          .margin({ left: 12, right: 12 })

        TextInput({ text: this.simName, placeholder: $r('app.string.sim_card_name') })
          .maxLength(20)
          .height(48)
          .placeholderFont({ size: 16, family: 'HarmonyHeiTi' })
          .fontWeight(FontWeight.Regular)
          .backgroundColor($r("sys.color.ohos_id_color_list_card_bg"))
          .onChange((value: string) => {
            this.simName = value;
            LogUtils.i(TAG, "simName: " + JSON.stringify(this.simName))
          })
        TextInput({ text: this.phoneNumber, placeholder: $r('app.string.sim_phone_number') })
          .maxLength(15)
          .height(48)
          .placeholderFont({ size: 16, family: 'HarmonyHeiTi' })
          .fontWeight(FontWeight.Regular)
          .backgroundColor($r("sys.color.ohos_id_color_list_card_bg"))
          .onChange((v: string) => {
            let inputString = v.match(REGULAR.regular);
            this.phoneNumber = '';
            if (inputString != null) {
              this.phoneNumber = inputString.join('');
            }
            ;
            this.isChange = !this.isChange;
          })
        Flex({ justifyContent: FlexAlign.SpaceAround }) {
          Text($r('app.string.cancel'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontFamily("HarmonyHeiTi")
            .lineHeight(21)
            .fontColor('#2871d4')
            .onClick(() => {
              this.controller.close();
              this.phoneNumber = '';
              this.simName = '';
            })
          Divider().vertical(true).height(0.5).strokeWidth(1).opacity(0.5)
          Text($r('app.string.confirm'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontFamily("HarmonyHeiTi")
            .lineHeight(21)
            .onClick(() => {
              if (this.phoneNumber == '+') {
                this.controller.close();
                return;
              }
              if (this.curEditList.id === 0) {
                if (!this.phoneNumber) {
                  LogUtils.i(TAG, "onclick edit confim : ")
                  this.phoneNumber = 'null';
                  this.setShowNumber(0, 'null');
                } else {
                  LogUtils.i(TAG, "onclick edit cancel : ")
                  this.setShowNumber(0, this.phoneNumber);
                }
                if (!this.simName) {
                  this.simName = 'null';
                  this.setShowName(0, 'null');
                } else {
                  this.setShowName(0, this.simName);
                }
                this.action(this.simName, this.curEditList, this.phoneNumber);
              } else {
                if (!this.phoneNumber) {
                  this.phoneNumber = 'null'
                  this.setShowNumber(1, 'null');
                } else {
                  this.setShowNumber(1, this.phoneNumber);
                }
                if (!this.simName) {
                  this.simName = 'null';
                  this.setShowName(1, 'null');
                } else {
                  this.setShowName(1, this.simName);
                }
                this.action(this.simName, this.curEditList, this.phoneNumber);
              }
              this.isChange = !this.isChange;
              this.controller.close()
            }).fontColor(this.isChange ? '#2871d4' : '#2871d4')
        }
        .margin({ left: 12, right: 12, top: 18 })
        .height(56)
      }
    }
    .height(216)
    .backgroundColor($r("sys.color.ohos_id_color_list_card_bg"))
    .padding({ left: 12, right: 12 })
  }
}
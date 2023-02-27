/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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
import { setCache, getCache } from '../../utils/KvManager'
import simServiceProxy from '../../../model/simServiceProxy'
import LogUtils from '../../../common/utils/LogUtils'

const TAG = "DefaultDialCard:"

@CustomDialog
export default struct DefaultDialCard {
  controller: CustomDialogController;
  action: (cardname) => void;
  @State changeDefault: boolean = true;
  @State changeCard1: boolean = false;
  @State changeCard2: boolean = false;
  @State phoneNumber1: string = '';
  @State phoneNumber2: string = '';
  @State defaultSetCard: any = '';
  SIM_CARD_DEFAULT = 'sim_card_management_card_default_call';
  SIM_CARD_KEYWORD = 'sim_card_keyword';

  /**
   * Get the phone number of sim card
   */
  getPhoneNumber(slotId) {
    simServiceProxy.getSimTelephoneNumber(slotId).then((res: string) => {
      if (!slotId) {
        this.phoneNumber1 = res;
      } else {
        this.phoneNumber2 = res;
      }
    }).catch((err) => {
    })
  }

  /**
   * Get the customized mobile phone number set by the user
   */
  getShowNumber(slotId) {
    simServiceProxy.getShowNumber(slotId).then((res: string) => {
      if (res !== 'null') {
        if (!slotId) {
          this.phoneNumber1 = res;
        } else {
          this.phoneNumber2 = res;
        }
      } else {
        this.getPhoneNumber(slotId)
      }
    }).catch((err) => {
    })
  }

  /**
   * Get default voice
   */
  getDefaultVoiceSlotId() {
    simServiceProxy.getDefaultVoiceSlotId().then((res: string) => {
      if (res == '0') {
        this.changeCard1 = true;
        this.changeCard2 = false;
        this.changeDefault = false;
      } else if (res == '1') {
        this.changeCard1 = false;
        this.changeCard2 = true;
        this.changeDefault = false;
      } else {
        this.changeCard1 = false;
        this.changeCard2 = false;
        this.changeDefault = true;
      }
    }).catch((err) => {
    })
  }

  /**
   * Set default voice
   */
  setDefaultVoiceSlotId(slotId) {
    simServiceProxy.setDefaultVoiceSlotId(slotId).catch((err) => {
    })
  }

  aboutToAppear() {
    LogUtils.i(TAG, "aboutToAppear:")
    this.getShowNumber(0);
    this.getShowNumber(1);
    this.getDefaultVoiceSlotId()
  }

  build() {
    Column() {
      Flex({ direction: FlexDirection.Column }) {
        Text($r('app.string.default_dial_card'))
          .fontSize('20vp')
          .fontColor('rgba(0, 0, 0, 0.9)')
          .textAlign(TextAlign.Start)
          .lineHeight(56)
          .fontWeight(FontWeight.Medium)
          .fontFamily("HarmonyHeiTi")
          .align(Alignment.Start)
        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
          Text($r('app.string.not_set')).fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontFamily("HarmonyHeiTi")
            .align(Alignment.Center | Alignment.Start)
            .lineHeight(21)
          Image(this.changeDefault ? $r('app.media.ic_Radiobtn_on') : $r('app.media.ic_Radiobtn_off')).height(24).width(24)
        }.height(48)
        .onClick(() => {
          this.action($r('app.string.not_set'));
          this.setDefaultVoiceSlotId(-1)
          this.changeCard1 = false;
          this.changeCard2 = false;
          this.changeDefault = true;
          this.controller.close();
        })

        Divider().vertical(false).strokeWidth(0.5).color('#ccc')
        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
          Column() {
            Text($r('app.string.card_1'))
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontFamily("HarmonyHeiTi")
              .align(Alignment.Start)
              .lineHeight(22)
            Text(this.phoneNumber1)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontFamily("HarmonyHeiTi")
              .align(Alignment.Start)
              .lineHeight(19)
              .fontColor('#555')
          }.alignItems(HorizontalAlign.Start)

          Column() {
            Image(this.changeCard1 ? $r('app.media.ic_Radiobtn_on') : $r('app.media.ic_Radiobtn_off')).height(24).width(24)
          }
        }.height(64)
        .onClick(() => {
          this.action($r('app.string.sim_card_one_no_space'));
          this.changeCard1 = true;
          this.setDefaultVoiceSlotId(0)
          this.changeCard2 = false;
          this.changeDefault = false;
          this.controller.close();
        })

        Divider().vertical(false).strokeWidth(0.5).color('#ccc')
        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
          Column() {
            Text($r('app.string.card_2'))
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontFamily("HarmonyHeiTi")
              .align(Alignment.Start)
              .lineHeight(22)
            Text(this.phoneNumber2)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontFamily("HarmonyHeiTi")
              .align(Alignment.Start)
              .lineHeight(19)
              .fontColor('#555')
          }.alignItems(HorizontalAlign.Start)

          Column() {
            Image(this.changeCard2 ? $r('app.media.ic_Radiobtn_on') : $r('app.media.ic_Radiobtn_off')).height(24).width(24)
          }
        }.height(64)
        .onClick(() => {
          setCache(this.SIM_CARD_DEFAULT, '+8618851354122');
          this.action($r('app.string.sim_card_two_no_space'));
          this.changeCard1 = false;
          setCache(this.SIM_CARD_KEYWORD, 2)
          this.setDefaultVoiceSlotId(1)
          this.changeCard2 = true;
          this.changeDefault = false;
          this.controller.close();
        })

        Divider().vertical(false).strokeWidth(0.5).color('#ccc')
        Flex({ justifyContent: FlexAlign.SpaceAround, alignItems: ItemAlign.Center }) {
          Text($r('app.string.cancel'))
            .fontSize('16vp')
            .fontWeight(FontWeight.Medium)
            .fontFamily("HarmonyHeiTi")
            .fontColor('#2871d4')
        }
        .onClick(() => {
          this.controller.close();
        })
        .height(56)
      }
    }
    .height(297)
    .padding({ left: 24, right: 24 })
  }
}
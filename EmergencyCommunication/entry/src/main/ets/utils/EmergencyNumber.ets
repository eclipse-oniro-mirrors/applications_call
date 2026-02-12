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

/**
 * Log Util
 *
 * standard :
 * 1. define TAG, recommend class name。
 * 2. switch IS_DEBUG_ON as true, when debugging.
 * 3. msg should be short and valuable.
 * 4. choose appropriate function.
 * 5. the function execute many times can not print.
 * 6. uniqueness.
 *
 * @since 2023-07-1
 */
import LogUtils from './HiLog';
import { EmergencyNumListStruct, EccsStruct, EccsCountryStruct } from '../utils/ClassStruct';
import radio from '@ohos.telephony.radio';
import EmergencyCallController from '../control/EmergencyCallControl';
import dataSim from '@ohos.telephony.data';
import sim from '@ohos.telephony.sim';
import commonData from '../data/CommonData';
import { BusinessError } from '@ohos.base';

const TAG = 'EmergencyNumber';

export default class EmergencyNumber {
  private static sInstance: EmergencyNumber;
  public static readonly TRAFFIC_ACCIDENT_ALARM_NUMBER_CN = '122';
  public static readonly TRAFFIC_ACCIDENT_ALARM_NUMBER_CN_TYPE = 'TRAFFIC';
  public static readonly ISO_GEO_CODE_CN = 'CN';
  public mEmergencyCallController: EmergencyCallController = EmergencyCallController.getInstance();
  public isoCode: string = '';

  static getInstance() {
    if (EmergencyNumber.sInstance == null) {
      EmergencyNumber.sInstance = new EmergencyNumber();
    }
    return EmergencyNumber.sInstance;
  }

  getISOCodeByCard(slotId: number, callback?: Function) {
    radio.getISOCountryCodeForNetwork(slotId).then(data => {
      this.isoCode = data.toUpperCase();

      this.getCountriesByISOCode((eccs: Array<EccsStruct>) => {
        const formatList: EmergencyNumListStruct[] = eccs.map((item: EccsStruct, index) => {
          let listItem: EmergencyNumListStruct =
            this.retrunEmerNumListItem(item.phone_number, item.types, index, slotId);
          return listItem;
        })
        callback && callback(formatList, this.isoCode);
      })
    }).catch((err: Object[]) => {
      LogUtils.e(TAG, 'radio.getISOCountryCodeForNetwork failed' + JSON.stringify(err));
    });
  }

  retrunEmerNumListItem(num: string, types: string, idx: number, slotId: number) {
    let listItem: EmergencyNumListStruct = {
      value: num,
      label: this.getEmergencyNumLabel(types),
      id: `default${idx}_${slotId}`,
      type: 0,
      slotId: slotId,
      labelStr: types
    }
    return listItem;
  }

  getCountriesByISOCode(callback: Function) {
    const target: EccsCountryStruct | undefined =
      this.mEmergencyCallController.eccEmerNumList.find((item: EccsCountryStruct) => item.iso_code == this.isoCode);
    callback(target ? target.eccs : []);
  }

  getEmergencyNumLabel(type: string): Resource {
    switch (type) {
      case 'POLICE':
        return $r('app.string.POLICE');
      case 'AMBULANCE':
        return $r('app.string.AMBULANCE');
      case 'FIRE':
        return $r('app.string.FIRE');
      case 'POLICE&AMBULANCE&FIRE':
        return $r('app.string.POLICE_AMBULANCE_FIRE');
      case 'AMBULANCE&FIRE':
        return $r('app.string.AMBULANCE_FIRE');
      case 'POLICE&AMBULANCE':
        return $r('app.string.POLICE_AMBULANCE');
      case 'POLICE&FIRE':
        return $r('app.string.POLICE_FIRE');
      case 'TRAFFIC':
        return $r('app.string.emergency_number_traffic')
      default:
        return $r('app.string.UNKNOWN');
    }
  }


  setAppStorageEmergencyNum(list: EmergencyNumListStruct[]) {
    AppStorage.SetOrCreate<Array<EmergencyNumListStruct>>('localEmergencyNumber', list);
  }

  ctGetDefaultCellularDataSlotId(cardOneList: EmergencyNumListStruct[], cardTwoList: EmergencyNumListStruct[],
    slotId: number, error?: BusinessError) {
    if (error) {
      LogUtils.e(TAG, 'initEmergencyNumData get default data slot error' +
        ', and set card one emergency num list.');
      this.setAppStorageEmergencyNum(cardOneList);
    } else {
      LogUtils.i(TAG, 'default data slot: ' + slotId);
      if (slotId === commonData.int.SIM_SLOT_ID_FIRST) {
        this.setAppStorageEmergencyNum(cardOneList);
      } else {
        this.setAppStorageEmergencyNum(cardTwoList);
      }
    }
  }

  onGetDefaultVoiceSlotId(cardOneList: EmergencyNumListStruct[], cardTwoList: EmergencyNumListStruct[],
    error: BusinessError, value: number) {
    if (error && error.code === commonData.int.SIM_SLOT_ID_EMPTY) {
      LogUtils.i(TAG, 'error, default voice slot is not set.');
      dataSim.getDefaultCellularDataSlotId((error, slotId) => {
        this.ctGetDefaultCellularDataSlotId(cardOneList, cardTwoList, slotId, error)
      });
    } else if (value === commonData.int.SIM_SLOT_ID_FIRST) {
      this.setAppStorageEmergencyNum(cardOneList);
    } else {
      this.setAppStorageEmergencyNum(cardTwoList);
    }
  }

  isoCodeSameisoCode2(cardOneList: EmergencyNumListStruct[], cardTwoList: EmergencyNumListStruct[],
    isoCode: string, isoCode2: string) {
    if (isoCode == isoCode2) {
      sim.getDefaultVoiceSlotId((error, value) => {
        this.onGetDefaultVoiceSlotId(cardOneList, cardTwoList, error, value)
      });
    } else {
      LogUtils.i(TAG, 'isoCode is different');
      let noRepeatList = this.handleRepeatList(cardOneList, cardTwoList)
      this.setAppStorageEmergencyNum(noRepeatList);
    }
  }

  initEmergencyNumData() {
    let cardOne: string | undefined = AppStorage.get('simOperatorNameFirst');
    let cardTwo: string | undefined = AppStorage.get('simOperatorNameSecond');
    LogUtils.i(TAG, ` cardOne：${cardOne},cardTwo：${cardTwo}`);
    if (cardOne && cardTwo) {
      this.getISOCodeByCard(0, (cardOneList: Array<EmergencyNumListStruct>, isoCode: string) => {
        this.getISOCodeByCard(1, (cardTwoList: Array<EmergencyNumListStruct>, isoCode2: string) => {
          // Check whether the isoCode is the same.
          LogUtils.i(TAG, `card1 isoCode :${isoCode}',card2 isoCode :${isoCode2}`);
          this.isoCodeSameisoCode2(cardOneList, cardTwoList,
            isoCode, isoCode2)
        })
      })
    } else if (cardOne && !cardTwo) {
      this.getISOCodeByCard(0, (cardOneList: Array<EmergencyNumListStruct>) => {
        LogUtils.i(TAG, 'have card1:' + cardOneList.length);
        this.setAppStorageEmergencyNum(cardOneList);
      })
    } else if (!cardOne && cardTwo) {
      this.getISOCodeByCard(1, (cardTwoList: Array<EmergencyNumListStruct>) => {
        LogUtils.i(TAG, 'have card2:' + cardTwoList.length);
        this.setAppStorageEmergencyNum(cardTwoList);
      })
    }
  }

  handleRepeatList(cardOnelist: Array<EmergencyNumListStruct>, cardTwolist: Array<EmergencyNumListStruct>) {
    let noRepeatList: EmergencyNumListStruct[] = [];
    cardTwolist.forEach(item => {
      cardOnelist.push(item);
    })
    for (let i = 0; i < cardOnelist.length; i++) {
      let flag: boolean = true;
      for (let j = 0; j < noRepeatList.length; j++) {
        if (cardOnelist[i].value == noRepeatList[j].value && cardOnelist[i].labelStr == noRepeatList[j].labelStr) {
          flag = false;
        }
      }
      if (flag) {
        noRepeatList.push(cardOnelist[i]);
      }
    }
    noRepeatList.forEach((item, index) => {
      item.id = `defalut${index}`;
    })
    LogUtils.i(TAG, 'have no RepeatList');
    return noRepeatList;
  }
}
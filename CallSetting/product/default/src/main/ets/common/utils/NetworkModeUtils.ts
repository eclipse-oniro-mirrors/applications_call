/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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
import radio from '@ohos.telephony.radio';

export function getRadioTechnologyFromStr(str: string): number {
  switch (str) {
    case 'GSM':
      return radio.RadioTechnology.RADIO_TECHNOLOGY_GSM;
    case '1XRTT':
      return radio.RadioTechnology.RADIO_TECHNOLOGY_1XRTT;
    case 'WCDMA':
      return radio.RadioTechnology.RADIO_TECHNOLOGY_WCDMA;
    case 'HSPA':
      return radio.RadioTechnology.RADIO_TECHNOLOGY_HSPA;
    case 'HSPAP':
      return radio.RadioTechnology.RADIO_TECHNOLOGY_HSPAP;
    case 'TD_SCDMA':
      return radio.RadioTechnology.RADIO_TECHNOLOGY_TD_SCDMA;
    case 'EVDO':
      return radio.RadioTechnology.RADIO_TECHNOLOGY_EVDO;
    case 'EHRPD':
      return radio.RadioTechnology.RADIO_TECHNOLOGY_EHRPD;
    case 'LTE':
      return radio.RadioTechnology.RADIO_TECHNOLOGY_LTE;
    case 'LTE_CA':
      return radio.RadioTechnology.RADIO_TECHNOLOGY_LTE_CA;
    case 'IWLAN':
      return radio.RadioTechnology.RADIO_TECHNOLOGY_IWLAN;
    case 'NR':
      return radio.RadioTechnology.RADIO_TECHNOLOGY_NR;
    case 'UNKNOWN':
    default:
      return radio.RadioTechnology.RADIO_TECHNOLOGY_UNKNOWN;
  }
}

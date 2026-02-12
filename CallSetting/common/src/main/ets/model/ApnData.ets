/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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

import { OptionClass } from './ApnTypes';

export enum ApnType {
  DEFAULT, IMS, MMS, ALL
}

export enum ApnAuthType {
  None = 0, PAP, CHAP, PAP_OR_CHAP
}

export const authenticationTypeOption: OptionClass[] = [{
  title: $r('app.string.Apn_enum_None'),
  value: ApnAuthType.None
}, {
  title: $r('app.string.Apn_enum_PAP'),
  value: ApnAuthType.PAP
}, {
  title: $r('app.string.Apn_enum_CHAP'),
  value: ApnAuthType.CHAP
}, {
  title: $r('app.string.Apn_enum_PAP_CHAP'),
  value: ApnAuthType.PAP_OR_CHAP
}]

export enum PdpProtocol {
  IPV4 = 0, IPV6, IPV4V6
}

export const apnProtocolOption: OptionClass[] = [{
  title: $r('app.string.Apn_enum_PAP_IPv4'),
  value: PdpProtocol.IPV4
}, {
  title: $r('app.string.Apn_enum_PAP_IPv6'),
  value: PdpProtocol.IPV6
}, {
  title: $r('app.string.Apn_enum_IPv4_IPv6'),
  value: PdpProtocol.IPV4V6
}]

export const apnRoamingAgreementOption: OptionClass[] = [{
  title: $r('app.string.Apn_enum_PAP_IPv4'),
  value: PdpProtocol.IPV4
}, {
  title: $r('app.string.Apn_enum_PAP_IPv6'),
  value: PdpProtocol.IPV6
}, {
  title: $r('app.string.Apn_enum_IPv4_IPv6'),
  value: PdpProtocol.IPV4V6
}]

export enum BearingSystemType {
  UNKNOWN = 0,
  LTE,
  HSPAP,
  HSPA,
  HSUPA,
  HSDPA,
  UMTS,
  EDGE,
  GPRS,
  eHRPD,
  EVDO_B,
  EVDO_A,
  EVDO_0,
  xRTT,
  IS95B,
  IS95AS
}

export const bearerSystemOption: OptionClass[] = [{
  title: $r('app.string.Apn_enum_Not_specified'),
  value: BearingSystemType.UNKNOWN
}, {
  title: $r('app.string.Apn_enum_LTE'),
  value: BearingSystemType.LTE
}, {
  title: $r('app.string.Apn_enum_HSPAP'),
  value: BearingSystemType.HSPAP
}, {
  title: $r('app.string.Apn_enum_HSPA'),
  value: BearingSystemType.HSPA
}, {
  title: $r('app.string.Apn_enum_HSUPA'),
  value: BearingSystemType.HSUPA
}, {
  title: $r('app.string.Apn_enum_HSDPA'),
  value: BearingSystemType.HSDPA
}, {
  title: $r('app.string.Apn_enum_UMTS'),
  value: BearingSystemType.UMTS
}, {
  title: $r('app.string.Apn_enum_EDGE'),
  value: BearingSystemType.EDGE
}, {
  title: $r('app.string.Apn_enum_GPRS'),
  value: BearingSystemType.GPRS
}, {
  title: $r('app.string.Apn_enum_eHRPD'),
  value: BearingSystemType.eHRPD
}, {
  title: $r('app.string.Apn_enum_EVDO_B'),
  value: BearingSystemType.EVDO_B
}, {
  title: $r('app.string.Apn_enum_EVDO_A'),
  value: BearingSystemType.EVDO_A
}, {
  title: $r('app.string.Apn_enum_EVDO_0'),
  value: BearingSystemType.EVDO_0
}, {
  title: $r('app.string.Apn_enum_1xRTT'),
  value: BearingSystemType.xRTT
}, {
  title: $r('app.string.Apn_enum_IS95B'),
  value: BearingSystemType.IS95B
}, {
  title: $r('app.string.Apn_enum_IS95A'),
  value: BearingSystemType.IS95AS
}]

export const mvnoTypeOption: OptionClass[] = [{
  title: $r('app.string.Apn_enum_None'),
  value: '0'
}, {
  title: $r('app.string.Apn_enum_SPN'),
  value: '1'
}, {
  title: $r('app.string.Apn_enum_IMSI'),
  value: '2'
}, {
  title: $r('app.string.Apn_enum_GID'),
  value: '3'
}]

export enum DataShareEnum {
  profile_id = 0,
  profile_name,
  mcc,
  mnc,
  mccmnc,
  apn,
  auth_type,
  auth_user,
  auth_pwd,
  apn_types,
  is_roaming_apn,
  apn_protocol,
  apn_roam_protocol,
  home_url,
  mms_ip_address,
  proxy_ip_address,
  bearing_system_type,
  mvno_type,
  mvno_match_data,
  edited,
  server,
  opkey
}
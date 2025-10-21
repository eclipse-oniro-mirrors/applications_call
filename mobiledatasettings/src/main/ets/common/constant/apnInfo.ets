/**
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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

export class ApnInfo {
  profile_id: number = 0
  profile_name: string = ''
  mcc: string = ''
  mnc: string = ''
  mccmnc: string = ''
  apn: string = ''
  auth_type: number = 0
  auth_user: string = ''
  auth_pwd: string = ''
  apn_types: string = 'default'
  is_roaming_apn: number = 1
  apn_protocol: string = ''
  apn_roam_protocol: string = ''
  home_url: string = ''
  mms_ip_address: string = ''
  proxy_ip_address: string = ''
  bearing_system_type: number = 0
  mvno_type: string = ''
  mvno_match_data: string = ''
  edited: number = 0
  server: string = ''
}
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
import { Context } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import LogUtils from '../utils/HiLog';

const TAG: string = 'EmergencyData';

interface EmergencyInfo {
  name?: preferences.ValueType,
  address?: preferences.ValueType,
  allergicReaction?: preferences.ValueType,
  bloodType?: preferences.ValueType,
  drug?: preferences.ValueType,
  drugStatusAndNotice?: preferences.ValueType
}

interface EmergencyContact {
  name: string,
  phoneNumber: string
}

interface EmergencyContactFromPre {
  value: string,
  label: string,
  id: string,
  nameRawContactId: number,
  type: number,
  index: number
}

class EmergencyData {
  private EMERGENCY_CONTACTS_PREFERENCES_NAME: string = 'emergency_contacts_preference_name';
  private EMERGENCY_CONTACTS_KEY = 'emergency_contacts_key';
  private EMERGENCY_INFO_PREFERENCES_NAME = 'emergency_info_preference_name';
  private DEFAULT_STRING: string = '';

  /**
   * 获取个人紧急信息
   * @param context
   * @returns {string}
   */
  public getEmergencyInfo(context: Context): string {
    try {
      preferences.removePreferencesFromCacheSync(context, this.EMERGENCY_INFO_PREFERENCES_NAME);
      const emergencyInfoOptions: preferences.Options = { name: this.EMERGENCY_INFO_PREFERENCES_NAME };
      const emergencyInfoPreferences = preferences.getPreferencesSync(context, emergencyInfoOptions);
      const emergencyInfo: EmergencyInfo = {
        name: emergencyInfoPreferences.getSync('name', this.DEFAULT_STRING),
        address: emergencyInfoPreferences.getSync('address', this.DEFAULT_STRING),
        allergicReaction: emergencyInfoPreferences.getSync('allergicReaction', this.DEFAULT_STRING),
        bloodType: emergencyInfoPreferences.getSync('bloodType', this.DEFAULT_STRING),
        drug: emergencyInfoPreferences.getSync('drug', this.DEFAULT_STRING),
        drugStatusAndNotice: emergencyInfoPreferences.getSync('drugStatusAndNotice', this.DEFAULT_STRING)
      };
      return JSON.stringify(emergencyInfo);
    } catch (err) {
      const error = err as BusinessError;
      LogUtils.e(TAG, `getEmergencyInfo fail, error code: ${error.code}, message: ${error.message}`);
      return this.DEFAULT_STRING;
    }
  }

  /**
   * 获取紧急联系人
   * @param context
   * @returns {string}
   */
  public getEmergencyContacts(context: Context): string {
    try {
      preferences.removePreferencesFromCacheSync(context, this.EMERGENCY_CONTACTS_PREFERENCES_NAME);
      const emergencyContactsOptions: preferences.Options = { name: this.EMERGENCY_CONTACTS_PREFERENCES_NAME };
      const emergencyContactsPreferences = preferences.getPreferencesSync(context, emergencyContactsOptions);
      const emergencyContacts = emergencyContactsPreferences.getSync(this.EMERGENCY_CONTACTS_KEY, this.DEFAULT_STRING);
      const newEmergencyContacts: EmergencyContactFromPre[] = JSON.parse(emergencyContacts as string);
      const emergencyContactsArray: EmergencyContact[] = newEmergencyContacts.map((item): EmergencyContact => {
        return {
          name: item.label,
          phoneNumber: item.value
        }
      });
      return JSON.stringify(emergencyContactsArray);
    } catch (err) {
      const error = err as BusinessError;
      LogUtils.e(TAG, `getEmergencyInfo fail, error code: ${error.code}, message: ${error.message}`);
      return this.DEFAULT_STRING;
    }
  }
}

export const emergencyData: EmergencyData = new EmergencyData();
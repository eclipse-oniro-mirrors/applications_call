/*
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
import { call } from '@kit.TelephonyKit';

export class EmergencyInfoStruct {
  public name?: string = '';
  public address?: string = '';
  public bloodType?: string = '';
  public allergicReaction?: string = '';
  public drug?: string = '';
  public isOrganDonor?: string = '';
  public drugStatusAndNotice?: string = '';
}

export class ContactListStruct {
  public index?: number = 0;
  /** phone number */
  public value: string = '';
  public label: ResourceStr = $r('app.string.emptyStr');
  public id: string = '';
  public nameRawContactId?: number;
  public type: number = 0;
  public photo?: Resource | PixelMap = $r('app.string.emptyStr');
  public callState?: call.DetailedCallState | null;
  public callId?: number | null;
  public callType?: 'sosCall' | 'carAccident' | 'fallDown' | 'commonCall' | 'commonCallFromSosCall';

  static getDeepCopy(emergencyContact: ContactListStruct): ContactListStruct {
    return {
      index: emergencyContact.index,
      value: emergencyContact.value,
      label: emergencyContact.label,
      id: emergencyContact.id,
      nameRawContactId: emergencyContact.nameRawContactId,
      type: emergencyContact.type,
      photo: emergencyContact.photo,
      callState: emergencyContact.callState,
      callId: emergencyContact.callId,
      callType: emergencyContact.callType
    } as ContactListStruct;
  }
}

export class RadioListItemStruct {
  public value: string = '';
  public label: ResourceStr = $r('app.string.emptyStr');
}

export class DialogDataStruct {
  public title: Resource = $r('app.string.emptyStr');
  public textValue: string = '';
  public placeholder: Resource = $r('app.string.emptyStr');
  public confirm: (value?: string) => void = (value: string = '') => {};
  public radioList?: SheetInfo[] = [];
  public contentText?: Resource = $r('app.string.emptyStr');
}

export class LocationDialogDataStruct {
  public title: Resource = $r('app.string.emptyStr');
  public contentText: Resource = $r('app.string.emptyStr');
  public confirm: () => void = () => {};
}

export class EmergencyContactDialogDataStruct {
  public title: Resource = $r('app.string.emptyStr');
  public contentText: Resource = $r('app.string.emptyStr');
  public confirm: () => void = () => {};
  public isWaring: boolean = false;
  public confirmText: Resource = $r('app.string.emptyStr');
}

export class LocationInfoStruct {
  public isSuccess: boolean = false;
  public data: string | undefined = '';
  public hasPermission?: boolean = true;
}

export class ContactDataStruct {
  public telephone: string = '';
  public contactName: string = '';
  public nameRawContactId?: number;
}

export class EmergencyNumListStruct {
  public value: string = '';
  public label: ResourceStr = $r('app.string.emptyStr');
  public id: string = '';
  public type: number = 0;
  public slotId: number = 0;
  public labelStr: string = '';
  public photo?: Resource | PixelMap = $r('app.string.emptyStr');
}

export interface EccsStruct {
  // This needs to keep align with 'eccdata.json' key define.
  phone_number: string,
  types: string
}

export interface EccsCountryStruct {
  // This needs to keep align with 'eccdata.json' key define.
  iso_code: string,
  eccs: EccsStruct[]
}

export class RequestParameterStruct {
  public deviceId: string = ''
  public deviceType: number = 0
}

export class PrivacyInfoStruct {
  public mFeature: number;
  public mIsAgree: boolean;
  public mVersion: string;

  constructor(feature: number, isAgree: boolean, version: string) {
    this.mFeature = feature;
    this.mIsAgree = isAgree;
    this.mVersion = version;
  }
}

export interface ConfigStruct {
  name: string
  value: string
}
export class TimeOutStruct {
  public itemId: string = '';
  public timerId: number = 0;
}

export enum RetryType {
  ReportPrivacy = 'ReportPrivacy',
  ReportLocation = 'ReportLocation',
  DailySystemTimer = 'DailySystemTimer',
}

export class RetryInfo {
  public retryType: RetryType | undefined = undefined;
  public isRetry: boolean = false;
  public retryToken?: number
  public retryMaxTimes?: number;
  public retryInterval?: number;
  public retryTimesKey?: string;
  public retrySystemTimerKey?: string;
}

/**
 * retry error code, retry continue or retry end
 */
export enum RetryErrorCode {
  CONTINUE,
  END
}

export interface PrivacyStatement {
  isAgree: boolean
  agreeTime: number
  privacyVersion: string
  appVersion: string
  accountId?: string
}

export interface DeviceLocation {
  geocode: string;
  countryCode: string;
  longitude: number;
  latitude: number;
  deviceModel: string;
  romVersion: string;
}

export type PersonalSafetyAccidentType = 'carAccident' | 'fallDown' | 'none';
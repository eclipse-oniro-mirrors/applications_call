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
import { CallSettingConstant } from '../constant/CallSettingConstant';

export class DialogDataStruct {
  public objectUse: string = ' ';
  public confirm: (value?: string) => void = (value: string = '') => {};
}

export class NumberListItemStruct {
  public value?: string = '';
  public label?: ResourceStr = $r('app.string.emptyStr');
}

export class StaticDataUseStruct {
  public statusUse: boolean = false;
  public objectUse?: string = CallSettingConstant.RECORDING_WAY_ALL_NUMBER;
  public numberUse?: number = 0;
}

export class StaticNumberDataListStruct {
  public image?: Resource = $r('app.media.ic_user');
  public isChecked?: boolean = false;
  public number?: string = '';
  public name?: string = '';
}

export class ContactsDataStruct {
  public id?: number = -1;
  public displayName: string = '';
  public detailInfo: string = '';
  public blobData?: Uint8Array = undefined;
  public typeId?: number = -1;
  public contactId: number = -1;
  public portraitColor?: Resource = $r('sys.color.ohos_id_color_special1');
}

export class ContactDataStruct {
  public telephone: string = '';
  public contactName: string = '';
}

export class RecordConfigDataStruct {
  public isOpen?: number = CallSettingConstant.CLOSE_RECORDING_STATUS;
  public object?: string = CallSettingConstant.RECORDING_WAY_ALL_NUMBER;
}

export class RecordConfigContactDataNoStruct {
  public phoneNumber?: string = '';
  public name?: string = '';
  public image?: Resource = $r('app.media.ic_user');
  public isChecked?: boolean = false;
}

export class RecordRouterStruct {
  public number: number = 0;
  public title: string = '';
}

@Observed
export class RecordConfigContactDataStruct {
  public phoneNumber: string = '';
  public id?: number = -1;
  public name?: string = '';
  public image?: Resource | PixelMap | undefined = $r('app.media.ic_user');
  public isChecked?: boolean = false;
  public isImageDefault?: boolean = true;
  // 新增时间戳字段,用于在lazyforeach中触发dom刷新
  public timestamp: number = 0;
}
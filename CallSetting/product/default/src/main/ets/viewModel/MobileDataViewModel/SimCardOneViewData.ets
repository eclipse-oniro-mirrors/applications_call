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
import { BusinessError } from '@kit.BasicServicesKit';
import { isSimActive } from '../../common/model/getSimStateApi';
import { getSimCardDefaultPhoneNumber, getSimCardPhoneNumber } from '../../common/model/getSimTelephoneNumberApi';
import { LogUtils } from '@ohos/common/CommonIndex';
import { StringUtil } from '../../common/utils/StringUtil';
import { phoneFormat } from '../../common/utils/SimIdFormat';

const TAG = 'SimCardOneViewData';

@Observed
export class SimCardOneViewData {
   public simStateStatusCardOne: boolean = false;
   public telephoneNumberOne: string = '';

  getSimStateDataCardOne() {
    isSimActive(0).then((res) => {
      LogUtils.i(TAG, 'isSimActive id' + ' one ' + JSON.stringify(res));
      if (res) {
        AppStorage.setOrCreate('hasSimCard1', true);
        this.simStateStatusCardOne = true;
      } else {
        this.setDisableSimCard();
      }
    }).catch(() => {
      this.setDisableSimCard();
    });
  }

  /**
   * Get mobile phone number
   */
  getSimCardOnePhoneNumber() {
    getSimCardPhoneNumber(0).then((res: string) => {
      if (res === 'null') {
        getSimCardDefaultPhoneNumber(0).then((resDefault: string) => {
          LogUtils.i(TAG, 'getSimCardDefaultPhoneNumber card1 other success res');
          this.telephoneNumberOne = StringUtil.formatPhoneNumberInMultiLanguage(phoneFormat(resDefault));
        }).catch((err: BusinessError) => {
          LogUtils.i(TAG, 'getSimCardDefaultPhoneNumber card1 other catch' + JSON.stringify(err));
        })
      } else {
        LogUtils.i(TAG, 'getSimCardPhoneNumber card1 other success res');
        this.telephoneNumberOne = StringUtil.formatPhoneNumberInMultiLanguage(phoneFormat(res));
      }
    }).catch((err: BusinessError) => {
      LogUtils.i(TAG, 'getSimCardPhoneNumber card1 other catch' + JSON.stringify(err));
    });
  }

  setDisableSimCard() {
    AppStorage.setOrCreate('hasSimCard1', false);
    this.simStateStatusCardOne = false;
    this.telephoneNumberOne = '';
  }
}
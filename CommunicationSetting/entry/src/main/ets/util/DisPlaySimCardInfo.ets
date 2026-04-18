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
import StringUtil from './StringUtil';
import myCommon from '@ohos.app.ability.common';
import { cardInfo } from './SimCradNameListener';
import { LogUtil } from './LogUtil';

const TAG = 'DisPlaySimCardInfo';

export class DisPlaySimCardInfo {
  getNetWorkDisplayName(context: myCommon.UIAbilityContext, slotId: number,
    operatorName?: string, showName?: string): ResourceStr {
    LogUtil.info(TAG, `getNetWorkDisplayName: slotId=${slotId}, operatorName=${operatorName}, showName=${showName}`);
    const serviceStatus = this.getName(context, operatorName, showName);
    const isSimCard = cardInfo[slotId]?.isSimCard;
    LogUtil.info(TAG, `isSimCard=${isSimCard}, cardName=${cardInfo[slotId].cardName}`);
    if (isSimCard) {
      return $r(cardInfo[slotId].cardName, serviceStatus);
    } else {
      LogUtil.info(TAG, `Returning eSIM name: ${cardInfo[slotId].cardName}`);
      return $r(cardInfo[slotId].cardName, `eSIM ${cardInfo[slotId].slotIndex}`, serviceStatus, context);
    }
  }

  private getName(context: myCommon.UIAbilityContext, operatorName?: string, showName?: string): string {
    if (showName !== undefined && !StringUtil.isEmpty(showName)) {
      LogUtil.info(TAG, `showName is not empty, using showName: ${showName}`);
      return showName;
    }
    return operatorName ? operatorName :
      StringUtil.convertResourceToString($r('app.string.network_no_service'), context);
  }
}
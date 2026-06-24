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
import { LogUtil } from './LogUtil';
import myCommon from '@ohos.app.ability.common';
import { intl } from '@kit.LocalizationKit';
import I18n from '@ohos.i18n';
import StringUtil from '../../../util/StringUtil';
import { getFlowText } from '../../../constants/CommonConstants';
import { GlobalContext } from '../../../entryability/CommunicationSettingAbility';

const TAG: string = 'AccessibilityTextHandler';

export class AccessibilityData {
  public visibleIndex: number = 0;
  public chartStr: string[] = [];
  public chartDate: number[] = [];
  public dataValues: number[][] = [];
  public isHourDuration: boolean = false;
}

export class AccessibilityTextHandler {
  public static updateAccessibilityText(param: AccessibilityData) {
    let length = param.chartStr.length;
    let visibleIndex = param.visibleIndex;
    let startIndex = 0;
    if (visibleIndex !== 0 && param.chartDate.length - visibleIndex < length) {
      startIndex = length - (param.chartDate.length - visibleIndex);
      param.chartStr[0] = '';
    }
    for (let index = startIndex; index < length; index++) {
      if (param.isHourDuration) {
        param.chartStr[index] = AccessibilityTextHandler.getHourDurationAccessibilityText(visibleIndex, param)
      } else {
        param.chartStr[index] = AccessibilityTextHandler.getDayDurationAccessibilityText(visibleIndex, param)
      }
      visibleIndex++
    }
  }

  static isSameDay(date1: Date, date2: Date): boolean {
    return date1.getFullYear() === date2.getFullYear() &&
      date1.getMonth() === date2.getMonth() &&
      date1.getDate() === date2.getDate();
  }

  static getHourDurationAccessibilityText(visibleIndex: number, param: AccessibilityData): string {
    if (visibleIndex < 0) {
      return '';
    }
    let index = visibleIndex;
    let popText = AccessibilityTextHandler.getPopText(index, param.dataValues);
    let date = new Date(param.chartDate[index]);
    LogUtil.log(`${TAG}, getHourDurationAccessibilityText date: ${date}`)
    let valueStr = '';
    let options: intl.DateTimeOptions = {};
    if (visibleIndex === 0) {
      options = {
        hourCycle: 'h12',
        year: 'long',
        month: 'long',
        day: 'long',
        hour: '2-digit',
        minute: '2-digit'
      }
    } else {
      options = {
        hourCycle: 'h12',
        hour: '2-digit',
        minute: '2-digit'
      }
    }
    try {
      let locale = new Intl.Locale(I18n.System.getSystemLanguage());
      let dateFormat = new intl.DateTimeFormat(locale.toString(), options);
      let formatString = dateFormat.format(date);
      valueStr = StringUtil.convertResourceToStringWithArgs($r('app.string.traffic_chart_view_net_used_day'),
        GlobalContext.getContext().getObject('rankPageContext') as myCommon.UIAbilityContext, formatString, popText);
    } catch (err) {
      LogUtil.error(`${TAG}, format hour date string, code: ${err.code}, message: ${err.message}`)
    }
    return valueStr;
  }

  static getDayDurationAccessibilityText(visibleIndex: number, param: AccessibilityData): string {
    if (visibleIndex < 0 || visibleIndex >= param.dataValues.length) {
      return '';
    }
    let index = visibleIndex;
    let popText = AccessibilityTextHandler.getPopText(index, param.dataValues);
    let currentDate = new Date();
    let date = new Date(param.chartDate[index]);
    LogUtil.log(`${TAG}, getDayDurationAccessibilityText date: ${date}`)
    let valueStr = '';
    if (AccessibilityTextHandler.isSameDay(currentDate, date)) {
      valueStr = StringUtil.convertResourceToStringWithArgs($r('app.string.traffic_chart_view_net_used_day_today'),
        GlobalContext.getContext().getObject('rankPageContext') as myCommon.UIAbilityContext, popText);
    } else {
      let year = currentDate.getFullYear();
      let options: intl.DateTimeOptions = {};
      if (date.getFullYear() < year) { // 去年
        options = {
          year: 'long',
          month: 'long',
          day: 'long'
        }
      } else { // 本月
        options = {
          month: 'long',
          day: 'long'
        }
      }
      try {
        let locale = new Intl.Locale(I18n.System.getSystemLanguage());
        let dateFormat = new intl.DateTimeFormat(locale.toString(), options);
        let formatString = dateFormat.format(date);
        valueStr = StringUtil.convertResourceToStringWithArgs($r('app.string.traffic_chart_view_net_used_day'),
          GlobalContext.getContext().getObject('rankPageContext') as myCommon.UIAbilityContext, formatString, popText);
      } catch (err) {
        LogUtil.error(`${TAG}, format hour date string, code: ${err.code}, message: ${err.message}`)
      }
    }
    return valueStr;
  }


  static getPopText(visibleIndex: number, dataValues: number[][]): string {
    if (visibleIndex < 0) {
      return '';
    }
    let indexY = Math.floor(visibleIndex);
    if (indexY >= dataValues.length) {
      return '';
    }
    try {
      let flow = dataValues[indexY][1];
      let text = getFlowText(flow);
      return text[0] + ' ' + text[1];
    } catch (e) {
      LogUtil.error(`${TAG}, popup get flow error`);
      return '';
    }
  }
}
/**
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
import myCommon from '@ohos.app.ability.common';
import { LogUtil } from './LogUtil';
import { i18n } from '@kit.LocalizationKit';

const TAG: string = 'StringUtil';
const allLatinTransliteration = i18n.Transliterator.getInstance('Any-Latin;Latin-ASCII');

class StringUtil {
  public isEmpty(str: string | undefined | null): boolean {
    return str === undefined || !str || !new RegExp('[^\\s]').test(str) || str.toString().trim() === '';
  }

  public convertResourceToString(simName: Resource | undefined, context: myCommon.UIAbilityContext): string {
    if (!context) {
      LogUtil.error(TAG, `convertResourceToString context is null`);
      return '';
    }
    if (!context.resourceManager) {
      LogUtil.error(TAG, `convertResourceToString resourceManager is null`);
      return '';
    }
    if (simName === undefined) {
      return '';
    }
    let simNameString = context.resourceManager.getStringSync(simName.id);
    return simNameString;
  }

  public convertResourceToStringWithArgs(simName: Resource | undefined, context: myCommon.UIAbilityContext,
    ...args: Array<string | number>): string {
    if (!context) {
      LogUtil.error(TAG, `convertResourceToString context is null`);
      return '';
    }
    if (!context.resourceManager) {
      LogUtil.error(TAG, `convertResourceToString resourceManager is null`);
      return '';
    }
    if (simName === undefined) {
      return '';
    }
    let simNameString = context.resourceManager.getStringSync(simName.id, ...args);
    return simNameString;
  }

  public formatString(text: string): string {
    return allLatinTransliteration.transform(text).replace(/\s/g, '').toLowerCase();
  }

  public isIncluded(text1: string, text2: string): boolean {
    const formattedText1 = this.formatString(text1);
    const formattedText2 = text2.toLowerCase();
    return formattedText1.includes(formattedText2) || text1.toLowerCase().includes(formattedText2);
  }

  public resource2String(res: Resource, context: Context): string {
    if (!res) {
      LogUtil.error(TAG, `resource2String res is null`);
      return '';
    }
    if (!context) {
      LogUtil.error(TAG, `resource2String context is null`);
      return '';
    }
    let resourceManager = context.resourceManager;
    if (!resourceManager) {
      LogUtil.error(TAG, `resource2String resourceManager is null`);
      return '';
    }
    return resourceManager.getStringSync(res.id);
  }
}

// Singleton
export default new StringUtil();
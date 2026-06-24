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

import { WATCH_TEXT_OVERFLOW } from '../constants/Constants';
import { LogUtil } from './LogUtil';

const TAG: string = 'ResourceUtils: ';

/**
 * 资源工具类
 *
 * @since 2025-01-24
 */
export class ResourcesUtils {
  /**
   * 获取指定资源编号的数值转化为文本跑马灯属性MARQUEE
   *
   * @param resource 资源编号 0  1
   * @returns 是否需要跑马灯效果 0 None 1 MARQUEE 默认为None
   */
  public static getTextOverflowSync(context: Context, resource?: Resource): TextOverflow {
    let resourceContent: TextOverflow = TextOverflow.None;
    if (!resource || !context) {
      LogUtil.warn(`${TAG} getTextOverflowSync resource invalid`);
      return resourceContent;
    }
    let resourceManager = context.resourceManager;
    if (!resourceManager) {
      return resourceContent;
    }
    try {
      LogUtil.info(`getTextOverflowSync ${resource.id}`);
      resourceContent = resourceManager.getNumber(resource.id);
      if (resourceContent === WATCH_TEXT_OVERFLOW) {
        resourceContent = TextOverflow.MARQUEE;
      } else {
        LogUtil.info(`getTextOverflowSync None`);
      }
    } catch (err) {
      LogUtil.error(`${TAG} getTextOverflowSync error, code:${err?.code},message:${err?.message}`);
    }
    return resourceContent;
  }
}
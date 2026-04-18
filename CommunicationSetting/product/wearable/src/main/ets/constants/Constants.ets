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

export const UNKNOWN_BUNDLE_TYPE: number = -1;

export const ORI_APP_INDEX: number = 0;

export function getFlowText(flow: number): string {
  let unit = ['B', 'KB', 'MB', 'GB', 'TB'];
  let index = 0;
  while (flow >= 1024 && index < 4) {
    flow = flow / 1024;
    index++;
  }
  return flow.toFixed(2) + unit[index];
}

/**
 * 副标题多语言跑马灯
 */
export const WATCH_TEXT_OVERFLOW: number = 1;

/**
 * 语言切换事件
 */
export const LANGUAGE_CHANGE_EVENT: string = 'LANGUAGE_CHANGE_EVENT';

/**
 * context-key
 */
export const PAGE_CONTEXT: string = 'PAGE_CONTEXT';

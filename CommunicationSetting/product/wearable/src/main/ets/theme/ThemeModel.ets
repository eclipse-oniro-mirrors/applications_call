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

/**
 * 主题描述类
 *
 * @since 2025-06-20
 */
export class ThemeDescription {
  public id?: string;
  public title?: string;
  public basePath?: PixelMap | null;
  public previewPath: PixelMap[] = [];
  public parentPath?: string;
  public i18nFilesPath?: string;
}

/**
 * 主题图标类型
 */
export enum ThemeIcon {
  /**
   * 原生图标
   */
  NATIVE_ICON = 0,

  /**
   * 主题图标
   */
  THEME_ICON = 1,

  /**
   * 合成图标
   */
  COMPOSE_ICON = 2
}
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
import { Context, contextConstant } from '@kit.AbilityKit';
import LogUtils from './LogUtils';

const TAG = 'GroupIdUtil';

// groupId用于联系人应用与联系人数据库应用之间数据共享，groupId为固定值，通过p7b申请，不可随意更改!
const groupId: string = 'group.1521646752317339712';
let groupDir: string;

// 获取公共沙箱路径
export async function getGroupDir(context: Context) {
  try {
    if (!groupDir) {
      let area = context.area;
      context.area = contextConstant.AreaMode.EL2;
      groupDir = await context.getGroupDir(groupId);
      context.area = area;
      LogUtils.i(TAG, 'getGroupId success: ' + groupDir);
    }
    return groupDir;
  } catch (error) {
    LogUtils.e(TAG, 'getGroupId error: ' + JSON.stringify(error));
    return groupDir;
  }
}
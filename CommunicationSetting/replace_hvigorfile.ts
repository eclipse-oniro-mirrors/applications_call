/*
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

import { hvigor, getHvigorNode } from '@ohos/hvigor';
import { uploadTestCases } from '@ohos/hypium-plugin';
import { appTasks } from '@ohos/hvigor-ohos-plugin';
import { onlineSignPlugin, OnlineSignOptions } from '@ohos/hvigor-ohos-online-sign-plugin';

const config = {
  hvigor: hvigor,
  hvigorNode: getHvigorNode(__filename),
  templateEngName: 'CommunicationSettingTask',
  modulesConfig: [
    {
      moduleName: 'entry', // build-profile.json5
      appName: 'CommunicationSetting'
    },
    {
      moduleName: 'wearable_communicationsetting', // build-profile.json5
      appName: 'WatchCommunicationSetting',
      templateEngName: 'DTWatchCommunicationSetting_watch', // CDE任务模板中维护的模板英文名称
    },
  ]
};

const signOptions: OnlineSignOptions = {
  profile: 'hw_sign/CommunicationSetting.p7b',
  keyAlias: 'TrafficStatistic',
  hapSignToolFile: 'hw_sign/hap-sign-tool.jar', // 签名工具hap-sign-tool.jar的路径
  username: `${process.env.ONLINE_USERNAME}`, // 环境变量中需要配置用户名和密码
  password: `${process.env.ONLINE_PASSWD}`,
  enableOnlineSign: true // 是否启用在线签名
};

uploadTestCases(config); // 执行上述配置的模块测试，并上传对应的用例信息。 注意：本地调试时该方法务必注释掉，不然会影响流水线文本用例

export default {
  system: appTasks,
  plugins: [onlineSignPlugin(signOptions)]
};
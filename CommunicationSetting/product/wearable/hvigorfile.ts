/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

module.exports = require('@ohos/hvigor-ohos-plugin').hapTasks;

// import { hvigor, getHvigorNode } from '@ohos/hvigor';
// import { hapTasks } from '@ohos/hvigor-ohos-plugin';
// import * as path from 'path';
// import { executeOnlineSign } from '../../hw_sign/sign.js';
// import { initTesting } from '@ohos/hypium-plugin';

// const M_MODULE: string = getHvigorNode(__filename);
// const OHOS_PLUGIN: string = hapTasks(M_MODULE);

// const ONLINE_SIGNHAP_TASK_NAME: string = 'onlineSignHap';
// let curTargetName: string = 'default';
// const M_MODULE_NAME: string = M_MODULE.getName();
// const PROJECT_ROOT_PATH: string = process.cwd();
//
// // 若是feature模块签名，此处填写依赖的entry模块名称
// const ENTRY_NAME: string = '';
//
// OHOS_PLUGIN.getNeedExecTargetServiceList().forEach(targetServices => {
//
//   curTargetName = targetServices.getTargetData().getTargetName();
//
//   // 注册在线签名任务和创建任务依赖
//   const ONLINE_SIGN_TASK = M_MODULE.task(() => {
//     // 构建的未签名的hap的输出根目录
//     const M_MODULE_BUILD_OUTPUT_DIE: string = path.resolve(PROJECT_ROOT_PATH, 'product', 'wearable', `build/default/outputs/${curTargetName}/`);
//
//     // 未签名的hap包路径
//     const INPUT_FILE: string = path.resolve(M_MODULE_BUILD_OUTPUT_DIE, `${M_MODULE_NAME}${ENTRY_NAME ? '-' + ENTRY_NAME : ''}-${curTargetName}-unsigned.hap`);
//     // 签名后的hap包路径
//     const OUTPUT_FILE: string = path.resolve(M_MODULE_BUILD_OUTPUT_DIE, `${M_MODULE_NAME}${ENTRY_NAME ? '-' + ENTRY_NAME : ''}-${curTargetName}-signed.hap`);
//
//     executeOnlineSign(INPUT_FILE, OUTPUT_FILE);
//
//   }, ONLINE_SIGNHAP_TASK_NAME).dependsOn(`${curTargetName}@PackageHap`);
//
//   // 使用在线签名,可以把离线签名任务disable掉
//   if (ONLINE_SIGN_TASK.getEnabled()) {
//     M_MODULE.getTaskByName(`${curTargetName}@SignHap`).setEnabled(false);
//   }
// });
//
// // 将在线签名任务挂接在assembleHap任务上,如果需要在IDE上使用,assembleHap任务是固定的
// M_MODULE.getTaskByName('assembleHap').dependsOn(ONLINE_SIGNHAP_TASK_NAME);
//
// const config = {
//   hvigor: hvigor,
//   packageConfig: {
//     appName: 'WatchCommunicationSetting', // 与cde架构定义的模块名相同，每个模块流水线归档的hap名，不填默认是module.json5定的模块名
//     commandParams: hvigor.getExtraConfig(), // hvigor 命令行参数
//     module: M_MODULE, // 当前模块对象,
//     entryName: '' // 若是feature模块签名，此处填写依赖的entry模块名称
//   }
// };
// initTesting(config);
// module.exports = {
//   ohos: OHOS_PLUGIN,
// };
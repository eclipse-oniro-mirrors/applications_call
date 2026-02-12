/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025-2025. All rights reserved.
 */

module.exports = require('@ohos/hvigor-ohos-plugin').hapTasks;

// import { hvigor, getHvigorNode } from '@ohos/hvigor';
// import { hapTasks } from '@ohos/hvigor-ohos-plugin';
// import { dtPipelinePackagePlugin } from '@ohos/hypium-plugin';
//
// const mModule = getHvigorNode(__filename);
//
// const config = {
//   hvigor: hvigor,
//   packageConfig: {
//     appName: 'WatchCommunicationSetting', // 与cde架构定义的模块名相同，每个模块流水线归档的hap名，不填默认是module.json5定的模块名
//     commandParams: hvigor.getExtraConfig(), // hvigor 命令行参数
//     module: mModule, // 当前模块对象,
//     entryName: '' // 若是feature模块签名，此处填写依赖的entry模块名称
//   }
// }
//
// export default {
//   system: hapTasks,
//   plugins: [dtPipelinePackagePlugin(config)]
// }
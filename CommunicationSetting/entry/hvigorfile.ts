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

module.exports = require('@ohos/hvigor-ohos-plugin').hapTasks;

// Script for compiling build behavior. It is built in the build plug-in and cannot be modified currently.
// import { hvigor, getHvigorNode } from '@ohos/hvigor';
// import { hapTasks } from '@ohos/hvigor-ohos-plugin';
// import { initTesting } from '@ohos/hypium-plugin';
// import * as path from 'path';
// import { executeOnlineSign } from '../hw_sign/sign';
//
// const mModule = getHvigorNode(__filename);
// const ohosPlugin = hapTasks(mModule);
//
// const onlineSignHapTaskName: string = 'onlineSignHap';
// const mModuleName: string = mModule.getName();
// const projectRootPath: string = process.cwd();
// const productPath: string = 'entry';
//
// // 若是feature模块签名，此处填写依赖的entry模块名称
// const entryName = '';
//
// let moduleProps = hvigor.getExtraConfig().get('module');
// let curTargetNames = ['default'];
// if (moduleProps) {
//     let modules = moduleProps.split(',');
//     // 可处理打包命令中单模块多个目标的情况；entry@default@ohosTest
//     let mObj = {};
//     for (let m of modules) {
//         const [mName, ...target] = m.split('@');
//         mObj[mName] = target;
//     }
//     // 当前模块不在打包范围直接返回
//     if (!(mModuleName in mObj)) {
//         module.exports = {
//             ohos: ohosPlugin
//         };
//         return ohosPlugin;
//     }
//     curTargetNames = mObj[mModuleName];
//     if (JSON.stringify(curTargetNames) === '[]') {
//         curTargetNames = ['default'];
//     }
// }
//
// curTargetNames.forEach((curTargetName)=>{
//     const onlineSignTask = mModule.task(() => {
//         const moduleBuildOutputDir = path.resolve(projectRootPath, mModuleName, `build/default/outputs/${curTargetName}/`);
//         const inputFile = path.resolve(moduleBuildOutputDir,
//             `${mModuleName}${entryName ? '-' + entryName : ''}-${curTargetName}-unsigned.hap`);
//
//         const outputFile = path.resolve(moduleBuildOutputDir,
//             `${mModuleName}${entryName ? '-' + entryName : ''}-${curTargetName}-signed.hap`);
//
//         executeOnlineSign(inputFile, outputFile);
//     }, onlineSignHapTaskName).dependsOn(`${curTargetName}@PackageHap`);
//
//     if (onlineSignTask.getEnabled()) {
//         mModule.getTaskByName(`${curTargetName}@SignHap`).setEnabled(false);
//     }
//
//     mModule.getTaskByName('assembleHap').dependsOn(onlineSignHapTaskName);
// });
//
// const config = {
//     hvigor: hvigor,
//     packageConfig: {
//         appName: 'CommunicationSetting',
//         commandParams: hvigor.getExtraConfig(),
//         module: mModule,
//         entryName: ''
//     }
// }
//
// // The release signing is included and supported.
// initTesting(config);
//
// module.exports = {
//     ohos: ohosPlugin
// };
//
// export default {
//     system: hapTasks,  /* Built-in plugin of Hvigor. It cannot be modified. */
//     plugins:[]         /* Custom plugin to extend the functionality of Hvigor. */
// }
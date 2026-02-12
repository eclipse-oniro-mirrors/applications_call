/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

// Script for compiling build behavior. It is built in the build plug-in and cannot be modified currently.
import { hvigor, getHvigorNode } from '@ohos/hvigor';
import { hapTasks } from '@ohos/hvigor-ohos-plugin';
// import { initTesting } from '@ohos/hypium-plugin';
// import * as path from 'path';
// import { executeOnlineSign } from '../sign/sign.js';
// import fs from 'fs';

const mModule = getHvigorNode(__filename);
const ohosPlugin = hapTasks(mModule);

// const onlineSignHapTaskName: string = 'onlineSignHap';
// const mModuleName: string = mModule.getName();
// const projectRootPath: string = process.cwd();
// const productPath: string = 'entry';
// const updateModuleJsonDepTaskName = 'updateModuleJsonDep';
//
// // 若是feature模块签名，此处填写依赖的entry模块名称
// const entryName = '';
//
// let moduleProps = hvigor.getExtraConfig().get('module');
// let curTargetNames = ['default'];
// if (moduleProps) {
//   let modules = moduleProps.split(',');
//   // 可处理打包命令中单模块多个目标的情况；entry@default@ohosTest
//   let mObj = {};
//   for (let m of modules) {
//     const [mName, ...target] = m.split('@');
//     mObj[mName] = target;
//   }
//   // 当前模块不在打包范围直接返回
//   if (!(mModuleName in mObj)) {
//     return ohosPlugin;
//   }
//   curTargetNames = mObj[mModuleName];
// }
//
// curTargetNames.forEach((curTargetName) => {
//   // 注册在线签名任务和创建任务依赖
//   const onlineSignTask = mModule.task(() => {
//     // 构建的未签名的hap的输出根目录
//     const moduleBuildOutputDir = path.resolve(projectRootPath, mModuleName, `build/default/outputs/${curTargetName}/`);
//     // 未签名的hap包路径
//     const inputFile = path.resolve(moduleBuildOutputDir, `${mModuleName}-${curTargetName}-unsigned.hap`);
//     // 签名后的hap包路径
//     const outputFile = path.resolve(moduleBuildOutputDir, `${mModuleName}-${curTargetName}-signed.hap`);
//
//     executeOnlineSign(inputFile, outputFile)
//   }, `${onlineSignHapTaskName}_${curTargetName}`).dependsOn(`${curTargetName}@PackageHap`);
//
//   if (onlineSignTask.getEnabled()) {
//     mModule.getTaskByName(`${curTargetName}@SignHap`)?.setEnabled(false);
//   }
//   // 将在线签名任务挂接在assembleHap任务上,如果需要在IDE上使用,assembleHap任务是固定的
//   mModule.getTaskByName('assembleHap').dependsOn(`${onlineSignHapTaskName}_${curTargetName}`);
//   // 规避IDE打包检查HSP依赖的问题
//   const updateModuleJsonDepTask = mModule.task(() => {
//     const moduleJsonPath = path.resolve(projectRootPath, mModuleName, `build/default/intermediates/process_profile/${curTargetName}/module.json`);
//     const content = JSON.parse(fs.readFileSync(moduleJsonPath, 'utf-8').toString());
//     content.module.dependencies = [{ 'bundleName': 'com.ohos.photobrowser', 'moduleName': 'browserlibrary' }];
//     fs.writeFileSync(moduleJsonPath, JSON.stringify(content), 'utf-8');
//   }, `${curTargetName}@${updateModuleJsonDepTaskName}`).dependsOn(`${curTargetName}@ProcessProfile`);
//
//   mModule.getTaskByName(`${curTargetName}@CompileResource`).dependsOn(`${curTargetName}@${updateModuleJsonDepTaskName}`);
// });
//
// const config = {
//   hvigor: hvigor,
//   packageConfig: {
//     appName: 'EmergencyCommunication', // 与cde架构定义的模块名相同，每个模块流水线归档的hap名，不填默认是module.json5定的模块名
//     commandParams: hvigor.getExtraConfig(), // hvigor 命令行参数
//     module: mModule // 当前模块对象,
//     // entryName: '' // 若是feature模块签名，此处填写依赖的entry模块名称
//   },
// }
// console.log(require.resolve('@ohos/hvigor'));
//
// initTesting(config);

module.exports = {
  ohos: ohosPlugin
}
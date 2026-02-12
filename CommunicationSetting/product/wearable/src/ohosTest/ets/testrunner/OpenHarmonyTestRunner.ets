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

import { abilityDelegatorRegistry, TestRunner } from '@kit.TestKit';
import { UIAbility, common, application } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { resourceManager } from '@kit.LocalizationKit';
import { util } from '@kit.ArkTS';
import { LogUtil } from '../../../main/ets/util/LogUtil';

let abilityDelegator: abilityDelegatorRegistry.AbilityDelegator;
let abilityDelegatorArguments: abilityDelegatorRegistry.AbilityDelegatorArgs;
let jsonPath: string = 'mock/mock-config.json';
let TAG: string = 'OpenHarmonyTestRunner';
const UNLOCK_ERROR = -3;
const global: object = new Function('return this')();

async function onAbilityCreateCallback(data: UIAbility) {
  LogUtil.info(`${TAG} onAbilityCreateCallback`);
}

async function addAbilityMonitorCallback(err: BusinessError) {
  LogUtil.info(`${TAG} addAbilityMonitorCallback`);
}

export default class OpenHarmonyTestRunner implements TestRunner {
  constructor() {
  }

  onPrepare() {
    LogUtil.info(`${TAG} OnPrepare`);
  }

  async onRun() {
    LogUtil.info(`${TAG} onRun run`);
    abilityDelegatorArguments = abilityDelegatorRegistry.getArguments()
    abilityDelegator = abilityDelegatorRegistry.getAbilityDelegator()
    let moduleName = abilityDelegatorArguments.parameters['-m'];

    const savePath: string = '__savePath__';
    const readPath: string = '__readPath__';
    const testMode: string = '__testMode__';
    let uid: number = Math.floor(abilityDelegator.getAppContext().applicationInfo.uid / 200000);
    const bundleName: string = abilityDelegatorArguments.bundleName;
    global[savePath] = '/data/storage/el2/base/js_coverage.json';
    global[readPath] = '/data/app/el2/' + uid + '/base/' + bundleName + '/js_coverage.json';
    global[testMode] = 'ohostest';

    try {
      application.createModuleContext(abilityDelegator.getAppContext().getApplicationContext(), moduleName)
        .then((data: Context) => {
          doOnRun(data, moduleName);
        }).catch((error: BusinessError) => {
        LogUtil.error(`test runner createModuleContext failed, error.message: ${(error as BusinessError).message}`);
        return;
      })
    } catch (error) {
      LogUtil.error(`test runner createModuleContext failed, error.message: ${(error as BusinessError).message}`);
      return;
    }
  }
}

async function doOnRun(context: common.Context, moduleName: string) {
  let mResourceManager = context.resourceManager;
  await checkMock(abilityDelegator, mResourceManager);
  const bundleName = abilityDelegatorArguments.bundleName;
  const testAbilityName: string = 'TestAbility';
  let lMonitor: abilityDelegatorRegistry.AbilityMonitor = {
    abilityName: testAbilityName,
    onAbilityCreate: onAbilityCreateCallback,
    moduleName: moduleName
  };
  abilityDelegator.addAbilityMonitor(lMonitor, addAbilityMonitorCallback)
  await startAbility(bundleName, testAbilityName, moduleName);
  LogUtil.info(`${TAG} OpenHarmonyTestRunner onRun end`);
}

async function startAbility(bundleName: string, abilityName: string, moduleName: string) {
  await abilityDelegator.executeShellCommand(`aa start -b ${bundleName} -a ${abilityName} -m ${moduleName}`)
    .then(result => {
      if (result.stdResult.includes('error: unlock screen failed in developer mode')) {
        LogUtil.info(`${TAG} startAbility failed ${result.stdResult}`);
        abilityDelegator.finishTest('', UNLOCK_ERROR, () => {
        });
        return;
      }
    })
    .catch((err: string) => {
      LogUtil.error(`${TAG} startAbility error: ${err}`);
    })
}

async function checkMock(abilityDelegator: abilityDelegatorRegistry.AbilityDelegator,
  resourceManager: resourceManager.ResourceManager) {
  let rawFile: Uint8Array;
  try {
    rawFile = resourceManager.getRawFileContentSync(jsonPath);
    LogUtil.info(`${TAG} MockList file exists`);
    let mockStr: string = util.TextDecoder.create('utf-8', { ignoreBOM: true }).decodeToString(rawFile);
    let mockMap: Record<string, string> = getMockList(mockStr);
    try {
      abilityDelegator.setMockList(mockMap)
    } catch (error) {
      let code = (error as BusinessError).code;
      let message = (error as BusinessError).message;
      LogUtil.error(`${TAG} abilityDelegator.setMockList failed, error code: ${code}, message: ${message}.`);
    }
  } catch (error) {
    let code = (error as BusinessError).code;
    let message = (error as BusinessError).message;
    LogUtil.error(`${TAG} ResourceManager:callback getRawFileContent failed, error code: ${code}, message: ${message}.`);
  }
}

function getMockList(jsonStr: string) {
  let jsonObj: Record<string, Object> = JSON.parse(jsonStr);
  let map: Map<string, object> = new Map<string, object>(Object.entries(jsonObj));
  let mockList: Record<string, string> = {};
  map.forEach((value: object, key: string) => {
    let realValue: string = value['source'].toString();
    mockList[key] = realValue;
  });
  LogUtil.info(`${TAG} mock-json value: ${mockList}`);
  return mockList;
}
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

const path = require('path');
const execa = require('execa');
const fs = require('fs-extra');
const childProcess = require('child_process');

const projectRootPath = process.cwd();
const userName = process.env.ONLINE_USERNAME;
const password = process.env.ONLINE_PASSWD;
const onlineSignServer = '';
const hapSignTool = 'hap-sign-tool.jar';
const hapSignOnlinePlugin = 'hapsign-online-plugin.jar';
const p7bFileName = 'CommunicationSetting.p7b';
const keyAlias = 'TrafficStatistic';
const signMaterialPath = path.resolve(projectRootPath, 'hw_sign');
const signToolFile = path.resolve(signMaterialPath, hapSignTool);

fs.exists(signToolFile, function(exists) {
  if (!exists) {
    childProcess.execFile('copy.bat', null, {cwd: signMaterialPath}, function(error, stdout, stderr) {
      if (error !== null) {
        console.log('exec error' + error);
      } else {
        console.log('stdout: ' + stdout);
        console.log('stderr: ' + stderr);
      }
    });
  }
});

function executeOnlineSign(inputFile, outputFile) {
  const p7bFile = path.resolve(signMaterialPath, p7bFileName);
  const command = [
    '-jar',
    signToolFile,
    'sign-app',
    '-mode',
    'remoteSign',
    '-signServer',
    onlineSignServer,
    '-signerPlugin',
    hapSignOnlinePlugin,
    '-onlineAuthMode',
    'account',
    '-username',
    userName,
    '-userPwd',
    password,
    '-profileFile',
    p7bFile,
    '-compatibleVersion',
    '8',
    '-signAlg',
    'SHA256withECDSA',
    '-keyAlias',
    keyAlias,
    '-inFile',
    inputFile,
    '-outFile',
    outputFile
  ];

  execa.sync('java', command);
}

module.exports = {
    executeOnlineSign:executeOnlineSign
};
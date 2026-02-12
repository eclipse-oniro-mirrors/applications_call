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
import { describe, it, expect } from '@ohos/hypium'
import { copyDbDataHelper } from '../../../../../main/ets/backup/presenter/CopyDbDataHelper'
import Utils from '../../../../../main/ets/common/utils/utils';
import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';

export default function CopyDbDataHelperTest() {
  let emptyContext: common.Context;
  describe('CopyDbDataHelperTest', () => {
    let initDirsTest = async () => {
      let textContext = AppStorage.get<common.UIAbilityContext>('testAbility');
      if (!textContext) {
        return;
      }
      let result = await copyDbDataHelper.initDirs(textContext);
      await copyDbDataHelper.initDirs(emptyContext);
      expect(result == null).assertTrue();
    }
    let copySingleFileSync = () => {
      let textContext = AppStorage.get<common.UIAbilityContext>('testAbility');
      if (!textContext) {
        return;
      }
      let pathDir = textContext.filesDir;
      let dirPath = pathDir + "/testDir";
      let dirPath1 = pathDir + "/testDir1";
      fs.mkdirSync(dirPath);
      copyDbDataHelper.copySingleFileSync(dirPath, dirPath1, true);
      copyDbDataHelper.copyDbListFileForClone('sadhaih', 'sadhaih', false);
      let result = copyDbDataHelper.copyDbListFileForClone('dirPath', 'sadhaih', false);
      expect(result).assertFalse();
      fs.rmdirSync(dirPath);
    }
    let copyDbListFileForClone = () => {
      let textContext = AppStorage.get<common.UIAbilityContext>('testAbility');
      if (!textContext) {
        return;
      }
      let pathDir = textContext.filesDir;
      let dirPath = pathDir + "/testDir";
      let dirPath1 = pathDir + "/testDir1";
      let dirPath2 = dirPath + "/testDir2";
      fs.mkdirSync(dirPath);
      copyDbDataHelper.copyDbListFileForClone(dirPath, dirPath1, false);
      copyDbDataHelper.copyDbListFileForClone(dirPath, dirPath1, true);
      fs.mkdirSync(dirPath2);
      let result = copyDbDataHelper.copyDbListFileForClone(dirPath, dirPath1, true);
      expect(result).assertTrue();
      fs.rmdirSync(dirPath);
      fs.rmdirSync(dirPath1);
    }

    it('initDirsTest', 0, async () => {
      await initDirsTest();
    })
    it('CopyDbDataHelperTest_getSrcDirListFile', 0, async () => {
      let textContext = AppStorage.get<common.UIAbilityContext>('testAbility');
      if (!textContext) {
        return;
      }
      let pathDir = textContext.filesDir;
      let dirPath = pathDir + "/test";
      fs.mkdirSync(dirPath);
      let result = copyDbDataHelper.getSrcDirListFile('/test');
      expect(result.toString()).assertEqual('');
      result = copyDbDataHelper.getSrcDirListFile(dirPath);
      fs.rmdirSync(dirPath);
      expect(result.toString()).assertEqual('');
    })
    it('copySingleFileSync', 0, () => {
      copySingleFileSync();
    })
    it('copyDbListFileForClone', 0, () => {
      copyDbListFileForClone();
    })
  })
}
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

import {
  afterEach,
  ArgumentMatchers,
  beforeEach,
  describe,
  expect,
  it,
  MockKit,
  when
} from '@ohos/hypium';
import image from '@ohos.multimedia.image';
import { ThemeUtils } from '../../../../main/ets/theme/ThemeUtils';
import { MockHelper } from '../../common/MockHelper';

const DEFAULT_EMPTY_STRING: string = '';
const VALID_PATH: string = '/data/themes/a/app';
const FALSE_PATH: string = '/data';

export default function ThemeUtilsTest() {
  describe('ThemeUtilsTest', () => {
    let mocker: MockKit;
    beforeEach(() => {
      mocker = new MockKit();
      MockHelper.mockLog(mocker);
    })
    afterEach(() => {
      MockHelper.ignoreMockLog(mocker);
      mocker.clearAll();
    })

    it('isFileExistsTest', 0, async (done: Function) => {
      const result = ThemeUtils.isFileExists(DEFAULT_EMPTY_STRING);
      expect(result).assertFalse();
      ThemeUtils.isFileExists(VALID_PATH);
      done();
    })

    it('isDirTest_1', 0, async (done: Function) => {
      let mockIsFileExists: Function = mocker.mockFunc(ThemeUtils, ThemeUtils.isFileExists);
      when(mockIsFileExists)(ArgumentMatchers.any).afterReturn(false);
      expect(ThemeUtils.isDir(DEFAULT_EMPTY_STRING)).assertEqual(false);
      mocker.ignoreMock(ThemeUtils, ThemeUtils.isFileExists);
      done();
    })

    it('isDirTest_2', 0, async (done: Function) => {
      let mockIsFileExists: Function = mocker.mockFunc(ThemeUtils, ThemeUtils.isFileExists);
      when(mockIsFileExists)(ArgumentMatchers.any).afterReturn(true);
      expect(ThemeUtils.isDir(DEFAULT_EMPTY_STRING)).not().assertNull();
      mocker.ignoreMock(ThemeUtils, ThemeUtils.isFileExists);
      done();
    })

    it('readFileTest', 0, async (done: Function) => {
      const result1 = await ThemeUtils.readFile(DEFAULT_EMPTY_STRING);
      expect(result1).assertUndefined();
      const result2 = await ThemeUtils.readFile(VALID_PATH);
      expect(result2).not().assertNull();
      done();
    })

    it('getFileListTest', 0, async (done: Function) => {
      expect(ThemeUtils.getFileList(DEFAULT_EMPTY_STRING)).not().assertNull();
      expect(ThemeUtils.getFileList(VALID_PATH)).not().assertNull();
      done();
    })

    it('getActivatingThemePathTest_1', 0, async (done: Function) => {
      let mockIsFileExists: Function = mocker.mockFunc(ThemeUtils, ThemeUtils.isFileExists);
      when(mockIsFileExists)(ArgumentMatchers.any).afterReturn(true);
      expect(ThemeUtils.getActivatingThemePath()).not().assertNull();
      mocker.ignoreMock(ThemeUtils, ThemeUtils.isFileExists);
      done();
    })

    it('getActivatingThemePathTest_2', 0, async (done: Function) => {
      let mockIsFileExists: Function = mocker.mockFunc(ThemeUtils, ThemeUtils.isFileExists);
      when(mockIsFileExists)(ArgumentMatchers.any).afterReturn(false);
      expect(ThemeUtils.getActivatingThemePath()).assertUndefined();
      mocker.ignoreMock(ThemeUtils, ThemeUtils.isFileExists);
      done();
    })

    it('getFilePixelMapSyncTest', 0, async (done: Function) => {
      expect(ThemeUtils.getFilePixelMapSync(FALSE_PATH)).assertUndefined();
      done();
    })

    it('addNameTest_1', 0, async (done: Function) => {
      let mockPixelMap: image.PixelMap = {} as image.PixelMap;
      let name: string = "testTheme";
      let isActive: boolean = true;
      ThemeUtils.addName(mockPixelMap, name, isActive);
      expect(ThemeUtils.getFilePixelMapSync(DEFAULT_EMPTY_STRING)).assertUndefined();
      done();
    });

    it('addNameTest_2', 0, async (done: Function) => {
      let mapTest: image.PixelMap = { isEditable: true } as image.PixelMap;
      let name: string = "testTheme";
      let isActive: boolean = false;
      ThemeUtils.addName(mapTest, name, isActive);
      expect(ThemeUtils.getFilePixelMapSync(VALID_PATH)).not().assertNull();
      done();
    });

    it('readThemeDescriptionTest_1', 0, async (done: Function) => {
      let mockIsFileExists: Function = mocker.mockFunc(ThemeUtils, ThemeUtils.isFileExists);
      when(mockIsFileExists)(ArgumentMatchers.any).afterReturn(false);
      expect(ThemeUtils.readThemeDescription(DEFAULT_EMPTY_STRING)).not().assertNull();
      mocker.ignoreMock(ThemeUtils, ThemeUtils.isFileExists);
      done();
    });

    it('readThemeDescriptionTest_2', 0, async (done: Function) => {
      let mockIsFileExists: Function = mocker.mockFunc(ThemeUtils, ThemeUtils.isFileExists);
      when(mockIsFileExists)(ArgumentMatchers.any).afterReturn(true);
      expect(ThemeUtils.readThemeDescription(VALID_PATH)).not().assertNull();
      mocker.ignoreMock(ThemeUtils, ThemeUtils.isFileExists);
      done();
    });

    it('readImageTest', 0, async (done: Function) => {
      expect(ThemeUtils.readImage(VALID_PATH)).not().assertNull();
      expect(ThemeUtils.readImage(DEFAULT_EMPTY_STRING)).not().assertNull();
      done();
    });
  })
}
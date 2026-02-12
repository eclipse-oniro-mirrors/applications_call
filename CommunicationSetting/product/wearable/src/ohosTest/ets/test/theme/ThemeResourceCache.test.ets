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

import bundle from '@ohos.bundle.bundleManager';
import image from '@ohos.multimedia.image';
import { afterEach, ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { ThemeResourceCache } from '../../../../main/ets/theme/ThemeResourceCache';
import { ThemeUtils } from '../../../../main/ets/theme/ThemeUtils';
import { LogUtil } from '../../../../main/ets/util/LogUtil';
import { ContextUtils } from '../../common/ContextUtils';
import { MockHelper } from '../../common/MockHelper';

const TAG: string = 'ThemeResourceCache ';
const TEST_PATH: string = 'TestPath';
const TEST_BUNDLE_NAME_ARRAY: string[] = ['Test'];
const TEST_BUNDLE_NAME: string = 'Test';
const TEST_INVALID_BUNDLE_NAME: string = 'TEST_INVALID_BUNDLE';
const SETTINGS_BUNDLE_NAME: string = 'com.ohos.settings';
const SETTINGS_MODULE_NAME: string = 'wearable_settings';
const ICONS: string = '/icons';
const OTHERS_ICONS: string = '/other_icons';
const TEST_ICON_ID: number = 1;
const TEST_ICON_ID_INVALID: number = 0;

export default function ThemeResourceCacheTest() {
  describe('ThemeResourceCacheTest', () => {
    let mocker: MockKit;

    beforeEach(() => {
      mocker = new MockKit();
    })

    afterEach(() => {
      mocker.clearAll();
    })

    it('initDataTestPathIsNull', 0, () => {
      let mockGetActivatingThemePath = mocker.mockFunc(ThemeUtils, ThemeUtils.getActivatingThemePath);
      when(mockGetActivatingThemePath)(ArgumentMatchers.any).afterReturn(undefined);
      mocker.mockFunc(LogUtil, LogUtil.warn);
      ThemeResourceCache.themeResourceCache().initActivatingTheme(ContextUtils.getContext());
      mocker.verify('warn', [MockHelper.getNormalLog(TAG, 'the flag file does not exist.')]).once();
      mocker.ignoreMock(ThemeUtils, ThemeUtils.getActivatingThemePath);
      mocker.ignoreMock(LogUtil, LogUtil.warn);
    })

    it('initDataTestIsFileNotExists', 0, () => {
      let mockGetActivatingThemePath = mocker.mockFunc(ThemeUtils, ThemeUtils.getActivatingThemePath);
      when(mockGetActivatingThemePath)(ArgumentMatchers.any).afterReturn(TEST_PATH);
      let mockFileExists = mocker.mockFunc(ThemeUtils, ThemeUtils.isFileExists);
      when(mockFileExists)(TEST_PATH + ICONS).afterReturn(false);
      mocker.mockFunc(LogUtil, LogUtil.warn);
      let themeResourceCache: ThemeResourceCache = new ThemeResourceCache();
      themeResourceCache.initActivatingTheme(ContextUtils.getContext());
      mocker.verify('warn', [MockHelper.getNormalLog(TAG, 'the icons file does not exist.')]).once();
      mocker.ignoreMock(ThemeUtils, ThemeUtils.getActivatingThemePath);
      mocker.ignoreMock(ThemeUtils, ThemeUtils.isFileExists);
      mocker.ignoreMock(LogUtil, LogUtil.warn);
    })

    it('initDataTestThemePathFileNotExists', 0, () => {
      let mockGetActivatingThemePath = mocker.mockFunc(ThemeUtils, ThemeUtils.getActivatingThemePath);
      when(mockGetActivatingThemePath)(ArgumentMatchers.any).afterReturn(TEST_PATH);
      let mockFileExists = mocker.mockFunc(ThemeUtils, ThemeUtils.isFileExists);
      when(mockFileExists)(TEST_PATH + ICONS).afterReturn(true);
      when(mockFileExists)(TEST_PATH + ICONS + OTHERS_ICONS).afterReturn(false);
      mocker.mockFunc(LogUtil, LogUtil.warn);
      let themeResourceCache: ThemeResourceCache = new ThemeResourceCache();
      themeResourceCache.initActivatingTheme(ContextUtils.getContext());
      mocker.verify('warn', [MockHelper.getNormalLog(TAG, 'the other icons file does not exist.')]).once();
      mocker.ignoreMock(ThemeUtils, ThemeUtils.getActivatingThemePath);
      mocker.ignoreMock(ThemeUtils, ThemeUtils.isFileExists);
      mocker.ignoreMock(LogUtil, LogUtil.warn);
    })

    it('initDataTest', 0, () => {
      let mockGetActivatingThemePath = mocker.mockFunc(ThemeUtils, ThemeUtils.getActivatingThemePath);
      when(mockGetActivatingThemePath)(ArgumentMatchers.any).afterReturn(TEST_PATH);
      let mockFileExists = mocker.mockFunc(ThemeUtils, ThemeUtils.isFileExists);
      when(mockFileExists)(ArgumentMatchers.any).afterReturn(true);
      mocker.mockFunc(LogUtil, LogUtil.info);
      let themeResourceCache: ThemeResourceCache = new ThemeResourceCache();
      themeResourceCache.initActivatingTheme(ContextUtils.getContext());
      mocker.verify('info', [MockHelper.getNormalLog(TAG, 'initData end.')]).once();
      mocker.ignoreMock(ThemeUtils, ThemeUtils.getActivatingThemePath);
      mocker.ignoreMock(ThemeUtils, ThemeUtils.isFileExists);
      mocker.ignoreMock(LogUtil, LogUtil.info);
    })

    it('loadBackGroundImageTestBackPixelMapNotExists', 0, () => {
      let mockGetActivatingThemePath = mocker.mockFunc(ThemeUtils, ThemeUtils.getActivatingThemePath);
      when(mockGetActivatingThemePath)(ArgumentMatchers.any).afterReturn(TEST_PATH);
      let mockFileExists = mocker.mockFunc(ThemeUtils, ThemeUtils.isFileExists);
      when(mockFileExists)(ArgumentMatchers.any).afterReturn(true);
      let mockFilePixelMapExists = mocker.mockFunc(ThemeUtils, ThemeUtils.getFilePixelMapSync);
      when(mockFilePixelMapExists)(ArgumentMatchers.any).afterReturn(false);
      mocker.mockFunc(LogUtil, LogUtil.warn);
      let themeResourceCache: ThemeResourceCache = new ThemeResourceCache();
      themeResourceCache.initActivatingTheme(ContextUtils.getContext());
      mocker.verify('warn', [MockHelper.getNormalLog(TAG, 'loadBackGroundImage backPixelMap is null.')]).once();
      mocker.ignoreMock(ThemeUtils, ThemeUtils.getActivatingThemePath);
      mocker.ignoreMock(ThemeUtils, ThemeUtils.isFileExists);
      mocker.ignoreMock(ThemeUtils, ThemeUtils.getFilePixelMapSync);
      mocker.ignoreMock(LogUtil, LogUtil.warn);
    })

    it('loadBackGroundImageTest', 0, () => {
      let mockGetActivatingThemePath = mocker.mockFunc(ThemeUtils, ThemeUtils.getActivatingThemePath);
      when(mockGetActivatingThemePath)(ArgumentMatchers.any).afterReturn(TEST_PATH);
      let mockFileExists = mocker.mockFunc(ThemeUtils, ThemeUtils.isFileExists);
      when(mockFileExists)(ArgumentMatchers.any).afterReturn(true);
      let mockFilePixelMapExists = mocker.mockFunc(ThemeUtils, ThemeUtils.getFilePixelMapSync);
      when(mockFilePixelMapExists)(ArgumentMatchers.any).afterReturn(true);
      mocker.mockFunc(LogUtil, LogUtil.info);
      let themeResourceCache: ThemeResourceCache = new ThemeResourceCache();
      themeResourceCache.initActivatingTheme(ContextUtils.getContext());
      mocker.verify('info', [MockHelper.getNormalLog(TAG, 'initData end.')]).once();
      mocker.ignoreMock(ThemeUtils, ThemeUtils.getActivatingThemePath);
      mocker.ignoreMock(ThemeUtils, ThemeUtils.isFileExists);
      mocker.ignoreMock(ThemeUtils, ThemeUtils.getFilePixelMapSync);
      mocker.ignoreMock(LogUtil, LogUtil.info);
    })

    it('loadBackGroundImageTestThrowErr', 0, () => {
      let mockGetActivatingThemePath = mocker.mockFunc(ThemeUtils, ThemeUtils.getActivatingThemePath);
      when(mockGetActivatingThemePath)(ArgumentMatchers.any).afterReturn(TEST_PATH);
      let mockFileExists = mocker.mockFunc(ThemeUtils, ThemeUtils.isFileExists);
      when(mockFileExists)(ArgumentMatchers.any).afterReturn(true);
      let mockFilePixelMapExists = mocker.mockFunc(ThemeUtils, ThemeUtils.getFilePixelMapSync);
      when(mockFilePixelMapExists)(ArgumentMatchers.any).afterThrow('test err');
      mocker.mockFunc(LogUtil, LogUtil.error);
      let themeResourceCache: ThemeResourceCache = new ThemeResourceCache();
      try {
        themeResourceCache.initActivatingTheme(ContextUtils.getContext());
      } catch (e) {
        expect(e).assertEqual('test err');
      }
      mocker.ignoreMock(ThemeUtils, ThemeUtils.getActivatingThemePath);
      mocker.ignoreMock(ThemeUtils, ThemeUtils.isFileExists);
      mocker.ignoreMock(ThemeUtils, ThemeUtils.getFilePixelMapSync);
      mocker.ignoreMock(LogUtil, LogUtil.error);
    })

    it('isThemePackagesExistenceTest', 0, () => {
      let mockGetActivatingThemePath = mocker.mockFunc(ThemeUtils, ThemeUtils.getActivatingThemePath);
      when(mockGetActivatingThemePath)(ArgumentMatchers.any).afterReturn(TEST_PATH);
      let mockFileExists = mocker.mockFunc(ThemeUtils, ThemeUtils.isFileExists);
      when(mockFileExists)(ArgumentMatchers.any).afterReturn(true);
      let mockFilePixelMapExists = mocker.mockFunc(ThemeUtils, ThemeUtils.getFilePixelMapSync);
      when(mockFilePixelMapExists)(ArgumentMatchers.any).afterReturn(true);
      let mockGetFileList = mocker.mockFunc(ThemeUtils, ThemeUtils.getFileList);
      when(mockGetFileList)(ArgumentMatchers.any).afterReturn(TEST_BUNDLE_NAME_ARRAY);
      let themeResourceCache: ThemeResourceCache = new ThemeResourceCache();
      themeResourceCache.initActivatingTheme(ContextUtils.getContext());
      let packageExists = themeResourceCache.isThemePackagesExistence(TEST_BUNDLE_NAME);
      expect(packageExists).assertTrue();
      mocker.ignoreMock(ThemeUtils, ThemeUtils.getActivatingThemePath);
      mocker.ignoreMock(ThemeUtils, ThemeUtils.isFileExists);
      mocker.ignoreMock(ThemeUtils, ThemeUtils.getFilePixelMapSync);
      mocker.ignoreMock(ThemeUtils, ThemeUtils.getFileList);
    })

    it('isThemePackagesNotExistenceTest', 0, () => {
      let mockGetActivatingThemePath = mocker.mockFunc(ThemeUtils, ThemeUtils.getActivatingThemePath);
      when(mockGetActivatingThemePath)(ArgumentMatchers.any).afterReturn(TEST_PATH);
      let mockFileExists = mocker.mockFunc(ThemeUtils, ThemeUtils.isFileExists);
      when(mockFileExists)(TEST_PATH + ICONS).afterReturn(false);
      let themeResourceCache: ThemeResourceCache = new ThemeResourceCache();
      themeResourceCache.initActivatingTheme(ContextUtils.getContext());
      let packageExists = themeResourceCache.isThemePackagesExistence(TEST_BUNDLE_NAME);
      expect(packageExists).assertFalse();
      mocker.ignoreMock(ThemeUtils, ThemeUtils.getActivatingThemePath);
      mocker.ignoreMock(ThemeUtils, ThemeUtils.isFileExists);
    })

    it('isThemePackagesNotExistenceTestBundleNameNotInclude', 0, () => {
      let mockGetActivatingThemePath = mocker.mockFunc(ThemeUtils, ThemeUtils.getActivatingThemePath);
      when(mockGetActivatingThemePath)(ArgumentMatchers.any).afterReturn(TEST_PATH);
      let mockFileExists = mocker.mockFunc(ThemeUtils, ThemeUtils.isFileExists);
      when(mockFileExists)(ArgumentMatchers.any).afterReturn(true);
      let mockFilePixelMapExists = mocker.mockFunc(ThemeUtils, ThemeUtils.getFilePixelMapSync);
      when(mockFilePixelMapExists)(ArgumentMatchers.any).afterReturn(true);
      let mockGetFileList = mocker.mockFunc(ThemeUtils, ThemeUtils.getFileList);
      when(mockGetFileList)(ArgumentMatchers.any).afterReturn(TEST_BUNDLE_NAME_ARRAY);
      let themeResourceCache: ThemeResourceCache = new ThemeResourceCache();
      themeResourceCache.initActivatingTheme(ContextUtils.getContext());
      let packageExists = themeResourceCache.isThemePackagesExistence(ICONS);
      expect(packageExists).assertFalse();
      mocker.ignoreMock(ThemeUtils, ThemeUtils.getActivatingThemePath);
      mocker.ignoreMock(ThemeUtils, ThemeUtils.isFileExists);
      mocker.ignoreMock(ThemeUtils, ThemeUtils.getFilePixelMapSync);
      mocker.ignoreMock(ThemeUtils, ThemeUtils.getFileList);
    })

    it('getThemeDrawableDescriptorTestBundleNameIsUndefined', 0, async (done: Function) => {
      let themeResourceCache: ThemeResourceCache = new ThemeResourceCache();
      let result: PixelMap | undefined =
        await themeResourceCache.getThemeDrawableDescriptor(TEST_BUNDLE_NAME, TEST_BUNDLE_NAME, TEST_ICON_ID_INVALID);
      expect(result).assertEqual(undefined);
      done();
    })

    it('getThemeDrawableDescriptorTestOffCanvasIsUndefined', 0, async (done: Function) => {
      let themeResourceCache: ThemeResourceCache = new ThemeResourceCache();
      let result: PixelMap | undefined =
        await themeResourceCache.getThemeDrawableDescriptor(TEST_BUNDLE_NAME, TEST_BUNDLE_NAME, TEST_ICON_ID);
      expect(result).assertEqual(undefined);
      done();
    })

    it('getThemeDrawableDescriptorTest', 0, async (done: Function) => {
      ThemeResourceCache.clearThemeIcons();
      let mockGetActivatingThemePath = mocker.mockFunc(ThemeUtils, ThemeUtils.getActivatingThemePath);
      when(mockGetActivatingThemePath)(ArgumentMatchers.any).afterReturn(TEST_PATH);
      let mockFileExists = mocker.mockFunc(ThemeUtils, ThemeUtils.isFileExists);
      when(mockFileExists)(ArgumentMatchers.any).afterReturn(true);
      const color: ArrayBuffer = new ArrayBuffer(96);
      let opts: image.InitializationOptions =
        { editable: true, pixelFormat: image.PixelMapFormat.RGBA_8888, size: { height: 4, width: 6 } }
      let pixelMap: image.PixelMap = image.createPixelMapSync(color, opts);
      let mockFilePixelMap = mocker.mockFunc(ThemeUtils, ThemeUtils.getFilePixelMapSync);
      when(mockFilePixelMap)(ArgumentMatchers.any).afterReturn(pixelMap);
      let mockGetFileList = mocker.mockFunc(ThemeUtils, ThemeUtils.getFileList);
      when(mockGetFileList)(ArgumentMatchers.any).afterReturn(TEST_BUNDLE_NAME_ARRAY);
      let themeResourceCache: ThemeResourceCache = new ThemeResourceCache();
      themeResourceCache.initActivatingTheme(ContextUtils.getContext());
      let result: PixelMap | undefined =
        await themeResourceCache.getThemeDrawableDescriptor(TEST_BUNDLE_NAME, TEST_BUNDLE_NAME, TEST_ICON_ID);
      expect(result).assertEqual(undefined);
      mocker.ignoreMock(ThemeUtils, ThemeUtils.getActivatingThemePath);
      mocker.ignoreMock(ThemeUtils, ThemeUtils.isFileExists);
      mocker.ignoreMock(ThemeUtils, ThemeUtils.getFilePixelMapSync);
      mocker.ignoreMock(ThemeUtils, ThemeUtils.getFileList);
      done();
    })

    it('getThemeDrawableDescriptorThrowErrTest', 0, async (done: Function) => {
      let themeResourceCache: ESObject = new ThemeResourceCache();
      let mockGetImageBase64 = mocker.mockFunc(themeResourceCache, themeResourceCache.getImageBase64);
      when(mockGetImageBase64)(ArgumentMatchers.any).afterThrow('err');
      try {
        themeResourceCache.getThemeDrawableDescriptor(TEST_BUNDLE_NAME, TEST_BUNDLE_NAME, TEST_ICON_ID);
      } catch (err) {
        expect(err).assertEqual('err');
      }
      mocker.ignoreMock(themeResourceCache, themeResourceCache.getImageBase64);
      done();
    })

    it('getThemeDrawableDescriptorNativeIconTest', 0, async (done: Function) => {
      const color: ArrayBuffer = new ArrayBuffer(96);
      let opts: image.InitializationOptions =
        { editable: true, pixelFormat: image.PixelMapFormat.RGBA_8888, size: { height: 4, width: 6 } }
      let pixelMap: image.PixelMap = image.createPixelMapSync(color, opts);
      let themeResourceCache: ESObject = new ThemeResourceCache();
      let mockGetImageBase64 = mocker.mockFunc(themeResourceCache, themeResourceCache.getImageBase64);
      when(mockGetImageBase64)(ArgumentMatchers.any).afterReturn(pixelMap);
      let mockGetComposePixelMap = mocker.mockFunc(themeResourceCache, themeResourceCache.getComposePixelMap);
      when(mockGetComposePixelMap)(ArgumentMatchers.any).afterReturn(undefined);
      try {
        themeResourceCache.getThemeDrawableDescriptor(TEST_BUNDLE_NAME, TEST_BUNDLE_NAME, TEST_ICON_ID);
      } catch (err) {
        expect(err).assertEqual('err');
      }
      mocker.ignoreMock(themeResourceCache, themeResourceCache.getImageBase64);
      mocker.ignoreMock(themeResourceCache, themeResourceCache.getComposePixelMap);
      done();
    })

    it('getThemeDrawableDescriptorCacheTest', 0, async (done: Function) => {
      const color: ArrayBuffer = new ArrayBuffer(96);
      let opts: image.InitializationOptions =
        { editable: true, pixelFormat: image.PixelMapFormat.RGBA_8888, size: { height: 4, width: 6 } }
      let pixelMap: image.PixelMap = image.createPixelMapSync(color, opts);
      let themeResourceCache: ESObject = new ThemeResourceCache();
      let mockGetComposePixelMap = mocker.mockFunc(themeResourceCache, themeResourceCache.getComposePixelMap);
      when(mockGetComposePixelMap)(ArgumentMatchers.any).afterReturn(pixelMap);
      let result: PixelMap | undefined =
        await themeResourceCache.getThemeDrawableDescriptor(TEST_BUNDLE_NAME, TEST_BUNDLE_NAME, TEST_ICON_ID);
      let cacheResult: PixelMap | undefined =
        await themeResourceCache.getThemeDrawableDescriptor(TEST_BUNDLE_NAME, TEST_BUNDLE_NAME, TEST_ICON_ID);
      expect(cacheResult).assertEqual(result);
      mocker.ignoreMock(themeResourceCache, themeResourceCache.getComposePixelMap);
      done();
    })

    it('getComposePixelMapTest', 0, async (done: Function) => {
      ThemeResourceCache.clearThemeIcons();
      let mockGetActivatingThemePath = mocker.mockFunc(ThemeUtils, ThemeUtils.getActivatingThemePath);
      when(mockGetActivatingThemePath)(ArgumentMatchers.any).afterReturn(TEST_PATH);
      let mockFileExists = mocker.mockFunc(ThemeUtils, ThemeUtils.isFileExists);
      when(mockFileExists)(ArgumentMatchers.any).afterReturn(true);
      const color: ArrayBuffer = new ArrayBuffer(96);
      let opts: image.InitializationOptions =
        { editable: true, pixelFormat: image.PixelMapFormat.ASTC_4x4, size: { height: 4, width: 6 } }
      let pixelMap: image.PixelMap = image.createPixelMapSync(color, opts);
      let mockFilePixelMap = mocker.mockFunc(ThemeUtils, ThemeUtils.getFilePixelMapSync);
      when(mockFilePixelMap)(ArgumentMatchers.any).afterReturn(pixelMap);
      let mockGetFileList = mocker.mockFunc(ThemeUtils, ThemeUtils.getFileList);
      when(mockGetFileList)(ArgumentMatchers.any).afterReturn(TEST_BUNDLE_NAME_ARRAY);
      let themeResourceCache: ESObject = new ThemeResourceCache();
      let mockGetImageBase64 = mocker.mockFunc(themeResourceCache, themeResourceCache.getImageBase64);
      when(mockGetImageBase64)(ArgumentMatchers.any).afterReturn(pixelMap);
      themeResourceCache.initActivatingTheme(ContextUtils.getContext());
      let result: PixelMap | undefined =
        await themeResourceCache.getThemeDrawableDescriptor(TEST_BUNDLE_NAME, TEST_BUNDLE_NAME, TEST_ICON_ID);
      themeResourceCache.getComposePixelMap(pixelMap);
      expect(result?.getImageInfoSync()?.size?.width).assertEqual(12);
      mocker.ignoreMock(ThemeUtils, ThemeUtils.getActivatingThemePath);
      mocker.ignoreMock(ThemeUtils, ThemeUtils.isFileExists);
      mocker.ignoreMock(ThemeUtils, ThemeUtils.getFilePixelMapSync);
      mocker.ignoreMock(ThemeUtils, ThemeUtils.getFileList);
      mocker.ignoreMock(themeResourceCache, themeResourceCache.getImageBase64);
      done();
    })

    it('getImageBase64InvalidIconIdTest', 0, async (done: Function) => {
      let themeResourceCache: ESObject = new ThemeResourceCache();
      let result: undefined | image.PixelMap =
        await themeResourceCache.getImageBase64(TEST_BUNDLE_NAME, TEST_BUNDLE_NAME, TEST_ICON_ID_INVALID,
          TEST_ICON_ID_INVALID);
      expect(result).assertUndefined();
      done();
    })

    it('getImageBase64InvalidBundleThrowErrTest', 0, async (done: Function) => {
      let themeResourceCache: ESObject = new ThemeResourceCache();
      themeResourceCache.initActivatingTheme(ContextUtils.getContext());
      let result: undefined | image.PixelMap =
        await themeResourceCache.getImageBase64(TEST_INVALID_BUNDLE_NAME, TEST_BUNDLE_NAME, TEST_ICON_ID,
          TEST_ICON_ID);
      expect(result).assertUndefined();
      done();
    })

    it('getImageBase64Test', 0, async (done: Function) => {
      let themeResourceCache: ESObject = new ThemeResourceCache();
      themeResourceCache.initActivatingTheme(ContextUtils.getContext());
      let bundleInfo: bundle.BundleInfo | undefined = undefined;
      try {
        bundleInfo = await bundle.getBundleInfo(SETTINGS_BUNDLE_NAME,
          bundle.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION | bundle.BundleFlag.GET_BUNDLE_INFO_WITH_DISABLE);
      } catch (err) {
        LogUtil.error(`${TAG} getBundleInfo err ${err?.message}`);
      }
      mocker.mockFunc(LogUtil, LogUtil.info);
      await themeResourceCache.getImageBase64(SETTINGS_BUNDLE_NAME, SETTINGS_MODULE_NAME,
        bundleInfo?.appInfo?.iconId,
        TEST_ICON_ID_INVALID);
      mocker.verify('info', [MockHelper.getNormalLog(TAG, 'getImageBase64 end')]).once();
      done();
    })
  })
}
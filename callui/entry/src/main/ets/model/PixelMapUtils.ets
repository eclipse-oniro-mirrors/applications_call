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
import image from '@ohos.multimedia.image';
import LogUtils from '../common/utils/LogUtils';

const TAG = 'PixelMapUtils';

export default class PixelMapUtils {
  static async getImageSourceByArray(buffer: ArrayBufferLike): Promise<Nullable<image.ImageSource>> {
    let imageSource: Nullable<image.ImageSource>;
    try {
      imageSource = image.createImageSource(buffer);
    } catch (err) {
      LogUtils.e(TAG, `createImageSource failed: ${err}`);
    }
    return imageSource;
  }

  static async getImageSourceByPath(path: string): Promise<Nullable<image.ImageSource>> {
    let imageSource: Nullable<image.ImageSource>;
    try {
      imageSource = image.createImageSource(path);
    } catch (err) {
      LogUtils.e(TAG, `createImageSource failed: ${err}`);
    }
    return imageSource;
  }

  static async createPixelMapWithOption(imageSource: image.ImageSource,
    options?: image.DecodingOptions): Promise<image.PixelMap | undefined> {
    let pixelMap: image.PixelMap | undefined;
    try {
      pixelMap = await imageSource?.createPixelMap(options);
    } catch (err) {
      LogUtils.e(TAG, `createPixelMapWithOption failed to create the pixel map: ${err}`);
    }
    return pixelMap;
  }

  static async release(imageSource: Nullable<image.ImageSource>): Promise<void> {
    try {
      await imageSource?.release();
    } catch (err) {
      LogUtils.e(TAG, `release failed to release the image source:${err}`);
    }
  }

  static async releasePixelMap(pixelMap: Nullable<image.PixelMap>): Promise<void> {
    try {
      await pixelMap?.release();
    } catch (err) {
      LogUtils.e(TAG, `releasePixelMap failed to release the pixel map:${err}`);
    }
  }

  static async copyPixelMap(ori: image.PixelMap): Promise<image.PixelMap | undefined> {
    if (ori === undefined || ori === null) {
      return ori;
    }
    let buffer: ArrayBuffer | undefined;
    let bgraBuffer: ArrayBuffer | undefined;
    try {
      const oriBytesNumber = ori.getPixelBytesNumber();
      buffer = new ArrayBuffer(oriBytesNumber);
      ori.readPixelsToBufferSync(buffer);
      let oriImgInfo = ori.getImageInfoSync();
      LogUtils.i(TAG, `copyPixelMap oriImgInfo:${JSON.stringify(oriImgInfo)}`)
      bgraBuffer = PixelMapUtils.rgba2BGRA(buffer);
      let ret = image.createPixelMapSync(bgraBuffer, {
        size:{width: oriImgInfo.size.width, height: oriImgInfo.size.height},
      })
      return ret;
    } catch (err) {
      LogUtils.e(TAG, `copyPixelMap failed to copy the pixel map:${err}`);
      return undefined;
    }
  }

  private static rgba2BGRA(data: ArrayBuffer): ArrayBuffer {
    let len = data.byteLength;
    let tmpBuffer = new ArrayBuffer(len);
    let rgbaData = new DataView(data);
    let bgraData = new DataView(tmpBuffer);

    for (let i = 0; i < len; i += 4) {
      bgraData.setUint8(i, rgbaData.getUint8(i + 2));
      bgraData.setUint8(i + 1, rgbaData.getUint8(i + 1));
      bgraData.setUint8(i + 2, rgbaData.getUint8(i));
      bgraData.setUint8(i + 3, rgbaData.getUint8(i + 3));
    }
    return tmpBuffer;
  }
}
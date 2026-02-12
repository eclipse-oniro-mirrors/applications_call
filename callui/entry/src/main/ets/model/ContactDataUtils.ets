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
import DataShareResultSet from '@ohos.data.DataShareResultSet';
import DefaultCallData from '../common/struct/TypeUtils';
import { ContactsData } from '../common/utils/ContactsData';
import LogUtils from '../common/utils/LogUtils';
import { getGroupDir } from '../common/utils/GroupIdUtil';
import fs from '@ohos.file.fs';
import PixelMapUtils from './PixelMapUtils';
import effectKit from '@ohos.effectKit';

const TAG = 'ContactManager';

export default class ContactDataUtils {
  static async dataParse(resultSet: DataShareResultSet, callData: DefaultCallData, context: Context) {
    try {
      const typeId = resultSet.getString(resultSet.getColumnIndex(ContactsData.TYPE_ID));
      LogUtils.i(TAG, 'updateContactEnhancedInfo typeId: ' + typeId);
      switch (typeId) {
        case ContactsData.ORGANIZATION:
          const company = resultSet.getString(resultSet.getColumnIndex(ContactsData.COMPANY));
          const position = resultSet.getString(resultSet.getColumnIndex(ContactsData.COMPANY_POSITION));
          callData.contactCompany = company;
          callData.contactCompanyPosition = position;
          LogUtils.i(TAG, 'updateContactCompanyInfo successfully');
          break;
        case ContactsData.PHOTO:
          const detailInfo = resultSet.getString(resultSet.getColumnIndex(ContactsData.DETAIL_INFO));
          let isResGroupFileExist = false;
          let groupFilePath = '';
          if (detailInfo?.trim()) {
            let groupDir = await getGroupDir(context);
            if (groupDir) {
              groupFilePath = groupDir + '/' + detailInfo;
              isResGroupFileExist = await fs.accessSync(groupFilePath);
            }
          }
          LogUtils.i(TAG, 'updateContactAvatar avatar file is ' + isResGroupFileExist);
          // 联系人头像文件路径
          if (isResGroupFileExist) {
            // 使用头像文件获取pixMap
            let imageSource = await PixelMapUtils.getImageSourceByPath(groupFilePath);
            if (imageSource) {
              try {
                await ContactDataUtils.updateContactAvatar(imageSource, context, callData);
                return;
              } finally {
                await PixelMapUtils.release(imageSource);
              }
            }
            LogUtils.e(TAG, 'updateContactAvatar failed to get image source by path');
          }
          const blobData = resultSet.getBlob(resultSet.getColumnIndex(ContactsData.BLOB_DATA));
          // Convert to pixel map
          let imageSource = await PixelMapUtils.getImageSourceByArray(blobData.buffer);
          if (imageSource) {
            try {
              await ContactDataUtils.updateContactSmallAvatar(imageSource, context, callData);
              return;
            } finally {
              await PixelMapUtils.release(imageSource);
            }
          }
          LogUtils.e(TAG, 'updateContactAvatar failed to get image source by array');
          break;
        case ContactsData.NOTE:
          const note = resultSet.getString(resultSet.getColumnIndex(ContactsData.DETAIL_INFO));
          callData.contactNote = note;
          LogUtils.i(TAG, 'updateContactNote successfully');
          break;
        default:
          break;
      }
    } catch (error) {
      LogUtils.e(TAG, `dataParse failed: ${JSON.stringify(error)}`);
    }
  }

  static async updateContactAvatar(imageSource: image.ImageSource, context: Context, callData: DefaultCallData) {
    try {
      const pixelMap = await PixelMapUtils.createPixelMapWithOption(imageSource);
      if (pixelMap) {
        const imageInfo = pixelMap.getImageInfoSync();
        const endWidth = ContactDataUtils.cropAvatar(imageInfo.size.height, imageInfo.size.width, pixelMap);

        const avatarWidth = vp2px(context.resourceManager.getNumber($r('app.float.call_avatar_width')));
        const scale = avatarWidth / endWidth;
        LogUtils.i(TAG, 'scale:' + scale);
        pixelMap.scaleSync(scale, scale);
        callData.contactAvatar = pixelMap;
        await ContactDataUtils.getAvatarColor(callData, pixelMap);

        callData.contactSmallAvatar = await PixelMapUtils.copyPixelMap(pixelMap);
        const iconSize = 112;
        const smallScale = iconSize / avatarWidth;
        LogUtils.i(TAG, 'smallScale:' + smallScale);
        callData.contactSmallAvatar?.scaleSync(smallScale, smallScale);

        LogUtils.i(TAG, 'updateContactAvatar successfully');
      }
    } catch (err) {
      LogUtils.e(TAG, `updateContactAvatar failed : ${JSON.stringify(err)}`);
    } finally {
      await PixelMapUtils.release(imageSource);
    }
  }

  private static async getAvatarColor(callData: DefaultCallData, pixelMap: image.PixelMap) {
    try {
      const colorPicker = await effectKit.createColorPicker(pixelMap);
      const averageColor = colorPicker.getAverageColor();
      LogUtils.i(TAG, `average color: ${JSON.stringify(averageColor)}`);
      callData.contactAvatarColor =
        `#6B${averageColor.red.toString(16)}${averageColor.green.toString(16)}${averageColor.blue.toString(16)}`;
      LogUtils.i(TAG, `result color: ${callData.contactAvatarColor}`);
    } catch (err) {
      LogUtils.e(TAG, `getAvatarColor failed : ${JSON.stringify(err)}`);
    }
  }

  private static cropAvatar(oriHeight: number, oriWidth: number, pixelMap: image.PixelMap) {
    LogUtils.i(TAG, `oriHeight: ${oriHeight}, oriWidth: ${oriWidth}`);
    if (oriHeight !== oriWidth) {
      const region: image.Region = {
        size: {
          height: oriHeight, width: oriWidth
        }, x: 0, y: 0
      };
      if (oriHeight > oriWidth) {
        region.size.height = oriWidth;
        region.y = (oriHeight - oriWidth) / 2;
        pixelMap.cropSync(region);
        return oriWidth;
      } else {
        region.size.width = oriHeight;
        region.x = (oriWidth - oriHeight) / 2;
        pixelMap.cropSync(region);
        return oriHeight;
      }
    }
    if (oriWidth === 640) { // Remove the white border of the default avatar.
      pixelMap.cropSync({
        size: {
          height: 638, width: 638
        }, x: 1, y: 1
      });
    }
    return oriWidth;
  }

  static async updateContactSmallAvatar(imageSource: image.ImageSource, context: Context, callData: DefaultCallData) {
    try {
      const avatarWidth = vp2px(context.resourceManager.getNumber($r('app.float.call_avatar_width')));
      callData.contactAvatar = await PixelMapUtils.createPixelMapWithOption(imageSource, {
        desiredSize: {
          height: avatarWidth,
          width: avatarWidth
        }
      });
      if (callData.contactAvatar) {
        await ContactDataUtils.getAvatarColor(callData, callData.contactAvatar);
      }
      callData.contactSmallAvatar = await PixelMapUtils.createPixelMapWithOption(imageSource, {
        desiredSize: {
          height: 112, // BannerResourceManager.MEDIUM_ICON_SIZE,
          width: 112
        }
      });

      LogUtils.i(TAG, 'updateContactAvatar by small successfully');
    } catch (err) {
      LogUtils.e(TAG, `updateContactAvatar failed by small: ${JSON.stringify(err)}`);
    } finally {
      await PixelMapUtils.release(imageSource);
    }
  }
}
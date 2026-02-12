/**
 * Copyright (c) 2025-2025 Huawei Device Co., Ltd.
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

import { StringUtil } from '../../common/utils/StringUtil';
import { Card } from './model/Card';
import { BusinessError } from '@kit.BasicServicesKit';
import { Constants, LogUtils, sharedPreferencesUtils } from '@ohos/common';
import { systemSoundManager } from '@kit.AudioKit';
import { media } from '@kit.MediaKit';
import fs from '@ohos.file.fs';
import { image } from '@kit.ImageKit';

const TAG: string = 'VideoRingtoneHandler';

const MEDIA_TYPE_VIDEO: number = 1;

export const ERROR_TOAST_TIME = 2000;
export const KEY_DUPLICATE_NUMBER = 'duplicate_number';
export const DUPLICATE_ERROR_MESSAGE = 'I/O error, duplicate file name';

export enum VideoSetErrorType {
  VIDEO_SET_ERROR_MAX_SIZE = 20700004,
  VIDEO_SET_ERROR_LIMIT_COUNT = 20700005,
  VIDEO_SET_ERROR_NO_SPACE = 20700006,
  VIDEO_SET_ERROR_IO = 5400103
}

class VideoRingtoneHandler {

  private static readonly INDEX_FD = 1;
  private static readonly INDEX_PATH = 0;
  private static readonly INVALID_FD = -1;

  getUsePath(path: string): string {
    // 反转字符串
    let reversedPath = path.split('').reverse().join('');
    // 初始化计数器和索引
    let count = 0;
    let index = -1;
    // 遍历反转后的字符串，查找斜杠
    for (let i = 0; i < reversedPath.length; i++) {
      if (reversedPath[i] === '/') {
        count += 1;
        if (count === 3) {
          index = i;
          break;
        }
      }
    }
    // 如果找到了第三个斜杠，计算其在原始字符串中的位置
    if (index !== -1) {
      let originalIndex = path.length - index - 1;
      let part2 = path.slice(originalIndex);
      return part2;
    } else {
      return '';
    }
  }

  public async readVideoRingtoneDataSection(simCard: string, videoRingtoneSource: number, contactsPath: string) {
    let cardList: Card[] = [];
    LogUtils.i(TAG, 'readVideoRingtoneDataSection videoRingtoneSource:' + videoRingtoneSource);
    if (videoRingtoneSource == Constants.VIDEO_RINGTONE_SOURCE_CONTACT) {
      if (!StringUtil.isEmpty(contactsPath)) {
        await VideoRingtoneHandler.handleContactVideoRingtoneData( contactsPath, cardList);
      }
      return cardList;
    }
    let videoRingtoneDataSp: string = Constants.VIDEO_RINGTONE_DATA_SP + simCard;
    let videoRingtoneHistoryArrayStr: string = '';
    let videoRingtoneData: string = '';
    try {
      videoRingtoneData = await sharedPreferencesUtils.getFromPreferences(videoRingtoneDataSp, '') as string;
      let videoRingtoneHistoryArraySp: string = Constants.VIDEO_RINGTONE_HISTORY_DATA_SP + simCard;
      videoRingtoneHistoryArrayStr = await sharedPreferencesUtils
        .getFromPreferences(videoRingtoneHistoryArraySp, '') as string;
    } catch (e) {
      LogUtils.e(TAG, 'readVideoRingtoneDataSection e: ' + JSON.stringify(e));
    }
    LogUtils.i(TAG, 'readVideoRingtoneDataSection videoRingtoneDataSp:' + videoRingtoneDataSp +
      ' videoRingtoneData:' + videoRingtoneData);
    if (StringUtil.isEmpty(videoRingtoneData)) {
      LogUtils.e(TAG, 'readVideoRingtoneDataSection videoRingtoneData is empty');
    } else {
      await VideoRingtoneHandler.handleVideoRingtoneData(simCard, videoRingtoneData, cardList);
    }
    if (StringUtil.isEmpty(videoRingtoneHistoryArrayStr)) {
      LogUtils.e(TAG, 'readVideoRingtoneDataSection videoRingtoneHistory is empty');
    } else {
      await VideoRingtoneHandler.handleHistoryVideoRingtoneData(simCard, videoRingtoneHistoryArrayStr, cardList);
    }
    LogUtils.i(TAG, 'readVideoRingtoneDataSection cardList filteredArray:' + cardList.length);
    return cardList;
  }

  public async getHistoryVideoRingtoneData(simCard: string): Promise<string[]> {
    let historyVideoRingtoneList: string[] = [];
    try {
      let videoRingtoneHistoryArraySp: string = Constants.VIDEO_RINGTONE_HISTORY_DATA_SP + simCard;
      let videoRingtoneHistoryArrayStr = await sharedPreferencesUtils
        .getFromPreferences(videoRingtoneHistoryArraySp, '') as string;
      historyVideoRingtoneList = StringUtil.stringToArray(videoRingtoneHistoryArrayStr);
      LogUtils.i(TAG, 'getHistoryVideoRingtoneData historyVideoRingtoneListStr:' + videoRingtoneHistoryArrayStr +
        ' params length : ' + historyVideoRingtoneList.length);
      historyVideoRingtoneList.reverse();
    } catch (e) {
      LogUtils.e(TAG, `getHistoryVideoRingtoneData error :${e}`);
    }
    return historyVideoRingtoneList;
  }

  // 创建视频缩略图
  private static async createThumbnailFromVideo(fileFd: number): Promise<image.PixelMap | undefined> {
    let imagePixel: undefined | PixelMap = undefined;
    try {
      LogUtils.i(TAG, 'createThumbnailFromVideo is called');
      let avImageGenerator: media.AVImageGenerator = await media.createAVImageGenerator();
      avImageGenerator.fdSrc = { fd: fileFd };
      let timeUs = 0
      let queryOption = media.AVImageQueryOptions.AV_IMAGE_QUERY_NEXT_SYNC
      let param: media.PixelMapParams = {
        colorFormat: media.PixelFormat.RGBA_8888,
      }
      imagePixel = await avImageGenerator.fetchFrameByTime(timeUs, queryOption, param);
      avImageGenerator.release()
      fs.closeSync(fileFd)
    } catch (e) {
      LogUtils.e(TAG, `createThumbnailFromVideo catch exception: ${JSON.stringify(e)}`)
    }
    return imagePixel;
  }

  private static async handleDuration(fileFd: number): Promise<string> {
    let duration = '';
    try {
      let avMetadataExtractor = await media.createAVMetadataExtractor();
      let avFileDescriptor: media.AVFileDescriptor = { fd: fileFd };
      avMetadataExtractor.fdSrc = avFileDescriptor;
      // 获取媒体元数据
      let metadata = await avMetadataExtractor.fetchMetadata();
      duration = metadata.duration as string;
    } catch (e) {
      LogUtils.e(TAG, 'handleDuration fail error:' + JSON.stringify(e));
    }
    return duration;
  }

  private static async handleContactVideoRingtoneData(videoRingtoneData: string, cardList: Card[]) {
    try {
      LogUtils.i(TAG, 'handleContactVideoRingtoneData');
      let sysSoundManagerInstance: systemSoundManager.SystemSoundManager = systemSoundManager.getSystemSoundManager();
      let result = await sysSoundManagerInstance.openToneList([videoRingtoneData]);
      if (result.length < 1) {
        return;
      }
      let param = result[0];
      if (param[VideoRingtoneHandler.INDEX_FD] === VideoRingtoneHandler.INVALID_FD) {
        return;
      }
      let fd = param[VideoRingtoneHandler.INDEX_FD];
      let duration = await VideoRingtoneHandler.handleDuration(fd);
      let pixMap = await VideoRingtoneHandler.createThumbnailFromVideo(fd);
      let card: Card = new Card({
        displayImagePath: param[VideoRingtoneHandler.INDEX_PATH],
        applyData: param[VideoRingtoneHandler.INDEX_PATH],
        ignoreTimeStamp: false,
        isInUse: true,
        fileFd: fd,
        thumbnail: pixMap,
        videoDuration:duration
      });
      cardList.push(card);
    } catch (e) {
      LogUtils.e(TAG, `handleContactVideoRingtoneData error :${e}`);
    }
  }

  private static async handleVideoRingtoneData(simCard: string, videoRingtoneData: string, cardList: Card[]) {
    try {
      LogUtils.i(TAG, 'handleVideoRingtoneData videoRingtoneData : ' + videoRingtoneData);
      let sysSoundManagerInstance: systemSoundManager.SystemSoundManager = systemSoundManager.getSystemSoundManager();
      let result = await sysSoundManagerInstance.openToneList([videoRingtoneData]);
      let toneAttr: systemSoundManager.ToneAttrs =
        await sysSoundManagerInstance.getCurrentRingtoneAttribute(simCard === Constants.CARD1_VALUE ?
        systemSoundManager.RingtoneType.RINGTONE_TYPE_SIM_CARD_0 :
        systemSoundManager.RingtoneType.RINGTONE_TYPE_SIM_CARD_1)
      if (result.length < 1) {
        return;
      }
      let param = result[0];
      if (param[VideoRingtoneHandler.INDEX_FD] === VideoRingtoneHandler.INVALID_FD &&
        toneAttr.getMediaType() !== MEDIA_TYPE_VIDEO) {
        VideoRingtoneHandler.removeUnUseFulUriToSp(simCard)
        return;
      }
      let fd = param[VideoRingtoneHandler.INDEX_FD];
      let duration = await VideoRingtoneHandler.handleDuration(fd);
      let pixMap = await VideoRingtoneHandler.createThumbnailFromVideo(fd);
      let card: Card = new Card({
        displayImagePath: param[VideoRingtoneHandler.INDEX_PATH],
        applyData: param[VideoRingtoneHandler.INDEX_PATH],
        ignoreTimeStamp: false,
        isInUse: toneAttr.getMediaType() === MEDIA_TYPE_VIDEO,
        fileFd: fd,
        thumbnail: pixMap,
        videoDuration:duration
      });
      cardList.push(card);
    } catch (e) {
      LogUtils.e(TAG, `readVideoRingtoneDataSection error :${e}`);
    }
  }

  private static async handleHistoryVideoRingtoneData(simCard: string, historyVideoRingtoneListStr: string,
    cardList: Card[]) {
    try {
      let historyVideoRingtoneList: string[] = [];
      let unUsedVideoRingtone: string[] = [];
      historyVideoRingtoneList = StringUtil.stringToArray(historyVideoRingtoneListStr);
      LogUtils.i(TAG, 'handleHistoryVideoRingtoneData historyVideoRingtoneListStr:' + historyVideoRingtoneListStr +
        ' params length : ' + historyVideoRingtoneList.length);
      historyVideoRingtoneList.reverse();
      let sysSoundManagerInstance: systemSoundManager.SystemSoundManager = systemSoundManager.getSystemSoundManager();
      let result = await sysSoundManagerInstance.openToneList(historyVideoRingtoneList);
      for (let index = 0; index < result.length; index++) {
        let param = result[index];
        LogUtils.i(TAG, 'handleHistoryVideoRingtoneData fd = ' + param[VideoRingtoneHandler.INDEX_FD]);
        if (param[VideoRingtoneHandler.INDEX_FD] === VideoRingtoneHandler.INVALID_FD) {
          unUsedVideoRingtone.push(param[VideoRingtoneHandler.INDEX_PATH])
        } else {
          let fd = param[VideoRingtoneHandler.INDEX_FD];
          let duration = await VideoRingtoneHandler.handleDuration(fd);
          let pixMap = await VideoRingtoneHandler.createThumbnailFromVideo(fd);
          let card: Card = new Card({
            displayImagePath: param[VideoRingtoneHandler.INDEX_PATH],
            applyData: param[VideoRingtoneHandler.INDEX_PATH],
            historyIndex: index,
            fileFd: fd,
            thumbnail: pixMap,
            videoDuration:duration
          });
          cardList.push(card);
        }
      }
      if (unUsedVideoRingtone.length > 0) {
        VideoRingtoneHandler.removeUnUsefulUriFromHistory(simCard, unUsedVideoRingtone);
      }
    } catch (e) {
      LogUtils.e(TAG, `handleHistoryVideoRingtoneData error :${e}`);
    }
  }

  async saveUriListToSp(videoUri: string, simCard: string) {
    let videoRingtoneDataSp: string = Constants.VIDEO_RINGTONE_DATA_SP + simCard;
    LogUtils.i(TAG, 'saveUriListToSp videoUri:' + videoUri + ' videoRingtoneDataSp :' + videoRingtoneDataSp);
    // 读取首选项的历史铃声
    let lastVideoRingtoneData: string = await sharedPreferencesUtils
      .getFromPreferences(videoRingtoneDataSp, '') as string;
    if (StringUtil.isEmpty(lastVideoRingtoneData)) {
      LogUtils.e(TAG, 'saveUriListToSp videoRingtoneData is empty or equal');
    }
    if (!this.compareVideoRingtonePath(lastVideoRingtoneData, videoUri)) {
      await this.saveUriListToHistorySp(lastVideoRingtoneData, videoUri, simCard);
    }
    await sharedPreferencesUtils.saveToPreferences(videoRingtoneDataSp, videoUri);
    LogUtils.i(TAG, `saveUriListToSp lastVideoRingtoneData:${lastVideoRingtoneData}, videoUri:${videoUri}`);
  }

  // 判断当前视频是否呗其他卡所引用，如果被引用则只删除缓存的uri， 不删除铃音库中的视频文件， 最后一个删除引用的时候再删除视频文件
  async checkPathContainOnAnotherCard(simCard: string, path: string): Promise<boolean> {
    LogUtils.i(TAG, `checkPathContainOnAnotherCard is called`);
    try {
      let otherSimCard: string = simCard === Constants.CARD1_VALUE ? Constants.CARD2_VALUE : Constants.CARD1_VALUE;
      let videoRingtoneDataSp: string = Constants.VIDEO_RINGTONE_DATA_SP + otherSimCard;
      let videoRingtoneData: string =
        await sharedPreferencesUtils.getFromPreferences(videoRingtoneDataSp, '') as string;
      LogUtils.i(TAG, `checkPathContainOnAnotherCard videoRingtoneData is ${videoRingtoneData}`);
      if (videoRingtoneData.includes(path)) {
        return true;
      }
      let videoRingtoneHistoryArraySp: string = Constants.VIDEO_RINGTONE_HISTORY_DATA_SP + otherSimCard;
      let videoRingtoneHistoryArrayStr =
        await sharedPreferencesUtils.getFromPreferences(videoRingtoneHistoryArraySp, '') as string;
      LogUtils.i(TAG, `checkPathContainOnAnotherCard videoRingtoneHistoryArrayStr is ${videoRingtoneHistoryArrayStr}`);
      if (videoRingtoneHistoryArrayStr.includes(path)) {
        return true;
      }
    } catch (error) {
      LogUtils.e(TAG, `checkPathContainOnAnotherCard failed. code is ${(error as BusinessError).code}
      message is ${(error as BusinessError).message}`);
    }
    return false;
  }

  private async pushHistoryArray(videoUri: string, videoRingtoneHistoryArrayStr: string,
    videoRingtoneHistoryArray: string[], simCard: string): Promise<string> {
    if (StringUtil.isEmpty(videoUri)) {
      LogUtils.e(TAG, 'pushHistoryArray videoRingtoneData is empty or equal');
    } else {
      if (StringUtil.isEmpty(videoRingtoneHistoryArrayStr)) {
        LogUtils.e(TAG, 'pushHistoryArray videoRingtoneHistoryArrayStr is empty');
        videoRingtoneHistoryArray.push(videoUri);
      } else {
        if (videoRingtoneHistoryArray.length == 5) {
          let deletePath = videoRingtoneHistoryArray[0];
          if (!(await this.checkPathContainOnAnotherCard(simCard, deletePath))) {
            systemSoundManager.getSystemSoundManager()?.removeCustomizedTone(getContext(), deletePath).then((data) => {
              LogUtils.i(TAG, 'deleteVideoRingtoneList result = ' + JSON.stringify(data));
            })
          }
          videoRingtoneHistoryArray.splice(0, 1);
        }
        videoRingtoneHistoryArray.push(videoUri);
      }
    }
    return StringUtil.arrayToString(videoRingtoneHistoryArray);
  }

  async saveUriListToHistorySp(lastVideoRingtoneData: string, videoUri: string, simCard: string) {
    let videoRingtoneHistoryArray: string[] = [];
    let videoRingtoneHistoryArrayStr: string = '';
    let videoRingtoneHistoryArraySp: string = Constants.VIDEO_RINGTONE_HISTORY_DATA_SP + simCard;
    videoRingtoneHistoryArrayStr = await sharedPreferencesUtils
      .getFromPreferences(videoRingtoneHistoryArraySp, '') as string;
    LogUtils.w(TAG, 'saveUriListToHistorySp videoRingtoneHistoryArrayStr : ' + videoRingtoneHistoryArrayStr);
    if (StringUtil.isEmpty(videoRingtoneHistoryArrayStr)) {
      LogUtils.e(TAG, 'saveUriListToSp videoRingtoneHistoryArrayStr is empty');
    } else {
      videoRingtoneHistoryArray = StringUtil.stringToArray(videoRingtoneHistoryArrayStr);
    }
    // 如果选择的铃音是历史铃声
    let isHistoryVideoRingtone: boolean = false;
    let isHistoryVideoRingtoneIndex: number = -1;
    videoRingtoneHistoryArray.forEach((videoRingtoneHistory: string, index: number) => {
      LogUtils.w(TAG, 'saveUriListToSp videoRingtoneData videoRingtoneHistory : ' +
        videoRingtoneHistory + ' lastVideoRingtoneData :' + lastVideoRingtoneData + ' index: ' + index);
      if (this.compareVideoRingtonePath(videoRingtoneHistory, videoUri)) {
        isHistoryVideoRingtone = true;
        isHistoryVideoRingtoneIndex = index;
      }
    })
    LogUtils.w(TAG, 'saveUriListToSp videoRingtoneData isHistoryVideoRingtoneIndex : ' +
      isHistoryVideoRingtoneIndex + ' isHistoryVideoRingtone :' + isHistoryVideoRingtone);
    if (isHistoryVideoRingtone) {
      videoRingtoneHistoryArray.splice(isHistoryVideoRingtoneIndex, 1);
    }
    videoRingtoneHistoryArrayStr = await this.pushHistoryArray(lastVideoRingtoneData,
      videoRingtoneHistoryArrayStr, videoRingtoneHistoryArray, simCard);
    await sharedPreferencesUtils.saveToPreferences(videoRingtoneHistoryArraySp, videoRingtoneHistoryArrayStr);
  }

  private static async removeUnUseFulUriToSp(simCard: string) {
    LogUtils.i(TAG, 'removeUnUsedUriToSp is called');
    let videoRingtoneDataSp: string = Constants.VIDEO_RINGTONE_DATA_SP + simCard;
    await sharedPreferencesUtils.saveToPreferences(videoRingtoneDataSp, '');
  }

  private static async removeUnUsefulUriFromHistory(simCard: string, unUsedVideoRingtone: string[]) {
    LogUtils.i(TAG, 'removeUnUsefulUriFromHistory is called');
    let videoRingtoneHistoryArray: string[] = [];
    let videoRingtoneHistoryArraySp: string = Constants.VIDEO_RINGTONE_HISTORY_DATA_SP + simCard;
    let videoRingtoneHistoryArrayStr: string = await sharedPreferencesUtils
      .getFromPreferences(videoRingtoneHistoryArraySp, '') as string;
    if (StringUtil.isEmpty(videoRingtoneHistoryArrayStr)) {
      LogUtils.e(TAG, 'removeUnUsefulUriFromHistory videoRingtoneHistoryArrayStr is empty');
      return;
    } else {
      videoRingtoneHistoryArray = StringUtil.stringToArray(videoRingtoneHistoryArrayStr);
    }
    unUsedVideoRingtone.forEach((videoUri: string, index: number) => {
      let indexNumber = videoRingtoneHistoryArray.indexOf(videoUri)
      videoRingtoneHistoryArray.splice(indexNumber, 1);
    })
    videoRingtoneHistoryArrayStr = StringUtil.arrayToString(videoRingtoneHistoryArray);
    await sharedPreferencesUtils.saveToPreferences(videoRingtoneHistoryArraySp, videoRingtoneHistoryArrayStr);
  }

  removeElementsByIndices(array: string[], indices: number[]): string[] {
    let result: string[] = [...array];
    indices.sort((a, b) => b - a);
    for (const index of indices) {
      if (index >= 0 && index < result.length) {
        result.splice(index, 1);
      }
    }
    return result;
  }

  compareVideoRingtonePath(path1: string, path2: string): boolean {
    if (StringUtil.isEmpty(path1) || StringUtil.isEmpty(path2)) {
      LogUtils.e(TAG, `compareVideoRingtonePath path1 or path2 is empty`);
      return false;
    }
    if (StringUtil.isEmpty(this.getUsePath(path1)) || StringUtil.isEmpty(this.getUsePath(path2))) {
      LogUtils.e(TAG, `compareVideoRingtonePath getUsePath path1 or path2 is empty`);
      return false;
    }
    path1 = this.getUsePath(path1);
    path2 = this.getUsePath(path2);
    if (path1 == path2) {
      LogUtils.i(TAG, 'compareVideoRingtonePath getUsePath path1 equal path2');
      return true;
    }
    return false;
  }
}

// Singleton
export default new VideoRingtoneHandler();
/**
 * Copyright (c) 2024-2025 Huawei Device Co., Ltd.
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
import fs from '@ohos.file.fs';
import LogUtils from './LogUtils';
import { ArrayList, taskpool } from '@kit.ArkTS';
import { media } from '@kit.MediaKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { BusinessError } from '@ohos.base'

/**
 * 波形图数据保存录音文件中的一些常量数据
 */
export class SampleDataConstant {
  public static readonly LEN_HEAD_TOTAL_LENGTH: number = 4;
  public static readonly LEN_HEAD_UUID: number = 4;
  public static readonly LEN_HEAD_UUID_AFTER: number = 16;
  public static readonly LEN_BODY_END_LENGTH: number = 4;
  public static readonly LEN_BODY_END_TAG: number = 4;
  public static readonly SAMPLE_LEN: number = 2;
  public static readonly UUID: string = 'uuid';
  public static readonly UUID_AFTER: number[] = [0x0, 0x0, 0x0, 0x0];
  public static readonly END_TAG: number[] = [0xFF, 0xFF, 0xFF, 0xFF];
  public static readonly RECORD_FILE_SUFFIX: string = '.m4a'; // 录音文件后缀
  public static readonly SAMPLE_FILE_SUFFIX: string = '.tmp'; // 临时保存波形数据的文件后缀
  // 每秒多少个采样数据
  public static readonly SAMPLES_PRE_SECOND: number = 6;
  // 振幅值转波形值的比例
  public static AMPLITUDE_TO_WAVE_RATE: number = 140;
  // 波形图文件的最大大小为200M，录制时长大约为1846小时
  public static readonly MAX_WAVE_FILE_SIZE = 200 * 1024 * 1024;
  public static readonly DATA_TIME_INTERVAL = 320;
  public static readonly SMALL_AMPLITUDE = 500;
}

function getTailDataLength(): number {
  return SampleDataConstant.LEN_BODY_END_LENGTH + SampleDataConstant.LEN_BODY_END_TAG;
}

function getHeadDataLength(): number {
  return SampleDataConstant.LEN_HEAD_TOTAL_LENGTH + SampleDataConstant.LEN_HEAD_UUID +
  SampleDataConstant.LEN_HEAD_UUID_AFTER;
}

const TAG = 'CallRecorder_SampleUtil';

export class SampleUtil {
  private recordStartTime: number = 0;
  private sampleTimerId: number = 0;
  // 采样后的振幅数据
  private realTimeSamples: ArrayList<number> = new ArrayList();

  /**
   * 构建波形图数据的字节数组
   *
   * @param samples 波形数据
   * @returns DataView
   */
  private buildWaveSampleBytes(samples: number[]): DataView {
    LogUtils.i(TAG, 'buildWaveSampleBytes start. Samples length: ' + samples.length);
    let headLen: number = getHeadDataLength();
    let sampleDataLen: number = samples.length * 2;
    let tailDataLen: number = getTailDataLength();
    let totalLen: number = headLen + sampleDataLen + tailDataLen;
    let buffer: ArrayBuffer = new ArrayBuffer(totalLen);
    let dataView: DataView = new DataView(buffer);
    let offset: number = 0;
    // total length
    dataView.setInt32(offset, totalLen, false);
    offset += SampleDataConstant.LEN_HEAD_TOTAL_LENGTH;
    // uuid
    for (let i = 0; i < SampleDataConstant.UUID.length; i++) {
      dataView.setInt8(offset + i, SampleDataConstant.UUID.charCodeAt(i));
    }
    offset += SampleDataConstant.LEN_HEAD_UUID;
    // 16 bytes: 0x00 0x00 0x00 0x00
    for (let i = 0; i < SampleDataConstant.UUID_AFTER.length; i++) {
      dataView.setInt32(offset + i * 4, SampleDataConstant.UUID_AFTER[i]);
    }
    offset += SampleDataConstant.LEN_HEAD_UUID_AFTER;
    // raw samples
    for (let sample of samples) {
      dataView.setInt16(offset, sample, true);
      offset += SampleDataConstant.SAMPLE_LEN;
    }
    // body length
    let bodyLen: number = sampleDataLen + tailDataLen;
    dataView.setInt32(offset, bodyLen, true);
    offset += SampleDataConstant.LEN_BODY_END_LENGTH;
    // end mark
    for (let i = 0; i < SampleDataConstant.END_TAG.length; i++) {
      dataView.setInt8(offset + i, SampleDataConstant.END_TAG[i]);
    }
    LogUtils.i(TAG, 'buildWaveSampleBytes end. DataView bytes length: ' + dataView.byteLength);
    return dataView;
  }

  /**
   * 将波形数据写入到录音文件
   *
   * @param path 录音文件路径
   * @param samples 波形数据
   */
  writeWaveSamplesToFile(path: string, samples: number[]): void {
    LogUtils.i(TAG, 'writeWaveSamplesToFile start. Samples length: ' + samples.length);
    let buffer: ArrayBuffer = this.buildWaveSampleBytes(samples).buffer;
    let fileStat: fs.Stat | BusinessError = this.statSync(path);
    if (fileStat instanceof Error) {
      return;
    }
    let fileFd: number = -1;
    let result: number = -1;
    try {
      fileFd = fs.openSync(path, fs.OpenMode.WRITE_ONLY).fd;
      result = fs.writeSync(fileFd, buffer, {
        offset: fileStat.size
      });
      LogUtils.i(TAG, 'writeWaveSamplesToFile end. Result: ' + result);
    } catch (e) {
      LogUtils.e(TAG, `failed to get duration, code: ${e.code}, message: ${e.message}`);
    } finally {
      fs.closeSync(fileFd);
    }
  }

  private statSync(file: string): fs.Stat | BusinessError {
    try {
      return fs.statSync(file);
    } catch (e) {
      LogUtils.e(TAG, `fs stat error, code: ${e.code}, message: ${e.message}`);
      return e;
    }
  }

  /**
   * 保存采样数据到录音文件中
   *
   * @param currentFilePath 录音文件路径
   */
  public async trySaveSamples(currentFilePath: string) {
    // AVRecorder销毁后停止获取振幅的定时器
    this.stopAmplitudeTimer();
    LogUtils.i(TAG, 'trySaveSamples start.');
    if (currentFilePath !== '') {
      let realTimeSamples = this.getInterpolateData();
      // AVRecorder结束需要销毁资源等，状态切换没有上层UI那么迅速，所以最好再检查下时间和采样数据是否对应，不对应则增加些波形数据
      let samples: number[] = await this.fixSamples(currentFilePath, realTimeSamples);
      this.writeWaveSamplesToFile(currentFilePath, samples);
      LogUtils.i(TAG, 'trySaveSamples success.');
    }
    this.realTimeSamples.clear();
    LogUtils.i(TAG, 'trySaveSamples end.');
  }

  /**
   * 开启振幅定时器
   */
  public startAmplitudeTimer(avRecorder: media.AVRecorder): void {
    LogUtils.i(TAG, 'Amplitude Timer start.');
    if (this.sampleTimerId) {
      LogUtils.i(TAG, 'Amplitude Timer already start.');
      return;
    }
    this.sampleTimerId = setInterval(() => {
      if (avRecorder?.state !== 'started') {
        return;
      }
      this.getAmplitude(avRecorder);
    }, SampleDataConstant.DATA_TIME_INTERVAL);
  }

  /**
   * 获取单次的振幅（会在绘制中频繁调用，不打印日志）
   *
   */
  private getAmplitude(avRecorder: media.AVRecorder): void {
    if (avRecorder?.state == 'started') {
      avRecorder?.getAudioCapturerMaxAmplitude().then((amplitude: number) => {
        this.realTimeSamples.add(amplitude);
      })
    }
  }

  /**
   * 停止获取振幅的定时器
   */
  private stopAmplitudeTimer(): void {
    if (this.sampleTimerId) {
      clearInterval(this.sampleTimerId);
      this.sampleTimerId = 0;
    }
  }

  /**
   * 按照录音文件的录音时长，对采样数据的Size进行“修正”
   * 多余的采样将进行缩减，缺少的采样将进行增补
   *
   * @param path
   * @param samples
   * @returns
   */
  async fixSamples(path: string, samples: number[]): Promise<number[]> {
    // 拿到确切的录音时长
    let audioDuration: number = await this.getDuration(path);
    LogUtils.i(TAG, `fix samples, audioDuration: ${audioDuration}`);
    // 期望的采样数据长度
    const expectSize = Math.ceil(audioDuration / 1000 * SampleDataConstant.SAMPLES_PRE_SECOND);
    try {
      const task =
        new taskpool.Task('FIX_SAMPLES', fixSamples, TAG, samples, expectSize, SampleDataConstant.SMALL_AMPLITUDE);
      samples = await taskpool.execute(task) as number[];
    } catch (e) {
      LogUtils.e(TAG, `failed to fix samples, code: ${e.code}, message: ${e.message}`);
      return samples;
    }
    return samples;
  }

  /**
   * 获取时长
   * @param path
   * @returns
   */
  private async getDuration(path: string): Promise<number> {
    let fileFd = -1;
    let duration = 0;
    try {
      const extractor = await media.createAVMetadataExtractor();
      fileFd = fs.openSync(path, fs.OpenMode.READ_ONLY).fd;
      extractor.fdSrc = {
        fd: fileFd
      };
      const metaData = await extractor.fetchMetadata();
      duration = Number(metaData.duration ?? 0);
    } catch (e) {
      LogUtils.e(TAG, `failed to get duration, code: ${e.code}, message: ${e.message}`);
    } finally {
      fs.closeSync(fileFd);
    }
    return duration;
  }

  /**
   * 插值振幅数据
   * @returns
   */
  private getInterpolateData(): number[] {
    let interpolateData: number[] = [];
    for (let i = 0; i < this.realTimeSamples.length; i++) {
      interpolateData.push(this.realTimeSamples[i]);
      if (i < this.realTimeSamples.length - 1) {
        // 用平均值进行插值
        let avgData = (this.realTimeSamples[i] + this.realTimeSamples[i + 1]) / 2;
        interpolateData.push(avgData);
      }
    }
    return interpolateData;
  }
}

@Concurrent
function fixSamples(tag: string, samples: number[], expectSize: number, smallAmplitude: number): number[] {
  let samplesSize = samples.length;
  let diffSize = expectSize - samplesSize;
  LogUtils.i(tag, `fix samples start, expectSize: ${expectSize}, samplesSize: ${samplesSize}, diffSize: ${diffSize}`);
  if (diffSize === 0) {
    return samples;
  }
  if (diffSize > 0) {
    // 扩增样本
    if (samples.length === 0 || diffSize > samples.length / 3) {
      // 采样数据为0或采样差值大于采样数据的三分之一，补充每个差值为500（小振幅标准值）
      samples.push(...Array(diffSize).fill(smallAmplitude));
    } else {
      // 其他情况： // 把采样数据分成 差值+1 分，每份的最后一个值后插入一个值（每份的最后一个值后一位的值）
      let step = Math.floor(samples.length / (diffSize + 1));
      for (let i = 0; i < diffSize; i++) {
        let insertIndex = Math.min((i + 1) * step + i, expectSize - 1);
        // 插入前后的平均值保持平滑性
        let average = (samples[insertIndex - 1] + samples[insertIndex]) / 2;
        samples.splice(insertIndex, 0, average);
      }
    }
  } else {
    // 缩减样本
    diffSize = Math.abs(diffSize);
    // 把采样数据分成 差值+1 份，删除掉每份的最后一个值
    let step = Math.floor(samples.length / (diffSize + 1));
    // 从后往前删避免索引错位
    for (let i = diffSize; i > 0; i--) {
      let removeIndex = Math.min(i * step + (i - 1), expectSize - 1);
      if (removeIndex >= 0 && removeIndex < samples.length) {
        samples.splice(removeIndex, 1);
      }
    }
  }
  samplesSize = samples.length;
  diffSize = expectSize - samplesSize;
  LogUtils.i(tag, `fix samples end, expectSize: ${expectSize}, samplesSize: ${samplesSize}, diffSize: ${diffSize}`);
  return samples;
}


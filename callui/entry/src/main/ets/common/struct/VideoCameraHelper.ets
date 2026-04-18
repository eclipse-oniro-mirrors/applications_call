/**
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
import camera from '@ohos.multimedia.camera';
import common from '@ohos.app.ability.common';

import VideoCameraStatus from './VideoCameraStatus';
import * as Constants from '../utils/Constants';
import LogUtils from '../utils/LogUtils';
import { BusinessError } from '@ohos.base';
import { GlobalContextHelper } from '../utils/GlobalContextHelper';
import { DisplayUtil } from '../utils/DisplayUtil';
import display from '@ohos.display';
import { ExternalCallModel } from '../../model/ExternalCallModel';

const TAG = 'VideoCameraHelper';


export default class VideoCameraHelper {
  private static sInstance: VideoCameraHelper;
  //Camera Status
  public static CAMERA_STATE_INVALID: number = -1;
  public static CAMERA_STATE_OPEN: number = 0;
  public static CAMERA_STATE_MANUAL_CLOSED: number = 1;
  public static CAMERA_STATE_CLOSED: number = 2;
  public frontCameraId: string = '';
  public backCameraId: string = '';

  private constructor() {
  }

  public static getInstance(): VideoCameraHelper {
    if (!VideoCameraHelper.sInstance) {
      VideoCameraHelper.sInstance = new VideoCameraHelper();
    }
    return VideoCameraHelper.sInstance;
  }

  public getCurrentCameraId() {
    const videoCameraInfo: undefined | VideoCameraStatus = AppStorage.get('videoCameraInfo');
    LogUtils.i(TAG, `getCurrentCameraId,videoCameraInfo:${JSON.stringify(videoCameraInfo)}`);
    if (videoCameraInfo && videoCameraInfo.currentCameraId) {
      return videoCameraInfo.currentCameraId;
    }
    return this.frontCameraId;
  }

  public saveVideoCameraInfo(callid: number, cameraId: string, isClose: boolean) {
    let videoCameraInfo: VideoCameraStatus = {
      callId: callid,
      currentCameraId: cameraId,
      isCameraClose: isClose
    }
    AppStorage.setOrCreate('videoCameraInfo', videoCameraInfo);
  }

  /**
   * clear video camera info during videoToVoice and call disconnected.
   */
  public clearVideoCameraInfo() {
    AppStorage.delete('videoCameraInfo');
  }

  public getVideCameraInfo(): VideoCameraStatus | undefined {
    return AppStorage.get('videoCameraInfo');
  }

  /**
   *
   * @param status The new status
   * @param safe If true, we'll ignore the OPEN state if camera was manual closed
   */
  public updateCameraStatus(status: number, safe: boolean = false): void {
    let cameraStatus: number | undefined = AppStorage.get('cameraState');

    if (safe && status == VideoCameraHelper.CAMERA_STATE_OPEN &&
      cameraStatus === VideoCameraHelper.CAMERA_STATE_MANUAL_CLOSED) {
      return;
    }

    if (cameraStatus !== status) {
      AppStorage.setOrCreate('cameraState', status);
    }
  }

  public getCameraStatus(): number | undefined {
    return AppStorage.get('cameraState');
  }

  public getCameraIds() {
    if (this.frontCameraId !== '' && !DisplayUtil.isFoldable() && !ExternalCallModel.isSmallExternalDevice()) {
      return;
    }
    try {
      let cameraManager: camera.CameraManager = camera.getCameraManager(GlobalContextHelper.getContext()
        .getValue<common.UIAbilityContext>(Constants.CALL_ABILITY_CONTEXT));
      const cameraList = cameraManager.getSupportedCameras();
      LogUtils.i(TAG, 'cameraList:' + cameraList?.length);

      this.backCameraId = this.findCameraIndex(cameraList, camera.CameraPosition.CAMERA_POSITION_BACK).toString();
      this.frontCameraId = this.findCameraIndex(cameraList, camera.CameraPosition.CAMERA_POSITION_FRONT).toString();

      LogUtils.i(TAG, `frontCameraId:${this.frontCameraId},backCameraId:${this.backCameraId}`);
    } catch (error) {
      let err = error as BusinessError;
      LogUtils.e(TAG, `The getSupportedCameras call failed. error code: ${err.code}`);
    }
  }

  findCameraIndex(cameraList: Array<camera.CameraDevice>, position: camera.CameraPosition): number {
    if (!cameraList) {
      return -1;
    }
    return cameraList.findIndex((val) => val.cameraPosition === position);
  }
}

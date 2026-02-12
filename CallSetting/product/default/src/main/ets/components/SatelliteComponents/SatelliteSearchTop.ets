/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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
  SatelliteDirection,
  SYS_STATUS_DEFAULT,
  SYS_STATUS_SATELLITE_CONNECTING,
  SYS_STATUS_SEARCHING_SATELLITE,
  SYS_STATUS_SEARCH_SATELLITE_FAIL,
  SYS_STATUS_SEARCH_SATELLITE_SUCC,
  SYS_STATUS_WAIT_CALIBRATING,
  SYS_STATUS_WAIT_LOADING,
  SYS_STATUS_WAIT_BLOCKING,
  SENDING_TIME,
  RECEIVER_STATUS_RECEIVING,
  SEND_STATUS_SUCC,
  SEND_STATUS_SENT,
  RECEIVER_STATUS_SUCCESS,
  RECEIVER_STATUS_NULL,
  SEND_STATUS_FAIL,
  RECEIVER_STATUS_FAIL,
  SatelliteOperationType,
  SatelliteLevel,
  SatelliteEvent,
  SEND_RECEIPT_COUNTDOWN_TIMER,
  CLOSE_DIALOG_DELAY,
  MAX_QUANTITY_TO_RECEIVE,
  SYS_STATUS_SATELLITE_KEEPING,
  MAX_FONT_SCALE,
  HALF_WAIT_STATE_TIME_CACTUS
} from '../../common/constant/SatelliteSearchConst';
import { LogUtils, ReportUtil } from '@ohos/common/CommonIndex';
import SatelliteUtils from '../../common/utils/SatelliteUtils';
import AlertDialogManager from '../../manager/AlertDialogManager';
import SatelliteSearchManager, { SatelliteData } from '../../manager/SatelliteSearchManager';
import { curves, LengthMetrics } from '@kit.ArkUI';
import { ability, UIExtensionContentSession } from '@kit.AbilityKit';
import { StringUtil } from '../../common/utils/StringUtil';
import { getVisibilityByTextOp, isPhone, isSupportCactus } from '../../common/utils/Utils';
import { hDividedW08 } from '../../common/utils/DisplayUtil';
import { isTablet } from '../../common/utils/DeviceTypeUtils';
import { TrifoldManager } from '../../manager/TrifoldManager';
import { formatResourceToString } from '../../common/utils/formatResourceToString';

const COUNTDOWN_TIMER: number = 1 * 1000;

const TAG = 'SatelliteSearchTop';

@Entry
@Component
export struct SatelliteSearchTop {
  // 页面栈关联的 session
  @Consume('session') session: UIExtensionContentSession;
  // 操作类型：发送/接收
  @Link operationType: string;
  @Link scaleSize: number;
  @Link widthAspectRatio: number;
  @Link from: string;
  @Link @Watch('statusChange') currentStatus: Number;
  @Link @Watch('changeSatelliteData') mSatelliteData: SatelliteData;
  @Link @Watch('getText') isShowOrientationRemind: boolean;
  @Link @Watch('getText') showReConnect: boolean;
  @Link @Watch('getText') showReCalibrate: boolean;
  @Link @Watch('getText') showReSearch: boolean;
  @Link @Watch('getText') mAlertState: number;
  @Link @Watch('handleSatelliteEndStatus') isSatelliteNeedEnd: boolean;
  // 连接超时，自动切换卫星提示语开关
  @Link changeSatelliteOp: number;
  @State oldStatusText: Resource = $r('app.string.device_calibrating')
  @State newStatusText: Resource = $r('app.string.device_calibrating')
  @State oldGuideText: Resource = $r('app.string.device_calibrating_tips')
  @State newGuideText: Resource = $r('app.string.device_calibrating_tips')
  @State oldStatusTextColor: Resource = this.getTextPrimaryColor();
  @State newStatusTextColor: Resource = this.getTextPrimaryColor();
  @State guideAzimuthText: Resource =
    isPhone() ? $r('app.string.left_rotate_phone') : $r('app.string.smc_left_rotate_device');
  @State statusTextColor: Resource = this.getTextPrimaryColor();
  @State oldStatusTextOp: number = 0;
  @State newStatusTextOp: number = 1;
  @State newGuideTextOp: number = 1;
  @State oldGuideTextOp: number = 0;
  @State scaleUI: number = 1;
  @State mDirection: number = SatelliteDirection.NONE;
  @State signalIcon: Resource =
    SatelliteSearchManager.getInstance().getIsFromMeetime() ? $r('app.media.meetime_ic_satellite_signal') :
    $r('app.media.ic_satellite_signal');
  @State signalIconOk: Resource =
    SatelliteSearchManager.getInstance().getIsFromMeetime() ? $r('app.media.meetime_ic_satellite_signal_ok') :
    $r('app.media.ic_satellite_signal_ok');
  @State imageArr: ImageFrameInfo[] = [];
  @State imageDirection: string =
    SatelliteSearchManager.getInstance().getIsFromMeetime() ? 'meetime_tiltLeft' : 'tiltLeft';
  @State mAzimuthDelta: number = 0;
  @State mPitchDelta: number = 0;
  @State mSignal: number = 0;
  @State connectingGuideNumber: number = -1;
  @State connectTime: number = SatelliteSearchManager.getInstance().getIsFromMeetime() ? 0 :
    SatelliteSearchManager.getInstance().getMaxConnectTime();
  @State time: number = SENDING_TIME;
  private satelliteManager: SatelliteSearchManager = SatelliteSearchManager.getInstance();
  private singleOkCubic = curves.cubicBezierCurve(0.33, 0, 0.67, 1);
  private arr: number[] = [0, 1, 2, 3];
  private timerId: number = -1;
  private sateIndex: number = -1;
  private context: Context = {} as Context;
  @State agreementArray: Array<string> = [];
  private textContent: string = '';
  private text: string = '';
  // 发送超时定时器
  private timeOutTimeId: number = -1;
  // 剩余接收条数
  private includeValue: number = 0;
  // 是否结束接收
  private isEndReceive: boolean = false;
  // 异常中断定时器
  private abnormalInterruptionTimeId: number = -1;

  private satelliteConnectTimeCallBack: Function | undefined;
  private isHideSmcSatellitePage: boolean = false;

  startTimer() {
    LogUtils.i(TAG, 'startTimer time: ' + this.satelliteManager.getTime() + ', operationType: ' + this.operationType);
    if (!this.satelliteManager.getTime() || this.satelliteManager.getTime() === 0) {
      this.time = SENDING_TIME;
    } else {
      this.time = this.satelliteManager.getTime();
    }
    this.timerId = setInterval(() => {
      this.time = this.time - 1;
      if (this.operationType === SatelliteOperationType.OPERATION_TYPE_SEND) {
        this.setStatusText($r('app.plural.im_message_status_sending', this.time, this.time),
          $r('sys.color.ohos_id_color_text_primary'));
      } else if (this.operationType === SatelliteOperationType.OPERATION_TYPE_RECEIVE) {
        this.setStatusText($r('app.plural.im_message_smc_receiving', this.time, this.time),
          $r('sys.color.ohos_id_color_text_primary'));
      }
      if (this.time == 0) {
        this.stopTimer();
        this.updateSatelliteTimeOutStatus();

        // 倒计时结束后，把Manager中保存的时间还原成15s
        this.time = SENDING_TIME;
      }
      this.satelliteManager.setTime(this.time);
    }, COUNTDOWN_TIMER);
  }

  stopTimer() {
    clearInterval(this.timerId);
  }

  statusChange() {
    if (SatelliteSearchManager.getInstance().getIsFromMeetime() && this.isSatelliteNeedEnd) {
      LogUtils.i(TAG, 'statusChange is satellite need end.');
      return;
    }
    if (this.currentStatus === SYS_STATUS_SATELLITE_CONNECTING) {
      this.connectTime = this.satelliteManager.getConnectingTime();
    }

    if (this.currentStatus != SYS_STATUS_SEARCH_SATELLITE_SUCC) {
      this.updateSignal(0);
    }
    this.getText();
  }

  aboutToAppear(): void {
    this.scaleUI = this.widthAspectRatio <= hDividedW08 ? this.scaleSize : 1;
    if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      this.context = getContext(this);
      try {
        this.textContent = this.context.resourceManager.getStringSync($r('app.string.im_smc_tips_starfinder_loading'));
        this.text = this.context.resourceManager.getStringSync($r('app.string.im_smc_tips_outdoor_use'));
        this.textContent = this.textContent.replace('%1$s', this.text);
        this.agreementArray = StringUtil.concatenateStringArray(this.text, this.textContent);
      } catch (err) {
        LogUtils.e(TAG, 'privacy and copyRight show error.');
      }
    }
    if (this.currentStatus == SYS_STATUS_SATELLITE_CONNECTING) {
      this.connectTime = this.satelliteManager.getConnectingTime();
    }
    this.getText();
    this.changeSatelliteData();
    // 设置接收数据回调
    this.setReceiveDataCallback();
    this.addSatelliteConnectTimeCallback();
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear.');
    if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      this.isEndReceive = false;
      this.stopTimer();
      this.stopSendingTimeOut();
      clearTimeout(this.abnormalInterruptionTimeId);
      SatelliteSearchManager.getInstance().setIsFromMeetime(false);

      // 关闭寻星监听
      SatelliteSearchManager.getInstance().closeMeetimeSatelliteListener()
      SatelliteSearchManager.getInstance().finishMeetimeSatellite();
    }
    this.removeSatelliteConnectTimeCallback();
  }

  private setReceiveDataCallback(): void {
    if (!SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      return;
    }
    this.session?.setReceiveDataCallback((data: Record<string, Object>) => {
      if (this.isEndReceiveData(data)) {
        return;
      }
      LogUtils.i(TAG, 'setReceiveDataCallback action: ' + data.action + ', includeValue: ' + data.includeValue);
      if (data.action === SatelliteOperationType.OPERATION_TYPE_SEND_SUCCESS) {
        this.isEndReceive = true;
        this.currentStatus = SEND_STATUS_SUCC;
        this.getOtherText();
        this.satelliteManager.setCurrentStatus(SEND_STATUS_SUCC);
        this.setSendingTimeOut(SatelliteEvent.EVENT_SENDING_COMPLETED, SEND_RECEIPT_COUNTDOWN_TIMER);
      } else if (data.action === SatelliteOperationType.OPERATION_TYPE_SENT) {
        this.isEndReceive = true;
        this.currentStatus = SEND_STATUS_SENT;
        this.getOtherText();
        this.satelliteManager.setCurrentStatus(SEND_STATUS_SENT);
        this.setSendingTimeOut(SatelliteEvent.EVENT_SENDING_COMPLETED, SEND_RECEIPT_COUNTDOWN_TIMER);
      } else if (data.action === SatelliteOperationType.OPERATION_TYPE_SEND_FAIL) {
        this.isEndReceive = true;
        this.currentStatus = SEND_STATUS_FAIL;
        this.getOtherText();
        this.satelliteManager.setCurrentStatus(SEND_STATUS_FAIL);
        this.setSendingTimeOut(SatelliteEvent.EVENT_SENDING_COMPLETED, SEND_RECEIPT_COUNTDOWN_TIMER);
      } else if (data.action === SatelliteOperationType.OPERATION_TYPE_RECEIVE_SUCCESS) {
        this.isEndReceive = true;
        this.includeValue = data.includeValue as number;
        this.currentStatus = RECEIVER_STATUS_SUCCESS;
        this.getOtherText();
        this.satelliteManager.setCurrentStatus(RECEIVER_STATUS_SUCCESS);
        this.setSendingTimeOut(SatelliteEvent.EVENT_RECEIVING_COMPLETED, SEND_RECEIPT_COUNTDOWN_TIMER);
      } else if (data.action === SatelliteOperationType.OPERATION_TYPE_RECEIVE_FAIL) {
        this.isEndReceive = true;
        this.currentStatus = RECEIVER_STATUS_FAIL;
        this.satelliteManager.setCurrentStatus(RECEIVER_STATUS_FAIL);
        this.setSendingTimeOut(SatelliteEvent.EVENT_RECEIVING_COMPLETED, CLOSE_DIALOG_DELAY);
      } else if (data.action === SatelliteOperationType.OPERATION_TYPE_RECEIVE_NULL) {
        this.isEndReceive = true;
        this.currentStatus = RECEIVER_STATUS_NULL;
        this.getOtherText();
        this.satelliteManager.setCurrentStatus(RECEIVER_STATUS_NULL);
        this.setSendingTimeOut(SatelliteEvent.EVENT_RECEIVING_COMPLETED, SEND_RECEIPT_COUNTDOWN_TIMER);
      } else {
        this.handleSysStatus(data);
      }
    });
  }

  private isEndReceiveData(data: Record<string, Object>): boolean {
    if (!data) {
      LogUtils.e(TAG, 'isEndReceiveData data is invalid.');
      return true;
    }
    if (this.isEndReceive) {
      LogUtils.i(TAG, 'isEndReceiveData end receive.');
      return true;
    }
    if (this.isSatelliteNeedEnd && this.operationType === SatelliteOperationType.OPERATION_TYPE_SEND) {
      LogUtils.i(TAG, 'isEndReceiveData abnormal interruption receive.');
      // 发送北斗卫星消息的过程中异常中断，需要显示畅连发送过来的相关状态(已发送或发送失败)，同时需要将异常中断的timer清除
      clearTimeout(this.abnormalInterruptionTimeId);
      return false;
    }
    if (data.action !== SatelliteOperationType.OPERATION_TYPE_SEND_SUCCESS &&
      data.action !== SatelliteOperationType.OPERATION_TYPE_SENT &&
      data.action !== SatelliteOperationType.OPERATION_TYPE_RECEIVE_SUCCESS &&
      data.action !== SatelliteOperationType.OPERATION_TYPE_RECEIVE_NULL && this.isSatelliteNeedEnd) {
      LogUtils.i(TAG, 'isEndReceiveData is satellite need end.');
      return true;
    }
    return false;
  }

  private handleSysStatus(data: Record<string, Object>): void {
    if (data.action === SatelliteOperationType.OPERATION_TYPE_SYS_STATUS_SEARCHING) {
      let expireTime: number = data.includeValue as number;
      SatelliteSearchManager.getInstance()
        .updateSearchSatelliteStatus(SatelliteOperationType.OPERATION_TYPE_SYS_STATUS_SEARCHING, expireTime)
    } else if (data.action === SatelliteOperationType.OPERATION_TYPE_SYS_STATUS_SENDING) {
      let expireTime: number = data.includeValue as number;
      SatelliteSearchManager.getInstance()
        .updateSearchSatelliteStatus(SatelliteOperationType.OPERATION_TYPE_SYS_STATUS_SENDING, expireTime)
    } else if (data.action === SatelliteOperationType.OPERATION_TYPE_SYS_STATUS_RECEIVING) {
      let expireTime: number = data.includeValue as number;
      SatelliteSearchManager.getInstance()
        .updateSearchSatelliteStatus(SatelliteOperationType.OPERATION_TYPE_SYS_STATUS_RECEIVING, expireTime)
    } else if (data.action === SatelliteOperationType.OPERATION_TYPE_SYS_STATUS_BLOCKING) {
      let expireTime: number = data.includeValue as number;
      SatelliteSearchManager.getInstance()
        .updateSearchSatelliteStatus(SatelliteOperationType.OPERATION_TYPE_SYS_STATUS_BLOCKING, expireTime)
    } else if (data.action === SatelliteOperationType.OPERATION_TYPE_HIDE_SMC_SATELLITE_PAGE) {
      this.isHideSmcSatellitePage = true;
    } else if (data.action === SatelliteOperationType.OPERATION_TYPE_SYS_STATUS_ANGLE) {
      let values = data.includeValue as string;
      if (values && values.match('_')) {
        let result = values.split('_')
        /* 数组长度为2，result[0]为俯仰角，result[1]为方位角*/
        if (result && result.length >= 2) {
          SatelliteUtils.updateSuccessDelta(Number(result[0]), Number(result[1]));
        }
      }
    } else {
      LogUtils.i(TAG, 'handleSysStatus else branch.');
    }
  }

  //卫星角度信息发生变化
  changeSatelliteData() {
    if (SatelliteSearchManager.getInstance().getIsFromMeetime() && this.isSatelliteNeedEnd) {
      LogUtils.i(TAG, 'changeSatelliteData is satellite need end.');
      return;
    }
    if (this.mSatelliteData == undefined) {
      return;
    }
    if (this.isConTimedOut(this.mSatelliteData)) {
      LogUtils.i(TAG, 'changeSatelliteData stopConnectTimer.');
      SatelliteSearchManager.getInstance().stopConnectTimer();
    }
    this.mAzimuthDelta = this.mSatelliteData.azimuthDelta;
    this.mPitchDelta = this.mSatelliteData.pitchAngleDelta;
    this.mSignal = this.mSatelliteData.signal;
    if (SatelliteSearchManager.getInstance().isUpdateSatelliteData()) {
      if (!SatelliteUtils.checkAzimuthOk(this.mAzimuthDelta) || !SatelliteUtils.checkPitchOk(this.mPitchDelta)) {
        let safeAzimuthDelta: number = SatelliteUtils.getSuccessAzimuth();
        let safePitchDelta: number = SatelliteUtils.getSuccessPitch();
        if (this.mAzimuthDelta > safeAzimuthDelta) {
          this.updateDirection(SatelliteDirection.RIGHT);
          //todo 开始左右的
          this.buildImgArr('tiltRight');
        } else if (this.mAzimuthDelta < -safeAzimuthDelta) {
          this.updateDirection(SatelliteDirection.LEFT);
          this.buildImgArr('tiltLeft');
        } else if (this.mPitchDelta > safePitchDelta) {
          this.updateDirection(SatelliteDirection.UP);
          this.buildImgArr('tiltUp');
        } else if (this.mPitchDelta < -safePitchDelta) {
          this.updateDirection(SatelliteDirection.DOWN);
          this.buildImgArr('tiltDown');
        }
      } else {
        this.updateDirection(SatelliteDirection.NONE);
      }
    }
    this.updateSignal(this.mSignal);
  }

  private isConTimedOut(satelliteData: SatelliteData): boolean {
    if (!SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      return false;
    }
    if (!satelliteData) {
      LogUtils.e(TAG, 'isConTimedOut satelliteData is null.');
      return false;
    }
    let sateIdx: number = satelliteData.sateIdx;
    if (sateIdx == SatelliteLevel.SATELLITE_LEVEL_LOW || sateIdx == SatelliteLevel.SATELLITE_LEVEL_MEDIUM ||
      sateIdx == SatelliteLevel.SATELLITE_LEVEL_HIGH) {
      if (this.sateIndex === -1) {
        this.sateIndex = sateIdx;
        LogUtils.i(TAG, 'isConTimedOut first sateIndex.');
      } else if (this.sateIndex !== sateIdx) {
        LogUtils.i(TAG, 'isConTimedOut change satellite.');
        this.sateIndex = sateIdx;
        return true;
      }
    }
    return false;
  }

  // 给direction 赋值
  updateDirection(direction: number) {
    if (this.mDirection != direction) {
      this.mDirection = direction;
      this.updateStatusAndGuideTextForSuccess();
      this.getAzimuthText();
    }
  }

  //刷新信号
  updateSignal(signal: number) {
    if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      if (signal !== this.mSignal) {
        this.mSignal = signal;
      }
    } else {
      if (this.currentStatus != SYS_STATUS_SEARCH_SATELLITE_SUCC) {
        if (this.mSignal != 0) {
          LogUtils.i(TAG, 'updateSignal status != SYS_STATUS_SEARCH_SATELLITE_SUCC');
          this.mSignal = 0;
        }
      } else if (this.currentStatus == SYS_STATUS_SEARCH_SATELLITE_SUCC && signal != this.mSignal) {
        LogUtils.i(TAG, 'updateSignal status == SYS_STATUS_SEARCH_SATELLITE_SUCC signal = ' + signal);
        this.mSignal = signal;
      }
    }
  }

  // 更新向左先转，向右旋转提示语
  getAzimuthText() {
    if (this.mDirection == SatelliteDirection.NONE) {
      return;
    }
    if (this.mDirection == SatelliteDirection.LEFT) {
      this.guideAzimuthText = isPhone() ? $r('app.string.left_rotate_phone') : $r('app.string.smc_left_rotate_device');
    } else if (this.mDirection == SatelliteDirection.RIGHT) {
      this.guideAzimuthText =
        isPhone() ? $r('app.string.right_rotate_phone') : $r('app.string.smc_right_rotate_device');
    } else if (this.mDirection == SatelliteDirection.UP) {
      this.guideAzimuthText = isPhone() ? $r('app.string.upper_tilt_phone') : $r('app.string.im_smc_lift_device');
    } else if (this.mDirection == SatelliteDirection.DOWN) {
      this.guideAzimuthText = isPhone() ? $r('app.string.lower_tilt_phone') : $r('app.string.im_smc_lower_device');
    }
  }

  updateStatusAndGuideTextForSuccess() {
    if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      return;
    }
    if (this.currentStatus == SYS_STATUS_SEARCH_SATELLITE_SUCC) {
      if (this.mDirection != SatelliteDirection.NONE) {
        this.setStatusText($r('app.string.device_offset_reminder'), this.getTextPrimaryColor());
      } else {
        this.setStatusText($r('app.string.satellite_hunt_success'), this.getTextPrimaryColor());
      }
    }
  }

  getText() {
    LogUtils.i(TAG, 'getText currentStatus: ' + this.currentStatus);
    if (this.showReConnect) {
      this.getReConnectText();
      return;
    }
    if (this.showReCalibrate) {
      this.setStatusText(SatelliteSearchManager.getInstance().getIsFromMeetime() ?
      $r('app.string.im_smc_calibrate_failed') : $r('app.string.device_calibrate_failed'), this.getWarningColor());
      this.setGuideText(SatelliteSearchManager.getInstance().getIsFromMeetime() ?
      $r('app.string.im_message_smc_shake') :
      $r('app.string.device_calibrating_fail_tips'));
      return;
    }
    if (this.showReSearch) {
      this.setStatusText($r('app.string.satellite_search_failed'), this.getWarningColor());
      return;
    }
    let island = isTablet() || TrifoldManager.getInstance().isTrifold();
    if (this.isShowOrientationRemind && !island) {
      this.setStatusText($r('app.string.landscape_reminder'), this.getTextPrimaryColor());
      return;
    } else if (this.isShowOrientationRemind && island) {
      this.setStatusText($r('app.string.portrait_reminder'), this.getTextPrimaryColor());
      return;
    }
    if (this.currentStatus == SYS_STATUS_SEARCH_SATELLITE_SUCC) {
      this.getSatelliteSucText();
    } else if (this.currentStatus == SYS_STATUS_WAIT_BLOCKING) {
      this.setStatusText($r('app.string.satellite_search'), this.getTextPrimaryColor());
      try {
        this.textContent = this.context.resourceManager.getStringSync($r('app.string.im_smc_tips_starfinder_blocking'));
        this.text = this.context.resourceManager.getStringSync($r('app.string.im_smc_tips_outdoor_blocking'));
        this.textContent = this.textContent.replace('%1$s', this.text);
        this.agreementArray = StringUtil.concatenateStringArray(this.text, this.textContent);
      } catch (err) {
        LogUtils.e(TAG, 'privacy and copyRight show error.');
      }
    } else if (this.currentStatus == SYS_STATUS_WAIT_LOADING) {
      this.setStatusText($r('app.string.satellite_search'), this.getTextPrimaryColor());
      this.setGuideText($r('app.string.satellite_search_tips'));
    } else if (this.currentStatus == SYS_STATUS_WAIT_CALIBRATING) {
      this.setStatusText($r('app.string.device_calibrating'), this.getTextPrimaryColor());
      this.setGuideText($r('app.string.device_calibrating_tips'));
    } else if (this.currentStatus == SYS_STATUS_SEARCHING_SATELLITE) {
      this.setStatusText($r('app.string.satellite_alignment'), this.getTextPrimaryColor());
    } else if (this.currentStatus == SYS_STATUS_SATELLITE_CONNECTING) {
      this.changeSatelliteOp = 0;
      this.setStatusText(SatelliteSearchManager.getInstance().getIsFromMeetime() ?
      $r('app.plural.im_message_smc_connecting', this.connectTime, this.connectTime) :
      this.getWaitStateCountData(),
        this.getTextPrimaryColor());
      this.updateConnectingGuideText();
    } else {
      this.getOtherText();
    }
  }

  getReConnectText() {
    this.oldStatusText = this.getWaitStateCountData();
    this.newStatusText = $r('app.string.satellite_hunt_failed');

    this.oldStatusTextColor = this.getTextPrimaryColor();
    this.newStatusTextColor = this.getWarningColor();
    this.startStatusTextAnimation();

    if (this.connectingGuideNumber === 0) {
      this.oldGuideText = $r('app.string.keep_current_posture_wait_patiently');
    } else if (this.connectingGuideNumber === 1) {
      this.oldGuideText = $r('app.string.keep_current_posture');
    } else if (this.connectingGuideNumber === 2) {
      this.oldGuideText = $r('app.string.keep_current_posture_check_occlusion');
    }
    this.newGuideText = $r('app.string.satellite_hunt_timeout');
    this.startGuideTextAnimation();
  }

  getSatelliteSucText() {
    if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      this.startTimer();
      if (this.operationType === SatelliteOperationType.OPERATION_TYPE_SEND) {
        this.setStatusText($r('app.plural.im_message_status_sending', this.time, this.time),
          $r('sys.color.ohos_id_color_text_primary'));
      } else if (this.operationType === SatelliteOperationType.OPERATION_TYPE_RECEIVE) {
        this.setStatusText($r('app.plural.im_message_smc_receiving', this.time, this.time),
          $r('sys.color.ohos_id_color_text_primary'));
      }
      this.setGuideText($r('app.string.smc_keep_posture'));
    } else {
      this.setStatusText($r('app.string.satellite_hunt_success'), $r('sys.color.ohos_id_color_text_primary_dark'));
      this.setGuideText($r('app.string.keep_current_posture'));
    }
  }

  getOtherText() {
    if (!SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      return;
    }
    if (this.currentStatus === RECEIVER_STATUS_RECEIVING) {
      this.startTimer();
      this.setStatusText($r('app.plural.im_message_smc_receiving', this.time, this.time), this.getTextPrimaryColor());
      this.setGuideText($r('app.string.smc_keep_posture'));
    } else if (this.currentStatus === SEND_STATUS_SUCC) {
      this.stopSatelliteTimer();
      if (SatelliteSearchManager.getInstance().isOnlyFromMeetime(this.from)) {
        this.setStatusText($r('app.string.send_success'), this.getTextPrimaryColor());
        this.newGuideTextOp = 0;
      } else {
        this.setStatusText($r('app.string.message_status_sent'), this.getTextPrimaryColor());
        this.setGuideText($r('app.string.im_smc_received_satellite_return'));
      }
    } else if (this.currentStatus === SEND_STATUS_SENT) {
      this.stopSatelliteTimer();
      this.setStatusText($r('app.string.message_status_sent'), this.getTextPrimaryColor());
      if (SatelliteSearchManager.getInstance().isOnlyFromMeetime(this.from)) {
        this.setGuideText($r('app.string.im_message_smc_satellite_no_receipt_tips'));
      } else {
        this.newGuideTextOp = 0;
      }
    } else if (this.currentStatus === SEND_STATUS_FAIL) {
      this.stopSatelliteTimer();
      this.setStatusText($r('app.string.send_failed'), $r('sys.color.ohos_id_color_warning'));
      this.newGuideTextOp = 0;
    } else if (this.currentStatus === RECEIVER_STATUS_SUCCESS) {
      this.stopSatelliteTimer();
      this.setStatusText($r('app.string.im_message_smc_receive_success'), this.getTextPrimaryColor());
      let showNum: string;
      if (this.includeValue > MAX_QUANTITY_TO_RECEIVE) {
        showNum = MAX_QUANTITY_TO_RECEIVE + '+';
      } else {
        showNum = this.includeValue + '';
      }
      this.setGuideText($r('app.plural.im_message_smc_to_receive', this.includeValue, showNum));
    } else if (this.currentStatus === RECEIVER_STATUS_FAIL) {
      this.stopSatelliteTimer();
      this.setStatusText($r('app.string.im_message_smc_receive_fail'), $r('sys.color.ohos_id_color_warning'));
      this.newGuideTextOp = 0;
    } else if (this.currentStatus === RECEIVER_STATUS_NULL) {
      this.stopSatelliteTimer();
      this.setStatusText($r('app.string.im_message_smc_no_new_message_to_receive'), this.getTextPrimaryColor());
      this.newGuideTextOp = 0;
    } else if (this.currentStatus === SYS_STATUS_SATELLITE_KEEPING) {
      this.setStatusText($r('app.string.satellite_alignment'), this.getTextPrimaryColor());
      this.setGuideText($r('app.string.smc_keep_posture'));
    } else {
      LogUtils.i(TAG, 'getOtherText else branch.');
    }
  }

  setSendingTimeOut(event: string, delay: number): void {
    this.stopSendingTimeOut();
    this.timeOutTimeId = setTimeout(() => {
      clearTimeout(this.timeOutTimeId);
      if (!StringUtil.isEmpty(event)) {
        LogUtils.i(TAG, 'setSendingTimeOut event: ' + event);
        this.satelliteManager.sendSatelliteEventToMeetime(event);
      }
      // send closeSatelliteDialog action to meetime app
      SatelliteSearchManager.getInstance().sendSatelliteEventToMeetime(SatelliteEvent.EVENT_CLOSE_SATELLITE_DIALOG);
      this.terminateSelfWithResult();
    }, delay)
  }

  stopSendingTimeOut() {
    clearTimeout(this.timeOutTimeId);
  }

  setStatusText(target: Resource, color: Resource) {
    if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      this.newStatusText = target;
      this.newStatusTextColor = color;
      this.oldStatusTextOp = 0;
      this.newStatusTextOp = 1;
    } else {
      this.oldStatusText = this.newStatusText;
      this.newStatusText = target;

      this.oldStatusTextColor = this.newStatusTextColor;
      this.newStatusTextColor = color;
      this.startStatusTextAnimation();
    }
  }

  setGuideText(target: Resource) {
    if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      this.newGuideText = target;
      this.oldGuideTextOp = 0;
      this.newGuideTextOp = 1;
    } else {
      this.oldGuideText = this.newGuideText;
      this.newGuideText = target;
      if (this.currentStatus == SYS_STATUS_SATELLITE_CONNECTING && this.oldGuideText.id == this.newGuideText.id) {
        return;
      }
      this.startGuideTextAnimation();
    }
  }

  startStatusTextAnimation() {
    this.oldStatusTextOp = 1;
    this.newStatusTextOp = 0;
    animateTo({ duration: 200, curve: Curve.Sharp }, () => {
      this.oldStatusTextOp = 0;
      this.newStatusTextOp = 1;
    })
  }

  startGuideTextAnimation() {
    this.oldGuideTextOp = 1;
    this.newGuideTextOp = 0;
    animateTo({ duration: 200, curve: Curve.Sharp }, () => {
      this.oldGuideTextOp = 0;
    })
    animateTo({ duration: 200, curve: Curve.Sharp }, () => {
      this.newGuideTextOp = 1;
    })
  }

  updateConnectingGuideText() {
    if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      this.setGuideText($r('app.string.smc_keep_posture'));
      return;
    }
    if (this.currentStatus == SYS_STATUS_SATELLITE_CONNECTING) {
      let time = Math.trunc((this.connectTime - 1) / 10);
      // there are three remind string show
      switch (time % 3) {
        case 0:
          this.connectingGuideNumber = 0;
          this.setGuideText($r('app.string.keep_current_posture_wait_patiently'));
          break;
        case 1:
          this.connectingGuideNumber = 1;
          this.setGuideText($r('app.string.keep_current_posture'));
          break;
        case 2:
          this.connectingGuideNumber = 2;
          this.setGuideText($r('app.string.keep_current_posture_check_occlusion'));
          break;
        default:
          break;
      }
    }
  }

  buildImgArr(tiltName: string) {
    if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      this.imageDirection = 'meetime_' + tiltName;
    } else {
      this.imageDirection = tiltName;
    }
  }

  getImageArr(tiltName: string) {
    let arr: ImageFrameInfo[] = [];
    for (let i = 1; i < 46; i++) {
      let name = `app.media.${tiltName}${i}`;
      arr.push({ src: $r(name) });
    }
    return arr;
  }

  @Builder
  tiltAnim($$: ImageFrameInfo[]) {
    ImageAnimator()
      .images($$)
      .width(60 * this.scaleUI)
      .height(60 * this.scaleUI)
      .duration(1500)
      .iterations(-1)
      .fillMode(FillMode.None)
      .state(AnimationStatus.Running)
      .margin({top: 6 * this.scaleUI})
      .accessibilityLevel('no')
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.Top }) {
        if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
          this.showSmcCancelBtnLayout();
        } else {
          Row() {
            Button({ type: ButtonType.Circle, stateEffect: true }) {
              Column() {
                SymbolGlyph($r('sys.symbol.arrow_down_right_and_arrow_up_left'))
                  .fontSize('18vp')
                  .fontColor(['#FFFFFF'])
                  .draggable(false);
              }
              .width(40)
              .height(40)
              .alignItems(HorizontalAlign.Center)
              .justifyContent(FlexAlign.Center)
            }
            .id('back_btn')
            .visibility(this.currentStatus == SYS_STATUS_WAIT_LOADING ||
              this.currentStatus == SYS_STATUS_WAIT_CALIBRATING || this.currentStatus == SYS_STATUS_DEFAULT ?
            Visibility.None : Visibility.Visible)
            .onClick((): void => {
              SatelliteSearchManager.getInstance().createFloatWindow();
              ReportUtil.getInstance().reportSatelliteChangeFloatWindow();
            })
            .margin({ top: LengthMetrics.vp(16), end: LengthMetrics.vp(8)})
            .stateStyles({
              pressed: {
                .backgroundColor($r('sys.color.ohos_id_color_click_effect_dark'));
              },
              normal: {
                .backgroundColor($r('sys.color.ohos_id_color_button_normal_dark'));
              }
            })
            .accessibilityText($r('app.string.InfoEdit_back'))

            Button({ type: ButtonType.Circle, stateEffect: true }) {
              Column() {
                SymbolGlyph($r('sys.symbol.xmark'))
                  .fontSize('18vp')
                  .fontColor(['#FFFFFF'])
                  .draggable(false);
              }
              .width(40)
              .height(40)
              .alignItems(HorizontalAlign.Center)
              .justifyContent(FlexAlign.Center)
            }
            .id('close_btn')
            .onClick((): void => {
              AlertDialogManager.getInstance()
                .showDialogByDialogType(AlertDialogManager.TYPE_CLOSE_SATELLITE_TIPS);
            })
            .margin({ top: LengthMetrics.vp(16), end: LengthMetrics.vp(16)})
            .stateStyles({
              pressed: {
                .backgroundColor($r('sys.color.ohos_id_color_click_effect_dark'));
              },
              normal: {
                .backgroundColor($r('sys.color.ohos_id_color_button_normal_dark'));
              }
            })
            .accessibilityText($r('app.string.shut_down'))
          }
          .width('100%')
          .justifyContent(FlexAlign.End)
        }

        // 加载中
        Text(this.oldStatusText)
          .fontSize(24 * this.scaleUI)
          .maxLines(1)
          .height(32 * this.scaleUI)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 16, right: 16, top: 62 * this.scaleUI })
          .textAlign(TextAlign.Center)
          .ellipsisMode(EllipsisMode.END)
          .fontColor(this.oldStatusTextColor)
          .visibility(getVisibilityByTextOp(Boolean(this.oldStatusTextOp)))
          .maxFontScale(MAX_FONT_SCALE)

        // 寻星中
        if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
          Text(this.newStatusText)
            .fontSize(24 * this.scaleUI)
            .fontWeight(FontWeight.Medium)
            .margin({ left: 16, right: 16, top: 62 * this.scaleUI })
            .textAlign(TextAlign.Center)
            .ellipsisMode(EllipsisMode.END)
            .fontColor(this.newStatusTextColor)
            .visibility(getVisibilityByTextOp(Boolean(this.newStatusTextOp)))
            .maxFontScale(MAX_FONT_SCALE)
        } else {
          Text(this.newStatusText)
            .fontSize(24 * this.scaleUI)
            .maxLines(1)
            .height(32 * this.scaleUI)
            .fontWeight(FontWeight.Medium)
            .margin({ left: 16, right: 16, top: 62 * this.scaleUI })
            .textAlign(TextAlign.Center)
            .ellipsisMode(EllipsisMode.END)
            .fontColor(this.newStatusTextColor)
            .visibility(getVisibilityByTextOp(Boolean(this.newStatusTextOp)))
            .maxFontScale(MAX_FONT_SCALE)
        }
      }
      .width('100%')

      //信号
      Row() {
        if (this.mAlertState != 0) {
          Text($r('app.string.satellite_enhance_status'))
            .fontSize('10vp')
            .fontWeight(FontWeight.Medium)
            .fontColor(this.getTextPrimaryColor())
            .textAlign(TextAlign.Center)
            .backgroundColor('#ED6F21')
            .padding({ left: 8, right: 8 })
            .height(22 * this.scaleUI)
            .borderRadius('14vp')
            .maxFontScale(MAX_FONT_SCALE)
        } else {
          Text($r('app.string.satellite_signal'))//信号强度
            .fontSize(16 * this.scaleUI)
            .fontWeight(FontWeight.Regular)
            .fontColor(this.getTextSecondaryColor())
            .maxFontScale(MAX_FONT_SCALE)
          ForEach(this.arr, (item: number) =>{
            Stack() {
              Image(this.signalIcon)
                .width(8 * this.scaleUI)
                .height(12 * this.scaleUI)
                .margin({ left: 2 })
                .draggable(false)
              if (this.mSignal > item) {
                Image(this.signalIconOk)
                  .width(8 * this.scaleUI)
                  .height(12 * this.scaleUI)
                  .margin({ left: 2 })
                  .draggable(false)
                  .transition(TransitionEffect.OPACITY.animation({
                    duration: 200,
                    curve: this.singleOkCubic
                  }))
              }
            }
          })
        }
      }
      .height(SatelliteSearchManager.getInstance().getIsFromMeetime() ? 21 * this.scaleUI : 22 * this.scaleUI)
      .margin({ top: 8 * this.scaleUI })
      .visibility(this.currentStatus == SYS_STATUS_WAIT_LOADING || this.currentStatus == SYS_STATUS_WAIT_BLOCKING ||
        this.currentStatus == SYS_STATUS_WAIT_CALIBRATING ||
        this.currentStatus == SYS_STATUS_DEFAULT ? Visibility.Hidden : Visibility.Visible)
      .accessibilityGroup(true)

      if (SatelliteSearchManager.getInstance().getIsFromMeetime() &&
        (this.currentStatus == SYS_STATUS_SEARCH_SATELLITE_SUCC || this.currentStatus == RECEIVER_STATUS_RECEIVING)) {
        this.showBestSatelliteLayout();
      }
      Stack({ alignContent: Alignment.Top }) {
        if (this.currentStatus == SYS_STATUS_SEARCHING_SATELLITE ||
          (this.currentStatus == SYS_STATUS_SEARCH_SATELLITE_SUCC && this.mDirection != SatelliteDirection.NONE)) {
          this.showDirectionImageLayout();
        }
        if (this.currentStatus != SYS_STATUS_SEARCHING_SATELLITE &&
          !(this.currentStatus == SYS_STATUS_SEARCH_SATELLITE_SUCC && this.mDirection != SatelliteDirection.NONE)) {
          this.showGuidTextLayout();
        }
      }
      .visibility(this.isShowOrientationRemind ? Visibility.None : Visibility.Visible)
    }
    .width('100%')
    .height(SatelliteSearchManager.getInstance().getIsFromMeetime() ? '229' : '231.5')
  }

  @Builder
  showGuidTextLayout() {
    Text(this.oldGuideText)
      .fontSize(20 * this.scaleUI)
      .maxFontSize(20)
      .minFontSize(16)
      .maxLines(3)
      .fontWeight(FontWeight.Regular)
      .ellipsisMode(EllipsisMode.END)
      .fontColor(this.getTextPrimaryColor())
      .textAlign(TextAlign.Center)
      .margin({ left: 16, right: 16, top: 16 * this.scaleUI })
      .visibility(getVisibilityByTextOp(Boolean(this.oldGuideTextOp)))
      .maxFontScale(MAX_FONT_SCALE)
    if (SatelliteSearchManager.getInstance().getIsFromMeetime() &&
      (this.currentStatus == SYS_STATUS_WAIT_LOADING || this.currentStatus == SYS_STATUS_WAIT_BLOCKING)) {
      Text() {
        ForEach(this.agreementArray, (item: string) => {
          Span(item)
            .fontColor((item === this.text) ? (this.currentStatus == SYS_STATUS_WAIT_BLOCKING ?
            $r('app.color.MeeTime_orange_light') : $r('app.color.MeeTime_green_light')) : this.getTextPrimaryColor())
        })
      }
      .key('SatelliteSearchTop_New_Guide_Text')
      .fontSize(20 * this.scaleUI)
      .maxLines(3)
      .fontWeight(FontWeight.Regular)
      .ellipsisMode(EllipsisMode.END)
      .fontColor(this.getTextPrimaryColor())
      .textAlign(TextAlign.Center)
      .margin({ left: 16, right: 16, top: 17 * this.scaleUI })
      .opacity(this.newGuideTextOp)
      .maxFontScale(MAX_FONT_SCALE)
    } else {
      Text(this.newGuideText)
        .key('SatelliteSearchTop_New_Guide_Text')
        .fontSize(20 * this.scaleUI)
        .maxFontSize(20)
        .minFontSize(16)
        .maxLines(3)
        .fontWeight(FontWeight.Regular)
        .ellipsisMode(EllipsisMode.END)
        .fontColor(this.getTextPrimaryColor())
        .textAlign(TextAlign.Center)
        .margin({ left: 16, right: 16,
          top: SatelliteSearchManager.getInstance().getIsFromMeetime() ? 17 * this.scaleUI : 16 * this.scaleUI })
        .visibility(getVisibilityByTextOp(Boolean(this.newGuideTextOp)))
        .maxFontScale(MAX_FONT_SCALE)
    }
  }

  @Builder
  showDirectionImageLayout() {
    Column() {
      if (this.imageDirection === 'tiltRight' || this.imageDirection === 'meetime_tiltRight') {
        this.tiltAnim(this.getImageArr(this.imageDirection));
      } else if (this.imageDirection === 'tiltLeft' || this.imageDirection === 'meetime_tiltLeft') {
        this.tiltAnim(this.getImageArr(this.imageDirection));
      } else if (this.imageDirection === 'tiltDown' || this.imageDirection === 'meetime_tiltDown') {
        this.tiltAnim(this.getImageArr(this.imageDirection));
      } else if (this.imageDirection === 'tiltUp' || this.imageDirection === 'meetime_tiltUp') {
        this.tiltAnim(this.getImageArr(this.imageDirection));
      }

      Text(this.guideAzimuthText)
        .key('SatelliteSearchTop_Guide_Azimuth_Text')
        .fontSize(20 * this.scaleUI)
        .maxLines(1)
        .fontWeight(FontWeight.Regular)
        .ellipsisMode(EllipsisMode.END)
        .fontColor(this.getTextPrimaryColor())
        .textAlign(TextAlign.Center)
        .margin({ left: 16, right: 16,
          top: SatelliteSearchManager.getInstance().getIsFromMeetime() ? 4 * this.scaleUI : 5 * this.scaleUI })
        .maxFontScale(MAX_FONT_SCALE)
    }
    .key('SatelliteSearchTop_Direction_Column')
    .margin({ top: SatelliteSearchManager.getInstance().getIsFromMeetime() ? 3 * this.scaleUI : 18.5 * this.scaleUI })
  }

  @Builder
  showBestSatelliteLayout() {
    Text($r('app.string.satellite_best'))
      .key('SatelliteSearchTop_Best_Satellite_Text')
      .fontSize(16 * this.scaleUI)
      .maxLines(1)
      .fontWeight(FontWeight.Regular)
      .ellipsisMode(EllipsisMode.END)
      .fontColor(this.getTextPrimaryColor())
      .textAlign(TextAlign.Center)
      .margin({ left: 16, right: 16, top: 16 * this.scaleUI})
      .maxFontScale(MAX_FONT_SCALE)
  }

  @Builder
  showSmcCancelBtnLayout() {
    Row() {
      Button({ type: ButtonType.Circle, stateEffect: false }){
        SymbolGlyph($r('sys.symbol.xmark'))
          .key('SatelliteSearchTop_Cancel_Image')
          .fontSize('18vp')
          .draggable(false)
          .fontColor([$r('sys.color.ohos_id_color_primary')])
      }
      .key('SatelliteSearchTop_Cancel_Image_Row')
      .height('40vp')
      .width('40vp')
      .margin({ top: LengthMetrics.vp(16), end: LengthMetrics.vp(16) })
      .borderRadius('20vp')
      .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
      .onClick(() => {
        SatelliteSearchManager.getInstance().sendSatelliteEventToMeetime(SatelliteEvent.EVENT_CLICK_CANCEL_SATELLITE);
      })
      .accessibilityText(formatResourceToString($r('app.string.close_button')))
    }
    .key('SatelliteSearchTop_Cancel_Image_Row_Row')
    .width('100%')
    .justifyContent(FlexAlign.End)
  }

  terminateSelfWithResult(): void {
    let result: ability.AbilityResult = {
      'resultCode': 0,
    };
    this.session?.terminateSelfWithResult(result).then((data) => {
      LogUtils.i(TAG, 'terminateSelfWithResult');
    });
  }

  getTextPrimaryColor(): Resource {
    return SatelliteSearchManager.getInstance().getIsFromMeetime() ? $r('sys.color.ohos_id_color_text_primary') :
    $r('sys.color.ohos_id_color_text_primary_dark');
  }

  getTextSecondaryColor(): Resource {
    return SatelliteSearchManager.getInstance().getIsFromMeetime() ? $r('sys.color.ohos_id_color_text_secondary') :
    $r('sys.color.ohos_id_color_text_secondary_dark');
  }

  getWarningColor(): Resource {
    return SatelliteSearchManager.getInstance().getIsFromMeetime() ? $r('sys.color.ohos_id_color_warning') :
    $r('sys.color.ohos_id_color_warning_dark');
  }

  private handleSatelliteEndStatus(): void {
    if (!SatelliteSearchManager.getInstance().getIsFromMeetime()) {
      return;
    }
    if (this.isHideSmcSatellitePage) {
      LogUtils.i(TAG, 'handleSatelliteEndStatus isHideSmcSatellitePage return.');
      this.isHideSmcSatellitePage = false;
      return;
    }
    if (!this.isSatelliteNeedEnd) {
      return;
    }
    LogUtils.i(TAG,
      'handleSatelliteEndStatus operationType: ' + this.operationType + ', currentStatus: ' + this.currentStatus);
    if (this.operationType === SatelliteOperationType.OPERATION_TYPE_SEND) {
      this.handleSatelliteSendEndStatus();
      return;
    }
    if (this.operationType === SatelliteOperationType.OPERATION_TYPE_RECEIVE) {
      if (this.isEndReceive) {
        LogUtils.i(TAG, 'handleSatelliteEndStatus end receive');
        return;
      }
      this.stopSatelliteTimer();
      this.satelliteManager.setCurrentStatus(RECEIVER_STATUS_FAIL);
      this.setStatusText($r('app.string.im_message_smc_receive_fail'), $r('sys.color.ohos_id_color_warning'));
      this.newGuideTextOp = 0;
      this.setSendingTimeOut(SatelliteEvent.EVENT_RECEIVING_COMPLETED, CLOSE_DIALOG_DELAY);
    }
  }

  private handleSatelliteSendEndStatus(): void {
    if (this.isEndReceive) {
      LogUtils.i(TAG, 'handleSatelliteSendEndStatus end receive.');
      return;
    }
    LogUtils.i(TAG, 'handleSatelliteSendEndStatus send EVENT_ABNORMAL_INTERRUPTION.');
    this.satelliteManager.sendSatelliteEventToMeetime(SatelliteEvent.EVENT_ABNORMAL_INTERRUPTION);
    this.abnormalInterruptionTimeId = setTimeout(() => {
      LogUtils.i(TAG, 'handleSatelliteSendEndStatus time out.');
      clearTimeout(this.abnormalInterruptionTimeId);
      // 畅连1s内没有回复，则超时显示发送失败
      this.handleSatelliteSendFailStatus();
    }, COUNTDOWN_TIMER)
  }

  private handleSatelliteSendFailStatus(): void {
    this.stopSatelliteTimer();
    this.satelliteManager.setCurrentStatus(SEND_STATUS_FAIL);
    this.setStatusText($r('app.string.send_failed'), $r('sys.color.ohos_id_color_warning'));
    this.newGuideTextOp = 0;
    this.setSendingTimeOut(SatelliteEvent.EVENT_SENDING_COMPLETED, SEND_RECEIPT_COUNTDOWN_TIMER);
  }

  private stopSatelliteTimer(): void {
    this.stopTimer();
    this.satelliteManager.stopConnectTimer();
  }

  private addSatelliteConnectTimeCallback(): void {
    if (this.satelliteConnectTimeCallBack) {
      LogUtils.i(TAG, 'addSatelliteConnectTimeCallback callback has been added.');
      return;
    }
    this.satelliteConnectTimeCallBack = ((connectTime: number) => {
      LogUtils.i(TAG, 'addSatelliteConnectTimeCallback connectTime: ' + connectTime);
      this.connectTime = connectTime;
      if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
        this.newStatusText = $r('app.plural.im_message_smc_connecting', this.connectTime, this.connectTime);
      } else {
        this.newStatusText = this.getWaitStateCountData();
      }
      this.updateConnectingGuideText();
      if (this.connectTime == 0) {
        if (SatelliteSearchManager.getInstance().getIsFromMeetime()) {
          this.updateSatelliteTimeOutStatus();
        } else {
          this.showReConnect = true;
          SatelliteSearchManager.getInstance().setShowReconnect(true);
          // 倒计时结束后，把状态更新为 FAIL
          this.currentStatus = SYS_STATUS_SEARCH_SATELLITE_FAIL;
          this.satelliteManager.setCurrentStatus(SYS_STATUS_SEARCH_SATELLITE_FAIL);
          // 倒计时结束后，把Manager中保存的时间还原成60s
          this.connectTime = SatelliteSearchManager.getInstance().getMaxConnectTime();
        }
      }
    });
    SatelliteSearchManager.getInstance().addSatelliteConnectTimeCallback(this.satelliteConnectTimeCallBack);
  }

  private removeSatelliteConnectTimeCallback(): void {
    if (this.satelliteConnectTimeCallBack) {
      SatelliteSearchManager.getInstance().removeSatelliteConnectTimeCallback(this.satelliteConnectTimeCallBack);
      this.satelliteConnectTimeCallBack = undefined;
    }
  }

  private getWaitStateCountData(): Resource {
    let res: Resource;
    if (isSupportCactus()) {
      if (this.connectTime > HALF_WAIT_STATE_TIME_CACTUS) {
        res = $r('app.string.satellite_connecting', this.connectTime - HALF_WAIT_STATE_TIME_CACTUS)
      } else {
        res = $r('app.plural.satellite_reconnecting', this.connectTime, this.connectTime);
      }
    } else {
      res = $r('app.string.satellite_connecting', this.connectTime)
    }
    return res;
  }

  private updateSatelliteTimeOutStatus(): void {
    if (this.operationType === SatelliteOperationType.OPERATION_TYPE_SEND) {
      // 倒计时结束后，把状态更新为发送失败
      this.currentStatus = SEND_STATUS_FAIL;
      this.satelliteManager.setCurrentStatus(SEND_STATUS_FAIL);
      this.setSendingTimeOut(SatelliteEvent.EVENT_SENDING_TIME_OUT, SEND_RECEIPT_COUNTDOWN_TIMER);
    } else if (this.operationType === SatelliteOperationType.OPERATION_TYPE_RECEIVE) {
      // 倒计时结束后，把状态更新为接收失败
      this.currentStatus = RECEIVER_STATUS_FAIL;
      this.satelliteManager.setCurrentStatus(RECEIVER_STATUS_FAIL);
      this.setSendingTimeOut(SatelliteEvent.EVENT_RECEIVING_COMPLETED, CLOSE_DIALOG_DELAY);
    } else {
      LogUtils.i(TAG, 'updateSatelliteTimeOutStatus else branch.');
    }
  }
}
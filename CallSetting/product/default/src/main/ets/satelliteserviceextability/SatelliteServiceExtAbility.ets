/*
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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

import { rpc } from '@kit.IPCKit';
import {
  CallSettingGlobalContextHelper,
  Constants,
  LogUtils,
  ReportUtil,
  SatelliteSimCardInfoStruct,
  sharedPreferencesUtils
} from '@ohos/common';
import { common, ServiceExtensionAbility, Want } from '@kit.AbilityKit';
import SatelliteServiceSettingsVM from '../viewModel/SatelliteServiceSettingsVM';
import { settings } from '@kit.BasicServicesKit';
import { window } from '@kit.ArkUI';
import { isTablet } from '../common/utils/DeviceTypeUtils';
import { TrifoldManager } from '../manager/TrifoldManager';
// import vsim from '@hms.telephony.vsim';
import SystemParameterEnhance from '@ohos.systemParameterEnhance';
import { call } from '@kit.TelephonyKit';
import { isSupportRegionCard, saveCarrierType } from '../model/SimManager';
import { insertSatelliteNumber } from '../datashareability/SatelliteDataShare';
import { SATELLITE_KEY_SLOT_ID } from '../common/constant/SatelliteSearchConst';
import { CALL_SETTING_SATELLITE_ABILITY_CONTEXT, SATELLITE_DIALOG_TIPS } from '../common/constant/CallSettingsConstant';
import {
  addSatelliteToggleStateListener,
  insert,
  querySatellite,
  removeSatelliteToggleStateListener
} from '../common/utils/SateToggleStateManager';
import ScreenAdapterUtils from '../common/utils/ScreenAdapterUtils';
import { getAirPlaneMode } from '../model/RegisterStateApiForSatellite';

const TAG = 'SatelliteServiceExtAbility';
const SOS_ABILITY = 'com.ohos.emergencycommunication.SOSEmergencyCallAbility'

class ResultMessage {
  private result: boolean;
  private message: string; // 异常提示
  private errorMessage: string; // 错误提示

  constructor(result: boolean, message: string, errorMessage: string) {
    this.result = result;
    this.message = message;
    this.errorMessage = errorMessage;
  }
}


class SatelliteRpc extends rpc.RemoteObject {
  private readonly INTERFACE_TOKEN = SOS_ABILITY;
  private readonly SATELLITE_STATUS_BEIDOU_WORKING: number = 2;
  private controlSwitch: number = 0;
  private satelliteServiceSettingsVM: SatelliteServiceSettingsVM;
  private context: common.ServiceExtensionContext;

  constructor(des: string, satelliteServiceSettingsVM: SatelliteServiceSettingsVM,
    context: common.ServiceExtensionContext) {
    super(des);
    this.context = context;
    this.satelliteServiceSettingsVM = satelliteServiceSettingsVM;
    this.setSatelliteStateListener();
  }

  private setSatelliteStateListener() {
    LogUtils.i(TAG, 'addSatelliteToggleStateListener');
    addSatelliteToggleStateListener(this.context,
      (data: number) => {
        LogUtils.i(TAG, `Listener: ${data}`);
        if (this.isClosedWhenSosOpen(data)) {
          this.context.terminateSelf();
        }
      });
    querySatellite(this.context,
      (data: number) => {
        LogUtils.i(TAG, 'querySatellite get:' + data);
      });
  }

  private isClosedWhenSosOpen(data: number): boolean {
    return this.controlSwitch === 1 && data === 0;
  }

  private formatResourceToString(resource: Resource) {
    return this.context.resourceManager.getStringSync(resource);
  }

  private async getStartSatelliteResult(): Promise<string> {
    try {
      await this.satelliteServiceSettingsVM.setActiveSimInfoCT();
      let simCardInfoList = this.satelliteServiceSettingsVM.simCardInfoList;
      LogUtils.i(TAG, `getStartSatelliteResult: ${simCardInfoList.length}`);
      let windowMode: number = Number(settings.getValueSync(this.context, 'settings.windowMode', '-1'));
      LogUtils.i(TAG, 'windowMode:' + windowMode);
      // if (windowMode == window.WindowStatusType.SPLIT_SCREEN || windowMode == window.WindowStatusType.FLOATING) {
      //   if (isTablet()) {
      //     this.formatResourceToString($r('app.string.satellite_service_settings_window_suggest'));
      //   }
      //   return this.formatResourceToString($r('app.string.satellite_service_settings_window_mode'));
      // }
      // if (windowMode === window.WindowStatusType.MINIMIZE && isTablet()) {
      //   return this.formatResourceToString($r('app.string.satellite_service_settings_window_suggest'));
      // }
      if (ScreenAdapterUtils.isTrifoldPhone() && !TrifoldManager.getInstance().isTrifold()) {
        return this.formatResourceToString($r('app.string.fold_window_dialog_remind_title'));
      }
      if (simCardInfoList === undefined || simCardInfoList === null || simCardInfoList.length === 0) {
        ReportUtil.getInstance().reportOpenSatelliteCallIssue(Constants.UE_IS_NOT_CTCARD);
        return this.formatResourceToString($r('app.string.satellite_service_no_sim_card_descriptions'));
      }
      if (call.hasCallSync()) {
        ReportUtil.getInstance().reportOpenSatelliteCallIssue(Constants.UE_INCALL);
        return this.formatResourceToString($r('app.string.enter_in_call'));
      }
      let airplaneMode: number = await getAirPlaneMode(this.context);
      LogUtils.i(TAG, 'airplaneMode: ' + airplaneMode);
      if (this.isAirplaneMode(airplaneMode)) {
        ReportUtil.getInstance().reportOpenSatelliteCallIssue(Constants.UE_IN_AIRPLANE);
        return this.formatResourceToString($r('app.string.satellite_service_settings_airplane_mode'));
      }
      // let isVSimOn: boolean = vsim.getVSimStatus().isVSimEnabled;
      // LogUtils.i(TAG, 'isVSimOn: ' + isVSimOn);
      // if (isVSimOn) {
      //   ReportUtil.getInstance().reportOpenSatelliteCallIssue(Constants.UE_TIANJITONG_OPEND);
      //   return this.formatResourceToString($r('app.string.satellite_service_settings_skytone_mode'));
      // }
      let isBeidouWorking: number =
        Number(SystemParameterEnhance.getSync('persist.telephony.satellite.satelliteStatus', '0'));
      LogUtils.i(TAG, 'isBeidouWorking: ' + isBeidouWorking);
      if (isBeidouWorking == this.SATELLITE_STATUS_BEIDOU_WORKING) {
        return this.formatResourceToString($r('app.string.using_beidou_toast'));
      }
      if (await this.isNotStartSatelliteService(simCardInfoList)) {
        return this.formatResourceToString($r('app.string.satellite_service_no_region_card_descriptions'));
      }
    } catch (err) {
      LogUtils.e(TAG, `getStartSatelliteResult error: ${err?.code} ${err?.message}`);
      return `error: ${err?.message}`;
    }
    return 'true';
  }

  private isAirplaneMode(airplaneMode: number): boolean {
    return airplaneMode == 1;
  }

  private async isNotStartSatelliteService(simCardInfoList: SatelliteSimCardInfoStruct[]): Promise<boolean> {
    if (!await this.checkHasSupportRegionCard(simCardInfoList)) {
      ReportUtil.getInstance().reportOpenSatelliteCallIssue(1);
      return true;
    }
    if (this.satelliteServiceSettingsVM.hasTwoCard()) {
      let simInfo = simCardInfoList.find((simInfo: SatelliteSimCardInfoStruct) => simInfo.isChecked === true);
      if (simInfo === undefined) {
        let simInfo: SatelliteSimCardInfoStruct | undefined = await this.getSupportRegionCard(simCardInfoList);
        if (simInfo === undefined) {
          return true;
        }
        this.simCardAccept(simInfo, true);
      } else {
        if (await isSupportRegionCard(simInfo.slotId)) {
          this.satelliteServiceSettingsVM.startSatelliteService(this.context);
        } else {
          return true;
        }
      }
    } else {
      if (this.satelliteServiceSettingsVM.hasOneCard()) {
        let simInfo: SatelliteSimCardInfoStruct = simCardInfoList[0];
        this.simCardAccept(simInfo, false);
      }
    }
    return false;
  }

  private async getSupportRegionCard(simCardInfoList: SatelliteSimCardInfoStruct[]):
    Promise<SatelliteSimCardInfoStruct | undefined> {
    let result: SatelliteSimCardInfoStruct | undefined = undefined;
    for (let i = 0; i < simCardInfoList.length; i++) {
      if (await isSupportRegionCard(simCardInfoList[i].slotId)) {
        return simCardInfoList[i];
      }
    }
    return result;
  }

  private async checkHasSupportRegionCard(simCardInfoList: SatelliteSimCardInfoStruct[]): Promise<boolean> {
    for (let i = 0; i < simCardInfoList.length; i++) {
      if (await isSupportRegionCard(simCardInfoList[i].slotId)) {
        LogUtils.i(TAG, 'checkSupportRegionCard return true');
        return true;
      }
    }
    LogUtils.i(TAG, 'checkSupportRegionCard return false');
    return false;
  }

  private simCardAccept(simInfo: SatelliteSimCardInfoStruct, isPreferences: boolean) {
    LogUtils.i(TAG, `simCardAccept ${simInfo.slotId}`);
    if (isPreferences) {
      simInfo.isPreferences = true;
    }
    let info: string[] = [`${simInfo.slotId}`, `${simInfo.showNumber}`, `${simInfo.isPreferences}`, `${simInfo.iMsi}`];
    sharedPreferencesUtils.init(this.context);
    sharedPreferencesUtils.saveToPreferences(SATELLITE_DIALOG_TIPS.SATELLITE_DIALOG_TIPS, info);
    insertSatelliteNumber(this.context, simInfo.showNumber);
    try {
      settings.setValueSync(this.context, SATELLITE_KEY_SLOT_ID, String(simInfo.slotId));
    } catch (err) {
      LogUtils.e(TAG, `simCardAccept error: ${err?.code} ${err?.message}`);
    }
    saveCarrierType(this.context, simInfo.slotId);
    this.satelliteServiceSettingsVM.startSatelliteService(this.context);
  }

  /*
   * code 1 --- 开
   * code 0 --- 关
   * */
  onRemoteMessageRequest(
    code: number,
    data: rpc.MessageSequence,
    reply: rpc.MessageSequence,
    options: rpc.MessageOption
  ): boolean | Promise<boolean> {
    let token: string = data.readInterfaceToken();
    if (token != this.INTERFACE_TOKEN) {
      return false;
    }
    LogUtils.i(TAG, `onRemoteMessageRequest, code: ${code}, controlSwitch: ${this.controlSwitch}`);
    if (code === this.controlSwitch) {
      reply.writeString(JSON.stringify(new ResultMessage(false, '', 'No action required')));
      return false;
    }
    this.controlSwitch = code;
    if (code === 1) {
      return this.handleOpenTianTongSatelliteSwitch(code, reply);
    } else {
      LogUtils.i(TAG, `onRemoteMessageRequest Value: 0 satelliteType: default`);
      insert(0, this.context);
      reply.writeString(JSON.stringify(new ResultMessage(false, '', '')));
      ReportUtil.getInstance().reportEnterSatelliteCall(2);
      return true;
    }
  }

  private handleOpenTianTongSatelliteSwitch = async (code: number, reply: rpc.MessageSequence) => {
    let data = await this.getStartSatelliteResult();
    LogUtils.i(TAG, `getStartSatelliteResult data is: ${JSON.stringify(new ResultMessage(data === 'true', data, ''))}`);
    reply.writeString(JSON.stringify(new ResultMessage(data === 'true', data, '')));
    ReportUtil.getInstance().reportEnterSatelliteCall(1);
    return true;
  }

  sendMessageRequest(
    code: number,
    data: rpc.MessageSequence,
    reply: rpc.MessageSequence,
    options: rpc.MessageOption
  ): Promise<rpc.RequestResult> {
    return super.sendMessageRequest(code, data, reply, options);
  }
}

export default class SatelliteServiceExtAbility extends ServiceExtensionAbility {
  private satelliteServiceSettingsVM: SatelliteServiceSettingsVM = SatelliteServiceSettingsVM.getInstance();

  onCreate(want: Want) {
    this.satelliteServiceSettingsVM.aboutToAppear();
    LogUtils.i(TAG, `ServiceExtensionAbility onCreate`);
  }

  onRequest(want: Want, startId: number) {
    LogUtils.i(TAG, `ServiceExtensionAbility onRequest`);
  }

  onConnect(want: Want): rpc.RemoteObject | Promise<rpc.RemoteObject> {
    if (want?.parameters === null || want?.parameters === undefined ||
      want.parameters['ohos.aafwk.param.callerAbilityName'] !== SOS_ABILITY) {
      LogUtils.w(TAG, 'The caller does not have the permission to invoke the service.');
      return {} as rpc.RemoteObject;
    }
    CallSettingGlobalContextHelper.getContext()
      .set<common.ServiceExtensionContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT, this.context);
    LogUtils.i(TAG, `ServiceExtensionAbility onConnect`);
    // 返回Stub对象，客户端获取后便可以与ServiceExtensionAbility进行通信
    return new SatelliteRpc('SatelliteServiceExtAbility', this.satelliteServiceSettingsVM, this.context);
  }

  onDisconnect(want: Want) {
    LogUtils.i(TAG, `ServiceExtensionAbility onDisconnect`);
    removeSatelliteToggleStateListener();
  }

  onDestroy() {
    LogUtils.i(TAG, `SatelliteServiceExtAbility onDestroy`);
  }
}
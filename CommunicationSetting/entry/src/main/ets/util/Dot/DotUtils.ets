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
import hiSysEvent from '@ohos.hiSysEvent';
import { BusinessError } from '@ohos.base';
import bundleManager from '@ohos.bundle.bundleManager';
import { LogUtil } from '../LogUtil';
import dotCommon from './DotCommon';
import { AppInfo } from '../../viewmodel/AppInfo';
import { NetworkType } from '../../constants/CommonConstants';
import PageViewModel from '../../viewmodel/PageViewModel';
import { PackageUsageStatus } from '../TrafficPackageUtil';
import { cardInfo } from '../SimCradNameListener';

const TAG = 'DotUtil';
const DOMAIN = 'NETMANAGER_UE';
const PNAMEID = 'com.ohos.communicationsetting';

export default class DotUtil {
  private static instance: DotUtil;
  private isUnitTest: boolean = false;
  public versionNumber: string = '';

  public static getInstance(): DotUtil {
    if (!DotUtil.instance) {
      DotUtil.instance = new DotUtil();
    }
    return DotUtil.instance;
  }

  async updateCommunicationSettingVersion(): Promise<void> {
    if (this.versionNumber !== '') {
      return;
    }
    try {
      let bundleInfo: bundleManager.BundleInfo =
        await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      this.versionNumber = bundleInfo.versionName;
      LogUtil.info(TAG, 'updateCommunicationSettingVersion');
    } catch (err) {
      LogUtil.error(TAG, `err: ${err}`);
    }
  }

  /**
   * 共用行为打点事件
   */
  private publicReportBehaviorEvent(params: Record<string, string | number | boolean | undefined>, eventName: string) {
    try {
      this.updateCommunicationSettingVersion().then(() => {
        params['PNAMEID'] = PNAMEID;
        params['PVERSIONID'] = this.versionNumber;
        let eventInfo: hiSysEvent.SysEventInfo = {
          domain: DOMAIN,
          name: eventName,
          eventType: hiSysEvent.EventType.BEHAVIOR,
          params: params
        };
        if (this.isUnitTest) {
          return;
        }
        hiSysEvent.write(eventInfo).then(
          (_) => {
            LogUtil.info(TAG, `reportBehaviorEvent report success, name is: ${JSON.stringify(eventName)}`);
          }
        ).catch((error: BusinessError) => {
          LogUtil.error(TAG, `reportBehaviorEvent report error, name is: ${JSON.stringify(eventName)}` +
          JSON.stringify(error, ['error', 'message']));
        })
      })
    } catch (error) {
      LogUtil.error(TAG, 'reportBehaviorEvent catch report error' + JSON.stringify(error, ['error', 'message']));
    }
  }

  /**
   * 共用静态打点事件
   */
  private publicReportStatisticEvent(params: Record<string, string | number | boolean | undefined>, eventName: string) {
    try {
      this.updateCommunicationSettingVersion().then(() => {
        params['PNAMEID'] = PNAMEID;
        params['PVERSIONID'] = this.versionNumber;
        let eventInfo: hiSysEvent.SysEventInfo = {
          domain: DOMAIN,
          name: eventName,
          eventType: hiSysEvent.EventType.STATISTIC,
          params: params
        };
        if (this.isUnitTest) {
          return;
        }
        hiSysEvent.write(eventInfo).then(
          (_) => {
            LogUtil.info(TAG, `reportStatisticEvent report success, name is: ${JSON.stringify(eventName)}`);
          }
        ).catch((error: BusinessError) => {
          LogUtil.error(TAG, `reportStatisticEvent report error, name is: ${JSON.stringify(eventName)}` +
          JSON.stringify(error, ['error', 'message']));
        })
      })
    } catch (error) {
      LogUtil.error(TAG, 'reportStatisticEvent catch report error' + JSON.stringify(error, ['error', 'message']));
    }
  }

  dotStatisticDetails(data: AppInfo[], modeSelectedIndexes: number) {
    let tempBundleNames: string[] = [];
    let tempStates: string[] = [];
    let tempFlowList: number[] = [];
    for (let i = 0; i < Math.min(10, data.length); i++) {
      tempBundleNames.push(data[i].bundleName);
      tempFlowList.push(data[i].flow);
      if (modeSelectedIndexes === NetworkType.MOBILE) {
        //流量排行获取移动数据开关静态打点
        tempStates.push(data[i].mobileAccess ? '1' : '2');
      } else {
        //流量排行获取WLAN开关静态打点
        tempStates.push(data[i].wifiAccess ? '1' : '2');
      }
    }
    /**
     * 流量管理页面_流量排行页面_应用联网开关状态前十
     *
     * @param data
     * @param modeSelectedIndexes
     */
    let params1: Record<string, string | number | boolean | undefined> = {
      'BUNDLENAMES': tempBundleNames.toString(),
      'STATES': tempStates.toString()
    };
    this.publicReportStatisticEvent(params1,
      modeSelectedIndexes === NetworkType.MOBILE ? dotCommon.eventName.MOBILE_TOGGLE_STATE :
      dotCommon.eventName.WLAN_TOGGLE_STATE);
    /**
     * 流量管理页面_流量排行页面_流量排行前十
     *
     * @param data
     * @param modeSelectedIndexes
     */
    let params2: Record<string, string | number | boolean | undefined> = {
      'BUNDLENAMES': tempBundleNames.toString(),
      'DATA_FLOWS': tempFlowList.toString()
    };
    this.publicReportStatisticEvent(params2,
      modeSelectedIndexes === NetworkType.MOBILE ? dotCommon.eventName.DATA_USAGE_MOBILEDATA_FLOW_RANK :
      dotCommon.eventName.DATA_USAGE_WLAN_FLOW_RANK);
  }

  /**
   * 流量管理_应用联网移动数据开关切换
   *
   * @param bundleName - app名称
   * @param state - 切换状态
   */
  public reportChangeMobileDataNetworkToggle(bundleName: string, state: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'BUNDLENAME': bundleName,
      'STATE': state
    };
    this.publicReportBehaviorEvent(params, dotCommon.eventName.TOGGLE_MOBILEDATA);
  }

  /**
   * 流量管理_应用联网WLAN开关切换
   *
   * @param bundleName - app名称
   * @param state - 切换状态
   */
  public reportChangeWlanNetworkToggle(bundleName: string, state: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'BUNDLENAME': bundleName,
      'STATE': state
    };
    this.publicReportBehaviorEvent(params, dotCommon.eventName.TOGGLE_WLAN);
  }

  /**
   * 上报点击日已用流量限额提醒事件
   *
   * @param simId - SIM id
   * @param percent - 流量百分比的值
   */
  public reportClickDailyUsedTrafficRemind(simId: number, percent: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'DAILY_PERCENT': percent,
      'SIMID': simId
    };
    this.publicReportBehaviorEvent(params, dotCommon.eventName.CLICK_DAILY_USED_TRAFFIC_REMIND);
  }

  /**
   * 流量管理_限额提醒_点击月已用流量提醒
   *
   * @param simId
   * @param percent
   */
  public reportClickMonthlyTrafficRemind(simId: number, percent: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'MONTHLY_PERCENT': percent,
      'SIMID': simId
    };
    this.publicReportBehaviorEvent(params, dotCommon.eventName.CLICK_MONTHLY_TRAFFIC_REMIND);
  }

  /**
   * 流量管理_限额提醒_月度流量超限时弹窗
   *
   * @param simId
   * @param action
   */
  public reportWhenTrafficExceedDialog(simId: number, action: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'ACTION': action,
      'SIMID': simId
    };
    this.publicReportBehaviorEvent(params, dotCommon.eventName.WHEN_TRAFFIC_EXCEEDS_DIALOG);
  }

  /**
   * 流量管理_限额提醒_点击月度流量超限时
   *
   * @param simId
   */
  public reportClickMonthlyTrafficExceed(simId: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'SIMID': simId
    };
    this.publicReportBehaviorEvent(params, dotCommon.eventName.CLICK_MONTHLY_TRAFFIC_EXCEED);
  }

  /**
   * 流量管理_套餐设置_每月起始日期弹窗
   *
   * @param simId
   * @param action
   * @param data
   */
  public reportStartDataDialog(simId: number, action: number, data: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'ACTION': action,
      'DATE': data,
      'SIMID': simId
    };
    this.publicReportBehaviorEvent(params, dotCommon.eventName.START_DATE_DIALOG);
  }


  /**
   * 流量管理_套餐设置_点击每月起始日期
   *
   * @param simId
   */
  public reportClickStartDateOfMonth(simId: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'SIMID': simId
    };
    this.publicReportBehaviorEvent(params, dotCommon.eventName.CLICK_START_DATA_OF_MONTH);
  }

  /**
   * 流量管理_套餐设置_套餐限额弹窗
   *
   * @param simId
   * @param action
   * @param value
   * @param unit
   */
  public reportPackageQuotaDialog(simId: number, action: number, value: string, unit: string) {
    let params: Record<string, string | number | boolean | undefined> = {
      'ACTION': action,
      'VALUE': value,
      'UNIT': unit,
      'SIMID': simId
    };
    this.publicReportBehaviorEvent(params, dotCommon.eventName.PACKAGE_QUOTA_DIALOG);
  }

  /**
   * 流量管理_套餐设置_点击套餐限额
   *
   * @param simId
   */
  public reportClickPackageQuota(simId: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'SIMID': simId
    };
    this.publicReportBehaviorEvent(params, dotCommon.eventName.CLICK_PACKAGE_QUOTA);
  }

  /**
   * 流量管理_套餐设置_点击无限流量开关
   *
   * @param simId
   * @param status
   */
  public reportClickUnlimitedTrafficToggle(simId: number, status: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'STATUS': status,
      'SIMID': simId
    };
    this.publicReportBehaviorEvent(params, dotCommon.eventName.CLICK_UNLIMITED_TRAFFIC_TOGGLE);
  }

  /**
   * 流量管理_更多流量设置_点击限额提醒
   *
   * @param slotId
   */
  public reportClickQuotaNotification(slotId: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'SLOTID': slotId
    };
    this.publicReportBehaviorEvent(params, dotCommon.eventName.CLICK_QUOTA_NOTIFICATION);
  }

  /**
   * 流量管理_更多流量设置_点击套餐设置
   *
   * @param slotId
   */
  public reportClickPackageSettings(slotId: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'SLOTID': slotId
    };
    this.publicReportBehaviorEvent(params, dotCommon.eventName.CLICK_PACKAGE_SETTINGS);
  }

  /**
   * 流量管理_点击更多流量设置
   */
  public reportClickMoreTrafficSettings() {
    let params: Record<string, string | number | boolean | undefined> = {};
    this.publicReportBehaviorEvent(params, dotCommon.eventName.CLICK_MORE_TRAFFIC_SETTINGS);
  }

  /**
   * 流量管理_停用移动数据弹窗
   *
   * @param action
   */
  public reportDisableMobileDataDialog(action: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'ACTION': action
    };
    this.publicReportBehaviorEvent(params, dotCommon.eventName.DISABLE_MOBILE_DATA_DIALOG);
  }

  /**
   * 流量管理_允许应用使用无线数据弹窗
   *
   * @param action
   */
  public reportAllowWirelessDataDialog(action: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'ACTION': action
    };
    this.publicReportBehaviorEvent(params, dotCommon.eventName.ALLOW_WIRELESS_DATA_DIALOG);
  }

  /**
   * 流量管理_套餐设置_套餐设置页面的状态
   *
   * @param simId
   * @param unlimitedStatus
   * @param quota
   * @param date
   */
  public reportPackageSettingsPageStatus(simId: number, unlimitedStatus: number, quota: string, date: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'UNLIMITED_STATUS': unlimitedStatus,
      'QUOTA': quota,
      'DATE': date,
      'SIMID': simId
    };
    this.publicReportStatisticEvent(params, dotCommon.eventName.PACKAGE_SETTINGS_PAGE_STATUS);
  }

  /**
   * 流量管理_限额提醒_限额提醒页面的状态
   *
   * @param simId
   * @param exceedAction
   * @param monthlyPercent
   * @param dailyPercent
   */
  public reportQuotaNotificationPageStatus(simId: number, exceedAction: number, monthlyPercent: number,
    dailyPercent: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'EXCEED_ACTION': exceedAction,
      'MONTHLY_PERCENT': monthlyPercent,
      'DAILY_PERCENT': dailyPercent,
      'SIMID': simId
    };
    this.publicReportStatisticEvent(params, dotCommon.eventName.QUOTA_NOTIFICATION_PAGE_STATUS);
  }

  /**
   * 流量管理页面_新增获取sim卡和esim卡的标签
   */
  public reportSimLabelFetchStatus(slotId: number) {
    let params: Record<string, string | number | boolean | undefined> = {
      'SLOTID': slotId,
      'SIMTYPE': cardInfo[slotId].isSimCard ? 'PSIM' : 'ESIM',
      'CARDNAME': cardInfo[slotId].slotIndex

    };
    this.publicReportBehaviorEvent(params, dotCommon.eventName.GET_SIMLABEL_AND_INDEX);
  }

  /**
   * 流量管理页面_系统与服务流量排行前三
   *
   * @param sysServiceList
   * @param modeSelectedIndexes
   */
  public reportSystemAndServiceDataRankStatus(sysServiceList: Map<number, number>, modeSelectedIndexes: number) {
    let sysServiceListArray: [number, number][] = Array.from(sysServiceList);
    sysServiceListArray.sort(PageViewModel.sysListCompare);
    let uidList: number[] = [];
    let flowList: number[] = [];
    for (let i = 0; i < Math.min(sysServiceListArray.length, 3); i++) {
      uidList.push(sysServiceListArray[i][0])
      flowList.push(sysServiceListArray[i][1])
    }
    let params: Record<string, string | number | boolean | undefined> = {
      'UID_LIST': uidList.toString(),
      'DATA_FLOWS': flowList.toString()
    };
    if (modeSelectedIndexes === NetworkType.MOBILE) {
      this.publicReportStatisticEvent(params, dotCommon.eventName.SYS_SERVICE_MOBILEDATA_FLOW_RANK);
    } else {
      this.publicReportStatisticEvent(params, dotCommon.eventName.SYS_SERVICE_WLAN_FLOW_RANK);
    }
  }

  /**
   * 流量管理_柱状图
   *
   * @param totalFlow
   * @param startDate
   * @param packageUsageStatus
   * @param flowText
   */
  public reportTotalTrafficDetails(totalFlow: number, startDate: number | undefined,
    packageUsageStatus: PackageUsageStatus, flowText: string[]) {
    let tempStartDate: number = 1;
    if (!startDate) {
      tempStartDate = 1;
    } else {
      tempStartDate = startDate;
    }
    let params: Record<string, string | number | boolean | undefined> = {
      'START_DATE': tempStartDate.toString(),
      'TOTAL_FLOW': totalFlow.toString(),
      'DISPLAY_TYPE': packageUsageStatus.toString(),
      'SPECIFIC_DISPLAY_FLOW': flowText[0] + flowText[1]
    };
    this.publicReportStatisticEvent(params, dotCommon.eventName.DATA_USAGE_BARCHART);
  }

  /**
   * 流量管理_显示流量
   *
   * @param state
   */
  public reportTrafficDisplaySwitchEvent(state: number) {
    let params: Record<string,  number> = {
      'TRAFFIC_SWITCH': state
    };
    this.publicReportBehaviorEvent(params, dotCommon.eventName.CLICK_TRAFFIC_DISPLAY);
  }

  public setUnitTestPropetry() {
    this.isUnitTest = true;
  }
}
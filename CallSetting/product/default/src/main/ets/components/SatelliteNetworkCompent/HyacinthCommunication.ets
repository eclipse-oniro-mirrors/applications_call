/**
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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
import { CustomContentDialog, AlertDialog } from '@ohos.arkui.advanced.Dialog';
import {
  LogUtils,
  ReportUtil,
  SatelliteSimCardInfoStruct,
  CallSettingGlobalContextHelper,
  TitleParams,
  TitleBarLayout
} from '@ohos/common/CommonIndex';
import { getLocation, getString, LocationInter } from '../../common/utils/Utils';
import { ParseXmlUtil, SpanNodeInfo } from '../../common/utils/ParseXmlUtil';
import { common, abilityAccessCtrl } from '@kit.AbilityKit';
import {
  CALL_SETTING_SATELLITE_ABILITY_CONTEXT,
  MAX_TIME_COUNT
} from '../../common/constant/CallSettingsConstant';
import { LengthMetrics, promptAction } from '@kit.ArkUI';
import { DynamicLoader } from '../../common/control/DynamicLoader';
import HyacinthSubItem from './HyacinthSubItem';
import { isTablet } from '../../common/utils/DeviceTypeUtils';
import {
  addSatelliteToggleStateListener,
  getSatelliteModeKey,
  querySatellite,
  querySatelliteWithParam,
  removeSatelliteToggleStateListener
} from '../../common/utils/SateToggleStateManager';
import HyacinthDataShareManager from '../../manager/HyacinthDataShareManager';
import SatelliteServiceSettingsVM from '../../viewModel/SatelliteServiceSettingsVM';
import { HYACINTH_SIM_SHOW_NAME, SatelliteType } from '../../common/constant/SatelliteSearchConst';
import SatelliteSearchManager, { SatUsableTimeInfo } from '../../manager/SatelliteSearchManager';
import { DateUtil, TimeIndex, AcrossDay } from '../../common/utils/DateUtil';
import { util } from '@kit.ArkTS';
import { offOverTimeInfo } from '../../common/model/SatelliteServiceApi';
// import { NavDestination,  HdsNavDestinationAttribute } from '@kit.UIDesignKit';
import ScreenAdapterUtils from '../../common/utils/ScreenAdapterUtils'
import { BusinessError } from '@kit.BasicServicesKit';
import { QueryingOverTimeEnum } from '../SatelliteCommonData'

interface privacyParamType {
  isPrivacyNote: boolean
}

const TAG = 'HyacinthCommunication';
const MINUTE: number = 60;
const HOUR: number = 60 * 60;

@Builder
export function HyacinthCommunicationLoader(): void {
  HyacinthCommunication();
}

@Component
export struct HyacinthCommunication {
  @Consume('pathInfos') pathInfos: NavPathStack;
  @State subId: number = 1;
  @State subTitle: Resource = $r('app.string.hyacinth_satellite_communications');
  @StorageLink('hyacinthSimCardInfoList') @Watch('simCardChange') simCardInfoList: SatelliteSimCardInfoStruct[] = [];
  @StorageLink(HYACINTH_SIM_SHOW_NAME) @Watch('showNameChange') showName: Resource =
    $r('app.string.satellite_service_no_sim_card');
  @State mHyacinthSatelliteService: SatelliteServiceSettingsVM = SatelliteServiceSettingsVM.getInstance(
    SatelliteType.HYACINTH);
  @State title: string = getString($r('app.string.hyacinth_satellite_communications'));
  @State controlSwitch: boolean = false;
  @State nextTime: string = getString($r('app.string.call_setting_getting_hyacinth_available_time')); // 可用时间段提示
  @State satUsableTimeInfo: SatUsableTimeInfo[] = []; // 可用时间段提示
  @State queryingOverTime: boolean = true; // 查询卫星过顶时间中,等待接口返回的标识
  @State simCardInfoTemp: SatelliteSimCardInfoStruct[] = []; // sim卡信息监听变化的临时变量
  @State showNameTemp: string = ''; // showName信息监听变化的临时变量
  @StorageLink('refreshOverTime') @Watch('refreshOverTime') needRefreshOverTime: boolean = false;
  private hyacinthContext = CallSettingGlobalContextHelper.getContext()
    .getValue<common.UIExtensionContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT);
  private scroller: Scroller = new Scroller();
  private nextTimeCount: number = 0; // 已显示的可用时间段数量
  private needRequestNextTime: boolean = true; // 天通半模态窗在风信子界面关闭时请求过顶时间
  private satelliteCommunicationNotification: string = CallSettingGlobalContextHelper.getContext()
    .getValue<common.UIExtensionContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT)?.
    resourceManager.getStringSync($r('app.string.hyacinth_satellite_short_notification_info').id)
  private showInSubWindow: boolean = !ScreenAdapterUtils.isNewFormFoldPhone();

  private hyacinthDataShareManager: HyacinthDataShareManager = HyacinthDataShareManager.getInstance();

  private applyOverTimeCallback: Function = (result: SatUsableTimeInfo[]) => {
    LogUtils.i(TAG, 'applyOverTimeCallback: openOverTimeInfoListener')
    if (!result) {
      LogUtils.e(TAG, 'applyNextTime failed! queryNextOverTime return null.');
      ReportUtil.getInstance().reportHyacinthUncertain();
    }

    for (let i = 0; i < result.length; i++) {
      // 开始时间秒数小于30时显示当前分钟，大于等于30时显示从下一分钟开始
      let startSec = Number(result[i].startTimeList[5]);
      let diffSec = startSec < 30 ? -startSec : 60 - startSec;
      if (result[i].startTime + diffSec >= result[i].endTime) {
        diffSec = -startSec;
      }
      result[i].startTime = result[i].startTime + diffSec;
      result[i].startTimeList = DateUtil.getTimeList(result[i].startTime);
    }

    this.satUsableTimeInfo = result;
    this.nextTimeCount = 0;
    LogUtils.i(TAG, `queryNextOverTime result length: ${result.length}`);
    this.nextTime = '';
    let timeStringArr : string[] = [];
    for (let i = 0; i < result.length; i++) {
      // 最多显示两个时间段
      if (this.nextTimeCount >= MAX_TIME_COUNT) {
        break;
      }
      let info = result[i];
      if (info.startTime === 0 && info.endTime === 0) {
        // 协议接口返回starttime和endtime同时为0..表示失败,文案刷为暂无可用时间
        this.nextTime =
          this.hyacinthContext?.resourceManager.
            getStringSync($r('app.string.hyacinth_satellite_service_no_available_time'));
        break;
      }
      let now = new Date().getTime() / 1000;
      let nowList = DateUtil.getTimeList(now);
      // 已超过结束时间或离结束时间不足两分钟则不显示
      if (now > info.endTime || (info.endTime - now) < (2 * MINUTE)) {
        continue;
      }
      // 处于可用时间段内则记录inSatUsableTIme
      if (now >= info.startTime && now <= info.endTime) {
        SatelliteSearchManager.getInstance().inSatUsableTIme = true;
        // 处于可用时间且剩余可用时间大于3小时提示剩余可用时长
        if ((info.endTime - now) > 3 * HOUR) {
          this.nextTime =
            this.hyacinthContext?.resourceManager.getPluralStringValueSync($r('app.plural.hyacinth_available_time').id,
              Math.round((info.endTime - now) / HOUR)) + ' ';
          break;
        }
      }
      let isAcrossAay : number = AcrossDay.NO_ACROSS;
      // 判断开始时间是否跨天
      if (info.startTimeList[TimeIndex.DAY] !== nowList[TimeIndex.DAY]) {
        isAcrossAay = AcrossDay.START_TIME_ACROSS;
      }
      // 判断结束时间是否跨天
      if (info.startTimeList[TimeIndex.DAY] === nowList[TimeIndex.DAY] && info.endTimeList[TimeIndex.DAY] !==
      nowList[TimeIndex.DAY]) {
        isAcrossAay = AcrossDay.END_TIME_ACROSS;
      }
      let timeString = '';
      if (isAcrossAay === AcrossDay.NO_ACROSS) {
        timeString = util.format(this.hyacinthContext?.resourceManager.
          getStringSync($r('app.string.hyacinth_available_time_today').id,
          `${info.startTimeList[TimeIndex.HOUR]}:${info.startTimeList[TimeIndex.MINUTE]}`,
          `${info.endTimeList[TimeIndex.HOUR]}:${info.endTimeList[TimeIndex.MINUTE]}`));
      } else if (isAcrossAay === AcrossDay.START_TIME_ACROSS) {
        timeString = util.format(this.hyacinthContext?.resourceManager.
          getStringSync($r('app.string.hyacinth_available_time_tomorrow').id,
          `${info.startTimeList[TimeIndex.HOUR]}:${info.startTimeList[TimeIndex.MINUTE]}`,
          `${info.endTimeList[TimeIndex.HOUR]}:${info.endTimeList[TimeIndex.MINUTE]}`));
      } else if (isAcrossAay === AcrossDay.END_TIME_ACROSS) {
        timeString = util.format(this.hyacinthContext?.resourceManager.
          getStringSync($r('app.string.hyacinth_available_time_tomorrow_end').id,
          `${info.startTimeList[TimeIndex.HOUR]}:${info.startTimeList[TimeIndex.MINUTE]}`,
          `${info.endTimeList[TimeIndex.HOUR]}:${info.endTimeList[TimeIndex.MINUTE]}`));
      }
      timeStringArr[this.nextTimeCount++] = timeString;
    }
    if (this.nextTimeCount === 0) {
      this.queryingOverTime = false;
      LogUtils.i(TAG, 'nextTimeCount is 0');
      return;
    } else if (this.nextTimeCount === 1) {
      this.nextTime = util.format(this.hyacinthContext?.resourceManager.getStringSync(
        $r('app.string.hyacinth_available_tips_single').id, timeStringArr[0]));
    } else {
      this.nextTime = util.format(this.hyacinthContext?.resourceManager.getStringSync(
        $r('app.string.hyacinth_available_tips').id, timeStringArr[0], timeStringArr[1]));
    }
    // 协议接口off的状态下查询无法回调,禁用更新提示语的逻辑,防止异常触发查询过顶时间导致的提示语异常
    this.queryingOverTime = false;
    offOverTimeInfo();
  }

  private reRequestNextTime: Function = () => {
    LogUtils.i(TAG, 'reRequestNextTime.');
    this.updateCardInfo();
  }

  spanNodeArray: SpanNodeInfo[] = [];
  permissionDialog: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.hyacinth_satellite_service_permission_usage_details'),
      contentBuilder: () => {
        this.permissionBuildContent();
      },
      buttons: [{
        value: $r('app.string.gotIt'), buttonStyle: ButtonStyleMode.TEXTUAL, action: () => {
          this.permissionDialog.close();
        }
      }]
    }),
    autoCancel: false,
    showInSubWindow: true
  })

  // 后台进入且在风信子界面时重新请求过顶时间
  refreshOverTime() {
    if (!this.needRefreshOverTime) {
      return;
    }
    this.getTianTongSwitch().then((isTianTong: boolean) => {
      LogUtils.i(TAG, 'refreshOverTime.');
      !isTianTong && SatelliteSearchManager.getInstance().queryOverTime();
    })
    this.needRefreshOverTime = false;
  }

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    SatelliteSearchManager.getInstance()
      .registerApplyOvertimeCallback(this.applyOverTimeCallback, this.reRequestNextTime);
    this.mHyacinthSatelliteService.aboutToAppear(SatelliteType.HYACINTH);
    this.mHyacinthSatelliteService.setActiveSimInfoCT();
    this.SatelliteStateListener();
    ParseXmlUtil.getInstance().parseXml(this.satelliteCommunicationNotification, this.spanNodeArray);
    ReportUtil.getInstance();
    this.needRefreshOverTime = false;
    this.getTianTongSwitch().then((isTianTong: boolean) => {
      !isTianTong && SatelliteSearchManager.getInstance().openOverTimeInfoListener();
    });
  }

  SatelliteStateListener() {
    LogUtils.i(TAG, 'addHyacinthDataShareListener');
    this.hyacinthDataShareManager.addHyacinthDataShareListenerCallback((data: number) => {
        LogUtils.i(TAG, `addHyacinthDataShareListener Listener: ${data}`);
        let hSwitch = data === 1;
        // 退出半模态时重新请求过顶时间
        if (this.controlSwitch !== hSwitch && !hSwitch) {
          SatelliteSearchManager.getInstance().queryOverTime();
        }
        this.controlSwitch = hSwitch;
      }, SatelliteType.HYACINTH);

    this.hyacinthDataShareManager.addHyacinthDataShareListenerCallback((data: number) => {
        LogUtils.i(TAG, `addHyacinthDataShareListener tiantong Listener: ${data}`);
        // 天通半模态在风信子界面关闭时主动请求过顶时间
        if (data === 0 && this.needRequestNextTime) {
           SatelliteSearchManager.getInstance().queryOverTime();
        }
        this.needRequestNextTime = data === 1;
      }, SatelliteType.TIAN_TONG);

    querySatellite(CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT),
      (data: number) => {
        LogUtils.i(TAG, `get: ${data}`);
        this.controlSwitch = data === 1;
      }, SatelliteType.HYACINTH);
  }

  applyNextTime() {
    if (this.simCardInfoList.length < 1 || !this.showName.params || this.showName.params.length < 1) {
      LogUtils.e(TAG, 'queryNextOverTime failed! simCardInfoList or showName is empty.');
      return;
    }
    SatelliteSearchManager.getInstance().inSatUsableTIme = false;
    SatelliteSearchManager.getInstance().queryNextOverTime().then((res: number) => {
      if (res === QueryingOverTimeEnum.SUCCESS) {
        // 查询卫星过顶时间中,等待接口返回的标识
        this.queryingOverTime = true;
        this.nextTime = getString($r('app.string.call_setting_getting_hyacinth_available_time'));
      } else if (res === QueryingOverTimeEnum.POSITION_OFF) {
        LogUtils.i(TAG, 'Positioning is not enabled');
        // 没有定位信息,查询过顶时间失败, 查询标识置为false,提示语重置
        this.queryingOverTime = false;
        this.nextTime = this.hyacinthContext?.resourceManager.
          getStringSync($r('app.string.hyacinth_satellite_service_no_available_time'));
        // 开启定位弹窗加保护, 避免重复开启
        if (this.openLocationDialog.getState() !== promptAction.CommonState) {
          this.openLocationDialog.open();
        }
      } else if (res === QueryingOverTimeEnum.TIANTONG_ON) {
        LogUtils.i(TAG, 'Tiantong  is open');
      } else {
        LogUtils.e(TAG, 'queryingOverTime has exception');
        // 接口异常,查询过顶时间失败, 查询标识置为false,提示语重置
        this.queryingOverTime = false;
        this.nextTime = this.hyacinthContext?.resourceManager.
          getStringSync($r('app.string.hyacinth_satellite_service_no_available_time'));
      }
      LogUtils.i(TAG, `queryNextOverTime finished. result=${res}`);
    });
  }

  openLocationDialog: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      primaryTitle: $r('app.string.need_system_location'),
      content: $r('app.string.satellite_available_time_connection_use'),
      primaryButton: {
        value: $r('[common].string.mmi_cancel'),
        action: () => {
          this.openLocationDialog.close();
        }
      },
      secondaryButton: {
        value: $r('app.string.go_setting'),
        action: async () => {
          // 打开定位弹窗
          let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
          let context: Context = this.getUIContext().getHostContext() as common.UIAbilityContext;
          atManager.requestGlobalSwitch(context, abilityAccessCtrl.SwitchType.LOCATION).then((data: Boolean) => {
            LogUtils.i(TAG, `openLocationDialog result: ${data}`);
            if (data) {
              // 定位开关打开了...查询过顶时间
              this.updateCardInfo();
            }
          }).catch((err: BusinessError) => {
            LogUtils.e(TAG, `openLocationDialog failed: ${err?.code}`);
          });
          this.openLocationDialog.close();
        }
      }
    }),
    autoCancel: false,
    showInSubWindow: this.showInSubWindow,
  })

  simCardChange() {
    // 判断sim卡信息变化, 防止因地址值变化导致的异常触发
    if (this.simCardInfoTemp.length !== this.simCardInfoList.length) {
      LogUtils.i(TAG, 'simCardChange');
      this.simCardInfoTemp = this.simCardInfoList;
      this.updateCardInfo();
    }
  }

  showNameChange() {
    // 判断showname的信息变化,防止因地址值变化导致的异常触发
    try {
      const currentShowNameInfo = JSON.stringify(this.showName);
      if (this.showNameTemp !== currentShowNameInfo) {
        LogUtils.i(TAG, 'showNameChange');
        this.showNameTemp = currentShowNameInfo;
        this.updateCardInfo();
      }
    } catch (e) {
      LogUtils.e(TAG, `showNameChange error :${e?.code}`);
    }
  }

  async updateCardInfo() {
    LogUtils.i(TAG, 'updateCardInfo begin.');
    if (this.simCardInfoList.length < 1 || !this.showName.params || this.showName.params?.length < 1) {
      this.queryingOverTime = false;
      this.nextTime = '';
      return;
    }
    // 开启天通时不请求过顶时间，避免slotId冲突
    if (await this.getTianTongSwitch()) {
      LogUtils.i(TAG, 'TIAN_TONG is already on, unable to request nextTime');
      this.nextTime = getString($r('app.string.hyacinth_available_time_refresh'));
      this.queryingOverTime = false;
      return;
    }
    this.applyNextTime();
  }

  async getTianTongSwitch(): Promise<boolean> {
    let tianTongMode = await querySatelliteWithParam(getSatelliteModeKey(SatelliteType.TIAN_TONG),
      this.hyacinthContext);
    if (!tianTongMode) {
      return false;
    }
    LogUtils.i(TAG, 'TIAN_TONG is already on.');
    this.nextTime = getString($r('app.string.hyacinth_available_time_refresh'));
    this.queryingOverTime = false;
    return true;
  }

  @Builder
  permissionBuildContent(): void {
    Scroll(this.scroller) {
      Column() {
        Text($r('app.string.satellite_service_permission_count'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Regular)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .align(Alignment.Start)
          .alignSelf(ItemAlign.Start)
          .lineHeight(19)

        Text($r('app.string.satellite_service_location'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Medium)
          .margin({ top: 14 })
          .align(Alignment.Start)

        Text($r('app.string.satellite_service_location_permission_descriptions'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Regular)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
    }
    .nestedScroll({scrollForward: NestedScrollMode.PARALLEL, scrollBackward: NestedScrollMode.PARALLEL})
  }
  @Builder
  myTitleBar(){
    TitleBarLayout($r('app.string.hyacinth_satellite_communications'),
      $r('sys.color.ohos_id_color_sub_background'), false)
  }

  build() {
    NavDestination() {
      Scroll(this.scroller) {
        Column() {
          Image($r('app.media.satellite_hyacinth_settings_image'))
            .width(288)
            .height(288)
            .margin({ top: 24, bottom: 24 })
            .draggable(false)

          HyacinthSubItem({
            nextTime: this.nextTime,
            subId: 1,
            satUsableTimeInfo: this.satUsableTimeInfo,
            title: $r('app.string.start_hyacinth_satellite_communications'),
            queryingOverTime: this.queryingOverTime
          })
            .key('HyacinthCommunication_Start_Satellite')
            .margin({
              left: isTablet() ? $r('app.float.wh_value_24') : $r('app.float.margin_16'),
              right: isTablet() ? $r('app.float.wh_value_24') : $r('app.float.margin_16'),
              bottom: 8
            })

          Column() {
            Text() {
              ForEach(this.spanNodeArray, (item: SpanNodeInfo) => {
                if (item.textStyle === 'bold') {
                  Span(item.content)
                    .fontColor($r('sys.color.ohos_id_color_text_primary'))
                    .fontFamily('HarmonyHeiTi')
                    .fontWeight(FontWeight.Medium)
                    .fontSize($r('sys.float.ohos_id_text_size_body3'))
                } else if (item.textStyle === 'userAgreements') {
                  Span(item.content)
                    .fontColor($r('sys.color.ohos_id_color_text_hyperlink'))
                    .fontFamily('HarmonyHeiTi')
                    .fontWeight(FontWeight.Medium)
                    .fontSize($r('sys.float.ohos_id_text_size_body3'))
                    .onClick(() => {
                      DynamicLoader.getInstance().callFunction('HyacinthUserAgreement').then(() => {
                        let param: privacyParamType = { isPrivacyNote: true };
                        this.pathInfos.pushPathByName('HyacinthUserAgreement', param);
                        ReportUtil.getInstance().reportClickUserProtocol();
                      })
                    })
                } else if (item.textStyle === 'privacyStatement') {
                  Span(item.content)
                    .fontColor($r('sys.color.ohos_id_color_text_hyperlink'))
                    .fontFamily('HarmonyHeiTi')
                    .fontWeight(FontWeight.Medium)
                    .fontSize($r('sys.float.ohos_id_text_size_body3'))
                    .onClick(() => {
                      DynamicLoader.getInstance().callFunction('HyacinthPrivacyStatement').then(() => {
                        let param: privacyParamType = { isPrivacyNote: false };
                        this.pathInfos.pushPathByName('HyacinthPrivacyStatement', param);
                        ReportUtil.getInstance().reportClickUserPrivacy();
                      });
                    })
                } else if (item.textStyle === 'permissionStatement') {
                  Span(item.content)
                    .fontColor($r('sys.color.ohos_id_color_text_hyperlink'))
                    .fontFamily('HarmonyHeiTi')
                    .fontWeight(FontWeight.Medium)
                    .fontSize($r('sys.float.ohos_id_text_size_body3'))
                    .onClick(() => {
                      this.permissionDialog.open();
                      ReportUtil.getInstance().reportClickUserPermissions();
                    })
                } else {
                  Span(item.content)
                    .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                    .fontFamily('HarmonyHeiTi')
                    .fontWeight(FontWeight.Regular)
                    .fontSize($r('sys.float.ohos_id_text_size_body3'))
                }
              })
            }
            .alignSelf(ItemAlign.Start)
            .margin({ top: 4 })

          }
          .margin({ start: LengthMetrics.vp(28), end: LengthMetrics.vp(28), bottom: LengthMetrics.vp(16) })

          HyacinthSubItem({
            subId: 2,
            satUsableTimeInfo: this.satUsableTimeInfo,
            title: $r('app.string.satellite_service_select_sim')
          })
            .key('HyacinthCommunication_Select_Sim')
            .margin({
              left: isTablet() ? $r('app.float.wh_value_24') : $r('app.float.margin_16'),
              right: isTablet() ? $r('app.float.wh_value_24') : $r('app.float.margin_16'),
              bottom: $r('app.float.padding_12')
            })
            .enabled(this.simCardInfoList !== undefined && this.simCardInfoList.length === 2 && !this.controlSwitch)

          HyacinthSubItem({
            subId: 3,
            satUsableTimeInfo: this.satUsableTimeInfo,
            title: $r('app.string.frequently_asked_questions')
          })
            .key('HyacinthCommunication_Faq')
            .margin({
              left: isTablet() ? $r('app.float.wh_value_24') : $r('app.float.margin_16'),
              right: isTablet() ? $r('app.float.wh_value_24') : $r('app.float.margin_16')
            })
        }
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .key('HyacinthCommunication_Nav_Scroll')
      .layoutWeight(1)
      .align(Alignment.Top)
      .edgeEffect(EdgeEffect.Spring)
      .clip(false)
    }
    .key('HyacinthCommunication_Nav')
    .title(this.myTitleBar)
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .onAppear(() => {
      this.pathInfos.removeByName('HyacinthActivate');
    })
    .onWillDisappear(()=>{
      // Nav组件动效会导致aboutToDisappear延迟，需要使用onWillDisappear避免时序问题
      LogUtils.i(TAG, 'onWillDisappear');
      SatelliteSearchManager.getInstance().closeOverTimeInfoListener();
      this.hyacinthDataShareManager.removeHyacinthDataShareListenerCallback();
      this.showName = $r('app.string.satellite_service_no_sim_card');
    })
  }
}

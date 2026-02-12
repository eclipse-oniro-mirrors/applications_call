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
  LogUtils,
  ReportUtil,
  SatelliteSimCardInfoStruct,
  CallSettingGlobalContextHelper,
  sharedPreferencesUtils,
  PrivacyStatement,
  Constants
} from '@ohos/common/CommonIndex';
import { call } from '@kit.TelephonyKit';
import { AlertDialog, CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import {
  addBeiDouMessageSateListener,
  insertBeiDouMessage,
  queryBeiDouMessageState,
  removeBeiDouMessageSateListener
} from '../../common/utils/BeiDouMessageStateManager';
import { querySatellite, } from '../../common/utils/SateToggleStateManager';
import * as CallSettingsConstant from '../../common/constant/CallSettingsConstant';
import SimCardSelectedDialog from '../../common/dialog/SimCardSelectedDialog';
import { getShowName, updateBeiDouSwitchValue } from '../../model/SatelliteServiceSettingModel';
import { common } from '@kit.AbilityKit';
import { CALL_SETTING_SATELLITE_ABILITY_CONTEXT } from '../../common/constant/CallSettingsConstant';
import { BusinessError, commonEventManager, settings } from '@kit.BasicServicesKit';
import { SATELLITE_KEY_SLOT_ID } from '../../common/constant/SatelliteSearchConst';
// import vsim from '@hms.telephony.vsim';
import ServiceExtensionContext from '@ohos.app.ability.common';
import { LengthMetrics } from '@kit.ArkUI';
import { isTablet } from '../../common/utils/DeviceTypeUtils';
import { saveCarrierType } from '../../model/SimManager';
import { connection } from '@kit.NetworkKit';
import SatelliteServiceSettingsVMForBeiDou from '../../viewModel/SatelliteServiceSettingsVMForBeiDou';

const TAG = 'BeiDouSatelliteSubItem';

@Component
export default struct BeiDouSatelliteSubItem {
  @Consume('pathInfos') pathInfos: NavPathStack;
  @State subId: number = 1;
  @State title: Resource = $r('app.string.start_beidou_satellite_message');
  // 北斗短信是否开启--界面
  @State controlSwitch: boolean = false;
  @StorageLink('showNameForBeiDou') @Watch('watchShowName') showNameForBeiDou: Resource | string =
    $r('app.string.satellite_service_no_sim_card');
  @State mSatelliteServiceSettingsVM: SatelliteServiceSettingsVMForBeiDou =
    SatelliteServiceSettingsVMForBeiDou.getInstance();
  @State isOpenDialog: boolean = false;
  @StorageLink('simCardInfoListForBeiDou') simCardInfoList: SatelliteSimCardInfoStruct[] = [];
  @State isSimActiveChange: boolean = false;
  // 北斗短信是否开启--应用
  @StorageLink(CallSettingsConstant.IS_SMC_ENABLED) @Watch('closeService') isBeiDouStartService: boolean = false;
  // 天通是否开启
  private isTianTongSatelliteSwitch: boolean = false;
  @State showGoToUseBeiDouMessage: boolean = true;
  @State notShowAgain: boolean = false;
  scroller: Scroller = new Scroller();
  private callSettingContext = CallSettingGlobalContextHelper.getContext()
    .getValue<common.UIExtensionContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT);
  /**
   * 飞行模式
   */
  airPlaneModeControllerConfirm: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.beidou_satellite_message_service_settings_airplane_mode'),
      primaryButton: {
        value: $r('app.string.gotIt'),
        action: () => {
          this.airPlaneModeControllerConfirm.close();
          this.closeToggle();
        }
      },
    }),
    autoCancel: false,
    showInSubWindow: true,
    cancel: () => {
      this.closeToggle();
    }
  })
  /**
   * 没有网络
   */
  noNet: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.beidou_satellite_message_service_no_net'),
      primaryButton: {
        value: $r('app.string.gotIt'),
        action: () => {
          this.noNet.close();
          this.closeToggle();
        }
      },
    }),
    autoCancel: false,
    showInSubWindow: true,
    cancel: () => {
      this.closeToggle();
    }
  })
  dialogHasCallControllerConfirm: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.beidou_satellite_message_enter_in_call'),
      primaryButton: {
        value: $r('app.string.gotIt'),
        action: () => {
          this.dialogHasCallControllerConfirm.close();
          this.closeToggle();
        }
      },
    }),
    autoCancel: false,
    showInSubWindow: true,
    cancel: () => {
      this.closeToggle();
    }
  })
  /**
   * 确认退出北斗卫星短信？
   */
  exitSatelliteService: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.exit_beidou_satellite_message_service_tips'),
      primaryButton: {
        value: $r('app.string.cancel_space'),
        action: () => {
          this.exitSatelliteService.close();
          this.isBeiDouStartService = true;
          this.handleControlSwitch();
        }
      },
      secondaryButton: {
        value: $r('app.string.satellite_exit'),
        action: () => {
          this.isBeiDouStartService = false;
          this.insertStatusAndSimInfo();
          this.handleControlSwitch();
          this.exitSatelliteService.close();
          let timeId = setTimeout(() => {
            clearTimeout(timeId);
            updateBeiDouSwitchValue();
          }, 500);
        }
      }
    }),
    autoCancel: false,
    showInSubWindow: true,
    cancel: () => {
      this.controlSwitch = true;
    }
  })
  noCardDialogController: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.beidou_satellite_message_no_sim_card_descriptions'),
      primaryButton: {
        value: $r('app.string.gotIt'),
        action: () => {
          this.noCardDialogController.close();
          this.closeToggle();
        }
      }
    }),
    autoCancel: false,
    showInSubWindow: true,
    cancel: () => {
      this.closeToggle();
    }
  })
  /**
   * 是否启用北斗卫星短信
   */
  openSatelliteDialog: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.start_beidou_satellite_message'),
      contentBuilder: () => {
        this.buildContent();
      },
      buttons: [{
        value: $r('app.string.cancel_space'), buttonStyle: ButtonStyleMode.TEXTUAL, action: () => {
          this.closeToggle();
          ReportUtil.getInstance().reportOpenSatelliteDialogAction(0);
        }
      },
        {
          value: $r('app.string.enabled'),
          buttonStyle: ButtonStyleMode.EMPHASIZED,
          action: () => {
            ReportUtil.getInstance().reportOpenSatelliteDialogAction(1);
            // 需要SIM卡
            if (!this.simCardInfoList === undefined || this.simCardInfoList === null ||
              this.simCardInfoList.length === 0) {
              this.noCardDialogController.open();
              ReportUtil.getInstance().reportOpenSatelliteCallIssue(1);
              return;
            }
            // 选择SIM卡
            let simInfo: SatelliteSimCardInfoStruct = this.simCardInfoList[0];
            if (this.mSatelliteServiceSettingsVM.hasTwoCard()) {
                simInfo = this.simCardInfoList.find(
                (simInfo: SatelliteSimCardInfoStruct) => simInfo.isChecked === true) as SatelliteSimCardInfoStruct;
              if (simInfo === undefined) {
                // 如果刷机后，未配置北斗卫星卡槽信息，则默认选择卡1
                this.simCardInfoList[0].isChecked = true;
                this.simCardInfoList[0].isPreferences = true;
                simInfo = this.simCardInfoList[0];
              }
            }
            let info: string[] =
              [`${simInfo.slotId}`, `${simInfo.showNumber}`, `${simInfo.isPreferences}`, `${simInfo.iMsi}`];
            LogUtils.i(TAG, 'openSatelliteDialog, simCardInfoList has one simInfo');
            sharedPreferencesUtils.init(this.callSettingContext);
            sharedPreferencesUtils.saveToPreferences(
              CallSettingsConstant.SATELLITE_DIALOG_TIPS.SATELLITE_DIALOG_TIPS, info);
            // 开启北斗卫星短信
            this.openSateService(simInfo.slotId);
          }
        }]
    }),
    autoCancel: false,
    showInSubWindow: true,
    cancel: () => {
      this.closeToggle();
    }
  })
  /**
   * 前往使用北斗短信
   */
  goToUseBeiDouMessageDialog: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.go_use_beidou_satellite_message'),
      contentBuilder: () => {
        this.buildGoToUseMessageContent();
      },
      buttons: [{
        value: $r('app.string.cancel_space'), buttonStyle: ButtonStyleMode.TEXTUAL, action: () => {
          this.goToUseBeiDouMessageDialog.close();
        }
      },
        {
          value: $r('app.string.go_to_use'),
          buttonStyle: ButtonStyleMode.EMPHASIZED,
          action: () => {
            LogUtils.i(TAG, 'goToUseBeiDouMessageDialog  notShowAgain:' + this.notShowAgain);
            // 保存是否前往北斗短信
            insertBeiDouMessage('showGoToUseBeiDouMessage', this.notShowAgain ? 2 : 1, this.callSettingContext);
            // 跳往北斗卫星短信界面
            this.startBeiDouMessageAbility();
          }
        }]
    }),
    autoCancel: false,
    showInSubWindow: true,
  })

  startBeiDouMessageAbility(): void {
    let want: Want = {
      bundleName: 'com.ohos.mms',
      abilityName: 'com.ohos.mms.MainAbility'
    };
    try {
      let context = getContext(this) as common.UIAbilityContext;
      if (!context) {
        LogUtils.e(TAG, 'startSmcServiceExtAbility context is invalid.');
        return;
      }
      context.startAbility(want).then(() => {
        LogUtils.i(TAG, `startSmcServiceExtAbility success.`);
      }).catch((error: BusinessError) => {
        LogUtils.e(TAG, `startSmcServiceExtAbility failed, code: ${error?.code}, message: ${error?.message}`);
      });
    } catch (err) {
      LogUtils.e(TAG, `startSmcServiceExtAbility error, message: ${err?.message}`);
    }
  }

  simCardDialogController: CustomDialogController = new CustomDialogController({
    builder: SimCardSelectedDialog({
      controlSwitch: $controlSwitch,
      isSimActiveChange: $isSimActiveChange,
      simCardInfoList: $simCardInfoList,
      accept: this.simCardAccept,
      content: $r('app.string.beidou_satellite_message_select_sim_card')
    }),
    autoCancel: false,
    showInSubWindow: true,
    cancel: () => {
      if (!this.isSimActiveChange) {
        this.closeToggle();
      }
    }
  })

  watchShowName() {
    let showName = this.showNameForBeiDou as string
    LogUtils.i(TAG, `watchShowName: ${showName}`);
    LogUtils.i(TAG, `watchShowName: ${showName.toString()}`);
  }

  closeService() {
    LogUtils.i(TAG, `closeService: ${this.isBeiDouStartService}`);
    let options: PrivacyStatement = {
      isStartService: this.isBeiDouStartService,
      agreeTime: new Date().valueOf(),
      privacyVersion: Constants.PRIVACY_STATEMENT_VERSION,
      appVersion: ReportUtil.getInstance().versionName
    }
    sharedPreferencesUtils.init(this.callSettingContext);
    sharedPreferencesUtils.saveToPreferences(CallSettingsConstant.IS_SMC_ENABLED, options);

    if (!this.isBeiDouStartService) {
      this.closeDialog();
    }
  }

  closeDialog() {
    LogUtils.i(TAG, `closeDialog`);
    this.closeToggle();
    this.dialogHasCallControllerConfirm?.close();
    this.openSatelliteDialog?.close();
    this.noCardDialogController?.close();
    this.simCardDialogController?.close();
    this.airPlaneModeControllerConfirm?.close();
  }

  /**
   * 关闭启动选项
   */
  closeToggle() {
    LogUtils.i(TAG, 'closeToggle:' + JSON.stringify(this.controlSwitch))
    this.controlSwitch = false;
  }

  judgeHasNet(): boolean {
    try {
      let netHandle = connection.getDefaultNetSync();
      if (!netHandle || netHandle.netId === 0) {
        return false;
      }
      let netCapability = connection.getNetCapabilitiesSync(netHandle);
      let cap = netCapability.networkCap || [];
      if (cap.includes(connection.NetCap.NET_CAPABILITY_VALIDATED)) {
        //connection.NetCap.NET_CAPABILITY_VALIDATED，该值代表网络是通的，能够发起HTTP和HTTPS的请求。
        // 网络信息变化，网络可用
        return true;
      } else {
        // 网络信息变化，网络不可用
        return false;
      }
    } catch (e) {
      let err = e as BusinessError;
      console.error('JudgeHasNet' + JSON.stringify(err));
    }
    return false;
  }

  @Builder
  buildContent(): void {
    Column() {
      Scroll(this.scroller) {
        Text($r('app.string.satellite_service_settings_enable_tips'))
          .fontColor($r('sys.color.ohos_id_color_primary'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Regular)
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
      }
    }
  }

  @Builder
  buildGoToUseMessageContent(): void {
    Column({ space: 20 }) {
      Text($r('app.string.go_use_beidou_message_tips'))
        .fontColor($r('sys.color.ohos_id_color_primary'))
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))

      Row() {
        Checkbox({ name: 'checkbox1', group: 'checkboxGroup' })
          .select(false)// .selectedColor(0xed6f21)
          .shape(CheckBoxShape.CIRCLE)
          .onChange((value: boolean) => {
            console.info('Checkbox1 change is' + value)
            this.notShowAgain = value;
            this.showGoToUseBeiDouMessage = value ? false : true;
            insertBeiDouMessage('showGoToUseBeiDouMessage', this.notShowAgain ? 2 : 1, this.callSettingContext);
          })

        Text($r('app.string.do_not_show_again'))
          .fontColor($r('sys.color.ohos_id_color_primary'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Regular)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
    }
    .alignItems(HorizontalAlign.Start)
  }

  // 打开服务
  openSateService(slotId: number) {
    LogUtils.i(TAG, 'openSateService');
    this.isBeiDouStartService = true;
    this.saveToPreference(slotId);
    this.insertStatusAndSimInfo();
    if (this.showGoToUseBeiDouMessage) {
      this.goToUseBeiDouMessageDialog.open();
    }
    let timeId = setTimeout(() => {
      clearTimeout(timeId);
      updateBeiDouSwitchValue();
    }, 500);
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
    .borderRadius(16)
    .constraintSize({ minHeight: $r('app.float.wh_value_48') })
    .opacity(1)
  }

  @Styles
  normalStyles() {
    .backgroundColor(Color.Transparent)
  }

  simCardAccept(simInfo: SatelliteSimCardInfoStruct) {
    LogUtils.i(TAG, `simCardAccept ${simInfo.slotId}`);
    let showName = getShowName(simInfo);
    AppStorage.setOrCreate('showNameForBeiDou', showName);
    simInfo.isPreferences = true;
    let info: string[] = [`${simInfo.slotId}`, `${simInfo.showNumber}`, `${simInfo.isPreferences}`, `${simInfo.iMsi}`];
    LogUtils.i(TAG, 'isOpened simCardAccept');
    let callSettingContext = CallSettingGlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT);
    sharedPreferencesUtils.init(callSettingContext);
    sharedPreferencesUtils.saveToPreferences(CallSettingsConstant.SATELLITE_DIALOG_TIPS.SATELLITE_DIALOG_TIPS, info);
    insertBeiDouMessage(CallSettingsConstant.BEIDOU_SIM_SLOTID, simInfo.slotId, callSettingContext);
    try {
      settings.setValueSync(callSettingContext, SATELLITE_KEY_SLOT_ID, String(simInfo.slotId));
    } catch (err) {
      LogUtils.e(TAG, `simCardAccept error: ${err?.code} ${err?.message}`);
    }
    saveCarrierType(callSettingContext, simInfo.slotId);
  }

  /**
   * 保存状态、SIM卡信息
   */
  insertStatusAndSimInfo() {
    let status = this.isBeiDouStartService ? 1 : 0;
    insertBeiDouMessage(CallSettingsConstant.IS_SMC_ENABLED, status, this.callSettingContext);
    if (this.simCardInfoList.length > 0) {
      // 保存 SIM slotid 和 shounumber
      let simInfo = this.simCardInfoList.find(
        (simInfo: SatelliteSimCardInfoStruct) => simInfo.isChecked === true);
      simInfo = simInfo === undefined ? this.simCardInfoList[0] : simInfo;
      insertBeiDouMessage(CallSettingsConstant.BEIDOU_SIM_SLOTID, simInfo.slotId, this.callSettingContext);
      LogUtils.i(TAG, 'publishBeiDouSatellteMessageStatusEvent status:' + status);
      try {
        commonEventManager.publish('event.custom.satellite.ACTION_BEIDOU_SATELLITE_MESSAGE', {
          subscriberPermissions: ['ohos.permission.SEND_MESSAGES'],
          isOrdered: false,
          code: status,
          parameters: {
            slotId: simInfo.slotId,
            simNumber: simInfo.showNumber
          }
        }, () => {
        });
      } catch (err) {
        LogUtils.e(TAG, `BeiDou insertStatusAndSimInfo publish error: ${err?.code} ${err?.message}`);
      }
    }
  }

  /**
   * 保存选择的卡、以及运营商
   */
  saveToPreference(slotId: number) {
    if (this.simCardInfoList !== undefined && this.simCardInfoList.length > 0) {
      LogUtils.i(TAG, 'saveToPreference ' + JSON.stringify(slotId));
      try {
        settings.setValueSync(this.callSettingContext, SATELLITE_KEY_SLOT_ID, String(slotId));
      } catch (err) {
        LogUtils.e(TAG, `saveToPreference error: ${err?.code} ${err?.message}`);
      }
      saveCarrierType(this.callSettingContext, slotId);
    }
  }

  aboutToAppear(): void {
    if (this.subId === 1) {
      this.mSatelliteServiceSettingsVM.addSimStateAcitveChangeListener((bol: boolean) => {
        LogUtils.i(TAG, 'addSimStateAcitveChangeListener: closeDialog:' + JSON.stringify(bol));
        // 拔卡bol是false
        if (!bol) {
          this.closeDialog();
        }
      });
      // 监视北斗卫星短信状态，以及查询北斗卫星短信状态
      addBeiDouMessageSateListener(this.callSettingContext, (data: number) => {
        LogUtils.i(TAG, 'addBeiDouMessageSateListener:' + JSON.stringify(data));
        this.controlSwitch = data === 1;
        this.isBeiDouStartService = data === 1;
        let timeId = setTimeout(() => {
          clearTimeout(timeId);
          updateBeiDouSwitchValue();
        }, 500);
      });
      queryBeiDouMessageState(this.callSettingContext, 'showGoToUseBeiDouMessage', (data: number) => {
        LogUtils.i(TAG, 'queryBeiDouMessageState showGoToUseBeiDouMessage:' + JSON.stringify(data));
        if (data == 2) {
          this.showGoToUseBeiDouMessage = false;
        }
        queryBeiDouMessageState(this.callSettingContext, CallSettingsConstant.IS_SMC_ENABLED, (data: number) => {
          LogUtils.i(TAG, 'queryBeiDouMessageState IS_SMC_ENABLED:' + JSON.stringify(data));
          this.controlSwitch = data === 1;
          this.isBeiDouStartService = data === 1;
          if (this.isBeiDouStartService && this.showGoToUseBeiDouMessage) {
            LogUtils.i(TAG, 'aboutToAppear open go to use bei dou message: ' + this.isBeiDouStartService);
            this.controlSwitch = true;
            this.goToUseBeiDouMessageDialog.open();
          }
        })
      });
      LogUtils.i(TAG, 'aboutToAppear bei dou message status: ' + this.isBeiDouStartService);
    }
  }

  /**
   * 监视天通状态，以及查询天通状态
   */
  queryAndLinstenerTianTong(): void {
    querySatellite(this.callSettingContext, (data: number) => {
      LogUtils.i(TAG, 'querySatellite:' + JSON.stringify(data));
      this.isTianTongSatelliteSwitch = data === 1;
    })
    LogUtils.i(TAG, 'aboutToAppear tiantong satellite status: ' + this.isTianTongSatelliteSwitch);
  }

  aboutToDisappear(): void {
    if (this.subId === 1) {
      removeBeiDouMessageSateListener();
    }
  }

  handleControlSwitch() {
    LogUtils.i(TAG, 'handleControlSwitch ');
    this.controlSwitch = this.isBeiDouStartService;
    this.mSatelliteServiceSettingsVM.isStartSatelliteService = this.isBeiDouStartService;
  }

  /**
   * 启用状态
   * 1、检查是否又SIM卡
   * 2、是否在通话中
   * 3、飞行模式
   * 4、天际通
   */
  openDialog() {
    LogUtils.i(TAG, 'openDialog');
    let context = CallSettingGlobalContextHelper.getContext()
      .getValue<ServiceExtensionContext.ServiceExtensionContext>(CALL_SETTING_SATELLITE_ABILITY_CONTEXT);
    let airplanemode: number = Number(settings.getValueSync(context, 'settings.telephony.airplanemode', '-1'));
    LogUtils.i(TAG, 'airplanemode: ' + airplanemode);
    // let isVSimOn: boolean = vsim.getVSimStatus().isVSimOn;
    // LogUtils.i(TAG, 'isVSimOn: ' + isVSimOn);
    let hasNet = this.judgeHasNet();
    LogUtils.i(TAG, 'hasNet: ' + hasNet);
    if (!this.simCardInfoList === undefined || this.simCardInfoList === null || this.simCardInfoList.length === 0) {
      this.noCardDialogController.open();
      ReportUtil.getInstance().reportOpenSatelliteCallIssue(Constants.UE_IS_NOT_CTCARD);
    } else if (call.hasCallSync()) {
      this.dialogHasCallControllerConfirm.open();
      ReportUtil.getInstance().reportOpenSatelliteCallIssue(Constants.UE_INCALL);
    } else if (airplanemode == 1) {
      this.airPlaneModeControllerConfirm.open();
      ReportUtil.getInstance().reportOpenSatelliteCallIssue(Constants.UE_IN_AIRPLANE);
    } else if (!hasNet) {
      this.noNet.open();
      ReportUtil.getInstance().reportOpenSatelliteCallIssue(Constants.UE_NO_NET);
    } else {
      this.openSatelliteDialog.open();
      ReportUtil.getInstance().reportSatelliteOpenDialog();
    }
    ReportUtil.getInstance().reportOpenSatelliteSimCardInfo(this.simCardInfoList);
  }

  build() {
    Column() {
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Text(this.title)
          .key('start_beidou_satellite_message')
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor($r('sys.color.ohos_id_color_primary'))
          .fontWeight(FontWeight.Medium)
          .fontFamily('HarmonyHeiTi')
          .margin({ start: LengthMetrics.vp(12) })
          .onClick(() => {
            this.showGoToUseBeiDouMessage = true;
          })

        if (this.subId === 1) {
          Toggle({ type: ToggleType.Switch, isOn: this.controlSwitch })
            .width(36)
            .height(20)
            .enabled(true)
            .margin({ end: LengthMetrics.vp(12) })
            .key('beidou_satellite_button')
            .onChange((isOn) => {
              LogUtils.i(TAG, `onChange: toggle isOn: ${isOn} controSwitch: ${this.controlSwitch}  }`);
              LogUtils.i(TAG, `onChange: toggle isBeiDouStartService: ${this.isBeiDouStartService} }`);
              if (isOn == this.controlSwitch) {
                return;
              }
              // 如果界面改为开，而且实际北斗没有开，就打开北斗短信
              if (isOn) {
                this.controlSwitch = true;
                this.openDialog();
                ReportUtil.getInstance().reportEnterSatelliteCall(1);
                return;
              }

              // 关闭北斗短信
              this.controlSwitch = false;
              this.exitSatelliteService.open();
              ReportUtil.getInstance().reportEnterSatelliteCall(2);
            })
        }

        if (this.subId === 2) {
          Row() {
            Text(this.showNameForBeiDou)
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .fontFamily('HarmonyHeiTi')
              .fontWeight(FontWeight.Regular)
              .lineHeight(14)
              .margin({
                end: LengthMetrics.vp((this.simCardInfoList !== undefined &&
                  this.simCardInfoList.length === 2) ? 4 : 0)
              })

            Image($r('app.media.ic_public_arrow_right'))
              .fillColor($r('sys.color.ohos_id_color_fourth'))
              .height($r('app.float.wh_value_24'))
              .width($r('app.float.wh_value_12'))
              .draggable(false)
              .matchTextDirection(true)
              .visibility((this.simCardInfoList !== undefined && this.simCardInfoList.length === 2) ?
              Visibility.Visible : Visibility.None)
          }
          .margin({ end: LengthMetrics.vp(12) })
        }
        if (this.subId === 3) {
          Image($r('app.media.ic_public_arrow_right'))
            .fillColor($r('sys.color.ohos_id_color_fourth'))
            .height($r('app.float.wh_value_24'))
            .width($r('app.float.wh_value_12'))
            .margin({ end: LengthMetrics.vp(12) })
            .matchTextDirection(true)
            .draggable(false)
        }
      }
      .stateStyles({
        normal: this.normalStyles,
        pressed: this.pressedStyles
      })
      .constraintSize({ minHeight: $r('app.float.wh_value_48') })
      .margin(4)
    }
    .accessibilityGroup(true)
    .accessibilityDescription(this.subId === 2 ?
      ((this.simCardInfoList !== undefined && this.simCardInfoList.length === 2) ? undefined : ' ') : undefined)
    .onClick(async () => {
      if (this.subId === 2) {
        if (this.simCardInfoList !== undefined && this.simCardInfoList.length === 2) {
          this.isSimActiveChange = true;
          this.simCardDialogController.open();
          LogUtils.i(TAG, 'onclick simCardDialogController open: ');
        }
      } else if (this.subId === 3) {
        this.mSatelliteServiceSettingsVM.jumpPhoneWidget();
        ReportUtil.getInstance().reportClickCommonQuestion();
      }
    })
    .margin({
      left: isTablet() ? $r('app.float.wh_value_24') : $r('app.float.margin_16'),
      right: isTablet() ? $r('app.float.wh_value_24') : $r('app.float.margin_16')
    })
    .constraintSize({ minHeight: 56 })
    .borderRadius($r('sys.float.corner_radius_level10'))
    .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
  }
}
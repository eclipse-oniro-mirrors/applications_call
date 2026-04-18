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
import { EmergencyWarningDivider } from '../components/EmergencyWarningDivider';
import { ContactListStruct } from '../utils/ClassStruct';
import LogUtils from '../utils/HiLog';
import { common, OpenLinkOptions, UIExtensionContentSession } from '@kit.AbilityKit';
import commonData, { PersonalSafetyReportSwitch } from '../data/CommonData';
import { IMediaPlayer } from '../EmergencyEarthquakeAlarm/IMediaPlayere';
import SosLocationService from '../soslocationservice/SosLocationService';
import requestPermissionFromUsers from '../EmergencyEarthquackLocationService/Application';
import checkAccess from '../EmergencyEarthquackLocationService/Detector';
import { Prompt, LengthMetrics, EditableTitleBar, EditableLeftIconType, curves } from '@kit.ArkUI';
import { AmlUtils, ParseXmlUtil, SpanNodeInfo, Utils } from '../utils/Utils';
import { AlertDialog, CustomContentDialog } from '@ohos.arkui.advanced.Dialog'
import { DynamicLoader } from '../utils/DynamicLoader';
import { SosSettingsController } from '../control/SosSettingsController';
import { DataStorageUtil } from '../utils/DataStorageUtil';
import media from '@ohos.multimedia.media';
import AmlPrivacyStatement from './AmlPrivacyStatement';
// import SosPrivacyStatement from './SosPrivacyStatement';
import EmergencyCallController from '../control/EmergencyCallControl';
import { display } from '@kit.ArkUI';
import deviceInfo from '@ohos.deviceInfo';
import { ContactsService } from '../service/ContactsService';
import { getVersionName, ReportUtil } from '../utils/ReportUtil';
import LayoutUtils from '../utils/LayoutUtils';
import { PreferencesListenerUtil } from '../emergencydatashareextability/PreferencesListenerUtil';
import ScreenAdapterUtils from '../utils/ScreenAdapterUtils';
import { image } from '@kit.ImageKit';
import { CAR_ACCIDENT, FALL_DOWN } from '../utils/Constants'
import { PersonalSafetyAccidentType } from '../utils/ClassStruct'
//import { HdsNavigation, HdsNavigationAttribute, HdsNavigationTitleMode } from '@kit.UIDesignKit';
import SystemParameterEnhance from '@ohos.systemParameterEnhance';
import { BusinessError, settings } from '@kit.BasicServicesKit';
import EmergencyWarningController from '../control/EmergencyWarningControl';
import CallColumnUtils from '../utils/CallColumnUtils';
import { isTablet } from '../utils/DeviceTypeUtils';
import { StringUtil } from '../utils/StringUtil';
import { TitleBarLayout, TitleParams } from '../base/view/TitleParams';
import { TITLE_BAR_HEIGHT_MINI } from '../base/constant/HdsNavigationConstant';
import { EmergencyGlobalContextHelper } from '../utils/EmergencyGlobalContextHelper';

const TAG = 'SosEmergencyHelpSettings';
const EMERGENCY_POST_LOCATION_SWITCH = 'emergency_post_location_switch';
const EMERGENCY_POST_LOCATION_SWITCH_ON = '1';
const EMERGENCY_POST_LOCATION_SWITCH_OFF = '0';
const PERSONAL_SAFETY_COUNT_DOWN_VALUE = 90;
const ANIM_DURATION: number = 150;
const CIRCLE_ANIM_DURATION: number = 30;

@Entry
@Component
export struct SosEmergencyHelpSettings {
  public static readonly PAGE_NAME: string = 'SosEmergencyHelpSettings';
  @Provide('pathInfos') @Watch('routerPathChange') pathInfos: NavPathStack = new NavPathStack();
  @State emergencyContacts: ContactListStruct[] = [];
  @State isPlaying: Boolean = false;
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('topAndBottomMarginOnScale') topAndBottomMarginOnScale: string = '17vp';
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  @State defaultDisplayValue: boolean = false;
  @State animationStatus: AnimationStatus = AnimationStatus.Initial;
  @State images: ImageFrameInfo[] = [];
  public deviceTypeInfo = deviceInfo.deviceType;
  public displayChangeCallback: Callback<number> = (data: number) => {
    try {
      let displayInfo = display.getDefaultDisplaySync();
      let isDirectionRow =
        displayInfo.orientation === commonData.int.DEVICE_DISPLAY_ROW ||
          displayInfo.orientation === commonData.int.DEVICE_DISPLAY_ROW_REVERSE
      this.defaultDisplayValue = isDirectionRow;
    } catch (e) {
      LogUtils.e(TAG, 'displayChangeCallback error:' + JSON.stringify(e));
    }
  }
  public storage = LocalStorage.getShared();
  private session: UIExtensionContentSession =
    this.storage?.get<UIExtensionContentSession>('session') as UIExtensionContentSession;
  private sosContentAll = '';
  private sosContent1 = '';
  private sosContent2 = '';
  private sosContent3 = '';
  private sosContent4 = '';
  private sosContentNextAll = '';
  private sosContentNext1 = '';
  private sosContentNext2 = '';
  private sosContentNext3 = '';
  private sosContentNext4 = '1';
  private sosContentNext5 = '';
  private sosContentNext6 = '2';
  private sosContentNext7 = '';
  private sosVideo = ''
  private context = getContext(this) as common.UIAbilityContext
  private mediaPlayer: IMediaPlayer = new IMediaPlayer(getContext(this));
  private sosLocationBody: SosLocationService = new SosLocationService()
  @State autoSendSOSMessageSwitchState: boolean = Utils.isAutoSendSosSmsSwitchOn();
  private mySOSSettingsController: SosSettingsController = SosSettingsController.getInstance();
  @State emergencyContactsNum: number = 0;
  @State autoAutoDialSOSNumberSwitchState: boolean = Utils.isAutoDialSosNumberSwitchOn();
  @State sosEmergencyWarningSettingsTitle: string =
    EmergencyCallController.getInstance().formatResourceToString($r('app.string.Sos_emergency_title'));
  @State isShowHwAmlSwitch: boolean = false;
  @State isAmlEnabled: boolean = false;
  @State sosSendLocationInfo: boolean = this.getSwitchStateFromSetting() === EMERGENCY_POST_LOCATION_SWITCH_ON;
  @StorageLink('searchFoldStatus') @Watch('foldListener') searchFoldStatus: number = 0;
  @State isFromSearch: boolean = AppStorage.get<Boolean>('hideArrow') ? true : false;
  @State hideArrow: boolean =
    this.isFromSearch && this.searchFoldStatus !== 2 && !ScreenAdapterUtils.isNewFormFoldPhone();
  amlShortNotiSpanData: SpanNodeInfo[] = [];
  audioPlayState: media.AVPlayerState = 'stopped';
  noSOSContactsDialogPrimaryTitle: Resource | null = null;
  noSOSContactsDialogType: 'autoSendSMS' | 'autoDialNumber' | 'carAccident' | 'fallDown' | 'none' = 'none';
  mDataStorageUtil: DataStorageUtil = DataStorageUtil.getInstance();
  isRunningOfGetEmergencyContactsNoUseCatch: boolean = false;
  @State paddingStart: LengthMetrics = LengthMetrics.resource(LayoutUtils.getAdaptableTabletPadding(''));

  @State isCarAccidentAudioPlaying: Boolean = false;
  private carAccidentShortNoticeAll = '';
  private carAccidentShortNoticeLocation = '';
  private carAccidentShortNoticeDisclaimer = '';
  private carAccidentShortNoticeServiceAndPrivacy = '';
  private carAccidentShortNoticePermission = '';
  private carAccidentSosAudio: string = ''
  @State carAccidentAutoCallSwitchState: boolean = Utils.isCarAccidentAutoCallSwitchOn();

  @State isFallDownAudioPlaying: Boolean = false;
  private fallDownShortNoticeAll = '';
  private fallDownShortNoticeLocation = '';
  private fallDownShortNoticeDisclaimer = '';
  private fallDownShortNoticeServiceAndPrivacy = '';
  private fallDownShortNoticePermission = '';
  private fallDownSosAudio: string = ''
  @State fallDownAutoCallSwitchState: boolean = Utils.isFallDownAutoCallSwitchOn();
  @State isSupportCrashSos: boolean = false;
  @State isSupportFallSos: boolean = false;
  @State titleX: number | string = '40%';
  @State opacityVal: number = 0;
  @State circleOpacityVal: number = 0;

  dialogControllerOfNoSOSContacts: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      primaryTitle: this.noSOSContactsDialogPrimaryTitle || '',
      content: $r('app.string.unable_auto_dial_dialog_summary'),
      primaryButton: {
        value: $r('app.string.CANCEL'),
        buttonStyle: ButtonStyleMode.TEXTUAL,
        action: () => {
          if (this.noSOSContactsDialogType === CAR_ACCIDENT) {
            ReportUtil.getInstance().reportCrashCannotEnable(PersonalSafetyReportSwitch.CLOSE);
          } else if (this.noSOSContactsDialogType === FALL_DOWN) {
            ReportUtil.getInstance().reportFallCannotEnable(PersonalSafetyReportSwitch.CLOSE);
          }
          this.dialogControllerOfNoSOSContacts.close();
        },
      },
      secondaryButton: {
        value: $r('app.string.unable_auto_dial_dialog_add'),
        buttonStyle: ButtonStyleMode.EMPHASIZED,
        action: () => {
          if (this.noSOSContactsDialogType === CAR_ACCIDENT) {
            ReportUtil.getInstance().reportCrashCannotEnable(PersonalSafetyReportSwitch.ADD_CONTACT);
          } else if (this.noSOSContactsDialogType === FALL_DOWN) {
            ReportUtil.getInstance().reportFallCannotEnable(PersonalSafetyReportSwitch.ADD_CONTACT);
          }
          this.jumpToEmergencyContactsInfo('inherit',
            this.noSOSContactsDialogType === 'autoSendSMS' ? this.openAutoSendSosSmsSwitch :
              (this.noSOSContactsDialogType === CAR_ACCIDENT ? this.openCarAccidentAutoCallSwitch :
                (this.noSOSContactsDialogType === FALL_DOWN ? this.openFallDownAutoCallSwitch :
                this.openAutoDialSosNumberSwitch)));
          this.dialogControllerOfNoSOSContacts.close();
        }
      },
    }),
    showInSubWindow: true,
  });

  private foldListener() {
    LogUtils.i(TAG, 'Listening enabled. Data: ' + this.searchFoldStatus);
    if (ScreenAdapterUtils.isNewFormFoldPhone()) {
      return;
    }
    if (this.searchFoldStatus === 1 && this.isFromSearch) {
      this.hideArrow = true
    } else if (this.searchFoldStatus === 2 && this.isFromSearch) {
      this.hideArrow = false
    } else if (this.searchFoldStatus === 3 && this.isFromSearch) {
      this.hideArrow = true
    }
  }

  jumpToEmergencyContactsInfo(type: 'autoSendSMS' | 'autoDialNumber' | 'carAccident' | 'fallDown' | 'inherit',
    callBack: () => void) {
    const onPop = async (popInfo: PopInfo) => {
      LogUtils.i(TAG, `jumpToEmergencyContactsInfo onPop`);
      const emergencyContacts = await this.getEmergencyContactsNoUseCatch(false);
      if (!emergencyContacts || emergencyContacts.length === 0) {
        //After returning from 'EmergencyContactsInfo', no emergency contact is detected.
        this.noSOSContactsDialogType = type === 'inherit' ? this.noSOSContactsDialogType : type;
        this.noSOSContactsDialogPrimaryTitle = SosSettingsController.getNoSOSContactsDialogPrimaryTitle(
          this.autoSendSOSMessageSwitchState, this.autoAutoDialSOSNumberSwitchState, type,
          this.noSOSContactsDialogPrimaryTitle);
        if (this.noSOSContactsDialogType === CAR_ACCIDENT) {
          ReportUtil.getInstance().reportCrashCannotEnable(PersonalSafetyReportSwitch.OPEN);
        } else if (this.noSOSContactsDialogType === FALL_DOWN) {
          ReportUtil.getInstance().reportFallCannotEnable(PersonalSafetyReportSwitch.OPEN);
        }
        this.dialogControllerOfNoSOSContacts.open();
      } else {
        callBack && callBack();
      }
    }
    DynamicLoader.getInstance().callFunction('EmergencyContactsInfo').then(() => {
      this.pathInfos.pushPathByName('EmergencyContactsInfo', '', onPop);
    })
  }

  private openAutoSendSosSmsSwitch = () => {
    this.autoSendSOSMessageSwitchState = true;
    Utils.setAutoSendSosSmsSwitch(getContext(this), true);
  }

  private async onAutoSendSOSMessageToggleChange(isOn: boolean) {
    if (!isOn) {
      this.autoSendSOSMessageSwitchState = false;
      Utils.setAutoSendSosSmsSwitch(getContext(this), false);
      return;
    }

    const isPermissionCheckPass: boolean = await this.mySOSSettingsController.checkAutoSendSOSMessagePermission();
    if (!isPermissionCheckPass) {
      this.autoSendSOSMessageSwitchState = false;
      return;
    }
    this.autoSendSOSMessageSwitchState = isOn;

    const emergencyContacts = await this.getEmergencyContacts();
    if (!emergencyContacts || emergencyContacts.length === 0) {
      this.autoSendSOSMessageSwitchState = false;
      this.jumpToEmergencyContactsInfo('autoSendSMS', this.openAutoSendSosSmsSwitch);
    } else {
      this.openAutoSendSosSmsSwitch();
    }
    ReportUtil.getInstance().reportSosMmsSwitch(Number(isOn));
  }

  private openPersonalSafetyAutoCallSwitch = async (type: PersonalSafetyAccidentType) => {
    let checkPass = Utils.setPersonalSafetyAutoCallSwitch(getContext(this), type, true);
    if (!checkPass) {
      return;
    }

    if (type === CAR_ACCIDENT) {
      this.carAccidentAutoCallSwitchState = true;
    } else if (type === FALL_DOWN) {
      this.fallDownAutoCallSwitchState = true;
    }
  }

  private closePersonalSafetyAutoCallSwitch = async (type: PersonalSafetyAccidentType) => {
    let checkPass = Utils.setPersonalSafetyAutoCallSwitch(getContext(this), type, false);
    if (!checkPass) {
      return;
    }

    if (type === CAR_ACCIDENT) {
      this.carAccidentAutoCallSwitchState = false;
    } else if (type === FALL_DOWN) {
      this.fallDownAutoCallSwitchState = false;
    }
  }

  private openCarAccidentAutoCallSwitch = () => {
    this.openPersonalSafetyAutoCallSwitch(CAR_ACCIDENT);
  }

  private openFallDownAutoCallSwitch = () => {
    this.openPersonalSafetyAutoCallSwitch(FALL_DOWN);
  }

  private getAutoCallSwitchState(type: string): boolean {
    return type === CAR_ACCIDENT ? this.carAccidentAutoCallSwitchState :
      (type === FALL_DOWN ? this.fallDownAutoCallSwitchState : false);
  }

  private setAutoSwitchState(type: PersonalSafetyAccidentType, isOn: boolean): void {
    if (type === CAR_ACCIDENT) {
      this.carAccidentAutoCallSwitchState = isOn;
    } else if (type === FALL_DOWN) {
      this.fallDownAutoCallSwitchState = isOn;
    }
  }

  private async onPersonalSafetyAutoCallforHelpToggleChange(type: PersonalSafetyAccidentType, isOn: boolean) {
    ReportUtil.getInstance().reportCrashSwitchClick(PersonalSafetyReportSwitch.CLICK);

    if (!isOn) {
      this.closePersonalSafetyAutoCallSwitch(type);
      return;
    }

    const isPermissionCheckPass = await this.mySOSSettingsController.checkPersonalSafetyOpenPermission();
    if (!isPermissionCheckPass) {
      this.setAutoSwitchState(type, false);
      ReportUtil.getInstance().reportCrashSwitchClick(PersonalSafetyReportSwitch.CANNOT_OPEN_WITHOUT_LOCATION);
      return;
    }

    const emergencyContacts = await this.getEmergencyContacts();
    if (!emergencyContacts || emergencyContacts.length === 0) {
      if (type === CAR_ACCIDENT) {
        this.jumpToEmergencyContactsInfo(CAR_ACCIDENT, this.openCarAccidentAutoCallSwitch);
      } else if (type === FALL_DOWN) {
        this.jumpToEmergencyContactsInfo(FALL_DOWN, this.openFallDownAutoCallSwitch);
      }
    } else {
      this.openPersonalSafetyAutoCallSwitch(type);
    }
    this.setAutoSwitchState(type, isOn);
    ReportUtil.getInstance().reportCrashSwitchClick(Number(isOn));
  }

  private getEmergencyContacts = () => {
    LogUtils.i(TAG, 'getEmergencyContacts');
    try {
      return new Promise((resolve: (v: ContactListStruct[]) => void, reject) => {
        this.mDataStorageUtil.getEmergencyContacts((data) => {
          this.emergencyContactsNum = data?.length || 0;
          resolve(data);
        });
      })
    } catch (e) {
      LogUtils.e(TAG, `getEmergencyContacts error: ${JSON.stringify(e)}`)
      return;
    }
  }
  private openAutoDialSosNumberSwitch = () => {
    this.autoAutoDialSOSNumberSwitchState = true;
    Utils.setAutoDialSosNumberSwitch(getContext(this), true);
  }

  private async onAutoDialSOSNumberToggleChange(isOn: boolean) {
    if (!isOn) {
      this.autoAutoDialSOSNumberSwitchState = false;
      Utils.setAutoDialSosNumberSwitch(getContext(this), false);
      return;
    }
    this.autoAutoDialSOSNumberSwitchState = isOn;

    const emergencyContacts = await this.getEmergencyContacts();
    if (!emergencyContacts || emergencyContacts.length === 0) {
      this.autoAutoDialSOSNumberSwitchState = false;
      this.jumpToEmergencyContactsInfo('autoDialNumber', this.openAutoDialSosNumberSwitch);
    } else {
      this.openAutoDialSosNumberSwitch();
    }
    ReportUtil.getInstance().reportSosTelephoneSwitch(Number(isOn));
  }

  amlSwitchChangeListener = (isOn: boolean) => {
    LogUtils.i(TAG, `amlSwitch set to ${isOn}`);
    this.isAmlEnabled = isOn;
    AmlUtils.setSecSettingsSync(this.context, AmlUtils.SWITCH_KEY, isOn ? AmlUtils.SWITCH_ON : AmlUtils.SWITCH_OFF);
    AmlUtils.setSecSettingsSync(this.context, AmlUtils.SWITCH_USER_HANDLED_KEY, AmlUtils.SWITCH_ON);
    this.notifyChangeAmlSwitch();
  }
  notifyChangeAmlSwitch() {
    try {
      this.context.startAbility({ bundleName: 'com.ohos.aml', abilityName: 'ServiceExtAbility'});
    } catch (err) {
      LogUtils.i(TAG, `start ability error:${err?.code} ${err?.message}`);
    }
  }

  syncAutoSwitchStateAndEmergencyContacts = (contactList: ContactListStruct[] | undefined) => {
    if (!contactList || contactList.length === 0) {
      if (this.autoSendSOSMessageSwitchState) {
        this.autoSendSOSMessageSwitchState = false;
        Utils.setAutoSendSosSmsSwitch(getContext(this), false);
      }
      if (this.autoAutoDialSOSNumberSwitchState) {
        this.autoAutoDialSOSNumberSwitchState = false;
        Utils.setAutoDialSosNumberSwitch(getContext(this), false);
      }
      if (this.carAccidentAutoCallSwitchState) {
        this.carAccidentAutoCallSwitchState = false;
        Utils.setPersonalSafetyAutoCallSwitch(getContext(this), CAR_ACCIDENT, false);
      }
      if (this.fallDownAutoCallSwitchState) {
        this.fallDownAutoCallSwitchState = false;
        Utils.setPersonalSafetyAutoCallSwitch(getContext(this), FALL_DOWN, false);
      }
    }
  }

  async onPageShow() {
    LogUtils.i(TAG, 'onPageShow');
    this.getEmergencyContactsNoUseCatch(true);
  }

  onPageHide(): void {
    LogUtils.i(TAG, 'onPageHide');
    if (this.isPlaying) {
      this.stopSosHelpAudio();
    }
    if (this.isCarAccidentAudioPlaying) {
      this.stopPlayCarAccidentSosAudio();
    }
    if (this.isFallDownAudioPlaying) {
      this.stopPlayFallDownSosAudio();
    }
  }


  onBackPress(): boolean | void {
    LogUtils.i(TAG, 'onBackPress');

    LogUtils.i(TAG, `onBackPress called, pathInfos.size: ${this.pathInfos.size()}`);
    LogUtils.i(TAG, `session exists: ${this.session ? 'yes' : 'no'}`);

    this.backAnimate();
  
    // 优先检查Navigation栈
    if (this.pathInfos.size() === 0) {
      // Navigation栈为空，发送消息给宿主应用
      try {
        this.session?.sendData({ 'action': 'pop' });
      } catch (e) {
        LogUtils.e(TAG, `onBackPress sendData error: ${e?.code} ${e?.message}`);
      }
    } else {
      // Navigation栈不为空，让Navigation处理
      this.pathInfos.pop();
    }
    
    return true;
  }

  private backAnimate(): void {
    // title退场动画
    animateTo({ duration: 150, curve: Curve.Sharp }, () => {
      this.titleX = '40%';
    });
    animateTo({ duration: CIRCLE_ANIM_DURATION, delay: 30, curve: Curve.Sharp }, () => {
      this.circleOpacityVal = 0;
    });
  }

  async aboutToAppear(): Promise<void> {
    LogUtils.i(TAG, 'aboutToAppear');
    this.isSupportCrashSos =
      SystemParameterEnhance.getSync('const.emergencycommunication.support_crash_sos', 'false') === 'true';
    this.isSupportFallSos =
      SystemParameterEnhance.getSync('const.emergencycommunication.support_fall_sos', 'false') === 'true';
    // start preference listener
    const preferencesListenerUtil = PreferencesListenerUtil.getInstance();
    preferencesListenerUtil.startPreferenceListener(getContext(this));
    try {
      let displayInfo = display.getDefaultDisplaySync();
      this.defaultDisplayValue =
        displayInfo.orientation === commonData.int.DEVICE_DISPLAY_ROW ||
          displayInfo.orientation === commonData.int.DEVICE_DISPLAY_ROW_REVERSE;
    } catch (e) {
      LogUtils.e(TAG, 'getDefaultDisplaySync error: ' + JSON.stringify(e));
    }
    try {
      display.on('change', this.displayChangeCallback);
    } catch (e) {
      LogUtils.e(TAG, 'Register the callback for display changes error: ' + JSON.stringify(e));
    }
    DynamicLoader.getInstance().register(async (str: string): Promise<void> => {
      return await this.loadPage(str);
    });
    this.checkAmlStatus();
    this.sosContent1 = getContext(this)
      .resourceManager
      .getStringSync($r('app.string.Sos_Auto_Send_info_Detail_notice_dark_Two').id);
    this.sosContent2 = getContext(this)
      .resourceManager
      .getStringSync($r('app.string.Sos_Auto_Send_info_Detail_notice_dark_one').id);
    this.sosContent3 = getContext(this)
      .resourceManager
      .getStringSync($r('app.string.Sos_Auto_Send_info_Detail_notice_active_one').id);
    this.sosContent4 = getContext(this)
      .resourceManager
      .getStringSync($r('app.string.Sos_Auto_Send_info_Detail_notice_active_two').id);
    // this.sosContentAll = getContext(this)
      // .resourceManager.getStringSync($r('app.string.Sos_Auto_Send_info_Detail_notice_renew').id, this.sosContent1,
      //   this.sosContent3, this.sosContent4);
    this.sosContentNext1 = getContext(this)
      .resourceManager
      .getStringSync($r('app.string.Sos_Auto_Send_Location_Detail_Dark_one').id);
    this.sosContentNext2 = getContext(this)
      .resourceManager
      .getStringSync($r('app.string.Sos_Auto_Send_info_Detail_notice_dark_Two').id);
    this.sosContentNext3 = getContext(this)
      .resourceManager
      .getStringSync($r('app.string.Sos_Auto_Send_Location_Detail_Active_two').id);
    this.sosContentNext5 = getContext(this)
      .resourceManager
      .getStringSync($r('app.string.Emergency_Position_Service_Privacy').id);
    this.sosContentNext7 = getContext(this)
      .resourceManager
      .getStringSync($r('app.string.Location_Net_Privacy').id);
    // this.sosContentNextAll = getContext(this).resourceManager
    //   .getStringSync($r('app.string.Sos_Auto_Send_Location_Detail_new').id, this.sosContentNext1, this.sosContentNext2,
    //     this.sosContentNext3, this.sosContentNext4, this.sosContentNext5, this.sosContentNext6, this.sosContentNext7);
    this.sosVideo = Utils.getSosAudioFileName();

    this.carAccidentShortNoticeLocation = getContext(this).resourceManager
      .getStringSync($r('app.string.Sos_Auto_Send_info_Detail_notice_dark_Two').id);
    this.carAccidentShortNoticeDisclaimer = getContext(this).resourceManager
      .getStringSync($r('app.string.car_accident_detection_disclaimer_in_short_notice').id);
    this.carAccidentShortNoticeServiceAndPrivacy = getContext(this).resourceManager
      .getStringSync($r('app.string.car_accident_detection_statement_on_service_and_privacy').id);
    this.carAccidentShortNoticePermission = getContext(this).resourceManager
      .getStringSync($r('app.string.Sos_Auto_Send_info_Detail_notice_active_two').id);
    this.carAccidentShortNoticeAll = getContext(this).resourceManager
      .getStringSync($r('app.string.car_accident_auto_call_notice_all').id, this.carAccidentShortNoticeLocation,
        this.carAccidentShortNoticeDisclaimer, this.carAccidentShortNoticeServiceAndPrivacy,
        this.carAccidentShortNoticePermission);
    this.carAccidentSosAudio = Utils.getPersonalSafetySosAudioFileName(CAR_ACCIDENT);
    this.fallDownShortNoticeLocation = getContext(this).resourceManager
      .getStringSync($r('app.string.Sos_Auto_Send_info_Detail_notice_dark_Two').id);
    this.fallDownShortNoticeDisclaimer = getContext(this).resourceManager
      .getStringSync($r('app.string.fall_down_detection_disclaimer_in_short_notice').id);
    this.fallDownShortNoticeServiceAndPrivacy = getContext(this).resourceManager
      .getStringSync($r('app.string.fall_down_detection_statement_on_service_and_privacy').id);
    this.fallDownShortNoticePermission = getContext(this).resourceManager
      .getStringSync($r('app.string.Sos_Auto_Send_info_Detail_notice_active_two').id);
    this.fallDownShortNoticeAll = getContext(this).resourceManager
      .getStringSync($r('app.string.fall_down_auto_call_notice_all').id, this.fallDownShortNoticeLocation,
        this.fallDownShortNoticeDisclaimer, this.fallDownShortNoticeServiceAndPrivacy,
        this.fallDownShortNoticePermission);
    this.fallDownSosAudio = Utils.getPersonalSafetySosAudioFileName(FALL_DOWN);

    getVersionName(ReportUtil.VERSION_NAME_EMPTY_VALUE, (version: string) => {
      ReportUtil.getInstance().setVersionName(version);
    });
    // 延时1s开启插画播放
    this.images = await this.getImageFrameInfoFromMedia();
    setTimeout(() => {
      this.animationStatus = AnimationStatus.Running;
    }, 1000);
  }

  async checkAmlStatus(): Promise<void> {
    this.refreshAmlSwitch();
    this.registerAmlSettings();
  }

  refreshAmlSwitch(): void {
    this.isShowHwAmlSwitch = AmlUtils.getIsOverseaShowAml(this.context);
    if (this.isShowHwAmlSwitch && this.amlShortNotiSpanData.length === 0) {
      let amlShortNotiString = this.context.resourceManager.getStringSync($r('app.string.aml_short_notification'));
      new ParseXmlUtil().parseXml(amlShortNotiString, this.amlShortNotiSpanData);
      this.isAmlEnabled = AmlUtils.isAmlSwitchEnabled(this.context);
    }
  }

  registerAmlSettings(): void {
    try {
      settings.registerKeyObserver(this.context, AmlUtils.IS_SHOW_AML_KEY, settings.domainName.USER_SECURITY, () => {
        LogUtils.i(TAG, 'recv aml show change');
        this.refreshAmlSwitch();
      });
    } catch (err) {
      LogUtils.e(TAG, `reg show aml err:${err?.code} ${err?.message}`);
    }
  }

  unRegisterAmlSettings(): void {
    try {
      settings.unregisterKeyObserver(this.context, AmlUtils.IS_SHOW_AML_KEY, settings.domainName.USER_SECURITY);
    } catch (err) {
      LogUtils.e(TAG, `un reg show aml err:${err?.code} ${err?.message}`);
    }
  }

  setSwitchStateInSetting(value: string) {
    LogUtils.i(TAG, 'setSwitchStateInSetting start');
    let context = this.context;
    if (!context) {
      return;
    }
    Utils.setSettingsState(context,
      EMERGENCY_POST_LOCATION_SWITCH,
      value
    );
    LogUtils.i(TAG, 'setSwitchStateInSetting :' + value);
  }

  getSwitchStateFromSetting() {
    LogUtils.i(TAG, 'getSwitchStateFromSetting start');
    let context = this.context;
    if (!context) {
      return EMERGENCY_POST_LOCATION_SWITCH_OFF;
    }
    let value = Utils.getSettingsState(context, EMERGENCY_POST_LOCATION_SWITCH,
      EMERGENCY_POST_LOCATION_SWITCH_OFF)
    LogUtils.i(TAG, 'getSwitchStateFromSetting :' + value);
    return value;
  }

  async getEmergencyContactsNoUseCatch(isSyncAutoSwitchState: boolean) {
    if (this.isRunningOfGetEmergencyContactsNoUseCatch) {
      return [];
    }
    this.isRunningOfGetEmergencyContactsNoUseCatch = true;
    try {
      const context = getContext(this);
      const contactList = await ContactsService.getInstance().syncAndGetEmergencyContactsFromDatabase(context);
      this.emergencyContactsNum = contactList.length;
      if (isSyncAutoSwitchState) {
        this.syncAutoSwitchStateAndEmergencyContacts(contactList);
      }
      this.isRunningOfGetEmergencyContactsNoUseCatch = false;
      return contactList || [];
    } catch (e) {
      LogUtils.e(TAG, `getEmergencyContactsNoUseCatch error: ${JSON.stringify(e)}`);
      this.isRunningOfGetEmergencyContactsNoUseCatch = false;
      return [];
    }
  }

  routerPathChange() {
    LogUtils.i(TAG, 'routerPathChange');
    if (this.isPlaying) {
      this.stopSosHelpAudio();
    }
    if (this.isCarAccidentAudioPlaying) {
      this.stopPlayCarAccidentSosAudio();
    }
    if (this.isFallDownAudioPlaying) {
      this.stopPlayFallDownSosAudio();
    }
    let pathSize: number = this.pathInfos.size();
    if (pathSize === 0) {
      this.getEmergencyContactsNoUseCatch(true);
    }
  }

  playSosHelpAudio() {
    if (this.isCarAccidentAudioPlaying) {
      this.stopPlayCarAccidentSosAudio();
    }
    if (this.isFallDownAudioPlaying) {
      this.stopPlayFallDownSosAudio();
    }
    this.isPlaying = true;
    const onPlayCompleted = () => {
      LogUtils.i(TAG, 'playSosHelpAudio:onPlayCompleted');
      this.isPlaying = false;
    }
    this.mediaPlayer.doPlay(this.sosVideo, onPlayCompleted);
    ReportUtil.getInstance().reportSosClickAuditionRecording();
  }

  stopSosHelpAudio(): void {
    this.isPlaying = false
    this.mediaPlayer.reset();
  }

  startPlayCarAccidentSosAudio() {
    if (this.isPlaying) {
      this.stopSosHelpAudio();
    }
    if (this.isFallDownAudioPlaying) {
      this.stopPlayFallDownSosAudio();
    }
    this.isCarAccidentAudioPlaying = true;
    ReportUtil.getInstance().reportCrashAudioRecordClick(PersonalSafetyReportSwitch.OPEN);
    const onPlayCompleted = () => {
      LogUtils.i(TAG, 'playCarAccidentSosAudio: onPlayCompleted');
      this.isCarAccidentAudioPlaying = false;
    }
    this.mediaPlayer.doPlay(this.carAccidentSosAudio, onPlayCompleted);
  }

  stopPlayCarAccidentSosAudio(): void {
    if (this.isCarAccidentAudioPlaying !== true) {
      return;
    }

    this.isCarAccidentAudioPlaying = false
    ReportUtil.getInstance().reportCrashAudioRecordClick(PersonalSafetyReportSwitch.CLOSE);
    this.mediaPlayer.reset();
  }

  startPlayFalldownSosAudio(): void {
    if (this.isPlaying) {
      this.stopSosHelpAudio();
    }
    if (this.isCarAccidentAudioPlaying) {
      this.stopPlayCarAccidentSosAudio();
    }
    this.isFallDownAudioPlaying = true;
    ReportUtil.getInstance().reportFallAudioRecordClick(PersonalSafetyReportSwitch.OPEN);
    const onPlayCompleted = () => {
      LogUtils.i(TAG, 'startPlayFalldownSosAudio: onPlayCompleted');
      this.isFallDownAudioPlaying = false;
    }
    this.mediaPlayer.doPlay(this.fallDownSosAudio, onPlayCompleted);
  }

  stopPlayFallDownSosAudio(): void {
    if (this.isFallDownAudioPlaying !== true) {
      return;
    }

    this.isFallDownAudioPlaying = false
    ReportUtil.getInstance().reportFallAudioRecordClick(PersonalSafetyReportSwitch.CLOSE);
    this.mediaPlayer.reset();
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear')
    this.mediaPlayer.release()
    this.permissionDescriptionDialog1 = null
    this.permissionDescriptionDialog2 = null
    this.permissionDescriptionDialogforCarAccident = null;
    this.permissionDescriptionDialogforFallDown = null;
    try {
      display.off('change', this.displayChangeCallback);
    } catch (e) {
      LogUtils.i(TAG, 'display off change failed, error:' + JSON.stringify(e));
    }
    this.images = [];
    this.unRegisterAmlSettings();
  }

  @BuilderParam sateEmergencyInfoUIExtension: (previousPage: string) => void
  @BuilderParam sateEmergencyContactsEdit: () => void
  @BuilderParam sateEmergencyContactsInfo: (previousPage: string) => void

  async loadPage(key: string): Promise<void> {
    try {
      if (key === 'EmergencyInfoView') {
        let pageObj = await import('./EmergencyInfoUIExtension')
        this.sateEmergencyInfoUIExtension = pageObj.sateEmergencyInfoUIExtension
      } else if (key === 'EmergencyContactsEdit') {
        let pageObj = await import('./EmergencyContactsEdit')
        this.sateEmergencyContactsEdit = pageObj.sateEmergencyContactsEdit
      } else if (key === 'EmergencyContactsInfo') {
        let pageObj = await import('./EmergencyContactsInfo');
        this.sateEmergencyContactsInfo = pageObj.EmergencyContactsInfoBuilder;
      }
    } catch (e) {
      LogUtils.e(TAG, 'loadPage failed: ' + JSON.stringify(e));
    }
  }

  @Builder
  myRouter(name: string) {
    if (name === 'EmergencyInfoView') {
      this.sateEmergencyInfoUIExtension(SosEmergencyHelpSettings.PAGE_NAME);
    } else if (name === 'EmergencyContactsEdit') {
      this.sateEmergencyContactsEdit();
    } else if (name === 'EmergencyContactsInfo') {
      this.sateEmergencyContactsInfo(SosEmergencyHelpSettings.PAGE_NAME);
    } else if (name === 'amlprivacyStatement') {
      AmlPrivacyStatement();
    }
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
    .padding({ left: 8, right: 8 })
    .borderRadius(16)
    .constraintSize({ minHeight: '64vp' })
    .opacity(1)
  }

  @Styles
  titleStyle() {
    .size({ height: '100%', width: '100%' })
    .padding({
      start: isTablet() ? LengthMetrics.vp(24) : LengthMetrics.vp(16),
    })
  }

  @Builder
  PersonalEmergencyContact() {
    Column() {
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Column() {
          Text($r('app.string.personalEmergencyInfo'))
            .fontSize($r('sys.float.ohos_id_text_size_sub_title2'))
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Medium)
          Text($r('app.string.Sos_emergency_personal_info'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Regular)
            .margin({ top: 2 })
        }.alignItems(HorizontalAlign.Start)

        Image($r('app.media.ic_next'))
          .fillColor($r('sys.color.ohos_id_color_fourth'))
          .height('24vp')
          .width('12vp')
          .matchTextDirection(true)
          .draggable(false)
          .margin({ start: LengthMetrics.vp(16) })
      }
      .width('100%')
      .padding({ left: 12, right: 12 })
      .margin({
        top: this.fontSizeScale < 1.75 ? '' : this.topAndBottomMarginOnScale,
        bottom: this.fontSizeScale < 1.75 ? '' : this.topAndBottomMarginOnScale
      })
      .constraintSize({ minHeight: '64vp' })
      .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
      .hoverEffect(HoverEffect.Highlight)
      .borderRadius(20)
      .stateStyles({
        pressed: {
          .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
          .opacity(1)
        },
      })
      .onClick(() => {
        DynamicLoader.getInstance().callFunction('EmergencyInfoView').then(() => {
          this.pathInfos.pushPathByName('EmergencyInfoView', '');
          ReportUtil.getInstance().reportSosClickPersonalInfo();
        })
      })
    }
    .borderRadius(20)
    .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
    .padding({ left: 0, right: 0 })
    .expandSafeArea([SafeAreaType.KEYBOARD])
    .constraintSize({ minHeight: '64vp' })
  }

  @Builder
  EmergencyContact() {
    if (this.fontSizeScale < 1.75) {
      Column() {
        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
          Column() {
            Text($r('app.string.emergencyContact'))
              .fontSize($r('sys.float.ohos_id_text_size_sub_title2'))
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .fontFamily('HarmonyHeiTi')
              .fontWeight(FontWeight.Medium)
          }
          .alignItems(HorizontalAlign.Start)
          .constraintSize({ maxWidth: '55%' })
          .margin({ end: LengthMetrics.vp(16) })

          Column() {
            Row() {
              Text(this.emergencyContactsNum ? $r('app.string.peopleAdded', this.emergencyContactsNum) :
              $r('app.string.notAdded'))
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.Body_M'))
                .fontWeight(FontWeight.Regular)

              Image($r('app.media.ic_next'))
                .width(12)
                .height(24)
                .matchTextDirection(true)
                .draggable(false)
                .margin({ start: LengthMetrics.resource($r('sys.float.padding_level2')) })
                .fillColor($r('sys.color.icon_fourth'))
            }
          }.alignItems(HorizontalAlign.End);
        }
        .onClick(() => {
          DynamicLoader.getInstance().callFunction('EmergencyContactsInfo').then(() => {
            this.pathInfos.pushPathByName('EmergencyContactsInfo', '');
            ReportUtil.getInstance().reportSosClickEmergencyContacts();
          })
        })
        .width('100%')
        .constraintSize({ minHeight: '48vp' })
        .margin({
          top: this.fontSizeScale < 1.75 ? '' : this.topAndBottomMarginOnScale,
          bottom: this.fontSizeScale < 1.75 ? '' : this.topAndBottomMarginOnScale
        })
        .padding({ left: 12, right: 12})
        .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
        .hoverEffect(HoverEffect.Highlight)
        .borderRadius(20)
        .stateStyles({
          pressed: {
            .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
            .opacity(1)
          },
        })
      }
      .borderRadius(20)
      .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
      .padding({ left: 0, right: 0 })
      .expandSafeArea([SafeAreaType.KEYBOARD])
      .constraintSize({ minHeight: '48vp' })
    } else {
      Column() {
        Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
            Column() {
              Text($r('app.string.emergencyContact'))
                .fontSize($r('sys.float.ohos_id_text_size_sub_title2'))
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .fontFamily('HarmonyHeiTi')
                .fontWeight(FontWeight.Medium)
            }
          }
          .width('100%')
          .borderRadius(20)

          Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
            Text(this.emergencyContactsNum ? $r('app.string.peopleAdded', this.emergencyContactsNum) :
            $r('app.string.notAdded'))
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.Body_M'))
              .fontWeight(FontWeight.Regular)

            Image($r('app.media.ic_next'))
              .width(12)
              .height(24)
              .matchTextDirection(true)
              .draggable(false)
              .margin({ start: LengthMetrics.resource($r('sys.float.padding_level2')) })
              .fillColor($r('sys.color.icon_fourth'))
          }
          .width('100%')
          .margin({
            top: 2,
          })
          .borderRadius(20)
        }
        .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
        .hoverEffect(HoverEffect.Highlight)
        .stateStyles({
          pressed: this.pressedStyles,
        })
        .padding({ left: 12, right: 12 })
        .margin({
          top: this.fontSizeScale < 1.75 ? '' : this.topAndBottomMarginOnScale,
          bottom: this.fontSizeScale < 1.75 ? '' : this.topAndBottomMarginOnScale,
        })
      }
      .onClick(() => {
        DynamicLoader.getInstance().callFunction('EmergencyContactsInfo').then(() => {
          this.pathInfos.pushPathByName('EmergencyContactsInfo', '');
        })
      })
      .borderRadius(20)
      .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
      .padding({ left: 0, right: 0 })
      .expandSafeArea([SafeAreaType.KEYBOARD])
      .constraintSize({ minHeight: '64vp' })
    }
  }

  @Builder
  autoSendMessage() {
    Column() {
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Column() {
          Text($r('app.string.Sos_Auto_Send_info'))
            .fontSize($r('sys.float.ohos_id_text_size_sub_title2'))
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Medium)
          Flex() {
            Text(this.context.resourceManager.getPluralStringValueSync($r('app.plural.Sos_Auto_Send_info_Detail')
              .id, 5))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .fontFamily('HarmonyHeiTi')
              .fontWeight(FontWeight.Regular)
          }.margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .layoutWeight(1)
        .accessibilityGroup(true)
        .accessibilityLevel('no')

        Toggle({
          type: ToggleType.Switch,
          isOn: this.autoSendSOSMessageSwitchState
        })
          .onChange((isOn: boolean) => {
           this.onAutoSendSOSMessageToggleChange(isOn);
          })
          .width(36)
          .height(20)
          .margin({ start: LengthMetrics.vp(8), end: LengthMetrics.vp(12) })
      }
      .margin({
        top: this.getDeviceAndDirectionInfo() ? 0 : this.fontSizeScale < 1.75 ? 8 : this.topAndBottomMarginOnScale,
        bottom: this.getDeviceAndDirectionInfo() ? 0 : this.fontSizeScale < 1.75 ? 8 : this.topAndBottomMarginOnScale
      })
      .constraintSize({
        minHeight: this.getDeviceAndDirectionInfo() ? '64vp' : 0
      })
      .width('100%')
      .padding({ start: LengthMetrics.vp(12) })
      .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
      .borderRadius(20)
      .backgroundImagePosition(Alignment.End)
      .accessibilityText(`${EmergencyCallController.getInstance()
        .formatResourceToString($r('app.string.Sos_Auto_Send_info'))} ${
        this.context.resourceManager.getPluralStringValueSync($r('app.plural.Sos_Auto_Send_info_Detail').id, 5)}`)
    }
    .borderRadius(20)
    .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
    .constraintSize({ minHeight: 64 })
    .expandSafeArea([SafeAreaType.KEYBOARD])
  }

  @Builder
  buildPersonalSafetyAutoCallFuncArea(type: PersonalSafetyAccidentType) {
    Column() {
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Column() {
          Text(type == CAR_ACCIDENT ? $r('app.string.car_accident_auto_call_for_help_title') :
            (type == FALL_DOWN ? $r('app.string.fall_down_auto_call_for_help_title') : 'none'))
            .fontSize($r('sys.float.ohos_id_text_size_sub_title2'))
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Medium)
          Flex() {
            Text(type === CAR_ACCIDENT ?
            this.context.resourceManager.getPluralStringValueSync($r('app.plural.Sos_Car_Accident_Auto_Call_for_Help_Description')
              .id, PERSONAL_SAFETY_COUNT_DOWN_VALUE) : (type === FALL_DOWN ?
              this.context.resourceManager.getPluralStringValueSync($r('app.plural.Sos_Fall_Down_Auto_Call_for_Help_Description')
                .id, PERSONAL_SAFETY_COUNT_DOWN_VALUE) : 'none'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .fontFamily('HarmonyHeiTi')
              .fontWeight(FontWeight.Regular)
          }
          .margin({ top: 2 })
        }.alignItems(HorizontalAlign.Start).layoutWeight(1).width('100%')

        Toggle({
          type: ToggleType.Switch,
          isOn: this.getAutoCallSwitchState(type)
        })
          .onChange((isOn: boolean) => {
            this.onPersonalSafetyAutoCallforHelpToggleChange(type, isOn);
          })
          .width(36)
          .height(20)
          .margin({ start: LengthMetrics.vp(6), end: LengthMetrics.vp(9) })
      }
      .width('100%')
      .margin({
        top: this.getDeviceAndDirectionInfo() ? 0 : this.fontSizeScale < 1.75 ? 8 : this.topAndBottomMarginOnScale,
        bottom: this.getDeviceAndDirectionInfo() ? 0 : this.fontSizeScale < 1.75 ? 8 : this.topAndBottomMarginOnScale
      })
      .constraintSize({
        minHeight: this.getDeviceAndDirectionInfo() ? '64vp' : 0
      })
      .padding({ start: LengthMetrics.vp(12) })
      .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
      .borderRadius(20)

      EmergencyWarningDivider().padding({ left: 4, right: 4 });

      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Text($r('app.string.Sos_Auto_Call_Test'))
          .fontSize($r('sys.float.ohos_id_text_size_sub_title2'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Medium)
        Image((type === CAR_ACCIDENT ? this.isCarAccidentAudioPlaying :
          (type === FALL_DOWN ? this.isFallDownAudioPlaying : false)) ? $r('app.media.ic_public_pause_norm') :
        $r('app.media.ic_public_play_norm'))
          .height(24)
          .width(24)
          .fillColor($r('sys.color.ohos_id_color_text_primary'))
          .margin({ start: LengthMetrics.vp(16) })
          .matchTextDirection(true)
      }
      .width('100%')
      .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
      .hoverEffect(HoverEffect.Highlight)
      .constraintSize({ minHeight: this.fontSizeScale < 1.75 ? '48vp' : '' })
      .padding({ left: 12, right: 9 })
      .borderRadius(16)
      .stateStyles({
        pressed: {
          .backgroundColor($r('sys.color.interactive_click'))
          .opacity(1)
        },
      })
      .onClick(() => {
        if (type === CAR_ACCIDENT) {
          if (this.isCarAccidentAudioPlaying) {
            this.stopPlayCarAccidentSosAudio();
          } else {
            this.startPlayCarAccidentSosAudio();
          }
        } else if (type === FALL_DOWN) {
          if (this.isFallDownAudioPlaying) {
            this.stopPlayFallDownSosAudio();
          } else {
            this.startPlayFalldownSosAudio();
          }
        }
      })
    }
    .borderRadius(20)
    .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
    .padding({ left: 3, right: 3 })
  }

  @Builder
  autoSendLocationMessageWhenCall() {
    Column() {
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Column() {
          Text($r('app.string.Sos_Auto_Send_Location_When_Call'))
            .fontSize($r('sys.float.ohos_id_text_size_sub_title2'))
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
          Flex() {
            Text($r('app.string.Sos_Auto_Send_Location_When_Call_Detail'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .fontFamily('HarmonyHeiTi')
              .fontWeight(FontWeight.Regular)
          }
          .margin({ top: 2 })
        }.alignItems(HorizontalAlign.Start).width('100%').layoutWeight(1)

        Toggle({
          type: ToggleType.Switch,
          isOn: false
        })
          .onChange(() => {
          })
          .width(36)
          .height(20)
          .margin({ left: 8, right: 12 })

      }
      .margin({ top: 14, bottom: 14 })
      .width('100%')
      .padding({ left: 12 })
      .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
      .borderRadius(20)
    }
    .borderRadius(20)
    .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
    .expandSafeArea([SafeAreaType.KEYBOARD])
  }

  @Builder
  serviceSwitch(title: Resource, summary: Resource, isEnable: boolean, onClickFunction: (isOn: boolean) => void) {
    Column() {
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Column() {
          Text(title)
            .fontSize($r('sys.float.ohos_id_text_size_sub_title2'))
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Medium)
          Flex() {
            Text(summary)
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .fontFamily('HarmonyHeiTi')
              .fontWeight(FontWeight.Regular)
          }
          .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .layoutWeight(1)
        .accessibilityGroup(true)
        .accessibilityLevel('no')

        this.sosSendLocationToggle(isEnable, onClickFunction)
      }
      .margin({
        top: this.getDeviceAndDirectionInfo() ? 0 : this.fontSizeScale < 1.75 ? 8 : this.topAndBottomMarginOnScale,
        bottom: this.getDeviceAndDirectionInfo() ? 0 : this.fontSizeScale < 1.75 ? 8 : this.topAndBottomMarginOnScale
      })
      .constraintSize({
        minHeight: this.getDeviceAndDirectionInfo() ? '64vp' : 0
      })
      .width('100%')
      .padding({ start: LengthMetrics.vp(12) })
      .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
      .borderRadius(20)
    }
    .borderRadius(20)
    .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
    .expandSafeArea([SafeAreaType.KEYBOARD])
    .accessibilityText(`${EmergencyCallController.getInstance()
      .formatResourceToString(title)} ${EmergencyCallController.getInstance().formatResourceToString(summary)}`)
  }

  @Builder
  sosSendLocationToggle(isEnable: boolean, onClickFunction: (isOn: boolean) => void) {
    Column() {
      if (isEnable) {
        Toggle({
          type: ToggleType.Switch,
          isOn: $$this.isAmlEnabled,
        })
          .onChange((isOn: boolean) => {
            onClickFunction(isOn);
            ReportUtil.getInstance().reportSosClickLocationsSwitch(Number(isOn));
          })
          .width(36)
          .height(20)
          .margin({ start: LengthMetrics.vp(8), end: LengthMetrics.vp(12) });
      } else {
        Toggle({
          type: ToggleType.Switch,
          isOn: $$this.sosSendLocationInfo,
        })
          .onChange((isOn: boolean) => {
            onClickFunction(isOn);
            ReportUtil.getInstance().reportSosClickLocationsSwitch(Number(isOn));
          })
          .width(36)
          .height(20)
          .margin({ start: LengthMetrics.vp(8), end: LengthMetrics.vp(12) });
      }
    }.margin({ start: LengthMetrics.resource($r('sys.float.ohos_id_text_margin_horizontal')) })
  }

  @Builder
  PermissionDescriptionContent(infoTitle: ResourceStr, itemName1: ResourceStr, itemSummary1: ResourceStr,
    itemName2?: ResourceStr, itemSummary2?: ResourceStr) {
    Scroll() {
      Column() {
        Text(infoTitle)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontWeight(FontWeight.Regular)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .lineHeight(19)
          .width('100%')
        Text(itemName1)
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontWeight(FontWeight.Regular)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .lineHeight(21)
          .margin({ top: 16 })
          .width('100%')
        Row() {
          Text(itemSummary1)
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontWeight(FontWeight.Regular)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .lineHeight(19)
            .width('100%')
        }.margin({ top: 2 })

        if (itemName2 && itemSummary2) {
          Divider()
            .strokeWidth('1px')
            .color($r('sys.color.ohos_id_color_list_separator'))
            .lineCap(LineCapStyle.Round)
            .width('100%')
            .margin({ top: 8 })
          Text(itemName2)
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontWeight(FontWeight.Regular)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .lineHeight(21)
            .margin({ top: 8})
            .width('100%')
          Row() {
            Text(itemSummary2)
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Regular)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .lineHeight(19)
              .width('100%')
          }.margin({ top: 2 })
        }
      }
      .width('100%')
    }
    .nestedScroll({scrollForward: NestedScrollMode.PARALLEL, scrollBackward: NestedScrollMode.PARALLEL})
  }

  @Builder
  personalSafetyPermissionDescriptionContent(type: PersonalSafetyAccidentType, infoTitle: ResourceStr,
    itemName1: ResourceStr) {
    Scroll() {
      Column() {
        Text(infoTitle)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontWeight(FontWeight.Regular)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .lineHeight(19)
          .width('100%')
        Text(itemName1)
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontWeight(FontWeight.Regular)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .lineHeight(21)
          .margin({ top: 16 })
          .width('100%')
        Row() {
          Text(type === CAR_ACCIDENT ? $r('app.string.Sos_Permission_Description_3') :
            (type === FALL_DOWN ? $r('app.string.Sos_Permission_Description_3') : ''))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontWeight(FontWeight.Regular)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .lineHeight(19)
            .width('100%')
        }.margin({ top: 2 })
      }
      .width('100%')
    }
    .nestedScroll({scrollForward: NestedScrollMode.PARALLEL, scrollBackward: NestedScrollMode.PARALLEL})
  }

  @Builder
  PermissionDescriptionContent2() {
    Scroll() {
      Column() {
        Text(this.context.resourceManager.getPluralStringValueSync($r('app.plural.Sos_Permission_Description_1').id, 1))
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontWeight(FontWeight.Regular)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .lineHeight(19)
          .width('100%')
        Text($r('app.string.EmergencyWarningSettings_4'))
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontWeight(FontWeight.Regular)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .lineHeight(21)
          .margin({ top: 16 })
          .width('100%')
        Row() {
          Text($r('app.string.Sos_Permission_Description_2'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontWeight(FontWeight.Regular)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .lineHeight(19)
            .width('100%')
        }.margin({ top: 2 })
      }
      .width('100%')
    }
    .nestedScroll({scrollForward: NestedScrollMode.PARALLEL, scrollBackward: NestedScrollMode.PARALLEL})
  }

  @Builder
  DisclaimerDescriptionContent(type: PersonalSafetyAccidentType) {
    Scroll() {
      Column() {
        Text(type === CAR_ACCIDENT ? $r('app.string.car_accident_detection_disclaimer_content_one') :
          (type === FALL_DOWN ? $r('app.string.fall_down_detection_disclaimer_content_one') : ''))
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontWeight(FontWeight.Regular)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .lineHeight(21)
          .margin({ top: 16 })
          .width('100%')

        Text(type === CAR_ACCIDENT ? $r('app.string.car_accident_detection_disclaimer_content_two') :
          (type === FALL_DOWN ? $r('app.string.fall_down_detection_disclaimer_content_two') : ''))
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontWeight(FontWeight.Regular)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .lineHeight(21)
          .margin({ top: 16 })
          .width('100%')
        Text(type === CAR_ACCIDENT ? $r('app.string.car_accident_detection_disclaimer_content_three') :
          (type === FALL_DOWN ? $r('app.string.fall_down_detection_disclaimer_content_three') : ''))
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontWeight(FontWeight.Regular)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .lineHeight(21)
          .margin({ top: 16 })
          .width('100%')
        Text(type === CAR_ACCIDENT ? $r('app.string.car_accident_detection_disclaimer_content_four') :
          (type === FALL_DOWN ? $r('app.string.fall_down_detection_disclaimer_content_four') : ''))
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontWeight(FontWeight.Regular)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .lineHeight(21)
          .margin({ top: 16 })
          .width('100%')
      }
      .width('100%')
    }
    .nestedScroll({scrollForward: NestedScrollMode.PARALLEL, scrollBackward: NestedScrollMode.PARALLEL})
    .padding({
      start: LengthMetrics.vp(8),
      end: LengthMetrics.vp(8)
    })
  }

  private sosLocationSwitch = async (isOn: boolean) => {
    if (isOn) {
      LogUtils.i(TAG, 'sosLocationSwitch isOn')
      let locationAccess = await checkAccess()
      if (locationAccess) {
        LogUtils.i(TAG, 'locationAccess true')
        this.setSwitchStateInSetting(EMERGENCY_POST_LOCATION_SWITCH_ON)
      } else {
        LogUtils.i(TAG, 'locationAccess false')
        let requestOk = await requestPermissionFromUsers(this.context)
        if (requestOk) {
          LogUtils.i(TAG, 'requestOk ok')
          this.setSwitchStateInSetting(EMERGENCY_POST_LOCATION_SWITCH_ON)
        } else {
          Prompt.showToast({
            message: this.context.resourceManager.getStringSync($r('app.string.earthquake_location_notice')),
            duration: 5000
          })
          this.sosSendLocationInfo = false
          this.setSwitchStateInSetting(EMERGENCY_POST_LOCATION_SWITCH_OFF)
          LogUtils.i(TAG, 'requestOk false')
        }
      }
    } else {
      LogUtils.i(TAG, 'sosLocationSwitch isOff')
      this.setSwitchStateInSetting(EMERGENCY_POST_LOCATION_SWITCH_OFF)
    }
  }
  permissionDescriptionDialog1: CustomDialogController | null = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.Sos_Permission_Title_2'),
      contentBuilder: () => {
        this.PermissionDescriptionContent(
          this.context.resourceManager.getPluralStringValueSync($r('app.plural.Sos_Permission_Description_1').id, 1),
          $r('app.string.EmergencyWarningSettings_4'), $r('app.string.Sos_Permission_Description_3'))
      },
      buttons: [{
        value: $r('app.string.determine'),
        action: () => {
        },
      },
      ]
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    showInSubWindow: true
  })
  permissionDescriptionDialog2: CustomDialogController | null = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.Sos_Permission_Title_1'),
      contentBuilder: () => {
        this.PermissionDescriptionContent2()
      },
      buttons: [{
        value: $r('app.string.determine'),
        action: () => {
        },
      },
      ]
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    showInSubWindow: true
  })

  disclaimerDescriptionDialogforCarAccident: CustomDialogController | null = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.car_accident_detection_disclaimer'),
      contentBuilder: () => {
        this.DisclaimerDescriptionContent(CAR_ACCIDENT)
      },
      buttons: [{
        value: $r('app.string.determine'),
        action: () => {
          ReportUtil.getInstance().reportCrashDisclaimerClick(PersonalSafetyReportSwitch.CLOSE);
        },
      },
      ]
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    showInSubWindow: true
  })
  disclaimerDescriptionDialogforFalldown: CustomDialogController | null = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.fall_down_detection_disclaimer'),
      contentBuilder: () => {
        this.DisclaimerDescriptionContent(FALL_DOWN)
      },
      buttons: [{
        value: $r('app.string.determine'),
        action: () => {
          ReportUtil.getInstance().reportFallDisclaimerClick(0);
        },
      },
      ]
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    showInSubWindow: true
  })

  permissionDescriptionDialogforCarAccident: CustomDialogController | null = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.car_accident_permission_title'),
      contentBuilder: () => {
        this.personalSafetyPermissionDescriptionContent(CAR_ACCIDENT,
          this.context.resourceManager.getPluralStringValueSync($r('app.plural.Sos_Car_Accident_Permission_Description')
            .id, 1), $r('app.string.EmergencyWarningSettings_4'))
      },
      buttons: [{
        value: $r('app.string.determine'),
        action: () => {
          ReportUtil.getInstance().reportCrashPermissionClick(PersonalSafetyReportSwitch.CLOSE);
        },
      },
      ]
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    showInSubWindow: true
  })
  permissionDescriptionDialogforFallDown: CustomDialogController | null = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.fall_down_permission_title'),
      contentBuilder: () => {
        this.personalSafetyPermissionDescriptionContent(FALL_DOWN,
          this.context.resourceManager.getPluralStringValueSync($r('app.plural.Sos_Fall_Down_Permission_Description')
            .id, 1), $r('app.string.EmergencyWarningSettings_4'))
      },
      buttons: [{
        value: $r('app.string.determine'),
        action: () => {
          ReportUtil.getInstance().reportFallPermissionClick(PersonalSafetyReportSwitch.CLOSE);
        },
      },
      ]
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    showInSubWindow: true
  })

  permissionDescriptionDialogAml: CustomDialogController | null = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.aml_permission_dialog_title'),
      contentBuilder: () => {
        this.PermissionDescriptionContent($r('app.string.aml_permission_info_title'),
          $r('app.string.EmergencyWarningSettings_4'), $r('app.string.aml_permission_location_info'))
      },
      buttons: [{
        value: $r('app.string.determine'),
        action: () => {
        },
      },
      ]
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
  });

  @Builder
  buildAreaContent() {
    Text() {
      ForEach(this.getTextListFirst(this.sosContentAll, this.sosContent1, this.sosContent3,
        this.sosContent4),
        (item: string) => {
          this.buildAreaItemFirst(item, this.sosContent1, this.sosContent3, this.sosContent4, 1)
        });
    }
    .width('100%')
    .padding({ left: 12, right: 12 })
    .fontColor($r('sys.color.font_secondary'))
    .fontSize($r('sys.float.Body_M'))
    .fontWeight(FontWeight.Regular)
    .textAlign(TextAlign.Start)
  }

  @Builder
  buildPersonalSafetyNoticeArea(type: PersonalSafetyAccidentType) {
    Text() {
      if (type === CAR_ACCIDENT) {
        ForEach(this.getPersonalSafetyTextList(this.carAccidentShortNoticeAll, this.carAccidentShortNoticeLocation,
          this.carAccidentShortNoticeDisclaimer, this.carAccidentShortNoticeServiceAndPrivacy,
          this.carAccidentShortNoticePermission),
          (item: string) => {
            this.buildPersonalSafetyAreaItem(CAR_ACCIDENT, item, this.carAccidentShortNoticeDisclaimer,
              this.carAccidentShortNoticeServiceAndPrivacy, this.carAccidentShortNoticePermission);
          });
      } else if (type === FALL_DOWN) {
        ForEach(this.getPersonalSafetyTextList(this.fallDownShortNoticeAll, this.fallDownShortNoticeLocation,
          this.fallDownShortNoticeDisclaimer, this.fallDownShortNoticeServiceAndPrivacy,
          this.fallDownShortNoticePermission),
          (item: string) => {
            this.buildPersonalSafetyAreaItem(FALL_DOWN, item, this.fallDownShortNoticeDisclaimer,
              this.fallDownShortNoticeServiceAndPrivacy, this.fallDownShortNoticePermission);
          });
      }
    }
    .width('100%')
    .padding({ left: 12, right: 12 })
    .fontColor($r('sys.color.font_secondary'))
    .fontSize($r('sys.float.Body_M'))
    .fontWeight(FontWeight.Regular)
    .textAlign(TextAlign.Start)
  }

  @Builder
  buildServiceShortNotification() {
    Text() {
      if (this.isShowHwAmlSwitch) {
        ForEach(this.amlShortNotiSpanData, (item: SpanNodeInfo) => {
          this.buildShortNotificationStyle(item)
        })
      } else {
        ForEach(this.getReportLocationTextList(this.sosContentNextAll, this.sosContentNext1, this.sosContentNext2,
          this.sosContentNext3, this.sosContentNext4, this.sosContentNext5, this.sosContentNext6, this.sosContentNext7),
          (item: string) => {
            this.buildAreaItem(item, this.sosContentNext1,
              this.sosContentNext3, this.sosContentNext5, this.sosContentNext7, 2)
          });
      }
    }
    .width('100%')
    .padding({ left: 12, right: 12 })
    .fontColor($r('sys.color.font_secondary'))
    .fontSize($r('sys.float.Body_M'))
    .fontWeight(FontWeight.Regular)
    .textAlign(TextAlign.Start)
  }

  @Builder
  buildAreaItemFirst(item: string, sosContent1: string, sosContent3: string,
    sosContent4: string, sosContentNum: number) {
    Span(item)
      .fontColor((item === sosContent3 || item === sosContent4 ? $r('sys.color.ohos_id_color_text_primary_activated') :
      $r('sys.color.ohos_id_color_text_secondary')))
      .fontSize(10)
      .fontWeight(FontWeight.Medium)
      .onClick(() => {
        if (item === sosContent3 && sosContentNum === 1) {
          this.pathInfos.pushPath({ name: 'SosPrivacyStatement', param: 'note' }, false);
        } else if (item === sosContent3 && sosContentNum === 2) {
          this.pathInfos.pushPath({ name: 'SosPrivacyStatement', param: 'location' }, false);
        } else if (item === sosContent4 && sosContentNum === 1) {
          if (this.isPlaying) {
            this.stopSosHelpAudio();
          }
          this.permissionDescriptionDialog1?.open()
        } else if (item === sosContent4 && sosContentNum === 2) {
          if (this.isPlaying) {
            this.stopSosHelpAudio();
          }
          this.permissionDescriptionDialog2?.open()
        }
      })
  }

  @Builder
  buildAreaItem(item: string, sosContent1: string, sosContent3: string,
    sosContent4: string, sosContent5: string, sosContentNum: number) {
    Span(item)
      .fontColor(item === sosContent1 ? $r('sys.color.ohos_id_color_text_primary') :
        (item === sosContent3 || item === sosContent4 || item === sosContent5 ?
        $r('sys.color.ohos_id_color_text_primary_activated') :
        $r('sys.color.ohos_id_color_text_secondary')))
      .fontSize(10)
      .fontWeight(FontWeight.Medium)
      .onClick(async () => {
        if (item === sosContent3 && sosContentNum === 1) {
          this.pathInfos.pushPath({ name: 'SosPrivacyStatement', param: 'note' }, false);
        } else if (item === sosContent5 && sosContentNum === 2) {
          await EmergencyWarningController.getInstance().readValueFromConfigJSON(this.context);
          this.openLink(EmergencyWarningController.getInstance().mapName2Value.get('location_net_privacy_url'));
        } else if (item === sosContent4 && sosContentNum === 2) {
          await EmergencyWarningController.getInstance().readValueFromConfigJSON(this.context);
          this.openLink(EmergencyWarningController.getInstance().mapName2Value.get('eps_privacy_url'));
        } else if (item === sosContent4 && sosContentNum === 1) {
          if (this.isPlaying) {
            this.stopSosHelpAudio();
          }
          if (this.isCarAccidentAudioPlaying) {
            this.stopPlayCarAccidentSosAudio();
          }
          if (this.isFallDownAudioPlaying) {
            this.stopPlayFallDownSosAudio();
          }
          this.permissionDescriptionDialog1?.open()
        } else if (item === sosContent3 && sosContentNum === 2) {
          if (this.isPlaying) {
            this.stopSosHelpAudio();
          }
          if (this.isCarAccidentAudioPlaying) {
            this.stopPlayCarAccidentSosAudio();
          }
          if (this.isFallDownAudioPlaying) {
            this.stopPlayFallDownSosAudio();
          }
          this.permissionDescriptionDialog2?.open()
        }
      })
  }

  private openLink(link: string) {
    if (StringUtil.isEmpty(link)) {
      LogUtils.e(TAG, 'The link error.');
      return;
    }
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    let options: OpenLinkOptions = {
      appLinkingOnly: false
    };
    context.openLink(link, options)
      .then(() => {
        LogUtils.i(TAG, 'openLink success.');
      })
      .catch((err: BusinessError) => {
        LogUtils.i(TAG, `openLink failed. Code is ${err.code}, message is ${err.message}`);
      });
  }

  @Builder
  buildPersonalSafetyAreaItem(type: PersonalSafetyAccidentType, item: string, sosContent1: string, sosContent2: string,
    sosContent3: string) {
    Span(item)
      .fontColor(item === sosContent1 || item === sosContent2 || item === sosContent3 ?
      $r('sys.color.ohos_id_color_text_primary_activated') : $r('sys.color.ohos_id_color_text_secondary'))
      .fontSize(10)
      .fontWeight(item === sosContent1 || item === sosContent2 || item === sosContent3 ?
      FontWeight.Medium : FontWeight.Regular)
      .onClick(() => {
        if (type === CAR_ACCIDENT) {
          if (item === sosContent1) {
            ReportUtil.getInstance().reportCrashDisclaimerClick(PersonalSafetyReportSwitch.OPEN);
            this.disclaimerDescriptionDialogforCarAccident?.open()
          } else if (item === sosContent2) {
            ReportUtil.getInstance().reportCrashPrivacyClick(PersonalSafetyReportSwitch.OPEN);
            this.pathInfos.pushPath({ name: 'SosPrivacyStatement', param: CAR_ACCIDENT }, false);
          } else if (item === sosContent3) {
            ReportUtil.getInstance().reportCrashPermissionClick(PersonalSafetyReportSwitch.OPEN);
            this.permissionDescriptionDialogforCarAccident?.open()
          }
        } else if (type === FALL_DOWN) {
          if (item === sosContent1) {
            ReportUtil.getInstance().reportFallDisclaimerClick(PersonalSafetyReportSwitch.OPEN);
            this.disclaimerDescriptionDialogforFalldown?.open()
          } else if (item === sosContent2) {
            ReportUtil.getInstance().reportFallPrivacyClick(PersonalSafetyReportSwitch.OPEN);
            this.pathInfos.pushPath({ name: 'SosPrivacyStatement', param: FALL_DOWN }, false);
          } else if (item === sosContent3) {
            ReportUtil.getInstance().reportFallPermissionClick(PersonalSafetyReportSwitch.OPEN);
            this.permissionDescriptionDialogforFallDown?.open()
          }
        }
      })
  }

  @Builder
  buildShortNotificationStyle(item: SpanNodeInfo) {
    Span(item.content)
      .fontColor(item.textStyle === 'bold' ? $r('sys.color.ohos_id_color_text_primary') :
        (item.textStyle === 'privacyStatement' || item.textStyle === 'permission' ?
        $r('sys.color.ohos_id_color_text_primary_activated') : $r('sys.color.ohos_id_color_text_secondary')))
      .fontSize(10)
      .fontWeight(FontWeight.Medium)
      .onClick(() => {
        if (item.textStyle === 'privacyStatement') {
          this.pathInfos.pushPathByName('amlprivacyStatement', '');
        } else if (item.textStyle === 'permission') {
          this.permissionDescriptionDialogAml?.open()
        }
      })
  }

  @Builder
  autoCallForHelp() {
    Column() {
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Column() {
          Text($r('app.string.Sos_Auto_Call'))
            .fontSize($r('sys.float.ohos_id_text_size_sub_title2'))
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Medium)
          Flex() {
            Text(this.context.resourceManager.getPluralStringValueSync($r('app.plural.Sos_Auto_Call_Detail').id, 5))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .fontFamily('HarmonyHeiTi')
              .fontWeight(FontWeight.Regular)
          }
          .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .width('100%')
        .accessibilityGroup(true)
        .accessibilityLevel('no')

        Toggle({
          type: ToggleType.Switch,
          isOn: this.autoAutoDialSOSNumberSwitchState
        })
          .onChange((isOn: boolean) => {
            this.onAutoDialSOSNumberToggleChange(isOn);
          })
          .width(36)
          .height(20)
          .margin({ start: LengthMetrics.vp(8), end: LengthMetrics.vp(12) })
      }
      .width('100%')
      .margin({
        top: this.getDeviceAndDirectionInfo() ? 0 : this.fontSizeScale < 1.75 ? 8 : this.topAndBottomMarginOnScale,
        bottom: this.getDeviceAndDirectionInfo() ? 0 : this.fontSizeScale < 1.75 ? 8 : this.topAndBottomMarginOnScale
      })
      .constraintSize({
        minHeight: this.getDeviceAndDirectionInfo() ? '64vp' : 0
      })
      .padding({ start: LengthMetrics.vp(12) })
      .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
      .borderRadius(20)
      .accessibilityText(`${EmergencyCallController.getInstance()
        .formatResourceToString($r('app.string.Sos_Auto_Call'))} ${
        this.context.resourceManager.getPluralStringValueSync($r('app.plural.Sos_Auto_Call_Detail').id, 5)}`)

      EmergencyWarningDivider().padding({ left: 4, right: 4 });

      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Text($r('app.string.Sos_Auto_Call_Test'))
          .fontSize($r('sys.float.ohos_id_text_size_sub_title2'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Medium)
        Image(this.isPlaying ? $r('app.media.ic_public_pause_norm') : $r('app.media.ic_public_play_norm'))
          .height(24)
          .width(24)
          .fillColor($r('sys.color.ohos_id_color_text_primary'))
          .margin({ start: LengthMetrics.vp(8) })
          .matchTextDirection(true)
      }
      .width('100%')
      .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
      .hoverEffect(HoverEffect.Highlight)
      .margin({
        top: this.fontSizeScale < 1.75 ? '' : this.topAndBottomMarginOnScale,
        bottom: this.fontSizeScale < 1.75 ? '' : this.topAndBottomMarginOnScale
      })
      .constraintSize({ minHeight: this.fontSizeScale < 1.75 ? '48vp' : '' })
      .padding({ left: 12, right: 12 })
      .borderRadius(16)
      .stateStyles({
        pressed: {
          .backgroundColor($r('sys.color.interactive_click'))
          .opacity(1)
        },
      })
      .onClick(() => {
        if (this.isPlaying) {
          this.stopSosHelpAudio()
        } else {
          this.playSosHelpAudio()
        }
      })
    }
    .borderRadius(20)
    .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
    .padding({ left: 0, right: 0 })
  }

  getTextListFirst(source: string, target: string, target2: string, target3: string) {
    let result: string[] = []
    if (source) {
      let tempStr = target;
      let tempStr2 = target2;
      let tempStr3 = target3;
      let position: number = source.indexOf(tempStr)
      let position2: number = source.indexOf(tempStr2)
      let position3: number = source.indexOf(tempStr3)
      let before: string = source.substring(0, position)
      let after: string = source.substring(position + tempStr.length, position2)
      let mid: string = source.substring(position2 + tempStr2.length, position3)
      let end: string = source.substring(position3 + tempStr3.length)
      result.push(before)
      result.push(target)
      result.push(after)
      result.push(target2)
      result.push(mid)
      result.push(target3)
      result.push(end)
    }
    return result
  }

  /**
   * getReportLocationTextList 拼接紧急上报位置信息开关下方短通知字符串
   *
   * @param source 主字串
   * @param target 联网
   * @param target2 位置
   * @param target3 权限使用说明
   * @param target4 序号1
   * @param target5 关于紧急位置服务平台与隐私的声明
   * @param target6 序号2
   * @param target7 位置网隐私政策
   * @returns result 拼接后的字符串
   */
  getReportLocationTextList(source: string, target: string, target2: string, target3: string, target4: string,
    target5: string, target6: string, target7: string) {
    let result: string[] = []
    if (source) {
      let tempStr = target;
      let tempStr2 = target2;
      let tempStr3 = target3;
      let tempStr4 = target4;
      let tempStr5 = target5;
      let tempStr6 = target6;
      let tempStr7 = target7;
      let position: number = source.indexOf(tempStr)
      let position2: number = source.indexOf(tempStr2)
      let position3: number = source.indexOf(tempStr3)
      let position4: number = source.indexOf(tempStr4)
      let position5: number = source.indexOf(tempStr5)
      let position6: number = source.indexOf(tempStr6)
      let position7: number = source.indexOf(tempStr7)
      let zero: string = source.substring(0, position)
      let one: string = source.substring(position + tempStr.length, position2)
      let two: string = source.substring(position2 + tempStr2.length, position3)
      let three: string = source.substring(position3 + tempStr3.length, position4)
      let four: string = source.substring(position4 + tempStr4.length, position5)
      let five: string = source.substring(position5 + tempStr5.length, position6)
      let six: string = source.substring(position6 + tempStr6.length, position7)
      let seven: string = source.substring(position7 + tempStr7.length)
      result.push(zero)
      result.push(target)
      result.push(one)
      result.push(target2)
      result.push(two)
      result.push(target3)
      result.push(three)
      result.push(target4)
      result.push(four)
      result.push(target5)
      result.push(five)
      result.push(target6)
      result.push(six)
      result.push(target7)
      result.push(seven)
    }
    return result
  }

  getPersonalSafetyTextList(source: string, target1: string, target2: string, target3: string, target4: string) {
    let result: string[] = []
    if (source) {
      let tempStr1 = target1;
      let tempStr2 = target2;
      let tempStr3 = target3;
      let tempStr4 = target4;
      let position1: number = source.indexOf(tempStr1)
      let position4: number = source.indexOf(tempStr2)
      let position5: number = source.indexOf(tempStr3)
      let position6: number = source.indexOf(tempStr4)

      let start: string = source.substring(0, position1)
      let second: string = source.substring(position1 + tempStr1.length, position4)
      let fifth: string = source.substring(position4 + tempStr2.length, position5)
      let sixth: string = source.substring(position5 + tempStr3.length, position6)
      let end: string = source.substring(position6 + tempStr4.length)

      result.push(start)
      result.push(target1)
      result.push(second)
      result.push(target2)
      result.push(fifth)
      result.push(target3)
      result.push(sixth)
      result.push(target4)
      result.push(end)
    }
    return result
  }

  getDeviceAndDirectionInfo() {
    let isTabletRowDirection = this.deviceTypeInfo === 'tablet' && this.defaultDisplayValue && this.fontSizeScale < 1.75
    return isTabletRowDirection
  }

  getNaviPadding(direction: string): LengthMetrics {
    let margin = CallColumnUtils.getInstance().getNaviPaddingSpace(direction);
    return LengthMetrics.resource(margin);
  }

  private async getImageFrameInfoFromMedia(): Promise<ImageFrameInfo[]> {
    try {
      let resource: Resource = $r('app.media.SOS');
      if (this.deviceTypeInfo === 'tablet') {
        resource = $r('app.media.SOS_pad');
      } else if (ScreenAdapterUtils.isNewFormFoldPhone()) {
        resource = $r('app.media.SOS_NEW_FOLD');
      }
      let unit8Array = await getContext(this)?.resourceManager?.getMediaContent({
        bundleName: resource.bundleName,
        moduleName: resource.moduleName,
        id: resource.id
      })
      let imageSource = image.createImageSource(unit8Array.buffer.slice(0, unit8Array.buffer.byteLength))
      let createPixelMap: image.PixelMap[] = await imageSource.createPixelMapList({
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      })
      let delayList = await imageSource.getDelayTimeList()
      await imageSource.release()
      let imageFrameInfoArray: ImageFrameInfo[] = [];
      for (let i = 0; i < createPixelMap.length; i++) {
        imageFrameInfoArray.push({
          src: createPixelMap[i],
          duration: delayList[i]
        })
      }
      LogUtils.i(TAG, `getImageFrameInfoFromMedia array size:${imageFrameInfoArray.length}`);
      return imageFrameInfoArray
    } catch (e) {
      LogUtils.e(TAG, `getImageFrameInfoFromMedia error:${e}`);
    }
    return [];
  }

  @Builder
  buildImageAnima() {
    if (this.deviceTypeInfo === 'tablet') {
      this.deviceImageAnimator(394);
    } else if (ScreenAdapterUtils.isNewFormFoldPhone()) {
      // 新折叠插画是Min(440 , (707 / 2)) * 0.8
      this.deviceImageAnimator(282.8);
    } else {
      this.deviceImageAnimator(288);
    }
  }

  @Builder
  deviceImageAnimator(width: number) {
    ImageAnimator()
      .images(this.images)
      .state(this.animationStatus)
      .fillMode(FillMode.None)
      .iterations(-1)
      .height(width)
      .width(width)
      .onStart(() => {
        LogUtils.i(TAG, 'ImageAnimator Start');
      })
      .onPause(() => {
        LogUtils.i(TAG, 'ImageAnimator Pause');
      })
      .onRepeat(() => {
        LogUtils.i(TAG, 'ImageAnimator Repeat');
        this.animationStatus = AnimationStatus.Stopped;
        setTimeout(() => {
          this.animationStatus = AnimationStatus.Running;
        }, 3000);
      })
      .onCancel(() => {
        LogUtils.i(TAG, 'ImageAnimator Cancel');
      })
      .onFinish(() => {
        LogUtils.i(TAG, 'ImageAnimator Finish');
      })
      .accessibilityLevel('no')
  }

  @Builder
  title() {
    Row() {
      this.backButton()
      // normal title
      Text(this.sosEmergencyWarningSettingsTitle)
        .fontWeight(FontWeight.Bold)
        .fontFamily('HarmonyHeiTi')
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .margin({ start: LengthMetrics.vp(8) })
        .maxLines(2)
        .maxFontSize($r('sys.float.ohos_id_text_size_headline8'))
        .minFontSize($r('app.float.font_14'))
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .opacity(this.opacityVal)
        .constraintSize({
          maxWidth: 'calc(100% - 48vp - 48vp)',
          maxHeight: `100%`
        })
    }
    .titleStyle()
    .alignItems(VerticalAlign.Center)
    .translate({ x: this.titleX })
  }



  @Builder
  backButton(): void {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.chevron_backward'))
        .width(24)
        .height(24)
        .draggable(false)
        .fontSize('24vp')
        .fontColor([$r('sys.color.ohos_id_color_primary')])
    }
    .id('backButton')
    .draggable(false)
    .width('40vp')
    .height('40vp')
    .backgroundColor($r('sys.color.ohos_id_color_text_field_sub_bg'))
    .onClick(() => {
      this.onBackPress();
    })
    .opacity(this.circleOpacityVal)
    .accessibilityText($r('app.string.InfoEdit_back'))
  }

  build() {
 /*   HdsNavigation(this.pathInfos) {
      Column() {
        Scroll() {
          Column() {
            // 紧急呼叫插画图
            this.buildImageAnima();

            Column() {
              Text(this.context.resourceManager.getPluralStringValueSync($r('app.plural.Sos_emergency_notice_fiveTimes')
                .id, 5)).fontWeight(FontWeight.Regular)
                .fontSize($r('sys.float.Body_M'))
                .fontColor($r('sys.color.font_secondary'))
            }.margin({ top: 8 })

            Column() {
              this.PersonalEmergencyContact()
              EmergencyWarningDivider();
              this.EmergencyContact()
            }
            .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
            .borderRadius(20)
            .padding({ top: 4, bottom: 4 })
            .justifyContent(FlexAlign.Center)
            .margin({ top: 24 })

            Column() {
              this.autoSendMessage()
            }.backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
            .borderRadius(20)
            .padding({ top: 4, bottom: 4 })
            .margin({ top: 12 })

            Column() {
              this.buildAreaContent()
            }.margin({ top: 8 })

            Column() {
              this.autoCallForHelp()
            }.backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
            .borderRadius(20)
            .padding({ top: 4, bottom: 4 })
            .margin({ top: 24 })

            if (this.isSupportCrashSos) {
              Column() {
                this.buildPersonalSafetyAutoCallFuncArea(CAR_ACCIDENT)
              }.backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
              .borderRadius(20)
              .padding({ top: 4, bottom: 4 })
              .margin({ top: 12 })

              Column() {
                this.buildPersonalSafetyNoticeArea(CAR_ACCIDENT)
              }
              .margin({ top: 8 })
            }

            if (this.isSupportFallSos) {
              Column() {
                this.buildPersonalSafetyAutoCallFuncArea(FALL_DOWN)
              }.backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
              .borderRadius(20)
              .padding({ top: 4, bottom: 4 })
              .margin({ top: 24 })

              Column() {
                this.buildPersonalSafetyNoticeArea(FALL_DOWN)
              }.margin({ top: 8, bottom: 12 })
            }

            Column() {
              if (this.isShowHwAmlSwitch) {
                this.serviceSwitch($r('app.string.aml_switch_title'), $r('app.string.aml_switch_summary'),
                  this.isShowHwAmlSwitch, this.amlSwitchChangeListener)
              } else {
                this.serviceSwitch($r('app.string.Sos_Auto_Send_Location'),
                  $r('app.string.Sos_Auto_Send_Location_Info'),
                  this.isShowHwAmlSwitch, this.sosLocationSwitch)
              }
            }
            .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
            .borderRadius(20)
            .padding({ top: 4, bottom: 4 })
            .margin({ top: 12 })

            Column() {
              this.buildServiceShortNotification()
            }.margin({ top: 8 })

            Blank().height(44)
          }
          .margin({ top: TITLE_BAR_HEIGHT_MINI + this.statusBarHeight })
        }
        .padding({
          left: LayoutUtils.getAdaptableTabletPadding('left'),
          right: LayoutUtils.getAdaptableTabletPadding('right')
        })
        .scrollBar(BarState.Off).height('100%').align(Alignment.Top).layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)
      }
    }*/
    Navigation(this.pathInfos) {
      EditableTitleBar({
        title:this.sosEmergencyWarningSettingsTitle,
        contentMargin:{top:LengthMetrics.px(100)},
        isSaveIconRequired: false,
        onCancel:()=>{
          this.onBackPress()
        }
      })
        .margin({start:LengthMetrics.vp(12)})
      Column() {
        Scroll() {
          Column() {
            // 紧急呼叫插画图
            this.buildImageAnima();

            Column() {
              Text(this.context.resourceManager.getPluralStringValueSync($r('app.plural.Sos_emergency_notice_fiveTimes')
                .id, 5)).fontWeight(FontWeight.Regular)
                .fontSize($r('sys.float.Body_M'))
                .fontColor($r('sys.color.font_secondary'))
            }.margin({ top: 8 })

            Column() {
              this.PersonalEmergencyContact()
              EmergencyWarningDivider();
              this.EmergencyContact()
            }
            .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
            .borderRadius(20)
            .padding({ top: 4, bottom: 4 })
            .justifyContent(FlexAlign.Center)
            .margin({ top: 24 })

            Column() {
              this.autoSendMessage()
            }.backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
            .borderRadius(20)
            .padding({ top: 4, bottom: 4 })
            .margin({ top: 12 })

            Column() {
              this.buildAreaContent()
            }.margin({ top: 8 })

            Column() {
              this.autoCallForHelp()
            }.backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
            .borderRadius(20)
            .padding({ top: 4, bottom: 4 })
            .margin({ top: 24 })

            if (this.isSupportCrashSos) {
              Column() {
                this.buildPersonalSafetyAutoCallFuncArea(CAR_ACCIDENT)
              }.backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
              .borderRadius(20)
              .padding({ top: 4, bottom: 4 })
              .margin({ top: 12 })

              Column() {
                this.buildPersonalSafetyNoticeArea(CAR_ACCIDENT)
              }
              .margin({ top: 8 })
            }

            if (this.isSupportFallSos) {
              Column() {
                this.buildPersonalSafetyAutoCallFuncArea(FALL_DOWN)
              }.backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
              .borderRadius(20)
              .padding({ top: 4, bottom: 4 })
              .margin({ top: 24 })

              Column() {
                this.buildPersonalSafetyNoticeArea(FALL_DOWN)
              }.margin({ top: 8, bottom: 12 })
            }

            Column() {
              if (this.isShowHwAmlSwitch) {
                this.serviceSwitch($r('app.string.aml_switch_title'), $r('app.string.aml_switch_summary'),
                  this.isShowHwAmlSwitch, this.amlSwitchChangeListener)
              } else {
                this.serviceSwitch($r('app.string.Sos_Auto_Send_Location'),
                  $r('app.string.Sos_Auto_Send_Location_Info'),
                  this.isShowHwAmlSwitch, this.sosLocationSwitch)
              }
            }
            .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
            .borderRadius(20)
            .padding({ top: 4, bottom: 4 })
            .margin({ top: 12 })

            Column() {
              this.buildServiceShortNotification()
            }.margin({ top: 8 })

            Blank().height(132)
          }
          .margin({ top: TITLE_BAR_HEIGHT_MINI + this.statusBarHeight })
        }
        .padding({
          left: LayoutUtils.getAdaptableTabletPadding('left'),
          right: LayoutUtils.getAdaptableTabletPadding('right')
        })
        .scrollBar(BarState.Off).height('100%').align(Alignment.Top).layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .mode(NavigationMode.Stack)
    .height('100%')
    .width('100%')
    //.titleMode(HdsNavigationTitleMode.MINI)
    //.titleMode(NavigationTitleMode.Mini)
    /*.titleBar(TitleParams.MiniTitleParams(this.sosEmergencyWarningSettingsTitle,
      $r('sys.color.ohos_id_color_sub_background')))*/
    //.title(this.MyCustomTitle)
    .hideTitleBar(true)
    .navDestination(this.myRouter)
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    .onAppear(() => {
      LogUtils.i(TAG, 'onAppear');
      // title入场动画
      animateTo({ duration: ANIM_DURATION, curve: curves.interpolatingSpring(0.0, 1.0, 342.0, 37.0) }, () => {
        this.opacityVal = 1;
        this.titleX = 0;
      });
      animateTo({ duration: CIRCLE_ANIM_DURATION, delay: 120, curve: Curve.Sharp }, () => {
        this.circleOpacityVal = 1;
      });
    })
  }
}
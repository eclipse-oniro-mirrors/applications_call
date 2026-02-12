/**
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

import EmergencyCallController from '../control/EmergencyCallControl';
import Keyboard from '../components/Keyboard';
import {
  ContactListStruct,
  LocationDialogDataStruct,
  LocationInfoStruct,
  EmergencyNumListStruct,
  TimeOutStruct
} from '../utils/ClassStruct';
import * as storageUtil from '../utils/DataStorageUtil';
import commonData, { CommunicationNetworkType } from '../data/CommonData';
import LogUtils from '../utils/HiLog';
import { getEmptyEmergencyListData } from '../utils/InitDataUtil';
import CallColumnUtils from '../utils/CallColumnUtils';
import data from '@ohos.telephony.data';
import wallpaper from '@ohos.wallpaper';
import { BusinessError } from '@ohos.base';
import common from '@ohos.app.ability.common';
import { addAirPlaneModeListener, removeAirPlaneModeListener } from '../data/AirplaneMode';
import {
  addSatelliteToggleStateListener,
  removeSatelliteToggleStateListener
} from '../data/SateToggleStateManager';

import OnScreenOff, { SCREEN_OFF_EVENT, SCREEN_UNLOCKED_EVENT } from '../control/OnScreenOff';
import { ReportUtil } from '../utils/ReportUtil';
import { CustomContentDialog, AlertDialog } from '@ohos.arkui.advanced.Dialog';
import EmergencyInfoUIExtension from './EmergencyInfoUIExtension';
import mediaquery from '@ohos.mediaquery'
import sim from '@ohos.telephony.sim';
import { osAccount, settings } from '@kit.BasicServicesKit';
import { EmergencyGlobalContextHelper } from '../utils/EmergencyGlobalContextHelper';
import * as Constants from '../utils/Constants';
import { LengthMetrics, MeasureText } from '@kit.ArkUI';
import ScreenAdapterUtils from '../utils/ScreenAdapterUtils';
import { CommonEventUtils } from '../utils/CommonEventUtils';
import LocationUtils from '../utils/LocationUtils';
import { accessibility } from '@kit.AccessibilityKit';
import { isTablet } from '../utils/DeviceTypeUtils';
import LayoutUtils from '../utils/LayoutUtils';
//import { HdsNavigation, HdsNavigationAttribute, HdsNavigationTitleMode } from '@kit.UIDesignKit';

const TAG = 'emergencyCallIndex';
const AUTO_FLAG = 'autoLocationFlag';
const AIRPLANE_MODE = 1;
const SATELLITE_MODE_SWITCH = 1;
export const LLIST_SEL_TIMEOUT = 3000;
const DURATION_LONG = 200;


@Entry
@Component
struct emergencyCall {
  textScroller: Scroller = new Scroller();
  curColor: string = '';
  @Provide('pathInfos') @Watch('pathChange') pathInfos: NavPathStack = new NavPathStack();
  @State mEmergencyCallController: EmergencyCallController = EmergencyCallController.getInstance();
  @State @Watch('scrollTextToEnd') numberInputValue: string = '';
  @State textInputValue: string = '';
  @State isAutoLocation: boolean = false;
  @State isShowKeyboard: boolean = false;
  @State getLocationState: number = commonData.int.LOCATION_STATE_DOING;
  @State activeOffsetX: number = 0;
  @State movingId: string = '';
  @State locationStr: string | undefined = '';
  @State locationText: Resource = $r('app.string.getLocation');
  @StorageLink('localEmergencyNumber') emergencyContactsList: EmergencyNumListStruct[] = [];
  @State defaultContactsList: Array<ContactListStruct> = commonData.defaultContactsList;
  @State emergencyContacts: ContactListStruct[] = [];
  @State clickActiveContactItemIds: string[] = [];
  @State confirmDialogPhoneNumber: string = '';
  @StorageProp('simOperatorNameFirst') simOperatorNameFirst: string = '';
  @StorageProp('simOperatorNameSecond') simOperatorNameSecond: string = '';
  @StorageProp('curBp') curBp: string = '';
  @StorageProp('ratio') ratio: number = 0;
  private mCallColumnUtils: CallColumnUtils = CallColumnUtils.getInstance();
  @State wallpaperBg: PixelMap | undefined = undefined;
  @State isCancelTouch: boolean = false;
  @State deleteBtnPressed: boolean = false;
  @StorageProp('defaultVoiceId') defaultVoiceId: number = -1;
  @StorageProp('isAirPlaneMode') isAirPlaneMode: boolean = false;
  @StorageProp('isSatelliteModeOn') @Watch('showSatelliteWindow') isSatelliteModeOn: boolean = false;
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  @State isInput: boolean = false;
  @State isInOOBE: boolean = false;
  @State alreadyUnlocked: boolean = false; // 默认未认证解锁过
  @State dialogData: LocationDialogDataStruct = {
    title: $r('app.string.emptyStr'),
    contentText: $r('app.string.emptyStr'),
    confirm: () => {
    }
  };
  private isHome: boolean = true;
  @State hasPermission: boolean = true;
  @State isShowLandscapeHeight: boolean = false;
  @State isLandscape: boolean = false;
  @State nameFontSize: string = '30vp';
  listener = mediaquery.matchMediaSync('(orientation: landscape)')
  scroller: Scroller = new Scroller();

  onPortrait(mediaQueryResult: mediaquery.MediaQueryResult) {
    if (this.curBp === 'md') {
      if (mediaQueryResult.matches) {
        this.isLandscape = true;
      } else {
        this.isLandscape = false;
      }
    } else if (isTablet() && ScreenAdapterUtils.getProductType() === 'MLR') {
      if (mediaQueryResult.matches) {
        this.isLandscape = true;
      } else {
        this.isLandscape = false;
      }
    }
  }

  pathChange() {
    let pathSize: number = this.pathInfos.size();
    let ctx = EmergencyGlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constants.EMERGENCY_CALL_ABILITY_CONTEXT);
    let commonColor = ctx.config.colorMode ? commonData.backgroundColor.common :
    commonData.backgroundColor.commonDark;
    let tempColor = pathSize >= 1 ? commonColor : commonData.backgroundColor.index;
    if (tempColor !== this.curColor) {
      this.curColor = tempColor;
      this.mEmergencyCallController.setWindowBackgroundColor(this.curColor);
    }
    let pathArr = this.pathInfos.getAllPathName();
    let endPath = pathArr[pathArr.length - 1];
    if (endPath) {
      if (endPath === 'EmergencyInfoEdit' || endPath === 'EmergencyContactsEdit') {
        OnScreenOff.aboveScreen(false);
      } else {
        OnScreenOff.aboveScreen(true);
      }
    }
  }

  @Builder
  myRouter(name: string) {
    if (name === 'EmergencyInfoView') {
      EmergencyInfoUIExtension();
    }
  }

  /**
   * close location server bindMenu
   */
  @Builder
  MenuBuilder() {
    Column() {
      Text($r('app.string.closeLocationService_title'))
        .textAlign(TextAlign.Start)
        .fontSize($r('app.float.emc_fontSize_16'))
        .fontColor($r('sys.color.font_primary'))
        .lineHeight($r('app.float.emc_padding_level105'))
        .constraintSize({ minHeight: $r('app.float.emc_padding_level105') })
    }
    .justifyContent(FlexAlign.Center)
    .height($r('app.float.emc_padding_level24'))
    .padding({
      left: $r('sys.float.padding_level8'),
      right: $r('sys.float.padding_level8')
    })
    .onClick(() => {
      this.showLocationConfirmDialog($r('app.string.closeLocationService'),
        $r('app.string.closeLocationServiceMsg'), false);
    })
  }

  scrollTextToEnd() {
    let textWidth = MeasureText.measureText({
      textContent: this.numberInputValue,
      fontSize: $r('sys.float.Title_M'),
      textAlign: TextAlign.Center
    });
    this.textScroller.scrollTo({
      xOffset: textWidth,
      yOffset: 0
    });
  }

  getLocationCallback(data: LocationInfoStruct) {
    LogUtils.i(TAG, 'getLocationCallback, data.isSuccess: ' + data?.isSuccess);
    if (data.isSuccess) {
      this.getLocationState = commonData.int.LOCATION_STATE_DONE;
      this.locationStr = data.data;
      if (this.isLandscape) { //Folded screen landscape effective
        this.isShowLandscapeHeight = this.mCallColumnUtils.getAddressTwoLineShow(this.locationStr)
      }
    } else {
      this.getLocationState = commonData.int.LOCATION_STATE_FAILED;
      this.locationText = $r('app.string.getLocationFailed');
      if (data.hasPermission !== undefined) {
        this.hasPermission = data.hasPermission;
        LogUtils.i(TAG, 'hasPermission:' + this.hasPermission);
      }
    }
    if (!LocationUtils.getInstance().ignoreLocationSwitch) {
      LocationUtils.getInstance().setLocationSwitchIgnored(false);
    }
  }

  locationConfirmDialog: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      primaryTitle: this.dialogData.title,
      content: this.dialogData.contentText,
      primaryButton: {
        value: $r('app.string.CANCEL'),
        action: () => {
          this.locationConfirmDialog.close();
        }
      },
      secondaryButton: {
        value: $r('app.string.continue'),
        action: () => {
          this.dialogData.confirm();
        },
        buttonStyle: ButtonStyleMode.EMPHASIZED
      },
    }),
    autoCancel: false
  });

  showLocationConfirmDialog(title: Resource, contentText: Resource, isOpenLocation: boolean) {
    this.dialogData.title = title;
    this.dialogData.contentText = contentText;
    if (isOpenLocation) {
      this.dialogData.confirm = () => {
        this.isAutoLocation = true;
        storageUtil.updateLocationFlag(AUTO_FLAG, this.isAutoLocation);
        this.getLocationState = commonData.int.LOCATION_STATE_DOING;
        this.locationText = $r('app.string.gettingLocation');
        this.isAutoLocation = true;
        EmergencyCallController.getInstance().getLocationInfo((data) => {
          this.getLocationCallback(data);
        });
      }
    } else {
      this.dialogData.confirm = () => {
        this.isAutoLocation = false;
        let currentLocationEnable: boolean = LocationUtils.getInstance().getLocationEnable();
        if (!LocationUtils.getInstance().ignoreLocationSwitch && currentLocationEnable) {
          LocationUtils.getInstance().setLocationSwitchIgnored(false);
        }
        storageUtil.updateLocationFlag(AUTO_FLAG, this.isAutoLocation);
      }
    }
    this.locationConfirmDialog.open();
  }

  dialButtonClick(slotId: number): void {
    if (!this.textInputValue) {
      return;
    }
    LogUtils.i(TAG, 'Use slotId:' + slotId);
    this.mEmergencyCallController.checkIsEmergencyPhoneNumber(this.textInputValue, slotId, (result: boolean) => {
      LogUtils.i(TAG, 'answer, result: ' + result);
      if (result) {
        this.mEmergencyCallController.emergencyCallDial(this.textInputValue, slotId, true);
        ReportUtil.getInstance().reportEmergencyDial(this.textInputValue.length);
      } else {
        this.showConfirmDialog();
      }
      this.textInputValue = '';
      this.numberInputValue = '';
    })
  }

  @Builder
  confirmDialogContent() {
    Scroll(this.scroller) {
      Column() {
        Text($r('app.string.notEmergencyNumberMsg', this.confirmDialogPhoneNumber))
          .width('100%')
          .fontColor($r('sys.color.font_primary'))
          .fontSize($r('sys.float.Body_L'))
          .fontWeight(FontWeight.Regular)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .align(Alignment.Top)
  }


  @Builder MenuBuilders() {
    Column() {
      Text($r('app.string.closeLocationService_title'))
        .fontSize($r('app.float.emc_fontSize_16'))
        .fontColor($r('sys.color.font_primary'))
        .maxLines(2)
        .constraintSize({ minHeight: $r('app.float.emc_padding_level24') })
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.showLocationConfirmDialog($r('app.string.closeLocationService'),
                 $r('app.string.closeLocationServiceMsg'), false);
        })
    }
    .justifyContent(FlexAlign.Center)
    .padding({
      left: $r('sys.float.padding_level6'),
      right: $r('sys.float.padding_level6')
    })
    .width('auto')
    .backgroundColor($r('app.color.emc_comp_background_tertiary'))
    .backgroundBlurStyle(BlurStyle.NONE)
  }

  confirmDialog: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.emergencyCall'),
      contentBuilder: () => {
        this.confirmDialogContent();
      },
      buttons: [
        {
          value: $r('app.string.determine'),
          action: () => {
            this.confirmDialog.close();
          }
        }
      ]
    }),
    autoCancel: false,
  });

  @Builder
  permissionHintDialogContent() {
    Column() {
      Row() {
        Text($r('app.string.noLocationPermissionTitle'))
          .constraintSize({ minHeight: $r('app.float.emc_padding_level20') })
          .width('100%')
          .fontSize($r('sys.float.Body_L'))
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
      }
      .padding({ top: $r('sys.float.padding_level12') })
      .align(Alignment.Center)
      .width('100%')

      Row() {
        Text($r('app.string.noLocationPermissionDesc'))
          .width('100%')
          .fontColor($r('sys.color.font_secondary'))
          .fontSize($r('sys.float.Body_M'))
          .fontWeight(FontWeight.Regular)
          .textAlign(TextAlign.Start)
      }
      .margin({ top: $r('sys.float.padding_level1') })
      .width('100%')
    }
    .width('100%')
  }

  permissionHintDialog: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      contentBuilder: () => {
        this.permissionHintDialogContent()
      },
      buttons: [
        {
          value: $r('app.string.permissionConfirm'),
          action: () => {
            this.permissionHintDialog.close();
          }
        }
      ]
    }),
    autoCancel: false,
  })

  showConfirmDialog() {
    this.confirmDialogPhoneNumber = this.textInputValue;
    this.confirmDialog.open();
  }

  listenAirPlane(res: Record<string, number | boolean>) {
    const isAirPlaneMode = res?.data === AIRPLANE_MODE;
    if (isAirPlaneMode) {
      if (res?.isListen) {
        EmergencyCallController.getInstance().getSimOperatorNames(false);
      } else {
        AppStorage.setOrCreate('isAirPlaneMode', isAirPlaneMode);
      }
    }
  }

  initAirPlaneMode(context: Context) {
    LogUtils.i(TAG, 'initAirPlaneMode');
    try {
      addAirPlaneModeListener((res: Record<string, number | boolean>) => {
        LogUtils.i(TAG, 'initAirPlaneMode callback' + JSON.stringify(res));
        this.listenAirPlane(res)
      }, context);
    } catch (err) {
      LogUtils.e(TAG, `initAirPlaneMode err = ${JSON.stringify(err)}`);
    }
  }

  initSatelliteMode() {
    LogUtils.i(TAG, 'initSatelliteMode');
    try {
      addSatelliteToggleStateListener((res: number) => {
        LogUtils.i(TAG, 'initAirPlaneMode callback' + res);
        const isSatelliteModeOn = res === SATELLITE_MODE_SWITCH;
        if (isSatelliteModeOn) {
          AppStorage.setOrCreate('isSatelliteModeOn', isSatelliteModeOn);
        }
      });
    } catch (err) {
      LogUtils.e(TAG, `isSatelliteModeOn err = ${JSON.stringify(err)}`);
    }
  }

  aboutToAppear(): void {
    LogUtils.i(TAG, `emergency_call aboutToAppear`);
    this.curColor = commonData.backgroundColor.index;
    this.mEmergencyCallController.setWindowBackgroundColor(commonData.backgroundColor.index);
    this.clickActiveContactItemIds = [];
    storageUtil.getAutoLocationFlag((data) => {
      if (data[AUTO_FLAG]) {
        this.getLocationState = commonData.int.LOCATION_STATE_DOING;
        this.locationText = $r('app.string.gettingLocation');
        this.isAutoLocation = true;
        EmergencyCallController.getInstance().getLocationInfo((data) => {
          this.getLocationCallback(data);
        });
      } else {
        this.isAutoLocation = false;
      }
    });
    this.getWallpaper();
    EmergencyCallController.getInstance().getDefaultVoiceSlotId();
    this.initAirPlaneMode(getContext(this));
    this.initSatelliteMode();
    ReportUtil.getInstance().reportShowEmergencyPage();
    OnScreenOff.initSubscriber((value: string) => {
      LogUtils.i(TAG, 'commonEvent callback value: ' + value);
      let pathArr = this.pathInfos.getAllPathName();
      if (value === SCREEN_OFF_EVENT) {
        if (pathArr.length === 0 && this.isHome) {
          OnScreenOff.terminateSelf();
        }
      } else if (value === SCREEN_UNLOCKED_EVENT) {
        OnScreenOff.aboveScreen(false);
      }
    })
    let portraitFunc = (mediaQueryResult: mediaquery.MediaQueryResult): void => this.onPortrait(mediaQueryResult)
    // bind current js instance
    this.listener.on('change', portraitFunc)
    this.getisInOOBE();
    this.getIsOsAccountUnlocked();
  }

  onPageShow() {
    LogUtils.i(TAG, `emergency_call onPageShow`);
    this.isHome = true;
    storageUtil.DataStorageUtil.getInstance().getEmergencyContacts((data) => {
      this.emergencyContacts = data;
    })
    this.showSatelliteWindow();
  }

  onPageHide() {
    LogUtils.i(TAG, `emergency_call onPageHide`);
    this.isHome = false;
    CommonEventUtils.getInstance().hideSatelliteWindow(this.isSatelliteModeOn);
    this.exiting();
  }

  aboutToDisappear() {
    LogUtils.e(TAG, `emergency_call aboutToDisappear`);
    OnScreenOff.unsubscribe();
    if (!LocationUtils.getInstance().ignoreLocationSwitch) {
      LogUtils.i(TAG, 'emergency_call aboutToDisappear setLocationSwitchIgnored');
      LocationUtils.getInstance().setLocationSwitchIgnored(false);
    }
    if (this.wallpaperBg) {
      this.wallpaperBg.release();
    }
    removeAirPlaneModeListener();
    removeSatelliteToggleStateListener();
    CommonEventUtils.getInstance().hideSatelliteWindow(this.isSatelliteModeOn);
    AppStorage.delete('isSatelliteModeOn');
  }

  showSatelliteWindow() {
    CommonEventUtils.getInstance().showSatelliteWindow(this.isSatelliteModeOn);
  }

  private getIsOsAccountUnlocked() {
    let accountManager: osAccount.AccountManager = osAccount.getAccountManager();
    try {
      accountManager.isOsAccountUnlocked().then((isVerified: boolean) => {
        LogUtils.i(TAG, 'isOsAccountUnlocked successfully, isVerified: ' + isVerified);
        this.alreadyUnlocked = isVerified;
      }).catch((err: BusinessError) => {
        LogUtils.e(TAG, 'isOsAccountUnlocked failed, error: ' + JSON.stringify(err));
      });
    } catch (err) {
      LogUtils.e(TAG, 'isOsAccountUnlocked exception: ' + JSON.stringify(err));
    }
  }

  private getisInOOBE() {
    try {
      let context = getContext(this);
      if (context) {
        let provisioned: string = settings.getValueSync(context, 'device_provisioned', '0',
          settings.domainName.DEVICE_SHARED);
        let setupComplete: string = settings.getValueSync(context, 'user_setup_complete', '0',
          settings.domainName.USER_SECURITY);
        let otaFinished: string = settings.getValueSync(context, 'is_ota_finished', '1',
          settings.domainName.USER_SECURITY);
        LogUtils.i(TAG, 'isInOOBE: ' + provisioned + setupComplete + otaFinished);
        this.isInOOBE = (provisioned === '1' && setupComplete === '1' && otaFinished === '1') ? false : true;
      }
    } catch (e) {
      LogUtils.i(TAG, `getisInOOBE error: ${JSON.stringify(e)}`);
    }
  }

  getWallpaper() {
    wallpaper.getImage(wallpaper.WallpaperType.WALLPAPER_SYSTEM).then((data) => {
      LogUtils.i(TAG, `success to getImage`);
      this.wallpaperBg = data;
    }).catch((error: BusinessError) => {
      LogUtils.e(TAG, `failed to getImage because: ${JSON.stringify(error)}`);
    });
  }

  showKeyboard() {
    this.isShowKeyboard = true;
  }

  exiting() {
    LogUtils.i(TAG, `exiting`);
    this.mEmergencyCallController.exitingApplication();
  }

  hasEmergencyContactsList(): boolean {
    return ((this.emergencyContactsList !== undefined) && (this.emergencyContactsList.length !== 0));
  }

  getmariginPadding(): number | Resource {
    if (this.isLandscape) {
      return 78;
    } else {
      return this.mCallColumnUtils.getDualSimPadding(this.curBp)
    }
  }

  getSizeWidth(): number {
    if (this.isLandscape) {
      return 163.5;
    } else {
      return this.mCallColumnUtils.getDualSimButtonWidth(this.curBp)
    }
  }

  getBarrierFree(label: ResourceStr): string {
    if (label instanceof String) {
      return label as string;
    } else {
      let r = label as Resource;
      let value = getContext(this).resourceManager.getStringSync(r.id);
      return value;
    }
  }

  private getNameFontSize() {
    let textStr = this.numberInputValue ? this.numberInputValue : $r('app.string.emergencyCallsOnly')
    this.nameFontSize = new LayoutUtils().getDisplayNameForAutoSize(textStr, this.curBp);
    return this.nameFontSize;
  }

  build() {
    Stack() {
      Image(this.wallpaperBg)
        .draggable(false)
        .hoverEffect(HoverEffect.None)
        .interpolation(ImageInterpolation.High)
        .objectFit(ImageFit.Cover)
        .height('100%')
        .width('100%')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])

      Column()
        .height('100%')
        .width('100%')
        .backgroundColor($r('app.color.emc_background_primary'))
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
/*      HdsNavigation(this.pathInfos) {
        GridRow({ columns: { sm: 4, md: 8, lg: 12 }, gutter: { x: 24 } }) {
          GridCol({ span: { sm: 4, md: 8, lg: 12 } }) {
            Row() {
              Button() {
                Row() {
                  SymbolGlyph($r('sys.symbol.chevron_backward'))
                    .fontSize($r('app.float.emc_padding_level12'))
                    .fontColor([$r('app.color.emc_font_on_primary')])
                }
                .borderRadius($r('sys.float.corner_radius_level10'))
                .width($r('app.float.emc_padding_level20'))
                .height($r('app.float.emc_padding_level20'))
                .justifyContent(FlexAlign.Center)
                .alignItems(VerticalAlign.Center)
              }
              .type(ButtonType.Circle)
              .backgroundColor($r('app.color.emc_comp_background_tertiary'))
              .onClick(() => {
                this.exiting();
              })
              .accessibilityText(this.mEmergencyCallController.formatResourceToString(
                $r('app.string.InfoEdit_back')))

              if (this.isAutoLocation) {
                Row() {
                  SymbolGlyph($r('sys.symbol.dot_grid_2x2'))
                    .fontSize($r('app.float.emc_padding_level12'))
                    .fontColor(['#E5E5E5'])
                }
                .borderRadius($r('sys.float.corner_radius_level10'))
                .backgroundColor($r('app.color.emc_comp_background_tertiary'))
                .width($r('app.float.emc_padding_level20'))
                .height($r('app.float.emc_padding_level20'))
                .justifyContent(FlexAlign.Center)
                .alignItems(VerticalAlign.Center)
                .accessibilityText(this.mEmergencyCallController.formatResourceToString(
                  $r('app.string.InfoEdit_edit')))
                .bindMenu(this.MenuBuilders())
              }
            }
            .justifyContent(FlexAlign.SpaceBetween)
            .alignItems(VerticalAlign.Center)
            .width('100%')
            .height($r('app.float.emc_padding_level28'))
          }
          .visibility(this.isNewFoldPhoneExternalScreen ? Visibility.None : Visibility.Visible)

          GridCol({ span: { sm: 4, md: 6, lg: 8 }, offset: { md: 1, lg: 2 } }) {
            Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.SpaceBetween }) {
              Column() {
                Button($r('app.string.personalEmergencyInfo'), { buttonStyle: ButtonStyleMode.NORMAL })
                  .fontColor($r('app.color.emc_font_on_primary'))
                  .fontWeight(FontWeight.Medium)
                  .labelStyle({ maxFontSize: '16vp', minFontSize: this.fontSizeScale !== 0 ? '16vp' : '9vp' })
                  .constraintSize({
                    minWidth: $r('app.float.emc_padding_level100'),
                    maxWidth: '100%',
                    minHeight: '40vp'
                  })
                  .onClick(() => {
                    // Jump to EmergencyInfoView
                    this.pathInfos.pushPathByName('EmergencyInfoView', '');
                    ReportUtil.getInstance().reportClickPersonEmergencyInfo();
                  })
                  .backgroundColor($r('app.color.emc_comp_background_tertiary'))
                  .visibility((this.isInOOBE || !this.alreadyUnlocked || this.isNewFoldPhoneExternalScreen) ?
                  Visibility.None : Visibility.Visible)

                Scroll(this.textScroller) {
                  Text(this.numberInputValue ? this.numberInputValue : $r('app.string.emergencyCallsOnly'))
                    .maxLines(1)
                    .fontSize(this.isNewFoldPhoneExternalScreen ? '24vp' : this.getNameFontSize())
                    .fontColor($r('app.color.emc_font_on_primary'))
                    .textAlign(TextAlign.Center)
                    .lineHeight(this.isNewFoldPhoneExternalScreen ? '32vp' : '40vp')
                    .fontWeight(FontWeight.Bold)
                    .id('EmergencyCommunication_pages_index_scrollText_emergencyCallsOnly')
                    .height(this.isNewFoldPhoneExternalScreen ? '32vp' :
                      this.isShowLandscapeHeight === true ? $r('app.float.emc_padding_level24') :
                      $r('app.float.emc_padding_level32'))
                    .constraintSize({ minWidth: '100%' })
                }
                .scrollable(ScrollDirection.Horizontal)
                .scrollBar(BarState.Off)
                .draggable(true)
                .width('100%')
                .margin({
                  top: this.isNewFoldPhoneExternalScreen ? 8 :
                    this.isLandscape === true ? 0 : $r('sys.float.padding_level4')
                })
                .height(this.isNewFoldPhoneExternalScreen ? '32vp' : this.isShowLandscapeHeight === true ? '48vp'
                  : '64vp')
              }
              .alignItems(HorizontalAlign.Center)
              .padding({
                top: (this.isNewFoldPhoneExternalScreen || this.isLandscape === true) ? 0 : $r('sys.float.padding_level4')
              })

              Row() {
                if (!this.isSatelliteModeOn) {
                  Row() {
                    SymbolGlyph($r('sys.symbol.local'))
                      .fontSize($r('app.float.emc_paddding_level9'))
                      .fontColor(['#E5E5E5'])
                      .margin({
                        top: LengthMetrics.resource($r('sys.float.padding_level1')),
                        bottom: LengthMetrics.resource($r('sys.float.padding_level1')),
                        end: LengthMetrics.resource($r('sys.float.padding_level2')) })
                      .opacity($r('sys.float.alpha_secondary'))
                      .accessibilityText($r('app.string.positioning'))
                      .accessibilityRole(AccessibilityRoleType.BUTTON)
                    Text(this.isAutoLocation ?
                      (this.getLocationState === commonData.int.LOCATION_STATE_DONE ?
                      this.locationStr : this.locationText) : $r('app.string.getLocation'))
                      .fontSize('16vp')
                      .fontColor($r('sys.color.font_on_secondary'))
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .textAlign(TextAlign.Center)
                      .maxLines(2)
                      .flexShrink(1)
                  }
                  .onClick(() => {
                    // UE report click getLocation
                    ReportUtil.getInstance().reportClickGEOLocation();
                    if (!this.hasPermission) {
                      this.permissionHintDialog.open();
                    }
                    if (this.isAutoLocation) {
                      if (this.getLocationState === commonData.int.LOCATION_STATE_DOING) {
                        return;
                      }
                      this.getLocationState = commonData.int.LOCATION_STATE_DOING;
                      this.locationText = $r('app.string.gettingLocation');
                      this.mEmergencyCallController.getLocationInfo((data) => {
                        this.getLocationCallback(data);
                      });
                    } else {
                      this.showLocationConfirmDialog($r('app.string.getLocationService'),
                        $r('app.string.getLocationMsg1'), true);
                    }
                  })
                  .width('100%')
                  .justifyContent(FlexAlign.Center)
                  .alignItems(VerticalAlign.Top)
                  .visibility((this.isInOOBE || !this.alreadyUnlocked) ? Visibility.None : Visibility.Visible)
                }
              }
              .width('100%')
              .height(this.isLandscape === true ? null : $r('app.float.emc_padding_level32'))
              .alignItems(VerticalAlign.Center)
              .justifyContent(FlexAlign.Center)
              .visibility(this.isNewFoldPhoneExternalScreen ? Visibility.None : Visibility.Visible)

              Column() {
                if (this.isShowKeyboard === true || (this.simOperatorNameFirst.length === 0 &&
                  this.simOperatorNameSecond.length === 0) || this.isAirPlaneMode || !this.hasEmergencyContactsList()) {
                  Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.End }) {
                    Row() {
                      Keyboard({ inputValue: $numberInputValue,
                        textInputValue: $textInputValue,
                        isInOOBE: $isInOOBE,
                        isLandscape: this.isLandscape
                      })
                    }
                    .alignItems(VerticalAlign.Center)
                    .width('100%')

                    Column() {
                      if (this.simOperatorNameFirst.length > 0 && this.simOperatorNameSecond.length > 0 &&
                        this.defaultVoiceId === -1 && !this.isAirPlaneMode) {
                        Flex({ alignItems: ItemAlign.Center }) {
                          if (!this.isNewFoldPhoneExternalScreen) {
                            Blank()
                          }
                          Row()
                            .width(this.isNewFoldPhoneExternalScreen ? '46vp' : $r('app.float.emc_padding_level24'))
                            .height(this.isNewFoldPhoneExternalScreen ? '40vp' : $r('app.float.emc_padding_level24'))
                            .margin({
                              right: this.isNewFoldPhoneExternalScreen ? 0 : $r('sys.float.padding_level2')
                            })

                          Button() {
                            Row() {
                              SymbolGlyph(EmergencyCallController.getInstance()
                                .getPhoneBadgeIcon(commonData.int.SIM_SLOT_ID_FIRST))
                                .fontSize($r('app.float.emc_level8'))
                                .fontColor(['#E5E5E5'])
                                .margin({
                                  right: $r('sys.float.padding_level2'),
                                })
                                .opacity(this.numberInputValue ? 1 : $r('sys.float.alpha_tertiary'))
                              Text(this.simOperatorNameFirst)
                                .fontColor($r('app.color.emc_font_on_primary'))
                                .fontWeight(FontWeight.Regular)
                                .width(this.isNewFoldPhoneExternalScreen ? '48vp' :
                                $r('app.float.emc_padding_level28'))
                                .fontSize('12vp')
                                .opacity(this.numberInputValue ? 1 : $r('sys.float.alpha_disable'))
                                .margin({
                                  left: $r('sys.float.padding_level2'),
                                })
                            }
                            .height($r('app.float.emc_padding_level20'))
                            .alignItems(VerticalAlign.Center)
                            .justifyContent(FlexAlign.Center)
                            .borderRadius($r('sys.float.corner_radius_level10'))
                            .width(this.isNewFoldPhoneExternalScreen ? 92 : this.getSizeWidth())
                          }
                          .opacity(this.numberInputValue ? 1 : $r('sys.float.alpha_disable'))
                          .backgroundColor($r('app.color.emc_confirm'))
                          .margin({
                            right: this.isNewFoldPhoneExternalScreen ? '4vp' : $r('sys.float.padding_level4')
                          })
                          .onClick(() => {
                            if (this.numberInputValue) {
                              this.dialButtonClick(commonData.int.SIM_SLOT_ID_FIRST);
                            }
                          })
                          .accessibilityDescription(this.numberInputValue.length > 0 ?
                          $r('app.string.one_finger_double_click') : $r('app.string.not_available'))

                          Button() {
                            Row() {
                              SymbolGlyph(EmergencyCallController.getInstance()
                                .getPhoneBadgeIcon(commonData.int.SIM_SLOT_ID_SECOND))
                                .fontSize($r('app.float.emc_level8'))
                                .fontColor(['#E5E5E5'])
                                .margin({
                                  right: $r('sys.float.padding_level2'),
                                })
                                .opacity(this.numberInputValue ? 1 : $r('sys.float.alpha_disable'))
                              Text(this.simOperatorNameSecond)
                                .fontColor($r('app.color.emc_font_on_primary'))
                                .fontWeight(FontWeight.Regular)
                                .fontSize('12vp')
                                .width(this.isNewFoldPhoneExternalScreen ? '48vp' :
                                $r('app.float.emc_padding_level28'))
                                .opacity(this.numberInputValue ? 1 : $r('sys.float.alpha_disable'))
                                .margin({
                                  left: $r('sys.float.padding_level2'),
                                })
                            }
                            .height($r('app.float.emc_padding_level20'))
                            .alignItems(VerticalAlign.Center)
                            .justifyContent(FlexAlign.Center)
                            .borderRadius($r('sys.float.corner_radius_level10'))
                            .width(this.isNewFoldPhoneExternalScreen ? 92 : this.getSizeWidth())
                          }
                          .backgroundColor($r('app.color.emc_confirm'))
                          .opacity(this.numberInputValue ? 1 : $r('sys.float.alpha_disable'))
                          .margin({
                            left: this.isNewFoldPhoneExternalScreen ? '4vp' : $r('sys.float.padding_level4')
                          })
                          .onClick(() => {
                            if (this.numberInputValue) {
                              this.dialButtonClick(commonData.int.SIM_SLOT_ID_SECOND);
                            }
                          })
                          .accessibilityDescription(this.numberInputValue.length > 0 ?
                          $r('app.string.one_finger_double_click') : $r('app.string.not_available'))

                          Button() {
                            Row() {
                              Row() {
                                SymbolGlyph($r('sys.symbol.delete_left_fill'))
                                  .fontSize($r('app.float.emc_padding_level12'))
                                  .fontColor(['#E5E5E5'])
                                  .opacity(this.numberInputValue.length > 0 ? 1 : 0.38)
                                  .accessibilityLevel('no')

                              }
                              .alignItems(VerticalAlign.Center)
                              .justifyContent(FlexAlign.Center)
                            }
                            .width(this.isNewFoldPhoneExternalScreen ? 44 : $r('app.float.emc_padding_level24'))
                            .height(this.isNewFoldPhoneExternalScreen ? 40 : $r('app.float.emc_padding_level24'))
                            .margin({
                              left: this.isNewFoldPhoneExternalScreen ? 0 : $r('sys.float.padding_level2')
                            })
                            .borderRadius($r('sys.float.corner_radius_level4'))
                            .alignItems(VerticalAlign.Center)
                            .justifyContent(this.isNewFoldPhoneExternalScreen ? FlexAlign.End : FlexAlign.Center)
                          }
                          .backgroundColor(this.deleteBtnPressed ? $r('sys.color.interactive_click') : Color.Transparent)
                          .onTouch((event: TouchEvent) => {
                            if (event.type === TouchType.Down) {
                              this.deleteBtnPressed = true;
                            }
                            if (event.type === TouchType.Up) {
                              this.deleteBtnPressed = false;
                            }
                          })
                          .gesture(GestureGroup(GestureMode.Parallel,
                            LongPressGesture({ repeat: true, duration: DURATION_LONG }).onAction(() => {
                              if (this.numberInputValue.length > 0) {
                                this.textInputValue = '';
                                this.numberInputValue = '';
                              }
                            })
                          ))
                          .onClick(() => {
                            if (this.numberInputValue.length > 0) {
                              let resNormal = this.textInputValue.length - 1;
                              this.textInputValue = this.textInputValue.substring(0, resNormal);
                              this.numberInputValue = this.textInputValue;
                            }
                          })
                          .accessibilityText(this.mEmergencyCallController.formatResourceToString(
                            $r('app.string.InfoEdit_delete')))
                          .accessibilityDescription(this.numberInputValue.length > 0 ?
                          $r('app.string.one_finger_double_click') : $r('app.string.not_available'))
                          if (!this.isNewFoldPhoneExternalScreen) {
                            Blank()
                          }
                        }
                        .height(this.isNewFoldPhoneExternalScreen ? '40vp' : $r('app.float.emc_padding_level24'))
                        .width('100%')
                        .margin({
                          top: this.isNewFoldPhoneExternalScreen ? '24vp' : $r('app.float.emc_padding_level18')
                        })
                      } else {
                        if (this.defaultVoiceId !== -1 && (sim.getMaxSimCount() > 1)) {
                          Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
                            Row()
                              .margin({
                                right: this.curBp === 'sm' ?
                                $r('sys.float.padding_level4') : $r('sys.float.padding_level6')
                              })
                              .width('100%')
                            Row() {
                              Button() {
                                Row() {
                                  SymbolGlyph(EmergencyCallController.getInstance()
                                    .getPhoneBadgeIcon(this.defaultVoiceId))
                                    .fontSize($r('app.float.emc_level8'))
                                    .fontColor(['#E5E5E5'])
                                    .margin({
                                      right: $r('sys.float.padding_level2'),
                                      left: $r('sys.float.padding_level8')
                                    })
                                    .opacity(this.numberInputValue ? 1 : $r('sys.float.alpha_disable'))
                                  Text(this.defaultVoiceId === 0 ?
                                  this.simOperatorNameFirst : this.simOperatorNameSecond)
                                    .fontColor($r('app.color.emc_font_on_primary'))
                                    .fontWeight(FontWeight.Regular)
                                    .width($r('app.float.emc_padding_level28'))
                                    .fontSize('12vp')
                                    .opacity(this.numberInputValue ? 1 : $r('sys.float.alpha_disable'))
                                    .textAlign(TextAlign.Start)
                                    .margin({
                                      left: $r('sys.float.padding_level2'),
                                      right: $r('sys.float.padding_level8')
                                    })
                                }
                                .width($r('app.float.emc_width116'))
                                .height($r('app.float.emc_padding_level20'))
                                .width(this.getSizeWidth())
                                .alignItems(VerticalAlign.Center)
                                .borderRadius($r('sys.float.corner_radius_level10'))
                              }
                              .backgroundColor($r('app.color.emc_confirm'))
                              .opacity(this.numberInputValue ? 1 : $r('sys.float.alpha_disable'))
                              .onClick(() => {
                                if (this.numberInputValue) {
                                  this.dialButtonClick(this.defaultVoiceId === 0 ?
                                  commonData.int.SIM_SLOT_ID_FIRST : commonData.int.SIM_SLOT_ID_SECOND);
                                }
                              })
                            }
                            .justifyContent(FlexAlign.Center)
                            .width('100%')
                            .height($r('app.float.emc_padding_level20'))
                            .margin({
                              right: this.curBp === 'sm' ?
                              $r('sys.float.padding_level4') : $r('sys.float.padding_level6')
                            })
                            .accessibilityDescription(this.numberInputValue.length > 0 ?
                            $r('app.string.one_finger_double_click') : $r('app.string.not_available'))

                            Row() {
                              Button() {
                                Row() {
                                  SymbolGlyph($r('sys.symbol.delete_left_fill'))
                                    .fontSize($r('app.float.emc_padding_level12'))
                                    .fontColor(['#E5E5E5'])
                                    .opacity(this.numberInputValue.length > 0 ? 1 : 0.38)
                                    .accessibilityLevel('no')

                                }
                                .alignItems(VerticalAlign.Center)
                                .justifyContent(FlexAlign.Center)
                                .width($r('app.float.emc_padding_level24'))
                                .height($r('app.float.emc_padding_level24'))
                                .borderRadius($r('sys.float.corner_radius_level4'))
                              }
                              .backgroundColor(this.deleteBtnPressed ? $r('sys.color.interactive_click') : Color.Transparent)
                              .onTouch((event: TouchEvent) => {
                                if (event.type === TouchType.Down) {
                                  this.deleteBtnPressed = true;
                                }
                                if (event.type === TouchType.Up) {
                                  this.deleteBtnPressed = false;
                                }
                              })
                              .gesture(GestureGroup(GestureMode.Parallel,
                                LongPressGesture({ repeat: true, duration: DURATION_LONG }).onAction(() => {
                                  if (this.numberInputValue.length > 0) {
                                    this.textInputValue = '';
                                    this.numberInputValue = '';
                                  }
                                })
                              ))
                              .onClick((event: ClickEvent) => {
                                if (this.numberInputValue.length > 0) {
                                  let resNormal = this.textInputValue.length - 1;
                                  this.textInputValue = this.textInputValue.substring(0, resNormal);
                                  this.numberInputValue = this.textInputValue;
                                }
                              })
                              .accessibilityText(this.mEmergencyCallController.formatResourceToString(
                                $r('app.string.InfoEdit_delete')))
                              .accessibilityDescription(this.numberInputValue.length > 0 ?
                              $r('app.string.one_finger_double_click') : $r('app.string.not_available'))
                            }
                            .height($r('app.float.emc_padding_level24'))
                            .width('100%')
                            .alignItems(VerticalAlign.Center)
                            .justifyContent(FlexAlign.Center)
                          }
                          .width('100%')
                          .margin({
                            top: $r('app.float.emc_padding_level18'),
                          })
                          .height($r('app.float.emc_padding_level24'))
                        } else {
                          Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                            Row()
                              .margin({
                                right: this.isNewFoldPhoneExternalScreen ? 4 : this.curBp === 'sm' ?
                                $r('sys.float.padding_level4') : $r('sys.float.padding_level6')
                              })
                              .width('100%')

                            Row() {
                              Button() {
                                Row() {
                                  Row() {
                                    SymbolGlyph($r('sys.symbol.phone_fill'))
                                      .fontSize($r('app.float.emc_widthLevel14'))
                                      .fontColor(['#E5E5E5'])
                                  }
                                  .alignItems(VerticalAlign.Center)
                                  .justifyContent(FlexAlign.Center)
                                  .width(this.isNewFoldPhoneExternalScreen ? 56 : $r('app.float.emc_padding_level32'))
                                  .height(this.isNewFoldPhoneExternalScreen ? 56 : $r('app.float.emc_padding_level32'))
                                }
                                .width(this.isNewFoldPhoneExternalScreen ? 56 : $r('app.float.emc_padding_level32'))
                                .height(this.isNewFoldPhoneExternalScreen ? 56 : $r('app.float.emc_padding_level32'))
                                .borderRadius(this.isNewFoldPhoneExternalScreen ? 28 :
                                $r('sys.float.corner_radius_level16'))
                                .alignItems(VerticalAlign.Center)
                                .justifyContent(FlexAlign.End)
                              }
                              .backgroundColor($r('app.color.emc_confirm'))
                              .borderColor($r('app.color.emc_border_color'))
                              .onClick(() => {
                                let slotId: number = commonData.int.SIM_SLOT_ID_EMPTY;
                                if ((this.simOperatorNameFirst.length === 0 &&
                                  this.simOperatorNameSecond.length === 0) || this.isAirPlaneMode) {
                                  data.getDefaultCellularDataSlotId((error, slotIdNum) => {
                                    if (error) {
                                      LogUtils.e(TAG, `getDefaultCellularDataSlotId error.`);
                                    } else {
                                      slotId = slotIdNum;
                                      this.dialButtonClick(slotId);
                                    }
                                  });
                                  return;
                                }
                                if (this.simOperatorNameFirst.length > 0) {
                                  slotId = commonData.int.SIM_SLOT_ID_FIRST;
                                } else if (this.simOperatorNameSecond.length > 0) {
                                  slotId = commonData.int.SIM_SLOT_ID_SECOND;
                                }
                                this.dialButtonClick(slotId);
                              })
                              .accessibilityText(this.mEmergencyCallController.formatResourceToString(
                                $r('app.string.InfoEdit_dail')))
                              .opacity(this.numberInputValue ? 1 : $r('sys.float.alpha_disable'))
                              .accessibilityDescription(this.numberInputValue.length > 0 ?
                              $r('app.string.one_finger_double_click') : $r('app.string.not_available'))
                            }
                            .justifyContent(FlexAlign.Center)
                            .width('100%')
                            .height(this.isNewFoldPhoneExternalScreen ? 56 : $r('app.float.emc_padding_level32'))
                            .margin({
                              end: this.isNewFoldPhoneExternalScreen ? LengthMetrics.vp(4) : this.curBp === 'sm' ?
                              LengthMetrics.resource($r('sys.float.padding_level4')) :
                              LengthMetrics.resource($r('sys.float.padding_level6'))
                            })

                            Row() {
                              Button() {
                                Row() {
                                  SymbolGlyph($r('sys.symbol.delete_left_fill'))
                                    .fontSize($r('app.float.emc_padding_level12'))
                                    .fontColor(['#E5E5E5'])
                                    .opacity(this.numberInputValue.length > 0 ? 1 : 0.38)
                                    .accessibilityLevel('no')
                                    .gesture(GestureGroup(GestureMode.Exclusive,
                                      LongPressGesture({ repeat: true, duration: DURATION_LONG }).onAction(() => {
                                        if (this.numberInputValue.length > 0) {
                                          this.textInputValue = '';
                                          this.numberInputValue = '';
                                        }
                                      })
                                    ))
                                }
                                .alignItems(VerticalAlign.Center)
                                .justifyContent(FlexAlign.Center)
                                .width($r('app.float.emc_padding_level24'))
                                .height($r('app.float.emc_padding_level24'))
                                .borderRadius($r('sys.float.corner_radius_level4'))
                              }
                              .backgroundColor(this.deleteBtnPressed ? $r('sys.color.interactive_click') : Color.Transparent)
                              .onTouch((event: TouchEvent) => {
                                if (event.type === TouchType.Down) {
                                  this.deleteBtnPressed = true;
                                }
                                if (event.type === TouchType.Up) {
                                  this.deleteBtnPressed = false;
                                }
                              })
                              .gesture(GestureGroup(GestureMode.Parallel,
                                LongPressGesture({ repeat: true, duration: DURATION_LONG }).onAction(() => {
                                  if (this.numberInputValue.length > 0) {
                                    this.textInputValue = '';
                                    this.numberInputValue = '';
                                  }
                                })
                              ))
                              .onClick(() => {
                                if (this.numberInputValue.length > 0) {
                                  let resNormal = this.textInputValue.length - 1;
                                  let delNum = this.textInputValue.substring(this.textInputValue.length - 1);
                                  this.textInputValue = this.textInputValue.substring(0, resNormal);
                                  this.numberInputValue = this.textInputValue;
                                  if (accessibility.isOpenAccessibilitySync()) {
                                    this.sendAccessibilityEventInfo(
                                      this.mEmergencyCallController.formatResourceToStringWithParams(
                                        $r('app.string.NumberEdit_delete'), delNum));
                                  }
                                }
                              })
                              .accessibilityText(this.mEmergencyCallController.formatResourceToString(
                                $r('app.string.InfoEdit_delete')))
                              .accessibilityDescription(this.numberInputValue.length > 0 ?
                              $r('app.string.one_finger_double_click') : $r('app.string.not_available'))
                            }
                            .height('100%')
                            .width('100%')
                            .alignItems(VerticalAlign.Center)
                            .justifyContent(FlexAlign.Center)
                          }
                          .width('100%')
                          .margin({
                            top: this.isNewFoldPhoneExternalScreen ? '16vp' :
                              this.isLandscape ? $r('app.float.emc_padding_level6') : $r('sys.float.padding_level12'),
                            bottom: this.isNewFoldPhoneExternalScreen ? '32vp' : 0
                          })
                          .height(this.isNewFoldPhoneExternalScreen ? 56 : $r('app.float.emc_padding_level32'))
                        }
                      }
                    }
                    .height(this.isNewFoldPhoneExternalScreen ? 104 :
                      this.isLandscape ? $r('app.float.emc_padding_level555') : $r('app.float.emc_padding_level615'))
                  }
                } else {
                  Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.End }) {
                    Column() {
                      List({ space: 12, initialIndex: 0 }) {
                        ForEach(this.emergencyContactsList, (item: EmergencyNumListStruct, index: number) => {
                          ListItem() {
                            if (this.clickActiveContactItemIds.includes(item.id)) {
                              ActiveListItem({ listItem: item })
                                .translate({ x: this.movingId === item.id ? this.activeOffsetX : 0 })
                                .gesture(
                                  PanGesture({ direction: PanDirection.Horizontal })
                                    .onActionEnd((event: GestureEvent) => {
                                      if (event.offsetX > 0) {
                                        this.activeOffsetX = 0;
                                      }
                                      if (event.offsetX > 150) {
                                        this.mEmergencyCallController.emergencyCallDial(item.value, item.slotId, true);
                                        this.mEmergencyCallController.setTimeOutIdList.forEach(value => {
                                          if (value.timerId) {
                                            clearTimeout(value.timerId);
                                          }
                                        })
                                        this.mEmergencyCallController.setTimeOutIdList = [];
                                        this.clickActiveContactItemIds = [];
                                        this.movingId = ''
                                        ReportUtil.getInstance().reportEmergencyDial(item.value.length);
                                      }
                                    })
                                    .onActionUpdate((event: GestureEvent) => {
                                      this.mEmergencyCallController.clearIdOfList(item.id, (data: string) => {
                                        this.clickActiveContactItemIds =
                                          this.clickActiveContactItemIds.filter(value => value !== data);
                                      });
                                      this.movingId = item.id;
                                      if (event.offsetX > 0) {
                                        this.activeOffsetX = event.offsetX;
                                      }
                                    })
                                )
                            } else {
                              DefaultListItem({
                                listItem: item,
                                communicationNetworkType: CommunicationNetworkType.NONE
                              })
                                .onClick(() => {
                                  this.clickActiveContactItemIds.push(item.id);
                                  let timer = setTimeout(() => {
                                    this.clickActiveContactItemIds =
                                      this.clickActiveContactItemIds.filter(val => val !== item.id);
                                    this.mEmergencyCallController.setTimeOutIdList =
                                      this.mEmergencyCallController.setTimeOutIdList.filter(value =>
                                      value.itemId !== item.id);
                                  }, LLIST_SEL_TIMEOUT)
                                  let timerItem: TimeOutStruct = {
                                    itemId: item.id,
                                    timerId: timer
                                  }
                                  this.mEmergencyCallController.pushIdToList(timerItem);
                                })
                                .accessibilityText(item.value + this.getBarrierFree(item.label))
                            }
                          }
                          .width('100%')
                          .constraintSize({ minHeight: $r('app.float.emc_wh_level64') })
                          .backgroundColor(this.clickActiveContactItemIds.includes(item.id) ?
                          $r('app.color.emc_warning') : 'rgba(255, 255, 255, 0.2)')
                          .borderRadius($r('sys.float.corner_radius_level10'))
                        },
                          (item: ContactListStruct) => JSON.stringify(item))
                      }
                      .scrollBar(BarState.Off)
                      .width('100%')
                      .listDirection(Axis.Vertical)
                      .contentEndOffset(this.isNewFoldPhoneExternalScreen ? 112 : 0)
                      .height(this.isNewFoldPhoneExternalScreen ? '276vp' : 'auto')
                    }
                    .justifyContent(FlexAlign.End)
                    .height(this.isNewFoldPhoneExternalScreen ? 'calc(100% - 112vp)' : 'auto')

                    if (!this.isNewFoldPhoneExternalScreen) {
                      Column() {
                        Row() {
                          SymbolGlyph($r('sys.symbol.dial'))
                            .fontSize($r('app.float.emc_widthLevel14'))
                            .fontColor(['#E5E5E5'])
                            .id('EmergencyCommunication_pages_index_rowImage_DTMF')
                        }
                        .width($r('app.float.emc_padding_level32'))
                        .height($r('app.float.emc_padding_level32'))
                        .borderRadius($r('sys.float.corner_radius_level16'))
                        .backgroundColor('rgba(255, 255, 255, 0.2)')
                        .justifyContent(FlexAlign.Center)
                        .margin({ top: $r('sys.float.padding_level12') })
                        .onClick(() => {
                          this.showKeyboard();
                        })
                        .accessibilityText(this.mEmergencyCallController.formatResourceToString(
                          $r('app.string.InfoEdit_show_dialpad')))
                        .accessibilityRole(AccessibilityRoleType.BUTTON)
                      }
                      .height($r('app.float.emc_padding_level615'))
                      .width('100%')
                    } else {
                      Stack() {
                        Row()
                          .position({ top: 0 })
                          .width('100%')
                          .height(112)
                          .linearGradient({
                            angle: 180,
                            colors: [['rgba(0, 0, 0, 0)', 0], ['rgba(0, 0, 0, 0.6)', 1]]
                          })
                          .responseRegion({
                            x: 0,
                            y: 0,
                            width: '0%',
                            height: '0%'
                          });

                        Column() {
                          Row() {
                            SymbolGlyph($r('sys.symbol.dial'))
                              .fontSize($r('app.float.emc_widthLevel14'))
                              .fontColor(['#E5E5E5'])
                              .id('EmergencyCommunication_pages_index_rowImage_DTMF')
                          }
                          .width(this.isNewFoldPhoneExternalScreen ? 56 : $r('app.float.emc_padding_level32'))
                          .height(this.isNewFoldPhoneExternalScreen ? 56 : $r('app.float.emc_padding_level32'))
                          .borderRadius(this.isNewFoldPhoneExternalScreen ? 28 :
                          $r('sys.float.corner_radius_level16'))
                          .backgroundColor('rgba(255, 255, 255, 0.2)')
                          .backgroundEffect({
                            radius: 120,
                            saturation: 1.1,
                            brightness: 1.0,
                            color: '#0CFFFFFF'
                          })
                          .justifyContent(FlexAlign.Center)
                          .margin({
                            top: $r('sys.float.padding_level12'),
                            bottom: this.isNewFoldPhoneExternalScreen ? 32 : 0
                          })
                          .onClick(() => {
                            this.showKeyboard();
                          })
                          .accessibilityText(this.mEmergencyCallController.formatResourceToString(
                            $r('app.string.InfoEdit_show_dialpad')))
                          .accessibilityRole(AccessibilityRoleType.BUTTON)
                        }
                        .height(this.isNewFoldPhoneExternalScreen ? 112 : $r('app.float.emc_padding_level615'))
                        .width('100%')
                      }
                      .width('100%')
                    }
                  }
                  .margin({ top: this.isNewFoldPhoneExternalScreen ? '12vp' : $r('sys.float.padding_level10') })
                  .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
                }
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
            }
          }
        }
        .margin({
          left: this.isNewFoldPhoneExternalScreen ? this.isShowKeyboard ? '22vp' : '16VP' :
          CallColumnUtils.getInstance().getPaddingSpace(this.curBp, false),
          right: this.isNewFoldPhoneExternalScreen ? this.isShowKeyboard ? '22vp' : '16VP' :
          CallColumnUtils.getInstance().getPaddingSpace(this.curBp, false)
        })
      }*/
      Navigation(this.pathInfos) {
        GridRow({ columns: { sm: 4, md: 8, lg: 12 }, gutter: { x: 24 } }) {
          GridCol({ span: { sm: 4, md: 8, lg: 12 } }) {
            Row() {
              Button() {
                Row() {
                  SymbolGlyph($r('sys.symbol.chevron_backward'))
                    .fontSize($r('app.float.emc_padding_level12'))
                    .fontColor([$r('app.color.emc_font_on_primary')])
                }
                .borderRadius($r('sys.float.corner_radius_level10'))
                .width($r('app.float.emc_padding_level20'))
                .height($r('app.float.emc_padding_level20'))
                .justifyContent(FlexAlign.Center)
                .alignItems(VerticalAlign.Center)
              }
              .type(ButtonType.Circle)
              .backgroundColor($r('app.color.emc_comp_background_tertiary'))
              .onClick(() => {
                this.exiting();
              })
              .accessibilityText(this.mEmergencyCallController.formatResourceToString(
                $r('app.string.InfoEdit_back')))

              //if (this.isAutoLocation) {
              if (true) {
                Row() {
                  SymbolGlyph($r('sys.symbol.dot_grid_2x2'))
                    .fontSize($r('app.float.emc_padding_level12'))
                    .fontColor(['#E5E5E5'])
                }
                .borderRadius($r('sys.float.corner_radius_level10'))
                .backgroundColor($r('app.color.emc_comp_background_tertiary'))
                .width($r('app.float.emc_padding_level20'))
                .height($r('app.float.emc_padding_level20'))
                .justifyContent(FlexAlign.Center)
                .alignItems(VerticalAlign.Center)
                .accessibilityText(this.mEmergencyCallController.formatResourceToString(
                  $r('app.string.InfoEdit_edit')))
                .bindMenu(this.MenuBuilders())
              }
            }
            .justifyContent(FlexAlign.SpaceBetween)
            .alignItems(VerticalAlign.Center)
            .width('100%')
            .height($r('app.float.emc_padding_level28'))
          }
          .visibility(this.isNewFoldPhoneExternalScreen ? Visibility.None : Visibility.Visible)

          GridCol({ span: { sm: 4, md: 6, lg: 8 }, offset: { md: 1, lg: 2 } }) {
            Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.SpaceBetween }) {
              Column() {
                Button($r('app.string.personalEmergencyInfo'), { buttonStyle: ButtonStyleMode.NORMAL })
                  .fontColor($r('app.color.emc_font_on_primary'))
                  .fontWeight(FontWeight.Medium)
                  .labelStyle({ maxFontSize: '16vp', minFontSize: this.fontSizeScale !== 0 ? '16vp' : '9vp' })
                  .constraintSize({
                    minWidth: $r('app.float.emc_padding_level100'),
                    maxWidth: '100%',
                    minHeight: '40vp'
                  })
                  .onClick(() => {
                    // Jump to EmergencyInfoView
                    this.pathInfos.pushPathByName('EmergencyInfoView', '');
                    ReportUtil.getInstance().reportClickPersonEmergencyInfo();
                  })
                  .backgroundColor($r('app.color.emc_comp_background_tertiary'))
                  //路径： entry/src/main/ets/pages/EmergencyInfoView.ets
                  // .visibility((this.isInOOBE || !this.alreadyUnlocked || this.isNewFoldPhoneExternalScreen) ?
                  //   Visibility.None : Visibility.Visible)

                Scroll(this.textScroller) {
                  Text(this.numberInputValue ? this.numberInputValue : $r('app.string.emergencyCallsOnly'))
                    .maxLines(1)
                    .fontSize(this.isNewFoldPhoneExternalScreen ? '24vp' : this.getNameFontSize())
                    .fontColor($r('app.color.emc_font_on_primary'))
                    .textAlign(TextAlign.Center)
                    .lineHeight(this.isNewFoldPhoneExternalScreen ? '32vp' : '40vp')
                    .fontWeight(FontWeight.Bold)
                    .id('EmergencyCommunication_pages_index_scrollText_emergencyCallsOnly')
                    .height(this.isNewFoldPhoneExternalScreen ? '32vp' :
                      this.isShowLandscapeHeight === true ? $r('app.float.emc_padding_level24') :
                        $r('app.float.emc_padding_level32'))
                    .constraintSize({ minWidth: '100%' })
                }
                .scrollable(ScrollDirection.Horizontal)
                .scrollBar(BarState.Off)
                .draggable(true)
                .width('100%')
                .margin({
                  top: this.isNewFoldPhoneExternalScreen ? 8 :
                    this.isLandscape === true ? 0 : $r('sys.float.padding_level4')
                })
                .height(this.isNewFoldPhoneExternalScreen ? '32vp' : this.isShowLandscapeHeight === true ? '48vp'
                  : '64vp')
              }
              .alignItems(HorizontalAlign.Center)
              .padding({
                top: (this.isNewFoldPhoneExternalScreen || this.isLandscape === true) ? 0 : $r('sys.float.padding_level4')
              })

              Row() {
                //if (!this.isSatelliteModeOn) {
                  if (true) {
                  Row() {
                    SymbolGlyph($r('sys.symbol.local'))
                      .fontSize($r('app.float.emc_paddding_level9'))
                      .fontColor(['#E5E5E5'])
                      .margin({
                        top: LengthMetrics.resource($r('sys.float.padding_level1')),
                        bottom: LengthMetrics.resource($r('sys.float.padding_level1')),
                        end: LengthMetrics.resource($r('sys.float.padding_level2')) })
                      .opacity($r('sys.float.alpha_secondary'))
                      .accessibilityText($r('app.string.positioning'))
                      .accessibilityRole(AccessibilityRoleType.BUTTON)
                    Text(this.isAutoLocation ?
                      (this.getLocationState === commonData.int.LOCATION_STATE_DONE ?
                        this.locationStr : this.locationText) : $r('app.string.getLocation'))
                      .fontSize('16vp')
                      .fontColor($r('sys.color.font_on_secondary'))
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .textAlign(TextAlign.Center)
                      .maxLines(2)
                      .flexShrink(1)
                  }
                  .onClick(() => {
                    // UE report click getLocation
                    ReportUtil.getInstance().reportClickGEOLocation();
                    if (!this.hasPermission) {
                      this.permissionHintDialog.open();
                    }
                    if (this.isAutoLocation) {
                      if (this.getLocationState === commonData.int.LOCATION_STATE_DOING) {
                        return;
                      }
                      this.getLocationState = commonData.int.LOCATION_STATE_DOING;
                      this.locationText = $r('app.string.gettingLocation');
                      this.mEmergencyCallController.getLocationInfo((data) => {
                        this.getLocationCallback(data);
                      });
                    } else {
                      this.showLocationConfirmDialog($r('app.string.getLocationService'),
                        $r('app.string.getLocationMsg1'), true);
                    }
                  })
                  .width('100%')
                  .justifyContent(FlexAlign.Center)
                  .alignItems(VerticalAlign.Top)
                    //路径： entry/src/main/ets/pages/EmergencyInfoView.ets
                  // .visibility((this.isInOOBE || !this.alreadyUnlocked) ? Visibility.None : Visibility.Visible)
                }
              }
              .width('100%')
              .height(this.isLandscape === true ? null : $r('app.float.emc_padding_level32'))
              .alignItems(VerticalAlign.Center)
              .justifyContent(FlexAlign.Center)
              .visibility(this.isNewFoldPhoneExternalScreen ? Visibility.None : Visibility.Visible)

              Column() {
                if (this.isShowKeyboard === true || (this.simOperatorNameFirst.length === 0 &&
                  this.simOperatorNameSecond.length === 0) || this.isAirPlaneMode || !this.hasEmergencyContactsList()) {
                  Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.End }) {
                    Row() {
                      Keyboard({ inputValue: $numberInputValue,
                        textInputValue: $textInputValue,
                        isInOOBE: $isInOOBE,
                        isLandscape: this.isLandscape
                      })
                    }
                    .alignItems(VerticalAlign.Center)
                    .width('100%')

                    Column() {
                      if (this.simOperatorNameFirst.length > 0 && this.simOperatorNameSecond.length > 0 &&
                        this.defaultVoiceId === -1 && !this.isAirPlaneMode) {
                        Flex({ alignItems: ItemAlign.Center }) {
                          if (!this.isNewFoldPhoneExternalScreen) {
                            Blank()
                          }
                          Row()
                            .width(this.isNewFoldPhoneExternalScreen ? '46vp' : $r('app.float.emc_padding_level24'))
                            .height(this.isNewFoldPhoneExternalScreen ? '40vp' : $r('app.float.emc_padding_level24'))
                            .margin({
                              right: this.isNewFoldPhoneExternalScreen ? 0 : $r('sys.float.padding_level2')
                            })

                          Button() {
                            Row() {
                              SymbolGlyph(EmergencyCallController.getInstance()
                                .getPhoneBadgeIcon(commonData.int.SIM_SLOT_ID_FIRST))
                                .fontSize($r('app.float.emc_level8'))
                                .fontColor(['#E5E5E5'])
                                .margin({
                                  right: $r('sys.float.padding_level2'),
                                })
                                .opacity(this.numberInputValue ? 1 : $r('sys.float.alpha_tertiary'))
                              Text(this.simOperatorNameFirst)
                                .fontColor($r('app.color.emc_font_on_primary'))
                                .fontWeight(FontWeight.Regular)
                                .width(this.isNewFoldPhoneExternalScreen ? '48vp' :
                                  $r('app.float.emc_padding_level28'))
                                .fontSize('12vp')
                                .opacity(this.numberInputValue ? 1 : $r('sys.float.alpha_disable'))
                                .margin({
                                  left: $r('sys.float.padding_level2'),
                                })
                            }
                            .height($r('app.float.emc_padding_level20'))
                            .alignItems(VerticalAlign.Center)
                            .justifyContent(FlexAlign.Center)
                            .borderRadius($r('sys.float.corner_radius_level10'))
                            .width(this.isNewFoldPhoneExternalScreen ? 92 : this.getSizeWidth())
                          }
                          .opacity(this.numberInputValue ? 1 : $r('sys.float.alpha_disable'))
                          .backgroundColor($r('app.color.emc_confirm'))
                          .margin({
                            right: this.isNewFoldPhoneExternalScreen ? '4vp' : $r('sys.float.padding_level4')
                          })
                          .onClick(() => {
                            if (this.numberInputValue) {
                              this.dialButtonClick(commonData.int.SIM_SLOT_ID_FIRST);
                            }
                          })
                          .accessibilityDescription(this.numberInputValue.length > 0 ?
                            $r('app.string.one_finger_double_click') : $r('app.string.not_available'))

                          Button() {
                            Row() {
                              SymbolGlyph(EmergencyCallController.getInstance()
                                .getPhoneBadgeIcon(commonData.int.SIM_SLOT_ID_SECOND))
                                .fontSize($r('app.float.emc_level8'))
                                .fontColor(['#E5E5E5'])
                                .margin({
                                  right: $r('sys.float.padding_level2'),
                                })
                                .opacity(this.numberInputValue ? 1 : $r('sys.float.alpha_disable'))
                              Text(this.simOperatorNameSecond)
                                .fontColor($r('app.color.emc_font_on_primary'))
                                .fontWeight(FontWeight.Regular)
                                .fontSize('12vp')
                                .width(this.isNewFoldPhoneExternalScreen ? '48vp' :
                                  $r('app.float.emc_padding_level28'))
                                .opacity(this.numberInputValue ? 1 : $r('sys.float.alpha_disable'))
                                .margin({
                                  left: $r('sys.float.padding_level2'),
                                })
                            }
                            .height($r('app.float.emc_padding_level20'))
                            .alignItems(VerticalAlign.Center)
                            .justifyContent(FlexAlign.Center)
                            .borderRadius($r('sys.float.corner_radius_level10'))
                            .width(this.isNewFoldPhoneExternalScreen ? 92 : this.getSizeWidth())
                          }
                          .backgroundColor($r('app.color.emc_confirm'))
                          .opacity(this.numberInputValue ? 1 : $r('sys.float.alpha_disable'))
                          .margin({
                            left: this.isNewFoldPhoneExternalScreen ? '4vp' : $r('sys.float.padding_level4')
                          })
                          .onClick(() => {
                            if (this.numberInputValue) {
                              this.dialButtonClick(commonData.int.SIM_SLOT_ID_SECOND);
                            }
                          })
                          .accessibilityDescription(this.numberInputValue.length > 0 ?
                            $r('app.string.one_finger_double_click') : $r('app.string.not_available'))

                          Button() {
                            Row() {
                              Row() {
                                SymbolGlyph($r('sys.symbol.delete_left_fill'))
                                  .fontSize($r('app.float.emc_padding_level12'))
                                  .fontColor(['#E5E5E5'])
                                  .opacity(this.numberInputValue.length > 0 ? 1 : 0.38)
                                  .accessibilityLevel('no')

                              }
                              .alignItems(VerticalAlign.Center)
                              .justifyContent(FlexAlign.Center)
                            }
                            .width(this.isNewFoldPhoneExternalScreen ? 44 : $r('app.float.emc_padding_level24'))
                            .height(this.isNewFoldPhoneExternalScreen ? 40 : $r('app.float.emc_padding_level24'))
                            .margin({
                              left: this.isNewFoldPhoneExternalScreen ? 0 : $r('sys.float.padding_level2')
                            })
                            .borderRadius($r('sys.float.corner_radius_level4'))
                            .alignItems(VerticalAlign.Center)
                            .justifyContent(this.isNewFoldPhoneExternalScreen ? FlexAlign.End : FlexAlign.Center)
                          }
                          .backgroundColor(this.deleteBtnPressed ? $r('sys.color.interactive_click') : Color.Transparent)
                          .onTouch((event: TouchEvent) => {
                            if (event.type === TouchType.Down) {
                              this.deleteBtnPressed = true;
                            }
                            if (event.type === TouchType.Up) {
                              this.deleteBtnPressed = false;
                            }
                          })
                          .gesture(GestureGroup(GestureMode.Parallel,
                            LongPressGesture({ repeat: true, duration: DURATION_LONG }).onAction(() => {
                              if (this.numberInputValue.length > 0) {
                                this.textInputValue = '';
                                this.numberInputValue = '';
                              }
                            })
                          ))
                          .onClick(() => {
                            if (this.numberInputValue.length > 0) {
                              let resNormal = this.textInputValue.length - 1;
                              this.textInputValue = this.textInputValue.substring(0, resNormal);
                              this.numberInputValue = this.textInputValue;
                            }
                          })
                          .accessibilityText(this.mEmergencyCallController.formatResourceToString(
                            $r('app.string.InfoEdit_delete')))
                          .accessibilityDescription(this.numberInputValue.length > 0 ?
                            $r('app.string.one_finger_double_click') : $r('app.string.not_available'))
                          if (!this.isNewFoldPhoneExternalScreen) {
                            Blank()
                          }
                        }
                        .height(this.isNewFoldPhoneExternalScreen ? '40vp' : $r('app.float.emc_padding_level24'))
                        .width('100%')
                        .margin({
                          top: this.isNewFoldPhoneExternalScreen ? '24vp' : $r('app.float.emc_padding_level18')
                        })
                      } else {
                        if (this.defaultVoiceId !== -1 && (sim.getMaxSimCount() > 1)) {
                          Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
                            Row()
                              .margin({
                                right: this.curBp === 'sm' ?
                                  $r('sys.float.padding_level4') : $r('sys.float.padding_level6')
                              })
                              .width('100%')
                            Row() {
                              Button() {
                                Row() {
                                  SymbolGlyph(EmergencyCallController.getInstance()
                                    .getPhoneBadgeIcon(this.defaultVoiceId))
                                    .fontSize($r('app.float.emc_level8'))
                                    .fontColor(['#E5E5E5'])
                                    .margin({
                                      right: $r('sys.float.padding_level2'),
                                      left: $r('sys.float.padding_level8')
                                    })
                                    .opacity(this.numberInputValue ? 1 : $r('sys.float.alpha_disable'))
                                  Text(this.defaultVoiceId === 0 ?
                                    this.simOperatorNameFirst : this.simOperatorNameSecond)
                                    .fontColor($r('app.color.emc_font_on_primary'))
                                    .fontWeight(FontWeight.Regular)
                                    .width($r('app.float.emc_padding_level28'))
                                    .fontSize('12vp')
                                    .opacity(this.numberInputValue ? 1 : $r('sys.float.alpha_disable'))
                                    .textAlign(TextAlign.Start)
                                    .margin({
                                      left: $r('sys.float.padding_level2'),
                                      right: $r('sys.float.padding_level8')
                                    })
                                }
                                .width($r('app.float.emc_width116'))
                                .height($r('app.float.emc_padding_level20'))
                                .width(this.getSizeWidth())
                                .alignItems(VerticalAlign.Center)
                                .borderRadius($r('sys.float.corner_radius_level10'))
                              }
                              .backgroundColor($r('app.color.emc_confirm'))
                              .opacity(this.numberInputValue ? 1 : $r('sys.float.alpha_disable'))
                              .onClick(() => {
                                if (this.numberInputValue) {
                                  this.dialButtonClick(this.defaultVoiceId === 0 ?
                                    commonData.int.SIM_SLOT_ID_FIRST : commonData.int.SIM_SLOT_ID_SECOND);
                                }
                              })
                            }
                            .justifyContent(FlexAlign.Center)
                            .width('100%')
                            .height($r('app.float.emc_padding_level20'))
                            .margin({
                              right: this.curBp === 'sm' ?
                                $r('sys.float.padding_level4') : $r('sys.float.padding_level6')
                            })
                            .accessibilityDescription(this.numberInputValue.length > 0 ?
                              $r('app.string.one_finger_double_click') : $r('app.string.not_available'))

                            Row() {
                              Button() {
                                Row() {
                                  SymbolGlyph($r('sys.symbol.delete_left_fill'))
                                    .fontSize($r('app.float.emc_padding_level12'))
                                    .fontColor(['#E5E5E5'])
                                    .opacity(this.numberInputValue.length > 0 ? 1 : 0.38)
                                    .accessibilityLevel('no')

                                }
                                .alignItems(VerticalAlign.Center)
                                .justifyContent(FlexAlign.Center)
                                .width($r('app.float.emc_padding_level24'))
                                .height($r('app.float.emc_padding_level24'))
                                .borderRadius($r('sys.float.corner_radius_level4'))
                              }
                              .backgroundColor(this.deleteBtnPressed ? $r('sys.color.interactive_click') : Color.Transparent)
                              .onTouch((event: TouchEvent) => {
                                if (event.type === TouchType.Down) {
                                  this.deleteBtnPressed = true;
                                }
                                if (event.type === TouchType.Up) {
                                  this.deleteBtnPressed = false;
                                }
                              })
                              .gesture(GestureGroup(GestureMode.Parallel,
                                LongPressGesture({ repeat: true, duration: DURATION_LONG }).onAction(() => {
                                  if (this.numberInputValue.length > 0) {
                                    this.textInputValue = '';
                                    this.numberInputValue = '';
                                  }
                                })
                              ))
                              .onClick((event: ClickEvent) => {
                                if (this.numberInputValue.length > 0) {
                                  let resNormal = this.textInputValue.length - 1;
                                  this.textInputValue = this.textInputValue.substring(0, resNormal);
                                  this.numberInputValue = this.textInputValue;
                                }
                              })
                              .accessibilityText(this.mEmergencyCallController.formatResourceToString(
                                $r('app.string.InfoEdit_delete')))
                              .accessibilityDescription(this.numberInputValue.length > 0 ?
                                $r('app.string.one_finger_double_click') : $r('app.string.not_available'))
                            }
                            .height($r('app.float.emc_padding_level24'))
                            .width('100%')
                            .alignItems(VerticalAlign.Center)
                            .justifyContent(FlexAlign.Center)
                          }
                          .width('100%')
                          .margin({
                            top: $r('app.float.emc_padding_level18'),
                          })
                          .height($r('app.float.emc_padding_level24'))
                        } else {
                          Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                            Row()
                              .margin({
                                right: this.isNewFoldPhoneExternalScreen ? 4 : this.curBp === 'sm' ?
                                  $r('sys.float.padding_level4') : $r('sys.float.padding_level6')
                              })
                              .width('100%')

                            Row() {
                              Button() {
                                Row() {
                                  Row() {
                                    SymbolGlyph($r('sys.symbol.phone_fill'))
                                      .fontSize($r('app.float.emc_widthLevel14'))
                                      .fontColor(['#E5E5E5'])
                                  }
                                  .alignItems(VerticalAlign.Center)
                                  .justifyContent(FlexAlign.Center)
                                  .width(this.isNewFoldPhoneExternalScreen ? 56 : $r('app.float.emc_padding_level32'))
                                  .height(this.isNewFoldPhoneExternalScreen ? 56 : $r('app.float.emc_padding_level32'))
                                }
                                .width(this.isNewFoldPhoneExternalScreen ? 56 : $r('app.float.emc_padding_level32'))
                                .height(this.isNewFoldPhoneExternalScreen ? 56 : $r('app.float.emc_padding_level32'))
                                .borderRadius(this.isNewFoldPhoneExternalScreen ? 28 :
                                  $r('sys.float.corner_radius_level16'))
                                .alignItems(VerticalAlign.Center)
                                .justifyContent(FlexAlign.End)
                              }
                              .backgroundColor($r('app.color.emc_confirm'))
                              .borderColor($r('app.color.emc_border_color'))
                              .onClick(() => {
                                let slotId: number = commonData.int.SIM_SLOT_ID_EMPTY;
                                if ((this.simOperatorNameFirst.length === 0 &&
                                  this.simOperatorNameSecond.length === 0) || this.isAirPlaneMode) {
                                  data.getDefaultCellularDataSlotId((error, slotIdNum) => {
                                    if (error) {
                                      LogUtils.e(TAG, `getDefaultCellularDataSlotId error.`);
                                    } else {
                                      slotId = slotIdNum;
                                      this.dialButtonClick(slotId);
                                    }
                                  });
                                  return;
                                }
                                if (this.simOperatorNameFirst.length > 0) {
                                  slotId = commonData.int.SIM_SLOT_ID_FIRST;
                                } else if (this.simOperatorNameSecond.length > 0) {
                                  slotId = commonData.int.SIM_SLOT_ID_SECOND;
                                }
                                this.dialButtonClick(slotId);
                              })
                              .accessibilityText(this.mEmergencyCallController.formatResourceToString(
                                $r('app.string.InfoEdit_dail')))
                              .opacity(this.numberInputValue ? 1 : $r('sys.float.alpha_disable'))
                              .accessibilityDescription(this.numberInputValue.length > 0 ?
                                $r('app.string.one_finger_double_click') : $r('app.string.not_available'))
                            }
                            .justifyContent(FlexAlign.Center)
                            .width('100%')
                            .height(this.isNewFoldPhoneExternalScreen ? 56 : $r('app.float.emc_padding_level32'))
                            .margin({
                              end: this.isNewFoldPhoneExternalScreen ? LengthMetrics.vp(4) : this.curBp === 'sm' ?
                                LengthMetrics.resource($r('sys.float.padding_level4')) :
                                LengthMetrics.resource($r('sys.float.padding_level6'))
                            })

                            Row() {
                              Button() {
                                Row() {
                                  SymbolGlyph($r('sys.symbol.delete_left_fill'))
                                    .fontSize($r('app.float.emc_padding_level12'))
                                    .fontColor(['#E5E5E5'])
                                    .opacity(this.numberInputValue.length > 0 ? 1 : 0.38)
                                    .accessibilityLevel('no')
                                    .gesture(GestureGroup(GestureMode.Exclusive,
                                      LongPressGesture({ repeat: true, duration: DURATION_LONG }).onAction(() => {
                                        if (this.numberInputValue.length > 0) {
                                          this.textInputValue = '';
                                          this.numberInputValue = '';
                                        }
                                      })
                                    ))
                                }
                                .alignItems(VerticalAlign.Center)
                                .justifyContent(FlexAlign.Center)
                                .width($r('app.float.emc_padding_level24'))
                                .height($r('app.float.emc_padding_level24'))
                                .borderRadius($r('sys.float.corner_radius_level4'))
                              }
                              .backgroundColor(this.deleteBtnPressed ? $r('sys.color.interactive_click') : Color.Transparent)
                              .onTouch((event: TouchEvent) => {
                                if (event.type === TouchType.Down) {
                                  this.deleteBtnPressed = true;
                                }
                                if (event.type === TouchType.Up) {
                                  this.deleteBtnPressed = false;
                                }
                              })
                              .gesture(GestureGroup(GestureMode.Parallel,
                                LongPressGesture({ repeat: true, duration: DURATION_LONG }).onAction(() => {
                                  if (this.numberInputValue.length > 0) {
                                    this.textInputValue = '';
                                    this.numberInputValue = '';
                                  }
                                })
                              ))
                              .onClick(() => {
                                if (this.numberInputValue.length > 0) {
                                  let resNormal = this.textInputValue.length - 1;
                                  let delNum = this.textInputValue.substring(this.textInputValue.length - 1);
                                  this.textInputValue = this.textInputValue.substring(0, resNormal);
                                  this.numberInputValue = this.textInputValue;
                                  if (accessibility.isOpenAccessibilitySync()) {
                                    this.sendAccessibilityEventInfo(
                                      this.mEmergencyCallController.formatResourceToStringWithParams(
                                        $r('app.string.NumberEdit_delete'), delNum));
                                  }
                                }
                              })
                              .accessibilityText(this.mEmergencyCallController.formatResourceToString(
                                $r('app.string.InfoEdit_delete')))
                              .accessibilityDescription(this.numberInputValue.length > 0 ?
                                $r('app.string.one_finger_double_click') : $r('app.string.not_available'))
                            }
                            .height('100%')
                            .width('100%')
                            .alignItems(VerticalAlign.Center)
                            .justifyContent(FlexAlign.Center)
                          }
                          .width('100%')
                          .margin({
                            top: this.isNewFoldPhoneExternalScreen ? '16vp' :
                              this.isLandscape ? $r('app.float.emc_padding_level6') : $r('sys.float.padding_level12'),
                            bottom: this.isNewFoldPhoneExternalScreen ? '32vp' : 0
                          })
                          .height(this.isNewFoldPhoneExternalScreen ? 56 : $r('app.float.emc_padding_level32'))
                        }
                      }
                    }
                    .height(this.isNewFoldPhoneExternalScreen ? 104 :
                      this.isLandscape ? $r('app.float.emc_padding_level555') : $r('app.float.emc_padding_level615'))
                  }
                } else {
                  Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.End }) {
                    Column() {
                      List({ space: 12, initialIndex: 0 }) {
                        ForEach(this.emergencyContactsList, (item: EmergencyNumListStruct, index: number) => {
                          ListItem() {
                            if (this.clickActiveContactItemIds.includes(item.id)) {
                              ActiveListItem({ listItem: item })
                                .translate({ x: this.movingId === item.id ? this.activeOffsetX : 0 })
                                .gesture(
                                  PanGesture({ direction: PanDirection.Horizontal })
                                    .onActionEnd((event: GestureEvent) => {
                                      if (event.offsetX > 0) {
                                        this.activeOffsetX = 0;
                                      }
                                      if (event.offsetX > 150) {
                                        this.mEmergencyCallController.emergencyCallDial(item.value, item.slotId, true);
                                        this.mEmergencyCallController.setTimeOutIdList.forEach(value => {
                                          if (value.timerId) {
                                            clearTimeout(value.timerId);
                                          }
                                        })
                                        this.mEmergencyCallController.setTimeOutIdList = [];
                                        this.clickActiveContactItemIds = [];
                                        this.movingId = ''
                                        ReportUtil.getInstance().reportEmergencyDial(item.value.length);
                                      }
                                    })
                                    .onActionUpdate((event: GestureEvent) => {
                                      this.mEmergencyCallController.clearIdOfList(item.id, (data: string) => {
                                        this.clickActiveContactItemIds =
                                          this.clickActiveContactItemIds.filter(value => value !== data);
                                      });
                                      this.movingId = item.id;
                                      if (event.offsetX > 0) {
                                        this.activeOffsetX = event.offsetX;
                                      }
                                    })
                                )
                            } else {
                              DefaultListItem({
                                listItem: item,
                                communicationNetworkType: CommunicationNetworkType.NONE
                              })
                                .onClick(() => {
                                  this.clickActiveContactItemIds.push(item.id);
                                  let timer = setTimeout(() => {
                                    this.clickActiveContactItemIds =
                                      this.clickActiveContactItemIds.filter(val => val !== item.id);
                                    this.mEmergencyCallController.setTimeOutIdList =
                                      this.mEmergencyCallController.setTimeOutIdList.filter(value =>
                                      value.itemId !== item.id);
                                  }, LLIST_SEL_TIMEOUT)
                                  let timerItem: TimeOutStruct = {
                                    itemId: item.id,
                                    timerId: timer
                                  }
                                  this.mEmergencyCallController.pushIdToList(timerItem);
                                })
                                .accessibilityText(item.value + this.getBarrierFree(item.label))
                            }
                          }
                          .width('100%')
                          .constraintSize({ minHeight: $r('app.float.emc_wh_level64') })
                          .backgroundColor(this.clickActiveContactItemIds.includes(item.id) ?
                            $r('app.color.emc_warning') : 'rgba(255, 255, 255, 0.2)')
                          .borderRadius($r('sys.float.corner_radius_level10'))
                        },
                          (item: ContactListStruct) => JSON.stringify(item))
                      }
                      .scrollBar(BarState.Off)
                      .width('100%')
                      .listDirection(Axis.Vertical)
                      .contentEndOffset(this.isNewFoldPhoneExternalScreen ? 112 : 0)
                      .height(this.isNewFoldPhoneExternalScreen ? '276vp' : 'auto')
                    }
                    .justifyContent(FlexAlign.End)
                    .height(this.isNewFoldPhoneExternalScreen ? 'calc(100% - 112vp)' : 'auto')

                    if (!this.isNewFoldPhoneExternalScreen) {
                      Column() {
                        Row() {
                          SymbolGlyph($r('sys.symbol.dial'))
                            .fontSize($r('app.float.emc_widthLevel14'))
                            .fontColor(['#E5E5E5'])
                            .id('EmergencyCommunication_pages_index_rowImage_DTMF')
                        }
                        .width($r('app.float.emc_padding_level32'))
                        .height($r('app.float.emc_padding_level32'))
                        .borderRadius($r('sys.float.corner_radius_level16'))
                        .backgroundColor('rgba(255, 255, 255, 0.2)')
                        .justifyContent(FlexAlign.Center)
                        .margin({ top: $r('sys.float.padding_level12') })
                        .onClick(() => {
                          this.showKeyboard();
                        })
                        .accessibilityText(this.mEmergencyCallController.formatResourceToString(
                          $r('app.string.InfoEdit_show_dialpad')))
                        .accessibilityRole(AccessibilityRoleType.BUTTON)
                      }
                      .height($r('app.float.emc_padding_level615'))
                      .width('100%')
                    } else {
                      Stack() {
                        Row()
                          .position({ top: 0 })
                          .width('100%')
                          .height(112)
                          .linearGradient({
                            angle: 180,
                            colors: [['rgba(0, 0, 0, 0)', 0], ['rgba(0, 0, 0, 0.6)', 1]]
                          })
                          .responseRegion({
                            x: 0,
                            y: 0,
                            width: '0%',
                            height: '0%'
                          });

                        Column() {
                          Row() {
                            SymbolGlyph($r('sys.symbol.dial'))
                              .fontSize($r('app.float.emc_widthLevel14'))
                              .fontColor(['#E5E5E5'])
                              .id('EmergencyCommunication_pages_index_rowImage_DTMF')
                          }
                          .width(this.isNewFoldPhoneExternalScreen ? 56 : $r('app.float.emc_padding_level32'))
                          .height(this.isNewFoldPhoneExternalScreen ? 56 : $r('app.float.emc_padding_level32'))
                          .borderRadius(this.isNewFoldPhoneExternalScreen ? 28 :
                            $r('sys.float.corner_radius_level16'))
                          .backgroundColor('rgba(255, 255, 255, 0.2)')
                          .backgroundEffect({
                            radius: 120,
                            saturation: 1.1,
                            brightness: 1.0,
                            color: '#0CFFFFFF'
                          })
                          .justifyContent(FlexAlign.Center)
                          .margin({
                            top: $r('sys.float.padding_level12'),
                            bottom: this.isNewFoldPhoneExternalScreen ? 32 : 0
                          })
                          .onClick(() => {
                            this.showKeyboard();
                          })
                          .accessibilityText(this.mEmergencyCallController.formatResourceToString(
                            $r('app.string.InfoEdit_show_dialpad')))
                          .accessibilityRole(AccessibilityRoleType.BUTTON)
                        }
                        .height(this.isNewFoldPhoneExternalScreen ? 112 : $r('app.float.emc_padding_level615'))
                        .width('100%')
                      }
                      .width('100%')
                    }
                  }
                  .margin({ top: this.isNewFoldPhoneExternalScreen ? '12vp' : $r('sys.float.padding_level10') })
                  .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
                }
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
            }
          }
        }
        .margin({
          left: this.isNewFoldPhoneExternalScreen ? this.isShowKeyboard ? '22vp' : '16VP' :
            CallColumnUtils.getInstance().getPaddingSpace(this.curBp, false),
          right: this.isNewFoldPhoneExternalScreen ? this.isShowKeyboard ? '22vp' : '16VP' :
            CallColumnUtils.getInstance().getPaddingSpace(this.curBp, false)
        })
      }
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
/*      .titleBar({ avoidLayoutSafeArea: true })*/
      .navDestination(this.myRouter)
      .mode(NavigationMode.Stack)
      .hideNavBar(false)
      //.titleMode(HdsNavigationTitleMode.MINI)
      //.titleMode(NavigationTitleMode.Mini)
      .hideTitleBar(true)
      .hideBackButton(this.isNewFoldPhoneExternalScreen)
      .id('EmergencyCommunication_pages_index_body')
    }
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
  }

  sendAccessibilityEventInfo(textAccess: string) {
    let eventInfo: accessibility.EventInfo = ({
      type: 'announceForAccessibility',
      bundleName: 'com.ohos.emergencycommunication',
      triggerAction: 'click',
      textAnnouncedForAccessibility: textAccess
    });
    accessibility.sendAccessibilityEvent(eventInfo).then(() => {
    }).catch((err: BusinessError) => {
      LogUtils.e('Keyboard', `sendAccessibilityEvent failed: err:${err?.code}`);
    });
  }
}

@Component
export struct DefaultListItem {
  listItem: EmergencyNumListStruct = getEmptyEmergencyListData();
  @Prop communicationNetworkType: CommunicationNetworkType = CommunicationNetworkType.NONE;

  aboutToAppear() {
    LogUtils.e(TAG, 'DefaultListItem aboutToAppear');
  }

  build() {
    Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
      Row() {
        SymbolGlyph(this.communicationNetworkType === CommunicationNetworkType.TIAN_TONG ?
        $r('sys.symbol.phone_badge_satellite_fill') : $r('sys.symbol.phone_fill'))
          .fontSize($r('app.float.emc_padding_level12'))
          .fontColor([$r('sys.color.icon_on_primary')])
          .margin({
            start: LengthMetrics.resource($r('sys.float.padding_level6')),
            end: LengthMetrics.resource($r('sys.float.padding_level8'))
          })
        Text(this.listItem.value)
          .fontColor($r('sys.color.font_on_primary'))
          .fontSize('24vp')
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .height($r('app.float.emc_wh_level32'))
          .textAlign(TextAlign.Start)
      }

      Text(this.listItem.label)
        .margin({
          top: $r('sys.float.padding_level1'),
          start: LengthMetrics.resource($r('sys.float.padding_level6')),
          end: LengthMetrics.resource($r('sys.float.padding_level6'))
        })
        .fontColor($r('sys.color.font_on_secondary'))
        .fontSize('14vp')
        .fontWeight(FontWeight.Regular)
        .width('100%')
        .height($r('app.float.emc_padding_level95'))
        .textAlign(TextAlign.End)
    }
  }
}

@Component
export struct ActiveListItem {
  listItem: EmergencyNumListStruct = getEmptyEmergencyListData();

  aboutToAppear() {
    LogUtils.e(TAG, 'ActiveListItem aboutToAppear');
  }

  build() {
    Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontColor(['#E5E5E5'])
        .fontSize($r('app.float.emc_padding_level16'))
        .margin({ end: LengthMetrics.resource($r('sys.float.padding_level2')) })

      Text($r('app.string.rightCall', this.listItem.value))
        .fontSize('24vp')
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.emc_font_on_primary'))
        .lineHeight($r('app.float.emc_wh_level32'))
    }
    .padding({
      top: $r('sys.float.padding_level8'),
      bottom: $r('sys.float.padding_level8'),
      left: $r('sys.float.padding_level6'),
      right: $r('sys.float.padding_level6')
    })
  }
}



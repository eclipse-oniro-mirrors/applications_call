/*
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import { ContactDataStruct, DialogDataStruct, StaticDataUseStruct } from '../common/struct/RecorderSettingStruct';
import autoSelectObjectDialog from '../common/dialog/RecorderAutoSelectObjectDialog';
import LogUtils from '../common/utils/LogUtils';
import commonData from '../common/utils/CommonData';
import CommonController from '../common/control/CommonCtrol';
import router from '@ohos.router';
import { BusinessError } from '@ohos.base';
import { terminateSelfWithResult } from '../common/utils/CommonUtil';
import { CallSettingConstant } from '../common/constant/CallSettingConstant';
import { SelectDialog } from '@ohos.arkui.advanced.Dialog';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import display from '@ohos.display';
import CallRecorderColumnUtils from '../common/utils/CallRecorderColumnUtils'
import { ReportUtil, UE_CLICK_CANCEL, UE_SELECT_ALL_CALL, UE_SPECIFIED_NUMBER } from '../common/utils/ReportUtil';
import { FontScale } from '../common/utils/FontScaleState';
import { LengthMetrics } from '@kit.ArkUI';

/* instrument ignore file */

const AUTORECORDTYPE = 'auto_record_type';
const AUTORECORDOPENFLAG = 'auto_record_open_flag';

PersistentStorage.persistProp(AUTORECORDOPENFLAG, false);
PersistentStorage.persistProp(AUTORECORDTYPE, '1');

/**
 * This template implements the business card function and consists of three components.The top part is the
 * title, and the bottom part is the Tab. The middle card content shows the business information.
 * Developers can enrich the function of title and Tab, and add relevant business information to the list.
 */
const TAG = 'RecordingSettingRecorderConfig';

@Extend(Text)
function commonText(statusUse: Boolean) {
  .fontSize($r('sys.float.Subtitle_M'))
  .fontFamily('HarmonyHeiTi')
  .fontWeight(FontWeight.Medium)
  .constraintSize({ minHeight: 21 })
  .fontColor(statusUse ? $r('sys.color.ohos_id_color_text_primary') : $r('sys.color.ohos_id_color_text_tertiary'))
}

@Extend(Row)
function commonRow(statusUse: Boolean) {
  .width('100%')
  .justifyContent(statusUse ? FlexAlign.SpaceBetween : FlexAlign.End)
  .margin({ top: statusUse ? 2 : 0 })
}

@Entry
@Component
struct Index {
  // get session
  private session: UIExtensionContentSession = LocalStorage.getShared()
    .get<UIExtensionContentSession>('session') as UIExtensionContentSession;
  @State commonController: CommonController = CommonController.getInstance();
  @State staticDataUse: StaticDataUseStruct = {
    statusUse: false,
    objectUse: CallSettingConstant.RECORDING_WAY_ALL_NUMBER,
    numberUse: 0
  };
  @State dialogData: DialogDataStruct = {
    objectUse: '',
    confirm: (data?: string) => {
    }
  };
  selectedRadio: number = -1;
  @State objectUse: string = CallSettingConstant.RECORDING_WAY_ALL_NUMBER;
  @State radioId: number = 0;
  @StorageProp('curBp') curBp: string = '';
  @State statusBarHeight: number = -1;
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('fontSizeScaleMargin') fontSizeScaleMargin: number = 0;
  private isFromExternal: boolean = AppStorage.get<boolean>('isFromExternal') as boolean;
  @State recorderArray: SheetInfo[] = [
    {
      title: $r('app.string.all_calls'),
      action: () => {
        this.recorderText = $r('app.string.all_calls');
        this.radioId = 0;
        this.objectUse = CallSettingConstant.RECORDING_WAY_ALL_NUMBER;
        this.save(CallSettingConstant.RECORDING_WAY_ALL_NUMBER);
        ReportUtil.getInstance().reportRecordOperate(UE_SELECT_ALL_CALL);
      }
    },
    {
      title: $r('app.string.specified_number'),
      action: () => {
        this.recorderText = $r('app.string.specified_number');
        this.radioId = 1;
        this.objectUse = CallSettingConstant.RECORDING_WAY_DESIGNATE_NUMBER;
        this.save(CallSettingConstant.RECORDING_WAY_DESIGNATE_NUMBER);
        ReportUtil.getInstance().reportRecordOperate(UE_SPECIFIED_NUMBER);
      }
    }
  ];
  @State recorderText: ResourceStr = this.recorderArray[0].title;
  confirmDialog: CustomDialogController = new CustomDialogController({
    builder: SelectDialog({
      title: $r('app.string.auto_recording_object'),
      selectedIndex: this.radioId,
      radioContent: this.recorderArray,
      confirm: {
        value: $r('app.string.cancel'),
        action: () => {
          this.selectedRadio = -1;
          this.confirmDialog?.close();
          ReportUtil.getInstance().reportRecordOperate(UE_CLICK_CANCEL);
        }
      },
    }),
    backgroundColor: this.isFromExternal ? '#00000000' : ''
  })

  aboutToAppear() {
    LogUtils.i(TAG, 'RecorderConfig start');
    this.initPageShow();
    try {
      let displaySync = display.getDefaultDisplaySync();
      CallRecorderColumnUtils.getInstance().updateBreakpoint(displaySync.width);
    } catch (error) {
      LogUtils.e(TAG, 'Error getting default display');
    }
    ReportUtil.getInstance();
    this.statusBarHeight = AppStorage.get<number>('statusBarHeight') as number;
  }

  save(params: string) {
    this.dialogData.confirm(params);
    this.confirmDialog?.close();
  }

  onPageShow() {
    this.initPageShow();
  }

  initPageShow() {
    try {
      this.staticDataUse.statusUse = AppStorage.get<boolean>(AUTORECORDOPENFLAG) ?? false;
      this.staticDataUse.objectUse = AppStorage.get<string>(AUTORECORDTYPE);
      this.commonController.queryForConfig((configData) => {
        this.staticDataUse.statusUse = !!configData.isOpen;
        this.staticDataUse.objectUse = configData.object;
        AppStorage.setOrCreate(AUTORECORDOPENFLAG, !!configData.isOpen);
        AppStorage.setOrCreate(AUTORECORDTYPE, configData.object ?? '1');
        if (configData.object === CallSettingConstant.RECORDING_WAY_DESIGNATE_NUMBER) {
          this.commonController.queryForConfigContactLength((configDataLength) => {
            this.staticDataUse.numberUse = configDataLength;
          });
        }
      });
    } catch (err) {
      LogUtils.i(TAG, `initPageShow error code: ${(err as BusinessError).code}`);
    }
  }

  saveRecordingState(isOn: boolean) {
    LogUtils.i(TAG, 'saveRecordingState isOn: ' + isOn);
    let isOnChange = isOn ? CallSettingConstant.OPEN_RECORDING_STATUS : CallSettingConstant.CLOSE_RECORDING_STATUS;
    this.commonController.updateIsOpen(isOnChange, (result) => {
      LogUtils.i(TAG, `saveRecordingState result: ${result}`);
      if (result) {
        this.refreshStatusUse(isOn);
      } else {
        this.updateStatusUseFail(isOn);
      }
    });
    ReportUtil.getInstance().reportCallAutoRecord(isOnChange);
  }

  private updateStatusUseFail(isOn: boolean) {
    this.commonController.queryForConfig((data) => {
      LogUtils.i(TAG, 'saveRecordingState queryForConfig ' + JSON.stringify(data));
      if (data.isOpen === undefined) {
        this.commonController.createForConfig(isOn, (result) => {
          LogUtils.i(TAG, 'saveRecordingState createForConfig ' + JSON.stringify(result));
          if (result) {
            this.refreshStatusUse(isOn);
          }
        });
      }
    });
  }

  private refreshStatusUse(isOn: boolean) {
    this.staticDataUse.statusUse = isOn;
    AppStorage.setOrCreate(AUTORECORDOPENFLAG, isOn);
    // send data to call setting
    this.session?.sendData({ 'recordingState': isOn });
  }

  saveRecordingObject(object: string) {
    this.commonController.updateObject(object, (configData) => {
      this.staticDataUse.objectUse = object;
      AppStorage.setOrCreate(AUTORECORDTYPE, object);
      if (object === CallSettingConstant.RECORDING_WAY_DESIGNATE_NUMBER) {
        this.commonController.queryForConfigContactLength((configDataLength) => {
          this.staticDataUse.numberUse = configDataLength;
        });
      }
    });
  }

  showAutoSelectObjectDialog() {
    this.dialogData.confirm = (params) => {
      let objectChange = params ? params : CallSettingConstant.RECORDING_WAY_ALL_NUMBER;
      this.saveRecordingObject(objectChange);
    }
    this.radioId = this.staticDataUse.objectUse === CallSettingConstant.RECORDING_WAY_DESIGNATE_NUMBER ? 1 : 0
    this.confirmDialog.open();
  }

  openDesignateNumberListPage(): void {
    router.pushUrl({
      url: 'pages/RecorderDesignateNumber',
      params: {
        title: $r('app.string.specified_number'),
        number: this.staticDataUse.numberUse
      }
    });
    ReportUtil.getInstance().reportClickSpecifyNumber();
  }

  onBackPress() {
    this.session.sendData({ 'action': 'pop', 'recordingState': this.staticDataUse.statusUse });
    return true;
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
    .borderRadius($r('sys.float.corner_radius_level8'))
    .constraintSize({ minHeight: $r('app.float.wh_value_48') })
    .opacity(1)
  }

  build() {
    Navigation() {
      GridRow({
        breakpoints: { value: ['320vp', '600vp', '840vp'], reference: BreakpointsReference.WindowSize },
        columns: { xs: 4, sm: 4, md: 8, lg: 12 },
        gutter: { x: 24 },
        direction: GridRowDirection.Row
      }) {
        GridCol({ span: { xs: 4, sm: 4, md: 6, lg: 8 }, offset: { md: 1, lg: 2 } }) {
          List() {
            ListItemGroup() {
              ListItem() {
                Flex({
                  direction: FlexDirection.Row,
                  justifyContent: FlexAlign.SpaceBetween,
                  alignItems: ItemAlign.Center
                }) {
                  Column() {
                    Text($r('app.string.automatic_recording_of_calls'))
                      .fontSize($r('sys.float.Subtitle_M'))
                      .fontColor($r('sys.color.ohos_id_color_text_primary'))
                      .fontFamily('HarmonyHeiTi')
                      .fontWeight(FontWeight.Medium)
                      .constraintSize({ minHeight: 22 })
                      .margin({ top: $r('sys.float.padding_level5'), bottom: 2 })
                    Text($r('app.string.automatically_record_call_viewed'))
                      .fontSize($r('sys.float.Subtitle_S'))
                      .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                      .constraintSize({ minHeight: 19 })
                      .margin({ bottom: $r('sys.float.padding_level5') })
                  }
                  .constraintSize({ minHeight: 64 })
                  .padding({
                    start: LengthMetrics.vp(8),
                    top: this.fontSizeScale > 1 ? this.fontSizeScaleMargin : 0,
                    end: LengthMetrics.vp(14),
                    bottom: this.fontSizeScale > 1 ? this.fontSizeScaleMargin : 0
                  })
                  .alignItems(HorizontalAlign.Start)
                  .flexShrink(1)

                  Column() {
                    Toggle({
                      type: ToggleType.Switch,
                      isOn: this.staticDataUse.statusUse
                    })
                      .size({ width: 36, height: 20 })
                      .selectedColor($r('sys.color.comp_background_emphasize'))
                      .switchPointColor($r('sys.color.comp_background_primary_contrary'))
                      .margin(0)
                      .hoverEffect(HoverEffect.None)
                      .accessibilityLevel('yes')
                      .onChange((isOn: boolean) => {
                        this.saveRecordingState(isOn);
                      })
                  }
                  .width(48)
                  .padding({ end: LengthMetrics.vp(8) })
                  .justifyContent(FlexAlign.Center)
                  .flexGrow(0)
                }
              }
              .margin({ top: $r('sys.float.padding_level2'),
                left: $r('sys.float.padding_level2'),
                right: $r('sys.float.padding_level2') })
              .accessibilityGroup(true)

              ListItem() {
                Flex({
                  direction: FlexDirection.Row,
                  justifyContent: FlexAlign.SpaceBetween,
                  alignItems: ItemAlign.Center
                }) {
                  Column() {
                    Text($r('app.string.auto_recording_object'))
                      .commonText(this.staticDataUse.statusUse)
                    if (this.fontSizeScale >= FontScale.FourthGear) {
                      this.AutoRecording()
                    }
                  }
                  .alignItems(HorizontalAlign.Start)
                  .padding({
                    top: this.fontSizeScaleMargin,
                    bottom: this.fontSizeScaleMargin,
                    start: LengthMetrics.vp(8)
                  })

                  if (this.fontSizeScale < FontScale.FourthGear) {
                    Column() {
                      this.AutoRecording()
                    }
                    .width('50%')
                  }
                }
                .stateStyles({
                  pressed: this.pressedStyles,
                  normal: {
                    .backgroundColor(Color.Transparent)
                  }
                })
                .enabled(this.staticDataUse.statusUse)
                .onClick(() => {
                  if (this.staticDataUse.statusUse) {
                    this.showAutoSelectObjectDialog();
                  }
                })
              }
              .margin({
                left: $r('sys.float.padding_level2'), right: $r('sys.float.padding_level2'),
                bottom: this.staticDataUse.objectUse === CallSettingConstant.RECORDING_WAY_DESIGNATE_NUMBER ? 0 :
                $r('sys.float.padding_level2')
              })
              .constraintSize({ minHeight: 48 })

              if (this.staticDataUse.objectUse === CallSettingConstant.RECORDING_WAY_DESIGNATE_NUMBER) {
                ListItem() {
                  Flex({
                    direction: FlexDirection.Row,
                    justifyContent: FlexAlign.SpaceBetween,
                    alignItems: ItemAlign.Center
                  }) {
                    Column() {
                      Text($r('app.string.specified_number'))
                        .commonText(this.staticDataUse.statusUse)
                      if (this.fontSizeScale >= FontScale.FourthGear) {
                        this.SpecifiedNumber()
                      }
                    }
                    .padding({
                      start: LengthMetrics.vp(8),
                      top: this.fontSizeScaleMargin,
                      bottom: this.fontSizeScaleMargin
                    })
                    .alignItems(HorizontalAlign.Start)
                    .align(Alignment.Center)

                    if (this.fontSizeScale < FontScale.FourthGear) {
                      Column() {
                        this.SpecifiedNumber()
                      }
                      .width('50%')
                    }
                  }
                  .stateStyles({
                    pressed: this.pressedStyles,
                    normal: {
                      .backgroundColor(Color.Transparent)
                    }
                  })
                }
                .constraintSize({ minHeight: 48 })
                .margin({ bottom: $r('sys.float.padding_level2'), left: $r('sys.float.padding_level2'),
                  right: $r('sys.float.padding_level2') })
                .enabled(this.staticDataUse.statusUse)
                .onClick(() => {
                  let staticDataUseTemp = this.staticDataUse;
                  if (staticDataUseTemp?.statusUse) {
                    this.openDesignateNumberListPage();
                  }
                })
              }
            }
            .borderRadius({
              topLeft: $r('sys.float.corner_radius_level10'),
              topRight: $r('sys.float.corner_radius_level10'),
              bottomLeft: $r('sys.float.corner_radius_level10'),
              bottomRight: $r('sys.float.corner_radius_level10')
            })
            .width('100%')
            .divider({
              strokeWidth: '1px',
              color: $r('sys.color.comp_divider'),
              startMargin: $r('sys.float.padding_level6'),
              endMargin: $r('sys.float.padding_level6')
            })
            .backgroundColor(this.isFromExternal ? $r('sys.color.comp_background_list_card') :
            $r('sys.color.ohos_id_color_list_card_bg'))
            .margin({ top: $r('sys.float.padding_level4'), bottom: $r('sys.float.padding_level4') })
          }
          .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
          .height('100%')
        }
      }
      .margin({
        left: this.curBp === 'sm' ? $r('sys.float.padding_level8') :
          this.curBp === 'md' ? $r('sys.float.padding_level12') : $r('sys.float.padding_level16'),
        right: this.curBp === 'sm' ? $r('sys.float.padding_level8') :
          this.curBp === 'md' ? $r('sys.float.padding_level12') : $r('sys.float.padding_level16')
      })
      .backgroundColor(this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
        $r('sys.color.ohos_id_color_sub_background'))
      .height('100%')
    }
    .title($r('app.string.automatic_recording_of_calls'), {
      paddingEnd: LengthMetrics.vp(58)
    })
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .expandSafeArea([SafeAreaType.KEYBOARD])
    .padding({ top: this.isFromExternal ? 8 : this.statusBarHeight })
    .backgroundColor(this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
      $r('sys.color.background_secondary'))
  }

  @Builder
  AutoRecording() {
    Row() {
      Text(commonData.recordingObjectChange[
      this.staticDataUse?.objectUse ?
        this.staticDataUse?.objectUse : CallSettingConstant.RECORDING_WAY_ALL_NUMBER
      ])
        .fontSize($r('sys.float.Subtitle_S'))
        .fontColor(this.staticDataUse.statusUse ? $r('sys.color.ohos_id_color_text_secondary') :
        $r('sys.color.ohos_id_color_text_tertiary'))
        .margin({ end: LengthMetrics.vp(4) })
        .constraintSize({ maxWidth: 'calc(100% - 24vp)' })
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize($r('app.float.wh_value_24'))
        .fontColor([$r('sys.color.icon_fourth')])
        .margin({ end: LengthMetrics.vp(8) })
    }
    .commonRow(this.fontSizeScale >= FontScale.FourthGear)
  }

  @Builder
  SpecifiedNumber() {
    Row() {
      Text(this.staticDataUse?.numberUse ?
      $r('app.plural.use_numbers', this.staticDataUse.numberUse, this.staticDataUse.numberUse) : $r('app.string.unset_recorder'))
        .fontSize($r('sys.float.Subtitle_S'))
        .fontColor(this.staticDataUse.statusUse ? $r('sys.color.ohos_id_color_text_secondary') :
        $r('sys.color.ohos_id_color_text_tertiary'))
        .margin({ end: LengthMetrics.vp(4) })
        .constraintSize({ maxWidth: 'calc(100% - 24vp)' })
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize($r('app.float.wh_value_24'))
        .fontColor([$r('sys.color.ohos_id_color_fourth')])
        .margin({ end: LengthMetrics.vp(8) })
    }
    .commonRow(this.fontSizeScale >= FontScale.FourthGear)
  }
}

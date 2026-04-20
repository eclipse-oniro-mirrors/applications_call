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
import LogUtils from '../common/utils/LogUtils';
import { ContactDataStruct, RecordConfigContactDataStruct } from '../common/struct/RecorderSettingStruct';
import commonController from '../common/control/CommonCtrol';
import RecorderDesignateNumberSource from '../common/model/RecorderDesignateNumberSource';
import { EditableTitleBar } from '@ohos.arkui.advanced.EditableTitleBar';
import { ReportUtil } from '../common/utils/ReportUtil';
import CallRecorderColumnUtils from '../common/utils/CallRecorderColumnUtils';
import display from '@ohos.display';
// import { PafEmptyPage } from '@hms-paf/ui-widget-emptypage';
import { StringUtil } from '../common/utils/StringUtil';
import i18n from '@ohos.i18n';
import call from '@ohos.telephony.call';
import { LengthMetrics } from '@kit.ArkUI';
import { AlertDialog } from '@ohos.arkui.advanced.Dialog';
import { ResourceUtil } from '../common/utils/ResourceUtil';
import { GlobalContextHelper } from '../common/utils/GlobalContextHelper';
import common from '@ohos.app.ability.common';
import { Constant } from '../common/constant/Constant';
/* instrument ignore file */

const TAG = 'RecordingSettingDesignateNumber';
const LIST_ITEM_COUNT_ONE_PAGE: number = 100;

@Entry
@Component
export default struct designateNumberListPage {
  private listDataSource: RecorderDesignateNumberSource = new RecorderDesignateNumberSource();
  @State commonController: commonController = commonController.getInstance();
  @State isEditStatusAll: boolean = false;
  @State staticNumberDataUseLength: number = 0;
  //checkboxStatus:Indicates whether all is selected.
  @State checkboxStatus: boolean = false;
  //staticNumberDataUseCheck:Check whether the selected data exists.
  @State staticNumberDataUseCheck: boolean = false;
  @State @Watch('getCheckDataStatusChange') checkedNumber: number = 0;
  @State isNeedInit: boolean = true;
  @State isDeleted: boolean = false;
  @State statusBarHeight: number = -1;
  @StorageProp('curBp') curBp: string = '';
  @State listPageHeight: number = -1;
  private isFromExternal: boolean = AppStorage.get<boolean>('isFromExternal') as boolean;

  aboutToAppear() {
    this.isNeedInit = true;
    this.getInitData();
    this.statusBarHeight = AppStorage.get<number>('statusBarHeight') as number;
    try {
      let displayHeight = display.getDefaultDisplaySync().height;
      this.listPageHeight = px2vp(displayHeight) - this.statusBarHeight - 56;
    } catch (error) {
      LogUtils.e(TAG, 'Error getting default display');
    }
  }

  aboutToDisappear() {
    LogUtils.i(TAG, 'aboutToDisappear');
    this.listDataSource.getAllData().forEach(i => {
        if (i.image && i.image !== $r('app.media.ic_user') && !i.isImageDefault) {
          LogUtils.i(TAG, 'image is release');
          (i.image as PixelMap).release();
        }
    })
    this.isNeedInit = false;
    try {
      let displayWidth = display.getDefaultDisplaySync().width;
      CallRecorderColumnUtils.getInstance().updateBreakpoint(displayWidth);
    } catch (error) {
      LogUtils.e(TAG, 'aboutToDisappear Error getting default display width');
    }
  }

  getCheckDataStatusChange() {
    LogUtils.i(TAG, 'getCheckDataStatusChange start');
    let staticNumberDataUse = this.listDataSource.getAllData();
    let staticNumberDataUseCheck = false;
    let checkboxLength = 0;
    for (let i = 0; i < staticNumberDataUse.length; i++) {
      if (staticNumberDataUse[i].isChecked) {
        staticNumberDataUseCheck = true;
        checkboxLength++;
      }
    }
    LogUtils.i(TAG, 'getCheckDataStatusChange staticNumberDataUseCheck' + staticNumberDataUseCheck +
      'checkboxStatus' + this.checkboxStatus);
    let currentStatus: boolean = checkboxLength === staticNumberDataUse.length;
    this.checkboxStatus = currentStatus;
    this.staticNumberDataUseCheck = staticNumberDataUseCheck;
  }

  getInitData() {
    LogUtils.i(TAG, 'getInitData start')
    if (!this.isNeedInit) {
      return;
    }
    this.commonController.queryForConfigContact(this.checkboxStatus,
      (phoneNumberList: RecordConfigContactDataStruct[]) => {
        LogUtils.i(TAG, 'numberList' + phoneNumberList.length + 'totalCount' + this.listDataSource.totalCount());
        this.listDataSource.concatData(phoneNumberList);
        this.staticNumberDataUseLength = this.listDataSource.totalCount();
        if (phoneNumberList.length === 0) {
          if (this.checkboxStatus) {
            this.listDataSource.updateDataCheckStatusAll(this.checkboxStatus);
          }
          return;
        }
        if (phoneNumberList.length >= LIST_ITEM_COUNT_ONE_PAGE) {
          this.getInitData();
        }
      }, LIST_ITEM_COUNT_ONE_PAGE, this.listDataSource.totalCount());
  }

  updateDeleteStatus() {
    this.staticNumberDataUseLength = this.listDataSource.totalCount();
    if (this.staticNumberDataUseLength <= 0) {
      this.checkboxStatus = false;
    }
  }

  deleteNumberUseMulti() {
    if (this.checkboxStatus) {
      this.commonController.deleteConfigContact([], () => {
        this.listDataSource.deleteDataAll();
        this.updateDeleteStatus();
      });
      return;
    }
    let staticNumberDataUseTemp: RecordConfigContactDataStruct[] = this.listDataSource.getAllData();
    let resultSend: string[] = [];
    for (let i = staticNumberDataUseTemp.length - 1; i >= 0; i--) {
      if (staticNumberDataUseTemp[i].isChecked) {
        resultSend.push(staticNumberDataUseTemp[i].phoneNumber);
        this.listDataSource.deleteDataByIndex(i);
      }
    }
    this.commonController.deleteConfigContact(resultSend, () => {
      this.updateDeleteStatus();
    });
  }

  dialogController: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: this.getDeleteDialogTitle(),
      primaryButton: {
        value: $r('app.string.cancel'),
        action: () => {
          LogUtils.i(TAG, 'Callback when the first button is clicked');
          ReportUtil.getInstance().reportDeleteSpecifyNumber(0);
        }
      },
      secondaryButton: {
        value: $r('app.string.delete'),
        fontColor: $r('sys.color.ohos_id_color_warning'),
        action: () => {
          this.deleteNumberUseMulti();
          this.isDeleted = true;
          this.staticNumberDataUseCheck = false;
          ReportUtil.getInstance().reportDeleteSpecifyNumber(1);
        }
      }
    }),
    autoCancel: false,
    alignment: DialogAlignment.Default
  })

  batchInsertConfigFilter(contactData: ContactDataStruct[]) {
    this.commonController.batchInsertConfigFilter(contactData, this.listDataSource.getAllData(), (temp) => {
      if (temp.length > 0) {
        this.commonController.batchInsertConfigContact(temp, (rowId) => {
          this.getInitData();
        });
        ReportUtil.getInstance().reportAddSpecifyNumberSuccessful();
      }
      this.listDataSource.updateDataCheckStatusAll(false);
    })
  }

  addContactData() {
    this.commonController.jumpToContactForResult((contactData) => {
      LogUtils.i(TAG, 'jumpToContactForResult' + contactData.length);
      this.isEditStatusAll = false;
      if (contactData && contactData.length > 0) {
        this.batchInsertConfigFilter(contactData);
      }
      this.listDataSource.updateDataCheckStatusAll(false);
    });
  }

  getDeleteDialogTitle(): Resource | string {
    let checkedPhoneCount: number = this.listDataSource.getAllData().filter(phoneNum => {
      return phoneNum.isChecked;
    }).length;
    LogUtils.i(TAG, 'checkedPhoneCount');
    if (checkedPhoneCount < 1 || checkedPhoneCount > this.listDataSource.totalCount()) {
      LogUtils.w(TAG, `getDeleteDialogTitle error`);
      return $r('app.string.emptyStr');
    }
    let deleteDialogTitle: Resource | string;
    if (checkedPhoneCount === 1) {
      deleteDialogTitle = $r('app.string.is_delete_number');
    } else if (checkedPhoneCount === this.listDataSource.totalCount()) {
      deleteDialogTitle = $r('app.string.is_delete_all_number');
    } else {
      try {
        deleteDialogTitle =
          getContext().resourceManager.getIntPluralStringValueSync($r('app.plural.is_delete_plural_number').id,
            checkedPhoneCount, checkedPhoneCount);
      } catch (err) {
        LogUtils.e(TAG, `getIntPluralStringValueSync error code: ${err?.code}, msg: ${err?.message}`);
        deleteDialogTitle = $r('app.plural.is_delete_plural_number', checkedPhoneCount, checkedPhoneCount);
      }
    }
    return deleteDialogTitle;
  }

  private getTitleBarMarginEnd() {
    return this.isFromExternal ? LengthMetrics.vp(48) : LengthMetrics.vp(0);
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
    .borderRadius(8)
    .opacity(1)
  }

  build() {
    NavDestination() {
      if (this.staticNumberDataUseLength > 0) {
        EditableTitleBar({
          title: $r('app.string.specified_number'),
          isSaveIconRequired: false,
          menuItems: [{
            value: $r('app.media.plus'),
            label: $r('app.string.add'),
            isEnabled: true,
            action: () => {
              this.addContactData();
              ReportUtil.getInstance().reportClickAddButton();
            }
          }]
        })
          .backgroundColor(this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
            $r('sys.color.background_secondary'))
          .margin({ end: this.getTitleBarMarginEnd() })
        Column() {
          GridRow({
            columns: {
              xs: 2,
              sm: 4,
              md: 8,
              lg: 12,
              xl: 12,
              xxl: 12
            },
          }) {
            GridCol({
              span: {
                xs: 2,
                sm: 4,
                md: 8,
                lg: 12,
                xl: 4,
                xxl: 4
              },
              offset: {
                xs: 1,
                sm: 1,
                md: 2,
                lg: 4,
                xl: 4,
                xxl: 4
              }
            }) {
              Column() {
                Column() {
                  List() {
                    LazyForEach(this.listDataSource, (item: RecordConfigContactDataStruct, index: number) => {
                      ListItem() {
                        Column() {
                          if (index !== 0 && this.staticNumberDataUseLength > 1) {
                            Column() {
                              Divider()
                                .color($r('sys.color.ohos_id_color_list_separator'))
                                .margin({ start: LengthMetrics.vp(56) })
                            }
                          }
                          ListItemContent({
                            item,
                            isEditStatusAll: $isEditStatusAll,
                            checkedNumber: $checkedNumber
                          })
                        }
                      }
                    }, (item: RecordConfigContactDataStruct) => JSON.stringify(item))
                  }
                  .scrollBar(this.isFromExternal ? BarState.Off : BarState.Auto)
                  .contentEndOffset(25)
                }
                .layoutWeight(1)

                Column() {
                  if (this.isEditStatusAll && this.staticNumberDataUseLength !== 0) {
                    Row() {
                      Column() {
                        Column() {
                          SymbolGlyph($r('sys.symbol.trash'))
                            .fontSize($r('app.float.wh_value_24'))
                            .fontColor([$r('sys.color.ohos_id_color_primary')])
                            .opacity(this.staticNumberDataUseCheck ? 1 : $r('sys.float.ohos_id_alpha_disabled'))
                        }

                        Text($r('app.string.delete'))
                          .fontSize($r('sys.float.ohos_id_text_size_caption'))
                          .opacity(this.staticNumberDataUseCheck ? 1 : $r('sys.float.ohos_id_alpha_disabled'))
                          .margin({
                            top: 3
                          })
                      }
                      .height(56)
                      .justifyContent(FlexAlign.Center)
                      .width(156)
                      .enabled(this.staticNumberDataUseCheck)
                      .onClick(() => {
                        if (!this.staticNumberDataUseCheck) {
                          return;
                        }
                        this.staticNumberDataUseLength = this.listDataSource.totalCount();
                        this.dialogController.open();
                      })

                      Column() {
                        Column() {
                          SymbolGlyph(this.checkboxStatus ?
                          $r('sys.symbol.checkmark_square_on_square_fill') :
                          $r('sys.symbol.checkmark_square_on_square'))
                            .fontSize($r('app.float.wh_value_24'))
                            .fontColor(this.checkboxStatus ? [$r('sys.color.ohos_id_color_activated')] :
                              [$r('sys.color.ohos_id_color_primary')])
                        }

                        Text(this.checkboxStatus && this.staticNumberDataUseCheck ?
                        $r('app.string.deselect_all') : $r('app.string.select_all'))
                          .fontColor(this.checkboxStatus && this.staticNumberDataUseCheck ?
                          $r('sys.color.ohos_id_color_text_primary_activated') :
                          $r('sys.color.ohos_id_color_text_primary'))
                          .fontSize($r('sys.float.ohos_id_text_size_caption'))
                          .margin({
                            top: 3
                          })
                      }.width(156)
                      .height(56)
                      .justifyContent(FlexAlign.Center)
                      .onClick(() => {
                        let status: boolean = this.checkboxStatus;
                        status = !status;
                        LogUtils.i(TAG, 'select_all' + status);
                        this.checkboxStatus = status;
                        this.staticNumberDataUseCheck = status;
                        this.listDataSource.updateDataCheckStatusAll(status);
                        ReportUtil.getInstance().reportSpecifyAllSelectAction(status ? 1 : 0);
                      })
                    }
                    .justifyContent(FlexAlign.Center)
                    .height(56)
                    .alignItems(VerticalAlign.Center)
                    .width('100%')
                  }
                }
                .width('100%')
                .margin({ bottom: this.curBp === 'sm' ? 28 : 16 })
              }
              .justifyContent(FlexAlign.SpaceBetween)
            }
          }
        }
        .layoutWeight(1)
        .margin({
          left: this.curBp === 'sm' ? $r('sys.float.padding_level8') :
            this.curBp === 'md' ? $r('sys.float.padding_level12') : $r('sys.float.padding_level16'),
          right: this.curBp === 'sm' ? $r('sys.float.padding_level8') :
            this.curBp === 'md' ? $r('sys.float.padding_level12') : $r('sys.float.padding_level16')
        })
      } else {
        Column() {
          EditableTitleBar({
            title: $r('app.string.specified_number'),
            isSaveIconRequired: false
          })
            .backgroundColor(this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
              $r('sys.color.background_secondary'))
            .margin({ end: this.getTitleBarMarginEnd() })
          Column() {
            Blank().height(1)
            Column() {
              Image($r('app.media.no_contact'))
                .width(100)
                .height(100)
              Text($r('app.string.no_number_specified'))
            }
            Button($r('app.string.add_specified_number'))
              .fontColor(Color.Blue)
              .width(300)
              .margin({
                bottom: "10%",
              })
              .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
              .onClick(() => {
                this.addContactData();
                ReportUtil.getInstance().reportClickBottomAddSpecifyNumBtn();
              })
          }
          .backgroundColor(this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
            $r('sys.color.background_secondary'))
          .justifyContent(FlexAlign.SpaceBetween)
          .layoutWeight(1)
          .padding({ bottom: this.isFromExternal ? 0 : 27 })
        }
      }
    }
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .padding({ top: this.isFromExternal ? 8 : this.statusBarHeight })
    .backgroundColor(this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
      $r('sys.color.background_secondary'))
  }
}

@Component
struct ListItemContent {
  @State showPhoneNumber: string = '';
  @State item: RecordConfigContactDataStruct = new RecordConfigContactDataStruct();
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('fontSizeScaleMargin') fontSizeScaleMargin: number = 0;
  @Link isEditStatusAll: boolean;
  @Link checkedNumber: number;
  commonController: commonController = commonController.getInstance();

  async phoneAddSpace(numberParam: string) {
    let phoneNumber = numberParam;
    phoneNumber = ListItemContent.clearPhoneNumberSymbols(phoneNumber);
    let countryId = 'CN';
    try {
      countryId = i18n.System.getSystemRegion();

      let options: call.NumberFormatOptions = {
        countryCode: countryId
      }
      let formatNumber: string = await call.formatPhoneNumber(phoneNumber, options);
      if (StringUtil.isEmpty(formatNumber)) {
        formatNumber = phoneNumber;
      }
      return formatNumber;
    } catch (error) {
      countryId = 'CN';
      LogUtils.e(TAG, 'get formatPhoneNumber error')
    }
    return ''
  }

  static clearPhoneNumberSymbols(phoneNumber: string): string {
    if (!phoneNumber || phoneNumber === '') {
      return '';
    }
    let commaIndex = phoneNumber.indexOf(',');
    let semicolonIndex = phoneNumber.indexOf(';');
    if (semicolonIndex >= 0 && commaIndex === -1) {
      phoneNumber = phoneNumber.substring(0, semicolonIndex);
    } else if (commaIndex >= 0 && semicolonIndex === -1) {
      phoneNumber = phoneNumber.substring(0, commaIndex);
    } else if (semicolonIndex >= 0 && commaIndex >= 0) {
      if (commaIndex > semicolonIndex) {
        phoneNumber = phoneNumber.substring(0, semicolonIndex);
      } else {
        phoneNumber = phoneNumber.substring(0, commaIndex);
      }
    }
    return phoneNumber;
  }

  aboutToAppear(): void {
    if (this.item.id && this.item.id > 0) {
      this.commonController.getPhoto(this.item.id).then((photo) => {
        if (photo) {
          LogUtils.i(TAG, 'update photo ' + this.item.id);
          this.item.image = photo;
          this.item.isImageDefault = false;
        }
      });
    }
  }

  @Styles
  pressedStylesList() {
    .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
    .borderRadius(14)
    .opacity(1)
  }

  build() {
    Flex({
      justifyContent: FlexAlign.SpaceBetween,
      alignItems: ItemAlign.Center
    }) {
      Column() {
        Row() {
          if (this.item.isImageDefault) {
            Image(this.item.image)
              .width(40)
              .height(40)
              .margin({
                end: LengthMetrics.vp(16)
              })
          } else {
            Image(this.item.image)
              .width(40)
              .height(40)
              .margin({
                end: LengthMetrics.vp(16)
              })
              .objectFit(ImageFit.Contain)
              .borderRadius(42)
              .draggable(false)
              .onError(() => {
                this.item.image = $r('app.media.ic_user');
              })
          }
          Column() {
            if (this.item.name === '') {
              Text(this.showPhoneNumber)
                .direction(Direction.Ltr)
                .fontSize($r('sys.float.ohos_id_text_size_sub_title2'))
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .onAppear(async () => {
                  this.showPhoneNumber = await this.phoneAddSpace(this.item.phoneNumber)
                })
            } else {
              Text(this.item.name)
                .maxLines(1)
                .fontSize($r('sys.float.ohos_id_text_size_sub_title2'))
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .fontWeight(FontWeight.Medium)
                .margin({
                  end: this.isEditStatusAll ? LengthMetrics.vp(90) : LengthMetrics.vp(60),
                  bottom: $r('sys.float.padding_level2')
                })
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(this.showPhoneNumber)
                .direction(Direction.Ltr)
                .fontSize($r('sys.float.ohos_id_text_size_sub_title3'))
                .fontColor($r('sys.color.font_secondary'))
                .onAppear(async () => {
                  this.showPhoneNumber = await this.phoneAddSpace(this.item.phoneNumber)
                })
                .accessibilityLevel(this.isEditStatusAll ? 'no' : 'yes')
            }
          } .width(this.isEditStatusAll ? 'calc(100% - 90vp)' : 'calc(100% - 60vp)')
          .alignItems(HorizontalAlign.Start)
        }
        .accessibilityGroup(true)
      }

      if (this.isEditStatusAll) {
        Checkbox({ name: this.item.phoneNumber + '', group: 'checkboxGroup' })
          .selectedColor($r('sys.color.ohos_id_color_activated'))
          .width(20)
          .height(20)
          .margin($r('sys.float.padding_level1'))
          .selectedColor($r('sys.color.ohos_id_color_activated'))
          .select(this.item.isChecked)
          .responseRegion({ width: 0, height: 0 })
      }
    }
    .constraintSize({ minHeight: 64 })
    .borderRadius(14)
    .gesture(
      LongPressGesture({ repeat: false })
        .onAction((event?: GestureEvent) => {
          // 首次长按时选中第一个选项, 后续不选中
          if (!this.isEditStatusAll) {
            this.isEditStatusAll = true;
            this.item.isChecked = true;
            this.checkedNumber ++;
          }
          ReportUtil.getInstance().reportLongPressSpecifyNumber();
        })
    )
    .constraintSize({ minHeight: $r('app.float.wh_value_48') })
    .stateStyles({
      pressed: this.pressedStylesList,
      normal: {
        .backgroundColor(Color.Transparent)
      }
    })
    .accessibilityGroup(true)
    .onClick(() => {
      if (!this.isEditStatusAll) {
        return;
      }
      this.item.isChecked = !this.item.isChecked;
      if (this.item.isChecked) {
        this.checkedNumber ++;
        ReportUtil.getInstance().reportSelectOrCancelSelectSpecifyNum(1);
      } else {
        this.checkedNumber --;
        ReportUtil.getInstance().reportSelectOrCancelSelectSpecifyNum(0);
      }
    })
    .accessibilityLevel('yes')
    .accessibilityChecked(this.isEditStatusAll ? this.item.isChecked : undefined)
    .accessibilityRole(this.isEditStatusAll ? AccessibilityRoleType.CHECKBOX : undefined)
    .accessibilityDescription(this.getAccessibleDescription())
  }

  getAccessibleDescription() {
    if (this.isEditStatusAll) {
      return '';
    }
    const context = GlobalContextHelper.getContext()
      .getValue<common.UIExtensionContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    return ResourceUtil.resourceToString($r('app.string.voice_long_press'), context);
  }
}

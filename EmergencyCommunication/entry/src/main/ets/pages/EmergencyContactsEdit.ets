/*
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

import titleForEmergency from '../components/TitleForEmergency';
import { CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import { EmergencyContactDialogDataStruct, ContactListStruct } from '../utils/ClassStruct';
import * as storageUtil from '../utils/DataStorageUtil';
import commonData from '../data/CommonData';
import EmergencyCallController from '../control/EmergencyCallControl';
import promptAction from '@ohos.promptAction';
import LogUtils from '../utils/HiLog';
import { BusinessError } from '@ohos.base';
import { getEmptyContactListData } from '../utils/InitDataUtil';
import CallColumnUtils from '../utils/CallColumnUtils';
import EmergencyContactsDataSource from '../data/EmergencyContactsDataSource';
import { ConfirmDialogContent } from '../components/ConfirmDialogContent';
import { EditableTitleBar, LengthMetrics } from '@kit.ArkUI';
import { DataStorageUtil } from '../utils/DataStorageUtil';
import { Utils } from '../utils/Utils';
import { ReportUtil } from '../utils/ReportUtil';
import { ContactsService } from '../service/ContactsService';
import { sim } from '@kit.TelephonyKit';
import { photoFirstNameDeal } from '../utils/ContactNameUtil';
//import { HdsNavDestination, HdsNavDestinationAttribute, HdsNavigationTitleBarOptions } from '@kit.UIDesignKit';
import { TitleBarLayout, TitleParams } from '../base/view/TitleParams';
import { TITLE_BAR_HEIGHT_MINI } from '../base/constant/HdsNavigationConstant';

const TAG = 'emergencyContactsEdit';
const SHOW_EDIT_TOAST_TIMEOUT = 2000;

@Builder
export function sateEmergencyContactsEdit(): void {
  EmergencyContactsEdit()
}

@Component
export default struct EmergencyContactsEdit {
  private storage = LocalStorage.getShared();
  @Consume('pathInfos') pathInfos: NavPathStack;
  @State mEmergencyCallController: EmergencyCallController = EmergencyCallController.getInstance();
  @State emergencyContacts: ContactListStruct[] = [];
  @State emergencyContactsDataSource: EmergencyContactsDataSource = new EmergencyContactsDataSource();
  @State listItemExchange: boolean = false;
  @State dragStartIndex: number = commonData.int.INVALID;
  @State dropInsertIndex: number = commonData.int.INVALID;
  @StorageProp('simOperatorNameSecond') simOperatorNameSecondStr: string = '';
  @StorageProp('simOperatorNameFirst') simOperatorNameFirstStr: string = '';
  @StorageProp('curBp') curBp: string = '';
  @StorageProp('ratio') ratio: number = 0;
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('topAndBottomMarginOnScale') topAndBottomMarginOnScale: string = '';
  @StorageProp('statusBarHeight') statusBarHeight: number = 38;

  private mCallColumnUtils: CallColumnUtils = CallColumnUtils.getInstance();
  @State curDragItemIndex: number = -1;
  @State translateY: number = 0;
  @State emergencyContactsEditTitle: string =
    EmergencyCallController.getInstance().formatResourceToString($r('app.string.editEmergencyContact'));
  @State dialogData: EmergencyContactDialogDataStruct = {
    title: $r('app.string.emptyStr'),
    contentText: $r('app.string.emptyStr'),
    isWaring: false,
    confirmText: $r('app.string.emptyStr'),
    confirm: () => {
    }
  }
  @LocalStorageProp('extensionFlag') extensionFlag: boolean = true;
  isRunningOfOnAddContactButtonClick = false;

  aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear');
    // UE report entry emergency_contact page
    ReportUtil.getInstance().reportEntryEmergencyContact();
    this.getEmergencyContactList();
    EmergencyCallController.getInstance().getSimOperatorNames(false);
  }

  showToast(message: Resource) {
    try {
      promptAction.showToast({
        message: message,
        duration: SHOW_EDIT_TOAST_TIMEOUT
      });
    } catch (error) {
      LogUtils.e(TAG, `showToast args error code is ${error?.code}, message is ${error?.message}`);
    }
  }

  @Styles
  emergencyInfoGroup() {
    .padding($r('sys.float.padding_level2'))
    .borderRadius($r('sys.float.corner_radius_level10'))
    .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
  }

  @Styles
  normalStyles() {
    .backgroundColor(Color.Transparent)
  }

  @Builder
  confirmContent() {
    ConfirmDialogContent({ contentText: this.dialogData.contentText });
  }

  confirmDialog: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: this.dialogData.title,
      contentBuilder: () => {
        this.confirmContent();
      },
      buttons: [
        {
          value: $r('app.string.CANCEL'),
          action: () => {
            this.confirmDialog.close();
          }
        },
        {
          value: this.dialogData.confirmText,
          action: () => {
            this.dialogData.confirm();
            this.confirmDialog.close();
          },
          role: this.dialogData.isWaring ? ButtonRole.ERROR : ButtonRole.NORMAL
        }
      ]
    }),
    autoCancel: false,
    //showInSubWindow: true
    showInSubWindow: false
  });

  showConfirmDialog(title: Resource,
    contentText: Resource, isWaring: boolean, confirmText: Resource, contactData: ContactListStruct) {
    this.dialogData.contentText = contentText;
    this.dialogData.title = title;
    this.dialogData.isWaring = isWaring;
    this.dialogData.confirmText = confirmText;
    this.dialogData.confirm = () => {
      let slotId = commonData.int.SIM_SLOT_ID_SECOND;
      if (this.simOperatorNameFirstStr.length > 0) {
        slotId = commonData.int.SIM_SLOT_ID_FIRST;
      }
      if (!this.simOperatorNameFirstStr && !this.simOperatorNameSecondStr) {
        slotId = commonData.int.SIM_SLOT_ID_EMPTY
      }
      this.mEmergencyCallController.sendMessage(slotId, contactData.value,
        $r('app.string.sendMsg'))
    }
    // UE report add emergencyContact success
    ReportUtil.getInstance().reportAddEmergencyContactSuccess();
    this.confirmDialog.open();
  }

  backItemClick() {
    LogUtils.i(TAG, 'backItemClick');
  }

  getEmergencyContactList() {
    LogUtils.i(TAG, 'getEmergencyContactList');
    DataStorageUtil.getInstance().getEmergencyContacts((data) => {
      this.emergencyContactsDataSource.refresh(data, true);
    })
  };

  async destinationPageShow() {
    LogUtils.i(TAG, 'destinationPageShow');
    if (this.isRunningOfOnAddContactButtonClick) {
      LogUtils.i(TAG, 'isRunningOfOnAddContactButtonClick, return');
      return
    }
    const contacts = await ContactsService.getInstance().syncAndGetEmergencyContactsFromDatabase(getContext());
    this.emergencyContacts = contacts;
    this.emergencyContactsDataSource.refresh(contacts, true);
  };

  onAddContactButtonClick = () => {
    // UE report click add_emergency_contact
    ReportUtil.getInstance().reportClickAddEmergencyContact();
    this.mEmergencyCallController.selectInContactsPicker((contactData) => {
      if (!contactData) {
        this.isRunningOfOnAddContactButtonClick = false;
        return;
      }
      let hasSame = false;
      for (let i = 0; i < this.emergencyContactsDataSource.getEmergencyContacts().length; i++) {
        const emergencyContact = this.emergencyContactsDataSource.getEmergencyContacts()[i];
        if (contactData.nameRawContactId === emergencyContact.nameRawContactId &&
          contactData.telephone === emergencyContact.value) {
          hasSame = true;
          break;
        }
      }
      if (hasSame) {
        this.showToast($r('app.string.already_in_contacts', contactData.contactName));
        this.isRunningOfOnAddContactButtonClick = false;
      } else {
        const data: ContactListStruct = {
          value: contactData.telephone,
          label: contactData.contactName || $r('app.string.emptyStr'),
          id: new Date().getTime().toString(),
          nameRawContactId: contactData.nameRawContactId,
          type: commonData.int.COMMON_CONTACT_TYPE
        }
        const tempList: ContactListStruct[] = this.emergencyContactsDataSource.getEmergencyContacts();
        tempList.push(data);
        DataStorageUtil.getInstance().updateEmergencyContacts(tempList, (result: boolean) => {
          if (result) {
            this.emergencyContactsDataSource.refresh(tempList);
            if (sim.getMaxSimCount() && sim.getMaxSimCount() > 0) {
              this.showConfirmDialog($r('app.string.notifyContact'),
                $r('app.string.sendMsgNotice'), false, $r('app.string.sendNow'), data);
            }
          }
          this.isRunningOfOnAddContactButtonClick = false;
        });
      }
    });
  }


  build() {
   /* HdsNavDestination() {
      GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: 24 }) {
        GridCol({ span: { xs: 2, sm: 4, md: this.extensionFlag ? 8 : 6, lg: this.extensionFlag ? 12 : 8 },
          offset: { md: this.extensionFlag ? 0 : 1, lg: this.extensionFlag ? 0 : 2 } }) {
          List() {
            if (this.emergencyContactsDataSource.getEmergencyContacts().length > 0) {
              ListItemGroup() {
                LazyForEach(this.emergencyContactsDataSource, (item: ContactListStruct, index: number) => {
                  ListItem() {
                    ContactEditItem({
                      index: index,
                      listItem: item,
                      curDragItemIndex: $curDragItemIndex,
                      translateY: $translateY,
                      emergencyContactDataSource: $emergencyContactsDataSource,
                      listItemExchange: $listItemExchange
                    })
                      .padding({
                        left: $r('sys.float.padding_level4'),
                        right: $r('sys.float.padding_level4')
                      })
                  }
                  .borderRadius($r('sys.float.corner_radius_level8'))
                  .stateStyles({
                    pressed: this.pressedStyles,
                    normal: this.normalStyles
                  })
                  .width('100%')
                  .constraintSize({ minHeight: $r('app.float.emc_wh_level64') })
                  .translate({ y: index === this.curDragItemIndex ? this.translateY : 0 })
                }, (item: ContactListStruct) => JSON.stringify(item))
              }
              // hds内容区避让标题+状态栏, 首个卡片距离标题16vp
              .margin({ top: TITLE_BAR_HEIGHT_MINI + this.statusBarHeight + 16, bottom: $r('sys.float.padding_level6') })
              .emergencyInfoGroup()
            }

            if (this.emergencyContactsDataSource.getEmergencyContacts().length < commonData.int.CONTACT_UPPER_LIMIT) {
              ListItemGroup() {
                ListItem() {
                  Flex({ alignItems: ItemAlign.Center }) {
                    Column() {
                      SymbolGlyph($r('sys.symbol.plus_circle'))
                        .fontSize($r('app.float.emc_margin_level12'))
                        .fontColor([$r('sys.color.icon_emphasize')])
                        .draggable(false)
                    }
                    .width(24)
                    .margin({ end: LengthMetrics.resource($r('sys.float.padding_level8')) })
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)

                    Column() {
                      Text($r('app.string.addEmergencyContact'))
                        .width('100%')
                        .fontSize($r('sys.float.Subtitle_M'))
                        .fontColor($r('sys.color.font_emphasize'))
                        .fontWeight(FontWeight.Medium)
                        .constraintSize({ minHeight: $r('app.float.emc_height_level11') })
                    }
                    .margin({
                      top: this.fontSizeScale < 1.75 ? $r('app.float.emc_margin_level17') :
                      this.topAndBottomMarginOnScale,
                      bottom: this.fontSizeScale < 1.75 ? $r('app.float.emc_margin_level17') :
                      this.topAndBottomMarginOnScale
                    })
                    .layoutWeight(1)
                  }
                  .padding({
                    left: $r('sys.float.padding_level4'),
                    right: $r('sys.float.padding_level4'),
                  })
                }
                .borderRadius($r('sys.float.corner_radius_level8'))
                .stateStyles({
                  pressed: this.pressedStyles,
                  normal: this.normalStyles
                })
              }
              .margin({
                top: this.emergencyContactsDataSource.getEmergencyContacts().length > 0 ? 0 :
                  TITLE_BAR_HEIGHT_MINI + this.statusBarHeight + 16
              })
              .emergencyInfoGroup()
              .onClick(() => {
                this.isRunningOfOnAddContactButtonClick = true;
                try {
                  this.onAddContactButtonClick();
                } catch (e) {
                  LogUtils.e(TAG, `onAddContactButtonClick error: ${JSON.stringify(e)}`);
                  this.isRunningOfOnAddContactButtonClick = false;
                }
              })
            }
          }
          .scrollBar(BarState.Off)
          .layoutWeight(1)
          .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
        }
      }
      .margin({
        left: CallColumnUtils.getInstance().getPaddingSpace(this.curBp, this.extensionFlag),
        right: CallColumnUtils.getInstance().getPaddingSpace(this.curBp, this.extensionFlag)
      })
    }*/
    NavDestination() {
      EditableTitleBar({
        title:this.emergencyContactsEditTitle,
        isSaveIconRequired:false,
        onCancel:()=>{
          this.pathInfos.pop()
        },
      })
        .margin({top:LengthMetrics.px(100)})
      GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: 24 }) {
        GridCol({ span: { xs: 2, sm: 4, md: this.extensionFlag ? 8 : 6, lg: this.extensionFlag ? 12 : 8 },
          offset: { md: this.extensionFlag ? 0 : 1, lg: this.extensionFlag ? 0 : 2 } }) {
          List() {
            if (this.emergencyContactsDataSource.getEmergencyContacts().length > 0) {
              ListItemGroup() {
                LazyForEach(this.emergencyContactsDataSource, (item: ContactListStruct, index: number) => {
                  ListItem() {
                    ContactEditItem({
                      index: index,
                      listItem: item,
                      curDragItemIndex: $curDragItemIndex,
                      translateY: $translateY,
                      emergencyContactDataSource: $emergencyContactsDataSource,
                      listItemExchange: $listItemExchange
                    })
                      .padding({
                        left: $r('sys.float.padding_level4'),
                        right: $r('sys.float.padding_level4')
                      })
                  }
                  .borderRadius($r('sys.float.corner_radius_level8'))
                  .stateStyles({
                    pressed: this.pressedStyles,
                    normal: this.normalStyles
                  })
                  .width('100%')
                  .constraintSize({ minHeight: $r('app.float.emc_wh_level64') })
                  .translate({ y: index === this.curDragItemIndex ? this.translateY : 0 })
                }, (item: ContactListStruct) => JSON.stringify(item))
              }
              // hds内容区避让标题+状态栏, 首个卡片距离标题16vp
              .margin({ top: TITLE_BAR_HEIGHT_MINI + this.statusBarHeight + 16, bottom: $r('sys.float.padding_level6') })
              .emergencyInfoGroup()
            }

            if (this.emergencyContactsDataSource.getEmergencyContacts().length < commonData.int.CONTACT_UPPER_LIMIT) {
              ListItemGroup() {
                ListItem() {
                  Flex({ alignItems: ItemAlign.Center }) {
                    Column() {
                      SymbolGlyph($r('sys.symbol.plus_circle'))
                        .fontSize($r('app.float.emc_margin_level12'))
                        .fontColor([$r('sys.color.icon_emphasize')])
                        .draggable(false)
                    }
                    .width(24)
                    .margin({ end: LengthMetrics.resource($r('sys.float.padding_level8')) })
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)

                    Column() {
                      Text($r('app.string.addEmergencyContact'))
                        .width('100%')
                        .fontSize($r('sys.float.Subtitle_M'))
                        .fontColor($r('sys.color.font_emphasize'))
                        .fontWeight(FontWeight.Medium)
                        .constraintSize({ minHeight: $r('app.float.emc_height_level11') })
                    }
                    .margin({
                      top: this.fontSizeScale < 1.75 ? $r('app.float.emc_margin_level17') :
                        this.topAndBottomMarginOnScale,
                      bottom: this.fontSizeScale < 1.75 ? $r('app.float.emc_margin_level17') :
                        this.topAndBottomMarginOnScale
                    })
                    .layoutWeight(1)
                  }
                  .padding({
                    left: $r('sys.float.padding_level4'),
                    right: $r('sys.float.padding_level4'),
                  })
                }
                .borderRadius($r('sys.float.corner_radius_level8'))
                .stateStyles({
                  pressed: this.pressedStyles,
                  normal: this.normalStyles
                })
              }
              .margin({
                top: this.emergencyContactsDataSource.getEmergencyContacts().length > 0 ? 0 :
                  TITLE_BAR_HEIGHT_MINI + this.statusBarHeight + 16
              })
              .emergencyInfoGroup()
              .onClick(() => {
                this.isRunningOfOnAddContactButtonClick = true;
                try {
                  this.onAddContactButtonClick();
                } catch (e) {
                  LogUtils.e(TAG, `onAddContactButtonClick error: ${JSON.stringify(e)}`);
                  this.isRunningOfOnAddContactButtonClick = false;
                }
              })
            }
          }
          .scrollBar(BarState.Off)
          .layoutWeight(1)
          .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
        }
      }
      .margin({
        left: CallColumnUtils.getInstance().getPaddingSpace(this.curBp, this.extensionFlag),
        right: CallColumnUtils.getInstance().getPaddingSpace(this.curBp, this.extensionFlag)
      })
    }
    .onShown(() => {
      this.destinationPageShow();
    })
    /*.titleBar(TitleParams.MiniTitleParams(this.emergencyContactsEditTitle, $r('sys.color.background_secondary')))*/
    .hideTitleBar(true)
    .backgroundColor($r('sys.color.background_secondary'))
  }
}

@Component
export struct ContactEditItem {
  @Consume('pathInfos') pathInfos: NavPathStack
  @State preTranslateY: number = 0;
  @State isDragging: boolean = false;
  @State dragItemHeight: number = 64;
  @State dragItemHeightLimit: number = 42;
  @Link curDragItemIndex: number;
  @Link translateY: number;
  @Link emergencyContactDataSource: EmergencyContactsDataSource;
  @State index: number = -1;
  @Link @Watch('updateListItemShow') listItemExchange: boolean;
  @State listItem: ContactListStruct = getEmptyContactListData();
  @StorageProp('curBp') curBp: string = '';
  @StorageProp('ratio') ratio: number = 0;
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('topAndBottomMarginOnScale') topAndBottomMarginOnScale: string = '';
  private mCallColumnUtils: CallColumnUtils = CallColumnUtils.getInstance();
  @State dialogData: EmergencyContactDialogDataStruct = {
    title: $r('app.string.emptyStr'),
    contentText: $r('app.string.emptyStr'),
    isWaring: false,
    confirmText: $r('app.string.emptyStr'),
    confirm: () => {
    }
  }
  @State autoSendSOSMessageSwitchState: boolean = Utils.isAutoSendSosSmsSwitchOn();
  @State autoAutoDialSOSNumberSwitchState: boolean = Utils.isAutoDialSosNumberSwitchOn();
  // 如果联系人没有头像，那么就显示昵称的最后一个文字或者大小英文字母，如果为其他昵称中没有中英文那么就显示默认头像
  private photoFirstName: string = '';

  updateListItemShow() {
    this.listItem = this.emergencyContactDataSource.getData(this.index) as ContactListStruct;
  }

  @Builder
  confirmContent() {
    ConfirmDialogContent({ contentText: this.dialogData.contentText });
  }

  confirmDialog: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: this.dialogData.title,
      contentBuilder: () => {
        this.confirmContent();
      },
      buttons: [
        {
          value: $r('app.string.CANCEL'),
          action: () => {
            this.confirmDialog.close();
          }
        },
        {
          value: this.dialogData.confirmText,
          action: () => {
            this.dialogData.confirm();
            this.confirmDialog.close();
          },
          role: this.dialogData.isWaring ? ButtonRole.ERROR : ButtonRole.NORMAL
        }
      ]
    }),
    autoCancel: false,
    //showInSubWindow: true
    showInSubWindow: false
  });

  showConfirmDialog(title: Resource, contentText: Resource, isWaring: boolean, confirmText: Resource) {
    this.dialogData.contentText = contentText;
    this.dialogData.title = title;
    this.dialogData.isWaring = isWaring;
    this.dialogData.confirmText = confirmText;
    this.dialogData.confirm = () => {
      let tempList = this.emergencyContactDataSource.getEmergencyContacts();
      tempList.splice(this.index, 1);
      this.emergencyContactDataSource.refresh(tempList);
      DataStorageUtil.getInstance().updateEmergencyContacts(tempList, () => {
        if (tempList.length === 0) {
          this.pathInfos.pop();
        }
      });
    }
    this.confirmDialog.open();
  }

  aboutToAppear() {
    LogUtils.e(TAG, 'DefaultListItem aboutToAppear');
  }

  dragFinish(value: ContactListStruct[]) {
    this.isDragging = false;
    this.curDragItemIndex = -1;
    this.emergencyContactDataSource.refresh(value);
    DataStorageUtil.getInstance().updateEmergencyContacts(value);
  }

  getPhotoNameDeal(contactsName: ResourceStr) {
    this.photoFirstName = photoFirstNameDeal(contactsName);
    return this.photoFirstName;
  }

  build() {
    Row() {
      SymbolGlyph($r('sys.symbol.line_2_horizontal'))
        .fontSize($r('app.float.emc_margin_level12'))
        .fontColor([$r('sys.color.icon_primary')])
        .draggable(false)
        .gesture(
          PanGesture({ direction: PanDirection.Vertical })
            .onActionStart((event: GestureEvent) => {
              let fingerData = event.fingerList[0];
              if (!fingerData) {
                return;
              }
              this.isDragging = true;
              this.curDragItemIndex = this.index;
              this.translateY = 0;
              this.preTranslateY = 0;
            })
            .onActionUpdate((event: GestureEvent) => {
              if (this.isDragging) {
                let offsetY = event.offsetY - this.preTranslateY;
                this.preTranslateY = event.offsetY;
                let tempY = this.translateY + offsetY;
                if (Math.abs(tempY) > this.dragItemHeightLimit) {
                  const tempList = this.emergencyContactDataSource.getEmergencyContacts();
                  if (tempY > 0) {
                    if (this.curDragItemIndex < tempList.length - 1) {
                      let tempItem = this.emergencyContactDataSource.
                        getEmergencyContacts().splice(this.curDragItemIndex, 1)[0];
                      this.emergencyContactDataSource.getEmergencyContacts().
                        splice(this.curDragItemIndex + 1, 0, tempItem);
                      this.translateY = (tempY - this.dragItemHeight) % this.dragItemHeight;
                      this.curDragItemIndex = this.curDragItemIndex + 1;
                      this.listItemExchange = !this.listItemExchange;
                    }
                  } else {
                    if (this.curDragItemIndex > 0) {
                      let tempItem = this.emergencyContactDataSource.
                        getEmergencyContacts().splice(this.curDragItemIndex, 1)[0];
                      this.emergencyContactDataSource.getEmergencyContacts().
                        splice(this.curDragItemIndex - 1, 0, tempItem);
                      this.translateY = (this.dragItemHeight + tempY) % this.dragItemHeight;
                      this.curDragItemIndex = this.curDragItemIndex - 1;
                      this.listItemExchange = !this.listItemExchange;
                    }
                  }
                } else {
                  this.translateY += offsetY;
                }
              }
            })
            .onActionEnd(() => {
              this.dragFinish(this.emergencyContactDataSource.getEmergencyContacts());
            })
            .onActionCancel(() => {
              this.dragFinish(this.emergencyContactDataSource.getEmergencyContacts());
            })
        )

      Row() {
        if (this.listItem.photo) {
          Image(this.listItem.photo)
            .width(40)
            .height(40)
            .foregroundColor($r('sys.color.icon_secondary'))
        } else if (this.getPhotoNameDeal(this.listItem.label).length > 0) {
          Text(this.photoFirstName)
            .fontSize('16vp')
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .backgroundColor($r('sys.color.ohos_fa_icon_fourth'))
            .height($r('app.float.emc_wh_level40'))
            .width($r('app.float.emc_wh_level40'))
            .textAlign(TextAlign.Center)
            .borderRadius($r('sys.float.corner_radius_level10'))
        } else {
          Image($r('app.media.ic_user'))
            .width(40)
            .height(40)
            .foregroundColor($r('sys.color.icon_secondary'))
        }
      }
      .width(40)
      .constraintSize({ minHeight: 40 })
      .margin({ left: $r('sys.float.padding_level8'), right: $r('sys.float.padding_level8') })

      Column() {
        Row() {
          Column() {
            Row() {
              Text(this.listItem.label)
                .fontSize($r('sys.float.Subtitle_L'))
                .fontColor($r('sys.color.font_primary'))
                .constraintSize({ minHeight: $r('app.float.emc_height_level11') })
                .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .margin({ top: this.topAndBottomMarginOnScale })
            Row() {
              Text(this.listItem.value)
                .fontSize($r('sys.float.Subtitle_M'))
                .fontColor($r('sys.color.font_secondary'))
                .constraintSize({ minHeight: $r('app.float.emc_height_level19') })
                .fontWeight(FontWeight.Regular)
                .direction(Direction.Ltr)
            }
            .width('100%')
            .margin({ top: $r('sys.float.padding_level1') })
          }
          .layoutWeight(1)
          .accessibilityGroup(true)

          Column() {
            SymbolGlyph($r('sys.symbol.xmark_circle_fill'))
              .fontSize($r('app.float.emc_margin_level12'))
              .opacity(0.4)
              .fontColor([$r('sys.color.icon_primary')])
              .margin({
                top: $r('sys.float.padding_level6'),
                start: LengthMetrics.resource($r('sys.float.padding_level8')),
                end: LengthMetrics.resource($r('sys.float.padding_level0'))
              })
          }
          .padding(15) // 增加 10vp 的点击范围
          .accessibilityText(EmergencyCallController.getInstance().formatResourceToString(
            $r('app.string.ContactsEdit_close')))
          .onClick(() => {
            if (this.emergencyContactDataSource.emergencyContacts.length === 1 &&
              (this.autoSendSOSMessageSwitchState || this.autoAutoDialSOSNumberSwitchState)) {
              this.showConfirmDialog($r('app.string.remove_emergency_contact_text'),
                $r('app.string.remove_last_emergency_contact_prompt_content',
                  this.listItem.label), true, $r('app.string.remove'));
            } else {
              this.showConfirmDialog($r('app.string.remove_emergency_contact_text'),
                $r('app.string.removeContact',
                  this.listItem.label), true, $r('app.string.remove'));
            }
          })
        }.alignItems(VerticalAlign.Center)

        Row() {
          if (this.index !== this.emergencyContactDataSource.totalCount() - 1) {
            Divider()
              .color($r('sys.color.comp_divider'))
          }
        }
        .width('100%')
        .margin({
          top: this.topAndBottomMarginOnScale,
          right: $r('sys.float.padding_level0')
        })
      }
      .layoutWeight(1)
    }
  }
}

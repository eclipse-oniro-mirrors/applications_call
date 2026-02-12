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

import { EmergencyContactDialogDataStruct, ContactListStruct } from '../utils/ClassStruct';
import EmergencyCallController from '../control/EmergencyCallControl';
import commonData from '../data/CommonData';
import LogUtils from '../utils/HiLog';
import { getEmptyContactListData } from '../utils/InitDataUtil';
import CallColumnUtils from '../utils/CallColumnUtils';
import { ConfirmDialogContent } from '../components/ConfirmDialogContent';
import { ReportUtil } from '../utils/ReportUtil';
import { CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import { call } from '@kit.TelephonyKit';
import { Configuration, EditableTitleBar, LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI';
import { ContactsService } from '../service/ContactsService';
import { SosSettingsController } from '../control/SosSettingsController';
import { isTablet } from '../utils/DeviceTypeUtils';
import {
  EDIT_LOCAL_ICON,
  EDIT_SYMBOL_ICON,
  EmergencyContactsInfoController } from '../control/EmergencyContactsInfoController';
import { photoFirstNameDeal } from '../utils/ContactNameUtil';
import { EditMenu } from '../components/EditMenu';
//import { HdsNavDestination, HdsNavDestinationAttribute, HdsNavigationMenuContentOptions } from '@kit.UIDesignKit';
import { NavigationMenuContentOptions, TitleBarLayout, TitleParams } from '../base/view/TitleParams';
import { TITLE_BAR_HEIGHT_MINI } from '../base/constant/HdsNavigationConstant';

const TAG = 'emergencyContactsInfo';

@Builder
export function EmergencyContactsInfoBuilder(previousPage: string): void {
  EmergencyContactsInfo({ previousPage: previousPage })
}

@Component
export default struct EmergencyContactsInfo {
  public previousPage: string = '';
  @Consume('pathInfos') pathInfos: NavPathStack;
  @State emergencyContacts: ContactListStruct[] = [];
  @State showEmergencyContacts: boolean = false;
  @StorageProp('simOperatorNameSecond') simOperatorNameSecondStr: string = '';
  @StorageProp('simOperatorNameFirst') simOperatorNameFirstStr: string = '';
  @State mEmergencyCallController: EmergencyCallController = EmergencyCallController.getInstance();
  @State isContactsShow: boolean = false;
  @State dialogData: EmergencyContactDialogDataStruct = {
    title: $r('app.string.emptyStr'),
    contentText: $r('app.string.emptyStr'),
    isWaring: false,
    confirmText: $r('app.string.emptyStr'),
    confirm: () => {
    }
  }
  pathStack: NavPathStack = new NavPathStack();
/*  private navigationMenuItemArray: HdsNavigationMenuContentOptions = {
    value: [
      {
        content: {
          label: $r('app.string.InfoEdit_edits_info'),
          icon: $r(EDIT_SYMBOL_ICON),
          isEnabled: true,
          action: () => {
            EmergencyContactsInfoController.onSquareAndPencilClick(this.pathInfos);
          }
        }
      }
    ]
  };*/
  private navigationMenuItemArray: NavigationMenuContentOptions = {
    value: [
      {
        value:$r('app.string.InfoEdit_edits_info'),
        icon:$r(EDIT_SYMBOL_ICON),
        isEnabled:true,
        action:()=>{
          EmergencyContactsInfoController.onSquareAndPencilClick(this.pathInfos);
        }
      }
    ]
  };

  @State emergencyInfoTitle: string =
    EmergencyCallController.getInstance().formatResourceToString($r('app.string.emergencyContact'));
  isRunningOfOnAddContactButtonClick = false;

  aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear');
    EmergencyCallController.getInstance().getSimOperatorNames(false);
  }

  backItemClick() {
    LogUtils.i(TAG, 'backItemClick');
  }

  @Builder
  NavMenu() {
    Column() {
      EditMenu({
        onClickCallBack: () => {
          EmergencyContactsInfoController.onSquareAndPencilClick(this.pathInfos);
        }
      })
    }
    .padding({
      right: 16,
      top: 8,
      left: Configuration.getLocale().dir === 'rtl' ? $r('sys.float.padding_level8') : 8
    })
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
    showInSubWindow: true
  });
  showConfirmDialog = (title: Resource, contentText: Resource, isWaring: boolean,
    confirmText: Resource, contactData: ContactListStruct) => {
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
    this.confirmDialog.open()
  }

  checkContactsIsShow = () => {
    if (this.emergencyContacts.length > 0) {
      this.showEmergencyContacts = true;
    } else {
      this.showEmergencyContacts = false;
    }
    this.isContactsShow = true;
  }

  async destinationPageShow() {
    LogUtils.i(TAG, 'destinationPageShow');
    if (this.isRunningOfOnAddContactButtonClick) {
      LogUtils.i(TAG, 'isRunningOfOnAddContactButtonClick, return');
      return;
    }
    this.isContactsShow = false;
    const contacts = await ContactsService.getInstance().syncAndGetEmergencyContactsFromDatabase(getContext());
    this.emergencyContacts = contacts;
    this.checkContactsIsShow();
  };

  setIsRunningOfOnAddContactButtonClick = (value: boolean) => {
    this.isRunningOfOnAddContactButtonClick = value;
  }
  setEmergencyContacts = (emergencyContacts: ContactListStruct[]) => {
    this.emergencyContacts = emergencyContacts;
  }
  @Builder
  MyCustomTitle() {
    if(this.showEmergencyContacts || this.emergencyContacts.length > 0){
      TitleBarLayout(this.emergencyInfoTitle,$r('sys.color.background_secondary'),this.navigationMenuItemArray)
    }else {
      TitleBarLayout(this.emergencyInfoTitle,$r('sys.color.background_secondary'),{value: []});
    }

  }

  build() {
    NavDestination() {
      if(this.showEmergencyContacts || this.emergencyContacts.length > 0 ){
        EditableTitleBar({
          title:this.emergencyInfoTitle,
          isSaveIconRequired:false,
          menuItems:[
            {
              value:$r('sys.symbol.square_and_pencil'),
              isEnabled:true,
              action:()=>{
                EmergencyContactsInfoController.onSquareAndPencilClick(this.pathInfos);
              }
            }
          ],
          onCancel:()=>{
            this.pathInfos.pop({})
          },
          contentMargin:{top:LengthMetrics.px(100)},
        })
          .margin({start:LengthMetrics.vp(24), end:LengthMetrics.vp(24)})
      }else {
        EditableTitleBar({
          title:this.emergencyInfoTitle,
          isSaveIconRequired:false,
          contentMargin:{top:LengthMetrics.px(100)},

          onCancel:()=>{
            this.pathInfos.pop({})
          },
        })
          .margin({start:LengthMetrics.vp(24), end:LengthMetrics.vp(24)})
      }

      EmergencyContactsInfoContent({
        showEmergencyContacts: this.showEmergencyContacts,
        emergencyContacts: this.emergencyContacts,
        isRunningOfOnAddContactButtonClick: this.isRunningOfOnAddContactButtonClick,
        previousPage: this.previousPage,
        onAddContactButtonClick: () => {
          EmergencyContactsInfoController.onAddContactButtonClick(this.isRunningOfOnAddContactButtonClick,
            this.setIsRunningOfOnAddContactButtonClick, this.emergencyContacts, this.checkContactsIsShow,
            this.setEmergencyContacts, this.showConfirmDialog);
        },
      })
        .layoutWeight(1)
    }
    //.title(this.MyCustomTitle)
/*    .titleBar(this.showEmergencyContacts || this.emergencyContacts.length > 0 ?
      TitleParams.MiniTitleParams(this.emergencyInfoTitle, $r('sys.color.background_secondary'),
        this.navigationMenuItemArray) :
      TitleParams.MiniTitleParams(this.emergencyInfoTitle, $r('sys.color.background_secondary')))*/
    .hideTitleBar(true)
    .backgroundColor($r('sys.color.background_secondary'))
    .expandSafeArea([SafeAreaType.KEYBOARD, SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .visibility(this.isContactsShow ? Visibility.Visible : Visibility.None)
    .onShown(() => {
      this.destinationPageShow();
    })
    .onBackPressed(() => {
      this.pathStack.pop({});
      return true;
    })
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}

@Component
export struct ContactItem {
  listItem: ContactListStruct = getEmptyContactListData();
  @Link @Watch('listChange') list: ContactListStruct[];
  index: number = -1;
  @State isShowDivider: boolean = false;
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;
  @StorageProp('topAndBottomMarginOnScale') topAndBottomMarginOnScale: string = '';
  // 如果联系人没有头像，那么就显示昵称的最后一个文字或者大小英文字母，如果为其他昵称中没有中英文那么就显示默认头像
  private photoFirstName: string = '';

  aboutToAppear() {
    LogUtils.e(TAG, 'DefaultListItem aboutToAppear');
    this.listChange();
  }

  listChange() {
    this.isShowDivider = this.index !== this.list.length - 1;
  }

  getPhotoNameDeal(contactsName: ResourceStr) {
    this.photoFirstName = photoFirstNameDeal(contactsName);
    return this.photoFirstName;
  }

  build() {
    Row() {
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
            .borderRadius(40)
        } else {
          Image($r('app.media.ic_user'))
            .width(40)
            .height(40)
            .foregroundColor($r('sys.color.icon_secondary'))
        }
      }
      .width(56)
      .constraintSize({ minHeight: 40 })
      .padding({ right: $r('sys.float.padding_level2') })

      Column() {
        Row() {
          Text(this.listItem.label)
            .fontSize($r('sys.float.Subtitle_L'))
            .fontColor($r('sys.color.font_primary'))
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .margin({ top: this.topAndBottomMarginOnScale })
        Row() {
          Text(this.listItem.value)
            .fontSize($r('sys.float.Subtitle_M'))
            .fontColor($r('sys.color.font_secondary'))
            .fontWeight(FontWeight.Regular)
            .direction(Direction.Ltr)
        }
        .width('100%')
        .margin({ top: $r('sys.float.padding_level1') })
        Row() {
          if (this.isShowDivider) {
            Divider()
              .color($r('sys.color.comp_divider'))
          }
        }
        .width('100%')
        .margin({ top: this.topAndBottomMarginOnScale })
      }
      .layoutWeight(1)
    }
    .alignItems(VerticalAlign.Center)
  }
}

const CONTENT_TAG = 'EmergencyContactsInfoContent';

@Component
export struct EmergencyContactsInfoContent {
  @LocalStorageProp('extensionFlag') extensionFlag: boolean = true;
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;
  @StorageProp('topAndBottomMarginOnScale') topAndBottomMarginOnScale: string = '';
  @StorageProp('curBp') curBp: string = '';
  @StorageProp('statusBarHeight') statusBarHeight: number = 38;
  @Consume('pathInfos') pathInfos: NavPathStack;
  @Prop showEmergencyContacts: boolean = false;
  @Prop emergencyContacts: ContactListStruct[] = [];
  public isRunningOfOnAddContactButtonClick = false;
  public previousPage: string = '';
  private sosEmergencyHelpStr: string = '';
  private bottomTextList: string[] = [];
  private mySOSSettingsController: SosSettingsController = SosSettingsController.getInstance();
  public onAddContactButtonClick = () => {
  };

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

  aboutToAppear() {
    LogUtils.i(CONTENT_TAG, 'aboutToAppear');
    try {
      const context = getContext();
      this.sosEmergencyHelpStr = context.resourceManager.getStringSync($r('app.string.Sos_emergency_title').id);
      const warnInfoStr = context.resourceManager.getStringSync($r('app.string.warnInfo', '').id,
        this.sosEmergencyHelpStr);
      let tempLIst = warnInfoStr.split(this.sosEmergencyHelpStr);
      tempLIst.splice(1, 0, this.sosEmergencyHelpStr);
      this.bottomTextList = tempLIst.filter(v => (Boolean(v)));
    } catch (e) {
      LogUtils.e(CONTENT_TAG, `aboutToAppear error ${e?.code} ${e?.message}`);
    }
  }

  @Builder
  warnContentBuilder() {
    Column() {
      Image($r('app.media.empty_page_contacts'))
        .width(this.curBp === 'sm' || this.curBp === 'xs' ? 120 : 160)
        .constraintSize({ minHeight: this.curBp === 'sm' || this.curBp === 'xs' ? 120 : 160 })
        .draggable(false);
      Text($r('app.string.contactsWarnContent'))
        .width('100%')
        .fontSize($r('sys.float.Body_L'))
        .fontColor($r('sys.color.font_tertiary'))
        .fontWeight(FontWeight.Regular)
        .margin({ top: $r('sys.float.padding_level4') });
      Text() {
        ForEach(this.bottomTextList, (item: string) => {
          if (item === this.sosEmergencyHelpStr) {
            Span(item)
              .fontColor($r('sys.color.font_emphasize'))
              .fontWeight(FontWeight.Medium)
              .onClick(() => {
                LogUtils.i(TAG, 'session.sendData');
                this.mySOSSettingsController.handleJumpToSosSettingsPage(this.previousPage, this.pathInfos)
              });
          } else {
            Span(item)
              .fontColor($r('sys.color.font_tertiary'))
              .fontWeight(FontWeight.Regular);
          }
        });
      }
      .width('auto')
      .alignSelf(ItemAlign.Start)
      .fontSize($r('sys.float.Body_L'))
      .margin({ top: $r('sys.float.padding_level4') });
    }
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .margin({
      left: CallColumnUtils.getInstance().getPaddingSpace(this.curBp, this.extensionFlag),
      right: CallColumnUtils.getInstance().getPaddingSpace(this.curBp, this.extensionFlag)
    })
  }

  @Builder
  emergencyInfoItemContentBuilder() {
    Scroll() {
      Column() {
        this.warnContentBuilder();
      }
      .constraintSize({ minHeight: 'calc(100% - 108vp)' })
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .layoutWeight(1);

    Column() {
      Button() {
        Text($r('app.string.addEmergencyContact'))
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .fontSize($r('sys.float.Body_L'))
          .maxLines(2)
          .lineHeight(21)
      }
      .width('100%')
      .constraintSize({ maxWidth: 448 })
      .constraintSize({ minHeight: 40 })
      .backgroundColor($r('sys.color.comp_background_tertiary'))
      .fontColor($r('sys.color.font_emphasize'))
      .type(ButtonType.Normal)
      .borderRadius($r('sys.float.corner_radius_level10'))
      .padding({ top: 8, bottom: 8 })
      .onClick(() => {
        EmergencyContactsInfoController.onSquareAndPencilClick(this.pathInfos);
        ReportUtil.getInstance().reportClickAddEmergencyInfo();
      });
    }
    .margin({
      top: 24,
      bottom: 44,
      left: CallColumnUtils.getInstance().getPaddingSpace(this.curBp, this.extensionFlag),
      right: CallColumnUtils.getInstance().getPaddingSpace(this.curBp, this.extensionFlag)
    })
  }

  @Builder
  emergencyInfoItem() {
    Scroll() {
      Column() {
        this.emergencyInfoItemContentBuilder()
      }
      .margin({ top: TITLE_BAR_HEIGHT_MINI + this.statusBarHeight })
    }
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  build() {
    GridRow({
      columns: {
        xs: 2,
        sm: 4,
        md: 8,
        lg: 12
      },
      gutter: { x: 12, y: 0 }
    }) {
      GridCol({
        span: {
          xs: 2,
          sm: 4,
          md: this.extensionFlag ? 8 : 6,
          lg: this.extensionFlag ? 12 : 8
        },
        offset: { md: this.extensionFlag ? 0 : 1, lg: this.extensionFlag ? 0 : 2 }
      }) {
        if (this.showEmergencyContacts || this.emergencyContacts.length > 0) {
          List() {
            if (this.showEmergencyContacts) {
              ListItemGroup() {
                ForEach(this.emergencyContacts, (item: ContactListStruct, index: number) => {
                  ListItem() {
                    ContactItem({
                      listItem: item,
                      list: this.emergencyContacts,
                      index: index,
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
                  .onClick(() => {
                    EmergencyContactsInfoController.callEmergencyContact(item);
                  })
                }, (item: ContactListStruct) => JSON.stringify(item))
              }
              .width('100%')
              .constraintSize({ minHeight: 64 })
              .margin({
                top: TITLE_BAR_HEIGHT_MINI + this.statusBarHeight + 16,
                bottom: $r('sys.float.padding_level6')
              })
              .emergencyInfoGroup()
            }
            if (this.emergencyContacts.length < commonData.int.CONTACT_UPPER_LIMIT) {
              ListItemGroup() {
                ListItem() {
                  Flex({ alignItems: ItemAlign.Center }) {
                    Column() {
                      SymbolGlyph($r('sys.symbol.plus_circle'))
                        .fontSize($r('app.float.emc_margin_level12'))
                        .fontColor([$r('sys.color.font_emphasize')])
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
                    right: $r('sys.float.padding_level4')
                  })
                }
                .borderRadius($r('sys.float.corner_radius_level8'))
                .stateStyles({
                  pressed: this.pressedStyles,
                  normal: this.normalStyles
                })
                .width('100%')
              }
              .margin({ top: this.showEmergencyContacts ? 0 : TITLE_BAR_HEIGHT_MINI + this.statusBarHeight + 16 })
              .emergencyInfoGroup()
              .onClick(() => {
                this.isRunningOfOnAddContactButtonClick = true;
                try {
                  this.onAddContactButtonClick();
                } catch (e) {
                  LogUtils.e(TAG, `onAddContactButtonClick error: ${e?.code} ${e?.message}`);
                  this.isRunningOfOnAddContactButtonClick = false;
                }
              })
            }
          }
          .scrollBar(BarState.Off)
          .width('100%')
          .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
          .layoutWeight(1)
          .margin({
            left: CallColumnUtils.getInstance().getPaddingSpace(this.curBp, this.extensionFlag),
            right: CallColumnUtils.getInstance().getPaddingSpace(this.curBp, this.extensionFlag)
          })
        } else {
          this.emergencyInfoItem();
        }
      }
    }
  }
}

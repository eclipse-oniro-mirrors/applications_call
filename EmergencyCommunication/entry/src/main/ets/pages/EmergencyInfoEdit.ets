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

import emergencyInfoItem from '../components/EmergencyInfoItem';
import { EmergencyInfoStruct, DialogDataStruct, ContactListStruct } from '../utils/ClassStruct';
import * as storageUtil from '../utils/DataStorageUtil';
import LogUtils from '../utils/HiLog';
import EmergencyCallController from '../control/EmergencyCallControl';
import { updateObjectValue } from '../utils/CommonFunction';
import CallColumnUtils from '../utils/CallColumnUtils';
import { SubHeader } from '@ohos.arkui.advanced.SubHeader';
import { CustomContentDialog, SelectDialog, AlertDialog } from '@ohos.arkui.advanced.Dialog';
import { ComponentContent, EditableTitleBar, LengthMetrics } from '@kit.ArkUI';
import { DataStorageUtil } from '../utils/DataStorageUtil';
//import { HdsNavDestination, HdsNavDestinationAttribute, HdsNavigationMenuContentOptions } from '@kit.UIDesignKit';
import { NavigationMenuContentOptions, TitleBarLayout, TitleParams } from '../base/view/TitleParams';
import { TITLE_BAR_HEIGHT_MINI } from '../base/constant/HdsNavigationConstant';

const TAG = 'emergencyInfoEdit';
const RADIO_ID_0 = 0;
const RADIO_ID_1 = 1;
const RADIO_ID_2 = 2;
const RADIO_ID_3 = 3;
const RADIO_ID_4 = 4;
const RADIO_ID_5 = 5;
const RADIO_ID_6 = 6;
const RADIO_ID_7 = 7;
const RADIO_ID_8 = 8;
const RADIO_ID_9 = 9;


export interface MenuClass {
  value: ResourceStr;
  icon?: ResourceStr;
  action: () => void;
}

/**
 * 点击菜单栏弹出菜单，显示清除所有
 * @param { function } event
 */
@Builder
function menuComponent(event: (event: ClickEvent) => void): void {
  Menu() {
    MenuItem({ content: $r('app.string.clearAll') }).onClick(event)
  }.width(224)
}

@Component
export default struct EmergencyInfoEdit {
  private storage = LocalStorage.getShared();
  scroller: Scroller = new Scroller();
  @Consume('pathInfos') pathInfos: NavPathStack;
  @State mEmergencyCallController: EmergencyCallController = EmergencyCallController.getInstance();
  @State emergencyInfoEditTitle: string =
    this.mEmergencyCallController.formatResourceToString($r('app.string.editEmergencyInfo'));
  @StorageProp('curBp') curBp: string = '';
  @StorageProp('ratio') ratio: number = 0;
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('topAndBottomMarginOnScale') topAndBottomMarginOnScale: string = '';
  @StorageProp('statusBarHeight') statusBarHeight: number = 38;
  placeholder: Resource = $r('app.string.emptyStr');
  @State inputValue: string = '';
  private mCallColumnUtils: CallColumnUtils = CallColumnUtils.getInstance();
  @State isMenuTouch: boolean = false;
  @State inputFocus: boolean = true;
  @State emergencyInfo: EmergencyInfoStruct = {
    name: '',
    address: '',
    bloodType: '',
    allergicReaction: '',
    drug: '',
    isOrganDonor: '',
    drugStatusAndNotice: ''
  }
  @State emergencyContacts: ContactListStruct[] = [];
  bloodTypes: SheetInfo[] = [
    {
      title: '\u200eO+\u200e',
      action: () => {
        this.dialogData.confirm('\u200eO+\u200e');
        this.radioId = RADIO_ID_0;
      },
    },
    {
      title: '\u200eO-\u200e', action: () => {
      this.dialogData.confirm('\u200eO-\u200e');
      this.radioId = RADIO_ID_1;
    },
    },
    {
      title: '\u200eA+\u200e', action: () => {
      this.dialogData.confirm('\u200eA+\u200e');
      this.radioId = RADIO_ID_2;
    },
    },
    {
      title: '\u200eA-\u200e', action: () => {
      this.dialogData.confirm('\u200eA-\u200e');
      this.radioId = RADIO_ID_3;
    },
    },
    {
      title: '\u200eB+\u200e', action: () => {
      this.dialogData.confirm('\u200eB+\u200e');
      this.radioId = RADIO_ID_4;
    },
    },
    {
      title: '\u200eB-\u200e', action: () => {
      this.dialogData.confirm('\u200eB-\u200e');
      this.radioId = RADIO_ID_5;
    },
    },
    {
      title: '\u200eAB+\u200e', action: () => {
      this.dialogData.confirm('\u200eAB+\u200e');
      this.radioId = RADIO_ID_6;
    },
    },
    {
      title: '\u200eAB-\u200e', action: () => {
      this.dialogData.confirm('\u200eAB-\u200e');
      this.radioId = RADIO_ID_7;
    },
    },
    {
      title: 'H/H', action: () => {
      this.dialogData.confirm('H/H');
      this.radioId = RADIO_ID_8;
    },
    },
    {
      title: $r('app.string.noStated'), action: () => {
      this.dialogData.confirm('');
      this.radioId = RADIO_ID_9;
    },
      // action: $r('app.string.noStated'),
    }];
  stringYes: string = this.mEmergencyCallController.formatResourceToString($r('app.string.yes'));
  stringNo: string = this.mEmergencyCallController.formatResourceToString($r('app.string.no'));
  isOrganDonors: SheetInfo[] = [
    {
      title: $r('app.string.yes'),
      action: () => {
        this.dialogData.confirm(this.stringYes);
        this.radioId = RADIO_ID_0;
      },
    },
    {
      title: $r('app.string.no'),
      action: () => {
        this.dialogData.confirm(this.stringNo);
        this.radioId = RADIO_ID_1;
      }
    },
    {
      title: this.mEmergencyCallController.formatResourceToString($r('app.string.noStated')),
      action: () => {
        this.dialogData.confirm('');
        this.radioId = RADIO_ID_2;
      },
    }
  ];
  public radioId: number = -1;
  @State dialogData: DialogDataStruct = {
    title: $r('app.string.emptyStr'),
    textValue: '',
    placeholder: $r('app.string.emptyStr'),
    confirm: (data?: string) => {
    }
  };
  @LocalStorageProp('extensionFlag') extensionFlag: boolean = false;
/*  private moreMenu: HdsNavigationMenuContentOptions = {
    value: [
      {
        content: {
          label: $r('app.string.InfoEdit_edits_info'),
          icon: $r('sys.symbol.square_and_pencil'),
          componentId: 'editMenu',
          isEnabled: true,
          action: () => {
            let uiContext = this.getUIContext();
            let promptAction = uiContext.getPromptAction();
            let contentNode = new ComponentContent(uiContext, wrapBuilder(menuComponent), this.clickEvent);
            try {
              promptAction.openMenu(contentNode, { id: 'editMenu' }, { placement: Placement.BottomRight })
            } catch (error) {
              LogUtils.e(TAG, `openMenu args error code is ${error?.code}, message is ${error?.message}`);
            }

          }
        }
      }
    ]
  };*/
  // private moreMenu: NavigationMenuContentOptions = {
  //   value: [
  //     {
  //
  //         value: $r('app.string.InfoEdit_edits_info'),
  //         icon: $r('sys.symbol.square_and_pencil'),
  //         //componentId: 'editMenu',
  //         isEnabled: true,
  //         action: () => {
  //           let uiContext = this.getUIContext();
  //           let promptAction = uiContext.getPromptAction();
  //           let contentNode = new ComponentContent(uiContext, wrapBuilder(menuComponent), this.clickEvent);
  //           try {
  //             promptAction.openMenu(contentNode, { id: 'editMenu' }, { placement: Placement.BottomRight })
  //           } catch (error) {
  //             LogUtils.e(TAG, `openMenu args error code is ${error?.code}, message is ${error?.message}`);
  //           }
  //       }
  //     }
  //   ]
  // };


  /**
   * 清除所有菜单点击事件
   */
  clickEvent = () => {
    this.showConfirmDialog($r('app.string.clearInfo'));
  }

  aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear');
  }

  destinationPageShow() {
    LogUtils.i(TAG, 'destinationPageShow');
    storageUtil.getEmergencyInfoData((data => {
      let keys: string[] = Object.keys(data);
      if (keys.length !== 0) {
        this.emergencyInfo = {
          name: data['name'] || '',
          address: data['address'] || '',
          bloodType: data['bloodType'] || '',
          allergicReaction: data['allergicReaction'] || '',
          drug: data['drug'] || '',
          isOrganDonor: data['isOrganDonor'] || '',
          drugStatusAndNotice: data['drugStatusAndNotice'] || '',
        }
      }
    }));
    DataStorageUtil.getInstance().getEmergencyContacts((data) => {
      this.emergencyContacts = data;
    })
  };

  @Builder
  infoEditDialogContent() {
    Column() {
      TextArea({ text: this.inputValue, placeholder: this.placeholder })
        .width('100%')
        .constraintSize({ minHeight: 48 })
        .fontColor($r('sys.color.font_primary'))
        .fontSize($r('sys.float.Body_L'))
        .backgroundColor(Color.Transparent)
        .caretColor($r('sys.color.font_emphasize'))
        .borderRadius($r('sys.float.corner_radius_none'))
        .fontWeight(FontWeight.Regular)
        .draggable(false)
        .focusable(this.inputFocus)
        .defaultFocus(true)
        .padding({ left: $r('sys.float.padding_level0') })
        .align(Alignment.Center)
        .onChange((value) => {
          this.inputValue = value;
        })
        .onTouch(() => {
          this.inputFocus = true;
        })
        .onBlur(() => {
          this.inputFocus = false;
        })
        .margin({ top: $r('sys.float.padding_level2') })
      Divider()
        .margin({ bottom: $r('sys.float.padding_level2') })
        .width('100%')
        .color($r('sys.color.comp_divider'))
    }
    .width('100%')
  }

  /**
   * 点击菜单栏弹出菜单，显示清除所有
   * */
  @Builder
  moreMenu(){
    Menu(){
      MenuItem({
        content: $r('app.string.clearAll'),
      })
        .id( 'editMenu')
        .onClick(()=>{
          this.clickEvent()
        })
    }
  }

  editDialog: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: this.dialogData.title,
      contentBuilder: () => {
        this.infoEditDialogContent();
      },
      buttons: [
        {
          value: $r('app.string.CANCEL'),
          action: () => {
            this.inputFocus = false;
            this.editDialog.close();
          }
        },
        {
          value: $r('app.string.determine'),
          action: () => {
            this.inputFocus = false;
            this.dialogData.confirm(this.inputValue);
            this.editDialog.close();
          }
        }
      ]
    }),
    autoCancel: false,
    showInSubWindow: true
  });
  radioDialog: CustomDialogController = new CustomDialogController({
    builder: SelectDialog({
      title: this.dialogData.title,
      radioContent: this.dialogData.radioList,
      confirm: {
        value: $r('app.string.CANCEL'), action: () => {
          this.radioDialog.close();
        }
      },
      selectedIndex: this.radioId,
    }),
    autoCancel: false,
    showInSubWindow: true
  });
  confirmDialog: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.clearInfo'),
      primaryButton: {
        value: $r('app.string.CANCEL'),
        action: () => {
          this.confirmDialog.close();
        }
      },
      secondaryButton: {
        value: $r('app.string.clear'),
        action: () => {
          this.dialogData.confirm();
          this.confirmDialog.close();
        },
        role: ButtonRole.ERROR
      }
    }),
    autoCancel: false,
    showInSubWindow: true
  });

  showEditDialog(title: Resource, textValue: string, placeholder: Resource, key: string) {
    this.dialogData.title = title;
    this.dialogData.textValue = textValue;
    this.dialogData.placeholder = placeholder;
    this.dialogData.confirm = (value) => {
      this.emergencyInfo = updateObjectValue(key, value, this.emergencyInfo);
      storageUtil.updateEmergencyInfo(key, value || '');
    }
    this.inputValue = this.dialogData.textValue;
    this.placeholder = placeholder;
    this.inputFocus = true;
    this.editDialog.open();
  }

  bloodRadioSelect(textValue: string) {
    switch (textValue) {
      case '\u200eO+\u200e':
        this.radioId = RADIO_ID_0;
        break;
      case '\u200eO-\u200e':
        this.radioId = RADIO_ID_1;
        break;
      case '\u200eA+\u200e':
        this.radioId = RADIO_ID_2;
        break;
      case '\u200eA-\u200e':
        this.radioId = RADIO_ID_3;
        break;
      case '\u200eB+\u200e':
        this.radioId = RADIO_ID_4;
        break;
      case '\u200eB-\u200e':
        this.radioId = RADIO_ID_5;
        break;
      case '\u200eAB+\u200e':
        this.radioId = RADIO_ID_6;
        break;
      case '\u200eAB-\u200e':
        this.radioId = RADIO_ID_7;
        break;
      case 'H/H':
        this.radioId = RADIO_ID_8;
        break;
      case '':
        this.radioId = RADIO_ID_9;
        break;
      default:
        this.radioId = RADIO_ID_9;
    }
  }

  showRadioSelect(textValue: string, key: string) {
    if (key === 'bloodType') {
      this.bloodRadioSelect(textValue);
    } else {
      switch (textValue) {
        case this.stringYes:
          this.radioId = RADIO_ID_0;
          break;
        case this.stringNo: {
          this.radioId = RADIO_ID_1;
          break;
        }
        case '': {
          this.radioId = RADIO_ID_2;
          break;
        }
        default: {
          this.radioId = RADIO_ID_2;
        }
      }
    }
  }

  showRadioDialog(title: Resource, textValue: string, radioList: SheetInfo[], key: string) {
    this.dialogData.title = title;
    this.dialogData.textValue = textValue;
    this.showRadioSelect(textValue, key);
    this.dialogData.radioList = radioList;
    this.dialogData.confirm = (value) => {
      this.emergencyInfo = updateObjectValue(key, value, this.emergencyInfo);
      storageUtil.updateEmergencyInfo(key, value || '');
    }
    this.radioDialog.open();
  }

  showConfirmDialog(contentText: Resource) {
    this.dialogData.contentText = contentText;
    this.dialogData.confirm = () => {
      this.clearAllEmergencyInfo();
    }
    this.confirmDialog.open();
  }

  clearAllEmergencyInfo() {
    this.emergencyInfo = {
      name: '',
      address: '',
      bloodType: '',
      allergicReaction: '',
      drug: '',
      isOrganDonor: '',
      drugStatusAndNotice: ''
    }
    storageUtil.cleanEmergencyInfo();
    this.emergencyContacts = [];
    DataStorageUtil.getInstance().updateEmergencyContacts(this.emergencyContacts);
  }

  backItemClick() {
    LogUtils.i(TAG, 'backItemClick');
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
  DividerItem() {
    Row() {
      Divider()
        .width('100%')
        .color($r('sys.color.comp_divider'))
        .backgroundColor($r('sys.color.comp_background_primary'))
    }
    .width('100%')
    .padding({ start: LengthMetrics.vp(48), end: LengthMetrics.resource($r('sys.float.padding_level6')) })
  }

  @Builder
  imageNextBuilder() {
    SymbolGlyph($r('sys.symbol.chevron_right'))
      .fontSize('24vp')
      .margin({ start: LengthMetrics.resource($r('sys.float.padding_level2')) })
      .fontColor([$r('sys.color.icon_fourth')])
  }

  build() {
/*    HdsNavDestination() {
      GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: 24 }) {
        GridCol({ span: { xs: 2, sm: 4, md: this.extensionFlag ? 8 : 6, lg: this.extensionFlag ? 12 : 8 },
          offset: { md: this.extensionFlag ? 0 : 1, lg: this.extensionFlag ? 0 : 2 } }) {
          List() {
            SubHeader({ secondaryTitle: $r('app.string.personalInfo') })
              .margin({
                start: LengthMetrics.vp(-16),
                top: LengthMetrics.vp(TITLE_BAR_HEIGHT_MINI + this.statusBarHeight)
              })
            ListItemGroup() {
              ListItem() {
                Column() {
                  emergencyInfoItem({
                    value: this.emergencyInfo.name,
                    label: $r('app.string.fullName'),
                    labelOnly: true,
                    placeholder: $r('app.string.fullName'),
                    photoUrl: $r('sys.symbol.person')
                  })
                  this.DividerItem()
                }
              }
              .constraintSize({ minHeight: 56 })
              .onClick(() => {
                this.showEditDialog($r('app.string.fullName'), this.emergencyInfo.name!,
                  $r('app.string.emptyStr'), 'name');
              })
              ListItem() {
                emergencyInfoItem({
                  value: this.emergencyInfo.address,
                  label: $r('app.string.address'),
                  labelOnly: false,
                  placeholder: $r('app.string.noStated'),
                  photoUrl: $r('sys.symbol.local')
                })
              }
              .constraintSize({ minHeight: $r('app.float.emc_wh_level64') })
              .onClick(() => {
                this.showEditDialog($r('app.string.address'), this.emergencyInfo.address!, $r('app.string.emptyStr'), 'address');
              })
            }
            .emergencyInfoGroup()
            SubHeader({ secondaryTitle: $r('app.string.medicalInfo') })
              .margin({ start: LengthMetrics.vp(-16) })
            ListItemGroup() {
              ListItem() {
                Column() {
                  emergencyInfoItem({
                    value: this.emergencyInfo.bloodType,
                    label: $r('app.string.bloodType'),
                    labelOnly: false,
                    placeholder: $r('app.string.noStated'),
                    photoUrl: $r('sys.symbol.cross_filled_drop')
                  })
                  this.DividerItem();
                }
              }
              .constraintSize({ minHeight: $r('app.float.emc_wh_level64') })
              .onClick(() => {
                this.showRadioDialog($r('app.string.bloodType'), this.emergencyInfo.bloodType!,
                  this.bloodTypes, 'bloodType');
              })
              ListItem() {
                Column() {
                  emergencyInfoItem({
                    value: this.emergencyInfo.allergicReaction,
                    label: $r('app.string.allergies'),
                    labelOnly: false,
                    placeholder: $r('app.string.noStated'),
                    photoUrl: $r('sys.symbol.nosign')
                  })
                  this.DividerItem();
                }
              }
              .constraintSize({ minHeight: $r('app.float.emc_wh_level64') })
              .onClick(() => {
                this.showEditDialog($r('app.string.allergies'), this.emergencyInfo.allergicReaction!,
                  $r('app.string.allergiesPlacement'), 'allergicReaction');
              })
              ListItem() {
                Column() {
                  emergencyInfoItem({
                    value: this.emergencyInfo.drug,
                    label: $r('app.string.drug'),
                    labelOnly: false,
                    placeholder: $r('app.string.noStated'),
                    photoUrl: $r('sys.symbol.drug')
                  })
                  this.DividerItem();
                }
              }
              .constraintSize({ minHeight: $r('app.float.emc_wh_level64') })
              .onClick(() => {
                this.showEditDialog($r('app.string.drug'), this.emergencyInfo.drug!,
                  $r('app.string.drugPlacement'), 'drug');
              })
              ListItem() {
                emergencyInfoItem({
                  value: this.emergencyInfo.drugStatusAndNotice,
                  label: $r('app.string.drugStatus'),
                  labelOnly: false,
                  placeholder: $r('app.string.noStated'),
                  photoUrl: $r('sys.symbol.cross_vial')
                })
              }
              .borderRadius({
                bottomLeft: $r('sys.float.corner_radius_level10'),
                bottomRight: $r('sys.float.corner_radius_level10')
              })
              .constraintSize({ minHeight: $r('app.float.emc_wh_level64') })
              .onClick(() => {
                this.showEditDialog($r('app.string.drugStatus'),
                  this.emergencyInfo.drugStatusAndNotice!,
                  $r('app.string.drugStatusPlacement'), 'drugStatusAndNotice');
              })
            }
            .emergencyInfoGroup()

            SubHeader({ secondaryTitle: $r('app.string.emergencyContacts') })
              .margin({ start: LengthMetrics.vp(-16) })
            if (this.fontSizeScale < 1.75) {
              ListItemGroup() {
                ListItem() {
                  Flex({ alignItems: ItemAlign.Center }) {
                    Row() {
                      SymbolGlyph($r('sys.symbol.person_badge_heart'))
                        .fontSize($r('app.float.emc_margin_level12'))
                        .fontColor([$r('sys.color.icon_secondary')])
                        .margin({
                          start: LengthMetrics.resource($r('sys.float.padding_level0')),
                          end: LengthMetrics.resource($r('sys.float.padding_level8'))
                        })
                        .draggable(false)
                        .foregroundColor($r('sys.color.icon_secondary'))
                      Text($r('app.string.emergencyContact'))
                        .fontSize($r('sys.float.Body_L'))
                        .fontColor($r('sys.color.font_primary'))
                        .fontWeight(FontWeight.Medium)
                        .layoutWeight(1)
                    }
                    .flexGrow(1)
                    .justifyContent(FlexAlign.Start)
                    .padding({ right: $r('sys.float.padding_level2') })


                    Column() {
                      Row() {
                        Text(this.emergencyContacts.length > 0 ?
                        $r('app.string.peopleAdded', this.emergencyContacts.length) : $r('app.string.notAdded'))
                          .fontColor($r('sys.color.font_secondary'))
                          .fontSize($r('sys.float.Body_M'))
                          .fontWeight(FontWeight.Regular)

                        this.imageNextBuilder()
                      }
                    }
                    .alignItems(HorizontalAlign.End)
                  }
                }
                .padding({
                  left: $r('sys.float.padding_level6'),
                  right: $r('sys.float.padding_level6'),
                  top: $r('sys.float.padding_level2'),
                  bottom: $r('sys.float.padding_level2')
                })
                .borderRadius($r('sys.float.corner_radius_level8'))
                .constraintSize({ minHeight: 56 })
                .stateStyles({
                  pressed: this.pressedStyles,
                  normal: this.normalStyles
                })
                .onClick(() => {
                  this.pathInfos.pushPathByName('EmergencyContactsEdit', '');
                })
              }
              .width('100%')
              .emergencyInfoGroup()
            } else {
              ListItemGroup() {
                ListItem() {
                  Flex({ alignItems: ItemAlign.Center }) {
                    Column() {
                      SymbolGlyph($r('sys.symbol.person_badge_heart'))
                        .fontSize($r('app.float.emc_margin_level12'))
                        .fontColor([$r('sys.color.icon_secondary')])
                        .draggable(false)
                        .foregroundColor($r('sys.color.icon_secondary'))
                    }
                    .width(24)
                    .margin({ right: $r('sys.float.padding_level8') })
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)

                    Column() {
                      Text($r('app.string.emergencyContact'))
                        .width('100%')
                        .fontSize($r('sys.float.Body_L'))
                        .fontColor($r('sys.color.font_primary'))
                        .fontWeight(FontWeight.Medium)
                        .constraintSize({ minHeight: $r('app.float.emc_height_level11') })
                      Row() {
                        Text(this.emergencyContacts.length > 0 ?
                        $r('app.string.peopleAdded', this.emergencyContacts.length) : $r('app.string.notAdded'))
                          .fontSize($r('sys.float.Body_M'))
                          .fontColor($r('sys.color.font_secondary'))
                          .fontWeight(FontWeight.Regular)
                          .constraintSize({ minHeight: $r('app.float.emc_height_level19') })

                        this.imageNextBuilder()
                      }
                      .justifyContent(FlexAlign.SpaceBetween)
                      .width('100%')
                      .margin({ top: $r('sys.float.padding_level1') });
                    }
                    .margin({ right: $r('sys.float.padding_level0') })
                    .layoutWeight(1)
                  }
                  .padding({
                    left: $r('sys.float.padding_level6'),
                    right: $r('sys.float.padding_level6'),
                    top: this.fontSizeScale < 1.75 ? $r('app.float.emc_margin_level17') :
                    this.topAndBottomMarginOnScale,
                    bottom: this.fontSizeScale < 1.75 ? $r('app.float.emc_margin_level17') :
                    this.topAndBottomMarginOnScale
                  })
                }
                .width('100%')
                .borderRadius($r('sys.float.corner_radius_level8'))
                .constraintSize({ minHeight: 56 })
                .stateStyles({
                  pressed: this.pressedStyles,
                  normal: this.normalStyles
                })
                .onClick(() => {
                  this.pathInfos.pushPathByName('EmergencyContactsEdit', '');
                })
              }
              .emergencyInfoGroup()
            }
          }
          .backgroundColor($r('sys.color.background_secondary'))
          .scrollBar(BarState.Off)
          .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
          .padding({ bottom: $r('sys.float.padding_level12')})
          .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
          .layoutWeight(1)
        }
      }
      .margin({
        left: CallColumnUtils.getInstance().getPaddingSpace(this.curBp, this.extensionFlag),
        right: CallColumnUtils.getInstance().getPaddingSpace(this.curBp, this.extensionFlag)
      })
    }*/
    NavDestination() {
     Row(){
       EditableTitleBar({
         title:this.emergencyInfoEditTitle,
         contentMargin:{top:LengthMetrics.px(100)},
         isSaveIconRequired: false,
         onCancel:()=>{
           this.pathInfos.pop()
         }
       })
         .layoutWeight(1)
       Image($r("app.media.edit"))
         .height(36)
         .width(36)
         .padding(6)
         .margin({top:LengthMetrics.px(100)})
         .backgroundColor('rgba(0, 0, 0, 0.05)')
         .borderRadius(18)
         .bindMenu(
           this.moreMenu
         )
     }
         .margin({start:LengthMetrics.vp(24), end:LengthMetrics.vp(24)})
      GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: 24 }) {
        GridCol({ span: { xs: 2, sm: 4, md: this.extensionFlag ? 8 : 6, lg: this.extensionFlag ? 12 : 8 },
          offset: { md: this.extensionFlag ? 0 : 1, lg: this.extensionFlag ? 0 : 2 } }) {
          List() {
            SubHeader({ secondaryTitle: $r('app.string.personalInfo') })
              .margin({
                start: LengthMetrics.vp(-16),
                top: LengthMetrics.vp(TITLE_BAR_HEIGHT_MINI + this.statusBarHeight)
              })
            ListItemGroup() {
              ListItem() {
                Column() {
                  emergencyInfoItem({
                    value: this.emergencyInfo.name,
                    label: $r('app.string.fullName'),
                    labelOnly: true,
                    placeholder: $r('app.string.fullName'),
                    photoUrl: $r('sys.symbol.person')
                  })
                  this.DividerItem()
                }
              }
              .constraintSize({ minHeight: 56 })
              .onClick(() => {
                this.showEditDialog($r('app.string.fullName'), this.emergencyInfo.name!,
                  $r('app.string.emptyStr'), 'name');
              })
              ListItem() {
                emergencyInfoItem({
                  value: this.emergencyInfo.address,
                  label: $r('app.string.address'),
                  labelOnly: false,
                  placeholder: $r('app.string.noStated'),
                  photoUrl: $r('sys.symbol.local')
                })
              }
              .constraintSize({ minHeight: $r('app.float.emc_wh_level64') })
              .onClick(() => {
                this.showEditDialog($r('app.string.address'), this.emergencyInfo.address!, $r('app.string.emptyStr'), 'address');
              })
            }
            .emergencyInfoGroup()
            SubHeader({ secondaryTitle: $r('app.string.medicalInfo') })
              .margin({ start: LengthMetrics.vp(-16) })
            ListItemGroup() {
              ListItem() {
                Column() {
                  emergencyInfoItem({
                    value: this.emergencyInfo.bloodType,
                    label: $r('app.string.bloodType'),
                    labelOnly: false,
                    placeholder: $r('app.string.noStated'),
                    photoUrl: $r('sys.symbol.cross_filled_drop')
                  })
                  this.DividerItem();
                }
              }
              .constraintSize({ minHeight: $r('app.float.emc_wh_level64') })
              .onClick(() => {
                this.showRadioDialog($r('app.string.bloodType'), this.emergencyInfo.bloodType!,
                  this.bloodTypes, 'bloodType');
              })
              ListItem() {
                Column() {
                  emergencyInfoItem({
                    value: this.emergencyInfo.allergicReaction,
                    label: $r('app.string.allergies'),
                    labelOnly: false,
                    placeholder: $r('app.string.noStated'),
                    photoUrl: $r('sys.symbol.nosign')
                  })
                  this.DividerItem();
                }
              }
              .constraintSize({ minHeight: $r('app.float.emc_wh_level64') })
              .onClick(() => {
                this.showEditDialog($r('app.string.allergies'), this.emergencyInfo.allergicReaction!,
                  $r('app.string.allergiesPlacement'), 'allergicReaction');
              })
              ListItem() {
                Column() {
                  emergencyInfoItem({
                    value: this.emergencyInfo.drug,
                    label: $r('app.string.drug'),
                    labelOnly: false,
                    placeholder: $r('app.string.noStated'),
                    photoUrl: $r('sys.symbol.drug')
                  })
                  this.DividerItem();
                }
              }
              .constraintSize({ minHeight: $r('app.float.emc_wh_level64') })
              .onClick(() => {
                this.showEditDialog($r('app.string.drug'), this.emergencyInfo.drug!,
                  $r('app.string.drugPlacement'), 'drug');
              })
              ListItem() {
                emergencyInfoItem({
                  value: this.emergencyInfo.drugStatusAndNotice,
                  label: $r('app.string.drugStatus'),
                  labelOnly: false,
                  placeholder: $r('app.string.noStated'),
                  photoUrl: $r('sys.symbol.cross_vial')
                })
              }
              .borderRadius({
                bottomLeft: $r('sys.float.corner_radius_level10'),
                bottomRight: $r('sys.float.corner_radius_level10')
              })
              .constraintSize({ minHeight: $r('app.float.emc_wh_level64') })
              .onClick(() => {
                this.showEditDialog($r('app.string.drugStatus'),
                  this.emergencyInfo.drugStatusAndNotice!,
                  $r('app.string.drugStatusPlacement'), 'drugStatusAndNotice');
              })
            }
            .emergencyInfoGroup()

            SubHeader({ secondaryTitle: $r('app.string.emergencyContacts') })
              .margin({ start: LengthMetrics.vp(-16) })
            if (this.fontSizeScale < 1.75) {
              ListItemGroup() {
                ListItem() {
                  Flex({ alignItems: ItemAlign.Center }) {
                    Row() {
                      SymbolGlyph($r('sys.symbol.person_badge_heart'))
                        .fontSize($r('app.float.emc_margin_level12'))
                        .fontColor([$r('sys.color.icon_secondary')])
                        .margin({
                          start: LengthMetrics.resource($r('sys.float.padding_level0')),
                          end: LengthMetrics.resource($r('sys.float.padding_level8'))
                        })
                        .draggable(false)
                        .foregroundColor($r('sys.color.icon_secondary'))
                      Text($r('app.string.emergencyContact'))
                        .fontSize($r('sys.float.Body_L'))
                        .fontColor($r('sys.color.font_primary'))
                        .fontWeight(FontWeight.Medium)
                        .layoutWeight(1)
                    }
                    .flexGrow(1)
                    .justifyContent(FlexAlign.Start)
                    .padding({ right: $r('sys.float.padding_level2') })


                    Column() {
                      Row() {
                        Text(this.emergencyContacts.length > 0 ?
                          $r('app.string.peopleAdded', this.emergencyContacts.length) : $r('app.string.notAdded'))
                          .fontColor($r('sys.color.font_secondary'))
                          .fontSize($r('sys.float.Body_M'))
                          .fontWeight(FontWeight.Regular)

                        this.imageNextBuilder()
                      }
                    }
                    .alignItems(HorizontalAlign.End)
                  }
                }
                .padding({
                  left: $r('sys.float.padding_level6'),
                  right: $r('sys.float.padding_level6'),
                  top: $r('sys.float.padding_level2'),
                  bottom: $r('sys.float.padding_level2')
                })
                .borderRadius($r('sys.float.corner_radius_level8'))
                .constraintSize({ minHeight: 56 })
                .stateStyles({
                  pressed: this.pressedStyles,
                  normal: this.normalStyles
                })
                .onClick(() => {
                  this.pathInfos.pushPathByName('EmergencyContactsEdit', '');
                })
              }
              .width('100%')
              .emergencyInfoGroup()
            } else {
              ListItemGroup() {
                ListItem() {
                  Flex({ alignItems: ItemAlign.Center }) {
                    Column() {
                      SymbolGlyph($r('sys.symbol.person_badge_heart'))
                        .fontSize($r('app.float.emc_margin_level12'))
                        .fontColor([$r('sys.color.icon_secondary')])
                        .draggable(false)
                        .foregroundColor($r('sys.color.icon_secondary'))
                    }
                    .width(24)
                    .margin({ right: $r('sys.float.padding_level8') })
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)

                    Column() {
                      Text($r('app.string.emergencyContact'))
                        .width('100%')
                        .fontSize($r('sys.float.Body_L'))
                        .fontColor($r('sys.color.font_primary'))
                        .fontWeight(FontWeight.Medium)
                        .constraintSize({ minHeight: $r('app.float.emc_height_level11') })
                      Row() {
                        Text(this.emergencyContacts.length > 0 ?
                          $r('app.string.peopleAdded', this.emergencyContacts.length) : $r('app.string.notAdded'))
                          .fontSize($r('sys.float.Body_M'))
                          .fontColor($r('sys.color.font_secondary'))
                          .fontWeight(FontWeight.Regular)
                          .constraintSize({ minHeight: $r('app.float.emc_height_level19') })

                        this.imageNextBuilder()
                      }
                      .justifyContent(FlexAlign.SpaceBetween)
                      .width('100%')
                      .margin({ top: $r('sys.float.padding_level1') });
                    }
                    .margin({ right: $r('sys.float.padding_level0') })
                    .layoutWeight(1)
                  }
                  .padding({
                    left: $r('sys.float.padding_level6'),
                    right: $r('sys.float.padding_level6'),
                    top: this.fontSizeScale < 1.75 ? $r('app.float.emc_margin_level17') :
                      this.topAndBottomMarginOnScale,
                    bottom: this.fontSizeScale < 1.75 ? $r('app.float.emc_margin_level17') :
                      this.topAndBottomMarginOnScale
                  })
                }
                .width('100%')
                .borderRadius($r('sys.float.corner_radius_level8'))
                .constraintSize({ minHeight: 56 })
                .stateStyles({
                  pressed: this.pressedStyles,
                  normal: this.normalStyles
                })
                .onClick(() => {
                  this.pathInfos.pushPathByName('EmergencyContactsEdit', '');
                })
              }
              .emergencyInfoGroup()
            }
          }
          .backgroundColor($r('sys.color.background_secondary'))
          .scrollBar(BarState.Off)
          .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
          .padding({ bottom: $r('sys.float.padding_level12')})
          .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
          .layoutWeight(1)
        }
      }
      .margin({
        left: CallColumnUtils.getInstance().getPaddingSpace(this.curBp, this.extensionFlag),
        right: CallColumnUtils.getInstance().getPaddingSpace(this.curBp, this.extensionFlag)
      })
    }
/*    .titleBar(TitleParams.MiniTitleParams(this.emergencyInfoEditTitle, $r('sys.color.background_secondary'),
      this.moreMenu))*/
    //.title(this.MyCustomTitle)
    .hideTitleBar(true)
    .expandSafeArea([SafeAreaType.KEYBOARD])
    .backgroundColor($r('sys.color.background_secondary'))
    .onShown(() => {
      this.destinationPageShow();
    })
  }
}


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
import * as storageUtil from '../utils/DataStorageUtil';
import { EmergencyInfoStruct, ContactListStruct } from '../utils/ClassStruct';
import LogUtils from '../utils/HiLog';
import EmergencyCallController from '../control/EmergencyCallControl';
import { CanAddOrEditEmergencyInfo } from '../utils/EmergencyInfoUtil';
import { UIExtensionContentSession } from '@kit.AbilityKit';
import { SubHeader } from '@ohos.arkui.advanced.SubHeader';
import EmergencyInfoEdit from './EmergencyInfoEdit';
import EmergencyContactsInfo from './EmergencyContactsInfo';
import EmergencyContactsEdit from './EmergencyContactsEdit';
import CallColumnUtils from '../utils/CallColumnUtils';
import { Configuration, EditableTitleBar, LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI';
import {
  ON_RECEIVE_ACTION_JUMP_TO_SOS_SETTINGS_PAGE,
  ON_RECEIVE_URI_JUMP_TO_SOS_SETTINGS_PAGE
} from './EmergencyInfoUIExtension';
import { ReportUtil } from '../utils/ReportUtil';
import { ContactsService } from '../service/ContactsService';
import LooseObject from '../data/LooseObject';
import { call } from '@kit.TelephonyKit';
import { isTablet } from '../utils/DeviceTypeUtils';
import { EditMenu } from '../components/EditMenu';
/*import { HdsNavigation, HdsNavigationAttribute,
  HdsNavigationMenuContentOptions,
  HdsNavigationTitleMode } from '@kit.UIDesignKit';*/
import { NavigationMenuContentOptions, TitleBarLayout, TitleParams } from '../base/view/TitleParams';
import { TITLE_BAR_HEIGHT_MINI } from '../base/constant/HdsNavigationConstant';

const TAG = 'emergencyInfoView';
const storage = LocalStorage.getShared();

@Entry(storage)
@Component
export default struct EmergencyInfoView {
  private session = storage?.get<UIExtensionContentSession>('session');
  @Provide('pathInfos') @Watch('routerPathChange') pathInfos: NavPathStack = new NavPathStack();
  scroller: Scroller = new Scroller();
  @State hasEmergencyInfo: boolean = false;
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
  @State hasEmergencyDetailData: boolean = false;
  @State emergencyInfoTitle: string =
    EmergencyCallController.getInstance().formatResourceToString($r('app.string.emergencyInfo'));
  @State isRequestFinish: boolean = false;
  @StorageProp('curBp') curBp: string = '';
  @StorageProp('fontSizeScale') fontSizeScale: number = 1;
  @StorageProp('topAndBottomMarginOnScale') topAndBottomMarginOnScale: string = '';
  @StorageProp('ratio') ratio: number = 0;
  @LocalStorageProp('extensionFlag') extensionFlag: boolean = false;
  @StorageLink('navigationHeight') naviHeight: number = 28;
  @StorageLink('statusBarHeight') statusBarHeight: number = 38;
  @State isEmptyContentScroll: boolean = true;
  private addButtonContentHeight: number = 80;

/*  private navigationMenuItemArray: HdsNavigationMenuContentOptions = {
    value: [
      {
        content: {
          label: $r('app.string.InfoEdit_edits_info'),
          icon: $r('sys.symbol.square_and_pencil'),
          isEnabled: true,
          action: () => {
            // Need judge lock status before edit.
            this.checkLockStatus();
            // UE report click edit symbol
            ReportUtil.getInstance().reportClickEditEmergencyInfo();
          }
        }
      }
    ]
  };*/
  private navigationMenuItemArray: NavigationMenuContentOptions = {
    value: [

      {
          value: $r('app.string.InfoEdit_edits_info'),
          icon: $r('sys.symbol.square_and_pencil'),
          isEnabled: true,
          action: () => {
            // Need judge lock status before edit.
            this.checkLockStatus();
            // UE report click edit symbol
            ReportUtil.getInstance().reportClickEditEmergencyInfo();
          }
        }

    ]
  };

  sosEmergencyHelpStr: string = '';
  bottomTextList: string[] = [];
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
  myRouter(name: string) {
    if (name === 'EmergencyInfoEdit') {
      EmergencyInfoEdit();
    } else if (name === 'EmergencyContactsInfo') {
      EmergencyContactsInfo();
    } else if (name === 'EmergencyContactsEdit') {
      EmergencyContactsEdit();
    }
  }

  aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear');
    if (isTablet() && !call.hasVoiceCapability()) {
      return
    }
    const context = getContext();
    this.sosEmergencyHelpStr = context.resourceManager.getStringSync($r('app.string.Sos_emergency_title').id);
    const warnInfoStr = context.resourceManager.getStringSync($r('app.string.warnInfo', '').id,
      this.sosEmergencyHelpStr);
    let tempLIst = warnInfoStr.split(this.sosEmergencyHelpStr);
    tempLIst.splice(1, 0, this.sosEmergencyHelpStr);
    this.bottomTextList = tempLIst.filter(v => (Boolean(v)));
  }

  routerPathChange() {
    LogUtils.i(TAG, 'routerPathChange');
    let pathSize: number = this.pathInfos.size();
    if (pathSize === 0) {
      this.destinationShow();
    }
  }

  updateEmergencyDetailFlag() {
    if (!this.emergencyInfo.bloodType &&
      !this.emergencyInfo.allergicReaction &&
      !this.emergencyInfo.drug &&
      !this.emergencyInfo.isOrganDonor &&
      !this.emergencyInfo.drugStatusAndNotice) {
      this.hasEmergencyDetailData = false;
    } else {
      this.hasEmergencyDetailData = true;
    }
  }

  async destinationShow() {
    LogUtils.i(TAG, 'destinationShow');
    storageUtil.getEmergencyInfoData((data) => {
      let keys: string[] = Object.keys(data);
      if (keys.length === 0) {
        this.hasEmergencyInfo = false;
        this.emergencyInfo = {
          name: '',
          address: '',
          bloodType: '',
          allergicReaction: '',
          drug: '',
          isOrganDonor: '',
          drugStatusAndNotice: ''
        };
      } else {
        this.hasEmergencyInfo = true;
        this.emergencyInfo = {
          name: data['name'] || '',
          address: data['address'] || '',
          bloodType: data['bloodType'] || '',
          allergicReaction: data['allergicReaction'] || '',
          drug: data['drug'] || '',
          isOrganDonor: data['isOrganDonor'] || '',
          drugStatusAndNotice: data['drugStatusAndNotice'] || '',
        };
      }
      this.updateEmergencyDetailFlag();
    });
    const data = await ContactsService.getInstance().syncAndGetEmergencyContactsFromDatabase(getContext());
    this.emergencyContacts = data;
    this.isRequestFinish = true;
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
    .padding({
      left: 48,
      right: $r('sys.float.padding_level6')
    })
  }
  @Builder
  MyCustomTitle() {
    if(this.hasPersonalInformation() || this.hasEmergencyDetailData || this.emergencyContacts.length > 0){
      TitleBarLayout(this.emergencyInfoTitle,$r('sys.color.background_secondary'),
        this.navigationMenuItemArray)
    }else {
      TitleBarLayout(this.emergencyInfoTitle,$r('sys.color.background_secondary'),{value: []})
    }
  }

  async onPageShow(): Promise<void> {
    LogUtils.i(TAG, 'onPageShow');
    this.emergencyContacts = await ContactsService.getInstance().syncAndGetEmergencyContactsFromDatabase(getContext());
  }

  build() {
  /*  HdsNavigation(this.pathInfos) {
      GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: 24 }) {
        GridCol({ span: { xs: 2, sm: 4, md: this.extensionFlag ? 8 : 6, lg: this.extensionFlag ? 12 : 8 },
          offset: { md: this.extensionFlag ? 0 : 1, lg: this.extensionFlag ? 0 : 2 } }) {
          if (this.hasPersonalInformation() || this.hasEmergencyDetailData || this.emergencyContacts.length > 0) {
            this.emergencyAllItem()
          } else {
            if (this.isRequestFinish) {
              this.emergencyInfoItem()
            }
          }
        }
      }
    }*/
    Navigation(this.pathInfos) {
      if(this.hasPersonalInformation() || this.hasEmergencyDetailData || this.emergencyContacts.length > 0 ){
        EditableTitleBar({
          title:this.emergencyInfoTitle,
          isSaveIconRequired:false,
          menuItems:[
            {
              value:$r('sys.symbol.square_and_pencil'),
              isEnabled: true,
              action: () => {
                // Need judge lock status before edit.
                this.checkLockStatus();
                // UE report click edit symbol
                ReportUtil.getInstance().reportClickEditEmergencyInfo();
              }
            }
          ],
          onCancel:()=>{
            this.onBackPress()
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
            this.onBackPress()
          },
        })
          .margin({start:LengthMetrics.vp(24), end:LengthMetrics.vp(24)})
      }
      GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: 24 }) {
        GridCol({ span: { xs: 2, sm: 4, md: this.extensionFlag ? 8 : 6, lg: this.extensionFlag ? 12 : 8 },
          offset: { md: this.extensionFlag ? 0 : 1, lg: this.extensionFlag ? 0 : 2 } }) {
          if (this.hasPersonalInformation() || this.hasEmergencyDetailData || this.emergencyContacts.length > 0) {
            this.emergencyAllItem()
          } else {
            if (this.isRequestFinish) {
              this.emergencyInfoItem()
            }
          }
        }
      }
      .layoutWeight(1)
    }
    .mode(NavigationMode.Stack)
    .navDestination(this.myRouter)
    //.titleMode(HdsNavigationTitleMode.MINI)
    //.titleMode(NavigationTitleMode.Mini)
/*    .titleBar((this.hasPersonalInformation() || this.hasEmergencyDetailData || this.emergencyContacts.length > 0) ?
      TitleParams.MiniTitleParams(this.emergencyInfoTitle, $r('sys.color.background_secondary'),
        this.navigationMenuItemArray) :
      TitleParams.MiniTitleParams(this.emergencyInfoTitle, $r('sys.color.background_secondary')))*/
    //.title(this.MyCustomTitle)
    .hideTitleBar(true)
    .backgroundColor($r('sys.color.background_secondary'))
  }

  private hasPersonalInformation(): boolean {
    if (!this.emergencyInfo.name && !this.emergencyInfo.address) {
      return false;
    }
    return true;
  }

  @Builder
  NavMenu() {
    Column() {
      EditMenu({
        onClickCallBack: () => {
          // Need judge lock status before edit.
          this.checkLockStatus();
          // UE report click edit symbol
          ReportUtil.getInstance().reportClickEditEmergencyInfo();
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
  emergencyAllItem() {
    List() {
      SubHeader({ secondaryTitle: $r('app.string.personalInfo') })
        .visibility(!this.emergencyInfo.name && !this.emergencyInfo.address ?
        Visibility.None : Visibility.Visible)
        .margin({ start: LengthMetrics.vp(-16) })
      this.personInfoEditItem();
      SubHeader({ secondaryTitle: $r('app.string.medicalInfo') })
        .visibility(this.hasEmergencyDetailData ? Visibility.Visible : Visibility.None)
        .margin({ start: LengthMetrics.vp(-16) })
      this.ListCollection()
      if (this.emergencyContacts.length > 0) {
        SubHeader({ secondaryTitle: $r('app.string.emergencyContacts') })
          .margin({ start: LengthMetrics.vp(-16) })
        if (this.fontSizeScale < 1.45) {
          this.emergencyItem();
        } else {
          this.fontScaleItemBuilder();
        }
      }
      this.urgentInformation();
    }
    .clipContent(ContentClipMode.SAFE_AREA)
    .safeAreaPadding({ top: TITLE_BAR_HEIGHT_MINI + this.statusBarHeight + 8 })
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
    .padding({ bottom: $r('sys.float.padding_level12') })
    .layoutWeight(1)
    .margin({
      left: CallColumnUtils.getInstance().getPaddingSpace(this.curBp, this.extensionFlag),
      right: CallColumnUtils.getInstance().getPaddingSpace(this.curBp, this.extensionFlag)
    })
  }

  @Builder
  ListCollection() {
    ListItemGroup() {
      this.bloodItem();
      this.allergiesItem();
      this.drugItem();
      this.drugStatusItem();
    }
    .width('100%')
    .emergencyInfoGroup()
    .visibility(this.hasEmergencyDetailData ? Visibility.Visible : Visibility.None)
  }

  @Builder emergencyInfoItem() {
    Scroll() {
      Column() {
        this.emergencyInfoItemContentBuilder()
      }
      .margin({ top: TITLE_BAR_HEIGHT_MINI + this.statusBarHeight })
    }
    .scrollBar(BarState.Off)
    .onSizeChange((oldValue: SizeOptions, newValue: SizeOptions)=> {
      if (this.fontSizeScale < 1.75) {
        return;
      }
      if ((Number(newValue.height) - this.addButtonContentHeight) < 70) {
        if (this.isEmptyContentScroll) {
          this.isEmptyContentScroll = false;
        }
      } else {
        if (!this.isEmptyContentScroll) {
          this.isEmptyContentScroll = true;
        }
      }
    })
  }

  @Builder
  emergencyInfoItemContentBuilder() {
    if (this.isEmptyContentScroll) {
      Scroll() {
        this.emptyContentBuilder();
      }.layoutWeight(1)
    } else {
      this.emptyContentBuilder();
    }

    Column() {
      Button() {
        Text($r('app.string.add'))
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
        this.checkLockStatus();
        // UE report click add button
        ReportUtil.getInstance().reportClickAddEmergencyInfo();
      });
    }
    .margin({ top: 24, bottom: 16 + this.naviHeight,
      left: CallColumnUtils.getInstance().getPaddingSpace(this.curBp, this.extensionFlag),
      right: CallColumnUtils.getInstance().getPaddingSpace(this.curBp, this.extensionFlag) })
    .onSizeChange((oldValue: SizeOptions, newValue: SizeOptions)=> {
      this.addButtonContentHeight = Number(newValue.height) + 40;
    })
  }

  @Builder
  emptyContentBuilder() {
    Column() {
      this.warnContentBuilder();
    }
    .constraintSize({ minHeight: 'calc(100% - 108vp)' })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .margin({
      left: CallColumnUtils.getInstance().getPaddingSpace(this.curBp, this.extensionFlag),
      right: CallColumnUtils.getInstance().getPaddingSpace(this.curBp, this.extensionFlag)
    })
  }

  private jumpToSosEmergencyHelpSettings = () => {
    try {
      this.session?.sendData({
        action: ON_RECEIVE_ACTION_JUMP_TO_SOS_SETTINGS_PAGE,
        uri: ON_RECEIVE_URI_JUMP_TO_SOS_SETTINGS_PAGE,
        bundleName: 'com.ohos.emergencycommunication',
      } as LooseObject);
    } catch (e) {
      LogUtils.e(TAG, `onReceive:Failed to sendData. code: ${e?.code}, message: ${e?.message}`);
    }
  }

  @Builder
  warnContentBuilder() {
    Column() {
      Image($r('app.media.empty_page_info_help'))
        .width(this.curBp === 'sm' || this.curBp === 'xs' ? 120 : 160)
        .constraintSize({ minHeight: this.curBp === 'sm' || this.curBp === 'xs' ? 120 : 160 })
        .draggable(false);
      Text($r('app.string.warnContent'))
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
                this.jumpToSosEmergencyHelpSettings();
              });
          } else {
            Span(item)
              .fontColor($r('sys.color.font_tertiary'))
              .fontWeight(FontWeight.Regular);
          }
        });
      }
      .width('auto')
      .fontSize($r('sys.float.Body_L'))
      .alignSelf(ItemAlign.Start)
      .margin({ top: $r('sys.float.padding_level4') });
    }
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  emergencyItem() {
    ListItemGroup() {
      ListItem() {
        Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
          this.EmergencyContactRowText()
          Row() {
            Text($r('app.string.peopleAdded', this.emergencyContacts.length))
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.Body_M'))
              .fontWeight(FontWeight.Regular);

            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize('24vp')
              .margin({ start: LengthMetrics.resource($r('sys.float.padding_level2')) })
              .fontColor([$r('sys.color.icon_fourth')])
          }
        }
        .padding({
          left: $r('sys.float.padding_level6'),
          right: $r('sys.float.padding_level6'),
          top: $r('sys.float.padding_level2'),
          bottom: $r('sys.float.padding_level2')
        })
        .constraintSize({ minHeight: 56 })
        .width('100%')
        .onClick(() => {
          this.pathInfos.pushPathByName('EmergencyContactsInfo', '');
        });
      }
      .borderRadius($r('sys.float.corner_radius_level8'))
      .stateStyles({
        pressed: this.pressedStyles,
        normal: this.normalStyles
      })
    }
    .width('100%')
    .emergencyInfoGroup()
  }

  @Builder
  fontScaleItemBuilder() {
    ListItemGroup() {
      ListItem() {
        Flex({ alignItems: ItemAlign.Center }) {
          this.emergencyContactBuilder()
        }
        .padding({
          left: $r('sys.float.padding_level6'),
          right: $r('sys.float.padding_level6'),
          top: this.fontSizeScale < 1.75 ? $r('app.float.emc_margin_level17') : this.topAndBottomMarginOnScale,
          bottom: this.fontSizeScale < 1.75 ? $r('app.float.emc_margin_level17') : this.topAndBottomMarginOnScale
        })
      }
      .width('100%')
      .borderRadius({
        bottomLeft: $r('sys.float.corner_radius_level10'),
        bottomRight: $r('sys.float.corner_radius_level10')
      })
      .constraintSize({ minHeight: $r('app.float.emc_wh_level64') })
      .onClick(() => {
        this.pathInfos.pushPathByName('EmergencyContactsInfo', '');
      })
    }
    .emergencyInfoGroup()
  }

  @Builder
  emergencyContactBuilder() {
    Column() {
      SymbolGlyph($r('sys.symbol.person_badge_heart'))
        .fontSize($r('app.float.emc_margin_level12'))
        .fontColor([$r('sys.color.icon_secondary')])
        .draggable(false)
    }
    .width(24)
    .margin({ end: LengthMetrics.resource($r('sys.float.padding_level8')) })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)

    Column() {
      Text($r('app.string.emergencyContact'))
        .width('100%')
        .fontSize($r('sys.float.Body_L'))
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Medium)
        .constraintSize({ minHeight: $r('app.float.emc_height_level11') });

      Row() {
        Text(this.emergencyContacts.length > 0 ?
        $r('app.string.peopleAdded', this.emergencyContacts.length) : $r('app.string.notAdded'))
          .fontSize($r('sys.float.Body_M'))
          .fontColor($r('sys.color.font_secondary'))
          .fontWeight(FontWeight.Regular)
          .constraintSize({ minHeight: $r('app.float.emc_height_level19') })

        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize('24vp')
          .fontColor([$r('sys.color.icon_fourth')])
          .margin({ start: LengthMetrics.resource($r('sys.float.padding_level2')) })
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')
      .margin({ top: $r('sys.float.padding_level1') });
    }
    .margin({ right: $r('sys.float.padding_level0') })
    .layoutWeight(1)
  }

  @Builder
  EmergencyContactRowText() {
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
    }
    .flexGrow(1)
    .justifyContent(FlexAlign.Start)
    .padding({ right: $r('sys.float.padding_level2') })
  }

  @Builder
  drugStatusItem() {
    ListItem() {
      Column() {
        emergencyInfoItem({
          value: this.emergencyInfo.drugStatusAndNotice,
          label: $r('app.string.drugStatus'),
          labelOnly: false,
          placeholder: $r('app.string.noStated'),
          photoUrl: $r('sys.symbol.cross_vial')
        });
      }
      .width('100%');
    }
    .constraintSize({ minHeight: $r('app.float.emc_wh_level64') })
    .visibility(!this.emergencyInfo.drugStatusAndNotice ? Visibility.None : Visibility.Visible)
  }

  @Builder
  drugItem() {
    ListItem() {
      Column() {
        emergencyInfoItem({
          value: this.emergencyInfo.drug,
          label: $r('app.string.drug'),
          labelOnly: false,
          placeholder: $r('app.string.noStated'),
          photoUrl: $r('sys.symbol.drug')
        });
        if (this.emergencyInfo.isOrganDonor || this.emergencyInfo.drugStatusAndNotice) {
          this.DividerItem();
        }
      }
      .width('100%');
    }
    .constraintSize({ minHeight: $r('app.float.emc_wh_level64') })
    .visibility(!this.emergencyInfo.drug ? Visibility.None : Visibility.Visible)
  }

  @Builder
  allergiesItem() {
    ListItem() {
      Column() {
        emergencyInfoItem({
          value: this.emergencyInfo.allergicReaction,
          label: $r('app.string.allergies'),
          labelOnly: false,
          placeholder: $r('app.string.noStated'),
          photoUrl: $r('sys.symbol.nosign')
        });
        if (this.emergencyInfo.drug || this.emergencyInfo.isOrganDonor ||
        this.emergencyInfo.drugStatusAndNotice) {
          this.DividerItem();
        }
      }
      .width('100%');
    }
    .constraintSize({ minHeight: $r('app.float.emc_wh_level64') })
    .visibility(!this.emergencyInfo.allergicReaction ? Visibility.None : Visibility.Visible)
  }

  @Builder
  bloodItem() {
    ListItem() {
      Column() {
        emergencyInfoItem({
          value: this.emergencyInfo.bloodType,
          label: $r('app.string.bloodType'),
          labelOnly: false,
          placeholder: $r('app.string.noStated'),
          photoUrl: $r('sys.symbol.cross_filled_drop')
        });
        if (this.emergencyInfo.allergicReaction || this.emergencyInfo.drug ||
        this.emergencyInfo.isOrganDonor || this.emergencyInfo.drugStatusAndNotice) {
          this.DividerItem();
        }
      }
      .width('100%');
    }
    .constraintSize({ minHeight: $r('app.float.emc_wh_level64') })
    .visibility(!this.emergencyInfo.bloodType ? Visibility.None : Visibility.Visible)
  }

  @Builder
  personInfoEditItem() {
    ListItemGroup() {
      ListItem() {
        Column() {
          emergencyInfoItem({
            value: this.emergencyInfo.name,
            label: $r('app.string.fullName'),
            labelOnly: true,
            placeholder: $r('app.string.fullName'),
            photoUrl: $r('sys.symbol.person')
          });
          if (this.emergencyInfo.address) {
            this.DividerItem();
          }
        }
        .width('100%');
      }
      .constraintSize({ minHeight: 56 })
      .visibility(!this.emergencyInfo.name ? Visibility.None : Visibility.Visible);

      ListItem() {
        Column() {
          emergencyInfoItem({
            value: this.emergencyInfo.address,
            label: $r('app.string.address'),
            labelOnly: false,
            placeholder: $r('app.string.noStated'),
            photoUrl: $r('sys.symbol.local')
          });
        }
        .width('100%');
      }
      .constraintSize({ minHeight: 64 })
      .visibility(!this.emergencyInfo.address ? Visibility.None : Visibility.Visible);
    }
    .width('100%')
    .emergencyInfoGroup()
    .visibility(!this.emergencyInfo.name && !this.emergencyInfo.address ?
    Visibility.None : Visibility.Visible)
  }

  @Builder
  urgentInformation() {
    ListItemGroup() {
      ListItem() {
        Text() {
          ForEach(this.bottomTextList, (item: string) => {
            if (item === this.sosEmergencyHelpStr) {
              Span(item)
                .fontColor($r('sys.color.font_emphasize'))
                .fontWeight(FontWeight.Medium)
                .onClick(() => {
                  this.jumpToSosEmergencyHelpSettings();
                });
            } else {
              Span(item)
                .fontColor($r('sys.color.font_secondary'))
                .fontWeight(FontWeight.Regular);
            }
          });
        }
        .width('auto')
        .fontSize($r('sys.float.Body_M'))
        .margin({
          top: $r('sys.float.padding_level6')
        });
      }
    }
  }

  onBackPress() {
    this.terminateSelfWithResult();
    return true;
  }

  terminateSelfWithResult(): void {
    let session: UIExtensionContentSession = LocalStorage.getShared()
      .get<UIExtensionContentSession>('session') as UIExtensionContentSession;
    session?.terminateSelf();
  }

  private checkLockStatus() {
    CanAddOrEditEmergencyInfo((isUnlock) => {
      if (isUnlock) {
        this.pathInfos.pushPathByName('EmergencyInfoEdit', '');
      }
    })
  }
}
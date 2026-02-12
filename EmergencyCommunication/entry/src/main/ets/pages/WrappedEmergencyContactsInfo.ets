/*
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
import { CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import { call } from '@kit.TelephonyKit';
import { UIExtensionContentSession } from '@kit.AbilityKit';
import LogUtils from '../utils/HiLog';
import { EmergencyContactsInfoContent } from './EmergencyContactsInfo';
import { ContactListStruct, EmergencyContactDialogDataStruct } from '../utils/ClassStruct';
import {
  EDIT_SYMBOL_ICON,
  EmergencyContactsInfoController
} from '../control/EmergencyContactsInfoController';
import commonData from '../data/CommonData';
import { ReportUtil } from '../utils/ReportUtil';
import { ConfirmDialogContent } from '../components/ConfirmDialogContent';
import EmergencyCallController from '../control/EmergencyCallControl';
import { isTablet } from '../utils/DeviceTypeUtils';
import { ContactsService } from '../service/ContactsService';
import EmergencyContactsEdit from './EmergencyContactsEdit';
/*import {
  HdsNavigation,
  HdsNavigationAttribute,
  HdsNavigationMenuContentOptions,
  HdsNavigationTitleMode
} from '@kit.UIDesignKit';*/
import { NavigationMenuContentOptions, TitleBarLayout, TitleParams } from '../base/view/TitleParams';
import { EditableTitleBar, LengthMetrics, TitleBarType } from '@kit.ArkUI';

const TAG = 'WrappedEmergencyContactsInfo';
const storage = LocalStorage.getShared();

@Entry(storage)
@Component
export struct WrappedEmergencyContactsInfo {
  public static readonly currentPage: string = 'WrappedEmergencyContactsInfo';
  @Provide('pathInfos') @Watch('routerPathChange') pathInfos: NavPathStack = new NavPathStack();
  @StorageProp('simOperatorNameSecond') simOperatorNameSecondStr: string = '';
  @StorageProp('simOperatorNameFirst') simOperatorNameFirstStr: string = '';
  @State mEmergencyCallController: EmergencyCallController = EmergencyCallController.getInstance();
  @State emergencyInfoTitle: string =
    EmergencyCallController.getInstance().formatResourceToString($r('app.string.emergencyContact'));
  @State showEmergencyContacts: boolean = false;
  @State emergencyContacts: ContactListStruct[] = [];
  isRunningOfOnAddContactButtonClick = false;
  //@State isContactsShow: boolean = false;
  @State isContactsShow: boolean = true;
  @State dialogData: EmergencyContactDialogDataStruct = {
    title: $r('app.string.emptyStr'),
    contentText: $r('app.string.emptyStr'),
    isWaring: false,
    confirmText: $r('app.string.emptyStr'),
    confirm: () => {
    }
  }

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


  routerPathChange() {
    LogUtils.i(TAG, 'routerPathChange');
    let pathSize: number = this.pathInfos.size();
    if (pathSize === 0) {
      this.destinationPageShow();
    }
  }

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    try {
      //EmergencyCallController.getInstance().getSimOperatorNames(false);
      if (isTablet() && !call.hasVoiceCapability()) {
        return;
      }
    } catch (e) {
      LogUtils.e(TAG, `aboutToAppear error: ${e?.code} ${e?.message}`);
    }
  }

  aboutToDisappear(): void {
    LogUtils.i(TAG, 'aboutToDisappear');
  }

  /*async destinationPageShow() {
    LogUtils.i(TAG, 'destinationPageShow');
    if (this.isRunningOfOnAddContactButtonClick) {
      LogUtils.i(TAG, 'isRunningOfOnAddContactButtonClick, return');
      return;
    }
    this.isContactsShow = false;
    const contacts = await ContactsService.getInstance().syncAndGetEmergencyContactsFromDatabase(getContext());
    this.emergencyContacts = contacts;
    this.checkContactsIsShow();
  };*/
  async destinationPageShow() {
    LogUtils.i(TAG, 'destinationPageShow');
    if (this.isRunningOfOnAddContactButtonClick) {
      LogUtils.i(TAG, 'isRunningOfOnAddContactButtonClick, return');
      return;
    }

    // 修改前：这里会去查数据库，没SIM卡可能会卡死
    //this.isContactsShow = false;
    const contacts = await ContactsService.getInstance().syncAndGetEmergencyContactsFromDatabase(getContext());
    this.emergencyContacts = contacts;
    //this.checkContactsIsShow();

    // 修改后：直接给空数组，并强制刷新状态
    //this.emergencyContacts = []; // 空列表
    this.isContactsShow = true;  // 强制设为 true，配合上面的 Visibility 修改
    this.checkContactsIsShow();  // 更新一下内部状态
  };

  onPageShow(): void {
    LogUtils.i(TAG, 'onPageShow');
    this.destinationPageShow();
  }

  onPageHide(): void {
    LogUtils.i(TAG, 'onPageHide');
  }

  @Builder
  myRouter(name: string) {
    if (name === 'EmergencyContactsEdit') {
      EmergencyContactsEdit();
    }
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
  setIsRunningOfOnAddContactButtonClick = (value: boolean) => {
    this.isRunningOfOnAddContactButtonClick = value;
  }
  setEmergencyContacts = (emergencyContacts: ContactListStruct[]) => {
    this.emergencyContacts = emergencyContacts;
  }
  checkContactsIsShow = () => {
    if (this.emergencyContacts.length > 0) {
      this.showEmergencyContacts = true;
    } else {
      this.showEmergencyContacts = false;
    }
    this.isContactsShow = true;
  }
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
    this.confirmDialog.open();
  }

  onBackPress(): boolean | void {
    LogUtils.i(TAG, 'onBackPress');
    try {
      let session: UIExtensionContentSession = LocalStorage.getShared()
        .get<UIExtensionContentSession>('session') as UIExtensionContentSession;
      session?.sendData({ 'action': 'pop' });
    } catch (e) {
      LogUtils.e(TAG, `onBackPress terminateSelf error: ${e?.code} ${e?.message}`);
    }
    return true;
  }

  build() {
    /* HdsNavigation(this.pathInfos) {
       EmergencyContactsInfoContent({
         showEmergencyContacts: this.showEmergencyContacts,
         emergencyContacts: this.emergencyContacts,
         isRunningOfOnAddContactButtonClick: this.isRunningOfOnAddContactButtonClick,
         previousPage: WrappedEmergencyContactsInfo.currentPage,
         onAddContactButtonClick: () => {
           EmergencyContactsInfoController.onAddContactButtonClick(this.isRunningOfOnAddContactButtonClick,
             this.setIsRunningOfOnAddContactButtonClick, this.emergencyContacts, this.checkContactsIsShow,
             this.setEmergencyContacts, this.showConfirmDialog);
         },
       })
     }*/
    Navigation(this.pathInfos) {
      EditableTitleBar({
        title:this.emergencyInfoTitle,
        contentMargin:{top:LengthMetrics.px(100)},
        isSaveIconRequired: false,
        onCancel:()=>{
          this.onBackPress()
        },
        menuItems:[
          {
            value: $r('app.string.InfoEdit_edits_info'),
            action:()=>{
              EmergencyContactsInfoController.onSquareAndPencilClick(this.pathInfos);
            }
          }
        ]
      })
        .margin({start:LengthMetrics.vp(24)})
      EmergencyContactsInfoContent({
        showEmergencyContacts: this.showEmergencyContacts,
        emergencyContacts: this.emergencyContacts,
        isRunningOfOnAddContactButtonClick: this.isRunningOfOnAddContactButtonClick,
        previousPage: WrappedEmergencyContactsInfo.currentPage,
        onAddContactButtonClick: () => {
          EmergencyContactsInfoController.onAddContactButtonClick(this.isRunningOfOnAddContactButtonClick,
            this.setIsRunningOfOnAddContactButtonClick, this.emergencyContacts, this.checkContactsIsShow,
            this.setEmergencyContacts, this.showConfirmDialog);
        },
      })
    }
    .mode(NavigationMode.Stack)
    .navDestination(this.myRouter)
    //.titleMode(HdsNavigationTitleMode.MINI)
    //.titleMode(NavigationTitleMode.Mini)
    /*    .titleBar(this.showEmergencyContacts || this.emergencyContacts.length > 0 ?
          TitleParams.MiniTitleParams(this.emergencyInfoTitle, $r('sys.color.background_secondary'),
            this.navigationMenuItemArray) :
          TitleParams.MiniTitleParams(this.emergencyInfoTitle, $r('sys.color.background_secondary')))
        .expandSafeArea([SafeAreaType.KEYBOARD, SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])*/
    /*    .title(this.showEmergencyContacts || this.emergencyContacts.length > 0 ?
          TitleParams.MiniTitleParams(this.emergencyInfoTitle, $r('sys.color.background_secondary'),
            this.navigationMenuItemArray) :
          TitleParams.MiniTitleParams(this.emergencyInfoTitle, $r('sys.color.background_secondary')))*/
    //.title(this.MyCustomTitle)
    .hideTitleBar(true)
    .expandSafeArea([SafeAreaType.KEYBOARD, SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .backgroundColor($r('sys.color.background_secondary'))
    //.visibility(this.isContactsShow ? Visibility.Visible : Visibility.None)
    .visibility(Visibility.Visible)
    .id('EmergencyCommunication_pages_WrappedEmergencyContactsInfo');
  }
}
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

import call from '@ohos.telephony.call';
import { LogUtils, ReportUtil, TitleBarLayout, TitleParams } from '@ohos/common/CommonIndex';
import { SubCallForward } from '../components/SubCallForward';
import SubCallForwardData from '../common/struct/SubCallForwardData';
import { checkCellularDataEnabled } from '../model/CellularDataServiceProxy';
import { JumpAbilityUtils } from '../common/utils/JumpAbilityUtils';
import { BusinessError } from '@ohos.base';
import { LengthMetrics } from '@kit.ArkUI';
import CallColumnUtils from '../common/utils/CallColumnUtils';
import { AlertDialog } from '@ohos.arkui.advanced.Dialog';
import { SubDivider } from '../common/components/SubDivider';
import CallSettingVM from '../viewModel/CallSettingVM';
// import { NavDestination,  HdsNavDestinationAttribute, HdsNavDestinationTitleMode } from '@kit.UIDesignKit';

const TAG = 'CallForward';

@Component
export default struct CallForward {
  @Consume('pathInfos') pathInfos: NavPathStack;
  @State slotId: number = 1;
  unconditionalSubData: SubCallForwardData = new SubCallForwardData($r('app.string.Call_forward_unconditional'),
    call.CallTransferType.TRANSFER_TYPE_UNCONDITIONAL, true, undefined, true, false);
  busySubData: SubCallForwardData = new SubCallForwardData($r('app.string.Call_forward_no_busy'),
    call.CallTransferType.TRANSFER_TYPE_BUSY, true, undefined);
  noAnswerSubData: SubCallForwardData = new SubCallForwardData($r('app.string.Call_forward_no_reply'),
    call.CallTransferType.TRANSFER_TYPE_NO_REPLY, true, undefined);
  unreachableSubData: SubCallForwardData = new SubCallForwardData($r('app.string.Call_forward_user_unreachable'),
    call.CallTransferType.TRANSFER_TYPE_NOT_REACHABLE, true, undefined, false, true);
  @State subCallForwardList: SubCallForwardData[] = [];
  @State numberUnconditional: string = '';
  @State numberBusy: string = '';
  @State numberNoAnswer: string = '';
  @State numberUnreachable: string = '';
  @State statusUnconditional: number = -1;
  @State statusBusy: number = -1;
  @State statusNoAnswer: number = -1;
  @State statusUnreachable: number = -1;
  @State activeType: number = -1;
  init: boolean = true;
  isShowDialog: boolean = false;
  @State isCellularDataEnabled: boolean = true;
  @State isUnconditionalClicked: boolean = false;
  @StorageLink('showTipsDialog') @Watch('showTipsDialogAction') showTipsDialog: boolean = false;
  @State tipsDialogTitle: Resource = $r('app.string.Network_response_abnormal');
  @State isBack: boolean = false;
  @StorageProp('curBp') curBp: string = '';
  @StorageProp('ratio') ratio: number = 0;
  // 判断是否使用模态窗口拉起
  @State isFromExternal: boolean = CallSettingVM.getInstance().getIsFromExternal();
  // 判断半模态是否有叉号
  @State isCrossMarkExists: boolean = CallSettingVM.getInstance().getIsFromExternal();
  private mCallColumnUtils: CallColumnUtils = CallColumnUtils.getInstance();
  cellularDataDialog: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      primaryTitle: $r('app.string.open_mobile_data'),
      content: $r('app.string.open_mobile_data_detail'),
      primaryButton: {
        value: $r('app.string.cancel'),
        action: () => {
          this.pathInfos.pop();
          this.cellularDataDialog?.close();
        }
      },
      secondaryButton: {
        value: $r('app.string.go_setting'),
        action: () => {
          JumpAbilityUtils.jumpToSettings();
          this.cellularDataDialog?.close();
          setTimeout(() => {
            this.pathInfos.pop();
          }, 300);
        }
      }
    }),
    autoCancel: false
  })
  @State @Watch('reportDrawnCompleted') asyncTaskCount: number = 0;

  reportDrawnCompleted() {
    ReportUtil.reportDrawnCompleted(this.asyncTaskCount, getContext(this));
  }

  showTipsDialogAction() {
    if (this.showTipsDialog) {
      this.tipsDialogTitle = $r('app.string.networkAnomaly');
      this.openTipsDialogController.open();
      AppStorage.SetOrCreate('showTipsDialog', false);
    }
  }

  aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear');
    this.asyncTaskCount++;
    this.cellularDataEnabled((value: boolean) => {
      LogUtils.i(TAG, 'cellularDataEnabled' + value);
      if (value) {
        this.isCellularDataEnabled = true;
        this.cellularDataDialog.close();
        let obj: Record<string, number> = this.pathInfos.getParamByIndex(0) as Record<string, number>;
        if (obj) {
          this.slotId = obj.slotId;
          this.asyncTaskCount++;
          this.getCallTransfer();
        } else {
          LogUtils.i(TAG, 'aboutToAppear getParams null');
        }
      } else {
        this.isCellularDataEnabled = false;
        this.resetCallForwardStatus();
        this.cellularDataDialog.open();
      }
      this.asyncTaskCount--;
    });
  }

  aboutToDisappear() {
    LogUtils.i(TAG, 'aboutToDisappear');
    this.isBack = true;
  }

  destinationShow() {
    LogUtils.i(TAG, 'destinationShow');
    if (this.init) {
      this.subCallForwardList.push(this.unconditionalSubData, this.busySubData, this.noAnswerSubData,
        this.unreachableSubData)
      this.init = false;
    }
  }

  destinationHide() {
    LogUtils.i(TAG, 'destinationHide');
    AppStorage.SetOrCreate('showTipsDialog', false);
  }

  openTipsDialogController: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: this.tipsDialogTitle,
      primaryButton: {
        value: $r('app.string.gotIt'),
        action: () => {
          this.openTipsDialogController.close();
        }
      }
    }),
    autoCancel: false
  })

  resetCallForwardStatus() {
    this.statusBusy = 0;
    this.statusNoAnswer = 0;
    this.statusUnreachable = 0;
    this.statusUnconditional = 0;
    this.activeType = -1;
  }

  updateState(type: number, state: number) {
    if (state === 1) {
      switch (type) {
        case this.unconditionalSubData.callForwardType:
          this.statusBusy = 0;
          this.statusNoAnswer = 0;
          this.statusUnreachable = 0;
          break;
        case this.busySubData.callForwardType:
          this.statusNoAnswer = 0;
          this.statusUnreachable = 0;
          break;
        case this.noAnswerSubData.callForwardType:
          this.statusUnreachable = 0;
          break;
      }
      this.activeType = type;
      this.isShowDialog = false;
    }
  }

  async getCallTransfer() {
    try {
      LogUtils.i(TAG, 'getCallTransfer');
      let res0 = await this.getCallTransferStatus(this.unconditionalSubData.callForwardType);
      if (res0) {
        this.unconditionalSubData.forwardResult = res0[0];
        this.numberUnconditional = res0[0]?.number;
        this.statusUnconditional = res0[0]?.status;
        this.updateState(this.unconditionalSubData.callForwardType, this.statusUnconditional);
      }

      let res1 = await this.getCallTransferStatus(this.busySubData.callForwardType);
      if (res1) {
        this.busySubData.forwardResult = res1[0];
        this.numberBusy = res1[0]?.number;
        this.statusBusy = res1[0]?.status;
      }

      let res2 = await this.getCallTransferStatus(this.noAnswerSubData.callForwardType);
      if (res2) {
        this.noAnswerSubData.forwardResult = res2[0];
        this.numberNoAnswer = res2[0]?.number;
        this.statusNoAnswer = res2[0]?.status;
      }

      let res3 = await this.getCallTransferStatus(this.unreachableSubData.callForwardType);
      if (res3) {
        this.unreachableSubData.forwardResult = res3[0];
        this.numberUnreachable = res3[0]?.number;
        this.statusUnreachable = res3[0]?.status;
      }
      this.isShowDialog = false;
      this.asyncTaskCount--;
    } catch (error) {
      this.asyncTaskCount--;
      LogUtils.e(TAG, 'getCallTransferStatus error: ' + JSON.stringify(error));
    }
  }

  getCallTransferStatus(type: call.CallTransferType): Promise<Array<call.CallTransferResult>> | undefined {
    LogUtils.i(TAG, 'getCallTransferStatus start type: ' + type);
    if (this.isBack) {
      LogUtils.i(TAG, 'getCallTransferStatus view back return');
      return;
    }
    return new Promise((resolve) => {
      call.getCallTransferInfo(this.slotId, type).then((res) => {
        LogUtils.i(TAG, 'getCallTransferStatus end type: ' + type + ', res: ' + res.status);
        resolve([res]);
      }).catch((error: BusinessError) => {
        LogUtils.e(TAG, 'getCallTransferStatus end type: ' + type + ', error 0: ' + JSON.stringify(error));
        resolve([{
          'status': 0,
          'number': '',
          'startHour': 0,
          'startMinute': 0,
          'endHour': 0,
          'endMinute': 0
        }]);
        if (this.isShowDialog) {
          return;
        }
        this.tipsDialogTitle = $r('app.string.Network_response_abnormal');
        this.openTipsDialogController.open();
        this.isShowDialog = true;
      });
    })
  }

  cellularDataEnabled(callback: (value: boolean) => void) {
    checkCellularDataEnabled().then((res: boolean | BusinessError) => {
      let result: boolean = (typeof res === 'boolean') ? res : false;
      callback(result);
    }).catch((err: BusinessError) => {
      LogUtils.i(TAG, 'checkCellularDataEnabled response error' + JSON.stringify(err));
      callback(false);
    })
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.interactive_click'))
    .padding({
      left: $r('sys.float.padding_level6'),
      right: $r('sys.float.padding_level6')
    })
    .borderRadius($r('sys.float.corner_radius_level7'))
    .constraintSize({ minHeight: $r('app.float.wh_value_48') })
    .opacity(1)
  }

  build() {
    NavDestination() {
      GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: 24 }) {
        GridCol({ span: this.isFromExternal ? { xs: 2, sm: 4, md: 8, lg: 12 } : { xs: 2, sm: 4, md: 6, lg: 8 },
          offset: this.isFromExternal ? 0 : { md: 1, lg: 2 } }) {
          List() {
            ListItemGroup() {
              this.ForEachSubCallForwardData()
            }
            .backgroundColor(this.isFromExternal ? $r('sys.color.comp_background_list_card') :
              $r('sys.color.comp_background_primary'))
            .borderRadius($r('sys.float.corner_radius_level10'))
            .margin({ top: this.isFromExternal ? $r('sys.float.padding_level4') : $r('sys.float.padding_level8') })
          }
          .clip(false)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
          .height('100%')
          .contentEndOffset(44)
        }
      }
      .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .margin({
        left: this.isFromExternal ? $r('sys.float.padding_level8') :
          CallColumnUtils.getInstance().getPaddingSpace(this.curBp),
        right: this.isFromExternal ? $r('sys.float.padding_level8') :
          CallColumnUtils.getInstance().getPaddingSpace(this.curBp)
      })
    }
    .onShown(() => {
      this.destinationShow();
    })
    .onHidden(() => {
      this.destinationHide();
    })
    // .titleBar(TitleParams.MiniTitleParams($r('app.string.Call_forward'),
    //     this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
    //     $r('sys.color.background_secondary'), this.isCrossMarkExists))
    // .titleMode(this.isFromExternal ? HdsHdsNavDestinationTitleMode.MODAL : HdsHdsNavDestinationTitleMode.MINI)
    .title(this.myTitleBar)
    .backgroundColor(this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
    $r('sys.color.background_secondary'))
  }
  @Builder
  myTitleBar(){
    TitleBarLayout($r('app.string.Call_forward'),
      this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
     $r('sys.color.background_secondary'), this.isCrossMarkExists)
  }

  @Builder
  ForEachSubCallForwardData() {
    ForEach(this.subCallForwardList, (item: SubCallForwardData, index?: number) => {
      ListItem() {
        if (index === 0) {
          this.SubCallForwardNumberUnconditional(item)
        } else if (index === 1) {
          this.SubCallForwardNumberBusy(item)
        } else if (index === 2) {
          this.SubCallForwardNumberNoAnswer(item)
        } else if (index === 3) {
          this.SubCallForwardNumberUnreachable(item)
        }
      }
      .borderRadius($r('sys.float.corner_radius_level10'))
    })
  }

  @Builder
  SubCallForwardNumberUnreachable(item: SubCallForwardData) {
    SubCallForward({
      slotId: $slotId,
      subData: item,
      number: $numberUnreachable,
      status: $statusUnreachable,
      activeType: $activeType,
      isCellularDataEnabled: $isCellularDataEnabled,
      isUnconditionalClicked: $isUnconditionalClicked
    })
      .margin({ bottom: $r('sys.float.padding_level2') })
      .constraintSize({ minHeight: 48 })
  }

  @Builder
  SubCallForwardNumberNoAnswer(item: SubCallForwardData) {
    Column() {
      SubCallForward({
        slotId: $slotId,
        subData: item,
        number: $numberNoAnswer,
        status: $statusNoAnswer,
        activeType: $activeType,
        isCellularDataEnabled: $isCellularDataEnabled,
        isUnconditionalClicked: $isUnconditionalClicked
      });
      SubDivider();
    }
    .constraintSize({ minHeight: 48 })
  }

  @Builder
  SubCallForwardNumberBusy(item: SubCallForwardData) {
    Column() {
      SubCallForward({
        slotId: $slotId,
        subData: item,
        number: $numberBusy,
        status: $statusBusy,
        activeType: $activeType,
        isCellularDataEnabled: $isCellularDataEnabled,
        isUnconditionalClicked: $isUnconditionalClicked
      });
      SubDivider();
    }
    .constraintSize({ minHeight: 48 })
  }

  @Builder
  SubCallForwardNumberUnconditional(item: SubCallForwardData) {
    Column() {
      SubCallForward({
        slotId: $slotId,
        subData: item,
        number: $numberUnconditional,
        status: $statusUnconditional,
        activeType: $activeType,
        isCellularDataEnabled: $isCellularDataEnabled,
        isUnconditionalClicked: $isUnconditionalClicked
      });
      SubDivider();
    }
    .margin({ top: $r('sys.float.padding_level2') })
    .constraintSize({ minHeight: 48 })
  }
}
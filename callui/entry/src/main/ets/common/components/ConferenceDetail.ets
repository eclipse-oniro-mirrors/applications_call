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

/**
 * @file: User list component
 */

import CallStateConst from '../constant/CallStateConst';
import CallServiceProxy from '../../model/CallServiceProxy';
import LogUtils from '../utils/LogUtils';
import DefaultCallData from '../struct/TypeUtils';
import { BusinessError } from '@ohos.base';
import CallColumnUtils from '../utils/CallColumnUtils';
import { ReportUtil } from '../utils/ReportUtils/ReportUtil';
import { AlertDialog } from '@ohos.arkui.advanced.Dialog';
import { getCallLabelPrimary } from '../utils/CallLabelUtils';
import Utils from '../utils/utils';
import { LengthMetrics } from '@kit.ArkUI';
import { StringUtil } from '../utils/StringUtil';
import { AccessibilityUtil } from '../utils/AccessiblityUtil';

const TAG = 'ConferenceDetail';
const prefixLog = 'callUI app:@ohos.telephony.call:';

@Component
export struct ConferenceDetail {
  scroller: Scroller = new Scroller();
  @Link @Watch('callListChange') callList: Array<DefaultCallData>;
  @Link showConferenceDetail: boolean;
  @Link callListCount: number;
  @State mainCallId: number = -1;
  @State memberList: Array<DefaultCallData> = [];
  @StorageProp('curBp') curBp: string = '';
  @StorageLink('isNewFoldPhoneExternalScreen') isNewFoldPhoneExternalScreen: boolean = false;
  private mCallServiceProxy: CallServiceProxy = CallServiceProxy.getInstance();

  public aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    this.getMainCallId();
    this.callListChange();
    ReportUtil.getInstance().reportMultiCallEnterParticipantList();
  }

  /**
   * when call list data change
   *
   * @return {void}
   */
  private callListChange() {
    const tempMemberList: DefaultCallData[] = [];
    let hasComingCall = false;
    for (let i = 0; i < this.callList.length; i++) {
      const tempItem = this.callList[i];
      if (Utils.getInstance().isConferenceCall(tempItem)) {
        tempMemberList.push(tempItem);
      }
      if (tempItem.callState === CallStateConst.callStateObj.CALL_STATUS_WAITING ||
        tempItem.callState === CallStateConst.callStateObj.CALL_STATUS_INCOMING) {
        hasComingCall = true;
      }
    }
    this.memberList = tempMemberList;
    if (this.memberList.length <= 1 || hasComingCall) {
      this.showConferenceDetail = false;
    }
  }

  /**
   * get conference main id
   */
  public getMainCallId() {
    if (!this.callList.length) {
      return;
    }
    let callId = this.callList[0].callId;
    this.mCallServiceProxy.getMainCallId(callId, (mainId: number) => {
      this.mainCallId = mainId;
    });
  }

  /**
   * Hang up call
   *
   * @param {number} callId - callId
   */
  public onHangUp(callId: number) {
    LogUtils.i(TAG, 'onHangUp : ' + callId);
    this.mCallServiceProxy.hangUpCall(callId);
  }

  errorCodeDialogController: CustomDialogController = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.separate_conference_failed'),
      primaryButton: {
        value: $r('app.string.gotIt'),
        fontColor: $r('sys.color.font_emphasize'),
        action: () => {
          LogUtils.i(TAG, prefixLog + 'AlertDialog separateConference action');
          this.errorCodeDialogController.close();
        },
        buttonStyle: ButtonStyleMode.EMPHASIZED
      },
    }),
    autoCancel: false
  })

  /**
   * separate member from conference
   *
   * @param {number} callId - callId
   */
  public onSeparate(callId: number) {
    LogUtils.i(TAG, 'onSeparate : ' + callId);
    this.mCallServiceProxy.separateFromConference(callId, (res: void, err: BusinessError) => {
      if (res !== null) {
        this.showConferenceDetail = false;
      } else if (err !== null) {
        if (err.code === 8300008) {
          this.errorCodeDialogController.open();
        } else {
          Utils.getInstance().showToast(err.message);
        }
      }
    });
    ReportUtil.getInstance().reportMultiCallClickSeparation();
  }

  /**
   * kick out member
   *
   * @param {DefaultCallData} item - callList item
   */
  public onKickOut(item: DefaultCallData) {
    LogUtils.i(TAG, 'onKickOut : ' + item.callId);
    this.mCallServiceProxy.kickOutFromConference(item.callId, () => {
      if (this.callList.length === 1) {
        this.showConferenceDetail = false;
      }
    });
  }

  build() {
    GridRow({ columns: { xs: 2, sm: 4, md: 8, lg: 12 }, gutter: 24 }) {
      GridCol({ span: { xs: 2, sm: 4, md: 6, lg: 8 }, offset: { md: 1, lg: 2 } }) {
        Column() {
          Row() {
            Button() {
              SymbolGlyph($r('sys.symbol.chevron_backward'))
                .fontColor([$r('sys.color.icon_on_primary')])
                .fontSize($r('app.float.wh_value_24'))
                .draggable(false)
            }
            .width($r('app.float.conference_detail_colom_width'))
            .height($r('app.float.conference_detail_colom_width'))
            .borderRadius($r('sys.float.corner_radius_level10'))
            .backgroundColor('#19FFFFFF')
            .accessibilityText($r('app.string.InfoEdit_back'))
            .onClick(() => {
              this.showConferenceDetail = false;
            })
            .id(`conferenceDetail_back`)
            .onAppear(() => {
              AccessibilityUtil.requestFocusForAccessibility('conferenceDetail_back');
            })

            Text($r('app.string.manageUsers'))
              .fontSize($r('app.float.call_conference_detail_titel_font'))
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_on_primary'))
              .height($r('app.float.call_conference_detail_titel_text_height'))
              .margin({ start: LengthMetrics.vp(8) })

          }
          .width('100%')
          .height(64)
          .alignItems(VerticalAlign.Center)
          .padding({
            left: CallColumnUtils.getInstance().getPaddingSpace(this.curBp),
            right: CallColumnUtils.getInstance().getPaddingSpace(this.curBp)
          })
          .margin({ bottom: $r('sys.float.padding_level4') })

          this.buildListFunc()
        }
        .width('100%')
        .height('100%')
      }
    }
  }

  @Builder
  buildListFunc() {
    Column() {
      List({ scroller: this.scroller }) {
        ForEach(this.memberList, (item: DefaultCallData) => {
          ListItem() {
            Row() {
              this.listItemSubRowFunc(item)
            }
            .width('100%')
            .height(64)
            .alignItems(VerticalAlign.Center);
          };
        });
      }
      .divider({ strokeWidth: '1px', color: $r('sys.color.ohos_id_color_list_separator_dark') })
      .width('100%')
      .scrollBar(BarState.Off)
      .listDirection(Axis.Vertical)
      .contentEndOffset(this.isNewFoldPhoneExternalScreen ? 72 : 0)

      Divider().strokeWidth('1px')
        .color($r('sys.color.ohos_id_color_list_separator_dark'))
    }
    .margin({
      left: CallColumnUtils.getInstance().getPaddingSpace(this.curBp),
      right: CallColumnUtils.getInstance().getPaddingSpace(this.curBp)
    })
    .constraintSize({ minHeight: 64 })
  }

  @Builder
  listItemSubRowFunc(item: DefaultCallData) {
    Row() {
      Text(getCallLabelPrimary(item, false))
        .fontSize($r('app.float.call_conference_detail_list_titel_text_font'))
        .fontColor($r('sys.color.font_on_primary'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('60%')

    Row() {
      Row() {
        SymbolGlyph($r('sys.symbol.arrow_triangle_divide'))
          .rotate({ angle: 180 })
          .fontColor([$r('sys.color.icon_on_primary')])
          .fontSize('30vp')
          .draggable(false)
          .opacity((item.callType === CallStateConst.TYPE_CS && this.callListCount === 1) ? 1 : 0.4);
      }
      .width(54)
      .height(54)
      .padding(12)
      .enabled(item.callType === CallStateConst.TYPE_CS && this.callListCount === 1)
      .onClick(() => {
        this.onSeparate(item.callId);
      });

      Row() {
        SymbolGlyph($r('sys.symbol.phone_down_fill'))
          .fontSize($r('app.float.height_answer_btn_30'))
          .fontColor(['#E84026'])
          .width(30)
          .height(30)
          .draggable(false);
      }
      .width(42)
      .height(54)
      .padding({ left: 12, right: 0, top: 12, bottom: 12 })
      .accessibilityRole(AccessibilityRoleType.BUTTON)
      .accessibilityText(StringUtil.formatResourceToString($r('app.string.hangUp')))
      .onClick(() => {
        this.onKickOut(item);
      });

    }
    .height('100%')
    .width('40%')
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.End)
  }
}
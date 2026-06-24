/**
 * Copyright (c) 2024-2024 Huawei Device Co., Ltd.
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
 * @file: Header information display component
 */
import LogUtils from '../../utils/LogUtils';
import { isIncomingCall } from '../../utils/CallListHelper';
import DefaultCallData, { getSimIcon } from '../../struct/TypeUtils';
import CallTimeListStruct from '../../struct/CallTimeListStruct';
import CallListWithConference from './../CallListWithConference';
import ConferenceConst from '../../constant/ConferenceConst';
import { getCallLabelPrimary, getCallLabelSecondary } from '../../utils/CallLabelUtils';
import HiCarCallList from './HiCarCallList';
import Utils from '../../utils/utils';
import CallStateConst from '../../constant/CallStateConst';
import { LengthMetrics } from '@kit.ArkUI';

const TAG = 'HiCarMultiContactCard';

@Component
export default struct HiCarMultiContactCard {
  @StorageLink('TextInput') textInput: string = '';
  @StorageLink('TextInputValue') textInputValue: string = '';
  @Link @Watch('refreshingData') callData: DefaultCallData;
  @Link callState: number;
  @Link callId: number;
  @Link callType: number;
  @Link videoState: number;
  @Link @Watch('callListChange') callList: Array<DefaultCallData>;
  @Link callTimeList: Array<CallTimeListStruct>;
  @Link showConferenceDetail: boolean;
  @Link isShowSim: boolean;
  @Link isIncomingState: boolean;
  @Link hangup: boolean;
  @State isConferenceMode: boolean = false;
  @State callLabelPrimary: Resource | string = '';
  @State callLabelSecondary: string = '';
  @Link accountId: number;

  /**
   * when call list data change
   *
   * @return {void}
   */
  private callListChange(): void {
    let isConferenceMode = false;
    let conferenceMemberCount = 0;
    for (let i = 0; i < this.callList.length; i++) {
      let curCallData = this.callList[i];
      if (Utils.getInstance().isConferenceCall(curCallData)) {
        isConferenceMode = true;
        conferenceMemberCount++;
      }
    }
    if (conferenceMemberCount > 1) {
      this.isConferenceMode = isConferenceMode;
    } else {
      this.isConferenceMode = false;
    }
    if (!this.isConferenceMode) {
      this.showConferenceDetail = this.isConferenceMode;
    }
  }

  aboutToAppear(): void {
    LogUtils.i(TAG, 'aboutToAppear');
    this.refreshingData();
    this.callListChange();
  }

  refreshingData(): void {
    this.callLabelPrimary = getCallLabelPrimary(this.callData)
    this.callLabelSecondary = getCallLabelSecondary(this.callData)
  }

  build() {
    Column() {
      if (this.isConferenceMode) {
        CallListWithConference({
          callList: $callList,
          callData: $callData,
          callTimeList: $callTimeList,
          showConferenceDetail: $showConferenceDetail,
          isShowSim: $isShowSim
        })
      } else {
        HiCarCallList({
          callList: $callList,
          callType: $callType,
          callId: $callId,
          videoState: $videoState,
          callState: $callState,
          callTimeList: $callTimeList,
          hangup: $hangup,
          isShowSim: $isShowSim,
          isIncomingState: $isIncomingState
        })
      }

      if (isIncomingCall(this.callState, true)) {
        Column() {
          Text(this.callLabelPrimary)
            .fontSize(30)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_on_primary'))
            .height(40)
            .margin({
              bottom: '2vp'
            })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .accessibilityText(`${this.callLabelPrimary}`)
            .textAlign(TextAlign.Center)
            .id('callUI_components_HiCarMultiContactCard_ColumnText_getCallLabelPrimary')
          Row() {
            if (this.callType === CallStateConst.TYPE_SATELLITE && isIncomingCall(this.callState) &&
              !this.isShowSim) {
              Image($r('app.media.ic_satellite_call'))
                .margin({ end: LengthMetrics.vp(4) })
                .width(14)
                .height(14)
                .draggable(false)
                .id('callUI_components_HiCarContactCard_rowImage_satellite_call')
            } else {
              this.buildShowSim()
            }

            Text(this.callLabelSecondary)
              .fontSize(16)
              .height(21)
              .lineHeight(21)
              .fontColor($r('sys.color.ohos_id_color_text_secondary_contrary'))
              .visibility(this.callLabelSecondary ? Visibility.Visible : Visibility.None)
              .margin({ bottom: $r('sys.float.padding_level1') })
              .id('callUI_components_HiCarMultiContactCard_ColumnText_getCallLabelSecondary')
          }
          .alignSelf(ItemAlign.Center)
        }
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
  }

  @Builder
  buildShowSim() {
    if (this.isShowSim) {
      if (this.callType === CallStateConst.TYPE_SATELLITE) {
        Image($r('app.media.ic_satellite_call'))
          .margin({ end: LengthMetrics.vp(4) })
          .width(14)
          .height(14)
          .draggable(false)
          .id('callUI_components_HiCarContactCard_rowImage_isShowSim_callType_satellite_call')
      } else {
        SymbolGlyph(getSimIcon(this.accountId))
          .fontColor(['#99FFFFFF'])
          .fontSize(12)
          .width(12)
          .height(12)
          .margin({ end: LengthMetrics.resource($r('sys.float.padding_level2')) })
          .draggable(false)
          .id('callUI_components_HiCarContactCard_rowImage_isShowSim_getSimIcon_accountId')
      }
    }
  }

}
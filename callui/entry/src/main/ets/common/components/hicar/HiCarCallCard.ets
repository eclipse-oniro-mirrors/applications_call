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

import LogUtils from '../../utils/LogUtils';
import DefaultCallData from '../../struct/TypeUtils';
import CallTimeListStruct from '../../struct/CallTimeListStruct';
import HiCarMultiContactCard from './HiCarMultiContactCard';
import HiCarContactCard from './HiCarContactCard';

const TAG = 'HiCarCallCard';

@Component
export default struct HiCarCallCard {
  @Link callList: Array<DefaultCallData>;
  @Link @Watch('refreshingData') callData: DefaultCallData;
  @Link callTimeList: Array<CallTimeListStruct>;
  @Link showConferenceDetail: boolean;
  @Link hangup: boolean;
  @Link isShowSim: boolean;
  @Link isIncomingState: boolean;
  @Prop isShowKeyboard: boolean = false;
  @Prop callListCount: number = 0;
  @Prop translateName: string = '';
  @Prop translateTime: string = '';
  @Prop contactAppear: boolean = false;
  @State callState: number = -1;
  @State callId: number = -1;
  @State accountId: number = -1;
  @State videoState: number = -1;
  @State callType: number = -1;
  @State contactAvatar?: PixelMap | null = null;
  @State conferenceState: number = -1;

  aboutToAppear(): void {
    this.refreshingData();
    LogUtils.i(TAG, 'aboutToAppear');
  }

  refreshingData(): void {
    this.callState = this.callData.callState;
    this.callId = this.callData.callId;
    this.accountId = this.callData.accountId;
    this.videoState = this.callData.videoState;
    this.callType = this.callData.callType;
    this.contactAvatar = this.callData.contactAvatar
    this.conferenceState = this.callData.conferenceState;
  }

  build() {
    GridRow({ columns: { xs: 4, sm: 4, md: 8, lg: 12 }, gutter: 2 }) {
      GridCol({ span: { xs: 4, sm: 4, md: 6, lg: 8 }, offset: { md: 1, lg: 2 } }) {
        Grid() {
          if (this.callListCount > 1) {
            HiCarMultiContactCard({
              callData: $callData,
              callType: $callType,
              videoState: $videoState,
              callState: $callState,
              callId: $callId,
              callList: $callList,
              callTimeList: $callTimeList,
              showConferenceDetail: $showConferenceDetail,
              hangup: $hangup,
              isShowSim: $isShowSim,
              isIncomingState: $isIncomingState,
              accountId: $accountId
            })
          } else {
            HiCarContactCard({
              callData: $callData,
              callState: $callState,
              callId: $callId,
              accountId: $accountId,
              callType: $callType,
              contactAvatar: $contactAvatar,
              conferenceState: $conferenceState,
              isShowKeyboard: this.isShowKeyboard,
              callList: $callList,
              callTimeList: $callTimeList,
              translateName: this.translateName,
              translateTime: this.translateTime,
              contactAppear: this.contactAppear,
              showConferenceDetail: $showConferenceDetail,
              isShowSim: $isShowSim
            })
          }
        }
      }
    }
  }
}
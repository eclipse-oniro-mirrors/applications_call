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
import { SosEmergencyCallController } from '../../control/SosEmergencyCallController';
import { ContactListStruct } from '../../utils/ClassStruct';
import { call } from '@kit.TelephonyKit';
import LogUtils from '../../utils/HiLog';
import { LengthMetrics } from '@kit.ArkUI';
import { ReportUtil } from '../../utils/ReportUtil';
import { AutoDialCallResult, PersonalSafetyReportSosType } from '../../data/CommonData';
import { CAR_ACCIDENT, FALL_DOWN } from '../../utils/Constants';

const TAG = 'SosEmergencyNumberListItem';
@Component
export struct SosEmergencyNumberListItem {
  title?: string | Resource = ''
  @Prop index: number;
  @Prop icon: Resource;
  @Prop item: ContactListStruct;
  itemId: string = ''
  @StorageLink(SosEmergencyCallController.CURRENT_EMERGENCY_CONTACTS_INDEX_KEY) currentEmergencyContactsIndex:
  number | null = null;
  @State personalSafetyCallState: call.DetailedCallState = call.DetailedCallState.CALL_STATUS_IDLE;
  getSosEmergencyNumberListItemBody = (index: number, value: string, callState?: call.DetailedCallState | null,
    callId?: number | null,
    callType?: 'sosCall' | 'carAccident' | 'fallDown' | 'commonCall' | 'commonCallFromSosCall') => {
    LogUtils.i(TAG, 'getSosEmergencyNumberListItemBody');
    if (this.currentEmergencyContactsIndex === index &&
      (callType === 'sosCall' || callType === CAR_ACCIDENT || callType === FALL_DOWN)) {
      if (callState === call.DetailedCallState.CALL_STATUS_DIALING) {
        if (callType === 'sosCall') {
          ReportUtil.getInstance().reportSosCallSuccessOrFail(AutoDialCallResult.SUCCESS);
        }
        this.personalSafetyCallState = call.DetailedCallState.CALL_STATUS_DIALING;
        return $r('app.string.sos_is_auto_calling');
      } else {
        this.personalSafetyCallState = call.DetailedCallState.CALL_STATUS_ACTIVE;
        if (callType === CAR_ACCIDENT || callType === FALL_DOWN) {
          if (callType === CAR_ACCIDENT) {
            ReportUtil.getInstance().reportCrashDialResult('Contact_' + index, PersonalSafetyReportSosType.AUTO,
              AutoDialCallResult.SUCCESS);
          } else if (callType === FALL_DOWN) {
            ReportUtil.getInstance().reportFallDialResult('Contact_' + index, PersonalSafetyReportSosType.AUTO,
              AutoDialCallResult.SUCCESS);
          }
          return $r('app.string.sos_is_playing_recording_1');
        } else {
          return $r('app.string.sos_is_playing_recording');
        }
      }
    } else if (typeof callId === 'number') {
      return $r('app.string.sos_calling_summary');
    } else {
      return (value || '');
    }
  }

  @Builder
  buildPersonalSafetyItem(item: ContactListStruct) {
    Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
      Row() {
        SymbolGlyph(this.personalSafetyCallState === call.DetailedCallState.CALL_STATUS_DIALING ?
        $r('sys.symbol.phone_arrow_up_right_fill') : $r('sys.symbol.phone_fill'))
          .fontSize($r('app.float.emc_padding_level12'))
          .fontColor([$r('sys.color.icon_on_primary')])
          .margin({
            start: LengthMetrics.resource($r('sys.float.padding_level6')),
            end: LengthMetrics.resource($r('sys.float.padding_level8'))
          })
        Text(this.title)
          .fontColor($r('sys.color.font_on_primary'))
          .fontSize('24vp')
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .height('32vp')
          .textAlign(TextAlign.Start)
      }

      Text(this.getSosEmergencyNumberListItemBody(this.index, item.value, item.callState, null, item?.callType))
        .margin({
          top: $r('sys.float.padding_level1'),
          start: LengthMetrics.resource($r('sys.float.padding_level6')),
          end: LengthMetrics.resource($r('sys.float.padding_level6'))
        })
        .fontColor($r('sys.color.font_on_secondary'))
        .fontSize('14vp')
        .fontWeight(FontWeight.Regular)
        .width('100%')
        .height(this.personalSafetyCallState === call.DetailedCallState.CALL_STATUS_DIALING ? 19 :
          (this.personalSafetyCallState === call.DetailedCallState.CALL_STATUS_ACTIVE ? 2 * 19 : 9))
        .textAlign(TextAlign.End)
        .align(Alignment.Center)
    }
  }

  build() {
    if (this.item.callType === CAR_ACCIDENT || this.item.callType === FALL_DOWN) {
      this.buildPersonalSafetyItem(this.item)
    } else {
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Row() {
          SymbolGlyph(this.icon)
            .fontSize($r('app.float.emc_padding_level12'))
            .fontColor([$r('sys.color.icon_on_primary')])
            .margin({
              end: LengthMetrics.vp(16)
            })
            .id(`EmergencyCommunication_pages_index_DefaultListItem_rowImage_answer_${this.itemId}`)
        }
        .flexShrink(0)
        .alignItems(VerticalAlign.Center)

        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center, wrap: FlexWrap.Wrap }) {
          Text(this.title || '')
            .fontColor($r('sys.color.font_on_primary'))
            .fontSize($r('sys.float.Title_M'))
            .maxFontScale(1)
            .fontFamily('HarmonyHeiTi')
            .fontWeight(FontWeight.Medium)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .constraintSize({ minHeight: 32 })
            .margin({ top: LengthMetrics.vp(2), bottom: LengthMetrics.vp(2), end: LengthMetrics.vp(16) })
            .id(`EmergencyCommunication_pages_index_DefaultListItem_Text_value_${this.itemId}`)

          Text(this.getSosEmergencyNumberListItemBody(this.index, this.item.value, this.item.callState,
            this.item?.callId,
            this.item?.callType))
            .fontSize($r('sys.float.Body_M'))
            .fontWeight(FontWeight.Regular)
            .fontFamily('HarmonyHeiTi')
            .direction(Direction.Ltr)
            .maxLines(1)
            .maxFontScale(1)
            .textOverflow({ overflow: TextOverflow.MARQUEE })
            .constraintSize({ minHeight: $r('app.float.emc_padding_level95') })
            .fontColor($r('sys.color.font_on_secondary'))
            .id(`EmergencyCommunication_pages_index_DefaultListItem_Text_label_${this.itemId}`)
        }.constraintSize({ minWidth: '85%' })
      }
      .padding({
        left: 12,
        right: 12,
        top: 16,
        bottom: 16
      })
      .constraintSize({ minHeight: 64 })
    }
  }
}

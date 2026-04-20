/**
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

import call from '@ohos.telephony.call';
import { getCallWaiting } from '../model/CallServiceProxy';
import { CallSettingGlobalContextHelper, LogUtils, TitleBarLayout, TitleParams } from '@ohos/common/CommonIndex';
import prompt from '@system.prompt';
import { SubCallWaiting } from '../components/SubCallWaiting';
import { SystemMode } from '../model/SystemMode';
import { SubSettings } from '../components/SubSettings';
import SubSettingsData from '../common/struct/SubSettingsData';
import { StringUtil } from '../common/utils/StringUtil';
import { BusinessError } from '@ohos.base';
import CallSettingVM from '../viewModel/CallSettingVM';
import { common } from '@kit.AbilityKit';
import * as CallSettingsConstant from '../common/constant/CallSettingsConstant';
import { DisplayUtil } from '../common/utils/DisplayUtil';
// import { NavDestination,  HdsNavDestinationAttribute, HdsNavDestinationTitleMode } from '@kit.UIDesignKit';

const TAG = 'More';

@Component
export default struct More {
  @Consume('pathInfos') pathInfos: NavPathStack;
  @State slotId: number = 1;
  @State callWaitingStatus: number = -1;
  @State isEnable: boolean = true;
  @State newCallingIsEnable: boolean = !SystemMode.getInstance().isModePenglai();
  @State callBarring: SubSettingsData = new SubSettingsData($r('app.string.emptyStr'), true, true);
  @State voiceMail: SubSettingsData = new SubSettingsData($r('app.string.voicemail'), true, false);
  @State airPlaneOn: boolean = false;
  @State moreTitle: Resource = $r('app.string.more');
  @State callText: ResourceStr = $r('app.string.by_time');
  @State radioId: number = 0;
  // 判断是否使用模态窗口拉起
  @State isFromExternal: boolean = CallSettingVM.getInstance().getIsFromExternal();
  // 判断半模态是否有叉号
  @State isCrossMarkExists: boolean = CallSettingVM.getInstance().getIsFromExternal();
  @StorageLink('SearchMorePage') @Watch('showSearchPage') searchSlotId: number = 0;
  @State isSearchPush: boolean = false;

  async aboutToAppear() {
    LogUtils.i(TAG, 'aboutToAppear');
    let obj: Record<string, number> = this.pathInfos.getParamByIndex(0) as Record<string, number>;
    if (obj) {
      this.slotId = obj['slotId'];
      this.getCallWaiting();
    } else {
      LogUtils.e(TAG, 'aboutToAppear getParams null');
    }
    this.setIsSearchPush();
  }

  async showSearchPage() {
    LogUtils.i(TAG, `showSearchPage slotId: ${this.slotId} searchSlotId: ${this.searchSlotId}`);
    if (this.slotId !== this.searchSlotId) {
      this.slotId = this.searchSlotId;
      this.getCallWaiting();
    }
  }

  setIsSearchPush() {
    let param: Record<string, boolean> = this.pathInfos.getParamByIndex(0) as Record<string, boolean>;
    if (param) {
      this.isSearchPush = param['isSearchPush'];
    }
  }

  destinationHide() {
    AppStorage.setOrCreate('isDestinationHide', false);
    LogUtils.i(TAG, 'destinationHide');
  }

  getCallWaiting() {
    getCallWaiting(this.slotId).then((res) => {
      LogUtils.i(TAG, 'callSettings:@ohos.telephony.call:getCallWaiting：then' + JSON.stringify(res));
      if (res != undefined) {
        this.callWaitingStatus = res == call.CallWaitingStatus.CALL_WAITING_ENABLE ? 1 : 0;
      }
    }).catch((error: BusinessError) => {
      LogUtils.e(TAG, 'callSettings:@ohos.telephony.call:getCallWaiting error: ' + JSON.stringify(error));
      this.callWaitingStatus = 0;
      let msg: string = '';
      msg = error.code.toString();
      let showMsg = StringUtil.getErrorMsg(msg);
      prompt.showToast({
        message: (msg && !StringUtil.isEmpty(msg)) ?
        StringUtil.formatResourceToString(showMsg) :
        StringUtil.formatResourceToString($r('app.string.networkAnomaly'))
      });
    });
  }
  @Builder
  myTitleBar() {
    TitleBarLayout($r('app.string.more'),
      this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
      $r('sys.color.background_secondary'),
      this.isCrossMarkExists)
  }

  build() {
    NavDestination() {
      GridRow({
        columns: {
          xs: 2,
          sm: 4,
          md: 8,
          lg: 12
        },
        gutter: 24
      }) {
        GridCol({ span: this.isFromExternal ? { xs: 2, sm: 4, md: 8, lg: 12 } : { xs: 2, sm: 4, md: 6, lg: 8 },
          offset: this.isFromExternal ? 0 : { md: 1, lg: 2 } }) {
          List() {
            ListItemGroup() {
              ListItem() {
                SubCallWaiting({ slotId: $slotId, callWaitingStatus: $callWaitingStatus })
              }

            ListItem() {
              SubSettings({
                slotId: $slotId,
                subData: $voiceMail,
                isEnable: $isEnable,
                airPlaneOn: $airPlaneOn,
                callText: $callText,
                radioId: $radioId
              })
            }
            }.listItemGroupExtend(this.isFromExternal)
          }
          .width('100%')
          .height('100%')
          .backgroundColor(this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
            $r('sys.color.background_secondary'))
          .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
          .clip(false)
        }
      }
    }
    // .titleBar(TitleParams.MiniTitleParams($r('app.string.more'),
    //     this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
    //     $r('sys.color.background_secondary'), this.isCrossMarkExists))
    // .titleMode(this.isFromExternal ? HdsHdsNavDestinationTitleMode.MODAL : HdsHdsNavDestinationTitleMode.MINI)
    .title(this.myTitleBar)
    .backgroundColor(this.isFromExternal ? $r('app.color.color_bind_sheet_background') :
      $r('sys.color.background_secondary'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .onHidden(() => {
      this.destinationHide();
    })
    .onBackPressed(() => {
      LogUtils.i(TAG, 'onBackPressed');
      if (this.isSearchPush) {
        LogUtils.i(TAG, 'onBackPressed SearchPush');
        CallSettingGlobalContextHelper.getContext()
          .getValue<common.UIAbilityContext>(CallSettingsConstant.CALL_SETTING_ABILITY_CONTEXT)
          .terminateSelf();
        return true;
      }
      return false;
    })
  }
}

@Extend(ListItemGroup)
function listItemGroupExtend(isFromExternal = false) {
  .backgroundColor(isFromExternal ? $r('sys.color.comp_background_list_card') :
  $r('sys.color.comp_background_primary'))
  .margin({
    top: isFromExternal ? $r('sys.float.padding_level4') : $r('sys.float.padding_level8'),
    left: $r('sys.float.padding_level8'),
    right: $r('sys.float.padding_level8')
  })
  .padding({ bottom: $r('sys.float.padding_level2') })
  .borderRadius($r('sys.float.padding_level10'))
}

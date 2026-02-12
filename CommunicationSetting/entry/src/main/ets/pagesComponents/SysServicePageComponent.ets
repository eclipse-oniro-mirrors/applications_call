/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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

import { Keys } from '../constants/CommonConstants';
import { SearchInfo } from '../data/SearchData';
import AppInfoListPresenter, { AllAppInfoList } from '../presenter/AppInfoListPresenter';
import StringUtil from '../util/StringUtil';
import myCommon from '@ohos.app.ability.common';
import { isTablet } from '../util/DeviceUtil';
import { LogUtil } from '../util/LogUtil';
import { FontScaleState } from '../util/fontScaleState';
import { LengthMetrics } from '@kit.ArkUI';
import { UIExtensionContentSession } from '@kit.AbilityKit';
import SysServiceListDataSource, { SysAndServiceInfo, SysServiceCategoryManager,
  sysServiceInterface } from '../util/SystemAndServiceUtil';
// import { HdsNavDestination, HdsNavDestinationAttribute } from '@kit.UIDesignKit';
import { TitleParams } from '../view/TitleParams';

const TAG: string = 'SysServicePage';

@Component
export struct SysServicePageComponent {
  name: string = '';
  @Consume('pageInfos') pageInfos: NavPathStack;
  @Consume simSelectedIndexes: number[];
  @Consume modeSelectedIndexes: number[];
  @Consume sysServiceList: Map<number, number>;
  @State appInfoListPresenter: AppInfoListPresenter = AppInfoListPresenter.getInstance();
  private storage = LocalStorage.getShared();
  private trafficCallback = (data: AllAppInfoList) => {
    if (!data) {
      LogUtil.info(TAG, 'trafficCallback getAllAppTraffics data is empty.');
      return;
    }
    this.sysServiceList = data.sysServiceList;
    this.updateUiData();
  };
  @StorageProp('fontSizeScale') fontSizeScale: number = 0;
  private sysServiceListDataSource = new SysServiceListDataSource();
  scroller: Scroller = new Scroller;
  private naviHeight: number = 0;

  aboutToAppear(): void {
    let searchInfo = this.storage?.get<SearchInfo>(Keys.SEARCH_INFO);
    if (searchInfo && searchInfo?.isSystemAndServices()) {
      if (searchInfo?.slotId !== undefined && !searchInfo?.isSlotIdDefault()) {
        this.simSelectedIndexes[0] = searchInfo.slotId;
      }
      if (searchInfo?.networkType !== undefined && searchInfo?.isNetworkTypeValueAble()) {
        this.modeSelectedIndexes[0] = searchInfo?.networkType;
        this.appInfoListPresenter.getAllAppTraffics(searchInfo?.networkType,
          this.simSelectedIndexes[0], this.trafficCallback);
      } else {
        this.appInfoListPresenter.getAllAppTraffics(this.modeSelectedIndexes[0],
          this.simSelectedIndexes[0], this.trafficCallback);
      }
    } else {
      this.updateUiData();
    }
    if (AppStorage.get<number>('naviIndicatorHeight')) {
      this.naviHeight = AppStorage.get<number>('naviIndicatorHeight') as number;
    }
  }

  build() {
    NavDestination() {
      // HdsNavDestination() {
      Stack({ alignContent: Alignment.End }) {
        Column() {
          this.SysInfo()
        }
        .padding({ left: isTablet() ? 24 : 16, right: isTablet() ? 24 : 16, top: 16 })
        .height('100%')
        .width('100%')
        ScrollBar({ scroller: this.scroller, direction: ScrollBarDirection.Vertical, state: BarState.Auto })
          .margin({ top: 12, bottom: 16 + this.naviHeight });
      }
      .height('100%')
      .width('100%')
    }
    .title(TitleParams.MiniTitleParams($r('app.string.system_and_service'),
      $r('sys.color.ohos_id_color_sub_background')))
    .hideBackButton(false)
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    .onBackPressed(() => {
      if (this.storage?.get<SearchInfo>(Keys.SEARCH_INFO)?.isSystemAndServices()) {
        let session: UIExtensionContentSession =
          this.storage?.get<UIExtensionContentSession>('session') as UIExtensionContentSession
        session?.sendData({ 'action': 'pop' })
      } else {
        const popDestinationInfo = this.pageInfos.pop() // 弹出路由栈栈顶元素
        LogUtil.log(TAG, 'pop' + JSON.stringify(popDestinationInfo))
      }
      return true
    })
  }

  @Builder
  normalTitle() {
    Row() {
      Text($r('app.string.system_and_service'))
        .fontWeight(FontWeight.Bold)
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontFamily('HarmonyHeiTi')
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .margin({ start: LengthMetrics.vp(8) })
    }
    .height('100%')
  }

  @Builder
  SysInfo() {
    List({ scroller: this.scroller }) {
      ListItemGroup() {
        LazyForEach(this.sysServiceListDataSource, (item: sysServiceInterface) => {
          this.sysInfoItemLayout(item);
        }, (item: sysServiceInterface) => item.index.toString())
      }
      .width('100%')
      .padding({ top: 4 })
      .margin({ bottom: 16 + this.naviHeight })
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .borderRadius('20vp')
      .divider({
        strokeWidth: '1px',
        startMargin: 12,
        endMargin: 12,
        color: $r('sys.color.ohos_id_color_list_separator')
      })
    }
    .clip(false)
    .scrollBar(BarState.Off)
  }

  @Builder
  sysInfoItemLayout(item: sysServiceInterface) {
    ListItem() {
      if (FontScaleState.isStandardGear(this.fontSizeScale)) {
        this.SysInfoListDetails(item.sysServiceInfo);
      } else {
        this.seniorSysInfoListDetails(item.sysServiceInfo);
      }
    }
  }

  @Builder
  SysInfoListDetails(sysAndServiceInfo: SysAndServiceInfo) {
    Row() {
      Text(sysAndServiceInfo.category)
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Medium)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .constraintSize({
          minHeight: 21
        })
        .layoutWeight(1)
        .margin({end: LengthMetrics.vp(5)})
      Text(sysAndServiceInfo.getFlowText())
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .constraintSize({
          minHeight: 21
        })
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .accessibilityText(StringUtil.convertResourceToString(sysAndServiceInfo.category,
      getContext(this) as myCommon.UIAbilityContext) + sysAndServiceInfo.getFlowText())
    .accessibilityGroup(true)
    .padding({
      left: 12,
      right: 12,
      top: 13.5,
      bottom: 13.5
    })
    .constraintSize({ minHeight: 48 })
    .width('100%')
  }

  @Builder
  seniorSysInfoListDetails(sysAndServiceInfo: SysAndServiceInfo) {
    Flex({
      direction: FontScaleState.isSmallerFourGear(this.fontSizeScale) ? FlexDirection.Row : FlexDirection.Column,
      justifyContent:FontScaleState.isSmallerFourGear(this.fontSizeScale) ? FlexAlign.SpaceBetween : FlexAlign.Start
    }) {
      Text(sysAndServiceInfo.category)
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Medium)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .margin({ right: FontScaleState.isSmallerFourGear(this.fontSizeScale) ? 5 : 0 })
        .flexShrink(1)
      Text(sysAndServiceInfo.getFlowText())
        .fontFamily('HarmonyHeiTi')
        .fontWeight(FontWeight.Regular)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .constraintSize( { maxWidth: FontScaleState.isSmallerFourGear(this.fontSizeScale) ? '60%' : 'auto' })
        .margin({
          top: FontScaleState.isSmallerFourGear(this.fontSizeScale) ? 0 : '2vp'
        })
    }
    .accessibilityGroup(true)
    .accessibilityText(StringUtil.convertResourceToString(sysAndServiceInfo.category,
      getContext(this) as myCommon.UIAbilityContext) + sysAndServiceInfo.getFlowText())
    .padding({
      top: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, '13vp'),
      bottom: FontScaleState.fetchSeniorTopAndBottomSpace(this.fontSizeScale, 0, '14vp'),
      left: 12,
      right: 12
    })
    .constraintSize({ minHeight: '48vp' })
    .width('100%')
  }


  private updateUiData() {
    let sysServiceCategoryManager = new SysServiceCategoryManager(this.sysServiceList);
    this.sysServiceListDataSource.refresh(sysServiceCategoryManager.sysAndServiceArray);
  }
}

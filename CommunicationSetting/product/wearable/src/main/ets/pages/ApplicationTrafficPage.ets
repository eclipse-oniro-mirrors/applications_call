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

import { ArcList, ArcListItem, ArcListAttribute, ArcListItemAttribute } from '@ohos.arkui.ArcList';
import { ColorMetrics, ComponentContent, LengthMetrics } from '@ohos.arkui.node';
import connection from '@ohos.net.connection';
import StyleConstants from '../constants/StyleConstants';
import { LogUtil } from '../util/LogUtil';
import AppInfoListPresenter from '../presenter/AppInfoListPresenter';
import { AppInfo } from '../viewmodel/AppInfo';
import ItemComponent from '../component/ItemComponent';
import { ResourcesUtils } from '../util/ResourcesUtils';
import { LANGUAGE_CHANGE_EVENT } from '../constants/Constants';

const TAG: string = 'ApplicationTrafficPage: ';

interface SettingContentModel {
  content?: ResourceStr;
  overflow?: TextOverflow;
}

@Builder
function buildText(header: SettingContentModel) {
  Text(header.content)
    .width($r('app.float.traffic_title_width'))
    .fontColor(Color.White)
    .fontFamily(StyleConstants.COMMON_SELECT_FONT_FAMILY)
    .fontWeight(FontWeight.Bold)
    .lineHeight($r('app.float.traffic_title_line_height'))
    .fontSize($r('app.float.traffic_text_font_size'))
    .textAlign(TextAlign.Center)
    .focusable(true)
    .focusOnTouch(true)
    .id('watch_mobile_data_rank')
    .onAppear(() => {
      focusControl.requestFocus('watch_mobile_data_rank')
    })
    .textOverflow({ overflow: header.overflow })
}

/**
 * 应用流量列表页面
 *
 * @since 2024-07-02
 */
@Entry
@Component
struct ApplicationTrafficPage {
  private presenter: AppInfoListPresenter = AppInfoListPresenter.getInstance();
  @State dataList: AppInfo[] = [];
  @State isShowLoading: boolean = true;
  private uiContext: UIContext = this.getUIContext();
  @State header: ComponentContent<Object> | undefined = undefined;

  getHeader(): void {
    LogUtil.info(`${TAG} getHeader`);
    try {
      this.header =
        new ComponentContent(this.uiContext, wrapBuilder(buildText),
          {
            content: $r('app.string.watch_traffic_ranking_the_month'),
            overflow: ResourcesUtils.getTextOverflowSync(getContext(this), $r('app.float.mobile_data_overflow'))
          } as SettingContentModel);
    } catch (error) {
      LogUtil.error(`${TAG} getHeader error: ${error?.message}, code: ${error?.code}`);
    }
  }

  registerHeader(): void {
    LogUtil.info(`${TAG} registerHeader`);
    try {
      getContext(this)?.eventHub?.on(LANGUAGE_CHANGE_EVENT,
        () => {
          LogUtil.info(`${TAG} on_registerHeader`);
          this.getHeader();
        });
    } catch (error) {
      LogUtil.error(`${TAG} registerHeader error: ${error?.message}, code: ${error?.code}`);
    }
  }

  unRegisterHeader(): void {
    try {
      getContext(this)?.eventHub?.off(LANGUAGE_CHANGE_EVENT);
    } catch (error) {
      LogUtil.error(`${TAG} unRegisterHeader error: ${error?.message}, code: ${error?.code}`);
    }
  }

  aboutToAppear() {
    LogUtil.info(`${TAG} aboutToAppear`);
    this.registerHeader();
    this.getHeader();
    this.presenter.getAllAppTraffics(connection.NetBearType.BEARER_CELLULAR, (appInfoArray: AppInfo[]) => {
      this.isShowLoading = false;
      this.dataList = appInfoArray ?? [];
      LogUtil.info(`${TAG} aboutToAppear dataList length: ${this.dataList.length}`);
    })
  }

  aboutToDisappear(): void {
    LogUtil.info(`${TAG} aboutToDisappear`);
    this.unRegisterHeader();
  }

  build() {
    if (this.isShowLoading) {
      this.loading()
    } else {
      if (this.header) {
        this.trafficList()
      }
    }
  }

  @Builder
  noRecord() {
    Text($r('app.string.watch_permission_history_no_record'))
      .width(StyleConstants.FULL_PARENT)
      .constraintSize({
        minHeight: $r('app.float.item_view_min_height')
      })
      .fontColor(Color.White)
      .fontFamily(StyleConstants.COMMON_FONT_FAMILY)
      .fontWeight(FontWeight.Regular)
      .lineHeight($r('app.float.no_record_text_line_height'))
      .fontSize($r('app.float.no_record_text_font_size'))
      .textAlign(TextAlign.Center)
      .margin({
        top: $r('app.float.no_record_text_margin_top')
      })
  }

  @Builder
  loading() {
    Column() {
      LoadingProgress()
        .size({
          width: $r('app.float.loading_progress_size'),
          height: $r('app.float.loading_progress_size')
        })
      Text($r('app.string.watch_loading'))
        .fontColor(Color.White)
        .fontSize($r('app.float.loading_progress_text_size'))
        .fontFamily(StyleConstants.COMMON_SELECT_FONT_FAMILY)
        .fontWeight(FontWeight.Regular)
        .lineHeight($r('app.float.loading_progress_text_line_height'))
        .width($r('app.float.loading_progress_text_width'))
        .textAlign(TextAlign.Center)
    }
    .id('watch_loading')
    .size({
      width: StyleConstants.FULL_PARENT,
      height: StyleConstants.FULL_PARENT
    })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.Black)
  }

  @Builder
  trafficList() {
    ArcList({ header: this.header }) {
      if (this.dataList.length) {
        ForEach(this.dataList, (appInfo: AppInfo) => {
          ArcListItem() {
            ItemComponent({ appInfo: appInfo })
          }
        }, (appInfo: AppInfo) => appInfo.bundleName)
      } else {
        ArcListItem() {
          this.noRecord()
        }
        .autoScale(false)
      }
    }
    .scrollBar(BarState.Auto)
    .scrollBarWidth(LengthMetrics.vp(StyleConstants.SCROLLBAR_WIDTH))
    .scrollBarColor(ColorMetrics.resourceColor($r('app.color.page_scroll_bar_color')))
    .width(StyleConstants.FULL_PARENT)
    .height(StyleConstants.FULL_PARENT)
    .backgroundColor(Color.Black)
  }
}
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
import { AppRankItemComponent } from './AppRankItemComponent';
import router from '@ohos.router';
import AppInfoListDataSource from '../viewmodel/AppInfoListDataSource';
import { AppInfoInterface } from '../viewmodel/type';
import AppInfoListPresenter from '../presenter/AppInfoListPresenter';

@Component
export struct AppRankAreaComponent {
  @State mPresenter: AppInfoListPresenter = AppInfoListPresenter.getInstance();
  @Link modeSelectedIndexes: number[];
  @Consume simSelectedIndexes: number[]
  @Link totalCount: number;
  public showNetworkType: boolean = true

  @Builder
  getAppList(appList: AppInfoListDataSource) {
    List() {
      LazyForEach(appList, (item: AppInfoInterface) => {
        ListItem() {
          AppRankItemComponent({ appInfo: item.appInfo, showNetworkType: this.showNetworkType })
        }
        .width('100%')
        .onClick(() => {
          router.pushUrl({
            url: 'pages/SingleAppPage',
            params: {
              appInfo: item.appInfo,
              slotId: this.simSelectedIndexes[0],
              networkType: this.modeSelectedIndexes[0]
            }
          })
        })
      }, (item: AppInfoInterface) => {
        return item.appInfo.uid?.toString() +
        item.appInfo.flow.toString() + item.appInfo.wifiAccess + item.appInfo.mobileAccess
      })
    }
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.None)
    .nestedScroll({ scrollForward: NestedScrollMode.SELF_FIRST, scrollBackward: NestedScrollMode.PARENT_FIRST })
    .width('100%')
    .padding({
      top: 4,
      bottom: 4,
      right: 4,
      left: 4
    })
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .borderRadius('20vp')
    .divider({
      strokeWidth: '1px',
      startMargin: 64,
      color: $r('sys.color.ohos_id_color_list_separator')
    })
  }

  build() {
    this.getAppList(this.mPresenter.appListShow);
  }
}
/**
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import router from '@system.router';

@Component
export default struct Back {
  @State head: string = '';
  @State isChange: boolean = false;
  @State isShow: boolean = false;
  @State isShow2: boolean = false;

  deleteClick() {
    this.isChange = !this.isChange;
  };

  build() {
    Flex({ alignContent: FlexAlign.Center }) {
      Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
        Image($r('app.media.back'))
          .width('40vp')
          .height('40vp')
          .margin({ right: '10vp' })
          .onClick(() => {
            router.back();
          })
        Text(this.head)
          .fontSize('32vp')
          .fontWeight(500)
      }
      .width('100%')
    }.padding({ left: '24vp', top: '24vp' })
    .width('100%')
    .backgroundColor('#fff')
  }

  aboutToAppear() {
  };

  onPageShow() {
  };

  onPageHide() {
  };
}


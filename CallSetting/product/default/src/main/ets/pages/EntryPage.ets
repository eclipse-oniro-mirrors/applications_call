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
import { UIExtensionContentSession } from '@kit.AbilityKit';
import Index from './Index';

const TAG = 'EntryPage';

@Entry
@Component
struct EntryPage {
  @State isShow: boolean = true;
  @StorageProp('curBp') curBp: string = AppStorage.get('curBp') as string ?? 'sm';
  @StorageProp('showClose') showClose: boolean = true;
  private session: UIExtensionContentSession = AppStorage.get<UIExtensionContentSession>('extensionSession') as
  UIExtensionContentSession;

  aboutToAppear(): void {
    this.session?.setWindowBackgroundColor('#00000000');
  }

  @Builder
  BindSheetBuilder() {
    Column() {
      Index();
    }.height('100%').width('100%')
  }

  build() {
    // 加载通话设置模态窗口
    Column() {
    }.height(0).width(0)
    .backgroundColor('#00000000')
    .bindSheet($$this.isShow, this.BindSheetBuilder(), {
      dragBar: false,
      showClose: this.showClose,
      preferType: this.curBp === 'sm' ? SheetType.BOTTOM : SheetType.CENTER,
      onDisappear: () => {
        if (this.session) {
          this.session.sendData({ 'isClose': true });
        }
      }
    })
  }
}
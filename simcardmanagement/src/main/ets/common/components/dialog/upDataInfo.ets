/*
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
import { getString } from '../../utils/Utils'

@CustomDialog
export default struct UpdataInfo {
  controller: CustomDialogController;
  action: () => void;
  title: any = '';
  cancel: () => void;
  isChange: boolean;

  build() {
    Column() {
      Text($r('app.string.sim_stop_information', `${!this.isChange ? getString($r('app.string.stop_use')) : getString($r('app.string.sim_enabled'))}`, `${getString(this.title)}`))
        .height('98vp')
        .fontWeight(FontWeight.Medium)
        .fontFamily('HarmonyHeiTi')
        .fontSize('20vp')
        .fontColor('rgba(0, 0, 0, 0.9)')
    }
    .alignItems(HorizontalAlign.Start)
    .padding({ left: '24pv' })
    .width('100%')
  }
}
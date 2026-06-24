/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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
import { CustomContentDialog } from '@kit.ArkUI';
import { common, UIExtensionContentSession } from '@kit.AbilityKit';
import { MobileDataViewModel } from '../viewmodel/MobileDataViewModel';
import { AppStorageUtils } from '../util/AppStorageUtils';
import { LogUtil } from '../util/LogUtil';
import { BusinessError } from '@kit.BasicServicesKit';
import DotUtil from '../util/Dot/DotUtils';
import { DisableMobileUsersOperation } from '../util/Dot/DotCommon';

const TAG = 'DisableMobileDataDialogComponent';

@Entry
@Component
export struct DisableMobileDataDialogPage {
  @State viewModel: MobileDataViewModel = new MobileDataViewModel();
  @State dialogText: string | Resource = '';
  private simCount: number = 0;
  private storage: LocalStorage = LocalStorage.getShared();
  private session: UIExtensionContentSession =
    this.storage?.get<UIExtensionContentSession>('session') as UIExtensionContentSession;
  disableMobileDataDialog: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.disable_mobile_data'),
      contentBuilder: () => {
        this.disableMobileDataDialogContent()
      },
      buttons: [
        {
          value: $r('app.string.reopen'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            this.reopen();
          }
        },
        {
          value: $r('app.string.confirm'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            DotUtil.getInstance().reportDisableMobileDataDialog(DisableMobileUsersOperation.OK);
            this.finish();
          }
        }
      ]
    }),
    cancel: () => {
      this.finish();
    },
    autoCancel: false,
    alignment: DialogAlignment.Center,
    maskColor: $r('sys.color.ohos_id_color_mask_thin'),
    backgroundColor: $r('sys.color.ohos_id_color_dialog_bg')
  });
  disableMobileDataDialog2: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.disable_mobile_data'),
      contentBuilder: () => {
        this.disableMobileDataDialogContent()
      },
      buttons: [
        {
          value: $r('app.string.got_it'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            DotUtil.getInstance().reportDisableMobileDataDialog(DisableMobileUsersOperation.OK);
            this.finish();
          }
        },
        {
          value: $r('app.string.reopen_the_current_card'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            this.reopen();
          }
        },
        {
          value: $r('app.string.switch_to_another_card'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            this.switchToOtherSim();
          }
        }
      ]
    }),
    cancel: () => {
      this.finish();
    },
    autoCancel: false,
    alignment: DialogAlignment.Center,
    maskColor: $r('sys.color.ohos_id_color_mask_thin'),
    backgroundColor: $r('sys.color.ohos_id_color_dialog_bg')
  });

  @Builder
  disableMobileDataDialogContent() {
    Scroll() {
      Column() {
        Text(this.dialogText)
          .width('100%')
          .fontSize($r('sys.float.Body_L'))
          .fontColor($r('sys.color.font_primary'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Regular)
      }.width('100%')
    }
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: false })

  }

  aboutToAppear(): void {
    LogUtil.info(TAG, 'aboutToAppear');
    this.simCount = AppStorageUtils.getSimCount();
    if (this.simCount === 1) {
      this.dialogText = $r('app.string.data_traffic_reached_the_limit');
    } else if (this.simCount === 2) {
      this.dialogText = $r('app.string.current_sim_data_traffic_reached_the_limit');
    }
    let slotId = this.storage?.get<number>('slotId');
    if (typeof slotId !== 'undefined') {
      this.viewModel.limitSlotId = slotId;
    }
  }

  build() {
    if (this.simCount === 1) {
      Column(this.disableMobileDataDialog.open())
        .backgroundColor($r('sys.color.ohos_id_color_background_transparent'))
    } else if (this.simCount === 2) {
      Column(this.disableMobileDataDialog2.open())
        .backgroundColor($r('sys.color.ohos_id_color_background_transparent'))
    }
  }

  private finish() {
    try {
      this.session?.terminateSelf()
        .then(() => {
          LogUtil.info(TAG, `finish terminateSelf successfully`);
        }).catch((err: BusinessError) => {
        LogUtil.error(TAG, `finish terminateSelf catch:errCode=${err.code},errMsg=${err.message}`);
      });
    } catch (err) {
      LogUtil.error(TAG, `finish catch:errCode=${err.code},errMsg=${err.message}`);
    }
  }

  private reopen() {
    DotUtil.getInstance().reportDisableMobileDataDialog(DisableMobileUsersOperation.RESTART);
    this.viewModel.reopen()
      .then(() => {
        this.disableMobileDataDialog.close();
        this.finish();
      }).catch((err: BusinessError) => {
      LogUtil.info(TAG, `reopen catch:errCode=${err.code},errMsg=${err.message}`);
      this.disableMobileDataDialog.close();
      this.finish();
    });
  }

  private switchToOtherSim() {
    DotUtil.getInstance().reportDisableMobileDataDialog(DisableMobileUsersOperation.SWITCH_TO_ANOTHER_CARD);
    this.startSimCardManagement();
  }

  private startSimCardManagement() {
    let context = getContext(this) as common.UIAbilityContext;
    if (context === null || typeof context === 'undefined') {
      LogUtil.error(TAG, `startSimCardManagement context is not available.`);
      this.finish();
      return;
    }
    let want: Want = {
      bundleName: 'com.ohos.settings',
      abilityName: 'com.ohos.settings.MainAbility',
      uri: 'sim_card_management_entry'
    };
    context.startAbility(want).then(() => {
      LogUtil.info(TAG, `startSimCardManagement successfully.`);
      this.finish();
    }).catch((err: BusinessError) => {
      LogUtil.error(TAG, `startSimCardManagement catch:errCode=${err.code},errMsg=${err.message}`);
      this.finish();
    });
  }
}
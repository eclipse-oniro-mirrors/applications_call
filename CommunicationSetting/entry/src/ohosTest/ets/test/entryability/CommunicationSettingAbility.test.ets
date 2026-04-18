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
import { beforeEach, describe, expect, it, MockKit } from '@ohos/hypium';
import CommunicationSettingAbility, {
  GlobalContext
} from '../../../../main/ets/entryability/CommunicationSettingAbility';
import { LogUtil } from '../../../../main/ets/util/LogUtil';
import Window from '@ohos.window'
import { common, ConfigurationConstant, UIExtensionContentSession } from '@kit.AbilityKit';
import { FontScaleState } from '../../../../main/ets/util/fontScaleState';
import { uiExtensionHost, uiExtension, window } from '@kit.ArkUI';
import { SearchInfo } from '../../../../main/ets/data/SearchData';
import { Keys, QueryName, TAG_NAME, UNDERLINE } from '../../../../main/ets/constants/CommonConstants';
import { settingsDataParam } from '../../../../main/ets/model/SettingsDataModel';
import { SLOT_1 } from '../../../../main/ets/util/TrafficPackageUtil';
import SettingsDataService, { resType } from '../../../../main/ets/service/SettingsDataService';
import { dataShare, ValuesBucket } from '@kit.ArkData';
import DataShareHelper from '../../../../main/ets/model/DataShareHelper';
import { DTGlobalContext } from '../../testability/TestAbility';
import WorkFactory, { WorkerType } from '../../../../main/ets/workers/WorkFactory';
import worker from '@ohos.worker';
import { AppInfo } from '../../../../main/ets/viewmodel/AppInfo';

const TAG: string = 'CommunicationSettingAbility';

export default function CommunicationSettingAbilityTest() {
  describe('CommunicationSettingAbilityTest', () => {
    let communicationSettingAbility: CommunicationSettingAbility;
    let want: Want;
    let session: UIExtensionContentSession;
    let context: Context;
    beforeEach(() => {
      communicationSettingAbility = new CommunicationSettingAbility();
      let context: common.UIExtensionContext = {
        config: {
          fontSizeScale: 1
        }
      } as common.UIExtensionContext;
      communicationSettingAbility.context = context;
      want = {
        bundleName: 'com.ohos.communicationsetting',
        moduleName: 'entry',
        parameters: {
          'ability.want.params.IsNotifyOccupiedAreaChange': true,
          'ability.want.params.uiExtensionType': 'sys/commonUI',
          'component.startup.newRules': true,
          'moduleName': 'entry',
          'ohos.aafwk.param.callerAbilityName': 'com.ohos.settings.MainAbility',
          'ohos.aafwk.param.callerAppIdentifier': '5765880207852919475',
          'ohos.aafwk.param.callerBundleName': 'com.ohos.settings',
          'ohos.aafwk.param.callerUid': 20020052,
          'startReason': 'default',
        }
      };
      let rect: window.Rect = {
        left: 0,
        top: 0,
        width: 100,
        height: 100
      };
      let area: window.AvoidArea = {
        visible: false,
        leftRect: rect,
        topRect: rect,
        rightRect: rect,
        bottomRect: rect
      };
      let extensionWindow: uiExtensionHost.UIExtensionHostWindowProxy = {
        getWindowAvoidArea: (type: Window.AvoidAreaType): Window.AvoidArea => {
          return area;
        }
      } as uiExtensionHost.UIExtensionHostWindowProxy;
      session = {
        getUIExtensionHostWindowProxy: () => {
          return extensionWindow
        }
      } as UIExtensionContentSession;
    })
    it('onCreateTest', 0, () => {
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(LogUtil, LogUtil.log);
      communicationSettingAbility.registerFoldStatusChanged();
      communicationSettingAbility.onCreate();
      mocker.verify('log', [TAG, 'onCreate']).once();
      mocker.clear(LogUtil);
    })
    it('onForegroundTest', 0, () => {
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(LogUtil, LogUtil.log);
      communicationSettingAbility.onForeground()
      mocker.verify('log', [TAG, 'onForeground']).once();
      mocker.clear(LogUtil);
    })
    it('onBackgroundTest', 0, () => {
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(LogUtil, LogUtil.log);
      communicationSettingAbility.onBackground()
      mocker.verify('log', [TAG, 'onBackground']).once();
      mocker.clear(LogUtil);
    })
    it('onDestroyTest', 0, () => {
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(LogUtil, LogUtil.log);
      communicationSettingAbility.onDestroy()
      mocker.verify('log', [TAG, 'onDestroy']).once();
      mocker.clear(LogUtil);
    })
    it('onSessionCreateTest', 0, async () => {
      let appInfo = new AppInfo('', -1, 0, 0);
      let session: UIExtensionContentSession = {
        loadContent: (path: string, storage?: LocalStorage): void => {
          appInfo.uid = 1000001;
        },
        getUIExtensionWindowProxy: (): uiExtension.WindowProxy => {
          return {
            getWindowAvoidArea: (type: Window.AvoidAreaType): Window.AvoidArea => {
              return {
                topRect: {
                  left: 0,
                  top: 0,
                  width: 0,
                  height: 0
                }
              } as Window.AvoidArea;
            }
          } as uiExtension.WindowProxy;
        }
      } as UIExtensionContentSession;
      want.abilityName = 'CommunicationSettingAbility';
      let undefineActionData: settingsDataParam = {};
      undefineActionData.KEYWORD = undefined;
      let valueBucket: ValuesBucket = {
        'KEYWORD': TAG_NAME + SLOT_1 + UNDERLINE + QueryName.unlimited_traffic_enable,
        'VALUE': true
      };
      let actionData: settingsDataParam = {};
      actionData.KEYWORD = TAG_NAME + SLOT_1;
      let errorActionData: settingsDataParam = {};
      errorActionData.KEYWORD = 'error';
      let testContext = DTGlobalContext.getContext().getObject('TestContext') as Context;
      SettingsDataService.getInstance().deleteSettingsInfo(errorActionData, () => {
      }, testContext);
      SettingsDataService.getInstance().querySettingsInfoByBeginningCondition(errorActionData, () => {
      }, testContext);
      SettingsDataService.getInstance().querySettingsInfoByEndCondition(errorActionData, () => {
      }, testContext);
      SettingsDataService.getInstance().querySettingsInfo(errorActionData, () => {
      }, testContext);
      SettingsDataService.getInstance().updateSettingsInfo(errorActionData, valueBucket, () => {
      }, testContext);
      SettingsDataService.getInstance().querySettingsInfoByBeginningCondition(undefineActionData, () => {
      }, context);
      SettingsDataService.getInstance().querySettingsInfoByBeginningCondition(undefineActionData, () => {
      }, testContext);
      SettingsDataService.getInstance().querySettingsInfoByEndCondition(undefineActionData, () => {
      }, context);
      SettingsDataService.getInstance().querySettingsInfoByEndCondition(undefineActionData, () => {
      }, testContext);
      SettingsDataService.getInstance().querySettingsInfo(undefineActionData, () => {
      }, context);
      SettingsDataService.getInstance().querySettingsInfo(undefineActionData, () => {
      }, testContext);
      SettingsDataService.getInstance().deleteSettingsInfo(undefineActionData, () => {
      }, context);
      SettingsDataService.getInstance().deleteSettingsInfo(undefineActionData, () => {
      }, testContext);
      SettingsDataService.getInstance().querySettingsInfoByBeginningCondition(actionData, () => {
      }, testContext);
      SettingsDataService.getInstance().querySettingsInfoByEndCondition(actionData, () => {
      }, testContext);
      SettingsDataService.getInstance().querySettingsInfo(actionData, () => {
      }, testContext);
      SettingsDataService.getInstance().deleteSettingsInfo(actionData, () => {
      }, testContext);
      SettingsDataService.getInstance().insertOrUpdate(undefineActionData, valueBucket, () => {
      }, context);
      SettingsDataService.getInstance().insertOrUpdate(undefineActionData, valueBucket, () => {
      }, testContext);
      SettingsDataService.getInstance().updateSettingsInfo(undefineActionData, valueBucket, () => {
      }, context);
      SettingsDataService.getInstance().updateSettingsInfo(undefineActionData, valueBucket, () => {
      }, testContext);
      SettingsDataService.getInstance().insertSettingsInfo(valueBucket, () => {
      }, context);
      SettingsDataService.getInstance().insertSettingsInfo(valueBucket, () => {
      }, testContext);
      GlobalContext.getContext().setObject('DataWorker', WorkFactory.getWorker(WorkerType.DataWorker));
      SettingsDataService.getInstance().insertSettingsInfo(valueBucket, () => {
      }, testContext);
      SettingsDataService.getInstance().deleteSettingsInfo(undefineActionData, () => {
      }, testContext);
      SettingsDataService.getInstance().updateSettingsInfo(undefineActionData, valueBucket, () => {
      }, testContext);
      SettingsDataService.getInstance().querySettingsInfo(undefineActionData, () => {
      }, testContext);
      SettingsDataService.getInstance().querySettingsInfoByBeginningCondition(undefineActionData, () => {
      }, testContext);
      SettingsDataService.getInstance().querySettingsInfoByEndCondition(undefineActionData, () => {
      }, testContext);

      let mocker: MockKit = new MockKit();
      mocker.mockFunc(communicationSettingAbility, communicationSettingAbility.fetchSystemFontSizeScale);
      mocker.mockFunc(communicationSettingAbility, communicationSettingAbility.setSafeAreaInfo);
      communicationSettingAbility.onSessionCreate(want, session);
      communicationSettingAbility.unregisterFoldStatusChanged();
      expect(AppInfo.appInfoChecked(appInfo)).assertFalse();
    })
    it('onSessionDestroyTest', 0, () => {
      let session1: UIExtensionContentSession = {} as UIExtensionContentSession
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(LogUtil, LogUtil.log);
      communicationSettingAbility.onSessionDestroy(session);
      communicationSettingAbility.onSessionDestroy(session1);
      mocker.verify('log', [TAG, 'onSessionDestroy']).times(2);
      mocker.clear(LogUtil);
    })

    it('setSafeAreaInfoTest', 0, () => {
      communicationSettingAbility.setSafeAreaInfo(session);
      expect(AppStorage.get('statusBarHeight')).assertEqual(px2vp(100));
      expect(AppStorage.get('naviIndicatorHeight')).assertEqual(px2vp(100));
    })
    it('fetchSystemFontSizeScaleTest', 0, () => {
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(FontScaleState, FontScaleState.updateAppFontGearSize);
      communicationSettingAbility.fetchSystemFontSizeScale();
      mocker.verify('updateAppFontGearSize', [1]).once();
      mocker.clear(FontScaleState);
    })
    it('handleSearchInfo01', 0, () => {
      let storage: LocalStorage = new LocalStorage();
      // communicationSettingAbility.handleSearchInfo(want, storage);
      let pushParams = '1,-1,-1';
      let params = want.parameters as Record<string, Object>;
      params['pushParams'] = pushParams;
      let path = pushParams.split(',');
      let searchInfo = new SearchInfo(Number.parseInt(path[0]),
        Number.parseInt(path[1]), Number.parseInt(path[2]));
      communicationSettingAbility.handleSearchInfo(want, storage);
      expect(JSON.stringify(storage.get(Keys.SEARCH_INFO))).assertEqual(JSON.stringify(searchInfo))
    })
    it('handleSearchInfo02', 0, () => {
      let storage: LocalStorage = new LocalStorage();
      let pushParams = '2,-1,-1';
      let params = want.parameters as Record<string, Object>;
      params['pushParams'] = pushParams;
      let path = pushParams.split(',');
      let searchInfo = new SearchInfo(Number.parseInt(path[0]),
        Number.parseInt(path[1]), Number.parseInt(path[2]));
      communicationSettingAbility.handleSearchInfo(want, storage);
      expect(JSON.stringify(storage.get(Keys.SEARCH_INFO))).assertEqual(JSON.stringify(searchInfo))
    })
    it('handleSearchInfo03', 0, () => {
      let storage: LocalStorage = new LocalStorage();
      communicationSettingAbility.handleSearchInfo(want, storage);
      let pushParams = '3,-1,-1';
      let params = want.parameters as Record<string, Object>;
      params['pushParams'] = pushParams;
      let path = pushParams.split(',');
      let searchInfo = new SearchInfo(Number.parseInt(path[0]),
        Number.parseInt(path[1]), Number.parseInt(path[2]));
      communicationSettingAbility.handleSearchInfo(want, storage);
      expect(JSON.stringify(storage.get(Keys.SEARCH_INFO))).assertEqual(JSON.stringify(searchInfo))
    })
    it('handleSearchInfo04', 0, () => {
      let storage: LocalStorage = new LocalStorage();
      communicationSettingAbility.handleSearchInfo(want, storage);
      let pushParams = '3,-1';
      let params = want.parameters as Record<string, Object>;
      params['pushParams'] = pushParams;
      communicationSettingAbility.handleSearchInfo(want, storage);
      expect(JSON.stringify(storage.get(Keys.SEARCH_INFO))).assertUndefined();
    })
    it('onConfigurationUpdateTest', 0, () => {
      let mocker: MockKit = new MockKit();
      mocker.mockFunc(FontScaleState, FontScaleState.updateAppFontGearSize);
      communicationSettingAbility.onConfigurationUpdate({
        fontSizeScale: 1,
        colorMode: ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      });
      mocker.verify('updateAppFontGearSize', [1]).once();
      mocker.clear(FontScaleState);
    })
    it('onWindowStageCreateTest', 0, () => {
      let result = false;
      let windowStage: Window.WindowStage = {
        setDefaultDensityEnabled: (value) => {
          result = value;
          expect(result).assertTrue();
        }
      } as Window.WindowStage;
      communicationSettingAbility.onWindowStageCreate(windowStage);
    })
  })
}
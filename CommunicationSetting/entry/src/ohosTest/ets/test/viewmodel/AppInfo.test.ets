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
import { ArgumentMatchers, beforeAll, describe, expect, it, MockKit, when } from '@ohos/hypium'
import { AppInfo } from '../../../../main/ets/viewmodel/AppInfo'
import { DTGlobalContext } from '../../testability/TestAbility'
import myCommon from '@ohos.app.ability.common';
import { IsWiFiOnly } from '../../../../main/ets/util/DeviceUtil';
import {
  ABROAD_BUNDLE_NAME,
  ABROAD_OLD_BUNDLE_NAME,
  ABROAD_TOTAL_UID,
  DROI_BUNDLE_NAME,
  DROI_OLD_BUNDLE_NAME,
  DROI_UID,
  getFlowText,
  ORI_APP_INDEX,
  UNKNOWN_BUNDLE_TYPE
} from '../../../../main/ets/constants/CommonConstants';
import bundleManager from '@ohos.bundle.bundleManager';
import { LogUtil } from '../../../../main/ets/util/LogUtil';
import { policy } from '@kit.NetworkKit';

export default function AppInfoTest() {
  describe('AppInfoTest', () => {
    let context: myCommon.UIAbilityContext;
    let bundleName = 'com.ohos.communicationsetting';
    let uid: number;
    let appIndex: number = 0;
    let bundleType: number = 0;
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
      context = DTGlobalContext.getContext().getObject('TestContext') as myCommon.UIAbilityContext;
      uid = context.applicationInfo.uid;
    })
    it('AppInfoBasicTest', 0, () => {
      let a = new AppInfo(bundleName, uid, appIndex, bundleType);
      expect(AppInfo.appInfoChecked(a)).assertTrue();
      expect(a.bundleName).assertEqual(bundleName);
      expect(a.uid).assertEqual(uid);
      expect(a.flow).assertEqual(0);
      expect(JSON.stringify(a.flowText)).assertEqual(JSON.stringify(['0.00', 'B']));
      expect(a.mobileAccess).assertTrue();
      expect(a.wifiAccess).assertTrue();
    })
    it('appInfoCheckedTest', 0, () => {
      let a = new AppInfo('', -1, 0, 0);
      expect(AppInfo.appInfoChecked(a)).assertFalse();
      a.label = 'app';
      expect(AppInfo.appInfoChecked(a)).assertFalse();
      a.img = undefined;
      expect(AppInfo.appInfoChecked(a)).assertFalse();
      a.img = $r('app.media.app_icon');
      expect(AppInfo.appInfoChecked(a)).assertFalse();
      a.bundleName = 'aa';
      expect(AppInfo.appInfoChecked(a)).assertTrue();
    })
    it('getNetworkText', 0, () => {
      let a = new AppInfo(bundleName, uid, appIndex, bundleType);
      if (IsWiFiOnly()) {
        expect(JSON.stringify(a.getNetworkText())).assertEqual(JSON.stringify($r('app.string.allow_WLAN')));
        a.changeWifiAccess(false, a);
        expect(JSON.stringify(a.getNetworkText())).assertEqual(JSON.stringify($r('app.string.forbid')));
      } else {
        expect(JSON.stringify(a.getNetworkText()))
          .assertEqual(JSON.stringify($r('app.string.allow_mobile_data_and_WLAN')));
        a.changeWifiAccess(false, a);
        expect(JSON.stringify(a.getNetworkText())).assertEqual(JSON.stringify($r('app.string.allow_mobile_data')));
        a.changeMobileAccess(false, a);
        expect(JSON.stringify(a.getNetworkText())).assertEqual(JSON.stringify($r('app.string.forbid')));
        a.changeWifiAccess(true, a);
        expect(JSON.stringify(a.getNetworkText())).assertEqual(JSON.stringify($r('app.string.allow_WLAN')));
      }
    })
    it('AppInfoBasicTest01', 0, () => {
      let bundleName: string = DROI_BUNDLE_NAME;
      let uid: number = DROI_UID;
      let flow: number = 1;
      let appIndex: number = ORI_APP_INDEX;
      let result = AppInfo.createWithFlow(bundleName, uid, flow, appIndex);
      expect(result.bundleName).assertEqual(DROI_BUNDLE_NAME);
      expect(result.uid).assertEqual(DROI_UID);
      expect(result.appIndex).assertEqual(ORI_APP_INDEX);
      expect(result.bundleType).assertEqual(UNKNOWN_BUNDLE_TYPE);
      expect(result.flow).assertEqual(flow);
      expect(result.flowText).assertDeepEquals(getFlowText(flow));
    })
    it('AppInfoBasicTest02', 0, () => {
      let bundleName: string = ABROAD_BUNDLE_NAME;
      let uid: number = ABROAD_TOTAL_UID;
      let flow: number = 1;
      let appIndex: number = ORI_APP_INDEX;
      let result = AppInfo.createWithFlow(bundleName, uid, flow, appIndex);
      expect(result.bundleName).assertEqual(ABROAD_BUNDLE_NAME);
      expect(result.uid).assertEqual(ABROAD_TOTAL_UID);
      expect(result.appIndex).assertEqual(ORI_APP_INDEX);
      expect(result.bundleType).assertEqual(UNKNOWN_BUNDLE_TYPE);
      expect(result.flow).assertEqual(flow);
      expect(result.flowText).assertDeepEquals(getFlowText(flow));
    })
    it('AppInfoBasicTest03', 0, () => {
      let bundleName: string = DROI_OLD_BUNDLE_NAME;
      let uid: number = DROI_UID;
      let flow: number = 1;
      let appIndex: number = ORI_APP_INDEX;
      let result = AppInfo.createWithFlow(bundleName, uid, flow, appIndex);
      expect(result.bundleName).assertEqual(DROI_OLD_BUNDLE_NAME);
      expect(result.uid).assertEqual(DROI_UID);
      expect(result.appIndex).assertEqual(ORI_APP_INDEX);
      expect(result.bundleType).assertEqual(UNKNOWN_BUNDLE_TYPE);
      expect(result.flow).assertEqual(flow);
      expect(result.flowText).assertDeepEquals(getFlowText(flow));
    })
    it('AppInfoBasicTest04', 0, () => {
      let bundleName: string = ABROAD_OLD_BUNDLE_NAME;
      let uid: number = ABROAD_TOTAL_UID;
      let flow: number = 1;
      let appIndex: number = ORI_APP_INDEX;
      let result = AppInfo.createWithFlow(bundleName, uid, flow, appIndex);
      expect(result.bundleName).assertEqual(ABROAD_OLD_BUNDLE_NAME);
      expect(result.uid).assertEqual(ABROAD_TOTAL_UID);
      expect(result.appIndex).assertEqual(ORI_APP_INDEX);
      expect(result.bundleType).assertEqual(UNKNOWN_BUNDLE_TYPE);
      expect(result.flow).assertEqual(flow);
      expect(result.flowText).assertDeepEquals(getFlowText(flow));
    })
    it('appInfoCheckedTest01', 0, () => {
      let app: AppInfo = new AppInfo('', 1, 1, 1);
      let result = AppInfo.appInfoChecked(app);
      expect(result).assertFalse();
    })
    it('appInfoCheckedTest02', 0, () => {
      let app: AppInfo = new AppInfo('bundleName', 1, 1, 1);
      app.img = undefined;
      let result = AppInfo.appInfoChecked(app);
      expect(result).assertFalse();
    });
    it('appInfoCheckedTest03', 0, () => {
      let app: AppInfo = new AppInfo('bundleName', 1, 1, 1);
      app.img = $r('app.media.app_icon');
      let result = AppInfo.appInfoChecked(app);
      expect(result).assertTrue();
    });
    it('appInfoCheckedTest04', 0, () => {
      let app: AppInfo | null = null;
      try {
        let result = AppInfo.appInfoChecked(app!);
        expect(result).assertFalse();
      } catch (e) {
      }
    });
    it('getApplicationInfoTest01', 0, () => {
      let app: AppInfo = new AppInfo('bundleName', -1, 1, -1);
      app.getApplicationInfo();
      expect(app.label).assertEqual('');
      expect(app.bundleType).assertEqual(UNKNOWN_BUNDLE_TYPE);
    });
    it('getApplicationInfoTest02', 0, () => {
      let appInfo: AppInfo = new AppInfo('bundleNameTest', 1, 2, 0);
      appInfo.getApplicationInfo();
      expect(appInfo.bundleType).assertEqual(bundleManager.BundleType.APP);
    });
    it('getApplicationInfoTest03', 0, () => {
      let appInfo: AppInfo = new AppInfo('bundleNameTest', 1, 2, 1);
      appInfo.getApplicationInfo();
      expect(appInfo.label).assertEqual('');
      expect(appInfo.bundleType).assertEqual(bundleManager.BundleType.ATOMIC_SERVICE);
    });
    it('getNetworkText01', 0, () => {
      let appPolicy: policy.NetworkAccessPolicy = {
        allowWiFi: true,
        allowCellular: false
      };
      let appInfo: AppInfo = new AppInfo(DROI_BUNDLE_NAME, DROI_UID, ORI_APP_INDEX, UNKNOWN_BUNDLE_TYPE, appPolicy);
      const result = appInfo.getNetworkText();
      expect(JSON.stringify(result)).assertEqual(JSON.stringify($r('app.string.allow_WLAN')));
    });
    it('getNetworkText02', 0, () => {
      let appPolicy: policy.NetworkAccessPolicy = {
        allowWiFi: false,
        allowCellular: false
      };
      let appInfo: AppInfo = new AppInfo(DROI_BUNDLE_NAME, DROI_UID, ORI_APP_INDEX, UNKNOWN_BUNDLE_TYPE, appPolicy);
      const result = appInfo.getNetworkText();
      expect(JSON.stringify(result)).assertEqual(JSON.stringify($r('app.string.forbid')));
    });
    it('getNetworkText03', 0, () => {
      let appPolicy: policy.NetworkAccessPolicy = {
        allowWiFi: true,
        allowCellular: true
      };
      let appInfo: AppInfo = new AppInfo(DROI_BUNDLE_NAME, DROI_UID, ORI_APP_INDEX, UNKNOWN_BUNDLE_TYPE, appPolicy);
      const result = appInfo.getNetworkText();
      expect(JSON.stringify(result)).assertEqual(JSON.stringify($r('app.string.allow_mobile_data_and_WLAN')));
    });
    it('getNetworkText04', 0, () => {
      let appPolicy: policy.NetworkAccessPolicy = {
        allowWiFi: false,
        allowCellular: true
      };
      let appInfo: AppInfo = new AppInfo(DROI_BUNDLE_NAME, DROI_UID, ORI_APP_INDEX, UNKNOWN_BUNDLE_TYPE, appPolicy);
      const result = appInfo.getNetworkText();
      expect(JSON.stringify(result)).assertEqual(JSON.stringify($r('app.string.allow_mobile_data')));
    });
    it('changeMobileAccessTest01', 0, () => {
      let appPolicy: policy.NetworkAccessPolicy = {
        allowWiFi: false,
        allowCellular: true
      };
      let appInfo1: AppInfo = new AppInfo(DROI_BUNDLE_NAME, DROI_UID, ORI_APP_INDEX, UNKNOWN_BUNDLE_TYPE, appPolicy);
      let appInfo2: AppInfo = new AppInfo(DROI_BUNDLE_NAME, DROI_UID, ORI_APP_INDEX, UNKNOWN_BUNDLE_TYPE, appPolicy);
      appInfo1.mobilePolicyApp = true;
      appInfo2.changeMobileAccess(true, appInfo1);
      expect(appInfo2.mobileAccess).assertTrue();
    });
    it('changeMobileAccessTest02', 0, () => {
      let appPolicy: policy.NetworkAccessPolicy = {
        allowWiFi: false,
        allowCellular: true
      };
      let appInfo1: AppInfo = new AppInfo(DROI_BUNDLE_NAME, DROI_UID, ORI_APP_INDEX, UNKNOWN_BUNDLE_TYPE, appPolicy);
      let appInfo2: AppInfo = new AppInfo(DROI_BUNDLE_NAME, DROI_UID, ORI_APP_INDEX, UNKNOWN_BUNDLE_TYPE, appPolicy);
      appInfo1.mobilePolicyApp = true;
      appInfo2.changeMobileAccess(false, appInfo1);
      expect(appInfo2.mobileAccess).assertTrue();
    });
    it('changeMobileAccessTest03', 0, () => {
      let appPolicy: policy.NetworkAccessPolicy = {
        allowWiFi: false,
        allowCellular: true
      };
      let appInfo1: AppInfo = new AppInfo(DROI_BUNDLE_NAME, DROI_UID, ORI_APP_INDEX, UNKNOWN_BUNDLE_TYPE, appPolicy);
      let appInfo2: AppInfo = new AppInfo(DROI_BUNDLE_NAME, DROI_UID, ORI_APP_INDEX, UNKNOWN_BUNDLE_TYPE, appPolicy);
      appInfo1.mobilePolicyApp = false;
      appInfo2.changeMobileAccess(false, appInfo1);
      expect(appInfo2.mobileAccess).assertFalse();
    });
    it('changeMobileAccessTest04', 0, () => {
      let appPolicy: policy.NetworkAccessPolicy = {
        allowWiFi: false,
        allowCellular: true
      };
      let appInfo1: AppInfo = new AppInfo(DROI_BUNDLE_NAME, DROI_UID, ORI_APP_INDEX, UNKNOWN_BUNDLE_TYPE, appPolicy);
      let appInfo2: AppInfo = new AppInfo(DROI_BUNDLE_NAME, DROI_UID, ORI_APP_INDEX, UNKNOWN_BUNDLE_TYPE, appPolicy);
      appInfo1.mobilePolicyApp = false;
      appInfo2.changeMobileAccess(true, appInfo1);
      expect(appInfo2.mobileAccess).assertTrue();
    });
    it('changeWifiAccessTest01', 0, () => {
      let appPolicy: policy.NetworkAccessPolicy = {
        allowWiFi: false
      };
      let appInfo1: AppInfo = new AppInfo(DROI_BUNDLE_NAME, DROI_UID, ORI_APP_INDEX, UNKNOWN_BUNDLE_TYPE, appPolicy);
      let appInfo2: AppInfo = new AppInfo(DROI_BUNDLE_NAME, DROI_UID, ORI_APP_INDEX, UNKNOWN_BUNDLE_TYPE, appPolicy);
      appInfo1.wlanPolicyApp = true;
      appInfo2.changeWifiAccess(true, appInfo1);
      expect(appInfo2.wifiAccess).assertFalse();
    });
    it('changeWifiAccessTest02', 0, () => {
      let appPolicy: policy.NetworkAccessPolicy = {
        allowWiFi: false
      };
      let appInfo1: AppInfo = new AppInfo(DROI_BUNDLE_NAME, DROI_UID, ORI_APP_INDEX, UNKNOWN_BUNDLE_TYPE, appPolicy);
      let appInfo2: AppInfo = new AppInfo(DROI_BUNDLE_NAME, DROI_UID, ORI_APP_INDEX, UNKNOWN_BUNDLE_TYPE, appPolicy);
      appInfo1.wlanPolicyApp = true;
      appInfo2.changeWifiAccess(false, appInfo1);
      expect(appInfo2.wifiAccess).assertFalse();
    });
    it('checkShowNetworkTypeTest01', 0, () => {
      let appInfo: AppInfo = new AppInfo(DROI_BUNDLE_NAME, DROI_UID, ORI_APP_INDEX, UNKNOWN_BUNDLE_TYPE, {
        allowWiFi: false,
        allowCellular: false
      });
      appInfo.isCompatibleApp = true;
      const result = appInfo.checkShowNetworkType();
      expect(result).assertTrue();
    });
    it('checkShowNetworkTypeTest02', 0, () => {
      let appInfo: AppInfo = new AppInfo(DROI_BUNDLE_NAME, DROI_UID, ORI_APP_INDEX, UNKNOWN_BUNDLE_TYPE, {
        allowWiFi: false,
        allowCellular: false
      });
      appInfo.isCompatibleApp = false;
      const result = appInfo.checkShowNetworkType();
      expect(result).assertTrue();
    });
    it('checkShowNetworkTypeTest03', 0, () => {
      let appInfo: AppInfo = new AppInfo(DROI_OLD_BUNDLE_NAME, DROI_UID, ORI_APP_INDEX, UNKNOWN_BUNDLE_TYPE, {
        allowWiFi: false,
        allowCellular: false
      });
      appInfo.isCompatibleApp = true;
      const result = appInfo.checkShowNetworkType();
      expect(result).assertTrue();
    });
    it('checkShowNetworkTypeTest04', 0, () => {
      let appInfo: AppInfo = new AppInfo(DROI_OLD_BUNDLE_NAME, DROI_UID, ORI_APP_INDEX, UNKNOWN_BUNDLE_TYPE, {
        allowWiFi: false,
        allowCellular: false
      });
      appInfo.isCompatibleApp = false;
      const result = appInfo.checkShowNetworkType();
      expect(result).assertTrue();
    });
    it('checkShowNetworkTypeTest05', 0, () => {
      let appInfo: AppInfo = new AppInfo(ABROAD_BUNDLE_NAME, DROI_UID, ORI_APP_INDEX, UNKNOWN_BUNDLE_TYPE, {
        allowWiFi: false,
        allowCellular: false
      });
      appInfo.isCompatibleApp = true;
      const result = appInfo.checkShowNetworkType();
      expect(result).assertTrue();
    });
    it('checkShowNetworkTypeTest06', 0, () => {
      let appInfo: AppInfo = new AppInfo(ABROAD_BUNDLE_NAME, ABROAD_TOTAL_UID, ORI_APP_INDEX, UNKNOWN_BUNDLE_TYPE, {
        allowWiFi: false,
        allowCellular: false
      });
      appInfo.isCompatibleApp = false;
      const result = appInfo.checkShowNetworkType();
      expect(result).assertTrue();
    });
    it('checkShowNetworkTypeTest07', 0, () => {
      let appInfo: AppInfo =
        new AppInfo('checkShowNetworkTypeTest04', 0, ORI_APP_INDEX, UNKNOWN_BUNDLE_TYPE, {
          allowWiFi: false,
          allowCellular: false
        });
      appInfo.isCompatibleApp = true;
      const result = appInfo.checkShowNetworkType();
      expect(result).assertFalse();
    });
    it('checkShowNetworkTypeTest08', 0, () => {
      let appInfo: AppInfo =
        new AppInfo('checkShowNetworkTypeTest08', 0, ORI_APP_INDEX, UNKNOWN_BUNDLE_TYPE, {
          allowWiFi: false,
          allowCellular: false
        });
      appInfo.isCompatibleApp = false;
      const result = appInfo.checkShowNetworkType();
      expect(result).assertTrue();
    });
  })
}
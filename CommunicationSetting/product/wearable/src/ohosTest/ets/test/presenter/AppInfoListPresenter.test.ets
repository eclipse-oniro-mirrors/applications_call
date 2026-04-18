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

import { ArgumentMatchers, describe, expect, it, MockKit, when } from '@ohos/hypium';
import AppInfoListPresenter from '../../../../main/ets/presenter/AppInfoListPresenter';
import { AppInfo } from '../../../../main/ets/viewmodel/AppInfo';

export default function AppInfoListPresenterTest() {
  describe('AppInfoListPresenterTest', () => {
    it('getInstanceTest', 0, () => {
      let presenter: ESObject = AppInfoListPresenter.getInstance();
      expect(presenter === null).assertFalse();
      presenter.sInstance = undefined;
      expect(AppInfoListPresenter.getInstance() === null).assertFalse();
    });

    it('countFlowsTest', 0, () => {
      let presenter: ESObject = AppInfoListPresenter.getInstance();
      let flows: string =
        '{"1001":{"rxBytes":12325,"txBytes":4783,"rxPackets":22,"txPackets":31},"1098":{"rxBytes":124416,' +
          '"txBytes":81894,"rxPackets":274,"txPackets":499},"1099":{"rxBytes":217064,"txBytes":116770,"rxPackets":546,' +
          '"txPackets":764},"6666":{"rxBytes":21023,"txBytes":15298,"rxPackets":49,"txPackets":55},' +
          '"7023":{"rxBytes":35212,"txBytes":22991,"rxPackets":92,"txPackets":131},"20003":{"rxBytes":31858,' +
          '"txBytes":11731,"rxPackets":56,"txPackets":64}';
      expect(presenter.countFlows(flows)).assertEqual(0);
    });

    it('appTrafficCompareTest', 0, () => {
      let presenter: ESObject = AppInfoListPresenter.getInstance();
      let appInfoOne = new AppInfo('', 1, 0, 0);
      appInfoOne.flow = 0;
      let appInfoTwo = new AppInfo('', -1, 0, 0);
      appInfoTwo.flow = 10;
      expect(presenter.appTrafficCompare(null, appInfoTwo)).assertEqual(0);
      console.info(`appTrafficCompareTest1: ${presenter.appTrafficCompare(appInfoOne, appInfoTwo)}`);
      expect(presenter.appTrafficCompare(appInfoOne, appInfoTwo)).assertEqual(10);
      appInfoTwo.flow = 0;
      console.info(`appTrafficCompareTest2: ${presenter.appTrafficCompare(appInfoOne, appInfoTwo)}`);
      expect(presenter.appTrafficCompare(appInfoOne, appInfoTwo)).assertEqual(0);
    });
    it('transmitAppTrafficInfoTestWhenDataValid', 0, async (done: Function) => {
      let presenter: ESObject = new AppInfoListPresenter();
      let data: ESObject = new Map<string, object>();
      let appInfo = new AppInfo('', -1, 0, 0);
      appInfo.uid = 100001;
      data.set('1', {rxBytes: 100, txBytes: 200});
      presenter.transmitAppTrafficInfo(data);
      expect(AppInfo.appInfoChecked(appInfo)).assertFalse();
      done();
    });
  })
}
/**
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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

import { describe, it, expect, MockKit, when } from '@ohos/hypium';
import CallCardScreen from '../../../../../main/ets/common/utils/CallCardScreen';
import { ScreenInfo } from '../../../../../main/ets/common/struct/CallUiDataStruct';
import { DisplayUtil } from '../../../../../main/ets/common/utils/DisplayUtil';

let setLandscapeOrPortraitSize_Test_01 = () => {
  let ret = CallCardScreen.getInstance().setLandscapeOrPortraitSize(0);
  expect(ret).assertEqual('10');
}

let setLandscapeOrPortraitSize_Test_02 = () => {
  let ret = CallCardScreen.getInstance().setLandscapeOrPortraitSize(1);
  expect(ret).assertEqual('22');
}

let callImageTop_Test_01 = () => {
  let windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  };
  let ret = CallCardScreen.getInstance().callImageTop(false, 0, windowSizeChangeMd, 0);
  expect(typeof ret !== 'string').assertTrue();
}

let callImageTop_Test_02 = () => {
  let mocker = new MockKit();
  let mocFun = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
  when(mocFun)().afterReturn(true);
  let mocFun2 = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
  when(mocFun2)().afterReturn(1);
  let mocFun3 = mocker.mockFunc(CallCardScreen, CallCardScreen.getInstance().getInstanceCallHeight);
  when(mocFun3)().afterReturn('getInstanceCallHeight');
  let windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  };
  let ret = CallCardScreen.getInstance().callImageTop(true, 0, windowSizeChangeMd, 0);
  expect(typeof ret === 'string').assertTrue();
}

let callImageTop_Test_02_1 = () => {
  let mocker = new MockKit();
  let mocFun = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
  when(mocFun)().afterReturn(true);
  let mocFun2 = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
  when(mocFun2)().afterReturn(1);
  let mocFun3 = mocker.mockFunc(CallCardScreen, CallCardScreen.getInstance().getInstanceCallHeight);
  when(mocFun3)().afterReturn('getInstanceCallHeight');
  let windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  };
  let ret = CallCardScreen.getInstance().callImageTop(true, 1, windowSizeChangeMd, 0);
  expect(typeof ret === 'string').assertTrue();
}

let callImageTop_Test_03 = () => {
  let mocker = new MockKit();
  let mocFun = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
  when(mocFun)().afterReturn(true);
  let mocFun2 = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
  when(mocFun2)().afterReturn(2);
  let windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  };
  let ret = CallCardScreen.getInstance().callImageTop(true, 0, windowSizeChangeMd, 0);
  expect(typeof ret === 'string').assertTrue();
}

let callImageTop_Test_04_1 = () => {
  let mocker = new MockKit();
  let mocFun = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
  when(mocFun)().afterReturn(false);
  let mocFun2 = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
  when(mocFun2)().afterReturn(2);
  let windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  };
  let ret = CallCardScreen.getInstance().callImageTop(true, 0, windowSizeChangeMd, 0);
  expect(typeof ret === 'string').assertTrue();
}

let callImageTop_Test_04_2 = () => {
  let mocker = new MockKit();
  let mocFun = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
  when(mocFun)().afterReturn(false);
  let mocFun2 = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
  when(mocFun2)().afterReturn(2);
  let windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  };
  let ret = CallCardScreen.getInstance().callImageTop(true, 1, windowSizeChangeMd, 0);
  expect(typeof ret === 'string').assertTrue();
}

let callImageTop_Test_04_3 = () => {
  let mocker = new MockKit();
  let mocFun = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
  when(mocFun)().afterReturn(true);
  let mocFun2 = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
  when(mocFun2)().afterReturn(10); //10 doesn't mean anything, It can be any number except 1 and 2.
  let windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  };
  let ret = CallCardScreen.getInstance().callImageTop(true, 1, windowSizeChangeMd, 0);
  expect(typeof ret !== 'string').assertTrue();
}

let callLableTop_Test_01 = () => {
  let mocker = new MockKit();
  let mocFun = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
  when(mocFun)().afterReturn(true);
  let mocFun2 = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
  when(mocFun2)().afterReturn(2);
  let ret = CallCardScreen.getInstance().callLableTop(true, 0, true, true);
  expect(typeof ret !== 'string').assertTrue();
}

let callLableTop_Test_02 = () => {
  let mocker = new MockKit();
  let mocFun = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
  when(mocFun)().afterReturn(true);
  let mocFun2 = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
  when(mocFun2)().afterReturn(2);
  let ret = CallCardScreen.getInstance().callLableTop(true, 0, false, true);
  expect(typeof ret !== 'string').assertTrue();
}

let callLableTop_Test_03 = () => {
  let mocker = new MockKit();
  let mocFun = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
  when(mocFun)().afterReturn(true);
  let mocFun2 = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
  when(mocFun2)().afterReturn(2);
  let ret = CallCardScreen.getInstance().callLableTop(true, 1, false, true);
  expect(typeof ret === 'string').assertTrue();
}

let callLableTop_Test_04 = () => {
  let mocker = new MockKit();
  let mocFun = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
  when(mocFun)().afterReturn(true);
  let mocFun2 = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
  when(mocFun2)().afterReturn(2);
  let ret = CallCardScreen.getInstance().callLableTop(true, 1, false, false);
  expect(typeof ret !== 'string').assertTrue();
}

let callLableTop_Test_05 = () => {
  let mocker = new MockKit();
  let mocFun = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
  when(mocFun)().afterReturn(false);
  let mocFun2 = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
  when(mocFun2)().afterReturn(2);
  let ret = CallCardScreen.getInstance().callLableTop(true, 1, false, false);
  expect(typeof ret === 'string').assertTrue();
}

let callLableTop_Test_06 = () => {
  let mocker = new MockKit();
  let mocFun = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
  when(mocFun)().afterReturn(false);
  let mocFun2 = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
  when(mocFun2)().afterReturn(2);
  let ret = CallCardScreen.getInstance().callLableTop(true, 1, false, true);
  expect(typeof ret === 'string').assertTrue();
}

let callLableTop_Test_07 = () => {
  let mocker = new MockKit();
  let mocFun = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
  when(mocFun)().afterReturn(false);
  let mocFun2 = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
  when(mocFun2)().afterReturn(2);
  let ret = CallCardScreen.getInstance().callLableTop(true, 0, false, true);
  expect(typeof ret !== 'string').assertTrue();
}

let callLableTop_Test_08 = () => {
  let mocker = new MockKit();
  let mocFun = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
  when(mocFun)().afterReturn(false);
  let mocFun2 = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
  when(mocFun2)().afterReturn(2);
  let ret = CallCardScreen.getInstance().callLableTop(false, 0, false, true);
  expect(typeof ret !== 'string').assertTrue();
}

let getImageWidth_Test_01 = () => {
  let windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  };
  CallCardScreen.getInstance().getImageWidth($r('app.float.call_avatar_width'), windowSizeChangeMd, 0, '');
  expect(windowSizeChangeMd.width !== 0).assertFalse();
}

let getImageWidth_Test_02 = () => {
  let windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  };
  CallCardScreen.getInstance().getImageWidth($r('app.float.call_avatar_width'), windowSizeChangeMd, 1, '');
  expect(windowSizeChangeMd.height !== 0).assertFalse()
}

let getImageWidth_Test_03 = () => {
  let mocker = new MockKit();
  let mocFun = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
  when(mocFun)().afterReturn(1000);
  let windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  };
  const res = CallCardScreen.getInstance().getImageWidth($r('app.float.call_avatar_width'), windowSizeChangeMd, 1, '');
  expect(res).assertEqual(110);
}

let getInstanceCallHeight_Test = () => {
  let mocker = new MockKit();
  let mocFun = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
  when(mocFun)().afterReturn(10000000);
  let windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  };
  CallCardScreen.getInstance().getInstanceCallHeight($r('app.float.call_avatar_width'), windowSizeChangeMd, 0);
  expect(windowSizeChangeMd.height !== 0).assertFalse();
}

let getInstanceCallWidth_Test = () => {
  let windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  };
  CallCardScreen.getInstance().getInstanceCallWidth($r('app.float.call_avatar_width'), windowSizeChangeMd);
  expect(windowSizeChangeMd.width !== 0).assertFalse();
}

let callImageBottom_Test_01 = () => {
  let windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  };
  CallCardScreen.getInstance().callImageBottom(false, 0, windowSizeChangeMd, 0);
  expect(windowSizeChangeMd.width).assertEqual(0);
}

let callImageBottom_Test_02 = () => {
  let mocker = new MockKit();
  let mocFun = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
  when(mocFun)().afterReturn(false);
  let windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  };
  CallCardScreen.getInstance().callImageBottom(true, 0, windowSizeChangeMd, 0);
  expect(windowSizeChangeMd.height !== 0).assertFalse();
}

let callImageBottom_Test_03 = () => {
  let mocker = new MockKit();
  let mocFun = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
  when(mocFun)().afterReturn(true);
  let mocFun2 = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
  when(mocFun2)().afterReturn(1);
  let windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  };
  CallCardScreen.getInstance().callImageBottom(true, 0, windowSizeChangeMd, 0);
  expect(windowSizeChangeMd.width !== 0).assertFalse();
}

let callImageBottom_Test_04 = () => {
  let mocker = new MockKit();
  let mocFun = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
  when(mocFun)().afterReturn(true);
  let mocFun2 = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
  when(mocFun2)().afterReturn(2);
  let windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  };
  CallCardScreen.getInstance().callImageBottom(true, 0, windowSizeChangeMd, 0);
  expect(windowSizeChangeMd.height !== 0).assertFalse();
}

let callImageBottom_Test_05 = () => {
  let mocker = new MockKit();
  let mocFun = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
  when(mocFun)().afterReturn(true);
  let mocFun2 = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
  when(mocFun2)().afterReturn(8); //8 doesn't mean anything, It can be any number except 1 and 2.
  let windowSizeChangeMd: ScreenInfo = {
    width: 0,
    height: 0
  };
  CallCardScreen.getInstance().callImageBottom(true, 0, windowSizeChangeMd, 0);
  expect(windowSizeChangeMd.width === 0).assertTrue();
}

let isHasFold_Test_01 = () => {
  const res = CallCardScreen.getInstance().isHasFold(1, 0);
  expect(res).assertEqual('5vp');
}

let isHasFold_Test_02 = () => {
  const res = CallCardScreen.getInstance().isHasFold(1, 1);
  expect(res).assertEqual('10vp');
}

let multiContactTop_Test_01 = () => {
  const res = CallCardScreen.getInstance().MultiContactTop(false, 0);
  expect(typeof res === 'object').assertTrue();
}

let multiContactTop_Test_02 = () => {
  let mocker = new MockKit();
  let mocFun = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
  when(mocFun)().afterReturn(true);
  let mocFun2 = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
  when(mocFun2)().afterReturn(2);
  const res = CallCardScreen.getInstance().MultiContactTop(true, 0);
  expect(res).assertEqual('40vp');
}

let multiContactTop_Test_03 = () => {
  let mocker = new MockKit();
  let mocFun = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
  when(mocFun)().afterReturn(true);
  let mocFun2 = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
  when(mocFun2)().afterReturn(2);
  const res = CallCardScreen.getInstance().MultiContactTop(true, 10000);
  expect(res).assertEqual('9990vp');
}

let multiContactTop_Test_04 = () => {
  let mocker = new MockKit();
  let mocFun = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
  when(mocFun)().afterReturn(true);
  let mocFun2 = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
  when(mocFun2)().afterReturn(80);
  const res = CallCardScreen.getInstance().MultiContactTop(true, 0);
  expect(res).assertEqual('0vp');
}

let multiContactTop_Test_05 = () => {
  let mocker = new MockKit();
  let mocFun = mocker.mockFunc(DisplayUtil, DisplayUtil.isFoldable);
  when(mocFun)().afterReturn(true);
  let mocFun2 = mocker.mockFunc(DisplayUtil, DisplayUtil.getScreenFoldStatus);
  when(mocFun2)().afterReturn(80);
  const res = CallCardScreen.getInstance().MultiContactTop(true, 5);
  expect(res).assertEqual('39vp');
}

export default function CallCardScreenTest() {
  describe('CallCardScreenTest', () => {
    it('setLandscapeOrPortraitSize_Test_01', 0, () => {
      setLandscapeOrPortraitSize_Test_01();
    })
    it('setLandscapeOrPortraitSize_Test_02', 0, () => {
      setLandscapeOrPortraitSize_Test_02();
    })
    it('callImageTop_Test_01', 0, () => {
      callImageTop_Test_01();
    })
    it('callImageTop_Test_02', 0, () => {
      callImageTop_Test_02();
    })
    it('callImageTop_Test_02_1', 0, () => {
      callImageTop_Test_02_1();
    })
    it('callImageTop_Test_03', 0, () => {
      callImageTop_Test_03();
    })
    it('callImageTop_Test_04_1', 0, () => {
      callImageTop_Test_04_1();
    })
    it('callImageTop_Test_04_2', 0, () => {
      callImageTop_Test_04_2();
    })
    it('callImageTop_Test_04_3', 0, () => {
      callImageTop_Test_04_3();
    })
    it('callLableTop_Test_01', 0, () => {
      callLableTop_Test_01();
    })
    it('callLableTop_Test_02', 0, () => {
      callLableTop_Test_02();
    })
    it('callLableTop_Test_03', 0, () => {
      callLableTop_Test_03();
    })
    it('callLableTop_Test_04', 0, () => {
      callLableTop_Test_04();
    })
    it('callLableTop_Test_05', 0, () => {
      callLableTop_Test_05();
    })
    it('callLableTop_Test_06', 0, () => {
      callLableTop_Test_06();
    })
    it('callLableTop_Test_07', 0, () => {
      callLableTop_Test_07();
    })
    it('callLableTop_Test_08', 0, () => {
      callLableTop_Test_08();
    })
    it('getImageWidth_Test_01', 0, () => {
      getImageWidth_Test_01();
    })
    it('getImageWidth_Test_02', 0, () => {
      getImageWidth_Test_02();
    })
    it('getImageWidth_Test_03', 0, () => {
      getImageWidth_Test_03();
    })
    it('getInstanceCallHeight_Test', 0, () => {
      getInstanceCallHeight_Test();
    })
    it('getInstanceCallWidth_Test', 0, () => {
      getInstanceCallWidth_Test();
    })
    it('callImageBottom_Test_01', 0, () => {
      callImageBottom_Test_01();
    })
    it('callImageBottom_Test_02', 0, () => {
      callImageBottom_Test_02();
    })
    it('callImageBottom_Test_03', 0, () => {
      callImageBottom_Test_03();
    })
    it('callImageBottom_Test_04', 0, () => {
      callImageBottom_Test_04();
    })
    it('callImageBottom_Test_05', 0, () => {
      callImageBottom_Test_05();
    })
    it('isHasFold_Test_01', 0, () => {
      isHasFold_Test_01();
    })
    it('isHasFold_Test_02', 0, () => {
      isHasFold_Test_02();
    })
    it('multiContactTop_Test_01', 0, () => {
      multiContactTop_Test_01();
    })
    it('multiContactTop_Test_02', 0, () => {
      multiContactTop_Test_02();
    })
    it('multiContactTop_Test_03', 0, () => {
      multiContactTop_Test_03();
    })
    it('multiContactTop_Test_04', 0, () => {
      multiContactTop_Test_04();
    })
    it('multiContactTop_Test_05', 0, () => {
      multiContactTop_Test_05();
    })
  })
}

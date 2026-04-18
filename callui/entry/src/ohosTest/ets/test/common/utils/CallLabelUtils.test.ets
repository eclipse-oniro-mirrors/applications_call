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

import { describe, it, expect } from '@ohos/hypium';
import {
  fileNameString,
  getCallLabelPrimary, getCallLabelSecondary,
  getCallLabelThird,
  getMarkContentResource,
  getNumberMarked,
  } from '../../../../../main/ets/common/utils/CallLabelUtils';
import DefaultCallData, { MarkType } from '../../../../../main/ets/common/struct/TypeUtils';
import { StringUtil } from '../../../../../main/ets/common/utils/StringUtil';

let CallLabelUtilsTest_getCallLabelPrimary_01 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.isEcc = true;
  let result = getCallLabelPrimary(callData);
  expect(result).not().assertUndefined();
}

let CallLabelUtilsTest_getCallLabelPrimary_02 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.isEcc = false;
  callData.contactName = 'test';
  let result = getCallLabelPrimary(callData);
  expect(result).assertEqual(callData.contactName);
}

let CallLabelUtilsTest_getCallLabelPrimary_03 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.isEcc = false;
  callData.contactName = '';
  callData.formatNumber = '12345678910';
  let result = getCallLabelPrimary(callData);
  expect(result).assertEqual(callData.formatNumber);
}

let CallLabelUtilsTest_getCallLabelSecondary_01 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.isEcc = true;
  callData.contactName = '';
  callData.formatNumber = '12345678910';
  let result = getCallLabelSecondary(callData);
  expect(result).assertEqual(callData.formatNumber);
}

let CallLabelUtilsTest_getCallLabelSecondary_02 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.isEcc = false;
  callData.contactName = 'test';
  callData.formatNumber = '12345678910';
  callData.numberLocation = 'test Location';
  let result = getCallLabelSecondary(callData);
  let str = callData.formatNumber + ' ' + callData.numberLocation;
  expect(result).assertEqual(str);
}

let CallLabelUtilsTest_getCallLabelSecondary_03 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.isEcc = false;
  callData.contactName = 'test';
  callData.formatNumber = '12345678910';
  callData.numberLocation = '';
  let result = getCallLabelSecondary(callData);
  expect(result).assertEqual(callData.formatNumber);
}

let CallLabelUtilsTest_getCallLabelSecondary_04 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.isEcc = false;
  callData.contactName = '';
  callData.formatNumber = '\u202a' + '12345678910' + '\u202c';
  callData.numberLocation = 'test Location';
  callData.numberMarkInfo.markType = 0;
  let result = getCallLabelSecondary(callData);
  expect(result).assertContain(callData.numberLocation);
}

let CallLabelUtilsTest_getCallLabelSecondary_05 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.isEcc = false;
  callData.contactName = '';
  callData.formatNumber = '\u202a' + '12345678910' + '\u202c';
  callData.numberLocation = '';
  callData.numberMarkInfo.markType = 0;
  let result = getCallLabelSecondary(callData);
  expect(result).assertContain(callData.formatNumber);
}

let CallLabelUtilsTest_getCallLabelSecondary_06 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.isEcc = false;
  callData.contactName = '';
  callData.formatNumber = '\u202a' + '12345678910' + '\u202c';
  callData.numberLocation = '';
  callData.numberMarkInfo.markType = 2;
  callData.numberMarkInfo.markSource = '5';
  let result = getCallLabelSecondary(callData);
  expect(result).assertContain(callData.formatNumber);
}

let CallLabelUtilsTest_getCallLabelSecondary_07 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.isEcc = false;
  callData.contactName = '';
  callData.formatNumber = '\u202a' + '12345678910' + '\u202c';
  callData.numberLocation = '';
  callData.numberMarkInfo.markType = 11;
  callData.numberMarkInfo.markSource = '5';
  let result = getCallLabelSecondary(callData);
  expect(result).assertContain(callData.formatNumber);
}

let CallLabelUtilsTest_fileNameString_01 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.isEcc = true;
  callData.numberMarkInfo.markType = 10;
  callData.numberMarkInfo.markContent = 'test';
  let result = fileNameString(callData);
  expect(result).assertEqual(callData.numberMarkInfo.markContent);
}

let CallLabelUtilsTest_fileNameString_03 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.isVoiceMailNumber = true;
  let result = fileNameString(callData);
  expect(result).assertEqual(StringUtil.getStringByNameSync('voicemail'));
}

let CallLabelUtilsTest_fileNameString_04 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.isEcc = false;
  callData.contactName = 'test';
  let result = fileNameString(callData);
  expect(result).assertEqual(callData.contactName);
}

let CallLabelUtilsTest_fileNameString_05 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.isEcc = false;
  callData.distributedContactName = 'test';
  let result = fileNameString(callData);
  expect(result).assertEqual(callData.distributedContactName);
}

let CallLabelUtilsTest_fileNameString_06 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.isEcc = false;
  callData.numberMarkInfo.markType = 0;
  callData.numberMarkInfo.markContent = 'test';
  let result = fileNameString(callData);
  expect(result).assertEqual(callData.numberMarkInfo.markContent);
}

let CallLabelUtilsTest_fileNameString_07 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.isEcc = false;
  callData.accountNumber = '123456789';
  let result = fileNameString(callData);
  expect(result).assertEqual(callData.accountNumber);
}

let CallLabelUtilsTest_getCallLabelThird_01 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.contactCompany = 'test'
  let result = getCallLabelThird(callData);
  expect(result).assertEqual(callData.contactCompany);
}

let CallLabelUtilsTest_getCallLabelThird_02 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.contactNote = 'test'
  let result = getCallLabelThird(callData);
  expect(result).assertEqual(callData.contactNote);
}

let CallLabelUtilsTest_getCallLabelThird_03 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.numberMarkInfo.markDetails = 'test'
  let result = getCallLabelThird(callData);
  expect(result).assertEqual(callData.numberMarkInfo.markDetails);
}

let CallLabelUtilsTest_getCallLabelThird_04 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  let result = getCallLabelThird(callData);
  expect(result).assertEqual('');
}

let CallLabelUtilsTest_getNumberMarked_01 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.numberMarkInfo.markType = MarkType.MARK_TYPE_NONE;
  let result = getNumberMarked(callData);
  expect(result).assertEqual('');
}

let CallLabelUtilsTest_getNumberMarked_02 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.numberMarkInfo = {
    markContent: '',
    markType: -1,
    markCount: -1,
    isCloud: true
  };
  let result = getNumberMarked(callData);
  expect(result === null).assertFalse();
}

let CallLabelUtilsTest_getNumberMarked_03 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.numberMarkInfo = {
    markContent: '',
    markType: -1,
    markCount: -1,
    isCloud: false
  };
  let result = getNumberMarked(callData);
  expect(result === null).assertFalse();
}

let CallLabelUtilsTest_getMarkContentResource_01 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.numberMarkInfo = {
    markContent: '',
    markType: MarkType.MARK_TYPE_NONE,
    markCount: -1
  }
  let result = getMarkContentResource(callData);
  expect(result ===null).assertFalse();
}

let CallLabelUtilsTest_getMarkContentResource_02 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  let result = getMarkContentResource(callData);
  expect(result ===null).assertFalse();
}

let CallLabelUtilsTest_getMarkContentResource_03 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.numberMarkInfo = {
    markContent: '',
    markType: MarkType.MARK_TYPE_CRANK,
    markCount: -1
  }
  let result = getMarkContentResource(callData);
  expect(result === null).assertFalse();
}

let CallLabelUtilsTest_getMarkContentResource_04 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.numberMarkInfo = {
    markContent: '',
    markType: MarkType.MARK_TYPE_EXPRESS,
    markCount: -1
  }
  let result = getMarkContentResource(callData);
  expect(result === $r('app.string.courier_and_food_delivery')).assertFalse();
}

let CallLabelUtilsTest_getMarkContentResource_05 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.numberMarkInfo = {
    markContent: '',
    markType: MarkType.MARK_TYPE_PROMOTE_SALES,
    markCount: -1
  }
  let result = getMarkContentResource(callData);
  expect(result === $r('app.string.advertising_and_promotion')).assertFalse();
}

let CallLabelUtilsTest_getMarkContentResource_06 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.numberMarkInfo = {
    markContent: '',
    markType: MarkType.MARK_TYPE_HOUSE_AGENT,
    markCount: -1
  }
  let result = getMarkContentResource(callData);
  expect(result === $r('app.string.Real_Estate_Agency')).assertFalse();
}

let CallLabelUtilsTest_getMarkContentResource_07 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.numberMarkInfo = {
    markContent: '',
    markType: MarkType.MARK_TYPE_INSURANCE,
    markCount: -1
  }
  let result = getMarkContentResource(callData);
  expect(result === $r('app.string.financial_management_insurance')).assertFalse();
}

let CallLabelUtilsTest_getMarkContentResource_08 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.numberMarkInfo = {
    markContent: '',
    markType: MarkType.MARK_TYPE_TAXI,
    markCount: -1
  }
  let result = getMarkContentResource(callData);
  expect(result === $r('app.string.taxi')).assertFalse();
}

let CallLabelUtilsTest_getMarkContentResource_09 = () => {
  let callData: DefaultCallData = new DefaultCallData();
  callData.numberMarkInfo = {
    markContent: '',
    markType: MarkType.MARK_TYPE_FRAUD,
    markCount: -1
  }
  let result = getMarkContentResource(callData);
  expect(result === $r('app.string.taxi')).assertFalse();
}

export default function CallLabelUtilsTest() {
  describe('CallLabelUtilsTest', () => {
    it('CallLabelUtilsTest_getCallLabelPrimary_01', 0, async () => {
      CallLabelUtilsTest_getCallLabelPrimary_01();
    })
    it('CallLabelUtilsTest_getCallLabelPrimary_02', 0, async () => {
      CallLabelUtilsTest_getCallLabelPrimary_02();
    })
    it('CallLabelUtilsTest_getCallLabelPrimary_03', 0, async () => {
      CallLabelUtilsTest_getCallLabelPrimary_03();
    })
    it('CallLabelUtilsTest_getCallLabelSecondary_01', 0, async () => {
      CallLabelUtilsTest_getCallLabelSecondary_01();
    })
    it('CallLabelUtilsTest_getCallLabelSecondary_02', 0, async () => {
      CallLabelUtilsTest_getCallLabelSecondary_02();
    })
    it('CallLabelUtilsTest_getCallLabelSecondary_03', 0, async () => {
      CallLabelUtilsTest_getCallLabelSecondary_03();
    })
    it('CallLabelUtilsTest_getCallLabelSecondary_04', 0, async () => {
      CallLabelUtilsTest_getCallLabelSecondary_04();
    })
    it('CallLabelUtilsTest_getCallLabelSecondary_05', 0, async () => {
      CallLabelUtilsTest_getCallLabelSecondary_05();
    })
    it('CallLabelUtilsTest_getCallLabelSecondary_06', 0, async () => {
      CallLabelUtilsTest_getCallLabelSecondary_06();
    })
    it('CallLabelUtilsTest_getCallLabelSecondary_07', 0, async () => {
      CallLabelUtilsTest_getCallLabelSecondary_07();
    })
    it('CallLabelUtilsTest_fileNameString_01', 0, async () => {
      CallLabelUtilsTest_fileNameString_01();
    })
    it('CallLabelUtilsTest_fileNameString_03', 0, async () => {
      CallLabelUtilsTest_fileNameString_03();
    })
    it('CallLabelUtilsTest_fileNameString_04', 0, async () => {
      CallLabelUtilsTest_fileNameString_04();
    })
    it('CallLabelUtilsTest_fileNameString_05', 0, async () => {
      CallLabelUtilsTest_fileNameString_05();
    })
    it('CallLabelUtilsTest_fileNameString_06', 0, async () => {
      CallLabelUtilsTest_fileNameString_06();
    })
    it('CallLabelUtilsTest_fileNameString_07', 0, async () => {
      CallLabelUtilsTest_fileNameString_07();
    })
    it('CallLabelUtilsTest_getCallLabelThird_01', 0, async () => {
      CallLabelUtilsTest_getCallLabelThird_01();
    })
    it('CallLabelUtilsTest_getCallLabelThird_02', 0, async () => {
      CallLabelUtilsTest_getCallLabelThird_02();
    })
    it('CallLabelUtilsTest_getCallLabelThird_03', 0, async () => {
      CallLabelUtilsTest_getCallLabelThird_03();
    })
    it('CallLabelUtilsTest_getCallLabelThird_04', 0, async () => {
      CallLabelUtilsTest_getCallLabelThird_04();
    })
    it('CallLabelUtilsTest_getNumberMarked_01', 0, async () => {
      CallLabelUtilsTest_getNumberMarked_01();
    })
    it('CallLabelUtilsTest_getNumberMarked_02', 0, async () => {
      CallLabelUtilsTest_getNumberMarked_02();
    })
    it('CallLabelUtilsTest_getNumberMarked_03', 0, async () => {
      CallLabelUtilsTest_getNumberMarked_03();
    })
    it('CallLabelUtilsTest_getMarkContentResource_01', 0, async () => {
      CallLabelUtilsTest_getMarkContentResource_01();
    })
    it('CallLabelUtilsTest_getMarkContentResource_02', 0, async () => {
      CallLabelUtilsTest_getMarkContentResource_02();
    })
    it('CallLabelUtilsTest_getMarkContentResource_03', 0, async () => {
      CallLabelUtilsTest_getMarkContentResource_03();
    })
    it('CallLabelUtilsTest_getMarkContentResource_04', 0, async () => {
      CallLabelUtilsTest_getMarkContentResource_04();
    })
    it('CallLabelUtilsTest_getMarkContentResource_05', 0, async () => {
      CallLabelUtilsTest_getMarkContentResource_05();
    })
    it('CallLabelUtilsTest_getMarkContentResource_06', 0, async () => {
      CallLabelUtilsTest_getMarkContentResource_06();
    })
    it('CallLabelUtilsTest_getMarkContentResource_07', 0, async () => {
      CallLabelUtilsTest_getMarkContentResource_07();
    })
    it('CallLabelUtilsTest_getMarkContentResource_08', 0, async () => {
      CallLabelUtilsTest_getMarkContentResource_08();
    })
    it('CallLabelUtilsTest_getMarkContentResource_09', 0, async () => {
      CallLabelUtilsTest_getMarkContentResource_09();
    })

  })
}

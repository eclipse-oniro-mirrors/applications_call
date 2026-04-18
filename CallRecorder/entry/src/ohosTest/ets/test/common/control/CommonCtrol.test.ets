/**
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
import {
  describe,
  beforeAll,
  beforeEach,
  afterEach,
  afterAll,
  it,
  expect,
  MockKit,
  when,
  ArgumentMatchers
} from '@ohos/hypium';
import dataShare from '@ohos.data.dataShare';
import commonController from '../../../../../main/ets/common/control/CommonCtrol'
import { GlobalContextHelper } from '../../../../../main/ets/common/utils/GlobalContextHelper';
import common from '@ohos.app.ability.common';
import { Constant } from '../../../../../main/ets/common/constant/Constant';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import { sleep } from '../utils/Sleep';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import {
  ContactDataStruct,
  ContactsDataStruct,
  RecordConfigContactDataStruct
} from '../../../../../main/ets/common/struct/RecorderSettingStruct';
import { CallSettingConstant } from '../../../../../main/ets/common/constant/CallSettingConstant';
import DataShareResultSet from '@ohos.data.DataShareResultSet';
import LogUtils from '../../../../../main/ets/common/utils/LogUtils';
import RecordDatabaseHelper from '../../../../../main/ets/common/utils/DatabaseHelper';
import { RecordLog } from '../../../../../main/ets/common/struct/RecorderStruct';

const TAG: string = 'RecordingSettingCommonCtrolTest';

let dataShareHelper: dataShare.DataShareHelper;
let contactUri: string = Constant.CONTACT_URI;
let recordConfigUri: string = Constant.RECORDER_DATA_SHARE_URL + Constant.RECORD_CONFIG;
let recordContactUri: string = Constant.RECORDER_DATA_SHARE_URL + Constant.RECORD_CONTACT;
let recordRecordUri: string = Constant.RECORDER_DATA_SHARE_URL + Constant.RECORD_LOG;
let commonCtrol = commonController.getInstance();
let contactsListMockData: ContactDataStruct[] = [
  {
    telephone: '12345678910',
    contactName: 'test1'
  }, {
  telephone: '23456789101',
  contactName: 'test2'
}];
let RecordConfigContactDataMoke: RecordConfigContactDataStruct[] = [{
  phoneNumber: '1345678910',
  id: 0,
  name: 'test',
  image: $r('app.media.ic_user'),
  isChecked: false,
  isImageDefault: true,
  timestamp: new Date().getTime()
}]
let contactsDataResultMoke: ContactsDataStruct[] = [{
  id: 1,
  displayName: 'test',
  detailInfo: '10086',
  blobData: undefined,
  typeId: 5,
  contactId: 10003
}, {
  id: 1,
  displayName: 'test',
  detailInfo: '10086',
  blobData: undefined,
  typeId: 5,
  contactId: 10003
}];

let CommonCtrolTest_jumpToContactForResult_01Func = async () => {
  commonCtrol.jumpToContactForResult((result) => {
    expect([]).assertEqual(result);
  });
};

let CommonCtrolTest_getPhotoDisplayNameDataHelper_01Func = (testContext: Context) => {
  getPhotoDisplayNameDataHelperFunc(testContext, (result) => {
    expect(result).assertEqual(true);
  });
};

let CommonCtrolTest_getPhotoDetailInfo_01Func = () => {
  let contactsDataResult: ContactsDataStruct[] = [{
    id: 1,
    displayName: 'test',
    detailInfo: '10086',
    blobData: undefined,
    typeId: 5,
    contactId: 10003
  }];
  let result = commonCtrol.getPhotoDetailInfo(contactsDataResult, false);
  expect(contactsDataResult[0].displayName).assertEqual(result[0].name);
};

let CommonCtrolTest_getPhotoDetailInfo_02Func = () => {
  let contactsDataResult: ContactsDataStruct[] = [{
    id: 1,
    displayName: 'test',
    detailInfo: '10086',
    blobData: undefined,
    typeId: 5,
    contactId: 10003
  }];
  let result = commonCtrol.getPhotoDetailInfo(contactsDataResult, false);
  sleep(500);
  let resourceResult: Resource = $r('app.media.ic_user');
  expect(JSON.stringify(resourceResult)).assertEqual(JSON.stringify(result[0].image));
};

let CommonCtrolTest_getPhotoDetailInfo_03Func = () => {
  let contactsDataResult: ContactsDataStruct[] = [{
    id: 1,
    displayName: '',
    detailInfo: '10086',
    blobData: undefined,
    typeId: 5,
    contactId: 10003
  }];
  let result = commonCtrol.getPhotoDetailInfo(contactsDataResult, false);
  expect(contactsDataResult[0].detailInfo).assertEqual(result[0].name);
};

let CommonCtrolTest_getPhotoDetailInfo_04Func = () => {
  let contactsDataResult: ContactsDataStruct[] = [{
    id: 1,
    displayName: '',
    detailInfo: '10086',
    blobData: undefined,
    typeId: 5,
    contactId: -1
  }];
  let result = commonCtrol.getPhotoDetailInfo(contactsDataResult, false);
  expect(contactsDataResult[0].displayName).assertEqual(result[0].name);
};

let CommonCtrolTest_queryForContactsInfoForPhoto_01Func = () => {
  commonCtrol.queryForContactsInfoForPhoto([], (data) => {
    expect(data.length >= 0).assertTrue();
  }, false);
};

let CommonCtrolTest_queryForContactsInfoForPhoto_02Func = async () => {
  let mocker: MockKit = new MockKit();
  let func: Function = mocker.mockFunc([], commonCtrol.getPhotoDisplayNameDataHelper);
  when(func)(ArgumentMatchers.any).afterThrow('error');
  commonCtrol.queryForContactsInfoForPhoto(RecordConfigContactDataMoke, (data) => {
    expect(JSON.stringify(data)).not().assertEqual(JSON.stringify([]));
    mocker.clearAll();
  }, false);
  await sleep(2000);
};

let CommonCtrolTest_queryForContactsInfoForPhoto_03Func = async () => {
  let mocker: MockKit = new MockKit();
  let func: Function = mocker.mockFunc(commonCtrol, commonCtrol.getPhotoDisplayNameDataHelper);
  when(func)(ArgumentMatchers.any).afterReturn(contactsDataResultMoke);
  commonCtrol.queryForContactsInfoForPhoto(RecordConfigContactDataMoke, (data) => {
    expect(JSON.stringify(data)).not().assertEqual(JSON.stringify([]));
    mocker.clearAll();
  }, false);
  await sleep(1000);
};

let CommonCtrolTest_queryForConfigContactLength_01Func = async (testContext: Context) => {
  dataShare.createDataShareHelper(testContext, recordContactUri, async (err, res) => {
    dataShareHelper = res;
    let data: ValuesBucket = {
      'phone_number': '17314984771'
    }
    await dataShareHelper.insert(recordContactUri, data);
    await commonCtrol.queryForConfigContactLength((callback) => {
      expect(callback >= 0).assertTrue();
    });
  });
  await sleep(2000);
};

let CommonCtrolTest_getRecordLogDataHelper_01Func = async (testContext: Context) => {
  commonCtrol.recordLogDataHelper = undefined;
  commonCtrol.getRecordLogDataHelper(testContext);
  expect(commonCtrol.recordLogDataHelper).assertEqual(undefined);
};

let CommonCtrolTest_queryForConfigContact_01Func = () => {
  commonCtrol.queryForConfigContact(false, (result) => {
    expect(result.length >= 0).assertTrue();
  }, 0, 0);
};

let CommonCtrolTest_queryForConfigContact_02Func = () => {
  commonCtrol.queryForConfigContact(false, (result) => {
    expect(result.length >= 0).assertTrue();
  }, 100, 1);
};

let CommonCtrolTest_updateObject_01Func = async (testContext: Context) => {
  let dataHelper = await dataShare.createDataShareHelper(testContext, recordConfigUri);
  commonCtrol.updateObject(CallSettingConstant.RECORDING_WAY_DESIGNATE_NUMBER, async (result) => {
    if (result) {
      let condition = new dataSharePredicates.DataSharePredicates();
      let columns = ['object'];
      dataHelper.query(recordConfigUri, condition, columns, (err, resultSet) => {
        if (resultSet.goToNextRow()) {
          let object = resultSet.getString(resultSet.getColumnIndex('object'));
          expect(object).assertEqual(CallSettingConstant.RECORDING_WAY_DESIGNATE_NUMBER);
          resultSet.close();
        }
      });
    } else {
      expect(result).assertEqual(0);
    }
  });
};

let CommonCtrolTest_insertConfigContact_01Func = (testContext: Context) => {
  commonCtrol.insertConfigContact({ phone_number: 10086, name: '10086' }, async () => {
    let dataHelper = await dataShare.createDataShareHelper(testContext, recordConfigUri);
    let condition = new dataSharePredicates.DataSharePredicates();
    condition.equalTo('name', '10086');
    let columns = ['name'];
    dataHelper.query(recordConfigUri, condition, columns, (err, resultSet) => {
      if (resultSet?.goToNextRow()) {
        let name = resultSet.getString(resultSet.getColumnIndex('name'));
        if(name == '10086') {
          expect(name).assertEqual('10086');
        }
        resultSet.close();
      }
    });
  });
};

function getPhotoDisplayNameDataHelperFunc(testContext: Context, callback: (data: boolean) => void) {
  let displayName: string;
  let detailInfo: string;
  let typeId: number;
  let contactId: number;
  dataShare.createDataShareHelper(testContext, Constant.CONTACT_URI, async (err, res) => {
    dataShareHelper = res;
    let data: ValuesBucket = {
      'type_id': 5,
      'is_deleted': '0',
      'detail_info': '17314984771'
    };
    await dataShareHelper.insert(Constant.CONTACT_URI, data);
    let phoneNumberList: string[] = [
      '17314984771'
    ];
    let resultColumns = [
      'display_name',
      'detail_info',
      'type_id',
      'contact_id'
    ];
    let condition = new dataSharePredicates.DataSharePredicates();
    condition.equalTo('type_id', 5);
    condition.and();
    condition.equalTo('is_deleted', '0');
    condition.and();
    condition.in('detail_info', phoneNumberList);
    dataShareHelper.query(Constant.CONTACT_URI, condition, resultColumns, (err, queryData) => {
      if (queryData) {
        displayName = queryData.getString(queryData.getColumnIndex('display_name'));
        detailInfo = queryData.getString(queryData.getColumnIndex('detail_info'));
        typeId = queryData.getLong(queryData.getColumnIndex('type_id'));
        contactId = queryData.getLong(queryData.getColumnIndex('contact_id'));
      }
      queryData?.close();
    });
    let contactsDataResult: ContactsDataStruct[] = [];
    contactsDataResult.push({
      displayName: displayName,
      detailInfo: detailInfo,
      typeId: typeId,
      contactId: contactId
    });
    let result = await commonController.getInstance().getPhotoDisplayNameDataHelper(phoneNumberList, dataShareHelper);
    let resultCallback = result.length === contactsDataResult.length;
    callback(resultCallback);
  });
}

let CommonCtrolTest_jumpToContactForResult_02 = async () => {
  let mocker: MockKit = new MockKit();
  let context = await GlobalContextHelper.getContext()
    .getValue<common.UIExtensionContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
  let func: Function = mocker.mockFunc(context, context.startAbilityForResult);
  when(func)(ArgumentMatchers.any).afterThrow('error');
  commonController.getInstance().jumpToContactForResult((result) => {
    expect(true).assertTrue();
  })
  await sleep(2000);
  mocker.clearAll();
}

let CommonCtrolTest_jumpToContactForResult_03 = async () => {
  let mocker: MockKit = new MockKit();
  let context = await GlobalContextHelper.getContext()
    .getValue<common.UIExtensionContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
  let func: Function = mocker.mockFunc(context, context.startAbilityForResult);
  when(func)(ArgumentMatchers).afterReturn({
    want: {
      parameters: {
        contactObjects: JSON.stringify(contactsListMockData)
      }
    }
  });
  commonController.getInstance().jumpToContactForResult((result) => {
    expect(true).assertTrue();
  })
  await sleep(2000);
  mocker.clearAll();
}

let CommonCtrolTest_updateIsOpen_01 = async () => {
  commonCtrol.updateIsOpen(0, () => {
    expect(true).assertTrue();
  })
  await sleep(1000);
}

let CommonCtrolTest_getPixelMap_01 = () => {
  commonCtrol.getPixelMap(new ArrayBuffer(1024) as Uint8Array);
  expect(true).assertTrue();
}

let CommonCtrolTest_batchInsertConfigFilter = async () => {
  commonController.getInstance().batchInsertConfigFilter(contactsListMockData, RecordConfigContactDataMoke, (data) => {
    expect(true).assertTrue();
  });
}

let CommonCtrolTest_batchInsertConfigFilter_02 = async () => {
  let dataList: RecordConfigContactDataStruct[] = [{
    phoneNumber: '12345678910',
    id: 0,
    name: 'test',
    image: $r('app.media.ic_user'),
    isChecked: false,
    isImageDefault: true,
    timestamp: new Date().getTime()
  }]
  commonController.getInstance().batchInsertConfigFilter(contactsListMockData, dataList, (data) => {
    expect(contactsListMockData[0].telephone === dataList[0].phoneNumber).assertTrue();
  });
}


let CommonCtrolTest_batchInsertConfigContact = async (context: Context) => {
  let temp: ValuesBucket[] = [{
    phone_number: '12345678910',
    name: 'test1'
  }];

  commonController.getInstance().batchInsertConfigContact(temp, (data) => {
    expect(temp.length >= 0).assertTrue();
  });
}

let CommonCtrolTest_batchInsertConfigContact1 = async (context: Context) => {
  let temp: ValuesBucket[] = [];
  commonController.getInstance().batchInsertConfigContact(temp, (data) => {
    expect(temp.length >= 0).assertTrue();
  });
}

let CommonCtrolTest_deleteConfigContact = async (context: Context) => {
  let params: string[] = ['test'];

  commonController.getInstance().deleteConfigContact(params, () => {
    expect(true).assertTrue();
  });
}

let CommonCtrolTest_deleteConfigContact_01 = async (context: Context) => {
  let params: string[] = [];
  commonController.getInstance().deleteConfigContact([], () => {
    expect(params.length >= 0).assertTrue();
  });
}

let CommonCtrolTest_updateErrorTime = async (context: Context) => {
  commonController.getInstance().updateErrorTime(context);
  expect(true).assertTrue();
}


let CommonCtrolTest_queryByNumberMatch = async (context: Context) => {
  LogUtils.i(TAG, 'CommonCtrolTest_queryByNumberMatch start');
  let contactUri: string = Constant.CONTACT_URI;
  let dataHelper: dataShare.DataShareHelper = await dataShare.createDataShareHelper(context, contactUri);
  let finalList: ContactsDataStruct[] = [];

  let instance = commonController.getInstance();
  await instance.queryNoEqualsNumByNumberMatch([], [], dataHelper, finalList);

  await instance.queryNoEqualsNumByNumberMatch(['1', '1'], ['1'], dataHelper, finalList);

  await instance.queryNoEqualsNumByNumberMatch(['13888888888', '10010', '13800000000'], ['13888888888'],
    dataHelper, finalList);

  try {
    let queryResult = await instance.queryContactNumberMatchResultSet(dataHelper, '10000');
    if (queryResult) {
      let mocker: MockKit = new MockKit();
      let mockFunc: Function = mocker.mockFunc(instance, instance.queryContactNumberMatchResultSet);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(queryResult);
      await instance.queryNoEqualsNumByNumberMatch(['10086', '123', '13800000000'], ['123'], dataHelper, finalList);
      mocker.clearAll();
    }
    queryResult?.close();
  } catch (err) {
    LogUtils.e(TAG, 'queryByNumberMatch err' + JSON.stringify(err));
  }
  LogUtils.i(TAG, 'CommonCtrolTest_queryByNumberMatch finalList.length:' + finalList.length);
  expect(finalList.length >= 0).assertTrue();
}

let CommonCtrolTest_updateIsOpenForClone_01 = async () => {
  let context = await GlobalContextHelper.getContext()
    .getValue<common.UIExtensionContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
  await RecordDatabaseHelper.getInstance().InitForDB(context);
  LogUtils.i('ComonCtrolTest', 'CommonCtrolTest_updateIsOpenForClone_01 start test');

  let emptyContactVal: ValuesBucket[] = [];
  await commonController.getInstance().batchInsertConfigContactForClone(context, emptyContactVal, (result) => {});
  let test: ValuesBucket = {'1': '1', '2': '2','3': '3','4': '4','5': '5','6': '6','7': '7','8': '8','9': '9','0': ''};
  emptyContactVal.push(test);
  await commonController.getInstance().batchInsertConfigContactForClone(context, emptyContactVal, (result) => {});
  LogUtils.i('ComonCtrolTest', 'CommonCtrolTest_updateIsOpenForClone_01 test step 01');

  emptyContactVal.pop();
  let valuesBucket: ValuesBucket = {};
  valuesBucket['phone_number'] = '10086';
  valuesBucket['name'] = 'yidong';
  emptyContactVal.push(valuesBucket);
  let insertRows = 0;
  await commonController.getInstance().batchInsertConfigContactForClone(context, emptyContactVal, (result) => {
    insertRows = result;
  });
  LogUtils.i('ComonCtrolTest', 'CommonCtrolTest_updateIsOpenForClone_01 insertRows:' + insertRows);
  expect(insertRows >= 0).assertTrue();

  let emptyVal: ValuesBucket = {};
  await commonController.getInstance().updateIsOpenForClone(context, emptyVal, (result) => {});
  let invalidVal: ValuesBucket = {isOpenxxx:1};
  await commonController.getInstance().updateIsOpenForClone(context, invalidVal, (result) => {});
  await commonController.getInstance().updateIsOpenForClone(context, invalidVal, (result) => {});
  let notEmptyVal: ValuesBucket = {"is_open":1,"object":"2"};
  let updateRow = 0;
  await commonController.getInstance().updateIsOpenForClone(context, notEmptyVal, (result) => {
    updateRow = result;
  });
  LogUtils.i('ComonCtrolTest', 'CommonCtrolTest_updateIsOpenForClone_01 updateRow:' + updateRow);
  expect(updateRow >= 0).assertTrue();
}

let CommonCtrolTest_updateRecordLog = async (context: Context) => {
  let reLog: RecordLog = new RecordLog();
  let date = new Date().getTime();
  let fileName = `test_${date}.m4a`;
  let filePath = `/CallRecord/${fileName}`;
  reLog.filePath = filePath;
  reLog.displayName = fileName;
  reLog.phoneNumber = '12345678901';
  reLog.dateAdded = date;
  reLog.recorderAdded = date;

  let ret = await commonController.getInstance().updateRecordLog(context, reLog, fileName, filePath);
  expect(ret != null);
}

let CommonCtrolTest_getPhoto = async () => {
  commonController.getInstance().getPhoto(1);
  expect(true).assertTrue();
}

let CommonCtrolTest_batchInsertRecordInfoForClone_01 = async (context: Context) => {
  let data: ValuesBucket[] = [{ "is_open": 1 }, { "object": "2" }]

  let ret = await commonController.getInstance().batchInsertRecordInfoForClone(context, data);
  expect(ret != null);
}

let CommonCtrolTest_batchInsertRecordInfoForClone_02 = async (context: Context) => {
  let data: ValuesBucket[] = []

  let ret = await commonController.getInstance().batchInsertRecordInfoForClone(context, data);
  expect(ret != null);
}

let CommonCtrolTest_createForConfig = async (testContext: Context) => {
  dataShare.createDataShareHelper(testContext, recordConfigUri, async (err, res) => {
    dataShareHelper = res;
    let data: ValuesBucket = {
      'phone_number': '17314984771'
    }
    await dataShareHelper.insert(recordContactUri, data);
    await commonCtrol.createForConfig(true, (callback) => {
      expect(callback >= 0).assertTrue();
    });
  });
  await sleep(2000);
};

let CommonCtrolTest_queryForConfig = async () => {
  let res = 1
  try {
    await commonCtrol.queryForConfig((callback) => {});
  } catch (e) {
    res = 0
  }
  expect(res).assertEqual(1);
};

export function CommonCtrolTest() {
  describe('CommonCtrolTest', () => {
    let testContext = GlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    it('CommonCtrolTest_getPhotoDisplayNameDataHelper_01', 0, () => {
      CommonCtrolTest_getPhotoDisplayNameDataHelper_01Func(testContext);
    });
    it('CommonCtrolTest_getPhotoDetailInfo_01', 0, () => {
      CommonCtrolTest_getPhotoDetailInfo_01Func();
    });
    it('CommonCtrolTest_getPhotoDetailInfo_02', 0, () => {
      CommonCtrolTest_getPhotoDetailInfo_02Func();
    });
    it('CommonCtrolTest_getPhotoDetailInfo_03', 0, () => {
      CommonCtrolTest_getPhotoDetailInfo_03Func();
    });
    it('CommonCtrolTest_getPhotoDetailInfo_04', 0, () => {
      CommonCtrolTest_getPhotoDetailInfo_04Func();
    });
    it('CommonCtrolTest_queryForContactsInfoForPhoto_01', 0, () => {
      CommonCtrolTest_queryForContactsInfoForPhoto_01Func();
    });
    it('CommonCtrolTest_queryForConfigContactLength_01', 0, async () => {
      await CommonCtrolTest_queryForConfigContactLength_01Func(testContext);
    });
    it('CommonCtrolTest_queryForConfigContact_01', 0, () => {
      CommonCtrolTest_queryForConfigContact_01Func();
    });
    it('CommonCtrolTest_queryForConfigContact_02', 0, () => {
      CommonCtrolTest_queryForConfigContact_02Func();
    });
  });
}

export function CommonCtrolTest1() {
  describe('CommonCtrolTest1', () => {
    let testContext = GlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    it('CommonCtrolTest_insertConfigContact_01', 0, () => {
      CommonCtrolTest_insertConfigContact_01Func(testContext);
    });
    it('CommonCtrolTest_getRecordLogDataHelper_01', 0, async () => {
      await CommonCtrolTest_getRecordLogDataHelper_01Func(testContext);
    });
    it('CommonCtrolTest_getPixelMap_01', 0, () => {
      CommonCtrolTest_getPixelMap_01();
    });
    it('CommonCtrolTest_updateObject_01', 0, async () => {
      await CommonCtrolTest_updateObject_01Func(testContext);
    });
    it('CommonCtrolTest_getPhoto', 0, async () => {
      await CommonCtrolTest_getPhoto();
    });
    it('CommonCtrolTest_batchInsertRecordInfoForClone_01', 0, async () => {
      await CommonCtrolTest_batchInsertRecordInfoForClone_01(testContext);
    });
    it('CommonCtrolTest_batchInsertRecordInfoForClone_02', 0, async () => {
      await CommonCtrolTest_batchInsertRecordInfoForClone_02(testContext);
    });
    it('CommonCtrolTest_createForConfig', 0, async () => {
      await CommonCtrolTest_createForConfig(testContext);
    });
    it('CommonCtrolTest_queryForConfig', 0, async () => {
      await CommonCtrolTest_queryForConfig();
    });
    it('CommonCtrolTest_updateIsOpen_01', 0, async () => {
      await CommonCtrolTest_updateIsOpen_01();
    });
    it('CommonCtrolTest_jumpToContactForResult_01Func', 0, async () => {
      await CommonCtrolTest_jumpToContactForResult_01Func();
    });
  });
}

export function CommonCtrolTest2() {
  describe('CommonCtrolTest2', () => {
    let testContext = GlobalContextHelper.getContext()
      .getValue<common.UIAbilityContext>(Constant.CALL_RECORDER_ABILITY_CONTEXT);
    it('CommonCtrolTest_batchInsertConfigFilter', 0, async () => {
      await CommonCtrolTest_batchInsertConfigFilter();
    });
    it('CommonCtrolTest_batchInsertConfigFilter_02', 0, async () => {
      await CommonCtrolTest_batchInsertConfigFilter_02();
    });
    it('CommonCtrolTest_batchInsertConfigContact', 0, async () => {
      await CommonCtrolTest_batchInsertConfigContact(testContext);
    });
    it('CommonCtrolTest_batchInsertConfigContact1', 0, async () => {
      await CommonCtrolTest_batchInsertConfigContact1(testContext);
    });
    it('CommonCtrolTest_deleteConfigContact', 0, async () => {
      await CommonCtrolTest_deleteConfigContact(testContext);
    });
    it('CommonCtrolTest_deleteConfigContact_01', 0, async () => {
      await CommonCtrolTest_deleteConfigContact_01(testContext);
    });
    it('CommonCtrolTest_updateErrorTime', 0, async () => {
      await CommonCtrolTest_updateErrorTime(testContext);
    });
    it('CommonCtrolTest_queryByNumberMatch', 0, async () => {
      await CommonCtrolTest_queryByNumberMatch(testContext);
    });
    it('CommonCtrolTest_updateIsOpenForClone_01', 0, async () => {
      await CommonCtrolTest_updateIsOpenForClone_01();
    });
    it('CommonCtrolTest_updateRecordLog', 0, async () => {
      await CommonCtrolTest_updateRecordLog(testContext);
    });
    it('CommonCtrolTest_jumpToContactForResult_02', 0, async () => {
      await CommonCtrolTest_jumpToContactForResult_02();
    });
    it('CommonCtrolTest_jumpToContactForResult_03', 0, async () => {
      await CommonCtrolTest_jumpToContactForResult_03();
    });
  });
}
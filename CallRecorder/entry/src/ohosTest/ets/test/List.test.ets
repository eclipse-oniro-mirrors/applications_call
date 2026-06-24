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
import DbBackUpProcessorTest from './database/DbBackUpProcessor.test'
import BackUpToDoubleDbHelperTest from './common/utils/database/BackUpToDoubleDbHelper.test'
import StringUtilTest from './common/utils/StringUtil.test'
import FileUtilsTest from './common/utils/FileUtils.test'
import AutoRecordDbHelperTest from './common/utils/database/AutoRecordDbHelper.test'
import QuerySettingDataHelperTest from './common/utils/QuerySettingDataHelper.test'
import CallRecorderModelTest from './common/model/CallRecorderModel.test';
import CallRecorderPresenterTest from './common/utils/presenter/CallRecorderPresenter.test';
import ServiceExtAbilityTest from './serviceextability/ServiceExtAbility.test';
import FuncManagerTest from './serviceextability/FuncManager.test';
import BackupExtensionTest from './serviceextability/BackupExtension.test';
import BasicDataSourceTest from './common/model/BasicDataSource.test';
import idl_service_ext_stubTest from './IdlServiceExt/idl_service_ext_stub.test';
import { CommonCtrolTest, CommonCtrolTest1, CommonCtrolTest2 } from '././common/control/CommonCtrol.test';
import CommonUtilTest from './common/utils/CommonUtil.test';
import DatabaseHelperTest from './common/utils/DatabaseHelper.test';
import CallRecorderDbHelperTest from './common/utils/database/CallRecorderDbHelper.test';
import TimeUtilTest from './common/utils/TimeUtil.test';
import ResourceUtilTest from './common/utils/ResourceUtil.test';
import LogUtilsTest from './common/utils/LogUtils.test';
import CommonDataTest from './common/utils/CommonData.test';
import ArrayUtilTest from './common/utils/ArrayUtil.test';
import RecorderStructTest from './common/struct/RecorderStruct.test';
import RecorderSettingStructTest from './common/struct/RecorderSettingStruct.test';
import ContactServiceTest from './common/service/ContactService.test';
import abilityTest from './Ability.test';
import { idl_service_ext_implTest, idl_service_ext_implTest01 } from './IdlServiceExt/idl_service_ext_impl.test';
import CallRecorderPresenter from './common/utils/presenter/CallRecorderPresenter.test';
import GlobalContextHelper from './common/utils/GlobalContextHelper.test';
import RecorderDesignateNumberSourceTest from './common/model/RecorderDesignateNumberSource.test';
import { FontScaleStateTest01 } from './common/utils/FontScaleState.test';
import { ReportUtilTest01 } from './common/utils/ReportUtil.test';
import CallRecorderColumnUtilsTest from './common/utils/CallRecorderColumnUtils.test';
import SampleUtilTest from './common/utils/SampleUtil.test';
import MigrationServiceExtStubTest from './migrationServiceExt/MigrationServiceExtStub.test';
import MigrationServiceExtImplTest from './migrationServiceExt/MigrationServiceExtImpl.test';
import MigrationServiceAbilityTest from './serviceextability/MigrationServiceAbility.test'
import FilePermissionAbilityTest from  './serviceextability/FilePermissionAbility.test';
import file_permission_ext_stubTest from './filePermissionExt/idl_file_permission_ext_stub.test';
import file_permission_ext_implTest from './filePermissionExt/idl_file_permission_ext_impl.test'
import MigrationServiceHelperTest from './migrationServiceExt/MigrationServiceHelper.test'
import CallRecorderExtensionAbilityTest from './callrecorderuiextability/CallRecorderAbility.test'

export default function testsuite() {
  BackUpToDoubleDbHelperTest();
  DbBackUpProcessorTest();
  abilityTest();
  AutoRecordDbHelperTest();
  FileUtilsTest();
  ContactServiceTest();
  RecorderSettingStructTest();
  RecorderStructTest();
  ArrayUtilTest();
  CommonDataTest();
  LogUtilsTest();
  ResourceUtilTest();
  TimeUtilTest();
  CallRecorderDbHelperTest();
  DatabaseHelperTest();
  CommonUtilTest();
  idl_service_ext_stubTest();
  BasicDataSourceTest();
  BackupExtensionTest();
  FuncManagerTest();
  ServiceExtAbilityTest();
  MigrationServiceAbilityTest()
  CallRecorderPresenterTest();
  CallRecorderModelTest();
  CommonCtrolTest();
  CommonCtrolTest1();
  CommonCtrolTest2();
  FontScaleStateTest01();
  ReportUtilTest01();
  idl_service_ext_implTest();
  idl_service_ext_implTest01();
  CallRecorderPresenter();
  GlobalContextHelper();
  RecorderDesignateNumberSourceTest();
  QuerySettingDataHelperTest();
  StringUtilTest();
  CallRecorderColumnUtilsTest();
  SampleUtilTest();
  FilePermissionAbilityTest();
  file_permission_ext_stubTest();
  file_permission_ext_implTest();
  MigrationServiceExtStubTest();
  MigrationServiceExtImplTest();
  MigrationServiceHelperTest();
  CallRecorderExtensionAbilityTest();
}
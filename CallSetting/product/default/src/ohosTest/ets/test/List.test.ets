import CallSettingAbilityTest from './CallSettingAbility.test'
import SatelliteLocationDataShareAbilityTest from './SatelliteLocationDataShareAbility.test'
import SatelliteStrongNotifyManagerTest from './manager/SatelliteStrongNotifyManager.test'
import IntentSwitchAdaptorTest from './insightintents/adapter/IntentSwitchAdaptor.test'
import IntentCustomAdapterTest from './insightintents/adapter/IntentCustomAdapter.test'
import AlertDialogManagerTest from './manager/AlertDialogManager.test'
import DisplayUtilTest from './common/utils/DisplayUtil.test'
import IntentCheckAdaptorTest from './insightintents/adapter/IntentCheckAdaptor.test'
import SatelliteFloatWindowManagerTest from './manager/SatelliteFloatWindowManager.test'
import FontScaleStateTest from './common/utils/FontScaleState.test'
import setPreferredNetworkApiTest from './common/model/setPreferredNetworkApi.test'
import getSimTelephoneNumberApiTest from './common/model/getSimTelephoneNumberApi.test'
import SatelliteServiceSettingsVMTest from './viewModel/SatelliteServiceSettingsVM.test'
import SimCardInfoStructTest from './SimCardInfoStruct.test'
import getSimInfoApiTest from './common/model/getSimInfoApi.test'
import EncryptedTest from './common/utils/Encrypted.test'
import SettingUtilTest from './common/utils/SettingUtil.test'
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

import SatelliteUtilsTest from './common/utils/SatelliteUtils.test';
import SatelliteLocationTest from './common/utils/SatelliteLocation.test';
import SateToggleStateManagerTest from './common/utils/SateToggleStateManager.test';
import PlaySkillsJumpUtilsTest from './common/utils/PlaySkillsJumpUtils.test';
import AirplaneModeTest from './common/utils/AirplaneMode.test';
import AirPlaneStateManagerTest from './common/utils/AirPlaneStateManager.test';
import ApnDataStorageCommonTest from './common/utils/ApnDataStorageCommon.test';
import ReportUtilTest from './common/utils/ReportUtil.test';
import SubscriberManagementTest from './common/utils/SubscriberManagement.test';
import QueryAddDataTest from './common/utils/QueryAddData.test';
import ContactServiceTest from './ContactService.test';
import CommonFunUtilTest from './common/utils/CommonFunUtil.test';
import SubSettingsDataTest from './SubSettingsData.test';
import SubSettingVMTest from './viewModel/SubSettingVM.test';
import SubCallForwardDataTest from './SubCallForwardData.test';
import StringUtilTest from './common/utils/StringUtil.test';
import SharedPreferencesUtilsTest from './common/utils/SharedPreferencesUtils.test';
import RecorderSettingConfigTest from './RecorderSettingConfig.test';
import LogUtilsTest from './common/utils/LogUtils.test';
import CommonDataTest from './CommonData.test';
import commonCtrolTest from './common/control/commonCtrol.test';
import CallColumnUtilsTest from './common/utils/CallColumnUtils.test';
import NumberFormatTest from './common/utils/NumberFormat.test';
import simIdFormatTest from './common/utils/SimIdFormat.test';
import IncomingCallRejectionSms from './IncomingCallRejectionSms.test';
import DeviceTypeUtilTest from './common/utils/DeviceTypeUtil.test';
import RegisterCellularDataSettingTest from './common/utils/cellularDataStateApi.test';
import abilityTest from './Ability.test';
import NetworkModeUtilsTest from './common/utils/NetworkModeUtils.test';
import formatResourceToStringTest from './common/utils/formatResourceToString.test';
import ClassUtilTest from './common/utils/ClassUtil.test';
import updateObjectValueTest from './common/utils/updateObjectValue.test';
import UtilssTest from './common/utils/Utils.test';
import ApnDetailsCommonTest from './common/utils/ApnDetailsCommon.test';
import DataStorageUtilTest from './common/utils/DataStorageUtil.test';
import MobileDataGlobalContextHelperTest from './common/utils/MobileDataGlobalContextHelper.test';
import CallSettingVMTest from './viewModel/CallSettingVM.test';
import { ApnListCommonTest01, ApnListCommonTest02 } from './common/utils/ApnListCommon.test';
import ApnListTest from './ApnList.test';
import ApnTypesTest from './model/ApnTypes.test';
import NetworkOperatorsTest from './NetworkOperators.test';
import CallServiceProxyTest from './SettingRingTone.test';
import SubCallAboutTest from './SubCallAbout.test';
import SatelliteServiceSettingModelTest from './SatelliteServiceSettingModel.test';
import DefaultIntentBackgroundUiAbilityTest from './insightintents/ability/DefaultIntentBackgroundUiAbility.test';
import DefaultIntentUiExtensionAbilityTest from './insightintents/ability/DefaultIntentUiExtensionAbility.test';
import IntentOptionAdaptorTest from './insightintents/adapter/IntentOptionAdaptor.test';
import IntentCodeConstantTest from './insightintents/constant/IntentCodeConstant.test';
import IntentTypeTest from './insightintents/constant/IntentConstant.test';
import SettingItemPropertyTest from './insightintents/model/SettingItemProperty.test';
import IntentItemManagerTest from './insightintents/util/IntentItemManager.test';
import DefaultIntentComponentTest from './insightintents/DefaultIntentComponent.test';
import IntentExecutorImplTest from './insightintents/IntentExecutorImpl.test';
import localUnitTest from './LocalUnit.test'
import DynamicLoaderTest from './common/control/DynamicLoader.test'
import ReportWorkSchedulerExtensionTest from './WorkSchedulerExtension/ReportWorkSchedulerExtension.test'
import SatelliteSearchManagerTest from './manager/SatelliteSearchManager.test'
import FileUtilsTest from './common/utils/presenter/FileUtils.test'
import PermissionVerifyManagerTest from './manager/PermissionVerifyManager.test'
import ParseXmlUtilTest from './common/utils/ParseXmlUtil.test'
import SatelliteDialogManagerTest from './manager/SatelliteDialogManager.test'
import MobileViewDataTest from './viewModel/MobileDataViewModel/MobileViewData.test'
import MobileDataUtilsTest from './common/utils/MobileDataUtils.test'
import NewFoldScreenAlertDialogManagerTest from './manager/NewFoldScreenAlertDialogManager.test'
import OperatorConfigUtilsTest from './feature/cust/OperatorConfigUtils.test'
import SatelliteServiceSettingsVMForBeiDouTest from './viewModel/SatelliteServiceSettingsVMForBeiDou.test'
import BeiDouMessageStateManagerTest from './common/utils/BeiDouMessageStateManager.test'
import DistributeUtilsTest from './common/utils/DistributeUtils.test'
import SystemModeUtilsTest from './common/utils/SystemModeUtils.test'

export default function testsuite() {
  CallColumnUtilsTest();
  commonCtrolTest();
  NumberFormatTest();
  simIdFormatTest();
  IncomingCallRejectionSms();
  commonCtrolTest();
  CommonDataTest();
  LogUtilsTest();
  RecorderSettingConfigTest();
  StringUtilTest();
  SubCallForwardDataTest();
  SubSettingVMTest();
  SubSettingsDataTest();
  CommonFunUtilTest();
  ContactServiceTest();
  DeviceTypeUtilTest();
  NetworkOperatorsTest();
  CallServiceProxyTest();
  SubCallAboutTest();
  RegisterCellularDataSettingTest();
  abilityTest();
  NetworkModeUtilsTest();
  formatResourceToStringTest();
  ClassUtilTest();
  updateObjectValueTest();
  UtilssTest();
  ApnDetailsCommonTest();
  DataStorageUtilTest();
  MobileDataGlobalContextHelperTest();
  CallSettingVMTest();
  ApnListCommonTest01();
  ApnListCommonTest02();
  SubscriberManagementTest();
  ApnListTest();
  ApnTypesTest();
  QueryAddDataTest();
  ReportUtilTest();
  AirPlaneStateManagerTest();
  AirplaneModeTest();
  PlaySkillsJumpUtilsTest();
  SateToggleStateManagerTest();
  SatelliteLocationTest();
  DefaultIntentBackgroundUiAbilityTest();
  DefaultIntentUiExtensionAbilityTest();
  IntentOptionAdaptorTest();
  IntentSwitchAdaptorTest();
  IntentCodeConstantTest();
  IntentTypeTest();
  SettingItemPropertyTest();
  IntentItemManagerTest();
  DefaultIntentComponentTest();
  IntentExecutorImplTest();
  SettingUtilTest();
  EncryptedTest();
  getSimInfoApiTest();
  SimCardInfoStructTest();
  SatelliteServiceSettingsVMTest();
  getSimTelephoneNumberApiTest();
  setPreferredNetworkApiTest();
  FontScaleStateTest();
  localUnitTest();
  DynamicLoaderTest();
  SatelliteServiceSettingModelTest();
  SatelliteSearchManagerTest();
  ReportWorkSchedulerExtensionTest();
  SatelliteUtilsTest();
  SharedPreferencesUtilsTest();
  SatelliteFloatWindowManagerTest();
  ApnDataStorageCommonTest();
  IntentCheckAdaptorTest();
  DisplayUtilTest();
  AlertDialogManagerTest();
  IntentCustomAdapterTest();
  FileUtilsTest();
  PermissionVerifyManagerTest();
  ParseXmlUtilTest();
  SatelliteDialogManagerTest();
  MobileViewDataTest();
  MobileDataUtilsTest();
  SatelliteStrongNotifyManagerTest();
  SatelliteLocationDataShareAbilityTest();
  CallSettingAbilityTest();
  NewFoldScreenAlertDialogManagerTest();
  OperatorConfigUtilsTest();
  SatelliteServiceSettingsVMForBeiDouTest();
  BeiDouMessageStateManagerTest();
  DistributeUtilsTest();
  SystemModeUtilsTest();
}